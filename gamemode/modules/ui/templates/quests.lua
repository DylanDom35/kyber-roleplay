-- kyber/gamemode/modules/ui/templates/quests.lua
-- Quests UI template

local KYBER = KYBER or {}

-- Quests UI
KYBER.UI.Quests = KYBER.UI.Quests or {}

-- Create quests UI
function KYBER.UI.Quests.Create(parent)
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
    list:AddColumn("Quest", 200, true)
    list:AddColumn("Level", 100, true)
    list:AddColumn("Status", 100, true)
    list:AddColumn("Progress", 100, true)
    list:AddColumn("Rewards", 280, true)
    
    -- Load active quests
    KYBER.SQL.Query(
        "SELECT * FROM quests WHERE character_id = ? AND status = 'active'",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows then return end
            
            -- Add rows
            for _, row in ipairs(rows) do
                list:AddRow({
                    quest = row.name,
                    level = row.level,
                    status = row.status,
                    progress = row.progress .. "%",
                    rewards = row.rewards
                })
            end
        end
    )
    
    -- Completed tab
    local completedTab = vgui.Create("DPanel")
    tabs:AddSheet("Completed", completedTab)
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(completedTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("Quest", 200, true)
    list:AddColumn("Level", 100, true)
    list:AddColumn("Completed", 200, true)
    list:AddColumn("Rewards", 280, true)
    
    -- Load completed quests
    KYBER.SQL.Query(
        "SELECT * FROM quests WHERE character_id = ? AND status = 'completed'",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows then return end
            
            -- Add rows
            for _, row in ipairs(rows) do
                list:AddRow({
                    quest = row.name,
                    level = row.level,
                    completed = row.completed_at,
                    rewards = row.rewards
                })
            end
        end
    )
    
    -- Available tab
    local availableTab = vgui.Create("DPanel")
    tabs:AddSheet("Available", availableTab)
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(availableTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("Quest", 200, true)
    list:AddColumn("Level", 100, true)
    list:AddColumn("Requirements", 280, true)
    list:AddColumn("Rewards", 200, true)
    
    -- Load available quests
    KYBER.SQL.Query(
        "SELECT * FROM quests WHERE character_id = ? AND status = 'available'",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows then return end
            
            -- Add rows
            for _, row in ipairs(rows) do
                list:AddRow({
                    quest = row.name,
                    level = row.level,
                    requirements = row.requirements,
                    rewards = row.rewards
                })
            end
        end
    )
    
    -- Add context menu
    local menuItems = {
        {
            label = "View Details",
            callback = function(row)
                KYBER.UI.Quests.ShowDetails(row.data)
            end
        },
        {
            label = "Accept Quest",
            callback = function(row)
                KYBER.UI.Quests.AcceptQuest(row.data)
            end,
            condition = function(row)
                return row.status == "available"
            end
        },
        {
            label = "Abandon Quest",
            callback = function(row)
                KYBER.UI.Quests.AbandonQuest(row.data)
            end,
            condition = function(row)
                return row.status == "active"
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
function KYBER.UI.Quests.ShowDetails(data)
    local panel = KYBER.UI.Panel.CreateModal(nil, data.quest, KYBER.UI.Panel.Styles.Default, {w = 600, h = 400})
    
    -- Add level
    local level = vgui.Create("DLabel", panel.content)
    level:SetPos(10, 10)
    level:SetSize(580, 20)
    level:SetText("Level: " .. data.level)
    level:SetTextColor(Color(255, 255, 255))
    
    -- Add status
    if data.status then
        local status = vgui.Create("DLabel", panel.content)
        status:SetPos(10, 40)
        status:SetSize(580, 20)
        status:SetText("Status: " .. data.status)
        status:SetTextColor(Color(255, 255, 255))
    end
    
    -- Add progress
    if data.progress then
        local progress = vgui.Create("DLabel", panel.content)
        progress:SetPos(10, 70)
        progress:SetSize(580, 20)
        progress:SetText("Progress: " .. data.progress)
        progress:SetTextColor(Color(255, 255, 255))
        
        -- Add progress bar
        local progressBar = vgui.Create("DProgress", panel.content)
        progressBar:SetPos(10, 100)
        progressBar:SetSize(580, 20)
        progressBar:SetFraction(tonumber(data.progress:gsub("%%", "")) / 100)
    end
    
    -- Add requirements
    if data.requirements then
        local requirements = vgui.Create("DLabel", panel.content)
        requirements:SetPos(10, 130)
        requirements:SetSize(580, 20)
        requirements:SetText("Requirements:")
        requirements:SetTextColor(Color(255, 255, 255))
        
        -- Add requirements list
        local requirementsList = vgui.Create("DLabel", panel.content)
        requirementsList:SetPos(10, 160)
        requirementsList:SetSize(580, 20)
        requirementsList:SetText(data.requirements)
        requirementsList:SetTextColor(Color(255, 255, 255))
    end
    
    -- Add rewards
    if data.rewards then
        local rewards = vgui.Create("DLabel", panel.content)
        rewards:SetPos(10, 190)
        rewards:SetSize(580, 20)
        rewards:SetText("Rewards:")
        rewards:SetTextColor(Color(255, 255, 255))
        
        -- Add rewards list
        local rewardsList = vgui.Create("DLabel", panel.content)
        rewardsList:SetPos(10, 220)
        rewardsList:SetSize(580, 20)
        rewardsList:SetText(data.rewards)
        rewardsList:SetTextColor(Color(255, 255, 255))
    end
    
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
function KYBER.UI.Quests.AcceptQuest(data)
    -- Create confirmation dialog
    local panel = KYBER.UI.Panel.CreateModal(nil, "Accept Quest", KYBER.UI.Panel.Styles.Default, {w = 400, h = 200})
    
    -- Add message
    local message = vgui.Create("DLabel", panel.content)
    message:SetPos(10, 10)
    message:SetSize(380, 20)
    message:SetText("Are you sure you want to accept this quest?")
    message:SetTextColor(Color(255, 255, 255))
    
    -- Add buttons
    local confirmButton = KYBER.UI.Button.Create(
        panel.content,
        "Accept",
        KYBER.UI.Button.Styles.Primary,
        {w = 100, h = 30},
        function()
            -- Accept quest
            KYBER.SQL.Query(
                "UPDATE quests SET status = 'active', progress = 0 WHERE id = ?",
                {data.id},
                function()
                    -- Show success message
                    KYBER.UI.Notification.Create("Quest accepted successfully.", KYBER.UI.Notification.Styles.Success)
                    
                    -- Close dialog
                    panel:Close()
                    
                    -- Refresh quests UI
                    KYBER.UI.Quests.Refresh()
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

-- Abandon quest
function KYBER.UI.Quests.AbandonQuest(data)
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
                "UPDATE quests SET status = 'available' WHERE id = ?",
                {data.id},
                function()
                    -- Show success message
                    KYBER.UI.Notification.Create("Quest abandoned successfully.", KYBER.UI.Notification.Styles.Success)
                    
                    -- Close dialog
                    panel:Close()
                    
                    -- Refresh quests UI
                    KYBER.UI.Quests.Refresh()
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

-- Refresh quests UI
function KYBER.UI.Quests.Refresh()
    if not KYBER.UI.Quests.panel then return end
    
    -- Clear lists
    for _, tab in ipairs(KYBER.UI.Quests.panel.content:GetChildren()[1].Items) do
        if tab.Panel and tab.Panel:GetChildren()[1] then
            local list = tab.Panel:GetChildren()[1]
            list:Clear()
        end
    end
    
    -- Reload quests
    KYBER.UI.Quests.Create(KYBER.UI.Quests.panel:GetParent())
end 