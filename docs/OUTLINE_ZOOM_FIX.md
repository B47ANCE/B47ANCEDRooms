# Room outline zoom correction

Project Version: 0.1.0-dev.2

## Diagnosis and compatibility

User report: scrolling in/out moves the room outlines instead of scaling them
with the world. [VERIFIED source] Editor.prerender called renderIsoLine for all
cached edge layers, invalid-tile crosses and the current rectangle. The installed
engine helper projects into world-buffer coordinates, then calls LineDrawer;
it does not divide by camera zoom or add the player's screen viewport origin.
Calling it during UI rendering therefore uses the wrong coordinate space.

[VERIFIED installed source/native inspection] Steam build 25485521. Core's
gameVersion initializer identifies 42.21 (project compatibility target 42.21.0).
The native isoToScreenX/Y(playerNum,x,y,z) globals use that player's camera,
model-alignment adjustment, zoom division and screen-left/top offsets. Vanilla
Foraging/ISBaseIcon.lua uses these globals for world-anchored UI positions.
ISUIElement.drawLineAbsolute converts absolute screen endpoints into panel-local
coordinates and delegates to the vanilla UI DrawLine path.

Evidence fingerprints (installed inputs, not copied engine source):

- `media/lua/client/Foraging/ISBaseIcon.lua` lines 167-176: SHA-256 `45f675dced22f046de7d3236133550c330e9b54820e161b9aa4892e49ff1e2ab`.
- `media/lua/client/ISUI/ISUIElement.lua` lines 1235-1251: SHA-256 `2de4720f995ae35e76a1465c6690ad17fe272e33dec3b106e49c475310440f8f`.
- `projectzomboid.jar!zombie/Lua/LuaManager$GlobalObject.class`: SHA-256 `80ecbd3bd702db2f992db6cba7cb09c32d775fa6f2a3297e0460874ff5ba20c7`; inspected renderIsoLine and isoToScreenX/Y bytecode without executing game code.

The compatible visual bug fix has PATCH scope and advances the existing
development checkpoint from 0.1.0-dev.1 to 0.1.0-dev.2. Editor.drawWorldLine now
projects both endpoints using the native UI globals on each draw. World-space
geometry remains cached; projected endpoints are never cached. UI line thickness
stays readable in screen pixels. All existing edge layers, invalid marks and
rectangle previews use the same path.

This change is client presentation only: no gameplay/server API, custom network
message, ownership rule, persistence/schema, protocol or sandbox option changed.
Projection and line thickness are implementation details, not gameplay settings.
No third-party source or assets were used. No engine files were modified and no
custom Java or other runtime dependency was introduced.

## Validation and remaining gates

[TESTED offline Windows/Lua 5.1] The updated test_editor.lua fails against the
old renderer when the UI calls the world-render line helper. With the correction,
numeric endpoint checks pass at zoom 0.5, 2 and 1.35, moving camera offsets and
player 0/1/3 viewports. The same cached edges remain in use. The test includes
saved/add/remove/overlap/split layers, an elevated floor, fractional invalid-tile
crosses and a rectangle preview; rendering leaves the registry unmodified.
The complete Rooms suite also passes. These are simulated engine surfaces,
not actual game rendering or split-screen acceptance.

Commands from repository root, using the bundled host Python:

```powershell
$roomsPython = "$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
& $roomsPython tests/run_tests.py
& $roomsPython scripts/check_versions.py --root . --json
git diff --check
```

The version checker passed before edits. After edits all declared source mirrors
and the new changelog entry match 0.1.0-dev.2. The full checker deliberately FAILS
on the unchanged historical 0.1.0-dev.1 ZIP filename and its embedded mod.info
under dist/current. It must remain a blocking packaging mismatch, not a warning
or a claimed version PASS. That published ZIP and adjacent provenance/checksum
files were not rebuilt, relabeled, moved or deleted. The publication report is
classified historical, and its evidence remains tied to the original version.
No current-version package exists. Packaging/reconciliation requires separate
authorization; stable G8 remains BLOCKED.

[RUNTIME GATE] Open the Rooms editor over a known room. Zoom fully in/out and
through intermediate levels while stationary, walking and panning. Confirm saved
boundaries, draft additions/removals, overlaps, split previews, invalid marks and
drag rectangles remain attached to the same floor tiles. Repeat upstairs and
for another local player's viewport if used. Native rendering NOT TESTED for
this iteration. Dedicated G7 remains BLOCKED / NOT TESTED and stable G8 BLOCKED;
the project's stricter gates are retained even for this local presentation fix.
No game/server launch, packaging, deployment or Workshop publication occurred.
