# Testing TUI Applications

This reference covers strategies and patterns for testing terminal user interface applications built with Bubble Tea.

---

## Testing Philosophy

### Separation of Concerns

The MVU (Model-View-Update) architecture naturally supports testing:

- **Model**: Pure data, easily inspectable
- **Update**: Pure function, given input → output
- **View**: String output, easy to assert against

```ruby
# Model is just data - easy to create test fixtures
model = MyModel.new
model.items = ["a", "b", "c"]
model.cursor = 1

# Update is deterministic - same input = same output
new_model, cmd = model.update(Bubbletea::KeyMsg.new("down"))
expect(new_model.cursor).to eq(2)

# View is a string - easy to assert
output = model.view
expect(output).to include("b")  # Selected item
```

---

## Unit Testing Models

### Testing Initial State

```ruby
RSpec.describe MyModel do
  describe "#initialize" do
    it "starts with default values" do
      model = MyModel.new

      expect(model.cursor).to eq(0)
      expect(model.items).to be_empty
      expect(model.loading).to be false
    end

    it "accepts initial configuration" do
      model = MyModel.new(items: ["a", "b"], selected: 1)

      expect(model.items).to eq(["a", "b"])
      expect(model.cursor).to eq(1)
    end
  end
end
```

### Testing Update Logic

Test each message type and verify state transitions:

```ruby
RSpec.describe MyModel do
  describe "#update" do
    let(:model) { MyModel.new(items: %w[one two three]) }

    context "with KeyMsg" do
      it "moves cursor down on j/down" do
        new_model, _ = model.update(key_msg("j"))
        expect(new_model.cursor).to eq(1)

        new_model, _ = model.update(key_msg("down"))
        expect(new_model.cursor).to eq(1)
      end

      it "moves cursor up on k/up" do
        model.cursor = 2
        new_model, _ = model.update(key_msg("k"))
        expect(new_model.cursor).to eq(1)
      end

      it "wraps at boundaries" do
        model.cursor = 2
        new_model, _ = model.update(key_msg("j"))
        expect(new_model.cursor).to eq(0)  # Wrapped to start
      end

      it "returns quit command on q" do
        _, cmd = model.update(key_msg("q"))
        expect(cmd).to eq(Bubbletea.quit)
      end
    end

    context "with custom messages" do
      it "updates on DataLoaded" do
        msg = DataLoaded.new(items: %w[x y z])
        new_model, _ = model.update(msg)

        expect(new_model.items).to eq(%w[x y z])
        expect(new_model.loading).to be false
      end

      it "handles errors gracefully" do
        msg = LoadError.new(message: "Network failed")
        new_model, _ = model.update(msg)

        expect(new_model.error).to eq("Network failed")
        expect(new_model.loading).to be false
      end
    end

    # Helper to create key messages
    def key_msg(key)
      Bubbletea::KeyMsg.new(key)
    end
  end
end
```

### Testing Commands

Commands are functions that produce messages. Test them in isolation:

```ruby
RSpec.describe "Commands" do
  describe ".fetch_data" do
    it "returns DataLoaded on success" do
      allow(API).to receive(:get).and_return({ items: ["a"] })

      result = fetch_data_cmd.call
      expect(result).to be_a(DataLoaded)
      expect(result.items).to eq(["a"])
    end

    it "returns LoadError on failure" do
      allow(API).to receive(:get).and_raise(StandardError, "timeout")

      result = fetch_data_cmd.call
      expect(result).to be_a(LoadError)
      expect(result.message).to include("timeout")
    end
  end
end
```

---

## Testing Views

### String Matching

Test view output contains expected content:

```ruby
RSpec.describe MyModel do
  describe "#view" do
    let(:model) { MyModel.new(items: %w[Apple Banana Cherry]) }

    it "displays all items" do
      output = model.view
      expect(output).to include("Apple")
      expect(output).to include("Banana")
      expect(output).to include("Cherry")
    end

    it "highlights selected item" do
      model.cursor = 1
      output = model.view

      # Selected item should have indicator
      expect(output).to include("> Banana")
      # Others should not
      expect(output).not_to include("> Apple")
    end

    it "shows help text" do
      output = model.view
      expect(output).to include("q quit")
      expect(output).to include("↑/k up")
    end

    it "shows loading state" do
      model.loading = true
      output = model.view
      expect(output).to include("Loading")
    end

    it "shows error message" do
      model.error = "Connection failed"
      output = model.view
      expect(output).to include("Error: Connection failed")
    end
  end
end
```

### Snapshot Testing

For complex views, use snapshot testing:

```ruby
RSpec.describe MyModel do
  describe "#view" do
    it "matches expected output" do
      model = MyModel.new(
        items: %w[One Two Three],
        cursor: 1,
        title: "Select Item"
      )

      expect(model.view).to match_snapshot("item_list_view")
    end
  end
end

# Snapshots stored in spec/snapshots/item_list_view.txt
```

---

## Integration Testing

### Golden File Testing

Compare full program output against expected files:

```ruby
RSpec.describe "Integration" do
  it "produces expected output" do
    output = run_program(["--items", "a,b,c"])
    expected = File.read("spec/fixtures/expected_output.txt")

    expect(output).to eq(expected)
  end
end
```

### Testing with Aruba

Aruba provides integration testing for CLI applications:

```ruby
# spec/spec_helper.rb
require "aruba/rspec"

RSpec.describe "CLI", type: :aruba do
  it "displays help" do
    run_command("mycli --help")
    expect(last_command_started).to have_output(/Usage: mycli/)
  end

  it "processes files" do
    write_file("input.txt", "hello")
    run_command("mycli process input.txt")

    expect(last_command_started).to be_successfully_executed
    expect(read("output.txt")).to include("HELLO")
  end

  it "handles errors gracefully" do
    run_command("mycli process nonexistent.txt")

    expect(last_command_started).to have_exit_status(66)
    expect(last_command_started.stderr).to include("File not found")
  end
end
```

---

## Testing Interactive Behavior

### Simulating User Input

Create test helpers for common interactions:

```ruby
module TestHelpers
  def simulate_keystrokes(model, keys)
    keys.each_char do |key|
      model, _ = model.update(Bubbletea::KeyMsg.new(key))
    end
    model
  end

  def simulate_sequence(model, messages)
    messages.each do |msg|
      model, _ = model.update(msg)
    end
    model
  end
end

RSpec.configure do |c|
  c.include TestHelpers
end

# Usage in tests
it "navigates to third item and selects" do
  model = MyModel.new(items: %w[a b c d])

  model = simulate_keystrokes(model, "jj")  # Down twice
  expect(model.cursor).to eq(2)

  model, _ = model.update(key_msg("enter"))
  expect(model.selected).to eq("c")
end
```

### Testing State Machines

For complex flows, test state transitions:

```ruby
RSpec.describe "Wizard flow" do
  let(:model) { WizardModel.new }

  it "progresses through screens" do
    # Start at welcome
    expect(model.screen).to eq(:welcome)

    # Move to name input
    model, _ = model.update(key_msg("enter"))
    expect(model.screen).to eq(:name_input)

    # Enter name and continue
    model.name = "Alice"
    model, _ = model.update(key_msg("enter"))
    expect(model.screen).to eq(:email_input)

    # Complete wizard
    model.email = "alice@example.com"
    model, cmd = model.update(key_msg("enter"))
    expect(model.screen).to eq(:complete)
    expect(model.result).to include(name: "Alice", email: "alice@example.com")
  end
end
```

---

## Testing Components

### Isolated Component Testing

Test Bubbles components independently:

```ruby
RSpec.describe Bubbles::TextInput do
  let(:input) { Bubbles::TextInput.new }

  it "accumulates typed characters" do
    input, _ = input.update(key_msg("h"))
    input, _ = input.update(key_msg("i"))

    expect(input.value).to eq("hi")
  end

  it "handles backspace" do
    input.value = "hello"
    input, _ = input.update(key_msg("backspace"))

    expect(input.value).to eq("hell")
  end

  it "respects character limit" do
    input.char_limit = 5
    input.value = "hello"

    input, _ = input.update(key_msg("x"))
    expect(input.value).to eq("hello")  # Unchanged
  end
end
```

### Testing Component Composition

Test how components work together:

```ruby
RSpec.describe FormModel do
  let(:model) { FormModel.new }

  it "tabs between fields" do
    expect(model.focused_field).to eq(:name)

    model, _ = model.update(key_msg("tab"))
    expect(model.focused_field).to eq(:email)

    model, _ = model.update(key_msg("tab"))
    expect(model.focused_field).to eq(:submit)
  end

  it "passes input to focused field" do
    model, _ = model.update(key_msg("A"))
    expect(model.name_input.value).to eq("A")
    expect(model.email_input.value).to be_empty
  end
end
```

---

## Testing Edge Cases

### Terminal Size Handling

```ruby
RSpec.describe "Responsive layout" do
  it "renders compact view for narrow terminals" do
    model = MyModel.new
    model.terminal_width = 40

    output = model.view
    output.lines.each do |line|
      expect(line.length).to be <= 40
    end
  end

  it "renders full view for wide terminals" do
    model = MyModel.new
    model.terminal_width = 120

    output = model.view
    expect(output).to include("detailed information")
  end
end
```

### Empty State

```ruby
it "handles empty list gracefully" do
  model = ListModel.new(items: [])
  output = model.view

  expect(output).to include("No items")
  expect(output).not_to include("> ")  # No selection indicator
end
```

### Error States

```ruby
it "recovers from error state" do
  model = MyModel.new
  model.error = "Previous error"

  # User action should clear error
  model, _ = model.update(key_msg("enter"))

  expect(model.error).to be_nil
end
```

---

## Mocking External Dependencies

### API Calls

```ruby
RSpec.describe "Data loading" do
  before do
    allow(API).to receive(:fetch_items).and_return([
      { id: 1, name: "Item 1" },
      { id: 2, name: "Item 2" }
    ])
  end

  it "loads and displays data" do
    model = MyModel.new
    _, cmd = model.init

    # Execute command
    msg = cmd.call
    model, _ = model.update(msg)

    expect(model.items.length).to eq(2)
    expect(model.view).to include("Item 1")
  end
end
```

### File System

```ruby
RSpec.describe "Config loading" do
  around do |example|
    Dir.mktmpdir do |dir|
      @config_dir = dir
      example.run
    end
  end

  it "loads config from file" do
    config_path = File.join(@config_dir, "config.yml")
    File.write(config_path, "theme: dark\n")

    model = MyModel.new(config_path: config_path)
    expect(model.config[:theme]).to eq("dark")
  end
end
```

---

## Performance Testing

### Render Performance

```ruby
RSpec.describe "Performance" do
  it "renders large lists efficiently" do
    model = ListModel.new(items: (1..10000).map { |i| "Item #{i}" })

    start = Time.now
    100.times { model.view }
    elapsed = Time.now - start

    expect(elapsed).to be < 1.0  # 100 renders under 1 second
  end

  it "handles rapid key events" do
    model = MyModel.new(items: (1..100).to_a)

    start = Time.now
    1000.times { model, _ = model.update(key_msg("j")) }
    elapsed = Time.now - start

    expect(elapsed).to be < 0.5  # 1000 updates under 500ms
  end
end
```

---

## CI/CD Considerations

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
      - name: Run tests
        run: bundle exec rspec
        env:
          TERM: xterm-256color  # Ensure color support
          NO_COLOR: 1           # But disable for reproducible output
```

### Deterministic Tests

Ensure tests produce consistent results:

```ruby
# Fix random seed for shuffle operations
RSpec.configure do |c|
  c.before(:each) { srand(12345) }
end

# Mock time-dependent operations
before do
  allow(Time).to receive(:now).and_return(Time.new(2024, 1, 1, 12, 0, 0))
end
```

---

## Resources

- [RSpec Documentation](https://rspec.info/)
- [Aruba Testing Framework](https://github.com/cucumber/aruba)
- [Test-Driven Development](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
