# Outline-fix Workshop testing update

Project Version: 0.1.0-dev.2

[VERIFIED distribution] The explicitly requested Rooms fix was uploaded to the
existing public Workshop item 3820077442, App ID 108600, Mod ID B47ANCEDRooms.
SteamCMD exited 0 and reported Committing update...Success. The live Steam
published-file API confirmed exact canonical rendered description, title, item,
app and unchanged public visibility, with update timestamp 2026-10-15 08:31:27 UTC
(October 15, 2026, 1:31:27 AM America/Phoenix). No new item was created.

Release commit: `2a6d7ce6607048ce9f1316cca72fae5bd685e361` on the public
B47ANCE/B47ANCEDRooms repository, branch feature/standalone-rooms. The runtime
fix originated at f0d4857; release preparation changed documentation only.
Package SHA-256:
`dae7e3cdc7827bb1a875461a3585c6da1a35be5739ba9c18615e588c6e366fb1`.
Target game: Build 42.21.0, installed Steam build 25485521.

Canonical inputs: docs/WORKSHOP_DESCRIPTION.md and docs/WORKSHOP_CHANGELOG.md.
Generated outputs: workshop/description.bbcode and workshop/changenote.txt.
The fresh submission, immutable VDF, release manifest, upload/download logs,
live metadata and publication receipt are under ignored
dist/workshop-publish/0.1.0-dev.2-outline/submission. Current ZIP/checksum and
provenance are under dist/current. Credentials and raw diagnostics are not
committed. The release manifest binds commit, version, item/mod IDs, exact game
build, source/package/stage/text hashes and offline/runtime evidence.

[TESTED offline Windows/Lua 5.1] All Rooms suites pass, including projection
regression, editor lifecycle, registry/permissions/migration and headless
transport. Source/package/stage parity passes for 84 runtime files. ZIP paths,
case collisions, duplicates, CRC, require-case, localization/source manifest,
Lua-only and version checks pass. The description and note preserve real
paragraph breaks and the required MP testing label. The description is below
the current documented 8000-byte limit. Repository freshness and public remote
SHA matched before packaging and upload; tracked/staged content was audited.

Exact commands from repository root, using the configured bundled host Python:

```powershell
python scripts/check_versions.py
python scripts/build_dev.py
python scripts/check_versions.py --root . --release
python scripts/prepare_workshop.py --output dist/workshop-publish/0.1.0-dev.2-outline/submission
```

The build runs tests/run_tests.py and version checks itself. Do not replay the
build/preparation over existing artifacts: both preserve prior output. Before
building, the four old current package/provenance/report files were preserved
within dist, byte-for-byte, with a SHA-256 ledger and retained ZIP CRC check.
No historical validation or package was relabeled and nothing was deleted.
Recovery restores the previous package, not a reverse migration of future saves.

The first account candidate lacked cached credentials, so SteamCMD stopped
before upload. The account evidenced by the prior successful Rooms publication
then authenticated using its existing cache. No password or Steam Guard code
was supplied, stored or bypassed. Upload success was established from exit 0,
the explicit commit success message, the selected VDF identity and live API;
the upload log itself does not repeat the item ID. A fresh tool-cache download
matched all 84 published runtime files and required common/AnimSets/actiongroups
roots. A read-only inspection found matching bytes in the Steam desktop client's
subscribed Rooms folder as well.

After verified upload, the established Steam desktop executable was asked to
exit gracefully and restarted from the same installation with a hidden launch
window. The restarted client process was verified. No forced termination,
game/server launch, SP deployment, SFTP mutation or other Workshop upload occurred.

[RUNTIME GATE] Native zoom/pan/upper-floor outline rendering remains NOT TESTED.
The user can now test this exact subscribed build. Real persistence, dedicated
join/rejoin, synchronization and restart acceptance remain NOT TESTED.
G7 BLOCKED / NOT TESTED; stable-release G8 BLOCKED. Distribution/download/Steam
restart success does not establish gameplay or native rendering correctness.
