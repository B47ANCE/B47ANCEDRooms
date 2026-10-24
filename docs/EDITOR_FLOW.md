# Contextual room editor flow

Project Version: 0.2.0-dev.9

[VERIFIED source] Delete Room is visible for a selected saved room without expanding Advanced. It is disabled for a busy or stale editor or a room without geometry-edit permission; the existing confirmation and server-side revision/permission validation are unchanged. The editor now obtains shared controls/theme/layout/tooltips through B47ANCEDUI client API 1 while retaining its Rooms-specific confirmation behavior. [TESTED offline] Paired Rooms/UI source fixtures pass. [RUNTIME GATE] Native sizing, focus, appearance and dedicated multiplayer remain untested for this iteration. See UX_AUDIT_DEV9.md.

[VERIFIED source] Paint and Erase mouse drags preview the filled rectangle, then apply it once on mouse-up. A click still edits one tile, and controller A still edits the cursor tile. One drag creates one undo step and no client-side shared-state write; Save retains the established server request and validation path. This replaces per-tile draft rebuilds on every mouse move. Draft edits also reuse normalized row runs rather than expanding and sorting the entire geometry multiple times; the server's existing geometry validator is unchanged. [TESTED offline] Editor fixture covers enclosed tiles, preview stability, single undo, click and cancelled drag. Geometry fixtures compare row-for-row against the original edit algorithm. A local Lua 5.1 benchmark of 20 single-tile erases in a 4,096-tile room measured 39.02 ms/edit before and 13.22 ms/edit after for geometry processing only. [RUNTIME GATE] Native lag/visual/controller and dedicated multiplayer acceptance remain untested.

[VERIFIED source] Current .5 extends the .3 contextual editor and .4 designation/navigation work with compatible feature additions; see ROOM_DESIGNATIONS.md for the MINOR-scope rationale, API/persistence details and current evidence. Creating a
room advances to a blank draft on the same floor; editing retains and reloads
the selected room when the actor remains authorized. Permissions/visitor changes
retain the selected room and visitor account. Deletion returns to a blank draft. Routine creation/rename uses one save action, with additional
confirmation for geometry replacement, deletion, merges/splits, incomplete or
disconnected previews and ownership/permission changes. Done protects unsaved
work. Contextual controls and a collapsed Advanced section reduce clutter;
visitor fields appear only during visitor management. Select Room uses loaded saved
geometry with overlap choices and no drawing; names under the cursor appear in
the sidebar. The list groups actual saved floors, shows type/storage role and
prioritizes the active floor. Type and Primary/Secondary/Unassigned choices are
draft metadata committed by the existing Save action. Duplicate retains them;
split copies them and merge requires matching values. Dirty selection/Done
protection includes these fields. Eight current-floor overlays plus the selected
room bound caching and reads; use the list for other saved rooms. Search and filters
narrow the list/current-floor overlays without dropping the selected room. The
optional repeat toggle retains only the last successful create's labels for this
session. Save/Done are fixed below the scrolling body. Summary row spacing scales
with font metrics. WORKFLOW_COMPLETION.md records current completion and tests.

Server-owned leases/revisions and policy/geometry validation remain authoritative.
API/protocol 1 and schema 2 retain their numbers; new optional metadata fields,
designation and target-anchored storage APIs are documented in ROOM_DESIGNATIONS.md.
Sandbox configuration is unchanged; per-room metadata is explicit server state. Client convenience never
grants authority. No new sandbox setting is warranted for presentation controls.
Live revision notifications refresh clean editors and protect dirty drafts,
including input arriving during list reads. Stale saved rooms block Save until
explicit refresh, discard/reload or recovery as a new room. Copy Permissions
previews source mode and confirms preserving/replacing visitor grants. The server
validates both records and rechecks queued authority; no client snapshot grants
access. The later explicit publish request authorizes Workshop test distribution;
local deployment and game/server launch remain outside this workflow.

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

The source-only checkpoint was blocked by the prior .2 ZIP. The later explicit
publish request authorized preserving it and building .5; current source/artifact
version and ZIP checks PASS. See WORKSHOP_WORKFLOW_PUBLICATION.md for distribution
status. Historical packages/evidence are unchanged; native gates remain open.

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
mouse, controller, small viewport and larger UI fonts. Also test outline overlap selection, floor switching, label tooltips and type/role persistence through save/reload/rejoin/restart. Test rejection, delayed
acknowledgements, disconnect/close and two-client edits on disposable saves.
Actual native UI/controller/focus and dedicated G7 remain
NOT TESTED/BLOCKED; stable G8 BLOCKED. Existing published .2 artifacts and its
publication record retain their original hashes/evidence.
