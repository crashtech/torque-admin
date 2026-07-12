# Torque Admin Element Components

## Overview

`app/elements/*.rb` are the concrete, pre-built UI components shipped with Torque Admin — subclasses of `Torque::Elements::Base` (see `elements-architecture.md` for the underlying node/render/template machinery). Their completeness varies significantly: some are fully built, one is an explicit placeholder, and the table element has a real, unfixed bug in one of its code paths.

## `BaseElement` — explicit placeholder

```ruby
class BaseElement < Elements::Base
  self.abstract_class = true

  # TODO: This is just a placeholder right now
  def element_settings
    super + %i[placement]
  end
end
```

That's the entire file. All the "core rendering functionality," "lifecycle management," and "context management" that might be expected of a base element actually live in `Torque::Elements::Base` and its `Core::*` mixins (a separate class in the gem's `lib/` layer) — not here. `BaseElement` itself only adds one setting (`:placement`) on top of that.

## `ButtonsElement` — fully implemented

Superclass `BaseElement`, no extra modules. Adds `:sort, :icons, :icons_only` settings. DSL:
- `group(identifier, label = nil, **, &block)` → adds a `:group` node
- `item(identifier, href_or_label, href = nil, **, &block)` (aliased `button`) → builds a `:button` node using `Elements::LinkNode`, pulling an icon from `settings(:icons)` and a label unless `icons_only?`
- `divider` → adds a `:divider` node
- `fallback_text_for(key, value, node)` — i18n-miss text fallback, titleizing the label
- `icons_only!`/`icons_only?`

Small but complete — real node vocabulary (group/button/divider), icon lookup, `LinkNode`-based links, i18n fallback. Nothing here is a stub.

## `BreadcrumbElement` — fully implemented, powered by `ItemsFromAction`

Superclass `BaseElement`, includes `Torque::Admin::ItemsFromAction` (see `admin-architecture.md`). Adds `:auto_dividers` setting. DSL:
- `home(label = nil)` — a `:home` item pointing at `url_for(:root)`, prepended to root
- `section(label, href_or_name = nil)` — a `:section` item, resolving the current route's section annotation if not given
- `item(identifier, href_or_label = nil, href = nil, **, &block)` — auto-inserts a divider when `auto_dividers?` and children exist; resolves `href_or_label == true` into a looked-up label; uses `Elements::LinkNode` when `href` is present
- `divider(content = nil)`, `pop` (removes last root child)
- `auto_dividers!`/`auto_dividers?` (defaults to `view_context.ui.breadcrumb_with_dividers` if unset)

Most of its real power comes from the included `ItemsFromAction` concern, which drives auto-importing the breadcrumb trail from the current controller/action/route annotations (home → section → chained resource ancestors → current action), not from bespoke logic in this file.

## `MenuElement` — fully implemented, powered by `ItemsFromRouter`, the most sophisticated element

Superclass `BaseElement`, includes `Torque::Admin::ItemsFromRouter`. Adds `:sort, :icons, :dropdowns, :detect_current` settings. Has a `custom_render_for(:item)` hook (unique among the five elements) that chooses between `ui.menu_item`, `ui.menu_header`, or building dropdown submenus via `ui.submenu`. DSL:
- `item(identifier, href_or_label = nil, href = nil, **, &block)` (aliased `import_item`) — reindexes nodes into a container when nesting submenus under an existing item id; icon lookup; `LinkNode` when `href` present
- `divider`, `fallback_text_for` for item labels
- `current_link_setting` (overridden) → `settings(:detect_current)` (used by `LinkNode#active?`)
- `load_config!` (overridden) — applies label-based sorting if `settings(:sort)` (tagged `# TODO: Maybe turn this into a callback` in the source, i.e. considered provisional by the original author)
- `links` — all `LinkNode` children

Real power again comes from `ItemsFromRouter`: `import_items_from_router`/`import_from_routes` walks the entire Rails route set (filtering by verb/annotation/section) to auto-build a nested menu; `import_items_from_sections`/`import_from_sections` builds one entry per resource section.

## `TableElement` — mostly implemented, has a real bug and no pagination

Superclass `BaseElement`. Custom `initialize` requires `entries` to be `Enumerable`, wraps `@current_entry` in a `SimpleDelegator`, and infers `:sortable` from `entries.is_a?(CollectionState) && entries.provides?(:sort)`. Adds `:as, :id, :sortable, :batch_form` settings.

- `selection(label = nil, value: :id, name: :ids, input: nil, **)` — requires `settings(:batch_form)` (raises `ArgumentError` otherwise); builds a checkbox `column`
- `column(identifier, label = nil, sortable: nil, stretch: nil, **options, &block)` — the core DSL call: creates **three** nodes per column — `"#{id}.col"` (`:column`), `"#{id}.header"` (`:header`), and `identifier` (`:cell`, an `Elements::ColumnNode` sourced from `@current_entry`)
- `rows(**, &block)` — iterates `each_entry`, adding a `:row` node per entry, invoking `each_row` callbacks
- `default_sort_for`, `default_stretch_for`, `build_accessor` (chooses hash-style `[]` access vs. method access — the source of the "safe path" noted below)
- `cols`, `headers`, `cells`, `hash_accessor?`

**Real, unfixed bug**: `column`'s content resolution goes through `ColumnNode#content` (`lib/torque/elements/nodes/column_node.rb`), which dispatches on the type of `:as`. Only the `Array` case (`content_from_call`) is implemented — which is what `build_accessor` always produces for the default (no explicit `:as`) path, so ordinary `column(:name)` calls work fine. But:
- `column(:x) { block }` sets `:as` to a `Proc` → routed through `content_from_method`, which has an **empty body** and always returns `nil` (silently drops the block's content)
- `column(:x, as: :some_symbol)` → routed through `content_from_helper(name)`, which calls `content_from_method(helper)` where **`helper` is an undefined local/method** and `name` is discarded — raises `NameError`

**No pagination exists in this file at all** despite being a commonly assumed feature — `sortable` is just a boolean flag derived from `CollectionState`, not a sorting/paging engine.

A trailing comment block sketches a **future, unimplemented DSL** (`row_number`, `actions do...end`, `footer(:title, ...)`, `footer(:quantity, as: :numeric, op: :sum)`) — these are not real methods; don't document them as available.

## Templates (`app/templates/resource/*.html.erb`)

These are "unbound" macro templates (see `elements-architecture.md` → Template system) rendered once to generate the real, bound template's source.

- **`index.html.erb`** — 4 real lines: a `content_for(:page_actions)` wiring for `@page_actions`, then `<%= render 'table' %>` (written escaped, `<%%= ... %>`, since this file itself generates that ERB as output).
- **`_table.html.erb`** — the actual partial `index.html.erb` renders. Live code is just:
  ```erb
  <%= @table.render do |t| %>
    <colgroup>
    </colgroup>
  <% end %>
  ```
  with a commented-out line (`<%# @table.cols.each { |node| concat node.render } %>`) showing the intended iteration. **The block body does nothing with `t`** — an empty `<colgroup>`. `TableElement`'s `cols`/`headers`/`cells` accessors exist but aren't actually wired into rendering here; `IndexController#define_table_element` (`app/controllers/index_controller.rb`) carries its own TODO acknowledging index is unfinished. `@table` is a real `TableElement` instance, confirmed via `IndexController` (`provide_template_ivars :@table`, `define_table_element` building `TableElement.new(...)`), but the partial under-uses it.
- **`edit.html.erb`** and **`new.html.erb`** — each is a single line, just the ERB locals comment (`<%# locals: (**) -%>`). **Completely empty, pure stubs**, no body content.
- **`show.html.erb`** — 4 lines, only the same `page_actions` `content_for` wiring as `index.html.erb`. No other content.

Don't describe these five templates as rendering meaningful UI by default — three of five (edit/new/show) render essentially nothing beyond boilerplate, and the table partial's per-column rendering loop is commented out.

## Frames (`app/views/frames/*.html.erb`)

Full-page body-region layouts (not complete `<html>` documents) built with the Elements UI-grid helpers (`ui.rows`/`ui.columns`) — see `elements-architecture.md` → Frame system for how `frame.rb`/`FrameRenderer` select and wrap these around a page's real template.

- **`classic.html.erb`** — single-column vertical stack (`ui.rows('min-content', 'min-content', '1fr', 'min-content', as: :body, ...)`): `elements.main_menu(preset: :primary_horizontal, as: :header, prepend: app_banner)`, `app_page_banner`, `app_page_content { yield }`, `app_page_footer`. **This is the only frame actually wired up anywhere** — `BaseController` calls `frame 'classic'` explicitly.
- **`minimal.html.erb`** — **completely empty, 0 bytes.** Not referenced by name anywhere else in the codebase. Would render blank if ever selected.
- **`modern.html.erb`** — two-row grid: a horizontal `elements.secondary_menu` bar on top, then a two-column split below (`elements.main_menu(preset: :primary_vertical)` sidebar + a nested rows layout with banner/content/footer). Top bar + left nav + content.
- **`sidebar.html.erb`** — two-column grid: `elements.main_menu(preset: :primary_vertical, prepend: app_banner)` as the left column (banner folded into the menu itself), nested rows (banner/content/footer) as the content column. Left nav + content, no separate top header bar.

## Summary

| Element / Template | Status |
|---|---|
| `BaseElement` | Explicit placeholder (one setting) |
| `ButtonsElement` | Fully implemented |
| `BreadcrumbElement` | Fully implemented (via `ItemsFromAction`) |
| `MenuElement` | Fully implemented, most sophisticated (via `ItemsFromRouter`) |
| `TableElement` | Mostly implemented; `ColumnNode`'s non-default content paths are broken; no pagination; documented future DSL not implemented |
| `index.html.erb` | Minimal — wires `page_actions` + renders `_table` |
| `_table.html.erb` | Renders `@table` but with an empty, non-iterating block body |
| `edit.html.erb` / `new.html.erb` | Completely empty stubs |
| `show.html.erb` | Minimal — only `page_actions` wiring |
| `frames/classic.html.erb` | Implemented and the only one actually used |
| `frames/modern.html.erb`, `sidebar.html.erb` | Implemented, structurally complete, but unreferenced by any controller today |
| `frames/minimal.html.erb` | Empty (0 bytes), unreferenced |
