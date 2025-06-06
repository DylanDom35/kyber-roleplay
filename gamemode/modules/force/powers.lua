-- Initialize force powers system
KYBER.ForcePowers = KYBER.ForcePowers or {}
KYBER.ForcePowers.PlayerPowers = {}

-- Load force powers data
local success, err = pcall(function()
    local data = KYBER.Management.File:Read("force_powers.json")
    if data then
        KYBER.ForcePowers.PlayerPowers = data
    end
end)

if not success then
    KYBER.Management.ErrorHandler:Handle(err, "Failed to load force powers data")
end

-- Save force powers periodically
KYBER.Management.Timers:Create("SaveForcePowers", 300, 0, function()
    local success, err = pcall(function()
        KYBER.Management.File:Write("force_powers.json", KYBER.ForcePowers.PlayerPowers)
    end)
    
    if not success then
        KYBER.Management.ErrorHandler:Handle(err, "Failed to save force powers data")
    end
end)

-- Register network strings
KYBER.Management.Network:Register("Kyber_ForcePowers_Update")
KYBER.Management.Network:Register("Kyber_ForcePowers_Request")
KYBER.Management.Network:Register("Kyber_ForcePowers_Use")

-- Handle force powers requests
net.Receive("Kyber_ForcePowers_Request", function(len, ply)
    local success, err = pcall(function()
        net.Start("Kyber_ForcePowers_Update")
        net.WriteTable(KYBER.ForcePowers:GetPlayerPowers(ply))
        net.Send(ply)
    end)
    
    if not success then
        KYBER.Management.ErrorHandler:Handle(err, "Failed to send force powers to " .. ply:SteamID64())
    end
end)

-- Handle force power usage
net.Receive("Kyber_ForcePowers_Use", function(len, ply)
    local success, err = pcall(function()
        local powerName = net.ReadString()
        local target = net.ReadEntity()
        
        if not KYBER.Force:IsForceSensitive(ply) then
            ply:ChatPrint("You are not force sensitive!")
            return
        end
        
        if not KYBER.ForcePowers:HasPower(ply, powerName) then
            ply:ChatPrint("You don't have that force power!")
            return
        end
        
        -- Execute power
        KYBER.ForcePowers:ExecutePower(ply, powerName, target)
    end)
    
    if not success then
        KYBER.Management.ErrorHandler:Handle(err, "Failed to execute force power for " .. ply:SteamID64())
        ply:ChatPrint("Failed to execute force power!")
    end
end)

-- Force powers functions
function KYBER.ForcePowers:GetPlayerPowers(ply)
    return KYBER.ForcePowers.PlayerPowers[ply:SteamID64()] or {}
end

function KYBER.ForcePowers:HasPower(ply, powerName)
    local powers = self:GetPlayerPowers(ply)
    return powers[powerName] or false
end

function KYBER.ForcePowers:AddPower(ply, powerName)
    local success, err = pcall(function()
        if not KYBER.ForcePowers.PlayerPowers[ply:SteamID64()] then
            KYBER.ForcePowers.PlayerPowers[ply:SteamID64()] = {}
        end
        
        KYBER.ForcePowers.PlayerPowers[ply:SteamID64()][powerName] = true
        
        -- Notify client
        net.Start("Kyber_ForcePowers_Update")
        net.WriteTable(self:GetPlayerPowers(ply))
        net.Send(ply)
        
        -- Save immediately
        KYBER.Management.File:Write("force_powers.json", KYBER.ForcePowers.PlayerPowers)
    end)
    
    if not success then
        KYBER.Management.ErrorHandler:Handle(err, "Failed to add force power for " .. ply:SteamID64())
        return false
    end
    
    return true
end

function KYBER.ForcePowers:ExecutePower(ply, powerName, target)
    -- Implement power execution logic here
    -- This is just a placeholder
    ply:ChatPrint("Executed " .. powerName .. " on " .. tostring(target))
end

-- Player cleanup
KYBER.Management.Hooks:Add("PlayerDisconnected", "ForcePowersCleanup", function(ply)
    local success, err = pcall(function()
        -- Save force powers before player disconnects
        if KYBER.ForcePowers.PlayerPowers[ply:SteamID64()] then
            KYBER.Management.File:Write("force_powers.json", KYBER.ForcePowers.PlayerPowers)
        end
    end)
    
    if not success then
        KYBER.Management.ErrorHandler:Handle(err, "Failed to cleanup force powers for " .. ply:SteamID64())
    end
end)

-- Cleanup function
function KYBER.ForcePowers:Cleanup()
    KYBER.Management.Timers:Remove("SaveForcePowers")
    KYBER.Management.Hooks:Remove("ForcePowersCleanup")
end 