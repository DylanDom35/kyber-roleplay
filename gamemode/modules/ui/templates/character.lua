-- kyber/gamemode/modules/ui/templates/character.lua
-- Character creation UI template

local KYBER = KYBER or {}

-- Character UI
KYBER.UI.Character = KYBER.UI.Character or {}

-- Create character UI
function KYBER.UI.Character.Create(parent)
    local panel = KYBER.UI.Panel.CreateModal(parent, "Create Character", KYBER.UI.Panel.Styles.Default, {w = 800, h = 600})
    
    -- Create tabs
    local tabs = vgui.Create("DPropertySheet", panel.content)
    tabs:SetSize(panel.content:GetWide(), panel.content:GetTall())
    tabs:SetPos(0, 0)
    
    -- Appearance tab
    local appearanceTab = vgui.Create("DPanel")
    tabs:AddSheet("Appearance", appearanceTab)
    
    -- Create form
    local form = KYBER.UI.Form.CreateWithCancel(
        appearanceTab,
        KYBER.UI.Form.Styles.Default,
        {w = 780, h = 500},
        function(values)
            -- Save appearance
            KYBER.Character.appearance = values
        end,
        function()
            panel:Close()
        end
    )
    form:SetPos(10, 10)
    
    -- Add fields
    form:AddField("gender", "Gender", "select", {
        required = true,
        options = {
            {label = "Male", value = "male"},
            {label = "Female", value = "female"}
        }
    })
    
    form:AddField("race", "Race", "select", {
        required = true,
        options = {
            {label = "Human", value = "human"},
            {label = "Elf", value = "elf"},
            {label = "Dwarf", value = "dwarf"},
            {label = "Orc", value = "orc"}
        }
    })
    
    form:AddField("hair_style", "Hair Style", "select", {
        required = true,
        options = {
            {label = "Style 1", value = "style1"},
            {label = "Style 2", value = "style2"},
            {label = "Style 3", value = "style3"}
        }
    })
    
    form:AddField("hair_color", "Hair Color", "color", {
        required = true
    })
    
    form:AddField("eye_color", "Eye Color", "color", {
        required = true
    })
    
    form:AddField("skin_tone", "Skin Tone", "slider", {
        required = true,
        min = 0,
        max = 100,
        default = 50
    })
    
    form:AddField("height", "Height", "slider", {
        required = true,
        min = 150,
        max = 200,
        default = 175
    })
    
    form:AddField("weight", "Weight", "slider", {
        required = true,
        min = 50,
        max = 100,
        default = 75
    })
    
    -- Attributes tab
    local attributesTab = vgui.Create("DPanel")
    tabs:AddSheet("Attributes", attributesTab)
    
    -- Create form
    local form = KYBER.UI.Form.CreateWithCancel(
        attributesTab,
        KYBER.UI.Form.Styles.Default,
        {w = 780, h = 500},
        function(values)
            -- Save attributes
            KYBER.Character.attributes = values
        end,
        function()
            panel:Close()
        end
    )
    form:SetPos(10, 10)
    
    -- Add fields
    form:AddField("strength", "Strength", "slider", {
        required = true,
        min = 1,
        max = 10,
        default = 5
    })
    
    form:AddField("dexterity", "Dexterity", "slider", {
        required = true,
        min = 1,
        max = 10,
        default = 5
    })
    
    form:AddField("constitution", "Constitution", "slider", {
        required = true,
        min = 1,
        max = 10,
        default = 5
    })
    
    form:AddField("intelligence", "Intelligence", "slider", {
        required = true,
        min = 1,
        max = 10,
        default = 5
    })
    
    form:AddField("wisdom", "Wisdom", "slider", {
        required = true,
        min = 1,
        max = 10,
        default = 5
    })
    
    form:AddField("charisma", "Charisma", "slider", {
        required = true,
        min = 1,
        max = 10,
        default = 5
    })
    
    -- Background tab
    local backgroundTab = vgui.Create("DPanel")
    tabs:AddSheet("Background", backgroundTab)
    
    -- Create form
    local form = KYBER.UI.Form.CreateWithCancel(
        backgroundTab,
        KYBER.UI.Form.Styles.Default,
        {w = 780, h = 500},
        function(values)
            -- Save background
            KYBER.Character.background = values
        end,
        function()
            panel:Close()
        end
    )
    form:SetPos(10, 10)
    
    -- Add fields
    form:AddField("name", "Name", "text", {
        required = true,
        min = 3,
        max = 20
    })
    
    form:AddField("age", "Age", "number", {
        required = true,
        min = 18,
        max = 100,
        default = 25
    })
    
    form:AddField("birthplace", "Birthplace", "select", {
        required = true,
        options = {
            {label = "City", value = "city"},
            {label = "Village", value = "village"},
            {label = "Wilderness", value = "wilderness"}
        }
    })
    
    form:AddField("occupation", "Occupation", "select", {
        required = true,
        options = {
            {label = "Merchant", value = "merchant"},
            {label = "Warrior", value = "warrior"},
            {label = "Mage", value = "mage"},
            {label = "Rogue", value = "rogue"}
        }
    })
    
    form:AddField("background_story", "Background Story", "textarea", {
        required = true,
        min = 100,
        max = 1000
    })
    
    -- Add buttons
    local createButton = KYBER.UI.Button.Create(
        panel.content,
        "Create Character",
        KYBER.UI.Button.Styles.Primary,
        {w = 150, h = 40},
        function()
            KYBER.UI.Character.CreateCharacter()
        end
    )
    createButton:SetPos(600, 550)
    
    local cancelButton = KYBER.UI.Button.Create(
        panel.content,
        "Cancel",
        KYBER.UI.Button.Styles.Secondary,
        {w = 150, h = 40},
        function()
            panel:Close()
        end
    )
    cancelButton:SetPos(450, 550)
    
    return panel
end

-- Create character
function KYBER.UI.Character.CreateCharacter()
    -- Validate data
    if not KYBER.Character.appearance or not KYBER.Character.attributes or not KYBER.Character.background then
        KYBER.UI.Notification.Create("Please fill in all required fields.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Create character
    KYBER.SQL.Query(
        "INSERT INTO characters (steam_id, name, gender, race, hair_style, hair_color, eye_color, skin_tone, height, weight, strength, dexterity, constitution, intelligence, wisdom, charisma, age, birthplace, occupation, background_story) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        {
            LocalPlayer():SteamID(),
            KYBER.Character.background.name,
            KYBER.Character.appearance.gender,
            KYBER.Character.appearance.race,
            KYBER.Character.appearance.hair_style,
            KYBER.Character.appearance.hair_color,
            KYBER.Character.appearance.eye_color,
            KYBER.Character.appearance.skin_tone,
            KYBER.Character.appearance.height,
            KYBER.Character.appearance.weight,
            KYBER.Character.attributes.strength,
            KYBER.Character.attributes.dexterity,
            KYBER.Character.attributes.constitution,
            KYBER.Character.attributes.intelligence,
            KYBER.Character.attributes.wisdom,
            KYBER.Character.attributes.charisma,
            KYBER.Character.background.age,
            KYBER.Character.background.birthplace,
            KYBER.Character.background.occupation,
            KYBER.Character.background.background_story
        },
        function()
            -- Show success message
            KYBER.UI.Notification.Create("Character created successfully.", KYBER.UI.Notification.Styles.Success)
            
            -- Close character creation
            if KYBER.UI.Character.panel then
                KYBER.UI.Character.panel:Close()
            end
            
            -- Refresh character selection
            KYBER.UI.MainMenu.ShowCharacterSelection()
        end
    )
end

-- Show character selection UI
function KYBER.UI.Character.ShowSelection(parent)
    local panel = KYBER.UI.Panel.CreateModal(parent, "Character Selection", KYBER.UI.Panel.Styles.Default, {w = 800, h = 600})
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(panel.content, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("Name", 200, true)
    list:AddColumn("Species", 150, true)
    list:AddColumn("Occupation", 200, true)
    list:AddColumn("Level", 100, true)
    list:AddColumn("Last Login", 200, true)
    
    -- Add context menu
    local menuItems = {
        {
            label = "Select Character",
            callback = function(row)
                KYBER.UI.Character.SelectCharacter(row.data)
            end
        },
        {
            label = "Edit Character",
            callback = function(row)
                KYBER.UI.Character.ShowEditDialog(row.data)
            end
        },
        {
            label = "Delete Character",
            callback = function(row)
                KYBER.UI.Character.ShowDeleteDialog(row.data)
            end
        }
    }
    
    list = KYBER.UI.List.CreateWithContextMenu(panel.content, KYBER.UI.List.Styles.Default, {w = 780, h = 500}, menuItems)
    list:SetPos(10, 10)
    
    -- Add create button
    local createButton = KYBER.UI.Button.Create(
        panel.content,
        "Create Character",
        KYBER.UI.Button.Styles.Primary,
        {w = 120, h = 30},
        function()
            KYBER.UI.Character.Create(panel)
        end
    )
    createButton:SetPos(10, 520)
    
    -- Load characters
    KYBER.SQL.Query(
        "SELECT * FROM characters WHERE steam_id = ?",
        {LocalPlayer():SteamID()},
        function(rows)
            if not rows then return end
            
            -- Add rows
            for _, row in ipairs(rows) do
                list:AddRow({
                    name = row.name,
                    species = row.species,
                    occupation = row.occupation,
                    level = row.level,
                    last_login = row.last_login
                })
            end
        end
    )
    
    return panel
end

-- Select character
function KYBER.UI.Character.SelectCharacter(character)
    -- Save selected character
    KYBER.Character.selected = character
    
    -- Update last login
    KYBER.SQL.Query(
        "UPDATE characters SET last_login = CURRENT_TIMESTAMP WHERE id = ?",
        {character.id}
    )
    
    -- Close selection UI
    if KYBER.UI.Character.selectionPanel then
        KYBER.UI.Character.selectionPanel:Close()
    end
end

-- Show edit dialog
function KYBER.UI.Character.ShowEditDialog(character)
    local panel = KYBER.UI.Panel.CreateModal(nil, "Edit Character", KYBER.UI.Panel.Styles.Default, {w = 800, h = 600})
    
    -- Create tabs
    local tabs = vgui.Create("DPropertySheet", panel.content)
    tabs:SetSize(panel.content:GetWide(), panel.content:GetTall())
    tabs:SetPos(0, 0)
    
    -- Basic Info tab
    local basicInfoTab = vgui.Create("DPanel")
    tabs:AddSheet("Basic Info", basicInfoTab)
    
    -- Create form
    local form = KYBER.UI.Form.CreateWithCancel(
        basicInfoTab,
        KYBER.UI.Form.Styles.Default,
        {w = 780, h = 500},
        function(values)
            -- Update basic info
            KYBER.SQL.Query(
                "UPDATE characters SET name = ?, gender = ?, age = ?, height = ?, weight = ? WHERE id = ?",
                {
                    values.name,
                    values.gender,
                    values.age,
                    values.height,
                    values.weight,
                    character.id
                },
                function()
                    panel:Close()
                    -- Refresh character selection
                    KYBER.UI.Character.RefreshSelection()
                end
            )
        end,
        function()
            panel:Close()
        end
    )
    form:SetPos(10, 10)
    
    -- Add fields
    form:AddField("name", "Name", "text", {
        required = true,
        minLength = 3,
        maxLength = 32,
        pattern = "^[a-zA-Z0-9_ ]+$",
        patternError = "Name can only contain letters, numbers, spaces, and underscores",
        default = character.name
    })
    
    form:AddField("gender", "Gender", "select", {
        required = true,
        options = {
            {label = "Male", value = "male"},
            {label = "Female", value = "female"}
        },
        default = character.gender
    })
    
    form:AddField("age", "Age", "number", {
        required = true,
        min = 18,
        max = 100,
        default = character.age
    })
    
    form:AddField("height", "Height (cm)", "number", {
        required = true,
        min = 100,
        max = 250,
        default = character.height
    })
    
    form:AddField("weight", "Weight (kg)", "number", {
        required = true,
        min = 30,
        max = 200,
        default = character.weight
    })
    
    -- Appearance tab
    local appearanceTab = vgui.Create("DPanel")
    tabs:AddSheet("Appearance", appearanceTab)
    
    -- Create form
    local form = KYBER.UI.Form.CreateWithCancel(
        appearanceTab,
        KYBER.UI.Form.Styles.Default,
        {w = 780, h = 500},
        function(values)
            -- Update appearance
            KYBER.SQL.Query(
                "UPDATE characters SET hair_style = ?, hair_color = ?, eye_color = ?, skin_tone = ? WHERE id = ?",
                {
                    values.hair_style,
                    values.hair_color,
                    values.eye_color,
                    values.skin_tone,
                    character.id
                },
                function()
                    panel:Close()
                    -- Refresh character selection
                    KYBER.UI.Character.RefreshSelection()
                end
            )
        end,
        function()
            panel:Close()
        end
    )
    form:SetPos(10, 10)
    
    -- Add fields
    form:AddField("hair_style", "Hair Style", "select", {
        required = true,
        options = {
            {label = "Style 1", value = "style1"},
            {label = "Style 2", value = "style2"},
            {label = "Style 3", value = "style3"}
        },
        default = character.hair_style
    })
    
    form:AddField("hair_color", "Hair Color", "color", {
        required = true,
        default = character.hair_color
    })
    
    form:AddField("eye_color", "Eye Color", "color", {
        required = true,
        default = character.eye_color
    })
    
    form:AddField("skin_tone", "Skin Tone", "slider", {
        required = true,
        min = 0,
        max = 100,
        default = character.skin_tone
    })
    
    -- Background tab
    local backgroundTab = vgui.Create("DPanel")
    tabs:AddSheet("Background", backgroundTab)
    
    -- Create form
    local form = KYBER.UI.Form.CreateWithCancel(
        backgroundTab,
        KYBER.UI.Form.Styles.Default,
        {w = 780, h = 500},
        function(values)
            -- Update background
            KYBER.SQL.Query(
                "UPDATE characters SET birthplace = ?, occupation = ?, background_story = ? WHERE id = ?",
                {
                    values.birthplace,
                    values.occupation,
                    values.background_story,
                    character.id
                },
                function()
                    panel:Close()
                    -- Refresh character selection
                    KYBER.UI.Character.RefreshSelection()
                end
            )
        end,
        function()
            panel:Close()
        end
    )
    form:SetPos(10, 10)
    
    -- Add fields
    form:AddField("birthplace", "Birthplace", "select", {
        required = true,
        options = {
            {label = "City", value = "city"},
            {label = "Village", value = "village"},
            {label = "Wilderness", value = "wilderness"}
        },
        default = character.birthplace
    })
    
    form:AddField("occupation", "Occupation", "select", {
        required = true,
        options = {
            {label = "Merchant", value = "merchant"},
            {label = "Warrior", value = "warrior"},
            {label = "Mage", value = "mage"},
            {label = "Rogue", value = "rogue"}
        },
        default = character.occupation
    })
    
    form:AddField("background_story", "Background Story", "textarea", {
        required = true,
        minLength = 100,
        maxLength = 1000,
        default = character.background_story
    })
    
    -- Attributes tab
    local attributesTab = vgui.Create("DPanel")
    tabs:AddSheet("Attributes", attributesTab)
    
    -- Create form
    local form = KYBER.UI.Form.CreateWithCancel(
        attributesTab,
        KYBER.UI.Form.Styles.Default,
        {w = 780, h = 500},
        function(values)
            -- Update attributes
            KYBER.SQL.Query(
                "UPDATE characters SET strength = ?, dexterity = ?, constitution = ?, intelligence = ?, wisdom = ?, charisma = ? WHERE id = ?",
                {
                    values.strength,
                    values.dexterity,
                    values.constitution,
                    values.intelligence,
                    values.wisdom,
                    values.charisma,
                    character.id
                },
                function()
                    panel:Close()
                    -- Refresh character selection
                    KYBER.UI.Character.RefreshSelection()
                end
            )
        end,
        function()
            panel:Close()
        end
    )
    form:SetPos(10, 10)
    
    -- Add fields
    form:AddField("strength", "Strength", "slider", {
        required = true,
        min = 1,
        max = 10,
        default = character.strength
    })
    
    form:AddField("dexterity", "Dexterity", "slider", {
        required = true,
        min = 1,
        max = 10,
        default = character.dexterity
    })
    
    form:AddField("constitution", "Constitution", "slider", {
        required = true,
        min = 1,
        max = 10,
        default = character.constitution
    })
    
    form:AddField("intelligence", "Intelligence", "slider", {
        required = true,
        min = 1,
        max = 10,
        default = character.intelligence
    })
    
    form:AddField("wisdom", "Wisdom", "slider", {
        required = true,
        min = 1,
        max = 10,
        default = character.wisdom
    })
    
    form:AddField("charisma", "Charisma", "slider", {
        required = true,
        min = 1,
        max = 10,
        default = character.charisma
    })
    
    return panel
end

-- Show delete dialog
function KYBER.UI.Character.ShowDeleteDialog(character)
    local panel = KYBER.UI.Panel.CreateModal(nil, "Delete Character", KYBER.UI.Panel.Styles.Default, {w = 400, h = 200})
    
    -- Add message
    local message = vgui.Create("DLabel", panel.content)
    message:SetPos(10, 10)
    message:SetSize(380, 20)
    message:SetText("Are you sure you want to delete this character?")
    message:SetTextColor(Color(255, 255, 255))
    
    -- Add buttons
    local confirmButton = KYBER.UI.Button.Create(
        panel.content,
        "Delete",
        KYBER.UI.Button.Styles.Danger,
        {w = 100, h = 30},
        function()
            -- Delete character
            KYBER.SQL.Query(
                "DELETE FROM characters WHERE id = ?",
                {character.id},
                function()
                    panel:Close()
                    -- Refresh character selection
                    KYBER.UI.Character.RefreshSelection()
                end
            )
        end
    )
    confirmButton:SetPos(100, 100)
    
    local cancelButton = KYBER.UI.Button.Create(
        panel.content,
        "Cancel",
        KYBER.UI.Button.Styles.Secondary,
        {w = 100, h = 30},
        function()
            panel:Close()
        end
    )
    cancelButton:SetPos(200, 100)
end

-- Refresh character selection
function KYBER.UI.Character.RefreshSelection()
    if not KYBER.UI.Character.selectionPanel then return end
    
    -- Clear list
    KYBER.UI.Character.selectionPanel.list:Clear()
    
    -- Load characters
    KYBER.SQL.Query(
        "SELECT * FROM characters WHERE steam_id = ?",
        {LocalPlayer():SteamID()},
        function(rows)
            if not rows then return end
            
            -- Add rows
            for _, row in ipairs(rows) do
                KYBER.UI.Character.selectionPanel.list:AddRow({
                    name = row.name,
                    species = row.species,
                    occupation = row.occupation,
                    level = row.level,
                    last_login = row.last_login
                })
            end
        end
    )
end

-- Show details
function KYBER.UI.Character.ShowDetails(data)
    if not data then
        KYBER.UI.Notification.Create("Please select an item.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Create details panel
    local panel = KYBER.UI.Panel.CreateModal(nil, data.name, KYBER.UI.Panel.Styles.Default, {w = 600, h = 400})
    
    -- Add details
    local details = vgui.Create("DLabel", panel.content)
    details:SetPos(10, 10)
    details:SetSize(580, 300)
    details:SetText([[
        Value: ]] .. data.value .. [[
        Base: ]] .. data.base .. [[
        Bonus: ]] .. data.bonus .. [[
        
        Description:
        ]] .. data.description .. [[
        
        Effects:
        ]] .. data.effects .. [[
        
        Requirements:
        ]] .. data.requirements .. [[
    ]])
    details:SetTextColor(Color(255, 255, 255))
    
    -- Add close button
    local closeButton = KYBER.UI.Button.Create(
        panel.content,
        "Close",
        KYBER.UI.Button.Styles.Secondary,
        {w = 100, h = 30},
        function()
            panel:Close()
        end
    )
    closeButton:SetPos(250, 350)
end

-- Increase attribute
function KYBER.UI.Character.IncreaseAttribute(attribute)
    if not attribute then
        KYBER.UI.Notification.Create("Please select an attribute.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Check if character has enough points
    KYBER.SQL.Query(
        "SELECT attribute_points FROM characters WHERE id = ?",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows or rows[1].attribute_points <= 0 then
                KYBER.UI.Notification.Create("You don't have enough attribute points.", KYBER.UI.Notification.Styles.Error)
                return
            end
            
            -- Increase attribute
            KYBER.SQL.Query(
                "UPDATE attributes SET value = value + 1, base = base + 1 WHERE character_id = ? AND name = ?",
                {KYBER.Character.selected.id, attribute.name},
                function()
                    -- Decrease attribute points
                    KYBER.SQL.Query(
                        "UPDATE characters SET attribute_points = attribute_points - 1 WHERE id = ?",
                        {KYBER.Character.selected.id},
                        function()
                            -- Show success message
                            KYBER.UI.Notification.Create("Attribute increased successfully.", KYBER.UI.Notification.Styles.Success)
                            
                            -- Refresh character
                            KYBER.UI.Character.Create(nil)
                        end
                    )
                end
            )
        end
    )
end

-- Upgrade perk
function KYBER.UI.Character.UpgradePerk(perk)
    if not perk then
        KYBER.UI.Notification.Create("Please select a perk.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Check if character has enough points
    KYBER.SQL.Query(
        "SELECT perk_points FROM characters WHERE id = ?",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows or rows[1].perk_points <= 0 then
                KYBER.UI.Notification.Create("You don't have enough perk points.", KYBER.UI.Notification.Styles.Error)
                return
            end
            
            -- Upgrade perk
            KYBER.SQL.Query(
                "UPDATE perks SET level = level + 1 WHERE character_id = ? AND name = ?",
                {KYBER.Character.selected.id, perk.name},
                function()
                    -- Decrease perk points
                    KYBER.SQL.Query(
                        "UPDATE characters SET perk_points = perk_points - 1 WHERE id = ?",
                        {KYBER.Character.selected.id},
                        function()
                            -- Show success message
                            KYBER.UI.Notification.Create("Perk upgraded successfully.", KYBER.UI.Notification.Styles.Success)
                            
                            -- Refresh character
                            KYBER.UI.Character.Create(nil)
                        end
                    )
                end
            )
        end
    )
end 