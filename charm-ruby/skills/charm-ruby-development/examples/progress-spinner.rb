# frozen_string_literal: true

# Progress Spinner - Async Operations Example
#
# Demonstrates using spinners and progress bars for
# long-running operations with Bubble Tea commands.
#
# Run: ruby progress-spinner.rb

require "bubbletea"
require "lipgloss"
require "bubbles"

# Custom messages for async operations
ProgressMsg = Struct.new(:percent)
CompleteMsg = Struct.new(:result)
ErrorMsg = Struct.new(:error)

class DownloadModel
  include Bubbletea::Model

  STATES = %i[idle downloading complete error].freeze

  def initialize
    @state = :idle
    @progress = 0.0
    @spinner = Bubbles::Spinner.new
    @spinner.style = :dots
    @result = nil
    @error = nil

    setup_styles
  end

  def init
    nil
  end

  def update(msg)
    case msg
    when Bubbletea::KeyMsg
      handle_key(msg)
    when Bubbles::Spinner::TickMsg
      @spinner, cmd = @spinner.update(msg)
      [self, cmd]
    when ProgressMsg
      @progress = msg.percent
      if @progress >= 1.0
        @state = :complete
        @result = "Downloaded 42 files (128 MB)"
        [self, nil]
      else
        [self, simulate_progress_cmd]
      end
    when CompleteMsg
      @state = :complete
      @result = msg.result
      [self, nil]
    when ErrorMsg
      @state = :error
      @error = msg.error
      [self, nil]
    else
      [self, nil]
    end
  end

  def view
    case @state
    when :idle
      render_idle
    when :downloading
      render_downloading
    when :complete
      render_complete
    when :error
      render_error
    end
  end

  private

  def setup_styles
    @title_style = Lipgloss::Style.new
      .bold(true)
      .foreground("#FAFAFA")
      .background("#7D56F4")
      .padding(0, 2)

    @spinner_style = Lipgloss::Style.new
      .foreground("#FF69B4")

    @progress_bar_filled = Lipgloss::Style.new
      .background("#7D56F4")

    @progress_bar_empty = Lipgloss::Style.new
      .background("#3C3C3C")

    @success_style = Lipgloss::Style.new
      .foreground("#04B575")
      .bold(true)

    @error_style = Lipgloss::Style.new
      .foreground("#FF0000")
      .bold(true)

    @help_style = Lipgloss::Style.new
      .foreground("#626262")
  end

  def render_idle
    title = @title_style.render("📥 File Downloader")
    help = @help_style.render("Press Enter to start download • q to quit")

    <<~VIEW

      #{title}

      Ready to download files.

      #{help}
    VIEW
  end

  def render_downloading
    title = @title_style.render("📥 File Downloader")

    # Spinner with styled output
    spinner = @spinner_style.render(@spinner.view)

    # Progress bar
    bar = render_progress_bar(@progress, 40)
    percent = "#{(@progress * 100).round}%"

    # Status text
    status = "Downloading... #{spinner}"

    help = @help_style.render("Press q to cancel")

    <<~VIEW

      #{title}

      #{status}

      #{bar} #{percent}

      #{help}
    VIEW
  end

  def render_complete
    title = @title_style.render("📥 File Downloader")
    success = @success_style.render("✓ Download Complete!")
    result = @result

    help = @help_style.render("Press r to restart • q to quit")

    <<~VIEW

      #{title}

      #{success}

      #{result}

      #{help}
    VIEW
  end

  def render_error
    title = @title_style.render("📥 File Downloader")
    error = @error_style.render("✗ Error: #{@error}")

    help = @help_style.render("Press r to retry • q to quit")

    <<~VIEW

      #{title}

      #{error}

      #{help}
    VIEW
  end

  def render_progress_bar(percent, width)
    filled_width = (width * percent).round
    empty_width = width - filled_width

    filled = @progress_bar_filled.render(" " * filled_width)
    empty = @progress_bar_empty.render(" " * empty_width)

    "#{filled}#{empty}"
  end

  def handle_key(msg)
    case msg.string
    when "q", "ctrl+c", "esc"
      [self, Bubbletea.quit]
    when "enter"
      if @state == :idle
        start_download
      else
        [self, nil]
      end
    when "r"
      if @state == :complete || @state == :error
        reset_and_start
      else
        [self, nil]
      end
    else
      [self, nil]
    end
  end

  def start_download
    @state = :downloading
    @progress = 0.0

    # Start spinner and progress simulation
    [self, Bubbletea.batch(@spinner.tick, simulate_progress_cmd)]
  end

  def reset_and_start
    @state = :idle
    @progress = 0.0
    @result = nil
    @error = nil
    start_download
  end

  def simulate_progress_cmd
    # Simulate async download progress
    Bubbletea.tick(0.1) do |_time|
      # Random progress increment (simulates variable download speed)
      increment = rand(0.02..0.08)
      ProgressMsg.new(@progress + increment)
    end
  end
end

# Run the application
if __FILE__ == $PROGRAM_NAME
  Bubbletea.run(DownloadModel.new)
end
