-- kyber/modules/admin/core.lua
KYBER.Admin = KYBER.Admin or {}

-- Core admin configuration
KYBER.Admin.Config = {
    -- Superadmins (hardcoded into gamemode)
    superadmins = {
        ["76561198065092442"] = {name = "GamemodeCreator", level = 5},
        ["76561198065092443"] = {name = "HeadAdmin", level = 5},
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
        ["edit_gamemode"] = 4,
        ["force_character_creation"] = 4,
        ["manage_server_settings"] = 4,
        
        -- Level 5 - Superadmin
        ["all_permissions"] = 5,
        ["manage_server"] = 5,
        ["console_commands"] = 5,
        ["shutdown_server"] = 5
    }
}

-- Admin data storage
KYBER.Admin.Data = {}

-- Initialize admin system
function KYBER.Admin:Initialize()
    self:LoadAdminData()
    self:SetupHooks()
    
    print("[KYBER] Admin system initialized")
end

-- Load admin data from file
function KYBER.Admin:LoadAdminData()
    if file.Exists("kyber/admin/admins.json", "DATA") then
        local data = file.Read("kyber/admin/admins.json", "DATA")
        self.Data = util.JSONToTable(data) or {}
    else
        self.Data = {}
    end
end

-- Save admin data to file
function KYBER.Admin:SaveAdminData()
    if not file.Exists("kyber/admin", "DATA") then
        file.CreateDir("kyber/admin")
    end
    file.Write("kyber/admin/admins.json", util.TableToJSON(self.Data))
end

-- Check if player is admin
function KYBER.Admin:IsAdmin(ply, minLevel)
    if not IsValid(ply) then return false end
    
    local steamID = ply:SteamID64()
    minLevel = minLevel or 1
    
    -- Check superadmins first
    if self.Config.superadmins[steamID] then
        return self.Config.superadmins[steamID].level >= minLevel
    end
    
    -- Check stored admin data
    if self.Data[steamID] and self.Data[steamID].level >= minLevel then
        return true
    end
    
    return false
end

-- Get admin level
function KYBER.Admin:GetAdminLevel(ply)
    if not IsValid(ply) then return 0 end
    
    local steamID = ply:SteamID64()
    
    -- Check superadmins
    if self.Config.superadmins[steamID] then
        return self.Config.superadmins[steamID].level
    end
    
    -- Check stored data
    if self.Data[steamID] then
        return self.Data[steamID].level
    end
    
    return 0
end

-- Check if player has permission
function KYBER.Admin:HasPermission(ply, permission)
    if not IsValid(ply) then return false end
    
    local adminLevel = self:GetAdminLevel(ply)
    local requiredLevel = self.Config.permissions[permission] or 999
    
    return adminLevel >= requiredLevel
end

-- Add admin
function KYBER.Admin:AddAdmin(steamID, name, level, promoter)
    level = math.Clamp(level, 1, 4) -- Limit to non-superadmin levels
    
    self.Data[steamID] = {
        name = name,
        level = level,
        promoter = promoter,
        promoted = os.time()
    }
    
    self:SaveAdminData()
    
    -- Find player if online and set their status
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID64() == steamID then
            self:SetAdminStatus(ply)
            break
        end
    end
    
    return true
end

-- Remove admin
function KYBER.Admin:RemoveAdmin(steamID, demoter)
    if not self.Data[steamID] then return false end
    
    local oldData = self.Data[steamID]
    self.Data[steamID] = nil
    self:SaveAdminData()
    
    -- Find player if online and update their status
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID64() == steamID then
            self:SetAdminStatus(ply)
            break
        end
    end
    
    self:LogAction(demoter or "SYSTEM", "DEMOTE", oldData.name .. " removed from admin")
    return true
end

-- Set player admin status (networked variables)
function KYBER.Admin:SetAdminStatus(ply)
    if not IsValid(ply) then return end
    
    local level = self:GetAdminLevel(ply)
    local config = self.Config.levels[level]
    
    ply:SetNWInt("kyber_admin_level", level)
    
    if config then
        ply:SetNWString("kyber_admin_prefix", config.prefix)
        ply:SetNWString("kyber_admin_color", config.color.r .. "," .. config.color.g .. "," .. config.color.b)
    else
        ply:SetNWString("kyber_admin_prefix", "")
        ply:SetNWString("kyber_admin_color", "255,255,255")
    end
end

-- Get all admins
function KYBER.Admin:GetAllAdmins()
    local admins = {}
    
    -- Add superadmins
    for steamID, data in pairs(self.Config.superadmins) do
        table.insert(admins, {
            steamID = steamID,
            name = data.name,
            level = data.level,
            type = "superadmin"
        })
    end
    
    -- Add regular admins
    for steamID, data in pairs(self.Data) do
        table.insert(admins, {
            steamID = steamID,
            name = data.name,
            level = data.level,
            promoter = data.promoter,
            promoted = data.promoted,
            type = "admin"
        })
    end
    
    return admins
end

-- Logging system
function KYBER.Admin:LogAction(admin, action, details, target)
    local logEntry = {
        admin = admin,
        adminID = IsValid(admin) and admin:SteamID64() or "CONSOLE",
        action = action,
        details = details,
        target = target,
        timestamp = os.time()
    }
    
    -- Ensure log directory exists
    if not file.Exists("kyber/admin/logs", "DATA") then
        file.CreateDir("kyber/admin/logs")
    end
    
    -- Write to daily log file
    local date = os.date("%Y-%m-%d", os.time())
    local logFile = "kyber/admin/logs/" .. date .. ".json"
    
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

-- Setup hooks
function KYBER.Admin:SetupHooks()
    if SERVER then
        -- Network strings
        util.AddNetworkString("Kyber_Admin_OpenPanel")
        util.AddNetworkString("Kyber_Admin_ExecuteCommand")
        util.AddNetworkString("Kyber_Admin_RequestData")
        util.AddNetworkString("Kyber_Admin_UpdateData")
        
        -- Set admin status on spawn
        hook.Add("PlayerInitialSpawn", "KyberAdminSpawn", function(ply)
            timer.Simple(1, function()
                if IsValid(ply) then
                    self:SetAdminStatus(ply)
                end
            end)
        end)
        
        -- Admin chat command
        hook.Add("PlayerSay", "KyberAdminChat", function(ply, text)
            if string.sub(text, 1, 1) == "!" and self:IsAdmin(ply) then
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
        
        -- Network handlers
        net.Receive("Kyber_Admin_ExecuteCommand", function(len, ply)
            local command = net.ReadString()
            local args = net.ReadTable()
            
            -- Verify admin status
            if not self:IsAdmin(ply) then
                ply:ChatPrint("Access denied")
                return
            end
            
            -- Execute command
            hook.Run("Kyber_Admin_ExecuteCommand", ply, command, args)
        end)
        
        net.Receive("Kyber_Admin_RequestData", function(len, ply)
            if not self:IsAdmin(ply) then return end
            
            local dataType = net.ReadString()
            
            if dataType == "players" then
                local players = {}
                for _, p in ipairs(player.GetAll()) do
                    table.insert(players, {
                        name = p:Nick(),
                        steamID = p:SteamID64(),
                        userID = p:UserID(),
                        health = p:Health(),
                        maxHealth = p:GetMaxHealth(),
                        armor = p:Armor(),
                        faction = p:GetNWString("kyber_faction", "None"),
                        adminLevel = self:GetAdminLevel(p)
                    })
                end
                
                net.Start("Kyber_Admin_UpdateData")
                net.WriteString("players")
                net.WriteTable(players)
                net.Send(ply)
                
            elseif dataType == "admins" then
                local admins = self:GetAllAdmins()
                
                net.Start("Kyber_Admin_UpdateData")
                net.WriteString("admins")
                net.WriteTable(admins)
                net.Send(ply)
                
            elseif dataType == "logs" then
                local logs = self:GetLogs(7) -- Last 7 days
                
                net.Start("Kyber_Admin_UpdateData")
                net.WriteString("logs")
                net.WriteTable(logs)
                net.Send(ply)
            end
        end)
    end
end

-- Override default admin functions
if SERVER then
    local meta = FindMetaTable("Player")
    
    -- Override IsAdmin to use Kyber system
    function meta:IsAdmin()
        return KYBER.Admin:IsAdmin(self, 2) -- Admin level or higher
    end
    
    -- Override IsSuperAdmin to use Kyber system
    function meta:IsSuperAdmin()
        return KYBER.Admin:IsAdmin(self, 5) -- Superadmin level
    end
    
    -- Add Kyber-specific admin functions
    function meta:GetKyberAdminLevel()
        return KYBER.Admin:GetAdminLevel(self)
    end
    
    function meta:HasKyberPermission(permission)
        return KYBER.Admin:HasPermission(self, permission)
    end
    
    function meta:IsKyberAdmin(minLevel)
        return KYBER.Admin:IsAdmin(self, minLevel)
    end
end

-- Console commands for admin management
if SERVER then
    concommand.Add("kyber_admin_add", function(ply, cmd, args)
        -- Only superadmins can use console commands
        if IsValid(ply) and not KYBER.Admin:IsAdmin(ply, 5) then
            ply:ChatPrint("Access denied")
            return
        end
        
        if #args < 3 then
            print("Usage: kyber_admin_add <steamid64> <name> <level>")
            return
        end
        
        local steamID = args[1]
        local name = args[2]
        local level = tonumber(args[3])
        
        if not level or level < 1 or level > 4 then
            print("Invalid admin level (1-4)")
            return
        end
        
        KYBER.Admin:AddAdmin(steamID, name, level, IsValid(ply) and ply:Nick() or "CONSOLE")
        print("Added " .. name .. " as level " .. level .. " admin")
    end)
    
    concommand.Add("kyber_admin_remove", function(ply, cmd, args)
        -- Only superadmins can use console commands
        if IsValid(ply) and not KYBER.Admin:IsAdmin(ply, 5) then
            ply:ChatPrint("Access denied")
            return
        end
        
        if #args < 1 then
            print("Usage: kyber_admin_remove <steamid64>")
            return
        end
        
        local steamID = args[1]
        
        if KYBER.Admin:RemoveAdmin(steamID, IsValid(ply) and ply:Nick() or "CONSOLE") then
            print("Removed admin: " .. steamID)
        else
            print("Admin not found: " .. steamID)
        end
    end)
    
    concommand.Add("kyber_admin_list", function(ply, cmd, args)
        -- Only superadmins can use console commands
        if IsValid(ply) and not KYBER.Admin:IsAdmin(ply, 5) then
            ply:ChatPrint("Access denied")
            return
        end
        
        local admins = KYBER.Admin:GetAllAdmins()
        print("=== KYBER ADMIN LIST ===")
        
        for _, admin in ipairs(admins) do
            local levelName = KYBER.Admin.Config.levels[admin.level] and KYBER.Admin.Config.levels[admin.level].name or "Unknown"
            print(admin.name .. " (" .. admin.steamID .. ") - Level " .. admin.level .. " (" .. levelName .. ") [" .. admin.type .. "]")
        end
        
        print("=== END LIST ===")
    end)
end

-- Initialize on server start
if SERVER then
    hook.Add("Initialize", "KyberAdminInit", function()
        KYBER.Admin:Initialize()
    end)
end

-- Client-side admin status display
if CLIENT then
    -- Admin tag in scoreboard/chat
    hook.Add("OnPlayerChat", "KyberAdminChat", function(ply, text, teamChat, dead)
        if not IsValid(ply) then return end
        
        local adminLevel = ply:GetNWInt("kyber_admin_level", 0)
        if adminLevel > 0 then
            local prefix = ply:GetNWString("kyber_admin_prefix", "")
            local colorStr = ply:GetNWString("kyber_admin_color", "255,255,255")
            local r, g, b = colorStr:match("(%d+),(%d+),(%d+)")
            
            if prefix ~= "" then
                chat.AddText(
                    Color(tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255), prefix .. " ",
                    team.GetColor(ply:Team()) or Color(255, 255, 255), ply:Nick(),
                    Color(255, 255, 255), ": " .. text
                )
                return true
            end
        end
    end)
    
    -- Admin HUD indicator
    hook.Add("HUDPaint", "KyberAdminHUD", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        local adminLevel = ply:GetNWInt("kyber_admin_level", 0)
        if adminLevel > 0 then
            local config = KYBER.Admin.Config.levels[adminLevel]
            if config then
                local text = "ADMIN MODE: " .. config.name
                local w, h = surface.GetTextSize(text)
                
                draw.RoundedBox(4, ScrW() - w - 20, 10, w + 10, 25, Color(0, 0, 0, 150))
                draw.SimpleText(text, "DermaDefault", ScrW() - w/2 - 15, 22, config.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end)
    
    -- Bind admin panel key
    hook.Add("PlayerButtonDown", "KyberAdminKey", function(ply, button)
        if button == KEY_F4 and ply:GetNWInt("kyber_admin_level", 0) > 0 then
            net.Start("Kyber_Admin_OpenPanel")
            net.SendToServer()
        end
    end)
end

-- Utility functions
function KYBER.Admin:GetOnlineAdmins()
    local admins = {}
    for _, ply in ipairs(player.GetAll()) do
        if self:IsAdmin(ply) then
            table.insert(admins, ply)
        end
    end
    return admins
end

function KYBER.Admin:NotifyAdmins(message, minLevel)
    minLevel = minLevel or 1
    for _, ply in ipairs(player.GetAll()) do
        if self:IsAdmin(ply, minLevel) then
            ply:ChatPrint("[ADMIN] " .. message)
        end
    end
end

function KYBER.Admin:BroadcastAdminAction(admin, action, target)
    local adminName = IsValid(admin) and admin:Nick() or "CONSOLE"
    local targetName = IsValid(target) and target:Nick() or "Unknown"
    local message = adminName .. " " .. action .. " " .. targetName
    
    self:NotifyAdmins(message)
    self:LogAction(adminName, action:upper(), targetName)
end

-- Export system for other modules
KYBER.Admin.IsAdmin = function(ply, level) return KYBER.Admin:IsAdmin(ply, level) end
KYBER.Admin.HasPermission = function(ply, perm) return KYBER.Admin:HasPermission(ply, perm) end
KYBER.Admin.GetAdminLevel = function(ply) return KYBER.Admin:GetAdminLevel(ply) end