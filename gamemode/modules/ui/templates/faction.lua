-- kyber/gamemode/modules/ui/templates/faction.lua
-- Faction management UI template

local KYBER = KYBER or {}

-- Faction management UI
KYBER.UI.Faction = KYBER.UI.Faction or {}

-- Create faction management UI
function KYBER.UI.Faction.Create(parent)
    local panel = KYBER.UI.Panel.Create(parent, KYBER.UI.Panel.Styles.Default, {w = 800, h = 600})
    panel:SetTitle("Faction Management")
    panel:Center()
    
    -- Create tabs
    local tabs = vgui.Create("DPropertySheet", panel.content)
    tabs:SetSize(panel.content:GetWide(), panel.content:GetTall())
    tabs:SetPos(0, 0)
    
    -- Factions tab
    local factionsTab = vgui.Create("DPanel")
    tabs:AddSheet("Factions", factionsTab)
    
    -- Create factions list
    local factionsList = KYBER.UI.List.CreateWithSearch(factionsTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    factionsList:SetPos(10, 10)
    
    -- Add columns
    factionsList:AddColumn("Name", 200, true)
    factionsList:AddColumn("Description", 300, true)
    factionsList:AddColumn("Members", 100, true)
    factionsList:AddColumn("Territories", 100, true)
    factionsList:AddColumn("Resources", 100, true)
    
    -- Add context menu
    local menuItems = {
        {
            label = "View Details",
            callback = function(row)
                KYBER.UI.Faction.ShowDetails(row.data)
            end
        },
        {
            label = "Edit Faction",
            callback = function(row)
                KYBER.UI.Faction.ShowEditDialog(row.data)
            end
        },
        {
            label = "Delete Faction",
            callback = function(row)
                KYBER.UI.Faction.ShowDeleteDialog(row.data)
            end
        }
    }
    
    factionsList = KYBER.UI.List.CreateWithContextMenu(factionsTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500}, menuItems)
    factionsList:SetPos(10, 10)
    
    -- Add create button
    local createButton = KYBER.UI.Button.Create(
        factionsTab,
        "Create Faction",
        KYBER.UI.Button.Styles.Primary,
        {w = 120, h = 30},
        function()
            KYBER.UI.Faction.ShowCreateDialog()
        end
    )
    createButton:SetPos(10, 520)
    
    -- Members tab
    local membersTab = vgui.Create("DPanel")
    tabs:AddSheet("Members", membersTab)
    
    -- Create members list
    local membersList = KYBER.UI.List.CreateWithSearch(membersTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    membersList:SetPos(10, 10)
    
    -- Add columns
    membersList:AddColumn("Name", 200, true)
    membersList:AddColumn("Faction", 200, true)
    membersList:AddColumn("Rank", 200, true)
    membersList:AddColumn("Joined", 200, true)
    
    -- Add context menu
    local menuItems = {
        {
            label = "View Profile",
            callback = function(row)
                KYBER.UI.Faction.ShowMemberProfile(row.data)
            end
        },
        {
            label = "Change Rank",
            callback = function(row)
                KYBER.UI.Faction.ShowRankDialog(row.data)
            end
        },
        {
            label = "Kick Member",
            callback = function(row)
                KYBER.UI.Faction.ShowKickDialog(row.data)
            end
        }
    }
    
    membersList = KYBER.UI.List.CreateWithContextMenu(membersTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500}, menuItems)
    membersList:SetPos(10, 10)
    
    -- Territories tab
    local territoriesTab = vgui.Create("DPanel")
    tabs:AddSheet("Territories", territoriesTab)
    
    -- Create territories list
    local territoriesList = KYBER.UI.List.CreateWithSearch(territoriesTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    territoriesList:SetPos(10, 10)
    
    -- Add columns
    territoriesList:AddColumn("Name", 200, true)
    territoriesList:AddColumn("Owner", 200, true)
    territoriesList:AddColumn("Type", 200, true)
    territoriesList:AddColumn("Resources", 200, true)
    
    -- Add context menu
    local menuItems = {
        {
            label = "View Details",
            callback = function(row)
                KYBER.UI.Faction.ShowTerritoryDetails(row.data)
            end
        },
        {
            label = "Edit Territory",
            callback = function(row)
                KYBER.UI.Faction.ShowTerritoryEditDialog(row.data)
            end
        },
        {
            label = "Delete Territory",
            callback = function(row)
                KYBER.UI.Faction.ShowTerritoryDeleteDialog(row.data)
            end
        }
    }
    
    territoriesList = KYBER.UI.List.CreateWithContextMenu(territoriesTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500}, menuItems)
    territoriesList:SetPos(10, 10)
    
    -- Add create button
    local createButton = KYBER.UI.Button.Create(
        territoriesTab,
        "Create Territory",
        KYBER.UI.Button.Styles.Primary,
        {w = 120, h = 30},
        function()
            KYBER.UI.Faction.ShowTerritoryCreateDialog()
        end
    )
    createButton:SetPos(10, 520)
    
    -- Resources tab
    local resourcesTab = vgui.Create("DPanel")
    tabs:AddSheet("Resources", resourcesTab)
    
    -- Create resources list
    local resourcesList = KYBER.UI.List.CreateWithSearch(resourcesTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500})
    resourcesList:SetPos(10, 10)
    
    -- Add columns
    resourcesList:AddColumn("Type", 200, true)
    resourcesList:AddColumn("Amount", 200, true)
    resourcesList:AddColumn("Location", 200, true)
    resourcesList:AddColumn("Last Harvest", 200, true)
    
    -- Add context menu
    local menuItems = {
        {
            label = "View Details",
            callback = function(row)
                KYBER.UI.Faction.ShowResourceDetails(row.data)
            end
        },
        {
            label = "Harvest Resource",
            callback = function(row)
                KYBER.UI.Faction.ShowHarvestDialog(row.data)
            end
        }
    }
    
    resourcesList = KYBER.UI.List.CreateWithContextMenu(resourcesTab, KYBER.UI.List.Styles.Default, {w = 780, h = 500}, menuItems)
    resourcesList:SetPos(10, 10)
    
    return panel
end

-- Show faction details
function KYBER.UI.Faction.ShowDetails(faction)
    local panel = KYBER.UI.Panel.CreateModal(nil, "Faction Details", KYBER.UI.Panel.Styles.Default, {w = 400, h = 300})
    
    -- Add details
    local details = {
        {"Name", faction.name},
        {"Description", faction.description},
        {"Members", faction.members},
        {"Territories", faction.territories},
        {"Resources", faction.resources}
    }
    
    local y = 10
    for _, detail in ipairs(details) do
        local label = vgui.Create("DLabel", panel.content)
        label:SetPos(10, y)
        label:SetSize(100, 20)
        label:SetText(detail[1] .. ":")
        label:SetTextColor(Color(255, 255, 255))
        
        local value = vgui.Create("DLabel", panel.content)
        value:SetPos(120, y)
        value:SetSize(270, 20)
        value:SetText(tostring(detail[2]))
        value:SetTextColor(Color(255, 255, 255))
        
        y = y + 30
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
    closeButton:SetPos(150, 250)
end

-- Show faction edit dialog
function KYBER.UI.Faction.ShowEditDialog(faction)
    local panel = KYBER.UI.Panel.CreateModal(nil, "Edit Faction", KYBER.UI.Panel.Styles.Default, {w = 400, h = 300})
    
    -- Create form
    local form = KYBER.UI.Form.CreateWithCancel(
        panel.content,
        KYBER.UI.Form.Styles.Default,
        {w = 380, h = 200},
        function(values)
            -- Update faction
            KYBER.SQL.Query(
                "UPDATE factions SET name = ?, description = ? WHERE id = ?",
                {values.name, values.description, faction.id},
                function()
                    panel:Close()
                    -- Refresh factions list
                    KYBER.UI.Faction.RefreshFactionsList()
                end
            )
        end,
        function()
            panel:Close()
        end
    )
    form:SetPos(10, 10)
    
    -- Add fields
    form:AddField("name", "Name", "text", {
        required = true,
        minLength = 3,
        maxLength = 32,
        default = faction.name
    })
    
    form:AddField("description", "Description", "text", {
        required = true,
        minLength = 10,
        maxLength = 256,
        default = faction.description
    })
end

-- Show faction delete dialog
function KYBER.UI.Faction.ShowDeleteDialog(faction)
    local panel = KYBER.UI.Panel.CreateModal(nil, "Delete Faction", KYBER.UI.Panel.Styles.Default, {w = 400, h = 200})
    
    -- Add message
    local message = vgui.Create("DLabel", panel.content)
    message:SetPos(10, 10)
    message:SetSize(380, 20)
    message:SetText("Are you sure you want to delete this faction?")
    message:SetTextColor(Color(255, 255, 255))
    
    -- Add buttons
    local confirmButton = KYBER.UI.Button.Create(
        panel.content,
        "Delete",
        KYBER.UI.Button.Styles.Danger,
        {w = 100, h = 30},
        function()
            -- Delete faction
            KYBER.SQL.Query(
                "DELETE FROM factions WHERE id = ?",
                {faction.id},
                function()
                    panel:Close()
                    -- Refresh factions list
                    KYBER.UI.Faction.RefreshFactionsList()
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

-- Show faction create dialog
function KYBER.UI.Faction.ShowCreateDialog()
    local panel = KYBER.UI.Panel.CreateModal(nil, "Create Faction", KYBER.UI.Panel.Styles.Default, {w = 400, h = 300})
    
    -- Create form
    local form = KYBER.UI.Form.CreateWithCancel(
        panel.content,
        KYBER.UI.Form.Styles.Default,
        {w = 380, h = 200},
        function(values)
            -- Create faction
            KYBER.SQL.Query(
                "INSERT INTO factions (name, description) VALUES (?, ?)",
                {values.name, values.description},
                function()
                    panel:Close()
                    -- Refresh factions list
                    KYBER.UI.Faction.RefreshFactionsList()
                end
            )
        end,
        function()
            panel:Close()
        end
    )
    form:SetPos(10, 10)
    
    -- Add fields
    form:AddField("name", "Name", "text", {
        required = true,
        minLength = 3,
        maxLength = 32
    })
    
    form:AddField("description", "Description", "text", {
        required = true,
        minLength = 10,
        maxLength = 256
    })
end

-- Refresh factions list
function KYBER.UI.Faction.RefreshFactionsList()
    KYBER.SQL.Query(
        "SELECT * FROM factions",
        {},
        function(rows)
            if not rows then return end
            
            -- Clear list
            factionsList:Clear()
            
            -- Add rows
            for _, row in ipairs(rows) do
                factionsList:AddRow({
                    name = row.name,
                    description = row.description,
                    members = row.members,
                    territories = row.territories,
                    resources = row.resources
                })
            end
        end
    )
end

-- Show member profile
function KYBER.UI.Faction.ShowMemberProfile(member)
    local panel = KYBER.UI.Panel.CreateModal(nil, "Member Profile", KYBER.UI.Panel.Styles.Default, {w = 400, h = 300})
    
    -- Add details
    local details = {
        {"Name", member.name},
        {"Faction", member.faction},
        {"Rank", member.rank},
        {"Joined", member.joined}
    }
    
    local y = 10
    for _, detail in ipairs(details) do
        local label = vgui.Create("DLabel", panel.content)
        label:SetPos(10, y)
        label:SetSize(100, 20)
        label:SetText(detail[1] .. ":")
        label:SetTextColor(Color(255, 255, 255))
        
        local value = vgui.Create("DLabel", panel.content)
        value:SetPos(120, y)
        value:SetSize(270, 20)
        value:SetText(tostring(detail[2]))
        value:SetTextColor(Color(255, 255, 255))
        
        y = y + 30
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
    closeButton:SetPos(150, 250)
end

-- Show rank dialog
function KYBER.UI.Faction.ShowRankDialog(member)
    local panel = KYBER.UI.Panel.CreateModal(nil, "Change Rank", KYBER.UI.Panel.Styles.Default, {w = 400, h = 200})
    
    -- Create form
    local form = KYBER.UI.Form.CreateWithCancel(
        panel.content,
        KYBER.UI.Form.Styles.Default,
        {w = 380, h = 100},
        function(values)
            -- Update rank
            KYBER.SQL.Query(
                "UPDATE faction_members SET rank_id = ? WHERE character_id = ?",
                {values.rank, member.id},
                function()
                    panel:Close()
                    -- Refresh members list
                    KYBER.UI.Faction.RefreshMembersList()
                end
            )
        end,
        function()
            panel:Close()
        end
    )
    form:SetPos(10, 10)
    
    -- Add fields
    form:AddField("rank", "Rank", "select", {
        required = true,
        options = {
            {label = "Padawan", value = 1},
            {label = "Knight", value = 2},
            {label = "Master", value = 3}
        }
    })
end

-- Show kick dialog
function KYBER.UI.Faction.ShowKickDialog(member)
    local panel = KYBER.UI.Panel.CreateModal(nil, "Kick Member", KYBER.UI.Panel.Styles.Default, {w = 400, h = 200})
    
    -- Add message
    local message = vgui.Create("DLabel", panel.content)
    message:SetPos(10, 10)
    message:SetSize(380, 20)
    message:SetText("Are you sure you want to kick this member?")
    message:SetTextColor(Color(255, 255, 255))
    
    -- Add buttons
    local confirmButton = KYBER.UI.Button.Create(
        panel.content,
        "Kick",
        KYBER.UI.Button.Styles.Danger,
        {w = 100, h = 30},
        function()
            -- Kick member
            KYBER.SQL.Query(
                "DELETE FROM faction_members WHERE character_id = ?",
                {member.id},
                function()
                    panel:Close()
                    -- Refresh members list
                    KYBER.UI.Faction.RefreshMembersList()
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

-- Show territory details
function KYBER.UI.Faction.ShowTerritoryDetails(territory)
    local panel = KYBER.UI.Panel.CreateModal(nil, "Territory Details", KYBER.UI.Panel.Styles.Default, {w = 400, h = 300})
    
    -- Add details
    local details = {
        {"Name", territory.name},
        {"Owner", territory.owner},
        {"Type", territory.type},
        {"Resources", territory.resources}
    }
    
    local y = 10
    for _, detail in ipairs(details) do
        local label = vgui.Create("DLabel", panel.content)
        label:SetPos(10, y)
        label:SetSize(100, 20)
        label:SetText(detail[1] .. ":")
        label:SetTextColor(Color(255, 255, 255))
        
        local value = vgui.Create("DLabel", panel.content)
        value:SetPos(120, y)
        value:SetSize(270, 20)
        value:SetText(tostring(detail[2]))
        value:SetTextColor(Color(255, 255, 255))
        
        y = y + 30
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
    closeButton:SetPos(150, 250)
end

-- Show territory edit dialog
function KYBER.UI.Faction.ShowTerritoryEditDialog(territory)
    local panel = KYBER.UI.Panel.CreateModal(nil, "Edit Territory", KYBER.UI.Panel.Styles.Default, {w = 400, h = 300})
    
    -- Create form
    local form = KYBER.UI.Form.CreateWithCancel(
        panel.content,
        KYBER.UI.Form.Styles.Default,
        {w = 380, h = 200},
        function(values)
            -- Update territory
            KYBER.SQL.Query(
                "UPDATE territories SET name = ?, type = ? WHERE id = ?",
                {values.name, values.type, territory.id},
                function()
                    panel:Close()
                    -- Refresh territories list
                    KYBER.UI.Faction.RefreshTerritoriesList()
                end
            )
        end,
        function()
            panel:Close()
        end
    )
    form:SetPos(10, 10)
    
    -- Add fields
    form:AddField("name", "Name", "text", {
        required = true,
        minLength = 3,
        maxLength = 32,
        default = territory.name
    })
    
    form:AddField("type", "Type", "select", {
        required = true,
        options = {
            {label = "Mining", value = "mining"},
            {label = "Farming", value = "farming"},
            {label = "Trading", value = "trading"}
        },
        default = territory.type
    })
end

-- Show territory delete dialog
function KYBER.UI.Faction.ShowTerritoryDeleteDialog(territory)
    local panel = KYBER.UI.Panel.CreateModal(nil, "Delete Territory", KYBER.UI.Panel.Styles.Default, {w = 400, h = 200})
    
    -- Add message
    local message = vgui.Create("DLabel", panel.content)
    message:SetPos(10, 10)
    message:SetSize(380, 20)
    message:SetText("Are you sure you want to delete this territory?")
    message:SetTextColor(Color(255, 255, 255))
    
    -- Add buttons
    local confirmButton = KYBER.UI.Button.Create(
        panel.content,
        "Delete",
        KYBER.UI.Button.Styles.Danger,
        {w = 100, h = 30},
        function()
            -- Delete territory
            KYBER.SQL.Query(
                "DELETE FROM territories WHERE id = ?",
                {territory.id},
                function()
                    panel:Close()
                    -- Refresh territories list
                    KYBER.UI.Faction.RefreshTerritoriesList()
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

-- Show territory create dialog
function KYBER.UI.Faction.ShowTerritoryCreateDialog()
    local panel = KYBER.UI.Panel.CreateModal(nil, "Create Territory", KYBER.UI.Panel.Styles.Default, {w = 400, h = 300})
    
    -- Create form
    local form = KYBER.UI.Form.CreateWithCancel(
        panel.content,
        KYBER.UI.Form.Styles.Default,
        {w = 380, h = 200},
        function(values)
            -- Create territory
            KYBER.SQL.Query(
                "INSERT INTO territories (name, owner_id, type, pos_x, pos_y, pos_z, size) VALUES (?, ?, ?, ?, ?, ?, ?)",
                {values.name, values.owner, values.type, values.pos_x, values.pos_y, values.pos_z, values.size},
                function()
                    panel:Close()
                    -- Refresh territories list
                    KYBER.UI.Faction.RefreshTerritoriesList()
                end
            )
        end,
        function()
            panel:Close()
        end
    )
    form:SetPos(10, 10)
    
    -- Add fields
    form:AddField("name", "Name", "text", {
        required = true,
        minLength = 3,
        maxLength = 32
    })
    
    form:AddField("owner", "Owner", "select", {
        required = true,
        options = {
            {label = "Jedi Order", value = 1},
            {label = "Sith Order", value = 2}
        }
    })
    
    form:AddField("type", "Type", "select", {
        required = true,
        options = {
            {label = "Mining", value = "mining"},
            {label = "Farming", value = "farming"},
            {label = "Trading", value = "trading"}
        }
    })
    
    form:AddField("pos_x", "X Position", "number", {
        required = true,
        min = -16384,
        max = 16384
    })
    
    form:AddField("pos_y", "Y Position", "number", {
        required = true,
        min = -16384,
        max = 16384
    })
    
    form:AddField("pos_z", "Z Position", "number", {
        required = true,
        min = -16384,
        max = 16384
    })
    
    form:AddField("size", "Size", "number", {
        required = true,
        min = 100,
        max = 1000
    })
end

-- Show resource details
function KYBER.UI.Faction.ShowResourceDetails(resource)
    local panel = KYBER.UI.Panel.CreateModal(nil, "Resource Details", KYBER.UI.Panel.Styles.Default, {w = 400, h = 300})
    
    -- Add details
    local details = {
        {"Type", resource.type},
        {"Amount", resource.amount},
        {"Location", resource.location},
        {"Last Harvest", resource.last_harvest}
    }
    
    local y = 10
    for _, detail in ipairs(details) do
        local label = vgui.Create("DLabel", panel.content)
        label:SetPos(10, y)
        label:SetSize(100, 20)
        label:SetText(detail[1] .. ":")
        label:SetTextColor(Color(255, 255, 255))
        
        local value = vgui.Create("DLabel", panel.content)
        value:SetPos(120, y)
        value:SetSize(270, 20)
        value:SetText(tostring(detail[2]))
        value:SetTextColor(Color(255, 255, 255))
        
        y = y + 30
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
    closeButton:SetPos(150, 250)
end

-- Show harvest dialog
function KYBER.UI.Faction.ShowHarvestDialog(resource)
    local panel = KYBER.UI.Panel.CreateModal(nil, "Harvest Resource", KYBER.UI.Panel.Styles.Default, {w = 400, h = 200})
    
    -- Create form
    local form = KYBER.UI.Form.CreateWithCancel(
        panel.content,
        KYBER.UI.Form.Styles.Default,
        {w = 380, h = 100},
        function(values)
            -- Harvest resource
            KYBER.SQL.Query(
                "UPDATE territory_resources SET amount = amount - ?, last_harvest = CURRENT_TIMESTAMP WHERE id = ?",
                {values.amount, resource.id},
                function()
                    panel:Close()
                    -- Refresh resources list
                    KYBER.UI.Faction.RefreshResourcesList()
                end
            )
        end,
        function()
            panel:Close()
        end
    )
    form:SetPos(10, 10)
    
    -- Add fields
    form:AddField("amount", "Amount", "number", {
        required = true,
        min = 1,
        max = resource.amount
    })
end

-- Refresh members list
function KYBER.UI.Faction.RefreshMembersList()
    KYBER.SQL.Query(
        "SELECT * FROM faction_members",
        {},
        function(rows)
            if not rows then return end
            
            -- Clear list
            membersList:Clear()
            
            -- Add rows
            for _, row in ipairs(rows) do
                membersList:AddRow({
                    name = row.name,
                    faction = row.faction,
                    rank = row.rank,
                    joined = row.joined
                })
            end
        end
    )
end

-- Refresh territories list
function KYBER.UI.Faction.RefreshTerritoriesList()
    KYBER.SQL.Query(
        "SELECT * FROM territories",
        {},
        function(rows)
            if not rows then return end
            
            -- Clear list
            territoriesList:Clear()
            
            -- Add rows
            for _, row in ipairs(rows) do
                territoriesList:AddRow({
                    name = row.name,
                    owner = row.owner,
                    type = row.type,
                    resources = row.resources
                })
            end
        end
    )
end

-- Refresh resources list
function KYBER.UI.Faction.RefreshResourcesList()
    KYBER.SQL.Query(
        "SELECT * FROM territory_resources",
        {},
        function(rows)
            if not rows then return end
            
            -- Clear list
            resourcesList:Clear()
            
            -- Add rows
            for _, row in ipairs(rows) do
                resourcesList:AddRow({
                    type = row.type,
                    amount = row.amount,
                    location = row.location,
                    last_harvest = row.last_harvest
                })
            end
        end
    )
end 