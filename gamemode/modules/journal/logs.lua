if SERVER then
    util.AddNetworkString("Kyber_OpenJournal")
    util.AddNetworkString("Kyber_SubmitJournal")
    util.AddNetworkString("Kyber_SendJournalData")

    local function GetJournalPath(ply)
        return "kyber/journals/" .. ply:SteamID64() .. ".txt"
    end

    function KYBER:GetJournal(ply)
        local path = GetJournalPath(ply)
        if not file.Exists("kyber/journals", "DATA") then
            file.CreateDir("kyber/journals")
        end

        if file.Exists(path, "DATA") then
            return file.Read(path, "DATA")
        else
            return ""
        end
    end

    function KYBER:SetJournal(ply, content)
        local path = GetJournalPath(ply)
        file.Write(path, content)
    end

    net.Receive("Kyber_SubmitJournal", function(len, ply)
        local content = net.ReadString()
        KYBER:SetJournal(ply, content)
    end)

    net.Receive("Kyber_OpenJournal", function(len, ply)
        local content = KYBER:GetJournal(ply)
        net.Start("Kyber_SendJournalData")
        net.WriteString(content)
        net.Send(ply)
    end)

else
    net.Receive("Kyber_SendJournalData", function()
        local content = net.ReadString()
        Kyber_OpenJournal(content)
    end)

    function Kyber_OpenJournal(content)
        if IsValid(JournalFrame) then JournalFrame:Remove() end

        JournalFrame = vgui.Create("DFrame")
        JournalFrame:SetSize(600, 500)
        JournalFrame:Center()
        JournalFrame:SetTitle("Personal Journal")
        JournalFrame:MakePopup()

        local textEntry = vgui.Create("DTextEntry", JournalFrame)
        textEntry:SetMultiline(true)
        textEntry:SetText(content or "")
        textEntry:Dock(FILL)
        textEntry:DockMargin(10, 10, 10, 10)

        local saveButton = vgui.Create("DButton", JournalFrame)
        saveButton:SetText("Save Journal")
        saveButton:Dock(BOTTOM)
        saveButton:DockMargin(10, 0, 10, 10)
        saveButton:SetTall(30)
        saveButton.DoClick = function()
            local newText = textEntry:GetValue()
            net.Start("Kyber_SubmitJournal")
            net.WriteString(newText)
            net.SendToServer()
            JournalFrame:Close()
        end
    end

    -- F3 to open journal
    hook.Add("ShowSpare3", "KyberJournalKeybind", function()
        net.Start("Kyber_OpenJournal")
        net.SendToServer()
    end)
end
