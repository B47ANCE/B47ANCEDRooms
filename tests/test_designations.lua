dofile(TEST_ROOT..'/fixtures/world.lua')
local f=CONTAINER_FIXTURE;f.network(false,true)
local API=require 'B47ANCEDRooms/API';local R=B47ANCEDRooms.Registry
local members={delegate=true,other=true}
local house={getId=function() return 'house-id' end,getOwner=function() return 'fixture-player' end,
 getX=function() return -2 end,getY=function() return -2 end,getX2=function() return 10 end,getY2=function() return 10 end}
function house:getPlayers() local list=f.list({'delegate','other'});list.contains=function(_,who) return members[who]==true end;return list end
SafeHouse.getSafehouseList=function() return f.list({house}) end
local function actor(who)
 return {getUsername=function() return who end,getPlayerNum=function() return 1 end,getAccessLevel=function() return 'None' end,
 getCurrentSquare=function() return f.a.sq end,getX=function() return 0 end,getY=function() return 0 end,isDead=function() return false end}
end
local delegate,other=actor('delegate'),actor('other');getOnlinePlayers=function() return f.list({f.player,delegate,other}) end
local serial=0
local function write(player,args)
 local lease=API.beginEdit(player);serial=serial+1
 args.nonce='designation:'..serial;args.editKey=lease.editKey;args.revision=lease.revision
 local result=API.change(player,args)
 for _=1,100 do if result.status~='pending' then return result end;f.advance(16);R.tick();result=R.handle(player,'roomPoll',{nonce=args.nonce}) end
 error('designation stalled')
end
assert(write(f.player,{action='save',name='Kitchen',rows={{0,0,0,1}}}).status=='ok')
local id=API.listRooms(f.player).rooms[1].id
assert(write(f.player,{action='assign',id=id,roomRevision=1,assigned='delegate'}).status=='ok')
assert(write(delegate,{action='policy',id=id,roomRevision=2,policy={mode='private',rules={},grants={}}}).status=='ok')
assert(write(delegate,{action='designation',id=id,roomRevision=3,roomType='kitchen',designation='primary'}).status=='ok')
local room=API.resolveRoom(f.player,id).room
assert(room.roomType=='kitchen' and room.designation=='primary' and room.revision==4)
assert(API.canAccessAt(f.player,0,0,0,'deposit').state=='deny','Primary role granted parent-owner gameplay access')
assert(write(other,{action='designation',id=id,roomRevision=4,roomType='storage',designation='secondary'}).status=='RoomDenied')
assert(write(delegate,{action='designation',id=id,roomRevision=3,roomType='storage',designation='secondary'}).status=='conflict')
assert(write(delegate,{action='designation',id=id,roomRevision=4,roomType='InventedCategory',designation='primary'}).status=='RoomDenied')
assert(write(delegate,{action='save',id=id,roomRevision=4,name='Kitchen renamed',rows={{0,0,0,1}}}).status=='ok')
room=API.resolveRoom(delegate,id).room;assert(room.roomType=='kitchen' and room.designation=='primary' and room.revision==5)
assert(API.capabilities().roomDesignations==1 and #API.roomTypes().types==14)
print('PASS OFFLINE room designations: stable metadata, authorized parent/delegate edits, no gameplay grants, stale/forged roles rejected and tags preserved through ordinary rename')
