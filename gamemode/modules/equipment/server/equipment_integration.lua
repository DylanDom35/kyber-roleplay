        -- Apply accuracy modifier
        if stats.accuracy ~= 0 then
            local spread = data.Spread or Vector(0, 0, 0)
            local accuracyMod = 1 - (stats.accuracy / 100) -- Negative accuracy increases spread
            
            data.Spread = spread * accuracyMod
            return true
        end
    end)
    
    -- Healing bonus integration
    hook.Add("Kyber_PlayerHeal", "EquipmentHealingBonus", function(ply, amount)
        local stats = ply.KyberStats
        if not stats or stats.healing_bonus <= 0 then return end
        
        local bonus = amount * (stats.healing_bonus / 100)
        return amount + bonus
    end)
    
    -- Force regeneration for Force users
    if KYBER.ForceLottery then
        timer.Create("KyberForceRegen", 1, 0, function()
            for _, ply in ipairs(player.GetAll()) do
                if IsValid(ply) and ply:GetNWBool("kyber_force_sensitive", false) then
                    local stats = ply.KyberStats
                    if stats and stats.force_regen > 0 then
                        -- Regenerate Force power (integrate with your Force system)
                        local currentForce = ply:GetNWInt("kyber_force_power", 0)
                        local maxForce = ply:GetNWInt("kyber_max_force_power", 100)
                        
                        if currentForce < maxForce then
                            local regen = stats.force_regen / 10 -- 1 point per 10 seconds per stat point
                            ply:SetNWInt("kyber_force_power", math.min(currentForce + regen, maxForce))
                        end
                    end
                end
            end
        end)
    end
    
    -- Intimidation check command
    concommand.Add("kyber_intimidate", function(ply)
        local stats = ply.KyberStats
        if not stats or stats.intimidation <= 0 then
            ply:ChatPrint("You lack the equipment to intimidate others.")
            return
        end
        
        local trace = ply:GetEyeTrace()
        if IsValid(trace.Entity) and trace.Entity:IsPlayer() and trace.Entity:GetPos():Distance(ply:GetPos()) < 200 then
            local target = trace.Entity
            
            -- Roll intimidation check
            local roll = math.random(1, 20) + stats.intimidation
            
            if roll >= 15 then
                -- Success
                target:EmitSound("vo/npc/male01/ohno.wav")
                target:SetNWBool("kyber_intimidated", true)
                target:SetNWFloat("kyber_intimidated_until", CurTime() + 10)
                
                -- Apply fear effect
                target:SetWalkSpeed(target:GetWalkSpeed() * 0.7)
                target:SetRunSpeed(target:GetRunSpeed() * 0.7)
                
                timer.Simple(10, function()
                    if IsValid(target) then
                        target:SetNWBool("kyber_intimidated", false)
                        KYBER.Equipment:RecalculateStats(target) -- Reset speed
                    end
                end)
                
                ply:ChatPrint("You successfully intimidated " .. target:Nick())
                target:ChatPrint("You are intimidated by " .. ply:Nick())
            else
                ply:ChatPrint("Your intimidation attempt failed.")
            end
        end
    end)
    
    -- Equipment durability system (optional)
    hook.Add("EntityTakeDamage", "KyberEquipmentDurability", function(target, dmginfo)
        if not IsValid(target) or not target:IsPlayer() then return end
        
        -- Small chance equipment takes durability damage
        if math.random() > 0.95 then
            local slots = {"head", "chest", "legs", "feet", "hands"}
            local slot = slots[math.random(#slots)]
            
            local equipped = target.KyberEquipment[slot]
            if equipped then
                equipped.durability = (equipped.durability or 100) - math.random(1, 5)
                
                if equipped.durability <= 0 then
                    local item = KYBER.Equipment.Items[equipped.id]
                    target:ChatPrint("Your " .. item.name .. " has broken!")
                    
                    -- Remove the item
                    target.KyberEquipment[slot] = nil
                    KYBER.Equipment:RecalculateStats(target)
                    KYBER.Equipment:SendEquipmentUpdate(target)
                elseif equipped.durability <= 20 then
                    target:ChatPrint("Your equipment is badly damaged!")
                end
            end
        end
    end)
    
else -- CLIENT
    
    -- Add equipment tab to datapad
    hook.Add("Kyber_Datapad_AddTabs", "AddEquipmentTab", function(tabSheet)
        local equipPanel = vgui.Create("DPanel", tabSheet)
        equipPanel:Dock(FILL)
        
        local openEquipBtn = vgui.Create("DButton", equipPanel)
        openEquipBtn:SetText("Open Equipment (C)")
        openEquipBtn:SetSize(200, 50)
        openEquipBtn:SetPos(20, 20)
        openEquipBtn.DoClick = function()
            RunConsoleCommand("kyber_equipment")
        end
        
        -- Quick stats display
        local statsPanel = vgui.Create("DPanel", equipPanel)
        statsPanel:SetPos(20, 80)
        statsPanel:SetSize(600, 200)
        
        statsPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            
            draw.SimpleText("Equipment Overview", "DermaDefaultBold", 10, 10, Color(255, 255, 255))
            
            local stats = LocalPlayer().KyberStats or {}
            local y = 30
            
            -- Display current stats
            draw.SimpleText("Current Stats:", "DermaDefault", 10, y, Color(200, 200, 200))
            y = y + 20
            
            for stat, value in pairs(stats) do
                if value ~= 0 then
                    local statName = string.gsub(stat, "_", " ")
                    statName = string.upper(string.sub(statName, 1, 1)) .. string.sub(statName, 2)
                    
                    local color = value > 0 and Color(100, 255, 100) or Color(255, 100, 100)
                    local prefix = value > 0 and "+" or ""
                    
                    draw.SimpleText("• " .. statName .. ": " .. prefix .. value, "DermaDefault", 20, y, color)
                    y = y + 18
                end
            end
            
            -- Equipment slots status
            draw.SimpleText("Equipment Slots:", "DermaDefault", 300, 30, Color(200, 200, 200))
            
            local equipment = LocalPlayer().KyberEquipment or {}
            local slotY = 50
            
            for slotID, slotData in pairs(KYBER.Equipment.Slots) do
                local equipped = equipment[slotID]
                local text = slotData.name .. ": "
                
                if equipped then
                    local item = KYBER.Equipment.Items[equipped.id]
                    text = text .. (item and item.name or "Unknown")
                    draw.SimpleText(text, "DermaDefault", 300, slotY, Color(100, 255, 100))
                else
                    text = text .. "Empty"
                    draw.SimpleText(text, "DermaDefault", 300, slotY, Color(150, 150, 150))
                end
                
                slotY = slotY + 18
            end
        end
        
        tabSheet:AddSheet("Equipment", equipPanel, "icon16/user_suit.png")
    end)
    
    -- Visual effects for equipment
    hook.Add("PostPlayerDraw", "KyberEquipmentVisuals", function(ply)
        -- This is where PAC3 integration would go
        -- For now, we can add simple visual indicators
        
        local equipment = ply.KyberEquipment
        if not equipment then return end
        
        -- Example: Jetpack visual
        if equipment.back then
            local item = KYBER.Equipment.Items[equipment.back.id]
            if item and item.abilities and table.HasValue(item.abilities, "jetpack_flight") then
                -- Draw jetpack flames when flying
                if ply:GetVelocity():Length() > 100 and ply:GetMoveType() == MOVETYPE_WALK and not ply:OnGround() then
                    local attach = ply:GetAttachment(ply:LookupAttachment("chest"))
                    if attach then
                        local effectdata = EffectData()
                        effectdata:SetOrigin(attach.Pos - ply:GetForward() * 20)
                        effectdata:SetNormal(-ply:GetUp())
                        effectdata:SetScale(0.5)
                        util.Effect("thruster_ring", effectdata)
                    end
                end
            end
        end
    end)
    
    -- HUD indicators for equipment status
    hook.Add("HUDPaint", "KyberEquipmentHUD", function()
        local ply = LocalPlayer()
        local equipment = ply.KyberEquipment
        if not equipment then return end
        
        -- Show broken equipment warnings
        local y = ScrH() - 200
        
        for slot, equipped in pairs(equipment) do
            if equipped.durability and equipped.durability <= 20 then
                local item = KYBER.Equipment.Items[equipped.id]
                if item then
                    local color = equipped.durability <= 0 and Color(255, 50, 50) or Color(255, 200, 50)
                    draw.SimpleText(item.name .. " DAMAGED!", "DermaDefault", 10, y, color)
                    y = y - 20
                end
            end
        end
        
        -- Intimidation indicator
        if ply:GetNWBool("kyber_intimidated", false) then
            local timeLeft = ply:GetNWFloat("kyber_intimidated_until", 0) - CurTime()
            if timeLeft > 0 then
                draw.SimpleText("INTIMIDATED", "DermaLarge", ScrW() / 2, 100, Color(255, 100, 100), TEXT_ALIGN_CENTER)
                draw.SimpleText(math.ceil(timeLeft) .. "s", "DermaDefault", ScrW() / 2, 130, Color(255, 100, 100), TEXT_ALIGN_CENTER)
            end
        end
    end)
    
    -- Context menu for equipment
    hook.Add("OnContextMenuOpen", "KyberEquipmentContext", function()
        if input.IsKeyDown(KEY_LALT) then
            RunConsoleCommand("kyber_equipment")
            return false
        end
    end)
end

-- Shared equipment set bonuses
KYBER.Equipment.Sets = {
    ["stormtrooper"] = {
        name = "Stormtrooper Set",
        pieces = {"helmet_trooper", "armor_trooper", "legs_trooper", "feet_trooper"},
        bonuses = {
            [2] = {armor = 5, accuracy = 5}, -- 2 pieces
            [4] = {armor = 15, accuracy = 10, intimidation = 5} -- Full set
        }
    },
    
    ["mandalorian"] = {
        name = "Mandalorian Set",
        pieces = {"helmet_mandalorian", "armor_beskar", "legs_beskar", "feet_beskar"},
        bonuses = {
            [2] = {armor = 10, blaster_resist = 10},
            [3] = {armor = 20, blaster_resist = 20, intimidation = 10},
            [4] = {armor = 30, blaster_resist = 30, intimidation = 20, jetpack_fuel = 20}
        }
    },
    
    ["jedi"] = {
        name = "Jedi Set",
        pieces = {"hood_jedi", "armor_jedi_robes", "legs_jedi", "feet_jedi"},
        bonuses = {
            [2] = {force_regen = 5, agility = 5},
            [3] = {force_regen = 10, agility = 10, stealth = 5},
            [4] = {force_regen = 20, agility = 20, stealth = 10, force_power = 20}
        }
    }
}

-- Calculate set bonuses
if SERVER then
    hook.Add("Kyber_Equipment_StatsCalculated", "CalculateSetBonuses", function(ply, stats)
        local equipment = ply.KyberEquipment
        if not equipment then return end
        
        -- Check each set
        for setID, setData in pairs(KYBER.Equipment.Sets) do
            local count = 0
            
            -- Count equipped pieces
            for _, itemID in ipairs(setData.pieces) do
                for slot, equipped in pairs(equipment) do
                    if equipped.id == itemID then
                        count = count + 1
                        break
                    end
                end
            end
            
            -- Apply bonuses
            if count >= 2 then
                for pieces, bonuses in pairs(setData.bonuses) do
                    if count >= pieces then
                        for stat, value in pairs(bonuses) do
                            stats[stat] = (stats[stat] or 0) + value
                        end
                    end
                end
            end
        end
    end)
end        if not stats or stats.stealth <= 0 then return end
        
        -- Reduce footstep volume based on stealth
        local stealthReduction = stats.stealth / 100
        return true, sound, volume * (1 - stealthReduction), rf
    end)
    
    -- Perception integration - extend entity visibility
    hook.Add("SetupPlayerVisibility", "KyberEquipmentPerception", function(ply)
        local stats = ply.KyberStats
        if not stats or stats.perception <= 0 then return end
        
        -- Extend PVS range based on perception
        local extraRange = stats.perception * 10
        local pos = ply:GetPos()
        
        for i = 1, 4 do
            local angle = i * 90
            local offset = Vector(math.cos(angle) * extraRange, math.sin(angle) * extraRange, 0)
            AddOriginToPVS(pos + offset)
        end
    end)
    
    -- Accuracy integration
    hook.Add("EntityFireBullets", "KyberEquipmentAccuracy", function(entity, data)
        if not IsValid(entity) or not entity:IsPlayer() then return end
        
        local stats = entity.KyberStats
        if not stats then return end
        
        -- Apply accuracy modifier
        if stats.accuracy ~= 0 then
            local spread = data.-- kyber/modules/equipment/integration.lua
-- Integration with other systems

-- Add equipment items to Grand Exchange
hook.Add("Initialize", "KyberEquipmentGEIntegration", function()
    timer.Simple(1, function()
        -- Add all equipment items to Grand Exchange
        for itemID, item in pairs(KYBER.Equipment.Items) do
            KYBER.GrandExchange.Items[itemID] = {
                name = item.name,
                description = item.description,
                category = "armor", -- You might want to add more categories
                basePrice = item.value or 1000,
                stackable = false, -- Equipment is not stackable
                icon = item.icon
            }
        end
    end)
end)

if SERVER then
    -- Add equipment stats to character sheet
    hook.Add("Kyber_CharacterSheet_AddInfo", "AddEquipmentStats", function(ply)
        local info = {}
        
        -- Total armor
        local armor = ply.KyberStats and ply.KyberStats.armor or 0
        table.insert(info, {
            label = "Total Armor",
            value = tostring(armor)
        })
        
        -- Equipment value
        local totalValue = 0
        for slot, equipped in pairs(ply.KyberEquipment or {}) do
            local item = KYBER.Equipment.Items[equipped.id]
            if item then
                totalValue = totalValue + (item.value or 0)
            end
        end
        
        table.insert(info, {
            label = "Equipment Value",
            value = totalValue .. " credits"
        })
        
        return info
    end)
    
    -- Combat integration - apply damage resistance
    hook.Add("EntityTakeDamage", "KyberEquipmentDamageReduction", function(target, dmginfo)
        if not IsValid(target) or not target:IsPlayer() then return end
        
        local stats = target.KyberStats
        if not stats then return end
        
        -- Apply armor damage reduction
        if stats.armor > 0 then
            local reduction = stats.armor / 100 -- 1 armor = 1% reduction, max 100%
            reduction = math.min(reduction, 0.9) -- Cap at 90% reduction
            
            dmginfo:ScaleDamage(1 - reduction)
        end
        
        -- Apply blaster resistance for energy damage
        if dmginfo:IsDamageType(DMG_ENERGYBEAM) or dmginfo:IsDamageType(DMG_DISSOLVE) then
            if stats.blaster_resist > 0 then
                local resist = stats.blaster_resist / 100
                resist = math.min(resist, 0.5) -- Cap at 50% blaster resist
                
                dmginfo:ScaleDamage(1 - resist)
            end
        end
    end)
    
    -- Stealth integration
    hook.Add("PlayerFootstep", "KyberEquipmentStealth", function(ply, pos, foot, sound, volume, rf)
        local stats = ply.KyberStats
        if not stats or stats.stealth <= 0 