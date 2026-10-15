# Changelog

## [0.1.0-dev.2]
- Compatible visual bug fix (PATCH scope; next development checkpoint): UI outlines now use native player-specific zoom/camera/viewport projections instead of the world-render line helper. Saved/draft/split/overlap outlines, invalid marks and drag rectangles share the corrected path. No API, protocol, sandbox, save or authority changes.
- [TESTED offline Windows/Lua 5.1] Projection regression fails on the previous renderer and passes with the fix; the complete Rooms suite passes. Native zoom/pan rendering NOT TESTED. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.
- Source iteration only. Historical 0.1.0-dev.1 publication evidence and generated artifacts remain unchanged; the old ZIP in dist/current fails current-version packaging checks until separately authorized reconciliation/build. No packaging, deployment, game/server launch or Workshop upload.

## [0.1.0-dev.1]
- First authorized Workshop testing distribution of this existing development checkpoint. Add canonical Workshop text and explicit Lua-only staging/provenance checks; assigned item identity is recorded after Steam allocation. Gameplay/API/schema and authority are unchanged. G7 NOT TESTED / BLOCKED; stable G8 BLOCKED.
- Offline cleaning consumer integration: distinct delegated clean permission, native building-scope leases and server cleaning options. Native/dedicated acceptance NOT TESTED; no deployment or publication.
- Initial standalone Lua-only extraction: bounded geometry/detection, independent editor/registry/network/API, native overrides/restore and delegated ownership/action policies.
- Separate schema-2 room persistence with data-only Quartermaster schema-1 import; preserve room IDs, revisions, creators and original recovery section.
- Server-validated safehouse hierarchy, private overlap rejection, boundary approval, action grants and stale-parent fail-closed checks. No parent/admin automatic gameplay bypass.
- Standalone/offline regressions cover edits, permissions, migration, native aliases, UI lifecycle and headless transport. Native UI/persistence/dedicated G7 NOT TESTED; stable G8 BLOCKED. Development artifacts only; no deployment/publication.
