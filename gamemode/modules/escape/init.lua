-- kyber/gamemode/modules/escape/init.lua
-- Escape menu module initialization

return {
    name = "escape",
    version = "1.0.0",
    author = "Kyber Development Team",
    description = "Custom escape menu with Star Wars theme",
    dependencies = {"core"},
    loadOrder = 1,
    
    Init = function(self)
        if CLIENT then
            -- Load module files
            include("vgui.lua")
            include("panel.lua")
            
            -- Register hooks
            KYBER.RegisterModuleHook("escape", "GUIMousePressed", function(mc)
                if mc == MOUSE_LEFT and gui.IsGameUIVisible() then
                    if not IsValid(KYBER.EscapePanel) then
                        KYBER.EscapePanel = KYBER.CreateEscapePanel()
                    end
                    return true
                end
            end)
            
            -- Register commands
            KYBER.RegisterModuleConcommand("escape", "open", function()
                KYBER.OpenEscapeMenu()
            end)
        end
    end
} 