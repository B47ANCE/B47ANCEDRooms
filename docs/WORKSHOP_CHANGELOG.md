# Version 0.2.0-dev.10

Client transport now initializes during the client Lua phase, after shared APIs. Required UI dependency and server-owned room state are unchanged. Native client and dedicated multiplayer acceptance remain pending.

The selected saved room now has a visible Delete Room button with confirmation. The editor uses B47ANCEDUI client API 1, now a required dependency, instead of carrying a duplicate UI toolkit.

MP testing build - dedicated multiplayer NOT TESTED

Paint/Erase mouse drags now apply the entire outlined rectangle on release as one undoable edit. Single clicks and controller single-tile edits remain. Draft geometry is no longer rebuilt on every crossed tile during a drag.

Offline source and editor regressions pass. Native UI responsiveness and dedicated multiplayer for this iteration remain NOT TESTED. This is a Workshop testing build, not a stable-release validation.
