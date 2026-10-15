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
renderIsoLine=function() end
getCell().createNewGridSquare=function() error('room editor created world geometry') end
for _,sq in pairs(f.squares) do
 sq.isWallTo=function() return true end;sq.isDoorTo=function() return false end;sq.isWindowTo=function() return false end;sq.isBlockedTo=function() return false end
end
local confirmation
U.Dialog.confirm=function(_,text,labels,callback) confirmation={text=text,callback=callback} end
local p=ISPanelJoypad:new(0,0,500,500);p.playerNum=0;p.selectedItems={};local selections=p.selectedItems;selections.keep=true
local editor=E.open(0,p);assert(editor and not p:isVisible())
assert(editor.sidebar.width<=width and editor.nameEntry and not editor.secondName:isVisible())
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
print('PASS OFFLINE room editor: mouse/controller rectangles, bounded preview history, explicit save, cancellation/late replies, capture/focus cleanup, themed controls and preserved sorting selections')
