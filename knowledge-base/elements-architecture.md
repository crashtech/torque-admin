# Torque Elements Architecture

## Overview

`Torque::Elements` (`lib/torque/elements/`) is the foundational component system underneath Torque Admin: a node-based architecture that separates a component's logical structure (e.g. "a table has columns") from its physical rendering (headers, cells, rows).

## Module bootstrap (`lib/torque/elements.rb`)

Declares the autoload map for the namespace: `Frame`, `Templates`, `Controller`, `Base`, `Node`, `Registry`, `Traverse`, `Component` (**dangling** — autoloaded, no backing file under `lib/`, only a draft at `tmp/component.rb`), `Context`, `Helpers`, `UiBuilder`, `HelperConstructor`, the six handlers, `ColumnNode`/`LinkNode`, and `AliasBuilder`/`HelperBuilder`.

**Attribute-definition API lives on the `Torque::Elements` module itself, not on `Base`:**
- `Elements.node_id(value)` — normalizes symbols/arrays/strings into a standard node id
- `Elements.attribute_name(name)`
- `Elements.define_attribute(name, handler)` — validates `handler.is_a?(BaseHandler)`, stores under `attributes[:static]` (dasherized key) or `attributes[:dynamic]` (Regexp key)
- `Elements.find_attribute(name)` — memoized static lookup (via `Concurrent::Map`), falls back to a matching dynamic Regexp key, defaults to a shared `BaseHandler.new`
- `Elements.static_attribute?(name)`

`node_id` is re-exposed via delegation on `Context` and (protected) on `Core::Index`, but always ultimately calls `Elements.node_id`.

`enable_ui_framework`/`add_ui_framework`/`ui_framework_helper` are thin wrappers over `UiBuilder.enable_framework`/`add_framework` (see "UI framework system" below). `Elements.debug_templates!` is the only switch that makes the template-macro system write generated sources to disk (default `tmp/templates`) — see "Template system" below.

## `Base` and the `Core::*` mixins

`Base` (`lib/torque/elements/base.rb`) is the abstract superclass for every element. It includes, **in this order**: `Core::Index`, `Core::Nodes`, `Core::Render`, `Core::Template`, `Core::Helpers`, `Core::Definition`. `class_attribute :abstract_class` defaults `true` on `Base` and is automatically flipped to `false` on subclasses via `inherited` — `Base` itself can't be instantiated (`Core::Definition#initialize` raises `NotImplementedError` if `abstract_class?`). `render`/`to_s`/`to_str`/`html_safe` are all aliased to `render_in`. `view_context` delegates to `Context`.

- **`Core::Definition`** — `initialize(name, *args, **options, &config)` builds the root node; tracks lifecycle state (`initiated?/loading?/loaded?/rendering?/rendered?`); `load_config!` lazily runs the config block once; `load(*, into:, &block)` uses a `SimpleDelegator` so config blocks can call element/node methods without an explicit receiver; `type` (abstract); `within`, `change`/`change!`, `remove`/`delete`, and `import` (the cross-element multi-node merge path in `import_nodes` is currently commented out/dead — importing nodes across elements doesn't fully work yet).
- **`Core::Helpers`** — `settings`/`settings?`/`change_setting` read/write the root node's settings hash; `element_settings` (base list `%i[max_depth min_depth]`, extended by subclasses e.g. `TableElement`); `apply_sorting!`; `fallback_text_for` (no-op hook); `i18n_name`/`i18n_keys` (back the label/translation system).
- **`Core::Index`** — the node lookup table (`@index`), lazily built; `[]`/`fetch`/`key?`/`size` keyed by normalized node id (`:root` special-cased); `index_node`/`unindex_node`/`reindex`; `ref_to_node`; `nodes_of_type`.
- **`Core::Nodes`** — owns the node tree (`children`/`nodes`); positional insertion (`insert_after`/`insert_before`/`prepend_to`/`append_to`); `traverse` (delegates to `Traverse`); `move`.
- **`Core::Render`** — per-class `custom_renders` table plus class method `custom_render_for(type, &block)` (an override table) and a *different*, instance-level `custom_render_for` (same name, different meaning — a per-node render-method cache). `render_in(view_context, &block)` is the default render entry point: loads config, wraps in `Context`, calls `root.render!`. `render_content_only!`/`?` toggle wrapper-tag suppression. `render_handler_for(node)` resolves/memoizes either a custom block or a handler discovered via the node's own `render_handlers` chain (see "Node system").
- **`Core::Template`** — the escape hatch to render the whole element via a real ActionView partial instead of the node tree; overrides `render_in` and falls back to `super` (`Core::Render#render_in`) unless `use_template` was declared. `grep` across the codebase found `use_template` defined but **never called anywhere** — treat "automatic name-based template matching" as unverified/likely aspirational rather than a working feature.

**Correction to prior docs**: earlier text said Base "includes Core modules for indexing, node management, rendering, and templates" — this omitted `Core::Helpers` and `Core::Definition`, which supply most of the actual public element API (`initialize`, `load_config!`, `within`, `change`, `remove`, `import`, `settings`).

## Handler system (`handlers/*.rb`)

Handlers manage **HTML attribute-value merging and serialization** — not general "component composition." Base API (`BaseHandler`):
- `combine(current, value)` — merge a new value into the accumulated value for an attribute (default: replace)
- `collapse(value)` — turn the accumulated representation into the final string/value written into the tag (default: identity)
- protected `list_combine` (append to an array) and `format` (apply a formatter symbol/proc)

The six handlers, all `< BaseHandler` (or `< RefHandler`, itself `< BaseHandler`):

1. **`Conditional`** (`handlers/conditional_handler.rb`) — backs `if`/`unless`/`remove_if`/`remove_unless`. `collapse` treats `nil`/`true` as pass, `false` as short-circuit-remove, Enumerables as flatten-and-recurse, `Method`/`Proc` as callables (`Proc`s run via `view_context.instance_exec`).
2. **`ContentHandler`** (`handlers/content_handler.rb`) — backs `@content` (i.e. `before`/`prepend`/`content`/`append`/`after` parts). Supports Hash (with `render:` triggering `view_context.render`), Enumerable, `Method`, `Proc`, Symbol (calls a view_context method or stringifies).
3. **`FormatHandler`** (`< RefHandler`) — applies a fixed `sprintf`-like format string to each queued value, joining into one string.
4. **`ListHandler`** (`< RefHandler`) — backs `class`/`data-controller`/`data-action`-style space-separated token lists; supports nested-hash keys, boolean toggling, de-duplication (`Set`) when `unique: true` (default).
5. **`MapHandler`** — backs `style`-like key:value maps; renders as JSON (default) or `key:value;key:value` CSS text (used for the real `style` attribute), parsing existing CSS text back in via `Crass.parse_properties`.
6. **`RefHandler`** — resolves symbolic references through `Context.refs`, letting one node's attribute point at another node's rendered id/name. Base class for `FormatHandler`/`ListHandler`.

Default attribute→handler bindings are registered in the Railtie, not in `Base`: `@content`/`if`/`remove_if`/`unless`/`remove_unless` → `ContentHandler`; `style` → `MapHandler(separator: ';', format: :dasherize, as_json: false)`; `class` → `ListHandler`; and (only if Stimulus is present) `data-controller`/`data-action` → `ListHandler`, `data-*-target` → `RefHandler`.

### Builders (`builders/*.rb`)

- **`AliasBuilder`** — compiles a wrapper method that calls another already-defined helper with a forced `preset:` list.
- **`HelperBuilder`** — a DSL that generates the *source code* of a UI helper method (e.g. `button`) as a string, later `module_eval`'d. DSL: `preset`, `toggles`, `imports`, `argument`/`property`, and effects `assigns`/`formats`/`applies`/`import_options`/`wrap_content`/`adds_to_content`/`maps`/`maps_using`/`calls`. `compile(presets, shared)` assembles the final method, which ultimately calls `render_tag(tag_name, combine_options(...), with_content:)`.

Orchestrated by `HelperConstructor` (`extend`ed into `Helpers::Bootstrap`/`Bulma`/`SemanticUI`): `load_definitions(path)` `module_eval`s a definitions file where top-level `define`/`associate`/`shared` calls populate pending builders; `compile_elements_helpers!` compiles them all into one Ruby source string and `module_eval`s it via a `Tempfile` (so generated helpers have real, debuggable backtraces).

## Node system (`node.rb`, `nodes/*.rb`)

`Node` (`node.rb`) is the base class for tree nodes. `CLASS_TYPES = { link: 'Torque::Elements::LinkNode' }` is the **only** symbol→class mapping registered — there's no equivalent entry for `ColumnNode`; it's instead passed explicitly as a `node_type:` argument at the call site (`app/elements/table_element.rb`: `add_node(identifier, :cell, Elements::ColumnNode, ...)`). Includes `Rendering` and `Textify`. Core API: `id`, `type`, `parent`, `options` (with `[]`/`[]=`), `tag` (delegated to the view context).

Two render handlers are registered at load time via `append_render_handler`:
1. First tries `Context.view_context.ui.node_render_names(node, element)` (the active `UiBuilder`'s naming convention, see `Defaults#node_render_names`) and calls the first candidate name the `ui` object responds to.
2. Falls back to asking `Context.view_context` (the controller/view) for candidate names via `Controller#node_render_names`.

This is the mechanism by which a node named `:header` on a `table` element resolves to a helper method like `render_table_header`/`render_header` — distinct from the template-macro system below.

`initialize(id, type, parent = nil, **options)` treats a `Base`-instance `parent` as the owning `@element` for the root node. `change`/`append` defer changes into `@options['@append']`; `change!` merges immediately. `sanitized_options`/`sanitized_options!` freeze/normalize options once before render (subclasses hook in their own normalization via `super`).

- **`Node::Rendering`** (`nodes/rendering.rb`) — `settings` class_attribute (option keys pulled out into a separate `@settings` hash, e.g. `ColumnNode` adds `:as`, `LinkNode` adds `:remove_if_invalid`); class-level ordered (`reverse_each`, last-registered wins first) `render_handlers` chain with fallthrough to the superclass's handlers; instance `content` (lazily renders children bottom-up via `Traverse#with_content`); `render!`/`render` dispatch to a resolved handler (Proc/lambda called directly, or Symbol naming an instance method).
- **`Node::Textify`** (`nodes/textify.rb`) — i18n/label resolution. `label_key` (default `:label`), `text_attributes` (default `%i[alt label placeholder title]`). `text_for(option, default:)` builds i18n keys from `@element`'s `i18n_name`/`type`/node `id`. `method_missing` lets you call `node.label` directly. `sanitized_options!` auto-translates all `text_attributes`.

### `ColumnNode` (`nodes/column_node.rb`) — **has a real, functional bug**

Adds a `:as` setting; `content` dispatches on its type: `Proc`/`Method` → `content_from_method`, `Symbol` → `content_from_helper`, `Array` → `content_from_call(target, method, *)`.

```ruby
def content_from_helper(name)
  content_from_method(helper)   # `helper` is an undefined local/method; `name` is ignored
end

def content_from_method(method)
  # empty body — always returns nil
end
```

Only `content_from_call` (the `Array` case) actually works. In practice this is safe *only* because `TableElement#build_accessor` always produces an `Array` for the default column path. But `TableElement#column` explicitly allows a block (`options[:as] = block if block_given?`, which is a `Proc`) or a bare symbol/method as `:as` — hitting either of those silently returns `nil` (`Proc`/`Method`) or raises `NameError` (`Symbol`, via the undefined `helper` reference). **Document `column(:x, as: ...)` with anything other than the default array-accessor as currently non-functional.**

### `LinkNode` (`nodes/link_node.rb`) — fully implemented

Adds `:remove_if_invalid`. `href` resolves route hashes via `url_for`, swallowing `ActionController::UrlGenerationError` via `Rails.error.handle`; on failure, if `remove_if_invalid` is set, drops `:href` and forces `options[:if] = false` (dropping the node at render time via the `Conditional` handler). `active?`/`current?` check against the element's `current_link_setting` (or `:current_page?` by default). Used by `ButtonsElement`, `BreadcrumbElement`, and `MenuElement` (not `TableElement`).

## UI framework system

### Actually implemented frameworks

| Constant | Files | Status |
|---|---|---|
| `Helpers::Bootstrap` | `helpers/bootstrap.rb`, `bootstrap/elements.rb` | Implemented (`button`, `badge`, `alert`, `card`, `progress`, `progress_bar`, `spinner`, `icon`) |
| `Helpers::Bulma` | `helpers/bulma.rb`, `bulma/elements.rb` | Implemented (`block`, `box`, `button`/`buttons`, `content`, `delete`, `icon`, `figure`, `notification`, `progress`, `badge`/`tag`/`badges`/`tags`, `title`/`subtitle`) |
| `Helpers::SemanticUI` | `helpers/semantic_ui.rb`, `semantic_ui/{elements,collection}.rb` | Implemented, the largest set (`button`/`buttons`, `container`, `divider`, `emoji`, `flag`, `header`, `icon`, `image`, `badge`/`badges`, `loader`, `placeholder`, `rail`, `reveal`, `segment`/`segments`, `step`/`steps`, `text`, `menu`/`submenu`, `menu_item`/`menu_header`, `breadcrumb`/`breadcrumb_item`) |
| `Helpers::Tailwind` | none | **Dangling** — only an `autoload :Tailwind` declaration in `helpers.rb`, no backing file. Referencing it raises `LoadError`/`NameError`. |
| Material UI | — | Not referenced anywhere in the codebase. |

**Correction to prior docs**: the actual, working framework list is **Bootstrap, Bulma, Semantic UI** — Bulma was previously omitted, and Tailwind/Material UI were previously listed as supported when they are not (Tailwind is a dangling autoload; Material UI doesn't exist at all).

### How `enable_ui_framework` works

`Elements.enable_ui_framework(name)` → `UiBuilder.enable_framework(name, base: UiBuilder)` → looks up the module via `Elements.ui_framework_helper(name)` (`Helpers.const_get(name.classify.sub(/Ui$/, 'UI'))`, e.g. `'semantic_ui'` → `Helpers::SemanticUI`) → `UiBuilder.add_framework(name, mod, base:)`, which does `framework_classes[normalize_name(name)] = Class.new(base) { include(mod) }` — a dynamically created anonymous subclass of `UiBuilder` per framework, registered in a class-level (`@@`, shared) hash. `UiBuilder.new(context, framework:)` picks the right subclass, raising `MissingFrameworkError` for unknown names. `UiBuilder.include` is itself overridden to fold any `elements_presets` a framework module exposes into `UiBuilder.presets`. Actual framework selection for a given admin app happens in `lib/torque/admin/application.rb` (`ui_builder`), not in this layer — this layer only provides the registration mechanism (`add_ui_framework`/`add_framework` is the real pluggable extension point).

### `ui/defaults.rb`, `ui/options_handlers.rb`, `ui/rendering.rb`

All three are mixed into `UiBuilder` (`include OptionsHandlers; include Rendering; include Defaults`):
- **`Defaults`** — `node_render_names(node, element)` (the naming convention consulted by `Node`'s first render handler), `menu_sections_for`, generic CSS-grid `rows`/`columns` layout helpers, and a `table` helper.
- **`OptionsHandlers`** — `removed_from_options` (interprets `if:false`/`unless:true`/`remove_if:true`/`remove_unless:false`), `append_options`/`build_options`/`flatten_options`/`combine_options`/`combine_option` (delegates to `Elements.find_attribute(key).combine`), `collapse_options` (delegates to `.collapse`), special-option flattening (`@node`/`@element` no-ops, `@content`/`@append`/`@controller` handled specially), `split_options_properties`/`fetch_presets`.
- **`Rendering`** — `render_content_tag`/`render_tag`: builds the final HTML tag via `view_context.tag`, calling `collapse_options` first, dropping the tag if `removed_from_options`, assembling `before/prepend/content/append/after` parts around it.

`UiBuilder` itself defines `SETTINGS = { default_gap: '1.5ex' }` and delegates almost everything else to `view_context` (`delegate_missing_to :view_context`).

## Template system — the "templates as macros" mechanism, precisely

This is the subtlest part of the codebase; earlier docs' phrasing ("produces a view file when none exists") is imprecise. Here's the actual chain:

- **`Templates`** concern — mixed into the host app's controllers; provides `provide_template_ivars`, `append_template_path`/`prepend_template_path` (registers a custom `Resolver` for a path), `template_context`/`template_context_class`, `template_assigns`.
- **`Templates::Resolver`** (`< ActionView::FileSystemResolver`) — overrides `_find_all` to build `UnboundTemplate` objects from matched files, then `bind_path`s each to the requested virtual path/prefix. One physical file can be bound to multiple virtual paths.
- **`Templates::UnboundTemplate`** (`< ActionView::Template`) — represents the raw, uncompiled macro file; `render`/`instrument_render_template` are undefined (it's never rendered directly). `bind_path` creates/memoizes a `Templates::Template` per virtual path. **`build_source(view, template, expected_locals)`** builds a `RenderContext`, temporarily nils `controller.request` (so request state doesn't leak into macro expansion), compiles the unbound template into that context, actually **executes** it against an `ActionView::OutputBuffer`, and captures the buffer's string as the new template's source.
- **`Templates::Template`** (`< ActionView::Template`) — the bound, real template. `render` lazily computes `@source ||= @template.build_source(...)` on **first render** — the ERB source doesn't exist until then — then proceeds with normal `ActionView::Template#render`.
- **`Templates::RenderContext`** (`< ActionView::Base`) — the sandbox used to compile/run the unbound macro template, `delegate_missing_to :@view_context`.
- **`Templates::Details`** — extracts/merges `:template_prefixes`/`:build_from` render options; prepended monkeypatches on `ActionView::AbstractRenderer`/`LookupContext`/`TemplateDetails::Requested` scope candidate lookup by prefix/source path.

**Concretely**: `app/templates/resource/index.html.erb` contains *escaped* ERB (`<%%= render 'table' %>`). Executed as an unbound macro template, it produces plain text containing real `<%= render 'table' %>` — that text becomes the in-memory source of a new bound `Templates::Template`, compiled and rendered by Rails exactly as if written directly to that path. **No file is written to disk in normal operation** — only when `Torque::Elements.debug_templates!` is enabled (default dump path `tmp/templates`) is the generated source persisted, purely for debugging.

The claim "templates automatically match names to components" is **unverified** — `use_template` (`Core::Template`) has no call sites anywhere in the current codebase. Treat it as aspirational until confirmed.

## Frame system (`frame.rb`, `frame/renderer.rb`)

A **Frame** is a Torque-specific layout-between-the-layout — the code's own comment describes it as "an almost direct copy of `ActionView::Layouts`, with just its own name." `Frame` is an `ActiveSupport::Concern` mixed into controllers, adding a `frame(name, only:, except:)` class macro (e.g. `frame 'classic'` in `BaseController`). It accepts a `String` (literal name), `Symbol` (controller method), `Proc`, `false` (no frame), or defaults to inheriting from the parent controller.

It hooks `_process_render_template_options`: for a normal full-template render, it replaces `options[:layout]` with a `FrameRenderer`-producing proc that sits *between* the template and the real layout. `_normalize_frame` auto-prefixes bare names with `"frames/"` — this is why `frame 'classic'` resolves to `app/views/frames/classic.html.erb`.

`FrameRenderer < ActionView::TemplateRenderer` resolves both the frame template and the real layout; `render` renders the frame template first (passing `view._layout_for` as its block), stores the result via `view.view_flow.set(:layout, frame_content)`, then renders the outer layout — so the flow is **Frame → (real page Layout) → wraps → Template**, with the frame's content reaching the outer layout through the same `view_flow` channel `content_for(:layout)`/`yield :layout` use.

`app/views/frames/*.html.erb` are ordinary views built using this same Elements system (`ui.rows`/`ui.columns`, `elements.main_menu`, `app_page_content { yield }`). Of the four shipped frames, **only `classic` is actually wired up anywhere** (`BaseController`'s `frame 'classic'`); `minimal.html.erb` is a completely empty (0-byte) file, unreferenced by name anywhere else in the codebase.

## `Context`, `Controller`, `Registry`, `Traverse`, `HelperConstructor` — quick recap

- **`Context`** (`< ActiveSupport::CurrentAttributes`) — thread/fiber-local, request-scoped: `view_context`, `elements` (registry cache), `registry`, `refs` (backing `RefHandler`). `with_ref`/`add_ref` implement scoped ref overriding (e.g. per-row refs in a table). `apply_changes`/`change` implement deferred cross-element append operations.
- **`Controller`** — mixed into host controllers; `element(name, of_type:, &config)` declares an element type; `change_element`/`alias_element` customize/rename; `element_class_for`/`element_class_name` resolve a type symbol to a `< Base` class (`camelize` + `Element` suffix convention); `node_render_names`/`elements_i18n_keys_for` are the controller-level render/i18n defaults; `fetch_element` builds/reuses the per-request `Registry`.
- **`Registry`** — per-`Context` cache/factory of element instances; `method_missing` lets you call `registry.some_element_name` (or `!`/`?` suffixed for required/existence checks, raising `NotFound` for the former).
- **`Traverse`** — iterative (stack-based, non-recursive) pre-order tree traversal with `max_depth`/`min_depth`; a `with_content` variant also collects post-order content, used by `Node::Rendering#content` to render children bottom-up.
- **`HelperConstructor`** — compiles `HelperBuilder`/`AliasBuilder` DSL output into a real module via a `Tempfile` (see "Builders" above).

## Errors (`errors.rb`)

Five classes: `StandardError` (wraps all others), `UnavailableError` (`< NoMethodError`, view-only APIs accessed outside a real view), `MissingFrameworkError` (`< NameError`, raised by `UiBuilder.new` for unknown frameworks), `NotFound` (`< KeyError`, raised by `Registry#fetch_from_controller`), `StrictLocalsError` (`< ActionView::StrictLocalsError`, raised by `UnboundTemplate#build_source`).

## Known gaps / incomplete code (for anyone extending this layer)

- `Torque::Elements::Component` is autoloaded but has no backing file under `lib/` (only a draft at `tmp/component.rb`).
- `Core::Definition#import`'s cross-element multi-node merge path is commented out.
- `ColumnNode#content_from_helper`/`#content_from_method` are broken/empty (see above).
- `use_template` (`Core::Template`) has no current call sites.
- `Helpers::Tailwind` is a dangling autoload.
