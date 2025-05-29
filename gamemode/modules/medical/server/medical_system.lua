-- kyber/modules/medical/system.lua
KYBER.Medical = KYBER.Medical or {}

-- Medical configuration
KYBER.Medical.Config = {
    -- Injury system
    injuryTypes = {
        ["blaster"] = {name = "Blaster Burn", severity = 2, bleedRate = 0},
        ["slash"] = {name = "Laceration", severity = 3, bleedRate = 2},
        ["blunt"] = {name = "Blunt Trauma", severity = 2, bleedRate = 0},
        ["explosion"] = {name = "Shrapnel Wounds", severity = 4, bleedRate = 3},
        ["fall"] = {name = "Fracture", severity = 3, bleedRate = 0},
        ["burn"] = {name = "Severe Burns", severity = 3, bleedRate = 0}
    },
    
    -- Medical skill progression
    skillLevels = {
        [0] = {name = "Untrained", healBonus = 0, diagnosisAccuracy = 0.3},
        [1] = {name = "First Aid", healBonus = 0.1, diagnosisAccuracy = 0.5},
        [2] = {name = "Field Medic", healBonus = 0.2, diagnosisAccuracy = 0.7},
        [3] = {name = "Combat Medic", healBonus = 0.3, diagnosisAccuracy = 0.8},
        [4] = {name = "Medical Professional", healBonus = 0.4, diagnosisAccuracy = 0.9},
        [5] = {name = "Master Healer", healBonus = 0.5, diagnosisAccuracy = 1.0}
    },
    
    -- Healing items and tools
    healingItems = {
        ["medpac"] = {heal = 25, skillRequired = 0, expGain = 5},
        ["medpac_advanced"] = {heal = 50, skillRequired = 2, expGain = 10},
        ["bacta_injection"] = {heal = 75, skillRequired = 3, expGain = 15},
        ["surgical_kit"] = {heal = 100, skillRequired = 4, expGain = 20}
    },
    
    -- Cloning/respawn
    cloneTime = 30,                    -- Seconds to respawn
    cloneCost = 500,                   -- Credit cost per clone
    cloneHealthPenalty = 0.25,         -- Start with 75% health after clone
    cloneSickness = 60,                -- Seconds of reduced stats after clone
    
    -- Bacta tank
    bactaHealRate = 5,                -- HP per second in bacta tank
    bactaCostPerSecond = 10,          -- Credits per second of bacta use
    
    -- General
    bleedDamageInterval = 2,          -- Seconds between bleed damage
    naturalHealRate = 1,              -- HP per minute when resting
    maxInjuries = 5                   -- Maximum simultaneous injuries
}

if SERVER then
    util.AddNetworkString("Kyber_Medical_UpdateInjuries")
    util.AddNetworkString("Kyber_Medical_TreatPlayer")
    util.AddNetworkString("Kyber_Medical_OpenMedicalUI")
    util.AddNetworkString("Kyber_Medical_LearnSkill")
    util.AddNetworkString("Kyber_Medical_UseItem")
    util.AddNetworkString("Kyber_Medical_DiagnosePatient")
    util.AddNetworkString("Kyber_Medical_UpdateSkill")
    
    -- Initialize medical data
    function KYBER.Medical:Initialize(ply)
        ply.KyberMedical = {
            injuries = {},
            medicalSkill = 0,
            medicalExp = 0,
            treatmentHistory = {},
            cloneCount = 0,
            lastClone = 0
        }
        
        -- Load saved data
        local steamID = ply:SteamID64()
        local path = "kyber/medical/" .. steamID .. ".json"
        
        if file.Exists(path, "DATA") then
            local data = file.Read(path, "DATA")
            local saved = util.JSONToTable(data)
            if saved then
                ply.KyberMedical.medicalSkill = saved.medicalSkill or 0
                ply.KyberMedical.medicalExp = saved.medicalExp or 0
                ply.KyberMedical.cloneCount = saved.cloneCount or 0
            end
        end
        
        -- Set networked skill
        ply:SetNWInt("kyber_medical_skill", ply.KyberMedical.medicalSkill)
        
        -- Start injury timer
        self:StartInjuryTimer(ply)
    end
    
    function KYBER.Medical:Save(ply)
        if not IsValid(ply) or not ply.KyberMedical then return end
        
        local steamID = ply:SteamID64()
        local path = "kyber/medical/" .. steamID .. ".json"
        
        if not file.Exists("kyber/medical", "DATA") then
            file.CreateDir("kyber/medical")
        end
        
        local data = {
            medicalSkill = ply.KyberMedical.medicalSkill,
            medicalExp = ply.KyberMedical.medicalExp,
            cloneCount = ply.KyberMedical.cloneCount
        }
        
        file.Write(path, util.TableToJSON(data))
    end
    
    -- Injury system
    function KYBER.Medical:AddInjury(ply, injuryType, severity)
        if not ply.KyberMedical then return end
        
        if #ply.KyberMedical.injuries >= self.Config.maxInjuries then
            -- Replace oldest injury
            table.remove(ply.KyberMedical.injuries, 1)
        end
        
        local injury = {
            type = injuryType,
            severity = severity or self.Config.injuryTypes[injuryType].severity,
            timestamp = CurTime(),
            treated = false
        }
        
        table.insert(ply.KyberMedical.injuries, injury)
        
        -- Notify player
        ply:ChatPrint("You sustained a " .. self.Config.injuryTypes[injuryType].name)
        
        -- Send update
        self:SendInjuryUpdate(ply)
        
        -- Start bleeding if applicable
        if self.Config.injuryTypes[injuryType].bleedRate > 0 then
            ply:ChatPrint("You are bleeding!")
        end
    end
    
    function KYBER.Medical:StartInjuryTimer(ply)
        timer.Create("KyberInjury_" .. ply:SteamID64(), self.Config.bleedDamageInterval, 0, function()
            if not IsValid(ply) or not ply.KyberMedical then
                timer.Remove("KyberInjury_" .. ply:SteamID64())
                return
            end
            
            local totalBleed = 0
            local untreatedInjuries = 0
            
            for _, injury in ipairs(ply.KyberMedical.injuries) do
                if not injury.treated then
                    untreatedInjuries = untreatedInjuries + 1
                    local injuryData = self.Config.injuryTypes[injury.type]
                    if injuryData and injuryData.bleedRate > 0 then
                        totalBleed = totalBleed + (injuryData.bleedRate * injury.severity)
                    end
                end
            end
            
            -- Apply bleed damage
            if totalBleed > 0 then
                ply:TakeDamage(totalBleed, ply, ply)
                
                -- Visual effect
                local effectdata = EffectData()
                effectdata:SetOrigin(ply:GetPos())
                effectdata:SetNormal(Vector(0, 0, 1))
                effectdata:SetMagnitude(1)
                effectdata:SetScale(1)
                effectdata:SetRadius(2)
                util.Effect("BloodImpact", effectdata)
            end
            
            -- Slow natural healing if resting and uninjured
            if untreatedInjuries == 0 and ply:Health() < ply:GetMaxHealth() then
                if ply:GetVelocity():Length() < 50 then -- Resting
                    ply:SetHealth(math.min(ply:Health() + 1, ply:GetMaxHealth()))
                end
            end
        end)
    end
    
    -- Medical treatment
    function KYBER.Medical:TreatPatient(medic, patient, treatmentType)
        if not IsValid(medic) or not IsValid(patient) then return false, "Invalid medic or patient" end
        
        -- Check range
        if medic:GetPos():Distance(patient:GetPos()) > 100 then
            return false, "Too far from patient"
        end
        
        -- Get medic skill
        local medicSkill = medic.KyberMedical.medicalSkill or 0
        local skillData = self.Config.skillLevels[medicSkill] or self.Config.skillLevels[0]
        
        -- Basic healing
        if treatmentType == "basic_heal" then
            local healAmount = 10 + (10 * skillData.healBonus)
            patient:SetHealth(math.min(patient:Health() + healAmount, patient:GetMaxHealth()))
            
            -- Gain experience
            self:GrantMedicalExp(medic, 5)
            
            -- Effects
            patient:EmitSound("items/smallmedkit1.wav")
            
            return true
        end
        
        -- Treat injuries
        if treatmentType == "treat_injury" then
            if #patient.KyberMedical.injuries == 0 then
                return false, "No injuries to treat"
            end
            
            -- Treat most severe injury first
            local mostSevere = nil
            local severity = 0
            
            for i, injury in ipairs(patient.KyberMedical.injuries) do
                if not injury.treated and injury.severity > severity then
                    mostSevere = i
                    severity = injury.severity
                end
            end
            
            if mostSevere then
                patient.KyberMedical.injuries[mostSevere].treated = true
                
                -- Experience based on injury severity
                self:GrantMedicalExp(medic, severity * 10)
                
                -- Notify
                local injuryName = self.Config.injuryTypes[patient.KyberMedical.injuries[mostSevere].type].name
                medic:ChatPrint("Successfully treated " .. patient:Nick() .. "'s " .. injuryName)
                patient:ChatPrint(medic:Nick() .. " treated your " .. injuryName)
                
                -- Update
                self:SendInjuryUpdate(patient)
                
                return true
            end
        end
        
        return false, "Unknown treatment type"
    end
    
    -- Medical skill progression
    function KYBER.Medical:GrantMedicalExp(ply, amount)
        if not ply.KyberMedical then return end
        
        ply.KyberMedical.medicalExp = ply.KyberMedical.medicalExp + amount
        
        -- Check for level up
        local currentLevel = ply.KyberMedical.medicalSkill
        local expNeeded = (currentLevel + 1) * 100
        
        if ply.KyberMedical.medicalExp >= expNeeded and currentLevel < 5 then
            ply.KyberMedical.medicalSkill = currentLevel + 1
            ply.KyberMedical.medicalExp = ply.KyberMedical.medicalExp - expNeeded
            
            -- Update networked value
            ply:SetNWInt("kyber_medical_skill", ply.KyberMedical.medicalSkill)
            
            -- Notify
            local newSkillData = self.Config.skillLevels[ply.KyberMedical.medicalSkill]
            ply:ChatPrint("Medical skill increased! You are now: " .. newSkillData.name)
            ply:EmitSound("buttons/button9.wav")
            
            -- Save
            self:Save(ply)
        end
        
        -- Send update
        self:SendSkillUpdate(ply)
    end
    
    -- Diagnosis system
    function KYBER.Medical:DiagnosePatient(medic, patient)
        if medic:GetPos():Distance(patient:GetPos()) > 100 then
            return false, "Too far from patient"
        end
        
        local medicSkill = medic.KyberMedical.medicalSkill or 0
        local skillData = self.Config.skillLevels[medicSkill] or self.Config.skillLevels[0]
        
        -- Build diagnosis based on skill
        local diagnosis = {
            health = patient:Health() .. "/" .. patient:GetMaxHealth(),
            injuries = {},
            accuracy = skillData.diagnosisAccuracy
        }
        
        -- Diagnose injuries based on accuracy
        for _, injury in ipairs(patient.KyberMedical.injuries or {}) do
            if math.random() <= skillData.diagnosisAccuracy then
                table.insert(diagnosis.injuries, {
                    type = injury.type,
                    severity = injury.severity,
                    treated = injury.treated
                })
            else
                -- Misdiagnosis
                table.insert(diagnosis.injuries, {
                    type = "unknown",
                    severity = "?",
                    treated = false
                })
            end
        end
        
        -- Small exp for diagnosis
        self:GrantMedicalExp(medic, 2)
        
        return true, diagnosis
    end
    
    -- Death and cloning
    hook.Add("PlayerDeath", "KyberMedicalDeath", function(victim, inflictor, attacker)
        if not victim.KyberMedical then return end
        
        -- Clear injuries on death
        victim.KyberMedical.injuries = {}
        
        -- Increase clone count
        victim.KyberMedical.cloneCount = victim.KyberMedical.cloneCount + 1
        victim.KyberMedical.lastClone = CurTime()
        
        -- Clone cost
        local cloneCost = KYBER.Medical.Config.cloneCost * victim.KyberMedical.cloneCount
        
        -- Check if player can afford clone
        local credits = KYBER:GetPlayerData(victim, "credits") or 0
        local bankCredits = victim.KyberBanking and victim.KyberBanking.credits or 0
        
        if credits + bankCredits >= cloneCost then
            -- Will be charged on respawn
            victim.PendingCloneCost = cloneCost
            victim:ChatPrint("Clone prepared. Cost: " .. cloneCost .. " credits")
        else
            victim:ChatPrint("WARNING: Insufficient credits for cloning!")
            -- Could implement permadeath or longer respawn
        end
    end)
    
    hook.Add("PlayerSpawn", "KyberMedicalSpawn", function(ply)
        if not ply.KyberMedical then return end
        
        -- Handle clone cost
        if ply.PendingCloneCost then
            local cost = ply.PendingCloneCost
            ply.PendingCloneCost = nil
            
            -- Try wallet first, then bank
            local walletCredits = KYBER:GetPlayerData(ply, "credits") or 0
            
            if walletCredits >= cost then
                KYBER:SetPlayerData(ply, "credits", walletCredits - cost)
            else
                -- Take from bank
                local needed = cost - walletCredits
                if ply.KyberBanking and ply.KyberBanking.credits >= needed then
                    KYBER:SetPlayerData(ply, "credits", 0)
                    ply.KyberBanking.credits = ply.KyberBanking.credits - needed
                    KYBER.Banking:Save(ply)
                end
            end
            
            ply:ChatPrint("Clone activation cost: " .. cost .. " credits")
        end
        
        -- Clone sickness
        if CurTime() - (ply.KyberMedical.lastClone or 0) < 60 then
            -- Recently cloned
            ply:SetHealth(ply:GetMaxHealth() * (1 - KYBER.Medical.Config.cloneHealthPenalty))
            
            -- Temporary debuffs
            ply:SetWalkSpeed(150)
            ply:SetRunSpeed(200)
            
            timer.Simple(KYBER.Medical.Config.cloneSickness, function()
                if IsValid(ply) then
                    ply:SetWalkSpeed(200)
                    ply:SetRunSpeed(400)
                    ply:ChatPrint("Clone sickness has worn off")
                end
            end)
            
            ply:ChatPrint("You are experiencing clone sickness...")
        end
    end)
    
    -- Network handlers
    net.Receive("Kyber_Medical_TreatPlayer", function(len, ply)
        local patient = net.ReadEntity()
        local treatmentType = net.ReadString()
        
        local success, err = KYBER.Medical:TreatPatient(ply, patient, treatmentType)
        
        if not success then
            ply:ChatPrint("Treatment failed: " .. err)
        end
    end)
    
    net.Receive("Kyber_Medical_DiagnosePatient", function(len, ply)
        local patient = net.ReadEntity()
        
        local success, diagnosis = KYBER.Medical:DiagnosePatient(ply, patient)
        
        if success then
            net.Start("Kyber_Medical_DiagnosisResult")
            net.WriteTable(diagnosis)
            net.Send(ply)
        else
            ply:ChatPrint("Diagnosis failed: " .. diagnosis)
        end
    end)
    
    net.Receive("Kyber_Medical_UseItem", function(len, ply)
        local itemID = net.ReadString()
        local target = net.ReadEntity()
        
        if not IsValid(target) then target = ply end
        
        -- Check if player has the item
        local hasItem = KYBER.Inventory:HasItem(ply, itemID, 1)
        if not hasItem then
            ply:ChatPrint("You don't have that medical item")
            return
        end
        
        local itemData = KYBER.Medical.Config.healingItems[itemID]
        if not itemData then return end
        
        -- Check skill requirement
        if ply.KyberMedical.medicalSkill < itemData.skillRequired then
            ply:ChatPrint("You lack the medical skill to use this item")
            return
        end
        
        -- Use item
        KYBER.Inventory:RemoveItem(ply, itemID, 1)
        
        -- Apply healing
        local skillBonus = KYBER.Medical.Config.skillLevels[ply.KyberMedical.medicalSkill].healBonus
        local healAmount = itemData.heal * (1 + skillBonus)
        
        target:SetHealth(math.min(target:Health() + healAmount, target:GetMaxHealth()))
        
        -- Grant experience
        KYBER.Medical:GrantMedicalExp(ply, itemData.expGain)
        
        -- Effects
        target:EmitSound("items/medshot4.wav")
        
        ply:ChatPrint("Used " .. itemID .. " on " .. target:Nick())
    end)
    
    -- Send updates
    function KYBER.Medical:SendInjuryUpdate(ply)
        net.Start("Kyber_Medical_UpdateInjuries")
        net.WriteTable(ply.KyberMedical.injuries or {})
        net.Send(ply)
    end
    
    function KYBER.Medical:SendSkillUpdate(ply)
        net.Start("Kyber_Medical_UpdateSkill")
        net.WriteInt(ply.KyberMedical.medicalSkill, 8)
        net.WriteInt(ply.KyberMedical.medicalExp, 16)
        net.Send(ply)
    end
    
    -- Damage hook for injuries
    hook.Add("EntityTakeDamage", "KyberMedicalInjuries", function(target, dmginfo)
        if not IsValid(target) or not target:IsPlayer() then return end
        
        local damage = dmginfo:GetDamage()
        if damage < 10 then return end -- Minor damage
        
        -- Determine injury type
        local injuryType = "blunt"
        
        if dmginfo:IsDamageType(DMG_BULLET) or dmginfo:IsDamageType(DMG_ENERGYBEAM) then
            injuryType = "blaster"
        elseif dmginfo:IsDamageType(DMG_SLASH) then
            injuryType = "slash"
        elseif dmginfo:IsDamageType(DMG_BLAST) then
            injuryType = "explosion"
        elseif dmginfo:IsDamageType(DMG_BURN) then
            injuryType = "burn"
        elseif dmginfo:IsDamageType(DMG_FALL) then
            injuryType = "fall"
        end
        
        -- Severity based on damage
        local severity = 1
        if damage >= 50 then severity = 4
        elseif damage >= 30 then severity = 3
        elseif damage >= 20 then severity = 2
        end
        
        -- Add injury
        KYBER.Medical:AddInjury(target, injuryType, severity)
    end)
    
    -- Initialize players
    hook.Add("PlayerInitialSpawn", "KyberMedicalInit", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                KYBER.Medical:Initialize(ply)
            end
        end)
    end)
    
    hook.Add("PlayerDisconnected", "KyberMedicalSave", function(ply)
        KYBER.Medical:Save(ply)
    end)
    
else -- CLIENT
    
    local MedicalUI = nil
    util.AddNetworkString("Kyber_Medical_DiagnosisResult")
    
    net.Receive("Kyber_Medical_UpdateInjuries", function()
        local injuries = net.ReadTable()
        LocalPlayer().KyberMedicalInjuries = injuries
        
        if IsValid(MedicalUI) then
            KYBER.Medical:RefreshUI()
        end
    end)
    
    net.Receive("Kyber_Medical_UpdateSkill", function()
        local skill = net.ReadInt(8)
        local exp = net.ReadInt(16)
        
        LocalPlayer().KyberMedicalSkill = skill
        LocalPlayer().KyberMedicalExp = exp
    end)
    
    net.Receive("Kyber_Medical_DiagnosisResult", function()
        local diagnosis = net.ReadTable()
        
        if IsValid(MedicalUI) then
            KYBER.Medical:ShowDiagnosis(diagnosis)
        end
    end)
    
    -- Medical interface
    function KYBER.Medical:OpenMedicalUI(patient)
        if IsValid(MedicalUI) then MedicalUI:Remove() end
        
        MedicalUI = vgui.Create("DFrame")
        MedicalUI:SetSize(600, 500)
        MedicalUI:Center()
        MedicalUI:SetTitle("Medical Interface - " .. (patient and patient:Nick() or "Self"))
        MedicalUI:MakePopup()
        
        local sheet = vgui.Create("DPropertySheet", MedicalUI)
        sheet:Dock(FILL)
        sheet:DockMargin(10, 10, 10, 10)
        
        -- Treatment tab
        local treatPanel = vgui.Create("DPanel", sheet)
        self:CreateTreatmentPanel(treatPanel, patient)
        sheet:AddSheet("Treatment", treatPanel, "icon16/heart.png")
        
        -- Medical skill tab
        local skillPanel = vgui.Create("DPanel", sheet)
        self:CreateSkillPanel(skillPanel)
        sheet:AddSheet("Medical Training", skillPanel, "icon16/book.png")
        
        -- Injuries tab (self only)
        if not patient or patient == LocalPlayer() then
            local injuryPanel = vgui.Create("DPanel", sheet)
            self:CreateInjuryPanel(injuryPanel)
            sheet:AddSheet("My Injuries", injuryPanel, "icon16/user_orange.png")
        end
    end
    
    function KYBER.Medical:CreateTreatmentPanel(parent, patient)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        end
        
        if not patient then
            -- Self treatment
            local info = vgui.Create("DLabel", parent)
            info:SetText("Use medical items from your inventory to treat yourself.")
            info:Dock(TOP)
            info:DockMargin(10, 10, 10, 10)
            info:SetWrap(true)
            info:SetAutoStretchVertical(true)
            
            -- Show medical items in inventory
            local itemScroll = vgui.Create("DScrollPanel", parent)
            itemScroll:Dock(FILL)
            itemScroll:DockMargin(10, 0, 10, 10)
            
            local inventory = LocalPlayer().KyberInventory or {}
            
            for slot, itemData in pairs(inventory) do
                if itemData and KYBER.Medical.Config.healingItems[itemData.id] then
                    local medItem = KYBER.Medical.Config.healingItems[itemData.id]
                    
                    local itemPanel = vgui.Create("DPanel", itemScroll)
                    itemPanel:Dock(TOP)
                    itemPanel:DockMargin(0, 0, 0, 5)
                    itemPanel:SetTall(60)
                    
                    itemPanel.Paint = function(self, w, h)
                        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
                        
                        local item = KYBER.GrandExchange.Items[itemData.id]
                        if item then
                            draw.SimpleText(item.name .. " x" .. itemData.amount, "DermaDefaultBold", 10, 10, Color(255, 255, 255))
                            draw.SimpleText("Heals: " .. medItem.heal .. " HP", "DermaDefault", 10, 30, Color(100, 255, 100))
                            
                            local skill = LocalPlayer().KyberMedicalSkill or 0
                            if skill < medItem.skillRequired then
                                draw.SimpleText("Requires Medical Skill: " .. medItem.skillRequired, "DermaDefault", 200, 20, Color(255, 100, 100))
                            end
                        end
                    end
                    
                    local useBtn = vgui.Create("DButton", itemPanel)
                    useBtn:SetText("Use")
                    useBtn:SetPos(itemPanel:GetWide() - 110, 15)
                    useBtn:SetSize(80, 30)
                    
                    useBtn.DoClick = function()
                        net.Start("Kyber_Medical_UseItem")
                        net.WriteString(itemData.id)
                        net.WriteEntity(LocalPlayer())
                        net.SendToServer()
                    end
                    
                    local skill = LocalPlayer().KyberMedicalSkill or 0
                    if skill < medItem.skillRequired then
                        useBtn:SetEnabled(false)
                    end
                end
            end
        else
            -- Treating another player
            local diagnoseBtn = vgui.Create("DButton", parent)
            diagnoseBtn:SetText("Diagnose Patient")
            diagnoseBtn:Dock(TOP)
            diagnoseBtn:DockMargin(10, 10, 10, 10)
            diagnoseBtn:SetTall(40)
            
            diagnoseBtn.DoClick = function()
                net.Start("Kyber_Medical_DiagnosePatient")
                net.WriteEntity(patient)
                net.SendToServer()
            end
            
            -- Diagnosis results
            self.diagnosisPanel = vgui.Create("DPanel", parent)
            self.diagnosisPanel:Dock(TOP)
            self.diagnosisPanel:DockMargin(10, 0, 10, 10)
            self.diagnosisPanel:SetTall(200)
            self.diagnosisPanel:SetVisible(false)
            
            self.diagnosisPanel.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
            end
            
            -- Treatment options
            local treatBtn = vgui.Create("DButton", parent)
            treatBtn:SetText("Basic Treatment (+10 HP)")
            treatBtn:Dock(TOP)
            treatBtn:DockMargin(10, 0, 10, 5)
            treatBtn:SetTall(35)
            
            treatBtn.DoClick = function()
                net.Start("Kyber_Medical_TreatPlayer")
                net.WriteEntity(patient)
                net.WriteString("basic_heal")
                net.SendToServer()
            end
            
            local injuryBtn = vgui.Create("DButton", parent)
            injuryBtn:SetText("Treat Injuries")
            injuryBtn:Dock(TOP)
            injuryBtn:DockMargin(10, 0, 10, 5)
            injuryBtn:SetTall(35)
            
            injuryBtn.DoClick = function()
                net.Start("Kyber_Medical_TreatPlayer")
                net.WriteEntity(patient)
                net.WriteString("treat_injury")
                net.SendToServer()
            end
        end
    end
    
    function KYBER.Medical:CreateSkillPanel(parent)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            
            local skill = LocalPlayer().KyberMedicalSkill or 0
            local exp = LocalPlayer().KyberMedicalExp or 0
            local skillData = KYBER.Medical.Config.skillLevels[skill] or KYBER.Medical.Config.skillLevels[0]
            
            -- Title
            draw.SimpleText("Medical Training", "DermaLarge", w/2, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            
            -- Current level
            draw.SimpleText("Current Level: " .. skillData.name .. " (Level " .. skill .. ")", "DermaDefaultBold", w/2, 70, Color(100, 255, 100), TEXT_ALIGN_CENTER)
            
            -- Experience bar
            if skill < 5 then
                local expNeeded = (skill + 1) * 100
                local progress = exp / expNeeded
                
                draw.SimpleText("Experience: " .. exp .. "/" .. expNeeded, "DermaDefault", w/2, 100, Color(200, 200, 200), TEXT_ALIGN_CENTER)
                
                -- Progress bar
                local barWidth = w - 100
                local barX = 50
                local barY = 120
                
                draw.RoundedBox(2, barX, barY, barWidth, 20, Color(50, 50, 50))
                draw.RoundedBox(2, barX, barY, barWidth * progress, 20, Color(100, 200, 100))
            else
                draw.SimpleText("Maximum level reached!", "DermaDefaultBold", w/2, 100, Color(255, 215, 0), TEXT_ALIGN_CENTER)
            end
            
            -- Skill benefits
            draw.SimpleText("Benefits:", "DermaDefaultBold", 30, 160, Color(255, 255, 255))
            draw.SimpleText("• Healing Bonus: +" .. (skillData.healBonus * 100) .. "%", "DermaDefault", 40, 185, Color(200, 200, 200))
            draw.SimpleText("• Diagnosis Accuracy: " .. (skillData.diagnosisAccuracy * 100) .. "%", "DermaDefault", 40, 205, Color(200, 200, 200))
            
            -- How to gain exp
            draw.SimpleText("Gain experience by:", "DermaDefaultBold", 30, 250, Color(255, 255, 255))
            draw.SimpleText("• Treating other players", "DermaDefault", 40, 275, Color(200, 200, 200))
            draw.SimpleText("• Using medical items", "DermaDefault", 40, 295, Color(200, 200, 200))
            draw.SimpleText("• Diagnosing injuries", "DermaDefault", 40, 315, Color(200, 200, 200))
            draw.SimpleText("• Healing in bacta tanks", "DermaDefault", 40, 335, Color(200, 200, 200))
        end
    end
    
    function KYBER.Medical:CreateInjuryPanel(parent)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        end
        
        local injuries = LocalPlayer().KyberMedicalInjuries or {}
        
        if #injuries == 0 then
            local noInjury = vgui.Create("DLabel", parent)
            noInjury:SetText("You have no injuries.")
            noInjury:SetFont("DermaLarge")
            noInjury:Dock(FILL)
            noInjury:SetContentAlignment(5)
        else
            local injuryScroll = vgui.Create("DScrollPanel", parent)
            injuryScroll:Dock(FILL)
            injuryScroll:DockMargin(10, 10, 10, 10)
            
            for i, injury in ipairs(injuries) do
                local injuryData = KYBER.Medical.Config.injuryTypes[injury.type]
                if injuryData then
                    local injPanel = vgui.Create("DPanel", injuryScroll)
                    injPanel:Dock(TOP)
                    injPanel:DockMargin(0, 0, 0, 5)
                    injPanel:SetTall(60)
                    
                    injPanel.Paint = function(self, w, h)
                        local col = injury.treated and Color(40, 60, 40) or Color(60, 40, 40)
                        draw.RoundedBox(4, 0, 0, w, h, col)
                        
                        draw.SimpleText(injuryData.name, "DermaDefaultBold", 10, 10, Color(255, 255, 255))
                        draw.SimpleText("Severity: " .. injury.severity .. "/4", "DermaDefault", 10, 30, Color(255, 200, 100))
                        
                        if injury.treated then
                            draw.SimpleText("TREATED", "DermaDefault", w - 100, 20, Color(100, 255, 100))
                        else
                            if injuryData.bleedRate > 0 then
                                draw.SimpleText("BLEEDING", "DermaDefault", w - 100, 20, Color(255, 100, 100))
                            end
                        end
                    end
                end
            end
        end
    end
    
    function KYBER.Medical:ShowDiagnosis(diagnosis)
        if not IsValid(self.diagnosisPanel) then return end
        
        self.diagnosisPanel:SetVisible(true)
        self.diagnosisPanel:Clear()
        
        local title = vgui.Create("DLabel", self.diagnosisPanel)
        title:SetText("Diagnosis Results (Accuracy: " .. math.floor(diagnosis.accuracy * 100) .. "%)")
        title:SetFont("DermaDefaultBold")
        title:Dock(TOP)
        title:DockMargin(10, 10, 10, 10)
        
        local health = vgui.Create("DLabel", self.diagnosisPanel)
        health:SetText("Patient Health: " .. diagnosis.health)
        health:Dock(TOP)
        health:DockMargin(10, 0, 10, 10)
        
        if #diagnosis.injuries > 0 then
            local injLabel = vgui.Create("DLabel", self.diagnosisPanel)
            injLabel:SetText("Detected Injuries:")
            injLabel:Dock(TOP)
            injLabel:DockMargin(10, 0, 10, 5)
            
            for _, injury in ipairs(diagnosis.injuries) do
                local injText = vgui.Create("DLabel", self.diagnosisPanel)
                
                if injury.type == "unknown" then
                    injText:SetText("• Unknown injury")
                    injText:SetTextColor(Color(255, 255, 100))
                else
                    local injuryData = KYBER.Medical.Config.injuryTypes[injury.type]
                    injText:SetText("• " .. injuryData.name .. " (Severity: " .. injury.severity .. ")")
                    injText:SetTextColor(injury.treated and Color(100, 255, 100) or Color(255, 100, 100))
                end
                
                injText:Dock(TOP)
                injText:DockMargin(20, 0, 10, 2)
            end
        else
            local noInj = vgui.Create("DLabel", self.diagnosisPanel)
            noInj:SetText("No injuries detected")
            noInj:Dock(TOP)
            noInj:DockMargin(10, 0, 10, 5)
        end
    end
    
    -- Context menu for medical treatment
    hook.Add("OnContextMenuOpen", "KyberMedicalContext", function()
        local tr = LocalPlayer():GetEyeTrace()
        
        if IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity ~= LocalPlayer() then
            if LocalPlayer():GetPos():Distance(tr.Entity:GetPos()) < 100 then
                KYBER.Medical:OpenMedicalUI(tr.Entity)
                return false
            end
        end
    end)
    
    -- HUD injuries
    hook.Add("HUDPaint", "KyberMedicalHUD", function()
        local injuries = LocalPlayer().KyberMedicalInjuries or {}
        
        if #injuries > 0 then
            local y = ScrH() - 350
            local bleeding = false
            
            for _, injury in ipairs(injuries) do
                if not injury.treated then
                    local injuryData = KYBER.Medical.Config.injuryTypes[injury.type]
                    if injuryData then
                        local col = Color(255, 100, 100)
                        if injuryData.bleedRate > 0 then
                            bleeding = true
                            col = Color(255, 50, 50, math.sin(CurTime() * 5) * 127 + 128)
                        end
                        
                        draw.SimpleText(injuryData.name, "DermaDefault", 10, y, col)
                        y = y - 20
                    end
                end
            end
            
            if bleeding then
                -- Bleeding effect on screen edges
                local alpha = math.sin(CurTime() * 3) * 30 + 30
                surface.SetDrawColor(255, 0, 0, alpha)
                
                -- Top
                surface.DrawRect(0, 0, ScrW(), 20)
                -- Bottom
                surface.DrawRect(0, ScrH() - 20, ScrW(), 20)
                -- Left
                surface.DrawRect(0, 0, 20, ScrH())
                -- Right
                surface.DrawRect(ScrW() - 20, 0, 20, ScrH())
            end
        end
        
        -- Clone sickness indicator
        if LocalPlayer():GetWalkSpeed() < 200 then
            draw.SimpleText("CLONE SICKNESS", "DermaLarge", ScrW() / 2, 150, Color(255, 255, 100, math.sin(CurTime() * 2) * 127 + 128), TEXT_ALIGN_CENTER)
        end
    end)
end