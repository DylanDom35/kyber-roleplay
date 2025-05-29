-- kyber/entities/entities/kyber_bacta_tank/init.lua
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_lab/crematorcase.mdl") -- Replace with bacta tank model
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false) -- Keep it stationary
    end
    
    self:SetTankActive(true)
    self:SetOccupied(false)
    self:SetBactaLevel(100)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    if not self:GetTankActive() then
        activator:ChatPrint("This bacta tank is not operational.")
        return
    end
    
    if self:GetOccupied() then
        -- Check if it's the occupant trying to exit
        if self.Occupant == activator then
            self:EjectOccupant()
        else
            activator:ChatPrint("This bacta tank is already in use.")
        end
        return
    end
    
    if self:GetBactaLevel() < 10 then
        activator:ChatPrint("Insufficient bacta levels. Refill required.")
        return
    end
    
    -- Enter bacta tank
    self:EnterTank(activator)
end

function ENT:EnterTank(ply)
    -- Check if injured or damaged
    if ply:Health() >= ply:GetMaxHealth() and #(ply.KyberMedical and ply.KyberMedical.injuries or {}) == 0 then
        ply:ChatPrint("You don't need medical treatment.")
        return
    end
    
    self.Occupant = ply
    self.OccupantEnterTime = CurTime()
    self:SetOccupied(true)
    
    -- Freeze player
    ply:SetMoveType(MOVETYPE_NONE)
    ply:SetPos(self:GetPos() + self:GetUp() * 40)
    ply:SetParent(self)
    ply:SetNoDraw(true)
    
    -- Start healing
    self:StartHealing()
    
    -- Effects
    self:EmitSound("ambient/water/water_in_boat1.wav")
    
    ply:ChatPrint("Entering bacta tank. Press E to exit.")
end

function ENT:StartHealing()
    local timerName = "BactaTank_" .. self:EntIndex()
    
    timer.Create(timerName, 1, 0, function()
        if not IsValid(self) or not self:GetOccupied() or not IsValid(self.Occupant) then
            timer.Remove(timerName)
            return
        end
        
        local ply = self.Occupant
        
        -- Check bacta level
        if self:GetBactaLevel() <= 0 then
            self:EjectOccupant()
            return
        end
        
        -- Heal player
        if ply:Health() < ply:GetMaxHealth() then
            local healAmount = KYBER.Medical.Config.bactaHealRate
            ply:SetHealth(math.min(ply:Health() + healAmount, ply:GetMaxHealth()))
            
            -- Medical experience for owner
            if self.MedicalOwner and IsValid(self.MedicalOwner) then
                KYBER.Medical:GrantMedicalExp(self.MedicalOwner, 2)
            end
        end
        
        -- Treat injuries
        if ply.KyberMedical and #ply.KyberMedical.injuries > 0 then
            for i, injury in ipairs(ply.KyberMedical.injuries) do
                if not injury.treated then
                    injury.treated = true
                    ply:ChatPrint("Bacta treatment healed your " .. KYBER.Medical.Config.injuryTypes[injury.type].name)
                    
                    -- Medical experience
                    if self.MedicalOwner and IsValid(self.MedicalOwner) then
                        KYBER.Medical:GrantMedicalExp(self.MedicalOwner, injury.severity * 5)
                    end
                    
                    break -- One injury per second
                end
            end
            
            KYBER.Medical:SendInjuryUpdate(ply)
        end
        
        -- Consume bacta
        self:SetBactaLevel(math.max(0, self:GetBactaLevel() - 1))
        
        -- Charge credits
        local cost = KYBER.Medical.Config.bactaCostPerSecond
        local credits = KYBER:GetPlayerData(ply, "credits") or 0
        
        if credits >= cost then
            KYBER:SetPlayerData(ply, "credits", credits - cost)
        else
            -- Try bank
            if ply.KyberBanking and ply.KyberBanking.credits >= cost then
                ply.KyberBanking.credits = ply.KyberBanking.credits - cost
                KYBER.Banking:Save(ply)
            else
                -- Can't pay, eject
                ply:ChatPrint("Insufficient credits for bacta treatment.")
                self:EjectOccupant()
            end
        end
        
        -- Check if fully healed
        if ply:Health() >= ply:GetMaxHealth() then
            local allTreated = true
            for _, injury in ipairs(ply.KyberMedical and ply.KyberMedical.injuries or {}) do
                if not injury.treated then
                    allTreated = false
                    break
                end
            end
            
            if allTreated then
                ply:ChatPrint("Treatment complete. You are fully healed.")
                self:EjectOccupant()
            end
        end
    end)
end

function ENT:EjectOccupant()
    if not IsValid(self.Occupant) then return end
    
    local ply = self.Occupant
    
    -- Unfreeze player
    ply:SetParent(nil)
    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetPos(self:GetPos() + self:GetForward() * 60 + Vector(0, 0, 10))
    ply:SetNoDraw(false)
    
    -- Calculate treatment time
    local treatmentTime = CurTime() - self.OccupantEnterTime
    local totalCost = math.floor(treatmentTime * KYBER.Medical.Config.bactaCostPerSecond)
    
    ply:ChatPrint("Bacta treatment complete. Duration: " .. math.floor(treatmentTime) .. " seconds. Cost: " .. totalCost .. " credits.")
    
    -- Clear occupant
    self.Occupant = nil
    self.OccupantEnterTime = nil
    self:SetOccupied(false)
    
    -- Stop healing timer
    timer.Remove("BactaTank_" .. self:EntIndex())
    
    -- Effects
    self:EmitSound("ambient/water/water_splash3.wav")
end

function ENT:OnRemove()
    if IsValid(self.Occupant) then
        self:EjectOccupant()
    end
    
    timer.Remove("BactaTank_" .. self:EntIndex())
end

-- kyber/entities/entities/kyber_bacta_tank/cl_init.lua
include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos()
    local ang = self:GetAngles()
    
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    
    cam.Start3D2D(pos + ang:Up() * 60, ang, 0.15)
        -- Background
        draw.RoundedBox(6, -150, -80, 300, 160, Color(0, 0, 0, 200))
        
        -- Title
        draw.SimpleText("Bacta Tank", "DermaLarge", 0, -50, Color(100, 200, 255), TEXT_ALIGN_CENTER)
        
        -- Status
        if self:GetTankActive() then
            if self:GetOccupied() then
                draw.SimpleText("IN USE", "DermaDefaultBold", 0, -20, Color(255, 100, 100), TEXT_ALIGN_CENTER)
                
                -- Healing animation
                local pulse = math.sin(CurTime() * 2) * 0.5 + 0.5
                draw.SimpleText("Healing...", "DermaDefault", 0, 0, Color(100, 255 * pulse, 100), TEXT_ALIGN_CENTER)
            else
                draw.SimpleText("READY", "DermaDefaultBold", 0, -20, Color(100, 255, 100), TEXT_ALIGN_CENTER)
                draw.SimpleText("Press E to enter", "DermaDefault", 0, 0, Color(200, 200, 200), TEXT_ALIGN_CENTER)
            end
            
            -- Bacta level
            local level = self:GetBactaLevel()
            draw.SimpleText("Bacta Level: " .. level .. "%", "DermaDefault", 0, 30, Color(200, 200, 200), TEXT_ALIGN_CENTER)
            
            -- Bacta bar
            local barWidth = 200
            local barHeight = 10
            local barX = -100
            local barY = 50
            
            draw.RoundedBox(2, barX, barY, barWidth, barHeight, Color(50, 50, 50))
            
            local fillColor = Color(100, 200, 255)
            if level < 25 then
                fillColor = Color(255, 100, 100)
            elseif level < 50 then
                fillColor = Color(255, 200, 100)
            end
            
            draw.RoundedBox(2, barX, barY, barWidth * (level / 100), barHeight, fillColor)
        else
            draw.SimpleText("OFFLINE", "DermaLarge", 0, 0, Color(255, 50, 50), TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
    
    -- Bacta liquid effect
    if self:GetOccupied() then
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = self:GetPos() + Vector(0, 0, 40)
            dlight.r = 100
            dlight.g = 200
            dlight.b = 255
            dlight.brightness = 2
            dlight.Decay = 1000
            dlight.Size = 256
            dlight.DieTime = CurTime() + 1
        end
    end
end

-- kyber/entities/entities/kyber_bacta_tank/shared.lua
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Bacta Tank"
ENT.Author = "Kyber"
ENT.Spawnable = true
ENT.Category = "Kyber RP"

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "TankActive")
    self:NetworkVar("Bool", 1, "Occupied")
    self:NetworkVar("Float", 0, "BactaLevel") -- 0-100
end