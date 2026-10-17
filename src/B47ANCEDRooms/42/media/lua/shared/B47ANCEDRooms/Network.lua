local I=require 'B47ANCEDRooms/Identity'
local R=require 'B47ANCEDRooms/Registry'
local A=require 'B47ANCEDRooms/API'
local W={};B47ANCEDRooms.Network=W
local participants=setmetatable({},{__mode='k'});local buckets=setmetatable({},{__mode='k'})
local commands={roomList=true,roomGet=true,roomChange=true,roomPoll=true,roomCancel=true}
local function requestID(value)
 return type(value)=='number' and value==value and value>=1 and value<=2147483647 and value==math.floor(value) and value or nil
end
function W.handle(player,command,args)
 if isClient() or not player or not commands[command] or type(args)~='table' or args.protocol~=1 then return {status='ProtocolMismatch'} end
 if args.request~=nil and not requestID(args.request) then return {status='invalid'} end
 local now=getTimestampMs();local b=buckets[player] or {time=now,tokens=8};buckets[player]=b
 b.tokens=math.min(8,b.tokens+math.max(0,now-b.time)/250);b.time=now
 local cost=command=='roomChange' and 4 or command=='roomCancel' and 0 or 1
 if b.tokens<cost then return {status='rateLimited'} end;b.tokens=b.tokens-cost
 participants[player]=true
 local result=R.handle(player,command,args)
 if command=='roomList' and result.status=='ok' then
  local visible=A.listRooms(player,{building=true})
  if visible.status~='ok' then return visible end
  result.rooms=visible.rooms
 end
 return result
end
function W.changed(revision)
 if not isServer() or not sendServerCommand then return end
 for player in pairs(participants) do sendServerCommand(player,'B47ANCEDRooms','changed',{revision=revision,protocol=1}) end
end
if Events and Events.OnClientCommand then Events.OnClientCommand.Add(function(module,command,player,args)
 if module~='B47ANCEDRooms' then return end
 local ok,result=pcall(W.handle,player,command,args)
 if not ok then print('[B47ANCEDRooms] request failed: '..tostring(result):sub(1,512));result={status='failed'} end
 result.request=type(args)=='table' and requestID(args.request) or nil;result.protocol=1
 sendServerCommand(player,'B47ANCEDRooms','result',result)
end) end
local lastCleanup=0
if Events and Events.OnTick then Events.OnTick.Add(function()
 if not isServer() then return end
 if getTimestampMs()-lastCleanup<1000 then return end;lastCleanup=getTimestampMs()
 local active=false;for _ in pairs(participants) do active=true;break end;if not active then return end
 local players=getOnlinePlayers();local online={};for n=0,players:size()-1 do online[players:get(n)]=true end
 for player in pairs(participants) do if not online[player] then R.cleanup(player);participants[player]=nil;buckets[player]=nil end end
end) end
return W
