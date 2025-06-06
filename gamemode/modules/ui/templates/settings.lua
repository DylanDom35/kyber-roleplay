-- kyber/gamemode/modules/ui/templates/settings.lua
-- Settings UI template

local KYBER = KYBER or {}

-- Settings UI
KYBER.UI.Settings = KYBER.UI.Settings or {}

-- Create settings UI
function KYBER.UI.Settings.Create(parent)
    local panel = KYBER.UI.Panel.CreateModal(parent, "Settings", KYBER.UI.Panel.Styles.Default, {w = 800, h = 600})
    
    -- Create tabs
    local tabs = vgui.Create("DPropertySheet", panel.content)
    tabs:SetSize(panel.content:GetWide(), panel.content:GetTall())
    tabs:SetPos(0, 0)
    
    -- General tab
    local generalTab = vgui.Create("DPanel")
    tabs:AddSheet("General", generalTab)
    
    -- Create settings
    local settings = {
        {
            name = "Show FPS",
            type = "checkbox",
            value = KYBER.Settings.Get("show_fps", false),
            callback = function(value)
                KYBER.Settings.Set("show_fps", value)
            end
        },
        {
            name = "Show Ping",
            type = "checkbox",
            value = KYBER.Settings.Get("show_ping", false),
            callback = function(value)
                KYBER.Settings.Set("show_ping", value)
            end
        },
        {
            name = "Show Time",
            type = "checkbox",
            value = KYBER.Settings.Get("show_time", false),
            callback = function(value)
                KYBER.Settings.Set("show_time", value)
            end
        },
        {
            name = "Show Date",
            type = "checkbox",
            value = KYBER.Settings.Get("show_date", false),
            callback = function(value)
                KYBER.Settings.Set("show_date", value)
            end
        }
    }
    
    -- Add settings
    local y = 10
    for _, setting in ipairs(settings) do
        if setting.type == "checkbox" then
            local checkbox = vgui.Create("DCheckBoxLabel", generalTab)
            checkbox:SetPos(10, y)
            checkbox:SetSize(780, 20)
            checkbox:SetText(setting.name)
            checkbox:SetValue(setting.value)
            checkbox.OnChange = function(_, value)
                setting.callback(value)
            end
        end
        y = y + 30
    end
    
    -- Audio tab
    local audioTab = vgui.Create("DPanel")
    tabs:AddSheet("Audio", audioTab)
    
    -- Create settings
    local settings = {
        {
            name = "Master Volume",
            type = "slider",
            value = KYBER.Settings.Get("master_volume", 1),
            callback = function(value)
                KYBER.Settings.Set("master_volume", value)
            end
        },
        {
            name = "Music Volume",
            type = "slider",
            value = KYBER.Settings.Get("music_volume", 1),
            callback = function(value)
                KYBER.Settings.Set("music_volume", value)
            end
        },
        {
            name = "SFX Volume",
            type = "slider",
            value = KYBER.Settings.Get("sfx_volume", 1),
            callback = function(value)
                KYBER.Settings.Set("sfx_volume", value)
            end
        },
        {
            name = "Voice Volume",
            type = "slider",
            value = KYBER.Settings.Get("voice_volume", 1),
            callback = function(value)
                KYBER.Settings.Set("voice_volume", value)
            end
        }
    }
    
    -- Add settings
    local y = 10
    for _, setting in ipairs(settings) do
        if setting.type == "slider" then
            local slider = vgui.Create("DNumSlider", audioTab)
            slider:SetPos(10, y)
            slider:SetSize(780, 20)
            slider:SetText(setting.name)
            slider:SetMin(0)
            slider:SetMax(1)
            slider:SetValue(setting.value)
            slider:SetDecimals(2)
            slider.OnValueChanged = function(_, value)
                setting.callback(value)
            end
        end
        y = y + 30
    end
    
    -- Video tab
    local videoTab = vgui.Create("DPanel")
    tabs:AddSheet("Video", videoTab)
    
    -- Create settings
    local settings = {
        {
            name = "Resolution",
            type = "combobox",
            value = KYBER.Settings.Get("resolution", "1920x1080"),
            options = {
                "1920x1080",
                "1600x900",
                "1366x768",
                "1280x720"
            },
            callback = function(value)
                KYBER.Settings.Set("resolution", value)
            end
        },
        {
            name = "Fullscreen",
            type = "checkbox",
            value = KYBER.Settings.Get("fullscreen", true),
            callback = function(value)
                KYBER.Settings.Set("fullscreen", value)
            end
        },
        {
            name = "VSync",
            type = "checkbox",
            value = KYBER.Settings.Get("vsync", true),
            callback = function(value)
                KYBER.Settings.Set("vsync", value)
            end
        },
        {
            name = "Anti-Aliasing",
            type = "combobox",
            value = KYBER.Settings.Get("anti_aliasing", "FXAA"),
            options = {
                "None",
                "FXAA",
                "MSAA 2x",
                "MSAA 4x",
                "MSAA 8x"
            },
            callback = function(value)
                KYBER.Settings.Set("anti_aliasing", value)
            end
        }
    }
    
    -- Add settings
    local y = 10
    for _, setting in ipairs(settings) do
        if setting.type == "combobox" then
            local combobox = vgui.Create("DComboBox", videoTab)
            combobox:SetPos(10, y)
            combobox:SetSize(780, 20)
            combobox:SetValue(setting.value)
            
            -- Add options
            for _, option in ipairs(setting.options) do
                combobox:AddChoice(option)
            end
            
            combobox.OnSelect = function(_, _, value)
                setting.callback(value)
            end
        elseif setting.type == "checkbox" then
            local checkbox = vgui.Create("DCheckBoxLabel", videoTab)
            checkbox:SetPos(10, y)
            checkbox:SetSize(780, 20)
            checkbox:SetText(setting.name)
            checkbox:SetValue(setting.value)
            checkbox.OnChange = function(_, value)
                setting.callback(value)
            end
        end
        y = y + 30
    end
    
    -- Controls tab
    local controlsTab = vgui.Create("DPanel")
    tabs:AddSheet("Controls", controlsTab)
    
    -- Create settings
    local settings = {
        {
            name = "Forward",
            type = "key",
            value = KYBER.Settings.Get("key_forward", "W"),
            callback = function(value)
                KYBER.Settings.Set("key_forward", value)
            end
        },
        {
            name = "Backward",
            type = "key",
            value = KYBER.Settings.Get("key_backward", "S"),
            callback = function(value)
                KYBER.Settings.Set("key_backward", value)
            end
        },
        {
            name = "Left",
            type = "key",
            value = KYBER.Settings.Get("key_left", "A"),
            callback = function(value)
                KYBER.Settings.Set("key_left", value)
            end
        },
        {
            name = "Right",
            type = "key",
            value = KYBER.Settings.Get("key_right", "D"),
            callback = function(value)
                KYBER.Settings.Set("key_right", value)
            end
        },
        {
            name = "Jump",
            type = "key",
            value = KYBER.Settings.Get("key_jump", "SPACE"),
            callback = function(value)
                KYBER.Settings.Set("key_jump", value)
            end
        },
        {
            name = "Sprint",
            type = "key",
            value = KYBER.Settings.Get("key_sprint", "SHIFT"),
            callback = function(value)
                KYBER.Settings.Set("key_sprint", value)
            end
        },
        {
            name = "Crouch",
            type = "key",
            value = KYBER.Settings.Get("key_crouch", "CTRL"),
            callback = function(value)
                KYBER.Settings.Set("key_crouch", value)
            end
        }
    }
    
    -- Add settings
    local y = 10
    for _, setting in ipairs(settings) do
        if setting.type == "key" then
            local label = vgui.Create("DLabel", controlsTab)
            label:SetPos(10, y)
            label:SetSize(200, 20)
            label:SetText(setting.name)
            label:SetTextColor(Color(255, 255, 255))
            
            local button = KYBER.UI.Button.Create(
                controlsTab,
                setting.value,
                KYBER.UI.Button.Styles.Secondary,
                {w = 100, h = 20},
                function()
                    -- Create key binding dialog
                    local panel = KYBER.UI.Panel.CreateModal(nil, "Key Binding", KYBER.UI.Panel.Styles.Default, {w = 400, h = 200})
                    
                    -- Add message
                    local message = vgui.Create("DLabel", panel.content)
                    message:SetPos(10, 10)
                    message:SetSize(380, 20)
                    message:SetText("Press a key to bind...")
                    message:SetTextColor(Color(255, 255, 255))
                    
                    -- Add key binding
                    panel.OnKeyCodePressed = function(_, key)
                        -- Get key name
                        local keyName = input.GetKeyName(key)
                        
                        -- Set key
                        setting.callback(keyName)
                        
                        -- Update button
                        button:SetText(keyName)
                        
                        -- Close dialog
                        panel:Close()
                    end
                end
            )
            button:SetPos(220, y)
        end
        y = y + 30
    end
    
    return panel
end 