-- kyber/gamemode/init.lua
-- Complete Kyber Gamemode Initialization

-- Initialize the KYBER table first
KYBER = KYBER or {}

print("[Kyber] Starting gamemode initialization...")

-- Add all client files for download
local clientFiles = {
    "shared.lua",
    "cl_init.lua",
    
    -- Character system
    "modules/character/sheet.lua",
    "modules/character/creation.lua",
    "modules/character/selection.lua",
    
    -- Admin system
    "modules/admin/core.lua",
    "modules/admin/ui.lua",
    "modules/admin/integration.lua",

    
    -- Inventory system
    "modules/inventory/system.lua",
    "modules/inventory/trading.lua",
    "modules/inventory/integration.lua",
    
    -- Equipment system
    "modules/equipment/system.lua",
    "modules/equipment/integration.lua",
    
    -- Medical system
    "modules/medical/system.lua",
    "modules/medical/integration.lua",
    
    -- Communication system
    "modules/communication/system.lua",
    
    -- Reputation system
    "modules/reputation/system.lua",
    "modules/reputation/integration.lua",
    
    -- Banking system
    "modules/banking/system.lua",
    "modules/banking/integration.lua",
    
    -- Crafting system
    "modules/crafting/system.lua",
    "modules/crafting/integration.lua",
    
    -- Grand Exchange system
    "modules/economy/grand_exchange.lua",
    
    -- Force lottery system
    "modules/force/lottery.lua",
    "modules/force/lottery_ui.lua",
    
    -- Faction creation system
    "modules/factions/creation.lua",
    
    -- Legendary character system
    "modules/legendary/system.lua",
    
    -- Galaxy travel system
    "modules/galaxy/travel.lua",
}

-- Add all client files
for _, file in ipairs(clientFiles) do
    AddCSLuaFile(file)
end

-- Include shared code first (this sets up KYBER table and factions)
include("shared.lua")

-- Utility function for safe includes with error handling
local function safeInclude(path, description)
    local success, err = pcall(include, path)
    if not success then
        print("[Kyber] ERROR loading " .. (description or path) .. ": " .. tostring(err))
        return false
    else
        print("[Kyber] ✓ Loaded " .. (description or path))
        return true
    end
end

-- Test that KYBER exists after shared.lua
if KYBER then
    print("[Kyber] KYBER table initialized successfully")
    if KYBER.Factions then
        print("[Kyber] Factions loaded:", table.Count(KYBER.Factions), "factions")
    end
else
    print("[Kyber] ERROR: KYBER table not initialized!")
    return
end

print("[Kyber] Loading core systems...")

-- Load core systems first (order matters for dependencies)
safeInclude("modules/playerdata/core.lua", "Player Data Core")

-- Character system (load early for player initialization)
safeInclude("modules/character/sheet.lua", "Character Sheet")
safeInclude("modules/character/creation.lua", "Character Creation")
safeInclude("modules/character/selection.lua", "Character Selection")

-- Admin system (load early for debugging)
safeInclude("modules/admin/core.lua", "Admin Core")
safeInclude("modules/admin/commands.lua", "Admin Commands")
safeInclude("modules/admin/integration.lua", "Admin Integration")
safeInclude("modules/admin/panel.lua", "Admin Panel")

-- Spawn system
safeInclude("modules/spawn/loadout.lua", "Spawn Loadout")

print("[Kyber] Loading economy systems...")

-- Economy and inventory systems
safeInclude("modules/inventory/system.lua", "Inventory System")
safeInclude("modules/inventory/trading.lua", "Trading System")
safeInclude("modules/economy/grand_exchange.lua", "Grand Exchange")

-- Banking system
safeInclude("modules/banking/system.lua", "Banking System")
safeInclude("modules/banking/integration.lua", "Banking Integration")

print("[Kyber] Loading equipment and crafting...")

-- Equipment system
safeInclude("modules/equipment/system.lua", "Equipment System")

-- Crafting system
safeInclude("modules/crafting/system.lua", "Crafting System")
safeInclude("modules/crafting/integration.lua", "Crafting Integration")

print("[Kyber] Loading medical and reputation...")

-- Medical system
safeInclude("modules/medical/system.lua", "Medical System")
safeInclude("modules/medical/integration.lua", "Medical Integration")

-- Reputation system
safeInclude("modules/reputation/system.lua", "Reputation System")
safeInclude("modules/reputation/integration.lua", "Reputation Integration")

print("[Kyber] Loading communication and special systems...")

-- Communication system
safeInclude("modules/communication/system.lua", "Communication System")

-- Force lottery system
safeInclude("modules/force/lottery.lua", "Force Lottery System")

-- Faction creation system
safeInclude("modules/factions/creation.lua", "Faction Creation")

-- Legendary character system
safeInclude("modules/legendary/system.lua", "Legendary Characters")

-- Galaxy travel system
safeInclude("modules/galaxy/travel.lua", "Galaxy Travel")

print("[Kyber] Loading integration modules...")

-- Load integration modules last
safeInclude("modules/inventory/integration.lua", "Inventory Integration")
safeInclude("modules/equipment/integration.lua", "Equipment Integration")

print("[Kyber] Registering entities...")

-- Register entities
local entities = {
    "kyber_dropped_item",
    "kyber_crafting_station", 
    "kyber_bacta_tank",
    "kyber_banking_terminal",
    "kyber_galaxy_terminal"
}

for _, entName in ipairs(entities) do
    local entPath = "entities/entities/" .. entName
    AddCSLuaFile(entPath .. "/cl_init.lua")
    AddCSLuaFile(entPath .. "/shared.lua")
    safeInclude(entPath .. "/init.lua", "Entity: " .. entName)
end

print("[Kyber] Setting up gamemode hooks...")

-- Essential gamemode hooks
function GM:PlayerInitialSpawn(ply)
    -- Prevent player from spawning immediately
    ply:SetNoDraw(true)
    ply:Freeze(true)
    ply:SetMoveType(MOVETYPE_NONE)
    
    -- Show loading screen
    net.Start("Kyber_ShowLoadingScreen")
    net.Send(ply)
    
    -- Wait a moment before showing character selection
    timer.Simple(2, function()
        if IsValid(ply) then
            -- Check if player has a character
            local hasChar = KYBER.Character:HasCharacter(ply)
            
            if hasChar then
                -- Show character selection
                KYBER.Character:OpenSelection(ply)
            else
                -- Show character creation
                net.Start("Kyber_Character_OpenCreation")
                net.Send(ply)
            end
        end
    end)
end

function GM:PlayerSpawn(ply)
    -- Only give loadout if player has a character
    if not ply.KyberCharacter then return end
    
    -- Give default loadout
    timer.Simple(0.1, function()
        if IsValid(ply) then
            ply:StripWeapons()
            ply:Give("weapon_crowbar")
            ply:Give("weapon_pistol")
            ply:GiveAmmo(60, "Pistol", true)
        end
    end)
end

function GM:PlayerSay(ply, text, teamChat)
    -- Handle OOC chat
    if string.sub(text, 1, 2) == "//" or string.sub(text, 1, 4) == "/ooc" then
        local oocText = string.sub(text, text:find(" ") and text:find(" ") + 1 or 3)
        
        for _, p in ipairs(player.GetAll()) do
            p:ChatPrint("[OOC] " .. ply:Nick() .. ": " .. oocText)
        end
        
        return ""
    end
    
    -- Handle character names in IC chat
    local charName = ply:GetNWString("kyber_name", ply:Nick())
    if charName ~= ply:Nick() then
        for _, p in ipairs(player.GetAll()) do
            p:ChatPrint(charName .. ": " .. text)
        end
        return ""
    end
end

print("[Kyber] Server initialization complete")