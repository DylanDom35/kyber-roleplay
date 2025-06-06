-- kyber/gamemode/modules/character/sheet.lua
-- Character sheet module with Star Wars themed UI

if SERVER then
    util.AddNetworkString("Kyber_OpenCharacterSheet")
    util.AddNetworkString("Kyber_UpdateCharacterData")

    -- Function to get character data
    function KYBER.GetCharacterData(ply)
        return {
            name = ply:GetNWString("kyber_name", ply:Nick()),
            species = ply:GetNWString("kyber_species", "Human"),
            alignment = ply:GetNWString("kyber_alignment", "Neutral"),
            faction = ply:GetNWString("kyber_faction", ""),
            rank = ply:GetNWString("kyber_rank", "Unranked"),
            force_sensitive = ply:GetNWBool("kyber_force_sensitive", false),
            backstory = ply:GetNWString("kyber_backstory", "Born into a galaxy in turmoil..."),
            skills = ply:GetNWString("kyber_skills", "Piloting, Sabersmithing")
        }
    end

    -- Function to update character data
    function KYBER.UpdateCharacterData(ply, data)
        if not IsValid(ply) then return end
        
        for key, value in pairs(data) do
            if key == "name" then
                ply:SetNWString("kyber_name", value)
            elseif key == "species" then
                ply:SetNWString("kyber_species", value)
            elseif key == "alignment" then
                ply:SetNWString("kyber_alignment", value)
            elseif key == "backstory" then
                ply:SetNWString("kyber_backstory", value)
            elseif key == "skills" then
                ply:SetNWString("kyber_skills", value)
            end
        end
        
        -- Notify client of update
        net.Start("Kyber_UpdateCharacterData")
        net.WriteTable(data)
        net.Send(ply)
    end

    hook.Add("ShowSpare1", "KyberOpenCharSheetKeybind", function(ply)
        net.Start("Kyber_OpenCharacterSheet")
        net.WriteTable(KYBER.GetCharacterData(ply))
        net.Send(ply)
    end)
else
    -- Include our custom VGUI elements
    include("modules/datapad/vgui.lua")

    net.Receive("Kyber_OpenCharacterSheet", function()
        local data = net.ReadTable()
        Kyber_OpenCharacterSheet(data)
    end)

    net.Receive("Kyber_UpdateCharacterData", function()
        local data = net.ReadTable()
        if IsValid(KyberSheetFrame) then
            KyberSheetFrame:UpdateData(data)
        end
    end)

    function Kyber_OpenCharacterSheet(data)
        if IsValid(KyberSheetFrame) then KyberSheetFrame:Remove() end

        -- Create main frame
        KyberSheetFrame = KYBER.CreateSWFrame(nil, "Character Sheet", 600, 700)
        
        -- Create main panel
        local mainPanel = KYBER.CreateSWPanel(KyberSheetFrame, 10, 40, 580, 650)
        
        -- Character portrait
        local portrait = KYBER.CreateSWPanel(mainPanel, 20, 20, 200, 250)
        local portraitLabel = KYBER.CreateSWLabel(portrait, "Character Portrait", 0, 0, 200, 20)
        portraitLabel:SetContentAlignment(5)
        
        -- Character info
        local infoPanel = KYBER.CreateSWPanel(mainPanel, 240, 20, 320, 250)
        
        local charInfo = {
            {label = "Name", value = data.name},
            {label = "Species", value = data.species},
            {label = "Alignment", value = data.alignment},
            {label = "Faction", value = KYBER.Factions[data.faction] and KYBER.Factions[data.faction].name or "None"},
            {label = "Rank", value = data.rank},
            {label = "Force Sensitive", value = data.force_sensitive and "Yes" or "No"}
        }
        
        local y = 10
        for _, info in ipairs(charInfo) do
            local label = KYBER.CreateSWLabel(infoPanel, info.label .. ":", 10, y, 100, 20)
            local value = KYBER.CreateSWLabel(infoPanel, info.value, 120, y, 190, 20)
            y = y + 30
        end
        
        -- Backstory
        local backstoryPanel = KYBER.CreateSWPanel(mainPanel, 20, 290, 540, 150)
        local backstoryLabel = KYBER.CreateSWLabel(backstoryPanel, "Backstory", 10, 10, 520, 20)
        local backstoryText = KYBER.CreateSWLabel(backstoryPanel, data.backstory, 10, 40, 520, 100)
        backstoryText:SetWrap(true)
        
        -- Skills
        local skillsPanel = KYBER.CreateSWPanel(mainPanel, 20, 460, 540, 150)
        local skillsLabel = KYBER.CreateSWLabel(skillsPanel, "Known Skills", 10, 10, 520, 20)
        local skillsText = KYBER.CreateSWLabel(skillsPanel, data.skills, 10, 40, 520, 100)
        skillsText:SetWrap(true)
        
        -- Edit button
        local editButton = KYBER.CreateSWButton(mainPanel, "Edit Character", 20, 630, 540, 30)
        editButton.DoClick = function()
            -- TODO: Implement character editing
            chat.AddText(KYBER.Colors.Primary, "Character editing coming soon!")
        end
        
        -- Add scanlines effect
        function KyberSheetFrame:PaintOver(w, h)
            local scanlineHeight = 2
            local scanlineSpacing = 4
            local scanlineAlpha = 20

            for y = 0, h, scanlineSpacing do
                draw.RoundedBox(0, 0, y, w, scanlineHeight, Color(0, 0, 0, scanlineAlpha))
            end
        end
        
        -- Add update function
        function KyberSheetFrame:UpdateData(newData)
            data = newData
            -- Update all labels with new data
            -- TODO: Implement dynamic updates
        end
    end
end