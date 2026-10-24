# Cleaning consumer API

Project Version: 0.2.0-dev.9

This is the Rooms side of the authorized offline Auto Clean integration. Rooms
uses vanilla physical building detection plus player-designated room geometry and owns cleaning permission. Vanilla room definitions are never read. It never searches
inventories, transfers supplies, moves characters or cleans the world.

`API.capabilities().cleaning == 1` advertises this consumer API. `cleaningScope='designatedRooms'` identifies the narrowed 0.2 scope contract; this intentionally replaces automatic native-room coverage. The
existing general API remains 1. `boundaries.cleaning=true` means cooperating
consumers can enforce cleaning permission; `vanillaFinalMutation=false` remains
explicit. Unrelated vanilla actions and other mods do not acquire these checks.
No global world-protection claim is made.

## Server API

| Method | Contract |
|---|---|
| `cleaningOptions()` | Effective, validated server sandbox values; on clients this is presentation only |
| `beginCleaningBuilding(player)` | Bind the current native physical building to the actual server actor; return `waiting` and a scope token |
| `readCleaningBuilding(player, scope)` | Advance a bounded designated-tile scan; return `waiting`, an explicit failure, or detached tile/options snapshots |
| `validateCleaningBuilding(player, scope)` | Reject a foreign, expired, disconnected, dead, disabled, changed-policy/settings or changed-building lease |
| `containsCleaningBuildingTile(player, scope, x, y, z)` | Current designated tile and physical building membership; does not itself grant cleaning permission |
| `canCleanBuildingTile(player, scope, x, y, z)` | Membership plus the current independent `clean` policy and native safehouse loot/interact checks; returns `allow`, `deny` or `unknown` |
| `canAccessAt(player, x, y, z, 'clean')` | Independent delegated clean permission at a loaded square |
| `endCleaningBuilding(player, scope)` | Release only that actor's exact scope |
| `cleaningTick()` | Expire disconnected/dead/old scopes; registered once by the Rooms module |

These are server APIs. Client geometry/permission claims are never accepted as
authority. A consumer must obtain `player` from the authenticated native command
event, retain exact resource references itself, and revalidate before each final
mutation. A clean grant never substitutes for supply `inspect`, `withdraw` or
`deposit` permission. Unknown or denied access must stop the affected operation.

The scope is the deduplicated union of loaded saved designated tiles whose
current square belongs to the selected vanilla physical building. Explicit saved
floors and holes are respected; other buildings and undesignated space are
excluded. A building without matching designations returns
`CleaningNoDesignatedRooms`; clients must prompt the user to designate rooms.
The editor starts empty and Detect Walls is an explicit preview only.

Each read examines at most 64 saved tiles within a 4 ms budget. The registry's
128-record/16384-total-tile caps bound admission. A matching designation with any
unloaded square fails `CleaningUnloaded` instead of returning a partial room.
Entirely unloaded/unmatched designations are outside this loaded scope. This is
not a promise of complete physical-building coverage. No chunk is created or
loaded. The sandbox tile limit applies to the unique resulting scope; exceeding
it fails instead of truncating. Delegated permission is checked for each action.

One cooperating cleaning scope may own a building at a time. The actor, native
building definition, Rooms registry revision and effective options are bound.
A policy or setting change invalidates the lease. The 30-minute lifetime,
bounded designated scan steps and connection check are implementation safety limits.
Cancellation/restart never replays a job. Scopes are ephemeral, not ModData.

## Sandbox settings

All settings use `B47ANCEDRooms`, stable identifiers and the existing Rooms
sandbox page. The server interprets them; clients only show the corresponding
action/status. Missing keys in existing saves use these defaults without writing
or resetting saved state.

| Identifier | Default | Supported values |
|---|---:|---|
| `CleanBuildingEnabled` | true | boolean; requires Rooms Enabled too |
| `CleaningBorrowSupplies` | true | boolean |
| `CleaningReturnSupplies` | true | boolean |
| `CleaningBleachML` | 10 | integer 1–100, step 1 |
| `CleaningBuildingTileLimit` | 4096 | integer 128–16384, step 1 |
| `CleaningTransferSeconds` | 1 | integer 1–10, step 1; base fetch/return duration before native actor modifiers |

The default recipe is **10 mL pure bleach first, then fill the 10 L bucket with
water**. A measured residual solution can be topped up in that order without
inventing a discard/refund. Chemical support remains the consumer's verified
native-fluid responsibility. These settings do not guarantee every fluid source
or cleaning effect is supported.
On a refill, only the additional bleach needed to reach the configured dose is
added; measured residual bleach is retained rather than dosed a second time.

Existing private policies with no `clean` entry default to the assigned owner,
as the other private actions do. Clean grants/rules are independent of storage
grants and editable through the existing policy/visitor menus. Native denial,
suspended parent associations and unknown state still fail closed. The independent clean rule was added in the historical 0.1.0-dev.1 checkpoint; the current 0.2 redesign changes scope geometry, not the save root or permission model. Current peers
must be updated together. Older parsers can reject a persisted `clean` rule;
downgrade after writing one is not claimed supported. No actual player save was
opened or migrated for this work.

UI/sandbox labels use the repository's existing identical-English fallback
dictionaries across available language folders. They are not claimed to be
human translations.

## Validation and activation

`python tests/run_tests.py` includes `test_cleaning.lua`, covering designated floors,
holes, empty buildings, no vanilla room reads, deduplicated overlaps, exclusion of undesignated/foreign-building tiles, partial unload and registry invalidation, actor binding, building claims, copied snapshots, independent clean rules,
native interact denial, validated defaults/bounds, settings revocation,
disconnect/expiry and client denial. Syntax, case, inventory, localization,
registry/network/migration and existing editor tests remain included.

Cleaning geometry/permission behavior is unchanged by the 0.2.0-dev.5 room
metadata/navigation/workflow additions; types and storage roles do not change clean priority; the full current offline suite, including cleaning, passes. Source
and artifact version checks pass following explicit publish authorization and
preservation of the old .2 package. WORKSHOP_WORKFLOW_PUBLICATION.md records current
distribution separately. WORKSHOP_KEEP_OPEN_PUBLICATION.md and
WORKSHOP_DESIGNATED_PUBLICATION.md retain historical evidence, not runtime proof.
Quartermaster source/integration is outside this Rooms-only iteration; existing
consumers must accept the designated-only scope and handle the no-rooms status.
No current cross-repository or native integration result is claimed.

Native UI, fluid/inventory transactions, synchronization, real save/load and
dedicated behavior are **NOT TESTED**. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.
The .1/.2 checkpoints were explicitly published for testing. The subsequent
explicit publish request authorizes the .5 Workshop test update. No local SP
deployment or game/server launch is included. Distribution is not runtime proof.
