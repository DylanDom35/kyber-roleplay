-- Medical module initialization
KYBER.Medical = KYBER.Medical or {}

-- Medical module configuration
KYBER.Medical.Config = {
    MaxHealth = 100,
    MaxArmor = 100,
    BleedRate = 1, -- Health points per second
    HealRate = 5, -- Health points per second
    ArmorRepairRate = 3, -- Armor points per second
    ReviveTime = 10, -- Seconds to revive a player
    MaxBleedTime = 300, -- Maximum time a player can bleed (5 minutes)
    DamageTypes = {
        ["blunt"] = {
            name = "Blunt Damage",
            armorEffectiveness = 0.8,
            bleedChance = 0.1
        },
        ["sharp"] = {
            name = "Sharp Damage",
            armorEffectiveness = 0.5,
            bleedChance = 0.3
        },
        ["energy"] = {
            name = "Energy Damage",
            armorEffectiveness = 0.3,
            bleedChance = 0.05
        },
        ["explosive"] = {
            name = "Explosive Damage",
            armorEffectiveness = 0.2,
            bleedChance = 0.2
        }
    },
    MedicalItems = {
        ["medkit"] = {
            name = "Medkit",
            healAmount = 50,
            armorAmount = 25,
            stopBleeding = true,
            useTime = 5
        },
        ["bandage"] = {
            name = "Bandage",
            healAmount = 10,
            armorAmount = 0,
            stopBleeding = true,
            useTime = 3
        },
        ["stim"] = {
            name = "Stim Pack",
            healAmount = 25,
            armorAmount = 0,
            stopBleeding = false,
            useTime = 1
        }
    }
}

-- Medical module functions
function KYBER.Medical:Initialize()
    print("[Kyber] Medical module initialized")
    return true
end

function KYBER.Medical:CreateMedicalData(ply)
    if not IsValid(ply) then return false end
    
    -- Create medical data table if it doesn't exist
    ply.KyberMedical = ply.KyberMedical or {
        bleeding = false,
        bleedStartTime = 0,
        lastDamage = 0,
        lastDamageType = "",
        lastDamageSource = nil,
        isReviving = false,
        reviveStartTime = 0,
        reviveTarget = nil
    }
    
    return true
end

function KYBER.Medical:ApplyDamage(ply, amount, damageType, attacker)
    if not IsValid(ply) then return false end
    if not self:CreateMedicalData(ply) then return false end
    
    -- Get damage type data
    local dmgData = self.Config.DamageTypes[damageType] or self.Config.DamageTypes["blunt"]
    
    -- Calculate armor reduction
    local armor = ply:Armor()
    local armorReduction = armor * dmgData.armorEffectiveness
    local finalDamage = math.max(0, amount - armorReduction)
    
    -- Apply damage
    ply:SetHealth(math.max(0, ply:Health() - finalDamage))
    ply:SetArmor(math.max(0, armor - (amount * 0.5)))
    
    -- Check for bleeding
    if math.random() < dmgData.bleedChance then
        self:StartBleeding(ply)
    end
    
    -- Update medical data
    ply.KyberMedical.lastDamage = amount
    ply.KyberMedical.lastDamageType = damageType
    ply.KyberMedical.lastDamageSource = attacker
    
    -- Check for death
    if ply:Health() <= 0 then
        self:HandleDeath(ply)
    end
    
    return true
end

function KYBER.Medical:StartBleeding(ply)
    if not IsValid(ply) then return false end
    if not self:CreateMedicalData(ply) then return false end
    
    ply.KyberMedical.bleeding = true
    ply.KyberMedical.bleedStartTime = CurTime()
    
    -- Start bleed timer
    timer.Create("Kyber_Bleed_" .. ply:SteamID(), 1, 0, function()
        if not IsValid(ply) or not ply.KyberMedical.bleeding then
            timer.Remove("Kyber_Bleed_" .. ply:SteamID())
            return
        end
        
        -- Check if bleeding should stop
        if CurTime() - ply.KyberMedical.bleedStartTime > self.Config.MaxBleedTime then
            self:StopBleeding(ply)
            return
        end
        
        -- Apply bleed damage
        ply:SetHealth(math.max(0, ply:Health() - self.Config.BleedRate))
        
        -- Check for death
        if ply:Health() <= 0 then
            self:HandleDeath(ply)
        end
    end)
    
    return true
end

function KYBER.Medical:StopBleeding(ply)
    if not IsValid(ply) then return false end
    if not ply.KyberMedical then return false end
    
    ply.KyberMedical.bleeding = false
    timer.Remove("Kyber_Bleed_" .. ply:SteamID())
    
    return true
end

function KYBER.Medical:HandleDeath(ply)
    if not IsValid(ply) then return false end
    
    -- Stop bleeding
    self:StopBleeding(ply)
    
    -- Reset medical data
    self:CreateMedicalData(ply)
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Medical_Death")
        net.WriteEntity(ply)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Medical:StartRevive(ply, target)
    if not IsValid(ply) or not IsValid(target) then return false end
    if not self:CreateMedicalData(ply) then return false end
    
    -- Check if target is dead
    if target:Health() > 0 then return false end
    
    -- Start revive process
    ply.KyberMedical.isReviving = true
    ply.KyberMedical.reviveStartTime = CurTime()
    ply.KyberMedical.reviveTarget = target
    
    -- Create revive timer
    timer.Create("Kyber_Revive_" .. ply:SteamID(), self.Config.ReviveTime, 1, function()
        if not IsValid(ply) or not IsValid(target) then
            self:StopRevive(ply)
            return
        end
        
        -- Revive target
        target:SetHealth(self.Config.MaxHealth * 0.5)
        target:SetArmor(0)
        
        -- Stop revive
        self:StopRevive(ply)
    end)
    
    return true
end

function KYBER.Medical:StopRevive(ply)
    if not IsValid(ply) then return false end
    if not ply.KyberMedical then return false end
    
    ply.KyberMedical.isReviving = false
    ply.KyberMedical.reviveTarget = nil
    timer.Remove("Kyber_Revive_" .. ply:SteamID())
    
    return true
end

function KYBER.Medical:UseMedicalItem(ply, itemId)
    if not IsValid(ply) then return false end
    
    -- Get item data
    local itemData = self.Config.MedicalItems[itemId]
    if not itemData then return false end
    
    -- Check if player has the item
    if not KYBER.Inventory:HasItem(ply, itemId) then
        return false
    end
    
    -- Apply medical effects
    if itemData.healAmount > 0 then
        ply:SetHealth(math.min(self.Config.MaxHealth, ply:Health() + itemData.healAmount))
    end
    
    if itemData.armorAmount > 0 then
        ply:SetArmor(math.min(self.Config.MaxArmor, ply:Armor() + itemData.armorAmount))
    end
    
    if itemData.stopBleeding then
        self:StopBleeding(ply)
    end
    
    -- Remove item from inventory
    KYBER.Inventory:RemoveItem(ply, itemId, 1)
    
    return true
end

function KYBER.Medical:GetMedicalData(ply)
    if not IsValid(ply) then return nil end
    if not self:CreateMedicalData(ply) then return nil end
    
    return ply.KyberMedical
end

-- Initialize the module
KYBER.Medical:Initialize() 