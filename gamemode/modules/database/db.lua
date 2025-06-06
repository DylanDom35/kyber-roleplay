-- kyber/gamemode/modules/database/db.lua
-- Database layer implementation

local KYBER = KYBER or {}

-- Database operations
KYBER.Database = KYBER.Database or {}

-- Data validation
local function ValidateData(data, schema)
    if not data or not schema then return false end
    
    for key, rules in pairs(schema) do
        -- Check required fields
        if rules.required and data[key] == nil then
            return false, "Missing required field: " .. key
        end
        
        -- Check type
        if data[key] ~= nil and type(data[key]) ~= rules.type then
            return false, "Invalid type for field: " .. key
        end
        
        -- Check min/max for numbers
        if rules.type == "number" then
            if rules.min and data[key] < rules.min then
                return false, "Value too small for field: " .. key
            end
            if rules.max and data[key] > rules.max then
                return false, "Value too large for field: " .. key
            end
        end
        
        -- Check string length
        if rules.type == "string" then
            if rules.minLength and #data[key] < rules.minLength then
                return false, "String too short for field: " .. key
            end
            if rules.maxLength and #data[key] > rules.maxLength then
                return false, "String too long for field: " .. key
            end
        end
        
        -- Check table length
        if rules.type == "table" then
            if rules.minItems and #data[key] < rules.minItems then
                return false, "Not enough items for field: " .. key
            end
            if rules.maxItems and #data[key] > rules.maxItems then
                return false, "Too many items for field: " .. key
            end
        end
    end
    
    return true
end

-- Save data to file
function KYBER.Database.Save(path, data, schema)
    if not path or not data then
        KYBER.LogError("Invalid parameters for Save")
        return false
    end
    
    -- Validate data if schema provided
    if schema then
        local valid, err = ValidateData(data, schema)
        if not valid then
            KYBER.LogError("Data validation failed: " .. err)
            return false
        end
    end
    
    -- Convert to JSON
    local json = util.TableToJSON(data, true)
    if not json then
        KYBER.LogError("Failed to convert data to JSON")
        return false
    end
    
    -- Save to file
    local success = file.Write(path, json)
    if not success then
        KYBER.LogError("Failed to write data to file: " .. path)
        return false
    end
    
    return true
end

-- Load data from file
function KYBER.Database.Load(path, schema)
    if not path then
        KYBER.LogError("Invalid path for Load")
        return nil
    end
    
    -- Check if file exists
    if not file.Exists(path, "DATA") then
        return nil
    end
    
    -- Read file
    local json = file.Read(path, "DATA")
    if not json then
        KYBER.LogError("Failed to read file: " .. path)
        return nil
    end
    
    -- Parse JSON
    local data = util.JSONToTable(json)
    if not data then
        KYBER.LogError("Failed to parse JSON from file: " .. path)
        return nil
    end
    
    -- Validate data if schema provided
    if schema then
        local valid, err = ValidateData(data, schema)
        if not valid then
            KYBER.LogError("Data validation failed: " .. err)
            return nil
        end
    end
    
    return data
end

-- Delete data file
function KYBER.Database.Delete(path)
    if not path then
        KYBER.LogError("Invalid path for Delete")
        return false
    end
    
    if not file.Exists(path, "DATA") then
        return true -- File doesn't exist, consider it deleted
    end
    
    local success = file.Delete(path)
    if not success then
        KYBER.LogError("Failed to delete file: " .. path)
        return false
    end
    
    return true
end

-- List files in directory
function KYBER.Database.List(path)
    if not path then
        KYBER.LogError("Invalid path for List")
        return nil
    end
    
    local files, dirs = file.Find(path .. "/*", "DATA")
    if not files then
        return nil
    end
    
    return files, dirs
end

-- Backup data
function KYBER.Database.Backup(path)
    if not path then
        KYBER.LogError("Invalid path for Backup")
        return false
    end
    
    if not file.Exists(path, "DATA") then
        return true -- Nothing to backup
    end
    
    -- Create backup directory
    local backupDir = "kyber/backups"
    if not file.Exists(backupDir, "DATA") then
        file.CreateDir(backupDir)
    end
    
    -- Generate backup filename
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local backupPath = backupDir .. "/" .. string.gsub(path, "/", "_") .. "_" .. timestamp .. ".bak"
    
    -- Copy file
    local success = file.Copy(path, backupPath, "DATA")
    if not success then
        KYBER.LogError("Failed to create backup: " .. backupPath)
        return false
    end
    
    return true
end

-- Restore from backup
function KYBER.Database.Restore(backupPath, targetPath)
    if not backupPath or not targetPath then
        KYBER.LogError("Invalid parameters for Restore")
        return false
    end
    
    if not file.Exists(backupPath, "DATA") then
        KYBER.LogError("Backup file not found: " .. backupPath)
        return false
    end
    
    -- Copy backup to target
    local success = file.Copy(backupPath, targetPath, "DATA")
    if not success then
        KYBER.LogError("Failed to restore backup: " .. backupPath)
        return false
    end
    
    return true
end

-- Log database operations
function KYBER.Database.Log(operation, path, success, error)
    if not operation or not path then
        KYBER.LogError("Invalid parameters for Log")
        return false
    end
    
    local logEntry = {
        timestamp = os.time(),
        operation = operation,
        path = path,
        success = success,
        error = error
    }
    
    local logPath = "kyber/logs/database_" .. os.date("%Y%m%d") .. ".log"
    local logFile = file.Read(logPath, "DATA") or ""
    
    logFile = logFile .. util.TableToJSON(logEntry) .. "\n"
    
    local success = file.Write(logPath, logFile)
    if not success then
        KYBER.LogError("Failed to write to log file: " .. logPath)
        return false
    end
    
    return true
end

-- Data schemas
KYBER.Database.Schemas = {
    Character = {
        name = {type = "string", required = true, minLength = 1, maxLength = 32},
        species = {type = "string", required = true},
        faction = {type = "string", required = false},
        rank = {type = "string", required = false},
        credits = {type = "number", required = true, min = 0},
        inventory = {type = "table", required = true, minItems = 0},
        attributes = {type = "table", required = true},
        created = {type = "number", required = true},
        lastLogin = {type = "number", required = true}
    },
    
    Faction = {
        name = {type = "string", required = true, minLength = 1, maxLength = 32},
        description = {type = "string", required = true},
        color = {type = "table", required = true},
        ranks = {type = "table", required = true, minItems = 1},
        members = {type = "table", required = true},
        territory = {type = "table", required = false},
        resources = {type = "table", required = true},
        created = {type = "number", required = true}
    },
    
    Group = {
        name = {type = "string", required = true, minLength = 1, maxLength = 32},
        leader = {type = "string", required = true},
        members = {type = "table", required = true, minItems = 1},
        description = {type = "string", required = true},
        color = {type = "table", required = true},
        territory = {type = "table", required = false},
        resources = {type = "table", required = true},
        created = {type = "number", required = true}
    },
    
    Territory = {
        name = {type = "string", required = true, minLength = 1, maxLength = 32},
        owner = {type = "string", required = true},
        type = {type = "string", required = true},
        position = {type = "table", required = true},
        size = {type = "number", required = true, min = 1},
        resources = {type = "table", required = true},
        defenses = {type = "table", required = true},
        created = {type = "number", required = true}
    }
} 