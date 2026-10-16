-- Execute the owned standalone Picker against a minimal host ISUI surface.
-- This tests callback binding/delegation, not native rendering or networking.
local Widget = {}
Widget.__index = Widget
function Widget:derive(name)
    local c = { Type = name }; c.__index = c
    return setmetatable(c, {__index=self})
end
function Widget:new(x,y,w,h)
    return setmetatable({x=x,y=y,width=w,height=h,children={},items={},itemheight=22,
        selected=1,count=0,scroll=0,scrollHeight=0,visible=true,
        backgroundColor={r=0,g=0,b=0,a=1},vscroll={x=-6,width=17,height=10,
            setAnchorsTBLR=function(s,t,b,l,r) s.anchorTop,s.anchorBottom,s.anchorLeft,s.anchorRight=t,b,l,r end,
            getWidth=function(s) return s.width end, getHeight=function(s) return s.height end,
            setX=function(s,v) s.x=v end, setY=function(s,v) s.y=v end,
            setHeight=function(s,v) s.height=v end,setWidth=function(s,v) s.width=v end}}, self)
end
function Widget:initialise() end
function Widget:isVisible() return self.visible end
function Widget:isFocused() return self.focused or false end
function Widget:setWantKeyEvents(on) self.wantKeyEvents=on end
function Widget:bringToTop() self.raised=(self.raised or 0)+1 end
function Widget:onFocus() self:bringToTop() end
function Widget:removeChild(child)
    for i,v in ipairs(self.children) do if v==child then table.remove(self.children,i); break end end
end
function Widget:instantiate() end
function Widget:addChild(child) self.children[#self.children+1]=child; child.parent=self end
function Widget:addToUIManager() if not self.created and self.createChildren then self.created=true; self:createChildren() end end
function Widget:removeFromUIManager() self.removed=true end
function Widget:createChildren() end
function Widget:prerender() end
function Widget:close() self.closed=true end
function Widget:getWidth() return self.width end
function Widget:getHeight() return self.height end
function Widget:setAnchorsTBLR(t,b,l,r) self.anchorTop,self.anchorBottom,self.anchorLeft,self.anchorRight=t,b,l,r end
function Widget:setWidth(v) self.width=v end
function Widget:setHeight(v) self.height=v end
function Widget:setX(v) self.x=v end
function Widget:setY(v) self.y=v end
function Widget:getAbsoluteX() return self.x end
function Widget:getAbsoluteY() return self.y end
function Widget:titleBarHeight() return 20 end
function Widget:setVisible(v) self.visible=v end
function Widget:setTitle(v) self.title=v end
function Widget:setEnable(v) self.enable=v end
function Widget:setTooltip(v) self.tooltip=v end
function Widget:setText(v) self.text=v end
function Widget:getInternalText() return self.text or '' end
function Widget:setMaxTextLength(v) end
function Widget:setEditable(v) self.editable=v end
function Widget:focus() self.focused=true end
function Widget:unfocus() self.focused=false end
function Widget:clear() self.items={}; self.count=0; self.selected=1 end
function Widget:addItem(text,data)
    local row={text=text,item=data,height=self.itemheight,index=#self.items+1}
    table.insert(self.items,row); self.count=#self.items
    self.scrollHeight=self.scrollHeight+self.itemheight
    return row
end
function Widget:getYScroll() return self.scroll end
function Widget:setYScroll(v) self.scroll=v end
function Widget:getScrollHeight() return self.scrollHeight end
function Widget:setScrollHeight(v) self.scrollHeight=v end
function Widget:isVScrollBarVisible() return self.scrollHeight>self.height end
function Widget:rowAt(x,y) local n=math.floor(y/self.itemheight)+1; return self.items[n] and n or -1 end
function Widget:onMouseDown(x,y)
    self.selected=self:rowAt(x,y)
    if self.items[self.selected] then self.onmousedown(self.target,self.items[self.selected].item) end
end
function Widget:prevVisibleIndex(n) return math.max(1,n-1) end
function Widget:nextVisibleIndex(n) return math.min(#self.items,n+1) end
function Widget:ensureVisible(n) end
function Widget:isMouseOver() return false end
function Widget:drawRect(...) end
function Widget:drawRectBorder(...) end
function Widget:drawTextureScaled(...) end
function Widget:drawText(...) end
function Widget:drawTextRight(...) end
function Widget:clearISButtons() end
function Widget:clearJoypadFocus() end
function Widget:restoreJoypadFocus() end
function Widget:getMinVisibleRow() return 1 end
function Widget:insertNewLineOfButtons(...)
    local row={...}; self.joypadButtonsY[#self.joypadButtonsY+1]=row
    for _,button in ipairs(row) do table.insert(self.allJoypadButtons,button) end
end
function Widget:onJoypadDown() end
function Widget:onGainJoypadFocus() end
ISCollapsableWindow=Widget:derive('Window')
ISCollapsableWindowJoypad=ISCollapsableWindow:derive('JoypadWindow')
ISPanelJoypad=Widget:derive('PanelJoypad')
ISPanel=Widget:derive('Panel')
ISScrollingListBox=Widget:derive('List')
ISButton=Widget:derive('Button')
function ISButton:new(x,y,w,h,title,target,onclick)
    local b=Widget.new(self,x,y,w,h); b.title,b.target,b.onclick=title,target,onclick; return b
end
ISTextEntryBox=Widget:derive('Entry')
function ISTextEntryBox:new(text,x,y,w,h)
    local b=Widget.new(self,x,y,w,h); b.text=text; return b
end
ISLabel=Widget:derive('Label')
ISComboBox=Widget:derive('ComboBox')
function ISComboBox:clear() self.options={};self.selected=1 end
function ISComboBox:addOption(text) self.options=self.options or {};self.options[#self.options+1]=text end
ISTextBox=Widget:derive('TextBox')
ISModalDialog=Widget:derive('Modal')
ISContextMenu={}
local lastMenu
function ISContextMenu.get(player)
    local menu={options={},player=player or 0}
    function menu:addOption(name,target,callback,...)
        local o={name=name,target=target,callback=callback,args={...}}
        self.options[#self.options+1]=o; return o
    end
    function menu:addSubMenu(option,sub) option.sub=sub end
    lastMenu=menu; return menu
end
function ISContextMenu:getNew(parent)
    -- B42.21 colon method requires a distinct parentContext argument.
    assert(type(parent)=='table' and parent.player~=nil,'native getNew requires parentContext')
    local menu=ISContextMenu.get(parent.player);menu.parent=parent;return menu
end
for _,name in ipairs({'ISCollapsableWindow','ISCollapsableWindowJoypad','ISPanel','ISScrollingListBox',
    'ISTextEntryBox','ISTextBox','ISModalDialog','ISContextMenu','ISButton','ISLabel','ISComboBox','ISPanelJoypad'}) do
    package.loaded['ISUI/'..name]=true
end
UIFont={Small=1,Medium=2}
Joypad={AButton=1,BButton=2,XButton=3,YButton=4,LBumper=5,RBumper=6}
function getText(key) return key end
function getTexture(path) return path end
function getTextManager() return {getFontHeight=function() return 14 end,MeasureStringX=function(_,_,s) return #s*7 end} end
function getCore() return {getScreenWidth=function() return 1600 end,getScreenHeight=function() return 900 end} end
local joypad={}
function getJoypadData() return joypad end
function getSpecificPlayer() return {getJoypadBind=function() return 0 end} end
function setJoypadFocus(_,value) joypad.focus=value end
function updateJoypadFocus() end
function getSoundManager() return {playUISound=function() end} end
function getMouseX() return 1 end
function getMouseY() return 1 end
local shiftDown,ctrlDown=false,false
Keyboard={KEY_A=30,KEY_ESCAPE=1,KEY_Z=44,KEY_Y=21}
function isCtrlKeyDown() return ctrlDown end
function isShiftKeyDown() return shiftDown end
