# Reviewer Preferences: Carlos Silva

A cheat-sheet for anticipating Carlos's code review feedback so PRs land cleanly on
the first pass. Every item below is grounded in his actual review comments.

**Scope of evidence:** Built from a substantial body of real review comments (inline
suggestions + prose; empty "Changes requested"/"Approved" reviews excluded) on a
Rails/Ruby (ActiveAdmin, Arbre, Stimulus) codebase, so his preferences below are
strongly Rails-idiomatic.

**Who he is on the team:** He is effectively the lead/architect of the codebase, not a
peer reviewer. He speaks from authorship: "My idea was…", "I already set…", "I fixed
with…" Treat his preferences as established conventions to align with, not
optional suggestions to weigh.

---

## Things Carlos dislikes (strong, recurring themes)

These appear across many reviews — treat them as near-certain feedback.

- **Over-engineering / scope creep.** His #1 hot button. He rejects changes that do more
  than the task needs.
  - "This PR is no good on several things. It's overdoing and changing things that
    make no sense!"
  - "It's adding a gem for something really simple. Plus, it's adding an attribute
    on tenants that's not necessary. What is the actual request here?" — He then *took over
    the branch and showed the fix*: deleted the `attr_accessor :owner_email` virtual attr and
    the `provisioned_admin_email` + `served_domain` derivation helpers from `Tenant`, made the
    form field **required**, and read the value straight from `params.dig(:tenant, :owner_email)`
    at the point of use. Lesson: a form-only, transient input doesn't belong on the model, and a
    required field beats an elaborate derived fallback (see the two items below).
  - A contributor once justified an elaborate "latent 500" fix; Carlos:
    "The 500 would never happen because we always load the ApplicationController… there is
    no reason to define the const 2 times. Plus, Current is a terrible place to put it."
    He distrusts scope creep *even when it's framed as thoroughness/going deeper*.

- **Unnecessary code that should just not exist.** He routinely says to delete whole
  jobs, models, mailers, files, and methods.
  - "You don't need this job." / "You don;t need this model anymore."
  - "This is pointless right now. We are not calling/triggering these emails, so
    there is no reason to have them."
  - "This file can be removed."
  - "This one is outdated. We don't need it anymore."
  - "Not actually needed at the moment, since we don't have full translations."
  - In one of his own refactor commits he deleted an `attr_accessor :owner_email` and two
    model methods (`provisioned_admin_email`, `served_domain`) — "Remove unnecessary code
    from tenant model." **Don't add a virtual attribute or helper method to a model for a
    transient, form-only input.** Read it from `params` at the point of use
    (`params.dig(:tenant, :owner_email)`) instead of routing it through the model and
    `permit_params`.
  - Many of his ````suggestion` blocks are *empty* — meaning "delete these lines."

- **Logic in the wrong place / wrong layer.** He insists code lives where it belongs.
  - "This should be in the model." (re: logic placed in an ActiveAdmin file)
  - "It shouldn't be the responsibility of this part to handle that, as we have
    helpers that handle… this."
  - "This is in the wrong place."
  - "This logic belongs only to `primary_domain`."
  - "Not here! …This file is exclusively for the things that we are sure to always
    have." (re: putting per-app config in a shared "always present" file)

- **Repeating / duplicating behavior, and overriding existing config.** Don't re-implement
  what the framework or his existing setup already does.
  - "Don't do this! We have no reason to change or repeat behavior. I already set
    `config.parent_mailer = 'ApplicationMailer'`, so this just adds to our maintenance code!"
  - "These lines are duplicated."
  - One PR title was literally "Removing duplicated render array component" (a fix he wanted).
  - "Don't duplicate the default. The information should be in one place, and the
    job should demand it." (re: a `def trigger_build(repo, payload, event_type = 'build')`
    default duplicating the `default: 'build'` already declared on the `App` model.) A
    default belongs to its single source of truth; a lower-layer method should take the
    value as a **required** argument and let the caller supply it, not re-declare the
    fallback.

- **Committing generated schema files.** A hard "never."
  - "Don't push the changes to `db/cache_schema.rb` and `db/queue_schema.rb`. This
    is something I fixed with the help of someone else, and we should never add those lines."

- **Comments / suggestions placed wrongly or sloppily.**
  - "Just adjust the comment, it's in the wrong position, look the other for example."

- **Too many code comments.** The code should speak for itself; he objects to inline comments
  that just restate what the code already does. Seen on both app code and specs — treat as a
  near-certain blocker, not a nit.
  - "There's too many inline comments that are unnecessary — the code speaks for itself."
  - "Remove ALL inline comments." (on test-harness specs — the absolute framing is literal;
    he strips *every* explanatory comment, keeping only functional magic comments like
    `# frozen_string_literal: true`.)
  - Default to no comment. Add one only when genuinely necessary, and then keep it intentful and
    concise — a short `# why` for rationale that would surprise a later reader, never a narration
    of *what* the code does.

- **Security shortcuts.** He reacts hard to weakened auth.
  - "Let's close this PR because of this, which is a major security problem! This
    puts the authorization based exclusively on the receiving param… Our current
    authorization scheme, the key that both ends hold independently, is good."
  - "If we receive a webhook request but the secret is not set, we should also
    return an unauthorized response, since the request was likely unexpected."

- **Convoluted / hard-to-read code.**
  - "I'm not a huge fan of this haduken code 😔" (deeply nested / staircase code).

---

## Things Carlos wants (recurring)

- **Validations and domain logic in the model**, not in controllers/admin.
- **Correct, idiomatic ActiveRecord/Rails:** e.g. uniqueness validation scoped with
  `conditions:`, `case_sensitive: true`, and `if: :will_save_change_to_email?` rather than
  skipping the email-format validation entirely. Don't bypass validations you only
  meant to narrow.
- **Lean on existing helpers/abstractions and his prior work** instead of new code
  ("we have helpers that handle this").
- **State the *why*.** When he can't see why a change exists, he asks rather than guesses,
  and tends to reject: "What is the actual request here?", "Why we need this seed?
  Is this for other devs?" Put the intent in the PR description.
- **Use Stimulus controllers for checkout/view JS** rather than inline scripts
  ("We should turn this into a Stimulus controller. Let's talk ways to do that").
- **Require the input rather than synthesize a clever fallback.** In one review he replaced an
  optional field + derived-default machinery (build `admin@<slug>.<suffix>.<host>` when blank)
  with a plain `required: true` field and no derivation. When a real value is needed, demand it
  from the operator/caller; don't guess one. (Mirrors "the job should demand it" — one
  source of truth, the lower layer requires the value instead of re-declaring a fallback.)

- **Model the concept with the existing domain model; don't invent a loose identifier.**
  In one review, a new table first carried a `device_id` string. Carlos: "We do have the concept
  of user devices, which maps to an authenticated device of the user. If we call it a device
  ID, but don't map to any other model, it should be `external_id`." Then, having pointed at
  the right model: "If you're gonna do it via `user_device_id`, then you don't need
  `user_id`! User and Tenant should be inferred from the `UserDevice` model." Three durable
  rules come out of that thread:
  - **A `<thing>_id` column must be a real foreign key.** An opaque, externally-supplied
    identifier that maps to no model is named **`external_id`** — his standing convention
    (`Product.external_id`, `Upsell.external_id`, `ArrayAlert.external_id`,
    `Customer#subscription_external_id`) — never `<noun>_id`, since the `_id` suffix implies
    an association that doesn't exist.
  - **Check for an existing model before adding an identifier.** If the platform already
    models the thing (here `UserDevice`, keyed on the JWT audience), associate to it with a
    real FK instead of storing a free-floating string. Reuse the abstraction.
  - **Don't denormalize an association you can traverse.** Once a row `belongs_to
    :user_device`, its `user` — and that user's `tenant` — are reachable through it, so the
    redundant `user_id`/`tenant_id` columns must go. One source of truth; infer through the
    association. (This is the grounded form of the "drop a redundant column" prior and a
    tenant-through-association pattern.)
- **Name the model after what the row actually is.** One model churned through several names
  before landing: the row is the *antivirus scan details* for one device — not a device
  registry, not a "metric." Pick the noun that matches the data and mirror it in the table,
  route, and controller.

## Model-centric operations (a keyless-check feature)

A five-round review that started as service objects + `Data` structs + a job + value objects
and was driven all the way down to a single `ActiveRecord` model owning the whole operation.
The arc *is* the lesson: **when a feature is "take an input, produce a stored result," put the
entire thing on the record model** — no service, no job, no companion value/DTO classes.
"Centralize everything in the model!!! With that, we don't even need the job. We gain
everything for free." (Corroborates the no-`app/services`, no-`Data` rules and
[[no-services-no-data]].) Concretely, the shape he steered to:

- **Pluggable steps are `include`d concerns that override one entry method and `super`-chain.**
  Each signal concern overrides `evaluate_query`, does its work, then calls `super`; the model's
  own `evaluate_query` runs the chain and then produces the result. **Use `include`, never
  `prepend`** — he called `prepend` out explicitly. (With `include` the class method is first in
  the ancestor chain, so it calls `super` into the concerns; the deepest concern needs
  `super if defined?(super)` to terminate cleanly.)
- **A concern's helper methods must be idempotent and never take `self`.** Pure helpers go in
  `class << self` on the concern (`Concern.parse(raw)`, `Concern.tld(host)`) so they don't leak
  onto the model; the instance-level `evaluate_query` reads the record's own state directly. He
  rejected `Concern.evaluate(self, payload)` outright: "`evaluate` is not idempotent!!! …`self`
  should never be provided as an argument."
- **The model provides a single standardized writer** (`add_finding`) that the concerns call.
  **Mandatory params are positional; keyword args are only for the variadic tail** — his exact
  wording: `def add_finding(source, severity, icon, text, **replacements)`, "use positional
  arguments for mandatory ones, and leave named just for replacements."
- **Store as symbols and let Rails cast on write.** Build result hashes with **symbol keys**
  ("keep all hash keys as Symbols … we won't ever be updating these records") and don't
  pre-stringify — "renders and models already deal with data transformation; don't state what is
  already expected." (Practical note: assigning a symbol hash to a `json`/`jsonb` attribute
  round-trips to string keys *on assignment*; appending with `<<` keeps symbols in memory until
  save. Assert the real runtime type in specs, not the type you wrote.)
- **`<<` to append to a collection attribute**, not `self.x += [..]`: "Use fast `<<` assignment."
- **Scope the I18n lookup** instead of repeating a key prefix at every call:
  `I18n.t(key, scope: "sentinel.findings.#{source}")` — a proper subset of keys, no repetition.
- **`jsonb`, not `json`, for a column you may want to query or aggregate.**
- **Two kinds of "validation" for two kinds of failure.** A genuine user-facing rule stays an
  `ActiveRecord` validation so it can't be bypassed and maps to an HTTP status (quota → a hard
  create validation → 402; a bad input-type column value → validation → 400). A *mis-implementation*
  (a wrong severity/icon our own code passed) is **exception-based** (`ArgumentError`) — "any
  validation should be Exception based, as it indicates miss-implementation." Don't conflate them.
- **HTTP status must match reality.** An inconclusive-but-processed result is `200`, not
  `422` — "The entity was processed! …this status is reserved to when the system can't process
  anything." Reserve `4xx` for actual rejection.
- **Semantic creation through the association**: `Current.user.sentinel_checks.new(...)` over
  `SentinelCheck.new(user: Current.user, ...)` — "start from the user itself. It adds a hidden
  layer of guarantee" (the FK is set and scoped by the association).
- **Class methods before instance methods** in a model's layout.
- **Don't extract a one-line render into its own method** — inline a simple single-use render at
  its call site.
- **Don't duplicate a method that already exists — relocate the source of truth and delegate.**
  Feature entitlement already lived in a `Current` helper *and* got re-added to `Customer`; he
  wanted one home. Resolution: keep the (correctly scoped) logic on `Customer` and have `Current`
  `delegate` to it, so the old caller still reaches it. "If something already exists and it's
  accessible, use it. If it's not accessible, change where it lives while the old place is [still]
  able to easily access it." (Same one-source-of-truth spine as elsewhere in this document.)
- **Comments: still a hard no.** He left a bare "No inline comments" with an empty-of-comment
  `suggestion` block — same absolute stance seen on the test harness, now confirmed on app code
  too.

## Error handling for external calls (a scam-text classifier feature)

A fourth signal (a scam-text classifier) reached merge-readiness through the same
model-centric shape as above, and pinned down three rules for how a signal talks to an
external vendor:

- **Wrap a vendor call in `Rails.error.handle(SpecificError)`, not a bare `rescue`.** "It's
  better to use so we get at least a log and the code gets cleaner." A `rescue Faraday::Error …
  nil` swallows the failure silently; `Rails.error.handle(Faraday::Error) { … }` reports it to
  the error reporter (so it's logged) and still returns nil on failure. He asked to apply it "on
  the other signals that are API based" too — treat it as the go-forward convention for every
  vendor-calling signal/caller.
- **Don't defensively type-check a vendor response — "better to get an exception than fail
  silently."** He had a `data.is_a?(Hash)` guard deleted: a malformed `2xx` body should raise and
  surface, not be quietly turned into "no result." Keep only the presence/nil guard needed for
  the *designed* no-op (e.g. dormant-without-credential, where the helper legitimately returns
  nil). This refines the "guard in the caller" rule above — the guard is for the
  never-crash-worthy cases (dormancy, a handled transport error), not for masking bad data.
  (Practical note: for the handler to actually catch an HTTP failure, that failure has to *be* an
  exception — a Faraday client that returns the raw body on a `5xx` needs `f.response :raise_error`
  so the error reaches `Rails.error.handle`.)
- **Keep the orchestrating method's surface minimal.** "Reduced the surface the `evaluate_query`
  method should be aware of." Push the fetch + branching into the helper — `rating(payload)` owns
  the `classify` call — so the entry method (`evaluate_query`) knows only `input_type` and the
  finding it writes, not the vendor plumbing.

## Testing (introducing the test suite)

A first automated suite landed and made his testing taste concrete on this codebase.
Themes:

- **RSpec, not Minitest.** "It's not common to use minitest or rails default testing. It's
  much much better to use RSPEC, as devs are more familiar to it." Use `rspec-rails`, specs
  under `spec/`, `bundle exec rspec` as the gate.
- **Test behavior, never static config or constants.** "We never test configurations… There
  is no value in having a test that checks just what we have set to be the value of something.
  It's things that we would have to maintain and change twice every time." Drop specs that
  restate a value we set; write a spec that exercises real logic instead.
- **Don't test factories.** "Remove this file, we don't test factories." A factory smoke spec
  (asserting `build(:x)` is valid) has no value to him — delete it. A broken factory surfaces
  in the specs that use it.
- **Lean on FactoryBot traits for the User hierarchy** (`:super_admin`, `:tenant_admin`,
  `:customer`) so specs read as intent; `faker` for non-identifying values, `sequence` for
  anything unique. DatabaseCleaner for isolation (transactional fixtures off). Wire WebMock
  in `rails_helper` (`disable_net_connect!(allow_localhost: true)`) and only add gems the
  suite actually uses — he pushed back on WebMock sitting unused ("setting up… Webmock, but
  not using webmock?").
- **The two tests he considers crucial for auth work:** admin-portal sign-in (Devise session)
  and API sign-in (JWT). When touching auth, cover both the happy path and the rejections.

## Things Carlos wants (noted once each — real but single-instance)

Treat these as his taste; each was raised a single time, so apply them but don't assume
they're hard laws:

- `frozen_string_literal: true` magic comment on files.
- `blank?` preferred over `nil?`.
- `Array.wrap(...)` preferred over `Array(...)` — more explicit, and `Array()` "might get
  deprecated from Ruby at some point."
- `slice` vs `permit`: knows `permit` logs unpermitted params as a side effect; fine to use
  either, just be deliberate.
- Symbols (not strings) for icon names in nav helpers.
- Name it `slug`, not `identifier` — "`identifier` causes confusion with `id`."
- Heredocs (`<<~STYLE.squish`) instead of `\`-concatenated multi-line strings, seen more
  than once (including a case where he rewrote a `\`-joined flash message as
  `<<~MESSAGE.squish`) — treat as a firm preference.
- No hardcoded record IDs in tests/previews — "Setting a specific ID will break on other
  machines. Either use a random first user, or just initialize a static one."
- Reuse `resource` in Devise views rather than re-fetching the user.
- Vendored JS belongs in `vendor/javascript` — the path importmap-rails 2.x pins to and
  registers on the propshaft load path (`pin 'x'` → `vendor/javascript/x.js`). (An older note
  of his said `app/vendor/javascript`, but that predates the importmap-rails 2.x + propshaft
  setup now in use; `app/vendor/javascript` is *not* on the asset load path, so a pin placed
  there would fail to resolve.)
- For mailer previews: store JSON fixtures and a single param-driven method instead of
  repeating `JSON.parse` blocks.
- Toggle `disabled` state rather than juggling input `name` attributes.
- Don't import from `*default` in `database.yml` — match established per-environment config
  instead of inheriting a shared default block.

---

## Ruby & Rails idioms he writes and asks for (broader history — treat as priors)

**Scope of evidence (apply with care):** Everything *above* is grounded in reviews on this
codebase. The items in *this* section are drawn from a broader analysis of the same
reviewer's review and authoring history, filtered down to what is genuinely idiomatic for
*this* stack (Rails / ActiveAdmin / Solid Queue). Anything tied to a framework, billing
provider, or test setup this codebase doesn't use was dropped. Treat these as **strong
priors, not directly observed facts** — confirm each against his reviews as they
accumulate. **Where any of this conflicts with the reviews-grounded items above, the
grounded item wins** (e.g. the grounded convention is `# frozen_string_literal: true` — keep
it).

**Control flow & methods**

- **Guard clauses / early `return` (or `raise`) at the top** keep the happy path flat — the
  constructive form of his "no haduken code" dislike.
- **Extract multi-step logic into small, intention-named private methods**, all under one
  `private` at the bottom; no section/banner comments inside the private block.
- **When `if`/`else` branches share most of their body, abstract the common part** and let
  the return carry only the conditional.
- **Hoist repeated literals (sizes, magic numbers, shared settings) into constants**, don't
  repeat them inline.

**Lookups, errors, idioms**

- **Memoize with `@var ||= …`; when the value can legitimately be nil/false, guard with
  `defined?(@var)`** instead — `||=` re-runs on a falsy result and defeats the memo.
- **Rescue specific exception classes by name** — never a bare `rescue` or generic
  `StandardError` that swallows unrelated bugs.
- **Define domain errors as `Name = Class.new(StandardError)`** scoped to the raising class
  and raise them with a message.
- **Reach for idiomatic finders/coalescers** — `find_or_initialize_by`, `includes`, `.pick`,
  `.presence` — over hand-rolled equivalents.
- **Forward methods with `delegate … to:` (`allow_nil: true` on optional associations)**
  instead of hand-written accessors; use `&.` (with `||` fallbacks) for maybe-nil receiver
  chains, not for boolean logic.
- **Prefer declarative Enumerable methods** (`filter_map`, `max_by`, `sum`) over manual
  loops or `map { … }.compact`.

**Models, concerns, jobs**

- **Keep models thin: push query/business logic into intention-named model methods** (incl.
  `to_<thing>` builders) rather than scattering it across callers — the constructive side of
  his "this should be in the model."
- **Extract shared model behavior into focused concerns** via `extend ActiveSupport::Concern`
  with the macros inside `included do`.
- **Move side-effecting work into single-purpose jobs via `perform_later`** — `retry_on`
  transient failures (bounded `attempts:`/`wait:`), `discard_on` permanent ones. Matches an
  `ApplicationJob` retry/discard + `limits_concurrency` posture.

**Database & performance**

- **Don't load a whole record just to read or update an id** — select the column or use a
  subquery (`where(...).select(:user_id)`).
- **Use `update_all` for mechanical bulk column updates** instead of loading and saving rows
  one at a time.
- **Avoid N+1: bulk-load `where(id: ids).find_each`, eager-load reads with `includes`** —
  never per-id `find_by` in a loop.
- **Define reusable query logic as composable scopes** (`scope :name, -> { … }`); build
  conditions with chainable AR/Arel (`where.not`, `.or`), not raw SQL strings.
- **Drop a column once another makes it derivable or redundant.**

**Process**

- **One named class per file.**
- **Attach screenshots for UI changes**; for new view components, add example states (empty,
  dark background) — he reviews the rendered result, not just the diff.

---

## Tone & process notes

- **Blunt and direct.** Exclamation points when he disagrees ("This should be in the
  model.", "Don't do this!"). Not hostile, but unfiltered.
- **Occasional emoji** to soften ("haduken code 😔").
- **Asks intent questions** when a PR confuses him instead of assuming ("What is the actual
  request here?", "Why we need this seed?"). Answer these proactively in the PR body.
- **Reviews thoroughly with concrete fixes** — he writes full ````suggestion` blocks with
  the exact code he wants, not vague hints. Apply them as written.
- **Distinguishes blockers from nits.** "Most comments are suggestions, except this
  one: [link]"; on approval: "Final things, after that, you can merge." If he says
  something is a suggestion, it's optional; if he flags one item specifically, that one is
  the blocker.
- **Will threaten to take over a PR** he considers fundamentally wrong: "Either I recreate
  it on another branch or I change this one." Avoid this by not over-building.

---

## Pre-review checklist (self-apply before requesting Carlos)

1. **Scope:** Does every file/line in this diff serve the stated task? Remove anything
   "extra," speculative, or future-proofing he didn't ask for.
2. **Dead/unused code:** No jobs, models, mailers, methods, or files that nothing calls.
   Delete, don't keep "just in case."
3. **No duplication / no re-implementing framework or his existing config** (check
   `parent_mailer`, existing helpers, prior work before adding new code).
4. **Layering:** Validations and domain logic in models; nothing in admin/controllers that
   belongs in a model or helper; config only in files meant for it. For an "input → stored
   result" operation, centralize the whole thing on the AR model (steps as `include`d concerns
   super-chaining one entry method; idempotent helpers in `class << self`) — no service, job,
   or DTO classes (see *Model-centric operations* above).
5. **No generated schema files** committed (`db/cache_schema.rb`, `db/queue_schema.rb`).
6. **Validations stay correct** — narrow them, never silently skip format/case rules.
7. **Auth/security untouched or strengthened** — never base authorization solely on an
   incoming param; unset secret ⇒ unauthorized.
8. **Naming:** `slug` not `identifier`; symbols for icons; clear over clever. Name a model
   after what its row actually is.
9. **Data modeling:** every `<thing>_id` is a real FK (opaque external ids are `external_id`);
   reuse an existing domain model instead of a loose identifier; don't store an association
   (`user_id`/`tenant_id`) you can infer through another FK.
10. **No nested "haduken" code** — flatten/extract; consider a Stimulus controller for view JS.
11. **Rails idioms:** `frozen_string_literal`, `blank?`, `Array.wrap`, heredocs over `\` —
    plus the *Ruby & Rails idioms* section above (memoize with `@var ||=`, rescue named
    exceptions, set-based DB over loading records, thin models / concerns).
12. **No machine-specific assumptions** (hardcoded IDs, local-only paths) in tests/previews.
13. **PR description states the *why*** — the request being solved — so he doesn't have to ask.
14. **Comments are minimal** — no inline comment that just restates the code; keep only the
    intentful `# why` notes that a later reader would actually need. He strips *all* of them
    on specs, so add none there.
15. **Tests earn their place** — RSpec behavior specs that exercise real logic; no specs over
    static config/constants, no factory smoke specs. Only add test gems the suite uses.
16. **Hash/enum hygiene:** symbol keys, let Rails cast on write (`jsonb` for queryable
    columns); mandatory args positional and only the variadic tail keyworded; `<<` to append to a
    collection attribute; scope I18n lookups instead of repeating a key prefix; class methods
    before instance methods; create through the association (`user.things.new`); user-facing rules
    are AR validations (mapped to HTTP status), mis-implementation is an `ArgumentError`; a
    processed-but-inconclusive result is `200`, not `422`.
17. **External calls:** vendor/API calls go through `Rails.error.handle(SpecificError)`
    (reports + logs, returns nil), not a bare `rescue`; don't type-check the response body
    (`is_a?(Hash)`) — let a malformed body raise; keep only the nil-guard for the designed no-op
    (dormancy). Push the vendor fetch into the helper so the entry method's surface stays minimal.
