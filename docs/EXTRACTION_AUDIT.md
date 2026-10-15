# Standalone extraction baseline

Baseline: Quartermaster 0.7.0-dev.1, de6101c45f6d09f6c926cb8afe09105c4c0dec30. Native game evidence: installed B42.21.0; no game/server launch. Rooms did not exist before this authorized initialization.

| Feature | Baseline | Evidence |
|---|---|---|
| Native room/building/proximity views | IMPLEMENTED | DiscoveryView.metadata/includes; Targets.discoverAt; Bindings |
| Custom geometry, detection, editor | IMPLEMENTED offline | RoomGeometry, RoomDetection, RoomDraft, RoomEditor |
| Room registry/network | IMPLEMENTED offline | Rooms.handle/tick; Authority; Protocol rooms 1 |
| Custom-room sorting | IMPLEMENTED offline | RoomSort; Trips area; Movement; configured physical sources only |
| Native-room/building sorting | ABSENT | RoomSort accepted customRoom only |
| Vanilla overrides / restore | ABSENT | Native Outline provided candidates only |
| Delegated ownership / action policies | ABSENT | Creator/current safehouse member editing only |
| Native safehouse storage gate | PARTIAL | Targets.valid checked isSafehouseAllowLoot; no distinct room action service |
| Shopping/Collect/Dibs | IMPLEMENTED | Shopping records and Movement.withdraw; Dibs.inspect target validation |
| Physical handles / furniture inheritance | IMPLEMENTED | Bindings.target; Furniture; Whole Container partial-scope guard |

Original room state: ModData.getOrCreate('B47ANCEDQuartermaster').customRooms schema 1, world UUID, room UUID, ordinal, creator, revision, safehouse ID, compressed rows and timestamps. Global root 1/config 2 remain independent. UI preferences store exact world/room IDs. Migration must preserve records/IDs and leave the original section as immutable recovery evidence.

Native audit found getSafeHouse(String) compares getTitle(), not getId(). Resolve stable house associations through getSafehouseList/getId. findSafeHouse(square) is private and must never be called by Lua. Public bounds are getX/getY/getX2/getY2; membership uses getOwner/getPlayers and authenticated player.getUsername(), not display labels. getSteamID returns Java long; avoid lossy Lua-number IDs. Native isSafehouseAllowLoot respects ServerOptions.safehouseAllowLoot, while isSafehouseAllowInteract additionally uses native role/war/playerAllowed logic. Do not replace their configured behavior with a broad membership assumption.

Installed ISInventoryTransferAction.isValid uses native item-transaction checks. No supported Lua final-mutation hook for unrelated native transfers is established. Enforce action-specific Rooms policy at Quartermaster's server discovery, configuration, planning and grant boundaries. Entry/door/build/destruction/vanilla transfers/other mods remain unsupported security boundaries. No protection claim may exceed this scope.

New project creation/remote/version/Mod ID explicitly approved by user. Unrelated Quartermaster AGENTS.md and Auto Clean audit files remain untouched. No Auto Clean gameplay is in scope. G7 NOT TESTED/BLOCKED; stable G8 BLOCKED.
