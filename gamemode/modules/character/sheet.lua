if SERVER then
    util.AddNetworkString("Kyber_OpenCharacterSheet")

    hook.Add("ShowSpare1", "KyberOpenCharSheetKeybind", function(ply) -- default is F1
        net.Start("Kyber_OpenCharacterSheet")
        net.Send(ply)
    end)
else
    net.Receive("Kyber_OpenCharacterSheet", function()
        Kyber_OpenCharacterSheet()
    end)

    function Kyber_OpenCharacterSheet()
        if IsValid(KyberSheetFrame) then KyberSheetFrame:Remove() end

        KyberSheetFrame = vgui.Create("DFrame")
        KyberSheetFrame:SetSize(500, 600)
        KyberSheetFrame:Center()
        KyberSheetFrame:SetTitle("Character Sheet")
        KyberSheetFrame:MakePopup()

        local sheetPanel = vgui.Create("DPanel", KyberSheetFrame)
        sheetPanel:Dock(FILL)
        sheetPanel:DockMargin(10, 10, 10, 10)

        local charInfo = {
			{label = "Name", value = LocalPlayer():GetNWString("kyber_name", LocalPlayer():Nick())},
			{label = "Species", value = LocalPlayer():GetNWString("kyber_species", "Human")},
			{label = "Alignment", value = LocalPlayer():GetNWString("kyber_alignment", "Neutral")},
			{label = "Faction", value = KYBER.Factions[LocalPlayer():GetNWString("kyber_faction", "none")] and KYBER.Factions[LocalPlayer():GetNWString("kyber_faction")].name or "None"},
            {label = "Force Sensitive", value = "Unknown"},
            {label = "Backstory", value = "Born into a galaxy in turmoil..."},
            {label = "Known Skills", value = "Piloting, Sabersmithing"}
			{label = "Rank", value = LocalPlayer():GetNWString("kyber_rank", "Unranked")},
        }

        local y = 10
        for _, info in ipairs(charInfo) do
            local lbl = vgui.Create("DLabel", sheetPanel)
            lbl:SetText(info.label .. ": " .. info.value)
            lbl:SetPos(10, y)
            lbl:SetSize(480, 20)
            y = y + 25
        end
    end
end
