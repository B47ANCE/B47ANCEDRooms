local I=require 'B47ANCEDRooms/Identity'
local D=require 'B47ANCEDRooms/Detection'
local N={};B47ANCEDRooms.Native=N
local cache={};local count=0;local reads=setmetatable({},{__mode='k'})
local function remember(def,square)
 if not def or not def.getIDString then return end
 local key=def:getIDString();if type(key)~='string' or #key<1 or #key>160 or key:find('%c') then return end
 local id='native:'..key
 if not cache[id] then count=count+1;if count>256 then cache={};count=1 end end
 cache[id]={id=id,def=def,square=square,name=def:getName(),z=def:getZ(),x=def:getX(),y=def:getY(),revision=0,native=true}
 return cache[id]
end
function N.list(player)
 if isClient() or not player then return {} end
 local square=player:getCurrentSquare();if not square then return {} end
 local out={};local building=square:getBuilding();local defs=building and building:getDef():getRooms()
 if defs and defs:size()<=128 then for n=0,defs:size()-1 do
  local def=defs:get(n);local seed=getCell():getGridSquare(def:getX(),def:getY(),def:getZ())
  local r=remember(def,seed);if r then out[#out+1]={id=r.id,name=r.name,label=r.name,revision=0,native=true,x=r.x,y=r.y,z=r.z} end
 end end
 local current=square.getRoomDef and square:getRoomDef() or square.getRoom and square:getRoom() and square:getRoom():getRoomDef()
 if current then
  local r=remember(current,square)
  if r then local found=false;for _,m in ipairs(out) do if m.id==r.id then found=true end end
   if not found then out[#out+1]={id=r.id,name=r.name,label=r.name,revision=0,native=true,x=r.x,y=r.y,z=r.z} end
  end
 end
 return out
end
function N.resolve(player,id)
 if isClient() or type(id)~='string' then return end
 N.list(player);local r=cache[id];if not r then return end
 local sq=player:getCurrentSquare();local b=sq and sq:getBuilding();local defs=b and b:getDef():getRooms()
 if sq and sq:getZ()==r.z and sq.getRoomDef and sq:getRoomDef()==r.def then return r end
 if defs and defs:size()<=128 then for n=0,defs:size()-1 do if defs:get(n)==r.def then return r end end end
end
function N.contains(player,id,x,y,z)
 local r=N.resolve(player,id);local sq=r and getCell():getGridSquare(x,y,z)
 return sq and sq:getRoomDef()==r.def or false
end
function N.snapshot(player,id,limit)
 local r=N.resolve(player,id);if not r then return {status='RoomUnavailable'} end
 local j=reads[player]
 if j and j.id~=id and not j.job.done then return {status='busy'} end
 if not j or j.id~=id then
  local active=0;for _,job in pairs(reads) do if not job.job.done then active=active+1 end end
  if active>=16 then return {status='busy'} end
  local w,h=r.def:getX2()-r.x,r.def:getY2()-r.y
  if w<1 or h<1 or w>128 or h>128 then return {status='RoomTooLarge'} end
  -- Use the detector's bounded native scan without searching for a non-hole
  -- corner synchronously. Exact membership is checked in every scan step.
  local job={native=r.def,bounds={x=r.x,y=r.y,z=r.z,width=w,height=h},index=1,tiles={},limit=limit}
  j={id=id,job=job,time=getTimestampMs()};reads[player]=j
 end
 D.step(j.job)
 if not j.job.done then return {status='waiting'} end
 if j.job.incomplete or not j.job.geometry then return {status=j.job.incomplete or 'RoomGeometryInvalid'} end
 return {status='ok',room={name=r.name,rows=I.copy(j.job.geometry.rows),nativeId=id,native=true,revision=0}}
end
function N.cleanup(player) reads[player]=nil end
if Events and Events.OnTick then Events.OnTick.Add(function()
 if isClient() then return end
 local deadline=getTimestampMs()+4;local work=0
 for player,j in pairs(reads) do
  if getTimestampMs()-j.time>30000 then reads[player]=nil
  elseif not j.job.done and work<4 and getTimestampMs()<deadline then D.step(j.job);work=work+1 end
 end
end) end
return N
