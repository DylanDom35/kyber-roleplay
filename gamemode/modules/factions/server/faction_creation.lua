-- kyber/modules/factions/creation.lua
if SERVER then
    util.AddNetworkString("Kyber_CreateFaction")
    util.AddNetworkString("Kyber_EditFaction")
    util.AddNetworkString("Kyber_DisbandFaction")
    util.AddNetworkString("Kyber_OpenFactionCreator")
    
    -- Faction creation costs and requirements
    KYBER.FactionConfig = {
        minMembers = 3,
        creationCost = 5000,
        nameMaxLength = 32,
        descMaxLength = 256,
        maxRanks = 10,
        defaultRanks = {"Recruit", "Member", "Officer", "Leader"}
    }
    
    -- Store custom factions in data folder
    function KYBER:SaveCustomFactions()
        if not file.Exists("kyber/factions", "DATA") then
            file.CreateDir("kyber/factions")
        end
        
        local data = util.TableToJSON(KYBER.CustomFactions or {})
        file.Write("kyber/factions/custom.json", data)
    end
    
    function KYBER:LoadCustomFactions()
        if file.Exists("kyber/factions/custom.json", "DATA") then
            local data = file.Read("kyber/factions/custom.json", "DATA")
            KYBER.CustomFactions = util.JSONToTable(data) or {}
            
            -- Merge with base factions
            for id, faction in pairs(KYBER.CustomFactions) do
                KYBER.Factions[id] = faction
            end
        else
            KYBER.CustomFactions = {}
        end
    end
    
    -- Initialize on server start
    hook.Add("Initialize", "KyberLoadCustomFactions", function()
        KYBER:LoadCustomFactions()
    end)
    
    function KYBER:CreateFaction(founder, data)
        -- Validate founder
        if not IsValid(founder) then return false, "Invalid founder" end
        
        -- Check if founder already leads a faction
        for id, faction in pairs(KYBER.Factions) do
            if faction.founder == founder:SteamID64() then
                return false, "You already lead a faction"
            end
        end
        
        -- Validate faction data
        if not data.name or #data.name > KYBER.FactionConfig.nameMaxLength then
            return false, "Invalid faction name"
        end
        
        if not data.description or #data.description > KYBER.FactionConfig.descMaxLength then
            return false, "Invalid faction description"
        end
        
        -- Check credits
        local credits = KYBER:GetPlayerData(founder, "credits") or 0
        if credits < KYBER.FactionConfig.creationCost then
            return false, "Insufficient credits (need " .. KYBER.FactionConfig.creationCost .. ")"
        end
        
        -- Generate unique ID
        local factionID = "custom_" .. os.time() .. "_" .. math.random(1000, 9999)
        
        -- Create faction structure
        local newFaction = {
            name = data.name,
            description = data.description,
            color = data.color or Color(200, 200, 200),
            founder = founder:SteamID64(),
            created = os.time(),
            members = {[founder:SteamID64()] = true},
            ranks = data.ranks or table.Copy(KYBER.FactionConfig.defaultRanks),
            canUseForce = data.canUseForce or false,
            isCustom = true,
            
            -- Faction perks/stats
            perks = {
                creditBonus = 0,        -- % bonus to credit earnings
                spawnArmor = 0,         -- Extra armor on spawn
                craftingBonus = 0,      -- % bonus to crafting success
                reputationGain = 0      -- % bonus to reputation gains
            },
            
            -- Visual customization
            icon = data.icon or "icon16/group.png",
            banner = data.banner or "",
            
            -- Faction bank/resources
            treasury = 0,
            resources = {}
        }
        
        -- Deduct credits
        KYBER:SetPlayerData(founder, "credits", credits - KYBER.FactionConfig.creationCost)
        
        -- Save faction
        KYBER.CustomFactions[factionID] = newFaction
        KYBER.Factions[factionID] = newFaction
        KYBER:SaveCustomFactions()
        
        -- Set founder as leader
        KYBER:SetFaction(founder, factionID)
        founder:SetNWString("kyber_rank", newFaction.ranks[#newFaction.ranks])
        
        -- Broadcast creation
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[FACTION] " .. founder:Nick() .. " has founded the " .. newFaction.name .. "!")
        end
        
        return true, factionID
    end
    
    function KYBER:DisbandFaction(factionID, disbander)
        local faction = KYBER.Factions[factionID]
        if not faction or not faction.isCustom then
            return false, "Cannot disband this faction"
        end
        
        -- Check if disbander is the founder
        if faction.founder ~= disbander:SteamID64() then
            return false, "Only the founder can disband the faction"
        end
        
        -- Remove all members
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetNWString("kyber_faction") == factionID then
                ply:SetNWString("kyber_faction", "")
                ply:SetNWString("kyber_rank", "")
                ply:ChatPrint("Your faction has been disbanded.")
            end
        end
        
        -- Return half the treasury to founder
        if faction.treasury > 0 then
            local refund = math.floor(faction.treasury / 2)
            local currentCredits = KYBER:GetPlayerData(disbander, "credits") or 0
            KYBER:SetPlayerData(disbander, "credits", currentCredits + refund)
            disbander:ChatPrint("You received " .. refund .. " credits from the faction treasury.")
        end
        
        -- Remove faction
        KYBER.CustomFactions[factionID] = nil
        KYBER.Factions[factionID] = nil
        KYBER:SaveCustomFactions()
        
        return true
    end
    
    -- Networking
    net.Receive("Kyber_CreateFaction", function(len, ply)
        local data = net.ReadTable()
        local success, result = KYBER:CreateFaction(ply, data)
        
        if success then
            ply:ChatPrint("Faction created successfully!")
        else
            ply:ChatPrint("Failed to create faction: " .. result)
        end
    end)
    
    net.Receive("Kyber_DisbandFaction", function(len, ply)
        local factionID = ply:GetNWString("kyber_faction")
        local success, result = KYBER:DisbandFaction(factionID, ply)
        
        if success then
            ply:ChatPrint("Faction disbanded.")
        else
            ply:ChatPrint("Failed to disband: " .. result)
        end
    end)
    
    concommand.Add("kyber_factioncreator", function(ply)
        net.Start("Kyber_OpenFactionCreator")
        net.Send(ply)
    end)
    
else -- CLIENT
    
    net.Receive("Kyber_OpenFactionCreator", function()
        if IsValid(FactionCreatorFrame) then FactionCreatorFrame:Remove() end
        
        FactionCreatorFrame = vgui.Create("DFrame")
        FactionCreatorFrame:SetSize(600, 700)
        FactionCreatorFrame:Center()
        FactionCreatorFrame:SetTitle("Create Your Faction")
        FactionCreatorFrame:MakePopup()
        
        local panel = vgui.Create("DScrollPanel", FactionCreatorFrame)
        panel:Dock(FILL)
        panel:DockMargin(10, 10, 10, 10)
        
        -- Faction name
        local nameLabel = vgui.Create("DLabel", panel)
        nameLabel:SetText("Faction Name:")
        nameLabel:Dock(TOP)
        nameLabel:DockMargin(0, 5, 0, 5)
        
        local nameEntry = vgui.Create("DTextEntry", panel)
        nameEntry:SetPlaceholderText("Enter faction name...")
        nameEntry:Dock(TOP)
        nameEntry:DockMargin(0, 0, 0, 10)
        
        -- Description
        local descLabel = vgui.Create("DLabel", panel)
        descLabel:SetText("Description:")
        descLabel:Dock(TOP)
        descLabel:DockMargin(0, 5, 0, 5)
        
        local descEntry = vgui.Create("DTextEntry", panel)
        descEntry:SetMultiline(true)
        descEntry:SetTall(100)
        descEntry:SetPlaceholderText("Describe your faction's goals and ideals...")
        descEntry:Dock(TOP)
        descEntry:DockMargin(0, 0, 0, 10)
        
        -- Color picker
        local colorLabel = vgui.Create("DLabel", panel)
        colorLabel:SetText("Faction Color:")
        colorLabel:Dock(TOP)
        colorLabel:DockMargin(0, 5, 0, 5)
        
        local colorMixer = vgui.Create("DColorMixer", panel)
        colorMixer:SetTall(200)
        colorMixer:Dock(TOP)
        colorMixer:DockMargin(0, 0, 0, 10)
        colorMixer:SetColor(Color(100, 100, 255))
        
        -- Force sensitivity option
        local forceCheck = vgui.Create("DCheckBoxLabel", panel)
        forceCheck:SetText("Force-Sensitive Faction")
        forceCheck:Dock(TOP)
        forceCheck:DockMargin(0, 5, 0, 10)
        
        -- Ranks editor
        local ranksLabel = vgui.Create("DLabel", panel)
        ranksLabel:SetText("Faction Ranks (from lowest to highest):")
        ranksLabel:Dock(TOP)
        ranksLabel:DockMargin(0, 5, 0, 5)
        
        local ranksList = vgui.Create("DListView", panel)
        ranksList:SetTall(150)
        ranksList:Dock(TOP)
        ranksList:DockMargin(0, 0, 0, 5)
        ranksList:AddColumn("Rank Name")
        
        -- Default ranks
        local defaultRanks = {"Recruit", "Member", "Officer", "Leader"}
        for _, rank in ipairs(defaultRanks) do
            ranksList:AddLine(rank)
        end
        
        -- Add/Remove rank buttons
        local rankButtonPanel = vgui.Create("DPanel", panel)
        rankButtonPanel:SetTall(30)
        rankButtonPanel:Dock(TOP)
        rankButtonPanel:DockMargin(0, 0, 0, 10)
        rankButtonPanel.Paint = function() end
        
        local addRankBtn = vgui.Create("DButton", rankButtonPanel)
        addRankBtn:SetText("Add Rank")
        addRankBtn:Dock(LEFT)
        addRankBtn:SetWide(100)
        addRankBtn.DoClick = function()
            Derma_StringRequest("Add Rank", "Enter rank name:", "", function(text)
                if text and text ~= "" then
                    ranksList:AddLine(text)
                end
            end)
        end
        
        local removeRankBtn = vgui.Create("DButton", rankButtonPanel)
        removeRankBtn:SetText("Remove Selected")
        removeRankBtn:Dock(LEFT)
        removeRankBtn:SetWide(120)
        removeRankBtn:DockMargin(5, 0, 0, 0)
        removeRankBtn.DoClick = function()
            local selected = ranksList:GetSelectedLine()
            if selected then
                ranksList:RemoveLine(selected)
            end
        end
        
        -- Cost display
        local costLabel = vgui.Create("DLabel", panel)
        costLabel:SetText("Creation Cost: " .. KYBER.FactionConfig.creationCost .. " credits")
        costLabel:SetFont("DermaLarge")
        costLabel:Dock(TOP)
        costLabel:DockMargin(0, 20, 0, 10)
        
        -- Create button
        local createBtn = vgui.Create("DButton", panel)
        createBtn:SetText("Create Faction")
        createBtn:SetTall(40)
        createBtn:Dock(TOP)
        createBtn:DockMargin(0, 10, 0, 0)
        createBtn.DoClick = function()
            -- Gather ranks
            local ranks = {}
            for _, line in ipairs(ranksList:GetLines()) do
                table.insert(ranks, line:GetValue(1))
            end
            
            -- Prepare data
            local data = {
                name = nameEntry:GetValue(),
                description = descEntry:GetValue(),
                color = colorMixer:GetColor(),
                canUseForce = forceCheck:GetChecked(),
                ranks = ranks
            }
            
            -- Send to server
            net.Start("Kyber_CreateFaction")
            net.WriteTable(data)
            net.SendToServer()
            
            FactionCreatorFrame:Close()
        end
    end)
    
    -- Add faction management to existing faction menu
    hook.Add("Kyber_FactionMenu_AddOptions", "AddCustomFactionOptions", function(menu, factionID)
        local faction = KYBER.Factions[factionID]
        if not faction or not faction.isCustom then return end
        
        local ply = LocalPlayer()
        if faction.founder == ply:SteamID64() then
            menu:AddSpacer()
            
            local disbandBtn = menu:Add("DButton")
            disbandBtn:SetText("Disband Faction")
            disbandBtn:SetTextColor(Color(255, 100, 100))
            disbandBtn:Dock(TOP)
            disbandBtn:DockMargin(10, 5, 10, 5)
            disbandBtn.DoClick = function()
                Derma_Query("Are you sure you want to disband your faction?", "Confirm Disband",
                    "Yes", function()
                        net.Start("Kyber_DisbandFaction")
                        net.SendToServer()
                    end,
                    "No", function() end
                )
            end
        end
    end)
end