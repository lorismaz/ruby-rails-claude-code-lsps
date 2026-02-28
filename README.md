# Ruby & Rails LSP Marketplace for Claude Code

A curated collection of Ruby and Rails LSP servers packaged as [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugins. Get full language intelligence — go-to-definition, diagnostics, completions, and more — for `.rb`, `.erb`, and `.html` files directly in Claude Code.

## Included Plugins

| Plugin | Description | Install prerequisite | File types |
|--------|-------------|---------------------|------------|
| **ruby-lsp** | Code intelligence, diagnostics, navigation | `gem install ruby-lsp` | `.rb`, `.rbw`, `.rake`, `.gemspec` |
| **herb-lsp** | ERB template intelligence | `npm i -g @herb-tools/language-server` | `.erb` |
| **rubocop-lsp** | Linting diagnostics and auto-correction | `gem install rubocop` | `.rb` |
| **stimulus-lsp** | Hotwire Stimulus controller intelligence | `npm i -g stimulus-language-server` | `.html`, `.erb` |
| **solargraph** | Code intelligence, completion, documentation | `gem install solargraph` | `.rb`, `.rake`, `.gemspec` |

## Usage

### 1. Install the LSP server(s) you want

```bash
# Ruby (gems)
gem install ruby-lsp
gem install rubocop
gem install solargraph

# ERB / Stimulus (requires Node.js)
npm i -g @herb-tools/language-server
npm i -g stimulus-language-server
```

### 2. Add the marketplace to Claude Code

Open Claude Code and run `/plugins`, then select **Add Marketplace** and enter:

```
lorismaz/ruby-rails-claude-code-lsps
```

### 3. Enable plugins

After adding the marketplace, select the plugins you want to enable from the list. Or add them manually to your settings (`~/.claude/settings.json` for global, `.claude/settings.json` for per-project):

```json
{
  "enabledPlugins": {
    "ruby-lsp@ruby-rails-claude-code-lsps": true,
    "herb-lsp@ruby-rails-claude-code-lsps": true,
    "rubocop-lsp@ruby-rails-claude-code-lsps": true,
    "stimulus-lsp@ruby-rails-claude-code-lsps": true,
    "solargraph@ruby-rails-claude-code-lsps": true
  }
}
```

### 4. Restart Claude Code

The enabled LSP servers will start automatically when you work with matching file types.

## What You Get

With these LSPs enabled, Claude Code gains access to:

- **Go to Definition** — jump to where a method, class, or variable is defined
- **Find References** — find all usages of a symbol across your codebase
- **Hover** — see documentation, type info, and method signatures
- **Diagnostics** — real-time linting errors and warnings
- **Document Symbols** — list all classes, methods, and constants in a file
- **Workspace Symbols** — search for symbols across your entire project

## Choosing Between ruby-lsp, solargraph, and rubocop-lsp

These plugins serve different purposes and can be used together:

- **ruby-lsp** — Shopify's modern Ruby LSP. Best all-around choice for navigation and diagnostics.
- **solargraph** — Excellent for documentation lookup and type inference via YARD annotations.
- **rubocop-lsp** — Focused on linting. Use alongside ruby-lsp or solargraph for style enforcement.

A good default setup for Rails projects:

```json
{
  "enabledPlugins": {
    "ruby-lsp@ruby-rails-claude-code-lsps": true,
    "herb-lsp@ruby-rails-claude-code-lsps": true,
    "stimulus-lsp@ruby-rails-claude-code-lsps": true
  }
}
```

## Upstream Projects

- [ruby-lsp](https://github.com/Shopify/ruby-lsp) by Shopify
- [herb](https://github.com/marcoroth/herb) by Marco Roth
- [rubocop](https://github.com/rubocop/rubocop) by the RuboCop team
- [stimulus-lsp](https://github.com/marcoroth/stimulus-lsp) by Marco Roth
- [solargraph](https://github.com/castwide/solargraph) by Fred Snyder

## License

MIT
