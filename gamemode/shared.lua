-- kyber/gamemode/shared.lua

-- Gamemode info
GM.Name = "Kyber RP"
GM.Author = "Kyber Development Team"
GM.Email = ""
GM.Website = ""

-- Initialize KYBER table
KYBER = KYBER or {}

-- Basic faction definitions (shared between client and server)
KYBER.Factions = {
    ["jedi"] = {
        name = "Jedi Order",
        color = Color(100, 200, 255),
        description = "Guardians of peace and justice",
        ranks = {"Youngling", "Padawan", "Knight", "Master"}
    },
    ["sith"] = {
        name = "Sith Order",
        color = Color(255, 50, 50),
        description = "Dark side Force users",
        ranks = {"Acolyte", "Apprentice", "Lord", "Darth"}
    },
    ["imperial"] = {
        name = "Imperial Remnant",
        color = Color(150, 150, 150),
        description = "Remains of the Galactic Empire",
        ranks = {"Trooper", "Sergeant", "Lieutenant", "Captain", "Admiral"}
    },
    ["rebel"] = {
        name = "Rebel Alliance",
        color = Color(255, 150, 50),
        description = "Freedom fighters",
        ranks = {"Recruit", "Fighter", "Commander", "General"}
    },
    ["bounty"] = {
        name = "Bounty Hunters",
        color = Color(200, 200, 50),
        description = "Independent contractors",
        ranks = {"Novice", "Hunter", "Veteran", "Legend"}
    },
    ["mandalorian"] = {
        name = "Mandalorian Clans",
        color = Color(100, 255, 100),
        description = "Warrior culture",
        ranks = {"Foundling", "Warrior", "Veteran", "Clan Leader"}
    }
}

-- Utility function to set faction
function KYBER:SetFaction(ply, factionID)
    if not IsValid(ply) then return end

    local faction = self.Factions and self.Factions[factionID]
    if faction then
        ply:SetNWString("kyber_faction", factionID)
        ply:SetNWString("kyber_rank", faction.ranks[1]) -- Set to lowest rank

        if SERVER then
            ply:ChatPrint("You joined the " .. faction.name)
        end
    else
        ply:SetNWString("kyber_faction", "")
        ply:SetNWString("kyber_rank", "")
        if SERVER then
            ply:ChatPrint("Faction not found or invalid.")
        end
    end
end