-- kyber/gamemode/modules/ui/templates/skills.lua
-- Skills UI template

local KYBER = KYBER or {}

-- Skills UI
KYBER.UI.Skills = KYBER.UI.Skills or {}

-- Create skills UI
function KYBER.UI.Skills.Create(parent)
    local panel = KYBER.UI.Panel.CreateModal(parent, "Skills", KYBER.UI.Panel.Styles.Default, {w = 800, h = 600})
    
    -- Create tabs
    local tabs = vgui.Create("DPropertySheet", panel.content)
    tabs:SetSize(panel.content:GetWide(), panel.content:GetTall())
    tabs:SetPos(0, 0)
    
    -- Combat tab
    local combatTab = vgui.Create("DPanel")
    tabs:AddSheet("Combat", combatTab)
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(combatTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("Name", 200, true)
    list:AddColumn("Level", 100, true)
    list:AddColumn("XP", 100, true)
    list:AddColumn("Next Level", 100, true)
    list:AddColumn("Description", 280, true)
    
    -- Load combat skills
    KYBER.SQL.Query(
        "SELECT * FROM skills WHERE character_id = ? AND category = 'combat'",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows then return end
            
            -- Add rows
            for _, row in ipairs(rows) do
                list:AddRow({
                    name = row.name,
                    level = row.level,
                    xp = row.xp,
                    next_level = row.next_level,
                    description = row.description
                })
            end
        end
    )
    
    -- Crafting tab
    local craftingTab = vgui.Create("DPanel")
    tabs:AddSheet("Crafting", craftingTab)
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(craftingTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("Name", 200, true)
    list:AddColumn("Level", 100, true)
    list:AddColumn("XP", 100, true)
    list:AddColumn("Next Level", 100, true)
    list:AddColumn("Description", 280, true)
    
    -- Load crafting skills
    KYBER.SQL.Query(
        "SELECT * FROM skills WHERE character_id = ? AND category = 'crafting'",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows then return end
            
            -- Add rows
            for _, row in ipairs(rows) do
                list:AddRow({
                    name = row.name,
                    level = row.level,
                    xp = row.xp,
                    next_level = row.next_level,
                    description = row.description
                })
            end
        end
    )
    
    -- Social tab
    local socialTab = vgui.Create("DPanel")
    tabs:AddSheet("Social", socialTab)
    
    -- Create list
    local list = KYBER.UI.List.CreateWithSearch(socialTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    list:SetPos(10, 10)
    
    -- Add columns
    list:AddColumn("Name", 200, true)
    list:AddColumn("Level", 100, true)
    list:AddColumn("XP", 100, true)
    list:AddColumn("Next Level", 100, true)
    list:AddColumn("Description", 280, true)
    
    -- Load social skills
    KYBER.SQL.Query(
        "SELECT * FROM skills WHERE character_id = ? AND category = 'social'",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows then return end
            
            -- Add rows
            for _, row in ipairs(rows) do
                list:AddRow({
                    name = row.name,
                    level = row.level,
                    xp = row.xp,
                    next_level = row.next_level,
                    description = row.description
                })
            end
        end
    )
    
    -- Add context menu
    local menuItems = {
        {
            label = "View Details",
            callback = function(row)
                KYBER.UI.Skills.ShowDetails(row.data)
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

-- Show skill details
function KYBER.UI.Skills.ShowDetails(skill)
    if not skill then
        KYBER.UI.Notification.Create("Please select a skill.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Create details panel
    local panel = KYBER.UI.Panel.CreateModal(nil, skill.name, KYBER.UI.Panel.Styles.Default, {w = 600, h = 400})
    
    -- Add details
    local details = vgui.Create("DLabel", panel.content)
    details:SetPos(10, 10)
    details:SetSize(580, 300)
    details:SetText([[
        Level: ]] .. skill.level .. [[
        XP: ]] .. skill.xp .. [[
        Next Level: ]] .. skill.next_level .. [[
        
        Description:
        ]] .. skill.description .. [[
        
        Effects:
        ]] .. skill.effects .. [[
        
        Requirements:
        ]] .. skill.requirements .. [[
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