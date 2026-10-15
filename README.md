# B47ANCE'd Rooms

Project Version: 0.1.0-dev.2

Standalone Lua-only room designation and delegated room-policy service for Project Zomboid Build 42.21.0. Mod ID **B47ANCEDRooms**. Current development source fixes zooming room outlines and is not packaged or published. The last published MP testing build is 0.1.0-dev.1 at [Workshop item 3820077442](https://steamcommunity.com/sharedfiles/filedetails/?id=3820077442). Quartermaster is optional and is never required by Rooms.

For Clean Building, subscribe to [Rooms](https://steamcommunity.com/sharedfiles/filedetails/?id=3820077442) and [Quartermaster](https://steamcommunity.com/sharedfiles/filedetails/?id=3807217050), then enable both mods on the server and every client. Rooms exposes API 1 with cleaning capability 1; Quartermaster 0.8.0-dev.1 supplies the automatic workflow. Single-player Clean Building remains disabled; native/dedicated behavior is not verified.

For the historical 0.1.0-dev.1 distribution, SteamCMD upload and public metadata were verified. A fresh Workshop download matched all 84 published source files and required runtime directory roots at that checkpoint. This is distribution evidence, not game/dedicated-MP proof or parity with current development source. See [publication evidence and exact checks](docs/WORKSHOP_PUBLICATION.md).

See [outline diagnosis and validation](docs/OUTLINE_ZOOM_FIX.md). The preserved published 0.1.0-dev.1 ZIP remains in `dist/current`; the version checker blocks release until current artifacts are reconciled during separately authorized packaging. No artifacts were changed by this visual fix.

Designate rooms from the world context menu: use native or structural candidates, rectangles, paint/erase, explicit floors, undo/redo, names, merge/split and a confirmed preview. Native edits are non-destructive overrides; Restore Vanilla removes the override. Dragging never persists shared state.

The server owns rooms, revisions, ownership and policies. Safehouse owners can delegate rooms, approve boundaries and revoke assignments. Assigned owners manage names, visitors and supported storage actions. Parent/admin metadata privileges do not automatically grant gameplay access.

Room rules apply only to supported integrations. They do not lock unrelated vanilla transfers, doors, entry, building or destruction. Quartermaster consumes API 1 at its server discovery/planning/grant boundaries. No final native transfer interception is claimed.

Authoritative source: `src/B47ANCEDRooms/42`. Registry: `ModData.B47ANCEDRooms.customRooms` schema 2. Legacy Quartermaster room data is read once into the independent root, preserving IDs and leaving the original data unchanged. See [API, permissions, migration and test gates](docs/ROOMS_API.md) and the [source-backed baseline](docs/EXTRACTION_AUDIT.md).

Run `python tests/run_tests.py` and `python scripts/check_versions.py`. Tests require the host-only Lupa 2.6 Lua 5.1 module; it is never a mod dependency. Every check is offline unless explicitly labelled otherwise. Native client and dedicated G7 NOT TESTED/BLOCKED; stable G8 BLOCKED. Development artifacts are not runtime certification. The user authorized first Workshop publication; no local SP deployment, game/server launch or server changes are authorized. See canonical Workshop text in `docs/WORKSHOP_DESCRIPTION.md` and `docs/WORKSHOP_CHANGELOG.md`; generated staging and upload receipts stay under ignored `dist/`.
