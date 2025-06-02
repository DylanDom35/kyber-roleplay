-- kyber/gamemode/modules/playerdata/core.lua

-- Ensure KYBER table exists
KYBER = KYBER or {}

-- Shared interface
KYBER.PlayerData = {}

-- Defaults
KYBER.PlayerData.Defaults = {
    credits = 100,
    rep_jedi = 0,
    rep_empire = 0,
    crafting_level = 1,
    is_force_sensitive = false
}

-- Get a player's data safely
function KYBER:GetPlayerData(ply, key)
    if not IsValid(ply) or not key then return nil end
    local val = ply:GetPData("kyber_" .. key)
    if val == nil then
        return KYBER.PlayerData.Defaults[key]
    end

    if val == "true" then return true end
    if val == "false" then return false end
    local num = tonumber(val)
    return num or val
end

-- Set and store data persistently
function KYBER:SetPlayerData(ply, key, value)
    if not IsValid(ply) or not key then return end
    ply:SetPData("kyber_" .. key, tostring(value))
end

if SERVER then
    -- Load player data into NWVars for client access
    hook.Add("PlayerInitialSpawn", "KyberLoadPlayerData", function(ply)
        timer.Simple(1, function()
            if not IsValid(ply) then return end
            
            for key, _ in pairs(KYBER.PlayerData.Defaults) do
                local val = KYBER:GetPlayerData(ply, key)
                ply:SetNWString("kyberdata_" .. key, tostring(val))
            end
        end)
    end)
end