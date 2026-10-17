-- Local appearance only. Background alpha never becomes a parent/child UI alpha.
require 'B47RoomsUI/Theme'
local U=B47RoomsUI;local A={};U.Appearance=A
local values={}
local function valid(n) return type(n)=='number' and n==n and n~=math.huge and n~=-math.huge end
function A.player(w)
 local n=0
 while w and n<32 do if w.playerNum~=nil then return w.playerNum end;w=w.parent;n=n+1 end
 return 0
end
function A.get(player)
 player=player or 0
 if values[player] then return values[player] end
 local value=82
 if getFileReader then
  local ok,reader=pcall(getFileReader,'B47ANCEDRoomsAppearance'..player..'.txt',true)
  if ok and reader then pcall(function() local line=reader:readLine() or '';local number=tonumber(line:match('^opacity=(.+)$'));if valid(number) and number>=20 and number<=100 then value=number end;reader:close() end) end
 end
 values[player]=value;return value
end
function A.set(player,value)
 value=tonumber(value);if not valid(value) then value=82 end
 value=math.max(20,math.min(100,value));values[player or 0]=value;return value
end
function A.save(player)
 player=player or 0
 if getFileWriter then
  local ok,writer=pcall(getFileWriter,'B47ANCEDRoomsAppearance'..player..'.txt',true,false)
  if ok and writer then pcall(function() writer:write('opacity='..A.get(player)..'\n');writer:close() end) end
 end
end
function A.alpha(w) if w and w.b47AppearanceOpaque then return .94 end;return A.get(A.player(w))/100 end
function A.prepare(w,kind)
 if not w.backgroundColor then return end
 if w.b47AppearanceOpaque then w.backgroundColor.a=.94
 elseif kind=='window' or kind=='panel' and not w.parent then w.backgroundColor.a=A.alpha(w)
 elseif kind=='panel' or kind=='list' then w.backgroundColor.a=0 end
 -- Buttons, inputs, dropdowns and native tooltip frames keep their readable backgrounds.
end
return A
