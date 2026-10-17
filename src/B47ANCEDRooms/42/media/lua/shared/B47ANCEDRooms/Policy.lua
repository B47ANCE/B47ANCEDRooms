local I=require 'B47ANCEDRooms/Identity'
local G=require 'B47ANCEDRooms/Geometry'
local P={actions={discover=true,inspect=true,withdraw=true,deposit=true,configure=true,clean=true}};B47ANCEDRooms.Policy=P
function P.admin(player) return player and player.getAccessLevel and tostring(player:getAccessLevel()):lower()=='admin' end
function P.houses()
 if not SafeHouse or type(SafeHouse.getSafehouseList)~='function' then return nil,'unavailable' end
 local list=SafeHouse.getSafehouseList();if not list or list:size()>1024 then return nil,'unavailable' end
 return list
end
function P.house(id)
 if not id then return end
 local list,e=P.houses();if not list then return nil,e end
 -- getSafeHouse(String) resolves titles, NOT IDs in installed B42.21.
 for n=0,list:size()-1 do local h=list:get(n);if h:getId()==id then return h end end
end
function P.at(square)
 if not square then return nil,'unavailable' end
 local list,e=P.houses();if not list then return nil,e end
 local found
 for n=0,list:size()-1 do local h=list:get(n)
  if square:getX()>=h:getX() and square:getX()<h:getX2() and square:getY()>=h:getY() and square:getY()<h:getY2() then
   if found and found~=h then return nil,'ambiguous' end;found=h
  end
 end
 return found
end
function P.member(player,h)
 local who=I.account(player)
 return h and who and (h:getOwner()==who or h:getPlayers():contains(who)) or false
end
function P.parentOwner(player,room)
 local h=P.house(room.safehouse);return h and h:getOwner()==I.account(player) or false
end
function P.edit(player,room,action)
 if P.admin(player) or P.parentOwner(player,room) then return true end
 if action=='assignOwner' then return false end
 if room.assigned then
  if action=='policy' and room.policy and room.policy.mode=='private' and not P.active(room) then return false end
  return room.assigned==I.account(player) and P.member(player,P.house(room.safehouse)) and action~='geometry'
 end
 return room.owner==I.account(player) or P.member(player,P.house(room.safehouse))
end
function P.base(player,square,action)
 if isClient() or not player or not square or not P.actions[action] then return false,'unavailable' end
 if not isServer() then return true end
 if not SafeHouse or not SafeHouse.isSafehouseAllowLoot then return false,'unavailable' end
 local ok,allowed=pcall(SafeHouse.isSafehouseAllowLoot,square,player)
 if not ok then return false,'unavailable' end
 if not allowed then return false,'denied' end
 if action=='configure' or action=='clean' then
  if not SafeHouse.isSafehouseAllowInteract then return false,'unavailable' end
  ok,allowed=pcall(SafeHouse.isSafehouseAllowInteract,square,player)
  if not ok then return false,'unavailable' end
  if not allowed then return false,'denied' end
 end
 return true
end
function P.active(room)
 local h,e=P.house(room.safehouse)
 if not h then return false,e or 'parentChanged' end
 local b=room.parentBounds
 if not b or room.parentOwner~=h:getOwner() or b[1]~=h:getX() or b[2]~=h:getY() or b[3]~=h:getX2() or b[4]~=h:getY2() then return false,'parentChanged' end
 if not room.assigned or not (h:getOwner()==room.assigned or h:getPlayers():contains(room.assigned)) then return false,'parentChanged' end
 return true,h
end
function P.storage(player,room,action)
 if not room.policy or room.policy.mode=='shared' then return true end
 local active,h=P.active(room);if not active then return false,h end
 -- Administrative editing is separate from gameplay. No parent/admin bypass.
 local who=I.account(player);local grant=room.policy.grants and room.policy.grants[who]
 local rule=room.policy.rules and room.policy.rules[action] or 'owner'
 if grant and grant[action]~=nil then if grant[action] then return true end;return false,'denied' end
 if rule=='members' and P.member(player,h) then return true end
 if rule=='owner' and who==room.assigned then return true end
 return false,'denied'
end
function P.valid(policy)
 if type(policy)~='table' or getmetatable(policy) or (policy.mode~='shared' and policy.mode~='private') then return false end
 for k in pairs(policy) do if k~='mode' and k~='rules' and k~='grants' then return false end end
 if type(policy.rules)~='table' or getmetatable(policy.rules) or type(policy.grants)~='table' or getmetatable(policy.grants) then return false end
 for action,rule in pairs(policy.rules) do if not P.actions[action] or (rule~='owner' and rule~='members' and rule~='none') then return false end end
 local count=0
 for who,grants in pairs(policy.grants) do
  count=count+1;if count>64 or type(who)~='string' or #who<1 or #who>256 or who:find('%c') or type(grants)~='table' or getmetatable(grants) then return false end
  for action,allow in pairs(grants) do if not P.actions[action] or type(allow)~='boolean' then return false end end
 end
 return true
end
function P.validate(room,records,removed)
 if not room.policy or room.policy.mode=='shared' then return true end
 if not P.valid(room.policy) then return false,'RoomPolicyInvalid' end
 local active,h=P.active(room);if not active then return false,'RoomParentChanged' end
 local g=G.normalize(room.rows)
 for _,t in ipairs(g.tiles) do
  if t.x<h:getX() or t.x>=h:getX2() or t.y<h:getY() or t.y>=h:getY2() then return false,'RoomAssociationConflict' end
 end
 for id,other in pairs(records) do if id~=room.id and not removed[id] and other.policy and other.policy.mode=='private' then
  local a=G.normalize(other.rows)
  for _,t in ipairs(g.tiles) do if G.contains(a,t.x,t.y,t.z) then return false,'RoomProtectedOverlap' end end
 end end
 return true
end
return P
