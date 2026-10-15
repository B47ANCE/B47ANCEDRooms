dofile(TEST_ROOT..'/fixtures/world.lua')
local f=CONTAINER_FIXTURE;f.network(false,true)
local A=require 'B47ANCEDRooms/API';local P=B47ANCEDRooms.Policy
local function def(z) return {getIDString=function() return 'cleaning-room-'..z end,getName=function() return 'Room '..z end,getZ=function() return z end,
 getX=function() return 0 end,getY=function() return 0 end,getX2=function() return 2 end,getY2=function() return 2 end} end
local lower,upper=def(0),def(1)
local bd={getRooms=function() return f.list({lower,upper}) end};local b={getDef=function() return bd end}
for z=0,1 do for x=0,1 do for y=0,1 do
 local sq=f.squares[x..','..y..','..z] or f.square(x,y,z)
 local d=z==0 and lower or upper;local hole=x==1 and y==1
 sq.getRoomDef=function() return not hole and d or nil end;sq.building=b
end end end
local other={isDead=function() return false end,getCurrentSquare=function() return f.player:getCurrentSquare() end,getUsername=function() return 'guest' end}
local players={f.player,other};getOnlinePlayers=function() return f.list(players) end
local defaults=A.cleaningOptions()
assert(defaults.enabled and defaults.borrow and defaults.returns and defaults.bleachML==10 and defaults.tileLimit==4096)
SandboxVars.B47ANCEDRooms.CleaningBleachML=0/0;assert(A.cleaningOptions().bleachML==10)
SandboxVars.B47ANCEDRooms.CleaningBleachML=200;assert(A.cleaningOptions().bleachML==100)
SandboxVars.B47ANCEDRooms.CleaningBleachML=nil
assert(A.capabilities().cleaning==1 and A.capabilities().boundaries.cleaning and not A.capabilities().boundaries.vanillaFinalMutation)
local begin=A.beginCleaningBuilding(f.player);assert(begin.status=='waiting')
local key=begin.scope;local result
for _=1,30 do result=A.readCleaningBuilding(f.player,key);if result.status~='waiting' then break end;f.advance(16) end
assert(result.status=='ok' and #result.tiles==6)
assert(A.containsCleaningBuildingTile(f.player,key,0,0,1) and not A.containsCleaningBuildingTile(f.player,key,1,1,1))
assert(A.canCleanBuildingTile(f.player,key,0,0,1).state=='allow')
assert(A.canCleanBuildingTile(other,key,0,0,0).state=='unknown' and not A.endCleaningBuilding(other,key))
assert(A.beginCleaningBuilding(other).status=='busy','two consumers claimed the same building')
result.tiles[1].x=999;assert(A.containsCleaningBuildingTile(f.player,key,0,0,0),'mutable snapshot changed authority')
local interact=true;SafeHouse.isSafehouseAllowInteract=function() return interact end
interact=false;assert(A.canAccessAt(f.player,0,0,0,'withdraw').state=='allow' and A.canCleanBuildingTile(f.player,key,0,0,0).state=='deny');interact=true
SandboxVars.B47ANCEDRooms.CleaningBleachML=11
assert(A.validateCleaningBuilding(f.player,key).status=='CleaningSettingsChanged')
assert(A.endCleaningBuilding(f.player,key));SandboxVars.B47ANCEDRooms.CleaningBleachML=nil
local members={contains=function(_,who) return who=='guest' end}
local house={getId=function() return 'house' end,getOwner=function() return 'fixture-player' end,getPlayers=function() return members end,
 getX=function() return 0 end,getY=function() return 0 end,getX2=function() return 10 end,getY2=function() return 10 end}
SafeHouse.getSafehouseList=function() return f.list({house}) end
local room={safehouse='house',parentOwner='fixture-player',parentBounds={0,0,10,10},assigned='fixture-player',policy={mode='private',rules={},grants={}}}
assert(P.storage(f.player,room,'clean') and not P.storage(other,room,'clean'))
room.policy.grants.guest={clean=true,withdraw=false}
assert(P.valid(room.policy) and P.storage(other,room,'clean') and not P.storage(other,room,'withdraw'))
SafeHouse.getSafehouseList=function() return f.list({}) end
begin=A.beginCleaningBuilding(f.player);assert(begin.status=='waiting')
players={other};A.cleaningTick();local guest=A.beginCleaningBuilding(other);assert(guest.status=='waiting')
assert(not A.endCleaningBuilding(other,'unknown'))
players={f.player};A.cleaningTick();begin=A.beginCleaningBuilding(f.player);assert(begin.status=='waiting')
f.advance(1800000);A.cleaningTick();assert(A.beginCleaningBuilding(f.player).status=='waiting')
f.network(true,false);assert(A.beginCleaningBuilding(f.player).status=='CleaningUnavailable')
print('PASS OFFLINE Rooms cleaning: multi-floor native scope/hole membership, independent clean policy, native interact gate, owner binding, building claims, copied snapshots, defaults/bounds, setting revocation, expiry/disconnect and client denial')
