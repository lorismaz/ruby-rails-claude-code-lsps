# frozen_string_literal: true

# Styled List - Lipgloss + Bubbles List Example
#
# Demonstrates a selectable list with custom styling,
# keyboard navigation, and item actions.
#
# Run: ruby styled-list.rb

require "bubbletea"
require "lipgloss"
require "bubbles"

# Custom list item with title and description
class Task
  attr_reader :title, :description
  attr_accessor :done

  def initialize(title, description, done: false)
    @title = title
    @description = description
    @done = done
  end

  # Used by Bubbles::List for filtering
  def filter_value
    "#{title} #{description}"
  end
end

class TaskListModel
  include Bubbletea::Model

  def initialize
    @tasks = [
      Task.new("Review PR #42", "Check the authentication changes"),
      Task.new("Write documentation", "Update API reference for v2"),
      Task.new("Fix login bug", "Users can't login with SSO"),
      Task.new("Deploy to staging", "Run integration tests first"),
      Task.new("Team standup", "Daily sync at 10am"),
      Task.new("Code review", "Review Maria's refactoring PR"),
      Task.new("Update dependencies", "Security patches available"),
      Task.new("Write tests", "Coverage for new features")
    ]
    @cursor = 0
    @width = 50

    setup_styles
  end

  def init
    nil
  end

  def update(msg)
    case msg
    when Bubbletea::KeyMsg
      handle_key(msg)
    when Bubbletea::WindowSizeMsg
      @width = [msg.width - 4, 40].max
      [self, nil]
    else
      [self, nil]
    end
  end

  def view
    # Header
    header = @header_style.render("📋 Task List")

    # Task list
    items = @tasks.map.with_index do |task, i|
      render_task(task, i == @cursor)
    end.join("\n")

    # Footer with counts
    done_count = @tasks.count(&:done)
    total = @tasks.length
    footer = @footer_style.render("#{done_count}/#{total} completed")

    # Help
    help = @help_style.render("j/k navigate • space toggle • q quit")

    # Compose layout
    <<~VIEW

      #{header}

      #{items}

      #{footer}
      #{help}
    VIEW
  end

  private

  def setup_styles
    @header_style = Lipgloss::Style.new
      .bold(true)
      .foreground("#FAFAFA")
      .background("#7D56F4")
      .padding(0, 2)
      .margin_bottom(1)

    @task_style = Lipgloss::Style.new
      .padding_left(2)

    @selected_style = Lipgloss::Style.new
      .foreground("#FF69B4")
      .bold(true)
      .padding_left(0)

    @done_style = Lipgloss::Style.new
      .foreground("#626262")
      .strikethrough(true)

    @description_style = Lipgloss::Style.new
      .foreground("#626262")
      .italic(true)
      .padding_left(4)

    @footer_style = Lipgloss::Style.new
      .foreground("#626262")
      .margin_top(1)

    @help_style = Lipgloss::Style.new
      .foreground("#4A4A4A")
  end

  def render_task(task, selected)
    # Checkbox
    checkbox = task.done ? "✓" : "○"

    # Title with appropriate styling
    title = if task.done
              @done_style.render(task.title)
            elsif selected
              @selected_style.render(task.title)
            else
              task.title
            end

    # Cursor indicator
    cursor = selected ? "→ " : "  "
    cursor = @selected_style.render(cursor) if selected

    # Main line
    line = "#{cursor}#{checkbox} #{title}"

    # Description (only for selected item)
    if selected && !task.description.empty?
      desc = @description_style.render(task.description)
      "#{line}\n#{desc}"
    else
      line
    end
  end

  def handle_key(msg)
    case msg.string
    when "q", "ctrl+c", "esc"
      [self, Bubbletea.quit]
    when "up", "k"
      @cursor = [@cursor - 1, 0].max
      [self, nil]
    when "down", "j"
      @cursor = [@cursor + 1, @tasks.length - 1].min
      [self, nil]
    when " ", "enter"
      @tasks[@cursor].done = !@tasks[@cursor].done
      [self, nil]
    when "g"
      @cursor = 0
      [self, nil]
    when "G"
      @cursor = @tasks.length - 1
      [self, nil]
    else
      [self, nil]
    end
  end
end

# Run the application
if __FILE__ == $PROGRAM_NAME
  Bubbletea.run(TaskListModel.new, alt_screen: true)
end
