-- kyber/entities/entities/kyber_dropped_item/sh_dropped_item_entity.lua
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    KYBER.EntityOptimization.InitializeEntity(self, self.Model or "models/props_junk/wood_crate001a.mdl", SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetItemActive(true)
    self:SetItemID(self.ItemID or "")
    self:SetItemAmount(self.ItemAmount or 1)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if not self:GetItemActive() then
        activator:ChatPrint("This item cannot be picked up.")
        return
    end
    self:PickupItem(activator)
end

function ENT:PickupItem(ply)
    -- Add item to player's inventory (placeholder logic)
    net.Start("Kyber_Inventory_PickupItem")
    net.WriteEntity(self)
    net.Send(ply)
    self:Remove()
end

function ENT:OnRemove()
    KYBER.EntityOptimization.OptimizedCleanup(self, function(ent)
        -- Add any additional cleanup logic here if needed
    end)
end

-- kyber/entities/entities/kyber_dropped_item/cl_init.lua
include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos()
    local ang = self:GetAngles()
    
    -- Draw item info above the model
    ang:RotateAroundAxis(ang:Up(), 90)
    
    cam.Start3D2D(pos + Vector(0, 0, 20), Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.1)
        local item = KYBER.GrandExchange.Items[self:GetItemID()]
        if item then
            -- Background
            draw.RoundedBox(6, -100, -20, 200, 40, Color(0, 0, 0, 200))
            
            -- Item name
            draw.SimpleText(item.name, "DermaDefault", 0, -10, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            
            -- Amount
            if self:GetItemAmount() > 1 then
                draw.SimpleText("x" .. self:GetItemAmount(), "DermaDefault", 0, 5, Color(255, 255, 100), TEXT_ALIGN_CENTER)
            end
        end
    cam.End3D2D()
end

function ENT:GetOverlayText()
    local item = KYBER.GrandExchange.Items[self:GetItemID()]
    if item then
        return item.name .. " x" .. self:GetItemAmount() .. "\nPress E to pick up"
    end
    return "Unknown Item"
end

-- kyber/entities/entities/kyber_dropped_item/shared.lua
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Dropped Item"
ENT.Author = "Kyber"
ENT.Spawnable = false
ENT.Category = "Kyber RP"

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "ItemActive")
    self:NetworkVar("String", 0, "ItemID")
    self:NetworkVar("Int", 0, "ItemAmount")
end