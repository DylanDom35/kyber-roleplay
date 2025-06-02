-- kyber/modules/admin/integration.lua
-- Integration with other Kyber systems and chat enhancements

if SERVER then
    -- Chat system integration
    hook.Add("PlayerSay", "KyberAdminChat", function(ply, text, teamChat)
        local level = KYBER.Admin:GetLevel(ply)
        
        if level > 0 then
            local levelData = KYBER.Admin.Config.levels[level]
            local prefix = levelData.prefix
            
            -- Admin chat (@ prefix)
            if string.sub(text, 1, 1) == "@" and level >= 1 then
                local message = string.sub(text, 2)
                
                -- Send to all admins
                for _, admin in ipairs(player.GetAll()) do
                    if KYBER.Admin:IsAdmin(admin) then
                        admin:ChatPrint("[ADMIN CHAT] " .. ply:Nick() .. ": " .. message)
                    end
                end
                
                KYBER.Admin:LogAction(ply, "ADMIN_CHAT", message)
                return ""
            end
            
            -- Silent admin chat (# prefix) - higher level admins only
            if string.sub(text, 1, 1) == "#" and level >= 3 then
                local message = string.sub(text, 2)
                
                -- Send only to senior admins
                for _, admin in ipairs(player.GetAll()) do
                    if KYBER.Admin:GetLevel(admin) >= 3 then
                        admin:ChatPrint("[SENIOR CHAT] " .. ply:Nick() .. ": " .. message)
                    end
                end
                
                KYBER.Admin:LogAction(ply, "SENIOR_CHAT", message)
                return ""
            end
        end
    end)
    
    -- Death hook for admin protection
    hook.Add("PlayerDeath", "KyberAdminProtection", function(victim, inflictor, attacker)
        if KYBER.Admin:IsAdmin(victim, 2) then
            -- Log admin deaths
            local attackerName = IsValid(attacker) and attacker:IsPlayer() and attacker:Nick() or "Unknown"
            KYBER.Admin:LogAction(victim, "DEATH", "killed by " .. attackerName)
            
            -- Notify other admins
            for _, admin in ipairs(player.GetAll()) do
                if KYBER.Admin:IsAdmin(admin) and admin ~= victim then
                    admin:ChatPrint("[ADMIN] " .. victim:Nick() .. " was killed by " .. attackerName)
                end
            end
        end
    end)
    
    -- Prop protection for admins
    hook.Add("PhysgunPickup", "KyberAdminPhysgun", function(ply, ent)
        if not IsValid(ent) or not ent.Owner then return end
        
        -- Admins can pick up anyone's props
        if KYBER.Admin:IsAdmin(ply, 2) then
            return true
        end
        
        -- Protect admin props from non-admins
        if KYBER.Admin:IsAdmin(ent.Owner, 1) and not KYBER.Admin:IsAdmin(ply) then
            ply:ChatPrint("You cannot manipulate admin-owned props")
            return false
        end
    end)
    
    -- Admin spectator mode enhancements
    hook.Add("PlayerNoClip", "KyberAdminNoclip", function(ply, desiredState)
        if KYBER.Admin:HasPermission(ply, "noclip") then
            return true
        end
        
        return false
    end)
    
    -- Admin damage protection
    hook.Add("EntityTakeDamage", "KyberAdminDamage", function(target, dmginfo)
        if IsValid(target) and target:IsPlayer() then
            local attacker = dmginfo:GetAttacker()
            
            -- Prevent non-admins from hurting admins (optional)
            if KYBER.Admin:IsAdmin(target, 3) and IsValid(attacker) and attacker:IsPlayer() then
                if not KYBER.Admin:IsAdmin(attacker) then
                    attacker:ChatPrint("You cannot damage senior staff members")
                    return true -- Block damage
                end
            end
        end
    end)
    
    -- Integration with reputation system
    hook.Add("Kyber_Admin_PlayerPunished", "AdminReputationPenalty", function(admin, target, punishment)
        if KYBER.Reputation then
            -- Admins get reputation bonus for proper moderation
            local factions = {"republic", "imperial", "rebel"}
            for _, faction in ipairs(factions) do
                KYBER.Reputation:ChangeReputation(admin, faction, 5, "Administrative action")
            end
            
            -- Punished players lose reputation
            if punishment == "ban" or punishment == "kick" then
                for _, faction in ipairs(factions) do
                    KYBER.Reputation:ChangeReputation(target, faction, -50, "Administrative punishment")
                end
            end
        end
    end)
    
    -- Integration with banking system
    hook.Add("Kyber_Admin_CreditsGiven", "AdminBankingLog", function(admin, target, amount)
        if KYBER.Banking then
            -- Log large credit transactions
            if amount > 10000 then
                KYBER.Admin:LogAction(admin, "LARGE_CREDIT_GRANT", 
                    amount .. " credits to " .. target:Nick())
            end
        end
    end)
    
    -- Anti-abuse measures
    local recentActions = {}
    
    hook.Add("Kyber_Admin_Command", "AdminAntiAbuse", function(admin, command, args)
        local steamID = admin:SteamID64()
        local now = CurTime()
        
        -- Track command frequency
        recentActions[steamID] = recentActions[steamID] or {}
        
        -- Clean old actions (last 60 seconds)
        for i = #recentActions[steamID], 1, -1 do
            if now - recentActions[steamID][i].time > 60 then
                table.remove(recentActions[steamID], i)
            end
        end
        
        -- Add current action
        table.insert(recentActions[steamID], {
            command = command,
            time = now
        })
        
        -- Check for spam
        if #recentActions[steamID] > 20 then
            -- Log potential abuse
            KYBER.Admin:LogAction(admin, "POTENTIAL_ABUSE", 
                "Executed " .. #recentActions[steamID] .. " commands in 60 seconds")
            
            -- Notify senior admins
            for _, seniorAdmin in ipairs(player.GetAll()) do
                if KYBER.Admin:GetLevel(seniorAdmin) >= 4 then
                    seniorAdmin:ChatPrint("[WARNING] " .. admin:Nick() .. 
                        " executed many commands rapidly. Check logs.")
                end
            end
        end
    end)
    
    -- Advanced logging integration
    hook.Add("Kyber_Admin_ActionLogged", "AdminAdvancedLogging", function(admin, action, details)
        -- Integration with external logging systems could go here
        
        -- Discord webhook integration (example)
        if action == "BAN" or action == "KICK" then
            -- Send to Discord webhook if configured
            -- This would require HTTP requests module
        end
        
        -- Database logging for serious actions
        if action == "BAN" or action == "PROMOTE" or action == "DEMOTE" then
            -- Log to SQL database if available
        end
    end)
    
else -- CLIENT
    
    -- Admin HUD elements
    hook.Add("HUDPaint", "KyberAdminHUD", function()
        local ply = LocalPlayer()
        local level = ply:GetNWInt("kyber_admin_level", 0)
        
        if level > 0 then
            local levelData = KYBER.Admin.Config.levels[level]
            
            -- Admin status indicator
            draw.SimpleText(levelData.prefix, "DermaDefaultBold", 10, 10, levelData.color)
            
            -- Show player count to admins
            local playerCount = #player.GetAll()
            draw.SimpleText("Players: " .. playerCount .. "/" .. game.MaxPlayers(), 
                          "DermaDefault", 10, 30, Color(255, 255, 255))
            
            -- Show server uptime
            local uptime = string.FormattedTime(SysTime(), "%02i:%02i:%02i")
            draw.SimpleText("Uptime: " .. uptime, "DermaDefault", 10, 50, Color(200, 200, 200))
            
            -- Admin notifications area
            local y = ScrH() - 200
            
            -- Show recent admin actions
            if KYBER.Admin.RecentNotifications then
                for i, notif in ipairs(KYBER.Admin.RecentNotifications) do
                    if CurTime() - notif.time < 10 then -- Show for 10 seconds
                        local alpha = math.min(255, (10 - (CurTime() - notif.time)) * 25.5)
                        draw.SimpleText("[ADMIN] " .. notif.text, "DermaDefault", 
                                      10, y - (i * 20), Color(255, 255, 100, alpha))
                    end
                end
            end
        end
    end)
    
    -- Admin notifications
    KYBER.Admin.RecentNotifications = {}
    
    function KYBER.Admin:AddNotification(text)
        table.insert(self.RecentNotifications, {
            text = text,
            time = CurTime()
        })
        
        -- Keep only last 5 notifications
        if #self.RecentNotifications > 5 then
            table.remove(self.RecentNotifications, 1)
        end
    end
    
    -- Enhanced admin chat
    hook.Add("OnPlayerChat", "KyberAdminChatClient", function(ply, text, teamChat, isDead)
        local level = ply:GetNWInt("kyber_admin_level", 0)
        
        if level > 0 then
            local levelData = KYBER.Admin.Config.levels[level]
            
            -- Add admin prefix to chat
            chat.AddText(
                levelData.color, levelData.prefix .. " ",
                team.GetColor(ply:Team()), ply:Nick(),
                Color(255, 255, 255), ": " .. text
            )
            
            return true -- Override default chat
        end
    end)
    
    -- Spectator enhancements for admins
    hook.Add("CreateMove", "KyberAdminSpectator", function(cmd)
        local ply = LocalPlayer()
        
        if ply:GetObserverMode() != OBS_MODE_NONE and KYBER.Admin:IsAdmin(ply) then
            -- Enhanced spectator controls for admins
            if input.IsKeyDown(KEY_LSHIFT) then
                cmd:SetForwardMove(cmd:GetForwardMove() * 3) -- Fast movement
                cmd:SetSideMove(cmd:GetSideMove() * 3)
            end
        end
    end)
    
    -- Admin-only information display
    hook.Add("HUDDrawTargetID", "KyberAdminTargetID", function()
        local ply = LocalPlayer()
        local level = ply:GetNWInt("kyber_admin_level", 0)
        
        if level > 0 then
            local tr = ply:GetEyeTrace()
            local target = tr.Entity
            
            if IsValid(target) and target:IsPlayer() then
                local x, y = ScrW() / 2, ScrH() / 2 + 50
                
                -- Show additional admin info
                draw.SimpleText("SteamID: " .. target:SteamID64(), "DermaDefault", 
                              x, y + 20, Color(255, 255, 255), TEXT_ALIGN_CENTER)
                
                draw.SimpleText("UserID: " .. target:UserID(), "DermaDefault", 
                              x, y + 35, Color(255, 255, 255), TEXT_ALIGN_CENTER)
                
                local targetLevel = target:GetNWInt("kyber_admin_level", 0)
                if targetLevel > 0 then
                    local targetLevelData = KYBER.Admin.Config.levels[targetLevel]
                    draw.SimpleText("Admin: " .. targetLevelData.name, "DermaDefault", 
                                  x, y + 50, targetLevelData.color, TEXT_ALIGN_CENTER)
                end
                
                -- Show faction info
                local faction = target:GetNWString("kyber_faction", "")
                if faction ~= "" and KYBER.Factions[faction] then
                    draw.SimpleText("Faction: " .. KYBER.Factions[faction].name, "DermaDefault", 
                                  x, y + 65, Color(200, 200, 200), TEXT_ALIGN_CENTER)
                end
            end
        end
    end)
    
    -- Quick admin menu (right-click on players)
    hook.Add("OnContextMenuOpen", "KyberAdminContext", function()
        local ply = LocalPlayer()
        
        if KYBER.Admin:IsAdmin(ply) then
            local tr = ply:GetEyeTrace()
            local target = tr.Entity
            
            if IsValid(target) and target:IsPlayer() and target ~= ply then
                -- Open quick admin context menu
                timer.Simple(0, function()
                    KYBER.Admin:OpenQuickMenu(target)
                end)
            end
        end
    end)
    
    function KYBER.Admin:OpenQuickMenu(target)
        local menu = DermaMenu()
        menu:SetMinimumWidth(200)
        
        -- Header
        local header = menu:AddOption(target:Nick())
        header:SetTextColor(Color(255, 255, 100))
        header:SetIcon("icon16/user.png")
        
        menu:AddSpacer()
        
        -- Quick actions
        if self:HasPermission(LocalPlayer(), "tp_to_player") then
            menu:AddOption("Goto", function()
                self:ExecuteCommand("goto", {target:UserID()})
            end):SetIcon("icon16/user_go.png")
        end
        
        if self:HasPermission(LocalPlayer(), "bring") then
            menu:AddOption("Bring", function()
                self:ExecuteCommand("bring", {target:UserID()})
            end):SetIcon("icon16/user_add.png")
        end
        
        if self:HasPermission(LocalPlayer(), "spectate") then
            menu:AddOption("Spectate", function()
                self:ExecuteCommand("spectate", {target:UserID()})
            end):SetIcon("icon16/eye.png")
        end
        
        if self:HasPermission(LocalPlayer(), "heal") then
            menu:AddOption("Heal", function()
                self:ExecuteCommand("heal", {target:UserID()})
            end):SetIcon("icon16/heart.png")
        end
        
        menu:AddSpacer()
        
        -- Punishment submenu
        if self:HasPermission(LocalPlayer(), "warn") then
            local punishMenu = menu:AddSubMenu("Punish")
            punishMenu:SetIcon("icon16/exclamation.png")
            
            punishMenu:AddOption("Warn", function()
                Derma_StringRequest("Warning", "Reason:", "",
                    function(text)
                        self:ExecuteCommand("warn", {target:UserID(), text})
                    end
                )
            end)
            
            if self:HasPermission(LocalPlayer(), "kick") then
                punishMenu:AddOption("Kick", function()
                    Derma_StringRequest("Kick", "Reason:", "",
                        function(text)
                            self:ExecuteCommand("kick", {target:UserID(), text})
                        end
                    )
                end)
            end
            
            if self:HasPermission(LocalPlayer(), "freeze") then
                punishMenu:AddOption("Freeze", function()
                    self:ExecuteCommand("freeze", {target:UserID()})
                end)
            end
        end
        
        -- Character management submenu
        if self:HasPermission(LocalPlayer(), "give_credits") then
            local charMenu = menu:AddSubMenu("Character")
            charMenu:SetIcon("icon16/user_edit.png")
            
            charMenu:AddOption("Give Credits", function()
                Derma_StringRequest("Credits", "Amount:", "1000",
                    function(text)
                        local amount = tonumber(text)
                        if amount then
                            self:ExecuteCommand("give_credits", {target:UserID(), amount})
                        end
                    end
                )
            end)
            
            if self:HasPermission(LocalPlayer(), "manage_factions") then
                charMenu:AddOption("Set Faction", function()
                    local factionFrame = vgui.Create("DFrame")
                    factionFrame:SetSize(300, 200)
                    factionFrame:Center()
                    factionFrame:SetTitle("Set Faction")
                    factionFrame:MakePopup()
                    
                    local combo = vgui.Create("DComboBox", factionFrame)
                    combo:SetPos(10, 30)
                    combo:SetSize(280, 25)
                    combo:SetValue("Select Faction")
                    combo:AddChoice("None", "")
                    
                    for factionID, faction in pairs(KYBER.Factions or {}) do
                        combo:AddChoice(faction.name, factionID)
                    end
                    
                    local setBtn = vgui.Create("DButton", factionFrame)
                    setBtn:SetPos(10, 150)
                    setBtn:SetSize(100, 30)
                    setBtn:SetText("Set")
                    setBtn.DoClick = function()
                        local _, factionID = combo:GetSelected()
                        if factionID ~= nil then
                            self:ExecuteCommand("set_faction", {target:UserID(), factionID})
                            factionFrame:Close()
                        end
                    end
                end)
            end
        end
        
        menu:Open()
    end
    
    -- Admin keybinds
    hook.Add("PlayerButtonDown", "KyberAdminKeybinds", function(ply, key)
        if ply ~= LocalPlayer() or not KYBER.Admin:IsAdmin(ply) then return end
        
        -- F1 - Quick admin help
        if key == KEY_F1 then
            KYBER.Admin:ShowQuickHelp()
        end
        
        -- F3 - Quick player list
        if key == KEY_F3 then
            KYBER.Admin:ShowQuickPlayerList()
        end
        
        -- Delete - Remove targeted entity (for cleanup)
        if key == KEY_DELETE and KYBER.Admin:HasPermission(ply, "spawn_props") then
            local tr = ply:GetEyeTrace()
            if IsValid(tr.Entity) and not tr.Entity:IsPlayer() then
                SafeRemoveEntity(tr.Entity)
                KYBER.Admin:AddNotification("Removed " .. tr.Entity:GetClass())
            end
        end
    end)
    
    function KYBER.Admin:ShowQuickHelp()
        local frame = vgui.Create("DFrame")
        frame:SetSize(500, 400)
        frame:Center()
        frame:SetTitle("Admin Quick Help")
        frame:MakePopup()
        
        local scroll = vgui.Create("DRichText", frame)
        scroll:Dock(FILL)
        scroll:DockMargin(10, 10, 10, 10)
        
        scroll:AppendText("Kyber Admin Quick Reference\n\n")
        
        scroll:SetFontInternal("DermaDefaultBold")
        scroll:AppendText("Keybinds:\n")
        scroll:SetFontInternal("DermaDefault")
        scroll:AppendText("F1 - This help menu\n")
        scroll:AppendText("F2 - Full admin panel\n")
        scroll:AppendText("F3 - Quick player list\n")
        scroll:AppendText("Delete - Remove targeted entity\n\n")
        
        scroll:SetFontInternal("DermaDefaultBold")
        scroll:AppendText("Chat Commands:\n")
        scroll:SetFontInternal("DermaDefault")
        scroll:AppendText("@ - Admin chat\n")
        scroll:AppendText("# - Senior admin chat\n")
        scroll:AppendText("! - Command prefix\n\n")
        
        scroll:SetFontInternal("DermaDefaultBold")
        scroll:AppendText("Quick Actions:\n")
        scroll:SetFontInternal("DermaDefault")
        scroll:AppendText("Right-click players for quick menu\n")
        scroll:AppendText("Look at player + Delete to quick-kick\n")
    end
    
    function KYBER.Admin:ShowQuickPlayerList()
        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 500)
        frame:SetPos(20, 20)
        frame:SetTitle("Quick Player List")
        frame:MakePopup()
        
        local list = vgui.Create("DListView", frame)
        list:Dock(FILL)
        list:DockMargin(10, 10, 10, 10)
        list:AddColumn("Name")
        list:AddColumn("Health")
        list:AddColumn("Faction")
        
        for _, ply in ipairs(player.GetAll()) do
            local line = list:AddLine(
                ply:Nick(),
                ply:Health() .. "/" .. ply:GetMaxHealth(),
                ply:GetNWString("kyber_faction", "None")
            )
            
            local adminLevel = ply:GetNWInt("kyber_admin_level", 0)
            if adminLevel > 0 then
                line:SetTextColor(KYBER.Admin.Config.levels[adminLevel].color)
            end
        end
        
        list.OnRowRightClick = function(self, lineID, line)
            local playerName = line:GetValue(1)
            local target = nil
            
            for _, ply in ipairs(player.GetAll()) do
                if ply:Nick() == playerName then
                    target = ply
                    break
                end
            end
            
            if IsValid(target) then
                KYBER.Admin:OpenQuickMenu(target)
            end
        end
    end
    
    -- Admin status on scoreboard
    hook.Add("ScoreboardShow", "KyberAdminScoreboard", function()
        -- Custom scoreboard would show admin status here
        return false -- Let default scoreboard show for now
    end)
    
    -- Enhanced chat for admins
    hook.Add("ChatText", "KyberAdminChatEnhancement", function(index, name, text, type)
        local ply = player.GetByID(index)
        
        if IsValid(ply) then
            local level = ply:GetNWInt("kyber_admin_level", 0)
            
            if level > 0 and LocalPlayer():GetNWInt("kyber_admin_level", 0) > 0 then
                -- Show admin info in chat for other admins
                local levelData = KYBER.Admin.Config.levels[level]
                
                if type == "all" then
                    chat.AddText(
                        levelData.color, levelData.prefix .. " ",
                        team.GetColor(ply:Team()), name,
                        Color(255, 255, 255), ": ",
                        Color(255, 255, 255), text
                    )
                    return true
                end
            end
        end
    end)
    
    -- Admin notifications for joins/leaves
    net.Receive("Kyber_Admin_PlayerEvent", function()
        local eventType = net.ReadString()
        local playerName = net.ReadString()
        local steamID = net.ReadString()
        
        if LocalPlayer():GetNWInt("kyber_admin_level", 0) > 0 then
            local color = eventType == "join" and Color(100, 255, 100) or Color(255, 100, 100)
            local action = eventType == "join" and "connected" or "disconnected"
            
            chat.AddText(
                Color(255, 255, 100), "[ADMIN] ",
                color, playerName,
                Color(255, 255, 255), " " .. action .. " (",
                Color(200, 200, 200), steamID,
                Color(255, 255, 255), ")"
            )
        end
    end)
    
end

-- Shared admin utilities
function KYBER.Admin:IsAdmin(ply, level)
    if CLIENT then
        return ply:GetNWInt("kyber_admin_level", 0) >= (level or 1)
    else
        if not IsValid(ply) then return false end
        
        local steamID = ply:SteamID64()
        local adminData = self.Admins[steamID]
        
        if not adminData then return false end
        
        level = level or 1
        return adminData.level >= level
    end
end

function KYBER.Admin:HasPermission(ply, permission)
    if CLIENT then
        -- Basic client-side check
        local level = ply:GetNWInt("kyber_admin_level", 0)
        local reqLevel = self.Config.permissions[permission]
        return reqLevel and level >= reqLevel
    else
        if not IsValid(ply) then return false end
        
        local level = self:GetLevel(ply)
        if level == 0 then return false end
        
        -- Superadmins have all permissions
        if level >= 5 then return true end
        
        local reqLevel = self.Config.permissions[permission]
        return reqLevel and level >= reqLevel
    end
end

-- Network admin events to clients
if SERVER then
    util.AddNetworkString("Kyber_Admin_PlayerEvent")
    
    hook.Add("PlayerConnect", "KyberAdminConnect", function(name, ip)
        timer.Simple(1, function()
            net.Start("Kyber_Admin_PlayerEvent")
            net.WriteString("join")
            net.WriteString(name)
            net.WriteString(ip)
            
            -- Send to all admins
            for _, admin in ipairs(player.GetAll()) do
                if KYBER.Admin:IsAdmin(admin) then
                    net.Send(admin)
                end
            end
        end)
    end)
    
    hook.Add("PlayerDisconnected", "KyberAdminDisconnect", function(ply)
        net.Start("Kyber_Admin_PlayerEvent")
        net.WriteString("leave")
        net.WriteString(ply:Nick())
        net.WriteString(ply:SteamID64())
        
        -- Send to all admins
        for _, admin in ipairs(player.GetAll()) do
            if KYBER.Admin:IsAdmin(admin) then
                net.Send(admin)
            end
        end
    end)
end

print("[Kyber Admin] Integration loaded")