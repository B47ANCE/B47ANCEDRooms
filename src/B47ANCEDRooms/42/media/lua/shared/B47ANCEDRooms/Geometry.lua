-- Pure bounded tile algebra. Rows are inclusive {z,y,x1,x2}, never world objects.
require 'B47ANCEDRooms/Identity'
local G={tileLimit=4096,rowLimit=512,extentLimit=128};B47ANCEDRooms.Geometry=G
local function int(n) return type(n)=='number' and n==n and math.abs(n)<10000000 and n==math.floor(n) end
local function plain(t) return type(t)=='table' and getmetatable(t)==nil end
local function array(t,max)
 if not plain(t) or #t>max then return false end
 local n=0;for k in pairs(t) do if not int(k) or k<1 or k>#t then return false end;n=n+1 end
 return n==#t
end
G.integer=int;G.array=array
function G.key(x,y,z) return z..':'..y..':'..x end
function G.normalize(rows,limit)
 if not array(rows,G.rowLimit) then return nil,'RoomGeometryInvalid' end
 local tiles,seen={},{};limit=math.min(limit or G.tileLimit,G.tileLimit)
 for _,r in ipairs(rows) do
  if not array(r,4) or #r~=4 then return nil,'RoomGeometryInvalid' end
  local z,y,a,b=unpack(r)
  if not int(z) or z< -32 or z>31 or not int(y) or not int(a) or not int(b) or b<a or b-a>=G.extentLimit then return nil,'RoomGeometryInvalid' end
  for x=a,b do
   local key=G.key(x,y,z)
   if not seen[key] then
    seen[key]=true;tiles[#tiles+1]={x=x,y=y,z=z}
    if #tiles>limit then return nil,'RoomTooLarge' end
   end
  end
 end
 table.sort(tiles,function(a,b) if a.z~=b.z then return a.z<b.z end;if a.y~=b.y then return a.y<b.y end;return a.x<b.x end)
 local out={};local bounds
 for _,t in ipairs(tiles) do
  if not bounds then bounds={x1=t.x,x2=t.x,y1=t.y,y2=t.y,z1=t.z,z2=t.z} end
  bounds.x1=math.min(bounds.x1,t.x);bounds.x2=math.max(bounds.x2,t.x)
  bounds.y1=math.min(bounds.y1,t.y);bounds.y2=math.max(bounds.y2,t.y);bounds.z1=math.min(bounds.z1,t.z);bounds.z2=math.max(bounds.z2,t.z)
  if bounds.x2-bounds.x1>=G.extentLimit or bounds.y2-bounds.y1>=G.extentLimit or bounds.z2-bounds.z1>=8 then return nil,'RoomTooLarge' end
  local last=out[#out]
  if last and last[1]==t.z and last[2]==t.y and last[4]+1==t.x then last[4]=t.x else out[#out+1]={t.z,t.y,t.x,t.x} end
 end
 if #out>G.rowLimit then return nil,'RoomTooLarge' end
 return {rows=out,tiles=tiles,set=seen,count=#tiles,bounds=bounds}
end
function G.contains(g,x,y,z) return g and g.set[G.key(x,y,z)]==true end
function G.edit(rows,addition,remove,limit)
 local a,e=G.normalize(rows);if not a then return nil,e end
 local b;b,e=G.normalize(addition);if not b then return nil,e end
 -- Normalize row-run count after combination, rather than sending one row/tile.
 local tiles={};for _,t in ipairs(a.tiles) do if not remove or not G.contains(b,t.x,t.y,t.z) then tiles[G.key(t.x,t.y,t.z)]=t end end
 if not remove then for _,t in ipairs(b.tiles) do tiles[G.key(t.x,t.y,t.z)]=t end end
 local list={};for _,t in pairs(tiles) do list[#list+1]=t end
 return G.fromTiles(list,limit)
end
function G.fromTiles(tiles,limit)
 if #tiles>G.tileLimit*2 then return nil,'RoomTooLarge' end
 table.sort(tiles,function(a,b) if a.z~=b.z then return a.z<b.z end;if a.y~=b.y then return a.y<b.y end;return a.x<b.x end)
 local rows={}
 for _,t in ipairs(tiles) do
  local r=rows[#rows]
  if r and r[1]==t.z and r[2]==t.y and t.x>=r[3] and t.x<=r[4]+1 then r[4]=math.max(r[4],t.x) else rows[#rows+1]={t.z,t.y,t.x,t.x} end
 end
 return G.normalize(rows,limit)
end
function G.rectangle(a,b)
 if not a or not b or a.z~=b.z then return nil,'RoomSameFloor' end
 for _,p in ipairs({a,b}) do for _,k in ipairs({'x','y','z'}) do if not int(p[k]) then return nil,'RoomGeometryInvalid' end end end
 if math.abs(a.x-b.x)>=G.extentLimit or math.abs(a.y-b.y)>=G.extentLimit then return nil,'RoomTooLarge' end
 local rows={};for y=math.min(a.y,b.y),math.max(a.y,b.y) do rows[#rows+1]={a.z,y,math.min(a.x,b.x),math.max(a.x,b.x)} end
 return G.normalize(rows)
end
function G.components(g)
 local seen={};local count=0
 for _,seed in ipairs(g.tiles) do
  local key=G.key(seed.x,seed.y,seed.z)
  if not seen[key] then
   count=count+1;local q={seed};seen[key]=true;local i=1
   while i<=#q do
    local t=q[i];i=i+1
    for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
     local x,y=t.x+d[1],t.y+d[2];local k=G.key(x,y,t.z)
     if g.set[k] and not seen[k] then seen[k]=true;q[#q+1]={x=x,y=y,z=t.z} end
    end
   end
  end
 end
 return count
end
return G
