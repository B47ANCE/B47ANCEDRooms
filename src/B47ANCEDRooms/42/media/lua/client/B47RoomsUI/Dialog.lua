require 'ISUI/ISPanelJoypad'
require 'B47RoomsUI/Controls'
local U=B47RoomsUI;local D={};U.Dialog=D
function D.decorate(dialog,playerNum,owner)
 dialog.b47AppearanceOpaque=true;dialog.playerNum=playerNum
 U.skin(dialog,'panel');U.skinChildren(dialog)
 -- Text-only owned modals use a bounded, scrollable body. Native text-entry
 -- dialogs retain their entry validation and native input-focus behavior.
 if dialog.text and not dialog.entry then
  local maxWidth=getPlayerScreenWidth and getPlayerScreenWidth(playerNum)-20 or 600
  dialog:setWidth(math.min(dialog:getWidth(),maxWidth))
  local lines={};local width=dialog:getWidth()-40
  for paragraph in string.gmatch(dialog.text..'\n','([^\n]*)\n') do
   local line=''
   for word in string.gmatch(paragraph,'%S+') do
    local candidate=line=='' and word or line..' '..word
    if line~='' and getTextManager():MeasureStringX(U.Theme.fonts.body,candidate)>width then lines[#lines+1]=line;line=word else line=candidate end
   end
   lines[#lines+1]=line
  end
  local t=U.Theme.metrics();local maxHeight=getPlayerScreenHeight and getPlayerScreenHeight(playerNum)-20 or 700
  dialog:setHeight(math.min(maxHeight,math.max(dialog:getHeight(),#lines*(t.font+6)+2*t.button+48)))
  local body=U.ScrollList:new(12,16,dialog:getWidth()-24,dialog:getHeight()-2*t.button-44)
  body:initialise();body:instantiate();body.itemheight=t.font+6;dialog:addChild(body);dialog.b47Body=body
  for _,line in ipairs(lines) do body:addItem(line,line) end
  body.doDrawItem=function(self,y,entry) U.Renderer.text(self,U.Renderer.fit(entry.text,self:getWidth()-24),4,y,U.Theme.colors.text);return y+entry.height end
  dialog.prerender=function(self)
   U.Renderer.rect(self,0,0,self:getWidth(),self:getHeight(),U.Theme.colors.panel)
   U.Renderer.border(self,0,0,self:getWidth(),self:getHeight(),U.Theme.colors.strong)
  end
  for i,button in ipairs({dialog.no or dialog.ok,dialog.yes}) do
   button:setX(dialog.yes and 12+(i-1)*(dialog:getWidth()/2) or 12);button:setY(dialog:getHeight()-t.button-12)
   button:setWidth(dialog.yes and dialog:getWidth()/2-24 or dialog:getWidth()-24);button:setHeight(t.button)
  end
 end
 U.bounds(dialog,playerNum)
 return dialog
end
function D.active(owner)
 local dialog=owner and owner.b47Dialog
 return dialog and not dialog.closed and not dialog.removed and dialog or nil
end
function D.close(owner)
 local dialog=D.active(owner);if dialog then dialog:destroy() end
end
function D.confirm(playerNum,text,labels,callback,owner)
 if owner and (owner.closed or owner.removed) then return end
 local existing=D.active(owner);if existing then existing:bringToTop();return existing end
 local left,top=getPlayerScreenLeft(playerNum),getPlayerScreenTop(playerNum)
 local width,height=getPlayerScreenWidth(playerNum),getPlayerScreenHeight(playerNum)
 -- A viewport-sized input shield sits below the confirmation in the native
 -- top layer. It never captures the mouse or changes global modal/game state.
 local shield=ISPanelJoypad:new(left,top,width,height);shield:initialise();shield:instantiate()
 shield.prerender=function() end
 for _,event in ipairs({'onMouseDown','onMouseUp','onRightMouseDown','onRightMouseUp','onMouseMove','onMouseWheel'}) do shield[event]=function() return true end end
 shield:addToUIManager();shield:setAlwaysOnTop(true)
 -- Own the two controls. Do not inherit ISModalDialog's decorated/native
 -- controls, focus shortcuts or game-speed side effects on destruction.
 local dialog=ISPanelJoypad:new(left,top,500,240);dialog:initialise();dialog:instantiate()
 dialog.text=text;dialog.b47Shield=shield;dialog.playerNum=playerNum
 if owner then owner.b47Dialog=dialog;owner.down=false;if owner.setCapture then owner:setCapture(false) end end
 local armed=getTimestampMs()+250
 local function liveOwner() return not owner or not owner.closed and not owner.removed end
 function dialog:destroy()
  if self.closed then return end
  self.closed=true;self.removed=true;self:setWantKeyEvents(false);self:setVisible(false)
  if owner and owner.b47Dialog==self then owner.b47Dialog=nil end
  U.Tooltip.dispose(self);ISPanelJoypad.removeFromUIManager(self)
  shield:setVisible(false);ISPanelJoypad.removeFromUIManager(shield)
  local restore=owner and liveOwner() and owner:isVisible() and owner or nil
  if restore then restore:bringToTop() end
  U.Focus.restore(playerNum,restore)
 end
 dialog.removeFromUIManager=dialog.destroy;shield.removeFromUIManager=function() dialog:destroy() end
 local function finish(result)
  if dialog.closed or not liveOwner() or result~='cancel' and getTimestampMs()<armed then return end
  dialog:destroy();callback(result)
 end
 local function button(title,result)
  local b=U.Button:new(0,0,100,28,title,nil,function() finish(result) end)
  b:initialise();b:instantiate();b:setImage(nil);b.iconTexture=nil;dialog:addChild(b);return b
 end
 dialog.no=button(labels.cancel,'cancel');dialog.yes=button(labels.accept,'accept')
 U.skin(dialog.yes,'button','primary');D.decorate(dialog,playerNum,owner)
 dialog:setX(left+math.max(0,(width-dialog:getWidth())/2));dialog:setY(top+math.max(0,(height-dialog:getHeight())/2))
 dialog.joypadButtonsY={};dialog.allJoypadButtons={};dialog.joypadButtons={}
 dialog:insertNewLineOfButtons(dialog.no,dialog.yes);dialog.joypadIndexY=1;dialog.joypadIndex=1
 dialog.onGainJoypadFocus=function(self,data)
  ISPanelJoypad.onGainJoypadFocus(self,data);self.joypadIndexY=1;self.joypadIndex=1;self:restoreJoypadFocus()
 end
 local joy=dialog.onJoypadDown
 dialog.onJoypadDown=function(self,key,...)
  if self.closed then return end
  if key==Joypad.BButton then finish('cancel');return end
  if getTimestampMs()<armed then return end
  return joy(self,key,...)
 end
 if labels.extra then
  local b=U.Button:new(10,dialog:getHeight()-60,dialog:getWidth()-20,24,labels.extra,dialog,function(self)
   finish('extra')
  end)
  b:initialise();b:instantiate();dialog:addChild(b);dialog:insertNewLineOfButtons(b)
 end
 if dialog.b47Body then dialog:insertNewLineOfButtons(dialog.b47Body) end
 dialog.isKeyConsumed=function() return true end
 dialog.onKeyPress=function(_,key) if key==Keyboard.KEY_ESCAPE then finish('cancel') end end
 dialog.onFocus=function(self) self:bringToTop() end;shield.onFocus=function() dialog:bringToTop() end
 dialog.update=function(self)
  if self.closed then return end
  if not liveOwner() then self:destroy();return end
  shield:setX(getPlayerScreenLeft(playerNum));shield:setY(getPlayerScreenTop(playerNum))
  shield:setWidth(getPlayerScreenWidth(playerNum));shield:setHeight(getPlayerScreenHeight(playerNum));U.bounds(self,playerNum)
 end
 dialog:addToUIManager();dialog:setAlwaysOnTop(true);dialog:bringToTop();dialog:setWantKeyEvents(true)
 setJoypadFocus(playerNum,dialog);return dialog
end
return D
