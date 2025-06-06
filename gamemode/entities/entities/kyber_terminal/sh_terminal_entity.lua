-- DEPRECATED: Use init.lua/shared.lua for kyber_terminal entity logic. This file is kept for reference only.
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    KYBER.EntityOptimization.InitializeEntity(self, "models/props_lab/monitor01b.mdl", SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetTerminalActive(true)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if not self:GetTerminalActive() then
        activator:ChatPrint("This terminal is offline.")
        return
    end
    self:OpenTerminalUI(activator)
end

function ENT:OpenTerminalUI(ply)
    -- Networking logic to open UI (placeholder)
    net.Start("Kyber_Terminal_Open")
    net.WriteEntity(self)
    net.Send(ply)
end

function ENT:OnRemove()
    KYBER.EntityOptimization.OptimizedCleanup(self, function(ent)
        -- Add any additional cleanup logic here if needed
    end)
end

-- shared.lua
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Terminal"
ENT.Author = "Kyber"
ENT.Spawnable = true
ENT.Category = "Kyber RP"

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "TerminalActive")
end 