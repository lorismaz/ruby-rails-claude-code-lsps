# Charm Ruby Development

This skill provides comprehensive guidance for building beautiful, interactive command-line applications in Ruby using the charm-ruby ecosystem (bubbletea, lipgloss, bubbles, huh, glamour, harmonica, gum, bubblezone, ntcharts). It helps users design CLI tools with Bubble Tea's Model-View-Update architecture, style terminal output with Lipgloss, integrate pre-built Bubbles components, create interactive forms with Huh, add mouse support with Bubblezone, render terminal charts with ntcharts, and package CLI tools as Ruby gems for distribution on RubyGems.org.

Use this skill when the user asks about:
- Building CLI tools or TUI applications with Ruby
- Using charm-ruby, bubbletea, lipgloss, bubbles, huh, glamour, harmonica, gum, bubblezone, or ntcharts
- Terminal user interfaces in Ruby
- Interactive command-line applications
- Mouse events in terminal applications
- Terminal charts and data visualization
- Distributing Ruby CLI tools as gems

> **Note**: The charm-ruby gems are Ruby ports of the original Go libraries from Charm.sh. While the API is similar, some Go-specific patterns (like Goroutine initialization) have been adapted for Ruby. If you encounter unexpected behavior, check that you're using the Ruby-specific patterns shown in this documentation.

---

## Quick Start

Install the core charm-ruby gems:

```ruby
# Gemfile
gem "bubbletea"    # MVU architecture
gem "lipgloss"     # Terminal styling
gem "bubbles"      # Pre-built components
gem "glamour"      # Markdown rendering
gem "harmonica"    # Spring animations
gem "gum"          # Shell script helpers
gem "bubblezone"   # Mouse event zones
gem "ntcharts"     # Terminal charts

# Huh requires GitHub install until gem name resolved
gem "huh", github: "marcoroth/huh-ruby"
```

Then run `bundle install`.

---

## Bubble Tea: Model-View-Update Architecture

Bubble Tea implements the Elm-inspired MVU pattern for building interactive terminal applications. Every Bubble Tea app has three core methods:

1. **init**: Initialize state and optionally return startup commands
2. **update**: Handle messages (user input, command results) and return new state
3. **view**: Render current state as a string for display

### Basic Structure

```ruby
require "bubbletea"

class MyModel
  include Bubbletea::Model

  def initialize
    @count = 0
  end

  def init
    nil  # No initial command
  end

  def update(msg)
    case msg
    when Bubbletea::KeyMsg
      case msg.string
      when "q", "ctrl+c"
        return self, Bubbletea.quit
      when "up", "k"
        @count += 1
      when "down", "j"
        @count -= 1
      end
    end
    [self, nil]
  end

  def view
    "Count: #{@count}\n\nPress up/down to change, q to quit"
  end
end

Bubbletea.run(MyModel.new)
```

### Key Concepts

- **Messages**: Events like `KeyMsg`, `MouseMsg`, or custom messages from commands
- **Commands**: Async operations that return messages when complete
- **Model immutability**: Return new state from `update`, don't mutate in place

For detailed architecture patterns, see `references/bubble-tea-architecture.md`.

---

## Lipgloss: Terminal Styling

Lipgloss provides CSS-like styling for terminal output with support for colors, borders, padding, margins, and alignment.

### Style Basics

```ruby
require "lipgloss"

# Create a style with method chaining
style = Lipgloss::Style.new
  .bold(true)
  .foreground("#FAFAFA")
  .background("#7D56F4")
  .padding(1, 2)
  .border(:rounded)
  .border_foreground("#FF0000")

# Apply style to text
styled_text = style.render("Hello, World!")
puts styled_text
```

### Color Support

Lipgloss automatically adapts to terminal capabilities:

- **ANSI 16**: Basic terminal colors
- **ANSI 256**: Extended color palette
- **True Color**: 24-bit hex colors like `"#FF5733"`
- **Adaptive**: Automatically adjusts for light/dark backgrounds

```ruby
# Adaptive color (light bg / dark bg)
style = Lipgloss::Style.new
  .foreground(Lipgloss.adaptive_color("#000000", "#FFFFFF"))
```

### Layout Primitives

```ruby
# Padding: top, right, bottom, left (or single value for all)
style.padding(1, 2, 1, 2)

# Margins
style.margin(1, 2)

# Width and alignment
style.width(40).align(:center)

# Borders: :normal, :rounded, :double, :thick, :hidden
style.border(:rounded).border_foreground("#888888")
```

For complete styling reference, see `references/lipgloss-styling.md`.

---

## Bubbles: Pre-Built Components

Bubbles provides ready-to-use components that integrate with Bubble Tea's MVU architecture.

### Available Components

| Component | Purpose |
|-----------|---------|
| Spinner | Animated loading indicators |
| TextInput | Single-line text input with cursor |
| TextArea | Multi-line text editing |
| List | Scrollable, selectable item list |
| Table | Formatted data tables |
| Progress | Progress bar with percentage |
| Viewport | Scrollable content area |

### Using Components

Components maintain their own state and expose `update` and `view` methods:

```ruby
require "bubbles"

class MyModel
  include Bubbletea::Model

  def initialize
    @spinner = Bubbles::Spinner.new
    @spinner.style = :dots  # :line, :dots, :minidots, :jump, etc.
    @loading = true
  end

  def init
    @spinner.tick  # Start spinner animation
  end

  def update(msg)
    if @loading
      spinner, cmd = @spinner.update(msg)
      @spinner = spinner
      return [self, cmd]
    end
    [self, nil]
  end

  def view
    if @loading
      "Loading... #{@spinner.view}"
    else
      "Done!"
    end
  end
end
```

For all component patterns, see `references/bubbles-components.md`.

---

## Huh: Interactive Forms

Huh simplifies building interactive forms with validation, styling, and multiple input types.

### Form Building

```ruby
require "huh"

form = Huh::Form.new do |f|
  f.group do |g|
    g.input :name, title: "What's your name?", placeholder: "Enter name..."
    g.select :color, title: "Favorite color?", options: %w[Red Green Blue]
    g.confirm :agree, title: "Do you agree to the terms?"
  end
end

result = form.run
puts "Name: #{result[:name]}"
puts "Color: #{result[:color]}"
puts "Agreed: #{result[:agree]}"
```

### Input Types

- `input`: Single-line text with optional validation
- `text`: Multi-line text area
- `select`: Single choice from options
- `multi_select`: Multiple choices
- `confirm`: Yes/No question

### Validation

```ruby
f.input :email,
  title: "Email address",
  validate: ->(v) { v.include?("@") ? nil : "Invalid email" }
```

For complete form patterns, see `references/huh-forms.md`.

---

## Gum: Shell Script Helpers

Gum provides a Ruby interface for creating interactive shell script prompts without building full Bubble Tea applications. Perfect for quick scripts and CLI utilities.

### Input Prompts

```ruby
require "gum"

# Simple text input
name = Gum.input(placeholder: "Enter your name")

# With header and default value
email = Gum.input(
  header: "Contact Information",
  placeholder: "email@example.com",
  value: ENV["USER_EMAIL"]
)
```

### Selection Menus

```ruby
# Single selection
color = Gum.choose("Red", "Green", "Blue", header: "Pick a color")

# Multiple selection
features = Gum.choose(
  "Authentication",
  "Database",
  "API",
  "Testing",
  header: "Select features to enable",
  no_limit: true  # Allow multiple selections
)
```

### Confirmations

```ruby
# Simple yes/no
if Gum.confirm("Delete all files?")
  delete_files
end

# With custom prompt
proceed = Gum.confirm(
  "Deploy to production?",
  affirmative: "Yes, deploy",
  negative: "No, cancel"
)
```

### Spinners for Long Operations

```ruby
# Show spinner while executing a block
result = Gum.spin(title: "Installing dependencies...") do
  system("bundle install")
end

# With custom spinner style
Gum.spin(title: "Building project...", spinner: :dots) do
  system("rake build")
end
```

### Filtering Lists

```ruby
# Interactive fuzzy filter
selected = Gum.filter(
  items,
  placeholder: "Search...",
  header: "Select a file"
)
```

### Styled Output

```ruby
# Print styled text
Gum.style("Success!", foreground: "#00FF00", bold: true)

# Create a styled box
Gum.style(
  "Welcome to My CLI",
  border: :rounded,
  padding: "1 2",
  foreground: "#FFFFFF",
  background: "#7D56F4"
)
```

---

## Composing Applications

Larger applications compose multiple components and screens:

### Multi-Screen Pattern

```ruby
class App
  include Bubbletea::Model

  SCREEN_MENU = :menu
  SCREEN_FORM = :form
  SCREEN_RESULT = :result

  def initialize
    @screen = SCREEN_MENU
    @menu = MenuModel.new
    @form = FormModel.new
    @result = nil
  end

  def update(msg)
    case @screen
    when SCREEN_MENU
      @menu, cmd = @menu.update(msg)
      if @menu.selected
        @screen = SCREEN_FORM
      end
    when SCREEN_FORM
      @form, cmd = @form.update(msg)
      if @form.submitted
        @result = process(@form.data)
        @screen = SCREEN_RESULT
      end
    end
    [self, cmd]
  end

  def view
    case @screen
    when SCREEN_MENU then @menu.view
    when SCREEN_FORM then @form.view
    when SCREEN_RESULT then render_result(@result)
    end
  end
end
```

---

## Best Practices

### Performance
- Keep `view` methods fast; avoid heavy computation
- Use commands for async operations (file I/O, network)
- Batch style creation; don't recreate styles every render
- Only re-render when state actually changes

### Testing
- Test `update` logic by calling with mock messages
- Verify state transitions independently from rendering
- Use Aruba gem for integration testing of complete CLI
- See `references/testing-tui-applications.md` for comprehensive patterns

### Error Handling
- Catch errors in commands and return error messages
- Display user-friendly error messages with styled output
- Provide clear feedback for invalid input in forms
- Use meaningful exit codes (0 success, non-zero errors)
- Send errors to stderr, output to stdout

### User Experience
- Support vim-style keys (j/k/h/l) alongside arrows
- Always show quit instructions (q or Ctrl+C)
- Use spinners for any operation over 100ms
- Provide progress feedback for long operations
- Show concise, meaningful output (avoid verbose confirmations)
- See `references/cli-ux-best-practices.md` for comprehensive UX patterns

### Accessibility
- Respect `NO_COLOR` environment variable
- Don't rely solely on color to convey meaning (use symbols too)
- Support `--no-color` flag for explicit control
- Use ANSI 16 colors for maximum terminal compatibility
- Provide JSON output mode for machine parsing
- See `references/accessibility-guidelines.md` for complete guidelines

---

## Distribution

Package your CLI as a Ruby gem for easy installation via RubyGems.org.

### Project Structure

```
my-cli/
├── Gemfile
├── my-cli.gemspec
├── bin/
│   └── my-cli          # Executable
├── lib/
│   ├── my_cli.rb       # Main entry
│   └── my_cli/
│       ├── version.rb
│       ├── cli.rb      # CLI class
│       └── model.rb    # Bubble Tea model
└── README.md
```

### Gemspec Essentials

```ruby
Gem::Specification.new do |spec|
  spec.name          = "my-cli"
  spec.version       = MyCli::VERSION
  spec.authors       = ["Your Name"]
  spec.summary       = "A beautiful CLI tool"

  spec.executables   = ["my-cli"]
  spec.require_paths = ["lib"]

  spec.add_dependency "bubbletea"
  spec.add_dependency "lipgloss"
  spec.add_dependency "bubbles"

  spec.required_ruby_version = ">= 2.7.0"
end
```

For complete distribution guide, see `references/gem-distribution.md`.

---

## Examples

Working code examples are available in the `examples/` directory:

- `simple-counter.rb` - Minimal Bubble Tea application
- `interactive-form.rb` - Huh form with validation
- `styled-list.rb` - Lipgloss-styled selectable list
- `progress-spinner.rb` - Async operation with spinner feedback

---

## Additional Features

For advanced functionality, see the detailed reference guides:

- `references/ntcharts-visualization.md` - Terminal charts (sparklines, bar charts, line charts, heatmaps)
- `references/bubblezone-mouse.md` - Mouse event handling and clickable zones
- `references/harmonica-animation.md` - Spring physics animations with angular_frequency and damping_ratio

## UX, Accessibility, and Testing

For building production-quality CLI applications:

- `references/cli-ux-best-practices.md` - Comprehensive CLI UX patterns (errors, help, progress, colors)
- `references/accessibility-guidelines.md` - NO_COLOR support, screen readers, keyboard navigation
- `references/testing-tui-applications.md` - Unit testing models, integration testing with Aruba

---

## Resources

- [charm-ruby.dev](https://charm-ruby.dev) - Official documentation
- [marcoroth.dev/posts/glamorous-christmas](https://marcoroth.dev/posts/glamorous-christmas) - Comprehensive overview blog post
- [marcoroth/bubbletea-ruby](https://github.com/marcoroth/bubbletea-ruby) - Bubble Tea source
- [marcoroth/lipgloss-ruby](https://github.com/marcoroth/lipgloss-ruby) - Lipgloss source
- [charm.sh](https://charm.sh) - Original Go libraries documentation
