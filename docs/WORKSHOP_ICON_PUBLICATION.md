# Rooms transparent icon testing update

Version 0.2.0-dev.7 is a compatible presentation-only checkpoint after merged
0.2.0-dev.6. The user explicitly selected the room-only transparent mod icon,
kept the thumbnail unchanged, requested all open Rooms PRs be merged, and
authorized publication after checks pass. At inspection no PRs were open:
PRs #1 and #2 were already merged into main at e9d3b0965155ef6bb5ae067eb42d50e96d2de7b2.

Changes: 64x64 RGBA runtime icon; original generated icon and old icon retained
outside runtime packaging; synchronized current version mirrors and artwork/
release documentation. No gameplay, API, protocol, schema or sandbox changes.
No new settings are appropriate for this artwork change. Existing server
authority and designated-room-only contracts are unchanged.

Canonical inputs: VERSION, src/B47ANCEDRooms, artwork/thumbnail.png,
docs/WORKSHOP_DESCRIPTION.md and docs/WORKSHOP_CHANGELOG.md. Generated text:
workshop/description.bbcode and workshop/changenote.txt. Existing item 3820077442,
App ID 108600, Mod ID B47ANCEDRooms, public visibility and source repository
https://github.com/B47ANCE/B47ANCEDRooms are retained.

Validation commands (run from repository root with the bundled Python):
- python tests/run_tests.py
- python scripts/check_versions.py --root . --json
- python scripts/build_dev.py
- python scripts/check_versions.py --root . --release
- python scripts/prepare_workshop.py --output dist/workshop-publish/0.2.0-dev.7-icon/submission
- git diff --check

Check true alpha, transparent corners, dimensions, complete silhouette and
source/icon hashes; unchanged thumbnail/source/poster hashes; exact manifest,
Lua-only, localization and case-correct requires; ZIP CRC, paths, duplicate/case
members and source/package/stage parity; fresh Git ancestry, public source and
tracked/staged secret/generated-file audit. Publication receipt follows after
the actual upload; preparation is not upload evidence.

Native UI/save-load and dedicated G7 remain NOT TESTED / BLOCKED. Stable G8
remains BLOCKED. Workshop distribution is an MP testing build, not runtime
acceptance. No local SP deployment, game/server launch or server modification.
Steam desktop restart requires a separate affirmative reply after upload.
Prior .5 publication evidence and all preserved artifacts remain historical.

[TESTED offline Windows/Lua 5.1] Full source/regression suite PASS on October 18,
2026 through scripts/build_dev.py; source and release version checks PASS.
The deterministic ZIP contains 85 runtime files, validates CRC/member paths,
duplicate/case safety and exact source parity. Package SHA-256:
45d6c1b98af807a79805dc79568961f9b56f5c4dd4f05ee1126f7ea1036d7310.
PNG size/alpha/corners and the unchanged thumbnail SHA PASS. Source inspection
confirms no gameplay behavior changed. GitHub main has no branch-protection
required checks and this repository has no CI workflow; offline checks do not
claim a GitHub CI pass. The icon branch is based on freshly verified main.

## Upload attempt — authentication blocked

[VERIFIED GitHub] PR #3 was merged into public main on October 18, 2026.
Release source commit: c0a4a2374fd98e833caaec8e1c0f19810c118266.
Remote main and the clean release checkout matched this SHA before staging.
No Rooms PRs remained open after the merge.

[TESTED offline] prepare_workshop.py PASS: all 85 committed source, package and
stage files match; rendered description is 6503 UTF-8 bytes with real paragraph
breaks and the required MP testing label. VDF App ID, existing item identity,
public visibility, source URL, preview and package hashes PASS. Pre-upload live
metadata confirmed the existing public item. The staged preview retains SHA-256
9602702443b0b1a92f9ed35e48e927fdd92d3e7d05d4789917a0edba2ed26668.
Target game 42.21.0; installed Steam build 25485521.

[BLOCKED upload] SteamCMD exited 5 at 2026-10-18T10:24:56Z and reported
"Cached credentials not found" / "No cached credentials and @NoPromptForPassword
is set". No Committing update...Success result occurred. Version .7 is NOT
published; no subscription/download/runtime acceptance is claimed. The existing
item was not replaced or recreated. Steam desktop was not restarted.

The inspected uploader performs no Steam desktop restart, game/server launch or
local deployment. The user must restore SteamCMD authentication locally; no
password or Steam Guard code is requested in chat or written to project files.
Retry the same validated source/package and existing item after authentication,
retaining this failed attempt's private log rather than overwriting it.

Ignored local evidence is under dist/workshop-publish/0.2.0-dev.7-icon/submission:
release-manifest.json, submission.vdf, stage and steamcmd-upload.log. The matching
ZIP/checksum/provenance remain in dist/current. Logs, VDFs and credentials are
not committed. G7/stable G8 remain BLOCKED; authentication recovery does not
provide runtime evidence.
