---
name: package
description: Prepare a charm-ruby CLI project for RubyGems distribution
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

# Package for RubyGems Distribution

Prepare the charm-ruby CLI project for publishing to RubyGems.org by validating and updating the gemspec, checking file permissions, and providing publishing instructions.

## Workflow

### 1. Verify Project Structure

Confirm this is a valid gem project by checking for:
- `*.gemspec` file
- `lib/*/version.rb` with VERSION constant
- `bin/` directory with executable(s)
- `Gemfile`

If missing critical files, inform the user what needs to be created.

### 2. Validate Gemspec

Read the gemspec file and check for:

#### Required Fields

- `spec.name` - Must be set and valid
- `spec.version` - Should reference VERSION constant
- `spec.authors` - Must not be placeholder
- `spec.email` - Must not be placeholder
- `spec.summary` - Should be meaningful (not default text)
- `spec.homepage` - Should be a valid URL
- `spec.license` - Should be specified

#### Recommended Fields

- `spec.description` - Longer than summary
- `spec.metadata` - homepage_uri, source_code_uri, changelog_uri
- `spec.required_ruby_version` - Should be specified

If any required field has placeholder values like "TODO", "Your Name", or "you@example.com", ask the user:

```
Your gemspec has placeholder values that need updating:

• authors: Currently "Your Name" - What's your name?
• email: Currently "you@example.com" - What's your email?
• homepage: Not set - What's the project URL? (e.g., GitHub repo)
```

Update the gemspec with the user's answers.

### 3. Check Version

Read `lib/*/version.rb` and display current version:

```
Current version: 0.1.0
```

Ask if the user wants to bump the version before publishing:

```
Do you want to update the version before publishing?
• Keep 0.1.0
• Bump patch (0.1.1)
• Bump minor (0.2.0)
• Bump major (1.0.0)
• Custom version
```

If they choose to bump, update the version.rb file.

### 4. Verify Executable Permissions

Check that files in `bin/` are executable:

```bash
ls -la bin/
```

If any are not executable, fix them:

```bash
chmod +x bin/*
```

### 5. Check for Required Files

Verify these files exist:
- `README.md` - Package documentation
- `LICENSE.txt` or `LICENSE` - License file
- `CHANGELOG.md` - Version history (optional but recommended)

If CHANGELOG.md doesn't exist, offer to create a template:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [{version}] - {date}

### Added
- Initial release
```

### 6. Validate Dependencies

Check the gemspec dependencies against the Gemfile:
- Ensure all runtime dependencies are in gemspec
- Verify version constraints are appropriate

If using `huh` from GitHub, warn:

```
Note: 'huh' is installed from GitHub. For gem publishing, ensure
users can install it. Add installation note to README.
```

### 7. Run Pre-flight Checks

Execute validation commands:

```bash
# Validate gemspec syntax
ruby -e "require 'rubygems'; spec = Gem::Specification.load('{gemspec}'); puts 'Gemspec valid!'"

# Check for uncommitted changes (optional)
git status --porcelain
```

### 8. Build the Gem

Build the gem file:

```bash
gem build {project-name}.gemspec
```

Verify the .gem file was created and show its size:

```
✓ Built {project-name}-{version}.gem (12.5 KB)
```

### 9. Display Publishing Instructions

Show the final steps to publish:

```
✅ Package ready for publishing!

To publish to RubyGems.org:

  1. Create account at https://rubygems.org/sign_up (if needed)

  2. Configure credentials:
     gem signin

  3. Push the gem:
     gem push {project-name}-{version}.gem

  4. Tag the release in git:
     git tag v{version}
     git push origin v{version}

After publishing, users can install with:
  gem install {project-name}
```

### 10. Checklist Summary

Display a summary checklist:

```
Pre-publish Checklist:

✓ Gemspec validates successfully
✓ Version set to {version}
✓ Author and email configured
✓ Homepage URL set
✓ License specified
✓ README.md exists
✓ Executables are executable
✓ Gem builds successfully

{Optional warnings if any}

Ready to publish!
```

## Common Issues

### "Couldn't find {project-name}.gemspec"

The gemspec file name must match the gem name exactly.

### "License identifier unknown"

Use standard SPDX license identifiers: MIT, Apache-2.0, GPL-3.0, etc.

### "Homepage has no value"

Set a valid URL, typically the GitHub repository.

### Permission denied on executable

Run `chmod +x bin/{executable}` to fix.

### Git not clean

Commit all changes before publishing to ensure the gem includes latest code:
```bash
git add -A && git commit -m "Prepare v{version} release"
```
