# Harmonica: Physics-Based Animations

Harmonica provides spring physics animations for Bubble Tea applications. Create smooth, natural-feeling transitions and animations using spring dynamics.

## Installation

```ruby
# Gemfile
gem "harmonica"
```

## Core Concepts

Harmonica simulates spring physics with two key parameters:

- **Angular Frequency (ω)**: Controls animation speed. Higher values = faster springs
- **Damping Ratio (ζ)**: Controls oscillation. Values < 1 oscillate, = 1 critically damped, > 1 overdamped

## Basic Usage

```ruby
require "harmonica"

# Create a spring with default parameters
spring = Harmonica::Spring.new

# Create with custom physics
spring = Harmonica::Spring.new(
  angular_frequency: 5.0,  # Speed of animation
  damping_ratio: 0.5       # Amount of bounce
)

# Set target value
spring.target = 100.0

# Update each frame (returns current position)
position = spring.update(delta_time)
```

## Animation Parameters

### Angular Frequency

Controls how fast the spring moves toward its target:

```ruby
# Slow, gentle animation
spring = Harmonica::Spring.new(angular_frequency: 2.0)

# Medium speed (good default)
spring = Harmonica::Spring.new(angular_frequency: 5.0)

# Fast, snappy animation
spring = Harmonica::Spring.new(angular_frequency: 10.0)

# Very fast (almost instant)
spring = Harmonica::Spring.new(angular_frequency: 20.0)
```

### Damping Ratio

Controls oscillation behavior:

```ruby
# Underdamped (bouncy) - oscillates around target
spring = Harmonica::Spring.new(damping_ratio: 0.3)  # Very bouncy
spring = Harmonica::Spring.new(damping_ratio: 0.5)  # Moderate bounce
spring = Harmonica::Spring.new(damping_ratio: 0.8)  # Slight bounce

# Critically damped - reaches target fastest without oscillation
spring = Harmonica::Spring.new(damping_ratio: 1.0)

# Overdamped - no oscillation, slower approach
spring = Harmonica::Spring.new(damping_ratio: 1.5)
spring = Harmonica::Spring.new(damping_ratio: 2.0)  # Very slow settle
```

### Common Presets

```ruby
module AnimationPresets
  # UI element hover/focus
  SNAPPY = { angular_frequency: 8.0, damping_ratio: 0.9 }

  # Menu transitions
  SMOOTH = { angular_frequency: 5.0, damping_ratio: 1.0 }

  # Playful bouncy effect
  BOUNCY = { angular_frequency: 6.0, damping_ratio: 0.4 }

  # Gentle, slow reveal
  GENTLE = { angular_frequency: 3.0, damping_ratio: 1.2 }

  # Quick snap with slight settle
  QUICK = { angular_frequency: 12.0, damping_ratio: 0.85 }
end

spring = Harmonica::Spring.new(**AnimationPresets::BOUNCY)
```

## Bubble Tea Integration

### Animated Counter

```ruby
require "bubbletea"
require "harmonica"
require "lipgloss"

class AnimatedCounter
  include Bubbletea::Model

  def initialize
    @value = 0
    @spring = Harmonica::Spring.new(
      angular_frequency: 6.0,
      damping_ratio: 0.6
    )
    @spring.target = 0
    @display_value = 0.0
    @last_tick = Time.now
    setup_styles
  end

  def init
    tick_cmd
  end

  def update(msg)
    case msg
    when TickMsg
      now = Time.now
      delta = now - @last_tick
      @last_tick = now
      @display_value = @spring.update(delta)
      return [self, tick_cmd]
    when Bubbletea::KeyMsg
      case msg.string
      when "q" then return [self, Bubbletea.quit]
      when "up", "k"
        @value += 10
        @spring.target = @value
      when "down", "j"
        @value -= 10
        @spring.target = @value
      end
    end
    [self, nil]
  end

  def view
    displayed = @display_value.round
    number = @number_style.render(displayed.to_s.rjust(5))

    "#{@title_style.render("Animated Counter")}\n\n" \
    "#{number}\n\n" \
    "↑/k +10 • ↓/j -10 • q quit"
  end

  private

  def tick_cmd
    Bubbletea.tick(1.0 / 60.0) { TickMsg.new }  # 60 FPS
  end

  def setup_styles
    @title_style = Lipgloss::Style.new.bold(true)
    @number_style = Lipgloss::Style.new
      .foreground("#7D56F4")
      .bold(true)
  end
end

class TickMsg; end
```

### Animated Progress Bar

```ruby
class AnimatedProgress
  include Bubbletea::Model

  def initialize
    @target_progress = 0.0
    @spring = Harmonica::Spring.new(
      angular_frequency: 4.0,
      damping_ratio: 1.0  # No bounce for progress
    )
    @display_progress = 0.0
    @last_tick = Time.now
    @width = 40
    setup_styles
  end

  def init
    tick_cmd
  end

  def update(msg)
    case msg
    when TickMsg
      delta = Time.now - @last_tick
      @last_tick = Time.now
      @display_progress = @spring.update(delta)
      return [self, tick_cmd]
    when Bubbletea::KeyMsg
      case msg.string
      when "q" then return [self, Bubbletea.quit]
      when " ", "enter"
        @target_progress = [@target_progress + 0.1, 1.0].min
        @spring.target = @target_progress
      when "r"
        @target_progress = 0.0
        @spring.target = 0.0
      end
    end
    [self, nil]
  end

  def view
    progress = @display_progress.clamp(0.0, 1.0)
    filled = (progress * @width).round
    empty = @width - filled

    bar = @filled_style.render("█" * filled) + @empty_style.render("░" * empty)
    percent = "#{(progress * 100).round}%"

    "Progress: #{bar} #{percent}\n\n" \
    "Space to add 10% • r to reset • q quit"
  end

  private

  def tick_cmd
    Bubbletea.tick(1.0 / 30.0) { TickMsg.new }
  end

  def setup_styles
    @filled_style = Lipgloss::Style.new.foreground("#7D56F4")
    @empty_style = Lipgloss::Style.new.foreground("#333333")
  end
end
```

### Smooth Scrolling

```ruby
class SmoothScrollView
  include Bubbletea::Model

  def initialize(content, height: 20)
    @content = content.lines
    @height = height
    @target_offset = 0
    @spring = Harmonica::Spring.new(
      angular_frequency: 8.0,
      damping_ratio: 0.9
    )
    @display_offset = 0.0
    @last_tick = Time.now
  end

  def init
    tick_cmd
  end

  def update(msg)
    case msg
    when TickMsg
      delta = Time.now - @last_tick
      @last_tick = Time.now
      @display_offset = @spring.update(delta)
      return [self, tick_cmd]
    when Bubbletea::KeyMsg
      case msg.string
      when "q" then return [self, Bubbletea.quit]
      when "j", "down"
        @target_offset = [@target_offset + 1, max_offset].min
        @spring.target = @target_offset
      when "k", "up"
        @target_offset = [@target_offset - 1, 0].max
        @spring.target = @target_offset
      when "d"  # Half page down
        @target_offset = [@target_offset + @height / 2, max_offset].min
        @spring.target = @target_offset
      when "u"  # Half page up
        @target_offset = [@target_offset - @height / 2, 0].max
        @spring.target = @target_offset
      end
    end
    [self, nil]
  end

  def view
    offset = @display_offset.round.clamp(0, max_offset)
    visible = @content[offset, @height] || []

    visible.join + "\n" + scroll_indicator
  end

  private

  def max_offset
    [@content.length - @height, 0].max
  end

  def scroll_indicator
    pct = max_offset > 0 ? (@display_offset / max_offset * 100).round : 100
    "Scroll: #{pct}% • j/k scroll • d/u half page • q quit"
  end

  def tick_cmd
    Bubbletea.tick(1.0 / 60.0) { TickMsg.new }
  end
end
```

## Multiple Springs

Animate multiple values independently:

```ruby
class MultiSpringDemo
  include Bubbletea::Model

  def initialize
    @springs = {
      x: Harmonica::Spring.new(angular_frequency: 5.0, damping_ratio: 0.6),
      y: Harmonica::Spring.new(angular_frequency: 5.0, damping_ratio: 0.6),
      size: Harmonica::Spring.new(angular_frequency: 8.0, damping_ratio: 0.8)
    }
    @position = { x: 20.0, y: 10.0, size: 1.0 }
    @last_tick = Time.now
  end

  def init
    tick_cmd
  end

  def update(msg)
    case msg
    when TickMsg
      delta = Time.now - @last_tick
      @last_tick = Time.now

      @position[:x] = @springs[:x].update(delta)
      @position[:y] = @springs[:y].update(delta)
      @position[:size] = @springs[:size].update(delta)

      return [self, tick_cmd]
    when Bubbletea::KeyMsg
      case msg.string
      when "h", "left"
        @springs[:x].target = [@springs[:x].target - 5, 0].max
      when "l", "right"
        @springs[:x].target = @springs[:x].target + 5
      when "k", "up"
        @springs[:y].target = [@springs[:y].target - 2, 0].max
      when "j", "down"
        @springs[:y].target = @springs[:y].target + 2
      when "+", "="
        @springs[:size].target = @springs[:size].target + 0.5
      when "-"
        @springs[:size].target = [@springs[:size].target - 0.5, 0.5].max
      when "q"
        return [self, Bubbletea.quit]
      end
    end
    [self, nil]
  end

  def view
    x = @position[:x].round
    y = @position[:y].round
    size = @position[:size].round

    canvas = Array.new(25) { " " * 60 }

    # Draw object at animated position
    char = "●" * size
    if y >= 0 && y < canvas.length && x >= 0 && x < 60
      canvas[y] = canvas[y][0...x] + char + canvas[y][(x + char.length)..-1].to_s
    end

    canvas.join("\n") + "\n\nhjkl move • +/- size • q quit"
  end

  private

  def tick_cmd
    Bubbletea.tick(1.0 / 60.0) { TickMsg.new }
  end
end
```

## Animation Utilities

### Easing Helper

```ruby
module Harmonica
  module Presets
    def self.ease_out
      Spring.new(angular_frequency: 6.0, damping_ratio: 1.0)
    end

    def self.ease_in_out
      Spring.new(angular_frequency: 4.0, damping_ratio: 1.2)
    end

    def self.bounce
      Spring.new(angular_frequency: 8.0, damping_ratio: 0.3)
    end

    def self.elastic
      Spring.new(angular_frequency: 10.0, damping_ratio: 0.2)
    end
  end
end
```

### Animation State Machine

```ruby
class AnimationController
  def initialize
    @spring = Harmonica::Spring.new(angular_frequency: 6.0, damping_ratio: 0.8)
    @state = :idle
  end

  def start_animation(from:, to:)
    @spring.position = from
    @spring.target = to
    @state = :animating
  end

  def update(delta)
    return @spring.position if @state == :idle

    position = @spring.update(delta)

    # Check if animation complete (velocity near zero, at target)
    if (@spring.position - @spring.target).abs < 0.01 && @spring.velocity.abs < 0.01
      @state = :idle
    end

    position
  end

  def animating?
    @state == :animating
  end
end
```

## Performance Tips

1. **Frame rate**: 30-60 FPS is usually sufficient
2. **Batch updates**: Update all springs in one tick
3. **Stop when settled**: Skip updates when animation complete
4. **Reuse springs**: Don't create new spring objects every frame

```ruby
def tick_cmd
  # Only continue animation if springs are moving
  if animation_active?
    Bubbletea.tick(1.0 / 60.0) { TickMsg.new }
  else
    nil
  end
end

def animation_active?
  @springs.values.any? do |spring|
    (spring.position - spring.target).abs > 0.001 ||
    spring.velocity.abs > 0.001
  end
end
```

## Resources

- [harmonica-ruby GitHub](https://github.com/marcoroth/harmonica-ruby)
- [Original Go harmonica](https://github.com/charmbracelet/harmonica)
- [Spring physics explanation](https://blog.maximeheckel.com/posts/the-physics-behind-spring-animations/)
