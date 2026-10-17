require 'B47RoomsUI/Renderer'
require 'B47RoomsUI/Appearance'
require 'B47RoomsUI/Tooltip'
require 'B47RoomsUI/RowTooltip'
require 'ISUI/ISPanel'
require 'ISUI/ISCollapsableWindowJoypad'
require 'ISUI/ISButton'
require 'ISUI/ISScrollingListBox'
require 'ISUI/ISTextEntryBox'
local U=B47RoomsUI;local T,R=U.Theme,U.Renderer
function U.kind(w)
 local name=w.Type or ''
 if w.isButton or w.onclick and w.title then return 'button' end
 if w.isCombobox or string.find(name,'Combo',1,true) then return 'dropdown' end
 if string.find(name,'Entry',1,true) then return 'input' end
 if string.find(name,'List',1,true) then return 'list' end
 if string.find(name,'Label',1,true) then return 'label' end
 return 'panel'
end
function U.skin(w,kind,role)
 if not w then return end
 if w.b47Styled then if role then w.b47Role=role end;return w end
 kind=kind or U.kind(w);w.b47Styled=true;w.b47Kind=kind;w.b47Role=role
 w.backgroundColor=T.copy(kind=='window' and T.colors.window or kind=='button' and T.colors.raised or T.colors.panel)
 w.backgroundColorMouseOver=T.copy(T.colors.hover);w.borderColor=T.copy(T.colors.border)
 w.textColor=T.copy(T.colors.text);w.textColorDisabled=T.copy(T.colors.disabled);w.font=T.fonts.body
 if kind=='window' then w.titleFont=T.fonts.title end
 if kind=='list' then w.selectionColor=T.copy(T.colors.selected) end
 U.Tooltip.attach(w,w.playerNum or w.parent and w.parent.playerNum)
 if kind=='list' and w.updateTooltip then U.RowTooltip.attach(w,w.b47TooltipPlayer) end
 if kind=='label' then
  w.r=T.colors.text.r;w.g=T.colors.text.g;w.b=T.colors.text.b
  local labelPre=w.prerender
  w.prerender=function(self,...)
   local name,translation=self.name,self.translation;local full=translation or name
   if full then self.name=R.fit(full,self:getWidth(),self.font);self.translation=nil;if self.setTooltip and (not self.tooltip or self.tooltip==self.b47FallbackTip) then self.b47FallbackTip=self.name~=full and full or nil;self:setTooltip(self.b47FallbackTip) end end
   local ok,result=pcall(labelPre,self,...);self.name,self.translation=name,translation
   if not ok then error(result) end;return result
  end
 end
 if kind=='button' and w.render then
  local render=w.render
  w.render=function(self,...)
   local full=self.title
   if full and (self.b47FullTitle~=full or self.b47TitleWidth~=self:getWidth() or self.b47TitleFont~=T.metrics().font) then
    self.b47FullTitle=full;self.b47TitleWidth=self:getWidth();self.b47TitleFont=T.metrics().font;self.b47ShortTitle=R.fit(full,self:getWidth()-18,self.font)
   end
   if full then self.title=self.b47ShortTitle;if not self.tooltip or self.tooltip==self.b47FallbackTip then self.b47FallbackTip=self.title~=full and full or nil;self:setTooltip(self.b47FallbackTip) end end
   local ok,result=pcall(render,self,...);self.title=full;if not ok then error(result) end;return result
  end
 end
 local old=w.prerender
 w.prerender=function(self,...)
  U.Appearance.prepare(self,kind)
  if old then old(self,...) end
  if self.tooltipUI and not self.tooltipUI.b47Styled then
   self.tooltipUI.b47Styled=true -- Preserve the native final tooltip frame deliberately.
  end
  if self.b47Selected then R.rect(self,0,self:getHeight()-3,self:getWidth(),3,T.colors.accent) end
  if self.b47Role=='destructive' then R.border(self,0,0,self:getWidth(),self:getHeight(),T.colors.destructive)
  elseif self.b47Role=='primary' then R.border(self,0,0,self:getWidth(),self:getHeight(),T.colors.accent) end
  R.focus(self)
 end
 return w
end
function U.skinChildren(parent)
 for _,child in pairs(parent.children or {}) do U.skin(child);if child.children then U.skinChildren(child) end end
end
local function factory(native,kind)
 return {new=function(_,...) return U.skin(native:new(...),kind) end,style=function(w,role) return U.skin(w,kind,role) end}
end
U.WindowShell=factory(ISCollapsableWindowJoypad,'window');U.Panel=factory(ISPanel,'panel');U.Button=factory(ISButton,'button');U.IconButton=factory(ISButton,'button')
U.ScrollList=factory(ISScrollingListBox,'list');U.TextInput=factory(ISTextEntryBox,'input')
U.NumberInput=factory(ISTextEntryBox,'input');U.Toggle=factory(ISButton,'button')
U.Dropdown={style=function(w) return U.skin(w,'dropdown') end}
-- Explicit layout and native anchoring must not both move the same geometry.
U.Layout={}
function U.Layout.place(w,x,y,width,height)
 if not w then return end
 if w.setAnchorsTBLR then w:setAnchorsTBLR(true,false,true,false) end
 w:setX(x);w:setY(y);w:setWidth(math.max(1,width));w:setHeight(math.max(1,height))
end
function U.Layout.scrollbar(list)
 if list and list.vscroll then
  U.Layout.place(list.vscroll,list:getWidth()-T.metrics().scrollbar,0,T.metrics().scrollbar,list:getHeight())
 end
end
U.SectionHeader={draw=function(w,label,x,y) R.text(w,label,x,y,T.colors.text,T.fonts.section) end}

U.TabBar={}
function U.TabBar.add(parent,label,callback)
 local b=U.Button:new(0,0,100,T.metrics().tab,label,parent,callback)
 b:initialise();b:instantiate();parent:addChild(b);return b
end
function U.TabBar.select(button,selected) button.b47Selected=selected==true end
U.SearchField={}
function U.SearchField.attach(owner,entry,placeholder)
 U.skin(entry,'input');entry.b47Placeholder=placeholder
 local old=entry.prerender
 entry.prerender=function(self,...)
  if old then old(self,...) end
  if self:getInternalText()=='' and not (self.isFocused and self:isFocused()) then R.text(self,R.fit(placeholder,self:getWidth()-36),6,5,T.colors.muted) end
 end
 local clear=U.IconButton:new(0,0,28,T.metrics().button,'x',owner,function()
  entry:setText('');if entry.onTextChangeFunction then entry.onTextChangeFunction(entry) end
 end)
 clear:initialise();clear:instantiate();owner:addChild(clear)
 return {entry=entry,clear=clear,layout=function(self)
  self.clear:setX(entry.x+entry:getWidth()-28);self.clear:setY(entry.y);self.clear:setHeight(entry:getHeight());self.clear:setVisible(entry:isVisible() and entry:getInternalText()~='')
 end}
end
function U.menu(menu) if menu then menu.backgroundColor=T.copy(T.colors.panel);menu.borderColor=T.copy(T.colors.border);menu.font=T.fonts.body end;return menu end
U.Focus={}
function U.Focus.visibleRows(owner,build)
 local currentRow=owner.joypadButtonsY and owner.joypadButtonsY[owner.joypadIndexY or 1]
 local current=currentRow and currentRow[owner.joypadIndex or 1]
 local insert=owner.insertNewLineOfButtons
 owner.insertNewLineOfButtons=function(self,...)
  local row={};for i=1,select('#',...) do local w=select(i,...);if w and w:isVisible() then row[#row+1]=w end end
  if #row>0 then insert(self,unpack(row)) end
 end
 local ok,err=pcall(build,owner);owner.insertNewLineOfButtons=insert
 if not ok then error(err) end
 if current and current:isVisible() then
  for y,row in ipairs(owner.joypadButtonsY or {}) do for x,w in ipairs(row) do if w==current then owner.joypadIndexY=y;owner.joypadIndex=x;return end end end
 end
end
function U.Focus.restore(playerNum,owner) setJoypadFocus(playerNum,owner and not owner.removed and not owner.closed and owner or nil) end
function U.bounds(window,playerNum)
 if not getPlayerScreenWidth then return end
 local width,height=getPlayerScreenWidth(playerNum),getPlayerScreenHeight(playerNum)
 local left,top=getPlayerScreenLeft(playerNum),getPlayerScreenTop(playerNum)
 window:setX(math.max(left,math.min(window.x,left+math.max(0,width-window:getWidth()))))
 window:setY(math.max(top,math.min(window.y,top+math.max(0,height-window:getHeight()))))
end
return U
