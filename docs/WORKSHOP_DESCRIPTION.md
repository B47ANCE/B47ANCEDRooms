# B47ANCE'd Rooms

## Overview
Room designation and server-owned room permissions for Project Zomboid Build 42.21.0. Requires B47ANCEDUI for the editor; Quartermaster remains optional.

Version 0.2.0-dev.9.

MP testing build - dedicated multiplayer NOT TESTED

Paint/Erase mouse drags preview and apply the filled rectangle once on release, with one undo step. This dev.8 source change awaits native visual and multiplayer testing.

Save & Next creates a room and starts the next blank draft on the same floor. Save Changes retains and reloads the selected room. Done protects unsaved work. Select a saved room to see Delete Room; deletion still requires confirmation and server permission. Routine create/rename uses one save action; incomplete and permission/ownership operations retain confirmation. Advanced operations are collapsed, and visitor fields appear only while managing visitors.

Development 0.2 uses only player-designated rooms within vanilla-detected buildings. Vanilla room definitions, Native Outline and Restore Vanilla are removed; existing overrides keep their saved geometry and permissions as ordinary designations. Building cleaning covers designated tiles only.

Fixes confirmation ordering and consistent button presentation. Confirmations use two labeled buttons above the Rooms editor and block clicks through to the preview. Native popup acceptance remains pending.

Fixes room outlines drifting instead of scaling when zooming. Outlines now follow the player camera and zoom; native visual acceptance remains pending.

Room Type and Storage Role add 14 room labels plus Primary, Secondary or Unassigned organization metadata. Save choices with the room. Existing rooms default to Unassigned. Select Room picks loaded saved outlines without drawing; overlapping rooms offer a choice. The building list groups actual floors, shows type/role and prioritizes active-floor overlays. Other rooms remain available through the list.

These labels do not move items, set quotas or allocate storage automatically. Consumer routing integration remains untested.

Live server-change updates protect dirty drafts and offer explicit conflict recovery. Search and combine room type, storage role and floor filters. Read saved permission summaries and copy rules between authorized rooms, choosing whether to replace visitor grants. Optionally repeat the last saved type/role for consecutive rooms. Save and Done stay in a fixed footer while details scroll. Native acceptance remains pending.

## Features
- Designate rooms from the world context menu using explicit structural previews, rectangles, paint/erase and explicit floors. Preview, name, undo/redo, merge/split, then confirm changes.
- Empty initial drafts and saved designations for the current physical building.
- Independent room registry, ownership, delegated safehouse boundaries and separate permissions for supported consumer actions, including cleaning.
- Server-owned designated-room cleaning scopes within the vanilla physical building and validated settings for cooperating consumers. Rooms itself does not fetch supplies or clean the world.
- Data-only migration of legacy Quartermaster custom rooms into the independent Rooms registry, preserving original recovery data.

## Compatibility & Requirements
Mod ID: B47ANCEDRooms. Workshop ID: 3820077442. Lua-only runtime; no custom Java/JAR dependency. Requires Build 42.21.0 or a compatible later build; other builds have not been verified. No other mod is required by Rooms.

For Clean Building, subscribe to and enable both Rooms and B47ANCE'd Quartermaster on the server and every client. Quartermaster 0.8.0-dev.1 consumes Rooms API 1 with cleaning capability 1. Its existing right-click Clean Building command fetches eligible supplies, adds 10 mL bleach by default before filling the remaining bucket capacity with water, uses supported native blood/grime cleaning, then returns borrowed supplies when permitted.

[url=https://steamcommunity.com/sharedfiles/filedetails/?id=3807217050]Quartermaster on Steam Workshop[/url]

Designate rooms before cleaning; undesignated building areas are excluded. Consumers of native room IDs must switch to designated UUIDs. Current paired Quartermaster integration has not been retested. Single-player Clean Building is disabled in Quartermaster. Other Rooms UI, real persistence, listen-server and dedicated acceptance remain NOT TESTED. Offline fixtures do not prove game behavior. Back up saves and use matching intended versions on all peers.

## Configuration
Use server sandbox settings in the B47ANCE'd Rooms group. Room configuration and permissions are server-authoritative. Cleaning settings cover enable, borrowing, return, bleach dose (default 10 mL), building tile limit and logistics timing. Changes invalidate active consumer scope leases.

Safehouse metadata ownership does not automatically bypass private gameplay permissions. Assigned room owners can manage supported names, visitors and actions within the server's policy.

## Source Code & Development
GitHub: https://github.com/B47ANCE/B47ANCEDRooms

Current API/protocol 1 (nativeOverrides=false, designatedRooms=true), cleaning capability 1 with designated-room scope and room registry schema 2 are independent of the project version. No stable-release readiness claim is made. Dedicated G7 remains BLOCKED / NOT TESTED; stable-release G8 BLOCKED.

## Known Issues
Policies apply at supported mod integration checks. They do not lock unrelated vanilla transfers, entry, doors, building or destruction, and do not intercept every final vanilla mutation.

Quartermaster Clean Building uses finite pure-water sources and supported equipment. Native floor cleaning can affect neighboring squares across levels, so its conservative scope guard may skip many or all targets. Cancellation can leave borrowed supplies carried. Cleaning jobs do not resume after reconnect/restart. Native packet processing can interrupt an earlier action before Lua confirmation; this engine limitation is not fixed by the Lua guard. Ashes, graffiti and arbitrary dirt are outside this feature.

Legacy records are imported without deleting Quartermaster recovery data. Removing Rooms does not export later independent edits back into the legacy data. Test migrations and save/reload on disposable backups first. Subscription/download agreement, native synchronization, reconnect and dedicated restart tests remain pending.

## Credits & Permissions
Developed by B47ANCE'd Workshop. Original standalone Lua implementation. Existing project artwork is preserved. No third-party mod source or assets are bundled. Vanilla APIs remain owned by the game.
