-- kyber/entities/entities/kyber_crafting_station/sh_crafting_station_entity.lua
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    KYBER.EntityOptimization.InitializeEntity(self, "models/props_c17/FurnitureBoiler001a.mdl", SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetStationActive(true)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if not self:GetStationActive() then
        activator:ChatPrint("This crafting station is offline.")
        return
    end
    self:OpenCraftingUI(activator)
end

function ENT:OpenCraftingUI(ply)
    -- Networking logic to open UI (placeholder)
    net.Start("Kyber_Crafting_OpenStation")
    net.WriteEntity(self)
    net.Send(ply)
end

function ENT:OnRemove()
    KYBER.EntityOptimization.OptimizedCleanup(self, function(ent)
        -- Add any additional cleanup logic here if needed
    end)
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
    self:NetworkVar("Bool", 0, "StationActive")
end