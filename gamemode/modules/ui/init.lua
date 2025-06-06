-- kyber/gamemode/modules/ui/init.lua
-- UI component system initialization

-- UI module initialization
KYBER.UI = KYBER.UI or {
    ActivePanels = {},
    timers = {},
    hooks = {}
}

-- UI module configuration
KYBER.UI.Config = {
    UpdateInterval = 1/30, -- 30 FPS
    DefaultFont = "DermaDefault",
    DefaultColor = Color(255, 255, 255),
    DefaultBackground = Color(0, 0, 0, 200),
    DefaultBorder = Color(100, 100, 100),
    DefaultPadding = 5,
    DefaultSpacing = 5
}

-- Panel styles
KYBER.UI.Panel = KYBER.UI.Panel or {}
KYBER.UI.Panel.Styles = {
    Default = {
        font = "DermaDefault",
        color = Color(255, 255, 255),
        background = Color(0, 0, 0, 200),
        border = Color(100, 100, 100),
        padding = 5,
        spacing = 5
    },
    Dark = {
        font = "DermaDefault",
        color = Color(200, 200, 200),
        background = Color(30, 30, 30, 230),
        border = Color(60, 60, 60),
        padding = 5,
        spacing = 5
    },
    Light = {
        font = "DermaDefault",
        color = Color(50, 50, 50),
        background = Color(240, 240, 240, 230),
        border = Color(180, 180, 180),
        padding = 5,
        spacing = 5
    }
}

-- Panel metatable
local Panel = {}
Panel.__index = Panel

function Panel:Cleanup()
    -- Remove all timers
    for _, timerName in ipairs(self.timers or {}) do
        timer.Remove(timerName)
    end
    
    -- Remove all hooks
    for _, hookName in ipairs(self.hooks or {}) do
        hook.Remove(hookName)
    end
    
    -- Remove all children
    for _, child in pairs(self:GetChildren()) do
        if IsValid(child) then
            child:Remove()
        end
    end
    
    -- Remove panel
    self:Remove()
end

function Panel:Update()
    -- Override this in derived panels
end

-- Set the metatable for all panels
function KYBER.UI:SetupPanel(panel)
    setmetatable(panel, Panel)
    panel.timers = {}
    panel.hooks = {}
    return panel
end

-- Create a new panel
function KYBER.UI:CreatePanel(name, parent)
    local panel = vgui.Create("DPanel", parent)
    panel:SetName(name)
    self:SetupPanel(panel)
    
    -- Add to active panels
    self.ActivePanels[name] = panel
    
    return panel
end

-- Create a modal panel
function KYBER.UI.Panel.CreateModal(parent, title, style, size)
    local frame = vgui.Create("DFrame", parent)
    frame:SetTitle(title or "")
    frame:SetSize(size.w or 400, size.h or 300)
    frame:Center()
    frame:MakePopup()
    
    -- Apply style
    style = style or KYBER.UI.Panel.Styles.Default
    frame:SetBackgroundColor(style.background)
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    
    -- Setup panel
    KYBER.UI:SetupPanel(frame)
    
    return frame
end

-- Update UI elements
function KYBER.UI:Update()
    local currentTime = CurTime()
    if currentTime - (self.lastUpdate or 0) < self.Config.UpdateInterval then
        return
    end
    
    self.lastUpdate = currentTime
    
    -- Update UI elements
    for name, panel in pairs(self.ActivePanels) do
        if IsValid(panel) then
            panel:Update()
        else
            self.ActivePanels[name] = nil
        end
    end
end

-- Cleanup all UI elements
function KYBER.UI:Cleanup()
    KYBER.Management.Hooks:Remove("KyberUICleanup")
    KYBER.Management.Hooks:Remove("KyberUIUpdate")
    
    -- Clean up all active panels
    for _, panel in pairs(self.ActivePanels) do
        if IsValid(panel) then
            panel:Remove()
        end
    end
    self.ActivePanels = {}
    
    -- Clean up all timers
    for name in pairs(self.timers) do
        KYBER.Management.Timers:Remove(name)
    end
    self.timers = {}
end

-- Initialize UI module
function KYBER.UI:Initialize()
    -- Add cleanup hook
    KYBER.Management.Hooks:Add("ShutDown", "KyberUICleanup", function()
        local success, err = pcall(function()
            self:Cleanup()
        end)
        
        if not success then
            KYBER.Management.ErrorHandler:Handle(err, "Failed to cleanup UI module")
        end
    end)
    
    -- Add update hook
    KYBER.Management.Hooks:Add("Think", "KyberUIUpdate", function()
        local success, err = pcall(function()
            self:Update()
        end)
        
        if not success then
            KYBER.Management.ErrorHandler:Handle(err, "Failed to update UI")
        end
    end)
    
    print("[Kyber] UI module initialized")
    return true
end

-- Initialize the module
KYBER.UI:Initialize()

return {
    name = "ui",
    version = "1.0.0",
    author = "Kyber Development Team",
    description = "UI component system",
    dependencies = {"core"},
    loadOrder = 2,
    
    Init = function(self)
        local success, err = pcall(function()
            -- Load UI components
            local files = file.Find("kyber/gamemode/modules/ui/components/*.lua", "LUA")
            for _, file in ipairs(files) do
                include("kyber/gamemode/modules/ui/components/" .. file)
            end
            
            -- Load UI templates
            local files = file.Find("kyber/gamemode/modules/ui/templates/*.lua", "LUA")
            for _, file in ipairs(files) do
                include("kyber/gamemode/modules/ui/templates/" .. file)
            end
        end)
        
        if not success then
            KYBER.Management.ErrorHandler:Handle(err, "Failed to initialize UI module")
            return false
        end
        
        return true
    end
} 