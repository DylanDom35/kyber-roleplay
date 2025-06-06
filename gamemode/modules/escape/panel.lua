-- kyber/gamemode/modules/escape/panel.lua
-- Custom escape menu implementation

local KYBER = KYBER or {}

-- Create the main escape menu frame
function KYBER.CreateEscapePanel()
    local frame = KYBER.CreateSWFrame(nil, "KYBER Menu", 800, 600)
    frame:Center()
    frame:MakePopup()
    
    -- Create property sheet for tabs
    local sheet = KYBER.CreateSWPropertySheet(frame)
    sheet:Dock(FILL)
    
    -- Main tab
    local mainPanel = KYBER.CreateSWPanel(sheet)
    local mainTab = sheet:AddSheet("Main", mainPanel, "icon16/home.png")
    
    -- Main menu buttons
    local resumeButton = KYBER.CreateSWButton(mainPanel, "Resume Game", 10, 10, 200, 40)
    resumeButton.DoClick = function()
        frame:Close()
    end
    
    local settingsButton = KYBER.CreateSWButton(mainPanel, "Settings", 10, 60, 200, 40)
    settingsButton.DoClick = function()
        sheet:SetActiveTab(sheet:GetItems()[2].Tab)
    end
    
    local characterButton = KYBER.CreateSWButton(mainPanel, "Character", 10, 110, 200, 40)
    characterButton.DoClick = function()
        KYBER.OpenDatapad()
        frame:Close()
    end
    
    local disconnectButton = KYBER.CreateSWButton(mainPanel, "Disconnect", 10, 160, 200, 40)
    disconnectButton.DoClick = function()
        RunConsoleCommand("disconnect")
    end
    
    -- Settings tab
    local settingsPanel = KYBER.CreateSWPanel(sheet)
    local settingsTab = sheet:AddSheet("Settings", settingsPanel, "icon16/cog.png")
    
    -- Graphics settings
    local graphicsLabel = KYBER.CreateSWLabel(settingsPanel, "Graphics", 10, 10, 200, 20)
    
    local fullscreenCheckbox = KYBER.CreateSWCheckbox(settingsPanel, "Fullscreen", 10, 40, 200, 20)
    fullscreenCheckbox:SetChecked(GetConVar("fullscreen"):GetBool())
    fullscreenCheckbox.OnChange = function(self, val)
        RunConsoleCommand("fullscreen", val and "1" or "0")
    end
    
    local vsyncCheckbox = KYBER.CreateSWCheckbox(settingsPanel, "VSync", 10, 70, 200, 20)
    vsyncCheckbox:SetChecked(GetConVar("mat_vsync"):GetBool())
    vsyncCheckbox.OnChange = function(self, val)
        RunConsoleCommand("mat_vsync", val and "1" or "0")
    end
    
    -- Audio settings
    local audioLabel = KYBER.CreateSWLabel(settingsPanel, "Audio", 10, 110, 200, 20)
    
    local masterVolume = KYBER.CreateSWSlider(settingsPanel, 10, 140, 300, 30)
    masterVolume:SetText("Master Volume")
    masterVolume:SetMinMax(0, 100)
    masterVolume:SetValue(GetConVar("volume"):GetFloat() * 100)
    masterVolume.OnValueChanged = function(self, val)
        RunConsoleCommand("volume", val / 100)
    end
    
    local musicVolume = KYBER.CreateSWSlider(settingsPanel, 10, 180, 300, 30)
    musicVolume:SetText("Music Volume")
    musicVolume:SetMinMax(0, 100)
    musicVolume:SetValue(GetConVar("snd_musicvolume"):GetFloat() * 100)
    musicVolume.OnValueChanged = function(self, val)
        RunConsoleCommand("snd_musicvolume", val / 100)
    end
    
    -- Game settings
    local gameLabel = KYBER.CreateSWLabel(settingsPanel, "Game", 10, 230, 200, 20)
    
    local fovSlider = KYBER.CreateSWSlider(settingsPanel, 10, 260, 300, 30)
    fovSlider:SetText("Field of View")
    fovSlider:SetMinMax(75, 120)
    fovSlider:SetValue(GetConVar("fov_desired"):GetFloat())
    fovSlider.OnValueChanged = function(self, val)
        RunConsoleCommand("fov_desired", val)
    end
    
    local sensitivitySlider = KYBER.CreateSWSlider(settingsPanel, 10, 300, 300, 30)
    sensitivitySlider:SetText("Mouse Sensitivity")
    sensitivitySlider:SetMinMax(1, 20)
    sensitivitySlider:SetValue(GetConVar("sensitivity"):GetFloat())
    sensitivitySlider.OnValueChanged = function(self, val)
        RunConsoleCommand("sensitivity", val)
    end
    
    -- Keybinds tab
    local keybindsPanel = KYBER.CreateSWPanel(sheet)
    local keybindsTab = sheet:AddSheet("Keybinds", keybindsPanel, "icon16/keyboard.png")
    
    -- Keybinds list
    local keybindsList = KYBER.CreateSWListView(keybindsPanel, 10, 10, 760, 400)
    keybindsList:AddColumn("Action")
    keybindsList:AddColumn("Key")
    
    -- Add default keybinds
    local defaultBinds = {
        {"Move Forward", "W"},
        {"Move Backward", "S"},
        {"Move Left", "A"},
        {"Move Right", "D"},
        {"Jump", "SPACE"},
        {"Sprint", "SHIFT"},
        {"Crouch", "CTRL"},
        {"Use", "E"},
        {"Reload", "R"},
        {"Primary Attack", "MOUSE1"},
        {"Secondary Attack", "MOUSE2"},
        {"Datapad", "F1"},
        {"Inventory", "TAB"},
        {"Chat", "Y"},
        {"Team Chat", "U"}
    }
    
    for _, bind in ipairs(defaultBinds) do
        keybindsList:AddLine(bind[1], bind[2])
    end
    
    -- Credits tab
    local creditsPanel = KYBER.CreateSWPanel(sheet)
    local creditsTab = sheet:AddSheet("Credits", creditsPanel, "icon16/star.png")
    
    -- Credits content
    local creditsLabel = KYBER.CreateSWLabel(creditsPanel, "KYBER Roleplay", 10, 10, 760, 30)
    creditsLabel:SetFont("KYBER_FontLarge")
    creditsLabel:SetContentAlignment(5)
    
    local versionLabel = KYBER.CreateSWLabel(creditsPanel, "Version 1.0.0", 10, 50, 760, 20)
    versionLabel:SetFont("KYBER_FontMedium")
    versionLabel:SetContentAlignment(5)
    
    local teamLabel = KYBER.CreateSWLabel(creditsPanel, "Development Team", 10, 90, 760, 20)
    teamLabel:SetFont("KYBER_FontMedium")
    teamLabel:SetContentAlignment(5)
    
    local creditsList = KYBER.CreateSWListView(creditsPanel, 10, 120, 760, 200)
    creditsList:AddColumn("Role")
    creditsList:AddColumn("Name")
    
    local teamMembers = {
        {"Lead Developer", "Kyber Development Team"},
        {"UI Designer", "Kyber Development Team"},
        {"Content Creator", "Kyber Development Team"},
        {"Community Manager", "Kyber Development Team"}
    }
    
    for _, member in ipairs(teamMembers) do
        creditsList:AddLine(member[1], member[2])
    end
    
    -- Override default escape menu
    hook.Add("GUIMousePressed", "KYBER_EscapeMenu", function(mc)
        if mc == MOUSE_LEFT and gui.IsGameUIVisible() then
            if not IsValid(KYBER.EscapePanel) then
                KYBER.EscapePanel = KYBER.CreateEscapePanel()
            end
            return true
        end
    end)
    
    return frame
end

-- Open escape menu
function KYBER.OpenEscapeMenu()
    if not IsValid(KYBER.EscapePanel) then
        KYBER.EscapePanel = KYBER.CreateEscapePanel()
    end
end

-- Register command
concommand.Add("kyber_escape", function()
    KYBER.OpenEscapeMenu()
end) 