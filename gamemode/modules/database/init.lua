-- kyber/gamemode/modules/database/init.lua
-- Database module initialization

return {
    name = "database",
    version = "1.0.0",
    author = "Kyber Development Team",
    description = "Database layer for data persistence",
    dependencies = {"core"},
    loadOrder = 0, -- Load first
    
    Init = function(self)
        -- Initialize database
        KYBER.Database = KYBER.Database or {}
        
        -- Create data directories
        if SERVER then
            if not file.Exists("kyber", "DATA") then
                file.CreateDir("kyber")
            end
            
            -- Create subdirectories
            local dirs = {
                "kyber/characters",
                "kyber/factions",
                "kyber/groups",
                "kyber/territories",
                "kyber/logs"
            }
            
            for _, dir in ipairs(dirs) do
                if not file.Exists(dir, "DATA") then
                    file.CreateDir(dir)
                end
            end
        end
    end
} 