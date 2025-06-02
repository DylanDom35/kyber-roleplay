-- kyber/modules/character/creation.lua
KYBER.Character = KYBER.Character or {}

-- Character creation configuration
KYBER.Character.Config = {
    -- Available models for character creation
    models = {
        ["models/player/group01/male_01.mdl"] = {
            name = "Human Male 1",
            species = "Human",
            gender = "Male",
            bodygroups = {} -- Will be populated if model supports them
        },
        ["models/player/group01/male_02.mdl"] = {
            name = "Human Male 2", 
            species = "Human",
            gender = "Male",
            bodygroups = {}
        },
        ["models/player/group01/male_03.mdl"] = {
            name = "Human Male 3",
            species = "Human", 
            gender = "Male",
            bodygroups = {}
        },
        ["models/player/group01/female_01.mdl"] = {
            name = "Human Female 1",
            species = "Human",
            gender = "Female", 
            bodygroups = {}
        },
        ["models/player/group01/female_02.mdl"] = {
            name = "Human Female 2",
            species = "Human",
            gender = "Female",
            bodygroups = {}
        },
        ["models/player/group01/female_03.mdl"] = {
            name = "Human Female 3",
            species = "Human",
            gender = "Female", 
            bodygroups = {}
        },
        -- Add more models as needed - these are placeholders for SW models
        ["models/player/twi_lek/twi_lek_male.mdl"] = {
            name = "Twi'lek Male",
            species = "Twi'lek",
            gender = "Male",
            bodygroups = {
                {name = "Lekku Style", id = 0, options = {"Standard", "Battle Worn", "Decorated"}},
                {name = "Skin Tone", id = 1, options = {"Blue", "Green", "Red", "Purple"}}
            }
        },
        ["models/player/twi_lek/twi_lek_female.mdl"] = {
            name = "Twi'lek Female", 
            species = "Twi'lek",
            gender = "Female",
            bodygroups = {
                {name = "Lekku Style", id = 0, options = {"Standard", "Battle Worn", "Decorated"}},
                {name = "Skin Tone", id = 1, options = {"Blue", "Green", "Red", "Purple"}}
            }
        }
    },
    
    -- Species information for future expansion
    species = {
        ["Human"] = {
            name = "Human",
            description = "The most common species in the galaxy",
            traits = {}
        },
        ["Twi'lek"] = {
            name = "Twi'lek", 
            description = "Humanoid species with distinctive head-tails",
            traits = {"Natural Dancers", "Diplomatic"}
        }
        -- More species can be added here
    },
    
    -- Default spawn location
    defaultSpawn = Vector(0, 0, 100),
    
    -- Character name validation
    nameMinLength = 3,
    nameMaxLength = 32,
    namePattern = "^[A-Za-z%s%-']+$" -- Letters, spaces, hyphens, apostrophes only
}

if SERVER then
    util.AddNetworkString("Kyber_Character_OpenCreation")
    util.AddNetworkString("Kyber_Character_CreateCharacter") 
    util.AddNetworkString("Kyber_Character_ValidateName")
    util.AddNetworkString("Kyber_Character_NameValidationResult")
    util.AddNetworkString("Kyber_Character_RequestReroll")
    util.AddNetworkString("Kyber_Character_SendModelData")
    
    -- Initialize character system
    function KYBER.Character:Initialize()
        -- Create character directory if it doesn't exist
        if not file.Exists("kyber/characters", "DATA") then
            file.CreateDir("kyber/characters")
        end
        
        print("[Kyber] Character creation system initialized")
    end
    
    -- Check if player has an existing character
    function KYBER.Character:HasCharacter(ply)
        local steamID = ply:SteamID64()
        local files = file.Find("kyber/characters/" .. steamID .. "_*.json", "DATA")
        return #files > 0, files
    end
    
    -- Load player's character data
    function KYBER.Character:LoadCharacter(ply)
        local steamID = ply:SteamID64()
        local hasChar, files = self:HasCharacter(ply)
        
        if not hasChar then
            return nil
        end
        
        -- For now, load the first character (single character system)
        -- Future: Add character selection for multiple characters
        local charFile = files[1]
        local charData = file.Read("kyber/characters/" .. charFile, "DATA")
        
        if charData then
            local character = util.JSONToTable(charData)
            if character then
                return character
            end
        end
        
        return nil
    end
    
    -- Save character data
    function KYBER.Character:SaveCharacter(ply, characterData)
        local steamID = ply:SteamID64()
        local fileName = steamID .. "_" .. util.CRC(characterData.name) .. ".json"
        local filePath = "kyber/characters/" .. fileName
        
        -- Add metadata
        characterData.steamID = steamID
        characterData.created = characterData.created or os.time()
        characterData.lastPlayed = os.time()
        
        -- Save to file
        file.Write(filePath, util.TableToJSON(characterData))
        
        -- Store current character data on player
        ply.KyberCharacter = characterData
        
        -- Set networked vars for other systems
        ply:SetNWString("kyber_name", characterData.name)
        ply:SetNWString("kyber_species", characterData.species)
        ply:SetNWString("kyber_model", characterData.model)
        
        print("[Kyber] Saved character '" .. characterData.name .. "' for " .. ply:Nick())
        
        return true
    end
    
    -- Apply character data to player
    function KYBER.Character:ApplyCharacter(ply, characterData)
        if not IsValid(ply) or not characterData then return end
        
        -- Set model
        ply:SetModel(characterData.model)
        
        -- Apply bodygroups if they exist
        if characterData.bodygroups then
            for bgID, value in pairs(characterData.bodygroups) do
                ply:SetBodygroup(bgID, value)
            end
        end
        
        -- Store character data
        ply.KyberCharacter = characterData
        
        -- Set networked variables
        ply:SetNWString("kyber_name", characterData.name)
        ply:SetNWString("kyber_species", characterData.species) 
        ply:SetNWString("kyber_model", characterData.model)
        
        -- Spawn player if not already spawned
        if not ply:Alive() then
            ply:Spawn()
        end
        
        print("[Kyber] Applied character '" .. characterData.name .. "' to " .. ply:Nick())
    end
    
    -- Validate character name
    function KYBER.Character:ValidateName(name)
        if not name or name == "" then
            return false, "Name cannot be empty"
        end
        
        if #name < self.Config.nameMinLength then
            return false, "Name too short (minimum " .. self.Config.nameMinLength .. " characters)"
        end
        
        if #name > self.Config.nameMaxLength then
            return false, "Name too long (maximum " .. self.Config.nameMaxLength .. " characters)"
        end
        
        if not string.match(name, self.Config.namePattern) then
            return false, "Name contains invalid characters (letters, spaces, hyphens, and apostrophes only)"
        end
        
        -- Check for existing character with same name (across all players)
        local files = file.Find("kyber/characters/*.json", "DATA")
        for _, fileName in ipairs(files) do
            local charData = file.Read("kyber/characters/" .. fileName, "DATA")
            if charData then
                local character = util.JSONToTable(charData)
                if character and character.name and string.lower(character.name) == string.lower(name) then
                    return false, "A character with this name already exists"
                end
            end
        end
        
        return true
    end
    
    -- Delete character (for rerolling)
    function KYBER.Character:DeleteCharacter(ply)
        local steamID = ply:SteamID64()
        local hasChar, files = self:HasCharacter(ply)
        
        if hasChar then
            for _, fileName in ipairs(files) do
                file.Delete("kyber/characters/" .. fileName)
            end
            
            -- Clear player data
            ply.KyberCharacter = nil
            ply:SetNWString("kyber_name", "")
            ply:SetNWString("kyber_species", "")
            ply:SetNWString("kyber_model", "")
            
            print("[Kyber] Deleted character data for " .. ply:Nick())
            return true
        end
        
        return false
    end
    
    -- Network handlers
    net.Receive("Kyber_Character_CreateCharacter", function(len, ply)
        local characterData = net.ReadTable()
        
        -- Validate the character data
        local nameValid, nameError = KYBER.Character:ValidateName(characterData.name)
        if not nameValid then
            ply:ChatPrint("Character creation failed: " .. nameError)
            return
        end
        
        -- Validate model
        if not KYBER.Character.Config.models[characterData.model] then
            ply:ChatPrint("Character creation failed: Invalid model selected")
            return
        end
        
        -- Save character
        local success = KYBER.Character:SaveCharacter(ply, characterData)
        
        if success then
            -- Apply character to player
            KYBER.Character:ApplyCharacter(ply, characterData)
            
            ply:ChatPrint("Character '" .. characterData.name .. "' created successfully!")
            
            -- Initialize other character systems
            timer.Simple(1, function()
                if IsValid(ply) then
                    -- Initialize inventory, reputation, etc.
                    if KYBER.Inventory then KYBER.Inventory:Initialize(ply) end
                    if KYBER.Reputation then KYBER.Reputation:Initialize(ply) end
                    if KYBER.Medical then KYBER.Medical:Initialize(ply) end
                    if KYBER.Banking then KYBER.Banking:Initialize(ply) end
                    if KYBER.Equipment then KYBER.Equipment:Initialize(ply) end
                    if KYBER.Crafting then KYBER.Crafting:Initialize(ply) end
                end
            end)
        else
            ply:ChatPrint("Character creation failed: Could not save character data")
        end
    end)
    
    net.Receive("Kyber_Character_ValidateName", function(len, ply)
        local name = net.ReadString()
        local isValid, error = KYBER.Character:ValidateName(name)
        
        net.Start("Kyber_Character_NameValidationResult")
        net.WriteBool(isValid)
        net.WriteString(error or "")
        net.Send(ply)
    end)
    
    net.Receive("Kyber_Character_RequestReroll", function(len, ply)
        -- Delete existing character and trigger creation
        KYBER.Character:DeleteCharacter(ply)
        
        -- Send them to character creation
        net.Start("Kyber_Character_OpenCreation")
        net.WriteTable(KYBER.Character.Config.models)
        net.Send(ply)
        
        ply:ChatPrint("Character data cleared. Creating new character...")
    end)
    
    -- Player spawn handling
    hook.Add("PlayerInitialSpawn", "KyberCharacterCheck", function(ply)
        timer.Simple(1, function()
            if not IsValid(ply) then return end
            
            local hasChar, _ = KYBER.Character:HasCharacter(ply)
            
            if not hasChar then
                -- New player - open character creation
                net.Start("Kyber_Character_OpenCreation")
                net.WriteTable(KYBER.Character.Config.models)
                net.Send(ply)
                
                print("[Kyber] Opened character creation for new player: " .. ply:Nick())
            else
                -- Load existing character
                local characterData = KYBER.Character:LoadCharacter(ply)
                if characterData then
                    KYBER.Character:ApplyCharacter(ply, characterData)
                    print("[Kyber] Loaded existing character '" .. characterData.name .. "' for " .. ply:Nick())
                end
            end
        end)
    end)
    
    -- Initialize on server start
    hook.Add("Initialize", "KyberCharacterInit", function()
        KYBER.Character:Initialize()
    end)
    
    -- Console commands
    concommand.Add("kyber_character_reroll", function(ply)
        if not IsValid(ply) then return end
        
        net.Start("Kyber_Character_RequestReroll")
        net.SendToServer()
    end)
    
    concommand.Add("kyber_character_info", function(ply)
        if not IsValid(ply) or not ply.KyberCharacter then
            print("No character data loaded")
            return
        end
        
        local char = ply.KyberCharacter
        print("=== Character Information ===")
        print("Name: " .. char.name)
        print("Species: " .. char.species)
        print("Model: " .. char.model)
        print("Created: " .. os.date("%c", char.created))
        print("Last Played: " .. os.date("%c", char.lastPlayed))
    end)
    
else -- CLIENT
    
    local CharacterCreationFrame = nil
    local selectedModel = nil
    local selectedBodygroups = {}
    local modelPreview = nil
    
    -- Receive character creation request
    net.Receive("Kyber_Character_OpenCreation", function()
        local modelData = net.ReadTable()
        KYBER.Character:OpenCreationUI(modelData)
    end)
    
    -- Receive name validation result
    net.Receive("Kyber_Character_NameValidationResult", function()
        local isValid = net.ReadBool()
        local error = net.ReadString()
        
        if IsValid(CharacterCreationFrame) and CharacterCreationFrame.nameEntry then
            if isValid then
                CharacterCreationFrame.nameEntry:SetTextColor(Color(100, 255, 100))
                CharacterCreationFrame.nameStatus:SetText("✓ Name available")
                CharacterCreationFrame.nameStatus:SetTextColor(Color(100, 255, 100))
                CharacterCreationFrame.createButton:SetEnabled(true)
            else
                CharacterCreationFrame.nameEntry:SetTextColor(Color(255, 100, 100))
                CharacterCreationFrame.nameStatus:SetText("✗ " .. error)
                CharacterCreationFrame.nameStatus:SetTextColor(Color(255, 100, 100))
                CharacterCreationFrame.createButton:SetEnabled(false)
            end
        end
    end)
    
    -- Open character creation UI
    function KYBER.Character:OpenCreationUI(modelData)
        if IsValid(CharacterCreationFrame) then
            CharacterCreationFrame:Remove()
        end
        
        -- Create main frame with Star Wars styling
        CharacterCreationFrame = vgui.Create("DFrame")
        CharacterCreationFrame:SetSize(1000, 700)
        CharacterCreationFrame:Center()
        CharacterCreationFrame:SetTitle("")
        CharacterCreationFrame:SetDraggable(false)
        CharacterCreationFrame:SetSizable(false)
        CharacterCreationFrame:MakePopup()
        CharacterCreationFrame:SetDeleteOnClose(false)
        
        -- Custom paint for sci-fi styling
        CharacterCreationFrame.Paint = function(self, w, h)
            -- Background
            draw.RoundedBox(0, 0, 0, w, h, Color(15, 20, 35, 240))
            
            -- Border glow effect
            surface.SetDrawColor(50, 150, 255, 100)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            surface.DrawOutlinedRect(2, 2, w - 4, h - 4, 1)
            
            -- Title area
            draw.RoundedBox(0, 0, 0, w, 50, Color(20, 30, 50, 200))
            draw.SimpleText("CHARACTER CREATION PROTOCOL", "DermaLarge", w/2, 25, Color(100, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Subtle animated elements
            local time = CurTime()
            local pulse = math.sin(time * 2) * 0.1 + 0.9
            
            -- Corner accents
            surface.SetDrawColor(50, 150, 255, 255 * pulse)
            surface.DrawRect(10, 10, 30, 3)
            surface.DrawRect(10, 10, 3, 30)
            surface.DrawRect(w - 40, 10, 30, 3)
            surface.DrawRect(w - 13, 10, 3, 30)
            surface.DrawRect(10, h - 13, 30, 3)
            surface.DrawRect(10, h - 40, 3, 30)
            surface.DrawRect(w - 40, h - 13, 30, 3)
            surface.DrawRect(w - 13, h - 40, 3, 30)
        end
        
        -- Create main container
        local container = vgui.Create("DPanel", CharacterCreationFrame)
        container:SetPos(20, 60)
        container:SetSize(960, 620)
        container.Paint = function() end
        
        -- Left panel - Character details
        local leftPanel = vgui.Create("DPanel", container)
        leftPanel:SetPos(0, 0)
        leftPanel:SetSize(450, 620)
        leftPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(25, 35, 55, 180))
            surface.SetDrawColor(50, 150, 255, 80)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        
        -- Character name section
        local nameLabel = vgui.Create("DLabel", leftPanel)
        nameLabel:SetPos(20, 20)
        nameLabel:SetSize(400, 30)
        nameLabel:SetText("CHARACTER DESIGNATION")
        nameLabel:SetFont("DermaDefaultBold")
        nameLabel:SetTextColor(Color(100, 200, 255))
        
        CharacterCreationFrame.nameEntry = vgui.Create("DTextEntry", leftPanel)
        CharacterCreationFrame.nameEntry:SetPos(20, 50)
        CharacterCreationFrame.nameEntry:SetSize(400, 35)
        CharacterCreationFrame.nameEntry:SetPlaceholderText("Enter character name...")
        CharacterCreationFrame.nameEntry:SetFont("DermaDefault")
        
        -- Custom paint for text entry
        CharacterCreationFrame.nameEntry.Paint = function(self, w, h)
            draw.RoundedBox(2, 0, 0, w, h, Color(10, 15, 25, 200))
            surface.SetDrawColor(50, 150, 255, 100)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            
            self:DrawTextEntryText(Color(255, 255, 255), Color(100, 200, 255), Color(255, 255, 255))
        end
        
        -- Name validation status
        CharacterCreationFrame.nameStatus = vgui.Create("DLabel", leftPanel)
        CharacterCreationFrame.nameStatus:SetPos(20, 90)
        CharacterCreationFrame.nameStatus:SetSize(400, 20)
        CharacterCreationFrame.nameStatus:SetText("Enter a character name")
        CharacterCreationFrame.nameStatus:SetTextColor(Color(150, 150, 150))
        
        -- Name validation on text change
        CharacterCreationFrame.nameEntry.OnValueChange = function(self, value)
            if value and value ~= "" then
                timer.Create("KyberNameValidation", 0.5, 1, function()
                    if IsValid(CharacterCreationFrame) then
                        net.Start("Kyber_Character_ValidateName")
                        net.WriteString(value)
                        net.SendToServer()
                    end
                end)
            else
                CharacterCreationFrame.nameStatus:SetText("Enter a character name")
                CharacterCreationFrame.nameStatus:SetTextColor(Color(150, 150, 150))
                CharacterCreationFrame.createButton:SetEnabled(false)
            end
        end
        
        -- Species/Model selection
        local modelLabel = vgui.Create("DLabel", leftPanel)
        modelLabel:SetPos(20, 130)
        modelLabel:SetSize(400, 30)
        modelLabel:SetText("SPECIES SELECTION")
        modelLabel:SetFont("DermaDefaultBold")
        modelLabel:SetTextColor(Color(100, 200, 255))
        
        -- Model list
        local modelList = vgui.Create("DScrollPanel", leftPanel)
        modelList:SetPos(20, 160)
        modelList:SetSize(400, 300)
        
        -- Custom scrollbar styling
        local sbar = modelList:GetVBar()
        sbar.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(20, 30, 50, 100))
        end
        sbar.btnUp.Paint = function() end
        sbar.btnDown.Paint = function() end
        sbar.btnGrip.Paint = function(self, w, h)
            draw.RoundedBox(2, 2, 0, w - 4, h, Color(50, 150, 255, 150))
        end
        
        -- Populate model list
        for modelPath, modelInfo in pairs(modelData) do
            local modelPanel = vgui.Create("DButton", modelList)
            modelPanel:SetSize(380, 60)
            modelPanel:Dock(TOP)
            modelPanel:DockMargin(0, 0, 0, 5)
            modelPanel:SetText("")
            
            modelPanel.Paint = function(self, w, h)
                local bgColor = Color(30, 40, 60, 150)
                local borderColor = Color(50, 150, 255, 80)
                
                if self:IsHovered() or selectedModel == modelPath then
                    bgColor = Color(40, 50, 80, 200)
                    borderColor = Color(100, 200, 255, 150)
                end
                
                if selectedModel == modelPath then
                    borderColor = Color(100, 255, 100, 200)
                end
                
                draw.RoundedBox(2, 0, 0, w, h, bgColor)
                surface.SetDrawColor(borderColor)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                
                -- Model info
                draw.SimpleText(modelInfo.name, "DermaDefaultBold", 10, 10, Color(255, 255, 255))
                draw.SimpleText("Species: " .. modelInfo.species, "DermaDefault", 10, 30, Color(200, 200, 200))
                draw.SimpleText("Gender: " .. modelInfo.gender, "DermaDefault", 10, 45, Color(200, 200, 200))
            end
            
            modelPanel.DoClick = function()
                selectedModel = modelPath
                selectedBodygroups = {}
                
                -- Update model preview
                if IsValid(modelPreview) then
                    modelPreview:SetModel(modelPath)
                    local ent = modelPreview:GetEntity()
                    if IsValid(ent) then
                        ent:SetSequence(ent:LookupSequence("idle_all_01"))
                    end
                end
                
                -- Update bodygroup panel
                self:UpdateBodygroupPanel(modelInfo)
            end
        end
        
        -- Bodygroup customization section
        local bodygroupLabel = vgui.Create("DLabel", leftPanel)
        bodygroupLabel:SetPos(20, 480)
        bodygroupLabel:SetSize(400, 30)
        bodygroupLabel:SetText("BIOMETRIC CUSTOMIZATION")
        bodygroupLabel:SetFont("DermaDefaultBold")
        bodygroupLabel:SetTextColor(Color(100, 200, 255))
        
        CharacterCreationFrame.bodygroupPanel = vgui.Create("DPanel", leftPanel)
        CharacterCreationFrame.bodygroupPanel:SetPos(20, 510)
        CharacterCreationFrame.bodygroupPanel:SetSize(400, 80)
        CharacterCreationFrame.bodygroupPanel.Paint = function(self, w, h)
            draw.RoundedBox(2, 0, 0, w, h, Color(20, 30, 50, 150))
            surface.SetDrawColor(50, 150, 255, 60)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            
            if not selectedModel then
                draw.SimpleText("Select a species to customize appearance", "DermaDefault", w/2, h/2, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
        
        -- Right panel - Model preview
        local rightPanel = vgui.Create("DPanel", container)
        rightPanel:SetPos(470, 0)
        rightPanel:SetSize(490, 620)
        rightPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(25, 35, 55, 180))
            surface.SetDrawColor(50, 150, 255, 80)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            
            -- Hologram effect overlay
            local time = CurTime()
            local scanLine = (time * 100) % h
            surface.SetDrawColor(100, 200, 255, 30)
            surface.DrawRect(0, scanLine - 2, w, 4)
        end
        
        local previewLabel = vgui.Create("DLabel", rightPanel)
        previewLabel:SetPos(20, 20)
        previewLabel:SetSize(450, 30)
        previewLabel:SetText("HOLOGRAPHIC PREVIEW")
        previewLabel:SetFont("DermaDefaultBold")
        previewLabel:SetTextColor(Color(100, 200, 255))
        
        -- Model preview panel
        modelPreview = vgui.Create("DModelPanel", rightPanel)
        modelPreview:SetPos(20, 60)
        modelPreview:SetSize(450, 450)
        modelPreview:SetFOV(45)
        modelPreview:SetCamPos(Vector(100, 0, 60))
        modelPreview:SetLookAt(Vector(0, 0, 40))
        
        -- Hologram effect for model preview
        modelPreview.PreDrawModel = function(self, ent)
            render.SetColorModulation(0.6, 0.8, 1)
            render.SetBlend(0.8)
        end
        
        modelPreview.PostDrawModel = function(self, ent)
            render.SetColorModulation(1, 1, 1)
            render.SetBlend(1)
        end
        
        function modelPreview:LayoutEntity(ent)
            ent:SetAngles(Angle(0, RealTime() * 20, 0))
        end
        
        -- Create character button
        CharacterCreationFrame.createButton = vgui.Create("DButton", rightPanel)
        CharacterCreationFrame.createButton:SetPos(150, 530)
        CharacterCreationFrame.createButton:SetSize(200, 50)
        CharacterCreationFrame.createButton:SetText("")
        CharacterCreationFrame.createButton:SetEnabled(false)
        
        CharacterCreationFrame.createButton.Paint = function(self, w, h)
            local bgColor = Color(20, 80, 20, 150)
            local textColor = Color(100, 255, 100)
            
            if not self:IsEnabled() then
                bgColor = Color(60, 60, 60, 150)
                textColor = Color(150, 150, 150)
            elseif self:IsHovered() then
                bgColor = Color(30, 120, 30, 200)
                textColor = Color(150, 255, 150)
            end
            
            draw.RoundedBox(4, 0, 0, w, h, bgColor)
            surface.SetDrawColor(textColor.r, textColor.g, textColor.b, 200)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            
            draw.SimpleText("INITIALIZE CHARACTER", "DermaDefaultBold", w/2, h/2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        CharacterCreationFrame.createButton.DoClick = function()
            if not selectedModel then
                notification.AddLegacy("Please select a species", NOTIFY_ERROR, 3)
                return
            end
            
            local name = CharacterCreationFrame.nameEntry:GetValue()
            if not name or name == "" then
                notification.AddLegacy("Please enter a character name", NOTIFY_ERROR, 3)
                return
            end
            
            -- Create character data
            local characterData = {
                name = name,
                model = selectedModel,
                species = modelData[selectedModel].species,
                gender = modelData[selectedModel].gender,
                bodygroups = selectedBodygroups
            }
            
            -- Send to server
            net.Start("Kyber_Character_CreateCharacter")
            net.WriteTable(characterData)
            net.SendToServer()
            
            CharacterCreationFrame:Remove()
            CharacterCreationFrame = nil
        end
        
        -- Initialize with no model selected
        selectedModel = nil
        selectedBodygroups = {}
    end
    
    -- Update bodygroup customization panel
    function KYBER.Character:UpdateBodygroupPanel(modelInfo)
        if not IsValid(CharacterCreationFrame) or not IsValid(CharacterCreationFrame.bodygroupPanel) then
            return
        end
        
        CharacterCreationFrame.bodygroupPanel:Clear()
        
        if not modelInfo.bodygroups or #modelInfo.bodygroups == 0 then
            -- No bodygroups available - show disabled message
            local noBodygroupLabel = vgui.Create("DLabel", CharacterCreationFrame.bodygroupPanel)
            noBodygroupLabel:SetPos(10, 10)
            noBodygroupLabel:SetSize(380, 60)
            noBodygroupLabel:SetText("This species does not support biometric customization")
            noBodygroupLabel:SetTextColor(Color(120, 120, 120))
            noBodygroupLabel:SetContentAlignment(5)
            noBodygroupLabel:SetWrap(true)
            return
        end
        
        -- Create bodygroup controls
        local yPos = 10
        for _, bodygroup in ipairs(modelInfo.bodygroups) do
            if yPos > 60 then break end -- Prevent overflow
            
            local bgLabel = vgui.Create("DLabel", CharacterCreationFrame.bodygroupPanel)
            bgLabel:SetPos(10, yPos)
            bgLabel:SetSize(150, 20)
            bgLabel:SetText(bodygroup.name .. ":")
            bgLabel:SetTextColor(Color(200, 200, 200))
            
            local bgCombo = vgui.Create("DComboBox", CharacterCreationFrame.bodygroupPanel)
            bgCombo:SetPos(170, yPos)
            bgCombo:SetSize(200, 20)
            bgCombo:SetValue(bodygroup.options[1] or "Default")
            
            -- Custom paint for combo box
            bgCombo.Paint = function(self, w, h)
                draw.RoundedBox(2, 0, 0, w, h, Color(20, 30, 50, 200))
                surface.SetDrawColor(50, 150, 255, 100)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            
            -- Add options
            for optionIndex, option in ipairs(bodygroup.options) do
                bgCombo:AddChoice(option, optionIndex - 1) -- Bodygroups are 0-indexed
            end
            
            bgCombo.OnSelect = function(self, index, value, data)
                selectedBodygroups[bodygroup.id] = data
                
                -- Update model preview
                if IsValid(modelPreview) then
                    local ent = modelPreview:GetEntity()
                    if IsValid(ent) then
                        ent:SetBodygroup(bodygroup.id, data)
                    end
                end
            end
            
            yPos = yPos + 25
        end
    end
    
    -- Character sheet UI (for viewing/editing existing characters)
    function KYBER.Character:OpenCharacterSheet()
        local ply = LocalPlayer()
        if not ply.KyberCharacter then
            chat.AddText(Color(255, 100, 100), "[Character] No character data loaded")
            return
        end
        
        local char = ply.KyberCharacter
        
        local frame = vgui.Create("DFrame")
        frame:SetSize(600, 500)
        frame:Center()
        frame:SetTitle("")
        frame:MakePopup()
        
        -- Custom paint matching creation UI style
        frame.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(15, 20, 35, 240))
            surface.SetDrawColor(50, 150, 255, 100)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            
            draw.RoundedBox(0, 0, 0, w, 50, Color(20, 30, 50, 200))
            draw.SimpleText("CHARACTER DATABANK", "DermaLarge", w/2, 25, Color(100, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        local container = vgui.Create("DPanel", frame)
        container:SetPos(20, 60)
        container:SetSize(560, 420)
        container.Paint = function() end
        
        -- Character info panel
        local infoPanel = vgui.Create("DPanel", container)
        infoPanel:SetPos(0, 0)
        infoPanel:SetSize(270, 420)
        infoPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(25, 35, 55, 180))
            surface.SetDrawColor(50, 150, 255, 80)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        
        -- Character details
        local yPos = 20
        local function AddInfoLine(label, value, color)
            local lbl = vgui.Create("DLabel", infoPanel)
            lbl:SetPos(20, yPos)
            lbl:SetSize(230, 20)
            lbl:SetText(label .. ": " .. value)
            lbl:SetTextColor(color or Color(255, 255, 255))
            yPos = yPos + 25
        end
        
        AddInfoLine("Name", char.name, Color(100, 200, 255))
        AddInfoLine("Species", char.species, Color(200, 200, 200))
        AddInfoLine("Gender", char.gender, Color(200, 200, 200))
        
        if char.created then
            AddInfoLine("Created", os.date("%m/%d/%Y", char.created), Color(150, 150, 150))
        end
        
        if char.lastPlayed then
            AddInfoLine("Last Played", os.date("%m/%d/%Y", char.lastPlayed), Color(150, 150, 150))
        end
        
        -- Add additional character info from other systems
        yPos = yPos + 20
        local additionalInfo = hook.Run("Kyber_CharacterSheet_AddInfo", ply) or {}
        
        if #additionalInfo > 0 then
            local addLabel = vgui.Create("DLabel", infoPanel)
            addLabel:SetPos(20, yPos)
            addLabel:SetSize(230, 20)
            addLabel:SetText("Additional Information:")
            addLabel:SetFont("DermaDefaultBold")
            addLabel:SetTextColor(Color(100, 200, 255))
            yPos = yPos + 30
            
            for _, info in ipairs(additionalInfo) do
                if type(info) == "table" and info.label and info.value then
                    AddInfoLine(info.label, info.value, Color(200, 200, 200))
                end
            end
        end
        
        -- Character model preview
        local previewPanel = vgui.Create("DPanel", container)
        previewPanel:SetPos(290, 0)
        previewPanel:SetSize(270, 350)
        previewPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(25, 35, 55, 180))
            surface.SetDrawColor(50, 150, 255, 80)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            
            -- Hologram effect
            local time = CurTime()
            local scanLine = (time * 80) % h
            surface.SetDrawColor(100, 200, 255, 20)
            surface.DrawRect(0, scanLine - 1, w, 2)
        end
        
        local modelPanel = vgui.Create("DModelPanel", previewPanel)
        modelPanel:SetPos(10, 10)
        modelPanel:SetSize(250, 330)
        modelPanel:SetModel(char.model)
        modelPanel:SetFOV(45)
        modelPanel:SetCamPos(Vector(80, 0, 50))
        modelPanel:SetLookAt(Vector(0, 0, 40))
        
        -- Apply bodygroups if they exist
        if char.bodygroups then
            local ent = modelPanel:GetEntity()
            if IsValid(ent) then
                for bgID, value in pairs(char.bodygroups) do
                    ent:SetBodygroup(bgID, value)
                end
            end
        end
        
        -- Hologram effect for model
        modelPanel.PreDrawModel = function(self, ent)
            render.SetColorModulation(0.6, 0.8, 1)
            render.SetBlend(0.9)
        end
        
        modelPanel.PostDrawModel = function(self, ent)
            render.SetColorModulation(1, 1, 1)
            render.SetBlend(1)
        end
        
        function modelPanel:LayoutEntity(ent)
            ent:SetAngles(Angle(0, RealTime() * 15, 0))
        end
        
        -- Action buttons
        local buttonPanel = vgui.Create("DPanel", container)
        buttonPanel:SetPos(290, 360)
        buttonPanel:SetSize(270, 60)
        buttonPanel.Paint = function() end
        
        local rerollBtn = vgui.Create("DButton", buttonPanel)
        rerollBtn:SetPos(0, 0)
        rerollBtn:SetSize(130, 50)
        rerollBtn:SetText("")
        
        rerollBtn.Paint = function(self, w, h)
            local bgColor = Color(80, 20, 20, 150)
            local textColor = Color(255, 100, 100)
            
            if self:IsHovered() then
                bgColor = Color(120, 30, 30, 200)
                textColor = Color(255, 150, 150)
            end
            
            draw.RoundedBox(4, 0, 0, w, h, bgColor)
            surface.SetDrawColor(textColor.r, textColor.g, textColor.b, 200)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            
            draw.SimpleText("REROLL", "DermaDefaultBold", w/2, h/2 - 8, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("CHARACTER", "DermaDefault", w/2, h/2 + 8, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        rerollBtn.DoClick = function()
            Derma_Query(
                "Are you sure you want to delete this character and create a new one?\n\nThis action cannot be undone!",
                "Confirm Character Reroll",
                "Yes, Reroll", function()
                    net.Start("Kyber_Character_RequestReroll")
                    net.SendToServer()
                    frame:Close()
                end,
                "Cancel", function() end
            )
        end
        
        local closeBtn = vgui.Create("DButton", buttonPanel)
        closeBtn:SetPos(140, 0)
        closeBtn:SetSize(130, 50)
        closeBtn:SetText("")
        
        closeBtn.Paint = function(self, w, h)
            local bgColor = Color(20, 60, 80, 150)
            local textColor = Color(100, 200, 255)
            
            if self:IsHovered() then
                bgColor = Color(30, 80, 120, 200)
                textColor = Color(150, 220, 255)
            end
            
            draw.RoundedBox(4, 0, 0, w, h, bgColor)
            surface.SetDrawColor(textColor.r, textColor.g, textColor.b, 200)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            
            draw.SimpleText("CLOSE", "DermaDefaultBold", w/2, h/2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        closeBtn.DoClick = function()
            frame:Close()
        end
    end
    
    -- Add character sheet to F4 datapad
    hook.Add("Kyber_Datapad_AddTabs", "AddCharacterSheet", function(tabSheet)
        local charPanel = vgui.Create("DPanel", tabSheet)
        charPanel:Dock(FILL)
        
        charPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20))
        end
        
        local title = vgui.Create("DLabel", charPanel)
        title:SetText("Character Information")
        title:SetFont("DermaLarge")
        title:Dock(TOP)
        title:DockMargin(20, 20, 20, 10)
        title:SetContentAlignment(5)
        
        local openSheetBtn = vgui.Create("DButton", charPanel)
        openSheetBtn:SetText("Open Character Sheet")
        openSheetBtn:SetSize(200, 50)
        openSheetBtn:SetPos(20, 80)
        
        openSheetBtn.DoClick = function()
            KYBER.Character:OpenCharacterSheet()
        end
        
        -- Quick character info display
        local quickInfo = vgui.Create("DPanel", charPanel)
        quickInfo:SetPos(20, 140)
        quickInfo:SetSize(600, 200)
        
        quickInfo.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            
            local ply = LocalPlayer()
            if ply.KyberCharacter then
                local char = ply.KyberCharacter
                
                draw.SimpleText("Character: " .. char.name, "DermaDefaultBold", 20, 20, Color(100, 200, 255))
                draw.SimpleText("Species: " .. char.species, "DermaDefault", 20, 45, Color(200, 200, 200))
                draw.SimpleText("Gender: " .. char.gender, "DermaDefault", 20, 65, Color(200, 200, 200))
                
                if char.created then
                    draw.SimpleText("Created: " .. os.date("%m/%d/%Y", char.created), "DermaDefault", 20, 90, Color(150, 150, 150))
                end
                
                -- Show additional info from other systems
                local additionalInfo = hook.Run("Kyber_CharacterSheet_AddInfo", ply) or {}
                local yPos = 120
                
                for i, info in ipairs(additionalInfo) do
                    if i > 3 then break end -- Only show first 3 additional items
                    if type(info) == "table" and info.label and info.value then
                        draw.SimpleText(info.label .. ": " .. info.value, "DermaDefault", 20, yPos, Color(200, 200, 200))
                        yPos = yPos + 20
                    end
                end
            else
                draw.SimpleText("No character data loaded", "DermaDefault", 20, 20, Color(255, 100, 100))
            end
        end
        
        tabSheet:AddSheet("Character", charPanel, "icon16/user.png")
    end)
    
    -- Console commands
    concommand.Add("kyber_character_sheet", function()
        KYBER.Character:OpenCharacterSheet()
    end)
    
end

-- Extensibility and Integration Ideas:

--[[
FUTURE EXPANSIONS:

1. Multiple Characters per Account:
   - Modify file naming to include character slot: steamID_slot1.json, steamID_slot2.json
   - Add character selection screen before spawning
   - Store "active character" preference
   - Example: KYBER.Character:GetCharacterSlots(ply) returns table of all characters

2. Faction/Species-Specific UIs:
   - Create theme tables in Config with different color schemes
   - Add KYBER.Character.Themes["imperial"] = {primary = Color(...), accent = Color(...)}
   - Modify paint functions to use selected theme
   - Load theme based on character's faction or species

3. Advanced Bodygroup System:
   - Support for player accessory models (hats, gear, etc.)
   - Save/load bodygroup presets
   - Racial trait modifiers based on species selection
   - Integration with PAC3 if available

4. Character Background System:
   - Add backstory text field to creation
   - Character age, homeworld selection
   - Starting skill bonuses based on background
   - Integration with reputation system for starting faction relationships

5. Integration Hooks:
   - "Kyber_Character_Created" hook for other systems to initialize data
   - "Kyber_Character_PreLoad" hook to modify character data before applying
   - "Kyber_Character_PostLoad" hook for systems that need to react to character loading

6. Character Progression Tracking:
   - Track total playtime, deaths, missions completed
   - Achievement system integration
   - Character "legacy" system for retired characters

INTEGRATION EXAMPLES:

-- In your reputation system:
hook.Add("Kyber_Character_Created", "InitializeReputation", function(ply, characterData)
    if characterData.species == "Twi'lek" then
        KYBER.Reputation:ChangeReputation(ply, "hutt", 25, "Species bonus")
    end
end)

-- In your inventory system:
hook.Add("Kyber_Character_PostLoad", "GiveStartingItems", function(ply, characterData)
    if not characterData.hasStartingItems then
        KYBER.Inventory:GiveItem(ply, "comlink", 1)
        KYBER.Inventory:GiveItem(ply, "credits", 100)
        characterData.hasStartingItems = true
        KYBER.Character:SaveCharacter(ply, characterData)
    end
end)

-- Character sheet integration:
hook.Add("Kyber_CharacterSheet_AddInfo", "AddCustomInfo", function(ply)
    return {
        {label = "Force Sensitive", value = ply:GetNWBool("kyber_force_sensitive") and "Yes" or "No"},
        {label = "Credits", value = tostring(KYBER:GetPlayerData(ply, "credits") or 0)},
        {label = "Faction", value = ply:GetNWString("kyber_faction", "None")}
    }
end)

DATABASE MIGRATION PATH:
When ready for MySQL, modify these functions:
- KYBER.Character:SaveCharacter() - Use SQL INSERT/UPDATE
- KYBER.Character:LoadCharacter() - Use SQL SELECT  
- KYBER.Character:HasCharacter() - Use SQL EXISTS query
- KYBER.Character:ValidateName() - Use SQL SELECT for name uniqueness

SECURITY CONSIDERATIONS:
- Add rate limiting for character creation
- Validate all client data on server
- Sanitize character names against XSS/injection
- Consider character name reservation system
--]]