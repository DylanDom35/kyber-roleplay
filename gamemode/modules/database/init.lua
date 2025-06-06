-- kyber/gamemode/modules/database/init.lua
-- Database module initialization

KYBER.Database = KYBER.Database or {}

-- Database module configuration
KYBER.Database.Config = {
    UseSQL = false, -- Set to true to use SQL instead of local database
    SQLConfig = {
        host = "localhost",
        user = "root",
        password = "",
        database = "kyber",
        port = 3306
    }
}

-- Initialize database
function KYBER.Database:Initialize()
    -- Create necessary directories
    if not file.Exists("kyber", "DATA") then
        file.CreateDir("kyber")
    end
    
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
    
    -- Initialize SQL if enabled
    if self.Config.UseSQL then
        include("kyber/gamemode/modules/database/sql.lua")
        if not KYBER.SQL.Initialize() then
            print("[Kyber] WARNING: SQL initialization failed")
            self.Config.UseSQL = false
        end
    end
    
    -- Initialize local database
    include("kyber/gamemode/modules/database/local.lua")
    
    print("[Kyber] Database module initialized")
    return true
end

-- Query data
function KYBER.Database:Query(tableName, conditions, callback, errorCallback)
    if self.Config.UseSQL and KYBER.SQL then
        return KYBER.SQL:Query(tableName, conditions, callback, errorCallback)
    else
        local results = KYBER.LocalDB:Query(tableName, conditions)
        if callback then callback(results) end
        return results
    end
end

-- Insert data
function KYBER.Database:Insert(tableName, data, callback, errorCallback)
    if self.Config.UseSQL and KYBER.SQL then
        return KYBER.SQL:Insert(tableName, data, callback, errorCallback)
    else
        local id = KYBER.LocalDB:Insert(tableName, data)
        if callback then callback({id = id}) end
        return id
    end
end

-- Update data
function KYBER.Database:Update(tableName, id, data, callback, errorCallback)
    if self.Config.UseSQL and KYBER.SQL then
        return KYBER.SQL:Update(tableName, id, data, callback, errorCallback)
    else
        local success = KYBER.LocalDB:Update(tableName, id, data)
        if callback then callback({success = success}) end
        return success
    end
end

-- Delete data
function KYBER.Database:Delete(tableName, id, callback, errorCallback)
    if self.Config.UseSQL and KYBER.SQL then
        return KYBER.SQL:Delete(tableName, id, callback, errorCallback)
    else
        local success = KYBER.LocalDB:Delete(tableName, id)
        if callback then callback({success = success}) end
        return success
    end
end

-- Initialize the module
KYBER.Database:Initialize()

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