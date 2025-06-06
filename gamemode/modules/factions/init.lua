-- Factions module
local Factions = {}
Factions.__index = Factions

-- Factions module configuration
KYBER.Factions.Config = {
    MaxFactionLevel = 100,
    ExperiencePerAction = 10,
    ExperienceMultiplier = 1.0,
    Factions = {
        ["jedi"] = {
            name = "Jedi Order",
            description = "Guardians of peace and justice",
            color = Color(0, 150, 255),
            ranks = {
                [1] = { name = "Initiate", color = Color(200, 200, 200) },
                [2] = { name = "Padawan", color = Color(150, 150, 255) },
                [3] = { name = "Knight", color = Color(100, 100, 255) },
                [4] = { name = "Master", color = Color(50, 50, 255) },
                [5] = { name = "Grand Master", color = Color(0, 0, 255) }
            },
            requirements = {
                forceAlignment = "light",
                minForceLevel = 10
            },
            benefits = {
                forceRegenMultiplier = 1.2,
                forceCostReduction = 0.9
            }
        },
        ["sith"] = {
            name = "Sith Order",
            description = "Seekers of power and knowledge",
            color = Color(255, 0, 0),
            ranks = {
                [1] = { name = "Acolyte", color = Color(255, 200, 200) },
                [2] = { name = "Apprentice", color = Color(255, 150, 150) },
                [3] = { name = "Lord", color = Color(255, 100, 100) },
                [4] = { name = "Darth", color = Color(255, 50, 50) },
                [5] = { name = "Dark Lord", color = Color(255, 0, 0) }
            },
            requirements = {
                forceAlignment = "dark",
                minForceLevel = 10
            },
            benefits = {
                forceDamageMultiplier = 1.2,
                forceCostReduction = 0.9
            }
        },
        ["imperial"] = {
            name = "Imperial Remnant",
            description = "Maintainers of order and security",
            color = Color(100, 100, 100),
            ranks = {
                [1] = { name = "Recruit", color = Color(200, 200, 200) },
                [2] = { name = "Trooper", color = Color(150, 150, 150) },
                [3] = { name = "Officer", color = Color(100, 100, 100) },
                [4] = { name = "Commander", color = Color(50, 50, 50) },
                [5] = { name = "Grand Moff", color = Color(0, 0, 0) }
            },
            requirements = {
                minReputation = 0
            },
            benefits = {
                weaponDamageMultiplier = 1.1,
                armorProtectionMultiplier = 1.1
            }
        },
        ["rebel"] = {
            name = "Rebel Alliance",
            description = "Fighters for freedom and justice",
            color = Color(0, 255, 0),
            ranks = {
                [1] = { name = "Recruit", color = Color(200, 255, 200) },
                [2] = { name = "Soldier", color = Color(150, 255, 150) },
                [3] = { name = "Officer", color = Color(100, 255, 100) },
                [4] = { name = "Commander", color = Color(50, 255, 50) },
                [5] = { name = "General", color = Color(0, 255, 0) }
            },
            requirements = {
                minReputation = 0
            },
            benefits = {
                weaponAccuracyMultiplier = 1.1,
                movementSpeedMultiplier = 1.1
            }
        }
    }
}

-- Initialize the module
function Factions:Initialize()
    print("[Kyber] Initializing Factions module")
    
    -- Register network strings
    util.AddNetworkString("Kyber_Factions_Open")
    util.AddNetworkString("Kyber_Factions_Update")
    util.AddNetworkString("Kyber_Factions_Join")
    util.AddNetworkString("Kyber_Factions_Leave")
    util.AddNetworkString("Kyber_Factions_Promote")
    util.AddNetworkString("Kyber_Factions_Demote")
    
    -- Initialize faction data
    self.Factions = {
        ["republic"] = {
            name = "Galactic Republic",
            ranks = {
                {name = "Citizen", level = 1},
                {name = "Trooper", level = 2},
                {name = "Sergeant", level = 3},
                {name = "Lieutenant", level = 4},
                {name = "Captain", level = 5},
                {name = "Commander", level = 6},
                {name = "General", level = 7}
            }
        },
        ["empire"] = {
            name = "Galactic Empire",
            ranks = {
                {name = "Citizen", level = 1},
                {name = "Stormtrooper", level = 2},
                {name = "Sergeant", level = 3},
                {name = "Lieutenant", level = 4},
                {name = "Captain", level = 5},
                {name = "Commander", level = 6},
                {name = "Admiral", level = 7}
            }
        },
        ["neutral"] = {
            name = "Neutral",
            ranks = {
                {name = "Citizen", level = 1}
            }
        }
    }
    
    -- Load faction data
    self:LoadFactions()
end

-- Load faction data
function Factions:LoadFactions()
    -- TODO: Implement faction loading from database
    print("[Kyber] Loading faction data")
end

-- Get player faction
function Factions:GetFaction(ply)
    if not IsValid(ply) then return nil end
    
    -- TODO: Implement faction retrieval
    return "neutral"
end

-- Get player rank
function Factions:GetRank(ply)
    if not IsValid(ply) then return nil end
    
    -- TODO: Implement rank retrieval
    return "Citizen"
end

-- Join faction
function Factions:Join(ply, faction)
    if not IsValid(ply) then return false end
    
    -- TODO: Implement faction joining
    print("[Kyber] " .. ply:Nick() .. " joining faction: " .. faction)
    return true
end

-- Leave faction
function Factions:Leave(ply)
    if not IsValid(ply) then return false end
    
    -- TODO: Implement faction leaving
    print("[Kyber] " .. ply:Nick() .. " leaving faction")
    return true
end

-- Promote player
function Factions:Promote(ply)
    if not IsValid(ply) then return false end
    
    -- TODO: Implement player promotion
    print("[Kyber] Promoting " .. ply:Nick())
    return true
end

-- Demote player
function Factions:Demote(ply)
    if not IsValid(ply) then return false end
    
    -- TODO: Implement player demotion
    print("[Kyber] Demoting " .. ply:Nick())
    return true
end

-- Check if faction exists
function Factions:Exists(faction)
    return self.Factions[faction] ~= nil
end

-- Get faction data
function Factions:GetData(faction)
    return self.Factions[faction]
end

-- Register the module
KYBER.Modules.factions = Factions
return Factions

-- Initialize factions module
KYBER.Factions = KYBER.Factions or {}

-- Include factions system files
include("kyber/gamemode/modules/factions/core.lua")
include("kyber/gamemode/modules/factions/ranks.lua")
include("kyber/gamemode/modules/factions/permissions.lua")

-- Register network strings
KYBER.Management.Network:Register("Kyber_Factions_Update")
KYBER.Management.Network:Register("Kyber_Factions_Join")
KYBER.Management.Network:Register("Kyber_Factions_Leave")
KYBER.Management.Network:Register("Kyber_Factions_Promote")
KYBER.Management.Network:Register("Kyber_Factions_Demote")

-- Initialize factions system
local success, err = pcall(function()
    -- Create factions directory if it doesn't exist
    if not file.Exists("kyber/factions", "DATA") then
        file.CreateDir("kyber/factions")
    end
end)

if not success then
    KYBER.Management.ErrorHandler:Handle(err, "Failed to initialize factions system")
end

-- Cleanup function
function KYBER.Factions:Cleanup()
    -- Add any cleanup code here
end

function KYBER.Factions:Save(ply)
    if not IsValid(ply) or not ply.KyberFactions then return end
    local path = "kyber/factions/" .. ply:SteamID64() .. ".json"
    -- Create backup
    if file.Exists(path, "DATA") then
        file.Write(path .. ".backup", file.Read(path, "DATA"))
    end
    -- Write new data (placeholder)
    file.Write(path, util.TableToJSON(ply.KyberFactions))
end 