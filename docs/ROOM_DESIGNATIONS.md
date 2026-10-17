# Room types, storage roles and navigation

Project Version: 0.2.0-dev.5

[VERIFIED source] MINOR-scope compatible feature additions within the existing
unreleased 0.2 line: 0.2.0-dev.3 to 0.2.0-dev.5; expected eventual release 0.2.0
subject to all gates. General API 1, protocol 1 and registry schema 2 remain.
The earlier team-owned designation PR #2 at f9a31f2 supplied the planned catalog
and API shape. This implementation adapts those concepts to designated UUIDs
only; it does not merge that branch or restore vanilla room definitions.

## Using the editor

- Draw a new room, enter its name, use the type/storage button to choose labels,
  then Save & Next. The next blank room starts with Unassigned labels unless the local
  Repeat last saved type/role toggle is enabled for this editor session.
- Select Room enters a dedicated selection mode. Mouse click or controller A
  selects a loaded saved outline without painting. Names under the cursor appear
  in the sidebar. Overlaps open an explicit choice; selecting another room or
  Done protects unsaved geometry, names and designation edits.
- The current building's list groups rooms by each floor actually present in
  their saved rows. The active floor comes first. Multi-floor rooms appear in
  each applicable group; selecting a row switches to that floor. Floor headers
  navigate without discarding the draft. Labels include type/role, with full
  text and tile count in mouse tooltips. Long labels fit the available width.
- Choose type and storage role for a selected room, then Save Changes. These
  are draft edits, not immediate writes. Duplicate retains labels; split copies
  them; merge requires matching type/role as well as compatible permissions.
  Save designation changes before attempting split/merge or a boundary request.

Overlay work is bounded to eight current-floor rooms plus the selected room.
Other rooms remain selectable through the list. Outline selection uses only
cached saved geometry; it does not guess from bounds.
No per-frame world scan is added. Cached shapes are reused, and refresh/floor
generations reject stale replies. Selection reloads the authoritative record;
a cached outline is never permission or persistence proof.

## Stable metadata and API

Types: `kitchen`, `pantry`, `medical`, `armory`, `workshop`, `garage`, `library`,
`bedroom`, `bathroom`, `laundry`, `storage`, `garden`, `electronics`, `utility`.
The absence/default is `unassigned`. Roles are `unassigned`, `primary`,
`secondary`. Type and role are independent labels. They define no item categories,
percentages, capacities, quotas, automatic allocation, transfers or cleaning
priority. Primary/Secondary interpretation belongs to a cooperating consumer.
Quartermaster is neither modified nor integration-tested by this iteration.

Capabilities include `roomDesignations=1`, `storageScopes=1` and `policyCopy=1`.
Current live/conflict/search/summary/repeated-entry and permission-copy behavior
is documented in WORKFLOW_COMPLETION.md. Authoritative APIs:

- `roomTypes()`: detached stable type and role lists.
- `setDesignation(player,args)`: normal leased/revisioned `designation` mutation;
  uses `roomType`/`designation`, defaulting omitted fields to Unassigned.
- `create`/`rename`/`editGeometry` (`save`) accept those optional fields. Existing
  callers that omit them preserve saved labels; new rooms default to Unassigned.
- `canAccess(player,id,'configureRoom')`: metadata privilege plus native configure
  checks on all loaded room tiles, bounded to 8 ms; unknown must fail closed.
- `resolveRoom`, `geometry`, `listRooms`, `permissions` include type/role defaults.
  List metadata adds exact `floors`; permission/edit snapshots include
  `canConfigureRoom`. No vanilla aliases or private ownership details are added
  to the public list.
- `storageScopes(player,target)`: server-only query using `target.obj:getSquare()`
  and current deposit permission; returns every matching designated room,
  sorted by UUID, with type/role and registry revision. Empty is valid.
- `storageGeometry(player,id,revision,target)` and `storageTiles(...)`: target
  must belong to that designated room and pass current deposit permission;
  stale revisions conflict. They deliberately do not use editor proximity.
  These are metadata/geometry queries, not reservations or transfer grants.
  Consumers must enforce their own action permissions and revalidate before
  final mutation. Overlapping organizational scopes are explicit, not resolved
  arbitrarily. Native IDs never resolve.

## Authority, persistence and configuration assessment

[VERIFIED source] Clients submit labels alongside ordinary edit intent. Registry
validates enum values, actor ownership/parent policy privilege, lease, nonce,
world/library/room revisions, current native permissions and loaded geometry.
Existing-record label changes require policy-management privilege. A queued
designation rechecks that privilege before each validation slice and commit;
changing parent state cannot retain stale assigned-owner authority. A guest
configure grant for storage does not grant room metadata ownership.
Atomic server replacement, changed notifications, replay/cancel/disconnect
handling and authoritative roomGet/list reads use the existing transport.
No client owns shared metadata, and no new custom network channel is added.

Fields live on existing schema-2 records in server ModData.customRooms. Missing
fields read as Unassigned without read-time rewrites. Compatible writes preserve
labels; invalid saved enums fail closed without resetting data. No destructive
migration occurs. Real native serialization, joins/rejoins and restart behavior
remain runtime gates. Use matching builds and back up saves: downgrade to older
writers is unsupported because they may discard the added fields.

No new sandbox setting is warranted: types/roles are explicit server-validated
per-room state, not a hidden gameplay rule. Existing authoritative Enabled,
geometry/range and delegated-policy options still apply. Eight-overlay cache,
read pacing, layout and API deadlines are technical presentation/safety limits,
not server gameplay configuration. English fallback keys cover all 29 installed
UI dictionaries; this is not a claim of human translation.

## Evidence and required tests

[TESTED offline Windows/Lua 5.1] `tests/run_tests.py` passes registry, permission,
designation, migration, editor, dialog, network, detection and cleaning suites.
Coverage includes missing/invalid saved fields, read purity, catalog copies,
create/rename/split/merge/reload, mismatched merge rejection, native/client/guest
denial, target queries outside editor range, queued authority revocation,
transported labels, exact multi-floor list groups, current-floor fetch priority,
stale floor replies, overlap choice, mouse/controller selection without painting,
dirty designation protection, clipping/full tooltip and type/role menu choices.
Disposable fixtures are not native save or MP evidence.

[VERIFIED source] Installed Steam build 25485521 / target 42.21.0, native
`media/lua/client/ISUI/ISScrollingListBox.lua` doDrawItem lines 304-325 uses
item.text/item.height; the editor preserves native row painting and fits text.
SHA-256: `380d222414d16ab40b830abe9d016f49f1fd2d07d0067a5879db22f89e5c796b`.
Existing native context menus, text inputs and projection APIs are reused.

Exact repository-root commands:

```powershell
$roomsPython = "$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
& $roomsPython tests/run_tests.py
& $roomsPython scripts/check_versions.py --root . --json
git -c core.safecrlf=false diff --check
```

Following explicit publish authorization, the old .2 ZIP/checksum/provenance
are preserved and current .5 source/artifact version and ZIP checks PASS. See
WORKSHOP_WORKFLOW_PUBLICATION.md. No local SP deployment, game/server launch,
server change or artifact deletion is included; native acceptance remains open.

[RUNTIME GATE] On disposable saves: create Kitchen/Primary and Pantry/Secondary;
save/reload and reconnect/restart; select outlines at different zooms/floors;
resolve overlap choices; verify controller, tooltip layering, small viewport and
larger fonts; cancel a dirty selection; test parent/delegate/guest, native denial,
membership removal during a queued write, simultaneous edits and late replies.
Actual native UI/save/load and dedicated multiplayer remain NOT TESTED.
G7 BLOCKED / NOT TESTED; stable-release G8 BLOCKED. No stable tag is authorized.
