-- Inventory module
local Inventory = {}
Inventory.__index = Inventory

-- Inventory module configuration
Inventory.Config = {
    MaxSlots = 30,
    MaxStackSize = 100,
    DefaultWeight = 10, -- Default weight for items without specified weight
    MaxWeight = 100, -- Maximum weight a player can carry
    ItemTypes = {
        "weapon",
        "ammo",
        "consumable",
        "material",
        "misc"
    },
    DefaultItems = {
        {
            id = "weapon_crowbar",
            name = "Crowbar",
            type = "weapon",
            weight = 5,
            description = "A standard crowbar"
        },
        {
            id = "weapon_pistol",
            name = "Pistol",
            type = "weapon",
            weight = 8,
            description = "A standard pistol"
        }
    }
}

-- Initialize the module
function Inventory:Initialize()
    print("[Kyber] Initializing Inventory module")
    
    -- Register network strings
    util.AddNetworkString("Kyber_Inventory_Open")
    util.AddNetworkString("Kyber_Inventory_Update")
    util.AddNetworkString("Kyber_Inventory_Use")
    util.AddNetworkString("Kyber_Inventory_Drop")
    util.AddNetworkString("Kyber_Inventory_Give")
    
    -- Initialize inventory data
    self.Items = {}
    self.MaxSlots = 50
    
    -- Load items
    self:LoadItems()
end

-- Load items
function Inventory:LoadItems()
    -- TODO: Implement item loading from database
    print("[Kyber] Loading item data")
end

-- Get player inventory
function Inventory:GetInventory(ply)
    if not IsValid(ply) then return {} end
    
    -- TODO: Implement inventory retrieval
    return {}
end

-- Add item
function Inventory:AddItem(ply, itemId, amount)
    if not IsValid(ply) then return false end
    
    -- TODO: Implement item addition
    print("[Kyber] Adding item " .. itemId .. " to " .. ply:Nick())
    return true
end

-- Remove item
function Inventory:RemoveItem(ply, itemId, amount)
    if not IsValid(ply) then return false end
    
    -- TODO: Implement item removal
    print("[Kyber] Removing item " .. itemId .. " from " .. ply:Nick())
    return true
end

-- Use item
function Inventory:UseItem(ply, itemId)
    if not IsValid(ply) then return false end
    
    -- TODO: Implement item usage
    print("[Kyber] Using item " .. itemId .. " by " .. ply:Nick())
    return true
end

-- Drop item
function Inventory:DropItem(ply, itemId, amount)
    if not IsValid(ply) then return false end
    
    -- TODO: Implement item dropping
    print("[Kyber] Dropping item " .. itemId .. " by " .. ply:Nick())
    return true
end

-- Give item
function Inventory:GiveItem(ply, target, itemId, amount)
    if not IsValid(ply) or not IsValid(target) then return false end
    
    -- TODO: Implement item giving
    print("[Kyber] Giving item " .. itemId .. " from " .. ply:Nick() .. " to " .. target:Nick())
    return true
end

-- Register the module
KYBER.Modules.inventory = Inventory
return Inventory

-- Initialize inventory module
KYBER.Inventory = KYBER.Inventory or {}

-- Include inventory system files
include("kyber/gamemode/modules/inventory/core.lua")
include("kyber/gamemode/modules/inventory/items.lua")

-- Register network strings
KYBER.Management.Network:Register("Kyber_Inventory_Update")
KYBER.Management.Network:Register("Kyber_Inventory_Use")
KYBER.Management.Network:Register("Kyber_Inventory_Drop")
KYBER.Management.Network:Register("Kyber_Inventory_Give")

-- Initialize inventory system
local success, err = pcall(function()
    -- Create inventory directory if it doesn't exist
    if not file.Exists("kyber/inventory", "DATA") then
        file.CreateDir("kyber/inventory")
    end
end)

if not success then
    KYBER.Management.ErrorHandler:Handle(err, "Failed to initialize inventory system")
end

-- Cleanup function
function KYBER.Inventory:Cleanup()
    -- Add any cleanup code here
end

function KYBER.Inventory:Save(ply)
    if not IsValid(ply) or not ply.KyberInventory then return end
    local path = "kyber/inventory/" .. ply:SteamID64() .. ".json"
    -- Create backup
    if file.Exists(path, "DATA") then
        file.Write(path .. ".backup", file.Read(path, "DATA"))
    end
    -- Write new data (placeholder)
    file.Write(path, util.TableToJSON(ply.KyberInventory))
end 