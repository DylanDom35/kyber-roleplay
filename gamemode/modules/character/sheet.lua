-- kyber/gamemode/modules/character/sheet.lua
-- Simplified version to avoid syntax errors

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

        -- Get player info safely
        local ply = LocalPlayer()
        local playerName = ply:GetNWString("kyber_name", ply:Nick())
        local playerSpecies = ply:GetNWString("kyber_species", "Human")
        local playerAlignment = ply:GetNWString("kyber_alignment", "Neutral")
        local playerRank = ply:GetNWString("kyber_rank", "Unranked")
        
        -- Get faction safely
        local factionID = ply:GetNWString("kyber_faction", "")
        local factionName = "None"
        if factionID ~= "" and KYBER and KYBER.Factions and KYBER.Factions[factionID] then
            factionName = KYBER.Factions[factionID].name
        end
        
        -- Get Force sensitivity
        local forceSensitive = ply:GetNWBool("kyber_force_sensitive", false) and "Yes" or "No"

        -- Create info table
        local charInfo = {
            {label = "Name", value = playerName},
            {label = "Species", value = playerSpecies},
            {label = "Alignment", value = playerAlignment},
            {label = "Faction", value = factionName},
            {label = "Rank", value = playerRank},
            {label = "Force Sensitive", value = forceSensitive},
            {label = "Backstory", value = "Born into a galaxy in turmoil..."},
            {label = "Known Skills", value = "Piloting, Sabersmithing"}
        }

        -- Display the info
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