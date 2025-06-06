-- kyber/modules/admin/commands.lua
KYBER.Admin = KYBER.Admin or {}
KYBER.Admin.Commands = {}

if SERVER then
    -- Command registration system
    function KYBER.Admin:RegisterCommand(name, permission, func, description)
        self.Commands[name] = {
            permission = permission,
            func = func,
            description = description or "No description"
        }
    end

    -- Execute command
    function KYBER.Admin:ExecuteCommand(admin, command, args)
        local cmd = self.Commands[command]
        if not cmd then
            admin:ChatPrint("Unknown command: " .. command)
            return false
        end

        -- Check permissions
        if not self:HasPermission(admin, cmd.permission) then
            admin:ChatPrint("Access denied: " .. command)
            return false
        end

        -- Execute and log
        local success, result = pcall(cmd.func, admin, args)
        if success then
            self:LogAction(admin, command:upper(), result or "executed")
            return true
        else
            admin:ChatPrint("Command error: " .. tostring(result))
            return false
        end
    end

    -- Basic Commands
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

    KYBER.Admin:RegisterCommand("kick", "kick", function(admin, args)
        local userid = tonumber(args[1])
        local reason = args[2] or "Kicked by admin"
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        -- Notify server
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[ADMIN] " .. target:Nick() .. " was kicked by " .. admin:Nick() .. " (" .. reason .. ")")
        end
        
        target:Kick(reason)
        return "kicked " .. target:Nick() .. " for: " .. reason
    end, "Kick a player")

    KYBER.Admin:RegisterCommand("ban", "ban", function(admin, args)
        local userid = tonumber(args[1])
        local reason = args[2] or "Banned by admin"
        local duration = tonumber(args[3]) or 0 -- 0 = permanent
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        local steamID = target:SteamID64()
        local name = target:Nick()
        local expiry = duration > 0 and (os.time() + duration) or 0
        
        -- Add to ban list
        KYBER.Admin:AddBan(steamID, name, reason, expiry, admin:Nick())
        
        -- Notify server
        local durationText = duration > 0 and string.FormattedTime(duration, "%02i:%02i:%02i") or "permanently"
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[ADMIN] " .. name .. " was banned " .. durationText .. " by " .. admin:Nick() .. " (" .. reason .. ")")
        end
        
        target:Kick("Banned: " .. reason)
        return "banned " .. name .. " for: " .. reason
    end, "Ban a player")

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
        admin:ChatPrint("Warned " .. target:Nick() .. " for: " .. reason)
        target:ChatPrint("[WARNING] You have been warned by " .. admin:Nick() .. " for: " .. reason)
        
        return "warned " .. target:Nick() .. " for: " .. reason
    end, "Warn a player")

    KYBER.Admin:RegisterCommand("jail", "jail", function(admin, args)
        local userid = tonumber(args[1])
        local duration = tonumber(args[2]) or 5 -- minutes
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        -- Store original position and restrict movement
        target.KyberJailData = {
            originalPos = target:GetPos(),
            endTime = CurTime() + (duration * 60),
            admin = admin:Nick()
        }
        
        -- Freeze and move to jail area (customize coordinates as needed)
        target:SetPos(Vector(0, 0, 100)) -- Replace with actual jail coordinates
        target:SetMoveType(MOVETYPE_NONE)
        
        -- Set timer to release
        timer.Create("KyberJail_" .. target:SteamID64(), duration * 60, 1, function()
            if IsValid(target) and target.KyberJailData then
                target:SetPos(target.KyberJailData.originalPos)
                target:SetMoveType(MOVETYPE_WALK)
                target.KyberJailData = nil
                target:ChatPrint("You have been released from jail.")
            end
        end)
        
        admin:ChatPrint("Jailed " .. target:Nick() .. " for " .. duration .. " minutes")
        target:ChatPrint("You have been jailed by " .. admin:Nick() .. " for " .. duration .. " minutes")
        
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
            admin:ChatPrint("Unfroze " .. target:Nick())
            target:ChatPrint("You have been unfrozen by " .. admin:Nick())
            return "unfroze " .. target:Nick()
        else
            target:SetMoveType(MOVETYPE_NONE)
            admin:ChatPrint("Froze " .. target:Nick())
            target:ChatPrint("You have been frozen by " .. admin:Nick())
            return "froze " .. target:Nick()
        end
    end, "Freeze/unfreeze a player")

    -- Economy Commands
    KYBER.Admin:RegisterCommand("give_credits", "give_credits", function(admin, args)
        local userid = tonumber(args[1])
        local amount = tonumber(args[2]) or 1000
        local target = Player(userid)
        
        if not IsValid(target) then
            admin:ChatPrint("Invalid target")
            return
        end
        
        -- Use economy system if available
        if KYBER.Economy then
            KYBER.Economy:AddCredits(target, amount)
        else
            -- Fallback to player data
            local credits = KYBER:GetPlayerData(target, "credits") or 0
            KYBER:SetPlayerData(target, "credits", credits + amount)
        end
        
        admin:ChatPrint("Gave " .. amount .. " credits to " .. target:Nick())
        target:ChatPrint("You received " .. amount .. " credits from " .. admin:Nick())
        
        return "gave " .. amount .. " credits to " .. target:Nick()
    end, "Give credits to a player")

    -- Mass Commands
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

    KYBER.Admin:RegisterCommand("freeze_all", "freeze", function(admin, args)
        local count = 0
        for _, ply in ipairs(player.GetAll()) do
            if ply ~= admin then
                ply:SetMoveType(MOVETYPE_NONE)
                count = count + 1
            end
        end
        
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[ADMIN] All players frozen by " .. admin:Nick())
        end
        
        admin:ChatPrint("Froze " .. count .. " players")
        return "froze " .. count .. " players"
    end, "Freeze all players")

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
        
        admin:ChatPrint("Unfroze " .. count .. " players")
        return "unfroze " .. count .. " players"
    end, "Unfreeze all players")
    
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

    -- Server Management Commands
    KYBER.Admin:RegisterCommand("cleanup_props", "spawn_props", function(admin, args)
        local count = 0
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetClass() == "prop_physics" then
                ent:Remove()
                count = count + 1
            end
        end
        
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[ADMIN] " .. count .. " props cleaned up by " .. admin:Nick())
        end
        
        return "cleaned up " .. count .. " props"
    end, "Clean up all props")

    KYBER.Admin:RegisterCommand("restart_map", "manage_server", function(admin, args)
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[ADMIN] Map restart initiated by " .. admin:Nick())
        end
        
        timer.Simple(5, function()
            RunConsoleCommand("changelevel", game.GetMap())
        end)
        
        return "initiated map restart"
    end, "Restart the current map")

    -- Ban system
    KYBER.Admin.Bans = {}
    
    function KYBER.Admin:LoadBans()
        if file.Exists("kyber/admin/bans.json", "DATA") then
            local data = file.Read("kyber/admin/bans.json", "DATA")
            self.Bans = util.JSONToTable(data) or {}
        end
    end
    
    function KYBER.Admin:SaveBans()
        if not file.Exists("kyber/admin", "DATA") then
            file.CreateDir("kyber/admin")
        end
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
        if ban.expiry > 0 and ban.expiry < os.time() then
            self.Bans[steamID] = nil
            self:SaveBans()
            return false
        end
        
        return true, ban
    end

    -- Check bans on player connect
    hook.Add("CheckPassword", "KyberBanCheck", function(steamID64, ipAddress, svPassword, clPassword, name)
        if KYBER.Admin:IsBanned(steamID64) then
            local _, ban = KYBER.Admin:IsBanned(steamID64)
            local reason = ban.reason or "No reason specified"
            local expiry = ban.expiry > 0 and os.date("%c", ban.expiry) or "Never"
            
            return false, "You are banned from this server.\nReason: " .. reason .. "\nExpires: " .. expiry
        end
    end)

    -- Command execution hook
    hook.Add("Kyber_Admin_ExecuteCommand", "KyberExecuteCommand", function(admin, command, args)
        KYBER.Admin:ExecuteCommand(admin, command, args)
    end)

    -- Initialize ban system
    hook.Add("Initialize", "KyberAdminBans", function()
        KYBER.Admin:LoadBans()
    end)

end