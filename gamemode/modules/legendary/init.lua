-- Legendary module initialization
KYBER.Legendary = KYBER.Legendary or {}

-- Legendary module configuration
KYBER.Legendary.Config = {
    MaxLegendaryLevel = 100,
    ExperiencePerAction = 20,
    ExperienceMultiplier = 1.0,
    LegendaryItems = {
        ["lightsaber_ancient"] = {
            name = "Ancient Lightsaber",
            description = "A lightsaber from a bygone era",
            type = "weapon",
            rarity = "legendary",
            level = 50,
            stats = {
                damage = 50,
                speed = 1.2,
                range = 100
            },
            effects = {
                forceRegen = 1.2,
                forceCost = 0.9
            },
            requirements = {
                forceLevel = 30,
                alignment = "light"
            }
        },
        ["armor_beskar"] = {
            name = "Beskar Armor",
            description = "Legendary Mandalorian armor",
            type = "armor",
            rarity = "legendary",
            level = 40,
            stats = {
                protection = 75,
                speed = 0.9,
                stamina = 1.2
            },
            effects = {
                damageReduction = 0.8,
                staminaRegen = 1.3
            },
            requirements = {
                strength = 25
            }
        },
        ["crystal_kyber"] = {
            name = "Kyber Crystal",
            description = "A rare and powerful crystal",
            type = "material",
            rarity = "legendary",
            level = 60,
            stats = {
                power = 100,
                stability = 90
            },
            effects = {
                forcePower = 1.5,
                forceControl = 1.3
            },
            requirements = {
                forceLevel = 40
            }
        }
    },
    LegendaryEvents = {
        ["temple_ruins"] = {
            name = "Ancient Temple Ruins",
            description = "Explore the ruins of an ancient temple",
            level = 30,
            rewards = {
                experience = 1000,
                items = {
                    ["crystal_kyber"] = 0.1 -- 10% chance
                }
            },
            requirements = {
                forceLevel = 20
            }
        },
        ["beskar_mine"] = {
            name = "Beskar Mine",
            description = "Discover a hidden Beskar mine",
            level = 40,
            rewards = {
                experience = 1500,
                items = {
                    ["armor_beskar"] = 0.05 -- 5% chance
                }
            },
            requirements = {
                strength = 25
            }
        }
    }
}

-- Legendary module functions
function KYBER.Legendary:Initialize()
    print("[Kyber] Legendary module initialized")
    return true
end

function KYBER.Legendary:CreateLegendaryData(ply)
    if not IsValid(ply) then return false end
    
    -- Create legendary data table if it doesn't exist
    ply.KyberLegendary = ply.KyberLegendary or {
        level = 1,
        experience = 0,
        discoveredItems = {},
        completedEvents = {},
        activeEvents = {}
    }
    
    return true
end

function KYBER.Legendary:GetLevel(ply)
    if not IsValid(ply) then return 1 end
    if not self:CreateLegendaryData(ply) then return 1 end
    
    return ply.KyberLegendary.level
end

function KYBER.Legendary:GetExperience(ply)
    if not IsValid(ply) then return 0 end
    if not self:CreateLegendaryData(ply) then return 0 end
    
    return ply.KyberLegendary.experience
end

function KYBER.Legendary:AddExperience(ply, amount)
    if not IsValid(ply) then return false end
    if not self:CreateLegendaryData(ply) then return false end
    
    -- Calculate experience with multiplier
    local expGain = math.floor(amount * self.Config.ExperienceMultiplier)
    
    -- Add experience
    ply.KyberLegendary.experience = ply.KyberLegendary.experience + expGain
    
    -- Check for level up
    local expNeeded = self:GetExperienceForLevel(ply.KyberLegendary.level + 1)
    while ply.KyberLegendary.experience >= expNeeded and ply.KyberLegendary.level < self.Config.MaxLegendaryLevel do
        ply.KyberLegendary.level = ply.KyberLegendary.level + 1
        ply.KyberLegendary.experience = ply.KyberLegendary.experience - expNeeded
        expNeeded = self:GetExperienceForLevel(ply.KyberLegendary.level + 1)
        
        -- Notify client of level up
        if SERVER then
            net.Start("Kyber_Legendary_LevelUp")
            net.WriteEntity(ply)
            net.WriteInt(ply.KyberLegendary.level, 32)
            net.Send(ply)
        end
    end
    
    -- Notify client of experience gain
    if SERVER then
        net.Start("Kyber_Legendary_Experience")
        net.WriteEntity(ply)
        net.WriteInt(expGain, 32)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Legendary:GetExperienceForLevel(level)
    return level * 200 -- Higher experience requirements for legendary levels
end

function KYBER.Legendary:CanUseLegendaryItem(ply, itemId)
    if not IsValid(ply) then return false end
    if not self:CreateLegendaryData(ply) then return false end
    
    -- Get item data
    local item = self.Config.LegendaryItems[itemId]
    if not item then return false end
    
    -- Check level requirement
    if ply.KyberLegendary.level < item.level then
        return false
    end
    
    -- Check force level requirement
    if item.requirements.forceLevel then
        local forceLevel = KYBER.Force:GetLevel(ply)
        if forceLevel < item.requirements.forceLevel then
            return false
        end
    end
    
    -- Check force alignment requirement
    if item.requirements.alignment then
        local alignment = KYBER.Force:GetAlignment(ply)
        if alignment ~= item.requirements.alignment then
            return false
        end
    end
    
    -- Check strength requirement
    if item.requirements.strength then
        -- Implementation depends on player stats module
        return false
    end
    
    return true
end

function KYBER.Legendary:DiscoverItem(ply, itemId)
    if not IsValid(ply) then return false end
    if not self:CreateLegendaryData(ply) then return false end
    
    -- Get item data
    local item = self.Config.LegendaryItems[itemId]
    if not item then return false end
    
    -- Add to discovered items
    ply.KyberLegendary.discoveredItems[itemId] = true
    
    -- Add experience
    self:AddExperience(ply, self.Config.ExperiencePerAction)
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Legendary_DiscoverItem")
        net.WriteEntity(ply)
        net.WriteString(itemId)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Legendary:HasDiscoveredItem(ply, itemId)
    if not IsValid(ply) then return false end
    if not self:CreateLegendaryData(ply) then return false end
    
    return ply.KyberLegendary.discoveredItems[itemId] or false
end

function KYBER.Legendary:GetDiscoveredItems(ply)
    if not IsValid(ply) then return {} end
    if not self:CreateLegendaryData(ply) then return {} end
    
    local items = {}
    for itemId, _ in pairs(ply.KyberLegendary.discoveredItems) do
        items[itemId] = self.Config.LegendaryItems[itemId]
    end
    
    return items
end

function KYBER.Legendary:CanStartEvent(ply, eventId)
    if not IsValid(ply) then return false end
    if not self:CreateLegendaryData(ply) then return false end
    
    -- Get event data
    local event = self.Config.LegendaryEvents[eventId]
    if not event then return false end
    
    -- Check level requirement
    if ply.KyberLegendary.level < event.level then
        return false
    end
    
    -- Check force level requirement
    if event.requirements.forceLevel then
        local forceLevel = KYBER.Force:GetLevel(ply)
        if forceLevel < event.requirements.forceLevel then
            return false
        end
    end
    
    -- Check strength requirement
    if event.requirements.strength then
        -- Implementation depends on player stats module
        return false
    end
    
    -- Check if already completed
    if ply.KyberLegendary.completedEvents[eventId] then
        return false
    end
    
    -- Check if already active
    if ply.KyberLegendary.activeEvents[eventId] then
        return false
    end
    
    return true
end

function KYBER.Legendary:StartEvent(ply, eventId)
    if not IsValid(ply) then return false end
    if not self:CanStartEvent(ply, eventId) then return false end
    
    -- Get event data
    local event = self.Config.LegendaryEvents[eventId]
    
    -- Add to active events
    ply.KyberLegendary.activeEvents[eventId] = {
        startTime = CurTime(),
        progress = 0
    }
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Legendary_StartEvent")
        net.WriteEntity(ply)
        net.WriteString(eventId)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Legendary:CompleteEvent(ply, eventId)
    if not IsValid(ply) then return false end
    if not self:CreateLegendaryData(ply) then return false end
    
    -- Get event data
    local event = self.Config.LegendaryEvents[eventId]
    if not event then return false end
    
    -- Check if event is active
    if not ply.KyberLegendary.activeEvents[eventId] then
        return false
    end
    
    -- Add to completed events
    ply.KyberLegendary.completedEvents[eventId] = true
    
    -- Remove from active events
    ply.KyberLegendary.activeEvents[eventId] = nil
    
    -- Add experience
    self:AddExperience(ply, event.rewards.experience)
    
    -- Give rewards
    if event.rewards.items then
        for itemId, chance in pairs(event.rewards.items) do
            if math.random() < chance then
                KYBER.Inventory:AddItem(ply, itemId, 1)
            end
        end
    end
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Legendary_CompleteEvent")
        net.WriteEntity(ply)
        net.WriteString(eventId)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Legendary:GetActiveEvents(ply)
    if not IsValid(ply) then return {} end
    if not self:CreateLegendaryData(ply) then return {} end
    
    local events = {}
    for eventId, data in pairs(ply.KyberLegendary.activeEvents) do
        events[eventId] = {
            data = self.Config.LegendaryEvents[eventId],
            progress = data.progress
        }
    end
    
    return events
end

function KYBER.Legendary:GetCompletedEvents(ply)
    if not IsValid(ply) then return {} end
    if not self:CreateLegendaryData(ply) then return {} end
    
    local events = {}
    for eventId, _ in pairs(ply.KyberLegendary.completedEvents) do
        events[eventId] = self.Config.LegendaryEvents[eventId]
    end
    
    return events
end

function KYBER.Legendary:GetAvailableEvents(ply)
    if not IsValid(ply) then return {} end
    if not self:CreateLegendaryData(ply) then return {} end
    
    local events = {}
    for eventId, event in pairs(self.Config.LegendaryEvents) do
        if self:CanStartEvent(ply, eventId) then
            events[eventId] = event
        end
    end
    
    return events
end

-- Initialize the module
KYBER.Legendary:Initialize() 