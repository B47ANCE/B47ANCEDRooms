# Changelog

## [0.1.0-dev.3]
- [VERIFIED distribution] Existing Workshop item 3820077442 updated successfully; live canonical description, identity and public visibility verified. Fresh download and desktop subscription match all 84 runtime files. Steam restarted gracefully. Offline/version/package checks PASS; native UI and dedicated acceptance remain NOT TESTED. See docs/WORKSHOP_UI_PUBLICATION.md.
- Explicitly authorized Workshop UI testing update: preserve the prior 0.1.0-dev.2 package/provenance with hashes, validate current packaging and update existing item 3820077442 without changing visibility. No gameplay changes or runtime verification are implied.
- UI audit following the reported placement-cancel popup appearing behind the designation panel with mixed controls. Compatible PATCH-scope fix; next development checkpoint, with no gameplay/API/protocol/schema/configuration changes.
- Construct Rooms confirmations from a plain native panel with exactly two Rooms-styled labeled buttons. Use the native top UI layer and a viewport input shield; do not inherit native modal controls or game-speed destruction effects.
- Track one confirmation per owner; prevent editor focus/input from escaping the popup and remove popup/shield safely on cancel, accept, owner close or removal. Raise the editor once on opening; leave native menus/tooltips ordering intact.
- [TESTED offline Windows/Lua 5.1] Actual confirmation module and full Rooms suite PASS. Native layering/mixed-control reproduction remains NOT TESTED; origin of the reported extra check/X controls is UNKNOWN without runtime evidence. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.
- Historical source-fix checkpoint 8924b9f: no package, deployment or upload occurred during the UI audit; the prior current ZIP blocked packaging checks until subsequent explicit publish authorization.

## [0.1.0-dev.2]
- Compatible visual bug fix (PATCH scope; next development checkpoint): UI outlines now use native player-specific zoom/camera/viewport projections instead of the world-render line helper. Saved/draft/split/overlap outlines, invalid marks and drag rectangles share the corrected path. No API, protocol, sandbox, save or authority changes.
- Explicitly authorized Workshop MP testing update: preserve prior package/provenance with hashes, reconcile current packaging, and publish to the existing item without changing visibility. Native visual acceptance and dedicated G7 remain NOT TESTED; stable G8 BLOCKED.
- [VERIFIED distribution] SteamCMD committed the existing item update; live canonical description/identity/visibility and fresh 84-file download parity pass. Steam desktop restarted gracefully and its subscribed payload matched the same 84 runtime files. Full version/package checks PASS. Distribution is not native rendering or MP proof; see docs/WORKSHOP_OUTLINE_PUBLICATION.md.
- [TESTED offline Windows/Lua 5.1] Projection regression fails on the previous renderer and passes with the fix; the complete Rooms suite passes. Native zoom/pan rendering NOT TESTED. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.
- Historical source-fix checkpoint f0d4857: source iteration only; the preserved old ZIP in dist/current blocked version checks before subsequent publish authorization. No packaging, deployment, game/server launch or Workshop upload occurred during that source fix.

## [0.1.0-dev.1]
- First authorized Workshop testing distribution of this existing development checkpoint. Add canonical Workshop text and explicit Lua-only staging/provenance checks; assigned item identity is recorded after Steam allocation. Gameplay/API/schema and authority are unchanged. G7 NOT TESTED / BLOCKED; stable G8 BLOCKED.
- Offline cleaning consumer integration: distinct delegated clean permission, native building-scope leases and server cleaning options. Native/dedicated acceptance NOT TESTED; no deployment or publication.
- Initial standalone Lua-only extraction: bounded geometry/detection, independent editor/registry/network/API, native overrides/restore and delegated ownership/action policies.
- Separate schema-2 room persistence with data-only Quartermaster schema-1 import; preserve room IDs, revisions, creators and original recovery section.
- Server-validated safehouse hierarchy, private overlap rejection, boundary approval, action grants and stale-parent fail-closed checks. No parent/admin automatic gameplay bypass.
- Standalone/offline regressions cover edits, permissions, migration, native aliases, UI lifecycle and headless transport. Native UI/persistence/dedicated G7 NOT TESTED; stable G8 BLOCKED. Development artifacts only; no deployment/publication.
