-- kyber/gamemode/cl_init.lua
-- Minimal test version

-- Include shared code first
include("shared.lua")

-- Test that KYBER exists on client
if KYBER then
    print("[Kyber] Client: KYBER table initialized successfully")
    if KYBER.Factions then
        print("[Kyber] Client: Factions loaded:", table.Count(KYBER.Factions), "factions")
    end
else
    print("[Kyber] Client: ERROR: KYBER table not initialized!")
end

-- Safe include function for client
local function safeInclude(path)
    local success, err = pcall(include, path)
    if not success then
        print("[Kyber] Client ERROR loading " .. path .. ": " .. tostring(err))
    else
        print("[Kyber] Client: Successfully loaded " .. path)
    end
end

-- Include client-side modules
safeInclude("modules/character/sheet.lua")

print("[Kyber] Client initialization complete")