-- kyber/gamemode/modules/config/config.lua
-- Configuration management system

local KYBER = KYBER or {}

-- Configuration management
KYBER.Config = KYBER.Config or {}

-- Cache for loaded configurations
local configCache = {}

-- Load a configuration file
function KYBER.Config.Load(path, schema)
    if not path then
        KYBER.LogError("Invalid path for Config.Load")
        return nil
    end
    
    -- Check cache first
    if configCache[path] then
        return configCache[path]
    end
    
    -- Load from database
    local data = KYBER.Database.Load(path, schema)
    if not data then
        return nil
    end
    
    -- Cache the data
    configCache[path] = data
    return data
end

-- Save a configuration file
function KYBER.Config.Save(path, data, schema)
    if not path or not data then
        KYBER.LogError("Invalid parameters for Config.Save")
        return false
    end
    
    -- Save to database
    local success = KYBER.Database.Save(path, data, schema)
    if not success then
        return false
    end
    
    -- Update cache
    configCache[path] = data
    return true
end

-- Reload a configuration file
function KYBER.Config.Reload(path)
    if not path then
        KYBER.LogError("Invalid path for Config.Reload")
        return false
    end
    
    -- Clear cache
    configCache[path] = nil
    
    -- Reload from database
    local data = KYBER.Database.Load(path)
    if not data then
        return false
    end
    
    -- Update cache
    configCache[path] = data
    return true
end

-- Get a configuration value
function KYBER.Config.Get(path, key, default)
    if not path then
        KYBER.LogError("Invalid path for Config.Get")
        return default
    end
    
    -- Load configuration if not cached
    if not configCache[path] then
        local data = KYBER.Database.Load(path)
        if not data then
            return default
        end
        configCache[path] = data
    end
    
    -- Get value
    local value = configCache[path]
    if key then
        for k in string.gmatch(key, "([^.]+)") do
            value = value[k]
            if value == nil then
                return default
            end
        end
    end
    
    return value
end

-- Set a configuration value
function KYBER.Config.Set(path, key, value)
    if not path or not key then
        KYBER.LogError("Invalid parameters for Config.Set")
        return false
    end
    
    -- Load configuration if not cached
    if not configCache[path] then
        local data = KYBER.Database.Load(path)
        if not data then
            data = {}
        end
        configCache[path] = data
    end
    
    -- Set value
    local current = configCache[path]
    local keys = {}
    for k in string.gmatch(key, "([^.]+)") do
        table.insert(keys, k)
    end
    
    for i, k in ipairs(keys) do
        if i == #keys then
            current[k] = value
        else
            current[k] = current[k] or {}
            current = current[k]
        end
    end
    
    -- Save to database
    return KYBER.Database.Save(path, configCache[path])
end

-- Watch for configuration changes
function KYBER.Config.Watch(path, callback)
    if not path or not callback then
        KYBER.LogError("Invalid parameters for Config.Watch")
        return false
    end
    
    -- Create watcher
    local watcher = {
        path = path,
        callback = callback,
        lastData = KYBER.Database.Load(path)
    }
    
    -- Add to watchers
    KYBER.Config.watchers = KYBER.Config.watchers or {}
    KYBER.Config.watchers[path] = KYBER.Config.watchers[path] or {}
    table.insert(KYBER.Config.watchers[path], watcher)
    
    return true
end

-- Check for configuration changes
function KYBER.Config.CheckChanges()
    if not KYBER.Config.watchers then return end
    
    for path, watchers in pairs(KYBER.Config.watchers) do
        local currentData = KYBER.Database.Load(path)
        if currentData then
            for _, watcher in ipairs(watchers) do
                if not table.Equals(watcher.lastData, currentData) then
                    watcher.callback(currentData, watcher.lastData)
                    watcher.lastData = table.Copy(currentData)
                end
            end
        end
    end
end

-- Initialize default configurations
function KYBER.Config.InitDefaults()
    -- Factions
    local factionsPath = "kyber/config/factions/default.json"
    if not file.Exists(factionsPath, "DATA") then
        local factions = {
            ["jedi"] = {
                name = "Jedi Order",
                color = {r = 100, g = 200, b = 255},
                description = "Guardians of peace and justice",
                ranks = {
                    {
                        name = "Padawan",
                        color = {r = 150, g = 200, b = 255},
                        permissions = {"meditate", "train"}
                    },
                    {
                        name = "Knight",
                        color = {r = 100, g = 150, b = 255},
                        permissions = {"meditate", "train", "teach", "lead"}
                    },
                    {
                        name = "Master",
                        color = {r = 50, g = 100, b = 255},
                        permissions = {"meditate", "train", "teach", "lead", "promote"}
                    }
                }
            },
            ["sith"] = {
                name = "Sith Order",
                color = {r = 255, g = 50, b = 50},
                description = "Dark side Force users",
                ranks = {
                    {
                        name = "Acolyte",
                        color = {r = 255, g = 100, b = 100},
                        permissions = {"meditate", "train"}
                    },
                    {
                        name = "Warrior",
                        color = {r = 255, g = 50, b = 50},
                        permissions = {"meditate", "train", "teach", "lead"}
                    },
                    {
                        name = "Lord",
                        color = {r = 200, g = 0, b = 0},
                        permissions = {"meditate", "train", "teach", "lead", "promote"}
                    }
                }
            }
        }
        KYBER.Config.Save(factionsPath, factions, KYBER.Database.Schemas.Faction)
    end
    
    -- Species
    local speciesPath = "kyber/config/species/default.json"
    if not file.Exists(speciesPath, "DATA") then
        local species = {
            ["Human"] = {
                name = "Human",
                description = "The most common species in the galaxy",
                attributes = {
                    strength = 1.0,
                    agility = 1.0,
                    intelligence = 1.0,
                    charisma = 1.0
                }
            },
            ["Twi'lek"] = {
                name = "Twi'lek",
                description = "Known for their head-tails and natural charm",
                attributes = {
                    strength = 0.9,
                    agility = 1.1,
                    intelligence = 1.0,
                    charisma = 1.2
                }
            }
        }
        KYBER.Config.Save(speciesPath, species)
    end
end

-- Initialize on server
if SERVER then
    KYBER.Config.InitDefaults()
    
    -- Check for configuration changes periodically
    timer.Create("KYBER_ConfigWatcher", 1, 0, function()
        KYBER.Config.CheckChanges()
    end)
end 