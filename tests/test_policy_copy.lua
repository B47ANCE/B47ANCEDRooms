-- Engine-shaped dedicated authority fixtures, not a running server.
dofile(TEST_ROOT..'/fixtures/world.lua')
local f=CONTAINER_FIXTURE;f.network(false,true)
local A=require 'B47ANCEDRooms/API';local R=B47ANCEDRooms.Registry;local I=B47ANCEDRooms.Identity
local parentOwner='fixture-player';local members={delegate=true,other=true}
local h={getId=function() return 'house' end,getOwner=function() return parentOwner end,getX=function() return -1 end,getY=function() return -1 end,getX2=function() return 10 end,getY2=function() return 10 end}
function h:getPlayers() local list=f.list({'delegate','other'});list.contains=function(_,name) return members[name]==true end;return list end
SafeHouse.getSafehouseList=function() return f.list({h}) end
local function actor(who) return {getUsername=function() return who end,getPlayerNum=function() return 0 end,getAccessLevel=function() return 'None' end,getCurrentSquare=function() return f.a.sq end,getX=function() return 0 end,getY=function() return 0 end,isDead=function() return false end} end
local delegate,other=actor('delegate'),actor('other');getOnlinePlayers=function() return f.list({f.player,delegate,other}) end
local nonce=0
local function begin(player,args)
 local lease=A.beginEdit(player);nonce=nonce+1;args.revision=lease.revision;args.editKey=lease.editKey;args.nonce='copy:'..nonce;args.confirm=true
 return A.change(player,args)
end
local function finish(player,args,result)
 for _=1,300 do if result.status~='pending' then return result end;R.tick();f.advance(16);result=R.handle(player,'roomPoll',{nonce=args.nonce}) end
 error('policy copy stalled')
end
local function write(player,args) return finish(player,args,begin(player,args)) end
local function rev(id) return R.library().records[id].revision end
local ids={}
for n=0,2 do assert(write(f.player,{action='save',name='Room '..n,rows={{0,0,n,n}},roomType='storage',designation='primary'}).status=='ok');for id in pairs(R.library().records) do if not ids[id] then ids[id]=n end end end
local source,target,third;for id,n in pairs(ids) do if n==0 then source=id elseif n==1 then target=id else third=id end end
for _,id in ipairs({source,target}) do assert(write(f.player,{action='assign',id=id,roomRevision=rev(id),assigned='delegate'}).status=='ok') end
local policy={mode='private',rules={deposit='members'},grants={guest={deposit=true,withdraw=false}}}
assert(write(delegate,{action='policy',id=source,roomRevision=rev(source),policy=policy}).status=='ok')
assert(write(delegate,{action='policy',id=target,roomRevision=rev(target),policy={mode='private',rules={},grants={oldGuest={withdraw=true}}}}).status=='ok')
assert(A.capabilities().policyCopy==1)
local function copy(player,visitors,revision)
 return write(player,{action='copyPolicy',id=target,roomRevision=rev(target),sourceId=source,sourceRevision=revision or rev(source),copyVisitors=visitors})
end
local before=I.copy(R.library().records[target]);local sourceRevision=rev(source)
assert(copy(delegate,false).status=='ok');local record=R.library().records[target]
assert(record.policy.rules.deposit=='members' and record.policy.grants.oldGuest.withdraw and not record.policy.grants.guest)
for _,field in ipairs({'id','owner','assigned','name','roomType','designation'}) do assert(record[field]==before[field]) end
assert(I.equal(record.rows,before.rows) and rev(source)==sourceRevision,'copy mutated geometry or source')
assert(copy(delegate,true).status=='ok');record=R.library().records[target]
assert(record.policy.grants.guest.deposit and record.policy.grants.guest.withdraw==false and not record.policy.grants.oldGuest)
local view=R.handle(delegate,'roomGet',{id=target}).room
assert(view.policyState=='active' and view.roomActions.deposit=='allow');view.policy.grants.guest.deposit=false
assert(R.library().records[target].policy.grants.guest.deposit,'copy/snapshot aliases persisted source policy')
assert(copy(delegate,true,0).status=='conflict')
assert(copy(delegate,'yes').status=='RoomDenied')
assert(write(delegate,{action='copyPolicy',id=target,roomRevision=rev(target),sourceId=target,sourceRevision=rev(target),copyVisitors=true}).status=='RoomDenied')
assert(write(f.player,{action='copyPolicy',id=third,roomRevision=rev(third),sourceId=source,sourceRevision=rev(source),copyVisitors=true}).status=='RoomPolicyInvalid','private copied to unassigned target')
assert(write(f.player,{action='assign',id=third,roomRevision=rev(third),assigned='other'}).status=='ok')
assert(write(other,{action='copyPolicy',id=third,roomRevision=rev(third),sourceId=source,sourceRevision=rev(source),copyVisitors=true}).status=='RoomDenied','target authority bypassed source authority')
assert(copy(other,true).status=='RoomDenied','source metadata leaked through unauthorized target')
-- Source loses policy authority while target is still an editable shared room.
assert(write(delegate,{action='policy',id=target,roomRevision=rev(target),policy={mode='shared',rules={},grants={}}}).status=='ok')
local args={action='copyPolicy',id=target,roomRevision=rev(target),sourceId=source,sourceRevision=rev(source),copyVisitors=true}
local unchanged=R.library();assert(begin(delegate,args).status=='pending');parentOwner='new-parent';R.tick()
assert(R.handle(delegate,'roomPoll',{nonce=args.nonce}).status=='RoomDenied' and R.library()==unchanged);parentOwner='fixture-player'
-- A queued ordinary policy write also rechecks policy authority.
args={action='policy',id=source,roomRevision=rev(source),policy={mode='shared',rules={},grants={}}}
assert(begin(delegate,args).status=='pending');parentOwner='new-parent';R.tick()
assert(R.handle(delegate,'roomPoll',{nonce=args.nonce}).status=='RoomDenied');parentOwner='fixture-player'
-- Source-tile native denial blocks an otherwise authorized target mutation.
SafeHouse.isSafehouseAllowLoot=function(square) return square:getX()~=0 end
assert(copy(delegate,true).status=='RoomDenied');SafeHouse.isSafehouseAllowLoot=function() return true end
args={action='copyPolicy',id=target,roomRevision=rev(target),sourceId=source,sourceRevision=rev(source),copyVisitors=true}
assert(begin(delegate,args).status=='pending');SandboxVars.B47ANCEDRooms.DelegatedRooms=false;R.tick()
assert(R.handle(delegate,'roomPoll',{nonce=args.nonce}).status=='RoomPolicyDisabled');SandboxVars.B47ANCEDRooms.DelegatedRooms=true
local W=require 'B47ANCEDRooms/Network';f.advance(3000);local lease=W.handle(delegate,'roomList',{protocol=1,renew=true})
args={protocol=1,action='copyPolicy',id=target,roomRevision=rev(target),sourceId=source,sourceRevision=rev(source),copyVisitors=true,revision=lease.revision,editKey=lease.editKey,nonce='network-copy'}
assert(W.handle(delegate,'roomChange',args).status=='pending');local result=finish(delegate,args,{status='pending'});assert(result.status=='ok')
local committed=R.library().revision;assert(R.handle(delegate,'roomChange',args).status=='ok' and R.library().revision==committed,'copy replay duplicated mutation')
parentOwner='new-parent';view=R.handle(delegate,'roomGet',{id=target}).room
assert(view.policyState=='suspended' and view.roomActions.deposit=='unknown' and not view.canConfigureRoom)
for _,m in ipairs(A.listRooms(delegate).rooms) do if m.id==target then assert(m.canConfigureRoom==false) end end
local lib=R.library();package.loaded['B47ANCEDRooms/Registry']=nil;local reload=require 'B47ANCEDRooms/Registry'
assert(I.equal(lib,(reload.library())),'reload changed copied state')
print('PASS OFFLINE policy copy: both-room authority, copied/retained visitor grants, source revisions/native gates, queued revocation, replay, transport, summary suspension and reload')
