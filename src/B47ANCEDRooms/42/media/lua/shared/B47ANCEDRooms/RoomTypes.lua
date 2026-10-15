-- Room organization metadata only. No item taxonomy or storage percentages.
local T={ids={'kitchen','pantry','medical','armory','workshop','garage','library','bedroom','bathroom','laundry','storage','garden','electronics','utility'},roles={'unassigned','primary','secondary'}}
local known={};for _,id in ipairs(T.ids) do known[id]=true end
function T.valid(id) return id==nil or id=='unassigned' or known[id]==true end
function T.role(id) return id==nil or id=='unassigned' or id=='primary' or id=='secondary' end
return T
