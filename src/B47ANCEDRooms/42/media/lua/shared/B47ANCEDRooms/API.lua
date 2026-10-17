local I=require 'B47ANCEDRooms/Identity'
local R=require 'B47ANCEDRooms/Registry'
local P=require 'B47ANCEDRooms/Policy'
local G=require 'B47ANCEDRooms/Geometry'
local Types=require 'B47ANCEDRooms/RoomTypes'
local A={version=1,ready=true};B47ANCEDRooms.API=A
local listeners={}
local function raw(player,id,revision)
 if isClient() or not player or not R.options().enabled then return nil,'RoomPermissionUnavailable' end
 local lib,e=R.library();if not lib then return nil,e end
 if type(id)~='string' or #id>180 or id:find('%c') then return nil,'RoomUnavailable' end
 local record=lib.records[id]
 if record then
  if revision~=nil and record.revision~=revision then return nil,'conflict' end
  local sq=player:getCurrentSquare();local b=R.geometry(record).bounds;local range=R.options().range
  if not sq or sq:getX()<b.x1-range or sq:getX()>b.x2+range or sq:getY()<b.y1-range or sq:getY()>b.y2+range then return nil,'RoomOutOfRange' end
  return record
 end
 return nil,'RoomUnavailable'
end
function A.capabilities()
 return {api=1,version=I.version,ready=true,editor=true,nativeOverrides=false,designatedRooms=true,delegatedPolicies=true,roomDesignations=1,storageScopes=1,policyCopy=1,
  cleaning=1,cleaningScope='designatedRooms',boundaries={quartermasterGrant=true,vanillaFinalMutation=false,entry=false,doors=false,building=false,destruction=false,cleaning=true}}
end
function A.subscribe(fn) if type(fn)~='function' then return end;listeners[fn]=true;return function() listeners[fn]=nil end end
function B47ANCEDRooms.changed(revision)
 for fn in pairs(listeners) do local ok=pcall(fn,revision);if not ok then print('[B47ANCEDRooms] room subscriber failed') end end
 if B47ANCEDRooms.Network then B47ANCEDRooms.Network.changed(revision) end
end
function A.canAccessAt(player,x,y,z,action)
 if isClient() or not R.options().enabled or not P.actions[action] then return {state='unknown',reason='RoomPermissionUnavailable'} end
 if not G.integer(x) or not G.integer(y) or not G.integer(z) or z< -32 or z>31 then return {state='unknown',reason='RoomPermissionUnavailable'} end
 local sq=getCell():getGridSquare(x,y,z);local allowed,reason=P.base(player,sq,action)
 if not allowed then return {state=reason=='unavailable' and 'unknown' or 'deny',reason='RoomAccessDenied'} end
 local lib,e=R.library();if not lib then return {state='unknown',reason='RoomPermissionUnavailable'} end
 local matched=0
 for _,room in pairs(lib.records) do if room.policy and room.policy.mode=='private' and G.contains(R.geometry(room),x,y,z) then
  matched=matched+1;if matched>1 then return {state='unknown',reason='RoomPermissionUnavailable',revision=lib.revision} end
  if I.option('DelegatedRooms',true)~=true then return {state='unknown',reason='RoomPermissionUnavailable',revision=lib.revision} end
  local ok,why=P.storage(player,room,action)
  if not ok then return {state=why=='denied' and 'deny' or 'unknown',reason=why=='denied' and 'RoomAccessDenied' or 'RoomPermissionUnavailable',revision=lib.revision} end
 end end
 return {state='allow',revision=lib.revision}
end
function A.containsTile(player,id,revision,x,y,z)
 local r=raw(player,id,revision);if not r then return false end
 return G.contains(R.geometry(r),x,y,z)
end
function A.containsTarget(player,id,revision,target)
 local sq=target and target.obj and target.obj:getSquare()
 return sq and A.containsTile(player,id,revision,sq:getX(),sq:getY(),sq:getZ()) or false
end
function A.resolveRoom(player,id,revision)
 local r,e=raw(player,id,revision);if not r then return {status=e} end
 local can=P.edit(player,r,'rename')
 if not can then
  local permitted=false;for _,t in ipairs(R.geometry(r).tiles) do if A.canAccessAt(player,t.x,t.y,t.z,'discover').state=='allow' then permitted=true;break end end
  if not permitted then return {status='RoomAccessDenied'} end
 end
 return {status='ok',room={id=r.id,name=r.name,revision=r.revision,count=R.geometry(r).count,roomType=r.roomType or 'unassigned',designation=r.designation or 'unassigned'}}
end
function A.geometry(player,id,revision)
 local resolution=A.resolveRoom(player,id,revision);if resolution.status~='ok' then return resolution end
 local r=raw(player,id,revision)
 return {status='ok',room={id=r.id,name=r.name,revision=r.revision,rows=I.copy(r.rows),roomType=r.roomType or 'unassigned',designation=r.designation or 'unassigned'}}
end
function A.tiles(player,id,revision)
 local result=A.geometry(player,id,revision);if result.status~='ok' then return result end
 local g,e=G.normalize(result.room.rows);if not g then return {status=e} end
 return {status='ok',tiles=I.copy(g.tiles),revision=result.room.revision}
end
function A.listRooms(player,filter)
 if isClient() then return {status='RoomPermissionUnavailable'} end
 local lib,e=R.library();if not lib then return {status=e} end
 local rooms={};local _,revision,world=R.metadata(player)
 for id,r in pairs(lib.records) do
  local visible=A.resolveRoom(player,id,r.revision)
  if visible.status=='ok' and (not filter or not filter.safehouse or r.safehouse==filter.safehouse) then
   local g=R.geometry(r);local inBuilding=not filter or not filter.building
   if not inBuilding then
    local sq=player:getCurrentSquare();local b=sq and sq:getBuilding();local def=b and b:getDef()
    for _,t in ipairs(g.tiles) do local q=getCell():getGridSquare(t.x,t.y,t.z);local other=q and q:getBuilding()
     if def and other and other:getDef()==def then inBuilding=true;break end
    end
   end
   local floors={};local last;for _,row in ipairs(g.rows) do if row[1]~=last then floors[#floors+1]=row[1];last=row[1] end end
   if inBuilding then rooms[#rooms+1]={id=id,name=r.name,label=r.name..' [r'..r.ordinal..']',revision=r.revision,count=g.count,bounds=I.copy(g.bounds),floors=floors,roomType=r.roomType or 'unassigned',designation=r.designation or 'unassigned',canConfigureRoom=P.edit(player,r,'policy')} end
  end
 end
 table.sort(rooms,function(a,b) return a.label<b.label end)
 return {status='ok',rooms=rooms,revision=revision,world=world}
end
function A.roomsAt(player,x,y,z)
 local list=A.listRooms(player);if list.status~='ok' then return list end
 local out={}
 for _,r in ipairs(list.rooms) do
  if A.containsTile(player,r.id,r.revision,x,y,z) then out[#out+1]=r end
 end
 return {status='ok',rooms=out}
end
function A.permissions(player,id)
 local r,e=raw(player,id);if not r or not P.edit(player,r,'rename') then return {status=e or 'RoomDenied'} end
 return {status='ok',owner=r.owner,assigned=r.assigned,safehouse=r.safehouse,revision=r.revision,
  policy=I.copy(r.policy or {mode='shared',rules={},grants={}}),canAssign=P.edit(player,r,'assignOwner'),canEditGeometry=P.edit(player,r,'geometry'),canConfigureRoom=P.edit(player,r,'policy'),roomType=r.roomType or 'unassigned',designation=r.designation or 'unassigned'}
end
function A.roomTypes() return {status='ok',types=I.copy(Types.ids),roles=I.copy(Types.roles)} end
-- Authoritative physical-target queries deliberately do not use editor range.
function A.storageScopes(player,target)
 if isClient() or not target or not target.obj then return {status='RoomPermissionUnavailable'} end
 local sq=target.obj:getSquare();if not sq then return {status='RoomPermissionUnavailable'} end
 local access=A.canAccessAt(player,sq:getX(),sq:getY(),sq:getZ(),'deposit')
 if access.state~='allow' then return {status=access.reason or 'RoomAccessDenied'} end
 local lib,e=R.library();if not lib then return {status=e} end
 local out={}
 for id,record in pairs(lib.records) do
  if G.contains(R.geometry(record),sq:getX(),sq:getY(),sq:getZ()) then
   out[#out+1]={id=id,name=record.name,revision=record.revision,roomType=record.roomType or 'unassigned',designation=record.designation or 'unassigned'}
  end
 end
 table.sort(out,function(a,b) return a.id<b.id end)
 return {status='ok',rooms=out,revision=lib.revision}
end
function A.storageGeometry(player,id,revision,target)
 local result=A.storageScopes(player,target);if result.status~='ok' then return result end
 local found;for _,room in ipairs(result.rooms) do if room.id==id then found=room end end
 if not found then return {status='RoomUnavailable'} end
 if revision~=nil and found.revision~=revision then return {status='conflict'} end
 local lib,e=R.library();if not lib then return {status=e} end
 local record=lib.records[found.id]
 return {status='ok',room={id=record.id,name=record.name,revision=record.revision,rows=I.copy(record.rows),roomType=record.roomType or 'unassigned',designation=record.designation or 'unassigned'}}
end
function A.storageTiles(player,id,revision,target)
 local result=A.storageGeometry(player,id,revision,target);if result.status~='ok' then return result end
 local geometry,e=G.normalize(result.room.rows);if not geometry then return {status=e} end
 return {status='ok',tiles=I.copy(geometry.tiles),revision=result.room.revision}
end
function A.change(player,args) return R.handle(player,'roomChange',args) end
function A.beginEdit(player) return R.handle(player,'roomList',{renew=true}) end
-- Retired API entry point fails explicitly; it must never delete a saved room.
function A.restoreVanilla() return {status='RoomPermissionUnsupported'} end
local mutations={create='save',rename='save',editGeometry='save',delete='delete',merge='merge',split='split',assignOwner='assign',revokeOwner='assign',setPolicy='policy',copyPolicy='copyPolicy',setDesignation='designation',requestBoundary='requestBoundary',approveBoundary='approveBoundary',rejectBoundary='rejectBoundary',relinquish='relinquish'}
for method,action in pairs(mutations) do local operation=action;local revoke=method=='revokeOwner'
 A[method]=function(player,args) local payload=I.copy(args or {});payload.action=operation;if revoke then payload.assigned=nil end;return A.change(player,payload) end
end
function A.canAccess(player,id,action,target)
 local r,e=raw(player,id);if not r then return {state='unknown',reason=e} end
 if action=='configureRoom' then
  if not P.edit(player,r,'policy') then return {state='deny',revision=r.revision} end
  local deadline=getTimestampMs()+8
  for _,tile in ipairs(R.geometry(r).tiles) do
   if getTimestampMs()>=deadline then return {state='unknown',reason='RoomPermissionUnavailable'} end
   local ok,why=P.base(player,getCell():getGridSquare(tile.x,tile.y,tile.z),'configure')
   if not ok then return {state=why=='unavailable' and 'unknown' or 'deny',reason='RoomAccessDenied'} end
  end
  return {state='allow',revision=r.revision}
 end
 if action=='editRoom' or action=='assignOwner' then
  return {state=P.edit(player,r,action=='assignOwner' and action or 'geometry') and 'allow' or 'deny',revision=r.revision}
 end
 if not P.actions[action] then return {state='unknown',reason='RoomPermissionUnsupported'} end
 local sq=target and target.obj and target.obj:getSquare()
 if not sq or not A.containsTarget(player,id,nil,target) then return {state='deny',reason='RoomAccessDenied'} end
 return A.canAccessAt(player,sq:getX(),sq:getY(),sq:getZ(),action)
end
function A.resolveAt(player,x,y,z)
 local result=A.roomsAt(player,x,y,z)
 if result.status~='ok' then return result end
 if #result.rooms~=1 then return {status=#result.rooms==0 and 'RoomUnavailable' or 'RoomAmbiguous',rooms=result.rooms} end
 return {status='ok',room=result.rooms[1]}
end
function A.request(playerNum,command,args,done)
 if isServer() then return nil,'clientOnly' end
 return require('B47ANCEDRooms/Client').request(playerNum,command,args,done)
end
function A.openEditor(playerNum,owner,done)
 if isServer() then return nil,'clientOnly' end
 require 'B47ANCEDRooms/Client'
 return require('B47ANCEDRooms/Editor').open(playerNum,owner,done)
end
require('B47ANCEDRooms/Cleaning')(A)
return A
