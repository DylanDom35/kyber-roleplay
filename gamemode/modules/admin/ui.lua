-- kyber/modules/admin/ui.lua
-- Client-side admin panel UI

if CLIENT then
    KYBER.Admin = KYBER.Admin or {}
    KYBER.Admin.Panel = nil
    KYBER.Admin.Data = {}
    
    function KYBER.Admin:OpenPanel()
        if IsValid(self.Panel) then
            self.Panel:Remove()
            return
        end
        
        -- Main admin panel styled like an Imperial Command Terminal
        self.Panel = vgui.Create("DFrame")
        self.Panel:SetSize(1200, 800)
        self.Panel:Center()
        self.Panel:SetTitle("")
        self.Panel:SetDraggable(false)
        self.Panel:ShowCloseButton(false)
        self.Panel:MakePopup()
        
        -- Custom paint for Imperial theme
        self.Panel.Paint = function(self, w, h)
            -- Background
            draw.RoundedBox(0, 0, 0, w, h, Color(10, 10, 15))
            
            -- Border
            draw.RoundedBox(0, 0, 0, w, 40, Color(50, 50, 60))
            draw.RoundedBox(0, 0, 0, w, 2, Color(100, 150, 255))
            
            -- Title
            draw.SimpleText("IMPERIAL COMMAND TERMINAL", "DermaLarge", w/2, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("ADMINISTRATIVE ACCESS GRANTED", "DermaDefault", w/2, 40, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            
            -- Classification
            draw.SimpleText("CLASSIFIED", "DermaDefaultBold", 10, h - 20, Color(255, 100, 100))
            draw.SimpleText("AUTHORIZED PERSONNEL ONLY", "DermaDefault", w - 10, h - 20, Color(255, 100, 100), TEXT_ALIGN_RIGHT)
        end
        
        -- Close button (styled as power button)
        local closeBtn = vgui.Create("DButton", self.Panel)
        closeBtn:SetPos(self.Panel:GetWide() - 35, 5)
        closeBtn:SetSize(30, 30)
        closeBtn:SetText("")
        
        closeBtn.Paint = function(self, w, h)
            local col = self:IsHovered() and Color(255, 100, 100) or Color(150, 150, 150)
            draw.RoundedBox(15, 0, 0, w, h, col)
            draw.SimpleText("X", "DermaDefaultBold", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        closeBtn.DoClick = function()
            self.Panel:Remove()
        end
        
        -- Tab system
        local sheet = vgui.Create("DPropertySheet", self.Panel)
        sheet:Dock(FILL)
        sheet:DockMargin(10, 50, 10, 30)
        
        -- Custom tab paint
        sheet.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 25))
        end
        
        -- Player Management Tab
        local playerPanel = vgui.Create("DPanel", sheet)
        self:CreatePlayerPanel(playerPanel)
        sheet:AddSheet("Personnel", playerPanel, "icon16/user.png")
        
        -- Admin Management Tab
        local adminPanel = vgui.Create("DPanel", sheet)
        self:CreateAdminPanel(adminPanel)
        sheet:AddSheet("Command Staff", adminPanel, "icon16/shield.png")
        
        -- Server Tools Tab
        local serverPanel = vgui.Create("DPanel", sheet)
        self:CreateServerPanel(serverPanel)
        sheet:AddSheet("Operations", serverPanel, "icon16/server.png")
        
        -- Logs Tab
        local logsPanel = vgui.Create("DPanel", sheet)
        self:CreateLogsPanel(logsPanel)
        sheet:AddSheet("Intelligence", logsPanel, "icon16/book.png")
        
        -- Quick Actions Tab
        local quickPanel = vgui.Create("DPanel", sheet)
        self:CreateQuickPanel(quickPanel)
        sheet:AddSheet("Quick Actions", quickPanel, "icon16/lightning.png")
        
        -- Load initial data
        self:RequestData("players")
        self:RequestData("admins")
        self:RequestData("logs")
        
        -- Update player list every 5 seconds
        timer.Create("KyberAdminUpdate", 5, 0, function()
            if IsValid(self.Panel) then
                self:RequestData("players")
            else
                timer.Remove("KyberAdminUpdate")
            end
        end)
    end
    
    function KYBER.Admin:CreatePlayerPanel(parent)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(15, 15, 20))
        end
        
        -- Search bar
        local searchPanel = vgui.Create("DPanel", parent)
        searchPanel:Dock(TOP)
        searchPanel:SetTall(40)
        searchPanel:DockMargin(10, 10, 10, 10)
        searchPanel.Paint = function() end
        
        local searchEntry = vgui.Create("DTextEntry", searchPanel)
        searchEntry:Dock(LEFT)
        searchEntry:SetWide(300)
        searchEntry:SetPlaceholderText("Search personnel...")
        
        -- Player list
        local playerList = vgui.Create("DListView", parent)
        playerList:Dock(FILL)
        playerList:DockMargin(10, 0, 10, 10)
        playerList:SetMultiSelect(false)
        
        -- Columns
        playerList:AddColumn("Name")
        playerList:AddColumn("SteamID")
        playerList:AddColumn("Health")
        playerList:AddColumn("Faction")
        playerList:AddColumn("Admin Level")
        
        -- Custom paint for dark theme
        playerList.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(25, 25, 30))
        end
        
        -- Context menu
        playerList.OnRowRightClick = function(self, lineID, line)
            local steamID = line:GetValue(2)
            local target = player.GetBySteamID64(steamID)
            
            if IsValid(target) then
                self:OpenPlayerContextMenu(target)
            end
        end
        
        parent.playerList = playerList
        parent.searchEntry = searchEntry
        
        -- Search functionality
        searchEntry.OnValueChange = function(self, value)
            if parent.allPlayers then
                self:FilterPlayers(value)
            end
        end
        
        parent.FilterPlayers = function(self, filter)
            self.playerList:Clear()
            
            for _, plyData in ipairs(self.allPlayers) do
                if filter == "" or 
                   string.find(string.lower(plyData.name), string.lower(filter)) or
                   string.find(string.lower(plyData.faction), string.lower(filter)) then
                    
                    local line = self.playerList:AddLine(
                        plyData.name,
                        plyData.steamID,
                        plyData.health .. "/" .. (plyData.armor or 100),
                        plyData.faction,
                        plyData.adminLevel > 0 and KYBER.Admin.Config.levels[plyData.adminLevel].name or "None"
                    )
                    
                    -- Color code based on admin level
                    if plyData.adminLevel > 0 then
                        local color = KYBER.Admin.Config.levels[plyData.adminLevel].color
                        line:SetTextColor(color)
                    end
                end
            end
        end
    end
    
    function KYBER.Admin:OpenPlayerContextMenu(target)
        local menu = DermaMenu()
        
        -- Basic actions
        menu:AddOption("Goto Player", function()
            self:ExecuteCommand("goto", {target:UserID()})
        end):SetIcon("icon16/user_go.png")
        
        menu:AddOption("Bring Player", function()
            self:ExecuteCommand("bring", {target:UserID()})
        end):SetIcon("icon16/user_add.png")
        
        menu:AddOption("Spectate", function()
            self:ExecuteCommand("spectate", {target:UserID()})
        end):SetIcon("icon16/eye.png")
        
        menu:AddSpacer()
        
        -- Punishment actions
        local punishMenu = menu:AddSubMenu("Disciplinary Actions")
        punishMenu:SetIcon("icon16/exclamation.png")
        
        punishMenu:AddOption("Warn", function()
            Derma_StringRequest("Warning", "Reason for warning:", "",
                function(text)
                    self:ExecuteCommand("warn", {target:UserID(), text})
                end
            )
        end)
        
        punishMenu:AddOption("Kick", function()
            Derma_StringRequest("Kick", "Reason for kick:", "",
                function(text)
                    self:ExecuteCommand("kick", {target:UserID(), text})
                end
            )
        end)
        
        punishMenu:AddOption("Ban", function()
            self:OpenBanDialog(target)
        end)
        
        punishMenu:AddOption("Jail", function()
            Derma_StringRequest("Jail", "Time in minutes:", "5",
                function(text)
                    self:ExecuteCommand("jail", {target:UserID(), tonumber(text) or 5})
                end
            )
        end)
        
        menu:AddSpacer()
        
        -- Character actions
        local charMenu = menu:AddSubMenu("Character Actions")
        charMenu:SetIcon("icon16/user_edit.png")
        
        charMenu:AddOption("Heal", function()
            self:ExecuteCommand("heal", {target:UserID()})
        end)
        
        charMenu:AddOption("Give Credits", function()
            Derma_StringRequest("Credits", "Amount to give:", "1000",
                function(text)
                    self:ExecuteCommand("give_credits", {target:UserID(), tonumber(text) or 1000})
                end
            )
        end)
        
        charMenu:AddOption("Set Faction", function()
            self:OpenFactionDialog(target)
        end)
        
        charMenu:AddOption("Force Rename", function()
            Derma_StringRequest("Rename", "New character name:", target:GetNWString("kyber_name", ""),
                function(text)
                    self:ExecuteCommand("rename", {target:UserID(), text})
                end
            )
        end)
        
        menu:Open()
    end
    
    function KYBER.Admin:CreateAdminPanel(parent)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(15, 15, 20))
        end
        
        -- Add admin section
        local addPanel = vgui.Create("DPanel", parent)
        addPanel:Dock(TOP)
        addPanel:SetTall(100)
        addPanel:DockMargin(10, 10, 10, 10)
        
        addPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(25, 25, 30))
            draw.SimpleText("Add Command Staff", "DermaDefaultBold", 10, 10, Color(255, 255, 255))
        end
        
        local steamEntry = vgui.Create("DTextEntry", addPanel)
        steamEntry:SetPos(10, 35)
        steamEntry:SetSize(200, 25)
        steamEntry:SetPlaceholderText("SteamID64")
        
        local nameEntry = vgui.Create("DTextEntry", addPanel)
        nameEntry:SetPos(220, 35)
        nameEntry:SetSize(150, 25)
        nameEntry:SetPlaceholderText("Name")
        
        local levelSelect = vgui.Create("DComboBox", addPanel)
        levelSelect:SetPos(380, 35)
        levelSelect:SetSize(120, 25)
        levelSelect:SetValue("Select Level")
        
        for level, data in pairs(KYBER.Admin.Config.levels) do
            levelSelect:AddChoice(data.name, level)
        end
        
        local addBtn = vgui.Create("DButton", addPanel)
        addBtn:SetPos(510, 35)
        addBtn:SetSize(100, 25)
        addBtn:SetText("Promote")
        
        addBtn.DoClick = function()
            local steamID = steamEntry:GetValue()
            local name = nameEntry:GetValue()
            local _, level = levelSelect:GetSelected()
            
            if steamID ~= "" and name ~= "" and level then
                self:ExecuteCommand("add_admin", {steamID, name, level})
                steamEntry:SetValue("")
                nameEntry:SetValue("")
                levelSelect:SetValue("Select Level")
            else
                Derma_Message("Please fill in all fields", "Error", "OK")
            end
        end
        
        -- Admin list
        local adminList = vgui.Create("DListView", parent)
        adminList:Dock(FILL)
        adminList:DockMargin(10, 0, 10, 10)
        adminList:SetMultiSelect(false)
        
        adminList:AddColumn("Name")
        adminList:AddColumn("SteamID")
        adminList:AddColumn("Level")
        adminList:AddColumn("Status")
        adminList:AddColumn("Promoted")
        
        adminList.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(25, 25, 30))
        end
        
        -- Context menu for admin management
        adminList.OnRowRightClick = function(self, lineID, line)
            local steamID = line:GetValue(2)
            self:OpenAdminContextMenu(steamID)
        end
        
        parent.adminList = adminList
    end
    
    function KYBER.Admin:OpenAdminContextMenu(steamID)
        if KYBER.Admin.Config.superadmins[steamID] then
            Derma_Message("Cannot modify superadmin", "Access Denied", "OK")
            return
        end
        
        local menu = DermaMenu()
        
        menu:AddOption("Demote", function()
            Derma_Query("Are you sure you want to demote this admin?", "Confirm Demotion",
                "Yes", function()
                    self:ExecuteCommand("remove_admin", {steamID})
                end,
                "No", function() end
            )
        end):SetIcon("icon16/user_delete.png")
        
        menu:AddOption("Change Level", function()
            self:OpenLevelChangeDialog(steamID)
        end):SetIcon("icon16/user_edit.png")
        
        menu:Open()
    end
    
    function KYBER.Admin:CreateServerPanel(parent)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(15, 15, 20))
        end
        
        -- Server info panel
        local infoPanel = vgui.Create("DPanel", parent)
        infoPanel:Dock(TOP)
        infoPanel:SetTall(150)
        infoPanel:DockMargin(10, 10, 10, 10)
        
        infoPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(25, 25, 30))
            draw.SimpleText("Server Status", "DermaDefaultBold", 10, 10, Color(255, 255, 255))
            
            -- Server stats
            local uptime = SysTime()
            local players = #player.GetAll()
            local maxPlayers = game.MaxPlayers()
            
            draw.SimpleText("Uptime: " .. string.FormattedTime(uptime, "%02i:%02i:%02i"), "DermaDefault", 10, 35, Color(200, 200, 200))
            draw.SimpleText("Players: " .. players .. "/" .. maxPlayers, "DermaDefault", 10, 55, Color(200, 200, 200))
            draw.SimpleText("Map: " .. game.GetMap(), "DermaDefault", 10, 75, Color(200, 200, 200))
            draw.SimpleText("Gamemode: Kyber RP", "DermaDefault", 10, 95, Color(200, 200, 200))
            
            -- Performance metrics
            local fps = math.Round(1 / FrameTime())
            draw.SimpleText("Server FPS: " .. fps, "DermaDefault", 200, 35, fps > 60 and Color(100, 255, 100) or Color(255, 100, 100))
        end
        
        -- Quick server actions
        local actionsPanel = vgui.Create("DPanel", parent)
        actionsPanel:Dock(TOP)
        actionsPanel:SetTall(200)
        actionsPanel:DockMargin(10, 0, 10, 10)
        
        actionsPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(25, 25, 30))
            draw.SimpleText("Server Operations", "DermaDefaultBold", 10, 10, Color(255, 255, 255))
        end
        
        -- Create action buttons
        local buttons = {
            {text = "Restart Map", cmd = "restart_map", warning = true},
            {text = "Change Map", cmd = "change_map"},
            {text = "Reload Gamemode", cmd = "reload_gamemode", warning = true},
            {text = "Clean Up Props", cmd = "cleanup_props"},
            {text = "Reset Economy", cmd = "reset_economy", warning = true},
            {text = "Backup Data", cmd = "backup_data"},
        }
        
        local x, y = 10, 40
        for i, btn in ipairs(buttons) do
            local button = vgui.Create("DButton", actionsPanel)
            button:SetPos(x, y)
            button:SetSize(150, 30)
            button:SetText(btn.text)
            
            if btn.warning then
                button.Paint = function(self, w, h)
                    local col = self:IsHovered() and Color(255, 100, 100) or Color(200, 50, 50)
                    draw.RoundedBox(4, 0, 0, w, h, col)
                    draw.SimpleText(self:GetText(), "DermaDefaultBold", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
            
            button.DoClick = function()
                if btn.warning then
                    Derma_Query("Are you sure? This action cannot be undone.", "Confirm Action",
                        "Yes", function()
                            self:ExecuteCommand(btn.cmd, {})
                        end,
                        "No", function() end
                    )
                else
                    self:ExecuteCommand(btn.cmd, {})
                end
            end
            
            x = x + 160
            if x > actionsPanel:GetWide() - 160 then
                x = 10
                y = y + 40
            end
        end
        
        -- Entity cleanup section
        local cleanupPanel = vgui.Create("DPanel", parent)
        cleanupPanel:Dock(FILL)
        cleanupPanel:DockMargin(10, 0, 10, 10)
        
        cleanupPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(25, 25, 30))
            draw.SimpleText("Entity Management", "DermaDefaultBold", 10, 10, Color(255, 255, 255))
            
            -- Entity counts
            local props = #ents.FindByClass("prop_*")
            local npcs = #ents.FindByClass("npc_*")
            local vehicles = #ents.FindByClass("vehicle_*")
            
            draw.SimpleText("Props: " .. props, "DermaDefault", 10, 35, Color(200, 200, 200))
            draw.SimpleText("NPCs: " .. npcs, "DermaDefault", 10, 55, Color(200, 200, 200))
            draw.SimpleText("Vehicles: " .. vehicles, "DermaDefault", 10, 75, Color(200, 200, 200))
        end
    end
    
    function KYBER.Admin:CreateLogsPanel(parent)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(15, 15, 20))
        end
        
        -- Filter controls
        local filterPanel = vgui.Create("DPanel", parent)
        filterPanel:Dock(TOP)
        filterPanel:SetTall(40)
        filterPanel:DockMargin(10, 10, 10, 10)
        filterPanel.Paint = function() end
        
        local filterEntry = vgui.Create("DTextEntry", filterPanel)
        filterEntry:Dock(LEFT)
        filterEntry:SetWide(200)
        filterEntry:SetPlaceholderText("Filter logs...")
        
        local actionFilter = vgui.Create("DComboBox", filterPanel)
        actionFilter:Dock(LEFT)
        actionFilter:SetWide(120)
        actionFilter:DockMargin(10, 0, 0, 0)
        actionFilter:SetValue("All Actions")
        actionFilter:AddChoice("All Actions")
        actionFilter:AddChoice("KICK")
        actionFilter:AddChoice("BAN")
        actionFilter:AddChoice("PROMOTE")
        actionFilter:AddChoice("DEMOTE")
        actionFilter:AddChoice("TELEPORT")
        
        -- Logs list
        local logsList = vgui.Create("DListView", parent)
        logsList:Dock(FILL)
        logsList:DockMargin(10, 0, 10, 10)
        logsList:SetMultiSelect(false)
        
        logsList:AddColumn("Time")
        logsList:AddColumn("Admin")
        logsList:AddColumn("Action")
        logsList:AddColumn("Details")
        logsList:AddColumn("Target")
        
        logsList.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(25, 25, 30))
        end
        
        parent.logsList = logsList
        parent.filterEntry = filterEntry
        parent.actionFilter = actionFilter
        
        -- Filter functionality
        local function applyFilter()
            if parent.allLogs then
                parent:FilterLogs()
            end
        end
        
        filterEntry.OnValueChange = applyFilter
        actionFilter.OnSelect = applyFilter
        
        parent.FilterLogs = function(self)
            self.logsList:Clear()
            
            local textFilter = self.filterEntry:GetValue():lower()
            local actionFilter = self.actionFilter:GetValue()
            
            for _, log in ipairs(self.allLogs) do
                local passTextFilter = textFilter == "" or 
                    string.find(log.admin:lower(), textFilter) or
                    string.find(log.details:lower(), textFilter) or
                    string.find((log.target or ""):lower(), textFilter)
                
                local passActionFilter = actionFilter == "All Actions" or log.action == actionFilter
                
                if passTextFilter and passActionFilter then
                    local timeStr = os.date("%m/%d %H:%M", log.timestamp)
                    local line = self.logsList:AddLine(
                        timeStr,
                        log.admin,
                        log.action,
                        log.details,
                        log.target or ""
                    )
                    
                    -- Color code by action type
                    if log.action == "BAN" or log.action == "KICK" then
                        line:SetTextColor(Color(255, 150, 150))
                    elseif log.action == "PROMOTE" then
                        line:SetTextColor(Color(150, 255, 150))
                    elseif log.action == "DEMOTE" then
                        line:SetTextColor(Color(255, 200, 150))
                    end
                end
            end
        end
    end
    
    function KYBER.Admin:CreateQuickPanel(parent)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(15, 15, 20))
        end
        
        -- Quick actions grid
        local actions = {
            {name = "God Mode", cmd = "god", icon = "icon16/shield.png"},
            {name = "Noclip", cmd = "noclip", icon = "icon16/car.png"},
            {name = "Invisible", cmd = "invisible", icon = "icon16/user_gray.png"},
            {name = "Freeze All", cmd = "freeze_all", icon = "icon16/stop.png"},
            {name = "Unfreeze All", cmd = "unfreeze_all", icon = "icon16/control_play.png"},
            {name = "Heal All", cmd = "heal_all", icon = "icon16/heart.png"},
            {name = "Bring All", cmd = "bring_all", icon = "icon16/group_go.png"},
            {name = "Return All", cmd = "return_all", icon = "icon16/group.png"},
            {name = "Strip Weapons", cmd = "strip_all", icon = "icon16/gun_delete.png"},
            {name = "Give Credits", cmd = "give_all_credits", icon = "icon16/money.png"},
            {name = "Reset Props", cmd = "cleanup_props", icon = "icon16/bin.png"},
            {name = "Emergency Stop", cmd = "emergency_stop", icon = "icon16/exclamation.png"},
        }
        
        local x, y = 20, 20
        for i, action in ipairs(actions) do
            local btn = vgui.Create("DButton", parent)
            btn:SetPos(x, y)
            btn:SetSize(120, 80)
            btn:SetText("")
            
            btn.Paint = function(self, w, h)
                local col = self:IsHovered() and Color(60, 60, 70) or Color(40, 40, 50)
                draw.RoundedBox(8, 0, 0, w, h, col)
                
                -- Icon (placeholder)
                draw.RoundedBox(4, 10, 10, w-20, 40, Color(80, 80, 90))
                
                -- Text
                draw.SimpleText(action.name, "DermaDefault", w/2, h-15, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            btn.DoClick = function()
                if action.cmd == "emergency_stop" then
                    Derma_Query("Emergency stop all players?", "Confirm Emergency Action",
                        "Yes", function()
                            self:ExecuteCommand(action.cmd, {})
                        end,
                        "No", function() end
                    )
                else
                    self:ExecuteCommand(action.cmd, {})
                end
            end
            
            x = x + 130
            if x > parent:GetWide() - 130 then
                x = 20
                y = y + 90
            end
        end
    end
    
    function KYBER.Admin:RequestData(dataType)
        net.Start("Kyber_Admin_RequestData")
        net.WriteString(dataType)
        net.SendToServer()
    end
    
    function KYBER.Admin:ExecuteCommand(command, args)
        net.Start("Kyber_Admin_ExecuteCommand")
        net.WriteString(command)
        net.WriteTable(args)
        net.SendToServer()
    end
    
    function KYBER.Admin:UpdatePanelData(dataType, data)
        if not IsValid(self.Panel) then return end
        
        if dataType == "players" then
            self.Data.players = data
            
            -- Find player panel and update
            local playerPanel = nil
            for _, child in ipairs(self.Panel:GetChildren()) do
                if child.GetActiveTab then
                    for _, tab in ipairs(child:GetItems()) do
                        if tab.Tab:GetText() == "Personnel" then
                            playerPanel = tab.Panel
                            break
                        end
                    end
                end
            end
            
            if playerPanel and playerPanel.playerList then
                playerPanel.allPlayers = data
                playerPanel:FilterPlayers(playerPanel.searchEntry:GetValue())
            end
            
        elseif dataType == "admins" then
            self.Data.admins = data
            
            -- Update admin panel
            local adminPanel = nil
            for _, child in ipairs(self.Panel:GetChildren()) do
                if child.GetActiveTab then
                    for _, tab in ipairs(child:GetItems()) do
                        if tab.Tab:GetText() == "Command Staff" then
                            adminPanel = tab.Panel
                            break
                        end
                    end
                end
            end
            
            if adminPanel and adminPanel.adminList then
                adminPanel.adminList:Clear()
                
                for steamID, adminData in pairs(data) do
                    local status = "Offline"
                    local target = player.GetBySteamID64(steamID)
                    if IsValid(target) then
                        status = "Online"
                    end
                    
                    local promoted = adminData.promoted and os.date("%m/%d/%Y", adminData.promoted) or "Unknown"
                    local levelData = KYBER.Admin.Config.levels[adminData.level]
                    
                    local line = adminPanel.adminList:AddLine(
                        adminData.name,
                        steamID,
                        levelData.name,
                        status,
                        promoted
                    )
                    
                    line:SetTextColor(levelData.color)
                end
            end
            
        elseif dataType == "logs" then
            self.Data.logs = data
            
            -- Update logs panel
            local logsPanel = nil
            for _, child in ipairs(self.Panel:GetChildren()) do
                if child.GetActiveTab then
                    for _, tab in ipairs(child:GetItems()) do
                        if tab.Tab:GetText() == "Intelligence" then
                            logsPanel = tab.Panel
                            break
                        end
                    end
                end
            end
            
            if logsPanel then
                logsPanel.allLogs = data
                logsPanel:FilterLogs()
            end
        end
    end
    
    function KYBER.Admin:OpenBanDialog(target)
        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 300)
        frame:Center()
        frame:SetTitle("Ban Player")
        frame:MakePopup()
        
        local reasonLabel = vgui.Create("DLabel", frame)
        reasonLabel:SetPos(10, 30)
        reasonLabel:SetText("Reason:")
        reasonLabel:SizeToContents()
        
        local reasonEntry = vgui.Create("DTextEntry", frame)
        reasonEntry:SetPos(10, 50)
        reasonEntry:SetSize(380, 25)
        
        local timeLabel = vgui.Create("DLabel", frame)
        timeLabel:SetPos(10, 85)
        timeLabel:SetText("Duration:")
        timeLabel:SizeToContents()
        
        local timeCombo = vgui.Create("DComboBox", frame)
        timeCombo:SetPos(10, 105)
        timeCombo:SetSize(200, 25)
        timeCombo:SetValue("Select Duration")
        timeCombo:AddChoice("5 minutes", 5)
        timeCombo:AddChoice("1 hour", 60)
        timeCombo:AddChoice("24 hours", 1440)
        timeCombo:AddChoice("1 week", 10080)
        timeCombo:AddChoice("1 month", 43200)
        timeCombo:AddChoice("Permanent", 0)
        
        local banBtn = vgui.Create("DButton", frame)
        banBtn:SetPos(10, 250)
        banBtn:SetSize(100, 30)
        banBtn:SetText("Ban Player")
        
        banBtn.DoClick = function()
            local reason = reasonEntry:GetValue()
            local _, duration = timeCombo:GetSelected()
            
            if reason ~= "" and duration then
                self:ExecuteCommand("ban", {target:UserID(), duration, reason})
                frame:Close()
            else
                Derma_Message("Please fill in all fields", "Error", "OK")
            end
        end
        
        local cancelBtn = vgui.Create("DButton", frame)
        cancelBtn:SetPos(120, 250)
        cancelBtn:SetSize(100, 30)
        cancelBtn:SetText("Cancel")
        cancelBtn.DoClick = function()
            frame:Close()
        end
    end
    
    function KYBER.Admin:OpenFactionDialog(target)
        local frame = vgui.Create("DFrame")
        frame:SetSize(300, 200)
        frame:Center()
        frame:SetTitle("Set Faction")
        frame:MakePopup()
        
        local factionCombo = vgui.Create("DComboBox", frame)
        factionCombo:SetPos(10, 30)
        factionCombo:SetSize(280, 25)
        factionCombo:SetValue("Select Faction")
        factionCombo:AddChoice("None", "")
        
        for factionID, faction in pairs(KYBER.Factions or {}) do
            factionCombo:AddChoice(faction.name, factionID)
        end
        
        local setBtn = vgui.Create("DButton", frame)
        setBtn:SetPos(10, 150)
        setBtn:SetSize(100, 30)
        setBtn:SetText("Set Faction")
        
        setBtn.DoClick = function()
            local _, factionID = factionCombo:GetSelected()
            if factionID ~= nil then
                self:ExecuteCommand("set_faction", {target:UserID(), factionID})
                frame:Close()
            end
        end
    end
    
    -- Keybind to open admin panel
    hook.Add("PlayerButtonDown", "KyberAdminKey", function(ply, key)
        if key == KEY_F2 and KYBER.Admin and LocalPlayer():GetNWInt("kyber_admin_level", 0) > 0 then
            KYBER.Admin:OpenPanel()
        end
    end)
    
end