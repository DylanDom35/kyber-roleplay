-- Admin module initialization
KYBER.Admin = KYBER.Admin or {}

-- Admin module configuration
KYBER.Admin.Config = {
    Ranks = {
        ["superadmin"] = {
            name = "Super Admin",
            color = Color(255, 0, 0),
            permissions = {
                "admin.*",
                "admin.ban",
                "admin.kick",
                "admin.slap",
                "admin.teleport",
                "admin.give",
                "admin.setrank",
                "admin.weather",
                "admin.time",
                "admin.noclip",
                "admin.god",
                "admin.freeze"
            }
        },
        ["admin"] = {
            name = "Admin",
            color = Color(255, 165, 0),
            permissions = {
                "admin.kick",
                "admin.slap",
                "admin.teleport",
                "admin.noclip",
                "admin.freeze"
            }
        },
        ["moderator"] = {
            name = "Moderator",
            color = Color(0, 255, 0),
            permissions = {
                "admin.kick",
                "admin.slap",
                "admin.teleport",
                "admin.freeze"
            }
        }
    },
    LogActions = true,
    LogFile = "kyber/logs/admin.log",
    MaxBanDuration = 31536000, -- 1 year in seconds
    DefaultBanDuration = 86400 -- 1 day in seconds
}

-- Admin module functions
function KYBER.Admin:Initialize()
    print("[Kyber] Admin module initialized")
    return true
end

function KYBER.Admin:GetPlayerRank(ply)
    if not IsValid(ply) then return nil end
    return ply:GetUserGroup()
end

function KYBER.Admin:HasPermission(ply, permission)
    if not IsValid(ply) then return false end
    
    local rank = self:GetPlayerRank(ply)
    if not rank then return false end
    
    local rankData = self.Config.Ranks[rank]
    if not rankData then return false end
    
    -- Check for wildcard permission
    if table.HasValue(rankData.permissions, "admin.*") then
        return true
    end
    
    return table.HasValue(rankData.permissions, permission)
end

function KYBER.Admin:BanPlayer(admin, target, duration, reason)
    if not IsValid(admin) or not IsValid(target) then return false end
    
    -- Check permissions
    if not self:HasPermission(admin, "admin.ban") then
        return false
    end
    
    -- Validate duration
    duration = math.Clamp(duration or self.Config.DefaultBanDuration, 0, self.Config.MaxBanDuration)
    
    -- Create ban
    local banData = {
        steam_id = target:SteamID(),
        admin_steam_id = admin:SteamID(),
        reason = reason or "No reason provided",
        duration = duration,
        created_at = os.time(),
        expires_at = os.time() + duration
    }
    
    -- Save to database
    if KYBER.SQL then
        KYBER.SQL:Query(string.format([[
            INSERT INTO kyber_bans (steam_id, admin_steam_id, reason, duration, created_at, expires_at)
            VALUES ('%s', '%s', '%s', %d, %d, %d)
        ]], banData.steam_id, banData.admin_steam_id, banData.reason, banData.duration, banData.created_at, banData.expires_at))
    end
    
    -- Log action
    if self.Config.LogActions then
        self:LogAction(admin, "ban", string.format("Banned %s for %d seconds. Reason: %s", 
            target:Nick(), duration, reason or "No reason provided"))
    end
    
    -- Kick player
    target:Kick(string.format("Banned for %d seconds. Reason: %s", duration, reason or "No reason provided"))
    
    return true
end

function KYBER.Admin:KickPlayer(admin, target, reason)
    if not IsValid(admin) or not IsValid(target) then return false end
    
    -- Check permissions
    if not self:HasPermission(admin, "admin.kick") then
        return false
    end
    
    -- Log action
    if self.Config.LogActions then
        self:LogAction(admin, "kick", string.format("Kicked %s. Reason: %s", 
            target:Nick(), reason or "No reason provided"))
    end
    
    -- Kick player
    target:Kick(reason or "No reason provided")
    
    return true
end

function KYBER.Admin:LogAction(admin, action, details)
    if not self.Config.LogActions then return end
    
    local log = {
        timestamp = os.time(),
        admin_steam_id = admin:SteamID(),
        admin_name = admin:Nick(),
        action = action,
        details = details
    }
    
    -- Log to file
    file.Append(self.Config.LogFile, util.TableToJSON(log) .. "\n")
    
    -- Log to console
    print(string.format("[Kyber Admin] %s (%s) %s: %s", 
        admin:Nick(), admin:SteamID(), action, details))
end

function KYBER.Admin:Notify(message, rank)
    if not message then return end
    
    -- Get all players with the specified rank or higher
    local targets = {}
    for _, ply in ipairs(player.GetAll()) do
        if not rank or self:HasPermission(ply, rank) then
            table.insert(targets, ply)
        end
    end
    
    -- Send notification
    net.Start("Kyber_Admin_Notify")
    net.WriteString(message)
    net.Send(targets)
end

-- Initialize the module
KYBER.Admin:Initialize() 