-- kyber/modules/admin/core.lua
KYBER.Admin = KYBER.Admin or {}

-- Core admin configuration
KYBER.Admin.Config = {
    -- Superadmins (hardcoded into gamemode)
    superadmins = {
        ["76561198065092442"] = {name = "GamemodeCreator", level = 5},
        ["76561198065092442"] = {name = "HeadAdmin", level = 5},
        -- Add more superadmin SteamIDs here
    },
    
    -- Admin levels
    levels = {
        [1] = {name = "Moderator", color = Color(100, 255, 100), prefix = "[MOD]"},
        [2] = {name = "Admin", color = Color(255, 255, 100), prefix = "[ADMIN]"},
        [3] = {name = "Senior Admin", color = Color(255, 150, 50), prefix = "[SENIOR]"},
        [4] = {name = "Head Admin", color = Color(255, 100, 100), prefix = "[HEAD]"},
        [5] = {name = "Superadmin", color = Color(255, 50, 255), prefix = "[SUPER]"}
    },
    
    -- Permissions
    permissions = {
        -- Level 1 - Moderator
        ["kick"] = 1,
        ["warn"] = 1,
        ["mute"] = 1,
        ["freeze"] = 1,
        ["spectate"] = 1,
        ["tp_to_player"] = 1,
        ["give_basic_items"] = 1,
        
        -- Level 2 - Admin
        ["ban"] = 2,
        ["jail"] = 2,
        ["noclip"] = 2,
        ["god"] = 2,
        ["teleport"] = 2,
        ["bring"] = 2,
        ["goto"] = 2,
        ["heal"] = 2,
        ["give_credits"] = 2,
        ["spawn_props"] = 2,
        ["manage_reputation"] = 2,
        
        -- Level 3 - Senior Admin
        ["unban"] = 3,
        ["promote_demote"] = 3,
        ["edit_characters"] = 3,
        ["spawn_entities"] = 3,
        ["manage_factions"] = 3,
        ["force_whitelist"] = 3,
        ["restart_round"] = 3,
        
        -- Level 4 - Head Admin
        ["promote_admin"] = 4,
        ["manage_admin_levels"] = 4,
        ["server_config"] = 4,
        ["database_access"] = 4,
        ["ban_permanent"] = 4,
        
        -- Level 5 - Superadmin
        ["promote_superadmin"] = 5,
        ["console_access"] = 5,
        ["shutdown_server"] = 5,
        ["all_permissions"] = 5
    }
}

-- Initialize admin system
function KYBER.Admin:Initialize()
    if not file.Exists("kyber/admin", "DATA") then
        file.CreateDir("kyber/admin")
    end
    
    -- Load admin data
    self:LoadAdmins()
    
    -- Create admin log
    self:InitializeLogging()
    
    print("[Kyber Admin] System initialized with " .. table.Count(self.Admins) .. " admins")
end

-- Load admin data from file
function KYBER.Admin:LoadAdmins()
    self.Admins = table.Copy(self.Config.superadmins) -- Start with hardcoded superadmins
    
    if file.Exists("kyber/admin/admins.json", "DATA") then
        local data = file.Read("kyber/admin/admins.json", "DATA")
        local saved = util.JSONToTable(data)
        
        if saved then
            -- Merge with saved admins (but don't overwrite superadmins)
            for steamID, adminData in pairs(saved) do
                if not self.Config.superadmins[steamID] then
                    self.Admins[steamID] = adminData
                end
            end
        end
    end
end

-- Save admin data
function KYBER.Admin:SaveAdmins()
    local toSave = {}
    
    -- Only save non-superadmin admins
    for steamID, adminData in pairs(self.Admins) do
        if not self.Config.superadmins[steamID] then
            toSave[steamID] = adminData
        end
    end
    
    file.Write("kyber/admin/admins.json", util.TableToJSON(toSave))
end

-- Check if player is admin
function KYBER.Admin:IsAdmin(ply, level)
    if not IsValid(ply) then return false end
    
    local steamID = ply:SteamID64()
    local adminData = self.Admins[steamID]
    
    if not adminData then return false end
    
    level = level or 1
    return adminData.level >= level
end

-- Get admin level
function KYBER.Admin:GetLevel(ply)
    if not IsValid(ply) then return 0 end
    
    local steamID = ply:SteamID64()
    local adminData = self.Admins[steamID]
    
    return adminData and adminData.level or 0
end

-- Check permission
function KYBER.Admin:HasPermission(ply, permission)
    if not IsValid(ply) then return false end
    
    local level = self:GetLevel(ply)
    if level == 0 then return false end
    
    -- Superadmins have all permissions
    if level >= 5 then return true end
    
    local reqLevel = self.Config.permissions[permission]
    return reqLevel and level >= reqLevel
end

-- Add admin
function KYBER.Admin:AddAdmin(steamID, name, level, promotedBy)
    if self.Config.superadmins[steamID] then
        return false, "Cannot modify superadmin"
    end
    
    self.Admins[steamID] = {
        name = name,
        level = level,
        promoted = os.time(),
        promotedBy = promotedBy
    }
    
    self:SaveAdmins()
    self:LogAction(promotedBy, "PROMOTE", steamID .. " to level " .. level)
    
    -- Notify if online
    local ply = player.GetBySteamID64(steamID)
    if IsValid(ply) then
        ply:ChatPrint("You have been promoted to " .. self.Config.levels[level].name)
        self:SetAdminStatus(ply)
    end
    
    return true
end

-- Remove admin
function KYBER.Admin:RemoveAdmin(steamID, removedBy)
    if self.Config.superadmins[steamID] then
        return false, "Cannot remove superadmin"
    end
    
    if not self.Admins[steamID] then
        return false, "Player is not an admin"
    end
    
    local oldLevel = self.Admins[steamID].level
    self.Admins[steamID] = nil
    
    self:SaveAdmins()
    self:LogAction(removedBy, "DEMOTE", steamID .. " from level " .. oldLevel)
    
    -- Notify if online
    local ply = player.GetBySteamID64(steamID)
    if IsValid(ply) then
        ply:ChatPrint("You have been demoted from admin")
        self:SetAdminStatus(ply)
    end
    
    return true
end

-- Set admin status on player
function KYBER.Admin:SetAdminStatus(ply)
    if not IsValid(ply) then return end
    
    local level = self:GetLevel(ply)
    ply:SetNWInt("kyber_admin_level", level)
    
    if level > 0 then
        local levelData = self.Config.levels[level]
        ply:SetNWString("kyber_admin_rank", levelData.name)
        ply:SetNWString("kyber_admin_prefix", levelData.prefix)
    else
        ply:SetNWString("kyber_admin_rank", "")
        ply:SetNWString("kyber_admin_prefix", "")
    end
end

-- Initialize logging
function KYBER.Admin:InitializeLogging()
    if not file.Exists("kyber/admin/logs", "DATA") then
        file.CreateDir("kyber/admin/logs")
    end
end

-- Log admin action
function KYBER.Admin:LogAction(admin, action, details, target)
    local logEntry = {
        timestamp = os.time(),
        admin = IsValid(admin) and admin:Nick() or admin,
        adminID = IsValid(admin) and admin:SteamID64() or "CONSOLE",
        action = action,
        details = details,
        target = IsValid(target) and target:Nick() or target,
        targetID = IsValid(target) and target:SteamID64() or target
    }
    
    -- Daily log file
    local logFile = "kyber/admin/logs/" .. os.date("%Y-%m-%d") .. ".json"
    local logs = {}
    
    if file.Exists(logFile, "DATA") then
        logs = util.JSONToTable(file.Read(logFile, "DATA")) or {}
    end
    
    table.insert(logs, logEntry)
    file.Write(logFile, util.TableToJSON(logs))
    
    -- Also log to console
    print(string.format("[ADMIN] %s (%s) %s: %s", 
        logEntry.admin, logEntry.adminID, action, details))
end

-- Get admin logs
function KYBER.Admin:GetLogs(days)
    days = days or 7
    local logs = {}
    
    for i = 0, days - 1 do
        local date = os.date("%Y-%m-%d", os.time() - (i * 86400))
        local logFile = "kyber/admin/logs/" .. date .. ".json"
        
        if file.Exists(logFile, "DATA") then
            local dayLogs = util.JSONToTable(file.Read(logFile, "DATA")) or {}
            for _, log in ipairs(dayLogs) do
                table.insert(logs, log)
            end
        end
    end
    
    -- Sort by timestamp (newest first)
    table.sort(logs, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    return logs
end

if SERVER then
    -- Network strings
    util.AddNetworkString("Kyber_Admin_OpenPanel")
    util.AddNetworkString("Kyber_Admin_ExecuteCommand")
    util.AddNetworkString("Kyber_Admin_RequestData")
    util.AddNetworkString("Kyber_Admin_UpdateData")
    
    -- Initialize on server start
    hook.Add("Initialize", "KyberAdminInit", function()
        KYBER.Admin:Initialize()
    end)
    
    -- Set admin status on spawn
    hook.Add("PlayerInitialSpawn", "KyberAdminSpawn", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                KYBER.Admin:SetAdminStatus(ply)
            end
        end)
    end)
    
    -- Admin chat command
    hook.Add("PlayerSay", "KyberAdminChat", function(ply, text)
        if string.sub(text, 1, 1) == "!" and KYBER.Admin:IsAdmin(ply) then
            -- Admin command
            local args = string.Explode(" ", text)
            local cmd = string.sub(args[1], 2) -- Remove !
            
            -- Handle basic commands
            if cmd == "admin" or cmd == "panel" then
                net.Start("Kyber_Admin_OpenPanel")
                net.Send(ply)
                return ""
            end
            
            -- Let other systems handle specific commands
            hook.Run("Kyber_Admin_Command", ply, cmd, args)
            return ""
        end
    end)
    
    -- Override default admin functions
    function ply:IsAdmin()
        return KYBER.Admin:IsAdmin(self, 2) -- Admin level or higher
    end
    
    function ply:IsSuperAdmin()
        return KYBER.Admin:IsAdmin(self, 5) -- Superadmin level
    end
    
    -- Network handlers
    net.Receive("Kyber_Admin_ExecuteCommand", function(len, ply)
        local command = net.ReadString()
        local args = net.ReadTable()
        
        -- Verify admin status
        if not KYBER.Admin:IsAdmin(ply) then
            ply:ChatPrint("Access denied")
            return
        end
        
        -- Execute command
        hook.Run("Kyber_Admin_ExecuteCommand", ply, command, args)
    end)
    
    net.Receive("Kyber_Admin_RequestData", function(len, ply)
        if not KYBER.Admin:IsAdmin(ply) then return end
        
        local dataType = net.ReadString()
        
        if dataType == "players" then
            local players = {}
            for _, p in ipairs(player.GetAll()) do
                table.insert(players, {
                    name = p:Nick(),
                    steamID = p:SteamID64(),
                    userID = p:UserID(),
                    health = p:Health(),
                    armor = p:Armor(),
                    faction = p:GetNWString("kyber_faction", ""),
                    adminLevel = KYBER.Admin:GetLevel(p)
                })
            end
            
            net.Start("Kyber_Admin_UpdateData")
            net.WriteString("players")
            net.WriteTable(players)
            net.Send(ply)
            
        elseif dataType == "admins" then
            if KYBER.Admin:HasPermission(ply, "manage_admin_levels") then
                net.Start("Kyber_Admin_UpdateData")
                net.WriteString("admins")
                net.WriteTable(KYBER.Admin.Admins)
                net.Send(ply)
            end
            
        elseif dataType == "logs" then
            if KYBER.Admin:HasPermission(ply, "database_access") then
                local logs = KYBER.Admin:GetLogs(7)
                
                net.Start("Kyber_Admin_UpdateData")
                net.WriteString("logs")
                net.WriteTable(logs)
                net.Send(ply)
            end
        end
    end)
    
    -- Console commands for manual admin management
    concommand.Add("kyber_admin_add", function(ply, cmd, args)
        if IsValid(ply) and not KYBER.Admin:HasPermission(ply, "promote_admin") then
            return
        end
        
        if #args < 3 then
            print("Usage: kyber_admin_add <steamid> <name> <level>")
            return
        end
        
        local steamID = args[1]
        local name = args[2]
        local level = tonumber(args[3])
        
        local success, err = KYBER.Admin:AddAdmin(steamID, name, level, IsValid(ply) and ply:Nick() or "CONSOLE")
        
        if success then
            print("Added admin: " .. name .. " (Level " .. level .. ")")
        else
            print("Failed to add admin: " .. err)
        end
    end)
    
    concommand.Add("kyber_admin_remove", function(ply, cmd, args)
        if IsValid(ply) and not KYBER.Admin:HasPermission(ply, "promote_admin") then
            return
        end
        
        if #args < 1 then
            print("Usage: kyber_admin_remove <steamid>")
            return
        end
        
        local steamID = args[1]
        local success, err = KYBER.Admin:RemoveAdmin(steamID, IsValid(ply) and ply:Nick() or "CONSOLE")
        
        if success then
            print("Removed admin: " .. steamID)
        else
            print("Failed to remove admin: " .. err)
        end
    end)
    
    concommand.Add("kyber_admin_list", function(ply, cmd, args)
        if IsValid(ply) and not KYBER.Admin:IsAdmin(ply) then
            return
        end
        
        print("=== Kyber Admin List ===")
        for steamID, adminData in pairs(KYBER.Admin.Admins) do
            local levelData = KYBER.Admin.Config.levels[adminData.level]
            print(string.format("%s (%s) - %s", adminData.name, steamID, levelData.name))
        end
    end)
    
else -- CLIENT
    
    -- Admin panel will be created in the UI file
    -- This handles the basic networking
    
    net.Receive("Kyber_Admin_OpenPanel", function()
        KYBER.Admin:OpenPanel()
    end)
    
    net.Receive("Kyber_Admin_UpdateData", function()
        local dataType = net.ReadString()
        local data = net.ReadTable()
        
        if IsValid(KYBER.Admin.Panel) then
            KYBER.Admin:UpdatePanelData(dataType, data)
        end
    end)
    
end