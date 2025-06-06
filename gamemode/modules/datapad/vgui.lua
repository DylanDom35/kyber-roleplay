-- kyber/gamemode/modules/datapad/vgui.lua
-- Custom Star Wars themed VGUI elements

local KYBER = KYBER or {}

-- Colors
KYBER.Colors = {
    Primary = Color(0, 150, 255),      -- Blue
    Secondary = Color(255, 150, 0),    -- Orange
    Background = Color(20, 20, 30),    -- Dark blue/black
    Text = Color(200, 200, 255),       -- Light blue
    Accent = Color(255, 50, 50),       -- Red
    Success = Color(50, 255, 50),      -- Green
    Warning = Color(255, 255, 50),     -- Yellow
    Error = Color(255, 50, 50),        -- Red
    Border = Color(100, 150, 255, 50), -- Semi-transparent blue
    Hover = Color(50, 100, 255),       -- Hover state
    Pressed = Color(0, 100, 200),      -- Pressed state
    Disabled = Color(100, 100, 100)    -- Disabled state
}

-- Animation utilities
KYBER.Animations = {
    Lerp = function(start, target, fraction)
        return start + (target - start) * fraction
    end,
    
    EaseInOut = function(x)
        return x < 0.5 and 2 * x * x or 1 - math.pow(-2 * x + 2, 2) / 2
    end
}

-- Custom Star Wars themed frame
function KYBER.CreateSWFrame(parent, title, w, h)
    local frame = vgui.Create("DFrame", parent)
    frame:SetSize(w or 800, h or 600)
    frame:Center()
    frame:SetTitle(title or "KYBER Terminal")
    frame:MakePopup()
    
    -- Animation variables
    frame.animAlpha = 0
    frame.animScale = 0.95
    
    -- Custom paint function
    function frame:Paint(w, h)
        -- Animate entrance
        self.animAlpha = KYBER.Animations.Lerp(self.animAlpha, 1, FrameTime() * 5)
        self.animScale = KYBER.Animations.Lerp(self.animScale, 1, FrameTime() * 5)
        
        -- Background with animation
        draw.RoundedBox(8, 0, 0, w, h, Color(KYBER.Colors.Background.r, KYBER.Colors.Background.g, KYBER.Colors.Background.b, 255 * self.animAlpha))
        
        -- Border with animation
        draw.RoundedBox(8, 0, 0, w, h, Color(KYBER.Colors.Border.r, KYBER.Colors.Border.g, KYBER.Colors.Border.b, 50 * self.animAlpha))
        
        -- Title bar with animation
        draw.RoundedBox(8, 0, 0, w, 30, Color(KYBER.Colors.Primary.r, KYBER.Colors.Primary.g, KYBER.Colors.Primary.b, 255 * self.animAlpha))
        
        -- Title text with animation
        draw.SimpleText(title or "KYBER Terminal", "DermaDefaultBold", 10, 15, 
            Color(KYBER.Colors.Text.r, KYBER.Colors.Text.g, KYBER.Colors.Text.b, 255 * self.animAlpha),
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        -- Decorative elements with animation
        local time = CurTime()
        for i = 1, 5 do
            local x = math.sin(time + i) * 10 + w - 30
            local y = 15
            draw.SimpleText("●", "DermaDefault", x, y, 
                Color(KYBER.Colors.Secondary.r, KYBER.Colors.Secondary.g, KYBER.Colors.Secondary.b, 255 * self.animAlpha),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    
    -- Add scanlines effect
    function frame:PaintOver(w, h)
        local scanlineHeight = 2
        local scanlineSpacing = 4
        local scanlineAlpha = 20 * self.animAlpha
        
        for y = 0, h, scanlineSpacing do
            draw.RoundedBox(0, 0, y, w, scanlineHeight, Color(0, 0, 0, scanlineAlpha))
        end
    end
    
    return frame
end

-- Custom Star Wars themed button
function KYBER.CreateSWButton(parent, text, x, y, w, h)
    local button = vgui.Create("DButton", parent)
    button:SetPos(x, y)
    button:SetSize(w or 100, h or 30)
    button:SetText(text)
    
    -- Animation variables
    button.animHover = 0
    button.animPress = 0
    
    -- Custom paint function
    function button:Paint(w, h)
        -- Animate hover and press states
        self.animHover = KYBER.Animations.Lerp(self.animHover, self:IsHovered() and 1 or 0, FrameTime() * 10)
        self.animPress = KYBER.Animations.Lerp(self.animPress, self:IsDown() and 1 or 0, FrameTime() * 10)
        
        -- Calculate colors with animations
        local bgColor = Color(
            KYBER.Animations.Lerp(KYBER.Colors.Background.r, KYBER.Colors.Hover.r, self.animHover),
            KYBER.Animations.Lerp(KYBER.Colors.Background.g, KYBER.Colors.Hover.g, self.animHover),
            KYBER.Animations.Lerp(KYBER.Colors.Background.b, KYBER.Colors.Hover.b, self.animHover),
            255
        )
        
        local borderColor = Color(
            KYBER.Animations.Lerp(KYBER.Colors.Border.r, KYBER.Colors.Pressed.r, self.animPress),
            KYBER.Animations.Lerp(KYBER.Colors.Border.g, KYBER.Colors.Pressed.g, self.animPress),
            KYBER.Animations.Lerp(KYBER.Colors.Border.b, KYBER.Colors.Pressed.b, self.animPress),
            50
        )
        
        -- Background
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        
        -- Border
        draw.RoundedBox(4, 0, 0, w, h, borderColor)
        
        -- Text
        local textColor = self:IsDown() and KYBER.Colors.Background or KYBER.Colors.Text
        draw.SimpleText(text, "DermaDefaultBold", w/2, h/2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Hover effect
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 10 * self.animHover))
        end
    end
    
    -- Add hover sound
    function button:OnCursorEntered()
        surface.PlaySound("ui/buttonrollover.wav")
    end
    
    -- Add click sound
    function button:DoClick()
        surface.PlaySound("ui/buttonclick.wav")
    end
    
    return button
end

-- Custom Star Wars themed panel
function KYBER.CreateSWPanel(parent, x, y, w, h)
    local panel = vgui.Create("DPanel", parent)
    panel:SetPos(x, y)
    panel:SetSize(w, h)
    
    -- Animation variables
    panel.animAlpha = 0
    
    -- Custom paint function
    function panel:Paint(w, h)
        -- Animate entrance
        self.animAlpha = KYBER.Animations.Lerp(self.animAlpha, 1, FrameTime() * 5)
        
        -- Background
        draw.RoundedBox(4, 0, 0, w, h, Color(KYBER.Colors.Background.r, KYBER.Colors.Background.g, KYBER.Colors.Background.b, 255 * self.animAlpha))
        
        -- Border
        draw.RoundedBox(4, 0, 0, w, h, Color(KYBER.Colors.Border.r, KYBER.Colors.Border.g, KYBER.Colors.Border.b, 50 * self.animAlpha))
        
        -- Decorative corner elements
        local cornerSize = 10
        local corners = {
            {0, 0, 1, 1},
            {w - cornerSize, 0, -1, 1},
            {0, h - cornerSize, 1, -1},
            {w - cornerSize, h - cornerSize, -1, -1}
        }
        
        for _, corner in ipairs(corners) do
            local x, y, dirX, dirY = corner[1], corner[2], corner[3], corner[4]
            draw.SimpleText("┌", "DermaDefault", x, y, 
                Color(KYBER.Colors.Primary.r, KYBER.Colors.Primary.g, KYBER.Colors.Primary.b, 255 * self.animAlpha),
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end
    
    return panel
end

-- Custom Star Wars themed label
function KYBER.CreateSWLabel(parent, text, x, y, w, h)
    local label = vgui.Create("DLabel", parent)
    label:SetPos(x, y)
    label:SetSize(w or 100, h or 20)
    label:SetText(text)
    label:SetTextColor(KYBER.Colors.Text)
    label:SetFont("DermaDefaultBold")
    
    -- Animation variables
    label.animAlpha = 0
    
    -- Custom paint function
    function label:Paint(w, h)
        -- Animate entrance
        self.animAlpha = KYBER.Animations.Lerp(self.animAlpha, 1, FrameTime() * 5)
        
        -- Draw text with animation
        draw.SimpleText(text, "DermaDefaultBold", 0, h/2,
            Color(KYBER.Colors.Text.r, KYBER.Colors.Text.g, KYBER.Colors.Text.b, 255 * self.animAlpha),
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    return label
end

-- Custom Star Wars themed text entry
function KYBER.CreateSWTextEntry(parent, x, y, w, h)
    local textEntry = vgui.Create("DTextEntry", parent)
    textEntry:SetPos(x, y)
    textEntry:SetSize(w or 200, h or 30)
    
    -- Animation variables
    textEntry.animFocus = 0
    
    -- Custom paint function
    function textEntry:Paint(w, h)
        -- Animate focus state
        self.animFocus = KYBER.Animations.Lerp(self.animFocus, self:IsEditing() and 1 or 0, FrameTime() * 10)
        
        -- Background
        draw.RoundedBox(4, 0, 0, w, h, KYBER.Colors.Background)
        
        -- Border with focus animation
        local borderColor = Color(
            KYBER.Animations.Lerp(KYBER.Colors.Border.r, KYBER.Colors.Primary.r, self.animFocus),
            KYBER.Animations.Lerp(KYBER.Colors.Border.g, KYBER.Colors.Primary.g, self.animFocus),
            KYBER.Animations.Lerp(KYBER.Colors.Border.b, KYBER.Colors.Primary.b, self.animFocus),
            50
        )
        draw.RoundedBox(4, 0, 0, w, h, borderColor)
        
        -- Text
        self:DrawTextEntryText(KYBER.Colors.Text, KYBER.Colors.Primary, KYBER.Colors.Text)
    end
    
    -- Add focus sound
    function textEntry:OnGetFocus()
        surface.PlaySound("ui/buttonrollover.wav")
    end
    
    return textEntry
end

-- Custom Star Wars themed property sheet
function KYBER.CreateSWPropertySheet(parent)
    local sheet = vgui.Create("DPropertySheet", parent)
    
    -- Animation variables
    sheet.animAlpha = 0
    
    -- Custom paint function
    function sheet:Paint(w, h)
        -- Animate entrance
        self.animAlpha = KYBER.Animations.Lerp(self.animAlpha, 1, FrameTime() * 5)
        
        draw.RoundedBox(4, 0, 0, w, h, Color(KYBER.Colors.Background.r, KYBER.Colors.Background.g, KYBER.Colors.Background.b, 255 * self.animAlpha))
    end
    
    -- Override tab creation
    local oldAddSheet = sheet.AddSheet
    function sheet:AddSheet(label, panel, material, tooltip)
        local tab = oldAddSheet(self, label, panel, material, tooltip)
        
        -- Animation variables
        tab.Tab.animHover = 0
        
        -- Custom paint function for active tab
        function tab.Tab:Paint(w, h)
            -- Animate hover state
            self.animHover = KYBER.Animations.Lerp(self.animHover, self:IsHovered() and 1 or 0, FrameTime() * 10)
            
            -- Calculate colors with animations
            local bgColor = Color(
                KYBER.Animations.Lerp(KYBER.Colors.Background.r, KYBER.Colors.Hover.r, self.animHover),
                KYBER.Animations.Lerp(KYBER.Colors.Background.g, KYBER.Colors.Hover.g, self.animHover),
                KYBER.Animations.Lerp(KYBER.Colors.Background.b, KYBER.Colors.Hover.b, self.animHover),
                255
            )
            
            if self:IsActive() then
                draw.RoundedBox(4, 0, 0, w, h, KYBER.Colors.Primary)
            else
                draw.RoundedBox(4, 0, 0, w, h, bgColor)
            end
            
            -- Text
            draw.SimpleText(label, "DermaDefaultBold", w/2, h/2,
                self:IsActive() and KYBER.Colors.Background or KYBER.Colors.Text,
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- Add hover sound
        function tab.Tab:OnCursorEntered()
            surface.PlaySound("ui/buttonrollover.wav")
        end
        
        return tab
    end
    
    return sheet
end

-- Custom Star Wars themed scrollbar
function KYBER.CreateSWScrollBar(parent)
    local scrollbar = vgui.Create("DVScrollBar", parent)
    
    -- Custom paint function
    function scrollbar:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, KYBER.Colors.Background)
    end
    
    -- Custom paint function for grip
    function scrollbar.btnGrip:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, KYBER.Colors.Primary)
    end
    
    return scrollbar
end

-- Custom Star Wars themed list view
function KYBER.CreateSWListView(parent, x, y, w, h)
    local list = vgui.Create("DListView", parent)
    list:SetPos(x, y)
    list:SetSize(w, h)
    
    -- Custom paint function
    function list:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, KYBER.Colors.Background)
    end
    
    -- Custom paint function for header
    function list.Header:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, KYBER.Colors.Primary)
    end
    
    -- Custom paint function for lines
    function list:OnRowSelected(rowIndex, row)
        surface.PlaySound("ui/buttonclick.wav")
    end
    
    return list
end

-- Custom Star Wars themed checkbox
function KYBER.CreateSWCheckBox(parent, text, x, y)
    local checkbox = vgui.Create("DCheckBoxLabel", parent)
    checkbox:SetPos(x, y)
    checkbox:SetText(text)
    checkbox:SetTextColor(KYBER.Colors.Text)
    
    -- Custom paint function
    function checkbox:OnChange(val)
        surface.PlaySound("ui/buttonclick.wav")
    end
    
    return checkbox
end

-- Custom Star Wars themed slider
function KYBER.CreateSWSlider(parent, x, y, w, h)
    local slider = vgui.Create("DNumSlider", parent)
    slider:SetPos(x, y)
    slider:SetSize(w, h)
    slider:SetTextColor(KYBER.Colors.Text)
    
    -- Custom paint function
    function slider.Slider:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, KYBER.Colors.Background)
    end
    
    -- Custom paint function for grip
    function slider.Slider.Knob:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, KYBER.Colors.Primary)
    end
    
    return slider
end 