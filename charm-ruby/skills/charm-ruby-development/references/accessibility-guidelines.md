# Terminal Accessibility Guidelines

This reference covers best practices for building accessible CLI and TUI applications that work for all users.

---

## Color Accessibility

### Respect NO_COLOR

The `NO_COLOR` environment variable is a standard that users set when they want applications to disable color output. Always respect it:

```ruby
def color_enabled?
  !ENV.key?("NO_COLOR") && $stdout.tty?
end

def styled_output(text, style)
  if color_enabled?
    style.render(text)
  else
    text
  end
end
```

### Provide --no-color Flag

Also support explicit flag control:

```ruby
# Parse arguments
no_color = ARGV.include?("--no-color")

# Disable colors if flag present
Lipgloss.no_color = no_color if no_color
```

### ANSI vs True Color

Not all terminals support 24-bit (true color). Use adaptive colors that degrade gracefully:

```ruby
# Prefer ANSI 16 colors for maximum compatibility
# These work on virtually all terminals:
ANSI_COLORS = {
  black: "0",
  red: "1",
  green: "2",
  yellow: "3",
  blue: "4",
  magenta: "5",
  cyan: "6",
  white: "7"
}

# Lipgloss handles degradation automatically:
# True Color → ANSI 256 → ANSI 16 → No color

# For critical information, use ANSI 16 colors directly:
style = Lipgloss::Style.new.foreground("1")  # ANSI red
```

### Don't Rely Solely on Color

Color should enhance, not convey essential meaning alone:

```ruby
# Bad: Color is the only indicator
def status(success)
  color = success ? "#00FF00" : "#FF0000"
  Lipgloss::Style.new.foreground(color).render("●")
end

# Good: Symbol + color provides redundancy
def status(success)
  if success
    style = Lipgloss::Style.new.foreground("#00FF00")
    style.render("✓ Success")
  else
    style = Lipgloss::Style.new.foreground("#FF0000")
    style.render("✗ Failed")
  end
end
```

### High Contrast

Ensure sufficient contrast between foreground and background:

```ruby
# Good: High contrast combinations
Lipgloss::Style.new
  .foreground("#FFFFFF")  # White text
  .background("#000000")  # Black background

# Use adaptive colors for different themes
Lipgloss::Style.new
  .foreground(Lipgloss.adaptive_color("#000000", "#FFFFFF"))
```

---

## Screen Reader Compatibility

### Structured Output

Screen readers parse terminal output linearly. Structure output clearly:

```ruby
# Good: Clear sections with headers
def render_report(data)
  <<~REPORT
    === Build Report ===

    Status: #{data.status}
    Duration: #{data.duration}s
    Files: #{data.file_count}

    === Warnings ===
    #{data.warnings.map { |w| "• #{w}" }.join("\n")}

    === Next Steps ===
    #{data.next_steps.map { |s| "• #{s}" }.join("\n")}
  REPORT
end
```

### Avoid Decorative Characters

Excessive decoration interferes with screen readers:

```ruby
# Bad: Decorative noise
puts "╔════════════════════════════════╗"
puts "║     Welcome to My CLI!         ║"
puts "╚════════════════════════════════╝"

# Good: Simple, parseable output
puts "=== Welcome to My CLI ==="
puts ""
```

### Announce State Changes

When state changes in interactive apps, make it clear:

```ruby
def update(msg)
  case msg
  when SelectionChanged
    @selected = msg.item
    # Clear announcement for screen readers
    @announcement = "Selected: #{msg.item.name}"
  end
  [self, nil]
end

def view
  content = render_list
  # Include announcement in output
  announcement = @announcement ? "\n#{@announcement}" : ""
  "#{content}#{announcement}"
end
```

---

## Keyboard Navigation

### Full Keyboard Support

Every action should be achievable via keyboard:

```ruby
KEYBINDINGS = {
  "up" => :prev_item,      "k" => :prev_item,
  "down" => :next_item,    "j" => :next_item,
  "enter" => :select,      " " => :toggle,
  "tab" => :next_section,  "shift+tab" => :prev_section,
  "?" => :show_help,       "q" => :quit,
  "ctrl+c" => :quit
}

def update(msg)
  case msg
  when Bubbletea::KeyMsg
    action = KEYBINDINGS[msg.string]
    send(action) if action && respond_to?(action, true)
  end
  [self, nil]
end
```

### Focus Indicators

Make it clear which element has focus:

```ruby
def render_item(item, focused)
  if focused
    style = Lipgloss::Style.new
      .foreground("#FFFFFF")
      .background("#7D56F4")
      .bold(true)
    style.render("> #{item.name}")
  else
    "  #{item.name}"
  end
end
```

### Skip Navigation

For long lists or complex UIs, provide shortcuts:

```ruby
# Jump to positions
when "g" then @cursor = 0              # Top
when "G" then @cursor = @items.length - 1  # Bottom
when "ctrl+d" then @cursor += 10       # Page down
when "ctrl+u" then @cursor -= 10       # Page up
```

---

## Alternative Output Modes

### Machine-Readable Output

Support JSON or structured output for scripts and assistive tools:

```ruby
if ENV["OUTPUT_FORMAT"] == "json"
  puts JSON.pretty_generate({
    status: "success",
    files_processed: 42,
    warnings: warnings
  })
else
  puts "Processed 42 files with #{warnings.count} warnings"
end
```

### Quiet Mode

Allow silencing non-essential output:

```ruby
def log(message, level: :info)
  return if @quiet && level != :error

  case level
  when :error then $stderr.puts "Error: #{message}"
  when :warn then puts "Warning: #{message}"
  else puts message
  end
end
```

### Verbose Mode

Provide detailed output when requested:

```ruby
def debug(message)
  puts "[DEBUG] #{message}" if @verbose
end
```

---

## Text and Typography

### Avoid Fancy Unicode

Not all terminals/fonts render Unicode equally:

```ruby
# Risky: May not render correctly
puts "→ Next step"
puts "★ Featured"
puts "◉ Selected"

# Safe: ASCII alternatives
puts "-> Next step"
puts "* Featured"
puts "[x] Selected"
```

### Configurable Symbols

Let users customize symbols:

```ruby
DEFAULT_SYMBOLS = {
  success: "✓",
  error: "✗",
  warning: "⚠",
  arrow: "→",
  bullet: "•"
}

ASCII_SYMBOLS = {
  success: "[ok]",
  error: "[ERR]",
  warning: "[!]",
  arrow: "->",
  bullet: "*"
}

def symbols
  @ascii_mode ? ASCII_SYMBOLS : DEFAULT_SYMBOLS
end
```

### Word Wrapping

Wrap long lines at word boundaries:

```ruby
def wrap_text(text, width)
  text.gsub(/(.{1,#{width}})(\s+|$)/, "\\1\n").strip
end

# Or use Lipgloss width constraints
style = Lipgloss::Style.new.width(60)
puts style.render(long_text)
```

---

## Animation and Motion

### Reduce Motion Option

Some users experience motion sensitivity:

```ruby
def animation_enabled?
  !ENV.key?("REDUCE_MOTION")
end

def spinner_view
  if animation_enabled?
    @spinner.view
  else
    "[loading]"  # Static alternative
  end
end
```

### Reasonable Animation Speed

Avoid flickering or rapid updates:

```ruby
# Spinner tick rate: ~100ms is comfortable
# Progress updates: No more than 10 per second
# Screen refreshes: Only when state changes

def update(msg)
  case msg
  when Bubbletea::TickMsg
    # Throttle updates
    return [self, nil] if (Time.now - @last_update) < 0.1
    @last_update = Time.now
    # ... update logic
  end
end
```

---

## Error Handling for Accessibility

### Descriptive Errors

Errors should be self-explanatory:

```ruby
# Bad
puts "Error: ENOENT"

# Good
puts "Error: File not found: /path/to/config.yml"
puts "Expected a configuration file at this location."
puts "Run 'myapp init' to create a default configuration."
```

### Error Placement

Send errors to stderr so they can be separated from output:

```ruby
def error(message)
  $stderr.puts "Error: #{message}"
end

def warn(message)
  $stderr.puts "Warning: #{message}"
end
```

### Exit Codes

Use meaningful exit codes for scripting:

```ruby
EXIT_SUCCESS = 0
EXIT_ERROR = 1
EXIT_USAGE = 2
EXIT_NOT_FOUND = 66

begin
  run_command
  exit(EXIT_SUCCESS)
rescue ArgumentError => e
  $stderr.puts "Invalid argument: #{e.message}"
  exit(EXIT_USAGE)
rescue FileNotFoundError => e
  $stderr.puts "File not found: #{e.message}"
  exit(EXIT_NOT_FOUND)
rescue => e
  $stderr.puts "Error: #{e.message}"
  exit(EXIT_ERROR)
end
```

---

## Testing Accessibility

### Checklist

Before release, verify:

- [ ] Works with `NO_COLOR=1`
- [ ] Works in 80-column terminal
- [ ] All actions have keyboard shortcuts
- [ ] Help text is comprehensive
- [ ] Error messages are descriptive
- [ ] Output makes sense without color
- [ ] Works with common screen readers
- [ ] JSON output mode available

### Automated Tests

```ruby
RSpec.describe "Accessibility" do
  it "respects NO_COLOR" do
    ENV["NO_COLOR"] = "1"
    output = capture_output { run_command }
    expect(output).not_to include("\e[")  # No ANSI codes
  end

  it "provides JSON output" do
    ENV["OUTPUT_FORMAT"] = "json"
    output = capture_output { run_command }
    expect { JSON.parse(output) }.not_to raise_error
  end

  it "handles narrow terminals" do
    ENV["COLUMNS"] = "40"
    output = capture_output { run_command }
    expect(output.lines.map(&:length).max).to be <= 40
  end
end
```

---

## Resources

- [NO_COLOR Standard](https://no-color.org/)
- [WCAG Guidelines](https://www.w3.org/WAI/standards-guidelines/wcag/)
- [Inclusive Design Principles](https://inclusivedesignprinciples.org/)
- [A11y Project](https://www.a11yproject.com/)
