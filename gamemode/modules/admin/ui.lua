-- kyber/modules/admin/ui.lua
KYBER.Admin = KYBER.Admin or {}

if CLIENT then
    -- Network strings
    net.Receive("Kyber_Admin_OpenPanel", function()
        KYBER.Admin:OpenPanel()
    end)

    net.Receive("Kyber_Admin_UpdateData", function()
        local dataType = net.ReadString()
        local data = net.ReadTable()
        KYBER.Admin:UpdatePanelData(dataType, data)
    end)

    -- Create main admin panel
    function KYBER.Admin:OpenPanel()
        if IsValid(self.Panel) then
            self.Panel:Remove()
        end

        local frame = vgui.Create("DFrame")
        frame:SetSize(ScrW() * 0.8, ScrH() * 0.8)
        frame:Center()
        frame:SetTitle("Kyber Administration Panel")
        frame:SetDeleteOnClose(true)
        frame:MakePopup()
        frame:SetSizable(true)

        self.Panel = frame
        self.Data = {}

        -- Custom paint for dark theme
        frame.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 25))
            draw.RoundedBox(8, 2, 2, w-4, h-4, Color(30, 30, 35))
        end

        -- Create property sheet
        local sheet = vgui.Create("DPropertySheet", frame)
        sheet:Dock(FILL)
        sheet:DockMargin(10, 30, 10, 10)

        -- Custom paint for property sheet
        sheet.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 20, w, h-20, Color(15, 15, 20))
        end

        -- Create tabs
        self:CreatePersonnelTab(sheet)
        self:CreateAdminTab(sheet)
        self:CreateServerTab(sheet)
        self:CreateLogsTab(sheet)
        self:CreateQuickActionsTab(sheet)

        -- Request initial data
        self:RequestData("players")
        self:RequestData("admins")
        self:RequestData("logs")
    end

    function KYBER.Admin:CreatePersonnelTab(sheet)
        local panel = vgui.Create("DPanel")
        panel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(15, 15, 20))
        end

        -- Search bar
        local searchLabel = vgui.Create("DLabel", panel)
        searchLabel:SetPos(10, 10)
        searchLabel:SetSize(100, 20)
        searchLabel:SetText("Search Players:")
        searchLabel:SetTextColor(Color(255, 255, 255))

        local searchEntry = vgui.Create("DTextEntry", panel)
        searchEntry:SetPos(110, 10)
        searchEntry:SetSize(200, 25)
        searchEntry.OnChange = function()
            panel:FilterPlayers(searchEntry:GetValue())
        end
        panel.searchEntry = searchEntry

        -- Filter options
        local factionFilter = vgui.Create("DComboBox", panel)
        factionFilter:SetPos(320, 10)
        factionFilter:SetSize(150, 25)
        factionFilter:SetValue("All Factions")
        factionFilter:AddChoice("All Factions")
        
        -- Add faction options if available
        if KYBER.Factions then
            for id, faction in pairs(KYBER.Factions) do
                factionFilter:AddChoice(faction.name, id)
            end
        end

        -- Player list
        local playerList = vgui.Create("DListView", panel)
        playerList:SetPos(10, 50)
        playerList:SetSize(panel:GetWide() - 20, panel:GetTall() - 60)
        playerList:AddColumn("Name")
        playerList:AddColumn("SteamID")
        playerList:AddColumn("Health")
        playerList:AddColumn("Faction")
        playerList:AddColumn("Admin Level")

        panel.playerList = playerList

        -- Context menu for players
        playerList.OnRowRightClick = function(lst, index, line)
            local steamID = line:GetColumnText(2)
            local target = nil
            for _, ply in ipairs(player.GetAll()) do
                if ply:SteamID64() == steamID then
                    target = ply
                    break
                end
            end
            
            if target then
                self:OpenPlayerContextMenu(target)
            end
        end

        -- Filter function
        panel.FilterPlayers = function(self, searchText)
            playerList:Clear()
            
            local allPlayers = KYBER.Admin.Data.players or {}
            for _, plyData in ipairs(allPlayers) do
                local matchesSearch = searchText == "" or 
                    string.find(plyData.name:lower(), searchText:lower()) or
                    string.find(plyData.steamID:lower(), searchText:lower())
                
                if matchesSearch then
                    local line = playerList:AddLine(
                        plyData.name,
                        plyData.steamID,
                        plyData.health .. "/" .. (plyData.maxHealth or 100),
                        plyData.faction or "None",
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

        sheet:AddSheet("Personnel", panel, "icon16/group.png")
    end

    function KYBER.Admin:CreateAdminTab(sheet)
        local panel = vgui.Create("DPanel")
        panel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(15, 15, 20))
        end

        -- Admin list
        local adminList = vgui.Create("DListView", panel)
        adminList:SetPos(10, 10)
        adminList:SetSize(panel:GetWide() - 20, panel:GetTall() - 100)
        adminList:AddColumn("Name")
        adminList:AddColumn("SteamID")
        adminList:AddColumn("Level")
        adminList:AddColumn("Status")

        panel.adminList = adminList

        -- Context menu for admins
        adminList.OnRowRightClick = function(lst, index, line)
            local steamID = line:GetColumnText(2)
            self:OpenAdminContextMenu(steamID)
        end

        -- Add admin button
        local addBtn = vgui.Create("DButton", panel)
        addBtn:SetPos(10, panel:GetTall() - 80)
        addBtn:SetSize(100, 30)
        addBtn:SetText("Add Admin")
        addBtn.DoClick = function()
            self:OpenAddAdminDialog()
        end

        -- Promote button
        local promoteBtn = vgui.Create("DButton", panel)
        promoteBtn:SetPos(120, panel:GetTall() - 80)
        promoteBtn:SetSize(100, 30)
        promoteBtn:SetText("Promote")
        promoteBtn.DoClick = function()
            local selected = adminList:GetSelectedLine()
            if selected then
                local steamID = adminList:GetLine(selected):GetColumnText(2)
                self:OpenPromoteDialog(steamID)
            end
        end

        sheet:AddSheet("Administration", panel, "icon16/shield.png")
    end

    function KYBER.Admin:CreateServerTab(sheet)
        local panel = vgui.Create("DPanel")
        self:CreateServerPanel(panel)
        sheet:AddSheet("Server", panel, "icon16/server.png")
    end

    function KYBER.Admin:CreateLogsTab(sheet)
        local panel = vgui.Create("DPanel")
        panel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(15, 15, 20))
        end

        -- Filter controls
        local filterPanel = vgui.Create("DPanel", panel)
        filterPanel:SetPos(10, 10)
        filterPanel:SetSize(panel:GetWide() - 20, 40)
        filterPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(25, 25, 30))
        end

        -- Text filter
        local textFilter = vgui.Create("DTextEntry", filterPanel)
        textFilter:SetPos(10, 10)
        textFilter:SetSize(200, 20)
        textFilter:SetPlaceholderText("Search logs...")
        panel.textFilter = textFilter

        -- Action filter
        local actionFilter = vgui.Create("DComboBox", filterPanel)
        actionFilter:SetPos(220, 10)
        actionFilter:SetSize(150, 20)
        actionFilter:SetValue("All Actions")
        actionFilter:AddChoice("All Actions")
        actionFilter:AddChoice("BAN")
        actionFilter:AddChoice("KICK")
        actionFilter:AddChoice("WARN")
        actionFilter:AddChoice("PROMOTE")
        actionFilter:AddChoice("DEMOTE")
        panel.actionFilter = actionFilter

        -- Refresh button
        local refreshBtn = vgui.Create("DButton", filterPanel)
        refreshBtn:SetPos(380, 8)
        refreshBtn:SetSize(80, 24)
        refreshBtn:SetText("Refresh")
        refreshBtn.DoClick = function()
            panel:FilterLogs()
        end

        -- Logs list
        local logsList = vgui.Create("DListView", panel)
        logsList:SetPos(10, 60)
        logsList:SetSize(panel:GetWide() - 20, panel:GetTall() - 70)
        logsList:AddColumn("Time")
        logsList:AddColumn("Admin")
        logsList:AddColumn("Action")
        logsList:AddColumn("Details")
        logsList:AddColumn("Target")

        panel.logsList = logsList

        -- Filter function
        panel.FilterLogs = function(self)
            logsList:Clear()
            
            local textFilter = self.textFilter:GetValue():lower()
            local actionFilter = self.actionFilter:GetValue()
            
            for _, log in ipairs(self.allLogs or {}) do
                local passTextFilter = textFilter == "" or 
                    string.find(log.admin:lower(), textFilter) or
                    string.find(log.details:lower(), textFilter) or
                    string.find((log.target or ""):lower(), textFilter)
                
                local passActionFilter = actionFilter == "All Actions" or log.action == actionFilter
                
                if passTextFilter and passActionFilter then
                    local timeStr = os.date("%m/%d %H:%M", log.timestamp)
                    local line = logsList:AddLine(
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

        sheet:AddSheet("Logs", panel, "icon16/script.png")
    end

    function KYBER.Admin:CreateQuickActionsTab(sheet)
        local panel = vgui.Create("DPanel")
        self:CreateQuickPanel(panel)
        sheet:AddSheet("Quick Actions", panel, "icon16/lightning.png")
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

        menu:Open()
    end

    function KYBER.Admin:OpenBanDialog(target)
        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 300)
        frame:Center()
        frame:SetTitle("Ban Player: " .. target:Nick())
        frame:MakePopup()

        -- Reason
        local reasonLabel = vgui.Create("DLabel", frame)
        reasonLabel:SetPos(10, 30)
        reasonLabel:SetSize(100, 20)
        reasonLabel:SetText("Reason:")

        local reasonEntry = vgui.Create("DTextEntry", frame)
        reasonEntry:SetPos(10, 50)
        reasonEntry:SetSize(380, 100)
        reasonEntry:SetMultiline(true)

        -- Duration
        local durationLabel = vgui.Create("DLabel", frame)
        durationLabel:SetPos(10, 160)
        durationLabel:SetSize(100, 20)
        durationLabel:SetText("Duration:")

        local durationCombo = vgui.Create("DComboBox", frame)
        durationCombo:SetPos(10, 180)
        durationCombo:SetSize(200, 25)
        durationCombo:SetValue("Permanent")
        durationCombo:AddChoice("Permanent", 0)
        durationCombo:AddChoice("1 Hour", 3600)
        durationCombo:AddChoice("1 Day", 86400)
        durationCombo:AddChoice("1 Week", 604800)
        durationCombo:AddChoice("1 Month", 2592000)

        -- Buttons
        local banBtn = vgui.Create("DButton", frame)
        banBtn:SetPos(10, 220)
        banBtn:SetSize(100, 30)
        banBtn:SetText("Ban")
        banBtn.DoClick = function()
            local reason = reasonEntry:GetValue()
            local _, duration = durationCombo:GetSelected()
            
            if reason == "" then
                reason = "No reason specified"
            end
            
            self:ExecuteCommand("ban", {target:UserID(), reason, duration or 0})
            frame:Close()
        end

        local cancelBtn = vgui.Create("DButton", frame)
        cancelBtn:SetPos(120, 220)
        cancelBtn:SetSize(100, 30)
        cancelBtn:SetText("Cancel")
        cancelBtn.DoClick = function()
            frame:Close()
        end
    end

    function KYBER.Admin:OpenAdminContextMenu(steamID)
        local menu = DermaMenu()
        
        menu:AddOption("View Profile", function()
            gui.OpenURL("https://steamcommunity.com/profiles/" .. steamID)
        end):SetIcon("icon16/user.png")
        
        menu:AddSpacer()
        
        menu:AddOption("Demote", function()
            Derma_Query("Remove admin privileges from this user?",
                "Confirm Demotion",
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
                    Derma_Query("Are you sure? This action cannot be undone.",
                        "Confirm Action",
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
            
        elseif dataType == "logs" then
            self.Data.logs = data
            -- Update logs panel
        end
    end

end