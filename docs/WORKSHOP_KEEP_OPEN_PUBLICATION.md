# Keep Designate Room open: Workshop testing update

Project Version: 0.2.0-dev.2

Status: PREPARED; upload and download verification pending.

Explicit publish request authorizes the keep-open fix on existing Workshop item
3820077442, App ID 108600, Mod ID B47ANCEDRooms. Public visibility and the supplied
Rooms thumbnail are preserved. A confirmed save refreshes the room list/lease and
starts a blank draft on the same floor in the same window; explicit close restores
the parent once. Failed saves retain drafts. API/protocol/schema, geometry,
permissions, server authority and sandbox behavior are unchanged.

Implementation checkpoint: `6453148bf8d43a17f07747846dcd2a1cc8538ada`.
Public source: https://github.com/B47ANCE/B47ANCEDRooms, feature/standalone-rooms.
Release preparation changes documentation only. Package SHA-256:
`97a8a2147b817b37058a5ef8c97fc73123ee3da038d4cbffe220f4191751b6da`.
Game target 42.21.0; installed Steam build 25485521.

Canonical inputs: docs/WORKSHOP_DESCRIPTION.md and docs/WORKSHOP_CHANGELOG.md.
Generated text: workshop/description.bbcode and workshop/changenote.txt.
Stage, VDF, release manifest, private local logs/API snapshots and receipt:
ignored dist/workshop-publish/0.2.0-dev.2-keep-open/submission. Current ZIP/checksum
and provenance are under dist/current. The manifest binds exact release commit,
version, IDs, game build, source/package/text/thumbnail hashes and evidence. Raw
account data and diagnostics are not committed.

[TESTED offline Windows/Lua 5.1] Full suite passes: consecutive distinct server
saves through one editor, immediate/polled completion, floor retention, refreshed
lease/list, duplicate/late reply isolation, failed-save draft retention, explicit
close/cancellation and parent restoration. Existing geometry, policy, migration,
cleaning, zoom/popup and transport regressions pass. Full version/artifact checks
pass. ZIP inventory is 83 Lua-only runtime files; no custom Java/JAR or host tests.

Commands from repository root using the bundled host Python:

```powershell
python tests/run_tests.py
python scripts/check_versions.py --root . --json
python scripts/build_dev.py
python scripts/check_versions.py --root . --release
python scripts/prepare_workshop.py --output dist/workshop-publish/0.2.0-dev.2-keep-open/submission
```

The initial source-only check failed solely on the old .1 ZIP filename/embedded
version. Explicit publication authorized preserving its ZIP/checksum/provenance
within dist with SHA-256/size ledger and ZIP CRC checks, before current packaging.
Prior package SHA-256:
`0cf1b9b75f2857d8e952a7fc745e3e2a29901b30f9e233771e0a2749aa028f88`.
No files were deleted or relabeled. Prior packages remain recovery evidence;
reverse save migration is not guaranteed. Do not replay preparation over output.

[RUNTIME GATE] Actual UI/focus/controller behavior, real save/load, paired consumer
integration and dedicated multiplayer remain NOT TESTED. Test save Kitchen then
Pantry without reopening; verify distinct saved rooms, unchanged floor, blank next
draft and normal Cancel/Escape close. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.
Distribution is not runtime verification. No game/server launch, local SP
deployment or server changes are included.
