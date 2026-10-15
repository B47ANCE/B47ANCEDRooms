# Changelog

## [0.2.0-dev.1]
- Add server-owned room types and Primary/Secondary/Unassigned metadata through the existing revision/permission-checked editor and API. Preserve roles/types on rename/split and require compatible metadata on merge.
- Add target-anchored server consumer membership/geometry APIs independent of editor range, preserving exact native holes and aliases. Room configuration checks complete native/managed parent permissions. No allocation, taxonomy or inventory engine belongs to Rooms.
- Offline standalone and paired consumer regressions PASS; native G6/dedicated G7 NOT TESTED, stable G8 BLOCKED. Development packages only; no deployment/publication.

## [0.1.0-dev.1]
- First authorized Workshop testing distribution of this existing development checkpoint. Add canonical Workshop text and explicit Lua-only staging/provenance checks; assigned item identity is recorded after Steam allocation. Gameplay/API/schema and authority are unchanged. G7 NOT TESTED / BLOCKED; stable G8 BLOCKED.
- Offline cleaning consumer integration: distinct delegated clean permission, native building-scope leases and server cleaning options. Native/dedicated acceptance NOT TESTED; no deployment or publication.
- Initial standalone Lua-only extraction: bounded geometry/detection, independent editor/registry/network/API, native overrides/restore and delegated ownership/action policies.
- Separate schema-2 room persistence with data-only Quartermaster schema-1 import; preserve room IDs, revisions, creators and original recovery section.
- Server-validated safehouse hierarchy, private overlap rejection, boundary approval, action grants and stale-parent fail-closed checks. No parent/admin automatic gameplay bypass.
- Standalone/offline regressions cover edits, permissions, migration, native aliases, UI lifecycle and headless transport. Native UI/persistence/dedicated G7 NOT TESTED; stable G8 BLOCKED. Development artifacts only; no deployment/publication.
