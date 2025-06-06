-- kyber/gamemode/modules/ui/components/list.lua
-- List component implementation

local KYBER = KYBER or {}

-- List component
KYBER.UI.List = KYBER.UI.List or {}

-- List styles
KYBER.UI.List.Styles = {
    Default = {
        bg = Color(40, 40, 40, 240),
        border = Color(60, 60, 60),
        header = {
            bg = Color(30, 30, 30),
            text = Color(255, 255, 255),
            font = "DermaDefault"
        },
        row = {
            bg = Color(50, 50, 50),
            hover = Color(60, 60, 60),
            selected = Color(70, 70, 70),
            text = Color(255, 255, 255),
            font = "DermaDefault"
        }
    },
    Dark = {
        bg = Color(20, 20, 20, 240),
        border = Color(40, 40, 40),
        header = {
            bg = Color(10, 10, 10),
            text = Color(255, 255, 255),
            font = "DermaDefault"
        },
        row = {
            bg = Color(30, 30, 30),
            hover = Color(40, 40, 40),
            selected = Color(50, 50, 50),
            text = Color(255, 255, 255),
            font = "DermaDefault"
        }
    },
    Light = {
        bg = Color(240, 240, 240, 240),
        border = Color(200, 200, 200),
        header = {
            bg = Color(220, 220, 220),
            text = Color(0, 0, 0),
            font = "DermaDefault"
        },
        row = {
            bg = Color(250, 250, 250),
            hover = Color(240, 240, 240),
            selected = Color(230, 230, 230),
            text = Color(0, 0, 0),
            font = "DermaDefault"
        }
    }
}

-- Create a list
function KYBER.UI.List.Create(parent, style, size)
    local list = vgui.Create("DPanel", parent)
    list:SetSize(size.w, size.h)
    
    -- Set style
    list.style = style or KYBER.UI.List.Styles.Default
    
    -- List data
    list.columns = {}
    list.rows = {}
    list.selectedRow = nil
    list.sortColumn = nil
    list.sortDirection = "asc"
    list.filter = ""
    
    -- Paint function
    function list:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, self.style.bg)
        draw.RoundedBox(4, 0, 0, w, h, self.style.border)
    end
    
    -- Add column
    function list:AddColumn(name, width, sortable)
        local column = {
            name = name,
            width = width,
            sortable = sortable or false
        }
        
        table.insert(self.columns, column)
        
        -- Update header
        self:UpdateHeader()
        
        return column
    end
    
    -- Update header
    function list:UpdateHeader()
        -- Remove old header
        if self.header then
            self.header:Remove()
        end
        
        -- Create header
        self.header = vgui.Create("DPanel", self)
        self.header:SetSize(self:GetWide(), 30)
        self.header:SetPos(0, 0)
        
        function self.header:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, self:GetParent().style.header.bg)
        end
        
        -- Add column headers
        local x = 0
        for i, column in ipairs(self.columns) do
            local header = vgui.Create("DButton", self.header)
            header:SetSize(column.width, 30)
            header:SetPos(x, 0)
            header:SetText(column.name)
            header:SetTextColor(self.style.header.text)
            header:SetFont(self.style.header.font)
            
            function header:Paint(w, h)
                draw.RoundedBox(4, 0, 0, w, h, self:GetParent():GetParent().style.header.bg)
                
                -- Draw sort indicator
                if self:GetParent():GetParent().sortColumn == column.name then
                    local text = self:GetParent():GetParent().sortDirection == "asc" and "▲" or "▼"
                    draw.SimpleText(
                        text,
                        self:GetParent():GetParent().style.header.font,
                        w - 20,
                        h/2,
                        self:GetParent():GetParent().style.header.text,
                        TEXT_ALIGN_CENTER,
                        TEXT_ALIGN_CENTER
                    )
                end
            end
            
            if column.sortable then
                function header:DoClick()
                    local list = self:GetParent():GetParent()
                    
                    if list.sortColumn == column.name then
                        list.sortDirection = list.sortDirection == "asc" and "desc" or "asc"
                    else
                        list.sortColumn = column.name
                        list.sortDirection = "asc"
                    end
                    
                    list:Sort()
                end
            end
            
            x = x + column.width
        end
    end
    
    -- Add row
    function list:AddRow(data)
        local row = {
            data = data,
            y = #self.rows * 30
        }
        
        table.insert(self.rows, row)
        
        -- Update rows
        self:UpdateRows()
        
        return row
    end
    
    -- Update rows
    function list:UpdateRows()
        -- Remove old rows
        if self.rowsPanel then
            self.rowsPanel:Remove()
        end
        
        -- Create rows panel
        self.rowsPanel = vgui.Create("DScrollPanel", self)
        self.rowsPanel:SetSize(self:GetWide(), self:GetTall() - 30)
        self.rowsPanel:SetPos(0, 30)
        
        -- Customize scrollbar
        local sbar = self.rowsPanel:GetVBar()
        sbar:SetWide(10)
        
        function sbar:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 0))
        end
        
        function sbar.btnUp:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60))
        end
        
        function sbar.btnDown:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60))
        end
        
        function sbar.btnGrip:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(80, 80, 80))
        end
        
        -- Add rows
        local y = 0
        for i, row in ipairs(self.rows) do
            local rowPanel = vgui.Create("DButton", self.rowsPanel)
            rowPanel:SetSize(self:GetWide(), 30)
            rowPanel:SetPos(0, y)
            rowPanel:SetText("")
            
            function rowPanel:Paint(w, h)
                local bg = self:GetParent():GetParent().style.row.bg
                
                if self:IsHovered() then
                    bg = self:GetParent():GetParent().style.row.hover
                end
                
                if self:GetParent():GetParent().selectedRow == row then
                    bg = self:GetParent():GetParent().style.row.selected
                end
                
                draw.RoundedBox(4, 0, 0, w, h, bg)
            end
            
            function rowPanel:DoClick()
                self:GetParent():GetParent().selectedRow = row
                self:GetParent():GetParent():UpdateRows()
                
                if self:GetParent():GetParent().onSelect then
                    self:GetParent():GetParent().onSelect(row)
                end
            end
            
            -- Add cells
            local x = 0
            for j, column in ipairs(self.columns) do
                local cell = vgui.Create("DLabel", rowPanel)
                cell:SetSize(column.width, 30)
                cell:SetPos(x, 0)
                cell:SetText(tostring(row.data[column.name] or ""))
                cell:SetTextColor(self.style.row.text)
                cell:SetFont(self.style.row.font)
                
                x = x + column.width
            end
            
            y = y + 30
        end
    end
    
    -- Sort rows
    function list:Sort()
        if not self.sortColumn then return end
        
        table.sort(self.rows, function(a, b)
            local aValue = a.data[self.sortColumn]
            local bValue = b.data[self.sortColumn]
            
            if type(aValue) == "string" then
                aValue = string.lower(aValue)
                bValue = string.lower(bValue)
            end
            
            if self.sortDirection == "asc" then
                return aValue < bValue
            else
                return aValue > bValue
            end
        end)
        
        self:UpdateRows()
    end
    
    -- Filter rows
    function list:SetFilter(filter)
        self.filter = string.lower(filter)
        self:UpdateRows()
    end
    
    -- Get selected row
    function list:GetSelectedRow()
        return self.selectedRow
    end
    
    -- Set selected row
    function list:SetSelectedRow(row)
        self.selectedRow = row
        self:UpdateRows()
    end
    
    -- Clear selection
    function list:ClearSelection()
        self.selectedRow = nil
        self:UpdateRows()
    end
    
    -- Get all rows
    function list:GetRows()
        return self.rows
    end
    
    -- Clear rows
    function list:Clear()
        self.rows = {}
        self.selectedRow = nil
        self:UpdateRows()
    end
    
    -- Set on select callback
    function list:SetOnSelect(callback)
        self.onSelect = callback
    end
    
    return list
end

-- Create a list with search
function KYBER.UI.List.CreateWithSearch(parent, style, size)
    local list = KYBER.UI.List.Create(parent, style, size)
    
    -- Add search box
    local search = vgui.Create("DTextEntry", list)
    search:SetSize(list:GetWide() - 20, 20)
    search:SetPos(10, list:GetTall() - 30)
    search:SetPlaceholderText("Search...")
    
    function search:OnChange()
        list:SetFilter(self:GetValue())
    end
    
    -- Adjust list size
    list:SetTall(list:GetTall() - 40)
    
    return list
end

-- Create a list with context menu
function KYBER.UI.List.CreateWithContextMenu(parent, style, size, menuItems)
    local list = KYBER.UI.List.Create(parent, style, size)
    
    -- Add context menu
    function list:OnMousePressed(mouseCode)
        if mouseCode == MOUSE_RIGHT then
            local menu = DermaMenu()
            
            for _, item in ipairs(menuItems) do
                menu:AddOption(item.label, function()
                    if item.callback and self.selectedRow then
                        item.callback(self.selectedRow)
                    end
                end)
            end
            
            menu:Open()
        end
    end
    
    return list
end 