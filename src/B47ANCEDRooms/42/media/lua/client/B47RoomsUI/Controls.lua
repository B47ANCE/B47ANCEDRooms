-- Rooms owns room behavior; B47ANCEDUI owns the client presentation primitives.
local API=require 'B47ANCEDUI/API'
B47RoomsUI=API.requireVersion(1).forMod('B47ANCEDRooms',{legacyAppearancePrefix='B47ANCEDRoomsAppearance'})
return B47RoomsUI
