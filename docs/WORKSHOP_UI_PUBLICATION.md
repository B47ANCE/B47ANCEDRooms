# Rooms UI fix Workshop testing update

Project Version: 0.1.0-dev.3

[VERIFIED distribution] Explicitly requested update to existing Workshop item
3820077442, App ID 108600, Mod ID B47ANCEDRooms. SteamCMD used existing cached
authentication, exited 0 and reported Committing update...Success. No password,
Steam Guard code or new item was supplied. Public visibility was preserved.
Steam's published-file API matched the canonical description and item/app/title,
with update time 2026-10-15 20:54:56 UTC (October 15, 2026, 1:54:56 PM Phoenix).

Release commit: `733d0cd532c28380497f0ddaf2f1c47a3edd6b4d`, public repository
B47ANCE/B47ANCEDRooms, feature/standalone-rooms. UI implementation checkpoint:
8924b9f. Release preparation changed documentation only. Package SHA-256:
`8fd3fc035f31c38996569e743584c98058a26b113ffc2d9079eac07b6f5b6087`.
Game target 42.21.0; installed Steam build 25485521.

Canonical inputs are docs/WORKSHOP_DESCRIPTION.md and docs/WORKSHOP_CHANGELOG.md.
Generated text is workshop/description.bbcode and workshop/changenote.txt. The
fresh stage, VDF, manifest, local logs, live API snapshots and publication receipt
are under ignored dist/workshop-publish/0.1.0-dev.3-ui/submission. Current ZIP,
checksum and provenance are under dist/current. The manifest binds version,
commit, item/mod IDs, game build, hashes and evidence. Raw diagnostics and private
local paths/account data are not committed.

[TESTED offline Windows/Lua 5.1] Complete Rooms suite passes, including the actual
dialog module, layering/button/input/focus/teardown fixtures and previous zoom
regressions. Full version checks pass. ZIP CRC, duplicate/path/case checks,
source inventory, localization, require-case, Lua-only and 84-file committed
source/package/stage parity pass. Real paragraph breaks, MP testing label,
description size, public source link and item identity were checked. GitHub
freshness and remote SHA were verified before packaging/upload; staged/tracked
files were audited before each public push.

Commands used with the bundled host Python, from repository root:

```powershell
python scripts/check_versions.py
python scripts/build_dev.py
python scripts/check_versions.py --root . --release
python scripts/prepare_workshop.py --output dist/workshop-publish/0.1.0-dev.3-ui/submission
```

The build invokes tests/run_tests.py and version checks. Do not replay build or
stage preparation over existing output. The prior .2 ZIP/provenance/checksum were
preserved within dist, with exact SHA-256/size ledger and ZIP CRC, no deletions or
historical relabeling. Restore the prior package for recovery; reverse save
migration is not claimed.

[VERIFIED distribution] A fresh SteamCMD Workshop download matches all 84 runtime
files and required common/AnimSets/actiongroups roots. After graceful Steam
desktop restart, its subscribed Rooms folder also matched those 84 files in a
read-only inspection. The client update was initially pending and subsequently
verified. The same registered/local verified Steam installation was shut down
gracefully and started with a hidden launch window; the client process returned.
No force termination, game/server launch, local SP deployment, server mutation or
other project's upload occurred.

[RUNTIME GATE] Test the placement-cancel/save popup above Designate Room, the two
labeled buttons, click-through blocking, mouse/Escape/controller cancellation,
confirmation once, focus restoration and editor-close/disconnect teardown. Exact
origin of the previously reported check/X controls remains runtime UNKNOWN.
Native popup/zoom rendering and dedicated multiplayer are NOT TESTED.
G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. Upload/download/restart success does
not establish native UI or gameplay correctness.
