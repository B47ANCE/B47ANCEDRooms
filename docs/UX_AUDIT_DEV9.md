# Rooms editor UX audit — 0.2.0-dev.9

This is a source and offline-fixture audit of the current editor. It is not an in-game visual acceptance pass.

| Finding | Evidence and disposition |
| --- | --- |
| Delete was hard to discover | [VERIFIED] It existed only inside Advanced for saved rooms. Moved to the saved-room actions and relabeled **Delete Room**. It remains hidden on a blank draft, disabled when busy/stale or geometry editing is forbidden, and requires the existing confirmation and authoritative server change. [TESTED offline] Editor visibility, controller row and deletion-path regressions pass. |
| Shared UI controls were duplicated in Rooms | [VERIFIED] The editor carried its own theme, renderer, appearance, tooltip, row tooltip and controls modules. The new small provider loads B47ANCEDUI public API 1 for `B47ANCEDRooms`; those duplicate runtime modules are removed. `mod.info` declares the dependency. The Rooms-specific dialog remains because its input shield, ownership and teardown are part of the editor workflow. [TESTED offline] Paired Rooms/UI suites pass against the local UI source. |
| Sidebar becomes long for a selected room | [VERIFIED] Contextual actions and Advanced reduce initial clutter, but all saved-room actions share a 360-pixel scrolling sidebar. Delete now appears near permissions rather than below Advanced. [RUNTIME GATE] Check small viewports, large fonts, touch/controller traversal and whether action grouping needs a further layout change. |
| Name field relies on helper text and position | [VERIFIED] It has a tooltip and status/help text, but no adjacent persistent visible label. This may be unclear after switching rooms. [RUNTIME GATE] Validate with native fonts and consider a compact persistent field label if needed. |
| Delete confirmation identifies a room by ordinal | [VERIFIED] The confirmation displays its `rN` identity, which avoids ambiguity but may be less recognizable than the saved name. [RUNTIME GATE] Check localized/native dialog width before adding name plus ordinal. |
| UI dependency version at runtime | [VERIFIED] The provider checks API major version 1 and the package declares `B47ANCEDUI`; the paired offline tests used UI 0.5.0-dev.11. [RUNTIME GATE] Test actual subscribed UI load order and styling in PZ. Do not treat an offline fixture as native proof. |

No gameplay authority, save schema, network protocol or sandbox setting changed. Server-side room deletion and permission checks remain the authority. G7 dedicated multiplayer and stable G8 remain blocked until actual runtime evidence is recorded. No deployment or Workshop upload was performed.
