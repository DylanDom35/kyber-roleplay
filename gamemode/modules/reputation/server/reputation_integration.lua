-- kyber/modules/reputation/integration.lua
-- Integration with other systems

-- Grand Exchange pricing based on reputation
if SERVER then
    hook.Add("Kyber_GrandExchange_GetPrice", "ReputationPricing", function(ply, item, basePrice)
        -- Check if item has faction association
        local itemFaction = nil
        
        -- Determine faction based on item category or specific items
        if item.category == "weapons" then
            if string.find(item.name, "Imperial") then
                itemFaction = "imperial"
            elseif string.find(item.name, "Rebel") then
                itemFaction = "rebel"
            end
        elseif item.id == "beskar_ingot" or string.find(item.name, "Mandalorian") then
            itemFaction = "mandalorian"
        elseif string.find(item.name, "Jedi") then
            itemFaction = "jedi"
        end
        
        if itemFaction then
            local rep = ply.KyberReputation[itemFaction] or 0
            local tier = KYBER.Reputation:GetTier(rep)
            
            -- Price modifier based on reputation
            local modifier = 1.0
            
            if rep >= 5000 then
                modifier = 0.7 -- 30% discount for Revered+
            elseif rep >= 2500 then
                modifier = 0.8 -- 20% discount for Honored+
            elseif rep >= 1000 then
                modifier = 0.9 -- 10% discount for Liked+
            elseif rep >= 500 then
                modifier = 0.95 -- 5% discount for Friendly+
            elseif rep <= -500 then
                modifier = 1.1 -- 10% markup for Suspicious-
            elseif rep <= -1000 then
                modifier = 1.25 -- 25% markup for Disliked-
            elseif rep <= -2500 then
                modifier = 1.5 -- 50% markup for Unfriendly-
            elseif rep <= -5000 then
                modifier = 2.0 -- 100% markup for Hated-
            end
            
            -- Apply faction discounts
            local discount = ply:GetNWFloat("kyber_discount_" .. itemFaction, 0)
            modifier = modifier * (1 - discount)
            
            return math.floor(basePrice * modifier)
        end
        
        return basePrice
    end)
end

-- Equipment requirements based on reputation
hook.Add("Initialize", "KyberReputationEquipment", function()
    timer.Simple(2, function()
        -- Add reputation requirements to equipment
        local reputationEquipment = {
            ["armor_rebel_pilot"] = {
                name = "Rebel Pilot Armor",
                description = "Standard Rebel Alliance flight suit",
                slot = "chest",
                icon = "icon16/shield.png",
                stats = {
                    armor = 15,
                    agility = 10,
                    perception = 5
                },
                requirements = {
                    reputation_rebel = 500
                },
                value = 2000
            },
            
            ["armor_imperial_officer"] = {
                name = "Imperial Officer Uniform",
                description = "Imperial Navy officer attire",
                slot = "chest",
                icon = "icon16/shield.png",
                stats = {
                    armor = 10,
                    intimidation = 15,
                    accuracy = 5
                },
                requirements = {
                    reputation_imperial = 1000
                },
                value = 2500
            },
            
            ["helmet_mandalorian_honor"] = {
                name = "Mandalorian Honor Guard Helmet",
                description = "Elite Mandalorian warrior helmet",
                slot = "head",
                icon = "icon16/user_gray.png",
                stats = {
                    armor = 20,
                    perception = 10,
                    intimidation = 15
                },
                requirements = {
                    reputation_mandalorian = 2500
                },
                value = 10000
            }
        }
        
        -- Add to equipment system
        for itemID, item in pairs(reputationEquipment) do
            KYBER.Equipment.Items[itemID] = item
            
            -- Also add to Grand Exchange
            KYBER.GrandExchange.Items[itemID] = {
                name = item.name,
                description = item.description,
                category = "armor",
                basePrice = item.value,
                stackable = false,
                icon = item.icon
            }
        end
    end)
end)

-- Modify equipment requirement checking
if SERVER then
    local oldCheckReq = KYBER.Equipment.CheckRequirements
    KYBER.Equipment.CheckRequirements = function(self, ply, item)
        -- First check original requirements
        local canEquip, reason = oldCheckReq(self, ply, item)
        if not canEquip then
            return false, reason
        end
        
        -- Check reputation requirements
        if item.requirements then
            for req, value in pairs(item.requirements) do
                if string.StartWith(req, "reputation_") then
                    local faction = string.sub(req, 12)
                    local rep = ply.KyberReputation[faction] or 0
                    
                    if rep < value then
                        local factionData = KYBER.Reputation.Factions[faction]
                        local factionName = factionData and factionData.name or faction
                        return false, "Requires " .. value .. " reputation with " .. factionName .. " (have " .. rep .. ")"
                    end
                end
            end
        end
        
        return true
    end
end

-- Crafting station access based on reputation
if SERVER then
    hook.Add("Kyber_Crafting_CanUseStation", "ReputationStationAccess", function(ply, station)
        local stationType = station:GetStationType()
        
        -- Mandalorian forge requires reputation
        if stationType == "mandalorian_forge" then
            local rep = ply.KyberReputation["mandalorian"] or 0
            if rep < 2500 then
                return false, "Requires Honored reputation with Mandalorian Clans"
            end
        end
        
        -- Imperial workshop
        if stationType == "imperial_workshop" then
            local rep = ply.KyberReputation["imperial"] or 0
            if rep < 1000 then
                return false, "Requires Liked reputation with Imperial Remnant"
            end
        end
        
        return true
    end)
end

-- Faction-specific vendors
if SERVER then
    -- Create faction vendor entity
    local ENT = {}
    ENT.Type = "anim"
    ENT.Base = "base_gmodentity"
    ENT.PrintName = "Faction Vendor"
    ENT.Author = "Kyber"
    ENT.Spawnable = true
    ENT.AdminOnly = true
    ENT.Category = "Kyber RP"
    
    function ENT:SetupDataTables()
        self:NetworkVar("String", 0, "VendorFaction")
        self:NetworkVar("String", 1, "VendorName")
    end
    
    function ENT:Initialize()
        self:SetModel("models/Humans/Group01/Male_07.mdl")
        self:SetUseType(SIMPLE_USE)
        self:SetSolid(SOLID_BBOX)
        self:SetMoveType(MOVETYPE_NONE)
    end
    
    function ENT:Use(activator, caller)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        
        local faction = self:GetVendorFaction()
        if not faction or faction == "" then return end
        
        local rep = activator.KyberReputation[faction] or 0
        local tier = KYBER.Reputation:GetTier(rep)
        
        if rep < -1000 then
            activator:ChatPrint("The vendor refuses to deal with you. (Reputation too low)")
            return
        end
        
        -- Open special vendor menu with reputation prices
        net.Start("Kyber_Vendor_Open")
        net.WriteString(faction)
        net.WriteInt(rep, 16)
        net.Send(activator)
    end
    
    -- Register entity
    scripted_ents.Register(ENT, "kyber_faction_vendor")
end

-- Mission rewards based on reputation
if SERVER then
    hook.Add("Kyber_Mission_Complete", "ReputationMissionRewards", function(ply, mission)
        -- Grant reputation based on mission faction
        if mission.faction then
            local repGain = mission.reputationReward or 100
            KYBER.Reputation:ChangeReputation(ply, mission.faction, repGain, "Completed mission: " .. mission.name)
        end
        
        -- Bonus rewards for high reputation
        if mission.faction then
            local rep = ply.KyberReputation[mission.faction] or 0
            
            if rep >= 5000 then
                -- Double credit reward for Revered+
                local bonus = mission.creditReward or 0
                KYBER:SetPlayerData(ply, "credits", (KYBER:GetPlayerData(ply, "credits") or 0) + bonus)
                ply:ChatPrint("Reputation bonus: +" .. bonus .. " credits!")
            end
        end
    end)
end

-- Trading restrictions based on reputation
if SERVER then
    hook.Add("Kyber_Trading_CanTrade", "ReputationTradeRestrictions", function(ply1, ply2)
        -- Check if players are from hostile factions
        local faction1 = ply1:GetNWString("kyber_faction", "")
        local faction2 = ply2:GetNWString("kyber_faction", "")
        
        if faction1 ~= "" and faction2 ~= "" and faction1 ~= faction2 then
            local factionData1 = KYBER.Reputation.Factions[faction1]
            if factionData1 and factionData1.relationships then
                local relationship = factionData1.relationships[faction2] or 0
                
                if relationship <= -0.8 then
                    return false, "Cannot trade with hostile faction members"
                end
            end
        end
        
        return true
    end)
end

-- Force lottery bonus for high Jedi reputation
if SERVER then
    hook.Add("Kyber_ForceLottery_GetChance", "ReputationForceBonus", function(ply)
        local jediRep = ply.KyberReputation["jedi"] or 0
        
        if jediRep >= 5000 then
            return 0.1 -- 10% chance for Revered+
        elseif jediRep >= 2500 then
            return 0.075 -- 7.5% chance for Honored+
        elseif jediRep >= 1000 then
            return 0.06 -- 6% chance for Liked+
        end
        
        return 0.05 -- Default 5%
    end)
end

-- Faction-specific chat colors based on reputation
if CLIENT then
    hook.Add("OnPlayerChat", "ReputationChatColors", function(ply, text, teamChat, isDead)
        if not IsValid(ply) then return end
        
        local faction = ply:GetNWString("kyber_faction", "")
        if faction == "" then return end
        
        local myRep = LocalPlayer().KyberReputation[faction] or 0
        local tier = KYBER.Reputation:GetTier(myRep)
        
        -- Color player name based on reputation
        local nameColor = tier.color
        
        if myRep >= 5000 then
            -- Special effect for high reputation
            nameColor = HSVToColor((CurTime() * 50) % 360, 0.5, 1)
        end
        
        chat.AddText(
            nameColor, ply:Nick(),
            Color(255, 255, 255), ": ",
            text
        )
        
        return true
    end)
end

-- Add reputation info to character sheet
if SERVER then
    hook.Add("Kyber_CharacterSheet_AddInfo", "AddReputationInfo", function(ply)
        local info = {}
        
        -- Find highest reputation
        local highest = {faction = nil, rep = 0}
        local lowest = {faction = nil, rep = 0}
        
        for factionID, rep in pairs(ply.KyberReputation or {}) do
            if rep > highest.rep then
                highest.faction = factionID
                highest.rep = rep
            end
            if rep < lowest.rep then
                lowest.faction = factionID
                lowest.rep = rep
            end
        end
        
        if highest.faction then
            local faction = KYBER.Reputation.Factions[highest.faction]
            local tier = KYBER.Reputation:GetTier(highest.rep)
            table.insert(info, {
                label = "Highest Reputation",
                value = faction.name .. " (" .. tier.name .. ")"
            })
        end
        
        if lowest.faction then
            local faction = KYBER.Reputation.Factions[lowest.faction]
            local tier = KYBER.Reputation:GetTier(lowest.rep)
            table.insert(info, {
                label = "Lowest Reputation",
                value = faction.name .. " (" .. tier.name .. ")"
            })
        end
        
        return info
    end)
end

-- Reputation-based spawning
if SERVER then
    hook.Add("PlayerSelectSpawn", "ReputationSpawnPoints", function(ply)
        -- High reputation players get better spawn points
        local spawnPoints = {}
        
        for factionID, rep in pairs(ply.KyberReputation or {}) do
            if rep >= 2500 then
                -- Add faction-specific spawn points
                local spawns = ents.FindByClass("info_player_" .. factionID)
                table.Add(spawnPoints, spawns)
            end
        end
        
        if #spawnPoints > 0 then
            return spawnPoints[math.random(#spawnPoints)]
        end
    end)
end

-- Console command to check all reputations
if CLIENT then
    concommand.Add("kyber_rep_check", function()
        print("=== Your Reputation ===")
        
        local sorted = {}
        for factionID, rep in pairs(LocalPlayer().KyberReputation or {}) do
            table.insert(sorted, {id = factionID, rep = rep})
        end
        
        table.sort(sorted, function(a, b)
            return a.rep > b.rep
        end)
        
        for _, data in ipairs(sorted) do
            local faction = KYBER.Reputation.Factions[data.id]
            local tier = KYBER.Reputation:GetTier(data.rep)
            
            if faction then
                print(string.format("%-20s: %-10s (%d)", faction.name, tier.name, data.rep))
            end
        end
    end)
end