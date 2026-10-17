-- Immutable preview snapshots; no authority, world mutation or network writes.
local G=require 'B47ANCEDRooms/Geometry'
local D={};D.__index=D;B47ANCEDRooms.Draft=D
function D.new(room)
 local g=assert(G.normalize(room and room.rows or {}))
 local self=setmetatable({original=g,geometry=g,history={},future={},action='save',ids=nil},D)
 return self
end
function D:snapshot() return {geometry=self.geometry,second=self.second,action=self.action,ids=self.ids} end
function D:restore(s) self.geometry=s.geometry;self.second=s.second;self.action=s.action;self.ids=s.ids end
function D:set(g,action,second,ids)
 self.history[#self.history+1]=self:snapshot();if #self.history>32 then table.remove(self.history,1) end
 self.future={};self.geometry=g;self.second=second;self.action=action or 'save';self.ids=ids
end
function D:edit(rows,remove)
 if self.action~='save' then return nil,'RoomFinishCompound' end
 local g,e=G.edit(self.geometry.rows,rows,remove)
 if not g then return nil,e end
 self:set(g);return true
end
function D:undo()
 local s=table.remove(self.history);if not s then return false end
 self.future[#self.future+1]=self:snapshot();self:restore(s);return true
end
function D:redo()
 local s=table.remove(self.future);if not s then return false end
 self.history[#self.history+1]=self:snapshot();self:restore(s);return true
end
function D:split(rows)
 if self.action~='save' then return nil,'RoomFinishCompound' end
 local chosen,e=G.normalize(rows);if not chosen then return nil,e end
 local first,rest={},{}
 for _,t in ipairs(self.geometry.tiles) do
  local list=G.contains(chosen,t.x,t.y,t.z) and first or rest;list[#list+1]=t
 end
 local a,b=G.fromTiles(first),G.fromTiles(rest)
 if a.count<1 or b.count<1 then return nil,'RoomSplitEmpty' end
 self:set(a,'split',b);return true
end
function D:combine(other,survivor)
 if self.action=='split' then return nil,'RoomFinishCompound' end
 local g,e=G.edit(self.geometry.rows,other.rows,false)
 if not g then return nil,e end
 local ids={};for _,id in ipairs(self.ids or {survivor}) do if id==other.id then return nil,'RoomAlreadyIncluded' end;ids[#ids+1]=id end
 ids[#ids+1]=other.id;self:set(g,'merge',nil,ids);return true
end
function D:edges(g,z)
 local out={};local horizontal,vertical={},{}
 local function mark(map,k,v) local line=map[k] or {};map[k]=line;line[v]=true end
 for _,t in ipairs(g.tiles) do if t.z==z then
  if not G.contains(g,t.x,t.y-1,z) then mark(horizontal,t.y,t.x) end
  if not G.contains(g,t.x,t.y+1,z) then mark(horizontal,t.y+1,t.x) end
  if not G.contains(g,t.x-1,t.y,z) then mark(vertical,t.x,t.y) end
  if not G.contains(g,t.x+1,t.y,z) then mark(vertical,t.x+1,t.y) end
 end end
 for axis,map in ipairs({horizontal,vertical}) do for key,units in pairs(map) do
  local values={};for v in pairs(units) do values[#values+1]=v end;table.sort(values)
  local start,ending
  local function emit()
   if start then out[#out+1]=axis==1 and {start,key,z,ending+1,key,z} or {key,start,z,key,ending+1,z} end
  end
  for _,v in ipairs(values) do if ending and v==ending+1 then ending=v else emit();start=v;ending=v end end;emit()
 end end
 return out,false
end
return D
