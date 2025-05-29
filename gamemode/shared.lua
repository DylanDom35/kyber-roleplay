-- Kyber Roleplay Framework
-- Shared configuration

GM.Name = "Kyber Roleplay"
GM.Author = "Kyber Development Team"
GM.Email = ""
GM.Website = ""
GM.Version = "1.0.0"

-- Initialize framework
KYBER = KYBER or {}

-- Shared faction definitions
KYBER.Factions = {
    ["republic"] = {
        name = "Galactic Republic",
        color = Color(100, 100, 255),
        ranks = {"Citizen", "Representative", "Senator", "Chancellor"},
        canUseForce = false
    },
    
    ["imperial"] = {
        name = "Imperial Remnant", 
        color = Color(150, 150, 150),
        ranks = {"Trooper", "Corporal", "Sergeant", "Lieutenant", "Captain", "Major", "Colonel", "Admiral"},
        canUseForce = false
    },
    
    ["rebel"] = {
        name = "Rebel Alliance",
        color = Color(255, 100, 100),
        ranks = {"Recruit", "Private", "Lieutenant", "Captain", "Major", "General"},
        canUseForce = false
    },
    
    ["jedi"] = {
        name = "Jedi Order",
        color = Color(100, 255, 100),
        ranks = {"Youngling", "Padawan", "Knight", "Master", "Council Member"},
        canUseForce = true
    },
    
    ["sith"] = {
        name = "Sith Order",
        color = Color(255, 50, 50),
        ranks = {"Acolyte", "Apprentice", "Lord", "Darth"},
        canUseForce = true
    },
    
    ["mandalorian"] = {
        name = "Mandalorian Clans",
        color = Color(255, 200, 100),
        ranks = {"Foundling", "Warrior", "Veteran", "Chieftain", "Mand'alor"},
        canUseForce = false
    },
    
    ["bounty"] = {
        name = "Bounty Hunters Guild",
        color = Color(200, 150, 100),
        ranks = {"Novice", "Hunter", "Veteran", "Master", "Guild Leader"},
        canUseForce = false
    },
    
    ["hutt"] = {
        name = "Hutt Cartel",
        color = Color(150, 255, 100),
        ranks = {"Thug", "Enforcer", "Lieutenant", "Underboss", "Kajidic Head"},
        canUseForce = false
    }
}

-- Game rules
function GM:PlayerLoadout(ply)
    ply:SetMaxHealth(100)
    ply:SetHealth(100)
    ply:SetArmor(0)
    
    -- Give basic tools
    ply:Give("weapon_physgun")
    ply:Give("gmod_tool")
    ply:Give("weapon_physcannon")
end

function GM:PlayerSpawn(ply)
    player_manager.SetPlayerClass(ply, "player_default")
    
    -- Set model based on faction/preference
    local model = ply:GetInfo("cl_playermodel") or "models/player/group01/male_02.mdl"
    ply:SetModel(model)
    
    self:PlayerLoadout(ply)
end

function GM:PlayerInitialSpawn(ply)
    -- Initialize character name
    if not ply:GetNWString("kyber_name") or ply:GetNWString("kyber_name") == "" then
        ply:SetNWString("kyber_name", ply:Nick())
    end
end

-- Disable fall damage for RP
function GM:GetFallDamage(ply, speed)
    return 0
end

-- Custom chat system hook placeholder
function GM:PlayerSay(ply, text, teamChat)
    -- Let modules handle chat processing
    return ""
end

print("[Kyber] Shared configuration loaded")