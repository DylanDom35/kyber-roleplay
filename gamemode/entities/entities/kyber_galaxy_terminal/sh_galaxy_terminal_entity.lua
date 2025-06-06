-- kyber/entities/entities/kyber_galaxy_terminal/sh_galaxy_terminal_entity.lua
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    KYBER.EntityOptimization.InitializeEntity(self, "models/props_combine/breenconsole.mdl", SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetTerminalActive(true)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if not self:GetTerminalActive() then
        activator:ChatPrint("This galaxy terminal is offline.")
        return
    end
    self:OpenGalaxyUI(activator)
end

function ENT:OpenGalaxyUI(ply)
    -- Networking logic to open UI (placeholder)
    net.Start("Kyber_Galaxy_OpenTerminal")
    net.WriteEntity(self)
    net.Send(ply)
end

function ENT:OnRemove()
    KYBER.EntityOptimization.OptimizedCleanup(self, function(ent)
        -- Add any additional cleanup logic here if needed
    end)
end

function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then return end

    local ent = ents.Create(ClassName)
    ent:SetPos(tr.HitPos + tr.HitNormal * 10)
    ent:Spawn()
    ent:Activate()

    return ent
end

-- kyber/entities/entities/kyber_galaxy_terminal/cl_init.lua
include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos()
    local ang = self:GetAngles()
    
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    
    cam.Start3D2D(pos + ang:Up() * 2 + ang:Forward() * -8, ang, 0.1)
        if self:GetTerminalActive() then
            draw.RoundedBox(6, -100, -50, 200, 100, Color(0, 0, 0, 200))
            
            local termType = self:GetTerminalType()
            local title = termType == "spaceport" ? "Spaceport Terminal" : "Local Transport"
            
            draw.SimpleText(title, "DermaLarge", 0, -25, Color(100, 200, 255), TEXT_ALIGN_CENTER)
            draw.SimpleText("Press E to access", "DermaDefault", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            
            -- Animated indicator
            local pulse = math.sin(CurTime() * 2) * 0.5 + 0.5
            surface.SetDrawColor(100, 200, 255, 100 + pulse * 155)
            surface.DrawRect(-90, 20, 180, 2)
        else
            draw.SimpleText("OFFLINE", "DermaLarge", 0, 0, Color(255, 50, 50), TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end

-- kyber/entities/entities/kyber_galaxy_terminal/shared.lua
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Galaxy Terminal"
ENT.Author = "Kyber"
ENT.Spawnable = true
ENT.Category = "Kyber RP"

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "TerminalActive")
    self:NetworkVar("String", 0, "TerminalType")
end