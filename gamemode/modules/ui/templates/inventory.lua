-- kyber/gamemode/modules/ui/templates/inventory.lua
-- Inventory UI template

local KYBER = KYBER or {}

-- Inventory UI
KYBER.UI.Inventory = KYBER.UI.Inventory or {}

-- Create inventory UI
function KYBER.UI.Inventory.Create(parent)
    local panel = KYBER.UI.Panel.CreateModal(parent, "Inventory", KYBER.UI.Panel.Styles.Default, {w = 800, h = 600})
    
    -- Create tabs
    local tabs = vgui.Create("DPropertySheet", panel.content)
    tabs:SetSize(panel.content:GetWide(), panel.content:GetTall())
    tabs:SetPos(0, 0)
    
    -- Items tab
    local itemsTab = vgui.Create("DPanel")
    tabs:AddSheet("Items", itemsTab)
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(itemsTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("Name", 200, true)
    list:AddColumn("Type", 100, true)
    list:AddColumn("Quantity", 100, true)
    list:AddColumn("Weight", 100, true)
    list:AddColumn("Value", 100, true)
    list:AddColumn("Description", 180, true)
    
    -- Load items
    KYBER.SQL.Query(
        "SELECT * FROM inventory WHERE character_id = ?",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows then return end
            
            -- Add rows
            for _, row in ipairs(rows) do
                list:AddRow({
                    name = row.name,
                    type = row.type,
                    quantity = row.quantity,
                    weight = row.weight,
                    value = row.value,
                    description = row.description
                })
            end
        end
    )
    
    -- Add buttons
    local useButton = KYBER.UI.Button.Create(
        itemsTab,
        "Use",
        KYBER.UI.Button.Styles.Primary,
        {w = 100, h = 30},
        function()
            KYBER.UI.Inventory.UseItem(list:GetSelected())
        end
    )
    useButton:SetPos(10, 520)
    
    local dropButton = KYBER.UI.Button.Create(
        itemsTab,
        "Drop",
        KYBER.UI.Button.Styles.Danger,
        {w = 100, h = 30},
        function()
            KYBER.UI.Inventory.DropItem(list:GetSelected())
        end
    )
    dropButton:SetPos(120, 520)
    
    local equipButton = KYBER.UI.Button.Create(
        itemsTab,
        "Equip",
        KYBER.UI.Button.Styles.Primary,
        {w = 100, h = 30},
        function()
            KYBER.UI.Inventory.EquipItem(list:GetSelected())
        end
    )
    equipButton:SetPos(230, 520)
    
    -- Equipment tab
    local equipmentTab = vgui.Create("DPanel")
    tabs:AddSheet("Equipment", equipmentTab)
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(equipmentTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("Slot", 100, true)
    list:AddColumn("Name", 200, true)
    list:AddColumn("Type", 100, true)
    list:AddColumn("Weight", 100, true)
    list:AddColumn("Value", 100, true)
    list:AddColumn("Description", 180, true)
    
    -- Load equipment
    KYBER.SQL.Query(
        "SELECT * FROM equipment WHERE character_id = ?",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows then return end
            
            -- Add rows
            for _, row in ipairs(rows) do
                list:AddRow({
                    slot = row.slot,
                    name = row.name,
                    type = row.type,
                    weight = row.weight,
                    value = row.value,
                    description = row.description
                })
            end
        end
    )
    
    -- Add buttons
    local unequipButton = KYBER.UI.Button.Create(
        equipmentTab,
        "Unequip",
        KYBER.UI.Button.Styles.Primary,
        {w = 100, h = 30},
        function()
            KYBER.UI.Inventory.UnequipItem(list:GetSelected())
        end
    )
    unequipButton:SetPos(10, 520)
    
    -- Add context menu
    local menuItems = {
        {
            label = "View Details",
            callback = function(row)
                KYBER.UI.Inventory.ShowDetails(row.data)
            end
        }
    }
    
    -- Add context menu to all lists
    for _, tab in ipairs(tabs.Items) do
        if tab.Panel and tab.Panel:GetChildren()[1] then
            local list = tab.Panel:GetChildren()[1]
            list = KYBER.UI.List.CreateWithContextMenu(tab.Panel, KYBER.UI.List.Styles.Default, {w = 780, h = 500}, menuItems)
            list:SetPos(10, 10)
        end
    end
    
    return panel
end

-- Show item details
function KYBER.UI.Inventory.ShowDetails(item)
    if not item then
        KYBER.UI.Notification.Create("Please select an item.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Create details panel
    local panel = KYBER.UI.Panel.CreateModal(nil, item.name, KYBER.UI.Panel.Styles.Default, {w = 600, h = 400})
    
    -- Add details
    local details = vgui.Create("DLabel", panel.content)
    details:SetPos(10, 10)
    details:SetSize(580, 300)
    details:SetText([[
        Type: ]] .. item.type .. [[
        Quantity: ]] .. item.quantity .. [[
        Weight: ]] .. item.weight .. [[
        Value: ]] .. item.value .. [[
        
        Description:
        ]] .. item.description .. [[
        
        Effects:
        ]] .. item.effects .. [[
        
        Requirements:
        ]] .. item.requirements .. [[
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

-- Use item
function KYBER.UI.Inventory.UseItem(item)
    if not item then
        KYBER.UI.Notification.Create("Please select an item.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Use item
    KYBER.SQL.Query(
        "UPDATE inventory SET quantity = quantity - 1 WHERE character_id = ? AND name = ?",
        {KYBER.Character.selected.id, item.name},
        function()
            -- Show success message
            KYBER.UI.Notification.Create("Item used successfully.", KYBER.UI.Notification.Styles.Success)
            
            -- Refresh inventory
            KYBER.UI.Inventory.Create(nil)
        end
    )
end

-- Drop item
function KYBER.UI.Inventory.DropItem(item)
    if not item then
        KYBER.UI.Notification.Create("Please select an item.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Create confirmation dialog
    local panel = KYBER.UI.Panel.CreateModal(nil, "Drop Item", KYBER.UI.Panel.Styles.Default, {w = 400, h = 200})
    
    -- Add message
    local message = vgui.Create("DLabel", panel.content)
    message:SetPos(10, 10)
    message:SetSize(380, 20)
    message:SetText("Are you sure you want to drop this item?")
    message:SetTextColor(Color(255, 255, 255))
    
    -- Add buttons
    local confirmButton = KYBER.UI.Button.Create(
        panel.content,
        "Drop",
        KYBER.UI.Button.Styles.Danger,
        {w = 100, h = 30},
        function()
            -- Drop item
            KYBER.SQL.Query(
                "UPDATE inventory SET quantity = quantity - 1 WHERE character_id = ? AND name = ?",
                {KYBER.Character.selected.id, item.name},
                function()
                    -- Show success message
                    KYBER.UI.Notification.Create("Item dropped successfully.", KYBER.UI.Notification.Styles.Success)
                    
                    -- Close dialog
                    panel:Close()
                    
                    -- Refresh inventory
                    KYBER.UI.Inventory.Create(nil)
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

-- Equip item
function KYBER.UI.Inventory.EquipItem(item)
    if not item then
        KYBER.UI.Notification.Create("Please select an item.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Equip item
    KYBER.SQL.Query(
        "INSERT INTO equipment (character_id, slot, name, type, weight, value, description) VALUES (?, ?, ?, ?, ?, ?, ?)",
        {KYBER.Character.selected.id, item.slot, item.name, item.type, item.weight, item.value, item.description},
        function()
            -- Show success message
            KYBER.UI.Notification.Create("Item equipped successfully.", KYBER.UI.Notification.Styles.Success)
            
            -- Refresh inventory
            KYBER.UI.Inventory.Create(nil)
        end
    )
end

-- Unequip item
function KYBER.UI.Inventory.UnequipItem(item)
    if not item then
        KYBER.UI.Notification.Create("Please select an item.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Unequip item
    KYBER.SQL.Query(
        "DELETE FROM equipment WHERE character_id = ? AND name = ?",
        {KYBER.Character.selected.id, item.name},
        function()
            -- Show success message
            KYBER.UI.Notification.Create("Item unequipped successfully.", KYBER.UI.Notification.Styles.Success)
            
            -- Refresh inventory
            KYBER.UI.Inventory.Create(nil)
        end
    )
end 