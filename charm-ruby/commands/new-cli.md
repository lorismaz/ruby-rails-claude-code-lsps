---
name: new-cli
description: Scaffold a new charm-ruby CLI project with Bubble Tea architecture
argument-hint: "[project-name]"
allowed-tools:
  - Write
  - Bash
  - Read
  - Glob
  - AskUserQuestion
---

# Initialize a Charm Ruby CLI Project

Create a new Ruby CLI project scaffolded for charm-ruby development with Bubble Tea MVU architecture, Lipgloss styling, and gem distribution setup.

## Workflow

### 1. Determine Project Name

If the user provided a project name argument, use it. Otherwise, ask:

```
What would you like to name your CLI project?
```

The project name should be:
- Lowercase with hyphens (e.g., `my-awesome-cli`)
- Valid Ruby gem name
- Converted to snake_case for module names (e.g., `my_awesome_cli` → `MyAwesomeCli`)

### 2. Create Project Structure

Create the following directory structure:

```
{project-name}/
├── bin/
│   └── {project-name}      # Executable (chmod +x)
├── lib/
│   ├── {project_name}.rb   # Main entry point
│   └── {project_name}/
│       ├── version.rb      # Version constant
│       ├── cli.rb          # CLI entry class
│       └── model.rb        # Main Bubble Tea model
├── spec/
│   └── {project_name}_spec.rb  # Basic test file
├── .gitignore
├── .rubocop.yml
├── Gemfile
├── {project-name}.gemspec
├── LICENSE.txt
├── Rakefile
└── README.md
```

### 3. File Contents

#### bin/{project-name}

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "{project_name}"

{ModuleName}::CLI.start
```

#### lib/{project_name}.rb

```ruby
# frozen_string_literal: true

require_relative "{project_name}/version"
require_relative "{project_name}/cli"
require_relative "{project_name}/model"

module {ModuleName}
  class Error < StandardError; end
end
```

#### lib/{project_name}/version.rb

```ruby
# frozen_string_literal: true

module {ModuleName}
  VERSION = "0.1.0"
end
```

#### lib/{project_name}/cli.rb

```ruby
# frozen_string_literal: true

require "bubbletea"

module {ModuleName}
  class CLI
    def self.start(args = ARGV)
      new(args).run
    end

    def initialize(args)
      @args = args
    end

    def run
      case @args.first
      when "-v", "--version"
        puts "{project-name} #{VERSION}"
      when "-h", "--help"
        show_help
      else
        start_app
      end
    end

    private

    def show_help
      puts <<~HELP
        {project-name} - A beautiful CLI tool

        Usage: {project-name} [options]

        Options:
          -h, --help     Show this help
          -v, --version  Show version
      HELP
    end

    def start_app
      Bubbletea.run(Model.new, alt_screen: true)
    end
  end
end
```

#### lib/{project_name}/model.rb

```ruby
# frozen_string_literal: true

require "bubbletea"
require "lipgloss"

module {ModuleName}
  class Model
    include Bubbletea::Model

    def initialize
      @cursor = 0
      @items = ["Getting started", "Add features", "Ship it!"]
      setup_styles
    end

    def init
      nil
    end

    def update(msg)
      case msg
      when Bubbletea::KeyMsg
        handle_key(msg)
      else
        [self, nil]
      end
    end

    def view
      title = @title_style.render(" {ModuleName} ")

      items = @items.map.with_index do |item, i|
        if i == @cursor
          @selected_style.render("> #{item}")
        else
          "  #{item}"
        end
      end.join("\n")

      help = @help_style.render("j/k navigate • enter select • q quit")

      "\n#{title}\n\n#{items}\n\n#{help}\n"
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

      @help_style = Lipgloss::Style.new
        .foreground("#626262")
    end

    def handle_key(msg)
      case msg.string
      when "q", "ctrl+c", "esc"
        [self, Bubbletea.quit]
      when "up", "k"
        @cursor = [@cursor - 1, 0].max
        [self, nil]
      when "down", "j"
        @cursor = [@cursor + 1, @items.length - 1].min
        [self, nil]
      when "enter"
        # Handle selection - customize this!
        [self, nil]
      else
        [self, nil]
      end
    end
  end
end
```

#### Gemfile

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development do
  gem "debug"
end
```

#### {project-name}.gemspec

```ruby
# frozen_string_literal: true

require_relative "lib/{project_name}/version"

Gem::Specification.new do |spec|
  spec.name          = "{project-name}"
  spec.version       = {ModuleName}::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["you@example.com"]

  spec.summary       = "A beautiful CLI tool built with charm-ruby"
  spec.description   = "Describe what your CLI does here."
  spec.homepage      = "https://github.com/yourusername/{project-name}"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md"
  }

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/}) ||
        f.match(%r{\A\.(?:git|github)})
    end
  end

  spec.bindir        = "bin"
  spec.executables   = ["{project-name}"]
  spec.require_paths = ["lib"]

  spec.add_dependency "bubbletea", "~> 0.1"
  spec.add_dependency "lipgloss", "~> 0.1"
  spec.add_dependency "bubbles", "~> 0.1"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end
```

#### .gitignore

```
/.bundle/
/.yardoc
/_yardoc/
/coverage/
/doc/
/pkg/
/spec/reports/
/tmp/
*.gem
Gemfile.lock
```

#### .rubocop.yml

```yaml
AllCops:
  TargetRubyVersion: 2.7
  NewCops: enable

Style/Documentation:
  Enabled: false

Metrics/MethodLength:
  Max: 20

Metrics/BlockLength:
  Exclude:
    - "spec/**/*"
    - "*.gemspec"
```

#### Rakefile

```ruby
# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec
```

#### README.md

```markdown
# {ModuleName}

A beautiful CLI tool built with [charm-ruby](https://charm-ruby.dev).

## Installation

```bash
gem install {project-name}
```

## Usage

```bash
{project-name}
```

## Development

```bash
bundle install
bundle exec rake spec
```

## License

MIT
```

#### LICENSE.txt

Use MIT license template with current year.

#### spec/{project_name}_spec.rb

```ruby
# frozen_string_literal: true

RSpec.describe {ModuleName} do
  it "has a version number" do
    expect({ModuleName}::VERSION).not_to be_nil
  end
end
```

### 4. Post-Creation Steps

After creating all files:

1. Make the bin file executable:
   ```bash
   chmod +x {project-name}/bin/{project-name}
   ```

2. Initialize git repository:
   ```bash
   cd {project-name} && git init
   ```

3. Display next steps to the user:
   ```
   ✅ Created {project-name}!

   Next steps:
     cd {project-name}
     bundle install
     bundle exec bin/{project-name}

   To publish to RubyGems:
     gem build {project-name}.gemspec
     gem push {project-name}-0.1.0.gem
   ```
