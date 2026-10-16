dofile(TEST_ROOT..'/fixtures/world.lua')
local f=CONTAINER_FIXTURE;f.network(false,true)
local A=require 'B47ANCEDRooms/API';local P=B47ANCEDRooms.Policy
local bd={getRooms=function() error('cleaning enumerated vanilla rooms') end};local b={getDef=function() return bd end}
local foreign={getDef=function() return {} end}
for z=0,1 do for x=0,2 do for y=0,1 do
 local sq=f.squares[x..','..y..','..z] or f.square(x,y,z)
 sq.getRoomDef=function() error('cleaning read a vanilla room definition') end;sq.building=b
end end end
f.square(3,0,0,foreign)
local R=B47ANCEDRooms.Registry
local world='11111111-1111-1111-1111-111111111111'
local function record(n,rows)
 local id=world..':22222222-2222-2222-2222-'..string.format('%012d',n)
 return id,{id=id,ordinal=n,name='Designated '..n,owner='fixture-player',revision=1,rows=rows,createdAt=1,updatedAt=1}
end
local function install()
 local records={}
 local id,r=record(1,{{0,0,0,1},{0,1,0,0},{1,0,0,1},{1,1,0,0}});records[id]=r
 id,r=record(2,{{0,0,0,0}});records[id]=r -- overlap is deduplicated
 id,r=record(3,{{0,0,3,3}});records[id]=r -- another physical building
 ModData.getOrCreate('B47ANCEDRooms').customRooms={schema=2,world=world,revision=1,serial=3,records=records}
end
local function complete(actor,key)
 for _=1,100 do local r=A.readCleaningBuilding(actor,key);if r.status~='waiting' then return r end;f.advance(16) end
 error('designated scope scan stalled')
end
local other={isDead=function() return false end,getCurrentSquare=function() return f.player:getCurrentSquare() end,getUsername=function() return 'guest' end}
local players={f.player,other};getOnlinePlayers=function() return f.list(players) end
local empty=A.beginCleaningBuilding(f.player);assert(empty.status=='waiting')
assert(complete(f.player,empty.scope).status=='CleaningNoDesignatedRooms')
assert(A.endCleaningBuilding(f.player,empty.scope));install()
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
assert(not A.containsCleaningBuildingTile(f.player,key,2,0,0),'undesignated building space was included')
assert(not A.containsCleaningBuildingTile(f.player,key,3,0,0),'foreign building designation was included')
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
-- Changed designation invalidates an old scope; partial selected geometry fails closed.
local active=A.beginCleaningBuilding(f.player);assert(active.status=='busy')
f.advance(1800000);A.cleaningTick();active=A.beginCleaningBuilding(f.player)
local data=ModData.getOrCreate('B47ANCEDRooms');data.customRooms.revision=data.customRooms.revision+1
assert(A.validateCleaningBuilding(f.player,active.scope).status=='CleaningScopeChanged')
assert(A.endCleaningBuilding(f.player,active.scope))
local square=f.squares['1,0,0'];f.squares['1,0,0']=nil
active=A.beginCleaningBuilding(f.player);assert(complete(f.player,active.scope).status=='CleaningUnloaded')
assert(A.endCleaningBuilding(f.player,active.scope));f.squares['1,0,0']=square
-- A large designation remains cooperative and over-limit scopes never truncate.
for x=0,127 do for y=0,1 do f.square(x,y,0,b) end end
local largeId,large=record(1,{{0,0,0,127},{0,1,0,127}})
data.customRooms={schema=2,world=world,revision=3,serial=1,records={[largeId]=large}}
SandboxVars.B47ANCEDRooms.CleaningBuildingTileLimit=128
active=A.beginCleaningBuilding(f.player)
local original=getCell().getGridSquare;local reads=0
getCell().getGridSquare=function(...) reads=reads+1;return original(...) end
assert(A.readCleaningBuilding(f.player,active.scope).status=='waiting' and reads<=64,'scope scan exceeded its per-read work budget')
getCell().getGridSquare=original
assert(complete(f.player,active.scope).status=='CleaningBuildingTooLarge')
assert(not A.containsCleaningBuildingTile(f.player,active.scope,0,0,0),'failed scope granted partial membership')
assert(A.endCleaningBuilding(f.player,active.scope))
f.network(true,false);assert(A.beginCleaningBuilding(f.player).status=='CleaningUnavailable')
print('PASS OFFLINE Rooms cleaning: designated multi-floor scopes/holes, empty building, no vanilla room definitions, deduplication and foreign-building exclusion, independent clean policy, native interact gate, owner binding, building claims, copied snapshots, defaults/bounds, setting revocation, expiry/disconnect and client denial')
