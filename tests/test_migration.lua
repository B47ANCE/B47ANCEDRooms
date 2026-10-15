dofile(TEST_ROOT..'/fixtures/world.lua')
local f=CONTAINER_FIXTURE
local root='11111111-1111-1111-1111-111111111111';local id=root..':22222222-2222-2222-2222-222222222222'
local old={schema=1,world=root,revision=8,serial=1,records={[id]={id=id,ordinal=1,name='Legacy Storage',owner='local:0',revision=3,rows={{0,0,0,1}},createdAt=10,updatedAt=20}}}
local original=ModData.getOrCreate('B47ANCEDQuartermaster');original.customRooms=old;original.unrelated={keep=true}
local API=require 'B47ANCEDRooms/API'
local result=API.resolveRoom(f.player,id,3);assert(result.status=='ok' and result.room.id==id)
local migrated=ModData.get('B47ANCEDRooms').customRooms
assert(migrated.schema==2 and migrated~=old and migrated.records[id]~=old.records[id])
assert(original.customRooms==old and old.schema==1 and old.revision==8 and original.unrelated.keep)
migrated.records[id].name='Imported Name';assert(old.records[id].name=='Legacy Storage')
local same=migrated
package.loaded['B47ANCEDRooms/Registry']=nil
local R=require 'B47ANCEDRooms/Registry';assert(R.library()==same,'reimport replaced authoritative Rooms state')
ModData.get('B47ANCEDRooms').customRooms={schema=99,records={}}
assert(R.library()==nil and ModData.get('B47ANCEDRooms').customRooms.schema==99)
assert(original.customRooms==old,'future/corrupt new schema deleted legacy recovery data')
print('PASS OFFLINE migration: independent root, stable IDs/revisions, copied ownership, unchanged original data, idempotent reload and future-schema preservation')
