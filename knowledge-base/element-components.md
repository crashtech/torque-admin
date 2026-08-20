# Torque Admin Element Components

## Overview

`app/elements/*.rb` are the concrete, pre-built UI components shipped with Torque Admin — subclasses of `Torque::Elements::Base` (see `elements-architecture.md` for the node/render machinery, and `ui-builder-and-helpers.md` for the `ui.*` helpers they dispatch to). Current as of 2026-08-16: Menu, Breadcrumb, Buttons and Table are all on the unified core (Table landed through `projects/04-table-element.md`, stages 1–4).

## `BaseElement` — pure abstract marker

```ruby
class BaseElement < Elements::Base
  self.abstract_class = true
end
```

That's the entire file. It exists so admin elements share a common app-level root (and a future hook point — see the `Extended` revival candidates in `projects/ideas.md`). All real behavior lives in `Torque::Elements::Base` and its `Core::*` mixins.

## `ButtonsElement` — converted, implemented

Grammar and settings:

```ruby
node :button, as: :link
node :group
node :divider, as: :basic
setting :sort, :icons, :icons_only
```

DSL: `group(identifier, label = nil, **, &)` (label defaults to the identifier), `item(identifier, href_or_label, href = nil, **, &)` — normalizes the href/label pair, applies `settings(:icons)` lookup, suppresses labels under `icons_only?`, and delegates to the generated `button` method. `icons_only!`/`icons_only?`.

Rendering: `render_button(node, content, **options)` is the element-method dispatch hook (stage 2 of render dispatch) — it calls `ui.buttons_button(content, grouped: !node.parent.equal?(self), **options)`, so a button inside a `:group` renders as a menu item inside the theme's dropdown (`Themes::SemanticUI#buttons_group`/`#buttons_button`). `titlelize_text_for?` titleizes `:label` fallbacks.

Used every request as `@page_actions` (built by `PageActionsController`).

## `BreadcrumbElement` — converted, implemented, powered by `ItemsFromAction`

```ruby
node :item, as: :link
node :divider, as: :basic
setting :auto_dividers
```

Includes `Torque::Admin::ItemsFromAction` (`import_from_current_action` alias) — the auto-import of the trail (home → section → chained resource ancestors → current action) from controller/route-annotation state is where the real behavior lives; see `admin-architecture.md`.

Own DSL: `home(label = nil)` (prepends an item pointing at `url_for(:root)`), `section(label, href_or_name = nil)` (resolves the current route's `:section` annotation to `<section>_dashboard#index`), `item` (auto-inserts a divider between items when `auto_dividers?`; resolves `href_or_label == true` via `action_label_for`), `divider(content = nil)` (default content `'/'` or `divider_content`), `pop`. `auto_dividers?` falls back to the theme flag `ui.breadcrumb_with_dividers`.

Name is singular following MDN/W3C usage.

## `MenuElement` — converted, implemented, powered by `ItemsFromRouter`

The reference example of the **one-logical-many-physical** pattern:

```ruby
class ItemNode < Elements::LinkNode
  # at sanitize time (content already built): inject dropdown: true when the item
  # has children content, honoring settings(:dropdowns)
end

node :item, as: ItemNode, render: :menu_entry
node :divider, as: :basic
setting :sort, :icons, :dropdowns, :detect_current
```

`ItemNode` computes the *logical* flags; the *physical* composition (plain `menu_item` vs `menu_header` + `submenu`, dropdown vs side-by-side) lives in the hand-written `Helpers::SemanticUI#menu_entry` ui helper — the `render: :menu_entry` dispatch target.

Own DSL: `item(identifier, href_or_label = nil, href = nil, **, &)` (aliased `import_item`) — reindexes an existing same-id node to `<id>-container` when a submenu is declared under it; icon lookup from `settings(:icons)`. `current_link_setting` → `settings(:detect_current)` (consumed by `LinkNode#active?`; `BaseController` sets `detect_current: true` for `main_menu` and `:current_page_prefix?` for `secondary_menu`). `load_config!` applies label sorting when `settings(:sort)` (tagged `# TODO: Maybe turn this into a callback`). `links` returns all indexed `LinkNode`s.

Real power comes from `ItemsFromRouter` (`import_from_routes` / `import_from_sections` aliases): walking the Rails route set (GET, no required params, allowed actions, section/authentication annotations) to auto-build the nav tree. See `admin-architecture.md`.

## `TableElement` (Project 4 — stages 1–4 landed)

```ruby
node :column, as: :column, renders: false, parts: Elements::ColumnNode::UNITS   # col header cell footer
node :actions, as: ButtonsElement

setting :as, :primary_key, :source_type, :sortable, :paginate, :read_mode, :tbody
node :pagination, as: PaginationElement, index: false   # auto-added in initialize when `paginate` is on; rendered as `after:` content
```

The logical structure is its columns; rows and cells are never nodes. `content` (overridden) walks the columns **once** collecting `STRUCTURE` parts (`colgroup: :col, thead: :header, tfoot: :footer`, cached by `render_part`), then `render_section` per tag and **`render_tbody(entries, columns)`** / `render_row(entry, columns)` — kept standalone so Hotwire can later append one `<tbody>` per page plus a skeleton one. Value access uses a `read_mode` inferred once (`:call` for a `CollectionState` over a relation, `:json` otherwise; `:hash`/`:dig` on request). There are no `render_column_*` element methods any more: `ColumnNode#dispatch_part` composes the arguments (`part_arguments`: label / `element.value_for` / `element.summary_for`) and options (`col_options`, `header_options`, unit options) itself, so a part goes node → view helper `render_table_column_#{part}` → `ui.table_column_#{part}` (defaults in `ui/defaults.rb`, SemanticUI overrides `table_column_header`). The table's own sections are parts too — `invoke_part_render(:colgroup | :thead | :tbody | :tfoot | :row, …)` → `ui.table_colgroup/thead/tbody/tfoot/row` — no `render_section`, no cache.

DSL (see `projects/04-table-element.md` for the settled reasoning):

- `column(identifier, from: nil, **kwargs, &block)` — `from:` names an association (one level: `t.column :name, from: :project` → id `project_name`, label "Project Name", value read through the association, sortable through `sort[project][name]`); a bare association column (`t.column :project`) renders the record's title (`implicit_resource_title_for` → `title_methods`) linked to its admin show page when the route exists. First argument is the **value source** (method or hash key, not necessarily a DB column; kept verbatim as `ColumnNode#source` because ids are dasherized); `label:` is the only verbatim override (defaults to the identifier, textified through the usual i18n chain with `implicit_attribute_for?` → `human_attribute_name`); every other kwarg is the formatter's namespace (`ColumnNode#formatter_options`, frozen); `as:` picks the formatter — a Symbol resolves through the view `formatter` proxy to a `format_as_<name>` helper (`projects/03-formatting.md`; unknown → `NoMethodError`), a block is a formatter receiving the entry, none → `formatter_for(value)` inference (Date/Time, admin adds record/count); `fallback:` runs after formatting (block receives nothing), all inside `Formatter#format`. Unit options either nested (`header: { class: … }`) or chained (`t.column(:x).header(class: …).cell(…)`) — `column` returns the `ColumnNode`, whose `to_s` is `''`.
- `footer(identifier, content: nil, aggregate: nil, all: nil, as: nil, **formatter_kwargs, &block)` — stored as the column's `summary` setting via `ColumnNode#summarize`; the column must exist. Aggregates use ActiveRecord's vocabulary (`sum count minimum maximum average`). `all:` defaults to `true` on a `CollectionState` over a relation and goes through **`CollectionState#aggregate(*requests)`** — one batched `pluck` of Arel aggregate nodes over the unpaginated/unordered scope, memoized (`TableSummaries#prefetch_aggregates` requests every footer at once before tfoot renders); `all: false` (and plain enumerables) run in Ruby over the entries (`sum count minimum maximum`). Lives in the `Torque::Admin::TableSummaries` concern so hosts can override.
- `each_row { |entry| { class: … } }` — hash-returning; per row the table appends `Elements::Deferred.new(block, entry)` under `'@append'` and the option system resolves it while flattening.
- `actions(*actions, column: :actions) { |entry| … }` — symbols become items whose `href` is one `Elements::Deferred.new(:relative_path_for, action, id: entry_proxy)` (the proxy is a `SimpleDelegator` the table retargets per row; `to_param` delegates to the entry); the block is `instance_exec`'d on the buttons interface with the proxy as its argument, so per-row values are plain closures (`if: -> { entry.id.odd? }`); with neither, `view_context.default_table_actions` (`IndexController#default_table_actions(*list, extras: %i[destroy])`: `list` defaults to the resource member actions, ordered as `action_methods`, then `extras` that exist) is imported. Each `column:` is an unindexed (`index: false`) `ButtonsElement` child plus a regular label-less `ColumnNode` whose formatter is `proc { element.render_in(reset: true) }` — so actions ride the same single structural pass as data columns.
- Sorting — the table holds no URL logic and no per-column logic: `TableElement#column` forces `sortable: false` on every column when the table itself is not sortable (declaration-time, like Buttons' `icons`), and `TableElement#sorting` hands the state's `Sorting` struct (`values`/`sortable`/`href` — the controller's method references) to the columns. `ColumnNode#sortable?` (explicit setting, else `sorting.sortable.call(attribute, reflection:)`), `#sorting_options` (`direction:` from `sorting.values[[reflection, attribute]]`, `href:` from `sorting.href.call`), `#stretch?` (explicit, else `title_methods` of the controller's admin config) and `#header_options` all live on the node. Value reading is `Torque::Elements::ValueReader` (`read_value_for(source, attribute, from:)`, `read_mode` memoized from `default_read_mode`, which the table overrides: relation-backed `CollectionState` → `:call`, else `:json`).

`IndexController#define_table_element` is live again; `app/templates/resource/index.html.erb` emits `<%%= @primary_element %>` so the table shows on index pages. `RowsFromEntries` and `_row.html.erb` are gone. Not yet: `selection`, `row_number` special columns, streaming/skeleton, single-query aggregates, Bootstrap/Bulma table vocabulary.

## `PaginationElement` (`< ButtonsElement`)

```ruby
node :per, as: :link     # plus button/group/divider inherited from Buttons
setting :window
```

Subclassing Buttons gives it `item`, icons (`icons:` setting, `icons_only!`), groups and dividers for free; the root dispatches to `ui.pagination`, page buttons to `ui.pagination_button`, and per-page choices are a second node type dispatching to `ui.pagination_per` (defaults: `<nav aria-label>` + `<a>`/`<span aria-current aria-disabled>`; SemanticUI: `menu(pagination: true)` + `menu_item`). `PaginationElement.new(name, pagination:, window: 2)`: `import_from_pagination` adds first / previous / page numbers with `…` gaps (page mode only) / next / last (page mode only); `import_per_options` adds one `per` node per `per_options` value. `TableElement` declares `node :pagination, as: PaginationElement, index: false` and adds one in `initialize` calling both (`paginate` setting, on when the state provides `:pagination`); `sanitized_options!` appends it as `after:` content.

## Templates (`app/templates/resource/*.html.erb`)

"Unbound" macro templates (see `elements-architecture.md` → Template system): executed once per virtual path to generate the source of the real bound template; `<%%= %>` writes literal ERB into that source.

- **`index.html.erb`** — the `content_for(:page_actions)` wiring (with a `TODO: Improve for compilation`), then `<%%= @primary_element if defined?(@primary_element) %>` — the one line that puts the table on the page. Declares `locals: (primary_element: nil, **)`.
- **`show.html.erb`** — only the `page_actions` wiring.
- **`new.html.erb`** / **`edit.html.erb`** — empty stubs (locals annotation only).

Index pages render the table; the rest is still frame + banner + menus + breadcrumb chrome.

## Frames (`app/views/frames/*.html.erb`)

Body-region layouts (not full `<html>` documents) built with `ui.rows`/`ui.columns` grid helpers; selected via the `frame` controller macro and rendered by `FrameRenderer` (see `elements-architecture.md`).

- **`classic.html.erb`** — vertical stack: `main_menu(preset: :primary_horizontal)` with `app_banner`, `app_page_banner`, `app_page_content { yield }`, `app_page_footer`. **The default** — `BaseController` declares `frame 'classic'`.
- **`modern.html.erb`** — `secondary_menu` top bar + `main_menu(preset: :primary_vertical)` sidebar + banner/content/footer column. Referenced by `UiBuilder::Defaults#menu_sections_for`, which only returns the current route's section for `:main_menu` when `current_frame == 'frames/modern'` (section-scoped sidebar behavior).
- **`sidebar.html.erb`** — vertical `main_menu` (banner folded in) + banner/content/footer column. Complete, unreferenced by default.
- **`minimal.html.erb`** — empty (0 bytes), unreferenced.

The dummy app also demonstrates a host-app frame at `app/views/frames/example.html.erb`.

## Summary

| Element / Template | Status |
|---|---|
| `BaseElement` | Pure abstract marker |
| `ButtonsElement` | Implemented (unified core; `render_button` hook) |
| `BreadcrumbElement` | Implemented (unified core; via `ItemsFromAction`) |
| `MenuElement` | Implemented (unified core; `ItemNode` + `ui.menu_entry`; via `ItemsFromRouter`) |
| `TableElement` (+ `Elements::ColumnNode`) | Implemented (unified core; columns/parts, footers, `each_row`, row actions, sorting) |
| `index.html.erb` | `page_actions` wiring + `@primary_element` |
| `show.html.erb` | `page_actions` wiring only |
| `new.html.erb` / `edit.html.erb` | Empty stubs |
| `frames/classic.html.erb` | Implemented, the default |
| `frames/modern.html.erb` | Implemented; drives section-scoped `menu_sections_for` |
| `frames/sidebar.html.erb` | Implemented, unreferenced |
| `frames/minimal.html.erb` | Empty, unreferenced |
