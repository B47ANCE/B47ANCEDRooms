# Rooms workflow Workshop testing update

Project Version: 0.2.0-dev.5

[VERIFIED distribution] SteamCMD exited 0 and reported Committing update...Success
for existing Workshop item 3820077442. App ID 108600, public visibility, title,
canonical description and supplied thumbnail match the live item. Release commit:
`fdf1fcbe4b93f58f12cf9a54eaa72fe9343e95c8`. Content update: 2026-10-16 15:48:09 UTC;
Phoenix: 2026-10-16 08:48:09 AM.

Fresh SteamCMD download exactly matches all 85 source/package/stage files and
required common/AnimSets/actiongroups roots. The desktop subscription has not yet matched .5 at the last read-only check.
Its Steam-managed update is pending; no desktop Workshop files were manually
replaced. Fresh SteamCMD download parity is verified independently.
Steam exited gracefully and the same registered executable restarted with a
hidden launch window; the new client process was verified.
No local SP deployment, server change or game/server launch occurred. Upload,
download and client restart are distribution evidence only, not runtime proof.

Source/artifact/version/ZIP/stage/text gates PASS. Real paragraph breaks and MP
testing labels are preserved; description is 6503 UTF-8 bytes, below
the current documented 8000-byte maximum checked October 16, 2026:
https://partner.steamgames.com/doc/api/ISteamRemoteStorage#k_cchPublishedDocumentDescriptionMax
Public GitHub ancestry/SHA and tracked/staged secret/path audits passed before
release pushes and upload. Prior .2 artifacts retain exact hashes and ZIP CRC.
Private logs, raw API data, local provenance and receipts remain ignored.
G7 BLOCKED / NOT TESTED; stable-release G8 BLOCKED.

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
