# ShopTrack — Codex Cloud and Local Development Handover

Last reviewed against the local checkout: **19 September 2026**.

This is the canonical continuity document for moving ShopTrack work between
Codex Cloud and local Codex tasks. It records the product intent, implemented
behavior, architectural constraints, current worktree state, approved design
decisions, pending work, verification expectations, and release blockers.

This document does **not** replace `AGENTS.md`. A new agent must read, in order:

1. The latest explicit user request.
2. `AGENTS.md`.
3. This handover.
4. `docs/sprint_17_2_sync.md` before any persistence, account, restore, or sync
   change.
5. The current source, tests, branch, and working tree before editing.

If documentation and source disagree, inspect and test the current checkout.
Do not guess which one is newer.

## 1. First Message for a New Codex Cloud Task

The user can paste this into a new Cloud task:

```text
Continue development of the ShopTrack Flutter application. Before changing
anything, read AGENTS.md, docs/CODEX_CLOUD_HANDOFF.md, and, for any data or
account work, docs/sprint_17_2_sync.md. Inspect the current branch, git status,
recent commits, and relevant tests. Preserve all existing uncommitted work and
do not broaden the requested scope. Clearly distinguish implemented behavior
from planned behavior. Never access production Firestore, change billing,
deploy, commit, push, or publish unless I explicitly request it. For visual
work, verify narrow portrait and short landscape layouts and state what still
needs checking on a real device.
```

The new task should begin with read-only inspection and report:

- current branch and latest commit;
- dirty/untracked files;
- the exact requested scope;
- relevant architecture and tests;
- any mismatch between this document and the checkout.

## 2. Source-Control Reality: Cloud Does Not Inherit This Chat

Codex Cloud does not automatically receive this conversation, hidden model
context, or uncommitted files on the developer's PC. Repository documents and
pushed Git state are the durable handover.

Before moving work from local to Cloud:

1. Review `git status` and `git diff` locally.
2. Run proportionate verification.
3. Commit the intended changes.
4. Push the branch that the Cloud task will use.
5. Tell the Cloud task the branch/ref and requested outcome.

Before bringing Cloud work back locally:

1. Make sure local edits are committed or safely separated.
2. Fetch the remote changes.
3. Review the Cloud diff before merging or cherry-picking.
4. Re-run local analysis/tests.
5. Perform device checks for appearance, animation, authentication, and live
   Firebase behavior.

Avoid simultaneous local and Cloud edits to the same files. Use one owner per
task or separate branches. Never solve divergence with `git reset --hard` or by
discarding unknown changes.

## 3. Current Checkout Snapshot

At the time of this handover:

- Local branch: `master`.
- Current local milestone: **Sprint 18.4.2 — list sharing and responsive UI
  refinements**.
- Its preceding revision is `1ae0cd8` —
  `Sprint 18.4.1: Refine Profile, shopping actions, list presentation, and sync resume behavior`.
- The branch containing Sprint 18.4.2 must be pushed before a Cloud task can
  reliably continue from it.

Sprint 18.4.2 work includes:

- restoring the centered Profile identity while keeping its vertical density
  compact;
- ordering Upcoming before Today in History;
- consistent theme-aware dialogs, menus, action-sheet headers, spacing, and
  compact empty states;
- concise move/delete confirmations and a create-list path when Move has no
  destination;
- plain-text copy/share for Today and any other shopping date;
- honest retry states for initial list, History, and sync-startup failures;
- responsive, text-scale, selection, sharing, and theme regression coverage.

Latest verification performed for this work:

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

Profile and Cloud Sync previews are rendered locally for inspection. Automated
checks cover completion accents across all themes, compact layouts, confirmation,
Move Undo and healthy/offline resume behavior. Physical-phone screenshot and
reconnect acceptance still require the device checklist below.

19 September Sprint 18.4.2 verification: analysis clean; full suite 272 passed,
7 optional visual tests skipped. Compact portrait and short landscape share and
Move sheets passed at 1.3x text scale. Native share destinations, the signed-in
Profile card, and subjective spacing still require physical-device acceptance.

## 4. Product Purpose and Design Principle

ShopTrack is a fast, comfortable, offline-first shopping-list and purchase-
history application. It should help a person prepare a shopping trip, track
prices and purchased items, organize separate lists, and recover history with
as little friction as possible.

The app is intentionally:

- simple enough to use immediately;
- item-focused rather than decoration-focused;
- usable offline;
- synchronized safely when online;
- free of advertisements;
- responsive across small and large phones;
- visually warm and distinctive without becoming a crowded productivity suite.

The central product question for every feature is: **does this help the user
finish or understand their shopping more quickly and safely?** If not, it is
probably optional or unnecessary.

## 5. Implemented User Experience

### Lists and shopping sessions

Implemented behavior includes:

- date-based shopping sessions for past, today, and future;
- optional named lists within a date;
- creating, renaming, deleting, and horizontally switching named lists;
- adding and editing items with quantity, unit, notes, and pricing;
- total-price and unit-price calculations;
- purchase toggling and purchased/pending sections;
- explicit drag-handle reordering;
- long-press multi-selection;
- moving selected items between named lists without losing item IDs/details;
- multi-item deletion with Undo;
- Future-to-Today transfer behavior;
- horizontally scrolling frequently/often-bought suggestions;
- theme-aware receipts and purchased totals;
- responsive hero scenery on Lists and past/future record screens.

Existing interaction contracts must be preserved:

- normal tile tap edits an item;
- the purchase control toggles completion;
- only the drag handle reorders;
- long-press enters selection mode;
- successful UI feedback follows a successful local save.

### History and search

Implemented behavior includes:

- grouped past, today, and planned/future records;
- compact record cards with reusable calendar date badges;
- month abbreviations inside the calendar badge;
- full weekday names where surrounding context already supplies month/year;
- History Search with query, purchase-state filters, and date-range filtering;
- frequently purchased suggestions;
- a custom responsive date-range picker;
- correct previous-complete-days presets, including seven days excluding today;
- connected endpoint highlighting;
- keyboard-aware manual date entry;
- Clear that resets without closing the range picker;
- shared Lists/History/Profile navigation on History Search.

### Profile, account, sync, and backups

Implemented behavior includes:

- a Profile tab with a signed-in account card;
- local ShopTrack display-name and profile-photo editing;
- the connected Google email displayed read-only;
- sign-out confirmation that explains local-data behavior;
- automatic Firestore sync status and conflict review;
- local JSON export/restore;
- Google Drive App Data backup/restore as a separate advanced system;
- About and app-version UI;
- a dedicated Appearance screen, plus currency and language placeholder
  dialogs.

Important distinction: the ShopTrack display name/photo is local app profile
data. It does not edit the user's Google account.

Currency and language are currently preference placeholders, not complete
internationalization or multi-currency systems.

## 6. Theme System and Approved Visual Identities

Themes are defined in `lib/core/theme/theme_presets.dart` and exposed through
`ShopTrackThemeTokens`. Avoid screen-specific hard-coded colors.

The public names, stable internal enum values, and scenery assets are:

| Public name | Internal preset | Scenery asset | Status |
| --- | --- | --- | --- |
| Golden Summer | `LightPreset.summer` | `theme_light_golden_summer.webp` | Complete identity |
| Blooming Spring | `LightPreset.spring` | `theme_light_blooming_spring.webp` | Complete identity; special mixed navigation and pink calendars |
| Tranquil Ocean | `LightPreset.ocean` | `theme_light_tranquil_ocean.webp` | Complete identity |
| Ember Autumn | `LightPreset.autumn` | `theme_light_ember_autumn.webp` | Complete identity |
| Silent Midnight | `DarkPreset.midnight` | `theme_dark_silent_midnight.webp` | Complete identity |
| Ethereal Aurora | `DarkPreset.aurora` | `theme_dark_ethereal_aurora.webp` | Complete identity; special mixed navigation |
| Bleeding Moonlight | `DarkPreset.moonlit` | `theme_dark_bleeding_moonlight.webp` | Complete identity |
| Ancient Forest | `DarkPreset.deepForest` | `theme_dark_ancient_forest.webp` | Complete identity |

Do not rename the enum values. They are persisted in user settings. Only the
display names and asset filenames changed.

Theme rules:

- every identity covers background, surfaces, item cards, borders, text,
  statuses, dialogs, sheets, fields, receipts, calendars, and navigation;
- important item tiles must remain easier to notice than atmospheric scenery;
- dark themes keep approximately 96% of the central background quiet, with
  only subtle edge differentiation;
- dark list-overflow shadows are genuinely black, not white fog;
- large dark surfaces should not become visibly washed out or blue;
- light themes may use more visible but still comfortable atmospheric blends;
- scenery reaches the top/left/right edges and must not have an artificial
  bottom fade line;
- header composition keeps the left area readable for dates/back controls and
  meaningful scenery detail toward the right;
- selected navigation icons transition from outline to filled, with subtle
  motion and reduced-motion support;
- only Ethereal Aurora and Blooming Spring currently use mixed-color selected
  navigation icons;
- Blooming Spring uses its blossom accent for calendar UI.

Ancient Forest is the charcoal-evergreen, moss, dark-earth, restrained-amber
identity. Keep it grounded and distinct from the luminous teal/violet Ethereal
Aurora palette.

## 7. Appearance UI

The Profile tab opens one dedicated Appearance destination with three groups:

1. Choose Theme: System, Light, Dark.
2. Light Theme: Blooming Spring, Ember Autumn, Golden Summer, Tranquil Ocean.
3. Dark Theme: Ancient Forest, Bleeding Moonlight, Ethereal Aurora,
   Silent Midnight.

Each preset has a compact scenery preview and clear selected state. Light and
Dark choices are alphabetized, and the screen is scrollable on narrow/short
layouts and with enlarged text.

Each preset has a compact scenery preview and clear selected state. The lists
are alphabetical and the page remains scrollable on compact layouts. Preserve
this shared destination instead of restoring separate selection dialogs.

## 8. Architecture and Data Ownership

### App composition

- `lib/main.dart` initializes Flutter/Firebase for the production entry path.
- `lib/app.dart` owns app services, lifecycle, settings, theme selection, and
  root navigation.
- Widget tests may instantiate `ShopTrackApp` without Firebase initialization;
  preserve that supported path.

### Persisted models

- `ShoppingSession` owns one date, items, and named list groups.
- `ShoppingItem` owns stable ID, name, notes, purchase state, quantity, pricing
  mode, shopping unit, price basis, position, and optional list ID.
- `ShoppingListGroup` owns stable ID, name, and position.
- Existing JSON fields are a compatibility contract.

Any new persisted field must include:

- tolerant reading of old JSON;
- round-trip tests;
- restart behavior;
- failed-write behavior;
- cloud merge behavior;
- deletion/tombstone behavior where relevant.

### Offline-first local storage

`SyncStore` is the persisted source for visible sessions, pending operations,
and conflicts while automatic sync is active. Writes are serialized.

`LocalShoppingRepository.activeStore` is account-scoped. Repository/editor
instances retain account generation so an old editor cannot write into a newly
selected account.

Signing out pauses cloud access but leaves that account's local data on the
device intentionally. This is offline continuity, not a device privacy lock.

### Cloud synchronization

Firestore ownership is rooted at the Firebase UID:

```text
users/<UID>/sessions/<YYYY-MM-DD>
users/<UID>/syncOperations/<operation UUID>
```

Never use email, display name, Google provider ID, or a remembered local account
as the ownership boundary.

Sync uses queued idempotent operations, operation receipts, tombstones,
revisions, and three-way merge. Pricing fields merge as one atomic group;
list ID and position merge as another. Same-field concurrent edits become
reviewable conflicts rather than silent last-write-wins.

Future-to-Today transfer spans two dates and must remain atomic. Do not rewrite
sync schemas, merge rules, restore semantics, batching, or account switching
without first reading `docs/sprint_17_2_sync.md` and expanding tests.

### Backup is not sync

- Firestore sync: automatic, current state, offline queue, conflict handling.
- Local JSON backup: explicit export/restore.
- Google Drive App Data backup: explicit advanced backup/restore.

One system's success must not be presented as proof that another succeeded.

## 9. Firebase and Security State

Current confirmed repository state:

- Android Firebase config exists at `android/app/google-services.json`.
- Google authentication is connected to Firebase Authentication on Android.
- Firestore Standard/Native mode is in use, with the project previously set up
  in `asia-southeast1`.
- Source-controlled rules restrict `users/<UID>` to that authenticated UID.
- The Spark/no-cost plan was used during setup.
- App Check is not yet configured for public release.
- iOS `GoogleService-Info.plist` is absent.
- Apple sign-in is not implemented.

Do not print Firebase configuration contents, tokens, account secrets, backup
payloads, or user data. Do not use production Firestore for automated tests.
Rules testing is local-only through project `demo-shoptrack-sync` at
`127.0.0.1:8787`.

The existing owner-only rules are a strong baseline, not a complete public-
release security audit. App Check, schema/field validation, abuse controls,
quota monitoring, privacy documentation, and account deletion requirements
still need deliberate release review.

## 10. Convenience and Planned Features

### Share a shopping list as text — implemented

Implemented behavior:

- share Today or any selected date as plain text;
- support the native share sheet for WhatsApp, Messenger, X, and compatible
  destinations;
- offer Copy Text for manual pasting;
- include list names, pending/purchased state, quantity, and optional prices in
  a readable format;
- do not claim Instagram supports arbitrary plain-text posts; platform behavior
  must be tested through the native share sheet.

The active Lists screen exposes Copy/Share beside the list switcher. History
record menus expose the same flow for any date. One readable plain-text export
contains all non-empty named lists, pending/purchased sections, quantities,
notes, prices, and pending/purchased totals. The native share destination list
depends on apps installed on the device; Instagram and other platforms may not
accept arbitrary plain text.

### Multi-currency shopping

Approved product direction:

- support a broad currency catalogue;
- allow items inside one session to use different currencies;
- total each currency separately, with no automatic conversion by default;
- show currency section headings only when a session contains multiple
  currencies;
- keep today's/purchased totals grouped by currency;
- in History cards, separate compact currency totals with vertical dividers and
  wrap when space is insufficient.

Current reality: `AppSettings.currency` is one global string and
`ShoppingItem` has no currency field. Multi-currency is a model, persistence,
pricing, backup, search, history, sync, merge, and migration change—not a small
UI enhancement. Design the schema and compatibility tests before editing UI.

### Receipt-photo import / OCR

Approved concept:

- photograph or choose a receipt;
- recognize candidate item names, quantities, prices, currency, merchant, and
  purchase date where possible;
- present an editable review screen;
- save only user-confirmed rows as purchased items;
- retain the original shopping data if OCR fails.

No receipt OCR service is currently implemented. Never silently insert OCR
results: receipts are noisy, totals may include tax/discounts, and mistaken
financial data must be reviewable.

### Profile and community features

Discussed but not implemented:

- Rate ShopTrack, opening the correct store listing;
- Help & Feedback;
- an optional donation/support presentation;
- account deletion;
- changing the authentication email while preserving owned data;
- Apple sign-in.

Donation/payment design must be checked against current Play/App Store policies
and the selected payment provider before implementation. Do not collect or
expose donor identity beyond explicit consent and a valid privacy purpose.

Changing email or linking identity providers must preserve the Firebase UID or
use an explicit, tested ownership migration. Never move user documents merely
because two email strings appear related.

## 11. Recommended Work Order

The safest path to a tester-ready build is:

### Phase A — finish the established UI system

1. Keep the all-eight-themes physical-device acceptance pass green.
2. Refine Profile subpages and text hierarchy without changing account/data
   semantics.

### Phase B — essential convenience implemented; device acceptance remains

1. Keep plain-text list copying/sharing covered while list and currency models
   evolve.
2. Continue recording and correcting specific empty/error/offline gaps found on
   real devices.
3. Complete the physical accessibility, native-share, keyboard, and device
   acceptance checklist before tester distribution.

### Phase C — release engineering and tester distribution

1. Choose the permanent Android application ID.
2. Register the final ID in Firebase and update configuration/SHA fingerprints.
3. Create secure release signing; never commit private keys or passwords.
4. Replace/verify launcher icons, splash assets, app name, version, and build
   number.
5. Add privacy policy, store data-safety disclosures, support contact, and
   account-deletion flow if required by the release model.
6. Configure App Check and monitor Firestore quotas during the pilot.
7. Build a signed internal-testing artifact.
8. Run real-device, offline, reinstall/upgrade, second-device, and restore tests.

### Phase D — larger post-pilot features

1. Multi-currency architecture and migration.
2. Receipt OCR with mandatory confirmation.
3. Rating, feedback, and optional donation flow.
4. iOS Firebase setup and Apple sign-in.
5. Later evaluate Huawei/AppGallery and mainland-China infrastructure as a
   separate platform project; do not assume Google/Firebase behavior there.

## 12. Release Blockers Confirmed in Source

The app must not be called store-ready yet:

- Android package/namespace is still `com.ishtiak.example.shoptrack`.
- Android release builds still use debug signing.
- `pubspec.yaml` remains `1.0.0+1` and still carries the default project
  description.
- iOS Firebase configuration is absent.
- Apple sign-in is absent.
- Ancient Forest's full identity is implemented; continue device acceptance
  after material theme changes.
- full current regression testing and physical-device theme acceptance remain
  necessary after the uncommitted theme changes.
- privacy/store policy work has not been documented as complete.

Changing the Android application ID affects Firebase registration, OAuth client
configuration, SHA fingerprints, installed-package continuity, and store
identity. Treat it as a dedicated release task.

## 13. Verification Commands

Use the smallest relevant tests while iterating, then complete checks before a
handover or commit:

```powershell
flutter pub get
dart format <touched-dart-files>
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug
```

`flutter pub get` is needed when dependencies or asset declarations change.
Do not hard-code the local Windows Flutter path into repository scripts.

Important targeted tests:

```powershell
flutter test test/sprint_18_test.dart --no-pub
flutter test test/item_selection_test.dart --no-pub
flutter test test/shopping_sync_test.dart test/firestore_sync_remote_test.dart --no-pub
```

Firestore rules checks require the official local emulator, then:

```powershell
node tool/test_firestore_rules.mjs
```

Never point improvised tests at production.

## 14. Physical-Device Acceptance Checklist

Automation cannot prove subjective feel or live provider behavior. Before a
tester build, verify on at least one real Android phone and one emulator:

### Themes and layout

- all eight names appear alphabetically in their Light/Dark groups;
- every scenery loads after a full app restart;
- no thin seam appears below hero artwork;
- date text remains readable over every scenery;
- item cards are clearly distinguishable from page backgrounds;
- dark gradients remain quiet and shadows remain black;
- Blooming Spring calendars are blossom-pink;
- navigation icons outline/fill cleanly and respect reduced motion;
- 320x640-like portrait, short landscape, large display, and 1.3x text remain
  usable;
- keyboard does not hide editor or date-range actions.

### Shopping behavior

- add/edit/reorder/purchase/delete items;
- Undo deletion;
- long-press and select multiple items;
- move items between named lists;
- move Future items to Today without duplication;
- confirm prices/totals after restart.

### Sync and account behavior

- Google sign-in reaches Firebase Auth;
- Cloud Sync reaches All Changes Saved;
- offline edits survive restart and upload after reconnect;
- same account on a second device receives the history;
- intentional same-field conflict is reviewable;
- a second account never inherits the first account's data;
- sign-out keeps the original account's local history as documented;
- local and Drive backup/restore remain explicit and understandable.

## 15. Cloud/Local Task Handoff Template

Every substantial task should finish with this information:

```text
Outcome:
- What now works.

Files changed:
- Exact source/assets/docs.

Architecture/data impact:
- None, or explicit schema/sync implications.

Verification:
- Commands and exact pass/failure summary.

Still requires device/external verification:
- Concrete checklist.

Working tree:
- Branch, commit status, and unrelated changes preserved.

Next safe step:
- One clearly scoped continuation.
```

Do not say “done” if required device, Firebase, App Store, or subjective visual
checks have not occurred. State the boundary plainly.

## 16. Decision Log for Future Agents

- The tab is called **Profile**, not Account.
- Theme names use the approved dramatic two-word names listed above.
- Internal enum names remain stable for backward-compatible settings.
- WebP is preferred for substantial scenery; code-native vectors are preferred
  for theme-tinted icons.
- Scenery is decorative support; shopping items remain the visual priority.
- Cloud sync and backups remain separate concepts and screens.
- Account ownership is Firebase UID-based.
- Local success precedes UI success feedback.
- Conflicts are retained for review, not guessed away.
- The app remains ad-free; donation, if added, is optional and non-coercive.
- Multi-currency totals are grouped, not silently converted.
- Currency and Language remain planned work. The amount-to-quantity calculator
  proposal was dropped; do not implement it as part of these refinements.
- Sync receipt/tombstone retention needs a separate safe cleanup design before
  scaling; do not purge them as routine UI cleanup.
- OCR output requires user confirmation.
- Cloud agents must not infer permission to deploy, push, bill, or alter live
  Firebase resources.

This file should be updated when major feature status, release configuration,
platform support, cloud architecture, or the approved roadmap changes. It is a
handover, not a sprint diary.
