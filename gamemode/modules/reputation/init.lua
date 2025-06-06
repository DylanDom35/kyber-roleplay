-- Reputation module initialization
KYBER.Reputation = KYBER.Reputation or {}

-- Reputation module configuration
KYBER.Reputation.Config = {
    MinReputation = -1000,
    MaxReputation = 1000,
    DefaultReputation = 0,
    ReputationLevels = {
        {
            name = "Hated",
            min = -1000,
            max = -500,
            color = Color(255, 0, 0)
        },
        {
            name = "Disliked",
            min = -499,
            max = -100,
            color = Color(255, 100, 0)
        },
        {
            name = "Neutral",
            min = -99,
            max = 99,
            color = Color(255, 255, 255)
        },
        {
            name = "Liked",
            min = 100,
            max = 499,
            color = Color(100, 255, 100)
        },
        {
            name = "Loved",
            min = 500,
            max = 1000,
            color = Color(0, 255, 0)
        }
    },
    FactionReputation = {
        ["jedi"] = {
            name = "Jedi Order",
            default = 0,
            max = 1000,
            min = -1000
        },
        ["sith"] = {
            name = "Sith Order",
            default = 0,
            max = 1000,
            min = -1000
        },
        ["imperial"] = {
            name = "Imperial Remnant",
            default = 0,
            max = 1000,
            min = -1000
        },
        ["rebel"] = {
            name = "Rebel Alliance",
            default = 0,
            max = 1000,
            min = -1000
        }
    }
}

-- Reputation module functions
function KYBER.Reputation:Initialize()
    print("[Kyber] Reputation module initialized")
    return true
end

function KYBER.Reputation:CreateReputationData(ply)
    if not IsValid(ply) then return false end
    
    -- Create reputation data table if it doesn't exist
    ply.KyberReputation = ply.KyberReputation or {
        global = self.Config.DefaultReputation,
        factions = {}
    }
    
    -- Initialize faction reputations
    for factionId, factionData in pairs(self.Config.FactionReputation) do
        if not ply.KyberReputation.factions[factionId] then
            ply.KyberReputation.factions[factionId] = factionData.default
        end
    end
    
    return true
end

function KYBER.Reputation:GetReputation(ply, factionId)
    if not IsValid(ply) then return 0 end
    if not self:CreateReputationData(ply) then return 0 end
    
    if factionId then
        return ply.KyberReputation.factions[factionId] or 0
    else
        return ply.KyberReputation.global
    end
end

function KYBER.Reputation:SetReputation(ply, amount, factionId)
    if not IsValid(ply) then return false end
    if not self:CreateReputationData(ply) then return false end
    
    -- Get faction data
    local factionData = factionId and self.Config.FactionReputation[factionId]
    if factionId and not factionData then return false end
    
    -- Clamp reputation value
    local min = factionData and factionData.min or self.Config.MinReputation
    local max = factionData and factionData.max or self.Config.MaxReputation
    amount = math.Clamp(amount, min, max)
    
    -- Set reputation
    if factionId then
        ply.KyberReputation.factions[factionId] = amount
    else
        ply.KyberReputation.global = amount
    end
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Reputation_Update")
        net.WriteEntity(ply)
        net.WriteString(factionId or "")
        net.WriteInt(amount, 32)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Reputation:AddReputation(ply, amount, factionId)
    if not IsValid(ply) then return false end
    
    local currentRep = self:GetReputation(ply, factionId)
    return self:SetReputation(ply, currentRep + amount, factionId)
end

function KYBER.Reputation:GetReputationLevel(amount)
    for _, level in ipairs(self.Config.ReputationLevels) do
        if amount >= level.min and amount <= level.max then
            return level
        end
    end
    
    return self.Config.ReputationLevels[3] -- Default to Neutral
end

function KYBER.Reputation:GetFactionReputationLevel(ply, factionId)
    if not IsValid(ply) then return nil end
    
    local rep = self:GetReputation(ply, factionId)
    return self:GetReputationLevel(rep)
end

function KYBER.Reputation:GetGlobalReputationLevel(ply)
    if not IsValid(ply) then return nil end
    
    local rep = self:GetReputation(ply)
    return self:GetReputationLevel(rep)
end

function KYBER.Reputation:GetAllFactionReputations(ply)
    if not IsValid(ply) then return nil end
    if not self:CreateReputationData(ply) then return nil end
    
    local reputations = {}
    for factionId, _ in pairs(self.Config.FactionReputation) do
        reputations[factionId] = {
            amount = self:GetReputation(ply, factionId),
            level = self:GetFactionReputationLevel(ply, factionId)
        }
    end
    
    return reputations
end

function KYBER.Reputation:ClearReputation(ply)
    if not IsValid(ply) then return false end
    
    -- Reset reputation data
    self:CreateReputationData(ply)
    ply.KyberReputation.global = self.Config.DefaultReputation
    
    -- Reset faction reputations
    for factionId, factionData in pairs(self.Config.FactionReputation) do
        ply.KyberReputation.factions[factionId] = factionData.default
    end
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Reputation_Update")
        net.WriteEntity(ply)
        net.WriteString("")
        net.WriteInt(self.Config.DefaultReputation, 32)
        net.Send(ply)
    end
    
    return true
end

-- Initialize the module
KYBER.Reputation:Initialize() 