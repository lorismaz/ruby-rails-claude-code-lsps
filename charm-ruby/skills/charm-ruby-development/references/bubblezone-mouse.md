# Bubblezone: Mouse Event Handling

Bubblezone enables mouse interaction in Bubble Tea applications by creating clickable zones in your terminal UI. It tracks mouse events and maps them to specific UI elements.

## Installation

```ruby
# Gemfile
gem "bubblezone"
```

## Core Concepts

Bubblezone works by:
1. **Marking zones**: Wrap UI elements with zone markers
2. **Tracking events**: Listen for mouse events in your model
3. **Checking bounds**: Determine which zone received a click

## Basic Usage

```ruby
require "bubbletea"
require "bubblezone"

class ClickableModel
  include Bubbletea::Model

  def initialize
    @zone = Bubblezone::Zone.new
    @clicked = nil
  end

  def init
    Bubbletea.enable_mouse  # Enable mouse tracking
  end

  def update(msg)
    case msg
    when Bubbletea::MouseMsg
      if @zone.in_bounds?("button1", msg)
        @clicked = "Button 1"
      elsif @zone.in_bounds?("button2", msg)
        @clicked = "Button 2"
      end
    when Bubbletea::KeyMsg
      return [self, Bubbletea.quit] if msg.string == "q"
    end
    [self, nil]
  end

  def view
    # Wrap clickable elements with zone.mark
    btn1 = @zone.mark("button1", "[ Click Me ]")
    btn2 = @zone.mark("button2", "[ Or Me ]")

    output = "#{btn1}  #{btn2}\n\n"
    output += "Clicked: #{@clicked || 'nothing'}\n"
    output += "\nPress q to quit"

    # Scan the output to register zone positions
    @zone.scan(output)
  end
end

Bubbletea.run(ClickableModel.new)
```

## Zone API

### Creating Zones

```ruby
zone = Bubblezone::Zone.new

# Mark a region with an ID
marked = zone.mark("unique-id", "content to make clickable")

# Mark with styling preserved
styled = Lipgloss::Style.new.bold(true).render("Styled Button")
marked = zone.mark("styled-btn", styled)
```

### Checking Bounds

```ruby
def update(msg)
  case msg
  when Bubbletea::MouseMsg
    # Check if click is within a zone
    if zone.in_bounds?("my-zone", msg)
      handle_click
    end

    # Get the zone ID at mouse position
    zone_id = zone.at(msg)
    if zone_id
      handle_zone_click(zone_id)
    end
  end
  [self, nil]
end
```

### Scanning Output

The `scan` method must be called on your final view output to register zone positions:

```ruby
def view
  output = build_ui_string
  @zone.scan(output)  # Returns the same string, registers positions
end
```

## Mouse Event Types

```ruby
def update(msg)
  case msg
  when Bubbletea::MouseMsg
    case msg.type
    when :press
      # Mouse button pressed
      handle_press(msg)
    when :release
      # Mouse button released
      handle_release(msg)
    when :motion
      # Mouse moved (with button held)
      handle_drag(msg)
    when :wheel_up
      handle_scroll_up
    when :wheel_down
      handle_scroll_down
    end

    # Mouse button information
    case msg.button
    when :left
      left_click(msg)
    when :right
      right_click(msg)
    when :middle
      middle_click(msg)
    end
  end
  [self, nil]
end
```

## Interactive List Example

Build a clickable list with hover highlighting:

```ruby
require "bubbletea"
require "bubblezone"
require "lipgloss"

class ClickableList
  include Bubbletea::Model

  ITEMS = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]

  def initialize
    @zone = Bubblezone::Zone.new
    @selected = nil
    @hovered = nil
    setup_styles
  end

  def init
    Bubbletea.enable_mouse
  end

  def update(msg)
    case msg
    when Bubbletea::MouseMsg
      ITEMS.each_with_index do |item, i|
        if @zone.in_bounds?("item-#{i}", msg)
          case msg.type
          when :press
            @selected = i
          when :motion
            @hovered = i
          end
        end
      end

      # Clear hover when mouse leaves items
      @hovered = nil unless ITEMS.any? { |_, i| @zone.in_bounds?("item-#{i}", msg) }

    when Bubbletea::KeyMsg
      return [self, Bubbletea.quit] if msg.string == "q"
    end
    [self, nil]
  end

  def view
    lines = [
      @title_style.render("Click an item:"),
      ""
    ]

    ITEMS.each_with_index do |item, i|
      style = if i == @selected
                @selected_style
              elsif i == @hovered
                @hover_style
              else
                @item_style
              end

      content = style.render("  #{item}  ")
      lines << @zone.mark("item-#{i}", content)
    end

    lines << ""
    lines << "Selected: #{@selected ? ITEMS[@selected] : 'none'}"
    lines << "\nPress q to quit"

    output = lines.join("\n")
    @zone.scan(output)
  end

  private

  def setup_styles
    @title_style = Lipgloss::Style.new
      .bold(true)
      .foreground("#FFFFFF")

    @item_style = Lipgloss::Style.new
      .foreground("#888888")

    @hover_style = Lipgloss::Style.new
      .foreground("#FFFFFF")
      .background("#333333")

    @selected_style = Lipgloss::Style.new
      .foreground("#FFFFFF")
      .background("#7D56F4")
      .bold(true)
  end
end

Bubbletea.run(ClickableList.new)
```

## Button Component

Create reusable clickable buttons:

```ruby
module Components
  class Button
    attr_reader :id, :label
    attr_accessor :pressed

    def initialize(id:, label:, zone:)
      @id = id
      @label = label
      @zone = zone
      @pressed = false
      setup_styles
    end

    def check_click(msg)
      @zone.in_bounds?(@id, msg)
    end

    def render
      style = @pressed ? @pressed_style : @normal_style
      content = style.render(" #{@label} ")
      @zone.mark(@id, content)
    end

    private

    def setup_styles
      @normal_style = Lipgloss::Style.new
        .foreground("#FFFFFF")
        .background("#7D56F4")
        .padding(0, 1)
        .border(:rounded)

      @pressed_style = Lipgloss::Style.new
        .foreground("#FFFFFF")
        .background("#5D36D4")
        .padding(0, 1)
        .border(:rounded)
    end
  end
end
```

Usage:

```ruby
class ButtonDemo
  include Bubbletea::Model

  def initialize
    @zone = Bubblezone::Zone.new
    @ok_btn = Components::Button.new(id: "ok", label: "OK", zone: @zone)
    @cancel_btn = Components::Button.new(id: "cancel", label: "Cancel", zone: @zone)
    @result = nil
  end

  def init
    Bubbletea.enable_mouse
  end

  def update(msg)
    case msg
    when Bubbletea::MouseMsg
      if msg.type == :press
        if @ok_btn.check_click(msg)
          @ok_btn.pressed = true
          @result = "OK clicked!"
        elsif @cancel_btn.check_click(msg)
          @cancel_btn.pressed = true
          @result = "Cancelled"
        end
      elsif msg.type == :release
        @ok_btn.pressed = false
        @cancel_btn.pressed = false
      end
    when Bubbletea::KeyMsg
      return [self, Bubbletea.quit] if msg.string == "q"
    end
    [self, nil]
  end

  def view
    buttons = "#{@ok_btn.render}  #{@cancel_btn.render}"
    output = "#{buttons}\n\n#{@result}\n\nPress q to quit"
    @zone.scan(output)
  end
end
```

## Tab Bar with Mouse

```ruby
class TabBar
  include Bubbletea::Model

  TABS = ["Home", "Settings", "Help"]

  def initialize
    @zone = Bubblezone::Zone.new
    @active_tab = 0
    setup_styles
  end

  def init
    Bubbletea.enable_mouse
  end

  def update(msg)
    case msg
    when Bubbletea::MouseMsg
      if msg.type == :press
        TABS.each_with_index do |_, i|
          @active_tab = i if @zone.in_bounds?("tab-#{i}", msg)
        end
      end
    when Bubbletea::KeyMsg
      case msg.string
      when "q" then return [self, Bubbletea.quit]
      when "left", "h" then @active_tab = [0, @active_tab - 1].max
      when "right", "l" then @active_tab = [@active_tab + 1, TABS.length - 1].min
      end
    end
    [self, nil]
  end

  def view
    tabs = TABS.map.with_index do |name, i|
      style = i == @active_tab ? @active_style : @inactive_style
      @zone.mark("tab-#{i}", style.render(" #{name} "))
    end

    tab_bar = tabs.join("")
    content = render_tab_content(@active_tab)

    output = "#{tab_bar}\n#{@border}\n#{content}\n\nClick tabs or use ←/→ • q to quit"
    @zone.scan(output)
  end

  private

  def render_tab_content(index)
    case index
    when 0 then "Welcome to the Home tab!"
    when 1 then "Settings would go here..."
    when 2 then "Help documentation..."
    end
  end

  def setup_styles
    @active_style = Lipgloss::Style.new
      .foreground("#FFFFFF")
      .background("#7D56F4")
      .bold(true)

    @inactive_style = Lipgloss::Style.new
      .foreground("#888888")
      .background("#333333")

    @border = "─" * 40
  end
end
```

## Best Practices

### Zone ID Naming

```ruby
# Good: descriptive, unique IDs
zone.mark("save-button", "Save")
zone.mark("item-0", items[0])
zone.mark("tab-settings", "Settings")

# Avoid: generic or duplicate IDs
zone.mark("btn", "Save")      # Not descriptive
zone.mark("item", item)       # Will conflict
```

### Performance

```ruby
# Create zone once, reuse
def initialize
  @zone = Bubblezone::Zone.new  # Single instance
end

# Scan only the final output
def view
  output = build_complex_ui
  @zone.scan(output)  # Scan once at the end
end
```

### Combining with Keyboard

```ruby
def update(msg)
  case msg
  when Bubbletea::MouseMsg
    handle_mouse(msg)
  when Bubbletea::KeyMsg
    # Always support keyboard alternatives
    case msg.string
    when "enter" then activate_focused_item
    when "j", "down" then focus_next
    when "k", "up" then focus_previous
    end
  end
  [self, nil]
end
```

### Accessibility

- Always provide keyboard alternatives to mouse actions
- Don't rely solely on hover states for information
- Consider users who can't use a mouse

## Disabling Mouse

```ruby
def cleanup
  Bubbletea.disable_mouse
end

# Or in update when quitting
def update(msg)
  if should_quit?(msg)
    return [self, Bubbletea.batch(
      Bubbletea.disable_mouse,
      Bubbletea.quit
    )]
  end
  [self, nil]
end
```

## Resources

- [bubblezone-ruby GitHub](https://github.com/marcoroth/bubblezone-ruby)
- [Original Go bubblezone](https://github.com/charmbracelet/zone)
