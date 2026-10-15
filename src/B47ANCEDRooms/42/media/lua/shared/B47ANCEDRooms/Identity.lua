B47ANCEDRooms=B47ANCEDRooms or {}
local I={version='0.2.0-dev.1',api=1};B47ANCEDRooms.Identity=I
-- Native safehouses persist account usernames. These are authenticated login
-- identities, not character/display names; Java long SteamIDs risk Lua rounding.
function I.account(player)
 if not player then return end
 if not isServer() and not isClient() then return 'local:'..player:getPlayerNum() end
 local value=player:getUsername()
 if type(value)=='string' and #value>0 and #value<=256 and not value:find('%c') then return value end
end
function I.copy(t,depth)
 if type(t)~='table' then return t end
 if (depth or 0)>16 then error('room snapshot depth') end
 local out={};for k,v in pairs(t) do out[k]=I.copy(v,(depth or 0)+1) end;return out
end
function I.equal(a,b,depth)
 if type(a)~=type(b) then return false end
 if type(a)~='table' then return a==b end
 if (depth or 0)>16 then return false end
 for k,v in pairs(a) do if not I.equal(v,b[k],(depth or 0)+1) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
function I.aliases(room)
 return room.nativeIds or (room.nativeId and {room.nativeId} or {})
end
function I.option(key,default)
 local options=SandboxVars and SandboxVars.B47ANCEDRooms
 local value=options and options[key]
 if value==nil then return default end
 return value
end
return I
