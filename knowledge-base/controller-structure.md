# Torque Admin Controller Structure

## The key structural fact

**None of the files in `app/controllers/` are controller classes.** Every one of them is declared as:

```ruby
module Torque
  module Admin
    module XController
      extend ActiveSupport::Concern
      ...
```

They're `ActiveSupport::Concern` modules. The actual controller *classes* are generated per admin application at runtime, in `lib/torque/admin/application/lazy_constants.rb` (see `admin-architecture.md`):

- `mod::BaseController` = `Class.new(config.base_controller!.constantize)` (default `ApplicationController`), `.include(Torque::Admin::BaseController)`, abstract
- `mod::ResourceController` = `Class.new(mod::BaseController)`, includes `Torque::Admin::ResourceController`, abstract
- `mod::DashboardController` = `Class.new(mod::BaseController)`, includes `Torque::Admin::DashboardController`, abstract
- `mod::SimpleController` = `Class.new(mod::ResourceController)`, includes `Torque::Admin::SimpleController` — **`Torque::Admin::SimpleController` has no backing file**, so this would fail to autoload

So the real inheritance chain for a concrete resource controller (e.g. `MyAdmin::UsersController`) is:

```
MyAdmin::UsersController
  < MyAdmin::ResourceController      (dynamic abstract class, includes the ResourceController concern)
    < MyAdmin::BaseController        (dynamic abstract class, includes the BaseController concern)
      < ApplicationController        (host app's, configurable via config.base_controller)
        < ActionController::Base
```

You cannot write `class UsersController < Torque::Admin::ResourceController` — that constant is a module. Subclass the per-application generated class instead, e.g. `class UsersController < MyAdmin::ResourceController` inside `module MyAdmin`.

## `BaseController` (module `Torque::Admin::BaseController`)

Included concerns: `Elements::Frame`, `Elements::Templates`, `Elements::Controller`, `SettingsController`. Delegates `admin_application`, `admin_application_config`, `admin_controller_name`, `ui_framework` to the class.

On `included`:
- Resolves the owning admin application module and defines a singleton `admin_application` method
- `prepend_view_path`/`append_view_path` for app-specific and gem-default views
- `helper Admin::ApplicationHelper, Admin::FormattingHelper`
- `helper_method :ui_framework, :relative_path_for, :relative_url_for, :route_annotation, :implicit_page_title_for`
- `layout admin_application.name.to_s` — layout is named after the admin app (e.g. `"admin"`)
- `frame 'classic'` — selects the Elements `Frame` layout (see `elements-architecture.md`)
- `before_action :assign_page_title` — **the only callback this module adds**
- `main_menu { import_from_routes }`, `secondary_menu { import_from_sections }`, `breadcrumb { import_from_current_action }`

Class methods: `admin_application_config`, `ui_framework`, `admin_controller_name(namespace:)` (derives e.g. `"users"` from the class name), `element_class_name(name)`, `main_menu`/`secondary_menu`/`breadcrumb` (thin `element(...)` wrappers), and protected `authorize_actions!(skip_if_none:, only:, except:)` — if `admin_application.authorization_adapter` is set, `include(Admin.const_get("#{adapter}Controller"))`; else raises unless `skip_if_none`. Also `generated_actions_module` — lazily creates an anonymous module (`GeneratedActions`) that other concerns (e.g. `IndexController`) use to define synthesized action methods.

Instance methods include page-title resolution (`implicit_page_title`, `implicit_page_title_for`), route-annotation readers (`route_annotation`, `authentication_protected_route?`), "slave controller" support for sharing a request/response across nested controller instances (`slave_controller?`, `initialize_as_slave_of`, `initialized_side_controllers`), i18n scope helpers, and `fallback_authorization_action` (maps HTTP verb → CanCan-style action symbol).

**There is no authentication logic, session management, or generic error handling in this file** — it only conditionally includes an authorization adapter module if one is configured.

## `ResourceController` (module `Torque::Admin::ResourceController`)

`delegate :resource_class, to: :admin_resource, prefix: :admin` (→ `admin_resource_class`). On `included`:
- `class_attribute :admin_resource`, `:primary_param` (default `:id`), `:identified_by`
- Appends template lookup paths (`app/templates/<app>/resource`, `app/templates/resource`, gem default)
- `helper_method :processing_member_action?, :implicit_resource_title, :implicit_resource_title_for`
- `stream_from_actions :index, :show if admin_application.config.stream_actions` — **currently commented out, dead code**
- `prepend_before_action :load_resource, if: :processing_member_action?`
- `prepend_before_action :find_chain_parents!`
- `authorize_actions! skip_if_none: true`

**After** `included do`, it includes — in this order — `StreamController`, `PageActionsController`, `CollectionController`, `MemberController`, `IndexController`, `ShowController`, `FormController`, `BatchController`, `ActionsController`, `WidgetsController`. This is how "CRUD controllers" are wired in: **they're all mixed-in concerns of `ResourceController`, not separately mounted controllers.**

Instance methods: `implicit_page_title` (builds resource-aware titles like "Edit User"), `implicit_resource_title`/`implicit_resource_title_for` (tries a configurable list of display methods), and protected: `processing_member_action?` (`params.key?(primary_param)` — the guard for `load_resource`), `scoped_resource`/`default_scoped_resource`/`chained_scoped_resource`, `find_chain_parents!` (walks nested-resource route annotations using `initialized_side_controllers`), `nested_scope_from` (infers the `belongs_to` reflection for a nested collection), and an overridden `add_page_action` (computes hrefs correctly for batch actions on member pages).

## Collection sub-architecture

`app/controllers/collection_controller.rb` (`CollectionController`) and `app/controllers/collection/{filter,pagination,scopes,sort}_controller.rb` are **concerns mixed into `CollectionController`, not separate controllers or routes.** There is no routing to them at all — confirmed against `railties/mapper.rb`/`routing.rb`, which never reference them.

`CollectionController` does `include BatchController`, then — **with an explicit comment "Order here is important, as they overload the load_collection method"** — `include SortController`, `include PaginationController`, `include ScopesController`, `include FilterController` (in that order). It also defines class-level macros (`includes`, `preload`, `eager_load`, `joins` — one per ActiveRecord method) that register a `before_action` mutating `collection_state.collection` via `public_send`.

**Chain of responsibility**: each of the four sub-concerns defines its own `load_collection(scope, state, <option>: ..., **)` that applies its own transform then calls `super` if defined. Because Ruby's `include` makes the **last-included module run first** in the ancestor chain, the actual call order is Filter → Scopes → Pagination → Sort → (base, returns scope unchanged). **All four `apply_collection_*` methods (`apply_collection_filter`, `apply_collection_scopes`, `apply_collection_pagination`, `apply_collection_sort`) are currently no-op pass-throughs that return `scope` unmodified** — they're extension points for host apps to override, not working filter/sort/paginate/scope features out of the box. Each file also exposes a `default_*_settings` (nil) and `current_*_value` (nil) stub pair.

`collection`/`collection_state` (memoized helper methods, `helper_method`-exposed), `load_collection` (calls the chain then `state&.ready!(result)`), and `assign_index_state_collection` (used by `IndexController`) round out `CollectionController` itself. See `admin-architecture.md` for `CollectionState`'s own API.

## `MemberController` (module `Torque::Admin::MemberController`)

`helper_method :member, :resource`. `member` memoizes `@<singular_key>` via `find_member!`; `resource`/`load_resource` are aliases of `member` (the latter is what `ResourceController`'s `prepend_before_action :load_resource, if: :processing_member_action?` actually invokes). `find_member!(id: params[primary_param], scope: scoped_resource, by: identified_by)` does `scope.find_sole_by(by => id)`.

## `IndexController` (module `Torque::Admin::IndexController`)

The most complete of the CRUD concerns. Class method `index(as: :table, **, &block)` is the public DSL end users call (see the dummy app's `Admin::ProjectsController`); it dispatches to `generate_#{as}_action_on`, which either hooks a `prepend_before_action` onto an existing action method or **synthesizes the action method itself** inside `generated_actions_module` if the host controller didn't define one. `define_table_element` (live since 2026-08-16 — it is the collection pipeline's first real caller): sets `@page_title`, runs the collection chain via `assign_index_state_collection` (which extracts `filter:`/`paginate:`/`scopes:`/`sort:` from the `index` options), derives name/`id`/`primary_key`/`source_type` options, and assigns `@table = @primary_element = TableElement.new(name, state, **options, preset: :index, &block)` (the template ivar is `@primary_element`, declared by `BaseController`'s `provide_template_ivars :@primary_element`; `app/templates/resource/index.html.erb` emits it). `SortController` is implemented around one interface method: **`default_sort_settings`** maps `params[:sort]` into `[reflection_or_nil, attribute, direction]` triples (`sort[name]=asc`, `sort[project][name]=desc`; any direction other than `desc` is `asc`; no filtering) — devs override it to change the mapping or add a default order, or pass `index sort: [...]` / `sort: false`. `apply_collection_sort` provides **one** sub-state, `SortController::Sorting = Struct.new(:values, :sortable, :href)` (`values` = `{ [reflection, attribute] => direction }`, `sortable` = `method(:sortable?)`, `href` = `method(:sort_href_for)`), read through `state.fetch(:values, from: :sort)`; then reduces the triples through `apply_collection_sort!(scope, attribute, direction, reflection:)`, which `left_joins` the reflection and `scope.merge(klass.order(attribute => direction))`. `sortable?(attribute, reflection:)` consults a **lazy per-class whitelist** `sortable_attributes(klass)` (default `klass.attribute_names`, memoized; devs override to add processed columns — beyond that we do no validation). `sort_href_for(attribute, reflection:, reset_page:)` cycles `asc → desc → removed`, merges into `request.query_parameters`, drops `page`. `IndexController#default_table_actions(*list, extras: %i[destroy])` (helper method) — `list` defaults to the resource's member actions, ordered as `action_methods`, then the `extras` that exist. **`PaginationController`** (innermost in the chain, so it paginates the sorted scope): `default_pagination_settings(per: 100, per_options: nil, mode: :page)` maps `params[:page]`/`params[:per]` (`per` honored only when in `per_options`); `apply_collection_pagination` builds `Torque::Admin::Pagination.build(config.resources.pagination_adapter, **settings, href: method(:page_href_for), per_href: method(:per_href_for))` (no scope inside the object), calls **`apply(scope)`** to get the paginated collection, then `provide`s it as `:pagination` (provide freezes, so apply comes first). `index paginate: { per: 10, per_options: [10, 25], mode: :cursor }` is bridged through `default_pagination_settings(**)` when it has no `page`; `paginate: false` disables; `default_pagination_settings(page: nil, per: nil, per_options: nil, mode: :page)`'s kwargs are the overridable defaults (`Pagination.default_per` = 100, `default_per_options` class attributes back them). Adapters: built-in offset/limit (`count` unless cursor, cursor `next?` via `offset(page * per).exists?`), `Pagination::Pagy` (`Pagy::Offset` / `Pagy::Offset::Countless`, pagy ≥ 43), `Pagination::Kaminari` (`page.per`, `without_count` for cursor). All expose `page per mode per_options count pages previous next first? last? href(page) per_href(per)`.

## `ShowController`, `BatchController`, `ActionsController`, `WidgetsController` — empty stubs

All four files contain **only** `extend ActiveSupport::Concern` plus a TODO comment describing planned functionality (show-page layouts for `ShowController`; centralized batch-action handling for `BatchController`; default `search` action + generic action execution for `ActionsController`; dashboard/index widgets for `WidgetsController`). **Zero methods, zero callbacks are implemented in any of these four.** Do not document these as working features.

## `FormController` (module `Torque::Admin::FormController`)

Partially implemented. `helper_method :form_record`. `form_record` memoizes `@<member_ivar>` (or `@<singular_key>`) via `initialize_form_record`, which does `processing_member_action? ? find_member! : build_new_record`. `build_new_record(scope:, using:, attributes:)` picks `:new` or `:build` based on nesting and delegates to the scope. **`initialize_form` exists but its body is commented out — currently a no-op.**

## `DashboardController` (module `Torque::Admin::DashboardController`)

On `included`: appends dashboard template paths (mirrors `ResourceController`'s pattern), `helper_method :dashboard_name`, `stream_actions :index if ...` (commented out, dead code), `authorize_actions! skip_if_none: true`. Includes `StreamController`. `controller_type` → `:dashboard`. `dashboard_name` strips app-module prefix and `Dashboard`/`Controller` suffix from the class name.

## `PageActionsController` (module `Torque::Admin::PageActionsController`)

`attr_reader :page_actions`. `provide_template_ivars :@page_actions`, `before_action :assign_page_actions` — the real callback that builds `@page_actions = ButtonsElement.new(:page_actions)` and (unless `infer: false`) calls `add_default_page_actions` (adds `new` on index, `edit`/`destroy` on show, gated by resource support) and `add_extended_page_actions` (a `:more` group of remaining actions on show). `add_page_action` appends an item; overridden by `ResourceController` (member-batch hrefs).

Note: `CancancanController` defines `add_inferred_page_action` (not `add_page_action`), so it does not actually participate in the `add_page_action` override chain as apparently intended — a likely latent bug/naming mismatch, not a documented feature.

## `SettingsController` (module `Torque::Admin::SettingsController`)

Included by `BaseController`, so active on every admin controller. `class_attribute :settings_for_actions` (default `{}`, write access made private), `helper_method :action_settings`. Class method `action_settings(*actions, **settings)` is a DSL macro to register per-action settings (e.g. `action_settings :index, :show, some_flag: true`); instance method `action_settings(setting, *, action: action_name)` reads them back. Has its own TODO: "I'm still not fully convinced that I will need this."

## `StreamController` (module `Torque::Admin::StreamController`)

Implemented, included by both `ResourceController` and `DashboardController` (though usage — `stream_from_actions` — is commented out at both call sites currently). Adds `class_attribute :stream_actions`, hooks a sync/async split around `ActionController::Live` (aliasing `process`/`process_sync`/`process_async` deliberately so both pre- and post-`Live` behavior are reachable), overrides `response_body=` to stream via `response.stream.writeln` when running async. `route_processing` dispatches sync vs. async per request; `process_action` wraps `super` with stream-disconnect handling and a per-thread async-job registry (`wait_all_async_processes!`, `initialize_async_process` — backed by the `Async` gem or `Concurrent::Future` depending on `admin_application_config.parallel_processing_with`).

## Authorization: `CancancanController` (module `Torque::Admin::CancancanController`)

**The only authorization integration that actually exists.** `include CanCan::ControllerAdditions`, `before_action :authorize_action!, if: :authentication_protected_route?` (the only enforcement callback in the whole controller layer). `authorize_action!` calls `authorize!(action, resource)`, rescuing `CanCan::AccessDenied` and degrading gracefully to a `fallback_authorization_action` if the user `can?` do that instead. Overrides `scoped_resource`/`nested_scope_from` to append `.accessible_by(current_ability, ...)`, and `build_new_record` to merge `current_ability.attributes_for(...)` into new-record attributes. `add_inferred_page_action` (intended to gate page actions by ability) doesn't actually hook into `add_page_action`'s call chain due to the naming mismatch noted above.

**`PunditController` and a base `AuthorizationController`** (for the `:torque_admin` adapter) do **not exist as files** — they're only names in `lib/torque/admin.rb`'s `eager_autoload` list, with no backing implementation. Selecting `authorization_adapter: :pundit` or `:torque_admin` raises at runtime.

## `app/helpers/formatting_helper.rb` (module `Torque::Admin::FormattingHelper`)

Admin formatters over `Torque::Elements::Formatter::Declarations`: `format_as_record` (title via `implicit_resource_title_for`, else `record.id`), `format_as_count` (`pluralize(size, model_name.human)`), `format_as_badge`/`format_as_badges` (`with:` value → color or option hash → `ui.badge`; label via `human_attribute_name("#{attribute}.#{value}")` when the formatter gets `entry:`/`attribute:`); `formatter_for` adds `to_model → :record`, `ActiveRecord::Relation → :count` before `super`. Record links use Rails' polymorphic mappings: `Application#register_polymorphic_mappings` (in `finalize_routes!`) registers one per resource so `url_for(record)`/`link_to title, record`/`edit_polymorphic_path(record)` resolve inside the engine through `Resource#member_url_options(record, action:)` (`projects/05-resource-paths.md`); unresolvable → `ActionController::UrlGenerationError`; `FormattingHelper#admin_routable?(record)` checks the mapping registry. `Resource#controllers`/`#controller_class` list the controllers the mapper set up for it.

## `app/helpers/application_helper.rb` (module `Torque::Admin::ApplicationHelper`)

`delegate :admin_application, to: :controller`. View-helper methods for admin chrome (`app_logo`, `app_page_title`, `app_banner`, `app_page_content`, `app_page_footer`, `app_menu_sections_for`, `app_translate`, etc.), mostly delegating to the `ui` (UI framework) object or i18n. Registered on every `BaseController` subclass via `helper Admin::ApplicationHelper`.

## Summary: what's real vs. stubbed

| Concern | Status |
|---|---|
| `BaseController` | Implemented |
| `ResourceController` | Implemented |
| `CollectionController` + Filter/Pagination/Scopes/Sort | Implemented as a composition mechanism; the four `apply_collection_*` transforms are no-ops (extension points) |
| `MemberController` | Implemented |
| `IndexController` | Implemented (most complete, still has open TODOs) |
| `FormController` | Partial (`initialize_form` is a no-op) |
| `ShowController` | Empty stub |
| `BatchController` | Empty stub |
| `ActionsController` | Empty stub |
| `WidgetsController` | Empty stub |
| `DashboardController` | Implemented |
| `PageActionsController` | Implemented (one likely method-naming bug with CanCanCan integration) |
| `SettingsController` | Implemented |
| `StreamController` | Implemented (not yet exercised — call sites commented out) |
| `CancancanController` | Implemented |
| `PunditController` / `AuthorizationController` (torque_admin) | Declared, not implemented — raises at runtime if selected |
| `SimpleController` | Declared, not implemented — raises at runtime if referenced |
