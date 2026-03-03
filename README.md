# Rails Claude Code Plugins

A curated marketplace of Ruby and Rails plugins for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). LSP servers, CLI tooling, and reactive UI patterns — everything you need for a productive Rails development experience.

## Included Plugins

| # | Plugin | Type | Description |
|---|--------|------|-------------|
| 1 | **ruby-lsp** | LSP | Code intelligence, diagnostics, and navigation for Ruby files |
| 2 | **herb-lsp** | LSP | ERB template intelligence, diagnostics, and navigation |
| 3 | **rubocop-lsp** | LSP | Ruby linting diagnostics and auto-correction |
| 4 | **stimulus-lsp** | LSP | Hotwire Stimulus controller intelligence for HTML and ERB |
| 5 | **solargraph** | LSP | Ruby code intelligence, completion, and documentation |
| 6 | **charm-ruby** | Skill + Commands + Agent | Build beautiful, interactive CLI tools in Ruby using the charm-ruby ecosystem |
| 7 | **reactive-rails-ui** | Skill + Command + Agent | Turbo Morphing, View Transitions, and Stimulus optimistic UI patterns |

## Installation

### 1. Add the marketplace to Claude Code

Open Claude Code and run `/plugins`, then select **Add Marketplace** and enter:

```
lorismaz/rails-claude-code-plugins
```

### 2. Enable plugins

After adding the marketplace, select the plugins you want to enable from the list. Or add them manually to your settings (`~/.claude/settings.json` for global, `.claude/settings.json` for per-project):

```json
{
  "enabledPlugins": {
    "ruby-lsp@rails-claude-code-plugins": true,
    "herb-lsp@rails-claude-code-plugins": true,
    "rubocop-lsp@rails-claude-code-plugins": true,
    "stimulus-lsp@rails-claude-code-plugins": true,
    "solargraph@rails-claude-code-plugins": true,
    "charm-ruby@rails-claude-code-plugins": true,
    "reactive-rails-ui@rails-claude-code-plugins": true
  }
}
```

### 3. Restart Claude Code

The enabled plugins will be available immediately after restart.

---

## LSP Servers

Five language server integrations that give Claude Code full code intelligence for Ruby and Rails projects.

| Plugin | Install prerequisite | File types |
|--------|---------------------|------------|
| **ruby-lsp** | `gem install ruby-lsp` | `.rb`, `.rbw`, `.rake`, `.gemspec` |
| **herb-lsp** | `npm i -g @herb-tools/language-server` | `.erb` |
| **rubocop-lsp** | `gem install rubocop` | `.rb` |
| **stimulus-lsp** | `npm i -g stimulus-language-server` | `.html`, `.erb` |
| **solargraph** | `gem install solargraph` | `.rb`, `.rake`, `.gemspec` |

### What You Get

- **Go to Definition** — jump to where a method, class, or variable is defined
- **Find References** — find all usages of a symbol across your codebase
- **Hover** — see documentation, type info, and method signatures
- **Diagnostics** — real-time linting errors and warnings
- **Document Symbols** — list all classes, methods, and constants in a file
- **Workspace Symbols** — search for symbols across your entire project

### Choosing Between ruby-lsp, solargraph, and rubocop-lsp

- **ruby-lsp** — Shopify's modern Ruby LSP. Best all-around choice for navigation and diagnostics.
- **solargraph** — Excellent for documentation lookup and type inference via YARD annotations.
- **rubocop-lsp** — Focused on linting. Use alongside ruby-lsp or solargraph for style enforcement.

A good default setup for Rails projects:

```json
{
  "enabledPlugins": {
    "ruby-lsp@rails-claude-code-plugins": true,
    "herb-lsp@rails-claude-code-plugins": true,
    "stimulus-lsp@rails-claude-code-plugins": true
  }
}
```

---

## Charm Ruby — CLI Tooling

Build beautiful, interactive command-line applications in Ruby using the [charm-ruby](https://charm-ruby.dev) ecosystem (Bubble Tea, Lipgloss, Bubbles, Huh, and more).

### Skill

The **charm-ruby-development** skill activates when you ask about building CLI tools in Ruby. It provides comprehensive knowledge of the Bubble Tea MVU architecture, Lipgloss styling, component integration, and gem distribution.

### Commands

| Command | Description |
|---------|-------------|
| `/charm:init [name]` | Scaffold a new charm-ruby CLI project |
| `/charm:add-component [type]` | Add a Bubbles component to your project |
| `/charm:package` | Prepare your CLI for RubyGems distribution |

### Agent: CLI Architect

Expert Ruby CLI architect that helps you design application architecture, plan multi-screen navigation, and select appropriate components.

---

## Reactive Rails UI

Build smooth, reactive Rails UIs using three techniques that make standard redirect-based controllers feel as responsive as a SPA — with zero client-side state management:

1. **Turbo Morphing** — diffs the DOM instead of replacing it, preserving scroll position and focus
2. **View Transitions API** — browser-native crossfade animations between page states
3. **Stimulus Optimistic UI** — instant visual feedback via aria-attribute toggling before the server responds

Based on the patterns described in [Smooth UI Animations on Server-Rendered HTML](https://blog.siami.fr/smooth-ui-animations-on-server-rendered-html).

### Skill

The **reactive-rails-ui** skill activates when working on a Rails app and wanting SPA-like responsiveness. It provides the full technique reference, code examples, and a checklist for wiring up new resources.

### Command

| Command | Description |
|---------|-------------|
| `/scaffold-reactive-resource [Resource fields...]` | Scaffold a full reactive resource with Turbo Morphing, View Transitions, and optimistic UI |

### Agent: Reactive UI Auditor

Read-only auditor that checks an existing Rails app for correct reactive UI implementation — verifying morph declarations, dom_id usage, view transition names, Stimulus wiring, and controller redirect patterns.

### Requirements

- Rails 8+
- Turbo (included in Rails by default)
- Stimulus (included in Rails by default)
- Tailwind CSS (for `group-aria-*` utility variants)

---

## Upstream Projects

- [ruby-lsp](https://github.com/Shopify/ruby-lsp) by Shopify
- [herb](https://github.com/marcoroth/herb) by Marco Roth
- [rubocop](https://github.com/rubocop/rubocop) by the RuboCop team
- [stimulus-lsp](https://github.com/marcoroth/stimulus-lsp) by Marco Roth
- [solargraph](https://github.com/castwide/solargraph) by Fred Snyder
- [charm-ruby](https://charm-ruby.dev) by Marco Roth
- [rails-hotwire-todo-app](https://github.com/Intrepidd/rails-hotwire-todo-app) by Loris Siami

## License

MIT
