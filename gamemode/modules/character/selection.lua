-- kyber/gamemode/modules/character/selection.lua
-- Character selection screen

if SERVER then
    util.AddNetworkString("Kyber_Character_OpenSelection")
    util.AddNetworkString("Kyber_Character_SelectCharacter")
    util.AddNetworkString("Kyber_Character_DeleteCharacter")
    util.AddNetworkString("Kyber_Character_LoadCharacter")
    
    -- Open character selection for player
    function KYBER.Character:OpenSelection(ply)
        local hasChar, files = self:HasCharacter(ply)
        local characters = {}
        
        if hasChar then
            for _, fileName in ipairs(files) do
                local charData = file.Read("kyber/characters/" .. fileName, "DATA")
                if charData then
                    local character = util.JSONToTable(charData)
                    if character then
                        table.insert(characters, character)
                    end
                end
            end
        end
        
        net.Start("Kyber_Character_OpenSelection")
        net.WriteBool(hasChar)
        net.WriteTable(characters)
        net.Send(ply)
    end
    
    -- Handle character selection
    net.Receive("Kyber_Character_SelectCharacter", function(len, ply)
        local charName = net.ReadString()
        local hasChar, files = KYBER.Character:HasCharacter(ply)
        
        if hasChar then
            for _, fileName in ipairs(files) do
                local charData = file.Read("kyber/characters/" .. fileName, "DATA")
                if charData then
                    local character = util.JSONToTable(charData)
                    if character and character.name == charName then
                        KYBER.Character:ApplyCharacter(ply, character)
                        break
                    end
                end
            end
        end
    end)
    
    -- Handle character deletion
    net.Receive("Kyber_Character_DeleteCharacter", function(len, ply)
        local charName = net.ReadString()
        local hasChar, files = KYBER.Character:HasCharacter(ply)
        
        if hasChar then
            for _, fileName in ipairs(files) do
                local charData = file.Read("kyber/characters/" .. fileName, "DATA")
                if charData then
                    local character = util.JSONToTable(charData)
                    if character and character.name == charName then
                        file.Delete("kyber/characters/" .. fileName)
                        break
                    end
                end
            end
        end
    end)
else
    -- Include our custom VGUI elements
    include("modules/datapad/vgui.lua")
    
    -- Character selection screen
    function Kyber_OpenCharacterSelection(hasCharacter, characters)
        if IsValid(KyberSelectionFrame) then KyberSelectionFrame:Remove() end
        
        -- Create main frame
        KyberSelectionFrame = KYBER.CreateSWFrame(nil, "Character Selection", 800, 600)
        
        -- Create main panel
        local mainPanel = KYBER.CreateSWPanel(KyberSelectionFrame, 10, 40, 780, 550)
        
        if not hasCharacter then
            -- No character - show creation button
            local createBtn = KYBER.CreateSWButton(mainPanel, "Create New Character", 290, 250, 220, 50)
            createBtn.DoClick = function()
                KyberSelectionFrame:Remove()
                net.Start("Kyber_Character_OpenCreation")
                net.SendToServer()
            end
            
            local welcomeText = KYBER.CreateSWLabel(mainPanel, "Welcome to Kyber Roleplay", 0, 150, 780, 40)
            welcomeText:SetFont("DermaLarge")
            welcomeText:SetContentAlignment(5)
            
            local subText = KYBER.CreateSWLabel(mainPanel, "Create your character to begin your journey", 0, 200, 780, 30)
            subText:SetFont("DermaDefault")
            subText:SetContentAlignment(5)
        else
            -- Has characters - show selection
            local title = KYBER.CreateSWLabel(mainPanel, "Select Your Character", 0, 20, 780, 40)
            title:SetFont("DermaLarge")
            title:SetContentAlignment(5)
            
            -- Character list
            local charList = vgui.Create("DScrollPanel", mainPanel)
            charList:SetPos(40, 80)
            charList:SetSize(700, 400)
            
            -- Custom scrollbar
            local sbar = charList:GetVBar()
            function sbar:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, KYBER.Colors.Background) end
            function sbar.btnUp:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, KYBER.Colors.Primary) end
            function sbar.btnDown:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, KYBER.Colors.Primary) end
            function sbar.btnGrip:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, KYBER.Colors.Secondary) end
            
            local y = 0
            for _, char in ipairs(characters) do
                local charPanel = KYBER.CreateSWPanel(charList, 0, y, 680, 100)
                
                -- Character name
                local nameLabel = KYBER.CreateSWLabel(charPanel, char.name, 20, 10, 300, 30)
                nameLabel:SetFont("DermaDefaultBold")
                
                -- Character info
                local infoLabel = KYBER.CreateSWLabel(charPanel, 
                    string.format("Species: %s | Last Played: %s", 
                    char.species,
                    os.date("%Y-%m-%d", char.lastPlayed or 0)),
                    20, 40, 300, 20)
                
                -- Select button
                local selectBtn = KYBER.CreateSWButton(charPanel, "Select", 500, 35, 80, 30)
                selectBtn.DoClick = function()
                    net.Start("Kyber_Character_SelectCharacter")
                    net.WriteString(char.name)
                    net.SendToServer()
                    KyberSelectionFrame:Remove()
                end
                
                -- Delete button
                local deleteBtn = KYBER.CreateSWButton(charPanel, "Delete", 590, 35, 80, 30)
                deleteBtn.DoClick = function()
                    local confirm = vgui.Create("DFrame")
                    confirm:SetSize(300, 150)
                    confirm:Center()
                    confirm:SetTitle("Confirm Deletion")
                    confirm:MakePopup()
                    
                    local confirmLabel = vgui.Create("DLabel", confirm)
                    confirmLabel:SetPos(10, 30)
                    confirmLabel:SetSize(280, 40)
                    confirmLabel:SetText("Are you sure you want to delete this character?")
                    confirmLabel:SetWrap(true)
                    
                    local yesBtn = vgui.Create("DButton", confirm)
                    yesBtn:SetPos(10, 80)
                    yesBtn:SetSize(135, 30)
                    yesBtn:SetText("Yes")
                    yesBtn.DoClick = function()
                        net.Start("Kyber_Character_DeleteCharacter")
                        net.WriteString(char.name)
                        net.SendToServer()
                        confirm:Remove()
                        KyberSelectionFrame:Remove()
                        timer.Simple(0.5, function()
                            net.Start("Kyber_Character_OpenSelection")
                            net.SendToServer()
                        end)
                    end
                    
                    local noBtn = vgui.Create("DButton", confirm)
                    noBtn:SetPos(155, 80)
                    noBtn:SetSize(135, 30)
                    noBtn:SetText("No")
                    noBtn.DoClick = function()
                        confirm:Remove()
                    end
                end
                
                y = y + 110
            end
            
            -- Create new character button
            local createBtn = KYBER.CreateSWButton(mainPanel, "Create New Character", 290, 500, 220, 40)
            createBtn.DoClick = function()
                KyberSelectionFrame:Remove()
                net.Start("Kyber_Character_OpenCreation")
                net.SendToServer()
            end
        end
        
        -- Add scanlines effect
        function KyberSelectionFrame:PaintOver(w, h)
            local scanlineHeight = 2
            local scanlineSpacing = 4
            local scanlineAlpha = 20

            for y = 0, h, scanlineSpacing do
                draw.RoundedBox(0, 0, y, w, scanlineHeight, Color(0, 0, 0, scanlineAlpha))
            end
        end
    end
    
    -- Receive character selection data
    net.Receive("Kyber_Character_OpenSelection", function()
        local hasCharacter = net.ReadBool()
        local characters = net.ReadTable()
        Kyber_OpenCharacterSelection(hasCharacter, characters)
    end)
end 