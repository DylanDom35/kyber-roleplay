if SERVER then
    util.AddNetworkString("Kyber_ChatMessage")

    local function SendChat(ply, text, chatType, color, range)
        if chatType == "ooc" then
            for _, v in ipairs(player.GetAll()) do
                net.Start("Kyber_ChatMessage")
                net.WriteEntity(ply)
                net.WriteString(text)
                net.WriteString(chatType)
                net.WriteColor(color)
                net.Send(v)
            end
            return
        end

        for _, v in ipairs(player.GetAll()) do
            if v:GetPos():DistToSqr(ply:GetPos()) <= (range * range) then
                net.Start("Kyber_ChatMessage")
                net.WriteEntity(ply)
                net.WriteString(text)
                net.WriteString(chatType)
                net.WriteColor(color)
                net.Send(v)
            end
        end
    end

    hook.Add("PlayerSay", "Kyber_CustomChat", function(ply, msg)
        local lower = string.Trim(string.lower(msg))

        -- /me emote
        if lower:StartWith("/me ") then
            local action = string.sub(msg, 5)
            SendChat(ply, "* " .. ply:Nick() .. " " .. action, "me", Color(200, 200, 255), 400)
            return ""
        end

        -- whisper
        if lower:StartWith("/w ") or lower:StartWith("/whisper ") then
            local realMsg = msg:match("^/[%w]+%s+(.*)")
            SendChat(ply, ply:Nick() .. " whispers: " .. realMsg, "whisper", Color(150, 150, 255), 150)
            return ""
        end

        -- shout
        if lower:StartWith("/s ") or lower:StartWith("/shout ") then
            local realMsg = msg:match("^/[%w]+%s+(.*)")
            SendChat(ply, ply:Nick() .. " shouts: " .. realMsg, "shout", Color(255, 200, 0), 800)
            return ""
        end

        -- ooc
        if lower:StartWith("//") or lower:StartWith("/ooc ") then
            local realMsg = msg:match("^/+[%w]*%s*(.*)")
            SendChat(ply, "[OOC] " .. ply:Nick() .. ": " .. realMsg, "ooc", Color(180, 180, 180), 0)
            return ""
        end

        -- default IC local chat
        SendChat(ply, ply:Nick() .. ": " .. msg, "ic", Color(255, 255, 255), 400)
        return ""
    end)
else
    net.Receive("Kyber_ChatMessage", function()
        local ply = net.ReadEntity()
        local text = net.ReadString()
        local chatType = net.ReadString()
        local color = net.ReadColor()

        chat.AddText(color, text)
        surface.PlaySound("buttons/button16.wav")
    end)
end
