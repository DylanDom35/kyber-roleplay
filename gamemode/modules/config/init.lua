-- kyber/gamemode/modules/config/init.lua
-- Configuration module initialization

return {
    name = "config",
    version = "1.0.0",
    author = "Kyber Development Team",
    description = "Configuration management system",
    dependencies = {"core", "database"},
    loadOrder = 1,
    
    Init = function(self)
        KYBER.Config = KYBER.Config or {}
        
        -- Create config directories
        if SERVER then
            local dirs = {
                "kyber/config",
                "kyber/config/factions",
                "kyber/config/species",
                "kyber/config/items",
                "kyber/config/territories"
            }
            
            for _, dir in ipairs(dirs) do
                if not file.Exists(dir, "DATA") then
                    file.CreateDir(dir)
                end
            end
        end
    end
} 