-- kyber/gamemode/modules/spawn/manager.lua

KYBER.SpawnManager = KYBER.SpawnManager or {}

if SERVER then
    util.AddNetworkString("Kyber_OpenSpawnManager")
    util.AddNetworkString("Kyber_SetSpawnPoint")
    util.AddNetworkString("Kyber_DeleteSpawnPoint")
    util.AddNetworkString("Kyber_UpdateSpawnList")
    
    -- Initialize spawn system
    function KYBER.SpawnManager:Initialize()
        -- Load spawn points from file
        self:LoadSpawnPoints()
        
        -- Create spawn management commands
        self:CreateCommands()
    end
    
    function KYBER.SpawnManager:LoadSpawnPoints()
        if file.Exists("kyber/spawns/spawnpoints.json", "DATA") then
            local data = file.Read("kyber/spawns/spawnpoints.json", "DATA")
            KYBER.SpawnPoints = util.JSONToTable(data) or {}
        else
            -- Default spawn points if none exist
            KYBER.SpawnPoints = {
                ["default"] = {
                    name = "Default Spawn",
                    pos = Vector(0, 0, 100),
                    ang = Angle(0, 0, 0),
                    faction = "",
                    description = "Default spawn location"
                }
            }
            self:SaveSpawnPoints()
        end
        
        print("[Kyber] Loaded " .. table.Count(KYBER.SpawnPoints) .. " spawn points")
    end
    
    function KYBER.SpawnManager:SaveSpawnPoints()
        if not file.Exists("kyber/spawns", "DATA") then
            file.CreateDir("kyber/spawns")
        end
        
        file.Write("kyber/spawns/spawnpoints.json", util.TableToJSON(KYBER.SpawnPoints))
    end
    
    function KYBER.SpawnManager:AddSpawnPoint(ply, name, faction, description)
        if not ply:IsAdmin() then
            ply:ChatPrint("You must be an admin to set spawn points")
            return false
        end
        
        local spawnID = string.lower(string.gsub(name, "%s+", "_"))
        
        KYBER.SpawnPoints[spawnID] = {
            name = name,
            pos = ply:GetPos(),
            ang = ply:GetAngles(),
            faction = faction or "",
            description = description or "",
            created_by = ply:SteamID64(),
            created_at = os.time()
        }
        
        self:SaveSpawnPoints()
        
        ply:ChatPrint("Spawn point '" .. name .. "' created at your location")
        
        -- Update all admin clients
        self:UpdateSpawnList()
        
        return true
    end
    
    function KYBER.SpawnManager:DeleteSpawnPoint(ply, spawnID)
        if not ply:IsAdmin() then
            ply:ChatPrint("You must be an admin to delete spawn points")
            return false
        end
        
        if KYBER.SpawnPoints[spawnID] then
            KYBER.SpawnPoints[spawnID] = nil
            self:SaveSpawnPoints()
            
            ply:ChatPrint("Spawn point deleted")
            self:UpdateSpawnList()
            return true
        else
            ply:ChatPrint("Spawn point not found")
            return false
        end
    end
    
    function KYBER.SpawnManager:GetSpawnPoint(ply)
        local factionID = ply:GetNWString("kyber_faction", "")
        
        -- First try faction-specific spawns
        if factionID ~= "" then
            for id, spawn in pairs(KYBER.SpawnPoints) do
                if spawn.faction == factionID then
                    return spawn.pos, spawn.ang
                end
            end
        end
        
        -- Fall back to default spawn
        local defaultSpawn = KYBER.SpawnPoints["default"]
        if defaultSpawn then
            return defaultSpawn.pos, defaultSpawn.ang
        end
        
        -- Ultimate fallback
        return Vector(0, 0, 100), Angle(0, 0, 0)
    end
    
    function KYBER.SpawnManager:UpdateSpawnList()
        for _, ply in ipairs(player.GetAll()) do
            if ply:IsAdmin() then
                net.Start("Kyber_UpdateSpawnList")
                net.WriteTable(KYBER.SpawnPoints)
                net.Send(ply)
            end
        end
    end
    
    function KYBER.SpawnManager:CreateCommands()
        -- Admin command to open spawn manager
        concommand.Add("kyber_spawns", function(ply)
            if not ply:IsAdmin() then
                ply:ChatPrint("You must be an admin to use this command")
                return
            end
            
            net.Start("Kyber_OpenSpawnManager")
            net.WriteTable(KYBER.SpawnPoints)
            net.Send(ply)
        end)
        
        -- Quick spawn set command
        concommand.Add("kyber_setspawn", function(ply, cmd, args)
            if not ply:IsAdmin() then
                ply:ChatPrint("You must be an admin to use this command")
                return
            end
            
            local name = args[1] or "Unnamed Spawn"
            local faction = args[2] or ""
            local description = table.concat(args, " ", 3) or ""
            
            KYBER.SpawnManager:AddSpawnPoint(ply, name, faction, description)
        end)
    end
    
    -- Network handlers
    net.Receive("Kyber_SetSpawnPoint", function(len, ply)
        local name = net.ReadString()
        local faction = net.ReadString()
        local description = net.ReadString()
        
        KYBER.SpawnManager:AddSpawnPoint(ply, name, faction, description)
    end)
    
    net.Receive("Kyber_DeleteSpawnPoint", function(len, ply)
        local spawnID = net.ReadString()
        KYBER.SpawnManager:DeleteSpawnPoint(ply, spawnID)
    end)
    
    -- Override player spawn
    hook.Add("PlayerSpawn", "KyberSpawnManager", function(ply)
        timer.Simple(0.1, function()
            if IsValid(ply) then
                local pos, ang = KYBER.SpawnManager:GetSpawnPoint(ply)
                ply:SetPos(pos)
                if ang then
                    ply:SetEyeAngles(ang)
                end
            end
        end)
    end)
    
    -- Initialize on gamemode load
    hook.Add("Initialize", "KyberSpawnManagerInit", function()
        KYBER.SpawnManager:Initialize()
    end)
    
else -- CLIENT
    
    local SpawnManagerFrame = nil
    
    net.Receive("Kyber_OpenSpawnManager", function()
        local spawnPoints = net.ReadTable()
        KYBER.SpawnManager:OpenUI(spawnPoints)
    end)
    
    net.Receive("Kyber_UpdateSpawnList", function()
        local spawnPoints = net.ReadTable()
        if IsValid(SpawnManagerFrame) then
            KYBER.SpawnManager:RefreshUI(spawnPoints)
        end
    end)
    
    function KYBER.SpawnManager:OpenUI(spawnPoints)
        if IsValid(SpawnManagerFrame) then SpawnManagerFrame:Remove() end
        
        SpawnManagerFrame = vgui.Create("DFrame")
        SpawnManagerFrame:SetSize(800, 600)
        SpawnManagerFrame:Center()
        SpawnManagerFrame:SetTitle("Spawn Point Manager")
        SpawnManagerFrame:MakePopup()
        
        -- Custom paint
        SpawnManagerFrame.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(20, 25, 35, 250))
            draw.RoundedBox(8, 2, 2, w-4, h-4, Color(40, 50, 70, 100))
            
            -- Title bar
            draw.RoundedBoxEx(8, 0, 0, w, 40, Color(30, 40, 60, 200), true, true, false, false)
            draw.SimpleText("SPAWN POINT MANAGER", "DermaDefaultBold", w/2, 20, Color(100, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- Main container
        local container = vgui.Create("DPanel", SpawnManagerFrame)
        container:SetPos(10, 50)
        container:SetSize(SpawnManagerFrame:GetWide() - 20, SpawnManagerFrame:GetTall() - 60)
        container.Paint = function() end
        
        -- Left side - Spawn list
        local leftPanel = vgui.Create("DPanel", container)
        leftPanel:SetPos(0, 0)
        leftPanel:SetSize(400, container:GetTall())
        leftPanel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(30, 40, 60, 150))
            draw.SimpleText("SPAWN POINTS", "DermaDefaultBold", w/2, 15, Color(100, 150, 255), TEXT_ALIGN_CENTER)
            surface.SetDrawColor(100, 150, 255, 100)
            surface.DrawRect(10, 35, w-20, 1)
        end
        
        -- Spawn list
        local spawnScroll = vgui.Create("DScrollPanel", leftPanel)
        spawnScroll:SetPos(10, 45)
        spawnScroll:SetSize(380, leftPanel:GetTall() - 55)
        
        SpawnManagerFrame.spawnScroll = spawnScroll
        
        -- Right side - Controls
        local rightPanel = vgui.Create("DPanel", container)
        rightPanel:SetPos(420, 0)
        rightPanel:SetSize(360, container:GetTall())
        rightPanel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(30, 40, 60, 150))
            draw.SimpleText("ADD NEW SPAWN", "DermaDefaultBold", w/2, 15, Color(100, 150, 255), TEXT_ALIGN_CENTER)
            surface.SetDrawColor(100, 150, 255, 100)
            surface.DrawRect(10, 35, w-20, 1)
        end
        
        local y = 50
        
        -- Name input
        local nameLabel = vgui.Create("DLabel", rightPanel)
        nameLabel:SetPos(15, y)
        nameLabel:SetText("Spawn Name:")
        nameLabel:SetTextColor(Color(200, 200, 200))
        nameLabel:SizeToContents()
        
        local nameEntry = vgui.Create("DTextEntry", rightPanel)
        nameEntry:SetPos(15, y + 20)
        nameEntry:SetSize(330, 25)
        nameEntry:SetPlaceholderText("Enter spawn point name...")
        nameEntry.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(20, 30, 50))
            draw.RoundedBox(4, 1, 1, w-2, h-2, Color(40, 50, 70))
            self:DrawTextEntryText(Color(255, 255, 255), Color(100, 150, 255), Color(255, 255, 255))
        end
        y = y + 60
        
        -- Faction selector
        local factionLabel = vgui.Create("DLabel", rightPanel)
        factionLabel:SetPos(15, y)
        factionLabel:SetText("Faction (leave empty for general):")
        factionLabel:SetTextColor(Color(200, 200, 200))
        factionLabel:SizeToContents()
        
        local factionCombo = vgui.Create("DComboBox", rightPanel)
        factionCombo:SetPos(15, y + 20)
        factionCombo:SetSize(330, 25)
        factionCombo:SetValue("Select Faction (Optional)")
        factionCombo:AddChoice("None", "")
        
        if KYBER and KYBER.Factions then
            for id, faction in pairs(KYBER.Factions) do
                factionCombo:AddChoice(faction.name, id)
            end
        end
        
        factionCombo.Paint = nameEntry.Paint
        y = y + 60
        
        -- Description
        local descLabel = vgui.Create("DLabel", rightPanel)
        descLabel:SetPos(15, y)
        descLabel:SetText("Description:")
        descLabel:SetTextColor(Color(200, 200, 200))
        descLabel:SizeToContents()
        
        local descEntry = vgui.Create("DTextEntry", rightPanel)
        descEntry:SetPos(15, y + 20)
        descEntry:SetSize(330, 60)
        descEntry:SetMultiline(true)
        descEntry:SetPlaceholderText("Enter description...")
        descEntry.Paint = nameEntry.Paint
        y = y + 100
        
        -- Position info
        local posLabel = vgui.Create("DLabel", rightPanel)
        posLabel:SetPos(15, y)
        posLabel:SetText("Position: Your current location")
        posLabel:SetTextColor(Color(100, 255, 100))
        posLabel:SizeToContents()
        y = y + 30
        
        -- Add button
        local addBtn = vgui.Create("DButton", rightPanel)
        addBtn:SetPos(15, y)
        addBtn:SetSize(330, 40)
        addBtn:SetText("ADD SPAWN POINT")
        addBtn:SetFont("DermaDefaultBold")
        addBtn.Paint = function(self, w, h)
            local col = self:IsHovered() and Color(120, 170, 255) or Color(100, 150, 255)
            draw.RoundedBox(6, 0, 0, w, h, col)
            draw.SimpleText(self:GetText(), "DermaDefaultBold", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        addBtn.DoClick = function()
            local name = nameEntry:GetValue()
            local _, faction = factionCombo:GetSelected()
            local description = descEntry:GetValue()
            
            if name == "" then
                LocalPlayer():ChatPrint("Please enter a spawn name")
                return
            end
            
            net.Start("Kyber_SetSpawnPoint")
            net.WriteString(name)
            net.WriteString(faction or "")
            net.WriteString(description)
            net.SendToServer()
            
            -- Clear fields
            nameEntry:SetValue("")
            factionCombo:SetValue("Select Faction (Optional)")
            descEntry:SetValue("")
        end
        y = y + 60
        
        -- Instructions
        local instrPanel = vgui.Create("DPanel", rightPanel)
        instrPanel:SetPos(15, y)
        instrPanel:SetSize(330, 80)
        instrPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(50, 70, 50, 100))
            draw.SimpleText("INSTRUCTIONS:", "DermaDefaultBold", 10, 10, Color(150, 255, 150))
            draw.SimpleText("• Stand where you want the spawn", "DermaDefault", 10, 30, Color(200, 255, 200))
            draw.SimpleText("• Face the direction players should spawn", "DermaDefault", 10, 45, Color(200, 255, 200))
            draw.SimpleText("• Click 'Add Spawn Point'", "DermaDefault", 10, 60, Color(200, 255, 200))
        end
        
        -- Populate spawn list
        self:RefreshUI(spawnPoints)
    end
    
    function KYBER.SpawnManager:RefreshUI(spawnPoints)
        if not IsValid(SpawnManagerFrame) or not IsValid(SpawnManagerFrame.spawnScroll) then return end
        
        SpawnManagerFrame.spawnScroll:Clear()
        
        for id, spawn in pairs(spawnPoints) do
            local spawnPanel = vgui.Create("DPanel", SpawnManagerFrame.spawnScroll)
            spawnPanel:Dock(TOP)
            spawnPanel:DockMargin(0, 0, 0, 5)
            spawnPanel:SetTall(80)
            
            spawnPanel.Paint = function(self, w, h)
                local bgColor = Color(40, 50, 70, 150)
                if spawn.faction ~= "" and KYBER.Factions and KYBER.Factions[spawn.faction] then
                    local factionColor = KYBER.Factions[spawn.faction].color
                    bgColor = Color(factionColor.r * 0.3, factionColor.g * 0.3, factionColor.b * 0.3, 150)
                end
                
                draw.RoundedBox(4, 0, 0, w, h, bgColor)
                
                -- Spawn name
                draw.SimpleText(spawn.name, "DermaDefaultBold", 10, 10, Color(255, 255, 255))
                
                -- Faction
                if spawn.faction ~= "" and KYBER.Factions and KYBER.Factions[spawn.faction] then
                    local factionName = KYBER.Factions[spawn.faction].name
                    local factionColor = KYBER.Factions[spawn.faction].color
                    draw.SimpleText("Faction: " .. factionName, "DermaDefault", 10, 30, factionColor)
                else
                    draw.SimpleText("Faction: General", "DermaDefault", 10, 30, Color(200, 200, 200))
                end
                
                -- Description
                if spawn.description and spawn.description ~= "" then
                    draw.SimpleText(spawn.description, "DermaDefault", 10, 50, Color(180, 180, 180))
                end
                
                -- Position
                local posText = string.format("Pos: %.0f, %.0f, %.0f", spawn.pos.x, spawn.pos.y, spawn.pos.z)
                draw.SimpleText(posText, "DermaDefault", w - 150, 10, Color(150, 150, 150))
            end
            
            -- Delete button
            local deleteBtn = vgui.Create("DButton", spawnPanel)
            deleteBtn:SetPos(spawnPanel:GetWide() - 80, 45)
            deleteBtn:SetSize(70, 25)
            deleteBtn:SetText("DELETE")
            deleteBtn:SetFont("DermaDefault")
            deleteBtn.Paint = function(self, w, h)
                local col = self:IsHovered() and Color(255, 100, 100) or Color(200, 50, 50)
                draw.RoundedBox(4, 0, 0, w, h, col)
                draw.SimpleText(self:GetText(), "DermaDefault", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            deleteBtn.DoClick = function()
                Derma_Query(
                    "Are you sure you want to delete the spawn point '" .. spawn.name .. "'?",
                    "Confirm Delete",
                    "Yes", function()
                        net.Start("Kyber_DeleteSpawnPoint")
                        net.WriteString(id)
                        net.SendToServer()
                    end,
                    "No", function() end
                )
            end
            
            -- Teleport button
            local teleBtn = vgui.Create("DButton", spawnPanel)
            teleBtn:SetPos(spawnPanel:GetWide() - 160, 45)
            teleBtn:SetSize(70, 25)
            teleBtn:SetText("TELEPORT")
            teleBtn:SetFont("DermaDefault")
            teleBtn.Paint = function(self, w, h)
                local col = self:IsHovered() and Color(100, 150, 255) or Color(50, 100, 200)
                draw.RoundedBox(4, 0, 0, w, h, col)
                draw.SimpleText(self:GetText(), "DermaDefault", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            teleBtn.DoClick = function()
                LocalPlayer():SetPos(spawn.pos)
                LocalPlayer():SetEyeAngles(spawn.ang)
                LocalPlayer():ChatPrint("Teleported to " .. spawn.name)
            end
        end
    end
end