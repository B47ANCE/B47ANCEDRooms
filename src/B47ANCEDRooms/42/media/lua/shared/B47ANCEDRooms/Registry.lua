-- Server-owned logical regions. Never mutate vanilla geometry or container data.
local I=require 'B47ANCEDRooms/Identity'
local G=require 'B47ANCEDRooms/Geometry'
local P=require 'B47ANCEDRooms/Policy'
local Import=require 'B47ANCEDRooms/LegacyImport'
local R={jobs=setmetatable({},{__mode='k'})};B47ANCEDRooms.Registry=R
local checked=setmetatable({},{__mode='k'});local shapes=setmetatable({},{__mode='k'})
local tickets=setmetatable({},{__mode='k'});local ticketSerial=0
local function geometry(room)
 local g=shapes[room];if not g then g=G.normalize(room.rows);if g then shapes[room]=g end end
 return g
end
local function integer(n) return type(n)=='number' and n==n and n>=0 and n<2^53 and n==math.floor(n) end
local owner=I.account
local admin=P.admin
local function name(s)
 if type(s)~='string' or #s>192 then return end
 s=s:match('^%s*(.-)%s*$')
 if #s<1 or #s>96 or s:find('%c') or s:find('[<>]') then return end
 return s
end
function R.options()
 local max=tonumber((I.option('RoomTileLimit'))) or 1024
 if not G.integer(max) then max=1024 end
 local distance=tonumber((I.option('RoomEditRange'))) or 30
 if not G.integer(distance) then distance=30 end
 local enabled=I.option('Enabled')
 return {enabled=enabled==nil or enabled==true,maxTiles=math.max(64,math.min(G.tileLimit,max)),
  range=math.max(5,math.min(128,distance)),doorways=I.option('RoomDoorways')~=false}
end
local function library()
 if isClient() then return nil,'invalid' end
 local data=ModData.getOrCreate('B47ANCEDRooms');local lib=data.customRooms;local importStamp
 if not lib then local imported,stamp=Import.read();if imported then lib=imported;importStamp=stamp elseif stamp then return nil,stamp end end
 if lib==nil then return {schema=2,revision=0,serial=0,records={}},data end
 if type(lib)~='table' or lib.schema~=2 or not integer(lib.revision) or not integer(lib.serial) or lib.serial>=10000000 or type(lib.records)~='table' then return nil,'schema' end
 if type(lib.world)~='string' or #lib.world~=36 or not lib.world:match('^[%x%-]+$') then return nil,'schema' end
 if checked[lib] then return lib,data end
 local n,total=0,0;local ordinals,aliases={},{}
 for id,room in pairs(lib.records) do
  if type(id)~='string' or #id~=73 or id:sub(1,37)~=lib.world..':' or not id:sub(38):match('^[%x%-]+$') or type(room)~='table' or room.id~=id
   or not name(room.name) or type(room.owner)~='string' or #room.owner<1 or #room.owner>256
   or not integer(room.revision) or not integer(room.createdAt) or not integer(room.updatedAt)
   or (room.safehouse~=nil and (type(room.safehouse)~='string' or #room.safehouse>256)) then return nil,'schema' end
  if not integer(room.ordinal) or room.ordinal<1 or room.ordinal>lib.serial then return nil,'schema' end
  if ordinals[room.ordinal] then return nil,'schema' end;ordinals[room.ordinal]=true
  if not G.array(I.aliases(room),128) then return nil,'schema' end
  for _,alias in ipairs(I.aliases(room)) do
   if type(alias)~='string' or #alias>180 or alias:sub(1,7)~='native:' or aliases[alias] then return nil,'schema' end;aliases[alias]=true
  end
  local g=geometry(room);if not g or g.count<1 then return nil,'schema' end
  if room.policy and not P.valid(room.policy) or room.assigned~=nil and (type(room.assigned)~='string' or #room.assigned>256)
   or room.pendingBoundary and not G.normalize(room.pendingBoundary) then return nil,'schema' end
  n=n+1;total=total+g.count;if n>128 or total>16384 then return nil,'schema' end
 end
 checked[lib]=true
 if importStamp then data.customRooms=lib;data.imported=importStamp end
 return lib,data
end
local house=P.house
local houseMember=P.member
local function member(player,room) return P.edit(player,room,'rename') end
local function nearby(player,g)
 local sq=player:getCurrentSquare();local b=g.bounds;if not sq or not b then return false end
 local range=R.options().range
 return sq:getX()>=b.x1-range and sq:getX()<=b.x2+range and sq:getY()>=b.y1-range and sq:getY()<=b.y2+range
end
local function copyRoom(room,player)
 local out=I.copy(room);out.nativeId=nil;out.nativeIds=nil
 out.canEditGeometry=P.edit(player,room,'geometry');out.canAssign=P.edit(player,room,'assignOwner');out.canRelinquish=room.assigned==owner(player)
 if out.canAssign then local h=house(room.safehouse);out.parentMembers={}
  if h and h:getPlayers():size()<=256 then
   out.parentMembers[1]=h:getOwner();for n=0,h:getPlayers():size()-1 do local who=h:getPlayers():get(n);if who~=h:getOwner() then out.parentMembers[#out.parentMembers+1]=who end end
  end
 end
 return out
end
function R.resolve(player,id,revision)
 if not R.options().enabled then return nil,'RoomDisabled' end
 if type(id)~='string' or #id~=73 then return nil,'RoomDenied' end
 local lib,e=library();if not lib then return nil,e end
 local room=type(id)=='string' and lib.records[id]
 if not room or not member(player,room) then return nil,'RoomDenied' end
 if revision~=nil and room.revision~=revision then return nil,'conflict' end
 local g=geometry(room)
 if not nearby(player,g) then return nil,'RoomOutOfRange' end
 return room,g
end
function R.contains(player,id,revision,x,y,z)
 local room,g=R.resolve(player,id,revision);return room and G.contains(g,x,y,z) or false
end
function R.metadata(player)
 local lib,e=library();if not lib then return nil,e end
 local out={}
 if not R.options().enabled then return out,lib.revision end
 for id,room in pairs(lib.records) do
  if member(player,room) then local g=geometry(room)
   if nearby(player,g) then out[#out+1]={id=id,name=room.name,label=room.name..' [r'..room.ordinal..']',revision=room.revision,count=g.count,bounds=g.bounds} end
  end
 end
 table.sort(out,function(a,b) return a.id<b.id end)
 return out,lib.revision,lib.world
end
local function currentPermission(player,sq)
 if not sq then return false,'RoomUnloaded' end
 if (isClient() or isServer()) and (not SafeHouse or not SafeHouse.isSafehouseAllowInteract
  or not SafeHouse.isSafehouseAllowInteract(sq,player) or not SafeHouse.isSafehouseAllowLoot(sq,player)) then return false,'RoomDenied' end
 return true
end
local fields={protocol=true,request=true,id=true,roomRevision=true,revision=true,editKey=true,nonce=true,action=true,
 name=true,rows=true,disconnected=true,confirm=true,ids=true,secondName=true,secondRows=true,
 assigned=true,policy=true,renew=true,owner=true} -- owner is ignored; authenticated actor owns creation.
local function plainArgs(args)
 if type(args)~='table' or getmetatable(args) then return false end
 for k in pairs(args) do if not fields[k] then return false end end
 return true
end
function R.cleanup(player) R.jobs[player]=nil;tickets[player]=nil end
local function finish(job,status,reason) job.done=true;job.result={status=status,reason=reason};return job.result end
function R.handle(player,command,args)
 if isClient() or not player or not plainArgs(args) then return {status='invalid'} end
 local who=owner(player);if type(who)~='string' or #who<1 or #who>256 then return {status='invalid'} end
 if not R.options().enabled then return {status='RoomDisabled'} end
 if command=='roomList' then
  local rooms,revision,world=R.metadata(player);if not rooms then return {status=revision} end
  local t=tickets[player]
  local pending=R.jobs[player] and not R.jobs[player].done
  if not t or not pending and (args.renew==true or t.used or getTimestampMs()-t.time>120000) then ticketSerial=ticketSerial+1;t={key=tostring(getTimestampMs())..':'..ticketSerial,time=getTimestampMs()};tickets[player]=t end
  return {status='ok',rooms=rooms,revision=revision,world=world,options=R.options(),editKey=t.key}
 end
 if command=='roomGet' then
  local room,e=R.resolve(player,args.id,args.roomRevision);if not room then return {status=e} end
  return {status='ok',room=copyRoom(room,player)}
 end
 if command=='roomPoll' then
  local j=R.jobs[player]
  if not j or j.nonce~=args.nonce then return {status='expired'} end
  return j.result or {status='pending'}
 end
 if command=='roomCancel' then
  local current=R.jobs[player]
  if current and current.nonce==args.nonce and current.editKey==args.editKey then return current.result or finish(current,'cancelled') end
  local t=tickets[player];if not t or t.key~=args.editKey then return {status='expired'} end
  t.used=true;local j=R.jobs[player]
  if j and j.nonce==args.nonce then return j.result or finish(j,'cancelled') end
  return {status='cancelled'}
 end
 if command~='roomChange' or type(args.nonce)~='string' or #args.nonce<1 or #args.nonce>96 or args.nonce:find('%c') then return {status='invalid'} end
 local prior=R.jobs[player]
 if prior and prior.nonce==args.nonce then
  if prior.editKey~=args.editKey then return {status='invalid'} end
  return prior.result or {status='pending'}
 end
 if prior and not prior.done then return {status='busy'} end
 local ticket=tickets[player]
 if not ticket or ticket.used or ticket.key~=args.editKey or getTimestampMs()-ticket.time>120000 then return {status='expired'} end
 local lib,data=library();if not lib then return {status=data} end
 if args.revision~=lib.revision then return {status='conflict'} end
 local pending=0;for _,j in pairs(R.jobs) do if not j.done then pending=pending+1 end end;if pending>=16 then return {status='busy'} end
 local changed,removed={},{};local serial=lib.serial
 local world=lib.world or getRandomUUID()
 if args.id~=nil and (type(args.id)~='string' or #args.id~=73) then return {status='invalid'} end
 local old=args.id and lib.records[args.id]
 if args.id and (not old or not member(player,old)) then return {status='RoomDenied'} end
 if old and args.roomRevision~=old.revision then return {status='conflict'} end
 local action=args.action
 if action=='restore' then return {status='RoomPermissionUnsupported'} end
 if old and action=='approveBoundary' then
  if not P.edit(player,old,'geometry') or not old.pendingBoundary then return {status='RoomDenied'} end
  local approved={};for k,v in pairs(args) do approved[k]=v end
  args=approved;args.rows=old.pendingBoundary;args.name=old.name;action='save'
 end
 if old and action=='save' and not P.edit(player,old,'geometry') then
  local proposed=G.normalize(args.rows);local original=geometry(old);local same=proposed and proposed.count==original.count
  if same then for k in pairs(proposed.set) do if not original.set[k] then same=false;break end end end
  if not same then action='requestBoundary' end
 end
 if action=='assign' or action=='policy' or action=='relinquish' or action=='requestBoundary' or action=='rejectBoundary' then
  if not old then return {status='invalid'} end
  local r=I.copy(old);r.revision=r.revision+1;r.updatedAt=getTimestamp()
  if action=='assign' then
   if not P.edit(player,old,'assignOwner') then return {status='RoomDenied'} end
   local h=house(old.safehouse);local who=args.assigned
   if who~=nil and (not h or type(who)~='string' or #who<1 or #who>256 or who:find('%c') or not (h:getOwner()==who or h:getPlayers():contains(who))) then return {status='RoomDenied'} end
   r.assigned=who;r.policy=who and I.copy(old.policy or {mode='shared',rules={},grants={}}) or {mode='shared',rules={},grants={}};r.policy.grants={}
   if h then r.parentOwner=h:getOwner();r.parentBounds={h:getX(),h:getY(),h:getX2(),h:getY2()} end
  elseif action=='policy' then
   if not P.edit(player,old,'policy') or not P.valid(args.policy) then return {status='RoomPolicyInvalid'} end
   if args.policy.mode=='private' and I.option('DelegatedRooms',true)~=true then return {status='RoomPolicyDisabled'} end
   r.policy=I.copy(args.policy)
   local h=house(r.safehouse);if h then r.parentOwner=h:getOwner();r.parentBounds={h:getX(),h:getY(),h:getX2(),h:getY2()} end
  elseif action=='relinquish' then
   if old.assigned~=owner(player) then return {status='RoomDenied'} end
   r.assigned=nil;r.policy={mode='shared',rules={},grants={}}
  elseif action=='requestBoundary' then
   if old.assigned~=owner(player) then return {status='RoomDenied'} end
   local g,e=G.normalize(args.rows,R.options().maxTiles);if not g or g.count<1 then return {status=e or 'RoomGeometryInvalid'} end
   if G.components(g)>1 and args.disconnected~=true then return {status='RoomDisconnected'} end
   r.pendingBoundary=g.rows
  else
   if not P.edit(player,old,'geometry') then return {status='RoomDenied'} end;r.pendingBoundary=nil
  end
  changed[old.id]=r
 elseif action=='delete' then
  if not old or not P.edit(player,old,'geometry') then return {status='RoomDenied'} end
  if not old or args.confirm~=true then return {status='invalid'} end;removed[old.id]=true
 elseif action=='save' or action=='split' or action=='merge' then
  local title=name(args.name);if not title then return {status='RoomNameInvalid'} end
  local geometry,e=G.normalize(args.rows,R.options().maxTiles)
  if not geometry or geometry.count<1 then return {status=e or 'RoomGeometryInvalid'} end
  if G.components(geometry)>1 and args.disconnected~=true then return {status='RoomDisconnected'} end
  local id=old and old.id
  if not id then serial=serial+1;id=world..':'..getRandomUUID();if lib.records[id] then return {status='failed'} end end
  changed[id]={id=id,ordinal=old and old.ordinal or serial,name=title,owner=old and old.owner or owner(player),revision=old and old.revision+1 or 1,
   safehouse=old and old.safehouse,rows=geometry.rows,createdAt=old and old.createdAt or getTimestamp(),updatedAt=getTimestamp()}
  if old then
   for _,k in ipairs({'assigned','policy','parentOwner','parentBounds','nativeId','nativeIds'}) do changed[id][k]=I.copy(old[k]) end
   if P.edit(player,old,'geometry') then local h=house(old.safehouse);if h then changed[id].parentOwner=h:getOwner();changed[id].parentBounds={h:getX(),h:getY(),h:getX2(),h:getY2()} end end
  end
  if action=='merge' then
   if not P.edit(player,old,'geometry') then return {status='RoomDenied'} end
   if not old or not G.array(args.ids,128) or #args.ids<2 or args.confirm~=true then return {status='invalid'} end
   local merged=G.normalize({});local seen={}
   for _,other in ipairs(args.ids) do
    if type(other)~='string' or #other~=73 or seen[other] then return {status='invalid'} end;seen[other]=true
    local r=lib.records[other];if not r or not member(player,r) then return {status='RoomDenied'} end
    if not P.edit(player,r,'geometry') or r.assigned~=old.assigned or not I.equal(r.policy or {mode='shared',rules={},grants={}},old.policy or {mode='shared',rules={},grants={}}) then return {status='RoomDenied'} end
    if r.safehouse~=old.safehouse then return {status='RoomAssociationConflict'} end
    merged,e=G.edit(merged.rows,r.rows,false,R.options().maxTiles);if not merged then return {status=e} end
    if other~=old.id then removed[other]=true end
   end
   if not seen[old.id] then return {status='invalid'} end
   local a,b=G.normalize(changed[id].rows),merged
   if a.count~=b.count then return {status='RoomGeometryInvalid'} end
   for key in pairs(a.set) do if not b.set[key] then return {status='RoomGeometryInvalid'} end end
  elseif action=='split' then
   if not P.edit(player,old,'geometry') then return {status='RoomDenied'} end
   if not old or args.confirm~=true then return {status='invalid'} end
   local title2=name(args.secondName);local second;second,e=G.normalize(args.secondRows,R.options().maxTiles)
   if not title2 or not second or second.count<1 then return {status=e or 'RoomNameInvalid'} end
   if G.components(second)>1 and args.disconnected~=true then return {status='RoomDisconnected'} end
   local original=G.normalize(old.rows)
   if geometry.count+second.count~=original.count then return {status='RoomGeometryInvalid'} end
   for key in pairs(geometry.set) do if not original.set[key] or second.set[key] then return {status='RoomGeometryInvalid'} end end
   for key in pairs(second.set) do if not original.set[key] then return {status='RoomGeometryInvalid'} end end
   serial=serial+1;local other=world..':'..getRandomUUID();if lib.records[other] or changed[other] then return {status='failed'} end
   changed[other]={id=other,ordinal=serial,name=title2,owner=old.owner,revision=1,safehouse=old.safehouse,rows=second.rows,createdAt=getTimestamp(),updatedAt=getTimestamp()}
   for _,k in ipairs({'assigned','policy','parentOwner','parentBounds'}) do changed[other][k]=I.copy(old[k]) end
  end
 else return {status='invalid'} end
 local count,total=0,0
 for id,r in pairs(lib.records) do if not removed[id] and not changed[id] then count=count+1;total=total+G.normalize(r.rows).count end end
 local work={}
 for _,r in pairs(changed) do
  local g=G.normalize(r.rows);count=count+1;total=total+g.count
  for _,tile in ipairs(g.tiles) do work[#work+1]={tile=tile,room=r} end
  if r.pendingBoundary then for _,tile in ipairs(G.normalize(r.pendingBoundary).tiles) do work[#work+1]={tile=tile,room=r} end end
 end
 if count>128 or total>16384 or not integer(serial) or serial>=10000000 or not integer(lib.revision+1) then return {status='RoomTooLarge'} end
 -- A deletion still validates access to the old room cooperatively.
 if action=='delete' then local validation={id=old.id,safehouse=old.safehouse};for _,t in ipairs(G.normalize(old.rows).tiles) do work[#work+1]={tile=t,room=validation} end end
 local j={nonce=args.nonce,editKey=args.editKey,world=world,revision=lib.revision,changed=changed,removed=removed,serial=serial,work=work,index=1,time=getTimestampMs(),original=lib,action=action}
 ticket.used=true;R.jobs[player]=j;return {status='pending'}
end
function R.tick()
 if isClient() then return end
 if not R.options().enabled then
  for _,j in pairs(R.jobs) do if not j.done then finish(j,'RoomDisabled') end end
  return
 end
 local deadline=getTimestampMs()+4
 local online
 local function connected(player)
  if not isServer() then return getSpecificPlayer(player:getPlayerNum())==player end
  if type(getOnlinePlayers)~='function' then return false end
  if not online then online={};local players=getOnlinePlayers();for i=0,players:size()-1 do online[players:get(i)]=true end end
  return online[player]==true
 end
 -- At most four jobs per tick and 32 native tile checks/job. Every job expires.
 local active={};for player,j in pairs(R.jobs) do
  if getTimestampMs()-j.time>30000 then R.jobs[player]=nil elseif not j.done then active[#active+1]={player,j} end
 end
 table.sort(active,function(a,b) return (a[2].lastStep or 0)<(b[2].lastStep or 0) end)
 for n=1,math.min(4,#active) do
  if getTimestampMs()>=deadline then break end
  local player,j=unpack(active[n]);j.lastStep=getTimestampMs()
  local ok,err=pcall(function()
   if not connected(player) or not player:getCurrentSquare() or (player.isDead and player:isDead()) then finish(j,'cancelled');return end
   local lib,data=library();if not lib or lib.revision~=j.revision then finish(j,'conflict');return end
   for id in pairs(j.removed) do if not lib.records[id] or not member(player,lib.records[id]) then finish(j,'RoomDenied');return end end
   for id in pairs(j.changed) do if lib.records[id] and not member(player,lib.records[id]) then finish(j,'RoomDenied');return end end
   for id in pairs(j.changed) do
    local old=lib.records[id]
    if old and (j.action=='assign' and not P.edit(player,old,'assignOwner') or (j.action=='merge' or j.action=='split' or j.action=='rejectBoundary') and not P.edit(player,old,'geometry')) then finish(j,'RoomDenied');return end
   end
   for _=1,32 do
    if getTimestampMs()>=deadline then break end
    local row=j.work[j.index];if not row then break end;j.index=j.index+1
    local t=row.tile;local sq=getCell():getGridSquare(t.x,t.y,t.z);local allowed,reason=currentPermission(player,sq)
    if not allowed then finish(j,reason);return end
    local range=R.options().range
    if math.max(math.abs(t.x-player:getX()),math.abs(t.y-player:getY()))>range then finish(j,'RoomOutOfRange');return end
    -- The association is server-derived and must not span distinct safehouses.
    if isServer() then
     local h,reason=P.at(sq)
     if reason then finish(j,'RoomPermissionUnavailable');return end
     if h then
      if not houseMember(player,h) then finish(j,'RoomDenied');return end
      if row.room.safehouse and row.room.safehouse~=h:getId() then finish(j,'RoomAssociationConflict');return end
      row.room.safehouse=h:getId()
     end
    end
   end
   if j.index>#j.work then
    -- Membership can change after an earlier tile slice. Recheck associated
    -- native groups before the single authoritative library replacement.
    for _,r in pairs(j.changed) do local h=house(r.safehouse);if h and not houseMember(player,h) then finish(j,'RoomDenied');return end end
    for id in pairs(j.removed) do local h=house(lib.records[id].safehouse);if h and not houseMember(player,h) then finish(j,'RoomDenied');return end end
    for _,r in pairs(j.changed) do if G.normalize(r.rows).count>R.options().maxTiles then finish(j,'RoomTooLarge');return end end
    -- No native calls or yields between revision check and replacing this library.
    local records={};for id,r in pairs(lib.records) do if not j.removed[id] then records[id]=r end end
    for id,r in pairs(j.changed) do records[id]=r end
    for _,r in pairs(j.changed) do local ok,reason=P.validate(r,records,j.removed);if not ok then finish(j,reason);return end end
    data.customRooms={schema=2,world=j.world,revision=lib.revision+1,serial=j.serial,records=records}
    j.done=true;j.result={status='ok',revision=lib.revision+1}
    if B47ANCEDRooms.changed then B47ANCEDRooms.changed(lib.revision+1) end
   end
  end)
  if not ok then if not j.done then finish(j,'failed') end;print('[B47ANCEDRooms] room validation/notification failed '..tostring(err)) end
 end
end
if Events and Events.OnTick then Events.OnTick.Add(R.tick) end
R.library=library;R.geometry=geometry
return R
