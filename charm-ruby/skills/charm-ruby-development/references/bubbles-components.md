# Bubbles Components Reference

## Overview

Bubbles provides pre-built, reusable components for Bubble Tea applications. Each component manages its own state and integrates via the standard `update`/`view` pattern.

## Component Integration Pattern

All Bubbles components follow this pattern:

```ruby
class MyModel
  include Bubbletea::Model

  def initialize
    @component = Bubbles::SomeComponent.new
  end

  def init
    @component.init  # Some components need initialization
  end

  def update(msg)
    # Forward messages to component
    @component, cmd = @component.update(msg)
    [self, cmd]
  end

  def view
    @component.view
  end
end
```

## Spinner

Animated loading indicator with multiple styles.

### Basic Usage

```ruby
require "bubbles"

class LoadingModel
  include Bubbletea::Model

  def initialize
    @spinner = Bubbles::Spinner.new
    @loading = true
  end

  def init
    @spinner.tick  # Start animation
  end

  def update(msg)
    return [self, Bubbletea.quit] if done_loading?

    @spinner, cmd = @spinner.update(msg)
    [self, cmd]
  end

  def view
    "#{@spinner.view} Loading..."
  end
end
```

### Spinner Styles

```ruby
@spinner.style = :line      # |/-\
@spinner.style = :dots      # ⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏
@spinner.style = :minidots  # ⠁⠂⠄⡀⢀⠠⠐⠈
@spinner.style = :jump      # ⢄⢂⢁⡁⡈⡐⡠
@spinner.style = :pulse     # ░▒▓█▓▒░
@spinner.style = :points    # ∙∙∙●∙∙
@spinner.style = :globe     # 🌍🌎🌏
@spinner.style = :moon      # 🌑🌒🌓🌔🌕🌖🌗🌘
@spinner.style = :monkey    # 🙈🙉🙊
@spinner.style = :meter     # ▱▰▱▱▱▱▱ cycling

# Custom spinner frames
@spinner.frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
@spinner.fps = 10  # Frames per second
```

### Styling Spinner Output

```ruby
@spinner.style = :dots
@spinner.spinner_style = Lipgloss::Style.new.foreground("#FF69B4")
```

## TextInput

Single-line text input with cursor.

### Basic Usage

```ruby
class FormModel
  include Bubbletea::Model

  def initialize
    @input = Bubbles::TextInput.new
    @input.placeholder = "Enter your name..."
    @input.focus  # Give focus to enable input
  end

  def init
    Bubbletea.blink  # Enable cursor blinking
  end

  def update(msg)
    case msg
    when Bubbletea::KeyMsg
      return [self, Bubbletea.quit] if msg.string == "enter"
    end

    @input, cmd = @input.update(msg)
    [self, cmd]
  end

  def view
    "Name: #{@input.view}\n\nPress Enter to submit"
  end

  def value
    @input.value
  end
end
```

### TextInput Options

```ruby
@input = Bubbles::TextInput.new

# Placeholder (shown when empty)
@input.placeholder = "Type here..."

# Initial value
@input.value = "Default text"

# Character limit
@input.char_limit = 50

# Width in characters
@input.width = 40

# Password mode (hide input)
@input.echo_mode = :password    # Shows ••••
@input.echo_mode = :none        # Shows nothing
@input.echo_mode = :normal      # Default, shows text

# Styling
@input.prompt = "> "
@input.prompt_style = Lipgloss::Style.new.foreground("#888888")
@input.text_style = Lipgloss::Style.new.foreground("#FFFFFF")
@input.placeholder_style = Lipgloss::Style.new.foreground("#555555")
@input.cursor_style = Lipgloss::Style.new.background("#FFFFFF")

# Focus handling
@input.focus    # Enable input
@input.blur     # Disable input
@input.focused? # Check if focused
```

### Validation

```ruby
def update(msg)
  case msg
  when Bubbletea::KeyMsg
    if msg.string == "enter"
      if valid_email?(@input.value)
        # Submit
      else
        @error = "Invalid email format"
      end
    end
  end

  @input, cmd = @input.update(msg)
  [self, cmd]
end

def valid_email?(value)
  value.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
end
```

## TextArea

Multi-line text editing.

### Basic Usage

```ruby
class EditorModel
  include Bubbletea::Model

  def initialize
    @textarea = Bubbles::TextArea.new
    @textarea.placeholder = "Enter your message..."
    @textarea.focus
  end

  def update(msg)
    case msg
    when Bubbletea::KeyMsg
      return [self, Bubbletea.quit] if msg.string == "ctrl+d"
    end

    @textarea, cmd = @textarea.update(msg)
    [self, cmd]
  end

  def view
    header = "Message (Ctrl+D to submit):\n\n"
    header + @textarea.view
  end
end
```

### TextArea Options

```ruby
@textarea = Bubbles::TextArea.new

# Dimensions
@textarea.width = 60
@textarea.height = 10

# Character/line limits
@textarea.char_limit = 500
@textarea.max_height = 20

# Initial value
@textarea.value = "Starting text..."

# Line numbers
@textarea.show_line_numbers = true
@textarea.line_number_style = Lipgloss::Style.new.foreground("#666666")

# Styling
@textarea.prompt = "│ "
@textarea.cursor_style = Lipgloss::Style.new.background("#FFFFFF")
```

## List

Scrollable, selectable item list.

### Basic Usage

```ruby
class ListModel
  include Bubbletea::Model

  def initialize(items)
    @list = Bubbles::List.new(items)
    @list.title = "Select an item"
  end

  def update(msg)
    case msg
    when Bubbletea::KeyMsg
      case msg.string
      when "q"
        return [self, Bubbletea.quit]
      when "enter"
        @selected = @list.selected_item
        return [self, Bubbletea.quit]
      end
    end

    @list, cmd = @list.update(msg)
    [self, cmd]
  end

  def view
    @list.view
  end
end

# Items can be strings or objects with `title` and `description` methods
items = [
  "Simple string item",
  ListItem.new("Item with details", "Additional description")
]
```

### List Options

```ruby
@list = Bubbles::List.new(items)

# Title and styling
@list.title = "Choose wisely"
@list.title_style = Lipgloss::Style.new.bold(true)

# Dimensions
@list.width = 40
@list.height = 15

# Filtering (type to filter)
@list.filter_enabled = true
@list.filter_prompt = "Filter: "

# Selection indicator
@list.show_selected = true
@list.selected_style = Lipgloss::Style.new.foreground("#FF69B4").bold(true)

# Cursor style
@list.cursor = "→ "
@list.cursor_style = Lipgloss::Style.new.foreground("#FF69B4")

# Pagination
@list.show_pagination = true
@list.pagination_style = Lipgloss::Style.new.foreground("#666666")

# Status bar
@list.show_status_bar = true
@list.status_bar_style = Lipgloss::Style.new.background("#333333")
```

### Custom List Items

```ruby
class TodoItem
  attr_reader :title, :description, :done

  def initialize(title, description, done: false)
    @title = title
    @description = description
    @done = done
  end

  # Required by Bubbles::List
  def filter_value
    "#{title} #{description}"
  end
end

items = [
  TodoItem.new("Buy groceries", "Milk, eggs, bread"),
  TodoItem.new("Call mom", "Wish her happy birthday"),
  TodoItem.new("Fix bug", "Issue #123 in production")
]

@list = Bubbles::List.new(items)
```

## Table

Formatted data tables.

### Basic Usage

```ruby
class TableModel
  include Bubbletea::Model

  def initialize
    @table = Bubbles::Table.new
    @table.columns = ["Name", "Age", "City"]
    @table.rows = [
      ["Alice", "30", "New York"],
      ["Bob", "25", "San Francisco"],
      ["Charlie", "35", "Chicago"]
    ]
  end

  def update(msg)
    case msg
    when Bubbletea::KeyMsg
      return [self, Bubbletea.quit] if msg.string == "q"
    end

    @table, cmd = @table.update(msg)
    [self, cmd]
  end

  def view
    @table.view
  end
end
```

### Table Options

```ruby
@table = Bubbles::Table.new

# Column definitions with widths
@table.columns = [
  Bubbles::Column.new("Name", width: 20),
  Bubbles::Column.new("Age", width: 5),
  Bubbles::Column.new("City", width: 15)
]

# Row selection
@table.focused = true
@table.selected_style = Lipgloss::Style.new.background("#333333")

# Border style
@table.border = :rounded
@table.border_style = Lipgloss::Style.new.foreground("#444444")

# Header styling
@table.header_style = Lipgloss::Style.new
  .bold(true)
  .foreground("#FFFFFF")
  .background("#7D56F4")

# Cell styling
@table.cell_style = Lipgloss::Style.new.padding(0, 1)

# Alternating rows
@table.styles = {
  even_row: Lipgloss::Style.new.background("#1a1a2e"),
  odd_row: Lipgloss::Style.new.background("#0f0f1a")
}
```

### Navigable Table

```ruby
def update(msg)
  case msg
  when Bubbletea::KeyMsg
    case msg.string
    when "enter"
      row = @table.selected_row
      handle_selection(row)
    end
  end

  @table, cmd = @table.update(msg)
  [self, cmd]
end
```

## Progress

Progress bar for showing completion.

### Basic Usage

```ruby
class DownloadModel
  include Bubbletea::Model

  def initialize
    @progress = Bubbles::Progress.new
    @percent = 0.0
  end

  def update(msg)
    case msg
    when ProgressMsg
      @percent = msg.percent
      if @percent >= 1.0
        return [self, Bubbletea.quit]
      end
    end

    @progress, cmd = @progress.update(msg)
    [self, cmd]
  end

  def view
    @progress.view_as(@percent) + "\n\n#{(@percent * 100).round}% complete"
  end
end
```

### Progress Options

```ruby
@progress = Bubbles::Progress.new

# Dimensions
@progress.width = 40

# Colors
@progress.full_color = "#00FF00"      # Completed portion
@progress.empty_color = "#333333"     # Remaining portion

# Gradient (alternative to solid color)
@progress.gradient_colors = ["#FF0000", "#FFFF00", "#00FF00"]

# Characters
@progress.full_char = "█"
@progress.empty_char = "░"

# Percentage display
@progress.show_percentage = true
@progress.percentage_style = Lipgloss::Style.new.foreground("#888888")
```

### Animated Progress

```ruby
def simulate_progress_cmd
  Bubbletea.tick(0.1) do |_time|
    ProgressMsg.new(@percent + 0.05)
  end
end

def update(msg)
  case msg
  when ProgressMsg
    @percent = [msg.percent, 1.0].min
    return [self, simulate_progress_cmd] if @percent < 1.0
  end
  [self, nil]
end
```

## Viewport

Scrollable content area for long text.

### Basic Usage

```ruby
class DocModel
  include Bubbletea::Model

  def initialize(content)
    @viewport = Bubbles::Viewport.new
    @viewport.content = content
    @viewport.width = 80
    @viewport.height = 20
  end

  def update(msg)
    case msg
    when Bubbletea::KeyMsg
      return [self, Bubbletea.quit] if msg.string == "q"
    end

    @viewport, cmd = @viewport.update(msg)
    [self, cmd]
  end

  def view
    header = "Documentation (q to quit)\n\n"
    footer = "\n\n#{scroll_percent}%"
    header + @viewport.view + footer
  end

  def scroll_percent
    @viewport.scroll_percent.round
  end
end
```

### Viewport Options

```ruby
@viewport = Bubbles::Viewport.new

# Dimensions (required)
@viewport.width = 80
@viewport.height = 20

# Content
@viewport.content = long_text
@viewport.set_content(new_content)  # Replace content

# Scroll position
@viewport.goto_top
@viewport.goto_bottom
@viewport.line_up(5)
@viewport.line_down(5)
@viewport.half_page_up
@viewport.half_page_down

# Query position
@viewport.at_top?
@viewport.at_bottom?
@viewport.scroll_percent  # 0.0 to 100.0
@viewport.y_offset        # Current line offset

# Mouse scrolling
@viewport.mouse_wheel_enabled = true
@viewport.mouse_wheel_delta = 3  # Lines per wheel tick
```

### Viewport with Styled Content

```ruby
def render_content
  lines = @items.map.with_index do |item, i|
    style = i == @cursor ? @selected_style : @normal_style
    style.render(item)
  end
  lines.join("\n")
end

def update(msg)
  # Update cursor
  @viewport.content = render_content
  @viewport, cmd = @viewport.update(msg)
  [self, cmd]
end
```

## File Picker

Browse and select files.

### Basic Usage

```ruby
class FilePickerModel
  include Bubbletea::Model

  def initialize(start_dir = Dir.pwd)
    @picker = Bubbles::FilePicker.new(start_dir)
    @selected = nil
  end

  def update(msg)
    case msg
    when Bubbletea::KeyMsg
      case msg.string
      when "q"
        return [self, Bubbletea.quit]
      when "enter"
        if @picker.selected_file
          @selected = @picker.selected_file
          return [self, Bubbletea.quit]
        end
      end
    end

    @picker, cmd = @picker.update(msg)
    [self, cmd]
  end

  def view
    header = "Select a file (Enter to select, q to cancel)\n\n"
    header + @picker.view
  end
end
```

### File Picker Options

```ruby
@picker = Bubbles::FilePicker.new(start_dir)

# Filtering
@picker.allowed_types = [".rb", ".txt", ".md"]
@picker.show_hidden = false
@picker.dir_allowed = true  # Allow selecting directories

# Display
@picker.height = 15
@picker.file_style = Lipgloss::Style.new.foreground("#AAAAAA")
@picker.dir_style = Lipgloss::Style.new.foreground("#5555FF").bold(true)
@picker.selected_style = Lipgloss::Style.new.reverse(true)

# Icons
@picker.show_icons = true
@picker.file_icon = "📄"
@picker.dir_icon = "📁"
```

## Composing Multiple Components

### Form with Multiple Inputs

```ruby
class SignupForm
  include Bubbletea::Model

  def initialize
    @inputs = [
      Bubbles::TextInput.new.tap { |i| i.placeholder = "Username" },
      Bubbles::TextInput.new.tap { |i| i.placeholder = "Email" },
      Bubbles::TextInput.new.tap { |i|
        i.placeholder = "Password"
        i.echo_mode = :password
      }
    ]
    @focus_index = 0
    @inputs[@focus_index].focus
  end

  def update(msg)
    case msg
    when Bubbletea::KeyMsg
      case msg.string
      when "tab"
        @inputs[@focus_index].blur
        @focus_index = (@focus_index + 1) % @inputs.length
        @inputs[@focus_index].focus
        return [self, nil]
      when "shift+tab"
        @inputs[@focus_index].blur
        @focus_index = (@focus_index - 1) % @inputs.length
        @inputs[@focus_index].focus
        return [self, nil]
      when "enter"
        if @focus_index == @inputs.length - 1
          return [self, submit_cmd]
        else
          @inputs[@focus_index].blur
          @focus_index += 1
          @inputs[@focus_index].focus
          return [self, nil]
        end
      end
    end

    @inputs[@focus_index], cmd = @inputs[@focus_index].update(msg)
    [self, cmd]
  end

  def view
    labels = ["Username", "Email", "Password"]
    fields = @inputs.zip(labels).map do |input, label|
      "#{label}: #{input.view}"
    end
    fields.join("\n\n") + "\n\n(Tab to switch fields, Enter to submit)"
  end
end
```
