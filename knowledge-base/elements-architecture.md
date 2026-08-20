# Torque Elements Architecture

## Overview

`Torque::Elements` (`lib/torque/elements/`) is the foundational component system underneath Torque Admin: a node-based architecture that separates a component's logical structure (e.g. "a table has columns") from its physical rendering (headers, cells, rows).

Since the Project 1 unification (2026-08), elements and nodes are **one inheritance spine**:

```
BasicNode  →  Node  →  Base (element)
 physical     logical    organizer
```

- **`BasicNode`** (`basic_node.rb`) — purely physical: a type/tag, handler-managed options, `parent`, `element` (both explicit references, assigned at build/append time — `element` is on the critical render path, so it is never derived by tree walking), children, content. No id, no settings, no i18n. No subclass variants ever. Its rendering portion is organized in the `BasicNode::BasicRender` module (`nodes/basic_render.rb`): renders through the same helper dispatch as every node, falling back to a plain content tag (`ui.render_content_tag`). Used only when needed (e.g. dividers).
- **`Node`** (`node.rb`) — logical: adds `id`, `settings` (declared per class via `Node.setting`, extracted from options at initialize), textify/i18n, context changes, per-part rendering (`render_part`, cached). Variations start here (`LinkNode`, element-local ones like `MenuElement::ItemNode`). Hosts `Node::TYPES`, the symbol→class map used by the classification DSL (`:basic`, `:link`).
- **`Base`** (`base.rb`) — the element, a `Node` subclass. **The element is its own root**: there is no separate `@root` node, no `:@element` ivar smuggling. Adds the classification DSL, its own lazy index, config-block loading, and render orchestration via the `Core::*` concerns. Any `Base` declared through the controller `element` DSL is app-reachable (a separate `Extended` tier was tried and killed for having no methods — revival candidates in `projects/ideas.md`).

Developer-facing vocabulary is "element" everywhere; `Node`/`BasicNode` are internal machinery.

## Module bootstrap (`lib/torque/elements.rb`)

Declares the autoload map for the namespace: `Frame`, `Templates`, `Controller`, `Base`, `BasicNode`, `Node`, `Registry`, `Traverse`, `Component` (**dangling** — autoloaded, no backing file under `lib/`, only a draft at `tmp/component.rb`), `Context`, `Helpers`, `UiBuilder`, `HelperConstructor`, the six handlers, `ColumnNode`/`LinkNode`, and `AliasBuilder`/`HelperBuilder`.

**Attribute-definition API lives on the `Torque::Elements` module itself, not on `Base`:**
- `Elements.node_id(value)` — normalizes symbols/arrays/strings into a standard node id
- `Elements.attribute_name(name)`
- `Elements.define_attribute(name, handler)` — validates `handler.is_a?(BaseHandler)`, stores under `attributes[:static]` (dasherized key) or `attributes[:dynamic]` (Regexp key)
- `Elements.find_attribute(name)` — memoized static lookup (via `Concurrent::Map`), falls back to a matching dynamic Regexp key, defaults to a shared `BaseHandler.new`
- `Elements.static_attribute?(name)`

`enable_ui_framework`/`add_ui_framework`/`ui_framework_helper` are thin wrappers over `UiBuilder.enable_framework`/`add_framework` (see "UI framework system" below). `Elements.debug_templates!` is the only switch that makes the template-macro system write generated sources to disk (default `tmp/templates`).

## Classification DSL (`core/classification.rb`)

Elements declare their structural grammar at class level:

```ruby
class MenuElement < Torque::Elements::Base
  node :item, as: ItemNode, render: :menu_entry
  node :divider, as: :basic
  setting :sort, :icons, :dropdowns, :detect_current
end
```

- `node type, as:, index:, renders:, one:, parts:, render:` — declares an accepted child node type and **generates the child DSL method** (`item`, `divider`, ...) into a module auto-included in the class (the `generated_attribute_methods` pattern), so the element can override the method for preprocessing and call `super`.
  - `as:` — the backing node class: `nil` (default) is `Node`; a Symbol resolves through `Node::TYPES` (`:basic` → `BasicNode`, `:link` → `LinkNode`; `:node` deliberately absent); a Class is used directly. `as: :basic` implies `index: false` (never indexed); the two cannot be contradicted.
  - `index: false` — built and appended but never indexed (was `transient: true` until 2026-08-18; basic nodes are never indexed).
  - `renders: false` — for pull-based nodes whose output goes through parts: during a captured (view-rendered) block, the call registers the node and returns **the node itself** (its own render is empty, e.g. `ColumnNode#to_s == ''`), so declarations chain (`t.column(:x).header(...)`) while `<%= t.column :x %>` still emits nothing; normally-rendering types render inline instead.
  - `one: true` — a second declaration of that type raises.
  - `parts:` — the physical parts the child can answer via `Node#render_part` (pull-based, cached per node; the parent orchestrates collection in one iteration). Fully exercised by the future Table project.
  - `render:` — overrides the conventional render target name.
- `setting :a, :b` — declares element setting keys (replaces the old hand-maintained `element_settings` arrays); backed by `Node.setting`/`settings_keys` shared with node classes (`LinkNode` declares `setting :href, :remove_if_invalid`).

## Render dispatch — direct helper calls, convention over configuration

A node renders by calling a helper directly; there are no handler chains. The target name is inferred as `#{element.type}_#{node.type}` (bare `type` for BasicNodes and for the element root), declarable via `render:`. Resolution (memoized per element instance in `render_handler_for`):

1. **Per-instance override** — a `Proc` under the node's `:render` setting (`change :item, render: -> {}`) is `instance_exec`'d in the view context.
2. **Element method** — `render_#{node.type}` defined on the owning element class (e.g. `ButtonsElement#render_button(node, content, **options)`) — the element-level custom rendering hook (replaces the old `custom_render_for`).
3. **View helper** — `render_#{name}` on the view context (application/controller escape hatch).
4. **UI builder** — `ui.#{name}` (the framework seam — Bootstrap/Bulma/SemanticUI vary behind the same call).
5. **Fallback** — BasicNode renders a plain content tag; Node raises listing what was probed.

When one logical node has several physical shapes, the pattern is: a node subclass computes
the *logical* flags at render time, and a hand-written composite ui helper does the
*physical* composition. Example: `MenuElement::ItemNode` injects `dropdown:` when the item
has content, and `Helpers::SemanticUI#menu_entry` (the `render: :menu_entry` dispatch
target, written in the module body because compiled definitions are `module_eval`'d later
and would overwrite same-named defs) branches into `menu_item`/`menu_header`/`submenu` —
same shape as the theme's `buttons_button`.

Parts follow the same probes with `_#{part}` suffixed names via `Node#render_part`.

Steps 3–4 live in one place, `BasicRender#resolve_dispatch_handler(name)` (view helper `render_#{name}` → `ui.#{name}`), used by both the node's own render and by parts. An element method that wants to shape the arguments and then let the helper/ui chain finish calls **`node.dispatch_render(body, **options)`** (nodes) or **`node.dispatch_part(part, *args, **options)`** (parts) instead of hitting `ui.*` directly — `ButtonsElement#render_button` and `TableElement#render_column_*` do exactly that, so a host can still override `render_buttons_button` / `render_table_column_header` on the view.

## Lifecycle and state

- **Loading** (`loading?`/`loaded?`) is **per element** (ivars): `load_config!` runs the config block once via `load`, which wraps the element in a `SimpleDelegator` interface; `nest_content` handles the three block semantics (capture when rendering, `instance_eval` for arity-0 loading, plain yield otherwise).
- **Rendering** (`initiated?`/`rendering?`/`rendered?`) is **tree-wide**: `@state` is a `Set` owned by the element; a child element born from a parent **shares the parent's state object** (`adopt_state`), so guards work everywhere while memory stays flat. `rendering` is set during the pass (only the element that added the flag removes it — `Set#add?` — so a nested element's render no longer clears its parent's flag); `rendered` only after completion. Mutating a rendered element **raises loudly** (`assert_mutable!` — the old silent `add_node!` no-op is gone); adds are allowed while `loading?` even mid-render (a nested element loading its own definition). `load_config!` is re-entrancy safe: touching `index` from inside the config block (which every `add_node!` does) used to trip its `ensure` and reset `@loading` mid-load — fixed 2026-08-16.
- `Elements.attribute_name` memoizes normalized names in a `Concurrent::Map` (`attribute_names`), the same pattern as `find_attribute`.
- **Nested elements as children** — `Core::Render#render` loads the child's config (`load_config!`) before rendering inside a parent's pass (the shared `rendering` state used to skip it, so a child element declared as a node — e.g. the table's `pagination` — rendered empty).
- **Repeatable render** (`Core::Render#render_in(view_context = Context.view_context, reset: true)`): the element loads and sanitizes/freezes its options once; between renders only the volatile memos reset (`BasicNode#reset_render!` clears `@rendered`, derived `@content` and children; `Node` also clears the `@parts` cache). Per-item values live as **callable leaves inside the frozen options** (`Proc`, `Method`, or `Elements::Deferred`) and resolve at collapse through **`view_context.collapse_proc(value)`** (`Elements::Helpers`; a template render context can override it) — `BaseHandler#collapse`, `ListHandler`, `ContentHandler` and `ConditionalHandler` all go through it; `LinkNode#href` keeps Proc/Deferred hrefs untouched for the collapse; `Textify` leaves Proc labels alone. The item itself never touches `Context`: the repeating element owns a `SimpleDelegator` proxy that it retargets (`__setobj__`) before each `render_in(reset: true)`, and the leaves either close over the proxy or receive it as a `Deferred` arg. This is the row-actions experiment from `projects/04-table-element.md`; its result is the evidence for the parked template design: deferred leaves inside a frozen structure are enough.
- **`Elements::Deferred`** — Proc-like: a callable (Proc → `instance_exec` on the view, `Method` → `call`, **Symbol → `view_context.public_send`**) plus bound args/kwargs; `call(view_context = Context.view_context)`, `curry(*args, **kwargs)` returns a new instance with more bound arguments, `to_proc` curries the block arguments and calls. `Elements::PROC_CLASSES = [Proc, Method, Deferred]` and `Elements.act_as_proc?(value)` are the one place that knows what counts as callable (handlers, `LinkNode#href`, `Textify`, `flatten_append_option`). Elements hand instances out through their own DSL (`TableElement#each_row`, `TableElement#actions`), never devs directly.

## Index (`core/index.rb`)

Per-element, lazy, obfuscated from parents. Nested elements are entries in the parent's index; their internals are not. Reach-in is varargs: `fetch(:address, :street)` ≡ `fetch(:address).fetch(:street)`. `:root` resolves to the element itself (there is no `:root` index entry anymore).

## Composition

`add_node` accepts any node — including elements — over one protocol; `append_node`/`add_on_position!` assign `parent` and share state with element children. `import(other, from:, into:)` deep-copies nodes (including from another element or registry name) into the tree, reindexing copies while leaving the source untouched.

## Handler system (`handlers/*.rb`)

Handlers manage **HTML attribute-value merging and serialization** — not general "component composition." Base API (`BaseHandler`):
- `combine(current, value)` — merge a new value into the accumulated value for an attribute (default: replace)
- `collapse(value)` — turn the accumulated representation into the final string/value written into the tag (default: identity)
- protected `list_combine` (append to an array) and `format` (apply a formatter symbol/proc)

The six handlers, all `< BaseHandler` (or `< RefHandler`, itself `< BaseHandler`):

1. **`Conditional`** — backs `if`/`unless`/`remove_if`/`remove_unless`. `collapse` treats `nil`/`true` as pass, `false` as short-circuit-remove, Enumerables as flatten-and-recurse, `Method`/`Proc` as callables (`Proc`s run via `view_context.instance_exec`).
2. **`ContentHandler`** — backs `@content` (i.e. `before`/`prepend`/`content`/`append`/`after` parts). Supports Hash (with `render:` triggering `view_context.render`), Enumerable, `Method`, `Proc`, Symbol.
3. **`FormatHandler`** (`< RefHandler`) — applies a fixed `sprintf`-like format string to each queued value, joining into one string.
4. **`ListHandler`** (`< RefHandler`) — backs `class`/`data-controller`-style space-separated token lists; supports nested-hash keys, boolean toggling, de-duplication.
5. **`MapHandler`** — backs `style`-like key:value maps; renders as JSON (default) or CSS text, parsing existing CSS text back in via `Crass.parse_properties`.
6. **`RefHandler`** — resolves symbolic references through `Context.refs`. Base class for `FormatHandler`/`ListHandler`.

Default attribute→handler bindings are registered in the Railtie, not in `Base`.

### Builders (`builders/*.rb`)

- **`AliasBuilder`** — compiles a wrapper method that calls another already-defined helper with a forced `preset:` list.
- **`HelperBuilder`** — a DSL that generates the *source code* of a UI helper method (e.g. `button`) as a string, later `module_eval`'d. `compile(presets, shared)` assembles the final method, which ultimately calls `render_tag(tag_name, combine_options(...), with_content:)`.

Orchestrated by `HelperConstructor` (`extend`ed into `Helpers::Bootstrap`/`Bulma`/`SemanticUI`): `load_definitions(path)` `module_eval`s a definitions file where top-level `define`/`associate`/`shared` calls populate pending builders; `compile_elements_helpers!` compiles them all into one Ruby source string and `module_eval`s it via a `Tempfile`.

## Node classes

- **`LinkNode`** (`nodes/link_node.rb`) — fully implemented. `setting :href, :remove_if_invalid`. `href` resolves route hashes via `url_for`, swallowing `ActionController::UrlGenerationError` via `Rails.error.handle`; on failure with `remove_if_invalid`, drops `:href` and forces `options[:if] = false`. `active?`/`current?` check against the owning element's `current_link_setting`. Used by `ButtonsElement`, `BreadcrumbElement`, and `MenuElement`.
- **`Node::Textify`** (`nodes/textify.rb`) — i18n/label resolution. `label_key` (default `:label`), `text_attributes` (default `%i[alt label placeholder title]`). `text_for(option, default:)` builds i18n keys from the owning element's `i18n_name`/`type`/node `id` (via `Context.view_context.elements_i18n_keys`, exposed as a controller helper). `method_missing` lets you call `node.label` directly.
- **`ColumnNode`** (`nodes/column_node.rb`) — **legacy, currently broken**: still written against the pre-unification Node API (`self.settings +=`, `@element`, `@rendering_type`, OutputFlow parts). It is only loaded when a table renders and will be redesigned in the Table project (parts grammar: `parts: %i[col header cell footer]`).

## UI framework system

> Deep dive: `ui-builder-and-helpers.md` covers the full compile pipeline (`HelperConstructor` → `HelperBuilder`/`AliasBuilder` → generated methods), the definitions DSL vocabulary, presets flow, and the recipe for adding a new framework. This section is the summary.

### Actually implemented frameworks

| Constant | Files | Status |
|---|---|---|
| `Helpers::Bootstrap` | `helpers/bootstrap.rb`, `bootstrap/elements.rb` | Implemented |
| `Helpers::Bulma` | `helpers/bulma.rb`, `bulma/elements.rb` | Implemented |
| `Helpers::SemanticUI` | `helpers/semantic_ui.rb`, `semantic_ui/{elements,collection}.rb` | Implemented, the largest set |
| `Helpers::Tailwind` | none | **Dangling** — autoload with no backing file |
| Material UI | — | Not referenced anywhere in the codebase |

### How `enable_ui_framework` works

`Elements.enable_ui_framework(name)` → `UiBuilder.enable_framework(name, base: UiBuilder)` → looks up the module via `Elements.ui_framework_helper(name)` → `UiBuilder.add_framework(name, mod, base:)`, which registers a dynamically created anonymous subclass of `UiBuilder` per framework. `UiBuilder.new(context, framework:)` picks the right subclass, raising `MissingFrameworkError` for unknown names. Framework selection for a given admin app happens in `lib/torque/admin/application.rb` (`ui_builder`).

### `ui/defaults.rb`, `ui/options_handlers.rb`, `ui/rendering.rb`

All three are mixed into `UiBuilder`:
- **`Defaults`** — `menu_sections_for`, generic CSS-grid `rows`/`columns` layout helpers, and `table`/`table_row`/`table_cell`/`column_header`/`column_col` helpers (the table ones await the Table project).
- **`OptionsHandlers`** — `append_options`/`build_options`/`flatten_options`/`combine_options`/`combine_option` (delegates to `Elements.find_attribute(key).combine`), `collapse_options` (delegates to `.collapse`), special-option flattening (`@content`/`@append`/`@controller`), `split_options_properties`/`fetch_presets`. Note: `split_options_properties` must not re-flatten `'@append'` from a parent input — `deep_extract_properties` already queues those entries as their own inputs (this was once a double-render bug). This file is flagged for future simplification (see `projects/ideas.md`).
- **`Rendering`** — `render_content_tag`/`render_tag`: builds the final HTML tag via `view_context.tag`, calling `collapse_options` first, assembling `before/prepend/content/append/after` parts around it. This is the floor of all rendering.

## Value reading (`value_reader.rb`)

`Torque::Elements::ValueReader` (concern): `read_value_for(source, attribute, from: nil)` (`from:` reads through one association first) switching on `read_mode` — `:call` (`public_send`), `:hash`/`:object` (`[sym]`), `:json` (`[str]`), `:dig`; `read_mode` is the `read_mode` setting, else memoized `default_read_mode` (`:call`; the Table overrides it from its entries). Meant to be shared with Forms.

## Formatting (`formatter.rb`, `helpers/formatting.rb`)

The view class is the formatter registry (`projects/03-formatting.md`). A formatter is a view helper named `#{Elements.formatter_prefix}#{name}` (`mattr_accessor :formatter_prefix`, default `'format_as_'`, set before helpers load); `Formatter::Declarations` (`extend` it in any helper module or a controller `helper do … end` block) gives `formatter name, helper = nil, wrap: nil, context: nil, &block` (`context:` ∈ `entry`/`attribute`/`collection`, validated, recorded in `Formatter.contexts` keyed by the defined `UnboundMethod`; `Formatter#format` extracts those keys from its options and passes only the declared ones) (`wrap:` names a `#{Elements.wrapper_prefix}#{name}` view method — default prefix `wrap_as_` — called as `wrap_as_x(output, value)`; `Helpers::Formatting` ships `wrap_as_time`/`wrap_as_data`) (`define_method` sugar — helper name → `public_send(helper, value, *args, **options)`, block → `instance_exec` on the view) and `formatters name: :helper, …`. Options are passed through, never validated. `Formatter` is the per-view proxy memoized as `formatter` (like `ui`): `formatter.money(value, unit: 'R$')` → `format_as_money` via `method_missing`/`respond_to_missing?`; `formatter.format(value, as = nil, fallback: nil, **options)` is the cells/footers entry point — nil value → collapsed `fallback`; `as` nil → `view.formatter_for(value)` inference (overridable, `super`-chained: Elements maps Date/Time, `Torque::Admin::FormattingHelper` adds `to_model → :record`, `ActiveRecord::Relation → :count`); `as` false → raw; blank result → `fallback`; `false` is not blank. `Helpers::Formatting` is the standard pack (number helpers, `l`, `truncate`, `sentence`, `sanitize`, `mail_to`, `ordinal`, `humanize`, `count`), included in `Elements::Helpers`.

## Template system — the "templates as macros" mechanism

- **`Templates`** concern — mixed into the host app's controllers; provides `provide_template_ivars`, `append_template_path`/`prepend_template_path`, `template_context`, `template_assigns`.
- **`Templates::Resolver`** (`< ActionView::FileSystemResolver`) — overrides `_find_all` to build `UnboundTemplate` objects from matched files, then `bind_path`s each to the requested virtual path/prefix.
- **`Templates::UnboundTemplate`** (`< ActionView::Template`) — the raw, uncompiled macro file. **`build_source`** builds a `RenderContext`, temporarily nils `controller.request`, compiles and **executes** the unbound template, capturing the output as the new template's source.
- **`Templates::Template`** (`< ActionView::Template`) — the bound, real template; source computed lazily on first render.
- **`Templates::RenderContext`** (`< ActionView::Base`) — the sandbox used to compile/run the unbound macro template.

**Concretely**: `app/templates/resource/index.html.erb` contains *escaped* ERB (`<%%= ... %>`). Executed as a macro, it produces text containing real ERB — that text becomes the in-memory source of a bound `Templates::Template`. No file is written to disk unless `Torque::Elements.debug_templates!` is enabled.

Elements are renderable in **both modes**: direct render (per-request instantiation, helpers emit strings — e.g. menus in frames) and template compile (definition runs once at compile; the emission seam is Project 2's concern). The tree, DSL, and helper calls are identical in both.

## Frame system (`frame.rb`, `frame/renderer.rb`)

A **Frame** is a layout-between-the-layout. `Frame` is a concern adding a `frame(name, only:, except:)` class macro (e.g. `frame 'classic'`). `FrameRenderer < ActionView::TemplateRenderer` renders the frame template first, stores the result via `view.view_flow.set(:layout, ...)`, then renders the outer layout — **Frame → (real page Layout) → wraps → Template**. Bare names auto-prefix to `frames/`, resolving to `app/views/frames/*.html.erb`.

## `Context`, `Controller`, `Registry`, `Traverse` — quick recap

- **`Context`** (`< ActiveSupport::CurrentAttributes`) — request-scoped: `view_context`, `elements` (registry cache), `registry`, `refs`. `apply_changes`/`change` implement deferred name-targeted append operations (the element applies them with `'root'` as its own node key).
- **`Controller`** — mixed into host controllers; `element(name, of_type:, &config)` declares an element; `element_class_for` resolves a type to a `< Base` class; `elements_i18n_keys` (helper method) backs textify.
- **`Registry`** — per-`Context` cache/factory of element instances; anonymous instances (`name.nil?`) are intentionally not memoized.
- **`Traverse`** — iterative pre-order tree traversal with `max_depth`/`min_depth`; `with_content` collects post-order content, used by `BasicNode#content` to render children bottom-up.

## Errors (`errors.rb`)

`StandardError` (wraps all others), `UnavailableError` (`< NoMethodError`), `MissingFrameworkError` (`< NameError`), `NotFound` (`< KeyError`), `StrictLocalsError` (`< ActionView::StrictLocalsError`).

## Known gaps / incomplete code (for anyone extending this layer)

- `Torque::Elements::Component` is autoloaded but has no backing file under `lib/`.
- `use_template` (`Core::Template`) has no current call sites; `Core::Template`'s `Referer` interface references a nonexistent `render_node`.
- `Helpers::Tailwind` is a dangling autoload.
- `parts:`/`renders: false` are exercised by Table (`ColumnNode`); `one:` still has no consumer (and it checks by node type, so it cannot guard a nested `Base` such as the table's `actions` buttons, whose `type` is `:buttons`).
- `CollectionState#provide(:sort, ...)` is shadowed by `Enumerable#sort` on the state — read it via `state.table[:sort]`.
- `ui/rendering.rb` emits void elements (`col`, `img`, `input`, …) without a closing tag from its own `VOID_ELEMENTS` list — Rails 8.1 keeps that list private in generated `TagBuilder` methods.
