# B47ANCE'd Rooms

Project Version: 0.2.0-dev.1

![B47ANCE'd Rooms project thumbnail](artwork/thumbnail.png)

Standalone Lua-only room designation and server-owned permissions for Project Zomboid Build 42.21.0. Mod ID **B47ANCEDRooms**; existing [Workshop item 3820077442](https://steamcommunity.com/sharedfiles/filedetails/?id=3820077442). Quartermaster is an optional consumer, never a Rooms dependency.

The development version keeps vanilla **building detection** and uses only **player-designated rooms**. Vanilla room definitions are never read. Open Designate Rooms to an empty draft, draw and name rooms, then confirm the server save. The list shows saved designations in the current physical building. Detect Walls is an explicit preview tool; rectangles, paint/erase, explicit floors, undo/redo, merge/split and the existing popup/zoom fixes remain.

Native Outline and Restore Vanilla are removed. Existing saved overrides remain ordinary designated rooms with the same geometry, IDs, revisions, ownership and permissions. Old aliases are inert recovery metadata; native IDs no longer resolve rooms. No save reset occurs. See the [contract and compatibility changes](docs/ROOMS_API.md).

Cleaning scopes now contain only loaded designated tiles belonging to the selected physical building, across saved floors and holes. Undesignated space is excluded; designate rooms before cleaning. Rooms owns scope/permission checks; consumers own supplies, movement and actual cleaning. General API 1 and cleaning capability 1 remain, with `nativeOverrides=false`, `designatedRooms=true` and `cleaningScope='designatedRooms'`. Consumers that require the retired native-room feature must change; Quartermaster is not edited or runtime-verified in this iteration. See [cleaning API](docs/CLEANING_API.md).

The server owns rooms, revisions, ownership and policies. Safehouse owners delegate rooms, approve boundaries and revoke assignments. Assigned owners manage names, visitors and supported actions. Parent/admin metadata privileges do not grant private gameplay access. Policies apply only to cooperating integrations; unrelated vanilla transfers, doors, entry, building and destruction are outside the protection boundary.

Authoritative source: `src/B47ANCEDRooms/42`. Persistence: `ModData.B47ANCEDRooms.customRooms`, schema 2. Data-only legacy Quartermaster import retains IDs and original recovery data. API 1, protocol 1 and save schema 2 are independent of SemVer. The incompatible native-room removal is explicitly tracked as the 0.2 development line; peers should use matching builds.

Run `python tests/run_tests.py` and `python scripts/check_versions.py --root .`. Tests use host-only Lupa/Lua 5.1 and never launch the game. [TESTED offline] Full source suite passes; [RUNTIME GATE] native UI, real persistence and dedicated G7 remain NOT TESTED/BLOCKED; stable G8 BLOCKED. The published .3 ZIP is preserved unchanged in `dist/current`, so artifact version checks remain blocked pending authorized packaging. No package, deployment or upload is part of this iteration.

The live Workshop item still contains **0.1.0-dev.3** with the prior UI/outline fixes and supplied thumbnail. Historical [UI audit](docs/UI_AUDIT.md), [UI publication](docs/WORKSHOP_UI_PUBLICATION.md), [outline publication](docs/WORKSHOP_OUTLINE_PUBLICATION.md) and [first publication](docs/WORKSHOP_PUBLICATION.md) retain their original evidence. [Artwork provenance](artwork/README.md) preserves the original, export and previous fallback. Historical distribution success is not current source or runtime verification.
