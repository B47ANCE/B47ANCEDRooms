dofile(TEST_ROOT..'/fixtures/world.lua')
local f=CONTAINER_FIXTURE
local G=require 'B47ANCEDRooms/Geometry'
local D=require 'B47ANCEDRooms/Detection'
local function inside(x,y) return x>=0 and x<4 and y>=0 and y<2 end
local doorBoundary=true;local doorway=false
local definition={getX=function() return 0 end,getY=function() return 0 end,getX2=function() return 4 end,getY2=function() return 2 end,getZ=function() return 0 end}
for y=-1,2 do for x=-1,4 do
 local xx,yy=x,y;local sq=f.squares[x..','..y..',0'] or f.square(x,y,0)
 function sq:isWallTo(other)
  if inside(xx,yy)~=inside(other:getX(),other:getY()) then return true end
  return doorBoundary and yy==1 and other:getY()==1 and math.min(xx,other:getX())==1 and math.max(xx,other:getX())==2
 end
 function sq:isWindowTo() return false end
 function sq:isDoorTo(other) return doorway and self:getY()==other:getY() and math.min(self:getX(),other:getX())==1 and math.max(self:getX(),other:getX())==2 end
 function sq:isBlockedTo() return false end
 function sq:getRoomDef() if inside(xx,yy) and not (xx==1 and yy==1) then return definition end end
end end
-- An open actual door stays a boundary even when movement and door flags allow passage.
local anchor=f.squares['2,0,0'];local door={class='IsoDoor',getNorth=function() return false end,IsOpen=function() return true end}
anchor.objects[#anchor.objects+1]=door
local function detect(native,limit,frames,doorways)
 local job=assert(D.start(f.a.sq,native,limit,doorways))
 for n=1,frames or 256 do f.advance(16);D.step(job);if job.done then return job,n end end
 error('detection did not finish')
end
local job=detect(false,1024);assert(not job.incomplete and job.geometry.count==4,'open door leaked into adjoining space')
table.remove(anchor.objects);doorBoundary=false
job=detect(false,1024);assert(not job.incomplete and job.geometry.count==8,'demolished boundary remained closed')
doorway=true;job=detect(false,1024,nil,true);assert(job.geometry.count==4)
job=detect(false,1024,nil,false);assert(job.geometry.count==8,'doorless doorway policy ignored')
doorway=false;job=detect(true,1024)
assert(job.geometry.count==7 and not G.contains(job.geometry,1,1,0),'native bounds included a different room tile')
job=detect(false,3);assert(job.done and job.incomplete=='RoomDetectionLimit' and not job.geometry,'truncation appeared complete')
local outside=f.squares['-1,0,0'];f.squares['-1,0,0']=nil
job=detect(false,1024);assert(job.incomplete=='RoomUnloaded','missing world data inferred as a complete wall')
f.squares['-1,0,0']=outside
-- Candidate jobs have no persistence or network path and never add another floor.
local root=ModData.getOrCreate('B47ANCEDRooms')
assert(not root.customRooms)
for _,tile in ipairs(detect(false,1024).geometry.tiles) do assert(tile.z==0) end
-- A wall on one edge must not hide a tile reachable by going around the wall.
for _,sq in pairs(f.squares) do function sq:isWallTo(other)
 if inside(self:getX(),self:getY())~=inside(other:getX(),other:getY()) then return true end
 return self:getY()==0 and other:getY()==0 and math.min(self:getX(),other:getX())==0 and math.max(self:getX(),other:getX())==1
end end
job=detect(false,1024);assert(not job.incomplete and job.geometry.count==8,'blocked neighbor was marked visited before a valid alternate path')
print('PASS OFFLINE room detection: loaded bounded cooperative candidates, open door identity, demolished wall, doorless policy, exact native membership, unloaded/limit rejection and no persistence/floor expansion')
