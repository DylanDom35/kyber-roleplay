-- kyber/gamemode/modules/escape/vgui.lua
-- Custom VGUI elements for the escape menu

local KYBER = KYBER or {}

-- Create a Star Wars themed frame
function KYBER.CreateSWFrame(parent, title, w, h)
    local frame = vgui.Create("DFrame", parent)
    frame:SetSize(w, h)
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:Center()
    
    -- Custom paint function
    function frame:Paint(w, h)
        -- Draw background with gradient
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 20, 230))
        
        -- Draw border
        draw.RoundedBox(8, 0, 0, w, h, Color(100, 100, 100, 50))
        
        -- Draw title bar
        draw.RoundedBox(8, 0, 0, w, 30, Color(40, 40, 40, 200))
        
        -- Draw title
        draw.SimpleText(title, "KYBER_FontMedium", 10, 15, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        -- Draw close button
        if self:IsHovered() then
            draw.RoundedBox(4, w - 30, 5, 20, 20, Color(200, 50, 50, 200))
        end
        draw.SimpleText("X", "KYBER_FontMedium", w - 20, 15, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Custom close button
    function frame:OnMousePressed(mc)
        if mc == MOUSE_LEFT then
            local x, y = self:CursorPos()
            if x > self:GetWide() - 30 and x < self:GetWide() - 10 and y > 5 and y < 25 then
                self:Close()
            end
        end
    end
    
    return frame
end

-- Create a Star Wars themed button
function KYBER.CreateSWButton(parent, text, x, y, w, h)
    local button = vgui.Create("DButton", parent)
    button:SetPos(x, y)
    button:SetSize(w, h)
    button:SetText("")
    
    -- Custom paint function
    function button:Paint(w, h)
        local col = self:IsHovered() and Color(100, 100, 100, 200) or Color(60, 60, 60, 200)
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.RoundedBox(4, 0, 0, w, h, Color(150, 150, 150, 50))
        
        -- Draw text with glow effect when hovered
        if self:IsHovered() then
            draw.SimpleText(text, "KYBER_FontMedium", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(text, "KYBER_FontMedium", w/2, h/2, Color(255, 255, 255, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText(text, "KYBER_FontMedium", w/2, h/2, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    
    return button
end

-- Create a Star Wars themed label
function KYBER.CreateSWLabel(parent, text, x, y, w, h)
    local label = vgui.Create("DLabel", parent)
    label:SetPos(x, y)
    label:SetSize(w, h)
    label:SetText(text)
    label:SetFont("KYBER_FontMedium")
    label:SetTextColor(Color(200, 200, 200))
    
    return label
end

-- Create a Star Wars themed checkbox
function KYBER.CreateSWCheckbox(parent, text, x, y, w, h)
    local checkbox = vgui.Create("DCheckBoxLabel", parent)
    checkbox:SetPos(x, y)
    checkbox:SetSize(w, h)
    checkbox:SetText(text)
    checkbox:SetFont("KYBER_FontMedium")
    checkbox:SetTextColor(Color(200, 200, 200))
    
    -- Custom paint function for the checkbox
    function checkbox:Button:Paint(w, h)
        local col = self:GetChecked() and Color(100, 100, 100, 200) or Color(60, 60, 60, 200)
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.RoundedBox(4, 0, 0, w, h, Color(150, 150, 150, 50))
        
        if self:GetChecked() then
            draw.SimpleText("✓", "KYBER_FontMedium", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    
    return checkbox
end

-- Create a Star Wars themed slider
function KYBER.CreateSWSlider(parent, x, y, w, h)
    local slider = vgui.Create("DNumSlider", parent)
    slider:SetPos(x, y)
    slider:SetSize(w, h)
    slider:SetText("")
    slider:SetFont("KYBER_FontMedium")
    slider:SetTextColor(Color(200, 200, 200))
    
    -- Custom paint function
    function slider:Paint(w, h)
        -- Draw background
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))
        
        -- Draw text
        draw.SimpleText(self:GetText(), "KYBER_FontMedium", 5, 5, Color(200, 200, 200))
    end
    
    -- Custom paint function for the slider
    function slider.Slider:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60, 200))
    end
    
    -- Custom paint function for the slider knob
    function slider.Slider.Knob:Paint(w, h)
        local col = self:IsHovered() and Color(100, 100, 100, 200) or Color(80, 80, 80, 200)
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.RoundedBox(4, 0, 0, w, h, Color(150, 150, 150, 50))
    end
    
    return slider
end

-- Create a Star Wars themed list view
function KYBER.CreateSWListView(parent, x, y, w, h)
    local list = vgui.Create("DListView", parent)
    list:SetPos(x, y)
    list:SetSize(w, h)
    list:SetMultiSelect(false)
    list:SetHeaderHeight(30)
    
    -- Custom paint function
    function list:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))
    end
    
    -- Custom paint function for headers
    function list.Header:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60, 200))
    end
    
    -- Custom paint function for header text
    function list.Header:Label:Paint(w, h)
        draw.SimpleText(self:GetText(), "KYBER_FontMedium", 5, h/2, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    -- Custom paint function for rows
    function list:OnRowSelected(rowIndex, row)
        self:ClearSelection()
        self:SelectItem(row)
    end
    
    function list:OnRowRightClick(rowIndex, row)
        -- Add custom right-click menu if needed
    end
    
    return list
end

-- Create a Star Wars themed property sheet
function KYBER.CreateSWPropertySheet(parent)
    local sheet = vgui.Create("DPropertySheet", parent)
    
    -- Custom paint function
    function sheet:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))
    end
    
    -- Custom paint function for tabs
    function sheet.tabScroller:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60, 200))
    end
    
    -- Custom paint function for tab buttons
    function sheet:AddSheet(label, panel, material)
        if not IsValid(panel) then
            panel = vgui.Create("DPanel", self)
            panel.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))
            end
        end
        
        local sheet = {}
        sheet.Name = label
        sheet.Tab = vgui.Create("DButton", self)
        sheet.Tab:SetText("")
        sheet.Tab:SetSize(100, 30)
        
        -- Custom paint function for tab button
        function sheet.Tab:Paint(w, h)
            local col = self:IsActive() and Color(100, 100, 100, 200) or Color(60, 60, 60, 200)
            draw.RoundedBox(4, 0, 0, w, h, col)
            
            -- Draw icon if provided
            if material then
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(Material(material))
                surface.DrawTexturedRect(5, 5, 20, 20)
            end
            
            -- Draw label
            draw.SimpleText(label, "KYBER_FontMedium", material and 30 or 5, h/2, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        
        sheet.Panel = panel
        sheet.Panel:SetVisible(false)
        
        table.insert(self.Items, sheet)
        
        if not self:GetActiveTab() then
            self:SetActiveTab(sheet.Tab)
        end
        
        return sheet
    end
    
    return sheet
end 