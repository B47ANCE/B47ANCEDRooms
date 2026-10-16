# Version 0.2.0-dev.2

MP testing build - dedicated multiplayer NOT TESTED

Keep Designate Room open after a successful server-confirmed save. Refresh the saved-room list and start a blank draft on the same floor, ready for the next room. Close the window yourself when finished.

Immediate and polled save acknowledgements use the same flow. Rejected saves preserve the draft; stale replies cannot overwrite the next room's refreshed list, lease or overlays. Room geometry, permissions, server authority and save/API formats are unchanged.

Offline source tests pass, including consecutive distinct room saves in one window. Actual UI and dedicated multiplayer remain NOT TESTED; G7 and stable G8 BLOCKED. Prepared development notes only: this UI request does not upload anything. The live Workshop item remains 0.2.0-dev.1.
