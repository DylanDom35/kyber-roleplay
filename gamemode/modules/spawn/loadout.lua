-- kyber/gamemode/modules/spawn/loadout.lua

-- Ensure KYBER table exists
KYBER = KYBER or {}

if SERVER then
    -- Define spawn positions for factions and default neutral players
    KYBER.SpawnPoints = {
        ["jedi"] = Vector(100, 100, 100),
        ["sith"] = Vector(-100, 100, 100),
        ["imperial"] = Vector(0, -200, 100),
        ["bounty"] = Vector(300, 300, 100),
        ["default"] = Vector(0, 0, 100) -- fallback for unaffiliated players
    }

    -- Define faction-specific and default loadouts
    KYBER.FactionLoadouts = {
        ["jedi"] = {"weapon_physgun", "gmod_camera"},
        ["sith"] = {"weapon_physgun", "gmod_camera"},
        ["imperial"] = {"weapon_physgun", "weapon_pistol"},
        ["bounty"] = {"weapon_physgun", "weapon_crossbow"},
        ["default"] = {"weapon_physgun", "gmod_tool"}
    }

    hook.Add("PlayerSpawn", "KyberSpawnLogic", function(ply)
        local factionID = ply:GetNWString("kyber_faction", "")
        local isInFaction = KYBER.Factions and KYBER.Factions[factionID] ~= nil

        -- Choose spawn location
        local pos = isInFaction and KYBER.SpawnPoints[factionID] or KYBER.SpawnPoints["default"]
        timer.Simple(0.1, function()
            if IsValid(ply) then
                ply:SetPos(pos)
            end
        end)

        -- Assign tools/loadout
        timer.Simple(0.2, function()
            if not IsValid(ply) then return end
            ply:StripWeapons()

            local loadout = isInFaction and KYBER.FactionLoadouts[factionID] or KYBER.FactionLoadouts["default"]
            for _, wep in ipairs(loadout) do
                ply:Give(wep)
            end
        end)
    end)
end