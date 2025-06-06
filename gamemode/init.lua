-- kyber/gamemode/init.lua
-- Complete Kyber Gamemode Initialization

-- Initialize KYBER table
KYBER = KYBER or {}

print("[Kyber] Starting gamemode initialization...")

-- Include shared code
include("kyber/gamemode/shared.lua")

-- Include management system
include("kyber/gamemode/core/management.lua")

-- Include module loader
include("kyber/gamemode/core/loader.lua")

-- Register network strings using the management system
local networkStrings = {
    -- Character
    "Kyber_Character_OpenSelection",
    "Kyber_Character_Select",
    "Kyber_Character_Create",
    "Kyber_Character_Delete",
    
    -- Inventory
    "Kyber_Inventory_Update",
    "Kyber_Inventory_Use",
    "Kyber_Inventory_Drop",
    "Kyber_Inventory_Give",
    
    -- Equipment
    "Kyber_Equipment_Update",
    "Kyber_Equipment_Equip",
    "Kyber_Equipment_Unequip",
    
    -- Banking
    "Kyber_Banking_Update",
    "Kyber_Banking_Deposit",
    "Kyber_Banking_Withdraw",
    "Kyber_Banking_Transfer",
    
    -- Factions
    "Kyber_Factions_Update",
    "Kyber_Factions_Join",
    "Kyber_Factions_Leave",
    "Kyber_Factions_RankUp",
    "Kyber_Factions_RankDown"
}

for _, name in ipairs(networkStrings) do
    KYBER.Management.Network:Register(name)
end

-- Load all modules
KYBER.LoadAllModules()

-- Initialize gamemode
function GM:Initialize()
    print("[Kyber] Initializing gamemode...")
end

-- Player initial spawn
hook.Add("PlayerInitialSpawn", "KyberPlayerInit", function(ply)
    KYBER.Management.Timers:Create("KyberPlayerInit_" .. ply:SteamID64(), 1, 1, function()
        if IsValid(ply) then
            local success, err = pcall(function()
                -- Initialize player data
                if KYBER.Character then
                    KYBER.Character:Initialize(ply)
                end
                
                if KYBER.Inventory then
                    KYBER.Inventory:Initialize(ply)
                end
                
                if KYBER.Equipment then
                    KYBER.Equipment:Initialize(ply)
                end
                
                if KYBER.Banking then
                    KYBER.Banking:Initialize(ply)
                end
                
                if KYBER.Factions then
                    KYBER.Factions:Initialize(ply)
                end
            end)
            
            if not success then
                KYBER.Management.ErrorHandler:Handle(err, "Failed to initialize player: " .. ply:SteamID64())
            end
        end
    end)
end)

-- Player disconnect
hook.Add("PlayerDisconnected", "KyberPlayerCleanup", function(ply)
    local success, err = pcall(function()
        -- Save player data
        if KYBER.Character then
            KYBER.Character:Save(ply)
        end
        
        if KYBER.Inventory then
            KYBER.Inventory:Save(ply)
        end
        
        if KYBER.Equipment then
            KYBER.Equipment:Save(ply)
        end
        
        if KYBER.Banking then
            KYBER.Banking:Save(ply)
        end
        
        if KYBER.Factions then
            KYBER.Factions:Save(ply)
        end
    end)
    
    if not success then
        KYBER.Management.ErrorHandler:Handle(err, "Failed to cleanup player: " .. ply:SteamID64())
    end
end)

-- Shutdown
hook.Add("ShutDown", "KyberShutdown", function()
    -- Save all player data
    for _, ply in ipairs(player.GetAll()) do
        local success, err = pcall(function()
            if KYBER.Character then
                KYBER.Character:Save(ply)
            end
            
            if KYBER.Inventory then
                KYBER.Inventory:Save(ply)
            end
            
            if KYBER.Equipment then
                KYBER.Equipment:Save(ply)
            end
            
            if KYBER.Banking then
                KYBER.Banking:Save(ply)
            end
            
            if KYBER.Factions then
                KYBER.Factions:Save(ply)
            end
        end)
        
        if not success then
            KYBER.Management.ErrorHandler:Handle(err, "Failed to save player data on shutdown: " .. ply:SteamID64())
        end
    end
end)

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
    -- Handle commands
    if string.sub(text, 1, 1) == "!" then
        local cmd = string.lower(string.sub(text, 2))
        local args = {}
        
        -- Split command and arguments
        for arg in string.gmatch(cmd, "%S+") do
            table.insert(args, arg)
        end
        
        -- Remove command from args
        cmd = table.remove(args, 1)
        
        -- Handle specific commands
        if cmd == "help" then
            ply:ChatPrint("Available commands:")
            ply:ChatPrint("!help - Show this help message")
            ply:ChatPrint("!char - Open character menu")
            ply:ChatPrint("!inv - Open inventory")
            ply:ChatPrint("!bank - Open banking menu")
            ply:ChatPrint("!faction - Open faction menu")
            return ""
        elseif cmd == "char" then
            if KYBER.Character then
                KYBER.Character:OpenMenu(ply)
            end
            return ""
        elseif cmd == "inv" then
            if KYBER.Inventory then
                KYBER.Inventory:OpenMenu(ply)
            end
            return ""
        elseif cmd == "bank" then
            if KYBER.Banking then
                KYBER.Banking:OpenMenu(ply)
            end
            return ""
        elseif cmd == "faction" then
            if KYBER.Factions then
                KYBER.Factions:OpenMenu(ply)
            end
            return ""
        end
    end
    
    return text
end

print("[Kyber] Gamemode initialization complete")