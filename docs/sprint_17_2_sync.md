# Sprint 17.2 — Automatic shopping sync

## Scope

Shopping dates, named lists, items, quantity/price inputs, notes, purchase state,
and ordering now sync through Firebase Authentication + Cloud Firestore.
The existing shopping models and pricing calculations remain in use.
Theme preferences, ShopTrack profile fields/photos and dismissed suggestions are
local-only in this increment. Apple sign-in and iOS native configuration are not
implemented by this change. No scheduled/background worker is installed:
sync runs while the app is open and reconnects on resume.

Profile → Cloud Sync shows device-only, saving, saved or needs-attention status,
with conflict review and a link to advanced file/Google Drive backups. Existing
Drive backup files are not automatically imported or overwritten by sync.

## Data ownership and migration

- Local envelopes: `shoptrack_sync_v1_<Firebase UID>`, plus a guest envelope.
  Sessions, upload queue and conflicts are saved together through serialized
  writes. SharedPreferences remains the local storage technology; this is not a
  guarantee against OS-level storage failure or device loss before upload.
- Existing `shopping_sessions` / `shopping_items` keys are retained as a migration
  recovery source, not actively updated after migration.
- The first Firebase account claims the device's pre-sync guest history once.
  A different account gets its own local store and cloud history, never a copy
  of the previous account. Invalid/missing known-account storage fails visibly
  rather than silently replacing records with an empty history.
- Signing out pauses cloud access but intentionally keeps the last account's
  local shopping data accessible. Offline edits resume with that same account.
  This is account isolation for sync, not a local-device privacy lock.
- Repositories capture their account store and editor generation. A delayed
  editor from an earlier account cannot write into the new account.

## Cloud layout and merge rules

`users/<Firebase UID>/sessions/<YYYY-MM-DD>`:

- `schema: 1`, `revision`, `updatedAt`, `deleted`, `session`
- One document per shopping date; `session` contains the existing model JSON.
- Deleted dates use tombstones so offline clients cannot silently resurrect them.

`users/<Firebase UID>/syncOperations/<operation UUID>`:

- Retry receipt with date, conflict fields and completion timestamp.
- Conflicting proposals are retained in receipts; the originating device also
  retains the complete baseline/local/cloud comparison for review.
- Receipts/tombstones are not automatically pruned yet: arbitrary pruning would
  make retries from old offline installations unsafe. Monitor their growth.

Transactions read the current session and operation receipt, then perform a
three-way merge against the editor's baseline. Independent changes merge;
different edits to the same field require review. All financial input fields
are merged as one group. List deletion versus new items also requires review.
Future-to-Today transfers commit both dates in one transaction; either both
succeed or both require review. Transfer conflict choices apply to both dates.
Local acknowledgement of a transfer is also one envelope write.

Server revisions prevent a delayed acknowledgement from overwriting newer
snapshots. Cache/pending-write snapshots are not treated as proof of cloud save.
Open item/list editors retain their baseline while remote changes arrive.

The existing UID-owner `firestore.rules` covers sessions and receipts. This turn
did not modify or publish production rules, upload production records, change
the Spark plan, or enable billable services. The emulator checks verify owner
isolation, not a comprehensive security audit. App Check and field/schema rules
hardening should be reviewed before public launch.

## Limits and recovery

- A date's result or queued operation exceeding 700 KiB pauses with a visible
  error; the original local data remains. This deliberately stays below the
  Firestore document limit. Large-history scaling needs additional design.
- The initial listener reads the account's date collection; transactions and
  receipts also consume Firestore quota. Check console usage during the pilot.
- Conflict review is currently originating-device only, not a shared inbox.
  Resolved versions and the pre-restore snapshot are retained locally for
  technical recovery; normal backup exports contain the visible shopping data,
  not these internal archives.
- Restore is an explicit replacement of the active account's local history;
  those changes also sync to its other devices. The confirmation explains this.
  Export before restoring. Multi-date backup replacement syncs date-by-date,
  unlike the atomic two-date item-transfer action.
- Sync is not a versioned disaster-recovery backup. Keep file/Drive exports,
  especially before testing migration, restores or simultaneous edits.

## Verification and phone acceptance checklist

Automated coverage: model merges, pricing conflicts, offline restart, stale
editors, account switching, delayed acknowledgements, cache status, transfer
atomicity, receipt retries, malformed storage and narrow-screen conflict UI.
Production adapter transaction tests use explicit test doubles. Security rules
are separately tested using Google's local Firestore emulator.

Commands:

```powershell
flutter test
dart analyze lib test/shopping_sync_test.dart test/firestore_sync_remote_test.dart
flutter build apk --debug
```

To run the rule checks, start an official Firestore emulator with project
`demo-shoptrack-sync`, `firestore.rules`, host `127.0.0.1`, port `8787`, then run
`node tool/test_firestore_rules.mjs`. The script has a fixed local-only endpoint
and uses emulator-only identities, never production credentials.

Live acceptance still required (do not uninstall/clear the original app):

1. Export a file backup before the first run of this build.
2. Run on the existing Android phone; sign in if needed. Profile → Cloud Sync
   should reach All Changes Saved. Verify real session documents under your
   Firebase UID in Firestore, not merely an Authentication user entry.
3. Add a disposable test item; toggle purchase and edit its price. Confirm the
   cloud document changes. Check existing history totals against the backup.
4. Go offline, make an edit, close/reopen the app, then reconnect. The edit must
   remain locally and eventually reach the cloud without manual restore.
5. Sign in to the same account on a second device/emulator; verify lists, names,
   quantities, totals and history. Test two independent edits and one intentional
   same-field conflict. Review the conflict on the originating device.
6. Move a future test item to Today; confirm it appears only once on both devices.
7. Sign out; verify local data stays. A second test account must not inherit it.
   Return to the first account and verify pending edits/history return.

Android build success does not verify live two-device behavior or an iOS build.
No commit was created by this implementation task.
