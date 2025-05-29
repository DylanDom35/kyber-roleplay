-- kyber/modules/force/lottery.lua
KYBER.ForceLottery = KYBER.ForceLottery or {}

-- Configuration
KYBER.ForceLottery.Config = {
    -- Lottery timing
    lotteryInterval = 3600, -- 1 hour between lotteries
    minPlayersForLottery = 5, -- Minimum players online for lottery to run
    
    -- Chances
    baseChance = 0.05, -- 5% base chance to win
    maxWinners = 1, -- Maximum winners per lottery
    
    -- Cooldowns
    playerCooldown = 604800, -- 7 days before same player can win again
    characterCooldown = 86400, -- 24 hours before same character can enter again
    
    -- Requirements
    minPlaytime = 3600, -- 1 hour minimum playtime to be eligible
    minLevel = 5, -- Minimum character level (if you have a level system)
    
    -- Rewards
    forceWeapon = "weapon_lightsaber", -- Change to your scripted weapon
    startingForceLevel = 1,
    bonusCredits = 1000,
    
    -- Announcements
    announceCountdown = true,
    countdownTimes = {600, 300, 60, 30, 10} -- Announce at these seconds before lottery
}

if SERVER then
    util.AddNetworkString("Kyber_ForceLottery_Announce")
    util.AddNetworkString("Kyber_ForceLottery_Winner")
    util.AddNetworkString("Kyber_ForceLottery_Status")
    util.AddNetworkString("Kyber_ForceLottery_Enter")
    
    -- Initialize lottery data
    function KYBER.ForceLottery:Initialize()
        if not file.Exists("kyber/forcelottery", "DATA") then
            file.CreateDir("kyber/forcelottery")
        end
        
        -- Load lottery history
        if file.Exists("kyber/forcelottery/history.json", "DATA") then
            local data = file.Read("kyber/forcelottery/history.json", "DATA")
            self.History = util.JSONToTable(data) or {}
        else
            self.History = {}
        end
        
        -- Load next lottery time
        if file.Exists("kyber/forcelottery/nextlottery.txt", "DATA") then
            self.NextLotteryTime = tonumber(file.Read("kyber/forcelottery/nextlottery.txt", "DATA")) or os.time() + self.Config.lotteryInterval
        else
            self.NextLotteryTime = os.time() + self.Config.lotteryInterval
        end
        
        -- Current lottery participants
        self.CurrentParticipants = {}
        
        -- Start lottery timer
        self:StartLotteryTimer()
    end
    
    function KYBER.ForceLottery:SaveData()
        file.Write("kyber/forcelottery/history.json", util.TableToJSON(self.History))
        file.Write("kyber/forcelottery/nextlottery.txt", tostring(self.NextLotteryTime))
    end
    
    -- Check if player is eligible
    function KYBER.ForceLottery:IsEligible(ply)
        -- Check if already Force sensitive
        local isForceUser = ply:GetNWBool("kyber_force_sensitive", false)
        if isForceUser then
            return false, "You are already Force sensitive"
        end
        
        -- Check character cooldown
        local charName = ply:GetNWString("kyber_name", ply:Nick())
        for _, entry in ipairs(self.History) do
            if entry.character == charName and (os.time() - entry.timestamp) < self.Config.characterCooldown then
                local timeLeft = self.Config.characterCooldown - (os.time() - entry.timestamp)
                return false, "This character must wait " .. string.NiceTime(timeLeft) .. " before entering again"
            end
        end
        
        -- Check player cooldown (across all characters)
        local steamID = ply:SteamID64()
        for _, entry in ipairs(self.History) do
            if entry.winner and entry.steamID == steamID and (os.time() - entry.timestamp) < self.Config.playerCooldown then
                local timeLeft = self.Config.playerCooldown - (os.time() - entry.timestamp)
                return false, "You must wait " .. string.NiceTime(timeLeft) .. " before winning again"
            end
        end
        
        -- Check playtime (example - implement based on your system)
        local playtime = ply:GetNWInt("kyber_playtime", 0)
        if playtime < self.Config.minPlaytime then
            return false, "You need " .. string.NiceTime(self.Config.minPlaytime - playtime) .. " more playtime"
        end
        
        -- Check if in a Force-capable faction
        local faction = ply:GetNWString("kyber_faction", "")
        if faction ~= "" and KYBER.Factions[faction] then
            if not KYBER.Factions[faction].canUseForce then
                return false, "Your faction cannot use the Force"
            end
        end
        
        return true
    end
    
    -- Enter lottery
    function KYBER.ForceLottery:EnterLottery(ply)
        local eligible, reason = self:IsEligible(ply)
        if not eligible then
            return false, reason
        end
        
        -- Check if already entered
        for _, participant in ipairs(self.CurrentParticipants) do
            if participant.steamID == ply:SteamID64() then
                return false, "You are already entered in the lottery"
            end
        end
        
        -- Add to participants
        table.insert(self.CurrentParticipants, {
            steamID = ply:SteamID64(),
            name = ply:Nick(),
            character = ply:GetNWString("kyber_name", ply:Nick()),
            enteredAt = os.time()
        })
        
        return true
    end
    
    -- Run the lottery
    function KYBER.ForceLottery:RunLottery()
        -- Check minimum players
        if #player.GetAll() < self.Config.minPlayersForLottery then
            self:ResetLottery("Not enough players online")
            return
        end
        
        -- Check participants
        if #self.CurrentParticipants == 0 then
            self:ResetLottery("No participants entered")
            return
        end
        
        -- Filter participants who are still online
        local validParticipants = {}
        for _, participant in ipairs(self.CurrentParticipants) do
            local ply = player.GetBySteamID64(participant.steamID)
            if IsValid(ply) then
                table.insert(validParticipants, {
                    player = ply,
                    data = participant
                })
            end
        end
        
        if #validParticipants == 0 then
            self:ResetLottery("No participants online")
            return
        end
        
        -- Announce lottery starting
        net.Start("Kyber_ForceLottery_Announce")
        net.WriteString("The Force Lottery is now drawing!")
        net.WriteBool(true) -- Is important announcement
        net.Broadcast()
        
        -- Dramatic pause
        timer.Simple(3, function()
            -- Select winners
            local winners = {}
            local attempts = 0
            local maxAttempts = #validParticipants * 10
            
            while #winners < self.Config.maxWinners and #validParticipants > 0 and attempts < maxAttempts do
                attempts = attempts + 1
                
                -- Pick random participant
                local index = math.random(1, #validParticipants)
                local candidate = validParticipants[index]
                
                -- Roll for win
                if math.random() <= self.Config.baseChance then
                    table.insert(winners, candidate)
                    table.remove(validParticipants, index)
                end
            end
            
            if #winners > 0 then
                -- Process winners
                for _, winner in ipairs(winners) do
                    self:ProcessWinner(winner.player, winner.data)
                end
            else
                -- No winners
                net.Start("Kyber_ForceLottery_Announce")
                net.WriteString("The Force has chosen no one this time. The midi-chlorians remain dormant.")
                net.WriteBool(false)
                net.Broadcast()
            end
            
            -- Reset for next lottery
            self:ResetLottery()
        end)
    end
    
    function KYBER.ForceLottery:ProcessWinner(ply, participantData)
        -- Record win
        table.insert(self.History, {
            steamID = ply:SteamID64(),
            name = ply:Nick(),
            character = ply:GetNWString("kyber_name", ply:Nick()),
            timestamp = os.time(),
            winner = true
        })
        
        -- Set Force sensitive
        ply:SetNWBool("kyber_force_sensitive", true)
        ply:SetPData("kyber_force_sensitive_" .. ply:GetNWString("kyber_name", "default"), "true")
        
        -- Give Force weapon
        ply:Give(self.Config.forceWeapon)
        
        -- Give bonus credits
        local currentCredits = KYBER:GetPlayerData(ply, "credits") or 0
        KYBER:SetPlayerData(ply, "credits", currentCredits + self.Config.bonusCredits)
        
        -- Announce winner
        net.Start("Kyber_ForceLottery_Winner")
        net.WriteEntity(ply)
        net.WriteString(ply:GetNWString("kyber_name", ply:Nick()))
        net.Broadcast()
        
        -- Special effects for winner
        ply:EmitSound("ambient/energy/zap1.wav")
        ply:ScreenFade(SCREENFADE.IN, Color(100, 100, 255, 100), 2, 0)
        
        -- Log
        self:SaveData()
        
        print("[Force Lottery] Winner: " .. ply:Nick() .. " (" .. ply:SteamID64() .. ")")
    end
    
    function KYBER.ForceLottery:ResetLottery(reason)
        -- Clear participants
        self.CurrentParticipants = {}
        
        -- Set next lottery time
        self.NextLotteryTime = os.time() + self.Config.lotteryInterval
        self:SaveData()
        
        -- Restart timer
        self:StartLotteryTimer()
        
        if reason then
            print("[Force Lottery] Reset: " .. reason)
        end
    end
    
    function KYBER.ForceLottery:StartLotteryTimer()
        timer.Remove("KyberForceLotteryMain")
        timer.Remove("KyberForceLotteryCountdown")
        
        -- Main lottery timer
        timer.Create("KyberForceLotteryMain", 1, 0, function()
            local timeLeft = self.NextLotteryTime - os.time()
            
            if timeLeft <= 0 then
                self:RunLottery()
                timer.Remove("KyberForceLotteryMain")
            elseif self.Config.announceCountdown then
                -- Check countdown announcements
                for _, countdownTime in ipairs(self.Config.countdownTimes) do
                    if timeLeft == countdownTime then
                        net.Start("Kyber_ForceLottery_Announce")
                        net.WriteString("Force Lottery in " .. string.NiceTime(countdownTime) .. "! Use /forcelottery to enter!")
                        net.WriteBool(false)
                        net.Broadcast()
                        break
                    end
                end
            end
        end)
    end
    
    -- Network handlers
    net.Receive("Kyber_ForceLottery_Enter", function(len, ply)
        local success, reason = KYBER.ForceLottery:EnterLottery(ply)
        
        if success then
            ply:ChatPrint("You have entered the Force Lottery! May the Force be with you.")
            
            -- Notify others
            for _, p in ipairs(player.GetAll()) do
                if p ~= ply then
                    p:ChatPrint(ply:GetNWString("kyber_name", ply:Nick()) .. " has entered the Force Lottery.")
                end
            end
        else
            ply:ChatPrint("Cannot enter lottery: " .. reason)
        end
    end)
    
    -- Chat commands
    hook.Add("PlayerSay", "KyberForceLotteryCommands", function(ply, text)
        local lower = string.lower(text)
        
        if lower == "/forcelottery" or lower == "!forcelottery" then
            -- Show lottery info
            local timeLeft = KYBER.ForceLottery.NextLotteryTime - os.time()
            
            if timeLeft > 0 then
                ply:ChatPrint("=== Force Lottery ===")
                ply:ChatPrint("Next lottery in: " .. string.NiceTime(timeLeft))
                ply:ChatPrint("Participants: " .. #KYBER.ForceLottery.CurrentParticipants)
                ply:ChatPrint("Your status: " .. (KYBER.ForceLottery:IsEligible(ply) and "Eligible" or "Not eligible"))
                ply:ChatPrint("Use /joinlottery to enter!")
            else
                ply:ChatPrint("Lottery is currently being drawn!")
            end
            
            return ""
        elseif lower == "/joinlottery" or lower == "!joinlottery" then
            net.Start("Kyber_ForceLottery_Enter")
            net.SendToServer()
            return ""
        end
    end)
    
    -- Initialize on server start
    hook.Add("Initialize", "KyberForceLotteryInit", function()
        KYBER.ForceLottery:Initialize()
    end)
    
    -- Check Force sensitivity on spawn
    hook.Add("PlayerSpawn", "KyberCheckForceSensitive", function(ply)
        timer.Simple(1, function()
            if not IsValid(ply) then return end
            
            local charName = ply:GetNWString("kyber_name", "default")
            local isForceSensitive = ply:GetPData("kyber_force_sensitive_" .. charName, "false") == "true"
            
            ply:SetNWBool("kyber_force_sensitive", isForceSensitive)
            
            if isForceSensitive then
                -- Give Force weapon if they don't have it
                if not ply:HasWeapon(KYBER.ForceLottery.Config.forceWeapon) then
                    ply:Give(KYBER.ForceLottery.Config.forceWeapon)
                end
            end
        end)
    end)
    
else -- CLIENT
    
    -- Announcement handler
    net.Receive("Kyber_ForceLottery_Announce", function()
        local message = net.ReadString()
        local isImportant = net.ReadBool()
        
        -- Chat message
        chat.AddText(
            Color(100, 100, 255), "[Force Lottery] ",
            Color(255, 255, 255), message
        )
        
        -- Sound effect
        if isImportant then
            surface.PlaySound("ambient/alarms/klaxon1.wav")
        else
            surface.PlaySound("buttons/button3.wav")
        end
        
        -- Screen notification for important announcements
        if isImportant then
            notification.AddLegacy(message, NOTIFY_HINT, 5)
        end
    end)
    
    -- Winner announcement
    net.Receive("Kyber_ForceLottery_Winner", function()
        local winner = net.ReadEntity()
        local charName = net.ReadString()
        
        -- Epic announcement
        chat.AddText(
            Color(255, 215, 0), "★ ",
            Color(100, 255, 100), "THE FORCE AWAKENS! ",
            Color(255, 255, 255), charName,
            Color(100, 255, 100), " has become Force Sensitive! ",
            Color(255, 215, 0), "★"
        )
        
        -- Sound
        surface.PlaySound("ambient/energy/newspark11.wav")
        
        -- Visual effect if it's us
        if winner == LocalPlayer() then
            -- Create dramatic effect
            hook.Add("HUDPaint", "ForceLotteryWinEffect", function()
                local alpha = math.sin(CurTime() * 2) * 50 + 50
                surface.SetDrawColor(100, 100, 255, alpha)
                surface.DrawRect(0, 0, ScrW(), ScrH())
            end)
            
            -- Remove effect after 5 seconds
            timer.Simple(5, function()
                hook.Remove("HUDPaint", "ForceLotteryWinEffect")
            end)
            
            -- Notification
            notification.AddLegacy("You have become Force Sensitive!", NOTIFY_HINT, 10)
            
            -- Open special menu
            timer.Simple(2, function()
                Derma_Message(
                    "The Force flows through you now.\n\n" ..
                    "You have been granted Force sensitivity and a lightsaber.\n" ..
                    "Use your new powers wisely.\n\n" ..
                    "May the Force be with you.",
                    "The Force Awakens",
                    "I understand"
                )
            end)
        end
    end)
    
    -- HUD element for lottery timer
    hook.Add("HUDPaint", "KyberForceLotteryHUD", function()
        if not KYBER.ForceLottery then return end
        
        local timeLeft = (KYBER.ForceLottery.NextLotteryTime or 0) - os.time()
        
        if timeLeft > 0 and timeLeft < 600 then -- Show when less than 10 minutes
            local x = ScrW() - 200
            local y = 100
            
            -- Background
            draw.RoundedBox(6, x - 10, y - 5, 190, 50, Color(0, 0, 0, 200))
            
            -- Title
            draw.SimpleText("Force Lottery", "DermaDefaultBold", x, y, Color(100, 100, 255), TEXT_ALIGN_LEFT)
            
            -- Timer
            local timeStr = string.FormattedTime(timeLeft, "%02i:%02i")
            draw.SimpleText(timeStr.m .. ":" .. timeStr.s, "DermaLarge", x, y + 15, Color(255, 255, 255), TEXT_ALIGN_LEFT)
            
            -- Participants
            local participants = KYBER.ForceLottery.CurrentParticipants and #KYBER.ForceLottery.CurrentParticipants or 0
            draw.SimpleText(participants .. " entered", "DermaDefault", x, y + 35, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        end
    end)
    
    -- Sync lottery data
    net.Receive("Kyber_ForceLottery_Status", function()
        KYBER.ForceLottery = KYBER.ForceLottery or {}
        KYBER.ForceLottery.NextLotteryTime = net.ReadInt(32)
        KYBER.ForceLottery.CurrentParticipants = net.ReadTable()
    end)
    
    -- Request status on spawn
    hook.Add("InitPostEntity", "KyberRequestLotteryStatus", function()
        timer.Simple(2, function()
            net.Start("Kyber_ForceLottery_Status")
            net.SendToServer()
        end)
    end)
end

-- Admin commands
if SERVER then
    concommand.Add("kyber_forcelottery_force", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        print("[Admin] Forcing lottery draw...")
        KYBER.ForceLottery:RunLottery()
    end)
    
    concommand.Add("kyber_forcelottery_reset", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        KYBER.ForceLottery:ResetLottery("Admin reset")
        ply:ChatPrint("Force lottery reset")
    end)
    
    concommand.Add("kyber_forcelottery_grant", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local target = args[1] and player.GetBySteamID(args[1]) or ply:GetEyeTrace().Entity
        
        if IsValid(target) and target:IsPlayer() then
            target:SetNWBool("kyber_force_sensitive", true)
            target:SetPData("kyber_force_sensitive_" .. target:GetNWString("kyber_name", "default"), "true")
            target:Give(KYBER.ForceLottery.Config.forceWeapon)
            
            ply:ChatPrint("Granted Force sensitivity to " .. target:Nick())
            target:ChatPrint("You have been granted Force sensitivity by an admin!")
        else
            ply:ChatPrint("Invalid target")
        end
    end)
end