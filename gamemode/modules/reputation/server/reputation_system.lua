-- kyber/modules/reputation/system.lua
KYBER.Reputation = KYBER.Reputation or {}

-- Reputation tiers
KYBER.Reputation.Tiers = {
    {min = -10000, name = "Hostile", color = Color(255, 0, 0)},
    {min = -5000, name = "Hated", color = Color(255, 50, 0)},
    {min = -2500, name = "Unfriendly", color = Color(255, 100, 0)},
    {min = -1000, name = "Disliked", color = Color(255, 150, 0)},
    {min = -500, name = "Suspicious", color = Color(255, 200, 0)},
    {min = 0, name = "Neutral", color = Color(200, 200, 200)},
    {min = 500, name = "Friendly", color = Color(150, 255, 150)},
    {min = 1000, name = "Liked", color = Color(100, 255, 100)},
    {min = 2500, name = "Honored", color = Color(50, 255, 50)},
    {min = 5000, name = "Revered", color = Color(0, 255, 0)},
    {min = 10000, name = "Exalted", color = Color(0, 255, 255)}
}

-- Faction definitions with relationships
KYBER.Reputation.Factions = {
    ["republic"] = {
        name = "Galactic Republic",
        description = "The democratic government of the galaxy",
        relationships = {
            imperial = -1.0,      -- Hostile
            rebel = 0.5,          -- Friendly
            jedi = 0.8,           -- Allied
            sith = -1.0,          -- Hostile
            mandalorian = 0,      -- Neutral
            bounty = -0.2,        -- Slightly negative
            hutt = -0.5,          -- Unfriendly
            black_sun = -0.8      -- Very unfriendly
        }
    },
    
    ["imperial"] = {
        name = "Imperial Remnant",
        description = "The remains of the Galactic Empire",
        relationships = {
            republic = -1.0,
            rebel = -1.0,
            jedi = -1.0,
            sith = 0.5,
            mandalorian = -0.3,
            bounty = 0.2,
            hutt = -0.3,
            black_sun = -0.5
        }
    },
    
    ["rebel"] = {
        name = "Rebel Alliance",
        description = "Freedom fighters against tyranny",
        relationships = {
            republic = 0.5,
            imperial = -1.0,
            jedi = 0.7,
            sith = -1.0,
            mandalorian = 0.2,
            bounty = -0.3,
            hutt = -0.4,
            black_sun = -0.7
        }
    },
    
    ["jedi"] = {
        name = "Jedi Order",
        description = "Guardians of peace and justice",
        relationships = {
            republic = 0.8,
            imperial = -1.0,
            rebel = 0.7,
            sith = -1.0,
            mandalorian = 0,
            bounty = -0.5,
            hutt = -0.6,
            black_sun = -0.8
        }
    },
    
    ["sith"] = {
        name = "Sith Cult",
        description = "Dark side Force users",
        relationships = {
            republic = -1.0,
            imperial = 0.5,
            rebel = -1.0,
            jedi = -1.0,
            mandalorian = -0.2,
            bounty = 0.3,
            hutt = 0.2,
            black_sun = 0.4
        }
    },
    
    ["mandalorian"] = {
        name = "Mandalorian Clans",
        description = "Warrior culture of Mandalore",
        relationships = {
            republic = 0,
            imperial = -0.3,
            rebel = 0.2,
            jedi = 0,
            sith = -0.2,
            bounty = 0.5,
            hutt = 0.1,
            black_sun = 0
        }
    },
    
    ["bounty"] = {
        name = "Bounty Hunters Guild",
        description = "Professional hunters for hire",
        relationships = {
            republic = -0.2,
            imperial = 0.2,
            rebel = -0.3,
            jedi = -0.5,
            sith = 0.3,
            mandalorian = 0.5,
            hutt = 0.6,
            black_sun = 0.4
        }
    },
    
    ["hutt"] = {
        name = "Hutt Cartel",
        description = "Criminal empire of the Hutts",
        relationships = {
            republic = -0.5,
            imperial = -0.3,
            rebel = -0.4,
            jedi = -0.6,
            sith = 0.2,
            mandalorian = 0.1,
            bounty = 0.6,
            black_sun = 0.3
        }
    },
    
    ["black_sun"] = {
        name = "Black Sun Syndicate",
        description = "Galaxy-spanning crime organization",
        relationships = {
            republic = -0.8,
            imperial = -0.5,
            rebel = -0.7,
            jedi = -0.8,
            sith = 0.4,
            mandalorian = 0,
            bounty = 0.4,
            hutt = 0.3
        }
    }
}

-- Reputation rewards/penalties
KYBER.Reputation.Rewards = {
    -- Faction-specific rewards at different tiers
    ["mandalorian"] = {
        [500] = {type = "recipe", id = "armor_mandalorian_basic", name = "Basic Mandalorian Armor Recipe"},
        [1000] = {type = "discount", value = 0.1, name = "10% Mandalorian vendor discount"},
        [2500] = {type = "access", id = "mandalorian_forge", name = "Access to Mandalorian Forge"},
        [5000] = {type = "recipe", id = "beskar_refined", name = "Beskar Refining Recipe"},
        [10000] = {type = "title", id = "mandalorian_ally", name = "Mandalorian Ally title"}
    },
    
    ["jedi"] = {
        [500] = {type = "training", id = "force_meditation", name = "Force Meditation training"},
        [1000] = {type = "item", id = "jedi_holocron", name = "Jedi Holocron"},
        [2500] = {type = "access", id = "jedi_archives", name = "Jedi Archives access"},
        [5000] = {type = "training", id = "advanced_force", name = "Advanced Force techniques"},
        [10000] = {type = "title", id = "jedi_friend", name = "Friend of the Jedi title"}
    },
    
    ["bounty"] = {
        [500] = {type = "contracts", level = 1, name = "Access to basic bounties"},
        [1000] = {type = "discount", value = 0.15, name = "15% equipment discount"},
        [2500] = {type = "contracts", level = 2, name = "Access to advanced bounties"},
        [5000] = {type = "item", id = "hunter_beacon", name = "Hunter's Beacon"},
        [10000] = {type = "title", id = "master_hunter", name = "Master Hunter title"}
    }
}

if SERVER then
    util.AddNetworkString("Kyber_Reputation_Update")
    util.AddNetworkString("Kyber_Reputation_Open")
    util.AddNetworkString("Kyber_Reputation_Change")
    
    -- Initialize reputation
    function KYBER.Reputation:Initialize(ply)
        ply.KyberReputation = {}
        
        -- Load saved reputation
        local steamID = ply:SteamID64()
        local charName = ply:GetNWString("kyber_name", "default")
        local path = "kyber/reputation/" .. steamID .. "_" .. charName .. ".json"
        
        if file.Exists(path, "DATA") then
            local data = file.Read(path, "DATA")
            ply.KyberReputation = util.JSONToTable(data) or {}
        else
            -- Initialize neutral reputation with all factions
            for factionID, _ in pairs(self.Factions) do
                ply.KyberReputation[factionID] = 0
            end
        end
        
        -- Check rewards
        self:CheckRewards(ply)
        
        -- Send to client
        self:SendReputationUpdate(ply)
    end
    
    function KYBER.Reputation:Save(ply)
        if not IsValid(ply) or not ply.KyberReputation then return end
        
        local steamID = ply:SteamID64()
        local charName = ply:GetNWString("kyber_name", "default")
        local path = "kyber/reputation/" .. steamID .. "_" .. charName .. ".json"
        
        if not file.Exists("kyber/reputation", "DATA") then
            file.CreateDir("kyber/reputation")
        end
        
        file.Write(path, util.TableToJSON(ply.KyberReputation))
    end
    
    -- Change reputation
    function KYBER.Reputation:ChangeReputation(ply, factionID, amount, reason)
        if not self.Factions[factionID] then return end
        
        local oldRep = ply.KyberReputation[factionID] or 0
        local newRep = math.Clamp(oldRep + amount, -10000, 10000)
        
        ply.KyberReputation[factionID] = newRep
        
        -- Apply relationship changes
        local faction = self.Factions[factionID]
        if faction.relationships then
            for relatedID, modifier in pairs(faction.relationships) do
                if relatedID ~= factionID then
                    local relatedChange = amount * modifier * 0.5 -- 50% of main change
                    local relatedOld = ply.KyberReputation[relatedID] or 0
                    ply.KyberReputation[relatedID] = math.Clamp(relatedOld + relatedChange, -10000, 10000)
                end
            end
        end
        
        -- Check for tier changes
        local oldTier = self:GetTier(oldRep)
        local newTier = self:GetTier(newRep)
        
        if oldTier.name ~= newTier.name then
            -- Tier changed
            net.Start("Kyber_Reputation_Change")
            net.WriteString(factionID)
            net.WriteString(self.Factions[factionID].name)
            net.WriteString(newTier.name)
            net.WriteColor(newTier.color)
            net.WriteBool(newRep > oldRep) -- Is increase
            net.Send(ply)
            
            -- Check rewards
            self:CheckRewards(ply)
        end
        
        -- Send update
        self:SendReputationUpdate(ply)
        
        -- Log change
        if reason then
            print("[Reputation] " .. ply:Nick() .. " " .. factionID .. ": " .. 
                  oldRep .. " -> " .. newRep .. " (" .. reason .. ")")
        end
    end
    
    -- Get reputation tier
    function KYBER.Reputation:GetTier(reputation)
        for i = #self.Tiers, 1, -1 do
            if reputation >= self.Tiers[i].min then
                return self.Tiers[i]
            end
        end
        return self.Tiers[1]
    end
    
    -- Check and grant rewards
    function KYBER.Reputation:CheckRewards(ply)
        if not ply.KyberReputationRewards then
            ply.KyberReputationRewards = {}
        end
        
        for factionID, reputation in pairs(ply.KyberReputation) do
            local rewards = self.Rewards[factionID]
            if rewards then
                for threshold, reward in pairs(rewards) do
                    if reputation >= threshold then
                        local rewardKey = factionID .. "_" .. threshold
                        
                        if not ply.KyberReputationRewards[rewardKey] then
                            -- Grant reward
                            self:GrantReward(ply, factionID, reward)
                            ply.KyberReputationRewards[rewardKey] = true
                        end
                    end
                end
            end
        end
    end
    
    function KYBER.Reputation:GrantReward(ply, factionID, reward)
        local faction = self.Factions[factionID]
        
        if reward.type == "recipe" then
            KYBER.Crafting:LearnRecipe(ply, reward.id)
            ply:ChatPrint("Reputation Reward: Learned " .. reward.name)
            
        elseif reward.type == "discount" then
            -- Store discount for Grand Exchange
            ply:SetNWFloat("kyber_discount_" .. factionID, reward.value)
            ply:ChatPrint("Reputation Reward: " .. reward.name)
            
        elseif reward.type == "access" then
            -- Grant access to special areas/stations
            ply:SetNWBool("kyber_access_" .. reward.id, true)
            ply:ChatPrint("Reputation Reward: " .. reward.name)
            
        elseif reward.type == "item" then
            KYBER.Inventory:GiveItem(ply, reward.id, 1)
            ply:ChatPrint("Reputation Reward: Received " .. reward.name)
            
        elseif reward.type == "title" then
            -- Grant title (integrate with your title system)
            ply:SetNWString("kyber_title_" .. reward.id, reward.name)
            ply:ChatPrint("Reputation Reward: Earned title '" .. reward.name .. "'")
            
        elseif reward.type == "contracts" then
            -- Enable bounty contract level
            ply:SetNWInt("kyber_bounty_level", reward.level)
            ply:ChatPrint("Reputation Reward: " .. reward.name)
            
        elseif reward.type == "training" then
            -- Grant Force training (integrate with Force system)
            ply:SetNWBool("kyber_training_" .. reward.id, true)
            ply:ChatPrint("Reputation Reward: " .. reward.name)
        end
        
        -- Sound effect
        ply:EmitSound("buttons/button9.wav")
    end
    
    -- Get faction discount for Grand Exchange
    function KYBER.Reputation:GetDiscount(ply, itemID)
        local item = KYBER.GrandExchange.Items[itemID]
        if not item then return 0 end
        
        -- Check which faction sells this item
        local bestDiscount = 0
        
        for factionID, _ in pairs(self.Factions) do
            local discount = ply:GetNWFloat("kyber_discount_" .. factionID, 0)
            if discount > bestDiscount then
                bestDiscount = discount
            end
        end
        
        return bestDiscount
    end
    
    -- Send reputation update to client
    function KYBER.Reputation:SendReputationUpdate(ply)
        net.Start("Kyber_Reputation_Update")
        net.WriteTable(ply.KyberReputation)
        net.Send(ply)
    end
    
    -- Reputation decay over time
    timer.Create("KyberReputationDecay", 3600, 0, function() -- Every hour
        for _, ply in ipairs(player.GetAll()) do
            if ply.KyberReputation then
                for factionID, rep in pairs(ply.KyberReputation) do
                    if math.abs(rep) > 100 then
                        -- Decay towards neutral
                        local decay = rep > 0 and -10 or 10
                        KYBER.Reputation:ChangeReputation(ply, factionID, decay, "Time decay")
                    end
                end
            end
        end
    end)
    
    -- Hooks for reputation changes
    hook.Add("OnNPCKilled", "KyberReputationNPCKill", function(npc, attacker, inflictor)
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        
        -- Get NPC faction from its class or model
        local npcFaction = nil
        local npcClass = npc:GetClass()
        
        -- Example faction assignments
        if string.find(npcClass, "rebel") then
            npcFaction = "rebel"
        elseif string.find(npcClass, "combine") or string.find(npcClass, "metro") then
            npcFaction = "imperial"
        elseif string.find(npcClass, "antlion") then
            npcFaction = "black_sun" -- Criminals
        end
        
        if npcFaction then
            KYBER.Reputation:ChangeReputation(attacker, npcFaction, -50, "Killed " .. npcFaction .. " NPC")
        end
    end)
    
    hook.Add("PlayerDeath", "KyberReputationPlayerKill", function(victim, inflictor, attacker)
        if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then return end
        
        -- Lose reputation for killing players of certain factions
        local victimFaction = victim:GetNWString("kyber_faction", "")
        if victimFaction ~= "" then
            KYBER.Reputation:ChangeReputation(attacker, victimFaction, -100, "Killed faction member")
        end
    end)
    
    -- Hooks
    hook.Add("PlayerInitialSpawn", "KyberReputationInit", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                KYBER.Reputation:Initialize(ply)
            end
        end)
    end)
    
    hook.Add("PlayerDisconnected", "KyberReputationSave", function(ply)
        KYBER.Reputation:Save(ply)
    end)
    
    -- Commands
    concommand.Add("kyber_reputation", function(ply)
        net.Start("Kyber_Reputation_Open")
        net.Send(ply)
    end)
    
    concommand.Add("kyber_setrep", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local target = ply
        if args[1] then
            target = player.GetBySteamID(args[1]) or ply
        end
        
        local faction = args[2]
        local amount = tonumber(args[3]) or 0
        
        if not faction or not KYBER.Reputation.Factions[faction] then
            ply:ChatPrint("Invalid faction. Available factions:")
            for id, data in pairs(KYBER.Reputation.Factions) do
                ply:ChatPrint("- " .. id .. " (" .. data.name .. ")")
            end
            return
        end
        
        target.KyberReputation[faction] = amount
        KYBER.Reputation:CheckRewards(target)
        KYBER.Reputation:SendReputationUpdate(target)
        
        ply:ChatPrint("Set " .. target:Nick() .. "'s " .. faction .. " reputation to " .. amount)
    end)
    
else -- CLIENT
    
    local ReputationFrame = nil
    
    net.Receive("Kyber_Reputation_Update", function()
        local reputation = net.ReadTable()
        LocalPlayer().KyberReputation = reputation
        
        if IsValid(ReputationFrame) then
            KYBER.Reputation:RefreshUI()
        end
    end)
    
    net.Receive("Kyber_Reputation_Change", function()
        local factionID = net.ReadString()
        local factionName = net.ReadString()
        local tierName = net.ReadString()
        local tierColor = net.ReadColor()
        local isIncrease = net.ReadBool()
        
        -- Fancy notification
        chat.AddText(
            Color(255, 255, 255), "Reputation with ",
            tierColor, factionName,
            Color(255, 255, 255), " changed to ",
            tierColor, tierName
        )
        
        -- Sound
        surface.PlaySound(isIncrease and "buttons/button9.wav" or "buttons/button8.wav")
        
        -- Screen effect
        if math.abs(LocalPlayer().KyberReputation[factionID]) >= 5000 then
            -- Major reputation milestone
            notification.AddLegacy("REPUTATION MILESTONE: " .. tierName .. " with " .. factionName, 
                                 isIncrease and NOTIFY_GENERIC or NOTIFY_ERROR, 5)
        end
    end)
    
    net.Receive("Kyber_Reputation_Open", function()
        KYBER.Reputation:OpenUI()
    end)
    
    function KYBER.Reputation:OpenUI()
        if IsValid(ReputationFrame) then
            ReputationFrame:Remove()
            return
        end
        
        ReputationFrame = vgui.Create("DFrame")
        ReputationFrame:SetSize(800, 600)
        ReputationFrame:Center()
        ReputationFrame:SetTitle("Reputation")
        ReputationFrame:MakePopup()
        
        local scroll = vgui.Create("DScrollPanel", ReputationFrame)
        scroll:Dock(FILL)
        scroll:DockMargin(10, 10, 10, 10)
        
        self:RefreshUI()
    end
    
    function KYBER.Reputation:RefreshUI()
        if not IsValid(ReputationFrame) then return end
        
        local scroll = ReputationFrame:GetChildren()[1]
        scroll:Clear()
        
        local reputation = LocalPlayer().KyberReputation or {}
        
        -- Sort factions by reputation
        local sortedFactions = {}
        for factionID, _ in pairs(self.Factions) do
            table.insert(sortedFactions, factionID)
        end
        
        table.sort(sortedFactions, function(a, b)
            return (reputation[a] or 0) > (reputation[b] or 0)
        end)
        
        -- Display each faction
        for _, factionID in ipairs(sortedFactions) do
            local faction = self.Factions[factionID]
            local rep = reputation[factionID] or 0
            local tier = self:GetTier(rep)
            
            local factionPanel = vgui.Create("DPanel", scroll)
            factionPanel:Dock(TOP)
            factionPanel:DockMargin(0, 0, 0, 10)
            factionPanel:SetTall(80)
            
            factionPanel.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
                
                -- Faction name
                draw.SimpleText(faction.name, "DermaLarge", 10, 10, Color(255, 255, 255))
                
                -- Description
                draw.SimpleText(faction.description, "DermaDefault", 10, 35, Color(200, 200, 200))
                
                -- Reputation tier
                draw.SimpleText(tier.name, "DermaDefaultBold", w - 100, 10, tier.color, TEXT_ALIGN_RIGHT)
                
                -- Reputation value
                draw.SimpleText(rep .. "/10000", "DermaDefault", w - 100, 30, Color(200, 200, 200), TEXT_ALIGN_RIGHT)
                
                -- Reputation bar
                local barWidth = w - 220
                local barX = 10
                local barY = 55
                
                -- Background
                draw.RoundedBox(2, barX, barY, barWidth, 15, Color(50, 50, 50))
                
                -- Fill
                local fillWidth = math.abs(rep) / 10000 * barWidth
                local fillColor = rep >= 0 and Color(100, 255, 100) or Color(255, 100, 100)
                
                if rep >= 0 then
                    draw.RoundedBox(2, barX + barWidth/2, barY, fillWidth/2, 15, fillColor)
                else
                    draw.RoundedBox(2, barX + barWidth/2 - fillWidth/2, barY, fillWidth/2, 15, fillColor)
                end
                
                -- Center line
                draw.RoundedBox(0, barX + barWidth/2 - 1, barY, 2, 15, Color(255, 255, 255))
                
                -- Show rewards
                local rewards = KYBER.Reputation.Rewards[factionID]
                if rewards then
                    local nextReward = nil
                    local nextThreshold = 0
                    
                    for threshold, reward in pairs(rewards) do
                        if rep < threshold and (not nextReward or threshold < nextThreshold) then
                            nextReward = reward
                            nextThreshold = threshold
                        end
                    end
                    
                    if nextReward then
                        draw.SimpleText("Next: " .. nextReward.name .. " (" .. nextThreshold .. ")", 
                                      "DermaDefault", w - 100, 50, Color(255, 255, 100), TEXT_ALIGN_RIGHT)
                    end
                end
            end
            
            -- Hover for relationships
            factionPanel:SetTooltip(self:GetRelationshipTooltip(factionID))
        end
    end
    
    function KYBER.Reputation:GetRelationshipTooltip(factionID)
        local faction = self.Factions[factionID]
        if not faction.relationships then return "" end
        
        local tooltip = "Relationships:\n"
        
        for relatedID, modifier in pairs(faction.relationships) do
            local related = self.Factions[relatedID]
            if related then
                local relationship = "Neutral"
                if modifier >= 0.5 then
                    relationship = "Allied"
                elseif modifier > 0 then
                    relationship = "Friendly"
                elseif modifier <= -0.5 then
                    relationship = "Hostile"
                elseif modifier < 0 then
                    relationship = "Unfriendly"
                end
                
                tooltip = tooltip .. related.name .. ": " .. relationship .. "\n"
            end
        end
        
        return tooltip
    end
    
    function KYBER.Reputation:GetTier(reputation)
        for i = #self.Tiers, 1, -1 do
            if reputation >= self.Tiers[i].min then
                return self.Tiers[i]
            end
        end
        return self.Tiers[1]
    end
    
    -- Add to datapad
    hook.Add("Kyber_Datapad_AddTabs", "AddReputationTab", function(tabSheet)
        local repPanel = vgui.Create("DPanel", tabSheet)
        repPanel:Dock(FILL)
        
        local openBtn = vgui.Create("DButton", repPanel)
        openBtn:SetText("Open Reputation Panel")
        openBtn:SetSize(200, 50)
        openBtn:SetPos(20, 20)
        openBtn.DoClick = function()
            RunConsoleCommand("kyber_reputation")
        end
        
        -- Quick reputation overview
        local overviewPanel = vgui.Create("DPanel", repPanel)
        overviewPanel:SetPos(20, 80)
        overviewPanel:SetSize(600, 400)
        
        overviewPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            
            draw.SimpleText("Reputation Overview", "DermaDefaultBold", 10, 10, Color(255, 255, 255))
            
            local y = 35
            local reputation = LocalPlayer().KyberReputation or {}
            
            -- Show top positive and negative reputations
            local sorted = {}
            for factionID, rep in pairs(reputation) do
                table.insert(sorted, {id = factionID, rep = rep})
            end
            
            table.sort(sorted, function(a, b)
                return math.abs(a.rep) > math.abs(b.rep)
            end)
            
            for i = 1, math.min(8, #sorted) do
                local data = sorted[i]
                local faction = KYBER.Reputation.Factions[data.id]
                if faction then
                    local tier = KYBER.Reputation:GetTier(data.rep)
                    
                    draw.SimpleText(faction.name .. ":", "DermaDefault", 20, y, Color(200, 200, 200))
                    draw.SimpleText(tier.name, "DermaDefault", 200, y, tier.color)
                    draw.SimpleText(data.rep, "DermaDefault", 350, y, Color(200, 200, 200))
                    
                    y = y + 20
                end
            end
        end
        
        tabSheet:AddSheet("Reputation", repPanel, "icon16/star.png")
    end)
    
    -- HUD indicator for extreme reputations
    hook.Add("HUDPaint", "KyberReputationHUD", function()
        local reputation = LocalPlayer().KyberReputation
        if not reputation then return end
        
        local y = ScrH() - 250
        
        for factionID, rep in pairs(reputation) do
            if math.abs(rep) >= 5000 then
                local faction = KYBER.Reputation.Factions[factionID]
                local tier = KYBER.Reputation:GetTier(rep)
                
                if faction and tier then
                    draw.SimpleText(faction.name .. ": " .. tier.name, "DermaDefault", 10, y, tier.color)
                    y = y - 20
                end
            end
        end
    end)
end