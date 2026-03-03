# Huh Forms Reference

## Overview

Huh simplifies building interactive terminal forms with validation, theming, and multiple input types. It handles the complexity of form navigation, focus management, and input validation.

## Installation

Currently, Huh must be installed from GitHub (gem name resolution pending):

```ruby
# Gemfile
gem "huh", github: "marcoroth/huh-ruby"
```

Then run `bundle install`.

## Basic Form

```ruby
require "huh"

form = Huh::Form.new do |f|
  f.group do |g|
    g.input :name, title: "What's your name?"
    g.input :email, title: "Email address"
  end
end

result = form.run

puts "Name: #{result[:name]}"
puts "Email: #{result[:email]}"
```

## Input Types

### Text Input

Single-line text input:

```ruby
g.input :username,
  title: "Username",
  description: "Choose a unique username",
  placeholder: "Enter username...",
  value: "default_value",        # Initial value
  char_limit: 20,                # Max characters
  validate: ->(v) { v.length >= 3 ? nil : "Must be at least 3 characters" }
```

### Text Area

Multi-line text input:

```ruby
g.text :bio,
  title: "Tell us about yourself",
  description: "Write a short bio",
  placeholder: "Enter your bio...",
  char_limit: 500,
  height: 5                      # Number of visible lines
```

### Select

Single choice from options:

```ruby
g.select :color,
  title: "Favorite color",
  options: %w[Red Green Blue Yellow],
  value: "Blue"                  # Default selection

# With detailed options
g.select :plan,
  title: "Choose a plan",
  options: [
    { value: "free", label: "Free", description: "Basic features" },
    { value: "pro", label: "Pro", description: "All features, $10/mo" },
    { value: "enterprise", label: "Enterprise", description: "Custom pricing" }
  ]
```

### Multi-Select

Multiple choices:

```ruby
g.multi_select :features,
  title: "Select features to enable",
  options: [
    { value: "auth", label: "Authentication" },
    { value: "api", label: "API Access" },
    { value: "export", label: "Data Export" },
    { value: "notify", label: "Notifications" }
  ],
  selected: ["auth"],            # Pre-selected values
  min: 1,                        # Minimum selections required
  max: 3                         # Maximum selections allowed
```

### Confirm

Yes/No question:

```ruby
g.confirm :agree,
  title: "Do you agree to the terms of service?",
  affirmative: "Yes, I agree",   # Custom yes text
  negative: "No, I don't"        # Custom no text
```

### Note

Display-only text (no input):

```ruby
g.note :info,
  title: "Important",
  description: "Please read the following carefully before proceeding."
```

## Form Groups

Groups organize related inputs. Forms can have multiple groups that appear sequentially:

```ruby
form = Huh::Form.new do |f|
  # First screen
  f.group do |g|
    g.input :name, title: "Name"
    g.input :email, title: "Email"
  end

  # Second screen
  f.group do |g|
    g.input :company, title: "Company"
    g.input :role, title: "Role"
  end

  # Third screen
  f.group do |g|
    g.confirm :subscribe, title: "Subscribe to newsletter?"
    g.confirm :agree, title: "Agree to terms?"
  end
end
```

## Validation

### Simple Validation

```ruby
g.input :email,
  title: "Email",
  validate: ->(v) {
    return "Email is required" if v.empty?
    return "Invalid email format" unless v.include?("@")
    nil  # Return nil for valid input
  }
```

### Multiple Validations

```ruby
g.input :password,
  title: "Password",
  validate: ->(v) {
    errors = []
    errors << "at least 8 characters" if v.length < 8
    errors << "one uppercase letter" unless v.match?(/[A-Z]/)
    errors << "one lowercase letter" unless v.match?(/[a-z]/)
    errors << "one number" unless v.match?(/[0-9]/)

    errors.empty? ? nil : "Password must have #{errors.join(', ')}"
  }
```

### Cross-Field Validation

Validate against other fields using form-level validation:

```ruby
form = Huh::Form.new do |f|
  f.group do |g|
    g.input :password, title: "Password"
    g.input :confirm, title: "Confirm Password"
  end

  f.validate do |data|
    if data[:password] != data[:confirm]
      { confirm: "Passwords do not match" }
    else
      {}
    end
  end
end
```

## Theming

### Built-in Themes

```ruby
form = Huh::Form.new(theme: :dracula) do |f|
  # ...
end

# Available themes: :default, :dracula, :catppuccin, :charm, :base16
```

### Custom Theme

```ruby
theme = Huh::Theme.new do |t|
  # Colors
  t.primary = "#FF69B4"
  t.secondary = "#888888"
  t.background = "#1A1A2E"

  # Focus styling
  t.focused do |s|
    s.title = Lipgloss::Style.new.foreground("#FF69B4").bold(true)
    s.description = Lipgloss::Style.new.foreground("#888888")
    s.cursor = Lipgloss::Style.new.foreground("#FF69B4")
  end

  # Blurred (unfocused) styling
  t.blurred do |s|
    s.title = Lipgloss::Style.new.foreground("#666666")
    s.description = Lipgloss::Style.new.foreground("#444444")
  end

  # Option styling (for selects)
  t.option do |s|
    s.selected = Lipgloss::Style.new.foreground("#FF69B4")
    s.unselected = Lipgloss::Style.new.foreground("#888888")
  end

  # Error styling
  t.error = Lipgloss::Style.new.foreground("#FF0000")
end

form = Huh::Form.new(theme: theme) do |f|
  # ...
end
```

## Keyboard Navigation

Default keybindings in Huh forms:

| Key | Action |
|-----|--------|
| `Tab` / `↓` | Next field |
| `Shift+Tab` / `↑` | Previous field |
| `Enter` | Submit current field / Next group |
| `Space` | Toggle (confirm/multi-select) |
| `Esc` | Cancel form |
| `Ctrl+C` | Cancel form |

## Conditional Fields

Show fields based on previous answers:

```ruby
form = Huh::Form.new do |f|
  f.group do |g|
    g.select :type,
      title: "Account type",
      options: %w[Personal Business]
  end

  f.group(visible: ->(data) { data[:type] == "Business" }) do |g|
    g.input :company, title: "Company name"
    g.input :tax_id, title: "Tax ID"
  end

  f.group(visible: ->(data) { data[:type] == "Personal" }) do |g|
    g.input :birthdate, title: "Birth date"
  end
end
```

## Form Options

```ruby
form = Huh::Form.new(
  theme: :charm,
  accessible: true,              # Screen reader friendly
  show_help: true,               # Show keybinding hints
  width: 60                      # Form width
) do |f|
  # ...
end
```

## Handling Results

### Basic Result Access

```ruby
result = form.run

# Access by key
name = result[:name]
email = result[:email]

# Check if form was cancelled
if result.cancelled?
  puts "Form cancelled"
  exit 1
end
```

### Result Methods

```ruby
result = form.run

result[:field_name]    # Get specific field value
result.to_h            # Convert to hash
result.cancelled?      # Was form cancelled?
result.completed?      # Was form completed?
```

## Advanced Patterns

### Wizard-Style Form

```ruby
def create_wizard
  Huh::Form.new do |f|
    # Step 1: Basic Info
    f.group do |g|
      g.note :step1, title: "Step 1 of 3: Basic Information"
      g.input :name, title: "Full name"
      g.input :email, title: "Email"
    end

    # Step 2: Preferences
    f.group do |g|
      g.note :step2, title: "Step 2 of 3: Preferences"
      g.select :language, title: "Preferred language", options: %w[English Spanish French]
      g.multi_select :notifications, title: "Notifications", options: %w[Email SMS Push]
    end

    # Step 3: Confirmation
    f.group do |g|
      g.note :step3, title: "Step 3 of 3: Confirm"
      g.confirm :confirm, title: "Is all information correct?"
    end
  end
end
```

### Inline Form (No Full Screen)

```ruby
# Run form without taking over terminal
result = form.run(inline: true)
```

### Programmatic Control

```ruby
form = Huh::Form.new do |f|
  # ...
end

# Set initial values
form.set_value(:name, "John Doe")
form.set_value(:email, "john@example.com")

# Skip to specific group
form.goto_group(2)

# Run with pre-populated values
result = form.run
```

### Dynamic Options

```ruby
# Fetch options from external source
def get_country_options
  countries = fetch_countries_from_api
  countries.map { |c| { value: c.code, label: c.name } }
end

form = Huh::Form.new do |f|
  f.group do |g|
    g.select :country,
      title: "Country",
      options: get_country_options
  end
end
```

## Integration with Bubble Tea

Huh forms can run standalone or be integrated into a larger Bubble Tea application:

```ruby
class AppModel
  include Bubbletea::Model

  def initialize
    @state = :menu
    @form = nil
    @form_result = nil
  end

  def update(msg)
    case @state
    when :menu
      if msg.is_a?(Bubbletea::KeyMsg) && msg.string == "n"
        @form = create_user_form
        @state = :form
      end
    when :form
      if @form.done?
        @form_result = @form.result
        @state = :result
      else
        @form.update(msg)
      end
    end
    [self, nil]
  end

  def view
    case @state
    when :menu
      "Press 'n' to create new user"
    when :form
      @form.view
    when :result
      "Created user: #{@form_result[:name]}"
    end
  end

  private

  def create_user_form
    Huh::Form.new do |f|
      f.group do |g|
        g.input :name, title: "Name"
        g.input :email, title: "Email"
      end
    end
  end
end
```

## Error Handling

```ruby
begin
  result = form.run
rescue Huh::CancelledError
  puts "Form was cancelled"
  exit 1
rescue Huh::ValidationError => e
  puts "Validation failed: #{e.message}"
  puts "Errors: #{e.errors}"
end
```

## Best Practices

1. **Keep groups focused**: Each group should represent one logical step
2. **Provide helpful descriptions**: Use `description` to explain expected input
3. **Use placeholders**: Show example values in placeholders
4. **Validate early**: Catch errors at the field level when possible
5. **Theme consistently**: Match form theme to your application's style
6. **Handle cancellation**: Always check if form was cancelled
7. **Pre-populate when possible**: Set sensible defaults to reduce user effort
