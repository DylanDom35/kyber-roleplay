-- kyber/entities/entities/kyber_crafting_station/init.lua
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    local stationType = self:GetStationType() or "armor_bench"
    local stationData = KYBER.Crafting.Stations[stationType]
    
    if stationData then
        self:SetModel(stationData.model)
    else
        self:SetModel("models/props_c17/FurnitureTable002a.mdl")
    end
    
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
    
    -- Default to armor bench
    if not self:GetStationType() or self:GetStationType() == "" then
        self:SetStationType("armor_bench")
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    -- Check if player is already crafting
    if activator.CraftingData then
        activator:ChatPrint("You are already crafting something!")
        return
    end
    
    -- Open crafting menu
    net.Start("Kyber_Crafting_Open")
    net.WriteEntity(self)
    net.WriteString(self:GetStationType())
    net.Send(activator)
    
    self:EmitSound("buttons/button1.wav")
end

function ENT:OnRemove()
    -- Cancel any crafting using this station
    for _, ply in ipairs(player.GetAll()) do
        if ply.CraftingData and ply.CraftingData.station == self then
            KYBER.Crafting:CancelCrafting(ply)
        end
    end
end

-- kyber/entities/entities/kyber_crafting_station/cl_init.lua
include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos()
    local ang = self:GetAngles()
    
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    
    local stationData = KYBER.Crafting.Stations[self:GetStationType()]
    local name = stationData and stationData.name or "Crafting Station"
    
    cam.Start3D2D(pos + ang:Up() * 20, ang, 0.1)
        draw.RoundedBox(6, -150, -50, 300, 100, Color(0, 0, 0, 200))
        
        draw.SimpleText(name, "DermaLarge", 0, -20, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        draw.SimpleText("Press E to craft", "DermaDefault", 0, 10, Color(200, 200, 200), TEXT_ALIGN_CENTER)
        
        -- Show if someone is using it
        local inUse = false
        for _, ply in ipairs(player.GetAll()) do
            if ply.CraftingData and ply.CraftingData.station == self then
                inUse = true
                break
            end
        end
        
        if inUse then
            local pulse = math.sin(CurTime() * 2) * 0.5 + 0.5
            draw.SimpleText("IN USE", "DermaDefault", 0, 30, Color(255, 100 + pulse * 155, 100), TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end

-- kyber/entities/entities/kyber_crafting_station/shared.lua
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Crafting Station"
ENT.Author = "Kyber"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Kyber RP"

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "StationType")
end