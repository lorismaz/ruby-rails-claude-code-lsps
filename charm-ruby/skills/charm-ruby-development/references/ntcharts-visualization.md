# Nimble Terminal Charts (ntcharts)

ntcharts provides terminal-native data visualization for Ruby CLI applications. It renders charts directly in the terminal using Unicode characters, making it ideal for dashboards, monitoring tools, and data exploration CLIs.

## Installation

```ruby
# Gemfile
gem "ntcharts"
```

## Chart Types

### Sparklines

Compact inline charts for showing trends in minimal space:

```ruby
require "ntcharts"

data = [4, 2, 1, 6, 3, 9, 1, 4, 2, 15, 14, 9, 8, 6, 10, 13, 15, 12, 10, 5, 3, 6, 1]

sparkline = Ntcharts::Sparkline.new(data)
puts sparkline.render
# Output: ▂▁▁▃▂▅▁▂▁█▇▅▄▃▅▇█▆▅▃▂▃▁
```

**Customization options:**

```ruby
sparkline = Ntcharts::Sparkline.new(data)
sparkline.width = 40           # Fixed width
sparkline.style = Lipgloss::Style.new.foreground("#FF69B4")

# With min/max labels
sparkline.show_min_max = true
```

### Bar Charts

Horizontal or vertical bar charts for comparing values:

```ruby
require "ntcharts"

# Horizontal bar chart
data = [
  { label: "Ruby", value: 85 },
  { label: "Python", value: 72 },
  { label: "Go", value: 68 },
  { label: "Rust", value: 45 }
]

bar_chart = Ntcharts::BarChart.new(data)
bar_chart.orientation = :horizontal
bar_chart.width = 50
bar_chart.bar_style = Lipgloss::Style.new.foreground("#7D56F4")

puts bar_chart.render
```

**Output:**

```
Ruby   ████████████████████████████████████████  85
Python ████████████████████████████████          72
Go     ██████████████████████████████            68
Rust   ████████████████████                      45
```

**Vertical bars:**

```ruby
bar_chart = Ntcharts::BarChart.new(data)
bar_chart.orientation = :vertical
bar_chart.height = 10
bar_chart.show_values = true
```

### Line Charts

For time series or continuous data:

```ruby
require "ntcharts"

# Single series
data = [10, 15, 12, 18, 22, 19, 25, 28, 24, 30]

line_chart = Ntcharts::LineChart.new(data)
line_chart.width = 60
line_chart.height = 15
line_chart.style = Lipgloss::Style.new.foreground("#00FF00")

puts line_chart.render
```

**Multiple series:**

```ruby
series = {
  "CPU" => [45, 52, 48, 55, 60, 58, 62],
  "Memory" => [30, 32, 35, 33, 38, 40, 42]
}

line_chart = Ntcharts::LineChart.new
line_chart.add_series("CPU", series["CPU"], color: "#FF6B6B")
line_chart.add_series("Memory", series["Memory"], color: "#4ECDC4")
line_chart.show_legend = true

puts line_chart.render
```

### Heatmaps

For visualizing 2D data matrices:

```ruby
require "ntcharts"

# Activity heatmap (like GitHub contribution graph)
data = [
  [0, 1, 2, 3, 4, 5, 2, 1],
  [1, 2, 4, 5, 3, 2, 1, 0],
  [2, 3, 5, 4, 2, 1, 3, 2],
  [0, 1, 3, 5, 4, 3, 2, 1],
  [1, 0, 2, 4, 5, 4, 3, 2]
]

heatmap = Ntcharts::Heatmap.new(data)
heatmap.color_scale = [:black, :dark_green, :green, :bright_green]
heatmap.cell_width = 2

puts heatmap.render
```

**Custom color scales:**

```ruby
heatmap.color_scale = ["#161B22", "#0E4429", "#006D32", "#26A641", "#39D353"]
```

## Integration with Bubble Tea

Use ntcharts in Bubble Tea models for live-updating dashboards:

```ruby
require "bubbletea"
require "ntcharts"
require "lipgloss"

class DashboardModel
  include Bubbletea::Model

  def initialize
    @data = []
    @sparkline = Ntcharts::Sparkline.new([])
    setup_styles
  end

  def init
    tick_cmd
  end

  def update(msg)
    case msg
    when TickMsg
      # Add new data point
      @data << rand(1..100)
      @data.shift if @data.length > 50
      @sparkline = Ntcharts::Sparkline.new(@data)
      return [self, tick_cmd]
    when Bubbletea::KeyMsg
      return [self, Bubbletea.quit] if msg.string == "q"
    end
    [self, nil]
  end

  def view
    title = @title_style.render("System Load")
    chart = @sparkline.render

    "#{title}\n\n#{chart}\n\nPress q to quit"
  end

  private

  def tick_cmd
    Bubbletea.tick(1) { TickMsg.new }
  end

  def setup_styles
    @title_style = Lipgloss::Style.new
      .bold(true)
      .foreground("#FFFFFF")
      .background("#7D56F4")
      .padding(0, 1)
  end
end

class TickMsg; end

Bubbletea.run(DashboardModel.new)
```

## Dashboard Layout

Combine multiple charts with Lipgloss layout:

```ruby
require "ntcharts"
require "lipgloss"

class MultiChartDashboard
  def initialize
    @cpu_data = Array.new(20) { rand(20..80) }
    @memory_data = Array.new(20) { rand(30..70) }
    @disk_usage = [
      { label: "/", value: 65 },
      { label: "/home", value: 82 },
      { label: "/var", value: 45 }
    ]
    setup_charts
    setup_styles
  end

  def render
    # Create chart panels
    cpu_panel = render_panel("CPU Usage", @cpu_sparkline.render)
    memory_panel = render_panel("Memory", @memory_sparkline.render)
    disk_panel = render_panel("Disk Usage", @disk_chart.render)

    # Layout: two sparklines on top, bar chart below
    top_row = Lipgloss.join_horizontal(:top, cpu_panel, memory_panel)
    Lipgloss.join_vertical(:left, top_row, disk_panel)
  end

  private

  def render_panel(title, content)
    @panel_style.render("#{@title_style.render(title)}\n#{content}")
  end

  def setup_charts
    @cpu_sparkline = Ntcharts::Sparkline.new(@cpu_data)
    @memory_sparkline = Ntcharts::Sparkline.new(@memory_data)
    @disk_chart = Ntcharts::BarChart.new(@disk_usage)
    @disk_chart.orientation = :horizontal
    @disk_chart.width = 30
  end

  def setup_styles
    @panel_style = Lipgloss::Style.new
      .border(:rounded)
      .padding(1)
      .margin(0, 1)
      .width(35)

    @title_style = Lipgloss::Style.new
      .bold(true)
      .foreground("#FF69B4")
  end
end
```

## Chart Styling

All ntcharts components support Lipgloss styling:

```ruby
# Styled sparkline
sparkline = Ntcharts::Sparkline.new(data)
sparkline.style = Lipgloss::Style.new
  .foreground("#7D56F4")
  .background("#1a1a2e")

# Styled bar chart with custom bar colors
bar_chart = Ntcharts::BarChart.new(data)
bar_chart.bar_style = Lipgloss::Style.new.foreground("#FF6B6B")
bar_chart.label_style = Lipgloss::Style.new.foreground("#888888")
bar_chart.value_style = Lipgloss::Style.new.bold(true)

# Adaptive colors for light/dark terminals
sparkline.style = Lipgloss::Style.new
  .foreground(Lipgloss.adaptive_color("#000000", "#FFFFFF"))
```

## Performance Considerations

- **Buffer updates**: For real-time charts, buffer data points and update periodically
- **Fixed dimensions**: Set explicit width/height to avoid recalculation
- **Data windowing**: Keep only recent data points (e.g., last 100)
- **Render caching**: Cache chart renders when data hasn't changed

```ruby
class OptimizedChart
  def initialize
    @data = []
    @last_render = nil
    @data_changed = false
  end

  def add_point(value)
    @data << value
    @data.shift if @data.length > 100
    @data_changed = true
  end

  def render
    return @last_render unless @data_changed

    @last_render = @sparkline.render
    @data_changed = false
    @last_render
  end
end
```

## Common Patterns

### Progress Dashboard

```ruby
tasks = [
  { name: "Download", progress: 0.75 },
  { name: "Extract", progress: 0.45 },
  { name: "Install", progress: 0.20 }
]

tasks.each do |task|
  bar = Ntcharts::ProgressBar.new(task[:progress])
  bar.width = 30
  puts "#{task[:name].ljust(10)} #{bar.render} #{(task[:progress] * 100).to_i}%"
end
```

### Real-time Metrics

```ruby
def render_metrics(cpu, memory, network)
  cpu_spark = Ntcharts::Sparkline.new(cpu)
  mem_spark = Ntcharts::Sparkline.new(memory)
  net_spark = Ntcharts::Sparkline.new(network)

  [
    "CPU:     #{cpu_spark.render}",
    "Memory:  #{mem_spark.render}",
    "Network: #{net_spark.render}"
  ].join("\n")
end
```

## Resources

- [ntcharts-ruby GitHub](https://github.com/marcoroth/ntcharts-ruby)
- [Original Go ntcharts](https://github.com/NimbleMarkets/ntcharts)
