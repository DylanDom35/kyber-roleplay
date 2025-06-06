-- kyber/gamemode/modules/ui/templates/map.lua
-- Map UI template

local KYBER = KYBER or {}

-- Map UI
KYBER.UI.Map = KYBER.UI.Map or {}

-- Create map UI
function KYBER.UI.Map.Create(parent)
    local panel = KYBER.UI.Panel.CreateModal(parent, "Map", KYBER.UI.Panel.Styles.Default, {w = 800, h = 600})
    
    -- Create map
    local map = vgui.Create("DImage", panel.content)
    map:SetPos(10, 10)
    map:SetSize(780, 500)
    map:SetImage("materials/kyber/map.png")
    
    -- Create zoom slider
    local zoomSlider = vgui.Create("DNumSlider", panel.content)
    zoomSlider:SetPos(10, 520)
    zoomSlider:SetSize(780, 20)
    zoomSlider:SetText("Zoom")
    zoomSlider:SetMin(0.5)
    zoomSlider:SetMax(2)
    zoomSlider:SetValue(1)
    zoomSlider:SetDecimals(1)
    zoomSlider.OnValueChanged = function(_, value)
        map:SetSize(780 * value, 500 * value)
    end
    
    -- Create location list
    local locationList = vgui.Create("DListView", panel.content)
    locationList:SetPos(10, 550)
    locationList:SetSize(780, 40)
    locationList:AddColumn("Name")
    locationList:AddColumn("Type")
    locationList:AddColumn("Description")
    
    -- Load locations
    KYBER.SQL.Query(
        "SELECT * FROM locations",
        {},
        function(rows)
            if not rows then return end
            
            -- Add rows
            for _, row in ipairs(rows) do
                locationList:AddLine(row.name, row.type, row.description)
            end
        end
    )
    
    -- Add buttons
    local teleportButton = KYBER.UI.Button.Create(
        panel.content,
        "Teleport",
        KYBER.UI.Button.Styles.Primary,
        {w = 100, h = 30},
        function()
            KYBER.UI.Map.Teleport(locationList:GetSelected())
        end
    )
    teleportButton:SetPos(10, 560)
    
    local markButton = KYBER.UI.Button.Create(
        panel.content,
        "Mark",
        KYBER.UI.Button.Styles.Secondary,
        {w = 100, h = 30},
        function()
            KYBER.UI.Map.MarkLocation(locationList:GetSelected())
        end
    )
    markButton:SetPos(120, 560)
    
    return panel
end

-- Teleport to location
function KYBER.UI.Map.Teleport(location)
    if not location then
        KYBER.UI.Notification.Create("Please select a location.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Create confirmation dialog
    local panel = KYBER.UI.Panel.CreateModal(nil, "Teleport", KYBER.UI.Panel.Styles.Default, {w = 400, h = 200})
    
    -- Add message
    local message = vgui.Create("DLabel", panel.content)
    message:SetPos(10, 10)
    message:SetSize(380, 20)
    message:SetText("Are you sure you want to teleport to " .. location.name .. "?")
    message:SetTextColor(Color(255, 255, 255))
    
    -- Add buttons
    local confirmButton = KYBER.UI.Button.Create(
        panel.content,
        "Teleport",
        KYBER.UI.Button.Styles.Primary,
        {w = 100, h = 30},
        function()
            -- Teleport
            KYBER.SQL.Query(
                "UPDATE characters SET position = ? WHERE id = ?",
                {location.position, KYBER.Character.selected.id},
                function()
                    -- Show success message
                    KYBER.UI.Notification.Create("Teleported successfully.", KYBER.UI.Notification.Styles.Success)
                    
                    -- Close dialog
                    panel:Close()
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

-- Mark location
function KYBER.UI.Map.MarkLocation(location)
    if not location then
        KYBER.UI.Notification.Create("Please select a location.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Mark location
    KYBER.SQL.Query(
        "INSERT INTO marked_locations (character_id, location_id) VALUES (?, ?)",
        {KYBER.Character.selected.id, location.id},
        function()
            -- Show success message
            KYBER.UI.Notification.Create("Location marked successfully.", KYBER.UI.Notification.Styles.Success)
        end
    )
end 