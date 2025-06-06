-- kyber/gamemode/modules/ui/templates/quest.lua
-- Quest UI template

local KYBER = KYBER or {}

-- Quest UI
KYBER.UI.Quest = KYBER.UI.Quest or {}

-- Create quest UI
function KYBER.UI.Quest.Create(parent)
    local panel = KYBER.UI.Panel.CreateModal(parent, "Quests", KYBER.UI.Panel.Styles.Default, {w = 800, h = 600})
    
    -- Create tabs
    local tabs = vgui.Create("DPropertySheet", panel.content)
    tabs:SetSize(panel.content:GetWide(), panel.content:GetTall())
    tabs:SetPos(0, 0)
    
    -- Active tab
    local activeTab = vgui.Create("DPanel")
    tabs:AddSheet("Active", activeTab)
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(activeTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("Name", 200, true)
    list:AddColumn("Level", 100, true)
    list:AddColumn("Type", 100, true)
    list:AddColumn("Progress", 200, true)
    list:AddColumn("Reward", 180, true)
    
    -- Load active quests
    KYBER.SQL.Query(
        "SELECT * FROM quests WHERE character_id = ? AND status = 'active'",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows then return end
            
            -- Add rows
            for _, row in ipairs(rows) do
                list:AddRow({
                    name = row.name,
                    level = row.level,
                    type = row.type,
                    progress = row.progress .. "/" .. row.required,
                    reward = row.reward
                })
            end
        end
    )
    
    -- Add buttons
    local abandonButton = KYBER.UI.Button.Create(
        activeTab,
        "Abandon",
        KYBER.UI.Button.Styles.Danger,
        {w = 100, h = 30},
        function()
            KYBER.UI.Quest.AbandonQuest(list:GetSelected())
        end
    )
    abandonButton:SetPos(10, 520)
    
    local trackButton = KYBER.UI.Button.Create(
        activeTab,
        "Track",
        KYBER.UI.Button.Styles.Primary,
        {w = 100, h = 30},
        function()
            KYBER.UI.Quest.TrackQuest(list:GetSelected())
        end
    )
    trackButton:SetPos(120, 520)
    
    -- Available tab
    local availableTab = vgui.Create("DPanel")
    tabs:AddSheet("Available", availableTab)
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(availableTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("Name", 200, true)
    list:AddColumn("Level", 100, true)
    list:AddColumn("Type", 100, true)
    list:AddColumn("Description", 280, true)
    list:AddColumn("Reward", 100, true)
    
    -- Load available quests
    KYBER.SQL.Query(
        "SELECT * FROM quests WHERE character_id = ? AND status = 'available'",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows then return end
            
            -- Add rows
            for _, row in ipairs(rows) do
                list:AddRow({
                    name = row.name,
                    level = row.level,
                    type = row.type,
                    description = row.description,
                    reward = row.reward
                })
            end
        end
    )
    
    -- Add buttons
    local acceptButton = KYBER.UI.Button.Create(
        availableTab,
        "Accept",
        KYBER.UI.Button.Styles.Primary,
        {w = 100, h = 30},
        function()
            KYBER.UI.Quest.AcceptQuest(list:GetSelected())
        end
    )
    acceptButton:SetPos(10, 520)
    
    -- Completed tab
    local completedTab = vgui.Create("DPanel")
    tabs:AddSheet("Completed", completedTab)
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(completedTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("Name", 200, true)
    list:AddColumn("Level", 100, true)
    list:AddColumn("Type", 100, true)
    list:AddColumn("Completed", 200, true)
    list:AddColumn("Reward", 180, true)
    
    -- Load completed quests
    KYBER.SQL.Query(
        "SELECT * FROM quests WHERE character_id = ? AND status = 'completed'",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows then return end
            
            -- Add rows
            for _, row in ipairs(rows) do
                list:AddRow({
                    name = row.name,
                    level = row.level,
                    type = row.type,
                    completed = row.completed_at,
                    reward = row.reward
                })
            end
        end
    )
    
    -- Add context menu
    local menuItems = {
        {
            label = "View Details",
            callback = function(row)
                KYBER.UI.Quest.ShowDetails(row.data)
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

-- Show quest details
function KYBER.UI.Quest.ShowDetails(quest)
    if not quest then
        KYBER.UI.Notification.Create("Please select a quest.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Create details panel
    local panel = KYBER.UI.Panel.CreateModal(nil, quest.name, KYBER.UI.Panel.Styles.Default, {w = 600, h = 400})
    
    -- Add details
    local details = vgui.Create("DLabel", panel.content)
    details:SetPos(10, 10)
    details:SetSize(580, 300)
    details:SetText([[
        Level: ]] .. quest.level .. [[
        Type: ]] .. quest.type .. [[
        
        Description:
        ]] .. quest.description .. [[
        
        Objectives:
        ]] .. quest.objectives .. [[
        
        Rewards:
        ]] .. quest.reward .. [[
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

-- Accept quest
function KYBER.UI.Quest.AcceptQuest(quest)
    if not quest then
        KYBER.UI.Notification.Create("Please select a quest.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Accept quest
    KYBER.SQL.Query(
        "UPDATE quests SET status = 'active' WHERE character_id = ? AND name = ?",
        {KYBER.Character.selected.id, quest.name},
        function()
            -- Show success message
            KYBER.UI.Notification.Create("Quest accepted successfully.", KYBER.UI.Notification.Styles.Success)
            
            -- Refresh quests
            KYBER.UI.Quest.Create(nil)
        end
    )
end

-- Abandon quest
function KYBER.UI.Quest.AbandonQuest(quest)
    if not quest then
        KYBER.UI.Notification.Create("Please select a quest.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Create confirmation dialog
    local panel = KYBER.UI.Panel.CreateModal(nil, "Abandon Quest", KYBER.UI.Panel.Styles.Default, {w = 400, h = 200})
    
    -- Add message
    local message = vgui.Create("DLabel", panel.content)
    message:SetPos(10, 10)
    message:SetSize(380, 20)
    message:SetText("Are you sure you want to abandon this quest?")
    message:SetTextColor(Color(255, 255, 255))
    
    -- Add buttons
    local confirmButton = KYBER.UI.Button.Create(
        panel.content,
        "Abandon",
        KYBER.UI.Button.Styles.Danger,
        {w = 100, h = 30},
        function()
            -- Abandon quest
            KYBER.SQL.Query(
                "UPDATE quests SET status = 'available' WHERE character_id = ? AND name = ?",
                {KYBER.Character.selected.id, quest.name},
                function()
                    -- Show success message
                    KYBER.UI.Notification.Create("Quest abandoned successfully.", KYBER.UI.Notification.Styles.Success)
                    
                    -- Close dialog
                    panel:Close()
                    
                    -- Refresh quests
                    KYBER.UI.Quest.Create(nil)
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

-- Track quest
function KYBER.UI.Quest.TrackQuest(quest)
    if not quest then
        KYBER.UI.Notification.Create("Please select a quest.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Track quest
    KYBER.SQL.Query(
        "UPDATE quests SET tracked = 1 WHERE character_id = ? AND name = ?",
        {KYBER.Character.selected.id, quest.name},
        function()
            -- Show success message
            KYBER.UI.Notification.Create("Quest tracked successfully.", KYBER.UI.Notification.Styles.Success)
            
            -- Refresh quests
            KYBER.UI.Quest.Create(nil)
        end
    )
end 