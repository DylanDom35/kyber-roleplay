if CLIENT then
    function Kyber_OpenDatapad()
        if IsValid(DatapadFrame) then DatapadFrame:Remove() end

        DatapadFrame = vgui.Create("DFrame")
        DatapadFrame:SetSize(700, 550)
        DatapadFrame:Center()
        DatapadFrame:SetTitle("KYBER Datapad Terminal")
        DatapadFrame:MakePopup()

        local tabSheet = vgui.Create("DPropertySheet", DatapadFrame)
        tabSheet:Dock(FILL)

        -- Character Tab
        local charPanel = vgui.Create("DPanel", tabSheet)
        charPanel:Dock(FILL)

        local charInfo = {
            {label = "Name", value = LocalPlayer():Nick()},
            {label = "Species", value = "Human"},
            {label = "Faction", value = KYBER.Factions[LocalPlayer():GetNWString("kyber_faction", "")] and KYBER.Factions[LocalPlayer():GetNWString("kyber_faction")].name or "None"},
            {label = "Rank", value = LocalPlayer():GetNWString("kyber_rank", "Unranked")},
            {label = "Force Sensitive", value = "Unknown"},
        }

        local y = 10
        for _, info in ipairs(charInfo) do
            local lbl = vgui.Create("DLabel", charPanel)
            lbl:SetText(info.label .. ": " .. info.value)
            lbl:SetPos(20, y)
            lbl:SetSize(640, 20)
            y = y + 25
        end

        tabSheet:AddSheet("Character", charPanel)

        -- Journal Tab
        local journalPanel = vgui.Create("DPanel", tabSheet)
        journalPanel:Dock(FILL)

        local journalEntry = vgui.Create("DTextEntry", journalPanel)
        journalEntry:SetMultiline(true)
        journalEntry:Dock(FILL)
        journalEntry:SetText("Loading...")

        local saveButton = vgui.Create("DButton", journalPanel)
        saveButton:SetText("Save Entry")
        saveButton:Dock(BOTTOM)
        saveButton:SetTall(30)

        tabSheet:AddSheet("Journal", journalPanel)

        -- Request Journal Data
        net.Start("Kyber_OpenJournal")
        net.SendToServer()

        net.Receive("Kyber_SendJournalData", function()
            local data = net.ReadString()
            if IsValid(journalEntry) then
                journalEntry:SetText(data)
            end
        end)

        saveButton.DoClick = function()
            net.Start("Kyber_SubmitJournal")
            net.WriteString(journalEntry:GetValue())
            net.SendToServer()
        end

        -- Faction Tab (Read-only for now)
        local factionPanel = vgui.Create("DPanel", tabSheet)
        factionPanel:Dock(FILL)

        local factionID = LocalPlayer():GetNWString("kyber_faction", "")
        local factionData = KYBER.Factions[factionID]

        local txt = "You are not in a faction."

        if factionData then
            txt = "Faction: " .. factionData.name .. "\n\nDescription: " .. factionData.description
        end

        local factionLabel = vgui.Create("DLabel", factionPanel)
        factionLabel:SetText(txt)
        factionLabel:SetPos(20, 20)
        factionLabel:SetSize(640, 100)
        factionLabel:SetWrap(true)

        tabSheet:AddSheet("Faction", factionPanel)
    end

    -- F4 to open datapad
    hook.Add("ShowSpare4", "KyberDatapadKeybind", function()
        Kyber_OpenDatapad()
    end)
end
