-- Candidate preview only. No writes, RPC, chunk loading or saved-room mutation.
local G=require 'B47ANCEDRooms/Geometry'
local D={};B47ANCEDRooms.Detection=D
local function structuralObject(a,b,doorways)
 for _,sq in ipairs({a,b}) do
  local objects=sq:getObjects()
  if objects:size()>512 then return nil,'RoomDetectionLimit' end
  for i=0,objects:size()-1 do
   local obj=objects:get(i)
   local boundary=instanceof(obj,'IsoDoor') or instanceof(obj,'IsoWindow')
    or instanceof(obj,'IsoThumpable') and (obj:isDoor() or doorways and obj:isDoorFrame())
   if boundary then
    -- Orientation is the physical doorway/window edge, independent of IsOpen.
    local north=obj:getNorth()
    if north and a:getX()==b:getX() and sq:getY()==math.max(a:getY(),b:getY())
     or not north and a:getY()==b:getY() and sq:getX()==math.max(a:getX(),b:getX()) then return true end
   end
  end
 end
 return false
end
function D.start(square,native,limit,doorways)
 if not square then return nil,'RoomUnloaded' end
 local seed={x=square:getX(),y=square:getY(),z=square:getZ()}
 local room=native and square:getRoomDef()
 if native and not room then return nil,'RoomNoNative' end
 local bounds
 if room then
  local width,height=room:getX2()-room:getX(),room:getY2()-room:getY()
  if width<1 or height<1 or width>G.extentLimit or height>G.extentLimit then return nil,'RoomDetectionLimit' end
  bounds={x=room:getX(),y=room:getY(),z=room:getZ(),width=width,height=height}
 end
 return {queue={seed},seen={[G.key(seed.x,seed.y,seed.z)]=true},tiles={},index=1,seed=seed,
  native=room,bounds=bounds,limit=math.min(limit or 1024,G.tileLimit),doorways=doorways~=false}
end
function D.step(job)
 if job.done then return job end
 local start=getTimestampMs();local work=0
 if job.native then
  local b=job.bounds;local total=b.width*b.height
  while job.index<=total and work<64 and getTimestampMs()-start<4 do
   local offset=job.index-1;job.index=job.index+1;work=work+1
   local x,y=b.x+offset%b.width,b.y+math.floor(offset/b.width)
   local sq=getCell():getGridSquare(x,y,b.z)
   if not sq then job.incomplete='RoomUnloaded';job.done=true;break end
   if sq:getRoomDef()==job.native then job.tiles[#job.tiles+1]={x=x,y=y,z=b.z} end
   if #job.tiles>job.limit then job.incomplete='RoomDetectionLimit';job.done=true;break end
  end
  if job.index>total then job.done=true end
  if job.done then
   if #job.tiles<=job.limit then job.geometry=G.fromTiles(job.tiles,job.limit) end
   if not job.geometry then job.incomplete=job.incomplete or 'RoomDetectionLimit' end
  end
  return job
 end
 while job.index<=#job.queue and work<64 and getTimestampMs()-start<4 do
  local p=job.queue[job.index];job.index=job.index+1;work=work+1
  local sq=getCell():getGridSquare(p.x,p.y,p.z)
  if not sq then job.incomplete='RoomUnloaded';job.done=true;break end
  if not job.native or sq:getRoomDef()==job.native then
   job.tiles[#job.tiles+1]=p
   if #job.tiles>job.limit then job.incomplete='RoomDetectionLimit';job.done=true;break end
   for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
    local x,y=p.x+d[1],p.y+d[2];local key=G.key(x,y,p.z)
    if not job.seen[key] then
     if math.abs(x-job.seed.x)>=G.extentLimit or math.abs(y-job.seed.y)>=G.extentLimit then job.incomplete='RoomDetectionLimit';job.done=true;break end
     local other=getCell():getGridSquare(x,y,p.z)
     if not other then job.incomplete='RoomUnloaded';job.done=true;break end
     local boundary=job.native and other:getRoomDef()~=job.native
     if not job.native then
      local edge,e=structuralObject(sq,other,job.doorways)
      if e then job.incomplete=e;job.done=true;break end
      boundary=edge or sq:isWallTo(other) or sq:isWindowTo(other) or (job.doorways and sq:isDoorTo(other)) or sq:isBlockedTo(other)
     end
     -- A blocked edge does not make its opposite tile unreachable from a
     -- different neighbor. Mark visited only when it enters the work queue.
     if not boundary then job.seen[key]=true;job.queue[#job.queue+1]={x=x,y=y,z=p.z} end
    end
   end
  end
 end
 if job.index>#job.queue then job.done=true end
 if job.done then
  if #job.tiles<=job.limit then job.geometry=G.fromTiles(job.tiles,job.limit) end
  if not job.geometry then job.incomplete=job.incomplete or 'RoomDetectionLimit' end
 end
 return job
end
return D
