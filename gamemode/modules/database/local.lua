-- Local database implementation
KYBER.LocalDB = KYBER.LocalDB or {}

-- Configuration
KYBER.LocalDB.Config = {
    Enabled = true, -- Set to false to use SQL instead
    SaveInterval = 300, -- Save every 5 minutes
    DataPath = "kyber/data/"
}

-- Initialize local database
function KYBER.LocalDB:Initialize()
    -- Create data directory if it doesn't exist
    if not file.Exists(self.Config.DataPath, "DATA") then
        file.CreateDir(self.Config.DataPath)
    end
    
    -- Initialize tables
    self.Tables = self.Tables or {}
    self.Tables.characters = self.Tables.characters or {}
    self.Tables.players = self.Tables.players or {}
    self.Tables.inventory = self.Tables.inventory or {}
    self.Tables.equipment = self.Tables.equipment or {}
    
    -- Load existing data
    self:LoadAll()
    
    -- Start save timer
    timer.Create("KyberLocalDBSave", self.Config.SaveInterval, 0, function()
        self:SaveAll()
    end)
    
    print("[Kyber] Local database initialized")
    return true
end

-- Load all data from files
function KYBER.LocalDB:LoadAll()
    local files = file.Find(self.Config.DataPath .. "*.json", "DATA")
    for _, filename in ipairs(files) do
        local tableName = string.gsub(filename, ".json", "")
        local data = util.JSONToTable(file.Read(self.Config.DataPath .. filename, "DATA") or "{}")
        self.Tables[tableName] = data
    end
end

-- Save all data to files
function KYBER.LocalDB:SaveAll()
    for tableName, data in pairs(self.Tables) do
        file.Write(self.Config.DataPath .. tableName .. ".json", util.TableToJSON(data, true))
    end
end

-- Query data
function KYBER.LocalDB:Query(tableName, conditions)
    if not self.Tables[tableName] then return {} end
    
    local results = {}
    for id, row in pairs(self.Tables[tableName]) do
        local match = true
        if conditions then
            for key, value in pairs(conditions) do
                if row[key] ~= value then
                    match = false
                    break
                end
            end
        end
        if match then
            table.insert(results, row)
        end
    end
    return results
end

-- Insert data
function KYBER.LocalDB:Insert(tableName, data)
    if not self.Tables[tableName] then
        self.Tables[tableName] = {}
    end
    
    local id = os.time() .. "_" .. math.random(1000, 9999)
    data.id = id
    self.Tables[tableName][id] = data
    
    -- Save immediately
    file.Write(self.Config.DataPath .. tableName .. ".json", util.TableToJSON(self.Tables[tableName], true))
    
    return id
end

-- Update data
function KYBER.LocalDB:Update(tableName, id, data)
    if not self.Tables[tableName] or not self.Tables[tableName][id] then
        return false
    end
    
    for key, value in pairs(data) do
        self.Tables[tableName][id][key] = value
    end
    
    -- Save immediately
    file.Write(self.Config.DataPath .. tableName .. ".json", util.TableToJSON(self.Tables[tableName], true))
    
    return true
end

-- Delete data
function KYBER.LocalDB:Delete(tableName, id)
    if not self.Tables[tableName] or not self.Tables[tableName][id] then
        return false
    end
    
    self.Tables[tableName][id] = nil
    
    -- Save immediately
    file.Write(self.Config.DataPath .. tableName .. ".json", util.TableToJSON(self.Tables[tableName], true))
    
    return true
end

-- Initialize the module
KYBER.LocalDB:Initialize() 