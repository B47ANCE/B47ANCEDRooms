-- Runs after test_editor's native-shaped host setup; no actual UI/MP proof.
local Q,U=B47ANCEDRooms,B47RoomsUI;local E=Q.Editor;local f=CONTAINER_FIXTURE
local originalRequest,originalConfirm=Q.Client.request,U.Dialog.confirm
local lists,gets,writes={},{},{};local confirmation
Q.Client.request=function(_,command,args,callback)
 local entry={args=args,callback=callback}
 if command=='roomList' then lists[#lists+1]=entry elseif command=='roomGet' then gets[#gets+1]=entry
 elseif command=='roomChange' then writes[#writes+1]=entry elseif command=='roomCancel' then callback({status='cancelled'}) else error(command) end
end
U.Dialog.confirm=function(_,text,labels,callback) confirmation={text=text,callback=callback} end
local function reply(revision,rooms) lists[#lists].callback({status='ok',revision=revision,editKey='workflow:'..revision,rooms=rooms,options={maxTiles=1024}}) end
local function meta(id,revision,name,z,type,role) return {id=id,revision=revision,name=name,label=name,floors={z},count=1,roomType=type or 'kitchen',designation=role or 'primary'} end
local function room(m) return {id=m.id,ordinal=1,revision=m.revision,name=m.name,rows={{m.floors[1],0,0,0}},roomType=m.roomType,designation=m.designation,owner='creator',assigned='delegate',canConfigureRoom=true,
 policy={mode='private',rules={deposit='members'},grants={visitor={deposit=true}}},policyState='active',roomActions={deposit='allow',withdraw='deny'}} end
local function selectRoom(editor,m) editor:select(m);gets[#gets].callback({status='ok',room=room(m)}) end
local getMenu=ISContextMenu.get
local function menuFor(run)
 local root;ISContextMenu.get=function(...) local m=getMenu(...);if not root then root=m end;return m end
 run();ISContextMenu.get=getMenu;return root
end
local function pick(option) assert(option and option.callback);option.callback(option.target) end
local a=meta('a',1,'Alpha',0);local b=meta('b',1,'Beta',2,'pantry','secondary')
local editor=E.open(0);reply(1,{a,b});selectRoom(editor,a)
Q.changed(2);f.advance(300);editor:workflowTick();assert(#lists==2,'clean notification did not refresh')
a=meta('a',2,'Updated',0);reply(2,{a,b});gets[#gets].callback({status='ok',room=room(a)})
assert(editor.record.revision==2 and editor.nameEntry:getInternalText()=='Updated' and not editor:isDirty())
-- Start editing while automatic refresh is in flight; preserve the draft.
Q.changed(3);f.advance(300);editor:workflowTick();assert(#lists==3)
editor.nameEntry:setText('Local draft');local draft=editor.draft;local readCount=#gets
a=meta('a',3,'Remote edit',0);reply(3,{a,b});editor:updateSidebar()
assert(editor.draft==draft and editor.record.revision==2 and editor.nameEntry:getInternalText()=='Local draft')
assert(editor.stale and not editor.buttons.Save.enable and #gets==readCount)
editor:submit();assert(#writes==0,'stale draft bypassed recovery')
local choices=menuFor(function() editor:conflictMenu() end);assert(#choices.options==4)
pick(choices.options[3]);confirmation.callback('cancel');assert(editor.record.id=='a' and editor.draft==draft)
pick(choices.options[3]);confirmation.callback('accept')
assert(not editor.record and editor.draft.geometry.count==1 and editor.nameEntry:getInternalText()=='Local draft')
reply(3,{a,b});assert(not editor.stale and editor:isDirty() and #writes==0)
editor:closeEditor();local requests=#lists;Q.changed(4);assert(not editor.pendingRevision and #lists==requests,'subscription leaked')
-- Unrelated room changes can refresh the lease without discarding a draft.
editor=E.open(0);reply(3,{a,b});selectRoom(editor,a);editor.nameEntry:setText('Unrelated draft');draft=editor.draft
Q.changed(4);assert(editor.stale);editor.buttons.RoomReload.onclick(editor);reply(4,{a,b});editor:updateSidebar()
assert(not editor.stale and editor.draft==draft and editor.buttons.Save.enable)
editor:submit();reply(4,{a,b});assert(#writes==1 and writes[1].args.roomRevision==3 and writes[1].args.revision==4)
writes[1].callback({status='RoomDenied'});assert(editor.draft==draft and not editor.submission)
Q.changed(5);editor.buttons.RoomReload.onclick(editor);reply(5,{b});assert(editor.stale and editor.draft==draft)
choices=menuFor(function() editor:conflictMenu() end);pick(choices.options[2]);confirmation.callback('cancel');assert(editor.draft==draft)
pick(choices.options[2]);confirmation.callback('accept');reply(5,{b});assert(not editor.record and editor.draft.geometry.count==0);editor:closeEditor()
-- Plain text search, combined filters and selected room outside results.
editor=E.open(0);local c=meta('c',1,'[Medical]',1,'medical','unassigned');reply(5,{a,b,c})
editor.searchEntry:setText('REMOTE');editor:workflowTick();f.advance(200);editor:workflowTick();assert(editor.matchCount==1)
editor.searchEntry:setText('[');editor:workflowTick();f.advance(200);editor:workflowTick();assert(editor.matchCount==1,'search used Lua patterns')
choices=menuFor(function() editor:filtersMenu() end);pick(choices.options[4]);assert(editor.matchCount==3)
editor.filters={roomType='pantry',role='secondary',floor=2};editor:rebuildList();editor:queueOverlays();assert(editor.matchCount==1 and editor.list.items[2].item.id=='b')
editor.filters.floor='current';editor:setFloor(0);assert(editor.matchCount==0);editor:setFloor(2);assert(editor.matchCount==1)
editor.filters={};editor:setFloor(0);selectRoom(editor,a);editor.filters={roomType='medical'};editor:rebuildList();editor:queueOverlays()
assert(editor.matchCount==1 and editor.record.id=='a' and editor.saved.a)
b.canConfigureRoom=false;c.canConfigureRoom=false;editor:updateSidebar()
assert(not editor.buttons.RoomCopyPermissions.enable,'copy action offered no manageable source')
b.canConfigureRoom=nil;c.canConfigureRoom=nil;editor:updateSidebar()
local originalText=getText;getText=function(key,...) local out={key};for i=1,select('#',...) do out[#out+1]=tostring(select(i,...)) end;return table.concat(out,'|') end
editor.summaryOpen=true;local lines=editor:summaryLines();assert(#lines==11 and lines[1]:find('delegate',1,true))
assert(table.concat(lines,'\n'):find('RoomDecision_deny',1,true) and lines[11]:find('RoomSummaryBoundary',1,true));getText=originalText
-- Source preview, explicit confirmation and clean wire payload.
choices=menuFor(function() editor:copyPermissionsMenu() end);assert(#choices.options==2);pick(choices.options[1].sub.options[1]);assert(editor.loadingSelection)
local sourceRead=gets[#gets];assert(sourceRead.args.id=='b');sourceRead.callback({status='ok',room=room(b)})
assert(confirmation.text:find('RoomCopyMode',1,true) and #writes==1);confirmation.callback('accept');reply(5,{a,b,c})
assert(#writes==2 and writes[2].args.action=='copyPolicy' and writes[2].args.sourceId=='b' and writes[2].args.copyVisitors==false)
assert(writes[2].args.sourceLabel==nil and writes[2].args.sourceMode==nil);writes[2].callback({status='RoomDenied'});editor:closeEditor()
-- Repeated labels are session-only and do not dirty the next empty draft.
editor=E.open(0);reply(0,{});editor.buttons.RoomRepeat.onclick(editor);editor:apply({x=0,y=0,z=0},{x=0,y=0,z=0})
editor.roomType='workshop';editor.designation='secondary';editor.nameEntry:setText('Workshop');editor:submit();reply(0,{})
assert(#writes==3);writes[3].callback({status='ok',revision=1})
assert(editor.draft.geometry.count==0 and editor.roomType=='workshop' and editor.designation=='secondary' and not editor:isDirty())
reply(1,{});editor.buttons.RoomRepeat.onclick(editor);editor.buttons.RoomCreate.onclick(editor)
assert(editor.roomType=='unassigned' and editor.designation=='unassigned' and not editor:isDirty());editor:closeEditor()
editor=E.open(0);reply(1,{});Q.changed(0/0);Q.changed(-1);Q.changed(1);assert(not editor.pendingRevision)
Q.changed(2);f.advance(300);editor:workflowTick();lists[#lists].callback({status='rateLimited'})
local count=#lists;editor:workflowTick();assert(#lists==count);f.advance(1000);editor:workflowTick();assert(#lists==count+1)
lists[#lists].callback({status='rateLimited'});f.advance(10000);editor:workflowTick();assert(editor.refreshFailed and not editor.pendingRevision and #writes==3)
editor:closeEditor();Q.changed(3);assert(not editor.pendingRevision)
-- A selection request overlapping a live list read must get a fresh recheck.
editor=E.open(0);local old=meta('a',1,'Old snapshot',0);reply(1,{old});Q.changed(2);f.advance(300);editor:workflowTick()
editor:select(old);local oldReply=gets[#gets].callback;local latest=meta('a',2,'Latest snapshot',0);reply(2,{latest})
assert(editor.recheckSelection);oldReply({status='ok',room=room(old)});editor:workflowTick();reply(2,{latest})
gets[#gets].callback({status='ok',room=room(latest)})
assert(editor.record.revision==2 and editor.nameEntry:getInternalText()=='Latest snapshot')
editor:setHeight(480);editor:updateSidebar()
assert(editor.buttons.Save.parent==editor.actionBar and editor.buttons.Done.parent==editor.actionBar)
assert(editor.actionBar.y+editor.actionBar.height==480 and editor.sidebar.height<=editor.actionBar.y,'footer escaped viewport')
local textManager=getTextManager
getTextManager=function() return {getFontHeight=function() return 30 end,MeasureStringX=function(_,_,text) return #text*14 end} end
editor:updateSidebar();editor.sidebar:prerender()
assert(editor.list.itemheight>=38 and editor.list.fontHgt==30)
assert(editor.sidebar.scrollHeight==editor.statusY+#editor.textLines*36+12,'large-font summary lines overlapped')
assert(editor.actionBar.y+editor.actionBar.height==480 and editor.buttons.Save.height>=42)
getTextManager=textManager;editor:closeEditor()
Q.Client.request=originalRequest;U.Dialog.confirm=originalConfirm
print('PASS OFFLINE editor workflow: live refresh races, protected conflict copy/reload, filters/plain search, summaries, reviewed copy, repeated labels, bounded retry and cleanup')
