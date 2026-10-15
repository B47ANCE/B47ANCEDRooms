local I=require 'B47ANCEDRooms/Identity'
local G=require 'B47ANCEDRooms/Geometry'
local M={};B47ANCEDRooms.LegacyImport=M
-- Data-only import of the former owner's namespace. No runtime dependency,
-- writes or deletion in that namespace; it remains rollback evidence.
function M.read()
 if isClient() then return nil,'invalid' end
 if not ModData.get then return nil,'unavailable' end
 local source=ModData.get('B47ANCEDQuartermaster')
 local old=source and source.customRooms
 if old==nil then return nil end
 if type(old)~='table' or old.schema~=1 or type(old.records)~='table' then return nil,'RoomMigrationConflict' end
 if type(old.world)~='string' or #old.world~=36 or type(old.serial)~='number' or type(old.revision)~='number' then return nil,'RoomMigrationConflict' end
 local n,total=0,0
 for id,r in pairs(old.records) do
  n=n+1;local g=type(r)=='table' and G.normalize(r.rows)
  if n>128 or type(id)~='string' or r.id~=id or not g or g.count<1 or type(r.owner)~='string' or type(r.revision)~='number' then return nil,'RoomMigrationConflict' end
  total=total+g.count;if total>16384 then return nil,'RoomMigrationConflict' end
 end
 local out=I.copy(old);out.schema=2
 return out,{world=old.world,revision=old.revision}
end
return M
