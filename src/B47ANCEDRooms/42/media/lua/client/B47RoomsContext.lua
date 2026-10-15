local A=require 'B47ANCEDRooms/API'
if Events and Events.OnFillWorldObjectContextMenu then Events.OnFillWorldObjectContextMenu.Add(function(num,context,objects,test)
 if test or not getSpecificPlayer(num) then return end
 context:addOption(getText('UI_B47Rooms_DesignateRoom'),nil,function() A.openEditor(num) end)
end) end
