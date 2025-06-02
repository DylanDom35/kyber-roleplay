-- kyber/gamemode/init.lua
-- Minimal test version

-- Initialize the KYBER table first
KYBER = KYBER or {}

-- Add shared files for client download
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("modules/character/sheet.lua")

-- Include shared code first (this sets up KYBER table and factions)
include("shared.lua")

-- Test that KYBER exists
if KYBER then
    print("[Kyber] KYBER table initialized successfully")
    if KYBER.Factions then
        print("[Kyber] Factions loaded:", table.Count(KYBER.Factions), "factions")
    end
else
    print("[Kyber] ERROR: KYBER table not initialized!")
end

-- Include core modules one by one with error checking
local function safeInclude(path)
    local success, err = pcall(include, path)
    if not success then
        print("[Kyber] ERROR loading " .. path .. ": " .. tostring(err))
    else
        print("[Kyber] Successfully loaded " .. path)
    end
end

-- Load modules in order
safeInclude("modules/playerdata/core.lua")
safeInclude("modules/spawn/loadout.lua") 
safeInclude("modules/character/sheet.lua")

print("[Kyber] Server initialization complete")