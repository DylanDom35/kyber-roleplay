-- kyber/gamemode/modules/ui/init.lua
-- UI component system initialization

return {
    name = "ui",
    version = "1.0.0",
    author = "Kyber Development Team",
    description = "UI component system",
    dependencies = {"core"},
    loadOrder = 2,
    
    Init = function(self)
        KYBER.UI = KYBER.UI or {}
        
        -- Load UI components
        local files = file.Find("kyber/gamemode/modules/ui/components/*.lua", "LUA")
        for _, file in ipairs(files) do
            include("kyber/gamemode/modules/ui/components/" .. file)
        end
        
        -- Load UI templates
        local files = file.Find("kyber/gamemode/modules/ui/templates/*.lua", "LUA")
        for _, file in ipairs(files) do
            include("kyber/gamemode/modules/ui/templates/" .. file)
        end
    end
} 