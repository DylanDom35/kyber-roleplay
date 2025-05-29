-- kyber/entities/entities/kyber_galaxy_terminal/init.lua
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_combine/combine_interface001.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
    
    -- Terminal settings
    self:SetTerminalActive(true)
    self:SetTerminalType("spaceport") -- Can be "spaceport" or "local"
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if not self:GetTerminalActive() then 
        activator:ChatPrint("This terminal is offline.")
        return 
    end
    
    -- Send appropriate network message based on terminal type
    if self:GetTerminalType() == "spaceport" then
        net.Start("Kyber_OpenGalaxyMap")
        net.Send(activator)
    else
        net.Start("Kyber_OpenLocalTravel")
        net.Send(activator)
    end
    
    -- Sound effect
    self:EmitSound("buttons/button3.wav")
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