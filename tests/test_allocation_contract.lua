-- Actual provider contract; disposable server fixtures, never native MP proof.
dofile(TEST_ROOT..'/fixtures/world.lua')
local f=CONTAINER_FIXTURE;local A=require 'B47ANCEDRooms/API';local R=B47ANCEDRooms.Registry
local lease=A.beginEdit(f.player)
local result=A.create(f.player,{name='Allocation contract',rows={{0,0,0,1}},roomType='storage',designation='primary',revision=lease.revision,editKey=lease.editKey,nonce='contract-create'})
for _=1,300 do
 if result.status~='pending' then break end
 R.tick();f.advance(16);result=R.handle(f.player,'roomPoll',{nonce='contract-create'})
end
assert(result.status=='ok')
local room=A.listRooms(f.player).rooms[1];local target={obj=f.a}
local caps=A.capabilities();assert(caps.storageScopes==1 and caps.roomDesignations==1 and caps.designatedRooms and not caps.nativeOverrides)
-- Retain the fixture creator identity when switching to native permission stubs.
f.player.getUsername=function() return 'local:0' end
f.network(false,true)
-- Every tile must pass native configuration permission, even for the creator.
SafeHouse.isSafehouseAllowInteract=function(square) return square:getX()~=1 end
assert(A.canAccess(f.player,room.id,'configureRoom').state=='deny','first-tile permission substituted for complete footprint')
SafeHouse.isSafehouseAllowInteract=function() return true end
local tile=f.squares['1,0,0'];f.squares['1,0,0']=nil
assert(A.canAccess(f.player,room.id,'configureRoom').state=='unknown','unloaded member became configuration permission')
f.squares['1,0,0']=tile
assert(A.canAccess(f.player,room.id,'configureRoom').state=='allow')
local snapshot=A.storageGeometry(f.player,room.id,room.revision,target)
assert(snapshot.status=='ok');snapshot.room.rows[1][4]=999
assert(#A.storageTiles(f.player,room.id,room.revision,target).tiles==2,'consumer mutated saved geometry')
local scopes=A.storageScopes(f.player,target);scopes.rooms[1].designation='secondary'
assert(A.storageScopes(f.player,target).rooms[1].designation=='primary','consumer mutated saved designation')
assert(A.storageTiles(f.player,'native:retired',nil,target).status=='RoomUnavailable')
SandboxVars.B47ANCEDRooms.Enabled=false
assert(A.storageScopes(f.player,target).status~='ok','disabled provider authorized storage')
SandboxVars.B47ANCEDRooms.Enabled=true
SafeHouse.isSafehouseAllowLoot=function() return false end
assert(A.storageTiles(f.player,room.id,room.revision,target).status~='ok','organization bypassed gameplay denial')
SafeHouse.isSafehouseAllowLoot=function() return true end
f.network(true,false)
assert(A.storageScopes(f.player,target).status=='RoomPermissionUnavailable')
print('PASS OFFLINE allocation provider: designated-only capabilities, complete-footprint/native-denial/unloaded/client/disabled guards and independent geometry/metadata snapshots')
