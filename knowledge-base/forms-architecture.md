# Torque Forms Architecture

## Current state: stub

`lib/torque/forms/` is not yet a working forms system. It's two small files:

### `lib/torque/forms.rb` (full content)

```ruby
module Torque
  module Forms
    extend ActiveSupport::Autoload
    autoload :Base
    autoload :Element
  end
end
```

Just a namespace declaring two autoloads. **`lib/torque/forms/base.rb` does not exist anywhere in the repo** — referencing `Torque::Forms::Base` raises a `LoadError`/`NameError` at runtime. This autoload is dangling, same class of problem as `Helpers::Tailwind`, `PunditController`, and `SimpleController` elsewhere in the gem (see `elements-architecture.md` and `controller-structure.md`).

### `lib/torque/forms/element.rb` (full content, ~50 lines)

A thin subclass of `Torque::Elements::Base`:
- `type` → `:form`
- `element_settings` → appends `%i[hints icons]` to the parent's settings
- `sanitize_node_button_options` — calls an `icons_helper` to inject icon options into button nodes
- `icons_helper` — lazily builds a settings handler for `:icons`/`:icon`
- `clear!` — resets `@icons_helper` then calls `super`
- Two rendering hooks (`sanitize_node_label_options`, `sanitize_node_input_options`) are **commented out / unimplemented**
- `i18n_keys` — empty protected stub
- No node/section DSL is defined at all (the "Define nodes" section of the file is empty)

### Wiring

`lib/torque/admin/railtie.rb` does `config.eager_load_namespaces << Torque::Forms` (just registers the namespace for eager loading). No other file in `app/` or `lib/torque/admin/` references `Torque::Forms` or `torque/forms` at all.

## What doesn't exist yet

None of the following exist despite being natural expectations for a "forms" layer:
- A working base form class (`Torque::Forms::Base` — file missing entirely)
- Input types (text, select, checkbox, etc.)
- Validation integration
- Rails form-helper integration
- Label/input rendering (the relevant hooks are commented out in `element.rb`)

## Summary

This layer is essentially a stub: a namespace with a broken autoload (`Base`) and one minimal `Torque::Elements::Base` subclass (`Element`) that only wires up icon settings for form buttons. Anything describing a fully-featured forms framework (base form class + input types + validation + Rails helper integration) does not reflect the current code — treat this layer as not-yet-implemented when planning work that depends on it.
