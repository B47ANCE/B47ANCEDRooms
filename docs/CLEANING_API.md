# Cleaning consumer API

Project Version: 0.1.0-dev.2

This is the Rooms side of the authorized offline Auto Clean integration. Rooms
owns physical building membership and cleaning permission. It never searches
inventories, transfers supplies, moves characters or cleans the world.

`API.capabilities().cleaning == 1` advertises this additive consumer API. The
existing general API remains 1. `boundaries.cleaning=true` means cooperating
consumers can enforce cleaning permission; `vanillaFinalMutation=false` remains
explicit. Unrelated vanilla actions and other mods do not acquire these checks.
No global world-protection claim is made.

## Server API

| Method | Contract |
|---|---|
| `cleaningOptions()` | Effective, validated server sandbox values; on clients this is presentation only |
| `beginCleaningBuilding(player)` | Bind the current native physical building to the actual server actor; return `waiting` and a scope token |
| `readCleaningBuilding(player, scope)` | Advance a bounded native room scan; return `waiting`, an explicit failure, or detached tile/options snapshots |
| `validateCleaningBuilding(player, scope)` | Reject a foreign, expired, disconnected, dead, disabled, changed-policy/settings or changed-building lease |
| `containsCleaningBuildingTile(player, scope, x, y, z)` | Current exact native building membership; does not itself grant cleaning permission |
| `canCleanBuildingTile(player, scope, x, y, z)` | Membership plus the current independent `clean` policy and native safehouse loot/interact checks; returns `allow`, `deny` or `unknown` |
| `canAccessAt(player, x, y, z, 'clean')` | Independent delegated clean permission at a loaded square |
| `endCleaningBuilding(player, scope)` | Release only that actor's exact scope and native scan |
| `cleaningTick()` | Expire disconnected/dead/old scopes; registered once by the Rooms module |

These are server APIs. Client geometry/permission claims are never accepted as
authority. A consumer must obtain `player` from the authenticated native command
event, retain exact resource references itself, and revalidate before each final
mutation. A clean grant never substitutes for supply `inspect`, `withdraw` or
`deposit` permission. Unknown or denied access must stop the affected operation.

The scope covers all loaded native rooms in the selected physical building,
including floors and holes. Custom overrides cannot narrow the physical building
into an invented native boundary. Delegated policy still applies on every tile.
Unloaded/oversized/incomplete native geometry fails explicitly; no chunk is
created or loaded and no truncated building is returned. Current native room
limits (4096 tiles, 128-tile extent, 128 room definitions) remain conservative
technical bounds. Total building size uses the sandbox limit below.

One cooperating cleaning scope may own a building at a time. The actor, native
building definition, Rooms registry revision and effective options are bound.
A policy or setting change invalidates the lease. The 30-minute lifetime,
bounded native scan steps and connection check are implementation safety limits.
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
suspended parent associations and unknown state still fail closed. This is an
additive development extension within the initial unreleased 0.1.0-dev.1
checkpoint; no new canonical version or save root was invented. Current peers
must be updated together. Older parsers can reject a persisted `clean` rule;
downgrade after writing one is not claimed supported. No actual player save was
opened or migrated for this work.

UI/sandbox labels use the repository's existing identical-English fallback
dictionaries across available language folders. They are not claimed to be
human translations.

## Validation and activation

`python tests/run_tests.py` includes `test_cleaning.lua`, covering native floors,
holes, actor binding, building claims, copied snapshots, independent clean rules,
native interact denial, validated defaults/bounds, settings revocation,
disconnect/expiry and client denial. Syntax, case, inventory, localization,
registry/network/migration and existing editor tests remain included.

`python scripts/check_versions.py --root .` passes at the observed checkpoint.
The paired Auto Clean runner in the Quartermaster repository uses this actual
Rooms API with native Lua and simulated engine/network objects. Native UI,
native fluid/inventory transactions, synchronization, real save/load and
dedicated behavior are **NOT TESTED**. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.

The Auto Clean context/job installers remain outside packaged source, under
Quartermaster `research/auto-clean/BuildingWire.lua`. No game/server was launched
and no deployment or publication was performed by this work.
