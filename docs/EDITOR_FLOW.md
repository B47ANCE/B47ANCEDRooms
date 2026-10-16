# Contextual room editor flow

Project Version: 0.2.0-dev.3

[VERIFIED source] Compatible PATCH-scope client UI refinement of published .2. Creating a
room advances to a blank draft on the same floor; editing retains and reloads
the selected room when the actor remains authorized. Permissions/visitor changes
retain the selected room and visitor account. Deletion returns to a blank draft. Routine creation/rename uses one save action, with additional
confirmation for geometry replacement, deletion, merges/splits, incomplete or
disconnected previews and ownership/permission changes. Done protects unsaved
work. Contextual controls and a collapsed Advanced section reduce clutter;
visitor fields appear only during visitor management. No room types or storage
roles from the separate PR are integrated in this slice.

Server-owned leases/revisions, policy/geometry validation, APIs/protocol/schema,
persistence and sandbox configuration remain unchanged. Client convenience never
grants authority. No new sandbox setting is warranted for presentation controls.
No package, deployment, upload or game/server launch is authorized by this task.

[TESTED offline Windows/Lua 5.1] Full source suite PASS. Actual registry writes
exercise consecutive new rooms and rename without a modal, with stable distinct
IDs and selected reload. Simulated transport exercises permission updates with
visitor context retained, bounded 500 ms read-only retries for up to 10 seconds
after admission denial, and manual Reload Rooms after failed reads. Writes are
never retried by that read mechanism. Overlays pause during pending reads/writes.
Busy input controls cannot change geometry or text during a write. In-progress
detection blocks Save; manual preview edits cancel outstanding detection.
Disposable UI fixtures check hidden controls excluded from controller rows,
Advanced collapse removing empty rows, dirty Done/Escape protection and reviewed
destructive/incomplete changes. Existing source/authority, geometry, permissions,
cleaning, migration, localization, case, zoom/popup and network suites pass.

Exact commands from repository root:

```powershell
$roomsPython = "$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
& $roomsPython tests/run_tests.py
& $roomsPython scripts/check_versions.py --root . --json
git diff --check
```

The version checker passes all declared current source mirrors but fails the
unchanged published .2 ZIP filename and embedded mod.info against .3. This blocks
release artifact checks; no package was rebuilt, relabeled or deleted.

[VERIFIED source] Installed Steam build 25485521, game target 42.21.0: native
ISTextEntryBox:setEditable and focus/unfocus are present at lines 64 and 146-150. Native
ISPanelJoypad:insertNewLineOfButtons/restoreJoypadFocus provide controller rows.
The mod reuses these and existing owned layout/focus primitives; no engine file
is modified. Source SHA-256:

- media/lua/client/ISUI/ISTextEntryBox.lua: `94d10e1583f68bcba635cd93f7921df85be4d8223ca8a99c67e00c650bf5d3e1`.
- media/lua/client/ISUI/ISPanelJoypad.lua: `8e7a2afbe11bb826bd3a2b8e08501790adba772171fd5e747af6cc520a60f060`.

[RUNTIME GATE] Test create Kitchen then Pantry without a popup; edit Kitchen's
name and confirm it stays selected; review/cancel a boundary replacement and
deletion; open ownership/visitor controls, save a grant and retain the selected
room/account; verify Advanced collapse and Done/Escape unsaved protection with
mouse, controller, small viewport and larger UI fonts. Test rejection, delayed
acknowledgements, disconnect/close and two-client edits on disposable saves.
Actual native UI/controller/focus and dedicated G7 remain
NOT TESTED/BLOCKED; stable G8 BLOCKED. Existing published .2 artifacts and its
publication record retain their original hashes/evidence.
