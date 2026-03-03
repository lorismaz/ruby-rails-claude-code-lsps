---
description: Scaffold a reactive resource with Turbo Morphing, View Transitions, and optimistic UI
argument-hint: ResourceName [toggle_field:boolean ...]
allowed-tools: Bash(rails generate*), Bash(rails stimulus:manifest:update), Bash(rails db:migrate)
---

# Scaffold Reactive Resource

You are scaffolding a new reactive Rails resource using Turbo Morphing, the View Transitions API, and Stimulus optimistic UI patterns.

**Resource**: $ARGUMENTS

## Instructions

Parse the arguments:
- First argument: the resource name (e.g., `Task`, `Item`, `Note`)
- Remaining arguments: model fields in Rails generator format (e.g., `completed:boolean`, `name:string`)
- Identify any boolean fields — these are candidates for toggle actions

## Step 1: Preflight Checks

1. Verify the application layout (`app/views/layouts/application.html.erb`) contains:
   ```html
   <meta name="view-transition" content="same-origin">
   ```
   If missing, add it inside the `<head>` tag.

2. Check if `app/javascript/controllers/toggle_attribute_controller.js` exists.
   If missing, create it:
   ```javascript
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
   Then run `rails stimulus:manifest:update`.

## Step 2: Generate Model & Migration

Run the Rails model generator with the provided fields:
```
rails generate model ResourceName field1:type field2:type ...
```

Run `rails db:migrate`.

## Step 3: Create Controller

Create `app/controllers/resources_controller.rb` with:
- `index` action that loads records (separate active/completed if there's a boolean toggle field)
- `create` action that saves and `redirect_to` the index (NOT render)
- `update` action that updates and `redirect_to` the index
- `destroy` action that destroys and `redirect_to` the index
- For each boolean toggle field, a `toggle` action:
  ```ruby
  def toggle
    @resource.update!(field: !@resource.field)
    redirect_to resources_path
  end
  ```
- All mutation actions MUST use `redirect_to`, never `render` (except for validation errors on update which can render :edit)

## Step 4: Configure Routes

Add to `config/routes.rb`:
```ruby
resources :resource_name_plural, except: [:show] do
  member do
    patch :toggle  # for each boolean toggle field
  end
end
```

## Step 5: Create Index View

Create `app/views/resources/index.html.erb`:
- MUST start with `<% turbo_refreshes_with method: :morph, scroll: :preserve %>`
- Include a form for creating new records
- Render the collection of records using partials

## Step 6: Create Partial

Create `app/views/resources/_resource.html.erb`:
- Container element MUST use `id: dom_id(resource)`
- Container MUST set `style: "view-transition-name: #{dom_id(resource)}; view-transition-class: resource_name"`
- For boolean toggle fields:
  - Add `aria: { checked: resource.field? }` (or appropriate aria attribute)
  - Add `data: { controller: "toggle-attribute", toggle_attribute_attribute_value: "aria-checked" }`
  - Add `class: "group ..."` to the container
  - Use `group-aria-checked:*` Tailwind variants for children to reflect state
  - Wire toggle button with `data: { action: "click->toggle-attribute#toggle" }`
  - Use `button_to toggle_resource_path(resource), method: :patch` for the toggle form

## Step 7: Create Edit View (optional)

If the resource has editable text fields, create `app/views/resources/edit.html.erb` using a Turbo Frame:
```erb
<%= turbo_frame_tag dom_id(@resource, :name) do %>
  <%= form_with model: @resource do |f| %>
    <%# form fields %>
  <% end %>
<% end %>
```

## Step 8: Update Stimulus Manifest

Run `rails stimulus:manifest:update` to ensure all controllers are registered.

## Summary

After completion, list all files created and modified:
- Model file
- Migration file
- Controller file
- Routes update
- Index view
- Partial
- Edit view (if created)
- Stimulus controller (if created)
- Stimulus manifest (if updated)
