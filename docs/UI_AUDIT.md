# Rooms UI layering and confirmation audit

Project Version: 0.1.0-dev.3

Scope: client editor, owned confirmations, menu/tooltip ordering, focus, input
and teardown. User reproduction: the placement-cancel popup appears behind the
Designate Room panel; cancel/confirm show mixed styled buttons and small check/X
controls. The runtime screenshot/active renderer and exact origin of those extra
controls are not available. This is a source audit and offline fix, not in-game
acceptance. No external mod implementation was inspected or modified.

## Findings

| Finding | Evidence and response |
|---|---|
| [VERIFIED source] Confirmation ordering has no protection | Dialog.confirm added an ordinary native ISModalDialog and never set the native top-layer flag or explicitly raised it. The editor inherited ordinary focus-to-front behavior. The replacement confirmation and input shield use setAlwaysOnTop(true), with an explicit raise on opening/focus only. Editor focus redirects to its active confirmation. |
| [VERIFIED source] Confirmation ownership was absent | The dialog was not tracked or closed with the editor. An editor could close while leaving its popup/focus/callback alive. There is now one tracked dialog per owner, idempotent teardown and dead-owner callback rejection. |
| [VERIFIED source] Input remained available behind confirmations | There was no viewport blocker or editor input guard. A transparent top-layer shield consumes mouse interaction; queued editor mouse, keyboard and controller events are guarded while its confirmation is open. The shield is restricted to the relevant player's viewport. |
| [UNKNOWN runtime] Extra small check/X controls | Vanilla source alone does not establish which active runtime decoration produced the reported controls. Previous Rooms code inherited ISModalDialog and then restyled/repositioned its controls. The replacement owns its native panel and two labeled ISButtons, with no inherited modal controls/images or iconTexture. No claim is made that another mod caused the symptom. |
| [VERIFIED source] Native modal destruction had broader effects | ISModalDialog.destroy changes paused-message/game-speed UI state. The owned confirmation teardown removes only its own panel/shield/tooltips and restores valid owner focus. No gameplay or global modal state is changed. |
| [VERIFIED source] Editor opening relied on insertion order | The editor now explicitly brings itself forward once after being added. It remains an ordinary window; only its temporary confirmation/shield use the native top layer. |
| [VERIFIED source] Native context ordering must be preserved | ISContextMenu.get/getNew already raise root/submenus; onFocus explicitly warns against re-raising the root over submenus. Rooms leaves this native ordering intact. No per-frame parent raise or shared-menu top-layer patch is introduced. |
| [VERIFIED source] Tooltip paths use native hit tests/frames | Rooms delegates widget/row hit tests and occlusion to vanilla controls and preserves tooltip frames. The audit does not disable those occlusion checks or force hidden/obscured tooltips visible. |

## Implementation and invariants

Compatible PATCH-scope change; advance published checkpoint 0.1.0-dev.2 to
0.1.0-dev.3 development source. Runtime changes are limited to Editor.lua and
B47RoomsUI/Dialog.lua. Tests exercise the real dialog module instead of only
the confirmation stub in the older editor test. Existing translated labels and
theme are reused. Native panel/button/list primitives supply the UI; no custom
Java, assets or dependencies are added. UI timing, geometry and layer choices
are internal presentation details and need no gameplay sandbox setting.

Cancel, Escape and controller B dismiss the confirmation; accept is guarded for
250 ms against the opening click/press. Controller focus starts on Cancel.
Repeated opening returns the existing owner dialog. Accept/cancel callbacks run
at most once; destroying/losing an owner never invokes a stale action. Tooltips
are disposed and focus is restored only to a live, visible owner. World geometry,
room records, permissions, network/API/protocol, persistence/schema, inventory
and sandbox interpretation are unchanged. The existing zoom correction remains.

## Installed source evidence

Steam build 25485521, installed 42.21 line (project target 42.21.0). Native
ISUIElement:setAlwaysOnTop and bringToTop forward to existing UIElement methods;
vanilla SpriteModelEditor creates a modal, adds it and sets its top-layer flag.
ISModalDialog confirms the ordinary add/controls/destruction behavior;
ISPanelJoypad provides focus/navigation and selected-button A handling.
Native UIManager.update inspects isAlwaysOnTop when ordering elements. No game
code was executed, changed or copied into the mod.

- `media/lua/client/ISUI/ISUIElement.lua`: SHA-256 `2de4720f995ae35e76a1465c6690ad17fe272e33dec3b106e49c475310440f8f`.
- `media/lua/client/ISUI/ISModalDialog.lua`: SHA-256 `084d21246c03e54f8fe2a0dd16fb19f83e9ee347aa400c2d974e536f31f692dc`.
- `media/lua/client/ISUI/ISContextMenu.lua`: SHA-256 `4e4616dedbf135960dd2b7c63d67480ad19ff17352b1797cf9224631f9a669c8`.
- `media/lua/client/ISUI/ISPanelJoypad.lua`: SHA-256 `8e7a2afbe11bb826bd3a2b8e08501790adba772171fd5e747af6cc520a60f060`.
- `media/lua/client/DebugUIs/SpriteModelEditor.lua`: SHA-256 `d8ac73db6207c48c87a9a6ac0dd69d845b47678b10ea4afc86c978460bbebaad`.

The available console log was last written before the 0.1.0-dev.2 publication.
It cannot certify or diagnose the currently reported layering; no current stack
trace was assigned as this bug's cause. Raw logs/player data remain local.

## Validation and remaining gates

[TESTED offline Windows/Lua 5.1] tests/test_dialog.lua runs the real confirmation
against a native-shaped UI stack and controls. The old implementation fails the
regression; the replacement passes: top-layer ordering above a newly raised
ordinary window, exactly two labeled/no-icon controls, player viewport bounds,
input shield, repeated opens, opening-press guard, mouse/keyboard/controller
accept/cancel, focus restoration, duplicate callback prevention and owner
close/removal. Editor regression checks cover focus/input guards and exactly-once
popup teardown. All existing Rooms suites, including zoom projection, pass.
These fixtures are not native compositor, controller or split-screen proof.

Exact commands from repository root (bundled host Python):

```powershell
$roomsPython = "$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
& $roomsPython tests/run_tests.py
& $roomsPython scripts/check_versions.py --root . --json
git diff --check
```

Version checks passed before edits. All current source mirrors and the changelog
now match 0.1.0-dev.3. The full checker FAILS on the preserved 0.1.0-dev.2 ZIP
filename and embedded mod.info in dist/current. The mismatch blocks packaging /
G8; it is not a version PASS. Published reports/ZIP/provenance remain historical
and unchanged. No new build, cleanup, deployment or Workshop upload is requested.

[RUNTIME GATE] Open Designate Room with inventory/loot and another ordinary
window visible. Edit a preview and request discard/save. Verify the confirmation
stays above the designation panel, displays only the two labeled buttons and
does not allow clicks to edit the preview underneath. Cancel with mouse/Escape/B,
then reopen and confirm once. Close the editor or disconnect while a popup is
open: no orphan panel/shield/focus or stale action may remain. Repeat with
controller navigation, long text, UI scaling and another player viewport.
Native rendering/interaction and third-party decoration coexistence remain
NOT TESTED. Live viewport/font resizing while a modal is open needs native
verification. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED under the project gates.
