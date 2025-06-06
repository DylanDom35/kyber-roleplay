if CLIENT then
    -- Include our custom VGUI elements
    include("modules/datapad/vgui.lua")

    function Kyber_OpenDatapad()
        if IsValid(DatapadFrame) then DatapadFrame:Remove() end

        -- Create main frame
        DatapadFrame = KYBER.CreateSWFrame(nil, "KYBER Datapad Terminal", 800, 600)

        -- Create property sheet
        local tabSheet = KYBER.CreateSWPropertySheet(DatapadFrame)
        tabSheet:Dock(FILL)
        tabSheet:DockMargin(10, 10, 10, 10)

        -- Character Tab
        local charPanel = KYBER.CreateSWPanel(tabSheet, 0, 0, 780, 520)
        charPanel:Dock(FILL)

        -- Request character data
        net.Start("Kyber_OpenCharacterSheet")
        net.SendToServer()

        net.Receive("Kyber_OpenCharacterSheet", function()
            local data = net.ReadTable()
            
            -- Character info
            local charInfo = {
                {label = "Name", value = data.name},
                {label = "Species", value = data.species},
                {label = "Alignment", value = data.alignment},
                {label = "Faction", value = KYBER.Factions[data.faction] and KYBER.Factions[data.faction].name or "None"},
                {label = "Rank", value = data.rank},
                {label = "Force Sensitive", value = data.force_sensitive and "Yes" or "No"}
            }

            local y = 20
            for _, info in ipairs(charInfo) do
                local label = KYBER.CreateSWLabel(charPanel, info.label .. ":", 20, y, 150, 20)
                local value = KYBER.CreateSWLabel(charPanel, info.value, 180, y, 580, 20)
                y = y + 30
            end

            -- Add character portrait
            local portrait = KYBER.CreateSWPanel(charPanel, 20, y + 20, 200, 250)
            local portraitLabel = KYBER.CreateSWLabel(portrait, "Character Portrait", 0, 0, 200, 20)
            portraitLabel:SetContentAlignment(5)

            -- Add quick stats
            local statsPanel = KYBER.CreateSWPanel(charPanel, 240, y + 20, 520, 250)
            local statsLabel = KYBER.CreateSWLabel(statsPanel, "Quick Stats", 10, 10, 500, 20)
            
            -- Add backstory preview
            local backstoryPanel = KYBER.CreateSWPanel(charPanel, 20, y + 290, 740, 100)
            local backstoryLabel = KYBER.CreateSWLabel(backstoryPanel, "Backstory Preview", 10, 10, 720, 20)
            local backstoryText = KYBER.CreateSWLabel(backstoryPanel, string.sub(data.backstory, 1, 200) .. "...", 10, 40, 720, 50)
            backstoryText:SetWrap(true)

            -- Add view full profile button
            local viewProfileBtn = KYBER.CreateSWButton(charPanel, "View Full Profile", 20, y + 410, 740, 30)
            viewProfileBtn.DoClick = function()
                Kyber_OpenCharacterSheet(data)
            end
        end)

        tabSheet:AddSheet("Character", charPanel, "icon16/user.png")

        -- Journal Tab
        local journalPanel = KYBER.CreateSWPanel(tabSheet, 0, 0, 780, 520)
        journalPanel:Dock(FILL)

        local journalEntry = KYBER.CreateSWTextEntry(journalPanel, 10, 10, 760, 460)
        journalEntry:SetMultiline(true)
        journalEntry:SetText("Loading...")

        local saveButton = KYBER.CreateSWButton(journalPanel, "Save Entry", 10, 480, 760, 30)
        saveButton.DoClick = function()
            net.Start("Kyber_SubmitJournal")
            net.WriteString(journalEntry:GetValue())
            net.SendToServer()
        end

        tabSheet:AddSheet("Journal", journalPanel, "icon16/book.png")

        -- Request Journal Data
        net.Start("Kyber_OpenJournal")
        net.SendToServer()

        net.Receive("Kyber_SendJournalData", function()
            local data = net.ReadString()
            if IsValid(journalEntry) then
                journalEntry:SetText(data)
            end
        end)

        -- Faction Tab
        local factionPanel = KYBER.CreateSWPanel(tabSheet, 0, 0, 780, 520)
        factionPanel:Dock(FILL)

        net.Receive("Kyber_OpenCharacterSheet", function()
            local data = net.ReadTable()
            local factionID = data.faction
            local factionData = KYBER.Factions[factionID]

            if factionData then
                -- Faction header
                local header = KYBER.CreateSWLabel(factionPanel, factionData.name, 20, 20, 740, 40)
                header:SetFont("DermaLarge")
                header:SetContentAlignment(5)

                -- Faction description
                local desc = KYBER.CreateSWLabel(factionPanel, factionData.description, 20, 70, 740, 60)
                desc:SetWrap(true)

                -- Faction ranks
                local ranksLabel = KYBER.CreateSWLabel(factionPanel, "Available Ranks:", 20, 140, 740, 20)
                local y = 170
                for _, rank in ipairs(factionData.ranks) do
                    local rankLabel = KYBER.CreateSWLabel(factionPanel, "• " .. rank, 40, y, 720, 20)
                    y = y + 25
                end

                -- Current rank
                local currentRank = KYBER.CreateSWLabel(factionPanel, "Current Rank: " .. data.rank, 20, y + 20, 740, 30)
                currentRank:SetFont("DermaDefaultBold")
                currentRank:SetContentAlignment(5)
            else
                local noFaction = KYBER.CreateSWLabel(factionPanel, "You are not in a faction.", 20, 20, 740, 40)
                noFaction:SetFont("DermaLarge")
                noFaction:SetContentAlignment(5)
            end
        end)

        tabSheet:AddSheet("Faction", factionPanel, "icon16/group.png")

        -- Add customization button to the menu
        local customizationButton = vgui.Create("DButton", charPanel)
        customizationButton:SetPos(20, 450) -- Adjust position as needed
        customizationButton:SetSize(740, 30)
        customizationButton:SetText("Character Customization")
        customizationButton.DoClick = function()
            net.Start("Kyber_Customization_Open")
            net.SendToServer()
        end

        -- Add decorative elements
        local time = 0
        hook.Add("Think", "KyberDatapadAnimation", function()
            if not IsValid(DatapadFrame) then
                hook.Remove("Think", "KyberDatapadAnimation")
                return
            end
            time = time + FrameTime()
        end)

        -- Add scanlines effect
        function DatapadFrame:PaintOver(w, h)
            local scanlineHeight = 2
            local scanlineSpacing = 4
            local scanlineAlpha = 20

            for y = 0, h, scanlineSpacing do
                draw.RoundedBox(0, 0, y, w, scanlineHeight, Color(0, 0, 0, scanlineAlpha))
            end
        end
    end

    -- F4 to open datapad
    hook.Add("ShowSpare4", "KyberDatapadKeybind", function()
        Kyber_OpenDatapad()
    end)
end
