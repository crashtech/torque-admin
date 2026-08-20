# Torque Admin - Technical Reference

## Overview

Torque Admin is a Rails gem that provides a modular admin engine system for building administrative portals. It's designed to be plug-and-play, leveraging the latest HTML and CSS resources with Hotwire support.

The gem is early-stage (`0.1.0.a1`). The `Elements` foundation layer is substantially built out; the `Admin` composition layer's routing/controller-generation machinery works, but several controller concerns (`ShowController`, `BatchController`, `ActionsController`, `WidgetsController`) and the entire `Forms` layer are stubs. See the other `knowledge-base/*.md` docs for the file-by-file status.

## Architecture

The gem is organized into three main components:

### 1. Elements (`lib/torque/elements/`)
The foundation layer that provides Rails enhancements and component-based classes. It includes:
- `Torque::Elements::Base` plus its `Core::*` mixins (indexing, node management, rendering, template macros, settings/i18n helpers, node/attribute definition)
- Node-based architecture for component composition (`Node`, `ColumnNode`, `LinkNode`)
- Handlers that merge and serialize HTML attribute values (content, conditional, format, list, map, ref)
- Builders for aliases and helpers (`AliasBuilder`, `HelperBuilder`)
- `Context` (request-scoped state) and UI framework support (`UiBuilder`)
- A `Frame` system for layout-between-the-layout, resolved to `app/views/frames/*.html.erb`

### 2. Forms (`lib/torque/forms/`)
A stub layer. `lib/torque/forms.rb` declares autoloads for `Base` and `Element`, but `Torque::Forms::Base` has no backing file (a `LoadError` waiting to happen). `Torque::Forms::Element` is a small `Torque::Elements::Base` subclass adding icon settings for form buttons only — no input types, validation, or Rails form-helper integration exist yet.

### 3. Admin (`lib/torque/admin/`)
The main composition layer that brings together all features:
- `Application`/`Engine` classes — one `Application` per named admin instance
- Resource management — `Resource` objects inferred from drawn routes, not declared directly
- Controller scaffolding — mostly `ActiveSupport::Concern` modules mixed into per-application dynamically generated classes (see `lib/torque/admin/application/lazy_constants.rb`), not directly-subclassable classes
- Element components (Buttons, Breadcrumb, Menu, Table)
- Theme support — only `Themes::SemanticUI` has an admin-level override; Bootstrap/Bulma use the plain Elements helpers; default theme (`tailwind`) has no implementation

## Key Features

### Component Architecture
- Node-based component system
- On-the-fly template generation using "unbound" templates as macros: an unbound template (e.g. `app/templates/resource/index.html.erb`) runs once per virtual path to generate the source of a real, bound `ActionView::Template`, which Rails compiles/renders normally — nothing is written to disk unless `Torque::Elements.debug_templates!` is enabled
- UI frameworks actually implemented: **Bootstrap, Bulma, Semantic UI**. `Tailwind` is a dangling autoload (declared, no file); Material UI isn't referenced anywhere in the code
- Handlers manage HTML attribute-value merging/serialization (`class`, `style`, `data-*`, conditional attributes), not general component composition

### Controller Structure
The gem provides controller-behavior *concerns*, mixed into per-application generated classes:
- `BaseController` - layout/frame selection, page title, i18n scopes, conditional authorization-adapter inclusion
- `ResourceController` - resource scoping, nested-resource chains; mixes in the CRUD concerns
- `CollectionController` - chain-of-responsibility collection loading (filter/scopes/pagination/sort, each currently a no-op extension point)
- `MemberController` - finds/memoizes the current record
- `IndexController`, `FormController` - implemented (index more completely than form)
- `ShowController`, `BatchController`, `ActionsController`, `WidgetsController` - **empty stubs**, TODO comments only
- Authorization: only CanCanCan is implemented; Pundit and a built-in `torque_admin` adapter are accepted config values with no backing controller files

### Elements
Pre-built UI components (all on the post-Project-1 unified core — see `element-components.md`):
- `ButtonsElement` - implemented (`render_button` element hook, groups/dividers)
- `BreadcrumbElement` - implemented, powered by the `ItemsFromAction` concern
- `MenuElement` - implemented (`ItemNode` + `ui.menu_entry`), powered by the `ItemsFromRouter` concern
- `TableElement` - implemented on the unified core (`projects/04-table-element.md`, stages 1–4): columns/parts, footers, `each_row`, per-row actions, sortable headers; formatting via the view `formatter` proxy (`projects/03-formatting.md`)
- `BaseElement` - pure abstract marker (`abstract_class = true` only)

## Usage

The gem is designed to be used as a Rails engine that can be mounted in applications. It provides:

1. **Modular structure** - Separate concerns between elements, forms, and admin components
2. **Extensible design** - Easy to extend with custom handlers, components, and controllers
3. **Framework agnostic** - Bootstrap, Bulma, and Semantic UI today; Tailwind planned but unimplemented
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
│   ├── templates/        # Unbound "macro" templates
│   ├── views/            # Frame layouts and other views
│   └── assets/           # Static assets
├── knowledge-base/       # Deep-dive architecture docs
└── spec/                 # Tests
```

## Integration

To use Torque Admin in a Rails application:
1. Add the gem to your Gemfile
2. Use the `admin` routing DSL in `routes.rb` (e.g. `admin :default, '/admin' do ... end`) — this lazily builds and mounts the engine; there is no manual `mount Torque::Admin::Engine => '/admin'` step
3. Configure admin applications and resources
4. Customize components as needed

The gem supports both the default application instance (`Torque::Admin[:default]`, internally named `:admin`) and custom named instances (`Torque::Admin[:custom]`), lazily created and memoized on first `[]` access.

Admin Resources are created from the defined routes, not declared directly in code. An Admin Resource is an indicator of an admin application resource: it manages its name, sections, actions/widgets (from route annotations), a displayable title, and a pointer to the actual resource class — resolved by taking the route-derived name and calling `.classify.constantize` on it (e.g. `"user"` → `User`).

Admin applications must run under a module namespace, so all controllers must be under a module (like `module Admin`). With that, one can reference `< ResourceController` because that module has had lazy, `const_missing`-based constants (`Resource`, `BaseController`, `ResourceController`, `DashboardController`, `SimpleController`) installed into it at setup time.

## Lazy Constants

Applications have a way to lazily resolve constants via `const_missing`. The `Torque::Admin::LazyConstants` module provides this via `lazy_constant`/`clear_lazy_constants`; if a constant is referenced and not already defined, its registered builder block runs once and the result is memoized with `const_set`.

The lazy constant loading is implemented in:
- `lib/torque/admin/lazy_constants.rb` — the generic mixin
- `lib/torque/admin/application/lazy_constants.rb` — the snippet evaluated into each generated application module

## Versioning

Current version: 0.1.0.a1

## License

MIT License - Copyright © 2024 Carlos Silva
