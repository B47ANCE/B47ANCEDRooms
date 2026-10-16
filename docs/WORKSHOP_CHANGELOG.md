# Version 0.2.0-dev.1

MP testing build - dedicated multiplayer NOT TESTED

Use player-designated rooms only. Keep vanilla building detection; remove vanilla room definitions, native outline/import and Restore Vanilla. Start designation with an empty draft and list saved rooms in the current building. Detect Walls remains an explicit preview tool.

Existing saved overrides retain their geometry, UUIDs, ownership and permissions as ordinary designations. Native aliases are inert recovery metadata; old native-ID consumers must switch to designated UUIDs. Retired restore requests cannot delete rooms.

Cleaning scopes now cover designated tiles within the selected physical building. Undesignated areas are excluded; an empty building requires room designation. Safehouse and server authority checks remain.

Offline source tests pass. Actual native UI/save-load, paired consumer integration and dedicated multiplayer remain NOT TESTED. G7 and stable G8 BLOCKED. This text is prepared for a future authorized upload; the live Workshop item remains 0.1.0-dev.3.
