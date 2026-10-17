-- Actual dedicated bootstrap/transport in disposable Lua fixtures, not native MP.
dofile(TEST_ROOT..'/fixtures/world.lua')
local f=CONTAINER_FIXTURE;f.network(false,true)
getOnlinePlayers=function() return f.list({f.player}) end
local replies={};sendServerCommand=function(player,module,command,args) replies[#replies+1]={player=player,module=module,command=command,args=args} end
require 'B47RoomsBootstrap'
assert(not B47ANCEDRooms.Client and not B47ANCEDRooms.Editor and not B47RoomsUI,'headless bootstrap loaded presentation')
local W=B47ANCEDRooms.Network;local R=B47ANCEDRooms.Registry
assert(W.handle(f.player,'roomList',{protocol=99}).status=='ProtocolMismatch')
assert(W.handle(f.player,'nativeGet',{protocol=1}).status=='ProtocolMismatch')
assert(W.handle(f.player,'assignMe',{protocol=1}).status=='ProtocolMismatch')
for _,bad in ipairs({0,-1,1/0,0/0,1.5,2147483648}) do
 f.fire('OnClientCommand','B47ANCEDRooms','roomList',f.player,{protocol=1,request=bad})
 assert(replies[#replies].args.status=='invalid' and replies[#replies].args.request==nil)
end
assert(W.handle(f.player,'roomList',{protocol=1,unknown={}}).status=='invalid')
f.advance(3000)
local lease=W.handle(f.player,'roomList',{protocol=1,request=7,renew=true})
assert(lease.status=='ok' and lease.editKey and lease.nativeRooms==nil)
local args={protocol=1,request=8,action='save',name='Network Room',rows={{0,0,0,0}},roomType='medical',designation='primary',nonce='transport:1',editKey=lease.editKey,revision=lease.revision,owner='forged'}
assert(W.handle(f.player,'roomChange',args).status=='pending')
for _=1,8 do f.advance(250);f.tick() end
local result=W.handle(f.player,'roomPoll',{protocol=1,nonce=args.nonce})
assert(result.status=='ok')
local lib=R.library();local id,record=next(lib.records);assert(record.owner=='fixture-player' and lib.revision==1)
assert(record.roomType=='medical' and record.designation=='primary','transport dropped designation intent')
f.advance(1000);assert(W.handle(f.player,'roomChange',args).status=='ok')
assert(R.library().revision==1,'replayed write mutated the room twice')
args.nonce='transport:2';f.advance(1000);assert(W.handle(f.player,'roomChange',args).status=='expired')
assert(R.library().records[id].name=='Network Room')
-- Client request/response matching rejects malformed and late results.
f.network(true,false)
local sent;sendClientCommand=function(_,_,command,payload) sent={command=command,args=payload} end
local C=require 'B47ANCEDRooms/Client';local outcome
C.request(0,'roomChange',{},function(r) outcome=r.status end)
local request=sent.args.request
f.fire('OnServerCommand','B47ANCEDRooms','result',{protocol=1,status='ok'})
f.fire('OnServerCommand','B47ANCEDRooms','result',{protocol=1,request=0/0,status='ok'})
assert(outcome==nil)
f.advance(10001);f.tick();assert(outcome=='uncertain')
f.fire('OnServerCommand','B47ANCEDRooms','result',{protocol=1,request=request,status='ok'})
assert(outcome=='uncertain','late acknowledgement changed expired client outcome')
print('PASS OFFLINE headless bootstrap/transport: bounded IDs, forged commands/owner, lease replay, authoritative mutation, uncertain writes and late-response isolation')
