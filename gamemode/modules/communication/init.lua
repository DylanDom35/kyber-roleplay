-- Communication module initialization
KYBER.Communication = KYBER.Communication or {}

-- Communication module configuration
KYBER.Communication.Config = {
    Channels = {
        ["global"] = {
            name = "Global",
            description = "Global chat channel",
            color = Color(255, 255, 255),
            range = 0, -- 0 means unlimited range
            cooldown = 0,
            prefix = "",
            requirements = {}
        },
        ["local"] = {
            name = "Local",
            description = "Local area chat",
            color = Color(200, 200, 200),
            range = 1000,
            cooldown = 0.5,
            prefix = "/l",
            requirements = {}
        },
        ["faction"] = {
            name = "Faction",
            description = "Faction-wide communication",
            color = Color(0, 255, 0),
            range = 0,
            cooldown = 1,
            prefix = "/f",
            requirements = {
                needsFaction = true
            }
        },
        ["force"] = {
            name = "Force",
            description = "Force-sensitive communication",
            color = Color(255, 0, 255),
            range = 0,
            cooldown = 2,
            prefix = "/force",
            requirements = {
                needsForce = true,
                minForceLevel = 5
            }
        },
        ["whisper"] = {
            name = "Whisper",
            description = "Private message to a player",
            color = Color(255, 255, 0),
            range = 0,
            cooldown = 0.5,
            prefix = "/w",
            requirements = {}
        }
    },
    Emotes = {
        ["wave"] = {
            name = "Wave",
            description = "Wave to someone",
            animation = "wave",
            sound = "vo/npc/male01/hi0%d.wav",
            cooldown = 2
        },
        ["bow"] = {
            name = "Bow",
            description = "Bow respectfully",
            animation = "bow",
            sound = nil,
            cooldown = 3
        },
        ["salute"] = {
            name = "Salute",
            description = "Salute someone",
            animation = "salute",
            sound = nil,
            cooldown = 2
        },
        ["dance"] = {
            name = "Dance",
            description = "Perform a dance",
            animation = "dance",
            sound = "music/dance.mp3",
            cooldown = 5
        }
    },
    Commands = {
        ["me"] = {
            name = "Me",
            description = "Describe an action",
            cooldown = 1,
            range = 1000
        },
        ["do"] = {
            name = "Do",
            description = "Describe a situation",
            cooldown = 1,
            range = 1000
        },
        ["roll"] = {
            name = "Roll",
            description = "Roll a dice",
            cooldown = 2,
            range = 1000
        }
    }
}

-- Communication module functions
function KYBER.Communication:Initialize()
    print("[Kyber] Communication module initialized")
    return true
end

function KYBER.Communication:CreateCommunicationData(ply)
    if not IsValid(ply) then return false end
    
    -- Create communication data table if it doesn't exist
    ply.KyberCommunication = ply.KyberCommunication or {
        lastMessage = {},
        lastEmote = {},
        lastCommand = {},
        muted = false,
        blockedPlayers = {}
    }
    
    return true
end

function KYBER.Communication:CanUseChannel(ply, channel)
    if not IsValid(ply) then return false end
    if not self:CreateCommunicationData(ply) then return false end
    
    -- Check if channel exists
    if not self.Config.Channels[channel] then
        return false
    end
    
    -- Check if player is muted
    if ply.KyberCommunication.muted then
        return false
    end
    
    -- Check requirements
    local requirements = self.Config.Channels[channel].requirements
    if requirements then
        -- Check faction requirement
        if requirements.needsFaction then
            local faction = KYBER.Factions:GetFaction(ply)
            if not faction then
                return false
            end
        end
        
        -- Check force requirement
        if requirements.needsForce then
            local forceLevel = KYBER.Force:GetLevel(ply)
            if forceLevel < requirements.minForceLevel then
                return false
            end
        end
    end
    
    -- Check cooldown
    local lastMessage = ply.KyberCommunication.lastMessage[channel]
    if lastMessage then
        local cooldown = self.Config.Channels[channel].cooldown
        if os.time() - lastMessage < cooldown then
            return false
        end
    end
    
    return true
end

function KYBER.Communication:SendMessage(ply, channel, message)
    if not IsValid(ply) then return false end
    if not self:CanUseChannel(ply, channel) then return false end
    
    -- Get channel data
    local channelData = self.Config.Channels[channel]
    
    -- Update last message time
    ply.KyberCommunication.lastMessage[channel] = os.time()
    
    -- Process message based on channel
    if channel == "whisper" then
        -- Whisper channel requires a target
        local target = string.match(message, "^%s*(%S+)%s+(.+)$")
        if not target then return false end
        
        local targetPly = player.GetBySteamID(target) or player.GetByName(target)
        if not IsValid(targetPly) then return false end
        
        -- Check if target has blocked the sender
        if targetPly.KyberCommunication and targetPly.KyberCommunication.blockedPlayers[ply:SteamID()] then
            return false
        end
        
        -- Send message to target
        if SERVER then
            net.Start("Kyber_Communication_Whisper")
            net.WriteEntity(ply)
            net.WriteString(message)
            net.Send(targetPly)
        end
    else
        -- Get players in range
        local recipients = {}
        if channelData.range > 0 then
            for _, otherPly in ipairs(player.GetAll()) do
                if otherPly:GetPos():Distance(ply:GetPos()) <= channelData.range then
                    table.insert(recipients, otherPly)
                end
            end
        else
            recipients = player.GetAll()
        end
        
        -- Send message to recipients
        if SERVER then
            net.Start("Kyber_Communication_Message")
            net.WriteEntity(ply)
            net.WriteString(channel)
            net.WriteString(message)
            net.Send(recipients)
        end
    end
    
    return true
end

function KYBER.Communication:CanUseEmote(ply, emote)
    if not IsValid(ply) then return false end
    if not self:CreateCommunicationData(ply) then return false end
    
    -- Check if emote exists
    if not self.Config.Emotes[emote] then
        return false
    end
    
    -- Check if player is muted
    if ply.KyberCommunication.muted then
        return false
    end
    
    -- Check cooldown
    local lastEmote = ply.KyberCommunication.lastEmote[emote]
    if lastEmote then
        local cooldown = self.Config.Emotes[emote].cooldown
        if os.time() - lastEmote < cooldown then
            return false
        end
    end
    
    return true
end

function KYBER.Communication:UseEmote(ply, emote)
    if not IsValid(ply) then return false end
    if not self:CanUseEmote(ply, emote) then return false end
    
    -- Get emote data
    local emoteData = self.Config.Emotes[emote]
    
    -- Update last emote time
    ply.KyberCommunication.lastEmote[emote] = os.time()
    
    -- Play animation
    if emoteData.animation then
        ply:AnimRestartGesture(GESTURE_SLOT_CUSTOM, ply:LookupSequence(emoteData.animation), true)
    end
    
    -- Play sound
    if emoteData.sound then
        if string.find(emoteData.sound, "%%d") then
            -- Random sound from sequence
            local sound = string.format(emoteData.sound, math.random(1, 5))
            ply:EmitSound(sound)
        else
            ply:EmitSound(emoteData.sound)
        end
    end
    
    -- Notify nearby players
    if SERVER then
        net.Start("Kyber_Communication_Emote")
        net.WriteEntity(ply)
        net.WriteString(emote)
        net.Send(ply:GetPlayersInRange(1000))
    end
    
    return true
end

function KYBER.Communication:CanUseCommand(ply, command)
    if not IsValid(ply) then return false end
    if not self:CreateCommunicationData(ply) then return false end
    
    -- Check if command exists
    if not self.Config.Commands[command] then
        return false
    end
    
    -- Check if player is muted
    if ply.KyberCommunication.muted then
        return false
    end
    
    -- Check cooldown
    local lastCommand = ply.KyberCommunication.lastCommand[command]
    if lastCommand then
        local cooldown = self.Config.Commands[command].cooldown
        if os.time() - lastCommand < cooldown then
            return false
        end
    end
    
    return true
end

function KYBER.Communication:UseCommand(ply, command, args)
    if not IsValid(ply) then return false end
    if not self:CanUseCommand(ply, command) then return false end
    
    -- Get command data
    local commandData = self.Config.Commands[command]
    
    -- Update last command time
    ply.KyberCommunication.lastCommand[command] = os.time()
    
    -- Process command
    if command == "me" then
        -- Describe an action
        local message = string.format("* %s %s", ply:Nick(), args)
        if SERVER then
            net.Start("Kyber_Communication_Command")
            net.WriteEntity(ply)
            net.WriteString(command)
            net.WriteString(message)
            net.Send(ply:GetPlayersInRange(commandData.range))
        end
    elseif command == "do" then
        -- Describe a situation
        local message = string.format("* %s", args)
        if SERVER then
            net.Start("Kyber_Communication_Command")
            net.WriteEntity(ply)
            net.WriteString(command)
            net.WriteString(message)
            net.Send(ply:GetPlayersInRange(commandData.range))
        end
    elseif command == "roll" then
        -- Roll a dice
        local max = tonumber(args) or 100
        local roll = math.random(1, max)
        local message = string.format("* %s rolls %d (1-%d)", ply:Nick(), roll, max)
        if SERVER then
            net.Start("Kyber_Communication_Command")
            net.WriteEntity(ply)
            net.WriteString(command)
            net.WriteString(message)
            net.Send(ply:GetPlayersInRange(commandData.range))
        end
    end
    
    return true
end

function KYBER.Communication:BlockPlayer(ply, target)
    if not IsValid(ply) then return false end
    if not IsValid(target) then return false end
    if not self:CreateCommunicationData(ply) then return false end
    
    -- Add target to blocked players
    ply.KyberCommunication.blockedPlayers[target:SteamID()] = true
    
    return true
end

function KYBER.Communication:UnblockPlayer(ply, target)
    if not IsValid(ply) then return false end
    if not IsValid(target) then return false end
    if not self:CreateCommunicationData(ply) then return false end
    
    -- Remove target from blocked players
    ply.KyberCommunication.blockedPlayers[target:SteamID()] = nil
    
    return true
end

function KYBER.Communication:IsBlocked(ply, target)
    if not IsValid(ply) then return false end
    if not IsValid(target) then return false end
    if not self:CreateCommunicationData(ply) then return false end
    
    return ply.KyberCommunication.blockedPlayers[target:SteamID()] or false
end

function KYBER.Communication:GetBlockedPlayers(ply)
    if not IsValid(ply) then return {} end
    if not self:CreateCommunicationData(ply) then return {} end
    
    local blocked = {}
    for steamID, _ in pairs(ply.KyberCommunication.blockedPlayers) do
        local target = player.GetBySteamID(steamID)
        if IsValid(target) then
            table.insert(blocked, target)
        end
    end
    
    return blocked
end

function KYBER.Communication:SetMuted(ply, muted)
    if not IsValid(ply) then return false end
    if not self:CreateCommunicationData(ply) then return false end
    
    ply.KyberCommunication.muted = muted
    return true
end

function KYBER.Communication:IsMuted(ply)
    if not IsValid(ply) then return false end
    if not self:CreateCommunicationData(ply) then return false end
    
    return ply.KyberCommunication.muted
end

-- Initialize the module
KYBER.Communication:Initialize() 