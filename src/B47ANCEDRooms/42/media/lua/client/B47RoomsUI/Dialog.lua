require 'ISUI/ISModalDialog'
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
 local destroy=dialog.destroy
 dialog.destroy=function(self,...)
  if destroy then destroy(self,...) end
  U.Focus.restore(playerNum,owner)
 end
 return dialog
end
function D.confirm(playerNum,text,labels,callback,owner)
 local dialog=ISModalDialog:new(0,0,500,240,text,true,nil,function(_,button) callback(button.internal=='YES' and 'accept' or 'cancel') end,playerNum)
 dialog:initialise();dialog:addToUIManager();D.decorate(dialog,playerNum,owner)
 local armed=getTimestampMs()+250
 dialog.yes:setTitle(labels.accept);dialog.no:setTitle(labels.cancel)
 U.skin(dialog.yes,'button','primary');U.skin(dialog.no,'button')
 dialog.joypadButtonsY={};dialog.allJoypadButtons={};dialog.joypadButtons={}
 dialog:insertNewLineOfButtons(dialog.no,dialog.yes);dialog.joypadIndexY=1;dialog.joypadIndex=1
 dialog.onGainJoypadFocus=function(self,data)
  ISPanelJoypad.onGainJoypadFocus(self,data);self.joypadIndexY=1;self.joypadIndex=1;self:restoreJoypadFocus()
 end
 local click=dialog.yes.onclick;dialog.yes.onclick=function(...) if getTimestampMs()>=armed then click(...) end end
 local joy=dialog.onJoypadDown
 dialog.onJoypadDown=function(self,key,...)
  if getTimestampMs()<armed then return end
  if key==Joypad.BButton then self.no:forceClick();return end
  return joy(self,key,...)
 end
 if labels.extra then
  local b=U.Button:new(10,dialog:getHeight()-60,dialog:getWidth()-20,24,labels.extra,dialog,function(self)
   if getTimestampMs()<armed then return end;self:destroy();callback('extra')
  end)
  b:initialise();b:instantiate();dialog:addChild(b);dialog:insertNewLineOfButtons(b)
 end
 if dialog.b47Body then dialog:insertNewLineOfButtons(dialog.b47Body) end
 setJoypadFocus(playerNum,dialog);return dialog
end
return D
