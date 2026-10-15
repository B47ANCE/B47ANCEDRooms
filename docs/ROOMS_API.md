# Standalone Rooms API, authority and acceptance

Project Version: 0.1.0-dev.2

## Scope and compatibility

[VERIFIED source] Initial standalone extraction from team-owned Quartermaster 0.7.0-dev.1. Canonical version is root VERSION. Authoritative runtime root is `src/B47ANCEDRooms/42`; package root is `B47ANCEDRooms`. Mod ID is B47ANCEDRooms. Steam assigned Workshop ID 3820077442 for the authorized first test publication; Quartermaster is not a dependency. See EXTRACTION_AUDIT.md for the historical baseline inventory and provenance. No third-party implementation/assets are included; isolated B47RoomsUI modules derive from team-owned UI code.

Room API version 1, network protocol 1 and registry schema 2 are independent of project SemVer. Callers check API readiness/version/capabilities. Unsupported or unknown permission results must fail closed for protected actions.

## Modules and public contract

| Module | Responsibility |
|---|---|
| Identity / Geometry | Authenticated account identity, bounded snapshots, canonical floor-specific row runs and algebra |
| Detection / Native | Bounded structural candidates, exact native identity/membership and cooperative snapshots |
| Policy | Native parent hierarchy, metadata authority, per-action gameplay grants and protected overlap checks |
| LegacyImport / Registry | Data-only import, independent persistence, leases, revisions and cooperative atomic writes |
| API / Network | Versioned snapshots/decisions, whitelisted commands, admission and change subscriptions |
| Client / Draft / Editor | Client intent, previews/history, independent world editor and lifecycle cleanup |
| B47RoomsBootstrap / B47RoomsContext | Dedicated-safe startup and standalone world-context entry |

`require 'B47ANCEDRooms/API'` exposes `B47ANCEDRooms.API`, `version=1`, `ready=true`.

Read methods on the authoritative Lua side:

- `capabilities()` describes API/version and supported boundaries.
- `listRooms(player, filter?)`: bounded accessible managed/native metadata, registry revision/world. `filter.safehouse` uses exact native ID; `filter.building=true` restricts to the actor's native building.
- `resolveRoom(player, id, revision?)`, `resolveAt(player,x,y,z)`, `roomsAt(...)`: explicit result/status. Overlapping organizational rooms make resolveAt ambiguous, never select arbitrary ownership.
- `geometry(player,id,revision?)`, `tiles(...)`, `containsTile(...)`, `containsTarget(...)`: snapshots or exact membership. Native snapshots may return waiting/busy and require retry; no native room object is mutated.
- `permissions(player,id)`: authorized metadata managers receive owner/assigned/safehouse/revision/policy and edit capabilities.
- `canAccessAt(player,x,y,z,action)`, `canAccess(player,id,action,target?)`: `{state='allow'|'deny'|'unknown',reason?,revision?}`. Unknown is not authorization. `editRoom` and `assignOwner` are metadata decisions.
- `subscribe(callback)` returns an unsubscribe function. Changes invalidate consumers; no UI must be open.

Client entry points `request(playerNum,command,args,callback)` and `openEditor(playerNum,parent?,onClose?)` submit intent/use local presentation. Client calls cannot mutate the server registry.

Mutation helpers `beginEdit`, `change`, `create`, `rename`, `editGeometry`, `delete`, `restoreVanilla`, `merge`, `split`, `assignOwner`, `revokeOwner`, `setPolicy`, `requestBoundary`, `approveBoundary`, `rejectBoundary`, `relinquish` are server-side operations using Registry validation. A helper does not bypass leases/revisions or become a synchronous promise of persistence.

## Protocol and writes

Module B47ANCEDRooms accepts only roomList, roomGet, nativeGet, roomChange, roomPoll and roomCancel. Each network request uses protocol 1 and a finite positive integer request ID. The server receives the authenticated actor; submitted owner fields cannot assign identity. Malformed IDs, unknown commands/fields and invalid policy/geometry are rejected. Admission is bounded per actor (burst 8, replenish 4/s, write cost 4); technical limits are internal, not gameplay options.

Acquire `roomList` with renew=true to obtain editKey, registry revision, world and server options. Submit roomChange with a bounded unique nonce, editKey, original registry revision, action, and applicable id/roomRevision. Save uses name and compressed rows `{z,y,x1,x2}`; merge also uses exact managed IDs/confirm; split uses secondName/secondRows/confirm. A native override supplies nativeId. Assignment uses a current parent account, policy uses validated mode/rules/grants. Delete/restore requires explicit confirm.

Writes return pending and are polled by nonce. Tile checks are cooperative (32 checks/job, up to 4 jobs within a 4ms tick budget); at most 16 active writes and a 30-second lifetime. The final replacement checks the original revision and current permissions, then atomically swaps the library. Replays return the same outcome; a used lease cannot create a second write. Stale revisions conflict. Cancellation/timeout does not invent a failed or successful mutation. Client write timeouts are uncertain; late replies cannot revive an expired callback.

## Identity, geometry and persistence

Native safehouses persist authenticated account usernames. Multiplayer ownership uses `IsoPlayer.getUsername()`, not display/character names. Java-long SteamIDs must not be rounded through Lua numbers. Offline SP uses local:<playerNum>; automatic cross-mode identity migration is unsupported.

Managed IDs are world UUID plus room UUID; ordinal display labels are not identity. Native IDs have native: prefix. Overrides retain aliases through merges; split leaves aliases on the surviving original identity. Restore removes the override and exposes all original native definitions. Native room loot/spawn names and map geometry stay unchanged.

Canonical row runs support rectangles, add/subtract/paint/erase, holes, irregular/disconnected regions and explicit floors. Technical caps: 4096 tiles/room, 512 row runs, 128 XY extent, 8 floors, z -32..31, 128 records and 16384 total managed tiles. Detection stops at unloaded/unbounded areas. Door identity remains a boundary even open; doorless openings follow the server setting. Previews never persist automatically. Undo/redo is bounded client history.

Authoritative root is `ModData.getOrCreate('B47ANCEDRooms').customRooms`, schema 2. Registry holds world, revision, serial and records (ID, ordinal, name, creator, revision, rows, times, parent association, optional assigned account/policy/parent stamp/native aliases/pending boundary). No arbitrary saved code is executed.

LegacyImport reads Quartermaster's existing schema-1 section with ModData.get, without requiring Quartermaster or creating its namespace. Full validation precedes storing the independent copy. IDs/revisions/ownership are retained; original data is left untouched for recovery. Existing schema 2 is not reimported. Future/corrupt data is not overwritten. Back up saves; reverse migration of later Rooms edits into old Quartermaster is unsupported.

## Permission hierarchy and safehouse audit

Installed Build 42.21.0 evidence: `projectzomboid.jar` and shipped Lua, inspected offline. SafeHouse.getSafehouseList/getId/getOwner/getPlayers and getX/getY/getX2/getY2 are public; native bounds are half-open. SafeHouse.getSafeHouse(String) compares titles, so ID resolution iterates getId instead. findSafeHouse(square) is private and is never called. Native membership mutations/overlapping native claims are not used by this mod.

`isSafehouseAllowLoot(square,player)` respects native server loot configuration. `isSafehouseAllowInteract` additionally follows native roles, war state and playerAllowed. Rooms calls native authority gates before its own decisions; it never substitutes membership assumptions for configured native access.

Effective supported storage policy: native/server rules, then active parent association, then room rule, then explicit per-account allow/deny. An explicit grant cannot override a native denial. Shared organizational regions do not add restrictions. Private regions require assignment, current parent owner/bounds/membership, exact contained geometry and no other private overlap on the same floor. Parent changes suspend private decisions as unknown until authorized revalidation. Definitions remain for recovery.

Parent safehouse owners/admins can administer metadata, assignments and boundaries. Assigned room owners can rename, relinquish, edit visitor/action policy and propose boundaries; expansion requires parent approval. Parent/admin management is independent of gameplay and grants no automatic access to private storage. Assignment preserves private state without an intermediate shared gap; incompatible private policies cannot be merged.

| Action/boundary | Current status |
|---|---|
| Discover, inspect, withdraw, deposit, configure | Server API implemented; enforced by Quartermaster at supported discovery/planning/grant boundaries |
| Edit room, assign/revoke, approve boundaries | Server revision-checked registry mutation |
| Native final inventory mutation | BLOCKED: no supported Lua interception established; accepted native actions may finish after revocation |
| Independently initiated vanilla/other-mod transfers | BLOCKED: no absolute protection claim |
| Entry, doors, furniture movement, building, destruction | BLOCKED/advisory; no reliable authoritative interception established |
| Auto Clean gameplay | Outside this extraction; separate consumer work is excluded from this snapshot |

Server sandbox controls: Enabled (true); RoomTileLimit (64–4096, default 1024); RoomEditRange (5–128, default 30); RoomDoorways (true); DelegatedRooms (true). Stable translation keys and English fallback exist in 29 installed language folders. Existing explicit settings are retained; newly introduced settings use defaults. Disabling the authority service is not a bypass for private access.

## Validation, artifacts and gates

[TESTED offline Windows/Lua 5.1] `python tests/run_tests.py`: syntax, standalone namespace, no inventory mutation, manifest/case/localization, geometry/edit/replay/concurrency/corruption, structural detection, ownership/action grants/native denial, parent changes, overlap, migration, native overrides/merged aliases/restore, editor mouse/controller lifecycle and dedicated bootstrap/transport. Native-shaped fixtures are disposable and do not certify actual Lua/Java networking.

`python scripts/check_versions.py` checks current mirrors. `python scripts/build_dev.py` builds a development-only ZIP after offline checks; `python scripts/check_versions.py --release` validates artifact version consistency, not gameplay G8. Production manifests and source/ZIP hashes are recorded separately. B42 common/AnimSets/actiongroups empty roots are explicit package entries. No host Python/Lupa, test code, credentials or custom Java is packaged. Manually supplied artwork takes precedence; this new project uses exact verified team fallback branding.

[RUNTIME GATE] Actual native UI/detection/override behavior, persistent native save/load and two-remote-client dedicated tests are NOT TESTED. Required acceptance includes parent/delegate/guest and native denial, source/destination policies, concurrent edits/sorts, revocation before/after dispatch, container relocation, reconnect/restart and item conservation. G7 NOT TESTED/BLOCKED; stable G8 BLOCKED. Development packaging does not deploy, publish or launch anything.
