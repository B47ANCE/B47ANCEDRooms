local A=require 'B47ANCEDRooms/API'
local R=require 'B47ANCEDRooms/Registry'
local C={pending={}};B47ANCEDRooms.Client=C
local serial=0
local function once(num,command,args,callback)
 args.protocol=1;serial=serial+1;args.request=serial
 if not isClient() then
  local ok,result=pcall(require('B47ANCEDRooms/Network').handle,getSpecificPlayer(num),command,args)
  callback(ok and result or {status='failed'});return
 end
 C.pending[serial]={player=getSpecificPlayer(num),num=num,time=getTimestampMs(),command=command,callback=callback}
 sendClientCommand(getSpecificPlayer(num),'B47ANCEDRooms',command,args)
end
function C.request(num,command,args,callback)
 once(num,command,args,callback)
end
if Events and Events.OnServerCommand then Events.OnServerCommand.Add(function(module,command,args)
 if module~='B47ANCEDRooms' or type(args)~='table' or args.protocol~=1 then return end
 if command=='changed' then B47ANCEDRooms.changed(args.revision);return end
 if command~='result' then return end
 if type(args.request)~='number' or args.request~=args.request or args.request<1 or args.request>2147483647 or args.request~=math.floor(args.request) then return end
 local request=C.pending[args.request];C.pending[args.request]=nil
 if request and request.player==getSpecificPlayer(request.num) then request.callback(args) end
end) end
if Events and Events.OnTick then Events.OnTick.Add(function()
 local now=getTimestampMs()
 for id,p in pairs(C.pending) do if now-p.time>10000 then C.pending[id]=nil;p.callback({status=p.command=='roomChange' and 'uncertain' or 'timeout'}) end end
end) end
if Events and Events.OnDisconnect then Events.OnDisconnect.Add(function() C.pending={} end) end
return C
