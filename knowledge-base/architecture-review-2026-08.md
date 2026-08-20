# Architecture Review — 2026-08-14

Combined evaluation: full-codebase pass + independent Rails-idiom review (prime), claims
verified against the working tree (Rails 8.1.1 per this repo's Gemfile.lock; dummy app on
8.1.3) and against live renders through the dummy-app runner harness. Table
(`projects/04`) excluded as a known teardown zone.

## Verdict

The hard architecture is right — one node spine, routes as the single source of truth,
public `render_in` at the boundary — and the private-API depth is mostly the honest price
of what's being built, not carelessness. The highest-return work is not architectural:
**the gem does not install from a build** (gemspec omits `app/`) **and nothing tells you
when Rails moves underneath it** (zero canaries over ~15 internal seams).

## Verified bugs (working tree, 2026-08-14)

1. `lib/torque/elements/core/template.rb:90` — `@config.arity.between(0, 1)` should be
   `between?`. `NoMethodError` the first time a templated element gets settings-style
   locals with a config block (dormant only because `use_template` has no call sites yet).
2. `lib/torque/elements/templates/render_context.rb:41-43` — `render_with_conditions`
   does `yield if conditions.empty?` then falls through to `raise 'This is more
   complex!'`. Missing `return`. Works today only because `render_tag`'s block non-locally
   `return`s when there is no before/after content; any node with `before`/`after` parts
   rendered in a template context raises.
3. `lib/torque/elements/nodes/basic_render.rb:22-27` — `render!` raises if `@to_s` is
   defined, then sets `@to_s = nil` and never assigns the result: the memo the guard
   protects is never written. Finish the memoization or delete the guard.
4. `lib/torque/admin/application.rb:126-127` — `const_defined?` without `false` uses
   ancestor lookup, and for bare modules that includes top-level constants (verified:
   `Module.new.const_defined?(:X)` is true for any `::X`). A host app with a top-level
   `::Engine` (or a constant matching the app module name) falsely aborts/short-circuits
   setup. Use `const_defined?(name, false)`.
5. `app/controllers/resource_controller.rb:117-126` — `reflection` local ends up holding
   a `Symbol` (`...&.name`); `reflection.name` then only works because `Symbol#name`
   exists (Ruby ≥3.0). Rename the variable or keep the reflection object.
6. `lib/torque/elements/builders/helper_builder.rb:153-166` — the
   `import_shared_properties` branch for an already-declared property calls `Hash#insert`
   (doesn't exist). Dead path today; would raise if a helper declared `property(:icon)`
   and also `imports(:icon)`.

## Packaging / boot landmines (will bite first)

- `torque-admin.gemspec:28` — `spec.files` omits `app/**/*`: controllers, elements,
  helpers, views, frames, templates, the logo asset (everything under `APP_DIR`) do not
  ship in a built gem. Only works today because the dummy consumes by path. Also
  `spec.test_files` is removed in modern RubyGems.
- `lib/torque/admin.rb` `eager_autoload`s `PunditController`, `AuthorizationController`,
  `SimpleController` with no backing files, and `config.eager_load_namespaces` includes
  `Torque::Admin` — a production boot (`eager_load = true`) raises `LoadError` before
  serving a request. `SimpleController` is additionally reachable from the routing DSL
  (`simple do ... end`) and the lazy-constants file.
- Other dangling autoloads that raise on first touch: `Forms::Base`,
  `Elements::Component`, `Helpers::Tailwind` — and `theme: 'tailwind'` is the **default
  config**, so the out-of-box configuration cannot boot a UI.
- `Torque::Elements::Accessors` lives at `app/controllers/accessors.rb` (an Elements
  library class under `app/controllers/`), its autoload points at a nonexistent
  `lib/torque/elements/accessors.rb`, and nobody references it. Delete or relocate when
  Project 2 needs it.

## Private-API exposure, tiered

Zero canaries exist; that makes all of this unmanaged risk. Full inventory in prime's
review; the tiers:

**Tier A — deep coupling, probably unavoidable, needs canaries.**
- Routing: `Mapper::Mapping#build` re-declares a 12-positional private signature
  (`railties/mapper.rb:7-24`) matched byte-for-byte against actionpack; churned across
  7.x; a change fails *silently* via positional misalignment. Plus `with_scope_level`,
  `resource_scope`, `name_for_action`, direct `@set.named_routes[...]` writes, and
  annotations smuggled through `scope_options` into `Journey::Route` — which Journey
  itself reads during URL generation.
- Template machinery: `FileSystemResolver#_find_all` override reusing private ivars;
  `ActionView::PathRegistry.instance_exec` into a framework singleton's private state
  (`templates.rb:42-50` — the single most fragile line in the gem); `UnboundTemplate`
  driving `compile`/`@compile_mutex`/`_run`; `PartialRenderer.new(nil, {}).send(:render_partial_template, ...)`.
- Frame: a deliberate fork of `ActionView::Layouts` keyed off private
  `_process_render_template_options`; doubles the Layouts-shaped private surface — a
  judged trade, but a named cost.

**Tier B — narrower/public paths exist.**
- Runtime reads of `request.get_header('action_dispatch.route')` and
  `route.scope_options.dig(:annotations, ...)` (`base_controller.rb`,
  `items_from_router.rb`): the gem already builds every `Resource` at draw time — it
  could own an annotations map keyed by route name/controller+action and stop reading
  Journey internals at runtime. Cheapest large surface reduction available.
- `PROTECTED_IVARS.concat` (both railties), `ABSTRACT_RAILTIES <<`,
  `tag_builder.content_tag_string`, the `in_rendering_context` hook.
- `Helpers::Template::Buffer#gsub` — defeats SafeBuffer escaping by intercepting the
  exact `gsub('"', '&quot;')` TagHelper makes internally; breaks *silently into emitted
  HTML* if TagHelper changes. Already slated to die with Project 2.

**Tier C — fine.** `const_missing` lazy constants (pure Ruby),
`Rails.autoloaders.main.on_load` (public Zeitwerk — the right way), `render_in` (public
renderable protocol).

## What is genuinely good — keep, defend against refactor

- The unified node spine + classification DSL (`GeneratedNodesMethods` override-plus-
  `super` pattern mirrors Rails' own attribute-method generation).
- Public `render_in` integration; dispatch-failure messages that enumerate every
  attempted target; `Context` as `CurrentAttributes`; Tempfile-backed codegen giving real
  backtraces; `Traverse`; route-as-single-source-of-truth; lazy constants; the documented
  `DEFAULT_CONFIG`; the honesty of `projects/*.md` / `knowledge-base/*.md` about stubs.
- The helper-definition DSL earns its keep (~20 SemanticUI components in 185 declarative
  lines, shared fragments reused; hand-written would be 3–4x with drift). Keep the
  approach; straighten internals when next touched (the `'end'`-rotation trick and
  positional `insert` splices are safe only for their author — restructure to
  self-contained `[open, *body, close]` triples; extract `flatten_options` to a
  module-level function and delete the `UiBuilder.allocate`).

## Structural opinions (prime, endorsed)

- **Move nested-chain resolution onto `Resource`.** `find_chain_parents!` instantiates
  sibling controllers via `allocate`, grafts request/response (`initialize_as_slave_of`),
  and drives their protected methods by `send`. Finding `Project → Task → Requirement`
  parents needs a Resource, a param, and a reflection — no controller carcass. Side
  controllers then shrink to breadcrumb label lookup.
- **Renames while alpha makes them free**: `slave_controller?`/`initialize_as_slave_of`
  (retired vocabulary), `titlelize` (misspelling baked into an override point:
  `textify.rb`, `menu_element.rb`), `Registry#new` (instance method with
  `||=`-and-discard semantics).
- `StreamController`'s alias sandwich around `ActionController::Live` is clever but
  depends on undocumented override behavior — needs the canary more than a rewrite.
- Overlaps worth knowing, not deleting: `ListHandler` vs `token_list`/`class_names`;
  `flatten_options!` nested-key walk vs TagBuilder's native `data:`/`aria:` handling;
  `Elements.node_id` vs `parameterize` (the `.` → `--` rule is load-bearing for i18n).

## Recommended order

1. **Packaging/boot fixes** (~30 min, pure deletion + one Dir glob): `app/**/*` into
   `spec.files`, drop `spec.test_files`, delete or de-eager the dangling autoloads.
2. **One internals-contract canary file** (runner-harness style per the verification
   recipe — not a spec suite): assert `Mapping.build` parameters,
   `Journey::Route#scope_options`, `FileSystemResolver#_find_all` arity,
   `PartialRenderer#render_partial_template` presence, one full page render. Turns
   "Rails 8.2 broke something somewhere" into a named failure.
3. **The verified bugs** above (items 1–4 especially).
4. **Own the route-annotations store** (draw-time write, runtime read from own map) —
   retires the second-largest Tier-A surface in an afternoon.
5. **Chain resolution onto `Resource`** + the renames.
6. Do **not** refactor the node spine, dispatch chain, Frame, or the HelperBuilder
   approach.

## Branch state (context for the above)

Main's working tree = Project 1 landed (uncommitted at review time). Project 2's
implementation (`CompileController`, `StagedRequest`, `element_slot`, declarative
`page_actions` + `ItemsFromController`) exists **only on the unmerged local branch
`template-attempt`** (c4bf3fd, atop an "UNDO" commit). The dummy's
`Admin::UsersController` uses that branch's `page_actions` DSL and fails to load against
main; `Admin::ProjectsController` renders complete pages on main. Landing Project 2 on
main (merge vs redo) is the open decision before Project 3.
