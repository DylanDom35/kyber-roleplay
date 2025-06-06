-- Initialize force lottery system
KYBER.ForceLottery = KYBER.ForceLottery or {}
KYBER.ForceLottery.NextLotteryTime = 0
KYBER.ForceLottery.CurrentParticipants = {}
KYBER.ForceLottery.Winner = nil

-- Load saved lottery data
local success, err = pcall(function()
    local data = KYBER.Management.File:Read("force_lottery.json")
    if data then
        KYBER.ForceLottery.NextLotteryTime = data.nextLotteryTime or 0
        KYBER.ForceLottery.CurrentParticipants = data.participants or {}
        KYBER.ForceLottery.Winner = data.winner
    end
end)

if not success then
    KYBER.Management.ErrorHandler:Handle(err, "Failed to load force lottery data")
end

-- Save lottery data periodically
KYBER.Management.Timers:Create("SaveForceLottery", 300, 0, function()
    local success, err = pcall(function()
        KYBER.Management.File:Write("force_lottery.json", {
            nextLotteryTime = KYBER.ForceLottery.NextLotteryTime,
            participants = KYBER.ForceLottery.CurrentParticipants,
            winner = KYBER.ForceLottery.Winner
        })
    end)
    
    if not success then
        KYBER.Management.ErrorHandler:Handle(err, "Failed to save force lottery data")
    end
end)

-- Handle lottery participation
KYBER.Management.Hooks:Add("PlayerSay", "ForceLotteryParticipation", function(ply, text)
    if text:lower() == "!lottery" then
        local success, err = pcall(function()
            if CurTime() >= KYBER.ForceLottery.NextLotteryTime then
                -- Start new lottery
                KYBER.ForceLottery.NextLotteryTime = CurTime() + 3600 -- 1 hour
                KYBER.ForceLottery.CurrentParticipants = {}
                KYBER.ForceLottery.Winner = nil
                hook.Run("Kyber_ForceLottery_Updated")
                ply:ChatPrint("A new force lottery has begun! Type !lottery to enter.")
            else
                -- Add player to current lottery
                if not table.HasValue(KYBER.ForceLottery.CurrentParticipants, ply:SteamID64()) then
                    table.insert(KYBER.ForceLottery.CurrentParticipants, ply:SteamID64())
                    hook.Run("Kyber_ForceLottery_Updated")
                    ply:ChatPrint("You have entered the force lottery!")
                else
                    ply:ChatPrint("You have already entered this lottery!")
                end
            end
        end)
        
        if not success then
            KYBER.Management.ErrorHandler:Handle(err, "Failed to process lottery participation for " .. ply:SteamID64())
            ply:ChatPrint("An error occurred while processing your lottery entry.")
        end
        
        return ""
    end
end)

-- Handle lottery drawing
KYBER.Management.Timers:Create("DrawForceLottery", 1, 0, function()
    if CurTime() >= KYBER.ForceLottery.NextLotteryTime and #KYBER.ForceLottery.CurrentParticipants > 0 then
        local success, err = pcall(function()
            -- Select random winner
            local winnerID = KYBER.ForceLottery.CurrentParticipants[math.random(1, #KYBER.ForceLottery.CurrentParticipants)]
            local winner = player.GetBySteamID64(winnerID)
            
            if IsValid(winner) then
                -- Award force sensitivity
                KYBER.Force:SetForceSensitive(winner, true)
                winner:ChatPrint("Congratulations! You have been chosen by the Force!")
                
                -- Broadcast to all players
                for _, ply in ipairs(player.GetAll()) do
                    ply:ChatPrint(winner:Nick() .. " has been chosen by the Force!")
                end
            end
            
            -- Reset lottery
            KYBER.ForceLottery.NextLotteryTime = CurTime() + 3600
            KYBER.ForceLottery.CurrentParticipants = {}
            KYBER.ForceLottery.Winner = winnerID
            hook.Run("Kyber_ForceLottery_Updated")
        end)
        
        if not success then
            KYBER.Management.ErrorHandler:Handle(err, "Failed to draw force lottery")
        end
    end
end)

-- Cleanup function
function KYBER.ForceLottery:Cleanup()
    KYBER.Management.Timers:Remove("SaveForceLottery")
    KYBER.Management.Timers:Remove("DrawForceLottery")
    KYBER.Management.Hooks:Remove("ForceLotteryParticipation")
end 