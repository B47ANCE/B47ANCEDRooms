# Rooms workflow Workshop testing update

Project Version: 0.2.0-dev.5

Status: PREPARED; upload and download verification pending.

Explicit publish request authorizes existing item 3820077442, App ID 108600,
Mod ID B47ANCEDRooms. Public visibility and supplied thumbnail are unchanged.
This distributes .3 contextual create/edit controls, .4 outline/floor/type/role
features and .5 live/conflict/filter/summary/repeated-entry/permission-copy work.
Implementation checkpoint: `65ad9d82e6595c6ca9f7fbe3e25f8e7e1b6c0a23`.
Public source: https://github.com/B47ANCE/B47ANCEDRooms,
branch feature/standalone-rooms. Release preparation changes documentation only.
Game target 42.21.0; installed Steam build 25485521.

Package SHA-256: `48c4f17746ec8e1c5c8bd992a6a9bb84e57b29c90c1462bb49fa16f6574f6565`.
Supplied thumbnail SHA-256:
`9602702443b0b1a92f9ed35e48e927fdd92d3e7d05d4789917a0edba2ed26668`.
Canonical inputs: docs/WORKSHOP_DESCRIPTION.md and docs/WORKSHOP_CHANGELOG.md.
Generated outputs: workshop/description.bbcode and workshop/changenote.txt.
Ignored stage/VDF/release manifest and private upload/API/download receipts:
dist/workshop-publish/0.2.0-dev.5-workflow/submission. Current package, checksum
and provenance are under dist/current. Manifest binds exact release commit,
version, IDs, game build and source/package/stage/text/artwork hashes.

[TESTED offline Windows/Lua 5.1] Full source suite PASS, including live-refresh
races, dirty conflict/deletion recovery, search/filter combinations, source and
destination copy authority, native denial, queued revocation, copied policy
reload, repeat setup and fixed-footer/font geometry. Existing custom geometry,
detection, ownership/policy, migration, cleaning, popup/zoom and headless network
checks pass. Source/artifact version checks PASS. Package is 85 Lua-only runtime
files with required common/AnimSets/actiongroups roots; CRC, duplicate/path/case
and exact source/ZIP checks PASS. No host tests, secrets or custom Java are shipped.

Exact commands from repository root (bundled host Python):

```powershell
$roomsPython = "$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
& $roomsPython tests/run_tests.py
& $roomsPython scripts/build_dev.py
& $roomsPython scripts/check_versions.py --root . --release
& $roomsPython scripts/prepare_workshop.py --output dist/workshop-publish/0.2.0-dev.5-workflow/submission
```

The old published .2 ZIP, checksum and provenance are preserved with a size/hash
ledger and ZIP CRC verification in this release's previous-current directory.
Old ZIP SHA-256: `97a8a2147b817b37058a5ef8c97fc73123ee3da038d4cbffe220f4191751b6da`.
No artifact was deleted or relabeled. Older release evidence remains immutable.
Do not replay one-time preparation over existing output; native save downgrade
is unsupported. Back up saves and use matching peer builds.

[RUNTIME GATE] WORKFLOW_COMPLETION.md lists native acceptance steps. Actual UI,
save/load, controller/focus, paired consumer integration and dedicated multiplayer
remain NOT TESTED. G7 BLOCKED / NOT TESTED; stable-release G8 BLOCKED. Description
and change note explicitly label MP testing. Upload/download success proves
distribution only. No game/server launch, local SP deployment or server changes
are included. Steam is gracefully restarted only after verified upload success.
