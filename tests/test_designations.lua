-- Disposable authoritative fixtures. No native save, network or MP proof.
dofile(TEST_ROOT..'/fixtures/world.lua')
local f=CONTAINER_FIXTURE;local A=require 'B47ANCEDRooms/API';local R=B47ANCEDRooms.Registry
local I=B47ANCEDRooms.Identity;local serial=0
local function write(args,player)
 player=player or f.player;local lease=A.beginEdit(player);serial=serial+1
 args.revision=lease.revision;args.editKey=lease.editKey;args.nonce='types:'..serial;args.confirm=true
 local result=A.change(player,args)
 for _=1,300 do if result.status~='pending' then return result end;R.tick();f.advance(16);result=R.handle(player,'roomPoll',{nonce=args.nonce}) end
 error('designation stalled')
end
local function rev(id) return R.library().records[id].revision end
assert(A.capabilities().roomDesignations==1 and A.capabilities().storageScopes==1)
local types=A.roomTypes();assert(#types.types==14 and #types.roles==3);types.types[1]='bad';assert(A.roomTypes().types[1]=='kitchen')
assert(write({action='save',name='Legacy',rows={{0,0,0,1}}}).status=='ok')
local id=A.listRooms(f.player).rooms[1].id
local old=R.library().records[id];old.roomType=nil;old.designation=nil
local before=I.copy((R.library()));assert(A.resolveRoom(f.player,id).room.roomType=='unassigned')
assert(R.handle(f.player,'roomGet',{id=id}).room.designation=='unassigned')
assert(I.equal(before,(R.library())),'read rewrote legacy records')
for _,bad in ipairs({'made-up',false,{},42}) do
 assert(write({action='designation',id=id,roomRevision=rev(id),roomType=bad,designation='primary'}).status=='RoomDesignationInvalid')
 assert(write({action='save',name='Invalid',rows={{0,0,0,0}},designation=bad}).status=='RoomDesignationInvalid')
end
assert(write({action='designation',id=id,roomRevision=rev(id),roomType='kitchen',designation='primary'}).status=='ok')
assert(A.permissions(f.player,id).canConfigureRoom and A.canAccess(f.player,id,'configureRoom').state=='allow')
assert(A.resolveRoom(f.player,id).room.designation=='primary')
assert(write({action='save',id=id,roomRevision=rev(id),name='Kitchen',rows={{0,0,0,1}}}).status=='ok')
assert(R.library().records[id].roomType=='kitchen','old save callers erased metadata')
assert(write({action='split',id=id,roomRevision=rev(id),name='Kitchen A',rows={{0,0,0,0}},secondName='Kitchen B',secondRows={{0,0,1,1}}}).status=='ok')
local second;for k,v in pairs(R.library().records) do assert(v.roomType=='kitchen' and v.designation=='primary');if k~=id then second=k end end
assert(write({action='designation',id=second,roomRevision=rev(second),roomType='pantry',designation='secondary'}).status=='ok')
assert(write({action='merge',id=id,roomRevision=rev(id),ids={id,second},name='Bad merge',rows={{0,0,0,1}}}).status=='RoomDenied')
assert(write({action='designation',id=second,roomRevision=rev(second),roomType='kitchen',designation='primary'}).status=='ok')
assert(write({action='merge',id=id,roomRevision=rev(id),ids={id,second},name='Kitchen',rows={{0,0,0,1}}}).status=='ok')
assert(not R.library().records[second] and R.library().records[id].designation=='primary')
-- Target-anchored scopes remain exact and permission checked outside edit range.
f.player.getX=function() return 1000 end;f.player.getY=function() return 1000 end
f.player.square=f.square(1000,1000,0)
assert(A.resolveRoom(f.player,id).status=='RoomOutOfRange')
local scopes=A.storageScopes(f.player,{obj=f.a});assert(scopes.status=='ok' and #scopes.rooms==1 and scopes.rooms[1].id==id)
assert(A.storageGeometry(f.player,id,rev(id),{obj=f.a}).room.roomType=='kitchen')
assert(#A.storageTiles(f.player,id,rev(id),{obj=f.a}).tiles==2)
assert(A.storageGeometry(f.player,id,0,{obj=f.a}).status=='conflict')
assert(A.storageGeometry(f.player,'native:old',nil,{obj=f.a}).status=='RoomUnavailable')
assert(#A.storageScopes(f.player,{obj=f.unrelatedObject}).rooms==0)
f.network(false,true);getOnlinePlayers=function() return f.list({f.player}) end
SafeHouse.isSafehouseAllowLoot=function() return false end
assert(A.storageScopes(f.player,{obj=f.a}).status~='ok','native denial bypassed by organization metadata')
SafeHouse.isSafehouseAllowLoot=function() return true end
f.network(true,false);assert(A.storageScopes(f.player,{obj=f.a}).status=='RoomPermissionUnavailable')
f.network(false,false);f.player.getX=function() return 0 end;f.player.getY=function() return 0 end;f.player.square=f.a.sq
f.square(0,0,2)
assert(write({action='save',id=id,roomRevision=rev(id),name='Floors',rows={{0,0,0,0},{2,0,0,0}},disconnected=true}).status=='ok')
local floors=A.listRooms(f.player).rooms[1].floors
assert(#floors==2 and floors[1]==0 and floors[2]==2,'floor metadata filled an undesignated intermediate floor')
-- Reload is idempotent. Future/corrupt fields are preserved and fail closed.
package.loaded['B47ANCEDRooms/Registry']=nil;local reload=require 'B47ANCEDRooms/Registry'
assert(reload.library().records[id].roomType=='kitchen');local lib=reload.library()
lib.records[id].roomType='unsupported';package.loaded['B47ANCEDRooms/Registry']=nil
local corrupt=require 'B47ANCEDRooms/Registry';local value,reason=corrupt.library();assert(not value and reason=='schema')
assert(ModData.getOrCreate('B47ANCEDRooms').customRooms==lib,'corruption reset saved data')
print('PASS OFFLINE designations: legacy defaults/read purity, enum validation, create/edit/split/merge/reload, copied catalog, target-anchored scopes, native/client denial and corrupt-data preservation')
