---
name: reactive-rails-ui
description: Build smooth, reactive Rails UIs using Turbo Morphing, the View Transitions API, and Stimulus optimistic UI patterns. Activate when the user is working on a Rails app and wants responsive, SPA-like interactions without client-side state management.
---

# Reactive Rails UI

Three techniques that combine to make standard Rails redirect-based controllers feel as responsive as a SPA — with zero client-side state management:

1. **Turbo Morphing** — diffs the DOM instead of replacing it, preserving scroll position and focus
2. **View Transitions API** — browser-native cross-fade animations between page states
3. **Stimulus Optimistic UI** — instant visual feedback via aria-attribute toggling before the server responds

Together, they let you keep simple CRUD controllers that `redirect_to` after every mutation — no Turbo Streams, no Turbo Frames (except for inline editing), and no client-side state.

## Prerequisites & Setup

- **Rails 8+** with Turbo (included by default)
- **Stimulus** (included by default)
- **Tailwind CSS** (for `group-aria-*` utility variants)
- **Importmaps** or any JS bundler

### One-time layout setup

Add the View Transitions meta tag to your application layout:

```erb
<%# app/views/layouts/application.html.erb %>
<head>
  <!-- ... existing tags ... -->
  <meta name="view-transition" content="same-origin">
</head>
```

This opts the entire application into the View Transitions API for same-origin navigations.

---

## Technique 1: Turbo Morphing

Instead of replacing the entire `<body>`, Turbo Morphing diffs the old and new DOM and applies only the changes — like a server-side virtual DOM. This preserves scroll position, focus state, and CSS transitions.

### View declaration

At the top of any index/listing view:

```erb
<%# app/views/resources/index.html.erb %>
<% turbo_refreshes_with method: :morph, scroll: :preserve %>
```

### Controller pattern

All mutation actions (`create`, `update`, `destroy`, and custom actions like `toggle`) use `redirect_to` instead of rendering or returning Turbo Streams:

```ruby
class TodosController < ApplicationController
  before_action :set_todo, only: %i[edit update toggle destroy]

  def index
    @todo = Todo.new
    @active_todos = Todo.active.ordered
    @completed_todos = Todo.completed.ordered
  end

  def create
    @todo = Todo.new(todo_params)

    if @todo.save
      redirect_to todos_path
    else
      redirect_to todos_path, alert: @todo.errors.full_messages.to_sentence
    end
  end

  def update
    if @todo.update(todo_params)
      redirect_to todos_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle
    @todo.update!(completed: !@todo.completed)
    redirect_to todos_path
  end

  def destroy
    @todo.destroy!
    redirect_to todos_path
  end

  private

  def set_todo
    @todo = Todo.find(params[:id])
  end

  def todo_params
    params.require(:todo).permit(:name)
  end
end
```

### Routes

```ruby
resources :todos, except: [:show] do
  member do
    patch :toggle
  end
end

root "todos#index"
```

### Why this works

Because every mutation redirects to the same `index` action, Turbo Morphing diffs the full page and applies only the changes. No Turbo Streams, no partial re-rendering — just a standard redirect.

---

## Technique 2: View Transitions API

The View Transitions API provides browser-native crossfade animations when DOM elements change position or state. Combined with Turbo Morphing, this creates smooth animations for reordering, appearing, and disappearing elements.

### Partial setup

Every record partial MUST:
1. Use `dom_id(record)` as the element's `id`
2. Set `view-transition-name` to a unique value (use `dom_id`)
3. Set `view-transition-class` to group elements for shared transition rules

```erb
<%# app/views/todos/_todo.html.erb %>
<%= tag.div id: dom_id(todo),
    data: {
      controller: "toggle-attribute",
      toggle_attribute_attribute_value: "aria-checked",
    },
    aria: { checked: todo.completed? },
    class: "group flex items-center gap-3 px-4 py-3 transition-colors hover:bg-gray-50 aria-checked:opacity-60",
    style: "view-transition-name: #{dom_id(todo)}; view-transition-class: todo" do %>

  <%# ... content ... %>

<% end %>
```

### Key rules

- `view-transition-name` MUST be unique per element on the page — `dom_id(record)` guarantees this.
- `view-transition-class` groups elements that share the same transition animation.
- The `group` Tailwind class on the container enables `group-aria-*` variants on children.

### Optional CSS customization

You can customize transition animations:

```css
::view-transition-group(.todo) {
  animation-duration: 0.3s;
}
```

---

## Technique 3: Stimulus Optimistic UI

The server round-trip takes ~100-300ms. Without optimistic UI, the user sees no feedback until the server responds. The optimistic UI pattern toggles an aria attribute immediately on click, providing instant visual feedback.

### Stimulus controller

```javascript
// app/javascript/controllers/toggle_attribute_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    attribute: String
  }

  toggle(event) {
    const currentValue = this.element.getAttribute(this.attributeValue)
    const isTrue = currentValue === "true"
    this.element.setAttribute(this.attributeValue, (!isTrue).toString())
  }
}
```

This controller is **generic** — it works with any boolean aria attribute (`aria-checked`, `aria-expanded`, `aria-selected`, `aria-pressed`, etc.).

### HTML wiring

```erb
<%= tag.div id: dom_id(todo),
    data: {
      controller: "toggle-attribute",
      toggle_attribute_attribute_value: "aria-checked",
    },
    aria: { checked: todo.completed? },
    class: "group ..." do %>

  <%= button_to toggle_todo_path(todo),
      method: :patch,
      data: { action: "click->toggle-attribute#toggle" },
      form: { class: "flex" } do %>
    <%# Unchecked state — visible when aria-checked is false %>
    <span class="inline-flex group-aria-checked:hidden ...">
      <%# empty circle %>
    </span>

    <%# Checked state — visible when aria-checked is true %>
    <span class="hidden group-aria-checked:inline-flex ...">
      <%# checkmark %>
    </span>
  <% end %>

  <span class="truncate group-aria-checked:line-through group-aria-checked:text-gray-400">
    <%= todo.name %>
  </span>
<% end %>
```

### How it works

1. User clicks the toggle button
2. Stimulus immediately flips `aria-checked` on the container div
3. Tailwind's `group-aria-checked:*` variants instantly update child styling
4. Meanwhile, `button_to` submits the form to the server
5. Server updates the record and redirects back
6. Turbo Morphing diffs the page — the attribute now matches the server state
7. View Transitions animate any element movement (e.g., todo moving between lists)

---

## Checklist for a New Resource

When adding reactive UI to a new resource, follow these steps:

1. **Layout**: Ensure `<meta name="view-transition" content="same-origin">` is in your application layout
2. **Model**: Create the model with any boolean/state fields needed for toggling
3. **Controller**: Write a standard CRUD controller where all mutation actions (`create`, `update`, `destroy`, custom toggles) use `redirect_to` back to the index
4. **Routes**: Add `resources` with any custom `member` routes for toggle actions
5. **Index view**: Add `<% turbo_refreshes_with method: :morph, scroll: :preserve %>` at the top
6. **Partial**: For each record partial:
   - Use `dom_id(record)` as the element `id`
   - Set `style: "view-transition-name: #{dom_id(record)}; view-transition-class: <group>"`
   - Add aria attributes reflecting server state (e.g., `aria: { checked: record.completed? }`)
   - Wire up Stimulus `toggle-attribute` controller with `data-toggle-attribute-attribute-value`
   - Use `group` class on container and `group-aria-*` variants on children
7. **Stimulus**: Create `toggle_attribute_controller.js` if it doesn't already exist (it's generic and reusable)
8. **Manifest**: Update the Stimulus manifest (`rails stimulus:manifest:update`)

---

## Adapting to Other Use Cases

The three techniques are not limited to todo-style toggles. Here are other patterns:

### Accordion (expand/collapse)

```erb
<%= tag.div data: {
      controller: "toggle-attribute",
      toggle_attribute_attribute_value: "aria-expanded",
    },
    aria: { expanded: false },
    class: "group" do %>
  <button data-action="click->toggle-attribute#toggle">
    <span class="group-aria-expanded:rotate-90 transition-transform">▶</span>
    Section Title
  </button>
  <div class="hidden group-aria-expanded:block">
    Content here...
  </div>
<% end %>
```

### Tabs (selection)

Use `aria-selected` with the same Stimulus controller. Each tab button toggles its own `aria-selected` attribute.

### Inline editing with Turbo Frames

For inline editing, wrap the editable content in a Turbo Frame:

```erb
<%= turbo_frame_tag dom_id(record, :name) do %>
  <span><%= record.name %></span>
  <%= link_to edit_resource_path(record) %>
<% end %>
```

The edit view renders inside the frame without a full page navigation.

---

## Common Pitfalls

1. **Missing `dom_id`**: Every record element MUST have `id: dom_id(record)` for Turbo Morphing to correctly diff elements. Without it, Turbo replaces instead of morphing.

2. **Duplicate `view-transition-name`**: Each `view-transition-name` must be unique on the page. Using `dom_id(record)` guarantees uniqueness. If you render the same record twice (e.g., in two lists), you'll get broken transitions.

3. **Forgotten morph declaration**: Without `turbo_refreshes_with method: :morph, scroll: :preserve` at the top of the view, Turbo falls back to full-page replacement, losing scroll position and breaking animations.

4. **Rendering instead of redirecting**: Mutation actions MUST `redirect_to` the index path — not `render`. Rendering skips the morph pipeline and breaks the pattern.

5. **Stale Stimulus manifest**: After creating a new Stimulus controller, run `rails stimulus:manifest:update` or the controller won't be registered. When using the Rails generator (`rails generate stimulus toggle_attribute`), the manifest is updated automatically.

6. **Browser support**: The View Transitions API is supported in Chromium-based browsers (Chrome, Edge, Arc, Brave). Firefox and Safari have partial/no support as of early 2025. The UI still works without it — transitions just won't animate.

7. **Missing `group` class**: The `group-aria-*` Tailwind variants only work when an ancestor has the `group` class. Make sure the container div (the one with the aria attribute) has `class="group ..."`.

---

## Reference

- [Smooth UI Animations on Server-Rendered HTML](https://blog.siami.fr/smooth-ui-animations-on-server-rendered-html) — the blog post describing these techniques
- [Intrepidd/rails-hotwire-todo-app](https://github.com/Intrepidd/rails-hotwire-todo-app) — reference implementation
- [Turbo Morphing docs](https://turbo.hotwired.dev/handbook/page_refreshes) — official Turbo page refresh documentation
- [MDN View Transitions API](https://developer.mozilla.org/en-US/docs/Web/API/View_Transitions_API) — browser API reference
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction) — Stimulus framework documentation
- [Tailwind group-aria variants](https://tailwindcss.com/docs/hover-focus-and-other-states#aria-states) — Tailwind aria state variants
