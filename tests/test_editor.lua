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
local buildingDef={};local building={getDef=function() return buildingDef end}
for _,sq in pairs(f.squares) do
 sq.building=building
 sq.isWallTo=function() return true end;sq.isDoorTo=function() return false end;sq.isWindowTo=function() return false end;sq.isBlockedTo=function() return false end
end
local confirmation
U.Dialog.confirm=function(_,text,labels,callback) confirmation={text=text,callback=callback} end
local p=ISPanelJoypad:new(0,0,500,500);p.playerNum=0;p.selectedItems={};local selections=p.selectedItems;selections.keep=true
local closes=0
local editor=E.open(0,p,function() closes=closes+1 end);assert(editor and not p:isVisible())
assert(editor.draft.geometry.count==0 and not editor.detection,'opening auto-designated a room')
assert(not editor.buttons.RoomUseNative and not editor.buttons.RoomRestore,'retired native tools remain visible')
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
assert(not editor.closed and not editor.capture and not p:isVisible() and closes==0,'successful save ended the editor session')
assert(editor.record==nil and editor.draft.geometry.count==0 and #editor.draft.history==0,'successful save did not start a blank room')
assert(editor.nameEntry:getInternalText()==getText('UI_B47Rooms_RoomDefaultName') and editor.floor==0)
local lib=ModData.getOrCreate('B47ANCEDRooms').customRooms
assert(lib and lib.revision==1)
assert(editor.revision==1 and #editor.metadata==1 and editor.metadata[1].name=='Workshop','saved list/lease did not refresh')
local firstId=editor.metadata[1].id
-- Save the next room through the same live editor and obtain a distinct identity.
f.advance(3000);editor:apply({x=2,y=0,z=0},{x=2,y=0,z=0});editor.nameEntry:setText('Pantry')
editor:submit();confirmation.callback('accept');assert(editor.submission)
Q.Registry.tick();f.advance(600);editor:update()
lib=ModData.getOrCreate('B47ANCEDRooms').customRooms
assert(not editor.closed and not p:isVisible() and closes==0 and lib.revision==2)
assert(editor.revision==2 and #editor.metadata==2 and editor.draft.geometry.count==0)
assert(lib.records[firstId].name=='Workshop' and lib.records[firstId].rows[1][4]==1,'second designation overwrote the first room')
local found=false;for id,room in pairs(lib.records) do if room.name=='Pantry' then assert(id~=firstId);found=true end end;assert(found)
editor:closeEditor();editor:closeEditor()
assert(p:isVisible() and closes==1 and p.selectedItems==selections and selections.keep,'explicit close failed to restore parent exactly once')
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
-- Controlled transport covers immediate acknowledgements, failure retention and
-- late reads while the editor remains alive across successive saves.
local lists,gets,changes={},{},{}
Q.Client.request=function(_,command,args,callback)
 if command=='roomList' then lists[#lists+1]={args=args,callback=callback}
 elseif command=='roomGet' then gets[#gets+1]=callback
 elseif command=='roomChange' then changes[#changes+1]=callback
 elseif command=='roomCancel' then callback({status='cancelled'})
 else error('unexpected editor request '..command) end
end
local live=E.open(0,p)
local function listReply(index,revision,rooms)
 lists[index].callback({status='ok',rooms=rooms or {},revision=revision,editKey='lease:'..revision,options={maxTiles=1024,doorways=true}})
end
listReply(1,10,{{id='prior',revision=1,label='Prior'}})
live:update();assert(#gets==1 and live.fetchPending)
local oldOverlay=gets[1]
live.floor=1;live.cursor.z=1;live.draft:set(assert(Q.Geometry.normalize({{1,0,0,0}})));live.nameEntry:setText('Upstairs')
local originalDraft=live.draft
live:submit();confirmation.callback('accept');listReply(2,10)
assert(#changes==1);changes[1]({status='ok',revision=11})
assert(not live.closed and live.draft~=originalDraft and live.draft.geometry.count==0 and live.floor==1)
assert(live.revision==nil and live.editKey==nil,'next save could reuse a consumed lease')
assert(not live.fetchPending and #live.fetch==0,'refresh retained an obsolete overlay queue')
oldOverlay({status='ok',room={rows={{0,0,0,0}}}})
assert(live.saved.prior==nil,'old overlay reply contaminated the next room')
listReply(3,11,{{id='new',revision=1,label='Upstairs'}})
assert(live.revision==11 and live.metadata[1].id=='new')
-- The same acknowledgement cannot reset a newly started draft a second time.
live.draft:set(assert(Q.Geometry.normalize({{1,0,1,1}})));local nextDraft=live.draft
changes[1]({status='ok',revision=11});assert(live.draft==nextDraft and live.draft.geometry.count==1)
live.nameEntry:setText('Keep on error');live:submit();confirmation.callback('accept');listReply(4,11)
changes[2]({status='RoomDenied'})
assert(not live.closed and live.draft==nextDraft and live.nameEntry:getInternalText()=='Keep on error' and not live.submission)
-- A newer list wins even when an earlier refresh finishes later.
live:refresh();live:refresh();listReply(6,13);listReply(5,12)
assert(live.revision==13,'stale list reply replaced the current save revision')
live:closeEditor();Q.Client.request=request
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
print('PASS OFFLINE room editor: zoom/camera/viewport projection, mouse/controller previews, consecutive distinct saves in one window, immediate/polled completion, refreshed leases/metadata, failure and stale-reply isolation, explicit close/cancellation, modal guards and parent/focus cleanup')
