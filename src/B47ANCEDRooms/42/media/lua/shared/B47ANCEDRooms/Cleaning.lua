-- Rooms owns cleaning permission and physical building membership, never inventory.
local I=require 'B47ANCEDRooms/Identity'
local R=require 'B47ANCEDRooms/Registry'
local G=require 'B47ANCEDRooms/Geometry'
return function(A)
 local jobs=setmetatable({},{__mode='k'})
 local claims=setmetatable({},{__mode='k'})
 local function connected(player)
  if not player or player:isDead() then return false end
  if not isServer() then return not isClient() end
  if type(getOnlinePlayers)~='function' then return false end
  local players=getOnlinePlayers();if players:size()>1024 then return false end
  for n=0,players:size()-1 do if players:get(n)==player then return true end end
  return false
 end
 local function release(player,j)
  jobs[player]=nil;if claims[j.building]==j then claims[j.building]=nil end
 end
 local function bounded(key,default,lo,hi)
  local n=I.option(key,default)
  if type(n)~='number' or n~=n or n~=math.floor(n) then return default end
  return math.max(lo,math.min(hi,n))
 end
 function A.cleaningOptions()
  return {enabled=R.options().enabled and I.option('CleanBuildingEnabled',true)==true,
   borrow=I.option('CleaningBorrowSupplies',true)==true,returns=I.option('CleaningReturnSupplies',true)==true,
   bleachML=bounded('CleaningBleachML',10,1,100),tileLimit=bounded('CleaningBuildingTileLimit',4096,128,16384),
   transferSeconds=bounded('CleaningTransferSeconds',1,1,10)}
 end
 local function current(player,key)
  local j=jobs[player]
  if isClient() or not j or j.key~=key or not connected(player) or not A.cleaningOptions().enabled then return nil,'CleaningUnavailable' end
  if getTimestampMs()-j.time>=1800000 then release(player,j);return nil,'CleaningExpired' end
  if not I.equal(j.options,A.cleaningOptions()) then return nil,'CleaningSettingsChanged' end
  local lib=R.library();local sq=player:getCurrentSquare();local b=sq and sq:getBuilding()
  if not lib or lib.revision~=j.revision or not b or b:getDef()~=j.building then return nil,'CleaningScopeChanged' end
  return j
 end
 function A.beginCleaningBuilding(player)
  if isClient() or not connected(player) or not A.cleaningOptions().enabled then return {status='CleaningUnavailable'} end
  local sq=player:getCurrentSquare();local b=sq and sq:getBuilding();local lib,e=R.library()
  if not b or not lib then return {status=e or 'CleaningNoBuilding'} end
  local old=jobs[player]
  if old and getTimestampMs()-old.time<1800000 then return {status='busy'} end
  local claim=claims[b:getDef()]
  if claim and getTimestampMs()-claim.time<1800000 and not claim.actor:isDead() then return {status='busy'} end
  local key=getRandomUUID()
  local rooms={};for _,room in pairs(lib.records) do rooms[#rooms+1]=room end
  jobs[player]={key=key,actor=player,building=b:getDef(),revision=lib.revision,time=getTimestampMs(),rooms=rooms,index=1,tileIndex=1,roomUnloaded=false,roomMatches=false,tiles={},members={},limit=A.cleaningOptions().tileLimit,options=A.cleaningOptions()}
  claims[b:getDef()]=jobs[player]
  return {status='waiting',scope=key}
 end
 function A.readCleaningBuilding(player,key)
  local j,e=current(player,key);if not j then return {status=e} end
  if j.failed then return {status=j.failed} end
  if not j.done then
   -- Inspect only persisted designated geometry, never vanilla room definitions.
   -- Membership still comes from the engine's current physical building.
   local start=getTimestampMs();local work=0
   while j.index<=#j.rooms and work<64 and getTimestampMs()-start<4 do
    local geometry=R.geometry(j.rooms[j.index]);local p=geometry.tiles[j.tileIndex]
    if p then
     work=work+1;j.tileIndex=j.tileIndex+1
     local sq=getCell():getGridSquare(p.x,p.y,p.z);local b=sq and sq:getBuilding()
     if not sq then j.roomUnloaded=true end
     if b and b:getDef()==j.building then
      j.roomMatches=true;local k=G.key(p.x,p.y,p.z)
      if not j.members[k] then
       if #j.tiles>=j.limit then j.failed='CleaningBuildingTooLarge';return {status=j.failed} end
       j.members[k]=true;j.tiles[#j.tiles+1]={x=p.x,y=p.y,z=p.z}
      end
     end
    else
     if j.roomMatches then
      -- A partially loaded matching designation must not become a partial scope.
      if j.roomUnloaded then j.failed='CleaningUnloaded';return {status=j.failed} end
     end
     j.index=j.index+1;j.tileIndex=1;j.roomUnloaded=false;j.roomMatches=false
    end
   end
   if j.index<=#j.rooms then return {status='waiting'} end
   if #j.tiles==0 then j.failed='CleaningNoDesignatedRooms';return {status=j.failed} end
   j.done=true;j.rooms=nil
   table.sort(j.tiles,function(a,b) if a.z~=b.z then return a.z<b.z end;if a.y~=b.y then return a.y<b.y end;return a.x<b.x end)
  end
  return {status='ok',scope=j.key,revision=j.revision,tiles=I.copy(j.tiles),options=I.copy(j.options)}
 end
 function A.validateCleaningBuilding(player,key)
  local j,e=current(player,key)
  return {status=j and j.done and not j.failed and 'ok' or e or j and j.failed or 'waiting'}
 end
 function A.canCleanBuildingTile(player,key,x,y,z)
  local j,e=current(player,key)
  if not j or not j.done or j.failed or not G.integer(x) or not G.integer(y) or not G.integer(z)
   or not j.members[G.key(x,y,z)] then return {state='unknown',reason=e or 'CleaningOutsideScope'} end
  local sq=getCell():getGridSquare(x,y,z);local b=sq and sq:getBuilding()
  if not b or b:getDef()~=j.building then return {state='unknown',reason='CleaningUnloaded'} end
  return A.canAccessAt(player,x,y,z,'clean')
 end
 function A.containsCleaningBuildingTile(player,key,x,y,z)
  local j=current(player,key)
  if not j or not j.done or j.failed or not G.integer(x) or not G.integer(y) or not G.integer(z) or not j.members[G.key(x,y,z)] then return false end
  local sq=getCell():getGridSquare(x,y,z);local b=sq and sq:getBuilding()
  return b and b:getDef()==j.building or false
 end
 function A.endCleaningBuilding(player,key)
  if isClient() then return false end
  local j=jobs[player];if not j or j.key~=key then return false end
  release(player,j);return true
 end
 function A.cleaningTick()
  if isClient() then return end
  for player,j in pairs(jobs) do if not connected(player) or getTimestampMs()-j.time>=1800000 then release(player,j) end end
 end
 if Events and Events.OnTick then Events.OnTick.Add(A.cleaningTick) end
end
