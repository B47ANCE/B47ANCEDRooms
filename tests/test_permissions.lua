dofile(TEST_ROOT..'/fixtures/world.lua')
local f=CONTAINER_FIXTURE;f.network(false,true)
local API=require 'B47ANCEDRooms/API';local R=B47ANCEDRooms.Registry;local P=B47ANCEDRooms.Policy
local members={B=true,C=true};local parentOwner='fixture-player';local maxX=10
local h={getId=function() return 'stable-house-id' end,getTitle=function() return 'Different title' end,getOwner=function() return parentOwner end,
 getX=function() return -1 end,getY=function() return -1 end,getX2=function() return maxX end,getY2=function() return 10 end}
function h:getPlayers() local out={};for who in pairs(members) do out[#out+1]=who end;local list=f.list(out);list.contains=function(_,who) return members[who]==true end;return list end
SafeHouse.getSafehouseList=function() return f.list({h}) end
SafeHouse.getSafeHouse=function() error('title overload must not resolve stable house IDs') end
local nativeAllowed=true
SafeHouse.isSafehouseAllowLoot=function() return nativeAllowed end
SafeHouse.isSafehouseAllowInteract=function() return nativeAllowed end
local function actor(who,admin)
 return {getUsername=function() return who end,getAccessLevel=function() return admin and 'admin' or 'None' end,getPlayerNum=function() return 0 end,
 getCurrentSquare=function() return f.a.sq end,getX=function() return 0 end,getY=function() return 0 end,getZ=function() return 0 end,isDead=function() return false end}
end
local a,b,c,z= f.player,actor('B'),actor('C'),actor('new-parent')
local administrator=actor('administrator',true)
getOnlinePlayers=function() return f.list({a,b,c,z,administrator}) end
local nonce=0
local function write(player,args)
 local lease=API.beginEdit(player);assert(lease.status=='ok');nonce=nonce+1
 args.revision=lease.revision;args.editKey=lease.editKey;args.nonce='permission-test:'..nonce;args.confirm=true
 local result=API.change(player,args)
 for _=1,300 do
  if result.status~='pending' then return result end
  f.advance(16);R.tick();result=R.handle(player,'roomPoll',{nonce=args.nonce})
 end
 error('permission fixture validation stalled')
end
local function revision(id) return R.library().records[id].revision end
assert(write(a,{action='save',name='Private Bedroom',rows={{0,0,0,0}}}).status=='ok')
local id=API.listRooms(a).rooms[1].id
assert(write(c,{action='assign',id=id,roomRevision=revision(id),assigned='C'}).status=='RoomDenied')
assert(write(a,{action='assign',id=id,roomRevision=revision(id),assigned='B'}).status=='ok')
assert(write(b,{action='policy',id=id,roomRevision=revision(id),policy={mode='private',rules={},grants={}}}).status=='ok')
assert(API.canAccessAt(b,0,0,0,'withdraw').state=='allow')
assert(API.canAccessAt(a,0,0,0,'withdraw').state=='deny','parent owner received gameplay bypass')
assert(API.canAccessAt(administrator,0,0,0,'withdraw').state=='deny','admin received gameplay bypass')
assert(API.permissions(a,id).canAssign and API.permissions(b,id).assigned=='B')
assert(write(b,{action='designation',id=id,roomRevision=revision(id),roomType='bedroom',designation='secondary'}).status=='ok')
assert(write(c,{action='designation',id=id,roomRevision=revision(id),roomType='armory',designation='primary'}).status=='RoomDenied')
assert(write(c,{action='save',id=id,roomRevision=revision(id),name='Forged',rows={{0,0,0,0}},roomType='armory'}).status=='RoomDenied')
-- Parent invalidation after admission revokes designation authority even when
-- rename membership remains valid. No partial metadata write may persist.
local lease=API.beginEdit(b);local prior=R.library()
assert(API.setDesignation(b,{id=id,roomRevision=revision(id),revision=lease.revision,editKey=lease.editKey,nonce='pending-designation',roomType='medical',designation='primary'}).status=='pending')
maxX=9;R.tick();assert(R.handle(b,'roomPoll',{nonce='pending-designation'}).status=='RoomDenied')
assert(R.library()==prior and R.library().records[id].roomType=='bedroom');maxX=10
assert(API.canAccessAt(c,0,0,0,'discover').state=='deny')
-- A guest can deposit without getting withdrawal or content inspection.
local policy={mode='private',rules={},grants={C={discover=true,deposit=true}}}
assert(write(b,{action='policy',id=id,roomRevision=revision(id),policy=policy}).status=='ok')
assert(API.canAccessAt(c,0,0,0,'deposit').state=='allow' and API.canAccessAt(c,0,0,0,'withdraw').state=='deny')
assert(API.canAccessAt(c,0,0,0,'inspect').state=='deny' and API.canAccessAt(c,0,0,0,'configure').state=='deny')
assert(API.storageScopes(c,{obj=f.a}).rooms[1].roomType=='bedroom')
assert(API.storageScopes(a,{obj=f.a}).status~='ok','parent metadata rights bypassed private deposit rules')
nativeAllowed=false;assert(API.canAccessAt(b,0,0,0,'withdraw').state=='deny');nativeAllowed=true
-- Permission snapshots are detached; callers cannot mutate persisted policy.
local snapshot=API.permissions(b,id);snapshot.policy.grants.C.withdraw=true
assert(API.canAccessAt(c,0,0,0,'withdraw').state=='deny')
-- Delegated expansion becomes a pending proposal, never an immediate boundary.
assert(write(b,{action='save',id=id,roomRevision=revision(id),name='Bedroom',rows={{0,0,0,1}}}).status=='ok')
assert(not API.containsTile(b,id,nil,1,0,0) and R.library().records[id].pendingBoundary)
assert(write(b,{action='approveBoundary',id=id,roomRevision=revision(id)}).status=='RoomDenied')
assert(write(a,{action='approveBoundary',id=id,roomRevision=revision(id)}).status=='ok')
assert(API.containsTile(b,id,nil,1,0,0) and not R.library().records[id].pendingBoundary)
-- Private overlap is rejected atomically while organizational overlap is valid.
assert(write(a,{action='save',name='Overlap',rows={{0,0,0,0}}}).status=='ok')
local other;for _,room in ipairs(API.listRooms(a).rooms) do if room.id~=id then other=room.id end end
assert(write(a,{action='assign',id=other,roomRevision=revision(other),assigned='C'}).status=='ok')
local before=R.library()
assert(write(c,{action='policy',id=other,roomRevision=revision(other),policy={mode='private',rules={},grants={}}}).status=='RoomProtectedOverlap')
assert(R.library()==before and API.canAccessAt(b,0,0,0,'withdraw').state=='allow')
-- Parent changes suspend enforcement until that parent explicitly revalidates.
maxX=8;assert(API.canAccessAt(b,0,0,0,'withdraw').state=='unknown')
assert(write(b,{action='policy',id=id,roomRevision=revision(id),policy=policy}).status~='ok')
assert(write(a,{action='policy',id=id,roomRevision=revision(id),policy=policy}).status=='ok')
parentOwner='new-parent';assert(API.canAccessAt(b,0,0,0,'withdraw').state=='unknown')
assert(write(z,{action='policy',id=id,roomRevision=revision(id),policy=policy}).status=='ok')
assert(API.canAccessAt(z,0,0,0,'withdraw').state=='deny')
members.B=nil;assert(API.canAccessAt(b,0,0,0,'withdraw').state=='unknown');members.B=true
assert(write(z,{action='assign',id=id,roomRevision=revision(id),assigned='C'}).status=='ok')
assert(API.canAccessAt(b,0,0,0,'withdraw').state=='deny' and API.canAccessAt(c,0,0,0,'withdraw').state=='allow','reassignment opened a temporary shared-storage gap')
assert(write(c,{action='policy',id=id,roomRevision=revision(id),policy={mode='private',rules={},grants={}}}).status=='ok')
assert(API.canAccessAt(b,0,0,0,'withdraw').state=='deny' and API.canAccessAt(c,0,0,0,'withdraw').state=='allow')
assert(API.canAccess(c,id,'enter').state=='unknown')
SafeHouse.getSafehouseList=function() return f.list() end
assert(API.canAccessAt(c,0,0,0,'withdraw').state=='unknown','deleted parent fell back to shared access')
print('PASS OFFLINE delegated permissions: exact house ID, independent actions, no parent/admin gameplay bypass, guest deposit privacy, native rules, immutable snapshots, approval, overlap, reassignment, revocation and parent deletion')
