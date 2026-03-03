---
name: add-component
description: Add a Bubbles component to an existing charm-ruby project
argument-hint: "[component-type]"
allowed-tools:
  - Write
  - Edit
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

# Add a Bubbles Component

Add a pre-built Bubbles component to an existing charm-ruby project, including the component module and integration with the main model.

## Available Component Types

| Type | Description |
|------|-------------|
| `spinner` | Animated loading indicator |
| `text-input` | Single-line text input with cursor |
| `text-area` | Multi-line text editing |
| `list` | Scrollable, selectable item list |
| `table` | Formatted data tables |
| `progress` | Progress bar with percentage |
| `viewport` | Scrollable content area |
| `form` | Huh interactive form |

## Workflow

### 1. Verify Project Structure

First, verify this is a charm-ruby project by checking for:
- A `lib/` directory with a main module file
- A `Gemfile` with bubbletea/lipgloss dependencies

If not found, inform the user:
```
This doesn't appear to be a charm-ruby project. Run /charm:init first to create one.
```

### 2. Determine Component Type

If the user provided a component type argument, validate it against the available types.

If not provided or invalid, ask:
```
Which component would you like to add?

• spinner - Loading indicator
• text-input - Single-line text input
• text-area - Multi-line text input
• list - Selectable item list
• table - Data table
• progress - Progress bar
• viewport - Scrollable content
• form - Interactive form (Huh)
```

### 3. Detect Project Structure

Find the project's module name by reading the main lib file. Look for:
```ruby
module SomeModuleName
```

Extract the module name and snake_case version for file paths.

### 4. Create Components Directory

If it doesn't exist, create `lib/{project_name}/components/`.

### 5. Generate Component File

Create the component file based on the selected type.

#### spinner.rb

```ruby
# frozen_string_literal: true

require "bubbles"
require "lipgloss"

module {ModuleName}
  module Components
    class Spinner
      attr_reader :spinner, :message

      def initialize(message = "Loading...")
        @spinner = Bubbles::Spinner.new
        @spinner.style = :dots
        @message = message
        @style = Lipgloss::Style.new.foreground("#FF69B4")
      end

      def tick
        @spinner.tick
      end

      def update(msg)
        @spinner, cmd = @spinner.update(msg)
        [self, cmd]
      end

      def view
        "#{@style.render(@spinner.view)} #{@message}"
      end
    end
  end
end
```

#### text_input.rb

```ruby
# frozen_string_literal: true

require "bubbles"
require "lipgloss"

module {ModuleName}
  module Components
    class TextInput
      attr_reader :input, :label

      def initialize(label:, placeholder: "")
        @label = label
        @input = Bubbles::TextInput.new
        @input.placeholder = placeholder
        @input.focus
        setup_styles
      end

      def value
        @input.value
      end

      def focus
        @input.focus
      end

      def blur
        @input.blur
      end

      def focused?
        @input.focused?
      end

      def update(msg)
        @input, cmd = @input.update(msg)
        [self, cmd]
      end

      def view
        label = @label_style.render("#{@label}:")
        "#{label} #{@input.view}"
      end

      private

      def setup_styles
        @label_style = Lipgloss::Style.new
          .foreground("#888888")
          .bold(true)
      end
    end
  end
end
```

#### text_area.rb

```ruby
# frozen_string_literal: true

require "bubbles"
require "lipgloss"

module {ModuleName}
  module Components
    class TextArea
      attr_reader :textarea, :label

      def initialize(label:, placeholder: "", width: 60, height: 5)
        @label = label
        @textarea = Bubbles::TextArea.new
        @textarea.placeholder = placeholder
        @textarea.width = width
        @textarea.height = height
        @textarea.focus
        setup_styles
      end

      def value
        @textarea.value
      end

      def focus
        @textarea.focus
      end

      def blur
        @textarea.blur
      end

      def update(msg)
        @textarea, cmd = @textarea.update(msg)
        [self, cmd]
      end

      def view
        label = @label_style.render(@label)
        "#{label}\n#{@textarea.view}"
      end

      private

      def setup_styles
        @label_style = Lipgloss::Style.new
          .foreground("#888888")
          .bold(true)
          .margin_bottom(1)
      end
    end
  end
end
```

#### list.rb

```ruby
# frozen_string_literal: true

require "bubbles"
require "lipgloss"

module {ModuleName}
  module Components
    class List
      attr_reader :items, :cursor

      def initialize(items:, title: nil)
        @items = items
        @title = title
        @cursor = 0
        setup_styles
      end

      def selected_item
        @items[@cursor]
      end

      def update(msg)
        case msg
        when Bubbletea::KeyMsg
          case msg.string
          when "up", "k"
            @cursor = [@cursor - 1, 0].max
          when "down", "j"
            @cursor = [@cursor + 1, @items.length - 1].min
          when "g"
            @cursor = 0
          when "G"
            @cursor = @items.length - 1
          end
        end
        [self, nil]
      end

      def view
        lines = []

        if @title
          lines << @title_style.render(@title)
          lines << ""
        end

        @items.each_with_index do |item, i|
          if i == @cursor
            lines << @selected_style.render("> #{item}")
          else
            lines << @item_style.render("  #{item}")
          end
        end

        lines.join("\n")
      end

      private

      def setup_styles
        @title_style = Lipgloss::Style.new
          .bold(true)
          .foreground("#FAFAFA")
          .background("#7D56F4")
          .padding(0, 1)

        @selected_style = Lipgloss::Style.new
          .foreground("#FF69B4")
          .bold(true)

        @item_style = Lipgloss::Style.new
          .foreground("#AAAAAA")
      end
    end
  end
end
```

#### table.rb

```ruby
# frozen_string_literal: true

require "bubbles"
require "lipgloss"

module {ModuleName}
  module Components
    class Table
      attr_reader :table, :cursor

      def initialize(columns:, rows:)
        @table = Bubbles::Table.new
        @table.columns = columns
        @table.rows = rows
        @cursor = 0
        setup_styles
      end

      def selected_row
        @table.rows[@cursor]
      end

      def update(msg)
        case msg
        when Bubbletea::KeyMsg
          case msg.string
          when "up", "k"
            @cursor = [@cursor - 1, 0].max
          when "down", "j"
            @cursor = [@cursor + 1, @table.rows.length - 1].min
          end
        end
        @table, cmd = @table.update(msg)
        [self, cmd]
      end

      def view
        @table.view
      end

      private

      def setup_styles
        @table.border = :rounded
        @table.header_style = Lipgloss::Style.new
          .bold(true)
          .foreground("#FFFFFF")
          .background("#7D56F4")
        @table.selected_style = Lipgloss::Style.new
          .background("#333333")
      end
    end
  end
end
```

#### progress.rb

```ruby
# frozen_string_literal: true

require "lipgloss"

module {ModuleName}
  module Components
    class Progress
      attr_reader :percent, :width

      def initialize(width: 40)
        @percent = 0.0
        @width = width
        setup_styles
      end

      def set(percent)
        @percent = [[percent, 0.0].max, 1.0].min
      end

      def increment(amount = 0.1)
        set(@percent + amount)
      end

      def complete?
        @percent >= 1.0
      end

      def view
        filled_width = (@width * @percent).round
        empty_width = @width - filled_width

        filled = @filled_style.render(" " * filled_width)
        empty = @empty_style.render(" " * empty_width)
        percentage = @percent_style.render("#{(@percent * 100).round}%")

        "#{filled}#{empty} #{percentage}"
      end

      private

      def setup_styles
        @filled_style = Lipgloss::Style.new
          .background("#7D56F4")

        @empty_style = Lipgloss::Style.new
          .background("#3C3C3C")

        @percent_style = Lipgloss::Style.new
          .foreground("#888888")
      end
    end
  end
end
```

#### viewport.rb

```ruby
# frozen_string_literal: true

require "bubbles"

module {ModuleName}
  module Components
    class Viewport
      attr_reader :viewport

      def initialize(content:, width: 80, height: 20)
        @viewport = Bubbles::Viewport.new
        @viewport.width = width
        @viewport.height = height
        @viewport.content = content
      end

      def content=(new_content)
        @viewport.content = new_content
      end

      def scroll_percent
        @viewport.scroll_percent
      end

      def at_top?
        @viewport.at_top?
      end

      def at_bottom?
        @viewport.at_bottom?
      end

      def update(msg)
        @viewport, cmd = @viewport.update(msg)
        [self, cmd]
      end

      def view
        @viewport.view
      end
    end
  end
end
```

#### form.rb (requires Huh)

```ruby
# frozen_string_literal: true

require "huh"

module {ModuleName}
  module Components
    class Form
      attr_reader :result

      def initialize(&block)
        @form = Huh::Form.new(&block)
        @result = nil
      end

      def run
        @result = @form.run
        @result
      end

      def cancelled?
        @result&.cancelled?
      end

      def completed?
        @result&.completed?
      end

      def [](key)
        @result&.[](key)
      end
    end
  end
end
```

### 6. Update Main Module File

Add the component require to the main `lib/{project_name}.rb`:

```ruby
require_relative "{project_name}/components/{component_name}"
```

### 7. Show Integration Example

After creating the component, show how to use it:

```ruby
# In your model:

def initialize
  @{component} = {ModuleName}::Components::{ComponentClass}.new(...)
end

def update(msg)
  @{component}, cmd = @{component}.update(msg)
  [self, cmd]
end

def view
  @{component}.view
end
```

### 8. Check for Missing Dependencies

If the component requires a gem not in the Gemfile (e.g., `huh` for form), inform the user:

```
Note: This component requires the 'huh' gem. Add to your Gemfile:

  gem "huh", github: "marcoroth/huh-ruby"

Then run: bundle install
```
