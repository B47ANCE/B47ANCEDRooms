require 'B47RoomsUI/Theme'
local U=B47RoomsUI;local T=U.Theme;local R={};U.Renderer=R
function R.rect(w,x,y,width,height,c) if width>0 and height>0 then w:drawRect(x,y,width,height,c.a,c.r,c.g,c.b) end end
function R.background(w,x,y,width,height,c)
 if width>0 and height>0 then w:drawRect(x,y,width,height,U.Appearance and U.Appearance.alpha(w) or c.a,c.r,c.g,c.b) end
end
function R.border(w,x,y,width,height,c) if width>0 and height>0 then w:drawRectBorder(x,y,width,height,c.a,c.r,c.g,c.b) end end
function R.text(w,text,x,y,c,font) w:drawText(tostring(text or ''),x,y,c.r,c.g,c.b,c.a,font or T.fonts.body) end
function R.fit(text,width,font)
 text=tostring(text or '');font=font or T.fonts.body
 local measure=getTextManager();if measure:MeasureStringX(font,text)<=width then return text end
 local suffix='...';local n=#text
 while n>0 do
  n=n-1;while n>0 and string.byte(text,n+1)>=128 and string.byte(text,n+1)<192 do n=n-1 end
  local candidate=string.sub(text,1,n)..suffix
  if measure:MeasureStringX(font,candidate)<=width then return candidate end
 end
 return ''
end
function R.focus(w)
 if w.joypadFocused or w.joyfocus or w.isFocused and w:isFocused() then
  R.border(w,1,1,w:getWidth()-2,w:getHeight()-2,T.colors.accent)
  R.border(w,2,2,w:getWidth()-4,w:getHeight()-4,T.colors.strong)
 end
end
function R.row(w,y,height,index,selected,hover)
 local c=selected and T.colors.selected or hover and T.colors.hover or index%2==0 and T.colors.alternate or T.colors.row
 -- The root owns the single backing pass. Rows add a light contrast overlay,
 -- while the opaque selection stripe stays independent of user opacity.
 local a=U.Appearance and U.Appearance.alpha(w)*.12 or c.a
 w:drawRect(0,y,w:getWidth(),height-1,a,c.r,c.g,c.b)
 if selected then R.rect(w,0,y,3,height-1,T.colors.accent) end
end
function R.checkbox(w,x,y,state)
 R.border(w,x,y,16,16,T.colors.strong)
 if state=='full' then R.text(w,'x',x+3,y-1,T.colors.accent)
 elseif state=='partial' then R.rect(w,x+3,y+7,10,3,T.colors.accent) end
end
function R.icon(w,texture,x,y,size)
 if texture then
  if w.drawTextureScaledAspect then w:drawTextureScaledAspect(texture,x,y,size,size,1,1,1,1)
  else w:drawTextureScaled(texture,x,y,size,size,1,1,1,1) end
 else R.border(w,x+3,y+3,size-6,size-6,T.colors.border) end
end
U.Badge={}
function U.Badge.draw(w,label,x,y,role) R.text(w,label,x,y,T.colors[role] or T.colors.muted,T.fonts.status) end
U.Progress={}
function U.Progress.draw(w,x,y,width,current,target,role)
 R.rect(w,x,y,width,8,T.colors.raised)
 local ratio=target and target>0 and math.min(1,math.max(0,current/target)) or 0
 R.rect(w,x,y,width*ratio,8,T.colors[role] or T.colors.accent)
 R.border(w,x,y,width,8,T.colors.border)
end
U.Tree={indent=function(depth) return 6+(depth or 0)*20 end,checkbox=R.checkbox}
U.Table={}
function U.Table.prepare(list,columns)
 list.b47Columns=columns
 local width=list:getWidth()-T.metrics().scrollbar;local x=8
 for _,c in ipairs(columns) do c.x=x;c.width=math.max(16,width*c.share);c.headerText=R.fit(c.label,c.width-12,T.fonts.body);x=x+c.width end
 for _,entry in ipairs(list.items) do
  entry.b47Cells={}
  for i,c in ipairs(columns) do entry.b47Cells[i]=R.fit(entry.item.cells and entry.item.cells[i] or '',c.width-(i==1 and entry.item.texture and 42 or 12),T.fonts.body) end
 end
end
function U.Table.draw(list,y,entry)
 if y+list:getYScroll()+entry.height<0 or y+list:getYScroll()>=list:getHeight() then return y+entry.height end
 R.row(list,y,entry.height,entry.index,list.selected==entry.index,list.mouseoverselected==entry.index and list:isMouseOver())
 local columns=list.b47Columns
 for i,c in ipairs(columns or {}) do
  local x=c.x;local color=entry.item.role and i==#columns and T.colors[entry.item.role] or T.colors.text
  if i==1 and entry.item.texture then R.icon(list,entry.item.texture,x,y+(entry.height-24)/2,24);x=x+30 end
  R.text(list,entry.b47Cells and entry.b47Cells[i] or '',x,y+(entry.height-T.metrics().font)/2,color)
 end
 return y+entry.height
end
return R
