-- kyber/gamemode/modules/ui/components/button.lua
-- Button component implementation

local KYBER = KYBER or {}

-- Button component
KYBER.UI.Button = KYBER.UI.Button or {}

-- Button styles
KYBER.UI.Button.Styles = {
    Primary = {
        normal = {
            bg = Color(50, 100, 255),
            text = Color(255, 255, 255),
            border = Color(30, 80, 235)
        },
        hover = {
            bg = Color(70, 120, 255),
            text = Color(255, 255, 255),
            border = Color(50, 100, 255)
        },
        pressed = {
            bg = Color(30, 80, 235),
            text = Color(255, 255, 255),
            border = Color(20, 60, 215)
        },
        disabled = {
            bg = Color(100, 100, 100),
            text = Color(200, 200, 200),
            border = Color(80, 80, 80)
        }
    },
    Secondary = {
        normal = {
            bg = Color(100, 100, 100),
            text = Color(255, 255, 255),
            border = Color(80, 80, 80)
        },
        hover = {
            bg = Color(120, 120, 120),
            text = Color(255, 255, 255),
            border = Color(100, 100, 100)
        },
        pressed = {
            bg = Color(80, 80, 80),
            text = Color(255, 255, 255),
            border = Color(60, 60, 60)
        },
        disabled = {
            bg = Color(80, 80, 80),
            text = Color(150, 150, 150),
            border = Color(60, 60, 60)
        }
    },
    Danger = {
        normal = {
            bg = Color(255, 50, 50),
            text = Color(255, 255, 255),
            border = Color(235, 30, 30)
        },
        hover = {
            bg = Color(255, 70, 70),
            text = Color(255, 255, 255),
            border = Color(255, 50, 50)
        },
        pressed = {
            bg = Color(235, 30, 30),
            text = Color(255, 255, 255),
            border = Color(215, 20, 20)
        },
        disabled = {
            bg = Color(150, 50, 50),
            text = Color(200, 200, 200),
            border = Color(130, 30, 30)
        }
    }
}

-- Create a button
function KYBER.UI.Button.Create(parent, text, style, size, callback)
    local button = vgui.Create("DButton", parent)
    button:SetText(text)
    button:SetSize(size.w, size.h)
    
    -- Set style
    button.style = style or KYBER.UI.Button.Styles.Primary
    button.state = "normal"
    
    -- Set callback
    button.callback = callback
    
    -- Paint function
    function button:Paint(w, h)
        local style = self.style[self.state]
        
        -- Draw background
        draw.RoundedBox(4, 0, 0, w, h, style.bg)
        
        -- Draw border
        draw.RoundedBox(4, 0, 0, w, h, style.border)
        
        -- Draw text
        draw.SimpleText(
            self:GetText(),
            "DermaDefault",
            w/2,
            h/2,
            style.text,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end
    
    -- Mouse events
    function button:OnCursorEntered()
        if not self:IsEnabled() then return end
        self.state = "hover"
    end
    
    function button:OnCursorExited()
        if not self:IsEnabled() then return end
        self.state = "normal"
    end
    
    function button:OnMousePressed()
        if not self:IsEnabled() then return end
        self.state = "pressed"
    end
    
    function button:OnMouseReleased()
        if not self:IsEnabled() then return end
        self.state = "hover"
        
        if self.callback then
            self.callback(self)
        end
    end
    
    -- Set enabled state
    function button:SetEnabled(enabled)
        self:SetEnabled(enabled)
        self.state = enabled and "normal" or "disabled"
    end
    
    return button
end

-- Create a button with icon
function KYBER.UI.Button.CreateWithIcon(parent, text, icon, style, size, callback)
    local button = KYBER.UI.Button.Create(parent, text, style, size, callback)
    
    -- Add icon
    local iconSize = 16
    local icon = vgui.Create("DImage", button)
    icon:SetSize(iconSize, iconSize)
    icon:SetImage(icon)
    icon:SetPos(8, (size.h - iconSize) / 2)
    
    -- Adjust text position
    function button:Paint(w, h)
        local style = self.style[self.state]
        
        -- Draw background
        draw.RoundedBox(4, 0, 0, w, h, style.bg)
        
        -- Draw border
        draw.RoundedBox(4, 0, 0, w, h, style.border)
        
        -- Draw text
        draw.SimpleText(
            self:GetText(),
            "DermaDefault",
            w/2 + 8,
            h/2,
            style.text,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end
    
    return button
end

-- Create a button with tooltip
function KYBER.UI.Button.CreateWithTooltip(parent, text, tooltip, style, size, callback)
    local button = KYBER.UI.Button.Create(parent, text, style, size, callback)
    
    -- Add tooltip
    button:SetTooltip(tooltip)
    
    return button
end

-- Create a button with confirmation
function KYBER.UI.Button.CreateWithConfirmation(parent, text, confirmText, style, size, callback)
    local button = KYBER.UI.Button.Create(parent, text, style, size, function(self)
        -- Create confirmation dialog
        local dialog = vgui.Create("DFrame")
        dialog:SetSize(300, 150)
        dialog:Center()
        dialog:SetTitle("Confirm Action")
        dialog:MakePopup()
        
        -- Add message
        local message = vgui.Create("DLabel", dialog)
        message:SetPos(10, 30)
        message:SetSize(280, 20)
        message:SetText(confirmText)
        message:SetTextColor(Color(255, 255, 255))
        
        -- Add buttons
        local confirmButton = KYBER.UI.Button.Create(dialog, "Confirm", KYBER.UI.Button.Styles.Danger, {w = 100, h = 30}, function()
            if callback then
                callback(self)
            end
            dialog:Close()
        end)
        confirmButton:SetPos(50, 100)
        
        local cancelButton = KYBER.UI.Button.Create(dialog, "Cancel", KYBER.UI.Button.Styles.Secondary, {w = 100, h = 30}, function()
            dialog:Close()
        end)
        cancelButton:SetPos(150, 100)
    end)
    
    return button
end 