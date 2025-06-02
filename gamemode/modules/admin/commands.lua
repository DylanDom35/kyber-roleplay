-- kyber/modules/admin/commands.lua
-- Server-side admin command handlers

if SERVER then
    KYBER.Admin = KYBER.Admin or {}
    KYBER.Admin.Commands = {}
    
    -- Command handler system
    function KYBER.Admin:RegisterCommand(name, permission, func, description)
        self.Commands[name] = {
            permission = permission,
            func = func,
            description = description or "No description"
        }
    end
    
    function KYBER.Admin:ExecuteCommand(admin, commandName, args)
        local command = self.Commands[commandName]
        if not command then
            admin:ChatPrint("Unknown command: " .. commandName)
            return
        end
        
        -- Check permission
        if not self:HasPermission(admin, command.permission) then
            admin:ChatPrint("Access denied: Insufficient permissions")
            self:LogAction(admin, "DENIED", commandName .. " - insufficient permissions")
            return
        end
        
        -- Execute command
        local success, result = pcall(command.func, admin, args)
        
        if not success then
            admin:ChatPrint("Command failed: " .. result)
            self:LogAction(admin, "ERROR", commandName .. " - " .. result)
        else
            self:LogAction(admin, string.upper(commandName), result or "executed")
        end
    end
    
    -- Player Management Commands
    KYBER.Admin:RegisterCommand("goto", "tp_to_player", function(admin, args)
        local userid = tonumber(args[1])
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        admin:SetPos(target:GetPos() + Vector(50, 0, 0))
        admin:ChatPrint("Teleported to " .. target:Nick())
        return "teleported to " .. target:Nick()
    end, "Teleport to a player")
    
    KYBER.Admin:RegisterCommand("bring", "bring", function(admin, args)
        local userid = tonumber(args[1])
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        target:SetPos(admin:GetPos() + admin:GetForward() * 100)
        admin:ChatPrint("Brought " .. target:Nick())
        target:ChatPrint("You were brought by " .. admin:Nick())
        return "brought " .. target:Nick()
    end, "Bring a player to you")
    
    KYBER.Admin:RegisterCommand("spectate", "spectate", function(admin, args)
        local userid = tonumber(args[1])
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        admin:SpectateEntity(target)
        admin:Spectate(OBS_MODE_CHASE)
        admin:ChatPrint("Now spectating " .. target:Nick())
        return "spectating " .. target:Nick()
    end, "Spectate a player")
    
    KYBER.Admin:RegisterCommand("heal", "heal", function(admin, args)
        local userid = tonumber(args[1])
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        target:SetHealth(target:GetMaxHealth())
        target:SetArmor(100)
        
        -- Clear injuries if medical system exists
        if target.KyberMedical then
            target.KyberMedical.injuries = {}
            if KYBER.Medical then
                KYBER.Medical:SendInjuryUpdate(target)
            end
        end
        
        admin:ChatPrint("Healed " .. target:Nick())
        target:ChatPrint("You were healed by " .. admin:Nick())
        return "healed " .. target:Nick()
    end, "Heal a player")
    
    KYBER.Admin:RegisterCommand("god", "god", function(admin, args)
        if admin:HasGodMode() then
            admin:GodDisable()
            admin:ChatPrint("God mode disabled")
            return "disabled god mode"
        else
            admin:GodEnable()
            admin:ChatPrint("God mode enabled")
            return "enabled god mode"
        end
    end, "Toggle god mode")
    
    KYBER.Admin:RegisterCommand("noclip", "noclip", function(admin, args)
        if admin:GetMoveType() == MOVETYPE_NOCLIP then
            admin:SetMoveType(MOVETYPE_WALK)
            admin:ChatPrint("Noclip disabled")
            return "disabled noclip"
        else
            admin:SetMoveType(MOVETYPE_NOCLIP)
            admin:ChatPrint("Noclip enabled")
            return "enabled noclip"
        end
    end, "Toggle noclip")
    
    -- Punishment Commands
    KYBER.Admin:RegisterCommand("warn", "warn", function(admin, args)
        local userid = tonumber(args[1])
        local reason = args[2] or "No reason specified"
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        -- Store warning
        target.KyberWarnings = target.KyberWarnings or {}
        table.insert(target.KyberWarnings, {
            admin = admin:Nick(),
            reason = reason,
            timestamp = os.time()
        })
        
        -- Notify
        target:ChatPrint("WARNING: " .. reason .. " (Issued by " .. admin:Nick() .. ")")
        admin:ChatPrint("Warned " .. target:Nick() .. " for: " .. reason)
        
        -- Broadcast to other admins
        for _, ply in ipairs(player.GetAll()) do
            if KYBER.Admin:IsAdmin(ply) and ply ~= admin then
                ply:ChatPrint("[ADMIN] " .. admin:Nick() .. " warned " .. target:Nick() .. " for: " .. reason)
            end
        end
        
        return "warned " .. target:Nick() .. " for: " .. reason
    end, "Warn a player")
    
    KYBER.Admin:RegisterCommand("kick", "kick", function(admin, args)
        local userid = tonumber(args[1])
        local reason = args[2] or "No reason specified"
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        if KYBER.Admin:GetLevel(target) >= KYBER.Admin:GetLevel(admin) then
            admin:ChatPrint("Cannot kick player with equal or higher admin level")
            return
        end
        
        -- Broadcast kick
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[ADMIN] " .. target:Nick() .. " was kicked by " .. admin:Nick() .. " (" .. reason .. ")")
        end
        
        target:Kick(reason)
        return "kicked " .. target:Nick() .. " for: " .. reason
    end, "Kick a player")
    
    KYBER.Admin:RegisterCommand("ban", "ban", function(admin, args)
        local userid = tonumber(args[1])
        local duration = tonumber(args[2]) or 0 -- 0 = permanent
        local reason = args[3] or "No reason specified"
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        if KYBER.Admin:GetLevel(target) >= KYBER.Admin:GetLevel(admin) then
            admin:ChatPrint("Cannot ban player with equal or higher admin level")
            return
        end
        
        -- Check if trying to permaban without permission
        if duration == 0 and not KYBER.Admin:HasPermission(admin, "ban_permanent") then
            admin:ChatPrint("You don't have permission for permanent bans")
            return
        end
        
        local steamID = target:SteamID64()
        local expiry = duration > 0 and (os.time() + duration * 60) or 0
        
        -- Store ban
        KYBER.Admin:AddBan(steamID, target:Nick(), reason, expiry, admin:Nick())
        
        -- Broadcast ban
        local durationText = duration > 0 and string.NiceTime(duration * 60) or "permanently"
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[ADMIN] " .. target:Nick() .. " was banned " .. durationText .. " by " .. admin:Nick() .. " (" .. reason .. ")")
        end
        
        target:Kick("BANNED: " .. reason .. (duration > 0 and " (Duration: " .. durationText .. ")" or " (Permanent)"))
        return "banned " .. target:Nick() .. " for " .. durationText .. ": " .. reason
    end, "Ban a player")
    
    KYBER.Admin:RegisterCommand("jail", "jail", function(admin, args)
        local userid = tonumber(args[1])
        local duration = tonumber(args[2]) or 5
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        -- Store original position
        target.KyberJailReturn = target:GetPos()
        
        -- Teleport to jail (you'll need to set this position for your map)
        local jailPos = Vector(0, 0, 0) -- Change this to your jail coordinates
        target:SetPos(jailPos)
        target:SetMoveType(MOVETYPE_NONE)
        
        -- Create jail timer
        timer.Create("KyberJail_" .. target:SteamID64(), duration * 60, 1, function()
            if IsValid(target) then
                target:SetMoveType(MOVETYPE_WALK)
                if target.KyberJailReturn then
                    target:SetPos(target.KyberJailReturn)
                    target.KyberJailReturn = nil
                end
                target:ChatPrint("You have been released from jail")
            end
        end)
        
        target:ChatPrint("You have been jailed for " .. duration .. " minutes by " .. admin:Nick())
        admin:ChatPrint("Jailed " .. target:Nick() .. " for " .. duration .. " minutes")
        return "jailed " .. target:Nick() .. " for " .. duration .. " minutes"
    end, "Jail a player")
    
    KYBER.Admin:RegisterCommand("freeze", "freeze", function(admin, args)
        local userid = tonumber(args[1])
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        if target:GetMoveType() == MOVETYPE_NONE then
            target:SetMoveType(MOVETYPE_WALK)
            target:ChatPrint("You have been unfrozen by " .. admin:Nick())
            admin:ChatPrint("Unfroze " .. target:Nick())
            return "unfroze " .. target:Nick()
        else
            target:SetMoveType(MOVETYPE_NONE)
            target:ChatPrint("You have been frozen by " .. admin:Nick())
            admin:ChatPrint("Froze " .. target:Nick())
            return "froze " .. target:Nick()
        end
    end, "Freeze/unfreeze a player")
    
    -- Character Management Commands
    KYBER.Admin:RegisterCommand("give_credits", "give_credits", function(admin, args)
        local userid = tonumber(args[1])
        local amount = tonumber(args[2]) or 1000
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        local current = KYBER:GetPlayerData(target, "credits") or 0
        KYBER:SetPlayerData(target, "credits", current + amount)
        
        target:ChatPrint("You received " .. amount .. " credits from " .. admin:Nick())
        admin:ChatPrint("Gave " .. amount .. " credits to " .. target:Nick())
        return "gave " .. amount .. " credits to " .. target:Nick()
    end, "Give credits to a player")
    
    KYBER.Admin:RegisterCommand("set_faction", "manage_factions", function(admin, args)
        local userid = tonumber(args[1])
        local factionID = args[2]
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        if factionID == "" then factionID = nil end
        
        local oldFaction = target:GetNWString("kyber_faction", "")
        KYBER:SetFaction(target, factionID)
        
        local factionName = "None"
        if factionID and KYBER.Factions[factionID] then
            factionName = KYBER.Factions[factionID].name
        end
        
        target:ChatPrint("Your faction has been set to: " .. factionName)
        admin:ChatPrint("Set " .. target:Nick() .. "'s faction to: " .. factionName)
        return "set " .. target:Nick() .. "'s faction to " .. factionName
    end, "Set a player's faction")
    
    KYBER.Admin:RegisterCommand("rename", "edit_characters", function(admin, args)
        local userid = tonumber(args[1])
        local newName = args[2]
        local target = Player(userid)
        
        if not IsValid(target) or not newName then
            admin:ChatPrint("Invalid target or name")
            return
        end
        
        local oldName = target:GetNWString("kyber_name", target:Nick())
        target:SetNWString("kyber_name", newName)
        
        target:ChatPrint("Your character name has been changed to: " .. newName)
        admin:ChatPrint("Renamed " .. oldName .. " to " .. newName)
        return "renamed " .. oldName .. " to " .. newName
    end, "Rename a player's character")
    
    -- Admin Management Commands
    KYBER.Admin:RegisterCommand("add_admin", "promote_admin", function(admin, args)
        local steamID = args[1]
        local name = args[2]
        local level = tonumber(args[3])
        
        if not steamID or not name or not level then
            admin:ChatPrint("Usage: steamID, name, level")
            return
        end
        
        if level >= KYBER.Admin:GetLevel(admin) then
            admin:ChatPrint("Cannot promote to equal or higher level than yourself")
            return
        end
        
        local success, err = KYBER.Admin:AddAdmin(steamID, name, level, admin:Nick())
        if success then
            admin:ChatPrint("Successfully promoted " .. name .. " to level " .. level)
            return "promoted " .. name .. " to admin level " .. level
        else
            admin:ChatPrint("Failed: " .. err)
            return
        end
    end, "Add a new admin")
    
    KYBER.Admin:RegisterCommand("remove_admin", "promote_admin", function(admin, args)
        local steamID = args[1]
        
        if not steamID then
            admin:ChatPrint("Usage: steamID")
            return
        end
        
        local adminData = KYBER.Admin.Admins[steamID]
        if not adminData then
            admin:ChatPrint("Player is not an admin")
            return
        end
        
        if adminData.level >= KYBER.Admin:GetLevel(admin) then
            admin:ChatPrint("Cannot demote admin with equal or higher level")
            return
        end
        
        local success, err = KYBER.Admin:RemoveAdmin(steamID, admin:Nick())
        if success then
            admin:ChatPrint("Successfully demoted " .. adminData.name)
            return "demoted " .. adminData.name .. " from admin"
        else
            admin:ChatPrint("Failed: " .. err)
            return
        end
    end, "Remove an admin")
    
    -- Server Management Commands
    KYBER.Admin:RegisterCommand("cleanup_props", "spawn_props", function(admin, args)
        local count = 0
        for _, ent in ipairs(ents.FindByClass("prop_*")) do
            if IsValid(ent) then
                ent:Remove()
                count = count + 1
            end
        end
        
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[ADMIN] " .. admin:Nick() .. " cleaned up " .. count .. " props")
        end
        
        return "cleaned up " .. count .. " props"
    end, "Clean up all props")
    
    KYBER.Admin:RegisterCommand("restart_map", "restart_round", function(admin, args)
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[ADMIN] Map restart initiated by " .. admin:Nick())
        end
        
        timer.Simple(5, function()
            RunConsoleCommand("changelevel", game.GetMap())
        end)
        
        return "initiated map restart"
    end, "Restart the current map")
    
    KYBER.Admin:RegisterCommand("change_map", "server_config", function(admin, args)
        local mapName = args[1]
        
        if not mapName then
            admin:ChatPrint("Usage: map_name")
            return
        end
        
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[ADMIN] Map changing to " .. mapName .. " by " .. admin:Nick())
        end
        
        timer.Simple(5, function()
            RunConsoleCommand("changelevel", mapName)
        end)
        
        return "changing map to " .. mapName
    end, "Change to a different map")
    
    -- Mass Actions
    KYBER.Admin:RegisterCommand("freeze_all", "freeze", function(admin, args)
        local count = 0
        for _, ply in ipairs(player.GetAll()) do
            if ply ~= admin and not KYBER.Admin:IsAdmin(ply) then
                ply:SetMoveType(MOVETYPE_NONE)
                count = count + 1
            end
        end
        
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[ADMIN] All players frozen by " .. admin:Nick())
        end
        
        return "froze " .. count .. " players"
    end, "Freeze all non-admin players")
    
    KYBER.Admin:RegisterCommand("unfreeze_all", "freeze", function(admin, args)
        local count = 0
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetMoveType() == MOVETYPE_NONE then
                ply:SetMoveType(MOVETYPE_WALK)
                count = count + 1
            end
        end
        
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[ADMIN] All players unfrozen by " .. admin:Nick())
        end
        
        return "unfroze " .. count .. " players"
    end, "Unfreeze all players")
    
    KYBER.Admin:RegisterCommand("heal_all", "heal", function(admin, args)
        for _, ply in ipairs(player.GetAll()) do
            ply:SetHealth(ply:GetMaxHealth())
            ply:SetArmor(100)
            
            if ply.KyberMedical then
                ply.KyberMedical.injuries = {}
                if KYBER.Medical then
                    KYBER.Medical:SendInjuryUpdate(ply)
                end
            end
        end
        
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[ADMIN] All players healed by " .. admin:Nick())
        end
        
        return "healed all players"
    end, "Heal all players")
    
    KYBER.Admin:RegisterCommand("bring_all", "bring", function(admin, args)
        local adminPos = admin:GetPos()
        local count = 0
        
        for _, ply in ipairs(player.GetAll()) do
            if ply ~= admin then
                ply:SetPos(adminPos + Vector(math.random(-200, 200), math.random(-200, 200), 10))
                count = count + 1
            end
        end
        
        admin:ChatPrint("Brought " .. count .. " players to your location")
        return "brought " .. count .. " players"
    end, "Bring all players to you")
    
    KYBER.Admin:RegisterCommand("emergency_stop", "all_permissions", function(admin, args)
        -- Freeze everyone, god mode everyone, stop all timers
        for _, ply in ipairs(player.GetAll()) do
            ply:SetMoveType(MOVETYPE_NONE)
            ply:GodEnable()
            ply:ChatPrint("[EMERGENCY] Server emergency stop activated by " .. admin:Nick())
        end
        
        -- Stop all Kyber timers
        for _, timerName in ipairs(timer.GetTimers()) do
            if string.StartWith(timerName, "Kyber") then
                timer.Remove(timerName)
            end
        end
        
        return "activated emergency stop"
    end, "Emergency stop all server activity")
    
    -- Ban system
    KYBER.Admin.Bans = {}
    
    function KYBER.Admin:LoadBans()
        if file.Exists("kyber/admin/bans.json", "DATA") then
            local data = file.Read("kyber/admin/bans.json", "DATA")
            self.Bans = util.JSONToTable(data) or {}
        end
    end
    
    function KYBER.Admin:SaveBans()
        file.Write("kyber/admin/bans.json", util.TableToJSON(self.Bans))
    end
    
    function KYBER.Admin:AddBan(steamID, name, reason, expiry, admin)
        self.Bans[steamID] = {
            name = name,
            reason = reason,
            expiry = expiry,
            admin = admin,
            timestamp = os.time()
        }
        
        self:SaveBans()
    end
    
    function KYBER.Admin:IsBanned(steamID)
        local ban = self.Bans[steamID]
        if not ban then return false end
        
        -- Check if ban expired
        if ban.expiry > 0 and os.time() > ban.expiry then
            self.Bans[steamID] = nil
            self:SaveBans()
            return false
        end
        
        return true, ban
    end
    
    function KYBER.Admin:RemoveBan(steamID)
        self.Bans[steamID] = nil
        self:SaveBans()
    end
    
    -- Check bans on connect
    hook.Add("CheckPassword", "KyberAdminBanCheck", function(steamID64, ipAddress, serverPassword, password, name)
        if KYBER.Admin:IsBanned(steamID64) then
            local isBanned, ban = KYBER.Admin:IsBanned(steamID64)
            
            if isBanned then
                local timeLeft = ban.expiry > 0 and string.NiceTime(ban.expiry - os.time()) or "Permanent"
                return false, "BANNED: " .. ban.reason .. " (Time left: " .. timeLeft .. ")"
            end
        end
    end)
    
    -- Command execution hook
    hook.Add("Kyber_Admin_ExecuteCommand", "KyberAdminCommandHandler", function(admin, command, args)
        KYBER.Admin:ExecuteCommand(admin, command, args)
    end)
    
    -- Initialize bans on server start
    hook.Add("Initialize", "KyberAdminBansInit", function()
        KYBER.Admin:LoadBans()
    end)
    
    -- Console commands for emergency admin management
    concommand.Add("kyber_emergency_admin", function(ply, cmd, args)
        if IsValid(ply) then return end -- Console only
        
        if #args < 1 then
            print("Usage: kyber_emergency_admin <steamid>")
            return
        end
        
        local steamID = args[1]
        KYBER.Admin:AddAdmin(steamID, "Emergency Admin", 5, "CONSOLE")
        print("Emergency admin granted to " .. steamID)
    end)
    
    -- Help command
    KYBER.Admin:RegisterCommand("help", "warn", function(admin, args)
        admin:ChatPrint("=== Kyber Admin Commands ===")
        
        local level = KYBER.Admin:GetLevel(admin)
        local availableCommands = {}
        
        for cmdName, cmdData in pairs(KYBER.Admin.Commands) do
            local reqLevel = KYBER.Admin.Config.permissions[cmdData.permission]
            if reqLevel and level >= reqLevel then
                table.insert(availableCommands, cmdName .. " - " .. cmdData.description)
            end
        end
        
        table.sort(availableCommands)
        
        for _, cmd in ipairs(availableCommands) do
            admin:ChatPrint("!" .. cmd)
        end
        
        return "displayed help"
    end, "Show available commands")
    
end