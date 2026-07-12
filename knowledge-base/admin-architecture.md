# Torque Admin Architecture

## Overview

`Torque::Admin` (`lib/torque/admin/`) is the composition layer that turns the `Elements` foundation into a working Rails admin engine: one or more named `Application` instances, each with its own generated module, controller classes, routing DSL, and resource registry.

## `Torque::Admin` module — access & configure API

```ruby
# lib/torque/admin.rb
class << self
  def [](name)
    instances[name.to_sym] ||= Application.new(name)
  end

  def configure(...)
    self[:default].configure(...)
  end

  def instances
    @instances ||= {}
  end
end
```

- `Torque::Admin[:default]` / `Torque::Admin[:custom]` — a memoized factory. First access for a given (symbolized) name lazily builds `Application.new(name)` and caches it in a plain (non-thread-safe) `instances` Hash. Any name works, not just `:default`/`:custom`.
- **`:default` is an alias for `:admin` internally.** `Application#initialize` renames `@name` to `:admin` when given `:default`, so `Torque::Admin[:default]` returns an `Application` whose real name/module is `Admin`, not literally `"default"`.
- `Torque::Admin.configure(...)` always forwards to `self[:default].configure(...)` — there's no shortcut to configure a non-default app via `Torque::Admin.configure`; use `Torque::Admin[:custom].configure { |config| ... }` directly.
- `Application#configure { |config| ... }` just yields the app's `ActiveSupport::InheritableOptions` config object.
- **There is no `Application#resource` method.** Resources are never declared directly in code (`Torque::Admin[:default].resource :users do ... end` is not a real API) — they're built exclusively from drawn routes (see "Resource System" below).
- **Mounting is not `mount Torque::Admin::Engine => '/admin'`.** `Torque::Admin::Engine` is an abstract base class subclassed per application via `Engine.build(admin_application)`. Use the `admin` routing DSL method instead (see "Routing" below).

## Application module setup & lazy constants

`Application#setup_application_module` (`lib/torque/admin/application.rb`) is where the "run under a module namespace" convention is implemented:

1. `base = config.parent_module!.constantize` (default `'Object'`).
2. `mod_name = name.to_s.camelize.to_sym` — gets or creates `base.const_get/const_set(mod_name)` as a plain `Module.new` (e.g. `Admin` for name `:admin`). Raises `ArgumentError` if that module already defines `Engine`.
3. **Key step**: the full contents of `lib/torque/admin/application/lazy_constants.rb` are `module_eval`'d directly into the new module. That file opens with `extend Torque::Admin::LazyConstants`, so the app module itself gains `const_missing`/`lazy_constant`/`clear_lazy_constants` as singleton methods, then registers builder blocks for:
   - `Resource` → `Class.new(Torque::Admin::Resource)`
   - `BaseController` → `Class.new(config.base_controller!.constantize)` (default `ApplicationController`), `.include(Torque::Admin::BaseController)`, `abstract_class = true`
   - `ResourceController` → `Class.new(mod::BaseController)`, includes `Torque::Admin::ResourceController`, abstract
   - `DashboardController` → `Class.new(mod::BaseController)`, includes `Torque::Admin::DashboardController`, abstract
   - `SimpleController` → `Class.new(mod::ResourceController)`, includes `Torque::Admin::SimpleController` (**note**: `Torque::Admin::SimpleController` has no backing file under `app/controllers/` — referencing `mod::SimpleController` would fail)
   - a nested `Devise` module (also `extend`s `LazyConstants`, currently registers nothing)
4. `mod.define_singleton_method(:admin_application) { self }` — lets `Admin.admin_application` return the `Application` instance.
5. `engine.isolate_namespace(mod)` unless `config.isolate_namespace == false`; if `isolate_namespace` is left `nil` (default "hybrid" mode), also defines no-op `table_name_prefix`/`use_relative_model_naming? → false` directly on `mod`.
6. `mod.const_set(:Engine, engine)`.

**Why `< ResourceController` works inside `module Admin`:** Ruby's constant lookup fails to find `ResourceController` and calls `const_missing` on the enclosing module — which is the `LazyConstants`-provided method:

```ruby
def const_missing(name)
  return super unless instance_variable_defined?(:@lazy_constants)
  return super if (handler = @lazy_constants[name]).nil?
  const_set(name, handler.call(self))
end
```

It looks up the registered block, calls it, and **memoizes the result via `const_set`** — so it only resolves once per module. This only works from code lexically inside that specific app module, not via `Torque::Admin::ResourceController` (which is a different thing — the mixin concern, not a class).

### The generic `LazyConstants` mixin (`lib/torque/admin/lazy_constants.rb`)

```ruby
module LazyConstants
  extend ActiveSupport::Concern
  def const_missing(name)
    return super unless instance_variable_defined?(:@lazy_constants)
    return super if (handler = @lazy_constants[name]).nil?
    const_set(name, handler.call(self))
  end
  protected
  def lazy_constant(*names, &block)
    (@lazy_constants ||= {}).merge!(names.index_with { block })
  end
  def clear_lazy_constants
    (constants & @lazy_constants.keys).each { |name| remove_const(name) }
  end
end
```

`const_missing`-based, not `method_missing`; `lazy_constant` only *registers* a builder block, nothing is built until Ruby's own constant resolution actually fails and triggers `const_missing`. `clear_lazy_constants` removes already-`const_set` constants (used to reset state between reloads).

## Resource system

Resources are created only as a side effect of drawing admin routes:

1. `Mapper::Scope#annotate!` runs for every route built under the admin routing DSL. If the scope has a resource context, `annotate_resource` runs: `name = [*module, singular].join('/')`, `resource = app.fetch_resource(name)`, `resource.enhance_from_route(self, action)`.
2. `Application#fetch_resource(name)` → `@resources[name] ||= mod::Resource.new(name)` (memoized per admin application).
3. `Resource#initialize` stores `sanitize_name(name)`, which strips the app-name prefix (e.g. `"admin/"`) unless `use_relative_resource_naming?` is true (delegates to `mod.use_relative_model_naming?`, `false` in default hybrid mode).
4. **The "guessing" algorithm** — `Resource#resource_class`:
   ```ruby
   def resource_class
     @resource_class ||= name.classify.constantize
   end
   ```
   Take the sanitized, route-derived name (e.g. `"user"` or `"blog/post"`), `.classify` it (→ `User` / `Blog::Post`), `.constantize` it. No rescue — raises `NameError` if the class doesn't exist. That's the entirety of the guessing logic: pure Rails-`classify` convention on the route's singular resource name, after namespace-prefix stripping.
5. `enhance_from_route` accumulates `@sections` (from route annotation `:section`) and buckets each drawn action into `@actions[:batch|:collection|:member]` or `@widgets[:collection|:member]`.
6. Public `Resource` API: `name`, `controllers`, `sections`, `widgets`, `actions`, `primary_handler`, `controller_class` (delegates to `primary_handler`), `resource_class`, `singular_key`/`singular_title`, `plural_key`/`plural_title`, `inspect`.
7. `resource/active_model.rb` (mixed via `include ActiveModel`) overrides the title/key methods to prefer `resource_class.model_name` (`.singular`, `.human`, `.plural`, `.human(count: 2)`) when the resource class responds to `model_name`, falling back to plain string-titleize otherwise.
8. `Application#setup_controller` registers a `Rails.autoloaders.main.on_load(controller)` hook: once the user's actual controller class loads, it sets `klass.admin_resource = resource` and `klass.identified_by = klass.primary_param = param` — this is the wiring between a drawn controller and its `Resource`.

## Routing DSL (`lib/torque/admin/railties/{mapper,routing}.rb`)

- `Routing#admin(name = :default, path = nil, app: Torque::Admin[name], authenticated: nil, **, &block)` — the actual entry point, mixed into `ActionDispatch::Routing::Mapper`. Usage: `admin :default, '/admin' do ... end`. Lazily mounts the app's engine on first call using `app.mount_options(path, options)` (defaults `root_path`/`at` to the app name, reverse-merges `as: name`).
- `Mapper < ActionDispatch::Routing::Mapper` provides the DSL surface available inside an `admin` block:
  - `section(name)` — scopes with an `annotations: { section: name }` marker
  - `with_actions` / `without_actions` — scope-level action allow/deny lists
  - `simple` — marks scope level `:simple` (drives `SimpleController`)
  - `annotate(annotations)` — generic annotation scope
  - `external` — a fresh, un-annotated mapper sharing the route set (used for e.g. `devise_for`)
  - `resource(*, actions:, source:, widgets:, ...)` / `resources(*, ...)` — admin-flavored overrides of the Rails resource DSL (adds `search`/`preview`/`upsert` to default actions, auto-draws member/collection routes)
  - `actions(*, on:, &block)` / `action(*actions, view:, add_alias:, action:, via:, on:)` — custom page actions, annotated `type: :action`
  - `widgets(*list, action:, on:)` — dashboard/collection "widget" endpoints, annotated `type: :widget`
  - `searchable(*resources, source:, **)` — shorthand collection-only `get :search`
  - `dashboard(path, partials:, as:, controller:, with_alias:)` / `dashboard_root` — dashboard root route + optional alias
  - `authenticate(resource, with: :rails|:custom|:devise, &block)` / `unauthenticated(&block)` — authentication scopes, including a Devise integration path
- `Mapper::Scope < ActionDispatch::Routing::Mapper::Scope` carries the `annotations` hash through scope merging and is what actually resolves/creates `Resource` objects at route-build time.
- `railtie.rb` does `Mapper.send(:undef_method, :admin)` — since `Mapper` includes the `Routing` module (which is also included globally into the base `ActionDispatch::Routing::Mapper`), this explicitly removes `admin` from the subclass so the DSL can't be recursively invoked from inside an already-scoped `Torque::Admin::Mapper`.

## Engine / Railtie hooks

- `Engine < ::Rails::Engine` is abstract; only used via `Engine.build(admin_application)`, which dynamically subclasses itself (`Class.new(self)`), stashes `@admin_application`, and sets `config.admin`/`config.admin_application`.
- `Railtie < ::Rails::Railtie`:
  - `config.eager_load_namespaces << Torque::Forms` / `<< Torque::Admin`
  - Initializer `'torque-admin.railtie_setup'`: adds `Torque::Admin::Engine` to `Rails::Railtie::ABSTRACT_RAILTIES`, includes `Routing` into `ActionDispatch::Routing::Mapper`, prepends `Mapper::Mapping` onto `Mapping`'s singleton class, undefines `admin` on `Mapper` (see above), adds an i18n locale load path.
  - Initializer `'torque-admin.action_controller_setup'`: on `:action_controller` load, appends several ivars to `ActionController::Base::PROTECTED_IVARS` (`@_initialized_side_controllers`, `@_slave_of`, `@_route_annotations`, `@_chained_scoped_resource`, `@_chained_members`, `@_i18n_default_scopes`, `@_implicit_resource_title`).
- Autoloading of `app/` classes is **not** generic Rails `autoload_paths` — it's a custom helper in `lib/torque/admin.rb`:
  ```ruby
  def app_autoload(const_name, *subs)
    folder = ActiveSupport::Inflector.pluralize(const_name.to_s.match(/[A-Z][a-z]+\z/).to_s.downcase)
    autoload(const_name, APP_DIR.join(folder, *subs, ActiveSupport::Inflector.underscore(const_name)))
  end
  ```
  Derives the app subfolder by pluralizing the last CamelCase word of the constant (e.g. `CancancanController` → `Controller` → `controller` → `controllers`), then autoloads `APP_DIR/<folder>/<subs>/<underscored_name>.rb`. This is also how `SimpleController`, `PunditController`, and `AuthorizationController` end up **declared but dangling** — they're `app_autoload`ed at `lib/torque/admin.rb` but have no corresponding file under `app/controllers/`; referencing them raises a load error.

## Themes

`lib/torque/admin/themes/semantic_ui.rb` defines `Themes::SemanticUI`, which `include`s `Elements::Helpers::SemanticUI` and layers admin-specific overrides on top:
- `self.elements_presets` — per-component style presets (`menu.primary_horizontal/secondary_horizontal/primary_vertical`, `button.primary/danger`), consumed by `UiBuilder.import_presets_from`
- Instance overrides: `breadcrumb_with_dividers = true`, `logo`, `application_banner`, `page_content`, `page_banner`, `page_footer`, plus composite elements `buttons_button`/`buttons_group`

Wiring: `Application#ui_theme` computes `["#{config.theme!}/#{name}", config.theme.to_s.classify.sub(/Ui$/, 'UI')]` (for `theme: 'semantic_ui'` → class name `SemanticUI`); `Application#ui_builder` does `mod = Themes.const_get(mod_name); Elements::UiBuilder.add_framework(name, mod)`.

**Default theme is `'tailwind'`**, not SemanticUI. Valid config values per `default_config.rb`: `bootstrap, bulma, semantic_ui, tailwind`. Only `SemanticUI` currently has an admin-level `Themes::` wrapper module with admin-specific overrides — Bootstrap/Bulma/Tailwind rely solely on the Elements-layer helpers (and Tailwind's helper module doesn't exist at all yet, see `elements-architecture.md`). `config.theme_extensions` lets you layer procs/module-includes onto the built `ui_builder` class (`Application#apply_theme_extensions`).

## Authorization adapters

`BaseController.authorize_actions!` does `include(Admin.const_get("#{adapter}Controller"))` when `admin_application.authorization_adapter` is set (config accepts `cancancan`, `pundit`, `torque_admin`, or `nil`). Only **CanCanCan** is actually implemented:

- `app/controllers/authorization/cancancan_controller.rb` — includes `CanCan::ControllerAdditions`, adds `before_action :authorize_action!, if: :authentication_protected_route?`, overrides `scoped_resource`/`nested_scope_from` to append `.accessible_by(current_ability, ...)`, overrides `build_new_record` to merge `current_ability.attributes_for(...)` into new-record attributes, and gates page actions via `can?`.
- `PunditController` and `AuthorizationController` (backing the `:torque_admin` adapter) are `app_autoload`ed in `lib/torque/admin.rb` and accepted as config values, but **no backing files exist** — selecting either adapter raises a load error at runtime. Treat these as planned-but-unimplemented, not working integrations.

## `CollectionState` (`lib/torque/admin/collection_state.rb`)

A small write-once, freeze-on-ready key/value bag plus pub/sub hook, used to accumulate index-page metadata (filter/sort/pagination/scopes settings) before the collection itself is materialized:

- `provide(key, value)` — raises if already `ready?` or if the key was already provided; freezes the value and stores it
- `provides?(key)` — predicate for optional state (the primary safe way to check if a key was provided)
- `on_ready(&block)` — runs immediately if already ready, otherwise queues the callback
- `ready!(collection)` — stores the collection, fires queued `on_ready` callbacks, **freezes `@table`** (but `collection` itself, via `attr_accessor`, remains reassignable afterward — an asymmetry worth knowing about)
- `ready?` — `!!defined?(@collection)`, so even assigning `nil` to `collection` makes this true
- `method_missing`/`respond_to_missing?` expose each provided key as a reader (e.g. `state.sort`)
- Includes `Enumerable`, delegates `[]`/`each` to the internal table

Collaborators (`FilterController`, `ScopesController`, `SortController`, `PaginationController`) call `state.provide(:filter, ...)` etc., each guarded against double-provide and against providing after `ready!`. `CollectionController#load_collection` calls `state&.ready!(result)` once the scope chain resolves. `TableElement` checks `entries.is_a?(CollectionState)` to decide whether to render sortable headers.

## Concerns: `ItemsFromAction`, `ItemsFromRouter`

Plain modules (not `ActiveSupport::Concern`), mixed into `BreadcrumbElement` and `MenuElement` respectively:

- **`ItemsFromAction`** (`lib/torque/admin/concerns/items_from_action.rb`) — builds breadcrumb items from the currently executing controller action. `import_items_from_current_action(with_home:, with_section:, with_current:)` optionally imports a home item, the current section's dashboard link, dynamically dispatches to `import_from_#{controller_type}_controller` (e.g. `import_from_resource_controller`, walking chained-member controllers for multi-level trails), and optionally appends the current action as an active item. `action_label_for` resolves a human label via i18n with a `titleize` fallback.
- **`ItemsFromRouter`** (`lib/torque/admin/concerns/items_from_router.rb`) — builds a full nav/menu tree by walking the actual Rails route set (`import_items_from_router`), filtering to GET routes with no required params matching allowed actions (default `index`/`show`), grouping by section, with optional dashboard-per-section entries. `import_items_from_sections` builds one menu entry per known resource section by reaching into `Application`'s `@resources` ivar directly (an encapsulation break worth noting).

## Errors

`lib/torque/admin/errors.rb` currently defines exactly one class: `Torque::Admin::StandardError` (wraps `::StandardError`). It is not raised anywhere in the codebase yet — actual `raise` calls elsewhere use plain `ArgumentError` or bare strings. There is no rich error taxonomy yet.

## Version

`Torque::Admin::VERSION = '0.1.0.a1'` (`lib/torque/admin/version.rb`).
