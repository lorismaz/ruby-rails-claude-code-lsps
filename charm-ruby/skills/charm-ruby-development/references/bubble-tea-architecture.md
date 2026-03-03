# Bubble Tea Architecture Reference

## The Model-View-Update Pattern

Bubble Tea implements the Elm architecture, creating a unidirectional data flow:

```
User Input → Message → Update → New Model → View → Terminal Output
                ↑                              |
                └──────── Commands ────────────┘
```

## Core Components

### Model

The Model holds all application state. It must include `Bubbletea::Model` and implement three methods:

```ruby
class MyModel
  include Bubbletea::Model

  attr_reader :items, :cursor, :selected

  def initialize
    @items = []
    @cursor = 0
    @selected = Set.new
    @loading = false
    @error = nil
  end

  def init
    # Called once at startup
    # Return a Command or nil
    load_items_cmd
  end

  def update(msg)
    # Handle messages, return [new_model, command]
    # ...
    [self, nil]
  end

  def view
    # Return string to display
    # ...
  end
end
```

### Messages

Messages are events that trigger state updates:

```ruby
# Built-in messages
Bubbletea::KeyMsg        # Keyboard input
Bubbletea::MouseMsg      # Mouse events
Bubbletea::WindowSizeMsg # Terminal resize

# Custom messages (use Struct or class)
LoadedItemsMsg = Struct.new(:items)
ErrorMsg = Struct.new(:error)
TickMsg = Struct.new(:time)
```

### Commands

Commands are functions that perform side effects and return messages:

```ruby
# Simple command returning a message
def load_items_cmd
  Bubbletea.cmd do
    items = fetch_items_from_api
    LoadedItemsMsg.new(items)
  rescue => e
    ErrorMsg.new(e.message)
  end
end

# Batch multiple commands
Bubbletea.batch(
  load_items_cmd,
  start_timer_cmd
)

# Quit command
Bubbletea.quit

# No-op (nil is also valid)
Bubbletea.none
```

## Handling Input

### Keyboard Input

```ruby
def update(msg)
  case msg
  when Bubbletea::KeyMsg
    handle_key(msg)
  else
    [self, nil]
  end
end

def handle_key(msg)
  case msg.string
  # Movement
  when "up", "k"
    @cursor = [@cursor - 1, 0].max
  when "down", "j"
    @cursor = [@cursor + 1, @items.length - 1].min
  when "g"
    @cursor = 0  # Go to top
  when "G"
    @cursor = @items.length - 1  # Go to bottom

  # Actions
  when "enter"
    return [self, select_item_cmd(@items[@cursor])]
  when " "  # Space
    toggle_selection(@cursor)

  # Quit
  when "q", "esc"
    return [self, Bubbletea.quit]
  when "ctrl+c"
    return [self, Bubbletea.quit]
  end

  [self, nil]
end
```

### Mouse Input

```ruby
def update(msg)
  case msg
  when Bubbletea::MouseMsg
    if msg.button == :left && msg.action == :press
      # msg.x and msg.y contain coordinates
      handle_click(msg.x, msg.y)
    elsif msg.action == :wheel_up
      scroll_up
    elsif msg.action == :wheel_down
      scroll_down
    end
  end
  [self, nil]
end
```

### Window Resize

```ruby
def update(msg)
  case msg
  when Bubbletea::WindowSizeMsg
    @width = msg.width
    @height = msg.height
    recalculate_layout
  end
  [self, nil]
end
```

## State Management Patterns

### Immutable Updates

Prefer returning new state rather than mutating:

```ruby
# Good: Create new state
def update(msg)
  new_items = @items + [msg.item]
  new_model = self.class.new
  new_model.instance_variable_set(:@items, new_items)
  [new_model, nil]
end

# Also acceptable: Mutate and return self
def update(msg)
  @items << msg.item
  [self, nil]
end
```

### Derived State

Calculate derived values in `view`, not `update`:

```ruby
def view
  # Calculate here, not stored in model
  visible_items = @items[@offset, @page_size]
  total_pages = (@items.length / @page_size.to_f).ceil
  current_page = @offset / @page_size + 1

  render_list(visible_items, current_page, total_pages)
end
```

### State Machines

Use explicit states for complex flows:

```ruby
class WizardModel
  STATES = [:welcome, :input_name, :input_email, :confirm, :complete]

  def initialize
    @state = :welcome
    @data = {}
  end

  def update(msg)
    case @state
    when :welcome
      if msg.is_a?(Bubbletea::KeyMsg) && msg.string == "enter"
        @state = :input_name
      end
    when :input_name
      if msg.is_a?(NameSubmittedMsg)
        @data[:name] = msg.name
        @state = :input_email
      end
    # ... etc
    end
    [self, nil]
  end
end
```

## Async Operations

### Long-Running Tasks

Use commands for operations that take time:

```ruby
def fetch_data_cmd
  Bubbletea.cmd do
    # This runs in a separate fiber/thread
    response = HTTP.get("https://api.example.com/data")
    DataLoadedMsg.new(JSON.parse(response.body))
  rescue => e
    ErrorMsg.new(e.message)
  end
end

def update(msg)
  case msg
  when Bubbletea::KeyMsg
    if msg.string == "r"  # Refresh
      @loading = true
      return [self, fetch_data_cmd]
    end
  when DataLoadedMsg
    @loading = false
    @data = msg.data
  when ErrorMsg
    @loading = false
    @error = msg.error
  end
  [self, nil]
end
```

### Timers and Ticks

Create periodic updates:

```ruby
def tick_cmd(interval = 0.1)
  Bubbletea.tick(interval) do |time|
    TickMsg.new(time)
  end
end

def update(msg)
  case msg
  when TickMsg
    @frame = (@frame + 1) % @animation_frames.length
    return [self, tick_cmd]  # Schedule next tick
  end
  [self, nil]
end

def init
  tick_cmd  # Start the tick loop
end
```

## Composing Models

### Sub-Models

Break complex UIs into composable pieces:

```ruby
class AppModel
  def initialize
    @header = HeaderModel.new
    @sidebar = SidebarModel.new
    @content = ContentModel.new
    @focus = :content
  end

  def update(msg)
    # Route to focused sub-model
    case @focus
    when :sidebar
      @sidebar, cmd = @sidebar.update(msg)
    when :content
      @content, cmd = @content.update(msg)
    end

    # Handle navigation between sections
    if msg.is_a?(Bubbletea::KeyMsg) && msg.string == "tab"
      @focus = next_focus(@focus)
    end

    [self, cmd]
  end

  def view
    [
      @header.view,
      horizontal_join(@sidebar.view, @content.view),
      footer_view
    ].join("\n")
  end
end
```

### Message Routing

Forward messages to sub-models with context:

```ruby
# Wrap sub-model messages
SidebarMsg = Struct.new(:inner_msg)
ContentMsg = Struct.new(:inner_msg)

def update(msg)
  case msg
  when SidebarMsg
    @sidebar, cmd = @sidebar.update(msg.inner_msg)
    # Wrap any returned command
    cmd = wrap_cmd(cmd, SidebarMsg) if cmd
  when ContentMsg
    @content, cmd = @content.update(msg.inner_msg)
    cmd = wrap_cmd(cmd, ContentMsg) if cmd
  end
  [self, cmd]
end
```

## Program Options

### Running the Application

```ruby
# Basic run
Bubbletea.run(MyModel.new)

# With options
Bubbletea.run(MyModel.new,
  alt_screen: true,      # Use alternate screen buffer
  mouse: true,           # Enable mouse support
  bracketed_paste: true  # Handle paste events
)

# Run and get final model
final_model = Bubbletea.run(MyModel.new)
puts "Final count: #{final_model.count}"
```

### Alternate Screen

Use alternate screen for full-screen apps:

```ruby
# Switches to alternate buffer, clears screen
# Restores original screen on exit
Bubbletea.run(model, alt_screen: true)
```

## Error Handling

### Graceful Degradation

```ruby
def update(msg)
  case msg
  when ErrorMsg
    @error = msg.error
    @loading = false
    # Don't quit, show error in UI
  end
  [self, nil]
end

def view
  if @error
    error_style.render("Error: #{@error}\nPress r to retry, q to quit")
  else
    normal_view
  end
end
```

### Recovery Commands

```ruby
def retry_cmd
  Bubbletea.cmd do
    sleep 1  # Brief delay before retry
    RetryMsg.new
  end
end

def update(msg)
  case msg
  when ErrorMsg
    @error = msg.error
    @retry_count += 1
    if @retry_count < 3
      return [self, retry_cmd]
    end
  when RetryMsg
    return [self, fetch_data_cmd]
  end
  [self, nil]
end
```

## Testing

### Unit Testing Update Logic

```ruby
require "minitest/autorun"

class TestMyModel < Minitest::Test
  def test_increment
    model = MyModel.new
    model.instance_variable_set(:@count, 5)

    key_msg = Bubbletea::KeyMsg.new("up")
    new_model, _cmd = model.update(key_msg)

    assert_equal 6, new_model.instance_variable_get(:@count)
  end

  def test_quit_returns_quit_cmd
    model = MyModel.new
    key_msg = Bubbletea::KeyMsg.new("q")

    _model, cmd = model.update(key_msg)

    assert_equal Bubbletea.quit, cmd
  end
end
```

### Testing View Output

```ruby
def test_view_shows_count
  model = MyModel.new
  model.instance_variable_set(:@count, 42)

  output = model.view

  assert_includes output, "42"
  assert_includes output, "Press"
end
```
