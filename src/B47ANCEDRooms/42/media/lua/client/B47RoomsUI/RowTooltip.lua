require 'B47RoomsUI/Renderer'
local U=B47RoomsUI
local H={};U.RowTooltip=H
function H.hide(list)
    local tip=list.tooltipUI
    if tip then
        local visible=tip:getIsVisible()
        tip:setVisible(false)
        if list.b47TooltipRegistered or visible then tip:removeFromUIManager() end
    end
    list.b47TooltipRegistered=false;list.b47TooltipEntry=nil
end
local function viewport(playerNum)
    return getPlayerScreenLeft(playerNum),getPlayerScreenTop(playerNum),getPlayerScreenWidth(playerNum),getPlayerScreenHeight(playerNum)
end
function H.place(list,tip,entry,playerNum)
    local left,top,width,height=viewport(playerNum)
    local y=list:getAbsoluteY()+list:getYScroll()
    for _,row in ipairs(list.items) do if row==entry then break end;y=y+row.height end
    local bottom=list:getAbsoluteY()+list:getHeight()
    if y+entry.height<=list:getAbsoluteY() or y>=bottom then H.hide(list);return false end
    local rowTop=math.max(y,list:getAbsoluteY())
    local x=list:getAbsoluteX()+list:getWidth()+8
    if x+tip:getWidth()>left+width then x=list:getAbsoluteX()-tip:getWidth()-8 end
    if rowTop+tip:getHeight()>top+height then rowTop=y-tip:getHeight()-8 end
    x=math.max(left,math.min(x,left+width-tip:getWidth()))
    rowTop=math.max(top,math.min(rowTop,top+height-tip:getHeight()))
    tip:setDesiredPosition(x,rowTop)
    return true
end
function H.attach(list,playerNum)
    if list.b47RowTooltip then return end
    list.b47RowTooltip=true
    local update=list.updateTooltip
    list.updateTooltip=function(self)
        local owner=self;while owner do if owner.playerNum~=nil then playerNum=owner.playerNum;break end;owner=owner.parent end
        if not self:isReallyVisible() then H.hide(self);return end
        -- Preserve the native hit test, scrollbar exclusion and occluding-window test.
        update(self)
        local tip=self.tooltipUI
        if not tip or not tip:getIsVisible() then self.b47TooltipRegistered=false;H.hide(self);return end
        self.b47TooltipRegistered=true
        local entry=self.items[self:rowAt(self:getMouseX(),self:getMouseY())]
        if not entry then H.hide(self);return end
        self.b47TooltipEntry=entry
        local _,_,vw,vh=viewport(playerNum)
        local font=ISToolTip.GetFont();local tm=getTextManager()
        local fontHeight=tm:getFontHeight(font)
        local maxWidth=math.max(1,math.min(360,vw-40))
        local maxLines=math.max(1,math.min(8,math.floor((vh-40)/(fontHeight+4))))
        local raw=tostring(entry.tooltip or '')
        if self.b47TooltipText~=raw or self.b47TooltipFont~=font or self.b47TooltipFontHeight~=fontHeight or self.b47TooltipWidth~=maxWidth or self.b47TooltipLines~=maxLines then
            local lines={};local text=raw:gsub('<LINE>','\n')
            for line in (text..'\n'):gmatch('(.-)\n') do
                if #lines>=maxLines then break end
                -- Container names are plain text, not rich-text instructions.
                line=line:gsub('[<>]',''):gsub('[\r\t]',' ')
                lines[#lines+1]=U.Renderer.fit(line,maxWidth,font)
            end
            self.b47TooltipText,self.b47TooltipFont,self.b47TooltipWidth,self.b47TooltipLines=raw,font,maxWidth,maxLines
            self.b47TooltipFontHeight=fontHeight
            self.b47TooltipDescription=table.concat(lines,' <LINE> ')
        end
        tip.description=self.b47TooltipDescription
        tip.defaultMyWidth=0
        tip.maxLineWidth=maxWidth/(fontHeight/15)
        tip.followMouse=false
        -- Native prerender and render must not paint backgrounds at different positions.
        tip.backgroundColor.a=0
        tip:doLayout()
        H.place(self,tip,entry,playerNum)
    end
    local visible=list.setVisible
    list.setVisible=function(self,value) if not value then H.hide(self) end;return visible(self,value) end
    local clear=list.clear
    list.clear=function(self,...) H.hide(self);return clear(self,...) end
end
return H
