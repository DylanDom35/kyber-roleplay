include("shared.lua")

net.Receive("Kyber_OpenTerminalUI", function()
    local terminal = net.ReadEntity()

    if not IsValid(terminal) then return end

    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 320)
    frame:Center()
    frame:SetTitle("Data Terminal")
    frame:MakePopup()

    local codeEntry = vgui.Create("DTextEntry", frame)
    codeEntry:SetPos(50, 50)
    codeEntry:SetSize(300, 30)
    codeEntry:SetPlaceholderText("Enter 4-digit code")

    local submit = vgui.Create("DButton", frame)
    submit:SetText("Unlock Door")
    submit:SetPos(50, 100)
    submit:SetSize(300, 30)
    submit.DoClick = function()
        net.Start("Kyber_Terminal_SubmitCode")
        net.WriteEntity(terminal)
        net.WriteString(codeEntry:GetValue())
        net.SendToServer()
        frame:Close()
    end

    -- Status display
    local status = vgui.Create("DLabel", frame)
    status:SetPos(50, 140)
    status:SetSize(300, 20)
    status:SetText("Failed Attempts: " .. (terminal:GetFailedAttempts() or 0))
    status:SetTextColor(Color(255, 200, 100))
    local lastUser = vgui.Create("DLabel", frame)
    lastUser:SetPos(50, 160)
    lastUser:SetSize(300, 20)
    lastUser:SetText("Last User: " .. (terminal:GetLastUser() or "N/A"))
    lastUser:SetTextColor(Color(200, 200, 255))
    local alarm = vgui.Create("DLabel", frame)
    alarm:SetPos(50, 180)
    alarm:SetSize(300, 20)
    alarm:SetText(terminal:GetAlarmActive() and "ALARM: ACTIVE" or "Alarm: Off")
    alarm:SetTextColor(terminal:GetAlarmActive() and Color(255, 50, 50) or Color(100, 255, 100))

    -- ADMIN/GM Setup Button
    if LocalPlayer():IsAdmin() then
        local linkButton = vgui.Create("DButton", frame)
        linkButton:SetText("Link Door (Look at a door)")
        linkButton:SetPos(50, 210)
        linkButton:SetSize(300, 25)

        linkButton.DoClick = function()
            local target = LocalPlayer():GetEyeTrace().Entity
            if not IsValid(target) then return end

            net.Start("Kyber_Terminal_SetLink")
            net.WriteEntity(terminal)
            net.WriteEntity(target)
            net.WriteString(codeEntry:GetValue())
            net.SendToServer()

            frame:Close()
        end

        local overrideButton = vgui.Create("DButton", frame)
        overrideButton:SetText("Admin Override (Open Door)")
        overrideButton:SetPos(50, 240)
        overrideButton:SetSize(300, 25)
        overrideButton.DoClick = function()
            net.Start("Kyber_Terminal_AdminOverride")
            net.WriteEntity(terminal)
            net.SendToServer()
            frame:Close()
        end

        local logButton = vgui.Create("DButton", frame)
        logButton:SetText("View Access Logs")
        logButton:SetPos(50, 270)
        logButton:SetSize(300, 25)
        logButton.DoClick = function()
            net.Start("Kyber_Terminal_RequestLogs")
            net.WriteEntity(terminal)
            net.SendToServer()
        end

        net.Receive("Kyber_Terminal_SendLogs", function()
            local ent = net.ReadEntity()
            local logs = net.ReadTable()
            if ent ~= terminal then return end
            local logFrame = vgui.Create("DFrame")
            logFrame:SetSize(500, 400)
            logFrame:Center()
            logFrame:SetTitle("Terminal Access Logs")
            logFrame:MakePopup()
            local logList = vgui.Create("DListView", logFrame)
            logList:Dock(FILL)
            logList:AddColumn("Time")
            logList:AddColumn("User")
            logList:AddColumn("Action")
            logList:AddColumn("Code")
            for _, log in ipairs(logs) do
                logList:AddLine(os.date("%H:%M:%S", log.time), log.user or "?", log.action or "", log.code or "")
            end
        end)
    end
end)

net.Receive("Kyber_Terminal_Alarm", function()
    local terminal = net.ReadEntity()
    if not IsValid(terminal) then return end
    surface.PlaySound("ambient/alarms/klaxon1.wav")
    notification.AddLegacy("[Kyber Terminal] Alarm triggered!", NOTIFY_ERROR, 5)
end)
