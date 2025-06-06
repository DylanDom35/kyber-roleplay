-- kyber/modules/admin/integration.lua
KYBER.Admin = KYBER.Admin or {}

if CLIENT then
    -- Scoreboard integration
    hook.Add("ScoreboardPlayerRightClick", "KyberAdminScoreboard", function(ply)
        if LocalPlayer():GetNWInt("kyber_admin_level", 0) == 0 then return end
        
        local menu = DermaMenu()
        
        -- Player info
        menu:AddOption("View Profile", function()
            gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
        end):SetIcon("icon16/user.png")
        
        menu:AddSpacer()
        
        -- Quick actions
        if KYBER.Admin:HasPermission(LocalPlayer(), "tp_to_player") then
            menu:AddOption("Goto", function()
                KYBER.Admin:ExecuteCommand("goto", {ply:UserID()})
            end):SetIcon("icon16/user_go.png")
        end
        
        if KYBER.Admin:HasPermission(LocalPlayer(), "bring") then
            menu:AddOption("Bring", function()
                KYBER.Admin:ExecuteCommand("bring", {ply:UserID()})
            end):SetIcon("icon16/user_add.png")
        end
        
        if KYBER.Admin:HasPermission(LocalPlayer(), "spectate") then
            menu:AddOption("Spectate", function()
                KYBER.Admin:ExecuteCommand("spectate", {ply:UserID()})
            end):SetIcon("icon16/eye.png")
        end
        
        if KYBER.Admin:HasPermission(LocalPlayer(), "heal") then
            menu:AddOption("Heal", function()
                KYBER.Admin:ExecuteCommand("heal", {ply:UserID()})
            end):SetIcon("icon16/heart.png")
        end
        
        menu:AddSpacer()
        
        -- Punishment submenu
        if KYBER.Admin:HasPermission(LocalPlayer(), "warn") then
            local punishMenu = menu:AddSubMenu("Punish")
            punishMenu:SetIcon("icon16/exclamation.png")
            
            punishMenu:AddOption("Warn", function()
                Derma_StringRequest("Warning", "Reason:", "",
                    function(text)
                        KYBER.Admin:ExecuteCommand("warn", {ply:UserID(), text})
                    end
                )
            end)
            
            if KYBER.Admin:HasPermission(LocalPlayer(), "kick") then
                punishMenu:AddOption("Kick", function()
                    Derma_StringRequest("Kick", "Reason:", "",
                        function(text)
                            KYBER.Admin:ExecuteCommand("kick", {ply:UserID(), text})
                        end
                    )
                end)
            end
            
            if KYBER.Admin:HasPermission(LocalPlayer(), "freeze") then
                punishMenu:AddOption("Freeze", function()
                    KYBER.Admin:ExecuteCommand("freeze", {ply:UserID()})
                end)
            end
            
            if KYBER.Admin:HasPermission(LocalPlayer(), "jail") then
                punishMenu:AddOption("Jail", function()
                    Derma_StringRequest("Jail Time", "Minutes:", "5",
                        function(text)
                            local time = tonumber(text) or 5
                            KYBER.Admin:ExecuteCommand("jail", {ply:UserID(), time})
                        end
                    )
                end)
            end
            
            if KYBER.Admin:HasPermission(LocalPlayer(), "ban") then
                punishMenu:AddOption("Ban", function()
                    KYBER.Admin:OpenBanDialog(ply)
                end)
            end
        end
        
        -- Character management submenu
        if KYBER.Admin:HasPermission(LocalPlayer(), "give_credits") then
            local charMenu = menu:AddSubMenu("Character")
            charMenu:SetIcon("icon16/user_edit.png")
            
            charMenu:AddOption("Give Credits", function()
                Derma_StringRequest("Credits", "Amount:", "1000",
                    function(text)
                        local amount = tonumber(text)
                        if amount then
                            KYBER.Admin:ExecuteCommand("give_credits", {ply:UserID(), amount})
                        end
                    end
                )
            end)
            
            if KYBER.Admin:HasPermission(LocalPlayer(), "manage_factions") then
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
                            KYBER.Admin:ExecuteCommand("set_faction", {ply:UserID(), factionID})
                            factionFrame:Close()
                        end
                    end
                    
                    local cancelBtn = vgui.Create("DButton", factionFrame)
                    cancelBtn:SetPos(120, 150)
                    cancelBtn:SetSize(100, 30)
                    cancelBtn:SetText("Cancel")
                    cancelBtn.DoClick = function()
                        factionFrame:Close()
                    end
                end)
            end
            
            if KYBER.Admin:HasPermission(LocalPlayer(), "edit_characters") then
                charMenu:AddOption("Edit Character", function()
                    -- Open character editor
                    if KYBER.Character and KYBER.Character.OpenEditor then
                        KYBER.Character:OpenEditor(ply)
                    else
                        LocalPlayer():ChatPrint("Character editor not available")
                    end
                end)
            end
        end
        
        -- Admin management (for high-level admins)
        if KYBER.Admin:HasPermission(LocalPlayer(), "promote_admin") then
            local adminMenu = menu:AddSubMenu("Admin")
            adminMenu:SetIcon("icon16/shield.png")
            
            local currentLevel = ply:GetNWInt("kyber_admin_level", 0)
            
            if currentLevel == 0 then
                adminMenu:AddOption("Promote to Moderator", function()
                    Derma_Query("Promote " .. ply:Nick() .. " to Moderator?",
                        "Confirm Promotion",
                        "Yes", function()
                            KYBER.Admin:ExecuteCommand("promote_admin", {ply:SteamID64(), 1})
                        end,
                        "No", function() end
                    )
                end)
            else
                adminMenu:AddOption("Demote", function()
                    Derma_Query("Remove admin privileges from " .. ply:Nick() .. "?",
                        "Confirm Demotion",
                        "Yes", function()
                            KYBER.Admin:ExecuteCommand("demote_admin", {ply:SteamID64()})
                        end,
                        "No", function() end
                    )
                end)
                
                if currentLevel < 4 then -- Can't promote superadmins
                    adminMenu:AddOption("Promote", function()
                        local frame = vgui.Create("DFrame")
                        frame:SetSize(300, 150)
                        frame:Center()
                        frame:SetTitle("Promote " .. ply:Nick())
                        frame:MakePopup()
                        
                        local combo = vgui.Create("DComboBox", frame)
                        combo:SetPos(10, 30)
                        combo:SetSize(280, 25)
                        combo:SetValue("Select Level")
                        
                        for level = currentLevel + 1, 4 do
                            local config = KYBER.Admin.Config.levels[level]
                            if config then
                                combo:AddChoice(config.name, level)
                            end
                        end
                        
                        local promoteBtn = vgui.Create("DButton", frame)
                        promoteBtn:SetPos(10, 70)
                        promoteBtn:SetSize(100, 30)
                        promoteBtn:SetText("Promote")
                        promoteBtn.DoClick = function()
                            local _, level = combo:GetSelected()
                            if level then
                                KYBER.Admin:ExecuteCommand("promote_admin", {ply:SteamID64(), level})
                                frame:Close()
                            end
                        end
                        
                        local cancelBtn = vgui.Create("DButton", frame)
                        cancelBtn:SetPos(120, 70)
                        cancelBtn:SetSize(100, 30)
                        cancelBtn:SetText("Cancel")
                        cancelBtn.DoClick = function()
                            frame:Close()
                        end
                    end)
                end
            end
        end
        
        menu:Open()
    end)
    
    -- Context menu integration
    hook.Add("OnContextMenuOpen", "KyberAdminContext", function()
        if LocalPlayer():GetNWInt("kyber_admin_level", 0) == 0 then return end
        
        -- Add admin tools to context menu
        local trace = LocalPlayer():GetEyeTrace()
        if IsValid(trace.Entity) then
            local ent = trace.Entity
            
            -- Entity management options
            if ent:IsPlayer() then
                -- Player options already handled in scoreboard
                return
            elseif ent:GetClass() == "prop_physics" then
                -- Prop management
                local menu = DermaMenu()
                
                menu:AddOption("Remove Prop", function()
                    KYBER.Admin:ExecuteCommand("remove_entity", {ent:EntIndex()})
                end):SetIcon("icon16/delete.png")
                
                if KYBER.Admin:HasPermission(LocalPlayer(), "spawn_props") then
                    menu:AddOption("Freeze Prop", function()
                        KYBER.Admin:ExecuteCommand("freeze_prop", {ent:EntIndex()})
                    end):SetIcon("icon16/stop.png")
                    
                    menu:AddOption("Copy Prop", function()
                        KYBER.Admin:ExecuteCommand("copy_prop", {ent:EntIndex()})
                    end):SetIcon("icon16/page_copy.png")
                end
                
                menu:Open()
            end
        end
    end)
    
    -- Chat command integration
    hook.Add("OnPlayerChat", "KyberAdminChatCommands", function(ply, text, teamChat, dead)
        if not IsValid(ply) or ply ~= LocalPlayer() then return end
        if not string.StartWith(text, "/") then return end
        
        local adminLevel = ply:GetNWInt("kyber_admin_level", 0)
        if adminLevel == 0 then return end
        
        local args = string.Explode(" ", text)
        local cmd = string.sub(args[1], 2) -- Remove /
        
        -- Quick admin commands
        if cmd == "admin" or cmd == "panel" then
            net.Start("Kyber_Admin_OpenPanel")
            net.SendToServer()
            return true
        elseif cmd == "goto" and #args >= 2 then
            local target = nil
            for _, p in ipairs(player.GetAll()) do
                if string.find(p:Nick():lower(), args[2]:lower()) then
                    target = p
                    break
                end
            end
            if target then
                KYBER.Admin:ExecuteCommand("goto", {target:UserID()})
            else
                ply:ChatPrint("Player not found")
            end
            return true
        elseif cmd == "bring" and #args >= 2 then
            local target = nil
            for _, p in ipairs(player.GetAll()) do
                if string.find(p:Nick():lower(), args[2]:lower()) then
                    target = p
                    break
                end
            end
            if target then
                KYBER.Admin:ExecuteCommand("bring", {target:UserID()})
            else
                ply:ChatPrint("Player not found")
            end
            return true
        elseif cmd == "noclip" then
            KYBER.Admin:ExecuteCommand("noclip", {})
            return true
        elseif cmd == "god" then
            KYBER.Admin:ExecuteCommand("god", {})
            return true
        end
    end)
    
    -- Notification system integration
    hook.Add("HUDPaint", "KyberAdminNotifications", function()
        if not KYBER.Admin.Notifications then return end
        
        local y = ScrH() - 200
        for i, notif in ipairs(KYBER.Admin.Notifications) do
            if notif.endTime > CurTime() then
                local alpha = math.min(255, (notif.endTime - CurTime()) * 255)
                local color = notif.type == "error" and Color(255, 100, 100, alpha) or Color(100, 255, 100, alpha)
                
                draw.RoundedBox(4, 20, y, 300, 25, Color(0, 0, 0, alpha * 0.7))
                draw.SimpleText(notif.text, "DermaDefault", 25, y + 12, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                
                y = y - 30
            else
                table.remove(KYBER.Admin.Notifications, i)
            end
        end
    end)
    
    -- Add notification function
    function KYBER.Admin:AddNotification(text, type, duration)
        self.Notifications = self.Notifications or {}
        
        table.insert(self.Notifications, {
            text = text,
            type = type or "info",
            endTime = CurTime() + (duration or 5)
        })
    end
    
    -- Utility functions for client
    function KYBER.Admin:ExecuteCommand(command, args)
        net.Start("Kyber_Admin_ExecuteCommand")
        net.WriteString(command)
        net.WriteTable(args or {})
        net.SendToServer()
    end
    
    function KYBER.Admin:HasPermission(ply, permission)
        if not IsValid(ply) then return false end
        
        local adminLevel = ply:GetNWInt("kyber_admin_level", 0)
        local requiredLevel = self.Config and self.Config.permissions and self.Config.permissions[permission] or 999
        
        return adminLevel >= requiredLevel
    end
end

-- Server-side integration
if SERVER then
    -- Additional admin commands for integration
    KYBER.Admin:RegisterCommand("set_faction", "manage_factions", function(admin, args)
        local userid = tonumber(args[1])
        local factionID = args[2]
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        if KYBER.Factions and KYBER.Factions[factionID] then
            target:SetNWString("kyber_faction", factionID)
            if KYBER.Character then
                KYBER.Character:SetFaction(target, factionID)
            end
            
            admin:ChatPrint("Set " .. target:Nick() .. "'s faction to " .. KYBER.Factions[factionID].name)
            target:ChatPrint("Your faction was changed to " .. KYBER.Factions[factionID].name .. " by " .. admin:Nick())
            
            return "set faction for " .. target:Nick()
        elseif factionID == "" then
            target:SetNWString("kyber_faction", "")
            admin:ChatPrint("Removed " .. target:Nick() .. " from their faction")
            target:ChatPrint("You were removed from your faction by " .. admin:Nick())
            
            return "removed faction for " .. target:Nick()
        else
            admin:ChatPrint("Invalid faction ID")
        end
    end, "Set a player's faction")
    
    KYBER.Admin:RegisterCommand("promote_admin", "promote_admin", function(admin, args)
        local steamID = args[1]
        local level = tonumber(args[2]) or 1
        
        if not steamID then
            admin:ChatPrint("Invalid SteamID")
            return
        end
        
        -- Find player name
        local targetName = "Unknown"
        for _, ply in ipairs(player.GetAll()) do
            if ply:SteamID64() == steamID then
                targetName = ply:Nick()
                break
            end
        end
        
        KYBER.Admin:AddAdmin(steamID, targetName, level, admin:Nick())
        admin:ChatPrint("Promoted " .. targetName .. " to admin level " .. level)
        
        return "promoted " .. targetName .. " to level " .. level
    end, "Promote a player to admin")
    
    KYBER.Admin:RegisterCommand("demote_admin", "promote_admin", function(admin, args)
        local steamID = args[1]
        
        if not steamID then
            admin:ChatPrint("Invalid SteamID")
            return
        end
        
        if KYBER.Admin:RemoveAdmin(steamID, admin:Nick()) then
            admin:ChatPrint("Removed admin privileges")
            return "demoted admin"
        else
            admin:ChatPrint("Player is not an admin")
        end
    end, "Demote an admin")
    
    -- Entity management commands
    KYBER.Admin:RegisterCommand("remove_entity", "spawn_props", function(admin, args)
        local entIndex = tonumber(args[1])
        local ent = Entity(entIndex)
        
        if not IsValid(ent) then
            admin:ChatPrint("Invalid entity")
            return
        end
        
        local class = ent:GetClass()
        ent:Remove()
        
        admin:ChatPrint("Removed " .. class)
        return "removed " .. class
    end, "Remove an entity")
    
    -- Integration with other Kyber systems
    hook.Add("PlayerInitialSpawn", "KyberAdminIntegration", function(ply)
        timer.Simple(2, function()
            if IsValid(ply) and KYBER.Admin:IsAdmin(ply) then
                ply:ChatPrint("Welcome back, " .. (KYBER.Admin.Config.levels[KYBER.Admin:GetAdminLevel(ply)] and KYBER.Admin.Config.levels[KYBER.Admin:GetAdminLevel(ply)].name or "Admin"))
                ply:ChatPrint("Type !admin or press F4 to open the admin panel")
            end
        end)
    end)
    
    -- Log important game events
    hook.Add("PlayerDeath", "KyberAdminDeathLog", function(victim, inflictor, attacker)
        if IsValid(victim) and IsValid(attacker) and attacker:IsPlayer() then
            KYBER.Admin:LogAction("SYSTEM", "DEATH", victim:Nick() .. " killed by " .. attacker:Nick(), victim:Nick())
        end
    end)
    
    hook.Add("PlayerDisconnected", "KyberAdminDisconnectLog", function(ply)
        if KYBER.Admin:IsAdmin(ply) then
            KYBER.Admin:LogAction("SYSTEM", "DISCONNECT", ply:Nick() .. " (Admin) disconnected", ply:Nick())
        end
    end)
end