# UI Builder & Helper Construction

How a UI framework (Bootstrap, Bulma, SemanticUI, a future Tailwind) becomes a set of
callable `ui.*` helper methods. Written from the SemanticUI implementation, which is the
reference and the largest set. Files involved:

```
lib/torque/elements/ui_builder.rb                 # UiBuilder class + framework registry
lib/torque/elements/ui/options_handlers.rb        #   mixin: the options pipeline
lib/torque/elements/ui/rendering.rb               #   mixin: render_tag / render_content_tag (the floor)
lib/torque/elements/ui/defaults.rb                #   mixin: framework-agnostic helpers (rows/columns/table)
lib/torque/elements/helper_constructor.rb         # compile orchestrator (extended into helper modules)
lib/torque/elements/builders/helper_builder.rb    # per-helper source generator (the DSL)
lib/torque/elements/builders/alias_builder.rb     # preset-forcing wrapper generator
lib/torque/elements/helpers/semantic_ui.rb        # the framework module (reference)
lib/torque/elements/helpers/semantic_ui/{elements,collection}.rb   # definition files
lib/torque/admin/themes/semantic_ui.rb            # admin-level theme layer on top
```

## The big picture

```
definitions file (define/associate/shared DSL)
      │  load_definitions → module_eval'd, populates @pending HelperBuilder/AliasBuilder instances
      ▼
compile_elements_helpers!  (HelperConstructor)
      │  each builder.compile(...) → Ruby source string
      │  + `def self.elements_presets; {...}; end`
      │  module_eval'd into the helper module (via Tempfile, so backtraces point at a real file)
      ▼
Helpers::SemanticUI  — a plain module whose instance methods are the compiled helpers
      │  UiBuilder.add_framework('semantic_ui/admin', Themes::SemanticUI)
      │  → Class.new(UiBuilder).include(mod); include hook imports presets
      ▼
per-framework anonymous UiBuilder subclass, registered in UiBuilder.framework_classes
      │  view's `ui` → UiBuilder.new(view_context, framework: name) → subclass instance
      ▼
ui.button('Save', :primary, icon: :check)  →  render_tag(...)  →  final HTML
```

Two distinct moments, easy to conflate:

1. **Compile time** (once per process, lazily): the `define` blocks run, each producing the
   *source code* of a method as a string. Nothing framework-instance-specific exists yet.
2. **Call time** (per render): the compiled method runs on a `UiBuilder` instance, walking
   the options pipeline and emitting a tag through `render_tag`.

## UiBuilder: the runtime object

`UiBuilder` (`ui_builder.rb`) is a thin per-request wrapper around the view context
(`delegate_missing_to :view_context`). The view helper `ui` (`helpers/ui_helper.rb`)
memoizes `UiBuilder.new(self, framework: ui_framework)` per view.

### Framework registry

- `UiBuilder.add_framework(name, mod, base: UiBuilder)` — registers
  `framework_classes[normalized_name] = Class.new(base).include(mod)`. One **anonymous
  subclass per framework**; the module carries the behavior, the subclass carries identity.
- `UiBuilder.enable_framework(name)` — convenience: resolves the module by naming
  convention via `Elements.ui_framework_helper(name)`
  (`Helpers.const_get(name.classify.sub(/Ui$/, 'UI'))` — so `'semantic_ui'` →
  `Helpers::SemanticUI`) and calls `add_framework`.
- `UiBuilder.new(context, framework: name)` — the base class's `new` is overridden to look
  up the subclass and instantiate *it* (raises `MissingFrameworkError` for unknown names);
  subclasses instantiate normally.
- Admin wiring: `Application#ui_builder` registers `"#{config.theme}/#{app_name}"` (e.g.
  `semantic_ui/admin`) with the **theme module** (`Torque::Admin::Themes::SemanticUI`),
  which itself includes the Elements-level `Helpers::SemanticUI` — so every admin app gets
  its own framework entry layered over the base framework. `config.theme_extensions`
  procs/modules are then applied to that class.

### The include hook and presets

`UiBuilder.include` is overridden: for every included module (and its own included
modules, walked first), it calls `import_presets_from(mod)`, which:

1. `mod.try(:compile_elements_helpers!)` — **this is what triggers compilation**, lazily,
   at framework-registration time;
2. imports `mod.elements_presets` into the class-level `presets` hash
   (`presets[:button][:primary] = {...}` etc.).

Because included modules are walked before the module itself, the theme's
`elements_presets` (hand-written in `Themes::SemanticUI`) land *after* the compiled ones
from `Helpers::SemanticUI`, overriding per preset name (`merge!` at the component level).

## The definitions DSL (compile time)

A framework helper module does exactly this (`helpers/semantic_ui.rb`):

```ruby
module Helpers::SemanticUI
  extend HelperConstructor

  ICON = +'icon %s'
  SIZES = %w[mini tiny small default large big huge massive]...  # value-mapping constants

  shared(:icon)  { |b| b.calls(:icon).adds_to_content(:prepend) }
  shared(:size)  { |b| b.maps_using(:SIZES).assigns(:class) }
  shared(:color) { |b| b.assigns(:class) }
  shared(:items) { |b| b.maps_using(:ITEMS).formats(:class, '%s item') }

  load_definitions './semantic_ui/elements'
  load_definitions './semantic_ui/collection'

  def menu_entry(content = nil, **options)   # hand-written composite helper — see below
    ...
  end
end
```

`extend HelperConstructor` seeds `@presets = {}`, `@pending = {}`, `@shared = Hash.new([])`
on the module. The DSL surface it adds (all protected):

- `shared(property) { |b| ... }` — registers a reusable property recipe under a name.
  Helpers pull it in with `imports`. This is the cross-component vocabulary (`:icon`,
  `:size`, `:color` exist in all three frameworks with framework-specific recipes —
  compare Bulma's `shared(:icon)` which additionally `wrap_content(:span)`).
- `load_definitions(path)` — reads the file and `module_eval`s it **in the module's
  context**, so the definitions files are top-level `define`/`associate` calls with no
  module ceremony.
- `define(helper, with_content: true) { |b| ... }` — creates (or reopens) a
  `HelperBuilder` named `helper` and yields it. `with_content: false` (e.g. `icon`,
  `flag`, `emoji`) makes a void-ish element: no content parameter, no block capture,
  default tag `span` instead of `div`.
  `with_content: :required` makes the content argument mandatory.
- `associate(helper, to: other, preset: name, **extensions)` — creates an `AliasBuilder`:
  a thin wrapper that forces a preset list (`buttons` → `button` with `preset: :multiple`).

Nothing is compiled here — builders queue in `@pending` until
`compile_elements_helpers!` runs (triggered by the `UiBuilder.include` hook, above).

### Naming convention

Helper names bridge frameworks using https://component.gallery/components/ vocabulary —
**not** the framework's own jargon. SemanticUI's "label" is defined as `badge`; its
"steps" are `step`/`steps`. This is what lets an element render `ui.badge(...)` and get
the right thing on every framework.

## HelperBuilder: anatomy of one helper

The builder DSL has three vocabularies: **presets**, **inputs** (arguments / properties /
toggles / imports), and **effects** (what an input does to the options). From the `button`
definition (`semantic_ui/elements.rb`):

```ruby
define :button do |b|
  b.preset(:default, as: 'button', class: 'ui button')
  b.preset(:multiple, as: 'div', class: { button: false, buttons: true })

  b.imports(:icon, :size, :color)

  b.property(:label).adds_to_content(:append)
  b.property(:badge).calls(:badge).adds_to_content(:append)

  b.toggles(:primary, :secondary, :inverted, :tertiary, :positive, :negative)
  b.property(:disabled).applies(class: 'disabled', disabled: true)

  b.property(:floated).maps(false, true => 'left').formats(:class, '%s floated')
  b.property(:social).assigns(:class)
end

associate :buttons, to: :button, preset: :multiple
```

### Inputs

| DSL | Meaning | Call-site shape |
|---|---|---|
| `argument(name, default:)` | positional argument, part of the method signature | `ui.icon('check')` |
| `property(name)` | keyword option, extracted from kwargs/presets into `_properties` | `ui.button(floated: :right)` |
| `toggles(:a, :b, assigns: :class, format: '%s')` | shorthand: each name becomes a property that applies its own name as a class when truthy | `ui.button(primary: true)` **or positionally** `ui.button('Save', :primary)` |
| `imports(:icon, :size)` / `imports(icon: :other_shared)` | pulls a `shared` recipe in as a property (optionally under a different local name) | `ui.button(icon: :check, size: :large)` |

Every property name is also collected into the property list used at call time to split
kwargs into `_properties` (consumed by this helper) vs `_options` (passed through to the
tag). `:as` is always a property — any helper accepts `as: 'span'` to change its tag.

### Effects (chained after an input)

Each effect appends a line of *generated source* to the current input's operation block:

| Effect | Generated behavior |
|---|---|
| `.assigns(:class)` | `combine_option('class', options, value)` — merge the raw value into an attribute |
| `.formats(:class, '%s floated')` | merge `format('%s floated', value)` — a String is inlined as a literal |
| `.formats(:class, using: :ICON)` | merge `format(ICON, value)` — a Symbol references a **module constant**, resolved at call time |
| `.applies(class: 'disabled', disabled: true)` | `combine_options(options, {...})` — merge a fixed options hash (flattened at compile time) |
| `.maps(false, true => 'left')` | `value = {true => 'left'}.with_indifferent_access[value] \|\| value` — translate; first positional `false` = don't force (unmapped values pass through); `maps(true, ...)` would drop unmapped values |
| `.maps_using(:SIZES)` | `value = SIZES[value]` — translate through a module constant |
| `.calls(:icon)` / `.calls(:badge, '(value, size: :small)')` | `value = icon(value)` — feed the value through **another compiled helper** (composition!) |
| `.adds_to_content(:append)` | `combine_option('@content', options, append: value)` — put the value into a content part (`before/prepend/content/append/after`) |
| `.adds_to_content(:content, property: :at)` | part name itself resolvable from another property |
| `.wrap_content(tag)` | adds `before`/`after` `@content` entries wrapping in `<tag>` (Bulma's icon-in-span) |
| `.import_options` | `combine_options(options, value)` — the property's value is itself an options hash |

Effects chain left to right and the generated lines run in that order:
`b.property(:floated).maps(false, true => 'left').formats(:class, '%s floated')` first
translates `true` → `'left'`, then merges `'left floated'` into `class`.

### What `compile` produces

Actual generated source for a trimmed `button` (captured by running the builder):

```ruby
def button(content = nil, *_toggles, preset: nil, **kwargs, &block)
  _options, _properties = split_options_properties(:button,
    [:as, :icon, :size, :color, :label, :primary, :basic, :disabled, :floated], preset, kwargs)
  options = {}

  _toggles.each { |toggle| _properties[toggle] = true }
  combine_option('@content', options, (block_given? ? view_context.capture(&block) : content))
  if (value = _properties[:label])
    combine_option('@content', options, :append => value)
  end
  if (value = _properties[:primary])
    combine_options(options, {"class" => "primary"})
  end
  if (value = _properties[:disabled])
    combine_options(options, {"class" => "disabled", "disabled" => true})
  end
  if (value = _properties[:floated])
    value = {true => "left"}.with_indifferent_access[value] || value
    combine_option('class', options, format("%s floated", value))
  end
  if (value = _properties[:icon])            # imported shared recipes come last
    value = icon(value)
    combine_option('@content', options, :prepend => value)
  end
  if (value = _properties[:size])
    value = SIZES[value]
    combine_option('class', options, value)
  end

  tag_name = _properties.fetch(:as, 'div')   # 'span' when with_content: false
  render_tag(tag_name, combine_options(_options, options), with_content: true)
end
```

And the alias:

```ruby
def buttons(*args, **kwargs, &block)
  preset = [:multiple].push(*kwargs.delete(:preset))
  button(*args, preset: preset, **kwargs, &block)
end
```

Compile mechanics worth knowing:

- Operation blocks are stored per input as `['end', 'if (value = ...)', ...effect lines]`;
  `compile` flattens them and rotates the first `'end'` to the tail (the
  `operations << operations.shift` "swap end" trick). That's why every input reads as an
  independent `if (value = ...) ... end` guard.
- `imports` recipes are stitched in by `import_shared_properties` *after* the helper's own
  inputs — imported properties always run last. (The branch that would merge a shared
  recipe into an *existing* same-named property calls `Hash#insert` and would raise; it is
  effectively a dead path today — don't define `property(:icon)` and also `imports(:icon)`
  in one helper.)
- String literals are baked in; Symbols (`maps_using(:SIZES)`, `formats(using: :ICON)`,
  `calls(:icon)`) become bare identifiers in the source, resolved as module
  constants/methods at call time. Constants therefore live on the helper module
  (`SIZES`, `ICON`, `ITEMS`).
- A `:default` preset is mandatory (`compile` raises without it).
- `HelperConstructor#compile_content` writes the assembled source to a `Tempfile` and
  `module_eval`s it with that path, so exceptions and `#source_location` point at
  inspectable real files (e.g. `/tmp/semantic_ui_helpers*.rb`).

## Call time: the options pipeline

The compiled method leans entirely on `UiBuilder::OptionsHandlers` + the attribute-handler
registry (see `elements-architecture.md` for the handlers themselves):

1. **`split_options_properties(source, property_list, preset_list, kwargs)`** — assembles
   the input queue `[kwargs, default_preset, *requested_presets]`, then
   `Context.deep_extract_properties` pops from the end: **default preset first, then named
   presets, then kwargs last**, each split into properties (merged; later wins) and
   options (combined through the attribute handlers; for list-like attributes such as
   `class`, "combined" means accumulated — `'ui button'` + preset `'primary'` + caller's
   `class:` all survive). Hash-valued `class` entries toggle: `{ button: false, buttons:
   true }` removes `button` and adds `buttons` (how the `:multiple` presets pluralize).
2. **`flatten_options!`** — normalizes nested hashes into dashed attribute names
   (`data: { controller: 'x' }` → `data-controller`), reroutes content parts
   (`prepend:`/`append:`/... → `'@content'`), and expands the special options `'@append'`
   (queued deferred changes from `Context.change` / `node.change`) and `'@controller'`.
3. **`combine_option(key, options, value)`** — `Elements.find_attribute(key).combine` —
   accumulate per the attribute's handler (list append for `class`, hash-merge queue for
   `style`, part-bucket for `'@content'`, replace by default).
4. **`render_tag(tag_name, options, with_content:)`** (`ui/rendering.rb`) — the floor:
   `collapse_options` (each handler serializes its accumulated value),
   `render_with_conditions` (honors collapsed `if`/`unless`/`remove_if`/`remove_unless`),
   pulls `'@content'` apart into `before/prepend/content/append/after`, renders
   `tag.content_tag_string`, and `safe_join`s the outer parts around it.
   `render_content_tag` is the with-content convenience wrapper (also accepts a block,
   captured via the view).

So a call like:

```ruby
ui.button('Save', :primary, icon: :check, size: :large, class: 'mine', data: { action: 'form#submit' })
```

resolves to `<button class="ui button primary mine large" data-action="form#submit">
<i class="icon check"></i>Save</button>` with every class contribution accumulated, never
clobbered.

## Beyond the DSL: hand-written helpers

The DSL covers "one tag, options in, decorated tag out." Three other kinds of helper
coexist in the same modules and are equally reachable via `ui.*`:

1. **Composite logical helpers** — written as plain methods in the framework module body,
   composing compiled helpers. `Helpers::SemanticUI#menu_entry` is the pattern: it decides
   *which* physical shape a menu entry takes (plain `menu_item`, `menu_header` +
   `submenu`, dropdown) from logical inputs computed by the node
   (`MenuElement::ItemNode`). **Important**: these must be written in the module body (or
   any module included *before* compilation), because compiled definitions are
   `module_eval`'d later and a same-named compiled `define` would overwrite them.
2. **Framework-agnostic defaults** — `UiBuilder::Defaults` (`ui/defaults.rb`): CSS-grid
   `rows`/`columns`, plain `table`/`table_row`/`table_cell` helpers (the table ones still
   read the removed `options[:@node]` — reworked with the Table project). Available on
   every framework because they're mixed into `UiBuilder` itself.
3. **Theme-level helpers** — `Themes::SemanticUI` adds admin-chrome methods (`logo`,
   `application_banner`, `page_banner`, `page_content`, `page_footer`), element dispatch
   targets (`buttons_button`, `buttons_group`, `table_skeleton`), and flags read by
   elements (`breadcrumb_with_dividers`). This is also where render-dispatch names from
   elements land: `MenuElement`'s items dispatch to `ui.menu_entry`, `ButtonsElement`'s
   `render_button` calls `ui.buttons_button`.

## Recipe: adding a new framework (e.g. Tailwind)

1. `lib/torque/elements/helpers/tailwind.rb` — module `Helpers::Tailwind`,
   `extend HelperConstructor`; define the `shared` recipes (`:icon`, `:size`, `:color` at
   minimum — elements assume they exist across frameworks); define value-map constants.
2. `lib/torque/elements/helpers/tailwind/elements.rb` (+ more files as it grows) —
   `define`/`associate` blocks per component.gallery name, loaded with
   `load_definitions './tailwind/elements'`.
3. The autoload already exists in `helpers.rb`; nothing to register — `enable_framework`
   / the admin theme wiring resolves `'tailwind'` → `Helpers::Tailwind` by convention.
4. For admin use: `lib/torque/admin/themes/tailwind.rb` including the Elements module,
   plus `elements_presets` and the chrome helpers (`page_banner`, `application_banner`,
   `buttons_button`, ...) that `ApplicationHelper`/frames call. Grep
   `Themes::SemanticUI` for the current required surface — there is no formal interface
   contract yet; the theme module *is* the contract.

## Known warts (as of 2026-08)

- `HelperBuilder#import_shared_properties`'s existing-property merge path calls
  `Hash#insert` (would raise); effectively dead — see above.
- The `flatten_options!` / `split_options_properties` / `deep_extract_properties` /
  `'@append'` interplay is flagged for simplification in `projects/ideas.md` (it already
  produced one double-append bug, fixed with the `except('@append')` guard).
- `UiBuilder::SETTINGS` (gaps, default col sizes, skeleton rows) is a frozen class-level
  hash with no per-app override path yet.
- `Defaults` table helpers read the removed `options[:@node]` — Table project territory.
- `framework_classes` is a mutable `@@`-style registry with no reset between app reloads
  (the admin layer re-registers on `Application#clear`, which masks this).
