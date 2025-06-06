AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    KYBER.EntityOptimization.InitializeEntity(self, "models/props_lab/monitor01b.mdl", SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetTerminalActive(true)
    self:SetAlarmActive(false)
    self:SetFailedAttempts(0)
    self:SetLastUser("")
    self.Logs = {}

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then phys:Wake() end
end

function ENT:Use(activator, caller)
    if not IsValid(caller) or not caller:IsPlayer() then return end
    if not self:GetTerminalActive() then
        caller:ChatPrint("This terminal is offline.")
        return
    end
    net.Start("Kyber_OpenTerminalUI")
    net.WriteEntity(self)
    net.Send(caller)
end

util.AddNetworkString("Kyber_OpenTerminalUI")
util.AddNetworkString("Kyber_Terminal_SetLink")
util.AddNetworkString("Kyber_Terminal_SubmitCode")
util.AddNetworkString("Kyber_Terminal_AdminOverride")
util.AddNetworkString("Kyber_Terminal_Alarm")
util.AddNetworkString("Kyber_Terminal_RequestLogs")
util.AddNetworkString("Kyber_Terminal_SendLogs")

-- Link door + set code
net.Receive("Kyber_Terminal_SetLink", function(len, ply)
    local terminal = net.ReadEntity()
    local door = net.ReadEntity()
    local code = net.ReadString()
    if not IsValid(terminal) or not IsValid(door) or not code then return end
    if door:GetClass() ~= "prop_door_rotating" and door:GetClass() ~= "func_door" then return end
    terminal.Door = door
    terminal.Code = code
    terminal.Logs = terminal.Logs or {}
    table.insert(terminal.Logs, {time=CurTime(), user=ply:Nick(), action="SetLink", code=code})
    ply:ChatPrint("[Kyber Terminal] Door linked and code set.")
end)

-- Player entering code
net.Receive("Kyber_Terminal_SubmitCode", function(len, ply)
    local terminal = net.ReadEntity()
    local inputCode = net.ReadString()
    if not IsValid(terminal) or not terminal.Door then return end
    terminal:SetLastUser(ply:Nick())
    terminal.Logs = terminal.Logs or {}
    if inputCode == terminal.Code then
        terminal.Door:Fire("Unlock")
        terminal.Door:Fire("Open")
        ply:ChatPrint("[Kyber Terminal] Access granted.")
        terminal:SetFailedAttempts(0)
        table.insert(terminal.Logs, {time=CurTime(), user=ply:Nick(), action="AccessGranted"})
        if terminal:GetAlarmActive() then
            terminal:SetAlarmActive(false)
            -- Optionally notify admins
        end
    else
        ply:ChatPrint("[Kyber Terminal] Access denied.")
        terminal:SetFailedAttempts(terminal:GetFailedAttempts() + 1)
        table.insert(terminal.Logs, {time=CurTime(), user=ply:Nick(), action="AccessDenied", code=inputCode})
        if terminal:GetFailedAttempts() >= 3 and not terminal:GetAlarmActive() then
            terminal:SetAlarmActive(true)
            terminal:EmitSound("ambient/alarms/klaxon1.wav")
            -- Optionally notify admins
            net.Start("Kyber_Terminal_Alarm")
            net.WriteEntity(terminal)
            net.Broadcast()
        end
    end
end)

-- Admin override
net.Receive("Kyber_Terminal_AdminOverride", function(len, ply)
    local terminal = net.ReadEntity()
    if not IsValid(terminal) or not ply:IsAdmin() then return end
    if terminal.Door then
        terminal.Door:Fire("Unlock")
        terminal.Door:Fire("Open")
        ply:ChatPrint("[Kyber Terminal] Admin override: Door opened.")
        terminal:SetAlarmActive(false)
        terminal:SetFailedAttempts(0)
        terminal.Logs = terminal.Logs or {}
        table.insert(terminal.Logs, {time=CurTime(), user=ply:Nick(), action="AdminOverride"})
    end
end)

-- Log request
net.Receive("Kyber_Terminal_RequestLogs", function(len, ply)
    local terminal = net.ReadEntity()
    if not IsValid(terminal) or not ply:IsAdmin() then return end
    net.Start("Kyber_Terminal_SendLogs")
    net.WriteEntity(terminal)
    net.WriteTable(terminal.Logs or {})
    net.Send(ply)
end)

function ENT:OnRemove()
    KYBER.EntityOptimization.OptimizedCleanup(self, function(ent)
        ent.Logs = nil
    end)
end
