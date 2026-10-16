-- Editor workflow only. Shared writes still pass through Registry authority.
local Types=require 'B47ANCEDRooms/RoomTypes'
local function tr(k,...) return getText('UI_B47Rooms_'..k,...) end
return function(E)
 local Q,U=B47ANCEDRooms,B47RoomsUI
 function E:startWorkflow()
  self.searchText='';self.filters={};self.summaryOpen=false
  self.unsubscribe=Q.API.subscribe(function(revision)
   if self.closed or type(revision)~='number' or revision~=revision or revision<0 or revision~=math.floor(revision) or revision>=2^53 then return end
   if revision<=(self.revision or -1) then return end
   self.pendingRevision=math.max(self.pendingRevision or 0,revision)
   self.liveAt=getTimestampMs()+250;self.liveDeadline=getTimestampMs()+10000
   if not self:isBusy() and self:isDirty() then self.stale=true;self:message('RoomChangesWaiting') end
  end)
 end
 function E:matches(meta,z)
  local f=self.filters or {};local floor=f.floor=='current' and self.floor or f.floor
  if floor~=nil and z~=floor then return false end
  if f.roomType and (meta.roomType or 'unassigned')~=f.roomType then return false end
  if f.role and (meta.designation or 'unassigned')~=f.role then return false end
  local query=(self.searchText or ''):lower()
  if query=='' then return true end
  local text=(meta.name or meta.label or '')..' '..tr('RoomType_'..(meta.roomType or 'unassigned'))..' '..tr('RoomRole_'..(meta.designation or 'unassigned'))
  return text:lower():find(query,1,true)~=nil
 end
 function E:filtersMenu()
  if self:isBusy() then return end
  local menu=ISContextMenu.get(self.playerNum,getMouseX(),getMouseY());self.filters=self.filters or {}
  local function group(key,title,choices,label)
   local option=menu:addOption(tr(title));local sub=ISContextMenu:getNew(menu);menu:addSubMenu(option,sub)
   local function choose(value) self.filters[key]=value;self:rebuildList();self:queueOverlays();self.layoutKey=nil end
   sub:addOption(tr('RoomAny'),self,function() choose(nil) end)
   for _,value in ipairs(choices) do local item=value;sub:addOption(label(value),self,function() choose(item) end) end
  end
  local ids={'unassigned'};for _,id in ipairs(Types.ids) do ids[#ids+1]=id end
  group('roomType','RoomTypeMenu',ids,function(id) return tr('RoomType_'..id) end)
  group('role','RoomRoleMenu',Types.roles,function(id) return tr('RoomRole_'..id) end)
  local floors={'current'};local seen={}
  for _,meta in ipairs(self.metadata or {}) do for _,z in ipairs(meta.floors or {}) do if not seen[z] then seen[z]=true;floors[#floors+1]=z end end end
  table.sort(floors,function(a,b) if a==b then return false elseif a=='current' then return true elseif b=='current' then return false end;return a<b end)
  group('floor','RoomFilterFloor',floors,function(z) return z=='current' and tr('RoomCurrentFloor') or tr('RoomFloorGroup',z) end)
  menu:addOption(tr('RoomClearFilters'),self,function()
   self.filters={};self.searchText='';self.searchEntry:setText('');self.searchPending=nil;self:rebuildList();self:queueOverlays();self.layoutKey=nil
  end)
  U.menu(menu);if self.joyfocus then setJoypadFocus(self.playerNum,menu) end
 end
 function E:reconcileDraft()
  self.stale=false;local record=self.record
  if record and record.id then
   local found;for _,meta in ipairs(self.metadata or {}) do if meta.id==record.id then found=meta;break end end
   if not found or found.revision~=record.revision then self.stale=true end
  end
  self:message(self.stale and 'RoomConflictPreserved' or 'RoomDraftPreserved');self.layoutKey=nil
 end
 function E:afterRefresh(after)
  if self.pendingRevision and self.revision>=self.pendingRevision then self.pendingRevision=nil end
  if not (after and after.id) and self:isDirty() then self:reconcileDraft();return true end
  if after and after.live then
   if self:isBusy() then self.recheckSelection=true;return true end
   if self.record and self.record.id then
    for _,meta in ipairs(self.metadata or {}) do if meta.id==self.record.id then
     self:readRoom(meta,'RoomLiveRefreshed',{visitor=self.visitorEditing,account=self.accountEntry:getInternalText()});return true
    end end
    self:load();self:message('RoomUnavailable');return true
   end
   self.stale=false;self:message('RoomLiveRefreshed');return true
  end
 end
 function E:workflowTick()
  local text=self.searchEntry:getInternalText():sub(1,96)
  if text~=self.searchObserved then self.searchObserved=text;self.searchPending=getTimestampMs()+150 end
  if self.searchPending and getTimestampMs()>=self.searchPending then
   self.searchPending=nil;self.searchText=text:match('^%s*(.-)%s*$');self:rebuildList();self:queueOverlays();self.layoutKey=nil
  end
  if self.recheckSelection and not self:isBusy() and not self.listPending and not U.Dialog.active(self) then
   self.recheckSelection=nil
   if self:isDirty() then self.stale=true;self:message('RoomChangesWaiting') else self:refresh({live=true}) end
   return
  end
  if not self.pendingRevision then return end
  if self.revision and self.pendingRevision<=self.revision then self.pendingRevision=nil;return end
  if self:isBusy() or self.listPending or self.detection or self.down or self.first or U.Dialog.active(self) then return end
  if self:isDirty() then self.stale=true;self:message('RoomChangesWaiting');return end
  if getTimestampMs()>self.liveDeadline then self.pendingRevision=nil;self.refreshFailed=true;self:message('RoomRefreshFailed');return end
  if getTimestampMs()>=(self.liveAt or 0) then self.liveAt=getTimestampMs()+1000;self:refresh({live=true}) end
 end
 function E:conflictMenu()
  if self:isBusy() then return end
  local menu=ISContextMenu.get(self.playerNum,getMouseX(),getMouseY())
  menu:addOption(tr('RoomReviewChanges'),self,function() self:refresh({live=true}) end)
  menu:addOption(tr('RoomReloadDiscard'),self,function()
   local id=self.record and self.record.id
   U.Dialog.confirm(self.playerNum,tr('RoomDiscard'),{accept=tr('Discard'),cancel=tr('Cancel')},function(result)
    if result~='accept' or self.closed then return end
    self:load();self:refresh(id and {id=id} or {live=true})
   end,self)
  end)
  local copy=menu:addOption(tr('RoomRecoverCopy'),self,function()
   U.Dialog.confirm(self.playerNum,tr('RoomRecoverCopyConfirm'),{accept=tr('RoomRecoverCopy'),cancel=tr('Cancel')},function(result)
    if result~='accept' or self.closed then return end
    local room={name=self.nameEntry:getInternalText(),rows=self.draft.geometry.rows,roomType=self.roomType,designation=self.designation}
    self:load(room);self.record=nil;self.stale=false;self:refresh({live=true})
   end,self)
  end)
  copy.notAvailable=self.draft.action~='save' or self.draft.geometry.count<1
  menu:addOption(tr('RoomKeepDraft'),self,function() end)
  U.menu(menu);if self.joyfocus then setJoypadFocus(self.playerNum,menu) end
 end
 function E:copyPermissionsMenu()
  local room=self.record
  if self:isBusy() or self:isDirty() or self.stale or not room or not room.canConfigureRoom then return end
  local menu=ISContextMenu.get(self.playerNum,getMouseX(),getMouseY())
  for _,meta in ipairs(self.metadata or {}) do if meta.id~=room.id and meta.canConfigureRoom~=false then
   local source=meta;local option=menu:addOption(meta.label);local sub=ISContextMenu:getNew(menu);menu:addSubMenu(option,sub)
   for _,visitors in ipairs({false,true}) do local include=visitors
    sub:addOption(tr(include and 'RoomCopyRulesVisitors' or 'RoomCopyRules'),self,function()
     self:previewPolicyCopy(source,include)
    end)
   end
  end end
  U.menu(menu);if self.joyfocus then setJoypadFocus(self.playerNum,menu) end
 end
 function E:previewPolicyCopy(source,include)
  if self:isBusy() or self:isDirty() or self.stale or not self.record or not self.record.canConfigureRoom then return end
  local target=self.record;self.loadingSelection=true;self.readGeneration=(self.readGeneration or 0)+1;local generation=self.readGeneration
  self:request('roomGet',{id=source.id,roomRevision=source.revision},function(result)
   if generation~=self.readGeneration or self.record~=target then return end
   self.loadingSelection=false
   if result.status~='ok' then self:message(result.status);return end
   if not result.room.canConfigureRoom then self:message('RoomDenied');return end
   self:submit('copyPolicy',{sourceId=source.id,sourceRevision=source.revision,copyVisitors=include,sourceLabel=source.label,sourceMode=result.room.policy and result.room.policy.mode or 'shared'})
  end)
 end
 function E:summaryLines()
  local room=self.record;if not room or not room.id then return {} end
  local policy=room.policy or {mode='shared',rules={},grants={}}
  local lines={tr('RoomSummaryOwner',room.assigned or room.owner or tr('RoomUnknown')),
   tr('RoomSummaryMode',tr(policy.mode=='private' and 'RoomPrivate' or 'RoomShared')),
   tr('RoomSummaryState',tr('RoomState_'..(room.policyState or 'unknown')))}
  if self.stale then lines[#lines+1]=tr('RoomSummaryStale') end
  if self.summaryOpen then
   for _,action in ipairs({'discover','inspect','withdraw','deposit','configure','clean'}) do
    local rule=policy.mode=='shared' and tr('RoomRuleShared') or tr('RoomRule_'..(policy.rules[action] or 'owner'))
    lines[#lines+1]=tr('RoomSummaryAction',tr('RoomAction_'..action),rule,tr('RoomDecision_'..(room.roomActions and room.roomActions[action] or 'unknown')))
   end
   local count=0;for _ in pairs(policy.grants) do count=count+1 end
   lines[#lines+1]=tr('RoomSummaryVisitors',count);lines[#lines+1]=tr('RoomSummaryBoundary')
  end
  return lines
 end
end
