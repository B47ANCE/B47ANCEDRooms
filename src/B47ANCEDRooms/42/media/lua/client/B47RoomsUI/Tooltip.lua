-- Local presentation only. Native hit tests and context focus remain authoritative for visibility.
require 'B47RoomsUI/Renderer'
local U=B47RoomsUI;local H={};U.Tooltip=H
function H.plain(text) return tostring(text or ''):gsub('[<>]',''):gsub('[\r\t]',' ') end
function H.wrap(text,width,font)
 local lines={};local current=''
 for char in H.plain(text):gmatch('.[\128-\191]*') do
  if current~='' and getTextManager():MeasureStringX(font,current..char)>width then lines[#lines+1]=current;current=char else current=current..char end
 end
 lines[#lines+1]=current;return lines
end
function H.hide(w)
 local tip=w and w.tooltipUI
 if tip then tip:setVisible(false);tip:removeFromUIManager() end
end
function H.dispose(w)
 H.hide(w);for _,child in pairs(w.children or {}) do H.dispose(child) end
end
local function bounds(p)
 p=p or 0
 return getPlayerScreenLeft and getPlayerScreenLeft(p) or 0,getPlayerScreenTop and getPlayerScreenTop(p) or 0,
 getPlayerScreenWidth and getPlayerScreenWidth(p) or 640,getPlayerScreenHeight and getPlayerScreenHeight(p) or 480
end
local function clamp(tip,p)
 local x,y,w,h=bounds(p);local tx=tip.getX and tip:getX() or tip.x or x;local ty=tip.getY and tip:getY() or tip.y or y
 tip:setDesiredPosition(math.max(x,math.min(tx,x+w-tip:getWidth())),math.max(y,math.min(ty,y+h-tip:getHeight())))
end
function H.prepare(tip,text,p)
 if not tip or not tip.doLayout or not ISToolTip or not ISToolTip.GetFont then return end
 local _,_,vw,vh=bounds(p);local font=ISToolTip.GetFont();local fh=getTextManager():getFontHeight(font)
 local width=math.max(1,math.min(360,vw-40));local count=math.max(1,math.min(8,math.floor((vh-40)/(fh+4))))
 local lines={};text=tostring(text or ''):gsub('<LINE>','\n')
 local truncated=false
 for line in (text..'\n'):gmatch('(.-)\n') do
  for _,part in ipairs(H.wrap(line,width,font)) do if #lines>=count then truncated=true;break end;lines[#lines+1]=part end
  if truncated then break end
 end
 if truncated then lines[#lines]=U.Renderer.fit(lines[#lines]..' ...',width,font) end
 tip.description=table.concat(lines,' <LINE> ');tip.defaultMyWidth=0;tip.maxLineWidth=width/(fh/15);tip.backgroundColor.a=0
 tip:doLayout()
 while #lines>1 and tip:getHeight()>vh-8 do table.remove(lines);tip.description=table.concat(lines,' <LINE> ');tip:doLayout() end
 tip.followMouse=false
 clamp(tip,p)
 if not tip.b47Bounded then
  tip.b47Bounded=true;tip.b47Player=p
  local setX,setY=tip.setX,tip.setY
  if setX and setY then
   tip.setX=function(self,value) local x,_,w=bounds(self.b47Player);return setX(self,math.max(x,math.min(value,x+w-self:getWidth()))) end
   tip.setY=function(self,value) local _,y,_,h=bounds(self.b47Player);return setY(self,math.max(y,math.min(value,y+h-self:getHeight()))) end
  end
  local avoid=tip.adjustPositionToAvoidOverlap
  if avoid then tip.adjustPositionToAvoidOverlap=function(self,rect) avoid(self,rect);local x,y,w,h=bounds(self.b47Player);self:setX(math.max(x,math.min(self:getX(),x+w-self:getWidth())));self:setY(math.max(y,math.min(self:getY(),y+h-self:getHeight()))) end end
 end
 tip.b47Player=p
end
function H.attach(w,p)
 if w.b47TooltipManaged then return end;w.b47TooltipManaged=true;w.b47TooltipPlayer=p or w.playerNum or 0
 local visible=w.setVisible
 if visible then w.setVisible=function(self,value) if not value then H.dispose(self) end;return visible(self,value) end end
 local remove=w.removeFromUIManager
 if remove then w.removeFromUIManager=function(self,...) H.dispose(self);return remove(self,...) end end
 local pre=w.prerender
 w.prerender=function(self,...)
  if self.isReallyVisible and not self:isReallyVisible() then H.hide(self);return end
  local owner=self;while owner do if owner.playerNum~=nil then self.b47TooltipPlayer=owner.playerNum;break end;if owner.player and owner.player.getPlayerNum then self.b47TooltipPlayer=owner.player:getPlayerNum();break end;owner=owner.parent end
  if pre then pre(self,...) end
  if self.tooltipUI and self.tooltipUI:getIsVisible() then H.prepare(self.tooltipUI,self.tooltip or self.tooltipUI.description,self.b47TooltipPlayer) end
 end
 local render=w.render
 if render then w.render=function(self,...) local result=render(self,...);if self.tooltipUI and self.tooltipUI:getIsVisible() then H.prepare(self.tooltipUI,self.tooltip or self.tooltipUI.description,self.b47TooltipPlayer) end;return result end end
end
function H.inspect(playerNum,text,owner)
 require 'ISUI/ISPanelJoypad';require 'ISUI/ISScrollingListBox';require 'ISUI/ISButton'
 local _,_,vw,vh=bounds(playerNum);local left,top=bounds(playerNum);local width,height=math.min(520,vw-20),math.min(480,vh-20)
 local panel=ISPanelJoypad:new(left+10,top+10,width,height);panel.playerNum=playerNum;panel.b47AppearanceOpaque=true;panel:initialise();panel:instantiate();U.skin(panel,'window')
 local list=ISScrollingListBox:new(10,10,width-20,height-60);list:initialise();list:instantiate();panel:addChild(list);U.skin(list,'list')
 local font=U.Theme.fonts.body;local fh=getTextManager():getFontHeight(font);local maxWidth=width-56
 for line in (tostring(text or ''):gsub('<LINE>','\n')..'\n'):gmatch('(.-)\n') do
  local wrapped=H.wrap(line,maxWidth,font);local row=list:addItem(line,wrapped);row.height=#wrapped*fh+8
 end
 list.doDrawItem=function(self,y,row) if y+self:getYScroll()+row.height<=0 or y+self:getYScroll()>=self:getHeight() then return y+row.height end;for i,line in ipairs(row.item) do self:drawText(line,8,y+4+(i-1)*fh,1,1,1,1,font) end;return y+row.height end
 local total=0;for _,row in ipairs(list.items) do total=total+row.height end;list:setScrollHeight(total)
 local function close() panel:removeFromUIManager();U.Focus.restore(playerNum,owner and (not owner.isReallyVisible or owner:isReallyVisible()) and owner or nil) end
 local button=U.Button:new(10,height-40,width-20,28,getText('UI_B47Rooms_Close'),nil,close);button:initialise();button:instantiate();panel:addChild(button)
 panel.joypadButtonsY={};panel.allJoypadButtons={};panel.joypadButtons={}
 panel:insertNewLineOfButtons(list);panel:insertNewLineOfButtons(button)
 local joy=panel.onJoypadDown;panel.onJoypadDown=function(self,key,...) if key==Joypad.BButton then close() elseif joy then joy(self,key,...) end end
 panel:addToUIManager();setJoypadFocus(playerNum,panel);return panel
end
function H.context(option,text,p,menu)
 if not ISToolTip or not ISToolTip.new then return end
 local tip=ISToolTip:new();tip:initialise();tip:setVisible(false);tip.contextMenu=menu;tip.description=text;tip.backgroundColor.a=0
 local render=tip.render
 tip.render=function(self,...) H.prepare(self,text,p);return render(self,...) end
 option.toolTip=tip;return tip
end
function H.set(w,text) w:setTooltip(text);return w end
return H
