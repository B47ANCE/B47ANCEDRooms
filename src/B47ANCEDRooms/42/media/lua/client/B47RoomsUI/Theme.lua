-- Embedded presentation library. No application state, networking or mod APIs.
B47RoomsUI=B47RoomsUI or {}
local T={};B47RoomsUI.Theme=T
local function color(r,g,b,a) return {r=r,g=g,b=b,a=a or 1} end
T.colors={window=color(.025,.03,.032,.94),panel=color(.045,.055,.06,.94),raised=color(.08,.095,.105,.96),
 row=color(.045,.05,.052,.90),alternate=color(.075,.085,.09,.92),hover=color(.16,.18,.19,.96),
 selected=color(.22,.19,.115,.96),border=color(.28,.31,.32,.85),strong=color(.62,.66,.66,.95),
 text=color(.92,.93,.91),muted=color(.65,.69,.70),accent=color(.83,.68,.35),accentHover=color(.94,.79,.44),
 needed=color(.87,.34,.32),warning=color(.83,.68,.35),success=color(.43,.72,.43),disabled=color(.42,.46,.47),
 destructive=color(.73,.28,.26),overlay=color(.01,.015,.02,.80)}
T.spacing={xs=4,s=8,m=12,l=18,xl=24};T.borderSize=1;T.corner='square'
T.fonts={title=UIFont.Medium,section=UIFont.Medium,body=UIFont.Small,small=UIFont.Small,item=UIFont.Small,status=UIFont.Small}
local cached
function T.metrics()
 local small=getTextManager():getFontHeight(T.fonts.body);local title=getTextManager():getFontHeight(T.fonts.title)
 if cached and cached.font==small and cached.titleFont==title then return cached end
 cached={font=small,titleFont=title,header=math.max(40,title+18),row=math.max(30,small+12),treeRow=math.max(22,small+8),
 button=math.max(28,small+12),tab=math.max(32,small+16),icon=24,treeIcon=18,railIcon=32,railRow=math.max(48,small+28),rail=math.max(180,small*8),scrollbar=17,gap=8}
 return cached
end
function T.copy(c) return {r=c.r,g=c.g,b=c.b,a=c.a} end
return T
