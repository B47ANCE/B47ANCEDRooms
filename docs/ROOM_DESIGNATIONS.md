# Room types and storage designations

Project Version: 0.2.0-dev.1

[VERIFIED SOURCE] Additive metadata extension of API/protocol 1 and registry schema 2. Rooms owns stable IDs, native aliases/overrides, complete geometry, ownership, permissions, room type and Primary/Secondary/Unassigned designation. No Quartermaster dependency, inventory mutation, category taxonomy, percentages, capacity model, presets or transfer engine is added to Rooms.

The 14 stable types are kitchen, pantry, medical, armory, workshop, garage, library, bedroom, bathroom, laundry, storage, garden, electronics and utility. Legacy records without fields remain Unassigned. `setDesignation` uses the existing authenticated, lease/revision/nonce-checked cooperative edit pipeline and repeats policy authorization before commit. Rename and split preserve metadata. Merge requires compatible type/role as well as existing ownership/policy compatibility; it does not pick an arbitrary winner. Metadata increments revisions and notifies subscribers; no designation grants gameplay access.

API capability `roomDesignations=1` adds `roomTypes()` and type/role snapshots. Capability `storageScopes=1` adds server-only `storageScopes(player, retainedPhysicalTarget)`, `storageGeometry(...)`, `storageTiles(...)`. A real server-resolved accessible target anchors consumer membership, independent of editor distance. Geometry remains bounded and exact; native holes and edited/merged aliases are preserved. No raw consumer geometry query is exposed as a network command, and caller-provided coordinates are not a target identity.

`canAccess(..., configureRoom)` is separate from configure/inspect/withdraw/deposit. Managed rooms require room-policy authority and native configuration permission throughout their loaded geometry. Native rooms require complete bounded membership and applicable parent permissions throughout, never just a bounding corner; waiting/unknown geometry fails closed. Parent/admin metadata authority never supplies private gameplay access. A stale/missing authority service must not be interpreted as permission.

The Rooms editor exposes Room Type & Storage Role on saved managed/native-override records through existing context menus. No room-type defaults are silently assigned and no inventory is moved. Quartermaster 0.9.0-dev.1 optionally owns its allocation profiles and consumes these fields; its quota/routing activation remains separately gated.

[TESTED OFFLINE] `python tests/run_tests.py`: designation permissions/stale values, metadata preservation, native aliases and holes, full native permission footprint, geometry/policies, persistence fixtures and editor/network lifecycle. Quartermaster paired tests cover real consumer APIs, configuration without contents, profile revisions and far-target membership. `python scripts/check_versions.py` and development ZIP integrity checks are separate offline gates.

[RUNTIME GATE] Native UI, disk save persistence/reconnect/restart, dedicated two-client behavior, permission changes during actual transfers and native final mutation remain NOT TESTED. G6 NOT TESTED; G7 NOT TESTED/BLOCKED; stable G8 BLOCKED. No game/server launch, installation changes, deployment, Workshop staging or publication. Previous 0.1 API/extraction records are historical evidence; original Auto Clean work in the shared checkout is excluded from this isolated feature branch.

## Authorized upstream reconciliation

The user approved reconciliation in fresh isolated worktrees. Current base d603cd53903e01b6c575f4e1efcfa6da555e4a70 includes upstream Auto Clean changes. Original allocation worktrees and patch/untracked-file hash snapshots are preserved under the sibling allocation-reconciliation directory. Incoming cleaning APIs, policy actions, UI/translation keys, tests and source inventory are retained; this allocation feature does not redesign them. Their previously published evidence remains historical.

Final metadata reconciliation base: f1f41f60e14fb6d9411203c9dfe9b6c79524b5af. Rooms Workshop ID is now 3820077442. Runtime bytes match the previously tested allocation-current worktree exactly; its development ZIP is retained for committed-source parity verification. No upload was performed by this task.
