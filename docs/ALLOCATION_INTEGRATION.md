# Designation PR reconciliation — 2026-10-17

Project Version: 0.2.0-dev.8

Compatible PATCH test/documentation checkpoint from 0.2.0-dev.5 main
fade0a0bf34c4cda6de0c1fd663c6d32eb17ef97. The old PR #2 head
f9a31f2ed542c4e0974b9c4d5e6e48858ceaa38c is reconciled through merge ancestry,
with the newer runtime retained. Its 14 types, roles and allocation APIs are
already implemented in current main for designated UUIDs. This merge does not
restore vanilla room overrides, native aliases as active identities or an old
editor/registry. Runtime changes are version metadata only.

General API/protocol remain 1, registry schema 2, roomDesignations/storageScopes 1,
policyCopy 1 and nativeOverrides=false. Retain current creation/editing, outlines,
floor groups, overlap choices, dirty drafts/conflict recovery, search, permission
copying, cleaning and safehouse boundaries. No new sandbox option is needed for
test/documentation reconciliation. Existing server options remain authoritative.

New tests/test_allocation_contract.lua checks complete-footprint native configure
denial, unloaded geometry, disabled/client provider, copied geometry/metadata,
and rejection of retired native identities. Existing tests cover exact far-target
storage membership, CAS, policy separation, editor and cleaning behavior.
Paired consumer Quartermaster 0.18.0-dev.1 tests use this actual provider and verify
that omitted retired nativeRooms metadata is accepted without weakening malformed
provider checks. No allocation enforcement or live routing is activated.

```powershell
python -B tests/run_tests.py
python -B scripts/check_versions.py
git -c core.safecrlf=false diff --check
# From the paired Quartermaster root, with Lupa 2.6:
python -u -B tests/run_tests.py --require-rooms --rooms ../Rooms
```

These are offline Windows/Lua 5.1 fixtures and source checks. Prior Workshop
publication records remain historical at their actual versions. Native UI,
serialization, save/reload, joins/rejoins and dedicated restart NOT TESTED for this
checkpoint. G7 and stable G8 BLOCKED. No package/upload/deployment/game/server launch.
