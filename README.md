# B47ANCE'd Rooms

Project Version: 0.1.0-dev.1

Standalone Lua-only room designation and delegated room-policy service for Project Zomboid Build 42.21.0. Mod ID **B47ANCEDRooms**. No Workshop ID assigned. Quartermaster is optional and is never required by Rooms.

Designate rooms from the world context menu: use native or structural candidates, rectangles, paint/erase, explicit floors, undo/redo, names, merge/split and a confirmed preview. Native edits are non-destructive overrides; Restore Vanilla removes the override. Dragging never persists shared state.

The server owns rooms, revisions, ownership and policies. Safehouse owners can delegate rooms, approve boundaries and revoke assignments. Assigned owners manage names, visitors and supported storage actions. Parent/admin metadata privileges do not automatically grant gameplay access.

Room rules apply only to supported integrations. They do not lock unrelated vanilla transfers, doors, entry, building or destruction. Quartermaster consumes API 1 at its server discovery/planning/grant boundaries. No final native transfer interception is claimed.

Authoritative source: `src/B47ANCEDRooms/42`. Registry: `ModData.B47ANCEDRooms.customRooms` schema 2. Legacy Quartermaster room data is read once into the independent root, preserving IDs and leaving the original data unchanged. See [API, permissions, migration and test gates](docs/ROOMS_API.md) and the [source-backed baseline](docs/EXTRACTION_AUDIT.md).

Run `python tests/run_tests.py` and `python scripts/check_versions.py`. Tests require the host-only Lupa 2.6 Lua 5.1 module; it is never a mod dependency. Every check is offline unless explicitly labelled otherwise. Native client and dedicated G7 NOT TESTED/BLOCKED; stable G8 BLOCKED. Development artifacts are not runtime certification. No deployment, publication or game/server launch.
