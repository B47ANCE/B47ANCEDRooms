dofile(TEST_ROOT..'/fixtures/world.lua')
local f=CONTAINER_FIXTURE;local API=require 'B47ANCEDRooms/API';local R=B47ANCEDRooms.Registry
local native={getName=function() return 'kitchen' end,getIDString=function() return 'native-fixture-101' end,getZ=function() return 0 end,
 getX=function() return 0 end,getY=function() return 0 end,getX2=function() return 4 end,getY2=function() return 2 end}
local building={getRooms=function() return f.list({native}) end}
local obj={getDef=function() return building end}
for y=0,1 do for x=0,3 do
 local sq=f.squares[x..','..y..',0'] or f.square(x,y,0);local belongs=not (x==1 and y==1)
 sq.getRoomDef=function() return belongs and native or nil end;sq.building=obj
end end
getCell().createNewGridSquare=function() error('native room override mutated world geometry') end
local options=API.roomsAt(f.player,0,0,0);assert(options.status=='ok' and #options.rooms==1)
local id=options.rooms[1].id;assert(id=='native:native-fixture-101')
local snapshot=API.geometry(f.player,id,0)
for _=1,20 do if snapshot.status~='waiting' then break end;f.tick();snapshot=API.geometry(f.player,id,0) end
assert(snapshot.status=='ok' and B47ANCEDRooms.Geometry.normalize(snapshot.room.rows).count==7)
assert(not API.containsTile(f.player,id,0,1,1,0),'native bounds treated a hole as room geometry')
f.network(false,true)
local interact=SafeHouse.isSafehouseAllowInteract
SafeHouse.isSafehouseAllowInteract=function(square) return square:getX()~=3 end
assert(API.canAccess(f.player,id,'configureRoom').state=='deny','one allowed corner authorized the rest of a restricted native room')
SafeHouse.isSafehouseAllowInteract=function(square) return not (square:getX()==1 and square:getY()==1) end
assert(API.canAccess(f.player,id,'configureRoom').state=='allow','bounding-box hole was treated as room membership')
SafeHouse.isSafehouseAllowInteract=interact;f.network(false,false)
local sequence=0
local function write(args)
 local lease=API.beginEdit(f.player);sequence=sequence+1;args.revision=lease.revision;args.editKey=lease.editKey;args.nonce='native:'..sequence;args.confirm=true
 local result=API.change(f.player,args)
 for _=1,100 do if result.status~='pending' then return result end;R.tick();f.advance(16);result=R.handle(f.player,'roomPoll',{nonce=args.nonce}) end
 error('native override write stalled')
end
assert(write({action='save',name='Remodeled Pantry',nativeId=id,rows={{0,0,0,1}}}).status=='ok')
local override=API.resolveRoom(f.player,id);assert(override.status=='ok' and override.room.id~=id and override.room.name=='Remodeled Pantry')
assert(API.containsTile(f.player,id,nil,0,0,0) and not API.containsTile(f.player,id,nil,3,0,0))
assert(native:getName()=='kitchen' and f.squares['3,0,0']:getRoomDef()==native,'override rewrote native room metadata')
local source=override.room.id
assert(write({action='restore',id=source,roomRevision=1}).status=='ok')
assert(API.resolveRoom(f.player,id).room.native and API.containsTile(f.player,id,0,3,0,0))
assert(API.resolveRoom(f.player,source).status~='ok','deleted override identity silently rebound')
-- Merging overrides retains every native alias; restoring exposes both originals.
local native2={getName=function() return 'dining' end,getIDString=function() return 'native-fixture-102' end,getZ=function() return 0 end,
 getX=function() return 2 end,getY=function() return 0 end,getX2=function() return 4 end,getY2=function() return 2 end}
building.getRooms=function() return f.list({native,native2}) end
for y=0,1 do for x=2,3 do f.squares[x..','..y..',0'].getRoomDef=function() return native2 end end end
local id2='native:native-fixture-102'
assert(write({action='save',name='Kitchen',nativeId=id,rows={{0,0,0,1}}}).status=='ok')
assert(write({action='save',name='Dining',nativeId=id2,rows={{0,0,2,3}}}).status=='ok')
local first=API.resolveRoom(f.player,id).room;local second=API.resolveRoom(f.player,id2).room
assert(write({action='merge',id=first.id,roomRevision=first.revision,name='Kitchen Dining',ids={first.id,second.id},rows={{0,0,0,3}}}).status=='ok')
local combined=API.resolveRoom(f.player,id).room
assert(API.resolveRoom(f.player,id2).room.id==combined.id and combined.revision==2)
assert(#API.listRooms(f.player).nativeRooms==0,'merged native aliases leaked duplicate rows')
assert(write({action='restore',id=combined.id,roomRevision=2}).status=='ok')
assert(#API.listRooms(f.player).nativeRooms==2 and API.resolveRoom(f.player,id2).room.native)
native.getIDString=function() return nil end
assert(API.listRooms(f.player).status=='ok','missing native identity caused a list error')
print('PASS OFFLINE native room API: bounded exact membership, holes, independent override/name, stable alias resolution and restoration without native mutation')
