-- Owned disposable fixtures only. Not native world, save or dedicated execution.
dofile(TEST_ROOT..'/fixtures/world.lua')
local f=CONTAINER_FIXTURE
local G=require 'B47ANCEDRooms/Geometry'
local Draft=require 'B47ANCEDRooms/Draft'
local R=require 'B47ANCEDRooms/Registry'

local function rect(x,y,x2,y2,z) return assert(G.rectangle({x=x,y=y,z=z or 0},{x=x2,y=y2,z=z or 0})) end
local box=rect(0,0,3,2);assert(box.count==12)
local l=assert(G.edit(box.rows,rect(1,1,3,2).rows,true));assert(l.count==6 and not G.contains(l,1,1,0) and G.components(l)==1)
local joined=assert(G.edit(l.rows,{{1,0,0,0}},false));assert(joined.count==7 and G.components(joined)==2)
-- The draft row-run path must match the established tile-set edit semantics.
for _,source in ipairs({G.normalize({}),box,rect(0,0,7,7)}) do
 for _,region in ipairs({rect(1,1,3,3),rect(-2,-2,2,2),rect(5,5,9,9),rect(0,0,0,0)}) do
  for _,remove in ipairs({false,true}) do
   local old=assert(G.edit(source.rows,region.rows,remove))
   local fast=assert(G.editShape(source,region.rows,remove))
   assert(fast.count==old.count and #fast.rows==#old.rows,'draft edit count differs')
   for i,r in ipairs(old.rows) do for k=1,4 do assert(fast.rows[i][k]==r[k],'draft edit rows differ') end end
  end
 end
end
assert(not G.normalize({{0,0,0,4096}}));assert(not G.normalize({{0,0,0,1},bad=true}))
assert(not G.normalize({{0,0,0,1/0}}));assert(not G.normalize({{0,0,0,1}},1))
local d=Draft.new({rows=box.rows})
assert(d:edit(rect(1,1,3,2).rows,true) and d.geometry.count==6)
assert(d:undo() and d.geometry.count==12 and d:redo() and d.geometry.count==6)
assert(d:split(rect(0,0,0,2).rows) and d.geometry.count==3 and d.second.count==3)
assert(d:undo() and d.action=='save' and d.geometry.count==6)
local edges=d:edges(rect(0,0,99,9),0);assert(#edges==4,'collinear tile boundaries were not compacted')
f.network(false,true)
local serial=0
getTimestamp=function() return math.floor(getTimestampMs()/1000) end
getRandomUUID=function() serial=serial+1;return '00000000-0000-0000-0000-'..string.format('%012d',serial) end
local members={['member']=true}
local h={getId=function() return 'house-a' end,getOwner=function() return 'fixture-player' end,
 getPlayers=function() return {size=function() return 1 end,get=function() return 'member' end,contains=function(_,who) return members[who]==true end} end}
h.getX=function() return -1 end;h.getY=function() return -1 end;h.getX2=function() return 10 end;h.getY2=function() return 10 end
SafeHouse.getSafehouseList=function() return f.list({h}) end
local deny=false
SafeHouse.getSafeHouse=function(key) if type(key)=='string' then return key=='house-a' and h end;return h end
SafeHouse.isSafehouseAllowInteract=function() return not deny end
SafeHouse.isSafehouseAllowLoot=function() return not deny end
local function actor(who)
 return {getUsername=function() return who end,getAccessLevel=function() return 'None' end,getPlayerNum=function() return 0 end,
 getCurrentSquare=function() return f.a.sq end,getX=function() return 0 end,getY=function() return 0 end,getZ=function() return 0 end}
end
local creator=f.player;local peer=actor('member');local stranger=actor('stranger')
getOnlinePlayers=function() return f.list({creator,peer,stranger}) end
local data=ModData.getOrCreate('B47ANCEDRooms');data.unrelated={preserve=true}
local nonce=0
local function proposal(player,fields)
 local snap=R.handle(player,'roomList',{});assert(snap.status=='ok')
 nonce=nonce+1;local args={action='save',nonce='test:'..nonce,revision=snap.revision,editKey=snap.editKey,name='Storage',rows={{0,0,0,1}}}
 for k,v in pairs(fields or {}) do args[k]=v end
 return args
end
local function drain(player,args)
 local result=R.handle(player,'roomChange',args)
 if result.status~='pending' then return result end
 for _=1,256 do f.advance(16);R.tick();result=R.handle(player,'roomPoll',{nonce=args.nonce});if result.status~='pending' then return result end end
 error('room validation did not finish')
end
assert(R.handle(creator,'roomList',{}).status=='ok' and data.customRooms==nil,'read initialized persistent geometry')
local create=proposal(creator,{owner='forged'});assert(drain(creator,create).status=='ok')
local lib=data.customRooms;local id=R.metadata(creator)[1].id;local original=lib.records[id]
assert(original.owner=='fixture-player' and original.safehouse=='house-a' and original.name=='Storage')
assert(data.unrelated.preserve and lib.schema==2 and lib.world and original.revision==1)
assert(R.handle(creator,'roomChange',create).status=='ok' and data.customRooms==lib,'replay committed twice')
assert(#R.metadata(stranger)==0 and R.handle(stranger,'roomGet',{id=id}).status=='RoomDenied')
assert(drain(stranger,proposal(stranger,{id=id,roomRevision=1})).status=='RoomDenied')
assert(drain(peer,proposal(peer,{id=id,roomRevision=1,name='Pantry'})).status=='ok')
assert(data.customRooms.records[id].owner=='fixture-player' and data.customRooms.records[id].revision==2)
assert(drain(creator,proposal(creator,{id=id,roomRevision=1})).status=='conflict')
deny=true;local before=data.customRooms
assert(drain(creator,proposal(creator,{id=id,roomRevision=2})).status=='RoomDenied' and data.customRooms==before)
deny=false
local bad=proposal(creator,{name='<TEXT>bad'});assert(drain(creator,bad).status=='RoomNameInvalid')
local disconnected=proposal(creator,{rows={{0,0,0,0},{0,0,2,2}}})
assert(drain(creator,disconnected).status=='RoomDisconnected')
disconnected.disconnected=true;assert(drain(creator,disconnected).status=='ok')
-- Cancel before arrival consumes a server-issued edit key; late save cannot revive it.
local cancelled=proposal(creator,{name='Cancelled'})
assert(R.handle(creator,'roomCancel',{editKey=cancelled.editKey,nonce=cancelled.nonce}).status=='cancelled')
assert(R.handle(creator,'roomChange',cancelled).status=='expired')
local inFlight=proposal(creator,{name='Cancel pending'})
assert(R.handle(creator,'roomChange',inFlight).status=='pending')
assert(R.handle(creator,'roomCancel',{editKey=inFlight.editKey,nonce=inFlight.nonce}).status=='cancelled')
R.tick();assert(R.handle(creator,'roomChange',inFlight).status=='cancelled')
-- More than one tick of validation: no partial writes, and current permissions win.
for y=0,7 do for x=0,7 do if not f.squares[x..','..y..',0'] then f.square(x,y,0) end end end
local large=proposal(peer,{id=id,roomRevision=2,rows=rect(0,0,7,7).rows})
assert(R.handle(peer,'roomChange',large).status=='pending');local unchanged=data.customRooms
R.tick();assert(data.customRooms==unchanged and R.handle(peer,'roomPoll',{nonce=large.nonce}).status=='pending')
members.member=nil;f.advance(16);R.tick()
assert(R.handle(peer,'roomPoll',{nonce=large.nonce}).status=='RoomDenied' and data.customRooms==unchanged)
members.member=true
-- Two edits based on one revision cannot both commit.
local stale=proposal(creator,{name='Stale'})
assert(drain(peer,proposal(peer,{id=id,roomRevision=2,name='Current'})).status=='ok')
assert(drain(creator,stale).status=='conflict')
-- New snapshots after a module reload preserve identities and geometry.
package.loaded['B47ANCEDRooms/Registry']=nil;R=require 'B47ANCEDRooms/Registry'
assert(R.handle(peer,'roomGet',{id=id}).room.name=='Current')
local retained=data.customRooms;data.customRooms={schema=99,records={}}
assert(R.handle(creator,'roomList',{}).status=='schema' and data.customRooms.schema==99)
data.customRooms=retained
local targetRoom=data.customRooms.records[id]
local deletion=proposal(creator,{action='delete',id=id,roomRevision=targetRoom.revision,confirm=true})
local modData=f.a.md;local inventory=f.a.containers[1]
assert(drain(creator,deletion).status=='ok' and not data.customRooms.records[id] and f.a.md==modData and f.a.containers[1]==inventory)
assert(R.handle(creator,'roomGet',{id=id}).status=='RoomDenied','deleted identity rebound by name')
local new=proposal(creator,{name='Current'});assert(drain(creator,new).status=='ok')
for _,m in ipairs(R.metadata(creator)) do assert(m.id~=id,'room identity reused') end
local function newest() for id,r in pairs(data.customRooms.records) do if r.ordinal==data.customRooms.serial then return id end end end
local a=newest()
assert(drain(creator,proposal(creator,{name='B',rows={{0,1,0,1}}})).status=='ok')
local b=newest()
assert(drain(creator,proposal(creator,{name='C',rows={{0,2,0,1}}})).status=='ok')
local c=newest()
local merge=proposal(creator,{action='merge',id=a,roomRevision=1,ids={a,b,c},name='Combined',rows=rect(0,0,1,2).rows,confirm=true})
assert(drain(creator,merge).status=='ok')
assert(data.customRooms.records[a].revision==2 and not data.customRooms.records[b] and not data.customRooms.records[c])
assert(drain(creator,proposal(creator,{action='split',id=a,roomRevision=2,name='First',rows={{0,0,0,1}},secondRows={{0,1,0,1},{0,2,0,1}},secondName='Second',confirm=true})).status=='ok')
assert(G.normalize(data.customRooms.records[a].rows).count==2 and data.customRooms.records[a].revision==3)
local found=false;for other,r in pairs(data.customRooms.records) do if r.name=='Second' then found=true;assert(other~=a and G.normalize(r.rows).count==4) end end;assert(found)
SandboxVars.B47ANCEDRooms.Enabled=false
assert(R.handle(creator,'roomList',{}).status=='RoomDisabled')
f.network(true,false);assert(R.handle(creator,'roomChange',new).status=='invalid')
print('PASS OFFLINE custom rooms: compact geometry, holes/floors, undo/split, ownership/safehouse edits, native denial, atomic revisions, cancellation/replay, reload/corruption, deletion isolation and disabled/client rejection')
