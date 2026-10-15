# Version 0.1.0-dev.3

MP testing build - dedicated multiplayer NOT TESTED

Workshop testing update for in-game popup and button validation.

Fix confirmation popups appearing behind the Rooms editor. Confirmations use a top-layer native panel with two Rooms-styled labeled buttons and a viewport input shield. Cancel/Escape/controller B return to the editor; closing the editor also removes its popup. Only one confirmation can belong to an editor at a time.

Offline Lua 5.1 regressions cover popup ordering, controls, click-through prevention, duplicate requests, confirmation arming, focus restoration, owner teardown and the previous zoom-outline behavior. Actual game rendering and the reported extra-icon origin remain unverified.

Dedicated G7 and stable G8 remain BLOCKED. Published 0.1.0-dev.2 evidence and artifacts are preserved. Room geometry, permissions, persistence and the server API are unchanged.

Upload/download success is distribution evidence only. No local SP deployment or game/server launch is included.
