-- kyber/gamemode/modules/ui/templates/main_menu.lua
-- Main menu UI template

local KYBER = KYBER or {}

-- Main menu UI
KYBER.UI.MainMenu = KYBER.UI.MainMenu or {}

-- Create main menu UI
function KYBER.UI.MainMenu.Create(parent)
    local panel = KYBER.UI.Panel.CreateModal(parent, "Main Menu", KYBER.UI.Panel.Styles.Default, {w = 800, h = 600})
    
    -- Create background
    local background = vgui.Create("DImage", panel.content)
    background:SetPos(0, 0)
    background:SetSize(800, 600)
    background:SetImage("materials/kyber/main_menu_background.png")
    
    -- Create title
    local title = vgui.Create("DLabel", panel.content)
    title:SetPos(0, 50)
    title:SetSize(800, 100)
    title:SetText("KYBER")
    title:SetFont("KYBER_Title")
    title:SetTextColor(Color(255, 255, 255))
    title:SetContentAlignment(5)
    
    -- Create buttons
    local buttons = {
        {
            label = "Play",
            callback = function()
                KYBER.UI.MainMenu.ShowCharacterSelection()
            end
        },
        {
            label = "Settings",
            callback = function()
                KYBER.UI.Settings.Create(panel)
            end
        },
        {
            label = "Help",
            callback = function()
                KYBER.UI.Help.Create(panel)
            end
        },
        {
            label = "Credits",
            callback = function()
                KYBER.UI.MainMenu.ShowCredits()
            end
        },
        {
            label = "Quit",
            callback = function()
                KYBER.UI.MainMenu.ShowQuitConfirmation()
            end
        }
    }
    
    -- Add buttons
    local y = 200
    for _, button in ipairs(buttons) do
        local btn = KYBER.UI.Button.Create(
            panel.content,
            button.label,
            KYBER.UI.Button.Styles.Primary,
            {w = 200, h = 50},
            button.callback
        )
        btn:SetPos(300, y)
        y = y + 70
    end
    
    -- Add version
    local version = vgui.Create("DLabel", panel.content)
    version:SetPos(10, 570)
    version:SetSize(200, 20)
    version:SetText("Version 1.0.0")
    version:SetTextColor(Color(255, 255, 255))
    
    return panel
end

-- Show character selection
function KYBER.UI.MainMenu.ShowCharacterSelection()
    local panel = KYBER.UI.Panel.CreateModal(nil, "Character Selection", KYBER.UI.Panel.Styles.Default, {w = 800, h = 600})
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(panel.content, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("Name", 200, true)
    list:AddColumn("Level", 100, true)
    list:AddColumn("Class", 150, true)
    list:AddColumn("Last Login", 200, true)
    list:AddColumn("Location", 130, true)
    
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
                    level = row.level,
                    class = row.class,
                    last_login = row.last_login,
                    location = row.location
                })
            end
        end
    )
    
    -- Add buttons
    local createButton = KYBER.UI.Button.Create(
        panel.content,
        "Create Character",
        KYBER.UI.Button.Styles.Primary,
        {w = 150, h = 40},
        function()
            KYBER.UI.Character.Create(panel)
        end
    )
    createButton:SetPos(10, 520)
    
    local playButton = KYBER.UI.Button.Create(
        panel.content,
        "Play",
        KYBER.UI.Button.Styles.Primary,
        {w = 150, h = 40},
        function()
            KYBER.UI.MainMenu.PlayCharacter(list:GetSelected())
        end
    )
    playButton:SetPos(170, 520)
    
    local deleteButton = KYBER.UI.Button.Create(
        panel.content,
        "Delete",
        KYBER.UI.Button.Styles.Danger,
        {w = 150, h = 40},
        function()
            KYBER.UI.MainMenu.DeleteCharacter(list:GetSelected())
        end
    )
    deleteButton:SetPos(330, 520)
    
    local backButton = KYBER.UI.Button.Create(
        panel.content,
        "Back",
        KYBER.UI.Button.Styles.Secondary,
        {w = 150, h = 40},
        function()
            panel:Close()
        end
    )
    backButton:SetPos(490, 520)
end

-- Play character
function KYBER.UI.MainMenu.PlayCharacter(character)
    if not character then
        KYBER.UI.Notification.Create("Please select a character.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Set selected character
    KYBER.Character.selected = character
    
    -- Update last login
    KYBER.SQL.Query(
        "UPDATE characters SET last_login = CURRENT_TIMESTAMP WHERE id = ?",
        {character.id}
    )
    
    -- Close character selection
    if KYBER.UI.MainMenu.characterSelectionPanel then
        KYBER.UI.MainMenu.characterSelectionPanel:Close()
    end
    
    -- Close main menu
    if KYBER.UI.MainMenu.panel then
        KYBER.UI.MainMenu.panel:Close()
    end
    
    -- Start game
    KYBER.Game.Start()
end

-- Delete character
function KYBER.UI.MainMenu.DeleteCharacter(character)
    if not character then
        KYBER.UI.Notification.Create("Please select a character.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Create confirmation dialog
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
                    -- Show success message
                    KYBER.UI.Notification.Create("Character deleted successfully.", KYBER.UI.Notification.Styles.Success)
                    
                    -- Close dialog
                    panel:Close()
                    
                    -- Refresh character selection
                    KYBER.UI.MainMenu.ShowCharacterSelection()
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

-- Show credits
function KYBER.UI.MainMenu.ShowCredits()
    local panel = KYBER.UI.Panel.CreateModal(nil, "Credits", KYBER.UI.Panel.Styles.Default, {w = 600, h = 400})
    
    -- Add credits
    local credits = vgui.Create("DLabel", panel.content)
    credits:SetPos(10, 10)
    credits:SetSize(580, 300)
    credits:SetText([[
        KYBER Roleplay
        
        Development Team:
        - Lead Developer: [Name]
        - Game Design: [Name]
        - Art Direction: [Name]
        - Sound Design: [Name]
        
        Special Thanks:
        - [Name] for their contributions
        - [Name] for their support
        - The community for their feedback
        
        © 2024 KYBER Roleplay. All rights reserved.
    ]])
    credits:SetTextColor(Color(255, 255, 255))
    
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

-- Show quit confirmation
function KYBER.UI.MainMenu.ShowQuitConfirmation()
    local panel = KYBER.UI.Panel.CreateModal(nil, "Quit Game", KYBER.UI.Panel.Styles.Default, {w = 400, h = 200})
    
    -- Add message
    local message = vgui.Create("DLabel", panel.content)
    message:SetPos(10, 10)
    message:SetSize(380, 20)
    message:SetText("Are you sure you want to quit the game?")
    message:SetTextColor(Color(255, 255, 255))
    
    -- Add buttons
    local confirmButton = KYBER.UI.Button.Create(
        panel.content,
        "Quit",
        KYBER.UI.Button.Styles.Danger,
        {w = 100, h = 30},
        function()
            -- Quit game
            RunConsoleCommand("quit")
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