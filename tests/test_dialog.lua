-- Exercise the real Rooms confirmation, not the stub used by editor callbacks.
dofile(TEST_ROOT..'/fixtures/ui.lua')
dofile(TEST_ROOT..'/fixtures/world.lua')
local f=CONTAINER_FIXTURE
local windows={};local topCalls=0
local function remove(window) for i=#windows,1,-1 do if windows[i]==window then table.remove(windows,i) end end end
function ISPanelJoypad:addToUIManager() remove(self);windows[#windows+1]=self;self.removed=false end
function ISPanelJoypad:removeFromUIManager() remove(self);self.removed=true end
function ISPanelJoypad:setAlwaysOnTop(value) self.alwaysOnTop=value end
function ISPanelJoypad:bringToTop() topCalls=topCalls+1;remove(self);windows[#windows+1]=self end
function ISPanelJoypad:setCapture(value) self.capture=value end
function ISPanelJoypad:onFocus() self:bringToTop() end
function ISPanelJoypad:onJoypadDown(key)
 local row=self.joypadButtonsY[self.joypadIndexY];local child=row and row[self.joypadIndex]
 if key==Joypad.AButton and child then child:forceClick() end
end
function ISButton:setImage(value) self.image=value end
function ISButton:forceClick() self.onclick(self.target,self) end
local function top()
 for i=#windows,1,-1 do if windows[i].alwaysOnTop and windows[i].visible then return windows[i] end end
 for i=#windows,1,-1 do if windows[i].visible then return windows[i] end end
end
-- The old inherited modal is deliberately unsuitable: its constructor can add
-- native/decorated controls. Rooms must construct exactly its own two buttons.
function ISModalDialog:new() error('Rooms confirmation inherited another modal control set') end
local left,screenTop,width,height=640,360,640,360
getPlayerScreenLeft=function() return left end;getPlayerScreenTop=function() return screenTop end
getPlayerScreenWidth=function() return width end;getPlayerScreenHeight=function() return height end
local D=require 'B47RoomsUI/Dialog'
local owner=ISPanelJoypad:new(left,screenTop,width,height);owner.playerNum=1;owner:addToUIManager()
local outcomes={}
local dialog=D.confirm(1,'Discard placement?',{accept='Discard',cancel='Keep editing'},function(value) outcomes[#outcomes+1]=value end,owner)
assert(dialog and owner.b47Dialog==dialog and top()==dialog,'confirmation not above its editor')
assert(dialog.alwaysOnTop and dialog.b47Shield and dialog.b47Shield.alwaysOnTop,'missing modal UI layer')
assert(dialog.x>=left and dialog.y>=screenTop and dialog.x+dialog.width<=left+width and dialog.y+dialog.height<=screenTop+height,'dialog escaped player viewport')
local count=0
for _,child in ipairs(dialog.children) do if child.isButton or child.Type=='Button' then count=count+1;assert(not child.image and not child.iconTexture,'duplicate native icon') end end
assert(count==2 and dialog.yes.title=='Discard' and dialog.no.title=='Keep editing','confirmation controls duplicated or unlabeled')
assert(D.confirm(1,'Duplicate?',{accept='Yes',cancel='No'},function() error('replaced callback') end,owner)==dialog,'stacked duplicate confirmations')
local other=ISPanelJoypad:new(0,0,300,300);other:addToUIManager();other:bringToTop()
assert(top()==dialog,'ordinary UI window covered confirmation')
assert(dialog.b47Shield:onMouseDown(1,1) and dialog.b47Shield:onMouseUp(1,1) and dialog.b47Shield:onRightMouseDown(1,1) and dialog.b47Shield:onMouseWheel(1),'click-through shield missing')
dialog.yes:forceClick();assert(#outcomes==0,'opening click confirmed immediately')
local n=topCalls;dialog:update();assert(topCalls==n,'per-frame raise fights unrelated UI')
f.advance(300);dialog.no:forceClick()
assert(#outcomes==1 and outcomes[1]=='cancel' and not owner.b47Dialog and dialog.removed and dialog.b47Shield.removed,'cancel leaked UI or callback')
assert(getJoypadData(1).focus==owner,'focus not restored to live owner')
dialog.yes:forceClick();dialog:destroy();assert(#outcomes==1,'closed dialog callback repeated')
local accepted=D.confirm(1,'Save?',{accept='Save',cancel='Cancel'},function(v) outcomes[#outcomes+1]=v end,owner)
f.advance(300);accepted.yes:forceClick();assert(outcomes[2]=='accept')
local escape=D.confirm(1,'Discard?',{accept='Discard',cancel='Cancel'},function(v) outcomes[#outcomes+1]=v end,owner)
escape:onKeyPress(Keyboard.KEY_A);assert(#outcomes==2,'unrelated key dismissed confirmation')
escape:onKeyPress(Keyboard.KEY_ESCAPE);assert(outcomes[3]=='cancel','Escape did not cancel')
local pad=D.confirm(1,'Discard?',{accept='Discard',cancel='Cancel'},function(v) outcomes[#outcomes+1]=v end,owner)
pad:onJoypadDown(Joypad.BButton);assert(outcomes[4]=='cancel','controller B did not cancel')
local padAccept=D.confirm(1,'Save?',{accept='Save',cancel='Cancel'},function(v) outcomes[#outcomes+1]=v end,owner)
padAccept.joypadIndex=2;padAccept:onJoypadDown(Joypad.AButton);assert(#outcomes==4,'controller opening press accepted')
f.advance(300);padAccept:onJoypadDown(Joypad.AButton);assert(outcomes[5]=='accept','controller selected accept failed')
local closing=D.confirm(1,'Discard?',{accept='Discard',cancel='Cancel'},function() error('orphaned callback executed') end,owner)
owner.closed=true;D.close(owner);closing.yes:forceClick()
assert(closing.removed and closing.b47Shield.removed and not owner.b47Dialog and getJoypadData(1).focus==nil,'closed owner retained popup/focus')
owner.closed=false
local orphan=D.confirm(1,'Discard?',{accept='Discard',cancel='Cancel'},function() error('removed owner callback executed') end,owner)
owner.removed=true;orphan:update();assert(orphan.closed and orphan.removed and orphan.b47Shield.removed)
assert(D.confirm(1,'Invalid',{accept='Yes',cancel='No'},function() end,owner)==nil,'removed owner opened popup')
print('PASS OFFLINE Rooms dialogs: native-independent two-button controls, top layering, viewport shield, click guard, duplicate prevention, mouse/Escape/controller cancel, focus and owner teardown')
