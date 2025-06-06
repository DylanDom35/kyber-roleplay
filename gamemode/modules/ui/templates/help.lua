-- kyber/gamemode/modules/ui/templates/help.lua
-- Help UI template

local KYBER = KYBER or {}

-- Help UI
KYBER.UI.Help = KYBER.UI.Help or {}

-- Create help UI
function KYBER.UI.Help.Create(parent)
    local panel = KYBER.UI.Panel.CreateModal(parent, "Help", KYBER.UI.Panel.Styles.Default, {w = 800, h = 600})
    
    -- Create tabs
    local tabs = vgui.Create("DPropertySheet", panel.content)
    tabs:SetSize(panel.content:GetWide(), panel.content:GetTall())
    tabs:SetPos(0, 0)
    
    -- Getting Started tab
    local gettingStartedTab = vgui.Create("DPanel")
    tabs:AddSheet("Getting Started", gettingStartedTab)
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(gettingStartedTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("Topic", 200, true)
    list:AddColumn("Description", 580, true)
    
    -- Add topics
    list:AddRow({
        topic = "Character Creation",
        description = "Learn how to create your first character and customize their appearance, attributes, and background."
    })
    
    list:AddRow({
        topic = "Basic Controls",
        description = "Master the basic controls for movement, combat, and interaction with the world and other players."
    })
    
    list:AddRow({
        topic = "User Interface",
        description = "Understand the various UI elements and how to navigate through menus, inventory, and other game systems."
    })
    
    list:AddRow({
        topic = "Combat System",
        description = "Learn about the combat mechanics, including weapons, abilities, and tactical considerations."
    })
    
    list:AddRow({
        topic = "Skills and Progression",
        description = "Discover how to develop your character's skills and progress through the game's leveling system."
    })
    
    -- Game Systems tab
    local gameSystemsTab = vgui.Create("DPanel")
    tabs:AddSheet("Game Systems", gameSystemsTab)
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(gameSystemsTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("System", 200, true)
    list:AddColumn("Description", 580, true)
    
    -- Add systems
    list:AddRow({
        system = "Inventory",
        description = "Manage your items, equipment, and resources. Learn about item types, storage, and trading."
    })
    
    list:AddRow({
        system = "Crafting",
        description = "Create items, weapons, and equipment using materials gathered from the world."
    })
    
    list:AddRow({
        system = "Quests",
        description = "Take on missions and quests to earn rewards, experience, and progress the story."
    })
    
    list:AddRow({
        system = "Factions",
        description = "Join factions, build reputation, and participate in faction-specific activities and rewards."
    })
    
    list:AddRow({
        system = "Economy",
        description = "Understand the game's economy, including currency, trading, and market systems."
    })
    
    -- Advanced Topics tab
    local advancedTopicsTab = vgui.Create("DPanel")
    tabs:AddSheet("Advanced Topics", advancedTopicsTab)
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(advancedTopicsTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("Topic", 200, true)
    list:AddColumn("Description", 580, true)
    
    -- Add topics
    list:AddRow({
        topic = "Advanced Combat",
        description = "Master advanced combat techniques, including combos, special abilities, and tactical positioning."
    })
    
    list:AddRow({
        topic = "Character Optimization",
        description = "Learn how to optimize your character build for different playstyles and roles."
    })
    
    list:AddRow({
        topic = "Group Dynamics",
        description = "Understand how to effectively work in groups, including roles, coordination, and strategy."
    })
    
    list:AddRow({
        topic = "Endgame Content",
        description = "Discover the challenges and rewards of endgame content, including raids, dungeons, and special events."
    })
    
    list:AddRow({
        topic = "Player vs Player",
        description = "Learn about PvP mechanics, strategies, and competitive play options."
    })
    
    -- Add context menu
    local menuItems = {
        {
            label = "View Details",
            callback = function(row)
                KYBER.UI.Help.ShowDetails(row.data)
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

-- Show topic details
function KYBER.UI.Help.ShowDetails(data)
    local panel = KYBER.UI.Panel.CreateModal(nil, data.topic or data.system, KYBER.UI.Panel.Styles.Default, {w = 600, h = 400})
    
    -- Add description
    local description = vgui.Create("DLabel", panel.content)
    description:SetPos(10, 10)
    description:SetSize(580, 20)
    description:SetText(data.description)
    description:SetTextColor(Color(255, 255, 255))
    
    -- Add content
    local content = vgui.Create("DLabel", panel.content)
    content:SetPos(10, 40)
    content:SetSize(580, 300)
    content:SetText(KYBER.UI.Help.GetContent(data.topic or data.system))
    content:SetTextColor(Color(255, 255, 255))
    
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

-- Get topic content
function KYBER.UI.Help.GetContent(topic)
    -- Load content from database
    KYBER.SQL.Query(
        "SELECT * FROM help_content WHERE topic = ?",
        {topic},
        function(rows)
            if not rows then return "" end
            
            -- Return content
            return rows[1].content
        end
    )
    
    return ""
end 