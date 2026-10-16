# Designated Rooms Workshop testing update

Project Version: 0.2.0-dev.1

[VERIFIED distribution] SteamCMD exited 0 and reported Committing update...Success
for the existing item. Live canonical description, title, App ID, item identity,
public visibility and unchanged supplied thumbnail match. Content update:
2026-10-16 08:20:54 UTC (October 16, 2026, 1:20:54 AM Phoenix).
Release commit: `6a385da52d40358814050b4c8ba6d9c9b66de44d`.

A fresh SteamCMD Workshop download matches all 83 committed runtime files and
required common/AnimSets/actiongroups roots. The removed Native.lua is absent.
After graceful Steam restart, the desktop subscription also matches exactly all
83 files, with no extras. The desktop update was initially pending and completed
before final verification. This is distribution evidence, not native game proof.

The registered Steam installation exited gracefully and the same verified client
started again with a hidden launch window. Restart PASS is separate from payload
parity. No force termination, game/server launch, local SP deployment or server
mutation occurred. Local receipt/provenance retain exact verification times.

Explicit publish request authorizes an MP testing update to existing Workshop
item 3820077442, App ID 108600, Mod ID B47ANCEDRooms, preserving public visibility.
This retains vanilla physical-building detection and uses player-designated
rooms exclusively. No vanilla room definitions are read. Native Outline and
Restore Vanilla are removed; old saved override geometry and permissions remain
ordinary designations. Designate rooms before building cleaning; undesignated
space is excluded. Safehouse and server authority checks remain.

Implementation checkpoint: 62de4839564ea4c1afff2c51171322286d055daa, public
repository B47ANCE/B47ANCEDRooms, feature/standalone-rooms. Release preparation
changes documentation only. Package SHA-256:
`0cf1b9b75f2857d8e952a7fc745e3e2a29901b30f9e233771e0a2749aa028f88`.
Target game 42.21.0; installed Steam build 25485521. API/protocol 1, registry
schema 2; nativeOverrides=false, designatedRooms=true and designated cleaning
scope explicitly describe the changed 0.x native-room feature contract.

Canonical inputs: docs/WORKSHOP_DESCRIPTION.md and docs/WORKSHOP_CHANGELOG.md.
Generated text: workshop/description.bbcode and workshop/changenote.txt.
Fresh stage, VDF, release manifest and local upload/verification evidence:
ignored dist/workshop-publish/0.2.0-dev.1-designated/submission. Current ZIP and
checksum: dist/current. The manifest binds commit, IDs, version, game build,
package/source/text/thumbnail hashes and evidence. Raw logs and private local
account data are never committed. The supplied Rooms thumbnail is unchanged. Committed source/package/stage hashes,
ZIP CRC/path/duplicate/case checks, real paragraph breaks, MP test labels and
linked public source/Workshop identities pass. The rendered description is 5127
UTF-8 bytes, below the documented 8000-byte bound checked on October 16, 2026:
https://partner.steamgames.com/doc/api/ISteamRemoteStorage#k_cchPublishedDocumentDescriptionMax
GitHub freshness/remote SHA and tracked/staged secret scans were verified before
public pushes and immediately before upload.

[TESTED offline Windows/Lua 5.1] Full source suite passes. Full version/artifact
checks pass. Package inventory: 83 runtime files, Lua-only; no custom Java/JAR,
host test tools or credentials. Native room API traps, legacy override reload
and edit, rejected restore/import, empty drafts/current-building filtering,
designated cleaning membership, holes/floors/overlaps, partial unload and lease
invalidation pass in disposable fixtures. Existing popup/zoom tests also pass.

Commands from repository root, using the bundled host Python:

```powershell
python tests/run_tests.py
python scripts/check_versions.py --root .
python scripts/build_dev.py
python scripts/check_versions.py --root . --release
python scripts/prepare_workshop.py --output dist/workshop-publish/0.2.0-dev.1-designated/submission
```

The initial source-only version check failed solely on the old .3 artifact.
After explicit publish authorization, its ZIP/checksum/provenance were moved
within dist to previous-current with exact SHA-256/size ledger and ZIP CRC checks.
No deletion, relabeling or historical evidence rewrite occurred. Prior ZIP hash:
`8fd3fc035f31c38996569e743584c98058a26b113ffc2d9079eac07b6f5b6087`.
Package recovery is preserved; reverse save migration is not guaranteed.

[RUNTIME GATE] Actual UI/zoom, native save/load, paired Quartermaster consumer,
client join/rejoin, synchronization, server restart and dedicated multiplayer
remain NOT TESTED. Test manual designation, no native rows, independent saved
rooms, cleaning excluding undesignated tiles, permissions and save/reload on a
disposable backup. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. Distribution does
not establish gameplay correctness. No game/server launch, local SP deployment
or server change is authorized by this publication.
