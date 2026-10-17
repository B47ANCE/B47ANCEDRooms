# Rooms workflow completion and validation

Project Version: 0.2.0-dev.6

Compatible MINOR-scope additions in the unreleased 0.2 line, from dev.4 to dev.5;
expected eventual release 0.2.0 remains subject to runtime/release gates. Source
identity, Mod ID, Workshop item, API/protocol 1 and save schema 2 are unchanged.
This iteration implements the four recommended workflow improvements. It does
not claim native UI, save serialization or dedicated multiplayer acceptance.

## Implemented behavior

| Request | Implemented result |
|---|---|
| Live updates | Open editors subscribe to authoritative revision notifications, coalesce them for 250 ms and refresh clean state. Busy reads/writes, drawing/detection and confirmations defer automatic refresh. Closing unsubscribes. |
| Conflict recovery | Dirty drafts remain intact and display a saved-changes notice. Reload checks the room revision; unrelated changes can advance the library snapshot safely. Changed/deleted rooms block Save and expose explicit refresh, confirmed discard/reload, or confirmed recovery as a new room. No automatic overwrite or three-way merge. |
| Search/filters | Plain case-insensitive name/type/role search with 150 ms debounce. Combine type, storage role and all/current/explicit-floor filters. Clear resets search and filters. Counts report unique rooms. Filtered current-floor overlays retain the selected room even outside results. |
| Permission summary | Selected rooms show assigned owner or creator, Shared/Private mode and active/suspended state. Expand for six rules, server-returned actor room-policy results and visitor count. Snapshot results do not replace native access checks or grant an action. |
| Repeated setup | Optional Repeat last saved type/role is off by default and lasts only for this editor session. Successful creates supply the next blank draft's labels. That blank draft is not dirty solely because labels repeat. No ownership/policy is copied. |
| Copy permissions | Source snapshot preview plus confirmation displays the resulting mode. Rules-only preserves target visitor grants; the explicit alternative replaces grants. The server validates source and destination authority, revisions, native access and final target policy. Names, geometry, IDs, labels and assignment remain unchanged. |
| Primary actions | Save/Done stay in a fixed footer outside the scrolling sidebar. Font-scaled row/summary spacing and footer geometry respond to viewport/font changes. Existing confirmation shield covers the whole editor. |

Automatic list refreshes never replace dirty text, geometry or labels when input
arrives while a read is in flight. Overlapping selected-room reads trigger a
fresh recheck. Read failures expose Reload Rooms; automatic retry attempts are
paced at one second within a ten-second notification window. No write is retried
automatically. Stale generations and dead-owner callbacks remain ignored.

Recover as new preserves the draft name, geometry and type/role; it copies no
ownership or permissions and performs no write until Save & Next. Compound
merge/split drafts cannot use this recovery shortcut. Their saved data stays
unchanged until an explicitly validated server operation completes.

## Authority and API audit

[VERIFIED source] `API.capabilities().policyCopy=1` advertises
`API.copyPolicy(player,args)`, or `roomChange` action `copyPolicy`. Required fields
include target `id`/`roomRevision`, source `sourceId`/`sourceRevision`, explicit
boolean `copyVisitors` and the usual lease, registry revision and nonce. Source
and destination must be distinct designated rooms. Submitted policy data cannot
replace the server-selected source policy in this operation.

Source metadata authority and editor proximity are validated at admission and
on each cooperative job slice. Both rooms' loaded tiles undergo the existing
native interaction/loot/range/safehouse checks. The source validation uses a
temporary descriptor, never edits the source record, and participates in the
same bounded job budget. Library revisions bind both source and target;
concurrent edits reject atomically. Private target assignment, parent bounds,
membership, overlap and DelegatedRooms setting are checked before commit.
Source metadata rights never grant gameplay access to its storage.

Queued ordinary policy mutations now also recheck policy-management authority;
a parent change after admission cannot downgrade a suspended private policy to
shared using a previously accepted request. Disabling delegated policies before
commit rejects a pending private policy. Replay, cancellation, disconnect,
expiration, join reads and change notifications reuse the existing transport.

`roomGet` adds ephemeral `policyState` (shared/active/suspended) and `roomActions`
(allow/deny/unknown for discover, inspect, withdraw, deposit, configure and clean).
They describe the room-policy layer for the authenticated actor at read time.
Native rules remain an independent requirement. These fields are not persisted.
Source snapshots/previews are not grants or reservations.
List metadata adds the actor's canConfigureRoom flag without exposing ownership
or policy details. The copy picker omits known unmanageable sources and disables
the action when no other manageable source is available. The server still checks
both records again; a UI flag is not authority.

| State | Owner / lifetime |
|---|---|
| Saved geometry, labels, policy, assignment | Server ModData schema 2, existing atomic replacement |
| Copy source/revision, nonce, lease, job | Server transient validation state; no restart resumption |
| Search, filters, expanded summary, repeat preference | Local editor presentation, discarded on close |
| Draft, conflict notice, cached snapshots | Local intent/presentation; cannot authorize shared writes |

No new sandbox option is appropriate: copied policy and labels are explicit
per-room server state, and existing authoritative settings apply. Search,
filters, repeated entry choices, footer geometry and debounce/cache/retry limits
are local presentation or technical safety details. No user-edited Lua rule or
hidden shared gameplay configuration is introduced. All runtime remains Lua-only.

No persistent schema migration is needed. Existing missing labels still default
to Unassigned without read-time rewrites; copied policies serialize in the
existing validated fields. Disposable reload fixtures preserve source/target
state. Native serialization/reconnect/restart evidence remains unavailable.
Older writers can drop newer label fields; back up saves and use matching builds.

Rooms' storage scopes, labels and permission APIs are implemented for cooperating
consumers. Automatic item allocation, quotas, inventory transfers and actual
cleaning execution belong to the consumer. This Rooms-only request does not
modify Quartermaster, third-party mods or native game files. No unsupported
interception of unrelated vanilla transfers, entry, doors or destruction is
claimed. Existing limitations are recorded in ROOMS_API.md and CLEANING_API.md.

## Offline evidence and remaining completion gates

[TESTED offline Windows/Lua 5.1] Full source suite PASS, including
`test_policy_copy.lua` and the editor-hosted `test_workflow.lua`. New coverage:
both-room authorization, source revision mismatch, native source denial, retained
versus replaced visitor grants, unchanged source/identity/geometry, queued parent
revocation, setting revocation, replay, network payloads, snapshot suspension and
reload; clean live refresh, dirty input during in-flight reads, unrelated-room
updates, deletion, confirmed draft copy/reload, plain search and combined filters,
saved policy summary, preview-before-copy, repeated blank drafts, bounded retry,
listener teardown and fixed-footer/large-font geometry. Existing geometry,
detection, migration, cleaning, modal/zoom and headless transport suites pass.

[VERIFIED installed source] Steam build 25485521, target 42.21.0. Existing native
ISPanelJoypad, context-menu, text-entry and scrolling-list primitives are reused.
Native doDrawItem uses fontHgt/item.height (ISScrollingListBox.lua 304-325);
the editor keeps these consistent when font metrics change. Source hashes and
API evidence remain in EDITOR_FLOW.md, ROOM_DESIGNATIONS.md and UI_AUDIT.md.
No new engine method or custom Java bridge is required.

Exact commands from repository root:

```powershell
$roomsPython = "$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
& $roomsPython tests/run_tests.py
& $roomsPython scripts/check_versions.py --root . --json
git -c core.safecrlf=false diff --check
```

The source-only checkpoint 65ad9d8 was blocked solely by the prior published
dev.2 ZIP. A subsequent explicit publish request authorized preserving the old
ZIP/checksum/provenance and building dev.5. Full current source/artifact version,
offline and ZIP integrity checks now PASS. WORKSHOP_WORKFLOW_PUBLICATION.md
records distribution status separately from native acceptance. No local SP
deployment, game/server launch, server change or artifact deletion is included.

[RUNTIME GATE] Required native acceptance on disposable saves:

1. Create Kitchen/Primary then Pantry/Secondary, with Repeat off and on. Verify
   Save/Done remain visible at small viewport and larger font settings.
2. Select overlapping outlines at several zooms/floors; search/filter/clear;
   inspect list/summary tooltips with inventory and another ordinary window open.
   Confirm discard/save popups stay above all editor controls with two buttons.
3. Use two clients: edit a clean selected room from the other client, then repeat
   with a dirty local draft. Test keep, refresh, discard/reload and recover-as-new,
   including remote deletion. No draft may disappear without confirmation.
4. As parent, delegate and guest, copy rules and then visitor grants. Test stale
   source revisions, native denial, source membership removal while pending,
   private overlap and settings revocation. No unauthorized copy may commit.
5. Save/reload, join/rejoin and restart a dedicated server; verify geometry,
   labels, ownership and copied policies. Close/disconnect during reads, writes
   and popups. Confirm no stale callbacks, duplicated mutations or orphan UI.
6. Separately validate a cooperating consumer's current action checks, routing
   interpretation and persistence before claiming cross-mod integration works.

Actual native UI/input, real saves and dedicated multiplayer are NOT TESTED.
G7 BLOCKED / NOT TESTED; stable-release G8 BLOCKED. Implemented source and offline
fixtures do not turn these gates into PASS. Workshop test distribution requires
its own explicit publish authorization and all applicable offline/package gates.
