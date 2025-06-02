if SERVER then
    util.AddNetworkString("Kyber_AdminPanel_Open")
    util.AddNetworkString("Kyber_AdminPanel_RequestJournal")
    util.AddNetworkString("Kyber_AdminPanel_SendJournal")
    util.AddNetworkString("Kyber_AdminPanel_SetFaction")
    util.AddNetworkString("Kyber_AdminPanel_Promote")
    util.AddNetworkString("Kyber_AdminPanel_Demote")

    concommand.Add("kyber_adminmenu", function(ply)
        if not KYBER.Admin or not KYBER.Admin:IsAdmin(ply) then return end
        net.Start("Kyber_AdminPanel_Open")
        net.Send(ply)
    end)

    net.Receive("Kyber_AdminPanel_RequestJournal", function(len, ply)
        local target = net.ReadEntity()
        if not IsValid(target) then return end

        local path = "kyber/journals/" .. target:SteamID64() .. ".txt"
        local content = file.Exists(path, "DATA") and file.Read(path, "DATA") or "No journal found."

        net.Start("Kyber_AdminPanel_SendJournal")
        net.WriteEntity(target)
        net.WriteString(content)
        net.Send(ply)
    end)

    net.Receive("Kyber_AdminPanel_SetFaction", function(len, ply)
        if not KYBER.Admin or not KYBER.Admin:IsAdmin(ply) then return end
        local target = net.ReadEntity()
        local factionID = net.ReadString()
        if KYBER.Factions[factionID] and IsValid(target) then
            KYBER:SetFaction(target, factionID)
        end
    end)

    net.Receive("Kyber_AdminPanel_Promote", function(len, ply)
        local target = net.ReadEntity()
        if IsValid(target) then
            KYBER:Promote(target)
        end
    end)

    net.Receive("Kyber_AdminPanel_Demote", function(len, ply)
        local target = net.ReadEntity()
        if IsValid(target) then
            KYBER:Demote(target)
        end
    end)
else
    net.Receive("Kyber_AdminPanel_Open", function()
        local frame = vgui.Create("DFrame")
        frame:SetSize(700, 600)
        frame:Center()
        frame:SetTitle("Kyber Admin Panel")
        frame:MakePopup()

        local playerList = vgui.Create("DComboBox", frame)
        playerList:SetPos(20, 40)
        playerList:SetSize(300, 25)
        playerList:SetValue("Select Player")

        local targetPlayer = nil

        for _, ply in ipairs(player.GetAll()) do
            playerList:AddChoice(ply:Nick(), ply)
        end

        playerList.OnSelect = function(_, _, text, data)
            targetPlayer = data
        end

        local readJournal = vgui.Create("DButton", frame)
        readJournal:SetText("Read Journal")
        readJournal:SetPos(350, 40)
        readJournal:SetSize(150, 25)

        local journalBox = vgui.Create("DTextEntry", frame)
        journalBox:SetMultiline(true)
        journalBox:SetSize(660, 400)
        journalBox:SetPos(20, 80)
        journalBox:SetText("Select a player and press 'Read Journal'.")

        readJournal.DoClick = function()
            if IsValid(targetPlayer) then
                net.Start("Kyber_AdminPanel_RequestJournal")
                net.WriteEntity(targetPlayer)
                net.SendToServer()
            end
        end

        net.Receive("Kyber_AdminPanel_SendJournal", function()
            local target = net.ReadEntity()
            local content = net.ReadString()
            if IsValid(frame) then
                journalBox:SetText("[" .. target:Nick() .. "]\n\n" .. content)
            end
        end)

        local promoteBtn = vgui.Create("DButton", frame)
        promoteBtn:SetText("Promote")
        promoteBtn:SetPos(20, 500)
        promoteBtn:SetSize(100, 30)
        promoteBtn.DoClick = function()
            if IsValid(targetPlayer) then
                net.Start("Kyber_AdminPanel_Promote")
                net.WriteEntity(targetPlayer)
                net.SendToServer()
            end
        end

        local demoteBtn = vgui.Create("DButton", frame)
        demoteBtn:SetText("Demote")
        demoteBtn:SetPos(130, 500)
        demoteBtn:SetSize(100, 30)
        demoteBtn.DoClick = function()
            if IsValid(targetPlayer) then
                net.Start("Kyber_AdminPanel_Demote")
                net.WriteEntity(targetPlayer)
                net.SendToServer()
            end
        end

        local factionSelect = vgui.Create("DComboBox", frame)
        factionSelect:SetPos(250, 500)
        factionSelect:SetSize(200, 30)
        factionSelect:SetValue("Assign Faction")
        for id, data in pairs(KYBER.Factions) do
            factionSelect:AddChoice(data.name, id)
        end

        local setFactionBtn = vgui.Create("DButton", frame)
        setFactionBtn:SetText("Set Faction")
        setFactionBtn:SetPos(460, 500)
        setFactionBtn:SetSize(100, 30)
        setFactionBtn.DoClick = function()
            if IsValid(targetPlayer) and factionSelect:GetSelected() then
                net.Start("Kyber_AdminPanel_SetFaction")
                net.WriteEntity(targetPlayer)
                net.WriteString(factionSelect:GetSelected())
                net.SendToServer()
            end
        end
    end)
end
