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
    include("kyber/gamemode/modules/datapad/vgui.lua")
    
    -- Character selection screen
    local function OpenCharacterSelection()
        if not IsValid(LocalPlayer()) then return end
        
        -- Create the frame
        local frame = vgui.Create("DFrame")
        if not IsValid(frame) then
            print("[Kyber] Failed to create character selection frame")
            return
        end
        
        frame:SetSize(ScrW() * 0.8, ScrH() * 0.8)
        frame:Center()
        frame:SetTitle("Character Selection")
        frame:SetDraggable(false)
        frame:ShowCloseButton(false)
        frame:MakePopup()
        
        -- Add Star Wars themed background
        local bg = vgui.Create("DPanel", frame)
        if IsValid(bg) then
            bg:Dock(FILL)
            bg.Paint = function(self, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 255))
                -- Add star field effect
                for i = 1, 100 do
                    local x = math.random(0, w)
                    local y = math.random(0, h)
                    local size = math.random(1, 3)
                    draw.RoundedBox(0, x, y, size, size, Color(255, 255, 255, 255))
                end
            end
        end
        
        -- Add character list
        local charList = vgui.Create("DScrollPanel", frame)
        if IsValid(charList) then
            charList:SetSize(ScrW() * 0.3, ScrH() * 0.6)
            charList:SetPos(ScrW() * 0.1, ScrH() * 0.1)
            
            -- Get character files
            local steamID = LocalPlayer():SteamID64()
            local files = file.Find("kyber/characters/" .. steamID .. "_*.json", "DATA")
            
            if #files > 0 then
                for _, fileName in ipairs(files) do
                    local charData = file.Read("kyber/characters/" .. fileName, "DATA")
                    if charData then
                        local character = util.JSONToTable(charData)
                        if character then
                            local button = vgui.Create("DButton", charList)
                            if IsValid(button) then
                                button:SetSize(ScrW() * 0.25, 50)
                                button:SetText(character.name)
                                button:SetTextColor(Color(255, 255, 255))
                                button.Paint = function(self, w, h)
                                    draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 200))
                                    if self:IsHovered() then
                                        draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 50))
                                    end
                                end
                                button.DoClick = function()
                                    net.Start("Kyber_Character_Select")
                                    net.WriteString(character.name)
                                    net.SendToServer()
                                    frame:Close()
                                end
                            end
                        end
                    end
                end
            else
                local label = vgui.Create("DLabel", charList)
                if IsValid(label) then
                    label:SetText("No characters found")
                    label:SetTextColor(Color(255, 255, 255))
                    label:SizeToContents()
                    label:Center()
                end
            end
        end
        
        -- Add create character button
        local createButton = vgui.Create("DButton", frame)
        if IsValid(createButton) then
            createButton:SetSize(ScrW() * 0.2, 40)
            createButton:SetPos(ScrW() * 0.1, ScrH() * 0.75)
            createButton:SetText("Create New Character")
            createButton:SetTextColor(Color(255, 255, 255))
            createButton.Paint = function(self, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 200))
                if self:IsHovered() then
                    draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 50))
                end
            end
            createButton.DoClick = function()
                net.Start("Kyber_Character_OpenCreation")
                net.SendToServer()
                frame:Close()
            end
        end
    end
    
    -- Network receiver for opening character selection
    net.Receive("Kyber_Character_OpenSelection", function()
        OpenCharacterSelection()
    end)
end 