-- kyber/entities/entities/kyber_dropped_item/init.lua
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/cardboard_box003a.mdl") -- Default model
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(5)
    end
    
    -- Default values
    self:SetItemID("unknown")
    self:SetAmount(1)
    
    -- Auto-remove after 5 minutes
    self.RemoveTime = CurTime() + 300
end

function ENT:SetItem(itemID, amount)
    self:SetItemID(itemID)
    self:SetAmount(amount or 1)
    
    -- Update model based on item type
    local item = KYBER.GrandExchange.Items[itemID]
    if item then
        -- You can set custom models for different item types here
        if item.category == "materials" then
            self:SetModel("models/props_junk/metal_paintcan001a.mdl")
        elseif item.category == "consumables" then
            self:SetModel("models/props_junk/garbage_bag001a.mdl")
        elseif item.category == "artifacts" then
            self:SetModel("models/props_combine/breenclock.mdl")
        end
        
        -- Set size based on value
        local scale = math.Clamp(item.basePrice / 5000, 0.5, 2)
        self:SetModelScale(scale, 0)
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    local itemID = self:GetItemID()
    local amount = self:GetAmount()
    
    -- Try to give item to player
    local success, err = KYBER.Inventory:GiveItem(activator, itemID, amount)
    
    if success then
        activator:EmitSound("items/ammo_pickup.wav")
        self:Remove()
    else
        activator:ChatPrint("Cannot pick up: " .. err)
    end
end

function ENT:Think()
    -- Auto-remove old items
    if CurTime() > self.RemoveTime then
        self:Remove()
    end
    
    self:NextThink(CurTime() + 1)
    return true
end

function ENT:OnTakeDamage(dmg)
    -- Items can be destroyed
    local attacker = dmg:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() then
        attacker:ChatPrint("The item was destroyed!")
        self:Remove()
    end
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
            if self:GetAmount() > 1 then
                draw.SimpleText("x" .. self:GetAmount(), "DermaDefault", 0, 5, Color(255, 255, 100), TEXT_ALIGN_CENTER)
            end
        end
    cam.End3D2D()
end

function ENT:GetOverlayText()
    local item = KYBER.GrandExchange.Items[self:GetItemID()]
    if item then
        return item.name .. " x" .. self:GetAmount() .. "\nPress E to pick up"
    end
    return "Unknown Item"
end

-- kyber/entities/entities/kyber_dropped_item/shared.lua
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Dropped Item"
ENT.Author = "Kyber"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "ItemID")
    self:NetworkVar("Int", 0, "Amount")
end