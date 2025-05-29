-- kyber/modules/communication/system.lua
KYBER.Comms = KYBER.Comms or {}

-- Communication configuration
KYBER.Comms.Config = {
    -- Holocom settings
    holocomRange = 5000,              -- Max distance for holocalls
    holocomQuality = {
        [0] = {name = "Static", clarity = 0.3, cost = 0},
        [1] = {name = "Poor", clarity = 0.5, cost = 10},
        [2] = {name = "Standard", clarity = 0.7, cost = 25},
        [3] = {name = "Clear", clarity = 0.9, cost = 50},
        [4] = {name = "Perfect", clarity = 1.0, cost = 100}
    },
    
    -- Broadcast settings
    broadcastCooldown = 300,          -- 5 minutes between faction broadcasts
    broadcastCost = 500,              -- Cost to send faction broadcast
    emergencyCooldown = 600,          -- 10 minutes between distress beacons
    
    -- Message system
    maxMessages = 50,                 -- Max stored messages per player
    messageExpiry = 604800,           -- Messages expire after 7 days
    attachmentMaxSize = 5,            -- Max items per message
    
    -- News/propaganda
    newsPostCost = 1000,              -- Cost to post news
    newsLifetime = 86400,             -- News lasts 24 hours
    maxNewsPosts = 20,                -- Maximum active news posts
    
    -- Encryption
    encryptionLevels = {
        [0] = {name = "None", hackDifficulty = 0},
        [1] = {name = "Basic", hackDifficulty = 5},
        [2] = {name = "Advanced", hackDifficulty = 10},
        [3] = {name = "Military", hackDifficulty = 15},
        [4] = {name = "Quantum", hackDifficulty = 20}
    }
}

if SERVER then
    util.AddNetworkString("Kyber_Comms_OpenHolocom")
    util.AddNetworkString("Kyber_Comms_StartCall")
    util.AddNetworkString("Kyber_Comms_EndCall")
    util.AddNetworkString("Kyber_Comms_SendMessage")
    util.AddNetworkString("Kyber_Comms_ReceiveMessage")
    util.AddNetworkString("Kyber_Comms_Broadcast")
    util.AddNetworkString("Kyber_Comms_DistressBeacon")
    util.AddNetworkString("Kyber_Comms_PostNews")
    util.AddNetworkString("Kyber_Comms_UpdateNews")
    util.AddNetworkString("Kyber_Comms_OpenMailbox")
    util.AddNetworkString("Kyber_Comms_DeleteMessage")
    util.AddNetworkString("Kyber_Comms_VoiceData")
    
    -- Initialize communication data
    function KYBER.Comms:Initialize(ply)
        ply.KyberComms = {
            messages = {},
            contacts = {},
            blocked = {},
            lastBroadcast = 0,
            lastDistress = 0,
            activeCall = nil,
            callQuality = 2 -- Default standard quality
        }
        
        -- Load saved data
        self:LoadPlayerData(ply)
    end
    
    function KYBER.Comms:LoadPlayerData(ply)
        local steamID = ply:SteamID64()
        local charName = ply:GetNWString("kyber_name", "default")
        local path = "kyber/comms/" .. steamID .. "_" .. charName .. ".json"
        
        if file.Exists(path, "DATA") then
            local data = file.Read(path, "DATA")
            local saved = util.JSONToTable(data)
            if saved then
                ply.KyberComms.messages = saved.messages or {}
                ply.KyberComms.contacts = saved.contacts or {}
                ply.KyberComms.blocked = saved.blocked or {}
                
                -- Clean expired messages
                self:CleanExpiredMessages(ply)
            end
        end
    end
    
    function KYBER.Comms:Save(ply)
        if not IsValid(ply) or not ply.KyberComms then return end
        
        local steamID = ply:SteamID64()
        local charName = ply:GetNWString("kyber_name", "default")
        local path = "kyber/comms/" .. steamID .. "_" .. charName .. ".json"
        
        if not file.Exists("kyber/comms", "DATA") then
            file.CreateDir("kyber/comms")
        end
        
        local data = {
            messages = ply.KyberComms.messages,
            contacts = ply.KyberComms.contacts,
            blocked = ply.KyberComms.blocked
        }
        
        file.Write(path, util.TableToJSON(data))
    end
    
    -- Holocom system
    function KYBER.Comms:StartHoloCall(caller, recipient, quality)
        if not IsValid(caller) or not IsValid(recipient) then
            return false, "Invalid caller or recipient"
        end
        
        -- Check if either is already in a call
        if caller.KyberComms.activeCall or recipient.KyberComms.activeCall then
            return false, "One party is already in a call"
        end
        
        -- Check distance
        local distance = caller:GetPos():Distance(recipient:GetPos())
        if distance > self.Config.holocomRange then
            return false, "Target is out of range"
        end
        
        -- Check blocked
        if recipient.KyberComms.blocked[caller:SteamID64()] then
            return false, "You have been blocked by this person"
        end
        
        -- Check credits for quality
        local qualityData = self.Config.holocomQuality[quality]
        if not qualityData then
            return false, "Invalid quality level"
        end
        
        local credits = KYBER:GetPlayerData(caller, "credits") or 0
        if credits < qualityData.cost then
            return false, "Insufficient credits for this quality"
        end
        
        -- Create call
        local callID = "CALL_" .. os.time() .. "_" .. math.random(1000, 9999)
        
        caller.KyberComms.activeCall = {
            id = callID,
            partner = recipient,
            quality = quality,
            startTime = CurTime(),
            isOutgoing = true
        }
        
        recipient.KyberComms.activeCall = {
            id = callID,
            partner = caller,
            quality = quality,
            startTime = CurTime(),
            isOutgoing = false
        }
        
        -- Notify both parties
        net.Start("Kyber_Comms_StartCall")
        net.WriteEntity(recipient)
        net.WriteInt(quality, 4)
        net.WriteBool(true) -- Is caller
        net.Send(caller)
        
        net.Start("Kyber_Comms_StartCall")
        net.WriteEntity(caller)
        net.WriteInt(quality, 4)
        net.WriteBool(false) -- Is recipient
        net.Send(recipient)
        
        -- Start billing timer
        self:StartCallBilling(caller, callID, qualityData.cost)
        
        return true
    end
    
    function KYBER.Comms:StartCallBilling(ply, callID, costPerMinute)
        local timerName = "HoloCallBilling_" .. callID
        
        timer.Create(timerName, 60, 0, function()
            if not IsValid(ply) or not ply.KyberComms.activeCall or ply.KyberComms.activeCall.id ~= callID then
                timer.Remove(timerName)
                return
            end
            
            local credits = KYBER:GetPlayerData(ply, "credits") or 0
            if credits >= costPerMinute then
                KYBER:SetPlayerData(ply, "credits", credits - costPerMinute)
            else
                -- End call due to insufficient funds
                self:EndHoloCall(ply)
                ply:ChatPrint("Call ended: Insufficient credits")
            end
        end)
    end
    
    function KYBER.Comms:EndHoloCall(ply)
        if not ply.KyberComms.activeCall then return end
        
        local partner = ply.KyberComms.activeCall.partner
        local callID = ply.KyberComms.activeCall.id
        
        -- Calculate duration
        local duration = CurTime() - ply.KyberComms.activeCall.startTime
        
        -- Clear call data
        ply.KyberComms.activeCall = nil
        
        if IsValid(partner) then
            partner.KyberComms.activeCall = nil
            
            net.Start("Kyber_Comms_EndCall")
            net.WriteFloat(duration)
            net.Send(partner)
        end
        
        net.Start("Kyber_Comms_EndCall")
        net.WriteFloat(duration)
        net.Send(ply)
        
        -- Stop billing
        timer.Remove("HoloCallBilling_" .. callID)
    end
    
    -- Message system
    function KYBER.Comms:SendMessage(sender, recipientName, subject, content, attachments, encrypted)
        -- Find recipient by character name
        local recipient = nil
        for _, p in ipairs(player.GetAll()) do
            if p:GetNWString("kyber_name", p:Nick()) == recipientName then
                recipient = p
                break
            end
        end
        
        -- If not online, check if character exists
        if not recipient then
            -- Store for offline delivery
            local offlinePath = "kyber/comms/offline/" .. util.CRC(recipientName) .. ".json"
            local offlineMessages = {}
            
            if file.Exists(offlinePath, "DATA") then
                offlineMessages = util.JSONToTable(file.Read(offlinePath, "DATA")) or {}
            end
            
            -- Create message
            local message = {
                id = "MSG_" .. os.time() .. "_" .. math.random(1000, 9999),
                sender = sender:GetNWString("kyber_name", sender:Nick()),
                senderID = sender:SteamID64(),
                subject = subject,
                content = content,
                attachments = attachments or {},
                encrypted = encrypted or 0,
                timestamp = os.time(),
                read = false
            }
            
            table.insert(offlineMessages, message)
            
            -- Save offline messages
            if not file.Exists("kyber/comms/offline", "DATA") then
                file.CreateDir("kyber/comms/offline")
            end
            
            file.Write(offlinePath, util.TableToJSON(offlineMessages))
            
            sender:ChatPrint("Message sent to " .. recipientName .. " (offline delivery)")
            return true
        end
        
        -- Check if blocked
        if recipient.KyberComms.blocked[sender:SteamID64()] then
            sender:ChatPrint("You cannot send messages to this person")
            return false
        end
        
        -- Check message limit
        if #recipient.KyberComms.messages >= self.Config.maxMessages then
            -- Remove oldest message
            table.remove(recipient.KyberComms.messages, 1)
        end
        
        -- Create message
        local message = {
            id = "MSG_" .. os.time() .. "_" .. math.random(1000, 9999),
            sender = sender:GetNWString("kyber_name", sender:Nick()),
            senderID = sender:SteamID64(),
            subject = subject,
            content = content,
            attachments = attachments or {},
            encrypted = encrypted or 0,
            timestamp = os.time(),
            read = false
        }
        
        -- Process attachments (remove from sender inventory)
        for _, attachment in ipairs(attachments) do
            KYBER.Inventory:RemoveItem(sender, attachment.id, attachment.amount)
        end
        
        -- Add to recipient's messages
        table.insert(recipient.KyberComms.messages, 1, message) -- Insert at beginning
        
        -- Notify recipient
        net.Start("Kyber_Comms_ReceiveMessage")
        net.WriteTable(message)
        net.Send(recipient)
        
        recipient:ChatPrint("New message from " .. message.sender .. ": " .. subject)
        recipient:EmitSound("buttons/button14.wav")
        
        -- Save
        self:Save(recipient)
        
        return true
    end
    
    -- Faction broadcast
    function KYBER.Comms:SendFactionBroadcast(sender, message)
        local faction = sender:GetNWString("kyber_faction", "")
        if faction == "" then
            return false, "You must be in a faction to broadcast"
        end
        
        -- Check cooldown
        if CurTime() - sender.KyberComms.lastBroadcast < self.Config.broadcastCooldown then
            local remaining = self.Config.broadcastCooldown - (CurTime() - sender.KyberComms.lastBroadcast)
            return false, "Broadcast cooldown: " .. math.ceil(remaining) .. " seconds"
        end
        
        -- Check rank permissions
        local rank = sender:GetNWString("kyber_rank", "")
        local factionData = KYBER.Factions[faction]
        if factionData and factionData.ranks then
            local rankIndex = 0
            for i, r in ipairs(factionData.ranks) do
                if r == rank then
                    rankIndex = i
                    break
                end
            end
            
            -- Only officers and above can broadcast
            if rankIndex < #factionData.ranks - 2 then
                return false, "Insufficient rank to broadcast"
            end
        end
        
        -- Check cost
        local credits = KYBER:GetPlayerData(sender, "credits") or 0
        if credits < self.Config.broadcastCost then
            return false, "Insufficient credits (need " .. self.Config.broadcastCost .. ")"
        end
        
        -- Deduct cost
        KYBER:SetPlayerData(sender, "credits", credits - self.Config.broadcastCost)
        
        -- Send broadcast
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetNWString("kyber_faction", "") == faction then
                net.Start("Kyber_Comms_Broadcast")
                net.WriteString("faction")
                net.WriteString(sender:GetNWString("kyber_name", sender:Nick()))
                net.WriteString(message)
                net.WriteColor(factionData.color or Color(255, 255, 255))
                net.Send(ply)
            end
        end
        
        -- Update cooldown
        sender.KyberComms.lastBroadcast = CurTime()
        
        return true
    end
    
    -- Distress beacon
    function KYBER.Comms:SendDistressBeacon(sender, message)
        -- Check cooldown
        if CurTime() - sender.KyberComms.lastDistress < self.Config.emergencyCooldown then
            local remaining = self.Config.emergencyCooldown - (CurTime() - sender.KyberComms.lastDistress)
            return false, "Distress cooldown: " .. math.ceil(remaining) .. " seconds"
        end
        
        -- Send to all players within range
        local senderPos = sender:GetPos()
        local faction = sender:GetNWString("kyber_faction", "")
        
        for _, ply in ipairs(player.GetAll()) do
            local distance = ply:GetPos():Distance(senderPos)
            
            -- Faction members get unlimited range
            if ply:GetNWString("kyber_faction", "") == faction or distance <= 3000 then
                net.Start("Kyber_Comms_DistressBeacon")
                net.WriteEntity(sender)
                net.WriteVector(senderPos)
                net.WriteString(message)
                net.WriteFloat(distance)
                net.Send(ply)
            end
        end
        
        -- Create map marker
        sender:SetNWVector("kyber_distress_pos", senderPos)
        sender:SetNWFloat("kyber_distress_time", CurTime() + 300) -- 5 minute marker
        
        -- Update cooldown
        sender.KyberComms.lastDistress = CurTime()
        
        return true
    end
    
    -- News system
    KYBER.Comms.NewsBoard = {}
    
    function KYBER.Comms:PostNews(author, headline, content, faction)
        -- Check if too many posts
        if #self.NewsBoard >= self.Config.maxNewsPosts then
            -- Remove oldest
            table.remove(self.NewsBoard, 1)
        end
        
        -- Check cost
        local credits = KYBER:GetPlayerData(author, "credits") or 0
        if credits < self.Config.newsPostCost then
            return false, "Insufficient credits (need " .. self.Config.newsPostCost .. ")"
        end
        
        -- Deduct cost
        KYBER:SetPlayerData(author, "credits", credits - self.Config.newsPostCost)
        
        -- Create news post
        local post = {
            id = "NEWS_" .. os.time() .. "_" .. math.random(1000, 9999),
            author = author:GetNWString("kyber_name", author:Nick()),
            authorID = author:SteamID64(),
            headline = headline,
            content = content,
            faction = faction, -- Optional faction association
            timestamp = os.time(),
            expires = os.time() + self.Config.newsLifetime,
            views = 0
        }
        
        table.insert(self.NewsBoard, post)
        
        -- Broadcast update
        net.Start("Kyber_Comms_UpdateNews")
        net.WriteTable(self.NewsBoard)
        net.Broadcast()
        
        -- Save news
        self:SaveNews()
        
        return true
    end
    
    function KYBER.Comms:SaveNews()
        if not file.Exists("kyber/comms", "DATA") then
            file.CreateDir("kyber/comms")
        end
        
        file.Write("kyber/comms/newsboard.json", util.TableToJSON(self.NewsBoard))
    end
    
    function KYBER.Comms:LoadNews()
        if file.Exists("kyber/comms/newsboard.json", "DATA") then
            self.NewsBoard = util.JSONToTable(file.Read("kyber/comms/newsboard.json", "DATA")) or {}
            
            -- Clean expired posts
            local time = os.time()
            for i = #self.NewsBoard, 1, -1 do
                if self.NewsBoard[i].expires < time then
                    table.remove(self.NewsBoard, i)
                end
            end
        end
    end
    
    -- Network handlers
    net.Receive("Kyber_Comms_StartCall", function(len, ply)
        local target = net.ReadEntity()
        local quality = net.ReadInt(4)
        
        local success, err = KYBER.Comms:StartHoloCall(ply, target, quality)
        
        if not success then
            ply:ChatPrint("Call failed: " .. err)
        end
    end)
    
    net.Receive("Kyber_Comms_EndCall", function(len, ply)
        KYBER.Comms:EndHoloCall(ply)
    end)
    
    net.Receive("Kyber_Comms_SendMessage", function(len, ply)
        local recipient = net.ReadString()
        local subject = net.ReadString()
        local content = net.ReadString()
        local attachments = net.ReadTable()
        local encrypted = net.ReadInt(4)
        
        KYBER.Comms:SendMessage(ply, recipient, subject, content, attachments, encrypted)
    end)
    
    net.Receive("Kyber_Comms_Broadcast", function(len, ply)
        local message = net.ReadString()
        
        local success, err = KYBER.Comms:SendFactionBroadcast(ply, message)
        
        if not success then
            ply:ChatPrint("Broadcast failed: " .. err)
        end
    end)
    
    net.Receive("Kyber_Comms_DistressBeacon", function(len, ply)
        local message = net.ReadString()
        
        local success, err = KYBER.Comms:SendDistressBeacon(ply, message)
        
        if not success then
            ply:ChatPrint("Distress beacon failed: " .. err)
        end
    end)
    
    net.Receive("Kyber_Comms_PostNews", function(len, ply)
        local headline = net.ReadString()
        local content = net.ReadString()
        local faction = net.ReadString()
        
        if faction == "" then faction = nil end
        
        local success, err = KYBER.Comms:PostNews(ply, headline, content, faction)
        
        if not success then
            ply:ChatPrint("News post failed: " .. err)
        else
            ply:ChatPrint("News posted successfully!")
        end
    end)
    
    net.Receive("Kyber_Comms_DeleteMessage", function(len, ply)
        local messageID = net.ReadString()
        
        for i, msg in ipairs(ply.KyberComms.messages) do
            if msg.id == messageID then
                table.remove(ply.KyberComms.messages, i)
                KYBER.Comms:Save(ply)
                break
            end
        end
    end)
    
    -- Voice data relay for holocalls
    net.Receive("Kyber_Comms_VoiceData", function(len, ply)
        if not ply.KyberComms.activeCall then return end
        
        local partner = ply.KyberComms.activeCall.partner
        if not IsValid(partner) then return end
        
        -- Relay voice data with quality effects
        local quality = ply.KyberComms.activeCall.quality
        local qualityData = KYBER.Comms.Config.holocomQuality[quality]
        
        net.Start("Kyber_Comms_VoiceData")
        net.WriteFloat(qualityData.clarity)
        net.Send(partner)
    end)
    
    -- Clean up expired messages
    function KYBER.Comms:CleanExpiredMessages(ply)
        local currentTime = os.time()
        
        for i = #ply.KyberComms.messages, 1, -1 do
            if currentTime - ply.KyberComms.messages[i].timestamp > self.Config.messageExpiry then
                table.remove(ply.KyberComms.messages, i)
            end
        end
    end
    
    -- Check for offline messages on spawn
    hook.Add("PlayerInitialSpawn", "KyberCommsOfflineMessages", function(ply)
        timer.Simple(2, function()
            if not IsValid(ply) then return end
            
            local charName = ply:GetNWString("kyber_name", "default")
            local offlinePath = "kyber/comms/offline/" .. util.CRC(charName) .. ".json"
            
            if file.Exists(offlinePath, "DATA") then
                local messages = util.JSONToTable(file.Read(offlinePath, "DATA")) or {}
                
                for _, msg in ipairs(messages) do
                    if #ply.KyberComms.messages < KYBER.Comms.Config.maxMessages then
                        table.insert(ply.KyberComms.messages, 1, msg)
                        
                        net.Start("Kyber_Comms_ReceiveMessage")
                        net.WriteTable(msg)
                        net.Send(ply)
                    end
                end
                
                if #messages > 0 then
                    ply:ChatPrint("You have " .. #messages .. " new messages!")
                end
                
                -- Delete offline file
                file.Delete(offlinePath)
                
                KYBER.Comms:Save(ply)
            end
        end)
    end)
    
    -- Initialize
    hook.Add("Initialize", "KyberCommsInit", function()
        KYBER.Comms:LoadNews()
    end)
    
    hook.Add("PlayerInitialSpawn", "KyberCommsPlayerInit", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                KYBER.Comms:Initialize(ply)
            end
        end)
    end)
    
    hook.Add("PlayerDisconnected", "KyberCommsSave", function(ply)
        if ply.KyberComms and ply.KyberComms.activeCall then
            KYBER.Comms:EndHoloCall(ply)
        end
        
        KYBER.Comms:Save(ply)
    end)
    
else -- CLIENT
    
    local CommsUI = nil
    local HoloCallUI = nil
    local activeHoloEffect = nil
    
    -- Holocall UI
    net.Receive("Kyber_Comms_StartCall", function()
        local partner = net.ReadEntity()
        local quality = net.ReadInt(4)
        local isCaller = net.ReadBool()
        
        KYBER.Comms:OpenHoloCall(partner, quality, isCaller)
    end)
    
    net.Receive("Kyber_Comms_EndCall", function()
        local duration = net.ReadFloat()
        
        if IsValid(HoloCallUI) then
            HoloCallUI:Remove()
        end
        
        if activeHoloEffect then
            activeHoloEffect:Remove()
            activeHoloEffect = nil
        end
        
        chat.AddText(Color(100, 200, 255), "[Holocom] ", Color(255, 255, 255), "Call ended. Duration: " .. string.FormattedTime(duration, "%02i:%02i"))
    end)
    
    function KYBER.Comms:OpenHoloCall(partner, quality, isCaller)
        if IsValid(HoloCallUI) then HoloCallUI:Remove() end
        
        HoloCallUI = vgui.Create("DFrame")
        HoloCallUI:SetSize(400, 500)
        HoloCallUI:SetPos(ScrW() - 420, 20)
        HoloCallUI:SetTitle("Holocall - " .. partner:Nick())
        HoloCallUI:MakePopup()
        
        -- Quality indicator
        local qualityPanel = vgui.Create("DPanel", HoloCallUI)
        qualityPanel:Dock(TOP)
        qualityPanel:SetTall(30)
        qualityPanel:DockMargin(10, 5, 10, 5)
        
        qualityPanel.Paint = function(self, w, h)
            local qualityData = KYBER.Comms.Config.holocomQuality[quality]
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            draw.SimpleText("Quality: " .. qualityData.name, "DermaDefault", 10, h/2, Color(100, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("Cost: " .. qualityData.cost .. " credits/min", "DermaDefault", w-10, h/2, Color(255, 255, 100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        
        -- Partner view (hologram effect)
        local holoPanel = vgui.Create("DModelPanel", HoloCallUI)
        holoPanel:Dock(FILL)
        holoPanel:DockMargin(10, 0, 10, 10)
        holoPanel:SetModel(partner:GetModel())
        
        local ent = holoPanel:GetEntity()
        ent:SetSequence(ent:LookupSequence("idle_all_01"))
        
        holoPanel:SetFOV(45)
        holoPanel:SetCamPos(Vector(80, 0, 60))
        holoPanel:SetLookAt(Vector(0, 0, 40))
        
        -- Apply hologram shader effect
        holoPanel.PreDrawModel = function(self)
            local qualityData = KYBER.Comms.Config.holocomQuality[quality]
            local clarity = qualityData.clarity
            
            -- Hologram color
            render.SetColorModulation(0.5, 0.8, 1)
            render.SetBlend(clarity)
            
            -- Static effect for poor quality
            if quality < 2 then
                local static = math.random() * (1 - clarity)
                render.SetColorModulation(0.5 + static, 0.8 - static, 1 - static)
            end
        end
        
        holoPanel.PostDrawModel = function(self)
            render.SetColorModulation(1, 1, 1)
            render.SetBlend(1)
        end
        
        -- End call button
        local endBtn = vgui.Create("DButton", HoloCallUI)
        endBtn:Dock(BOTTOM)
        endBtn:DockMargin(10, 0, 10, 10)
        endBtn:SetTall(40)
        endBtn:SetText("End Call")
        
        endBtn.DoClick = function()
            net.Start("Kyber_Comms_EndCall")
            net.SendToServer()
        end
        
        endBtn.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(200, 50, 50))
            draw.SimpleText(self:GetText(), "DermaDefaultBold", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- Sound effect
        surface.PlaySound("ambient/machines/thumper_startup1.wav")
    end
    
    -- Message received
    net.Receive("Kyber_Comms_ReceiveMessage", function()
        local message = net.ReadTable()
        
        -- Notification
        notification.AddLegacy("New message from " .. message.sender, NOTIFY_GENERIC, 5)
        surface.PlaySound("buttons/button14.wav")
        
        -- Add to local storage
        LocalPlayer().KyberCommsMessages = LocalPlayer().KyberCommsMessages or {}
        table.insert(LocalPlayer().KyberCommsMessages, 1, message)
    end)
    
    -- Broadcast received
    net.Receive("Kyber_Comms_Broadcast", function()
        local broadcastType = net.ReadString()
        local sender = net.ReadString()
        local message = net.ReadString()
        local color = net.ReadColor()
        
        -- Chat message
        if broadcastType == "faction" then
            chat.AddText(
                color, "[FACTION] ",
                Color(255, 255, 255), sender .. ": ",
                Color(200, 200, 200), message
            )
        else
            chat.AddText(
                Color(255, 100, 100), "[BROADCAST] ",
                Color(255, 255, 255), sender .. ": ",
                Color(200, 200, 200), message
            )
        end
        
        -- Sound
        surface.PlaySound("npc/overwatch/radiovoice/on3.wav")
    end)
    
    -- Distress beacon
    net.Receive("Kyber_Comms_DistressBeacon", function()
        local sender = net.ReadEntity()
        local position = net.ReadVector()
        local message = net.ReadString()
        local distance = net.ReadFloat()
        
        -- Alert
        chat.AddText(
            Color(255, 50, 50), "[DISTRESS] ",
            Color(255, 255, 255), sender:Nick() .. " (",
            Color(255, 200, 100), math.Round(distance) .. " units",
            Color(255, 255, 255), "): ",
            Color(200, 200, 200), message
        )
        
        -- Sound
        surface.PlaySound("npc/overwatch/radiovoice/on1.wav")
        timer.Simple(0.5, function()
            surface.PlaySound("ambient/alarms/alarm1.wav")
        end)
    end)
    
    -- News update
    net.Receive("Kyber_Comms_UpdateNews", function()
        local newsBoard = net.ReadTable()
        LocalPlayer().KyberNewsBoard = newsBoard
    end)
    
    -- Main communications UI
    function KYBER.Comms:OpenUI()
        if IsValid(CommsUI) then CommsUI:Remove() end
        
        CommsUI = vgui.Create("DFrame")
        CommsUI:SetSize(800, 600)
        CommsUI:Center()
        CommsUI:SetTitle("Communications Terminal")
        CommsUI:MakePopup()
        
        local sheet = vgui.Create("DPropertySheet", CommsUI)
        sheet:Dock(FILL)
        sheet:DockMargin(10, 10, 10, 10)
        
        -- Messages tab
        local msgPanel = vgui.Create("DPanel", sheet)
        self:CreateMessagesPanel(msgPanel)
        sheet:AddSheet("Messages", msgPanel, "icon16/email.png")
        
        -- Holocom tab
        local holoPanel = vgui.Create("DPanel", sheet)
        self:CreateHolocomPanel(holoPanel)
        sheet:AddSheet("Holocom", holoPanel, "icon16/webcam.png")
        
        -- Broadcast tab
        local broadPanel = vgui.Create("DPanel", sheet)
        self:CreateBroadcastPanel(broadPanel)
        sheet:AddSheet("Broadcast", broadPanel, "icon16/transmit.png")
        
        -- News tab
        local newsPanel = vgui.Create("DPanel", sheet)
        self:CreateNewsPanel(newsPanel)
        sheet:AddSheet("News Board", newsPanel, "icon16/newspaper.png")
    end
    
    function KYBER.Comms:CreateMessagesPanel(parent)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        end
        
        -- Control buttons
        local controlPanel = vgui.Create("DPanel", parent)
        controlPanel:Dock(TOP)
        controlPanel:SetTall(40)
        controlPanel:DockMargin(10, 10, 10, 10)
        controlPanel.Paint = function() end
        
        local composeBtn = vgui.Create("DButton", controlPanel)
        composeBtn:SetText("Compose Message")
        composeBtn:Dock(LEFT)
        composeBtn:SetWide(150)
        
        composeBtn.DoClick = function()
            self:OpenComposeMessage()
        end
        
        -- Message list
        local msgScroll = vgui.Create("DScrollPanel", parent)
        msgScroll:Dock(FILL)
        msgScroll:DockMargin(10, 0, 10, 10)
        
        local messages = LocalPlayer().KyberCommsMessages or {}
        
        for _, msg in ipairs(messages) do
            local msgPanel = vgui.Create("DPanel", msgScroll)
            msgPanel:Dock(TOP)
            msgPanel:DockMargin(0, 0, 0, 5)
            msgPanel:SetTall(80)
            
            msgPanel.Paint = function(self, w, h)
                local col = msg.read and Color(40, 40, 40) or Color(50, 50, 60)
                draw.RoundedBox(4, 0, 0, w, h, col)
                
                -- Unread indicator
                if not msg.read then
                    draw.RoundedBox(0, 0, 0, 4, h, Color(100, 200, 255))
                end
                
                -- From
                draw.SimpleText("From: " .. msg.sender, "DermaDefaultBold", 10, 10, Color(255, 255, 255))
                
                -- Subject
                draw.SimpleText(msg.subject, "DermaDefault", 10, 30, Color(200, 200, 200))
                
                -- Time
                local timeStr = os.date("%m/%d %H:%M", msg.timestamp)
                draw.SimpleText(timeStr, "DermaDefault", w - 100, 10, Color(150, 150, 150))
                
                -- Encrypted indicator
                if msg.encrypted > 0 then
                    draw.SimpleText("ENCRYPTED", "DermaDefault", w - 100, 30, Color(255, 100, 100))
                end
                
                -- Attachments indicator
                if #msg.attachments > 0 then
                    draw.SimpleText(#msg.attachments .. " attachments", "DermaDefault", 10, 50, Color(100, 255, 100))
                end
            end
            
            msgPanel:SetCursor("hand")
            msgPanel.DoClick = function()
                self:OpenMessage(msg)
                msg.read = true
            end
        end
    end
    
    function KYBER.Comms:CreateHolocomPanel(parent)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        end
        
        -- Contact list
        local contactLabel = vgui.Create("DLabel", parent)
        contactLabel:SetText("Online Contacts:")
        contactLabel:SetFont("DermaDefaultBold")
        contactLabel:Dock(TOP)
        contactLabel:DockMargin(10, 10, 10, 5)
        
        local contactScroll = vgui.Create("DScrollPanel", parent)
        contactScroll:Dock(FILL)
        contactScroll:DockMargin(10, 0, 10, 10)
        
        for _, ply in ipairs(player.GetAll()) do
            if ply != LocalPlayer() then
                local plyPanel = vgui.Create("DPanel", contactScroll)
                plyPanel:Dock(TOP)
                plyPanel:DockMargin(0, 0, 0, 5)
                plyPanel:SetTall(60)
                
                plyPanel.Paint = function(self, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
                    
                    -- Name
                    draw.SimpleText(ply:GetNWString("kyber_name", ply:Nick()), "DermaDefaultBold", 10, 15, Color(255, 255, 255))
                    
                    -- Distance
                    local dist = math.Round(LocalPlayer():GetPos():Distance(ply:GetPos()))
                    local inRange = dist <= KYBER.Comms.Config.holocomRange
                    
                    draw.SimpleText("Distance: " .. dist .. " units", "DermaDefault", 10, 35, 
                        inRange and Color(100, 255, 100) or Color(255, 100, 100))
                end
                
                -- Quality selector
                local qualitySelect = vgui.Create("DComboBox", plyPanel)
                qualitySelect:SetPos(200, 15)
                qualitySelect:SetSize(150, 30)
                qualitySelect:SetValue("Select Quality")
                
                for q = 0, 4 do
                    local qData = KYBER.Comms.Config.holocomQuality[q]
                    qualitySelect:AddChoice(qData.name .. " (" .. qData.cost .. " cr/min)", q)
                end
                
                -- Call button
                local callBtn = vgui.Create("DButton", plyPanel)
                callBtn:SetText("Call")
                callBtn:SetPos(360, 15)
                callBtn:SetSize(80, 30)
                
                callBtn.DoClick = function()
                    local _, quality = qualitySelect:GetSelected()
                    if quality then
                        net.Start("Kyber_Comms_StartCall")
                        net.WriteEntity(ply)
                        net.WriteInt(quality, 4)
                        net.SendToServer()
                    else
                        LocalPlayer():ChatPrint("Please select call quality")
                    end
                end
            end
        end
    end
    
    function KYBER.Comms:CreateBroadcastPanel(parent)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        end
        
        -- Faction broadcast
        local factionPanel = vgui.Create("DPanel", parent)
        factionPanel:Dock(TOP)
        factionPanel:SetTall(200)
        factionPanel:DockMargin(10, 10, 10, 10)
        
        factionPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
            draw.SimpleText("Faction Broadcast", "DermaDefaultBold", 10, 10, Color(255, 255, 255))
            
            local faction = LocalPlayer():GetNWString("kyber_faction", "")
            if faction == "" then
                draw.SimpleText("You must be in a faction to broadcast", "DermaDefault", 10, 35, Color(255, 100, 100))
            else
                local factionData = KYBER.Factions[faction]
                if factionData then
                    draw.SimpleText("Broadcasting to: " .. factionData.name, "DermaDefault", 10, 35, factionData.color)
                end
            end
        end
        
        local broadcastEntry = vgui.Create("DTextEntry", factionPanel)
        broadcastEntry:SetPos(10, 60)
        broadcastEntry:SetSize(factionPanel:GetWide() - 20, 80)
        broadcastEntry:SetMultiline(true)
        broadcastEntry:SetPlaceholderText("Enter broadcast message...")
        
        local broadcastBtn = vgui.Create("DButton", factionPanel)
        broadcastBtn:SetText("Send Broadcast (500 credits)")
        broadcastBtn:SetPos(10, 150)
        broadcastBtn:SetSize(200, 35)
        
        broadcastBtn.DoClick = function()
            local msg = broadcastEntry:GetValue()
            if msg ~= "" then
                net.Start("Kyber_Comms_Broadcast")
                net.WriteString(msg)
                net.SendToServer()
                
                broadcastEntry:SetValue("")
            end
        end
        
        -- Distress beacon
        local distressPanel = vgui.Create("DPanel", parent)
        distressPanel:Dock(TOP)
        distressPanel:SetTall(150)
        distressPanel:DockMargin(10, 0, 10, 10)
        
        distressPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
            draw.SimpleText("Distress Beacon", "DermaDefaultBold", 10, 10, Color(255, 100, 100))
            draw.SimpleText("Sends emergency signal to nearby players and faction members", "DermaDefault", 10, 35, Color(200, 200, 200))
        end
        
        local distressEntry = vgui.Create("DTextEntry", distressPanel)
        distressEntry:SetPos(10, 60)
        distressEntry:SetSize(distressPanel:GetWide() - 20, 30)
        distressEntry:SetPlaceholderText("Emergency message...")
        
        local distressBtn = vgui.Create("DButton", distressPanel)
        distressBtn:SetText("SEND DISTRESS SIGNAL")
        distressBtn:SetPos(10, 100)
        distressBtn:SetSize(200, 35)
        
        distressBtn.Paint = function(self, w, h)
            local col = self:IsHovered() and Color(255, 100, 100) or Color(200, 50, 50)
            draw.RoundedBox(4, 0, 0, w, h, col)
            draw.SimpleText(self:GetText(), "DermaDefaultBold", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        distressBtn.DoClick = function()
            local msg = distressEntry:GetValue()
            if msg == "" then msg = "HELP!" end
            
            net.Start("Kyber_Comms_DistressBeacon")
            net.WriteString(msg)
            net.SendToServer()
            
            distressEntry:SetValue("")
        end
    end
    
    function KYBER.Comms:CreateNewsPanel(parent)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        end
        
        -- Post news button
        local postBtn = vgui.Create("DButton", parent)
        postBtn:SetText("Post News Article (1000 credits)")
        postBtn:Dock(TOP)
        postBtn:DockMargin(10, 10, 10, 10)
        postBtn:SetTall(40)
        
        postBtn.DoClick = function()
            self:OpenNewsComposer()
        end
        
        -- News feed
        local newsScroll = vgui.Create("DScrollPanel", parent)
        newsScroll:Dock(FILL)
        newsScroll:DockMargin(10, 0, 10, 10)
        
        local newsBoard = LocalPlayer().KyberNewsBoard or {}
        
        -- Sort by newest first
        table.sort(newsBoard, function(a, b)
            return a.timestamp > b.timestamp
        end)
        
        for _, post in ipairs(newsBoard) do
            local postPanel = vgui.Create("DPanel", newsScroll)
            postPanel:Dock(TOP)
            postPanel:DockMargin(0, 0, 0, 10)
            postPanel:SetTall(120)
            
            postPanel.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
                
                -- Headline
                draw.SimpleText(post.headline, "DermaLarge", 10, 10, Color(255, 255, 255))
                
                -- Author and time
                local timeStr = os.date("%m/%d %H:%M", post.timestamp)
                draw.SimpleText("By " .. post.author .. " - " .. timeStr, "DermaDefault", 10, 40, Color(150, 150, 150))
                
                -- Faction tag
                if post.faction then
                    local factionData = KYBER.Factions[post.faction]
                    if factionData then
                        draw.SimpleText("[" .. factionData.name .. "]", "DermaDefault", w - 150, 10, factionData.color)
                    end
                end
                
                -- Content preview
                local preview = string.sub(post.content, 1, 100) .. "..."
                draw.DrawText(preview, "DermaDefault", 10, 65, Color(200, 200, 200), TEXT_ALIGN_LEFT)
            end
            
            postPanel:SetCursor("hand")
            postPanel.DoClick = function()
                self:OpenNewsArticle(post)
            end
        end
    end
    
    function KYBER.Comms:OpenComposeMessage()
        local compose = vgui.Create("DFrame")
        compose:SetSize(500, 400)
        compose:Center()
        compose:SetTitle("Compose Message")
        compose:MakePopup()
        
        -- Recipient
        local recipLabel = vgui.Create("DLabel", compose)
        recipLabel:SetText("To (Character Name):")
        recipLabel:SetPos(10, 30)
        recipLabel:SizeToContents()
        
        local recipEntry = vgui.Create("DTextEntry", compose)
        recipEntry:SetPos(10, 50)
        recipEntry:SetSize(480, 25)
        
        -- Subject
        local subjLabel = vgui.Create("DLabel", compose)
        subjLabel:SetText("Subject:")
        subjLabel:SetPos(10, 85)
        subjLabel:SizeToContents()
        
        local subjEntry = vgui.Create("DTextEntry", compose)
        subjEntry:SetPos(10, 105)
        subjEntry:SetSize(480, 25)
        
        -- Content
        local contentLabel = vgui.Create("DLabel", compose)
        contentLabel:SetText("Message:")
        contentLabel:SetPos(10, 140)
        contentLabel:SizeToContents()
        
        local contentEntry = vgui.Create("DTextEntry", compose)
        contentEntry:SetPos(10, 160)
        contentEntry:SetSize(480, 150)
        contentEntry:SetMultiline(true)
        
        -- Encryption
        local encryptCheck = vgui.Create("DCheckBoxLabel", compose)
        encryptCheck:SetPos(10, 320)
        encryptCheck:SetText("Encrypt Message")
        encryptCheck:SizeToContents()
        
        -- Send button
        local sendBtn = vgui.Create("DButton", compose)
        sendBtn:SetText("Send Message")
        sendBtn:SetPos(10, 350)
        sendBtn:SetSize(150, 35)
        
        sendBtn.DoClick = function()
            net.Start("Kyber_Comms_SendMessage")
            net.WriteString(recipEntry:GetValue())
            net.WriteString(subjEntry:GetValue())
            net.WriteString(contentEntry:GetValue())
            net.WriteTable({}) -- Attachments (TODO)
            net.WriteInt(encryptCheck:GetChecked() and 1 or 0, 4)
            net.SendToServer()
            
            compose:Close()
        end
    end
    
    function KYBER.Comms:OpenMessage(msg)
        local msgFrame = vgui.Create("DFrame")
        msgFrame:SetSize(500, 400)
        msgFrame:Center()
        msgFrame:SetTitle("Message from " .. msg.sender)
        msgFrame:MakePopup()
        
        local content = vgui.Create("DRichText", msgFrame)
        content:Dock(FILL)
        content:DockMargin(10, 10, 10, 50)
        
        content:AppendText("From: " .. msg.sender .. "\n")
        content:AppendText("Subject: " .. msg.subject .. "\n")
        content:AppendText("Date: " .. os.date("%c", msg.timestamp) .. "\n\n")
        
        if msg.encrypted > 0 then
            content:AppendText("[ENCRYPTED MESSAGE]\n\n")
        end
        
        content:AppendText(msg.content)
        
        -- Delete button
        local deleteBtn = vgui.Create("DButton", msgFrame)
        deleteBtn:SetText("Delete Message")
        deleteBtn:Dock(BOTTOM)
        deleteBtn:DockMargin(10, 0, 10, 10)
        deleteBtn:SetTall(30)
        
        deleteBtn.DoClick = function()
            net.Start("Kyber_Comms_DeleteMessage")
            net.WriteString(msg.id)
            net.SendToServer()
            
            -- Remove from local list
            for i, m in ipairs(LocalPlayer().KyberCommsMessages or {}) do
                if m.id == msg.id then
                    table.remove(LocalPlayer().KyberCommsMessages, i)
                    break
                end
            end
            
            msgFrame:Close()
            
            -- Refresh main UI
            if IsValid(CommsUI) then
                KYBER.Comms:OpenUI()
            end
        end
    end
    
    function KYBER.Comms:OpenNewsComposer()
        local composer = vgui.Create("DFrame")
        composer:SetSize(600, 500)
        composer:Center()
        composer:SetTitle("Post News Article")
        composer:MakePopup()
        
        -- Headline
        local headLabel = vgui.Create("DLabel", composer)
        headLabel:SetText("Headline:")
        headLabel:SetPos(10, 30)
        headLabel:SizeToContents()
        
        local headEntry = vgui.Create("DTextEntry", composer)
        headEntry:SetPos(10, 50)
        headEntry:SetSize(580, 30)
        headEntry:SetFont("DermaLarge")
        
        -- Content
        local contentLabel = vgui.Create("DLabel", composer)
        contentLabel:SetText("Article Content:")
        contentLabel:SetPos(10, 90)
        contentLabel:SizeToContents()
        
        local contentEntry = vgui.Create("DTextEntry", composer)
        contentEntry:SetPos(10, 110)
        contentEntry:SetSize(580, 250)
        contentEntry:SetMultiline(true)
        
        -- Faction association
        local factionCheck = vgui.Create("DCheckBoxLabel", composer)
        factionCheck:SetPos(10, 370)
        factionCheck:SetText("Post as faction news")
        factionCheck:SizeToContents()
        
        local faction = LocalPlayer():GetNWString("kyber_faction", "")
        if faction == "" then
            factionCheck:SetEnabled(false)
        end
        
        -- Cost warning
        local costLabel = vgui.Create("DLabel", composer)
        costLabel:SetText("Cost: 1000 credits")
        costLabel:SetPos(10, 400)
        costLabel:SetTextColor(Color(255, 255, 100))
        costLabel:SizeToContents()
        
        -- Post button
        local postBtn = vgui.Create("DButton", composer)
        postBtn:SetText("Post Article")
        postBtn:SetPos(10, 430)
        postBtn:SetSize(150, 40)
        
        postBtn.DoClick = function()
            net.Start("Kyber_Comms_PostNews")
            net.WriteString(headEntry:GetValue())
            net.WriteString(contentEntry:GetValue())
            net.WriteString(factionCheck:GetChecked() and faction or "")
            net.SendToServer()
            
            composer:Close()
        end
    end
    
    function KYBER.Comms:OpenNewsArticle(post)
        local article = vgui.Create("DFrame")
        article:SetSize(600, 500)
        article:Center()
        article:SetTitle("News Article")
        article:MakePopup()
        
        local scroll = vgui.Create("DScrollPanel", article)
        scroll:Dock(FILL)
        scroll:DockMargin(10, 10, 10, 10)
        
        local content = vgui.Create("DRichText", scroll)
        content:Dock(FILL)
        
        -- Headline
        content:SetFontInternal("DermaLarge")
        content:AppendText(post.headline .. "\n\n")
        
        -- Metadata
        content:SetFontInternal("DermaDefault")
        content:SetTextColor(Color(150, 150, 150))
        content:AppendText("By " .. post.author)
        content:AppendText(" - " .. os.date("%B %d, %Y at %I:%M %p", post.timestamp) .. "\n")
        
        if post.faction then
            local factionData = KYBER.Factions[post.faction]
            if factionData then
                content:SetTextColor(factionData.color)
                content:AppendText("[" .. factionData.name .. "]\n")
            end
        end
        
        content:AppendText("\n")
        
        -- Article content
        content:SetTextColor(Color(255, 255, 255))
        content:AppendText(post.content)
    end
    
    -- HUD indicators
    hook.Add("HUDPaint", "KyberCommsHUD", function()
        -- Unread messages
        local messages = LocalPlayer().KyberCommsMessages or {}
        local unread = 0
        
        for _, msg in ipairs(messages) do
            if not msg.read then
                unread = unread + 1
            end
        end
        
        if unread > 0 then
            local x = ScrW() - 200
            local y = 200
            
            draw.RoundedBox(6, x - 10, y - 5, 190, 30, Color(0, 0, 0, 200))
            draw.SimpleText(unread .. " unread messages", "DermaDefaultBold", x, y + 10, Color(100, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        
        -- Active distress beacons
        for _, ply in ipairs(player.GetAll()) do
            local distressTime = ply:GetNWFloat("kyber_distress_time", 0)
            if distressTime > CurTime() then
                local distressPos = ply:GetNWVector("kyber_distress_pos")
                local screenPos = distressPos:ToScreen()
                
                if screenPos.visible then
                    local pulse = math.sin(CurTime() * 5) * 0.5 + 0.5
                    
                    draw.RoundedBox(6, screenPos.x - 50, screenPos.y - 15, 100, 30, Color(255, 50, 50, 100 + pulse * 155))
                    draw.SimpleText("DISTRESS", "DermaDefaultBold", screenPos.x, screenPos.y, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                    local dist = math.Round(LocalPlayer():GetPos():Distance(distressPos))
                    draw.SimpleText(dist .. " units", "DermaDefault", screenPos.x, screenPos.y + 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
        end
    end)
    
    -- Console command to open comms
    concommand.Add("kyber_comms", function()
        KYBER.Comms:OpenUI()
    end)
end