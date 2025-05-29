-- kyber/modules/medical/integration.lua
-- Integration with other systems

-- Add medical items to Grand Exchange
hook.Add("Initialize", "KyberMedicalItems", function()
    timer.Simple(1, function()
        -- Medical consumables
        local medicalItems = {
            ["medpac"] = {
                name = "Basic Medpac",
                description = "Standard medical supplies",
                category = "consumables",
                basePrice = 100,
                stackable = true,
                maxStack = 10
            },
            ["bacta_injection"] = {
                name = "Bacta Injection",
                description = "Concentrated healing solution",
                category = "consumables",
                basePrice = 500,
                stackable = true,
                maxStack = 5
            },
            ["surgical_kit"] = {
                name = "Surgical Kit",
                description = "Professional medical equipment",
                category = "consumables",
                basePrice = 1000,
                stackable = true,
                maxStack = 3
            },
            ["bacta_canister"] = {
                name = "Bacta Canister",
                description = "Refills bacta tanks (25%)",
                category = "consumables",
                basePrice = 2000,
                stackable = true,
                maxStack = 5
            },
            ["medical_scanner"] = {
                name = "Medical Scanner",
                description = "Improves diagnosis accuracy",
                category = "utilities",
                basePrice = 1500,
                stackable = false
            }
        }
        
        -- Add to Grand Exchange
        for itemID, item in pairs(medicalItems) do
            KYBER.GrandExchange.Items[itemID] = item
        end
    end)
end)

-- Add medical info to character sheet
if SERVER then
    hook.Add("Kyber_CharacterSheet_AddInfo", "AddMedicalInfo", function(ply)
        local info = {}
        
        local medicalData = ply.KyberMedical or {}
        
        -- Medical skill
        local skill = medicalData.medicalSkill or 0
        local skillName = KYBER.Medical.Config.skillLevels[skill].name
        table.insert(info, {
            label = "Medical Training",
            value = skillName .. " (Level " .. skill .. ")"
        })
        
        -- Clone count
        table.insert(info, {
            label = "Times Cloned",
            value = tostring(medicalData.cloneCount or 0)
        })
        
        -- Current injuries
        local injuries = medicalData.injuries or {}
        local injuryCount = 0
        for _, injury in ipairs(injuries) do
            if not injury.treated then
                injuryCount = injuryCount + 1
            end
        end
        
        if injuryCount > 0 then
            table.insert(info, {
                label = "Untreated Injuries",
                value = tostring(injuryCount)
            })
        end
        
        return info
    end)
end

-- Add medical tab to datapad
if CLIENT then
    hook.Add("Kyber_Datapad_AddTabs", "AddMedicalTab", function(tabSheet)
        local medPanel = vgui.Create("DPanel", tabSheet)
        medPanel:Dock(FILL)
        
        medPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20))
        end
        
        -- Title
        local title = vgui.Create("DLabel", medPanel)
        title:SetText("Medical Status")
        title:SetFont("DermaLarge")
        title:Dock(TOP)
        title:DockMargin(20, 20, 20, 10)
        title:SetContentAlignment(5)
        
        -- Health status
        local healthPanel = vgui.Create("DPanel", medPanel)
        healthPanel:Dock(TOP)
        healthPanel:DockMargin(20, 0, 20, 20)
        healthPanel:SetTall(100)
        
        healthPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            
            local hp = LocalPlayer():Health()
            local maxHp = LocalPlayer():GetMaxHealth()
            local percent = hp / maxHp
            
            draw.SimpleText("Health Status", "DermaDefaultBold", 10, 10, Color(255, 255, 255))
            draw.SimpleText(hp .. "/" .. maxHp .. " HP", "DermaLarge", w/2, 40, Color(255 * (1-percent), 255 * percent, 0), TEXT_ALIGN_CENTER)
            
            -- Health bar
            local barX = 10
            local barY = 70
            local barWidth = w - 20
            local barHeight = 20
            
            draw.RoundedBox(2, barX, barY, barWidth, barHeight, Color(50, 50, 50))
            draw.RoundedBox(2, barX, barY, barWidth * percent, barHeight, Color(255 * (1-percent), 255 * percent, 0))
        end
        
        -- Medical skill
        local skillPanel = vgui.Create("DPanel", medPanel)
        skillPanel:Dock(TOP)
        skillPanel:DockMargin(20, 0, 20, 20)
        skillPanel:SetTall(80)
        
        skillPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            
            local skill = LocalPlayer():GetNWInt("kyber_medical_skill", 0)
            local skillData = KYBER.Medical.Config.skillLevels[skill]
            
            draw.SimpleText("Medical Training", "DermaDefaultBold", 10, 10, Color(255, 255, 255))
            draw.SimpleText(skillData.name .. " (Level " .. skill .. ")", "DermaDefault", 10, 30, Color(100, 255, 100))
            
            if skill < 5 then
                local exp = LocalPlayer().KyberMedicalExp or 0
                local needed = (skill + 1) * 100
                draw.SimpleText("Experience: " .. exp .. "/" .. needed, "DermaDefault", 10, 50, Color(200, 200, 200))
            else
                draw.SimpleText("Maximum level achieved!", "DermaDefault", 10, 50, Color(255, 215, 0))
            end
        end
        
        -- Injuries
        local injuryLabel = vgui.Create("DLabel", medPanel)
        injuryLabel:SetText("Current Injuries:")
        injuryLabel:SetFont("DermaDefaultBold")
        injuryLabel:Dock(TOP)
        injuryLabel:DockMargin(20, 0, 20, 10)
        
        local injuryScroll = vgui.Create("DScrollPanel", medPanel)
        injuryScroll:Dock(FILL)
        injuryScroll:DockMargin(20, 0, 20, 20)
        
        -- Update injuries
        local function RefreshInjuries()
            injuryScroll:Clear()
            
            local injuries = LocalPlayer().KyberMedicalInjuries or {}
            
            if #injuries == 0 then
                local noInj = vgui.Create("DLabel", injuryScroll)
                noInj:SetText("No injuries - you are in good health!")
                noInj:Dock(TOP)
                noInj:DockMargin(10, 10, 10, 10)
            else
                for _, injury in ipairs(injuries) do
                    local injuryData = KYBER.Medical.Config.injuryTypes[injury.type]
                    if injuryData then
                        local injPanel = vgui.Create("DPanel", injuryScroll)
                        injPanel:Dock(TOP)
                        injPanel:DockMargin(0, 0, 0, 5)
                        injPanel:SetTall(40)
                        
                        injPanel.Paint = function(self, w, h)
                            local col = injury.treated and Color(40, 50, 40) or Color(50, 40, 40)
                            draw.RoundedBox(4, 0, 0, w, h, col)
                            
                            draw.SimpleText(injuryData.name, "DermaDefault", 10, 10, Color(255, 255, 255))
                            
                            if injury.treated then
                                draw.SimpleText("TREATED", "DermaDefault", w - 80, 10, Color(100, 255, 100))
                            else
                                if injuryData.bleedRate > 0 then
                                    draw.SimpleText("BLEEDING", "DermaDefault", w - 80, 10, Color(255, 100, 100))
                                end
                            end
                        end
                    end
                end
            end
        end
        
        RefreshInjuries()
        
        -- Auto-refresh
        injuryScroll.Think = function()
            if CurTime() > (injuryScroll.NextRefresh or 0) then
                RefreshInjuries()
                injuryScroll.NextRefresh = CurTime() + 2
            end
        end
        
        -- Open medical UI button
        local medBtn = vgui.Create("DButton", medPanel)
        medBtn:SetText("Open Medical Interface")
        medBtn:Dock(BOTTOM)
        medBtn:DockMargin(20, 0, 20, 20)
        medBtn:SetTall(40)
        
        medBtn.DoClick = function()
            KYBER.Medical:OpenMedicalUI()
        end
        
        tabSheet:AddSheet("Medical", medPanel, "icon16/heart.png")
    end)
end

-- Reputation rewards for healing
if SERVER then
    hook.Add("Kyber_Medical_PlayerHealed", "MedicalReputation", function(medic, patient, amount)
        if medic == patient then return end -- No rep for self-healing
        
        -- Gain reputation with patient's faction
        local patientFaction = patient:GetNWString("kyber_faction", "")
        if patientFaction ~= "" then
            KYBER.Reputation:ChangeReputation(medic, patientFaction, 10, "Healed faction member")
        end
        
        -- Special reputation for consistent healing
        medic.HealingCount = (medic.HealingCount or 0) + 1
        
        if medic.HealingCount >= 10 then
            -- Gain reputation with civilian factions
            KYBER.Reputation:ChangeReputation(medic, "republic", 25, "Medical service")
            medic.HealingCount = 0
        end
    end)
end

-- Force healing bonus
if SERVER then
    hook.Add("Kyber_Medical_GetHealBonus", "ForceHealingBonus", function(medic)
        if medic:GetNWBool("kyber_force_sensitive", false) then
            -- Force users get healing bonus
            return 0.2 -- 20% bonus healing
        end
        
        return 0
    end)
end

-- Equipment integration - medical gear
hook.Add("Initialize", "KyberMedicalEquipment", function()
    timer.Simple(2, function()
        local medicalEquipment = {
            ["armor_medic"] = {
                name = "Field Medic Armor",
                description = "Protective gear for combat medics",
                slot = "chest",
                icon = "icon16/shield.png",
                stats = {
                    armor = 20,
                    healing_bonus = 20,
                    speed = -5
                },
                requirements = {
                    skill_medical = 2
                },
                value = 3000
            },
            
            ["utility_medical_droid"] = {
                name = "Medical Assistant Droid",
                description = "Automated healing companion",
                slot = "utility1",
                icon = "icon16/user_go.png",
                stats = {
                    healing_bonus = 30
                },
                abilities = {
                    "medical_droid"
                },
                requirements = {
                    skill_medical = 4
                },
                value = 5000
            }
        }
        
        -- Add to equipment system
        for itemID, item in pairs(medicalEquipment) do
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

-- Crafting recipes for medical items
hook.Add("Initialize", "KyberMedicalCrafting", function()
    timer.Simple(2, function()
        local medicalRecipes = {
            ["medpac_crafted"] = {
                name = "Craft Medpac",
                description = "Basic medical supplies",
                category = "consumables",
                result = {
                    id = "medpac",
                    amount = 3
                },
                ingredients = {
                    {id = "medical_supplies", amount = 2},
                    {id = "bacta_vial", amount = 1}
                },
                requirements = {
                    skill = 1,
                    station = "medical_station"
                },
                time = 10,
                experience = 8
            },
            
            ["bacta_injection_crafted"] = {
                name = "Craft Bacta Injection",
                description = "Concentrated healing injection",
                category = "consumables",
                result = {
                    id = "bacta_injection",
                    amount = 1
                },
                ingredients = {
                    {id = "bacta_vial", amount = 3},
                    {id = "medical_supplies", amount = 1},
                    {id = "stim_compound", amount = 1}
                },
                requirements = {
                    skill = 3,
                    station = "medical_station",
                    skill_medical = 2
                },
                time = 20,
                experience = 15
            }
        }
        
        -- Add to crafting system
        for recipeID, recipe in pairs(medicalRecipes) do
            KYBER.Crafting.Recipes[recipeID] = recipe
        end
    end)
end)

-- Admin commands
if SERVER then
    concommand.Add("kyber_medical_setskill", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local target = args[1] and player.GetBySteamID(args[1]) or ply
        local level = tonumber(args[2]) or 0
        
        if IsValid(target) and target.KyberMedical then
            level = math.Clamp(level, 0, 5)
            target.KyberMedical.medicalSkill = level
            target:SetNWInt("kyber_medical_skill", level)
            
            KYBER.Medical:Save(target)
            
            ply:ChatPrint("Set " .. target:Nick() .. "'s medical skill to level " .. level)
        end
    end)
    
    concommand.Add("kyber_medical_heal", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local target = args[1] and player.GetBySteamID(args[1]) or ply
        
        if IsValid(target) then
            target:SetHealth(target:GetMaxHealth())
            
            -- Clear injuries
            if target.KyberMedical then
                target.KyberMedical.injuries = {}
                KYBER.Medical:SendInjuryUpdate(target)
            end
            
            ply:ChatPrint("Fully healed " .. target:Nick())
        end
    end)
    
    concommand.Add("kyber_spawn_bacta", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local tr = ply:GetEyeTrace()
        local ent = ents.Create("kyber_bacta_tank")
        ent:SetPos(tr.HitPos + tr.HitNormal * 10)
        ent:Spawn()
        
        ply:ChatPrint("Spawned bacta tank")
    end)
end

-- Console status command
if CLIENT then
    concommand.Add("kyber_medical_status", function()
        print("=== Medical Status ===")
        
        local skill = LocalPlayer():GetNWInt("kyber_medical_skill", 0)
        local skillData = KYBER.Medical.Config.skillLevels[skill]
        print("Medical Skill: " .. skillData.name .. " (Level " .. skill .. ")")
        
        local injuries = LocalPlayer().KyberMedicalInjuries or {}
        print("Injuries: " .. #injuries)
        
        for i, injury in ipairs(injuries) do
            local injuryData = KYBER.Medical.Config.injuryTypes[injury.type]
            print("  - " .. injuryData.name .. " (Severity: " .. injury.severity .. ", Treated: " .. tostring(injury.treated) .. ")")
        end
        
        print("Health: " .. LocalPlayer():Health() .. "/" .. LocalPlayer():GetMaxHealth())
    end)
end

print("[Kyber] Medical system loaded")