# First Workshop MP testing distribution

Project Version: 0.1.0-dev.1

[VERIFIED distribution] Steam assigned item 3820077442 to B47ANCE'd Rooms,
Mod ID B47ANCEDRooms, App ID 108600. The explicitly authorized creation first
allocated the identity privately; it was recorded in WORKSHOP_ID.txt and pushed
before publishing that same item publicly. No second item was created. The item
is public and the Steam published-file API returned the exact canonical rendered
description, correct title and app/item identity.

Release commit: `f1f41f60e14fb6d9411203c9dfe9b6c79524b5af` on public repository
https://github.com/B47ANCE/B47ANCEDRooms, branch feature/standalone-rooms.
ZIP SHA-256: `6c0e1f19625dfaafff8145a158e1a00c256b0a84594386fc4768fd4311e24a78`.
The existing open 0.1.0-dev.1 construction checkpoint is its first published
candidate; gameplay/API/schema and server guards were unchanged for distribution.

Canonical inputs are docs/WORKSHOP_DESCRIPTION.md and docs/WORKSHOP_CHANGELOG.md.
The trusted shared renderer produces workshop/description.bbcode; the staging
helper produces workshop/changenote.txt and a fresh stage, VDF and release manifest
under ignored dist/workshop-publish/0.1.0-dev.1-initial/. The final public upload
receipt is in public-submission/publication-receipt.json there. Raw native API
diagnostics, credentials and SteamCMD logs are not committed. Previous extraction
package/provenance were preserved with a SHA-256 ledger before rebuilding.

[TESTED offline] Rooms source, geometry, policies, migration, editor, API and
headless transport tests pass. Paired Quartermaster production tests pass all 83
Clean Building/guard/transport/startup scenarios. Lua-only, localization, require
case, source inventory, version, archive CRC/path/case and 84-file source/package/
stage parity checks pass. A fresh SteamCMD Workshop download to its tool cache
matches all 84 runtime files byte-for-byte, with common and required actiongroup/
AnimSets directories present. No SP installation or game/server launch occurred.

Exact commands from the respective repositories, using the configured Python:

```
python tests/run_tests.py
python scripts/check_versions.py --root . --release
python scripts/build_dev.py
python scripts/prepare_workshop.py --output dist/workshop-publish/0.1.0-dev.1-initial/public-submission
python tests/run_auto_clean_building.py --source --game "E:/Program Files (x86)/Steam/steamapps/common/ProjectZomboid" --rooms ../B47ANCEDRooms
```

The preparation command uses a fresh output path and was run before publication;
do not replay it over saved evidence. The build similarly refuses to overwrite an
existing ZIP. SteamCMD used cached authentication, fixed App ID 108600 and the
assigned ID; its public update reported Committing update...Success. Quartermaster
item 3807217050 was updated with a direct Rooms Workshop link and instructions
to subscribe/enable both mods on the server and every client. Quartermaster's
runtime package SHA-256 remained unchanged.

[RUNTIME GATE] Native UI, real save/load, dedicated join/rejoin, authority,
conservation, observers and restart behavior remain NOT TESTED. G7 BLOCKED /
NOT TESTED; stable G8 BLOCKED. Single-player Clean Building remains disabled;
its conservative footprint guard may skip many or all targets. Policies do not
lock unrelated vanilla gameplay. Workshop download parity does not establish
runtime or subscription-state correctness.

Steam restart was BLOCKED by automatic approval review: the combined verification
and restart command was rejected with only "blocked by policy". Read-only live
metadata verification completed separately. No forced shutdown or alternate
restart attempt was made. Publication itself was already confirmed.
