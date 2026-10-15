-- Actual room editor callbacks on the owned offline ISUI surface.
dofile(TEST_ROOT..'/fixtures/ui.lua')
dofile(TEST_ROOT..'/fixtures/world.lua')
require 'B47ANCEDRooms/Client'
require 'B47ANCEDRooms/Editor'
function ISScrollingListBox:setOnMouseDownFunction(target,fn) self.target=target;self.onmousedown=fn end
function ISButton:setEnable(v) self.enable=v end
local Q,U=B47ANCEDRooms,B47RoomsUI
local f=CONTAINER_FIXTURE;local E=Q.Editor
getPlayerScreenLeft=function() return 0 end;getPlayerScreenTop=function() return 0 end
local width,height=1280,720
getPlayerScreenWidth=function() return width end;getPlayerScreenHeight=function() return height end
function ISPanelJoypad:setScrollChildren(v) self.scrollChildren=v end
function ISPanelJoypad:addScrollBars() end
function ISPanelJoypad:setCapture(v) self.capture=v end
function ISPanelJoypad:onJoypadDirRight() end
function ISScrollingListBox:setOverrideAButtonFunction(target,fn) self.overrideTarget=target;self.overrideA=fn end
local uuid=0;getRandomUUID=function() uuid=uuid+1;return '22222222-2222-2222-2222-'..string.format('%012d',uuid) end
getTimestamp=function() return math.floor(getTimestampMs()/1000) end
f.player.isDead=function() return false end
local cursorX,cursorY=0,0
getMouseXScaled=function() return cursorX end;getMouseYScaled=function() return cursorY end
ISCoordConversion={ToWorld=function(x,y) return x,y end}
-- Native-shaped UI projections: zoom and camera/viewport state can change
-- between draws while the draft's cached WORLD edges remain identical.
local camera={zoom=1,x=0,y=0,left=0,top=0,player=0}
local drawn={}
isoToScreenX=function(num,x,y,z)
 assert(num==camera.player,'outline used another player camera')
 return camera.left+((x-y)*64-camera.x)/camera.zoom
end
isoToScreenY=function(num,x,y,z)
 assert(num==camera.player,'outline used another player camera')
 return camera.top+((x+y)*32-z*192-camera.y)/camera.zoom
end
function ISPanelJoypad:drawLineAbsolute(texture,x1,y1,x2,y2,thickness,a,r,g,b)
 drawn[#drawn+1]={x1-self:getAbsoluteX(),y1-self:getAbsoluteY(),x2-self:getAbsoluteX(),y2-self:getAbsoluteY(),thickness,a,r,g,b}
end
renderIsoLine=function() error('world-render line used from UI outline') end
getCell().createNewGridSquare=function() error('room editor created world geometry') end
for _,sq in pairs(f.squares) do
 sq.isWallTo=function() return true end;sq.isDoorTo=function() return false end;sq.isWindowTo=function() return false end;sq.isBlockedTo=function() return false end
end
local confirmation
U.Dialog.confirm=function(_,text,labels,callback) confirmation={text=text,callback=callback} end
local p=ISPanelJoypad:new(0,0,500,500);p.playerNum=0;p.selectedItems={};local selections=p.selectedItems;selections.keep=true
local editor=E.open(0,p);assert(editor and not p:isVisible())
assert(editor.sidebar.width<=width and editor.nameEntry and not editor.secondName:isVisible())
-- Cover saved/added/removed/overlapping/split edges, invalid marks and the
-- drag rectangle, including an elevated floor and fractional invalid marks.
editor.detection=nil;editor.floor=2
editor.draft:set(assert(Q.Geometry.normalize({{2,1,1,2}})))
editor.draft.original=assert(Q.Geometry.normalize({{2,1,0,1}}))
editor.draft.second=assert(Q.Geometry.normalize({{2,2,2,2}}))
editor.saved={other={rows={{2,1,2,3}}}}
editor.invalidTiles={{x=2,y=1,z=2},{x=2,y=1,z=1}}
editor.first={x=1,y=1,z=2};editor.cursor={x=2,y=2,z=2}
editor:prerender()
local baseline=drawn;assert(#baseline>10,'outline layers missing')
local cached=editor.edgeCache;local geometry=editor.draft.geometry
for _,state in ipairs({{.5,13,-27,0,0,0},{2,-43,31,640,0,1},{1.35,93,64,640,360,3}}) do
 camera.zoom,camera.x,camera.y,camera.left,camera.top,camera.player=unpack(state)
 editor.playerNum=camera.player;editor:setX(camera.left);editor:setY(camera.top);drawn={}
 editor:prerender()
 assert(editor.edgeCache==cached and editor.draft.geometry==geometry,'zoom rebuilt or changed room geometry')
 assert(#drawn==#baseline,'zoom changed outline count')
 for i,line in ipairs(drawn) do
  local original=baseline[i]
  for k=1,4 do
   local offset=k%2==1 and camera.x or camera.y
   assert(math.abs(line[k]-(original[k]-offset)/camera.zoom)<.00001,'outline drifted or failed to scale')
  end
  for k=5,9 do assert(line[k]==original[k],'zoom changed UI thickness/color') end
 end
end
assert(not ModData.getOrCreate('B47ANCEDRooms').customRooms,'rendering persisted geometry')
camera={zoom=1,x=0,y=0,left=0,top=0,player=0};editor.playerNum=0;editor:setX(0);editor:setY(0)
editor.floor=0;editor.saved={};editor.invalidTiles=nil;editor:load()
editor:prerender();editor.sidebar:prerender()
editor:onMouseDown(100,100);assert(editor.capture)
cursorX=1;editor:onMouseMove(1,0);editor:onMouseUp(100,100)
assert(not editor.capture and editor.draft.geometry.count==2)
assert(not ModData.getOrCreate('B47ANCEDRooms').customRooms,'preview movement persisted')
editor.tool='RoomRemoveRectangle';editor.worldFocus=true;editor.cursor={x=0,y=0,z=0}
editor:onJoypadDown(Joypad.AButton);editor:onJoypadDirRight();editor:onJoypadDown(Joypad.AButton)
assert(editor.draft.geometry.count==0,'controller rectangle did not match mouse geometry')
editor.draft:undo();assert(editor.draft.geometry.count==2)
editor.draft:redo();assert(editor.draft.geometry.count==0);editor.draft:undo()
editor.nameEntry:setText('Workshop');editor:submit();assert(confirmation and not editor.submission)
confirmation.callback('accept');assert(editor.submission)
Q.Registry.tick();f.advance(600);editor:update()
assert(editor.closed and not editor.capture and p:isVisible() and p.selectedItems==selections and selections.keep)
local lib=ModData.getOrCreate('B47ANCEDRooms').customRooms
assert(lib and lib.revision==1)
local before=lib
f.advance(3000);local pending=E.open(0,p);pending.detection=nil;pending.draft:set(assert(Q.Geometry.normalize({{0,0,0,0}})));pending.nameEntry:setText('Cancelled')
pending:submit();confirmation.callback('accept');assert(pending.submission)
pending:closeEditor();Q.Registry.tick()
assert(ModData.getOrCreate('B47ANCEDRooms').customRooms==before,'closing pending editor committed later')
-- Late reads and externally removed UI cannot resurrect previews or capture.
local request=Q.Client.request;local queued={}
Q.Client.request=function(_,command,args,callback) queued[#queued+1]=callback end
local late=E.open(0,p);late.removed=true;late:update()
assert(late.closed and not late.capture and p:isVisible())
for _,callback in ipairs(queued) do callback({status='ok',rooms={},revision=100}) end
assert(late.closed and not late.draft,'late callback resurrected removed editor')
Q.Client.request=request
-- Even a focus/input event already queued for the editor cannot raise it above
-- its active confirmation, alter the preview, or close it via Escape/B.
f.advance(3000);local guarded=E.open(0,p);guarded.detection=nil
guarded.draft:set(assert(Q.Geometry.normalize({{0,0,0,0}})));guarded.cursor={x=0,y=0,z=0}
local guardedGeometry=guarded.draft.geometry;local raised=0;local destroyed=0
guarded.first={x=0,y=0,z=0};local first=guarded.first
guarded.b47Dialog={bringToTop=function() raised=raised+1 end,destroy=function(self)
 assert(guarded.closed,'popup closed before owner was marked closed')
 destroyed=destroyed+1;self.closed=true;guarded.b47Dialog=nil
end}
guarded:onFocus();guarded:onMouseDown(100,100);guarded:onMouseMove(1,1);guarded:onMouseUp(100,100)
guarded:onRightMouseDown();assert(guarded.first==first,'right click changed preview behind confirmation')
guarded:onKeyPress(Keyboard.KEY_ESCAPE);guarded:onJoypadDown(Joypad.BButton);guarded.worldFocus=true;guarded:onJoypadDirRight()
assert(raised==2 and not guarded.closed and guarded.cursor.x==0 and guarded.draft.geometry==guardedGeometry,'editor input escaped modal guard')
guarded:closeEditor();guarded:closeEditor();assert(destroyed==1 and not guarded.b47Dialog,'owner teardown leaked or destroyed popup twice')
print('PASS OFFLINE room editor: zoom/camera/viewport outline projection, mouse/controller rectangles, bounded preview history, explicit save, cancellation/late replies, capture/focus cleanup, themed controls and preserved sorting selections')
