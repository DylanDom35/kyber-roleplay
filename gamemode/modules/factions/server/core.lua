if SERVER then

concommand.Add("kyber_promote", function(ply, cmd, args)
    local target = ply:GetEyeTrace().Entity
    if IsValid(target) and target:IsPlayer() then
        if KYBER:Promote(target) then
            ply:ChatPrint("Promoted " .. target:Nick())
        else
            ply:ChatPrint("Promotion failed.")
        end
    end
end)

concommand.Add("kyber_demote", function(ply, cmd, args)
    local target = ply:GetEyeTrace().Entity
    if IsValid(target) and target:IsPlayer() then
        if KYBER:Demote(target) then
            ply:ChatPrint("Demoted " .. target:Nick())
        else
            ply:ChatPrint("Demotion failed.")
        end
    end
end)

    util.AddNetworkString("Kyber_OpenFactionMenu")
    util.AddNetworkString("Kyber_RequestJoinFaction")

    function KYBER:SetFaction(ply, factionID)
        if not KYBER.Factions[factionID] then return end

        ply:SetNWString("kyber_faction", factionID)
        ply:SetNWString("kyber_rank", KYBER.Factions[factionID].ranks[1]) -- default rank
    end

    net.Receive("Kyber_RequestJoinFaction", function(len, ply)
        local factionID = net.ReadString()
        if not KYBER.Factions[factionID] then return end
        KYBER:SetFaction(ply, factionID)
    end)
else
    net.Receive("Kyber_OpenFactionMenu", function()
        Kyber_OpenFactionMenu()
    end)
	

function KYBER:Promote(ply)
    local factionID = ply:GetNWString("kyber_faction", "")
    if not KYBER.Factions[factionID] then return end

    local currentRank = ply:GetNWString("kyber_rank", "")
    local ranks = KYBER.Factions[factionID].ranks
    for i, rank in ipairs(ranks) do
        if rank == currentRank and i < #ranks then
            ply:SetNWString("kyber_rank", ranks[i + 1])
            return true
        end
    end
    return false
end

function KYBER:Demote(ply)
    local factionID = ply:GetNWString("kyber_faction", "")
    if not KYBER.Factions[factionID] then return end

    local currentRank = ply:GetNWString("kyber_rank", "")
    local ranks = KYBER.Factions[factionID].ranks
    for i, rank in ipairs(ranks) do
        if rank == currentRank and i > 1 then
            ply:SetNWString("kyber_rank", ranks[i - 1])
            return true
        end
    end
    return false
end


    function Kyber_OpenFactionMenu()
        if IsValid(FactionFrame) then FactionFrame:Remove() end

        FactionFrame = vgui.Create("DFrame")
        FactionFrame:SetSize(400, 500)
        FactionFrame:Center()
        FactionFrame:SetTitle("Join a Faction")
        FactionFrame:MakePopup()

        local scroll = vgui.Create("DScrollPanel", FactionFrame)
        scroll:Dock(FILL)

        for id, data in pairs(KYBER.Factions) do
            local btn = vgui.Create("DButton", scroll)
            btn:SetText(data.name .. " - " .. data.description)
            btn:Dock(TOP)
            btn:DockMargin(10, 5, 10, 5)
            btn:SetTall(50)
            btn:SetTextColor(data.color)

            btn.DoClick = function()
                net.Start("Kyber_RequestJoinFaction")
                net.WriteString(id)
                net.SendToServer()
                FactionFrame:Close()
            end
        end
    end

    -- Temporary keybind: F2
    hook.Add("ShowSpare2", "KyberFactionKeybind", function()
        Kyber_OpenFactionMenu()
    end)
end

function KYBER:SetRank(ply, rankName)
    local factionID = ply:GetNWString("kyber_faction", "")
    if not KYBER.Factions[factionID] then return end

    for _, rank in ipairs(KYBER.Factions[factionID].ranks) do
        if rank == rankName then
            ply:SetNWString("kyber_rank", rankName)
            return true
        end
    end
    return false
end
