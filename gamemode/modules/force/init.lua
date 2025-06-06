-- Force module initialization
KYBER.Force = KYBER.Force or {}

-- Force module configuration
KYBER.Force.Config = {
    MaxForceLevel = 100,
    ExperiencePerUse = 5,
    ExperienceMultiplier = 1.0,
    ForceRegenRate = 1, -- points per second
    MaxForcePoints = 100,
    MinForcePoints = 0,
    ForceCosts = {
        push = 10,
        pull = 10,
        jump = 15,
        speed = 20,
        heal = 30,
        lightning = 40,
        choke = 35,
        mindTrick = 25
    },
    ForcePowers = {
        ["push"] = {
            name = "Force Push",
            description = "Push objects and enemies away",
            level = 1,
            cooldown = 5,
            range = 500,
            damage = 10,
            force = 500
        },
        ["pull"] = {
            name = "Force Pull",
            description = "Pull objects and enemies towards you",
            level = 1,
            cooldown = 5,
            range = 500,
            force = 500
        },
        ["jump"] = {
            name = "Force Jump",
            description = "Jump higher and further",
            level = 5,
            cooldown = 3,
            multiplier = 2.0
        },
        ["speed"] = {
            name = "Force Speed",
            description = "Move faster for a short time",
            level = 10,
            cooldown = 10,
            duration = 5,
            multiplier = 1.5
        },
        ["heal"] = {
            name = "Force Heal",
            description = "Heal yourself or others",
            level = 15,
            cooldown = 20,
            range = 200,
            healAmount = 25
        },
        ["lightning"] = {
            name = "Force Lightning",
            description = "Channel lightning at enemies",
            level = 20,
            cooldown = 15,
            range = 300,
            damage = 5,
            duration = 3
        },
        ["choke"] = {
            name = "Force Choke",
            description = "Choke enemies from a distance",
            level = 25,
            cooldown = 20,
            range = 400,
            damage = 2,
            duration = 5
        },
        ["mindTrick"] = {
            name = "Mind Trick",
            description = "Confuse enemies temporarily",
            level = 30,
            cooldown = 25,
            range = 200,
            duration = 10
        }
    },
    ForceAlignments = {
        ["light"] = {
            name = "Light Side",
            color = Color(0, 150, 255),
            powers = {
                "push",
                "pull",
                "jump",
                "speed",
                "heal"
            }
        },
        ["dark"] = {
            name = "Dark Side",
            color = Color(255, 0, 0),
            powers = {
                "push",
                "pull",
                "jump",
                "speed",
                "lightning",
                "choke"
            }
        },
        ["neutral"] = {
            name = "Neutral",
            color = Color(150, 150, 150),
            powers = {
                "push",
                "pull",
                "jump",
                "speed",
                "mindTrick"
            }
        }
    }
}

-- Force module functions
function KYBER.Force:Initialize()
    print("[Kyber] Force module initialized")
    return true
end

function KYBER.Force:CreateForceData(ply)
    if not IsValid(ply) then return false end
    
    -- Create force data table if it doesn't exist
    ply.KyberForce = ply.KyberForce or {
        level = 1,
        experience = 0,
        points = self.Config.MaxForcePoints,
        alignment = "neutral",
        unlockedPowers = {},
        cooldowns = {},
        activeEffects = {}
    }
    
    return true
end

function KYBER.Force:GetLevel(ply)
    if not IsValid(ply) then return 1 end
    if not self:CreateForceData(ply) then return 1 end
    
    return ply.KyberForce.level
end

function KYBER.Force:GetExperience(ply)
    if not IsValid(ply) then return 0 end
    if not self:CreateForceData(ply) then return 0 end
    
    return ply.KyberForce.experience
end

function KYBER.Force:AddExperience(ply, amount)
    if not IsValid(ply) then return false end
    if not self:CreateForceData(ply) then return false end
    
    -- Calculate experience with multiplier
    local expGain = math.floor(amount * self.Config.ExperienceMultiplier)
    
    -- Add experience
    ply.KyberForce.experience = ply.KyberForce.experience + expGain
    
    -- Check for level up
    local expNeeded = self:GetExperienceForLevel(ply.KyberForce.level + 1)
    while ply.KyberForce.experience >= expNeeded and ply.KyberForce.level < self.Config.MaxForceLevel do
        ply.KyberForce.level = ply.KyberForce.level + 1
        ply.KyberForce.experience = ply.KyberForce.experience - expNeeded
        expNeeded = self:GetExperienceForLevel(ply.KyberForce.level + 1)
        
        -- Notify client of level up
        if SERVER then
            net.Start("Kyber_Force_LevelUp")
            net.WriteEntity(ply)
            net.WriteInt(ply.KyberForce.level, 32)
            net.Send(ply)
        end
    end
    
    -- Notify client of experience gain
    if SERVER then
        net.Start("Kyber_Force_Experience")
        net.WriteEntity(ply)
        net.WriteInt(expGain, 32)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Force:GetExperienceForLevel(level)
    return level * 100 -- Simple linear progression
end

function KYBER.Force:GetForcePoints(ply)
    if not IsValid(ply) then return 0 end
    if not self:CreateForceData(ply) then return 0 end
    
    return ply.KyberForce.points
end

function KYBER.Force:AddForcePoints(ply, amount)
    if not IsValid(ply) then return false end
    if not self:CreateForceData(ply) then return false end
    
    -- Add points
    ply.KyberForce.points = math.min(ply.KyberForce.points + amount, self.Config.MaxForcePoints)
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Force_Points")
        net.WriteEntity(ply)
        net.WriteInt(ply.KyberForce.points, 32)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Force:RemoveForcePoints(ply, amount)
    if not IsValid(ply) then return false end
    if not self:CreateForceData(ply) then return false end
    
    -- Remove points
    ply.KyberForce.points = math.max(ply.KyberForce.points - amount, self.Config.MinForcePoints)
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Force_Points")
        net.WriteEntity(ply)
        net.WriteInt(ply.KyberForce.points, 32)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Force:GetAlignment(ply)
    if not IsValid(ply) then return "neutral" end
    if not self:CreateForceData(ply) then return "neutral" end
    
    return ply.KyberForce.alignment
end

function KYBER.Force:SetAlignment(ply, alignment)
    if not IsValid(ply) then return false end
    if not self:CreateForceData(ply) then return false end
    if not self.Config.ForceAlignments[alignment] then return false end
    
    -- Set alignment
    ply.KyberForce.alignment = alignment
    
    -- Update unlocked powers
    self:UpdateUnlockedPowers(ply)
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Force_Alignment")
        net.WriteEntity(ply)
        net.WriteString(alignment)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Force:UpdateUnlockedPowers(ply)
    if not IsValid(ply) then return false end
    if not self:CreateForceData(ply) then return false end
    
    -- Clear unlocked powers
    ply.KyberForce.unlockedPowers = {}
    
    -- Get alignment powers
    local alignment = self.Config.ForceAlignments[ply.KyberForce.alignment]
    if not alignment then return false end
    
    -- Add powers based on level
    for _, powerId in ipairs(alignment.powers) do
        local power = self.Config.ForcePowers[powerId]
        if power and ply.KyberForce.level >= power.level then
            ply.KyberForce.unlockedPowers[powerId] = true
        end
    end
    
    return true
end

function KYBER.Force:HasPower(ply, powerId)
    if not IsValid(ply) then return false end
    if not self:CreateForceData(ply) then return false end
    
    return ply.KyberForce.unlockedPowers[powerId] or false
end

function KYBER.Force:CanUsePower(ply, powerId)
    if not IsValid(ply) then return false end
    if not self:HasPower(ply, powerId) then return false end
    
    -- Check cooldown
    if ply.KyberForce.cooldowns[powerId] and ply.KyberForce.cooldowns[powerId] > CurTime() then
        return false
    end
    
    -- Check force points
    local cost = self.Config.ForceCosts[powerId]
    if not cost or ply.KyberForce.points < cost then
        return false
    end
    
    return true
end

function KYBER.Force:UsePower(ply, powerId)
    if not IsValid(ply) then return false end
    if not self:CanUsePower(ply, powerId) then return false end
    
    -- Get power data
    local power = self.Config.ForcePowers[powerId]
    if not power then return false end
    
    -- Remove force points
    self:RemoveForcePoints(ply, self.Config.ForceCosts[powerId])
    
    -- Set cooldown
    ply.KyberForce.cooldowns[powerId] = CurTime() + power.cooldown
    
    -- Add experience
    self:AddExperience(ply, self.Config.ExperiencePerUse)
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Force_UsePower")
        net.WriteEntity(ply)
        net.WriteString(powerId)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Force:GetCooldown(ply, powerId)
    if not IsValid(ply) then return 0 end
    if not self:CreateForceData(ply) then return 0 end
    
    local cooldown = ply.KyberForce.cooldowns[powerId]
    if not cooldown then return 0 end
    
    return math.max(0, cooldown - CurTime())
end

function KYBER.Force:GetUnlockedPowers(ply)
    if not IsValid(ply) then return {} end
    if not self:CreateForceData(ply) then return {} end
    
    local powers = {}
    for powerId, _ in pairs(ply.KyberForce.unlockedPowers) do
        powers[powerId] = self.Config.ForcePowers[powerId]
    end
    
    return powers
end

-- Initialize the module
KYBER.Force:Initialize() 