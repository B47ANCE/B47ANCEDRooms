-- Offline engine-shaped fixtures. Does not establish live Lua/Java or network behavior.
local client,server=false,false
function isClient() return client end
function isServer() return server end
function instanceof(o,c) return o and o.class==c end
local clock=1000
function getTimestampMs() return clock end
local function list(t)
    t=t or {}; t.size=function(s) return #s end; t.get=function(s,i) return s[i+1] end
    return t
end
ArrayList={new=function() return list() end}
local player={getX=function() return 0 end,getY=function() return 0 end,getZ=function() return 0 end,getJoypadBind=function() return -1 end}
function getSpecificPlayer() return player end
SandboxVars={B47ANCEDRooms={Enabled=true}}
local squares={}
local function square(x,y,z,building)
    local s={objects=list(),building=building,getX=function() return x end,getY=function() return y end,getZ=function() return z end}
    function s:getObjects() return self.objects end
    function s:getBuilding() return self.building end
    squares[x..','..y..','..z]=s;return s
end
local cell={getGridSquare=function(_,x,y,z) return squares[x..','..y..','..z] end}
function getCell() return cell end
local sent=0
local function object(s,grid,pos,storage)
    local o={sq=s,md={},grid=grid,pos=pos or {x=0,y=0,z=0},containers={}}
    function o:getSquare() return self.sq end
    function o:getObjectIndex() for i,v in ipairs(self.sq.objects) do if v==self then return i-1 end end;return -1 end
    function o:getContainerCount() return #self.containers end
    function o:getContainerByIndex(ci) return self.containers[ci+1] end
    function o:getSpriteGrid() return self.grid end
    function o:getSprite() return self.pos end
    function o:getSpriteGridObjectsIncludingSelf(out) for _,v in ipairs(self.members or {self}) do out[#out+1]=v end end
    function o:getModData() return self.md end
    function o:hasModData() return next(self.md)~=nil end
    function o:transmitModData() sent=sent+1 end
    if storage~=false then
        local c={getType=function() return 'crate' end,getContainingItem=function() end,getCustomName=function() return 'Identical crate' end,getItems=function() return list() end}
        o.containers={c}
    end
    s.objects[#s.objects+1]=o;return o
end
local grid={validate=function() return true end,getSpriteGridPosX=function(_,p) return p.x end,getSpriteGridPosY=function(_,p) return p.y end,getSpriteGridPosZ=function(_,p) return p.z end}
local a=object(square(0,0,0),grid)
player.square=a.sq
function player:getCurrentSquare() return self.square end
local b=object(square(1,0,0),grid,{x=1,y=0,z=0})
local decor=object(square(2,0,0),grid,{x=2,y=0,z=0},false)
local unrelated=object(square(0,1,0))
a.members={a,b,decor}; b.members=a.members
LootSorter=nil
local globalData={}
ModData={getOrCreate=function(key) globalData[key]=globalData[key] or {};return globalData[key] end}
function player:getUsername() return 'fixture-player' end
function player:getAccessLevel() return 'None' end
function player:getPlayerNum() return 0 end
SafeHouse={isSafehouseAllowLoot=function() return true end,isSafehouseAllowInteract=function() return true end,getSafehouseList=function() return list() end}

CONTAINER_FIXTURE={a=a,b=b,decor=decor,unrelatedObject=unrelated,player=player,grid=grid,squares=squares,
    object=object,square=square,list=list,sent=function() return sent end,
    network=function(c,s) client,server=c,s end,advance=function(ms) clock=clock+ms end}

ModData.get=function(key) return globalData[key] end
CONTAINER_FIXTURE.data=globalData
getTimestamp=function() return math.floor(getTimestampMs()/1000) end
local uuid=0
getRandomUUID=function() uuid=uuid+1;return '99999999-9999-9999-9999-'..string.format('%012d',uuid) end
local events={}
Events=setmetatable({},{__index=function(t,key) local e={Add=function(fn) events[key]=events[key] or {};events[key][#events[key]+1]=fn end};rawset(t,key,e);return e end})
function CONTAINER_FIXTURE.tick() for _,fn in ipairs(events.OnTick or {}) do fn() end end
function CONTAINER_FIXTURE.fire(event,...) for _,fn in ipairs(events[event] or {}) do fn(...) end end
function CONTAINER_FIXTURE.player:isDead() return false end
