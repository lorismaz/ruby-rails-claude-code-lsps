# Lipgloss Styling Reference

## Overview

Lipgloss provides CSS-like styling for terminal output. Styles are created through method chaining and applied with `render`.

## Creating Styles

```ruby
require "lipgloss"

# Empty style
style = Lipgloss::Style.new

# Chained style
style = Lipgloss::Style.new
  .bold(true)
  .foreground("#FFFFFF")
  .background("#7D56F4")
  .padding(1, 2)

# Apply to text
output = style.render("Hello, World!")
```

## Colors

### Color Formats

```ruby
# Hex colors (true color)
style.foreground("#FF5733")
style.background("#1A1A2E")

# ANSI 256 colors (0-255)
style.foreground("201")  # Hot pink
style.background("236")  # Dark gray

# ANSI 16 basic colors
style.foreground("red")
style.foreground("bright-blue")
# Available: black, red, green, yellow, blue, magenta, cyan, white
# Bright variants: bright-black, bright-red, etc.

# No color (transparent)
style.foreground("")
```

### Adaptive Colors

Automatically adjust for light/dark terminal backgrounds:

```ruby
# Lipgloss.adaptive_color(light_bg_color, dark_bg_color)
text_color = Lipgloss.adaptive_color("#333333", "#EEEEEE")
style = Lipgloss::Style.new.foreground(text_color)
```

### Complete Colors

Define colors for all color profiles:

```ruby
color = Lipgloss.complete_color(
  true_color: "#FF5733",
  ansi256: "202",
  ansi: "red"
)
style.foreground(color)
```

## Text Formatting

### Font Styles

```ruby
style
  .bold(true)
  .italic(true)
  .underline(true)
  .strikethrough(true)
  .reverse(true)       # Swap foreground/background
  .blink(true)         # Terminal support varies
  .faint(true)         # Dimmed text
```

### Disabling Styles

```ruby
# Turn off inherited styles
style.bold(false)
style.underline(false)
```

## Spacing

### Padding

Space inside the border:

```ruby
# All sides
style.padding(2)

# Vertical, horizontal
style.padding(1, 2)

# Top, right, bottom, left
style.padding(1, 2, 1, 2)

# Individual sides
style.padding_top(1)
style.padding_right(2)
style.padding_bottom(1)
style.padding_left(2)
```

### Margin

Space outside the border:

```ruby
# All sides
style.margin(2)

# Vertical, horizontal
style.margin(1, 2)

# Top, right, bottom, left
style.margin(1, 2, 1, 2)

# Individual sides
style.margin_top(1)
style.margin_right(2)
style.margin_bottom(1)
style.margin_left(2)
```

## Dimensions

### Width and Height

```ruby
# Fixed width (pads with spaces if shorter)
style.width(40)

# Fixed height (pads with newlines if shorter)
style.height(10)

# Max width (truncates if longer)
style.max_width(80)

# Max height
style.max_height(20)
```

### Alignment

```ruby
# Horizontal alignment (requires width to be set)
style.width(40).align(:left)
style.width(40).align(:center)
style.width(40).align(:right)

# Vertical alignment (requires height to be set)
style.height(10).align_vertical(:top)
style.height(10).align_vertical(:middle)
style.height(10).align_vertical(:bottom)
```

## Borders

### Border Styles

```ruby
# Built-in styles
style.border(:normal)    # Single line
style.border(:rounded)   # Rounded corners
style.border(:double)    # Double line
style.border(:thick)     # Thick line
style.border(:hidden)    # Space reserved but invisible

# No border
style.border(:none)
```

### Border Sides

```ruby
# All sides
style.border(:rounded)

# Specific sides only
style.border(:rounded, true, false, true, false)  # top, right, bottom, left

# Individual methods
style.border_top(true)
style.border_right(false)
style.border_bottom(true)
style.border_left(false)
```

### Border Colors

```ruby
# All borders same color
style.border_foreground("#FF0000")
style.border_background("#000000")

# Different colors per side
style.border_top_foreground("#FF0000")
style.border_right_foreground("#00FF00")
style.border_bottom_foreground("#0000FF")
style.border_left_foreground("#FFFF00")
```

### Custom Borders

```ruby
custom_border = Lipgloss::Border.new(
  top: "─",
  bottom: "─",
  left: "│",
  right: "│",
  top_left: "╭",
  top_right: "╮",
  bottom_left: "╰",
  bottom_right: "╯"
)
style.border(custom_border)
```

## Layout Helpers

### Joining Text

```ruby
# Horizontal join
left = style1.render("Left")
right = style2.render("Right")
combined = Lipgloss.join_horizontal(:top, left, right)
combined = Lipgloss.join_horizontal(:center, left, right)
combined = Lipgloss.join_horizontal(:bottom, left, right)

# Vertical join
top = style1.render("Top")
bottom = style2.render("Bottom")
combined = Lipgloss.join_vertical(:left, top, bottom)
combined = Lipgloss.join_vertical(:center, top, bottom)
combined = Lipgloss.join_vertical(:right, top, bottom)
```

### Placing Text

```ruby
# Place text at specific position within a larger space
content = style.render("Content")
result = Lipgloss.place(
  80,           # width
  24,           # height
  :center,      # horizontal position
  :middle,      # vertical position
  content
)
```

## Tables

Lipgloss includes a table renderer:

```ruby
table = Lipgloss::Table.new do |t|
  t.headers = ["Name", "Age", "City"]
  t.rows = [
    ["Alice", "30", "New York"],
    ["Bob", "25", "San Francisco"],
    ["Charlie", "35", "Chicago"]
  ]

  # Styling
  t.border(:rounded)
  t.border_foreground("#888888")

  # Column widths
  t.width(60)

  # Header style
  t.header_style = Lipgloss::Style.new.bold(true).foreground("#FFFFFF")

  # Cell style
  t.cell_style = Lipgloss::Style.new.padding(0, 1)

  # Alternating row colors
  t.row_styles = [
    Lipgloss::Style.new.background("#1A1A2E"),
    Lipgloss::Style.new.background("#2A2A3E")
  ]
end

puts table.render
```

## Lists

```ruby
list = Lipgloss::List.new do |l|
  l.items = ["First item", "Second item", "Third item"]

  # Bullet style
  l.enumerator = "• "  # or "- ", "→ ", numbers, etc.

  # Item style
  l.item_style = Lipgloss::Style.new.foreground("#AAAAAA")

  # Nested lists
  l.items = [
    "Parent item",
    Lipgloss::List.new { |nested|
      nested.items = ["Child 1", "Child 2"]
      nested.enumerator = "  ◦ "
    }
  ]
end

puts list.render
```

## Trees

```ruby
tree = Lipgloss::Tree.new do |t|
  t.root = "Project"
  t.items = [
    "src/",
    Lipgloss::Tree.new { |sub|
      sub.root = "lib/"
      sub.items = ["main.rb", "utils.rb"]
    },
    "README.md",
    "Gemfile"
  ]

  # Branch characters
  t.enumerator = Lipgloss::TreeEnumerator.new(
    branch: "├── ",
    last_branch: "└── ",
    indent: "│   ",
    last_indent: "    "
  )
end

puts tree.render
```

## Style Inheritance

### Copying Styles

```ruby
base_style = Lipgloss::Style.new
  .foreground("#FFFFFF")
  .padding(1, 2)

# Copy and extend
highlight_style = base_style.copy
  .background("#FF0000")
  .bold(true)
```

### Unsetting Properties

```ruby
# Remove a property (inherit from parent or use default)
style.unset_foreground
style.unset_background
style.unset_padding
style.unset_border
```

## Common Patterns

### Status Indicators

```ruby
success_style = Lipgloss::Style.new
  .foreground("#00FF00")
  .bold(true)

error_style = Lipgloss::Style.new
  .foreground("#FF0000")
  .bold(true)

warning_style = Lipgloss::Style.new
  .foreground("#FFFF00")

info_style = Lipgloss::Style.new
  .foreground("#00FFFF")

def status_badge(type, text)
  case type
  when :success then success_style.render("✓ #{text}")
  when :error   then error_style.render("✗ #{text}")
  when :warning then warning_style.render("⚠ #{text}")
  when :info    then info_style.render("ℹ #{text}")
  end
end
```

### Panels and Boxes

```ruby
panel_style = Lipgloss::Style.new
  .border(:rounded)
  .border_foreground("#888888")
  .padding(1, 2)
  .margin(1)

title_style = Lipgloss::Style.new
  .bold(true)
  .foreground("#FFFFFF")
  .background("#7D56F4")
  .padding(0, 1)

def panel(title, content)
  header = title_style.render(title)
  body = panel_style.render(content)
  Lipgloss.join_vertical(:left, header, body)
end
```

### Responsive Width

```ruby
def responsive_style(terminal_width)
  Lipgloss::Style.new
    .width([terminal_width - 4, 80].min)
    .padding(1, 2)
end
```

### Progress Bar

```ruby
def progress_bar(percent, width = 40)
  filled = (width * percent / 100.0).round
  empty = width - filled

  filled_style = Lipgloss::Style.new.background("#00FF00")
  empty_style = Lipgloss::Style.new.background("#333333")

  bar = filled_style.render(" " * filled) + empty_style.render(" " * empty)
  "#{bar} #{percent}%"
end
```

## Performance Tips

1. **Reuse styles**: Create styles once, reuse in `view`
2. **Avoid in loops**: Don't create new styles inside render loops
3. **Cache dimensions**: Store terminal width, don't recalculate every frame
4. **Minimize nesting**: Deep style nesting can slow rendering

```ruby
class MyModel
  def initialize
    # Create styles once
    @title_style = Lipgloss::Style.new.bold(true).foreground("#FFFFFF")
    @item_style = Lipgloss::Style.new.foreground("#AAAAAA")
    @selected_style = @item_style.copy.reverse(true)
  end

  def view
    # Reuse pre-created styles
    lines = @items.map.with_index do |item, i|
      style = i == @cursor ? @selected_style : @item_style
      style.render(item)
    end
    lines.join("\n")
  end
end
```
