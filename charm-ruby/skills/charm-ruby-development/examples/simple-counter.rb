# frozen_string_literal: true

# Simple Counter - Minimal Bubble Tea Application
#
# A basic example demonstrating the Model-View-Update pattern.
# Use arrow keys or j/k to change the count, q to quit.
#
# Run: ruby simple-counter.rb

require "bubbletea"
require "lipgloss"

class CounterModel
  include Bubbletea::Model

  def initialize
    @count = 0

    # Pre-create styles for performance
    @title_style = Lipgloss::Style.new
      .bold(true)
      .foreground("#FAFAFA")
      .background("#7D56F4")
      .padding(0, 1)

    @count_style = Lipgloss::Style.new
      .bold(true)
      .foreground("#FF69B4")

    @help_style = Lipgloss::Style.new
      .foreground("#626262")
  end

  # Called once at startup
  def init
    nil # No initial command needed
  end

  # Handle messages and return [new_model, command]
  def update(msg)
    case msg
    when Bubbletea::KeyMsg
      case msg.string
      when "q", "ctrl+c", "esc"
        return [self, Bubbletea.quit]
      when "up", "k"
        @count += 1
      when "down", "j"
        @count -= 1
      when "r"
        @count = 0
      end
    end

    [self, nil]
  end

  # Render current state as string
  def view
    title = @title_style.render(" Counter ")
    count = @count_style.render(@count.to_s)
    help = @help_style.render("↑/k increment • ↓/j decrement • r reset • q quit")

    <<~VIEW

      #{title}

      Count: #{count}

      #{help}
    VIEW
  end
end

# Run the application
if __FILE__ == $PROGRAM_NAME
  Bubbletea.run(CounterModel.new)
end
