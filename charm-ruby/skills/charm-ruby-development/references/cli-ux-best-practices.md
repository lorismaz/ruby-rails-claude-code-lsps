# CLI UX Best Practices

This reference provides guidelines for creating command-line applications that are intuitive, accessible, and delightful to use.

---

## Core UX Principles

### Human-First Design

The terminal is a human interface first, machine interface second. Prioritize clarity and usability:

```ruby
# Bad: Cryptic output
puts "ERR_AUTH_FAIL_403"

# Good: Human-readable with context
puts "Authentication failed: Invalid API token"
puts "Run `my-cli auth login` to authenticate"
```

### Consistency with Terminal Conventions

Users expect standard behaviors:

- **Exit codes**: `0` for success, non-zero for errors
- **Streams**: `stdout` for output, `stderr` for errors and progress
- **Signals**: Handle `SIGINT` (Ctrl+C) gracefully
- **Flags**: Use `-h/--help`, `-v/--version`, `-q/--quiet`, `--verbose`

```ruby
# Handle graceful shutdown
trap("INT") do
  puts "\nOperation cancelled"
  exit(130)  # Standard exit code for SIGINT
end
```

### Speed and Responsiveness

Users perceive CLIs as fast. Meet expectations:

- **< 100ms**: Immediate feedback expected
- **100ms - 1s**: Show spinner or progress indicator
- **> 1s**: Show progress bar with ETA if possible

```ruby
# For operations over 100ms
Gum.spin(title: "Fetching data...") do
  fetch_data
end
```

---

## Information Density

### Meaningful Output

Every line should add value. Avoid verbose congratulations or unnecessary confirmation:

```ruby
# Bad: Too verbose
puts "Starting operation..."
puts "Operation started successfully!"
puts "Processing items..."
puts "Items processed successfully!"
puts "Congratulations! Everything worked!"

# Good: Concise and informative
puts "Processed 42 items in 1.2s"
```

### Progressive Disclosure

Show essential info by default, details on request:

```ruby
# Default: Summary
puts "Build completed with 3 warnings"

# With --verbose: Full details
if verbose?
  warnings.each { |w| puts "  #{w.file}:#{w.line}: #{w.message}" }
end
```

---

## Error Handling

### Clear, Actionable Errors

Errors should tell users what happened, why, and how to fix it:

```ruby
class AppError < StandardError
  attr_reader :hint, :exit_code

  def initialize(message, hint: nil, exit_code: 1)
    super(message)
    @hint = hint
    @exit_code = exit_code
  end
end

def handle_error(error)
  style = Lipgloss::Style.new.foreground("#FF0000").bold(true)
  hint_style = Lipgloss::Style.new.foreground("#888888").italic(true)

  $stderr.puts style.render("Error: #{error.message}")
  $stderr.puts hint_style.render("Hint: #{error.hint}") if error.hint
  exit(error.exit_code)
end

# Usage
raise AppError.new(
  "Config file not found: ~/.myapp/config.yml",
  hint: "Run `myapp init` to create a default configuration"
)
```

### Error Categories

Use consistent exit codes by category:

| Exit Code | Category | Example |
|-----------|----------|---------|
| 0 | Success | Command completed |
| 1 | General error | Unknown error |
| 2 | Usage error | Invalid arguments |
| 64 | Input error | Malformed input file |
| 65 | Data error | Invalid data format |
| 66 | No input | File not found |
| 130 | SIGINT | User pressed Ctrl+C |

---

## Help System Design

### Multi-Level Help

Provide help at different detail levels:

```ruby
# Short help (shown on error or -h)
def short_help
  <<~HELP
    Usage: myapp <command> [options]

    Commands:
      init      Create new project
      build     Build the project
      deploy    Deploy to production

    Run 'myapp <command> --help' for command-specific help.
  HELP
end

# Detailed help (shown on --help)
def detailed_help(command)
  case command
  when "build"
    <<~HELP
      Usage: myapp build [options] [target]

      Build the project for deployment.

      Options:
        -o, --output DIR    Output directory (default: ./dist)
        -w, --watch         Watch for changes
        --minify            Minify output files
        --sourcemaps        Generate source maps

      Examples:
        myapp build                    # Build with defaults
        myapp build --watch            # Build and watch
        myapp build -o ./public        # Custom output dir
    HELP
  end
end
```

### Examples Are Essential

Always include practical examples in help text:

```ruby
# Show common use cases
Examples:
  # Basic usage
  myapp fetch https://api.example.com/data

  # With authentication
  myapp fetch --auth token123 https://api.example.com/data

  # Output to file
  myapp fetch https://api.example.com/data > output.json
```

---

## Progress Indicators

### Spinner for Indeterminate Progress

When you don't know how long an operation will take:

```ruby
spinner = Bubbles::Spinner.new
spinner.style = :dots  # Clean, professional

# Show context with spinner
def view
  if @loading
    "#{@spinner.view} Connecting to server..."
  else
    "Connected!"
  end
end
```

### Progress Bar for Known Progress

When you can measure progress:

```ruby
progress = Bubbles::Progress.new
progress.total = files.count

files.each_with_index do |file, i|
  process(file)
  progress.current = i + 1
  # Shows: [████████░░░░░░░░] 50% (25/50 files)
end
```

### X of Y Pattern

For batch operations, show position in sequence:

```ruby
items.each_with_index do |item, i|
  puts "[#{i + 1}/#{items.count}] Processing #{item.name}"
  process(item)
end
```

---

## Keyboard Navigation

### Vim-Style Bindings

Support both arrow keys and vim-style navigation:

```ruby
def update(msg)
  case msg
  when Bubbletea::KeyMsg
    case msg.string
    # Arrow keys
    when "up" then move_up
    when "down" then move_down
    when "left" then move_left
    when "right" then move_right
    # Vim keys
    when "k" then move_up
    when "j" then move_down
    when "h" then move_left
    when "l" then move_right
    # Common shortcuts
    when "g" then jump_to_start
    when "G" then jump_to_end
    when "/" then enter_search_mode
    when "q", "ctrl+c" then [self, Bubbletea.quit]
    end
  end
  [self, nil]
end
```

### Always Show Controls

Display available actions at the bottom of interactive UIs:

```ruby
def view
  content = render_main_content

  help_style = Lipgloss::Style.new.foreground("#888888")
  controls = help_style.render("↑/k up • ↓/j down • enter select • q quit")

  "#{content}\n\n#{controls}"
end
```

---

## Color and Styling Guidelines

### Semantic Colors

Use colors consistently for meaning:

```ruby
COLORS = {
  success: "#00FF00",
  error: "#FF0000",
  warning: "#FFAA00",
  info: "#00AAFF",
  muted: "#888888"
}

def success(msg)
  Lipgloss::Style.new.foreground(COLORS[:success]).render("✓ #{msg}")
end

def error(msg)
  Lipgloss::Style.new.foreground(COLORS[:error]).render("✗ #{msg}")
end

def warning(msg)
  Lipgloss::Style.new.foreground(COLORS[:warning]).render("⚠ #{msg}")
end
```

### Adaptive Colors

Support both light and dark terminal themes:

```ruby
# Automatically adjusts based on terminal background
text_color = Lipgloss.adaptive_color("#000000", "#FFFFFF")
style = Lipgloss::Style.new.foreground(text_color)
```

### Graceful Degradation

Handle terminals with limited color support:

```ruby
# Lipgloss automatically adapts to terminal capabilities:
# - True Color (24-bit): Full hex colors
# - ANSI 256: Closest match from 256 palette
# - ANSI 16: Basic colors only
# - No color: Plain text
```

---

## Confirmation Patterns

### Destructive Actions

Always confirm destructive operations:

```ruby
def delete_all
  if Gum.confirm("Delete all 47 files? This cannot be undone.")
    files.each(&:delete)
    puts success("Deleted 47 files")
  else
    puts "Operation cancelled"
  end
end
```

### Dry Run Support

Provide preview mode for risky operations:

```ruby
# --dry-run shows what would happen without doing it
if dry_run?
  puts "Would delete:"
  files.each { |f| puts "  #{f}" }
  puts "\nRun without --dry-run to execute"
else
  files.each(&:delete)
end
```

---

## Terminal Size Handling

### Responsive Layouts

Adapt to terminal dimensions:

```ruby
def view
  width = Bubbletea.term_width
  height = Bubbletea.term_height

  if width < 80
    render_compact_view
  else
    render_full_view
  end
end
```

### Minimum Size Requirements

Gracefully handle small terminals:

```ruby
def view
  width = Bubbletea.term_width

  if width < 40
    "Terminal too narrow. Please resize to at least 40 columns."
  else
    render_content
  end
end
```

---

## Resources

- [Command Line Interface Guidelines](https://clig.dev/)
- [12 Factor CLI Apps](https://medium.com/@jdxcode/12-factor-cli-apps-dd3c227a0e46)
- [GNU Coding Standards](https://www.gnu.org/prep/standards/standards.html#Command_002dLine-Interfaces)
