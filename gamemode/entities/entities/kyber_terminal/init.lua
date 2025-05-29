AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_lab/reciever01b.mdl") -- Change to a sci-fi terminal later
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self.Door = nil
    self.Code = nil

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then phys:Wake() end
end

function ENT:Use(activator, caller)
    if not IsValid(caller) or not caller:IsPlayer() then return end

    net.Start("Kyber_OpenTerminalUI")
    net.WriteEntity(self)
    net.Send(caller)
end

util.AddNetworkString("Kyber_OpenTerminalUI")
util.AddNetworkString("Kyber_Terminal_SetLink")
util.AddNetworkString("Kyber_Terminal_SubmitCode")

-- Link door + set code
net.Receive("Kyber_Terminal_SetLink", function(len, ply)
    local terminal = net.ReadEntity()
    local door = net.ReadEntity()
    local code = net.ReadString()

    if not IsValid(terminal) or not IsValid(door) or not code then return end
    if door:GetClass() ~= "prop_door_rotating" and door:GetClass() ~= "func_door" then return end

    terminal.Door = door
    terminal.Code = code
    ply:ChatPrint("[Kyber Terminal] Door linked and code set.")
end)

-- Player entering code
net.Receive("Kyber_Terminal_SubmitCode", function(len, ply)
    local terminal = net.ReadEntity()
    local inputCode = net.ReadString()

    if not IsValid(terminal) or not terminal.Door then return end

    if inputCode == terminal.Code then
        terminal.Door:Fire("Unlock")
        terminal.Door:Fire("Open")
        ply:ChatPrint("[Kyber Terminal] Access granted.")
    else
        ply:ChatPrint("[Kyber Terminal] Access denied.")
    end
end)
