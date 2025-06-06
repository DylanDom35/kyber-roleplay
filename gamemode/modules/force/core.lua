-- Initialize force system
KYBER.Force = KYBER.Force or {}
KYBER.Force.SensitivePlayers = {}

-- Load force sensitive players
local success, err = pcall(function()
    local data = KYBER.Management.File:Read("force_sensitive.json")
    if data then
        KYBER.Force.SensitivePlayers = data
    end
end)

if not success then
    KYBER.Management.ErrorHandler:Handle(err, "Failed to load force sensitive players")
end

-- Save force sensitive players periodically
KYBER.Management.Timers:Create("SaveForceSensitive", 300, 0, function()
    local success, err = pcall(function()
        KYBER.Management.File:Write("force_sensitive.json", KYBER.Force.SensitivePlayers)
    end)
    
    if not success then
        KYBER.Management.ErrorHandler:Handle(err, "Failed to save force sensitive players")
    end
end)

-- Register network strings
KYBER.Management.Network:Register("Kyber_Force_UpdateStatus")
KYBER.Management.Network:Register("Kyber_Force_RequestStatus")

-- Handle force status requests
net.Receive("Kyber_Force_RequestStatus", function(len, ply)
    local success, err = pcall(function()
        net.Start("Kyber_Force_UpdateStatus")
        net.WriteBool(KYBER.Force:IsForceSensitive(ply))
        net.Send(ply)
    end)
    
    if not success then
        KYBER.Management.ErrorHandler:Handle(err, "Failed to send force status to " .. ply:SteamID64())
    end
end)

-- Force sensitivity functions
function KYBER.Force:IsForceSensitive(ply)
    return KYBER.Force.SensitivePlayers[ply:SteamID64()] or false
end

function KYBER.Force:SetForceSensitive(ply, status)
    local success, err = pcall(function()
        KYBER.Force.SensitivePlayers[ply:SteamID64()] = status
        
        -- Notify client
        net.Start("Kyber_Force_UpdateStatus")
        net.WriteBool(status)
        net.Send(ply)
        
        -- Save immediately
        KYBER.Management.File:Write("force_sensitive.json", KYBER.Force.SensitivePlayers)
    end)
    
    if not success then
        KYBER.Management.ErrorHandler:Handle(err, "Failed to set force sensitivity for " .. ply:SteamID64())
        return false
    end
    
    return true
end

-- Player cleanup
KYBER.Management.Hooks:Add("PlayerDisconnected", "ForceCleanup", function(ply)
    local success, err = pcall(function()
        -- Save force sensitive status before player disconnects
        if KYBER.Force:IsForceSensitive(ply) then
            KYBER.Management.File:Write("force_sensitive.json", KYBER.Force.SensitivePlayers)
        end
    end)
    
    if not success then
        KYBER.Management.ErrorHandler:Handle(err, "Failed to cleanup force data for " .. ply:SteamID64())
    end
end)

-- Cleanup function
function KYBER.Force:Cleanup()
    KYBER.Management.Timers:Remove("SaveForceSensitive")
    KYBER.Management.Hooks:Remove("ForceCleanup")
end 