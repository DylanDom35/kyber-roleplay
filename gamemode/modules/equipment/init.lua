-- Equipment module
local Equipment = {}
Equipment.__index = Equipment

-- Equipment module configuration
Equipment.Config = {
    Slots = {
        "head",
        "chest",
        "arms",
        "hands",
        "legs",
        "feet",
        "back",
        "accessory1",
        "accessory2"
    },
    DefaultEquipment = {
        head = nil,
        chest = nil,
        arms = nil,
        hands = nil,
        legs = nil,
        feet = nil,
        back = nil,
        accessory1 = nil,
        accessory2 = nil
    },
    EquipmentTypes = {
        "armor",
        "clothing",
        "accessory",
        "weapon",
        "tool"
    },
    ArmorTypes = {
        "light",
        "medium",
        "heavy"
    },
    ArmorStats = {
        light = {
            protection = 0.2,
            speed = 1.0,
            stamina = 1.0
        },
        medium = {
            protection = 0.4,
            speed = 0.9,
            stamina = 0.9
        },
        heavy = {
            protection = 0.6,
            speed = 0.8,
            stamina = 0.8
        }
    }
}

-- Stat caching
local statCache = {}
local CACHE_DURATION = 1 -- seconds

function Equipment:GetCachedStats(ply)
    local key = ply:SteamID64()
    local cache = statCache[key]
    
    if cache and (CurTime() - cache.time) < CACHE_DURATION then
        return cache.stats
    end
    
    local stats = self:CalculateStats(ply)
    statCache[key] = {
        time = CurTime(),
        stats = stats
    }
    
    return stats
end

-- Cleanup old cache entries
timer.Create("KyberEquipmentCacheCleanup", 60, 0, function()
    local currentTime = CurTime()
    for key, cache in pairs(statCache) do
        if (currentTime - cache.time) > CACHE_DURATION then
            statCache[key] = nil
        end
    end
end)

-- Initialize the module
function Equipment:Initialize()
    print("[Kyber] Initializing Equipment module")
    
    -- Register network strings
    util.AddNetworkString("Kyber_Equipment_Open")
    util.AddNetworkString("Kyber_Equipment_Update")
    util.AddNetworkString("Kyber_Equipment_Equip")
    util.AddNetworkString("Kyber_Equipment_Unequip")
    
    -- Initialize equipment data
    self.Slots = {
        "head",
        "body",
        "hands",
        "legs",
        "feet",
        "weapon",
        "shield"
    }
    
    -- Load equipment
    self:LoadEquipment()
end

-- Load equipment
function Equipment:LoadEquipment()
    -- TODO: Implement equipment loading from database
    print("[Kyber] Loading equipment data")
end

-- Get player equipment
function Equipment:GetEquipment(ply)
    if not IsValid(ply) then return {} end
    
    -- TODO: Implement equipment retrieval
    return {}
end

-- Equip item
function Equipment:Equip(ply, itemId, slot)
    if not IsValid(ply) then return false end
    if not self:IsValidSlot(slot) then return false end
    
    -- TODO: Implement item equipping
    print("[Kyber] Equipping item " .. itemId .. " to " .. slot .. " for " .. ply:Nick())
    return true
end

-- Unequip item
function Equipment:Unequip(ply, slot)
    if not IsValid(ply) then return false end
    if not self:IsValidSlot(slot) then return false end
    
    -- TODO: Implement item unequipping
    print("[Kyber] Unequipping item from " .. slot .. " for " .. ply:Nick())
    return true
end

-- Get equipment stats
function Equipment:GetStats(ply)
    if not IsValid(ply) then return {} end
    
    -- TODO: Implement stats calculation
    return {}
end

-- Check if slot is valid
function Equipment:IsValidSlot(slot)
    return table.HasValue(self.Slots, slot)
end

-- Register the module
KYBER.Modules.equipment = Equipment
return Equipment

-- Initialize equipment module
KYBER.Equipment = KYBER.Equipment or {}

-- Include equipment system files
include("kyber/gamemode/modules/equipment/core.lua")
include("kyber/gamemode/modules/equipment/armor.lua")
include("kyber/gamemode/modules/equipment/weapons.lua")

-- Register network strings
KYBER.Management.Network:Register("Kyber_Equipment_Update")
KYBER.Management.Network:Register("Kyber_Equipment_Equip")
KYBER.Management.Network:Register("Kyber_Equipment_Unequip")
KYBER.Management.Network:Register("Kyber_Equipment_Repair")

-- Initialize equipment system
local success, err = pcall(function()
    -- Create equipment directory if it doesn't exist
    if not file.Exists("kyber/equipment", "DATA") then
        file.CreateDir("kyber/equipment")
    end
end)

if not success then
    KYBER.Management.ErrorHandler:Handle(err, "Failed to initialize equipment system")
end

-- Cleanup function
function KYBER.Equipment:Cleanup()
    -- Add any cleanup code here
end

function KYBER.Equipment:Save(ply)
    if not IsValid(ply) or not ply.KyberEquipment then return end
    local path = "kyber/equipment/" .. ply:SteamID64() .. ".json"
    -- Create backup
    if file.Exists(path, "DATA") then
        file.Write(path .. ".backup", file.Read(path, "DATA"))
    end
    -- Write new data (placeholder)
    file.Write(path, util.TableToJSON(ply.KyberEquipment))
end 