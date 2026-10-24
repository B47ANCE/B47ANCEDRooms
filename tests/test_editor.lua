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
function ISScrollingListBox:doDrawItem(y,item,alt) self.lastDrawn=item.text;return y+item.height end
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
-- Mouse brush drags preview a filled rectangle and commit it once on release.
local originalDraft=editor.draft
editor.draft=Q.Draft.new()
editor.draft:set(assert(Q.Geometry.rectangle({x=0,y=0,z=0},{x=4,y=4,z=0})))
editor.tool='RoomErase';cursorX=1;cursorY=1
local history=#editor.draft.history
editor:onMouseDown(100,100)
cursorX=3;cursorY=3;editor:onMouseMove(2,2)
assert(editor.draft.geometry.count==25 and #editor.draft.history==history,'erase mutated the draft during drag')
editor:onMouseUp(100,100)
assert(editor.draft.geometry.count==16 and not Q.Geometry.contains(editor.draft.geometry,2,2,0),'erase missed the box interior')
assert(#editor.draft.history==history+1,'erase drag created multiple undo steps')
assert(editor.draft:undo() and editor.draft.geometry.count==25,'erase drag did not undo as one edit')
editor.draft=Q.Draft.new();editor.tool='RoomPaint';cursorX=1;cursorY=1
editor:onMouseDown(100,100);cursorX=3;cursorY=3;editor:onMouseMove(2,2)
assert(editor.draft.geometry.count==0,'paint mutated the draft during drag')
editor:onMouseUp(100,100)
assert(editor.draft.geometry.count==9 and Q.Geometry.contains(editor.draft.geometry,2,2,0),'paint missed the box interior')
cursorX=5;cursorY=5;editor:onMouseDown(100,100);editor:onMouseUp(100,100)
assert(editor.draft.geometry.count==10 and Q.Geometry.contains(editor.draft.geometry,5,5,0),'single-click paint changed')
cursorX=6;cursorY=6;editor:onMouseDown(100,100);editor:onRightMouseDown()
assert(editor.draft.geometry.count==10 and not editor.capture,'cancelled drag changed the draft')
editor.draft=originalDraft
editor.tool='RoomRemoveRectangle';editor.worldFocus=true;editor.cursor={x=0,y=0,z=0}
editor:onJoypadDown(Joypad.AButton);editor:onJoypadDirRight();editor:onJoypadDown(Joypad.AButton)
assert(editor.draft.geometry.count==0,'controller rectangle did not match mouse geometry')
editor.draft:undo();assert(editor.draft.geometry.count==2)
editor.draft:redo();assert(editor.draft.geometry.count==0);editor.draft:undo()
editor.roomType='workshop';editor.designation='primary'
editor.nameEntry:setText('Workshop');confirmation=nil;editor:submit()
assert(editor.submission and not confirmation,'routine create still required an extra confirmation')
Q.Registry.tick();f.advance(600);editor:update()
assert(not editor.closed and not editor.capture and not p:isVisible() and closes==0,'successful save ended the editor session')
assert(editor.record==nil and editor.draft.geometry.count==0 and #editor.draft.history==0,'successful save did not start a blank room')
assert(editor.nameEntry:getInternalText()==getText('UI_B47Rooms_RoomDefaultName') and editor.floor==0)
local lib=ModData.getOrCreate('B47ANCEDRooms').customRooms
assert(lib and lib.revision==1)
assert(editor.revision==1 and #editor.metadata==1 and editor.metadata[1].name=='Workshop','saved list/lease did not refresh')
local firstId=editor.metadata[1].id
assert(lib.records[firstId].roomType=='workshop' and lib.records[firstId].designation=='primary','create lost draft designation')
-- Save the next room through the same live editor and obtain a distinct identity.
f.advance(3000);editor:apply({x=2,y=0,z=0},{x=2,y=0,z=0});editor.nameEntry:setText('Pantry')
editor:submit();assert(editor.submission)
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
pending:submit();assert(pending.submission)
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
listReply(1,10,{{id='prior',revision=1,label='Prior',floors={0}}})
live:update();assert(#gets==1 and live.fetchPending)
local oldOverlay=gets[1]
live.floor=1;live.cursor.z=1;live.draft:set(assert(Q.Geometry.normalize({{1,0,0,0}})));live.nameEntry:setText('Upstairs')
local originalDraft=live.draft
live:submit();listReply(2,10)
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
live.nameEntry:setText('Keep on error');live:submit();listReply(4,11)
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
-- The streamlined sidebar separates routine creation, editing and advanced work.
f.advance(3000);local flow=E.open(0,p)
flow:updateSidebar()
assert(flow.buttons.Save.title==getText('UI_B47Rooms_RoomSaveNext') and flow.buttons.Done.title==getText('UI_B47Rooms_Done'))
assert(not flow.accountEntry:isVisible() and not flow.buttons.RoomPermissions:isVisible())
assert(not flow.buttons.RoomDelete:isVisible() and not flow.buttons.RoomDuplicate:isVisible() and not flow.buttons.RoomClear:isVisible())
assert(not flow.buttons.Save.enable and flow.buttons.Done.enable)
local meta;for _,room in ipairs(flow.metadata) do if room.id==firstId then meta=room end end;assert(meta)
flow:select(meta);flow:updateSidebar()
assert(flow.record.id==firstId and flow.buttons.RoomPermissions:isVisible() and not flow.accountEntry:isVisible())
assert(flow.buttons.Save.title==getText('UI_B47Rooms_RoomSaveChanges'))
flow.buttons.RoomAdvanced.onclick(flow);assert(flow.buttons.RoomDelete:isVisible() and flow.buttons.RoomDuplicate:isVisible())
local expandedY=flow.statusY
flow.buttons.RoomAdvanced.onclick(flow);assert(not flow.buttons.RoomDelete:isVisible())
assert(flow.statusY<expandedY,'collapsed controls left empty sidebar rows')
for _,row in ipairs(flow.joypadButtonsY) do for _,control in ipairs(row) do assert(control:isVisible(),'hidden controls entered controller navigation') end end
flow.nameEntry:setText('Workshop Renamed');confirmation=nil;flow:submit()
assert(flow.submission and not confirmation,'routine rename needed a redundant modal')
assert(not flow.nameEntry.editable and not flow.buttons.RoomTools.enable,'pending write left mutable controls enabled')
local submittedGeometry=flow.draft.geometry;flow:apply({x=0,y=1,z=0},{x=0,y=1,z=0})
assert(flow.draft.geometry==submittedGeometry,'pending write allowed new preview edits')
for _=1,20 do Q.Registry.tick();f.advance(600);flow:update();if not flow:isBusy() then break end end
assert(flow.record and flow.record.id==firstId and flow.record.name=='Workshop Renamed','edit reset selection or kept stale room metadata')
assert(flow.draft.geometry.count==2 and not flow:isDirty() and flow.status==getText('UI_B47Rooms_RoomSaved'))
assert(ModData.getOrCreate('B47ANCEDRooms').customRooms.records[firstId].name=='Workshop Renamed')
assert(flow.roomType=='workshop' and flow.designation=='primary','rename/reload erased saved designation')
f.advance(3000);flow.roomType='kitchen';flow.designation='secondary';confirmation=nil;flow:submit()
assert(flow.submission and not confirmation,'metadata-only Save Changes did not use ordinary save')
for _=1,20 do Q.Registry.tick();f.advance(600);flow:update();if not flow:isBusy() then break end end
assert(flow.record.id==firstId and flow.roomType=='kitchen' and flow.designation=='secondary' and not flow:isDirty(),'designation save lost selected identity or reloaded stale labels')
flow:detect();flow:updateSidebar();assert(flow.detection and not flow.buttons.Save.enable)
flow:submit();assert(not flow.submission,'unfinished detection was submitted as a complete preview')
flow.detection=nil
-- Geometry replacements still require review; cancel leaves the edit intact.
flow:apply({x=0,y=1,z=0},{x=0,y=1,z=0});confirmation=nil;flow:submit()
assert(confirmation and not flow.submission);confirmation.callback('cancel');assert(flow:isDirty() and flow.record.id==firstId)
flow:requestClose();confirmation.callback('cancel');assert(not flow.closed and flow:isDirty())
flow:requestClose();confirmation.callback('accept');assert(flow.closed and p:isVisible())
-- Done/Escape also protect a new draft; incomplete previews never quick-save.
f.advance(3000);local draftEditor=E.open(0,p);draftEditor:apply({x=2,y=0,z=0},{x=2,y=0,z=0})
draftEditor:onKeyPress(Keyboard.KEY_ESCAPE);assert(confirmation and not draftEditor.closed)
confirmation.callback('cancel');draftEditor.incomplete='RoomUnloaded';draftEditor:submit()
assert(confirmation and not draftEditor.submission);confirmation.callback('cancel')
draftEditor.incomplete=nil;draftEditor:submit();assert(draftEditor.submission)
local beforeCancel=ModData.getOrCreate('B47ANCEDRooms').customRooms
draftEditor:requestClose();confirmation.callback('cancel');assert(draftEditor.submission and not draftEditor.closed)
draftEditor:requestClose();confirmation.callback('accept');Q.Registry.tick()
assert(draftEditor.closed and ModData.getOrCreate('B47ANCEDRooms').customRooms==beforeCancel)
-- Simulated transport: visitor policy edits reload the same selected room and
-- retain visitor context, including a bounded read retry after admission denial.
local roomLists,roomGets,writes={},{},{}
Q.Client.request=function(_,command,args,callback)
 local entry={args=args,callback=callback}
 if command=='roomList' then roomLists[#roomLists+1]=entry
 elseif command=='roomGet' then roomGets[#roomGets+1]=entry
 elseif command=='roomChange' then writes[#writes+1]=entry
 else error('unexpected contextual-editor command '..command) end
end
local managed=E.open(0,p)
local managedMeta={id=firstId,revision=3,label='Managed'}
local function replyList(index,revision)
 roomLists[index].callback({status='ok',revision=revision,editKey='context:'..revision,rooms={managedMeta},options={maxTiles=1024,doorways=true}})
end
local managedRoom={id=firstId,ordinal=1,revision=3,name='Managed',rows={{0,0,0,0}},canEditGeometry=true,canAssign=true,
 assigned='fixture-owner',policy={mode='private',rules={},grants={}},parentMembers={}}
replyList(1,100);managed:select(managedMeta);roomGets[1].callback({status='ok',room=managedRoom});managed:updateSidebar()
managed:openVisitors();assert(managed.accountEntry:isVisible() and managed.accountEntry.focused and managed.buttons.RoomVisitor:isVisible())
managed.accountEntry:setText('guest-account')
local getMenu=ISContextMenu.get;local visitorMenu
ISContextMenu.get=function(...) local menu=getMenu(...);visitorMenu=menu;return menu end
managed:visitorMenu();ISContextMenu.get=getMenu
assert(visitorMenu and #visitorMenu.options==12)
local choice=visitorMenu.options[1];choice.callback(choice.target)
assert(confirmation and #writes==0,'permission change bypassed review')
confirmation.callback('accept');replyList(2,100)
assert(#writes==1 and writes[1].args.action=='policy' and writes[1].args.policy.grants['guest-account'].discover==true)
writes[1].callback({status='ok',revision=101});assert(managed.loadingSelection and managed.record==nil)
managedMeta.revision=4;replyList(3,101)
roomGets[2].callback({status='rateLimited'});assert(managed.loadingSelection and managed.readRetry)
f.advance(600);managed:update();assert(#roomGets==3 and #writes==1,'read retry resubmitted a write')
managedRoom.revision=4;managedRoom.policy=writes[1].args.policy
roomGets[3].callback({status='ok',room=managedRoom});managed:updateSidebar()
assert(managed.record.id==firstId and managed.record.revision==4 and not managed:isDirty())
assert(managed.visitorEditing and managed.accountEntry:isVisible() and managed.accountEntry:getInternalText()=='guest-account')
managed.buttons.RoomHideVisitors.onclick(managed);assert(not managed.accountEntry:isVisible() and not managed.accountEntry:isFocused())
managed:refresh();roomLists[4].callback({status='rateLimited'});managed:updateSidebar()
assert(managed.buttons.RoomReload:isVisible() and managed.buttons.RoomReload.enable,'failed refresh had no recovery control')
managed.buttons.RoomReload.onclick(managed);replyList(5,101);managed:updateSidebar();assert(not managed.buttons.RoomReload:isVisible())
managed:requestClose();assert(managed.closed and p:isVisible());Q.Client.request=request
-- Floor groups and selection operate on bounded cached snapshots, never drawing.
local navLists,navGets={},{}
Q.Client.request=function(_,command,args,callback)
 if command=='roomList' then navLists[#navLists+1]=callback
 elseif command=='roomGet' then navGets[#navGets+1]={args=args,callback=callback}
 else error('outline selection issued a write '..command) end
end
local nav=E.open(0,p);local metadata={}
for i=1,10 do metadata[#metadata+1]={id='ground:'..i,name='Ground '..i,label='Ground '..i,revision=1,floors={0},count=1} end
metadata[#metadata+1]={id='upper',name='Upper',label='Upper',revision=2,floors={2},count=1,roomType='pantry',designation='secondary'}
metadata[#metadata+1]={id='stairs',name='Stairs',label='Stairs',revision=3,floors={0,2},count=2}
navLists[1]({status='ok',revision=10,editKey='navigation',rooms=metadata,options={maxTiles=1024}})
assert(nav.list.items[1].item.header and nav.list.items[1].item.listFloor==0)
assert(#nav.list.items==15 and nav.overlayLimited and #nav.fetch==8)
local text=nav.list.items[2].text;nav.list:doDrawItem(0,nav.list.items[2],false)
assert(nav.list.items[2].text==text and #nav.list.lastDrawn*7<=nav.list.width-32 and nav.list.items[2].tooltip,'long list labels spilled or lost full tooltip')
local multi=0;for _,row in ipairs(nav.list.items) do if row.item.id=='stairs' then multi=multi+1 end end;assert(multi==2)
nav:update();assert(navGets[1].args.id=='ground:1');local staleFloor=navGets[1].callback
nav:select({header=true,listFloor=2});assert(nav.floor==2 and nav.list.items[1].item.listFloor==2 and not nav.overlayLimited)
assert(#nav.fetch==2 and nav.fetch[1].id=='upper','current-floor overlays were not prioritized')
staleFloor({status='ok',room={id='ground:1',rows={{0,0,0,0}}}});assert(nav.saved['ground:1']==nil,'stale other-floor overlay was admitted')
nav.saved.upper={id='upper',ordinal=11,name='Upper',revision=2,rows={{2,0,0,0}},roomType='pantry',designation='secondary',canConfigureRoom=true}
nav.saved.stairs={id='stairs',ordinal=12,name='Stairs',revision=3,rows={{0,1,0,0},{2,0,0,0}},canConfigureRoom=true}
nav.cursor={x=0,y=0,z=2};nav:selectTool();local empty=nav.draft.geometry
local rootMenu;ISContextMenu.get=function(...) local menu=getMenu(...);if not rootMenu then rootMenu=menu end;return menu end
nav:onJoypadDown(Joypad.AButton);ISContextMenu.get=getMenu
assert(rootMenu and #rootMenu.options==2 and nav.draft.geometry==empty and not nav.first,'overlap selection drew or chose an arbitrary room')
choice=rootMenu.options[1];choice.callback(choice.target)
local read=navGets[#navGets];assert(read.args.id=='upper');read.callback({status='ok',room=nav.saved.upper})
assert(nav.record.id=='upper' and nav.tool=='RoomSelect' and nav.roomType=='pantry' and nav.designation=='secondary')
local previousReads=#navGets;nav.saved.stairs=nil;cursorX=0;cursorY=0
nav:onMouseDown(100,100);assert(not nav.capture and #navGets==previousReads+1)
nav:onMouseUp(100,100);assert(not nav.first,'Select mouse-up started a rectangle')
navGets[#navGets].callback({status='ok',room=nav.saved.upper})
local selected=nav.draft.geometry;nav:apply({x=1,y=1,z=2},{x=1,y=1,z=2});assert(nav.draft.geometry==selected)
nav:rebuildList();assert(nav.list.items[nav.list.selected].item.id=='upper')
-- Type/role menu changes only draft metadata and participates in dirty guards.
rootMenu=nil;ISContextMenu.get=function(...) local menu=getMenu(...);if not rootMenu then rootMenu=menu end;return menu end
nav:designationMenu();ISContextMenu.get=getMenu
assert(rootMenu and #rootMenu.options==2 and #rootMenu.options[1].sub.options==15)
choice=rootMenu.options[1].sub.options[2];choice.callback(choice.target)
choice=rootMenu.options[2].sub.options[2];choice.callback(choice.target)
nav:updateSidebar();assert(nav.roomType=='kitchen' and nav.designation=='primary' and nav:isDirty() and nav.buttons.Save.enable)
local reads=#navGets;nav:select(metadata[12]);assert(confirmation);confirmation.callback('cancel')
assert(#navGets==reads and nav.record.id=='upper' and nav.roomType=='kitchen','cancel selection lost unsaved designation')
nav:requestClose();confirmation.callback('cancel');assert(not nav.closed)
nav:requestClose();confirmation.callback('accept');assert(nav.closed)
Q.Client.request=request
dofile(TEST_ROOT..'/test_workflow.lua')
print('PASS OFFLINE room editor: creation/editing separation, quick create/rename, retained geometry/policy selection, contextual/advanced/visitor controls, busy guards, dirty Done/Escape, destructive/incomplete review, read recovery, consecutive saves, zoom and modal/parent lifecycle')
