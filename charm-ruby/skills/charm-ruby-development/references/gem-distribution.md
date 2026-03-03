# Gem Distribution Reference

## Overview

Distributing your charm-ruby CLI tool as a Ruby gem allows users to install it with a simple `gem install` command. This guide covers project structure, gemspec configuration, versioning, and publishing to RubyGems.org.

## Project Structure

Standard gem structure for a CLI tool:

```
my-cli/
├── bin/
│   └── my-cli              # Executable script
├── lib/
│   ├── my_cli.rb           # Main entry point (requires all modules)
│   └── my_cli/
│       ├── version.rb      # Version constant
│       ├── cli.rb          # CLI entry class
│       ├── model.rb        # Bubble Tea model(s)
│       └── components/     # Custom components
│           └── ...
├── spec/                   # Tests (optional but recommended)
│   └── ...
├── .gitignore
├── .rubocop.yml            # Linting config (optional)
├── Gemfile
├── LICENSE.txt
├── README.md
├── CHANGELOG.md
└── my-cli.gemspec
```

## Essential Files

### bin/my-cli

The executable that users run:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "my_cli"

MyCli::CLI.start
```

Make it executable:

```bash
chmod +x bin/my-cli
```

### lib/my_cli.rb

Main entry point that loads all modules:

```ruby
# frozen_string_literal: true

require_relative "my_cli/version"
require_relative "my_cli/cli"
require_relative "my_cli/model"

module MyCli
  class Error < StandardError; end
end
```

### lib/my_cli/version.rb

Version constant used by gemspec:

```ruby
# frozen_string_literal: true

module MyCli
  VERSION = "0.1.0"
end
```

### lib/my_cli/cli.rb

CLI entry class:

```ruby
# frozen_string_literal: true

require "bubbletea"
require "lipgloss"

module MyCli
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
        puts "my-cli #{VERSION}"
      when "-h", "--help"
        show_help
      else
        start_app
      end
    end

    private

    def show_help
      puts <<~HELP
        my-cli - A beautiful CLI tool

        Usage: my-cli [options]

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

### lib/my_cli/model.rb

Main Bubble Tea model:

```ruby
# frozen_string_literal: true

require "bubbletea"
require "lipgloss"

module MyCli
  class Model
    include Bubbletea::Model

    def initialize
      @cursor = 0
      @items = ["Item 1", "Item 2", "Item 3"]
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
      # Render your UI here
      lines = @items.map.with_index do |item, i|
        prefix = i == @cursor ? "> " : "  "
        "#{prefix}#{item}"
      end
      lines.join("\n") + "\n\nq to quit"
    end

    private

    def handle_key(msg)
      case msg.string
      when "q", "ctrl+c"
        [self, Bubbletea.quit]
      when "up", "k"
        @cursor = [@cursor - 1, 0].max
        [self, nil]
      when "down", "j"
        @cursor = [@cursor + 1, @items.length - 1].min
        [self, nil]
      else
        [self, nil]
      end
    end
  end
end
```

## Gemspec Configuration

### my-cli.gemspec

```ruby
# frozen_string_literal: true

require_relative "lib/my_cli/version"

Gem::Specification.new do |spec|
  spec.name          = "my-cli"
  spec.version       = MyCli::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["you@example.com"]

  spec.summary       = "A beautiful CLI tool built with charm-ruby"
  spec.description   = "A more detailed description of what your CLI does and why it's useful."
  spec.homepage      = "https://github.com/yourusername/my-cli"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata = {
    "bug_tracker_uri"   => "https://github.com/yourusername/my-cli/issues",
    "changelog_uri"     => "https://github.com/yourusername/my-cli/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/yourusername/my-cli#readme",
    "homepage_uri"      => spec.homepage,
    "source_code_uri"   => "https://github.com/yourusername/my-cli"
  }

  # Specify which files should be included in the gem
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/}) ||
        f.match(%r{\A\.(?:git|github|rubocop)})
    end
  end

  # Executables go in bin/ directory
  spec.bindir        = "bin"
  spec.executables   = ["my-cli"]
  spec.require_paths = ["lib"]

  # Runtime dependencies (required to run)
  spec.add_dependency "bubbletea", "~> 0.1"
  spec.add_dependency "lipgloss", "~> 0.1"
  spec.add_dependency "bubbles", "~> 0.1"

  # Development dependencies (only for development/testing)
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end
```

### Key Gemspec Fields

| Field | Description |
|-------|-------------|
| `name` | Gem name (lowercase, hyphens OK) |
| `version` | Semantic version (MAJOR.MINOR.PATCH) |
| `summary` | One-line description (< 140 chars) |
| `description` | Detailed description |
| `executables` | Array of bin/ scripts to install |
| `add_dependency` | Runtime dependencies with version constraints |

### Version Constraints

```ruby
# Exact version
spec.add_dependency "bubbletea", "0.1.0"

# Any version >= 0.1.0 and < 1.0.0
spec.add_dependency "bubbletea", "~> 0.1"

# Any version >= 0.1.0 and < 0.2.0
spec.add_dependency "bubbletea", "~> 0.1.0"

# Any version >= 0.1.0
spec.add_dependency "bubbletea", ">= 0.1"

# Complex constraints
spec.add_dependency "bubbletea", ">= 0.1", "< 2.0"
```

## Gemfile

For development:

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

# Specify gem dependencies in my-cli.gemspec
gemspec

# Development-only gems not in gemspec
group :development do
  gem "debug"
end
```

## Versioning

### Semantic Versioning (SemVer)

Follow MAJOR.MINOR.PATCH:

- **MAJOR**: Breaking changes (incompatible API changes)
- **MINOR**: New features (backwards-compatible)
- **PATCH**: Bug fixes (backwards-compatible)

### Version Workflow

```ruby
# lib/my_cli/version.rb

module MyCli
  VERSION = "0.1.0"  # Initial development
  # VERSION = "0.2.0"  # Added new feature
  # VERSION = "0.2.1"  # Bug fix
  # VERSION = "1.0.0"  # First stable release
end
```

### Pre-release Versions

```ruby
VERSION = "1.0.0.alpha"
VERSION = "1.0.0.beta.1"
VERSION = "1.0.0.rc.1"
```

## Building the Gem

### Build Locally

```bash
# Build gem file
gem build my-cli.gemspec

# Output: my-cli-0.1.0.gem
```

### Install Locally for Testing

```bash
# Install from local .gem file
gem install ./my-cli-0.1.0.gem

# Or install directly from source
bundle exec rake install
```

### Test the Executable

```bash
# After installation, test the command
my-cli --version
my-cli --help
my-cli
```

## Publishing to RubyGems.org

### First-Time Setup

1. Create account at [rubygems.org](https://rubygems.org/sign_up)
2. Get API key from profile settings
3. Configure credentials:

```bash
# Interactive setup
gem signin

# Or manually create ~/.gem/credentials
mkdir -p ~/.gem
echo ":rubygems_api_key: YOUR_API_KEY" > ~/.gem/credentials
chmod 0600 ~/.gem/credentials
```

### Publish

```bash
# Build fresh gem
gem build my-cli.gemspec

# Push to RubyGems
gem push my-cli-0.1.0.gem
```

### Release Workflow

1. Update version in `version.rb`
2. Update `CHANGELOG.md`
3. Commit changes: `git commit -am "Release v0.2.0"`
4. Tag release: `git tag v0.2.0`
5. Build: `gem build my-cli.gemspec`
6. Push gem: `gem push my-cli-0.2.0.gem`
7. Push to git: `git push && git push --tags`

### Using Rake Tasks

Add to `Rakefile`:

```ruby
# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec
```

Then use:

```bash
# Build gem
rake build

# Install locally
rake install

# Release (builds, tags, pushes gem and git)
rake release
```

## CHANGELOG.md

Keep a changelog for users:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- New feature in development

## [0.2.0] - 2025-01-15

### Added
- Interactive file picker
- Color theme support

### Fixed
- Cursor position after scroll

## [0.1.0] - 2025-01-01

### Added
- Initial release
- Basic navigation
- Item selection
```

## README.md Template

```markdown
# My CLI

A beautiful CLI tool built with charm-ruby.

## Installation

```bash
gem install my-cli
```

## Usage

```bash
# Start the interactive interface
my-cli

# Show help
my-cli --help

# Show version
my-cli --version
```

## Development

After cloning:

```bash
bin/setup
bundle exec rake spec
```

## Contributing

Bug reports and pull requests welcome at https://github.com/yourusername/my-cli

## License

MIT License - see LICENSE.txt
```

## CI/CD with GitHub Actions

### .github/workflows/ci.yml

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        ruby: ['2.7', '3.0', '3.1', '3.2']

    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby }}
          bundler-cache: true
      - run: bundle exec rake spec

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
      - run: bundle exec rubocop
```

### .github/workflows/release.yml

```yaml
name: Release

on:
  push:
    tags: ['v*']

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
      - name: Build gem
        run: gem build *.gemspec
      - name: Push to RubyGems
        run: gem push *.gem
        env:
          GEM_HOST_API_KEY: ${{ secrets.RUBYGEMS_API_KEY }}
```

## Best Practices

1. **Use frozen_string_literal**: Add to all Ruby files for performance
2. **Pin major versions**: Use `~>` to allow minor updates but prevent breaking changes
3. **Test before release**: Run full test suite before publishing
4. **Document changes**: Keep CHANGELOG updated
5. **Semantic versioning**: Follow SemVer strictly
6. **Minimal dependencies**: Only include what's needed
7. **Support multiple Ruby versions**: Test on Ruby 2.7+
8. **Provide --help and --version**: Standard CLI conventions
9. **Handle errors gracefully**: Don't crash with stack traces
10. **Include LICENSE**: Required for open source gems

## Troubleshooting

### Gem Not Found After Install

Check PATH includes gem bin directory:

```bash
echo $PATH
gem environment
```

### Permission Denied

Don't use `sudo gem install`. Instead:

```bash
# Use rbenv/rvm, or:
gem install --user-install my-cli
```

### Version Conflicts

```bash
# Check installed versions
gem list my-cli

# Uninstall old versions
gem uninstall my-cli --version 0.1.0
```

### Executable Not Running

Check shebang line in bin/ file:

```ruby
#!/usr/bin/env ruby
```

Ensure file is executable:

```bash
chmod +x bin/my-cli
```
