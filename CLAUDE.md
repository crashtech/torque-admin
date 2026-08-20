# Torque Admin - CLAUDE Documentation

## Overview

Torque Admin is a Rails gem that provides a modular admin engine system for building administrative portals. It's designed to be plug-and-play, leveraging the latest HTML and CSS resources with Hotwire support.

The gem is early-stage (`0.1.0.a1`): the `Elements` foundation and the `Admin` routing/controller composition layer are substantially built out, but several pieces are explicitly unfinished stubs or scaffolded-but-not-implemented. See "Implementation Status" below before assuming a documented feature works end-to-end — the `knowledge-base/` docs call out the specifics per area.

## Architecture

The gem is organized into three main components:

### 1. Elements (`lib/torque/elements/`)
The foundation layer providing Rails enhancements and component-based classes. Since the
Project 1 unification (2026-08), elements and nodes are one inheritance spine:
`BasicNode` (physical: tag + options + children + explicit `parent`/`element` refs, no
variants; rendering organized in `BasicNode::BasicRender`) → `Node` (logical: id,
settings, i18n; variations like `LinkNode`) → `Base` (the element — its own root, with a
classification DSL, lazy per-element index, config-block loading). Any `Base` declared
through the controller `element` DSL is application-reachable. It includes:
- A classification DSL (`node :item, as: :link` / `node :divider, as: :basic` /
  `setting :sort, ...`) — `as:` resolves through `Node::TYPES` or takes a Class, defaulting
  to `Node` — generating child DSL methods into an auto-included module
  (override + `super` works)
- Direct-helper render dispatch: element method `render_#{type}` → view helper
  `render_#{name}` → `ui.#{name}` (name convention `#{element.type}_#{node.type}`) — no
  handler chains
- Handlers for attribute-value merging/serialization (content, conditional, format, list, map, ref)
- Builders for aliases and helpers (`AliasBuilder`, `HelperBuilder`, compiled via `HelperConstructor`)
- `Context` (request-scoped `CurrentAttributes`) and a pluggable UI-framework system (`UiBuilder`)
- A `Frame` system — a layout-between-the-layout mechanism resolved to `app/views/frames/*.html.erb`

See `knowledge-base/elements-architecture.md` for details, and `projects/01-node-element-unification.md` for the settled design.

### 2. Forms (`lib/torque/forms/`)
This layer is a **stub**. `lib/torque/forms.rb` only declares autoloads for `Base` and `Element`; `Torque::Forms::Base` has no backing file (referencing it raises a `LoadError`). `Torque::Forms::Element` is a thin `Torque::Elements::Base` subclass that adds icon-related settings for form buttons — there are no input types, no validation integration, and no Rails form-helper integration yet. See `knowledge-base/forms-architecture.md`.

### 3. Admin (`lib/torque/admin/`)
The main composition layer that brings together all features:
- `Application`/`Engine` classes, one `Application` per named admin instance (`Torque::Admin[:name]`)
- `Resource` — inferred from drawn routes, resolves its model class by `classify.constantize` on the route-derived name
- Controller scaffolding: most `app/controllers/*.rb` files are `ActiveSupport::Concern` modules, not classes — see `knowledge-base/controller-structure.md`
- Element components (Buttons, Breadcrumb, Menu, Table)
- Theme support (only `Themes::SemanticUI` currently has an admin-level override module; Bootstrap/Bulma rely on the plain Elements helpers; default theme is `tailwind`, which has no implementation yet)

See `knowledge-base/admin-architecture.md`.

## Key Features

### Component Architecture
- Node-based component system
- On-the-fly template generation using "unbound" templates as macros: an unbound template file (e.g. `app/templates/resource/index.html.erb`) is executed once per distinct virtual path to generate the *source* of a bound `ActionView::Template`, which Rails then compiles/renders normally. Nothing is written to disk in production; source can optionally be dumped for debugging via `Torque::Elements.debug_templates!`.
- UI frameworks actually implemented: **Bootstrap, Bulma, Semantic UI** (`lib/torque/elements/helpers/{bootstrap,bulma,semantic_ui}*`). `Tailwind` is declared as an autoload with no backing file (dangling); Material UI is not referenced anywhere in the codebase.
- Extensible handler system: handlers merge/serialize HTML attribute values (`class`, `style`, `data-*`, `@content`, `if`/`unless`) — not general "component composition."

### Controller Structure
The gem provides a set of controller *concerns* mixed into dynamically generated per-application classes (see `lib/torque/admin/application/lazy_constants.rb`):
- `BaseController` — layout/frame selection, page title, i18n scopes, optional authorization-adapter inclusion
- `ResourceController` — resource scoping, nested-resource chain resolution; mixes in the CRUD concerns below
- `CollectionController` — chain-of-responsibility `load_collection` composed from `Filter`/`Scopes`/`Pagination`/`Sort` sub-concerns (each currently a no-op extension point)
- `MemberController` — finds/memoizes the current record
- `IndexController` — builds the `TableElement`; most complete of the CRUD concerns
- `FormController` — partially implemented (`initialize_form` body is commented out)
- `ShowController`, `BatchController`, `ActionsController`, `WidgetsController` — **empty stub modules**, TODO comments only, no methods
- `DashboardController`, `PageActionsController`, `SettingsController`, `StreamController` — implemented
- Authorization: only `CancancanController` (`app/controllers/authorization/cancancan_controller.rb`) is actually implemented. `PunditController` and `AuthorizationController` (for a built-in `:torque_admin` adapter) are declared in the `eager_autoload` list and accepted as `authorization_adapter` config values, but have **no backing files** — selecting them raises at runtime. `SimpleController` has the same dangling-autoload problem.

See `knowledge-base/controller-structure.md` for the full, file-by-file breakdown including what's real vs. stubbed.

### Elements
Pre-built UI components (`app/elements/*.rb`):
- `BaseElement` — abstract base for admin elements
- `ButtonsElement` — converted to the unified core (classification DSL, `render_button` element hook); groups, icons, dividers, link-based buttons
- `BreadcrumbElement` — converted to the unified core; most of its power comes from the `Torque::Admin::ItemsFromAction` concern (auto-imports breadcrumb trail from the current controller/action)
- `MenuElement` — converted to the unified core (`MenuElement::ItemNode` computes logical flags; `Helpers::SemanticUI#menu_entry` does the physical composition); most of its power comes from the `Torque::Admin::ItemsFromRouter` concern (auto-imports menu structure by walking the Rails route set)
- `PaginationElement` (`< ButtonsElement`; `per` as a second node type) — first/prev/pages/next/last and per-page buttons over a `Torque::Admin::Pagination` (built-in, `Pagination::Pagy`, `Pagination::Kaminari` via `config.resources.pagination_adapter`; `apply(scope)`); embedded by the table by default
- `TableElement` — on the unified core since 2026-08-16 (`projects/04-table-element.md`, stages 1–4): `node :column, as: :column, renders: false, parts: %i[col header cell footer]` with pull-based cached parts and zero nodes per cell; footers (`aggregate:`/`all:`), `each_row` (via `Elements::Deferred`), row `actions` (`t.actions :show, :edit do |a, entry| … end` — a nested `ButtonsElement` rendered per row through `Base#render_in(reset: true)`, per-entry leaves as `Elements::Deferred`/Procs closing over a `SimpleDelegator` entry proxy, collapsed by `view_context.collapse_proc`), sortable headers (`?sort[key]=asc`, merged into current params). `as:` symbols resolve through the view `formatter` proxy (Project 3, landed 2026-08-17: `Torque::Elements::Formatter`, `format_as_*` view helpers declared with `Formatter::Declarations#formatter/formatters`, `formatter_for` inference, `Helpers::Formatting` pack + admin `record`/`count`). `selection`/`row_number` not yet.

See `knowledge-base/element-components.md` (updated post-unification) and `knowledge-base/ui-builder-and-helpers.md` for how elements' `ui.*` dispatch targets are built.

## Usage

The gem is designed to be used as a Rails engine that can be mounted in applications. It provides:

1. **Modular structure** - Separate concerns between elements, forms, and admin components
2. **Extensible design** - Easy to extend with custom handlers, components, and controllers
3. **Framework agnostic** - Supports Bootstrap, Bulma, and Semantic UI today (Tailwind planned, not implemented)
4. **Hotwire ready** - Built with Turbo and Stimulus in mind

## Project Structure

```
torque-admin/
├── lib/
│   ├── torque/
│   │   ├── elements/     # Core component system
│   │   ├── forms/        # Form handling components (stub)
│   │   └── admin/        # Main admin composition layer
│   └── torque-admin.rb   # Main gem entry point
├── app/
│   ├── controllers/      # Admin controller concerns
│   ├── elements/         # UI elements
│   ├── helpers/          # View helpers
│   ├── templates/        # Unbound "macro" templates (app/templates/resource/*)
│   ├── views/            # Frame layouts (app/views/frames/*) and other views
│   └── assets/           # Static assets
├── knowledge-base/       # Deep-dive architecture docs (see below)
└── spec/                 # Tests
```

## Integration

To use Torque Admin in a Rails application:
1. Add the gem to your Gemfile
2. In `routes.rb`, use the `admin` routing DSL (added to `ActionDispatch::Routing::Mapper` by the Railtie) — e.g. `admin :default, '/admin' do ... end` — **not** a manual `mount Torque::Admin::Engine => '/admin'`; the engine is built and mounted lazily per named application by this DSL method.
3. Configure admin applications via `Torque::Admin.configure { |config| ... }` (always targets the default/`:admin` app) or `Torque::Admin[:custom].configure { |config| ... }` for a named one
4. Customize components as needed

The gem supports both the default application instance (`Torque::Admin[:default]`, internally named `:admin`) and custom named instances (`Torque::Admin[:custom]`), each lazily created on first `[]` access and memoized in `Torque::Admin.instances`.

Admin Resources are created from the defined routes, not declared directly — there is no `Torque::Admin[:default].resource :users do ... end` API. Drawing `resources :users` under an `admin` block causes `Application#fetch_resource` to build a `Resource` whose class is guessed by taking the route-derived, namespace-stripped name and calling `.classify.constantize` (e.g. `"user"` → `User`, `"blog/post"` → `Blog::Post`). A `Resource` manages its name, sections, actions/widgets (bucketed from route annotations), and this resolved class; `resource/active_model.rb` prefers `resource_class.model_name` for display titles when available.

Admin applications must run under a module namespace (e.g. `module Admin`). This works because `Application#setup_application_module` `module_eval`s `lib/torque/admin/application/lazy_constants.rb` into the generated module, giving it `const_missing`-based lazy constants (`Resource`, `BaseController`, `ResourceController`, `DashboardController`, `SimpleController`) — so referencing `< ResourceController` inside that module resolves (and memoizes) to a dynamically built class, but only from code lexically inside that specific app module.

## Versioning

Current version: 0.1.0.a1

## Lazy Constants

Applications have a way to lazily resolve certain constants via Ruby's `const_missing` hook. The `Torque::Admin::LazyConstants` mixin (`ActiveSupport::Concern`) provides `lazy_constant(*names, &block)` to register a builder block per constant name and `clear_lazy_constants` to reset already-resolved ones; `const_missing` looks up the registered block and memoizes the result via `const_set` so it only runs once.

The mechanism is implemented in:
- `lib/torque/admin/lazy_constants.rb` — the generic, reusable mixin
- `lib/torque/admin/application/lazy_constants.rb` — a source snippet `module_eval`'d into each generated application module, registering `Resource`, `BaseController`, `ResourceController`, `DashboardController`, `SimpleController`, and a (currently empty) nested `Devise` module

## License

MIT License - Copyright © 2024 Carlos Silva
