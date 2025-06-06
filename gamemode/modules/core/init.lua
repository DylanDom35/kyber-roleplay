-- Core module
local Core = {}
Core.__index = Core

-- Initialize the module
function Core:Initialize()
    print("[Kyber] Initializing Core module")
    
    -- Register network strings
    util.AddNetworkString("Kyber_Core_Message")
    util.AddNetworkString("Kyber_Core_Notification")
    util.AddNetworkString("Kyber_Core_Error")
    
    -- Initialize core data
    self.Config = {
        Debug = false,
        Version = "1.0.0",
        MaxPlayers = 32,
        DefaultCredits = 1000
    }
    
    -- Initialize SQL system
    self:InitializeSQL()
end

-- Initialize SQL system
function Core:InitializeSQL()
    print("[Kyber] SQL system initialized")
    -- TODO: Implement SQL initialization
end

-- Send message to player
function Core:SendMessage(ply, message)
    if not IsValid(ply) then return end
    
    net.Start("Kyber_Core_Message")
    net.WriteString(message)
    net.Send(ply)
end

-- Send notification to player
function Core:SendNotification(ply, title, message, type)
    if not IsValid(ply) then return end
    
    net.Start("Kyber_Core_Notification")
    net.WriteString(title)
    net.WriteString(message)
    net.WriteString(type or "info")
    net.Send(ply)
end

-- Send error to player
function Core:SendError(ply, message)
    if not IsValid(ply) then return end
    
    net.Start("Kyber_Core_Error")
    net.WriteString(message)
    net.Send(ply)
end

-- Debug print
function Core:Debug(message)
    if self.Config.Debug then
        print("[Kyber Debug] " .. message)
    end
end

-- Register the module
KYBER.Modules.core = Core
return Core 