-- Explicitly active presentation/editor. Shared geometry is written only by Rooms.
require 'ISUI/ISPanelJoypad'
require 'ISUI/ISContextMenu'
require 'B47RoomsUI/Controls'
require 'B47RoomsUI/Dialog'
local Draft=require 'B47ANCEDRooms/Draft'
local Detect=require 'B47ANCEDRooms/Detection'
local G=require 'B47ANCEDRooms/Geometry'
local Q,U=B47ANCEDRooms,B47RoomsUI
local E=ISPanelJoypad:derive('B47RoomsEditor');Q.Editor=E
local active={};local sequence=0
local function tr(k,...) return getText('UI_B47Rooms_'..k,...) end
local function changed(self) self.edgeSource=nil;self.incomplete=nil;self.candidate=nil end
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
function E:message(code) self.status=tr(code or 'Ready') end
function E:load(room)
 self.readGeneration=(self.readGeneration or 0)+1
 self.record=room;self.draft=Draft.new(room);self.nameEntry:setText(room and room.name or tr('RoomDefaultName'))
 self.accountEntry:setText('')
 self.secondName:setText(tr('RoomSecondName'));self.first=nil;self.detection=nil;self.incomplete=nil;self.mergeIDs=nil
 self.startName=self.nameEntry:getInternalText();self.conflict=nil
 self.tool='RoomAddRectangle';changed(self);self:message('RoomPreviewOnly')
end
function E:select(meta)
 local function perform()
  if not meta then self:load();return end
  self.readGeneration=(self.readGeneration or 0)+1;local generation=self.readGeneration
  self:request('roomGet',{id=meta.id,roomRevision=meta.revision},function(r)
   if generation~=self.readGeneration then return end
   if r.status=='ok' then self.saved[meta.id]=r.room;self:load(r.room) else self:message(r.status) end
  end)
 end
 if self.draft and (#self.draft.history>0 or self.nameEntry:getInternalText()~=self.startName) then U.Dialog.confirm(self.playerNum,tr('RoomDiscard'),{accept=tr('Discard'),cancel=tr('Cancel')},function(result) if result=='accept' and not self.closed then perform() end end,self)
 else perform() end
end
function E:refresh()
 self.refreshGeneration=(self.refreshGeneration or 0)+1;local generation=self.refreshGeneration
 self.fetchPending=false;self.fetch={}
 self:request('roomList',{},function(r)
  if generation~=self.refreshGeneration then return end
  if r.status~='ok' then self:message(r.status);return end
  self.revision=r.revision;self.editKey=r.editKey;self.options=r.options;self.metadata=r.rooms;self.list:clear()
  self.saved={};self.edgeSource=nil
  for _,room in ipairs(r.rooms) do self.list:addItem(room.label,room) end
  -- Fetch overlays only while this editor is open; bounded admission/payloads.
  self.overlayLimited=#r.rooms>8
  self.fetch={};for _,m in ipairs(r.rooms) do if #self.fetch<8 then self.fetch[#self.fetch+1]=m end end
  self:message(self.conflict or 'RoomPreviewOnly')
 end)
end
function E:saveSucceeded(submission)
 if self.submission~=submission then return end
 self.submission=nil
 if Q.onRoomsChanged then Q.onRoomsChanged() end
 if self.closed then return end
 -- A completed write starts the next designation, without ending this editor
 -- session or restoring the hidden parent. Wait for a fresh lease before saving.
 self.revision=nil;self.editKey=nil;self.down=false;self.dragStart=nil;self.lastPaint=nil
 self:setCapture(false);self.disconnected=false
 self:load();self:refresh()
end
function E:detect()
 if self.draft and self.draft.action~='save' then self:message('RoomFinishCompound');return end
 local p=self.cursor;local sq=getCell():getGridSquare(p.x,p.y,p.z)
 local job,e=Detect.start(sq,self.options and self.options.maxTiles or 1024,self.options and self.options.doorways)
 if not job then self:message(e);return end
 self.detection=job;self:message('RoomDetecting')
end
function E:tools()
 local menu=ISContextMenu.get(self.playerNum,getMouseX(),getMouseY())
 for _,key in ipairs({'RoomAddRectangle','RoomRemoveRectangle','RoomPaint','RoomErase','RoomSplit'}) do
  local tool=key;local option=menu:addOption(tr(key),self,function() self.tool=tool;self.first=nil;self.worldFocus=true;setJoypadFocus(self.playerNum,self);self:message('RoomWorldHelp') end)
  option.notAvailable=self.draft.action~='save' or key=='RoomSplit' and not (self.record and self.record.id)
 end
 U.menu(menu);if self.joyfocus then setJoypadFocus(self.playerNum,menu) end
end
function E:combine()
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
 local region,e=G.rectangle(a,b);if not region then self:message(e);return end
 local ok
 if self.tool=='RoomSplit' then ok,e=self.draft:split(region.rows)
 else ok,e=self.draft:edit(region.rows,self.tool=='RoomRemoveRectangle' or self.tool=='RoomErase') end
 if ok then self.detection=nil;changed(self);self:message('RoomPreviewOnly') else self:message(e) end
end
function E:point()
 if not self.worldFocus then return end
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
 if x>=self.sidebar.x then return true end
 self.worldFocus=true;self.cursor=self:mouseTile();self.down=true;self.dragStart=self.cursor;self.lastPaint=nil
 if self.tool=='RoomPaint' or self.tool=='RoomErase' then self:point() end
 self:setCapture(true);return true
end
function E:onMouseMove(dx,dy)
 if U.Dialog.active(self) then return true end
 self.cursor=self:mouseTile()
 if not self.down then return true end
 local key=G.key(self.cursor.x,self.cursor.y,self.cursor.z)
 if (self.tool=='RoomPaint' or self.tool=='RoomErase') and key~=self.lastPaint then self.lastPaint=key;self:point() end
 return true
end
function E:onMouseUp(x,y)
 if U.Dialog.active(self) then return true end
 if self.down then
  self.cursor=self:mouseTile();self.down=false;self:setCapture(false)
  if self.tool~='RoomPaint' and self.tool~='RoomErase' then
   if self.dragStart.x~=self.cursor.x or self.dragStart.y~=self.cursor.y then self:apply(self.dragStart,self.cursor);self.first=nil else self:point() end
  end
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
 if key==Keyboard.KEY_ESCAPE then self:closeEditor()
 elseif self.nameEntry:isFocused() or self.secondName:isFocused() or self.accountEntry:isFocused() then return
 elseif isCtrlKeyDown() and key==Keyboard.KEY_Z then if isShiftKeyDown() then self.draft:redo() else self.draft:undo() end;changed(self)
 elseif isCtrlKeyDown() and key==Keyboard.KEY_Y then self.draft:redo();changed(self) end
end
function E:onJoypadDown(key,data)
 if U.Dialog.active(self) then return end
 if key==Joypad.BButton then
  if self.worldFocus then self.first=nil;self.worldFocus=false;self:restoreJoypadFocus() else self:closeEditor() end;return
 end
 if self.worldFocus then if key==Joypad.AButton then self:point() elseif key==Joypad.YButton then self.worldFocus=false;self:restoreJoypadFocus() end;return end
 ISPanelJoypad.onJoypadDown(self,key,data)
end
for method,d in pairs({onJoypadDirUp={0,-1},onJoypadDirDown={0,1},onJoypadDirLeft={-1,0},onJoypadDirRight={1,0}}) do
 local delta=d;E[method]=function(self,data)
  if U.Dialog.active(self) then return end
  if self.worldFocus then self.cursor.x=self.cursor.x+delta[1];self.cursor.y=self.cursor.y+delta[2]
  else ISPanelJoypad[method](self,data) end
 end
end
function E:permissions()
 local room=self.record;if not room or not room.id then self:message('RoomSelectSaved');return end
 if #self.draft.history>0 or self.nameEntry:getInternalText()~=self.startName then self:message('RoomSaveBeforePolicy');return end
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
 local who=self.accountEntry:getInternalText():match('^%s*(.-)%s*$')
 local visitor=menu:addOption(tr('RoomVisitor'));visitor.notAvailable=who=='' or not room.assigned
 local sub=ISContextMenu:getNew(menu);menu:addSubMenu(visitor,sub)
  for _,action in ipairs({'discover','inspect','withdraw','deposit','configure','clean'}) do local which=action
  for _,allow in ipairs({true,false}) do local granted=allow
   sub:addOption(tr(granted and 'RoomGrant' or 'RoomDeny',tr('RoomAction_'..which)),self,function()
    local p=Q.Identity.copy(room.policy or {mode='private',rules={},grants={}});p.mode='private';p.grants[who]=p.grants[who] or {};p.grants[who][which]=granted;self:submit('policy',{policy=p})
   end)
  end
 end
 if room.pendingBoundary and room.canEditGeometry then
  menu:addOption(tr('RoomApproveBoundary'),self,function() self:submit('approveBoundary') end)
  menu:addOption(tr('RoomRejectBoundary'),self,function() self:submit('rejectBoundary') end)
 end
 U.menu(menu);if self.joyfocus then setJoypadFocus(self.playerNum,menu) end
end
function E:submit(action,extra)
 if self.submission or self.revision==nil then return end
 local draft=self.draft;local record=self.record;local count=draft.geometry.count
 if action~='delete' and count==0 then self:message('RoomGeometryInvalid');return end
 local function confirm(result)
  if self.closed or result~='accept' then return end
  sequence=sequence+1;local nonce=tostring(getTimestampMs())..':'..sequence
  local args={action=action or draft.action,nonce=nonce,editKey=self.editKey,revision=self.revision,id=record and record.id,roomRevision=record and record.revision,
   name=self.nameEntry:getInternalText(),rows=draft.geometry.rows,disconnected=self.disconnected,confirm=true,
   ids=draft.ids,secondName=self.secondName:getInternalText(),secondRows=draft.second and draft.second.rows}
  for k,v in pairs(extra or {}) do args[k]=v end
  local submission={args=args,nextAt=0,time=getTimestampMs(),changePending=true};self.submission=submission;self:message('RoomSaving')
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
 U.Dialog.confirm(self.playerNum,text,{accept=tr('Save'),cancel=tr('Cancel')},confirm,self)
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
 self.closed=true;U.Dialog.close(self);self.detection=nil;self.down=false;self.first=nil;self.submission=nil;self.saved={};self.edgeCache={}
 self:setCapture(false);self:setWantKeyEvents(false);active[self.playerNum]=nil
 ISPanelJoypad.removeFromUIManager(self)
 if owner and not owner.removed then owner:setVisible(true) end
 U.Focus.restore(self.playerNum,owner)
 self.draft=nil;self.fetch=nil;self.metadata=nil;self.record=nil;self.owner=nil;self.player=nil;self.onClose=nil
 self.edgeSource=nil;self.validation=nil;self.validationSource=nil;self.invalidTiles=nil;self.textLines=nil
 if onClose then onClose() end
end
function E:removeFromUIManager() self:closeEditor() end
function E:createChildren()
 self.sidebar=ISPanelJoypad:new(math.max(0,self.width-360),0,math.min(360,self.width),self.height)
 self.sidebar:initialise();self:addChild(self.sidebar);U.skin(self.sidebar,'panel')
 self.sidebar:setScrollChildren(true);self.sidebar:addScrollBars()
 local width=self.sidebar.width-32;local y=12;local h=U.Theme.metrics().button
 local function add(widget)
  widget:initialise();widget:instantiate();self.sidebar:addChild(widget);return widget
 end
 self.list=add(U.ScrollList:new(12,y,width,96));self.list.itemheight=24;y=y+104
 self.list:setOnMouseDownFunction(self,function(editor,room) editor:select(room) end)
 self.list:setOverrideAButtonFunction(self,function(editor) local e=editor.list.items[editor.list.selected];if e then editor:select(e.item) end end)
 self.nameEntry=add(U.TextInput:new('',12,y,width,h));self.nameEntry:setMaxTextLength(96);y=y+h+4
 self.secondName=add(U.TextInput:new(tr('RoomSecondName'),12,y,width,h));self.secondName:setMaxTextLength(96);self.secondName:setVisible(false);y=y+h+4
 self.accountEntry=add(U.TextInput:new('',12,y,width,h));self.accountEntry:setMaxTextLength(256);self.accountEntry:setTooltip(tr('RoomAccountHelp'));y=y+h+4
 self.buttons={};self.buttonRows={};self.joypadButtonsY={};self.allJoypadButtons={};self.joypadButtons={}
 self:insertNewLineOfButtons(self.list);self:insertNewLineOfButtons(self.nameEntry);self:insertNewLineOfButtons(self.secondName);self:insertNewLineOfButtons(self.accountEntry)
 local function row(left,right)
  local controls={}
  for i,spec in ipairs({left,right}) do
   local w=right and (width-4)/2 or width
   local b=add(U.Button:new(12+(i-1)*(w+4),y,w,h,tr(spec[1]),self,spec[2]));self.buttons[spec[1]]=b;controls[#controls+1]=b
  end
  self.buttonRows[#self.buttonRows+1]=controls;self:insertNewLineOfButtons(unpack(controls));y=y+h+4
 end
 row({'RoomCreate',function() self:select(nil) end},{'RoomTools',E.tools})
 row({'RoomRedetect',E.detect})
 row({'RoomUndo',function() self.draft:undo();changed(self) end},{'RoomRedo',function() self.draft:redo();changed(self) end})
 row({'RoomPermissions',E.permissions})
 row({'RoomClear',function() self.draft:set(assert(G.normalize({})));changed(self) end},{'RoomCombine',E.combine})
 row({'RoomDuplicate',function() if self.record and self.draft.action=='save' then local rows=self.draft.geometry.rows;local title=self.nameEntry:getInternalText();self:load({name=title,rows=rows});self.record=nil end end},
  {'RoomDelete',function() if self.record then self:submit('delete') end end})
 row({'RoomFloorDown',function() self.floor=math.max(-32,self.floor-1);self.cursor.z=self.floor;self.first=nil;self.edgeSource=nil end},
  {'RoomFloorUp',function() self.floor=math.min(31,self.floor+1);self.cursor.z=self.floor;self.first=nil;self.edgeSource=nil end})
 row({'RoomDisconnectedToggle',function() self.disconnected=not self.disconnected;self:message(self.disconnected and 'RoomDisconnectedWarning' or 'RoomPreviewOnly') end})
 row({'Save',function() self:submit() end},{'Cancel',E.closeEditor})
 self.statusY=y+8;self.sidebar:setScrollHeight(y+200)
 local old=self.sidebar.prerender
 self.sidebar.prerender=function(panel)
  old(panel);local c=U.Theme.colors.text
  local lines={tr('RoomEditorTitle'),tr('RoomDesignationHelp'),tr('RoomPolicyBoundary'),tr(self.tool or 'RoomAddRectangle'),tr('RoomCounts',self.floor,self.draft and self.draft.geometry.count or 0),tr('RoomInvalidCount',self.invalidCount or 0),self.status or '',self.overlayLimited and tr('RoomOverlayLimit') or '',tr('RoomWorldHelp'),tr('RoomLegend'),tr('RoomLegendOther')}
  local key=table.concat(lines,'\n')..':'..width..':'..U.Theme.metrics().font
  if self.textKey~=key then
   self.textKey=key;self.textLines={}
   for _,line in ipairs(lines) do for _,piece in ipairs(wrap(line,width)) do self.textLines[#self.textLines+1]=piece end end
   panel:setScrollHeight(self.statusY+#self.textLines*22+12)
  end
  for i,line in ipairs(self.textLines) do U.Renderer.text(panel,U.Renderer.fit(line,width),12,self.statusY+(i-1)*22,c) end
 end
 self.joypadIndex=1;self.joypadIndexY=1
end
function E:update()
 if self.closed then return end
 if self.removed or not getSpecificPlayer(self.playerNum) or self.player:isDead() or self.owner and self.owner.removed then self:closeEditor();return end
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
 self.buttons.RoomDisconnectedToggle:setTitle(tr(self.disconnected and 'RoomDisconnectedOn' or 'RoomDisconnectedOff'))
 self.buttons.RoomPermissions:setEnable(self.record and self.record.id~=nil or false)
 if self.focusAction~=self.draft.action then
  self.focusAction=self.draft.action;self.secondName:setVisible(self.draft.action=='split')
  U.Focus.visibleRows(self,function(panel)
   panel.joypadButtonsY={};panel.allJoypadButtons={};panel.joypadButtons={}
   panel:insertNewLineOfButtons(panel.list);panel:insertNewLineOfButtons(panel.nameEntry);panel:insertNewLineOfButtons(panel.secondName);panel:insertNewLineOfButtons(panel.accountEntry)
   for _,row in ipairs(panel.buttonRows) do panel:insertNewLineOfButtons(unpack(row)) end
  end)
 end
 if self.detection then
  local job=Detect.step(self.detection)
  if job.done then
   self.detection=nil
   if job.geometry then self.draft:set(job.geometry);changed(self) end
   self.incomplete=job.incomplete;self.candidate=true;self:message(job.incomplete or 'RoomCandidate')
  end
 end
 if self.closed then return end
 if self.fetch and #self.fetch>0 and getTimestampMs()>=(self.nextFetch or 0) and not self.fetchPending then
  local meta=table.remove(self.fetch,1);local generation=self.refreshGeneration;self.fetchPending=true;self.nextFetch=getTimestampMs()+500
  self:request('roomGet',{id=meta.id,roomRevision=meta.revision},function(r)
   if generation~=self.refreshGeneration then return end
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
 if w~=self.width or h~=self.height then self:setWidth(w);self:setHeight(h);self.sidebar:setX(math.max(0,w-360));self.sidebar:setHeight(h) end
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
   local other=assert(G.normalize(room.rows));lines(other,{.3,.7,.9,.45})
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
 editor:load();editor:refresh();if owner then owner:setVisible(false) end;setJoypadFocus(num,editor);active[num]=editor
 -- Designation starts empty; structural detection is an explicit preview tool.
 return editor
end
if Events then
 for _,event in ipairs({'OnDisconnect','OnMainMenuEnter'}) do if Events[event] then Events[event].Add(function() for _,e in pairs(active) do e:closeEditor() end end) end end
 if Events.OnPlayerDeath then Events.OnPlayerDeath.Add(function(player) for _,e in pairs(active) do if e.player==player then e:closeEditor() end end end) end
end
return E
