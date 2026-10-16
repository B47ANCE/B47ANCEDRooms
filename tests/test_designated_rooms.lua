dofile(TEST_ROOT..'/fixtures/world.lua')
local f=CONTAINER_FIXTURE
local world='11111111-1111-1111-1111-111111111111'
local id=world..':22222222-2222-2222-2222-222222222222'
local aliases={'native:old-kitchen','native:old-dining'}
local room={id=id,ordinal=1,name='Remodeled Pantry',owner='local:0',revision=3,rows={{0,0,0,1}},createdAt=10,updatedAt=20,
 nativeId=aliases[1],nativeIds=aliases,policy={mode='shared',rules={clean='none'},grants={guest={deposit=true}}},pendingBoundary={{0,0,0,0}}}
local lib={schema=2,world=world,revision=7,serial=1,records={[id]=room}}
ModData.getOrCreate('B47ANCEDRooms').customRooms=lib
local bd={getRooms=function() error('vanilla room enumeration') end}
local building={getDef=function() return bd end}
for _,sq in pairs(f.squares) do
 sq.building=building;sq.getRoomDef=function() error('vanilla room definition read') end
end
local A=require 'B47ANCEDRooms/API';local R=B47ANCEDRooms.Registry
assert(not package.loaded['B47ANCEDRooms/Native'] and not A.capabilities().nativeOverrides)
assert(A.capabilities().designatedRooms)
local before=B47ANCEDRooms.Identity.copy(lib)
assert(A.resolveRoom(f.player,id,3).status=='ok')
assert(A.geometry(f.player,id,3).room.rows[1][4]==1)
assert(A.containsTile(f.player,id,3,1,0,0) and not A.containsTile(f.player,id,3,2,0,0))
assert(#A.roomsAt(f.player,0,0,0).rooms==1 and #A.roomsAt(f.player,2,0,0).rooms==0)
local list=A.listRooms(f.player,{building=true})
assert(#list.rooms==1 and list.nativeRooms==nil and list.rooms[1].nativeId==nil)
for _,alias in ipairs(aliases) do
 assert(A.resolveRoom(f.player,alias).status=='RoomUnavailable')
 assert(not A.containsTile(f.player,alias,nil,0,0,0))
end
assert(R.handle(f.player,'nativeGet',{id=aliases[1]}).status=='invalid')
assert(A.restoreVanilla(f.player,{id=id}).status=='RoomPermissionUnsupported')
assert(B47ANCEDRooms.Identity.equal(lib,before),'read/retired helper changed the persisted legacy record')
local sequence=0
local function write(args)
 local lease=A.beginEdit(f.player);sequence=sequence+1
 args.revision=lease.revision;args.editKey=lease.editKey;args.nonce='designated:'..sequence;args.confirm=true
 local result=A.change(f.player,args)
 for _=1,100 do
  if result.status~='pending' then return result end
  R.tick();f.advance(16);result=R.handle(f.player,'roomPoll',{nonce=args.nonce})
 end
 error('designated write stalled')
end
assert(write({action='restore',id=id,roomRevision=3}).status=='RoomPermissionUnsupported')
assert(R.library()==lib,'obsolete restore deleted or rewrote existing state')
assert(write({action='save',nativeId=aliases[1],name='Bad import',rows={{0,0,0,0}}}).status=='invalid')
assert(write({action='save',id=id,roomRevision=3,name='Pantry',rows={{0,0,0,1}}}).status=='ok')
local current=R.library().records[id]
assert(current.id==id and current.revision==4 and current.nativeId==aliases[1])
assert(B47ANCEDRooms.Identity.equal(current.policy,room.policy))
assert(B47ANCEDRooms.Identity.equal(R.library().records[id].rows,room.rows))
assert(R.handle(f.player,'roomGet',{id=id,roomRevision=4}).room.nativeId==nil)
package.loaded['B47ANCEDRooms/Registry']=nil
local reload=require 'B47ANCEDRooms/Registry';assert(reload.library().records[id].id==id)
assert(A.resolveRoom(f.player,aliases[1]).status=='RoomUnavailable','reload reactivated legacy aliases')
local network=require 'B47ANCEDRooms/Network'
local visible=network.handle(f.player,'roomList',{protocol=1})
assert(visible.status=='ok' and #visible.rooms==1 and visible.nativeRooms==nil)
-- Building filtering is independent of room definitions, and has no exterior fallback.
f.player.square.building=nil;assert(#A.listRooms(f.player,{building=true}).rooms==0)
assert(#A.listRooms(f.player).rooms==1,'general managed-room API lost designated geometry')
print('PASS OFFLINE designated rooms: no vanilla definitions, stable legacy geometry/IDs/policy/reload, inert aliases, rejected restore/import, exact membership and current-building filtering')
