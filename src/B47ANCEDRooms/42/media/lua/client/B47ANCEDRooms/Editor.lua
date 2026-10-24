-- Explicitly active presentation/editor. Shared geometry is written only by Rooms.
require 'ISUI/ISPanelJoypad'
require 'ISUI/ISContextMenu'
require 'B47RoomsUI/Controls'
require 'B47RoomsUI/Dialog'
local Draft=require 'B47ANCEDRooms/Draft'
local Detect=require 'B47ANCEDRooms/Detection'
local G=require 'B47ANCEDRooms/Geometry'
local Types=require 'B47ANCEDRooms/RoomTypes'
local Q,U=B47ANCEDRooms,B47RoomsUI
local E=ISPanelJoypad:derive('B47RoomsEditor');Q.Editor=E
local active={};local sequence=0
local function tr(k,...) return getText('UI_B47Rooms_'..k,...) end
local function changed(self) self.edgeSource=nil;self.incomplete=nil;self.candidate=nil;self.detection=nil end
local function allowed(player,sq)
 if not sq then return false end
 if not isClient() and not isServer() then return true end
 return SafeHouse and SafeHouse.isSafehouseAllowInteract and SafeHouse.isSafehouseAllowInteract(sq,player)
  and SafeHouse.isSafehouseAllowLoot(sq,player) or false
end
local function wrap(text,width)
 local out={};local line=''
 for word in text:gmatch('%S+') do
  local candidate=line=='' and word or line..' '..word
  if line~='' and getTextManager():MeasureStringX(U.Theme.fonts.body,candidate)>width then out[#out+1]=line;line=word else line=candidate end
 end
 out[#out+1]=line;return out
end
function E:request(command,args,done)
 Q.Client.request(self.playerNum,command,args,function(r) if not self.closed then done(r) end end)
end
function E:message(code,detail)
 self.status=detail~=nil and tr(code or 'Ready',detail) or tr(code or 'Ready')
end
function E:isBusy() return self.submission~=nil or self.loadingSelection==true end
function E:designationDirty()
 return self.record and self.record.id and (self.roomType~=(self.record.roomType or 'unassigned') or self.designation~=(self.record.designation or 'unassigned'))
end
function E:isDirty()
 return self.draft and (not self.record and self.draft.geometry.count>0
  or not Q.Identity.equal(self.draft.geometry.rows,self.draft.original.rows)
  or self.roomType~=(self.startRoomType or 'unassigned') or self.designation~=(self.startDesignation or 'unassigned')
  or self.nameEntry:getInternalText()~=self.startName or self.draft.action~='save')
end
function E:load(room)
 self.readGeneration=(self.readGeneration or 0)+1
 self.record=room;self.draft=Draft.new(room);self.roomType=room and room.roomType or 'unassigned';self.designation=room and room.designation or 'unassigned';self.nameEntry:setText(room and room.name or tr('RoomDefaultName'))
 if not room and self.keepLabels and self.lastLabels then self.roomType=self.lastLabels.roomType;self.designation=self.lastLabels.designation end
 self.startRoomType=self.roomType;self.startDesignation=self.designation;self.stale=false
 self.accountEntry:setText('')
 self.secondName:setText(tr('RoomSecondName'));self.first=nil;self.detection=nil;self.incomplete=nil;self.mergeIDs=nil
 self.startName=self.nameEntry:getInternalText();self.conflict=nil;self.visitorEditing=false;self.loadingSelection=false;self.readRetry=nil
 self.tool='RoomAddRectangle';changed(self);self:message('RoomPreviewOnly')
 if not room or not room.id then self.list.selected=0 end
end
function E:readRoom(meta,message,after)
 self.readGeneration=(self.readGeneration or 0)+1;local generation=self.readGeneration
 local selectionTool=self.tool=='RoomSelect'
 self.loadingSelection=true;local started=getTimestampMs()
 local function read()
 self:request('roomGet',{id=meta.id,roomRevision=meta.revision},function(r)
  if generation~=self.readGeneration then return end
  if r.status=='rateLimited' and getTimestampMs()-started<10000 then self.readRetry={at=getTimestampMs()+500,run=read};return end
  self.readRetry=nil
  self.loadingSelection=false
  if r.status=='ok' then
   self.saved[meta.id]=r.room;self:load(r.room)
   if selectionTool then self.tool='RoomSelect' end
   self:highlightList();self:queueOverlays()
   if after and after.visitor and r.room.assigned then self.visitorEditing=true;self.accountEntry:setText(after.account or '') end
   if message then self:message(message,r.room.name) end
  else self.refreshFailed=true;self:message(r.status) end
 end)
 end
 read()
end
local function onFloor(meta,z)
 if meta.floors then for _,floor in ipairs(meta.floors) do if floor==z then return true end end;return false end
 return meta.bounds and meta.bounds.z1<=z and meta.bounds.z2>=z
end
function E:roomLabel(meta)
 return meta.label..' | '..tr('RoomType_'..(meta.roomType or 'unassigned'))..' / '..tr('RoomRole_'..(meta.designation or 'unassigned'))
end
function E:highlightList()
 self.list.selected=0
 if self.record and self.record.id then
  for i,row in ipairs(self.list.items) do if row.item.id==self.record.id and row.item.listFloor==self.floor then self.list.selected=i;return end end
 end
end
function E:rebuildList()
 self.list:clear();self.list.fontHgt=U.Theme.metrics().font;self.list.itemheight=math.max(24,self.list.fontHgt+8);local floors={};local groups={}
 for _,meta in ipairs(self.metadata or {}) do
  local levels=meta.floors or (meta.bounds and {meta.bounds.z1} or {self.floor})
  for _,z in ipairs(levels) do if self:matches(meta,z) then
   if not groups[z] then groups[z]={};floors[#floors+1]=z end
   groups[z][#groups[z]+1]=meta
  end end
 end
 table.sort(floors,function(a,b) if a==b then return false elseif a==self.floor then return true elseif b==self.floor then return false end;return a<b end)
 for _,z in ipairs(floors) do
  self.list:addItem(tr('RoomFloorGroup',z),{header=true,listFloor=z})
  for _,meta in ipairs(groups[z]) do
   local item=Q.Identity.copy(meta);item.listFloor=z;local row=self.list:addItem(self:roomLabel(meta),item)
   row.tooltip=row.text..'\n'..tr('RoomTileCount',meta.count or 0)
  end
 end
 local seen={};self.matchCount=0;for _,row in ipairs(self.list.items) do if row.item.id and not seen[row.item.id] then seen[row.item.id]=true;self.matchCount=self.matchCount+1 end end
 self:highlightList()
end
function E:queueOverlays()
 self.overlayGeneration=(self.overlayGeneration or 0)+1;self.fetchPending=false;self.fetch={};self.edgeSource=nil
 local keep={};local eligible=0
 for _,meta in ipairs(self.metadata or {}) do if onFloor(meta,self.floor) and self:matches(meta,self.floor) then
  eligible=eligible+1
  if eligible<=8 then keep[meta.id]=true;if not self.saved[meta.id] then self.fetch[#self.fetch+1]=meta end end
 end end
 self.overlayLimited=eligible>8
 for id in pairs(self.saved) do if not keep[id] and not (self.record and self.record.id==id) then self.saved[id]=nil end end
 self.savedShapes={}
end
function E:setFloor(z)
 self.floor=math.max(-32,math.min(31,z));self.cursor.z=self.floor;self.first=nil;self.down=false;self:setCapture(false)
 self:rebuildList();self:queueOverlays()
end
function E:savedShape(id,room)
 self.savedShapes=self.savedShapes or {};local entry=self.savedShapes[id]
 if not entry or entry.source~=room then entry={source=room,geometry=G.normalize(room.rows)};self.savedShapes[id]=entry end
 return entry.geometry
end
function E:roomsUnderCursor()
 local out={};local p=self.cursor
 for _,meta in ipairs(self.metadata or {}) do local room=self.saved[meta.id]
  if room and G.contains(self:savedShape(meta.id,room),p.x,p.y,p.z) then out[#out+1]=meta end
 end
 return out
end
function E:selectAtCursor()
 local rooms=self:roomsUnderCursor()
 if #rooms==0 then self:message('RoomSelectEmpty');return end
 if #rooms==1 then self:select(rooms[1]);return end
 local menu=ISContextMenu.get(self.playerNum,getMouseX(),getMouseY())
 for _,meta in ipairs(rooms) do local choice=meta;menu:addOption(self:roomLabel(meta),self,function() self:select(choice) end) end
 U.menu(menu);if self.joyfocus then setJoypadFocus(self.playerNum,menu) end
end
function E:selectTool()
 if self:isBusy() then return end
 self.tool='RoomSelect';self.first=nil;self.down=false;self.detection=nil;self:setCapture(false);self.worldFocus=true
 self.edgeSource=nil;setJoypadFocus(self.playerNum,self);self:message('RoomSelectHelp')
end
function E:designationMenu()
 if self:isBusy() or self.draft.action~='save' or self.record and self.record.id and not self.record.canConfigureRoom then return end
 local menu=ISContextMenu.get(self.playerNum,getMouseX(),getMouseY())
 local option=menu:addOption(tr('RoomTypeMenu'));local sub=ISContextMenu:getNew(menu);menu:addSubMenu(option,sub)
 local ids={'unassigned'};for _,id in ipairs(Types.ids) do ids[#ids+1]=id end
 for _,id in ipairs(ids) do local value=id;sub:addOption(tr('RoomType_'..id),self,function() self.roomType=value;self:updateSidebar() end) end
 option=menu:addOption(tr('RoomRoleMenu'));sub=ISContextMenu:getNew(menu);menu:addSubMenu(option,sub)
 for _,id in ipairs(Types.roles) do local value=id;sub:addOption(tr('RoomRole_'..id),self,function() self.designation=value;self:updateSidebar() end) end
 U.menu(menu);if self.joyfocus then setJoypadFocus(self.playerNum,menu) end
end
function E:select(meta)
 if self:isBusy() then return end
 if meta and meta.header then self:setFloor(meta.listFloor);return end
 local function perform()
  if not meta then self:load();return end
  if meta.listFloor~=nil then self:setFloor(meta.listFloor) end
  self:readRoom(meta)
 end
 if self:isDirty() then U.Dialog.confirm(self.playerNum,tr('RoomDiscard'),{accept=tr('Discard'),cancel=tr('Cancel')},function(result) if not self.closed then if result=='accept' then perform() else self:highlightList() end end end,self)
 else perform() end
end
function E:refresh(after)
 self.refreshGeneration=(self.refreshGeneration or 0)+1;local generation=self.refreshGeneration
 self.overlayGeneration=(self.overlayGeneration or 0)+1
 self.fetchPending=false;self.fetch={};self.refreshFailed=false;self.listPending=true
 self:request('roomList',{},function(r)
  if generation~=self.refreshGeneration then return end
  self.listPending=false
  if r.status~='ok' then self.loadingSelection=false;self.refreshFailed=true;self:message(r.status);return end
  self.revision=r.revision;self.editKey=r.editKey;self.options=r.options;self.metadata=r.rooms;self.list:clear()
  self.saved={};self.edgeSource=nil
  self:rebuildList();self:queueOverlays()
  if self:afterRefresh(after) then return end
  if after and after.id then
   for _,meta in ipairs(r.rooms) do if meta.id==after.id then self:readRoom(meta,'RoomSaved',after);return end end
   self.loadingSelection=false;self:message('RoomUnavailable');return
  end
  self:message(self.conflict or after and after.message or 'RoomPreviewOnly',after and after.name)
 end)
end
function E:saveSucceeded(submission)
 if self.submission~=submission then return end
 self.submission=nil
 if Q.onRoomsChanged then Q.onRoomsChanged() end
 if self.closed then return end
 -- Creates advance; existing edits reload their authoritative record. Both wait
 -- for a fresh lease, without ending this editor session or restoring its parent.
 self.revision=nil;self.editKey=nil;self.down=false;self.dragStart=nil
 self:setCapture(false);self.disconnected=false
 local args=submission.args;if not args.id and args.action=='save' then self.lastLabels={roomType=args.roomType,designation=args.designation} end
 local id=args.id and args.action~='delete' and args.id
 local visitor=self.visitorEditing;local account=self.accountEntry:getInternalText()
 self:load();self.loadingSelection=id~=nil
 self:refresh({id=id,message=args.action=='delete' and 'RoomDeleted' or 'RoomSavedNext',name=args.name,visitor=visitor,account=account})
 self:updateSidebar()
end
function E:detect()
 if self:isBusy() then return end
 if self.draft and self.draft.action~='save' then self:message('RoomFinishCompound');return end
 local p=self.cursor;local sq=getCell():getGridSquare(p.x,p.y,p.z)
 local job,e=Detect.start(sq,self.options and self.options.maxTiles or 1024,self.options and self.options.doorways)
 if not job then self:message(e);return end
 self.detection=job;self:message('RoomDetecting')
end
function E:tools()
 if self:isBusy() then return end
 local menu=ISContextMenu.get(self.playerNum,getMouseX(),getMouseY())
 for _,key in ipairs({'RoomAddRectangle','RoomRemoveRectangle','RoomPaint','RoomErase','RoomSplit'}) do
  local tool=key;local option=menu:addOption(tr(key),self,function() self.tool=tool;self.first=nil;self.worldFocus=true;setJoypadFocus(self.playerNum,self);self:message('RoomWorldHelp') end)
  option.notAvailable=self.draft.action~='save' or key=='RoomSplit' and (self:designationDirty() or not (self.record and self.record.id and self.advanced))
 end
 U.menu(menu);if self.joyfocus then setJoypadFocus(self.playerNum,menu) end
end
function E:combine()
 if self:isBusy() then return end
 if self:designationDirty() then self:message('RoomSaveBeforePolicy');return end
 if not self.record or not self.record.id then self:message('RoomSelectSaved');return end
 local menu=ISContextMenu.get(self.playerNum,getMouseX(),getMouseY())
 for _,m in ipairs(self.metadata or {}) do if m.id~=self.record.id then local other=m
  menu:addOption(other.label,self,function()
   local draft=self.draft
   self:request('roomGet',{id=other.id,roomRevision=other.revision},function(r)
    if self.draft~=draft then return end
    if r.status~='ok' then self:message(r.status);return end
    local ok,e=self.draft:combine(r.room,self.record.id)
    if ok then changed(self);self:message('RoomMergePreview') else self:message(e) end
   end)
  end)
 end end
 U.menu(menu);if self.joyfocus then setJoypadFocus(self.playerNum,menu) end
end
function E:apply(a,b)
 if self:isBusy() or self.tool=='RoomSelect' then return end
 local region,e=G.rectangle(a,b);if not region then self:message(e);return end
 local ok
 if self.tool=='RoomSplit' then ok,e=self.draft:split(region.rows)
 else ok,e=self.draft:edit(region.rows,self.tool=='RoomRemoveRectangle' or self.tool=='RoomErase') end
 if ok then self.detection=nil;changed(self);self:message('RoomPreviewOnly') else self:message(e) end
end
function E:point()
 if not self.worldFocus then return end
 if self.tool=='RoomSelect' then self:selectAtCursor();return end
 if self.tool=='RoomPaint' or self.tool=='RoomErase' then self:apply(self.cursor,self.cursor)
 elseif self.first then self:apply(self.first,self.cursor);self.first=nil
 else self.first={x=self.cursor.x,y=self.cursor.y,z=self.cursor.z};self:message('RoomSecondCorner') end
end
function E:mouseTile()
 local x,y=ISCoordConversion.ToWorld(getMouseXScaled(),getMouseYScaled(),self.floor)
 return {x=math.floor(x),y=math.floor(y),z=self.floor}
end
function E:onMouseDown(x,y)
 if U.Dialog.active(self) then self.b47Dialog:bringToTop();return true end
 if self:isBusy() then return true end
 if x>=self.sidebar.x then return true end
 self.worldFocus=true;self.cursor=self:mouseTile()
 if self.tool=='RoomSelect' then self:selectAtCursor();return true end
 self.down=true;self.dragStart=self.cursor
 self:setCapture(true);return true
end
function E:onMouseMove(dx,dy)
 if U.Dialog.active(self) then return true end
 if self:isBusy() then return true end
 self.cursor=self:mouseTile()
 if not self.down then return true end
 return true
end
function E:onMouseUp(x,y)
 if U.Dialog.active(self) then return true end
 if self:isBusy() then return true end
 if self.down then
  self.cursor=self:mouseTile();self.down=false;self:setCapture(false)
  if self.tool=='RoomPaint' or self.tool=='RoomErase' then
   self:apply(self.dragStart,self.cursor)
  elseif self.dragStart.x~=self.cursor.x or self.dragStart.y~=self.cursor.y then
   self:apply(self.dragStart,self.cursor);self.first=nil
  else self:point() end
 end
 return true
end
function E:onMouseUpOutside(x,y) return self:onMouseUp(x,y) end
function E:onMouseDownOutside() return true end
function E:onRightMouseDown()
 if U.Dialog.active(self) then return true end
 self.first=nil;self.down=false;self:setCapture(false);self.worldFocus=false;return true
end
function E:isKeyConsumed() return true end
function E:onFocus(x,y)
 local dialog=U.Dialog.active(self)
 if dialog then dialog:bringToTop() else ISPanelJoypad.onFocus(self,x,y) end
end
function E:onKeyPress(key)
 if U.Dialog.active(self) then return end
 if key==Keyboard.KEY_ESCAPE then self:requestClose()
 elseif self:isBusy() then return
 elseif self.nameEntry:isFocused() or self.secondName:isFocused() or self.accountEntry:isFocused() or self.searchEntry:isFocused() then return
 elseif isCtrlKeyDown() and key==Keyboard.KEY_Z then if isShiftKeyDown() then self.draft:redo() else self.draft:undo() end;changed(self)
 elseif isCtrlKeyDown() and key==Keyboard.KEY_Y then self.draft:redo();changed(self) end
end
function E:onJoypadDown(key,data)
 if U.Dialog.active(self) then return end
 if key==Joypad.BButton then
  if self.worldFocus then self.first=nil;self.worldFocus=false;self:restoreJoypadFocus() else self:requestClose() end;return
 end
 if self:isBusy() then return end
 if self.worldFocus then if key==Joypad.AButton then self:point() elseif key==Joypad.YButton then self.worldFocus=false;self:restoreJoypadFocus() end;return end
 ISPanelJoypad.onJoypadDown(self,key,data)
end
for method,d in pairs({onJoypadDirUp={0,-1},onJoypadDirDown={0,1},onJoypadDirLeft={-1,0},onJoypadDirRight={1,0}}) do
 local delta=d;E[method]=function(self,data)
  if U.Dialog.active(self) or self:isBusy() then return end
  if self.worldFocus then self.cursor.x=self.cursor.x+delta[1];self.cursor.y=self.cursor.y+delta[2]
  else ISPanelJoypad[method](self,data) end
 end
end
function E:permissions()
 if self:isBusy() then return end
 local room=self.record;if not room or not room.id then self:message('RoomSelectSaved');return end
 if self:isDirty() then self:message('RoomSaveBeforePolicy');return end
 local menu=ISContextMenu.get(self.playerNum,getMouseX(),getMouseY())
 if room.canAssign then
  local assign=menu:addOption(tr('RoomAssign'));local sub=ISContextMenu:getNew(menu);menu:addSubMenu(assign,sub)
  for _,account in ipairs(room.parentMembers or {}) do local who=account;sub:addOption(who,self,function() self:submit('assign',{assigned=who}) end) end
  assign.notAvailable=#(room.parentMembers or {})==0
  if room.assigned then menu:addOption(tr('RoomRevoke'),self,function() self:submit('assign') end) end
 end
 if room.canRelinquish then menu:addOption(tr('RoomRelinquish'),self,function() self:submit('relinquish') end) end
 local function policy(rules,mode)
  self:submit('policy',{policy={mode=mode or 'private',rules=rules or {},grants={}}})
 end
 menu:addOption(tr('RoomShared'),self,function() policy({},'shared') end)
 local private=menu:addOption(tr('RoomPrivate'),self,function() policy({}) end);private.notAvailable=not room.assigned
 local deposit=menu:addOption(tr('RoomDepositOnly'),self,function() policy({discover='members',inspect='members',withdraw='none',deposit='members'}) end);deposit.notAvailable=not room.assigned
 local withdraw=menu:addOption(tr('RoomWithdrawOnly'),self,function() policy({discover='members',inspect='members',withdraw='members',deposit='none'}) end);withdraw.notAvailable=not room.assigned
  for _,action in ipairs({'discover','inspect','withdraw','deposit','configure','clean'}) do
  local which=action;local option=menu:addOption(tr('RoomAction_'..which));local sub=ISContextMenu:getNew(menu);menu:addSubMenu(option,sub);option.notAvailable=not room.assigned
  for _,rule in ipairs({'owner','members','none'}) do local value=rule
   sub:addOption(tr('RoomRule_'..value),self,function()
    local p=Q.Identity.copy(room.policy or {mode='private',rules={},grants={}});p.mode='private';p.rules[which]=value;self:submit('policy',{policy=p})
   end)
  end
 end
 local visitor=menu:addOption(tr('RoomManageVisitors'),self,E.openVisitors);visitor.notAvailable=not room.assigned
 if room.pendingBoundary and room.canEditGeometry then
  menu:addOption(tr('RoomApproveBoundary'),self,function() self:submit('approveBoundary') end)
  menu:addOption(tr('RoomRejectBoundary'),self,function() self:submit('rejectBoundary') end)
 end
 U.menu(menu);if self.joyfocus then setJoypadFocus(self.playerNum,menu) end
end
function E:openVisitors()
 if self:isBusy() or not self.record or not self.record.assigned then return end
 self.visitorEditing=true;self:updateSidebar();self.accountEntry:focus()
end
function E:visitorMenu()
 local room=self.record;if self:isBusy() or not room or not room.assigned then return end
 if self:isDirty() then self:message('RoomSaveBeforePolicy');return end
 local who=self.accountEntry:getInternalText():match('^%s*(.-)%s*$')
 if who=='' then self:message('RoomVisitorRequired');return end
 local menu=ISContextMenu.get(self.playerNum,getMouseX(),getMouseY())
  for _,action in ipairs({'discover','inspect','withdraw','deposit','configure','clean'}) do local which=action
  for _,allow in ipairs({true,false}) do local granted=allow
   menu:addOption(tr(granted and 'RoomGrant' or 'RoomDeny',tr('RoomAction_'..which)),self,function()
    local p=Q.Identity.copy(room.policy or {mode='private',rules={},grants={}});p.mode='private';p.grants[who]=p.grants[who] or {};p.grants[who][which]=granted;self:submit('policy',{policy=p})
   end)
  end
 end
 U.menu(menu);if self.joyfocus then setJoypadFocus(self.playerNum,menu) end
end
function E:submit(action,extra)
 if self:isBusy() or self.revision==nil then return end
 if self.stale then self:message('RoomChangesWaiting');return end
 if self.detection then self:message('RoomDetecting');return end
 local draft=self.draft;local record=self.record;local count=draft.geometry.count
 if action~='delete' and count==0 then self:message('RoomGeometryInvalid');return end
 local function confirm(result)
  if self.closed or result~='accept' then return end
  sequence=sequence+1;local nonce=tostring(getTimestampMs())..':'..sequence
  local args={action=action or draft.action,nonce=nonce,editKey=self.editKey,revision=self.revision,id=record and record.id,roomRevision=record and record.revision,
   name=self.nameEntry:getInternalText(),rows=draft.geometry.rows,roomType=self.roomType,designation=self.designation,disconnected=self.disconnected,confirm=true,
   ids=draft.ids,secondName=self.secondName:getInternalText(),secondRows=draft.second and draft.second.rows}
  for k,v in pairs(extra or {}) do if k~='sourceLabel' and k~='sourceMode' then args[k]=v end end
  local submission={args=args,nextAt=0,time=getTimestampMs(),changePending=true};self.submission=submission;self:message('RoomSaving')
  self:updateSidebar()
  -- Acquire a fresh server lease after confirmation, preserving the preview's
  -- original revisions. Long editing/review time cannot expire a valid save.
  self:request('roomList',{renew=true},function(lease)
   if self.submission~=submission then return end
   if lease.status~='ok' or lease.revision~=args.revision then
    self.submission=nil;self.conflict=lease.status=='ok' and 'RoomEditConflict' or lease.status;self:message(self.conflict);self:refresh();return
   end
   args.editKey=lease.editKey;self.editKey=lease.editKey
   self:request('roomChange',args,function(r)
    if self.submission~=submission then return end;submission.changePending=false
    if r.status=='uncertain' or r.status=='timeout' then self:message('RoomOutcomeUnknown');return end
    if r.status=='ok' then self:saveSucceeded(submission);return end
    if r.status~='pending' then self.submission=nil;self:message(r.status);if r.status=='conflict' or r.status=='expired' then self.conflict='RoomEditConflict';self:refresh() end end
   end)
  end)
 end
 local identity=record and record.id and ('r'..tostring(record.ordinal)) or tr('RoomNewIdentity')
 local text=action=='delete' and tr('RoomDeleteConfirm',identity) or tr('RoomSaveConfirm',identity,count)
 if action=='copyPolicy' then text=tr(extra.copyVisitors and 'RoomCopyVisitorsConfirm' or 'RoomCopyRulesConfirm',extra.sourceLabel or '',record.name)..'\n'..tr('RoomCopyMode',tr(extra.sourceMode=='private' and 'RoomPrivate' or 'RoomShared')) end
 if action~='delete' and draft.action=='merge' then
  local labels={};for _,id in ipairs(draft.ids) do
   local label=id:sub(-8);for _,meta in ipairs(self.metadata or {}) do if meta.id==id then label=meta.label;break end end;labels[#labels+1]=label
  end
  text=text..'\n'..tr('RoomMergeConfirm',table.concat(labels,', '),identity)
 end
 if action~='delete' and draft.action=='split' then text=text..'\n'..tr('RoomSplitConfirm',identity) end
 if self.incomplete then text=text..'\n'..tr('RoomIncompleteConfirm') end
 if record and record.assigned and not record.canEditGeometry and not action then text=text..'\n'..tr('RoomBoundaryApproval') end
 if G.components(draft.geometry)>1 then text=text..'\n'..tr('RoomDisconnectedWarning') end
 local operation=action or draft.action
 local changedGeometry=record and not Q.Identity.equal(draft.geometry.rows,draft.original.rows)
 local review=operation~='save' or changedGeometry or self.incomplete or G.components(draft.geometry)>1
 if review then U.Dialog.confirm(self.playerNum,text,{accept=tr(action=='delete' and 'RoomDelete' or 'Save'),cancel=tr('Cancel')},confirm,self)
 else confirm('accept') end
end
function E:requestClose()
 if self.closed then return end
 if self.submission or self:isDirty() then
  U.Dialog.confirm(self.playerNum,tr(self.submission and 'RoomCancelPending' or 'RoomDiscard'),{accept=tr(self.submission and 'Done' or 'Discard'),cancel=tr('Cancel')},function(result)
   if result=='accept' and not self.closed then self:closeEditor() end
  end,self)
 else self:closeEditor() end
end
function E:closeEditor()
 if self.closed then return end
 local player,owner,onClose=self.player,self.owner,self.onClose
 if self.submission then
  local args=self.submission.args
  Q.Client.request(self.playerNum,'roomCancel',{nonce=args.nonce,editKey=args.editKey},function(result)
   if result.status=='ok' and player and player.setHaloNote then player:setHaloNote(tr('RoomAlreadySaved')) end
   if (result.status=='uncertain' or result.status=='timeout') and player and player.setHaloNote then player:setHaloNote(tr('RoomOutcomeUnknown')) end
  end)
 end
 self.closed=true;if self.unsubscribe then self.unsubscribe();self.unsubscribe=nil end;self.pendingRevision=nil;self.recheckSelection=nil
 U.Dialog.close(self);self.detection=nil;self.readRetry=nil;self.down=false;self.first=nil;self.submission=nil;self.saved={};self.savedShapes=nil;self.edgeCache={}
 self:setCapture(false);self:setWantKeyEvents(false);active[self.playerNum]=nil
 ISPanelJoypad.removeFromUIManager(self)
 if owner and not owner.removed then owner:setVisible(true) end
 U.Focus.restore(self.playerNum,owner)
 self.draft=nil;self.fetch=nil;self.metadata=nil;self.record=nil;self.owner=nil;self.player=nil;self.onClose=nil
 self.lastLabels=nil;self.filters=nil;self.searchPending=nil;self.edgeSource=nil;self.validation=nil;self.validationSource=nil;self.invalidTiles=nil;self.textLines=nil
 if onClose then onClose() end
end
function E:removeFromUIManager() self:closeEditor() end
function E:updateSidebar()
 if not self.buttons then return end
 local record=self.record;local saved=record and record.id~=nil or false
 local visitor=saved and record.assigned~=nil and self.visitorEditing or false
 local busy=self:isBusy();local count=self.draft and self.draft.geometry.count or 0
 local split=self.draft and self.draft.action=='split' or false
 local dirty=self:isDirty() or false;local h=U.Theme.metrics().button
 local history=self.draft and #self.draft.history>0 or false
 local future=self.draft and #self.draft.future>0 or false
 local geometry=saved and record.canEditGeometry==true
 local hasCopySource=false;for _,meta in ipairs(self.metadata or {}) do if saved and meta.id~=record.id and meta.canConfigureRoom~=false then hasCopySource=true;break end end
 local key=table.concat({tostring(saved),tostring(visitor),tostring(busy),tostring(split),tostring(dirty),
  tostring(self.advanced),tostring(geometry),tostring(count>0),tostring(self.revision~=nil),
  tostring(hasCopySource),tostring(self.stale),tostring(self.keepLabels),tostring(self.summaryOpen),tostring(self.searchEntry and self.searchEntry:getInternalText()==''),tostring(self.roomType),tostring(self.designation),tostring(self.draft and self.draft.action),tostring(record and record.canConfigureRoom),tostring(self.refreshFailed),tostring(self.detection~=nil),tostring(history),tostring(future),self.sidebar.width,self.height,h},':')
 if self.layoutKey==key then return end;self.layoutKey=key
 local width=math.max(1,self.sidebar.width-32);local y=12
 self.sidebar:setHeight(math.max(1,self.height-h-16))
 U.Layout.place(self.actionBar,self.sidebar.x,math.max(0,self.height-h-16),self.sidebar.width,h+16)
 if self.list.itemheight~=math.max(24,U.Theme.metrics().font+8) then self:rebuildList() end
 local function place(widget,show,height)
  widget:setVisible(show)
  if show then U.Layout.place(widget,12,y,width,height);y=y+height+4 end
 end
 place(self.searchEntry,true,h);self.searchControls:layout();place(self.filterButton,true,h)
 place(self.list,true,144);place(self.nameEntry,true,h)
 place(self.secondName,split,h);place(self.accountEntry,visitor,h)
 if not visitor and self.accountEntry:isFocused() then self.accountEntry:unfocus() end
 for _,entry in ipairs(self.buttonRows) do
  local show=entry.when=='footer' or entry.when=='basic' or entry.when=='saved' and saved or entry.when=='visitor' and visitor
   or entry.when=='advanced' and self.advanced or entry.when=='advancedSaved' and self.advanced and saved
   or entry.when=='advancedGeometry' and self.advanced and geometry or entry.when=='refresh' and (self.refreshFailed or self.stale) or entry.when=='conflict' and self.stale
  local visible={}
  for _,button in ipairs(entry.controls) do
   local on=show and (button.b47Condition~='geometry' or geometry) or false
   button:setVisible(on);button:setEnable(not busy or button==self.buttons.Done)
   if on then visible[#visible+1]=button end
  end
  local w=#visible==2 and (width-4)/2 or width
  for i,button in ipairs(visible) do U.Layout.place(button,12+(i-1)*(w+4),entry.when=='footer' and 8 or y,w,h) end
  if #visible>0 and entry.when~='footer' then y=y+h+4 end
 end
 self.buttons.RoomDesignation:setTitle(tr('RoomDesignationSummary',tr('RoomType_'..(self.roomType or 'unassigned')),tr('RoomRole_'..(self.designation or 'unassigned'))))
 self.buttons.RoomDesignation:setEnable(not busy and self.draft~=nil and self.draft.action=='save' and (not saved or record.canConfigureRoom==true))
 self.buttons.Save:setTitle(tr(saved and 'RoomSaveChanges' or 'RoomSaveNext'))
 self.buttons.Save:setEnable(not busy and not self.stale and not self.detection and self.revision~=nil and count>0 and (not saved or dirty))
 self.buttons.RoomUndo:setEnable(not busy and history);self.buttons.RoomRedo:setEnable(not busy and future)
 self.buttons.RoomClear:setEnable(not busy and count>0)
 self.buttons.RoomPermissions:setEnable(not busy and saved and not dirty)
 self.buttons.RoomPermissions:setTooltip(tr(dirty and 'RoomSaveBeforePolicy' or 'RoomPermissionsHelp'))
 self.buttons.RoomCopyPermissions:setEnable(not busy and not dirty and not self.stale and hasCopySource and saved and record.canConfigureRoom==true)
 self.buttons.RoomDelete:setEnable(not busy and not self.stale and saved and record.canEditGeometry==true)
 self.buttons.RoomRepeat:setTitle(tr(self.keepLabels and 'RoomRepeatOn' or 'RoomRepeatOff'))
 self.buttons.RoomSummary:setTitle(tr(self.summaryOpen and 'RoomSummaryHide' or 'RoomSummaryShow'))
 self.filterButton:setEnable(not busy);self.searchEntry:setEditable(not busy);self.searchControls.clear:setEnable(not busy)
 self.buttons.RoomVisitor:setEnable(not busy and visitor and not dirty)
 self.buttons.RoomAdvanced:setTitle(tr(self.advanced and 'RoomAdvancedHide' or 'RoomAdvancedShow'))
 self.buttons.RoomDisconnectedToggle:setTitle(tr(self.disconnected and 'RoomDisconnectedOn' or 'RoomDisconnectedOff'))
 self.nameEntry:setEditable(not busy);self.secondName:setEditable(not busy);self.accountEntry:setEditable(not busy)
 self.statusY=y+8;self.textKey=nil
 U.Focus.visibleRows(self,function(panel)
  panel.joypadButtonsY={};panel.allJoypadButtons={};panel.joypadButtons={}
  panel:insertNewLineOfButtons(panel.searchEntry,panel.searchControls.clear);panel:insertNewLineOfButtons(panel.filterButton)
  panel:insertNewLineOfButtons(panel.list);panel:insertNewLineOfButtons(panel.nameEntry)
  panel:insertNewLineOfButtons(panel.secondName);panel:insertNewLineOfButtons(panel.accountEntry)
  for _,entry in ipairs(panel.buttonRows) do panel:insertNewLineOfButtons(unpack(entry.controls)) end
 end)
 self.joypadIndexY=math.max(1,math.min(self.joypadIndexY or 1,#self.joypadButtonsY))
 local row=self.joypadButtonsY[self.joypadIndexY] or {}
 self.joypadIndex=math.max(1,math.min(self.joypadIndex or 1,#row))
 if self.joyfocus and not U.Dialog.active(self) then self:restoreJoypadFocus(self.joyfocus) end
end
function E:createChildren()
 self.sidebar=ISPanelJoypad:new(math.max(0,self.width-360),0,math.min(360,self.width),self.height)
 self.sidebar:initialise();self:addChild(self.sidebar);U.skin(self.sidebar,'panel')
 self.sidebar:setScrollChildren(true);self.sidebar:addScrollBars()
 self.actionBar=ISPanelJoypad:new(self.sidebar.x,0,self.sidebar.width,44);self.actionBar:initialise();self:addChild(self.actionBar);U.skin(self.actionBar,'panel')
 local function add(widget,parent)
  widget:initialise();widget:instantiate();(parent or self.sidebar):addChild(widget);return widget
 end
 self.searchEntry=add(U.TextInput:new('',12,0,200,28));self.searchEntry:setMaxTextLength(96);self.searchEntry:setTooltip(tr('RoomSearch'))
 self.searchControls=U.SearchField.attach(self.sidebar,self.searchEntry,tr('RoomSearch'))
 self.filterButton=add(U.Button:new(12,0,200,28,tr('RoomFilters'),self,E.filtersMenu))
 self.list=add(U.ScrollList:new(12,12,200,96));self.list.itemheight=24
 local drawItem=self.list.doDrawItem
 if drawItem then self.list.doDrawItem=function(list,y,item,alt)
  local full=item.text;local width=math.max(1,list.width-32);local font=U.Theme.metrics().font
  if item.b47FullText~=full or item.b47FitWidth~=width or item.b47FitFont~=font then
   item.b47FullText=full;item.b47FitWidth=width;item.b47FitFont=font;item.b47FitText=U.Renderer.fit(full,width,list.font)
  end
  item.text=item.b47FitText
  local ok,result=pcall(drawItem,list,y,item,alt);item.text=full;if not ok then error(result) end;return result
 end end
 self.list:setOnMouseDownFunction(self,function(editor,room) editor:select(room) end)
 self.list:setOverrideAButtonFunction(self,function(editor) local e=editor.list.items[editor.list.selected];if e then editor:select(e.item) end end)
 self.nameEntry=add(U.TextInput:new('',12,0,200,28));self.nameEntry:setMaxTextLength(96);self.nameEntry:setTooltip(tr('RoomNameHelp'))
 self.secondName=add(U.TextInput:new(tr('RoomSecondName'),12,0,200,28));self.secondName:setMaxTextLength(96)
 self.accountEntry=add(U.TextInput:new('',12,0,200,28));self.accountEntry:setMaxTextLength(256);self.accountEntry:setTooltip(tr('RoomAccountHelp'))
 self.buttons={};self.buttonRows={};self.joypadButtonsY={};self.allJoypadButtons={};self.joypadButtons={}
 local function row(when,left,right)
  local controls={}
  for _,spec in ipairs({left,right}) do
   local button=add(U.Button:new(12,0,200,28,tr(spec[1]),self,spec[2]),when=='footer' and self.actionBar or self.sidebar)
   button.b47Condition=spec[3];self.buttons[spec[1]]=button;controls[#controls+1]=button
  end
  self.buttonRows[#self.buttonRows+1]={when=when,controls=controls}
 end
 row('basic',{'RoomCreate',function() self:select(nil) end},{'RoomTools',E.tools})
 row('basic',{'RoomSelect',E.selectTool},{'RoomRedetect',E.detect})
 row('basic',{'RoomDesignation',E.designationMenu})
 row('basic',{'RoomUndo',function() self.draft:undo();changed(self) end},{'RoomRedo',function() self.draft:redo();changed(self) end})
 row('basic',{'RoomFloorDown',function() self:setFloor(self.floor-1) end},
  {'RoomFloorUp',function() self:setFloor(self.floor+1) end})
 row('saved',{'RoomSummary',function() self.summaryOpen=not self.summaryOpen;self:updateSidebar() end},{'RoomPermissions',E.permissions})
 row('saved',{'RoomCopyPermissions',E.copyPermissionsMenu})
 row('saved',{'RoomDelete',function() if self.record then self:submit('delete') end end})
 row('basic',{'RoomRepeat',function() self.keepLabels=not self.keepLabels;self:updateSidebar() end})
 row('visitor',{'RoomVisitor',E.visitorMenu},{'RoomHideVisitors',function() self.visitorEditing=false;self:updateSidebar() end})
 row('refresh',{'RoomReload',function() self:refresh({live=true}) end})
 row('conflict',{'RoomResolveConflict',E.conflictMenu})
 row('basic',{'RoomAdvanced',function() self.advanced=not self.advanced;self:updateSidebar() end})
 row('advanced',{'RoomClear',function() self.draft:set(assert(G.normalize({})));changed(self) end})
 row('advanced',{'RoomDisconnectedToggle',function() self.disconnected=not self.disconnected;self:message(self.disconnected and 'RoomDisconnectedWarning' or 'RoomPreviewOnly') end})
 row('advancedSaved',{'RoomDuplicate',function()
  if self.record and self.draft.action=='save' then local rows=self.draft.geometry.rows;local title=self.nameEntry:getInternalText();self:load({name=title,rows=rows,roomType=self.roomType,designation=self.designation});self.record=nil end
 end},{'RoomCombine',E.combine,'geometry'})
 row('footer',{'Save',function() self:submit() end},{'Done',E.requestClose})
 U.skin(self.buttons.Save,'button','primary');U.skin(self.buttons.RoomDelete,'button','destructive')
 self.buttons.RoomDesignation:setTooltip(tr('RoomDesignationHelp'))
 self.buttons.RoomPermissions:setTooltip(tr('RoomSaveBeforePolicy'));self.buttons.RoomVisitor:setTooltip(tr('RoomAccountHelp'))
 local renderSidebar=self.sidebar.prerender
 self.sidebar.prerender=function(panel)
  renderSidebar(panel)
  local width=math.max(1,panel.width-32)
  local lineHeight=math.max(22,U.Theme.metrics().font+6)
  local lines={tr('RoomEditorTitle'),tr(self.record and 'RoomEditHelp' or 'RoomCreateHelp'),
   tr(self.tool or 'RoomAddRectangle'),tr('RoomCounts',self.floor,self.draft and self.draft.geometry.count or 0),self.status or ''}
  lines[#lines+1]=tr('RoomMatchCount',self.matchCount or 0,#(self.metadata or {}))
  local f=self.filters or {};if f.roomType then lines[#lines+1]=tr('RoomType_'..f.roomType) end;if f.role then lines[#lines+1]=tr('RoomRole_'..f.role) end
  if f.floor~=nil then lines[#lines+1]=f.floor=='current' and tr('RoomCurrentFloor') or tr('RoomFloorGroup',f.floor) end
  for _,line in ipairs(self:summaryLines()) do lines[#lines+1]=line end
  if (self.invalidCount or 0)>0 then lines[#lines+1]=tr('RoomInvalidCount',self.invalidCount) end
  if self.tool=='RoomSelect' then local names={};for _,m in ipairs(self:roomsUnderCursor()) do names[#names+1]=m.label end;lines[#lines+1]=#names>0 and table.concat(names,', ') or tr('RoomSelectEmpty') end
  if self.overlayLimited then lines[#lines+1]=tr('RoomFloorOverlayLimit') end
  if self.advanced then for _,key in ipairs({'RoomPolicyBoundary','RoomWorldHelp','RoomLegend','RoomLegendOther'}) do lines[#lines+1]=tr(key) end end
  local key=table.concat(lines,'\n')..':'..width..':'..U.Theme.metrics().font
  if self.textKey~=key then
   self.textKey=key;self.textLines={}
   for _,line in ipairs(lines) do for _,piece in ipairs(wrap(line,width)) do self.textLines[#self.textLines+1]=piece end end
   panel:setScrollHeight(self.statusY+#self.textLines*lineHeight+12)
  end
  for i,line in ipairs(self.textLines) do U.Renderer.text(panel,U.Renderer.fit(line,width),12,self.statusY+(i-1)*lineHeight,U.Theme.colors.text) end
 end
 self:updateSidebar()
end

function E:update()
 if self.closed then return end
 if self.removed or not getSpecificPlayer(self.playerNum) or self.player:isDead() or self.owner and self.owner.removed then self:closeEditor();return end
 self:workflowTick()
 local retry=self.readRetry
 if retry and getTimestampMs()>=retry.at then self.readRetry=nil;retry.run() end
 if self.validationSource~=self.draft.geometry then
  self.validationSource=self.draft.geometry;self.validation={index=1};self.invalidTiles={};self.invalidCount=0
 end
 if self.validation then
  local start=getTimestampMs()
  for _=1,64 do
   if getTimestampMs()-start>=2 then break end
   local tile=self.draft.geometry.tiles[self.validation.index]
   if not tile then self.validation=nil;break end
   self.validation.index=self.validation.index+1
   if not allowed(self.player,getCell():getGridSquare(tile.x,tile.y,tile.z)) then
    self.invalidCount=self.invalidCount+1
    if #self.invalidTiles<512 then self.invalidTiles[#self.invalidTiles+1]=tile end
   end
  end
 end
 self:updateSidebar()
 if self.detection then
  local job=Detect.step(self.detection)
  if job.done then
   self.detection=nil
   if job.geometry then self.draft:set(job.geometry);changed(self) end
   self.incomplete=job.incomplete;self.candidate=true;self:message(job.incomplete or 'RoomCandidate')
  end
 end
 if self.closed then return end
 if self.fetch and #self.fetch>0 and getTimestampMs()>=(self.nextFetch or 0) and not self.fetchPending and not self.listPending and not self:isBusy() then
  local meta=table.remove(self.fetch,1);local generation=self.overlayGeneration;self.fetchPending=true;self.nextFetch=getTimestampMs()+500
  self:request('roomGet',{id=meta.id,roomRevision=meta.revision},function(r)
   if generation~=self.overlayGeneration then return end
   self.fetchPending=false;if r.status=='ok' then self.saved[meta.id]=r.room;self.edgeSource=nil end
  end)
 end
 local s=self.submission
 if s and not s.changePending and not s.pending and getTimestampMs()>=s.nextAt then
  if getTimestampMs()-s.time>30000 then self:message('RoomOutcomeUnknown');self:closeEditor();return end
  s.pending=true;s.nextAt=getTimestampMs()+500
  self:request('roomPoll',{nonce=s.args.nonce},function(r)
   s.pending=false;if self.submission~=s then return end
   if r.status=='pending' or r.status=='rateLimited' or r.status=='expired' or r.status=='uncertain' or r.status=='timeout' then return end
   if r.status=='ok' then self:saveSucceeded(s);return end
   self.submission=nil;self:message(r.status)
  end)
 end
 if self.closed then return end
 local w,h=getPlayerScreenWidth(self.playerNum),getPlayerScreenHeight(self.playerNum)
 if w~=self.width or h~=self.height then self:setWidth(w);self:setHeight(h);self.sidebar:setX(math.max(0,w-360));self.sidebar:setWidth(math.min(360,w));self.sidebar:setHeight(h);self:updateSidebar() end
end
function E:drawWorldLine(x1,y1,z1,x2,y2,z2,thickness,r,g,b,a)
 -- This panel draws in UI space. renderIsoLine targets the world buffer;
 -- native UI projections include this player's live zoom and viewport origin.
 local num=self.playerNum
 self:drawLineAbsolute(nil,isoToScreenX(num,x1,y1,z1),isoToScreenY(num,x1,y1,z1),
  isoToScreenX(num,x2,y2,z2),isoToScreenY(num,x2,y2,z2),thickness,a,r,g,b)
end
function E:prerender()
 if not self.draft then return end
 if self.edgeSource~=self.draft.geometry or self.edgeFloor~=self.floor then
  self.edgeSource=self.draft.geometry;self.edgeFloor=self.floor;self.edgeCache={}
  local function lines(g,color)
   local edges,limited=self.draft:edges(g,self.floor);self.edgeCache[#self.edgeCache+1]={edges=edges,color=color};if limited then self:message('RoomOverlayLimit') end
  end
  local added=G.edit(self.draft.geometry.rows,self.draft.original.rows,true)
  local removed=G.edit(self.draft.original.rows,self.draft.geometry.rows,true)
  lines(self.draft.geometry,self.candidate and {.3,.6,1,.9} or {1,.75,.2,.9})
  if self.draft.second then lines(self.draft.second,{.7,.35,.95,.9}) end
  if added then lines(added,{.3,.9,.4,.8}) end;if removed then lines(removed,{1,.2,.2,.8}) end
  local overlap={}
  for id,room in pairs(self.saved) do if not self.record or id~=self.record.id then
   local other=self:savedShape(id,room);lines(other,{.3,.7,.9,.45})
   for _,t in ipairs(self.draft.geometry.tiles) do if G.contains(other,t.x,t.y,t.z) then overlap[G.key(t.x,t.y,t.z)]=t end end
  end end
  local tiles={};for _,t in pairs(overlap) do tiles[#tiles+1]=t end
  local common=G.fromTiles(tiles);if common then lines(common,{.7,.3,.9,.9}) end
 end
 local budget=8192
 for _,layer in ipairs(self.edgeCache) do local c=layer.color
  for _,line in ipairs(layer.edges) do if budget<=0 then self:message('RoomOverlayLimit');break end;self:drawWorldLine(line[1],line[2],line[3],line[4],line[5],line[6],1,c[1],c[2],c[3],c[4]);budget=budget-1 end
 end
 for _,tile in ipairs(self.invalidTiles or {}) do if tile.z==self.floor then
  self:drawWorldLine(tile.x+.25,tile.y+.25,tile.z,tile.x+.75,tile.y+.75,tile.z,1,1,.2,.2,1)
  self:drawWorldLine(tile.x+.75,tile.y+.25,tile.z,tile.x+.25,tile.y+.75,tile.z,1,1,.2,.2,1)
 end end
 if self.tool=='RoomSelect' then return end
 local p=self.cursor;local c=allowed(self.player,getCell():getGridSquare(p.x,p.y,p.z)) and {1,.8,.2} or {1,.2,.2}
 local a=self.first or self.down and self.dragStart or p
 local x1,y1=math.min(a.x,p.x),math.min(a.y,p.y);local x2,y2=math.max(a.x,p.x)+1,math.max(a.y,p.y)+1
 for _,line in ipairs({{x1,y1,x2,y1},{x2,y1,x2,y2},{x2,y2,x1,y2},{x1,y2,x1,y1}}) do self:drawWorldLine(line[1],line[2],p.z,line[3],line[4],p.z,2,c[1],c[2],c[3],1) end
end
function E.open(num,owner,onClose)
 if active[num] then active[num]:closeEditor() end
 local player=getSpecificPlayer(num);if not player then return end
 local editor=ISPanelJoypad.new(E,getPlayerScreenLeft(num),getPlayerScreenTop(num),getPlayerScreenWidth(num),getPlayerScreenHeight(num))
 editor.owner=owner;editor.playerNum=num;editor.player=player;editor.floor=math.floor(player:getZ());editor.cursor={x=math.floor(player:getX()),y=math.floor(player:getY()),z=editor.floor}
 editor.saved={};editor.onClose=onClose;editor:initialise();editor:instantiate();editor:addToUIManager();editor:setWantKeyEvents(true)
 editor:bringToTop()
 editor:load();editor:startWorkflow();editor:refresh();if owner then owner:setVisible(false) end;setJoypadFocus(num,editor);active[num]=editor
 -- Designation starts empty; structural detection is an explicit preview tool.
 return editor
end
if Events then
 for _,event in ipairs({'OnDisconnect','OnMainMenuEnter'}) do if Events[event] then Events[event].Add(function() for _,e in pairs(active) do e:closeEditor() end end) end end
 if Events.OnPlayerDeath then Events.OnPlayerDeath.Add(function(player) for _,e in pairs(active) do if e.player==player then e:closeEditor() end end end) end
end
require('B47ANCEDRooms/Workflow')(E)
return E
