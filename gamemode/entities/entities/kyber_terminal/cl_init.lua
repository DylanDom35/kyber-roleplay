include("shared.lua")

net.Receive("Kyber_OpenTerminalUI", function()
    local terminal = net.ReadEntity()

    if not IsValid(terminal) then return end

    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 250)
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

    -- ADMIN/GM Setup Button
    if LocalPlayer():IsAdmin() then
        local linkButton = vgui.Create("DButton", frame)
        linkButton:SetText("Link Door (Look at a door)")
        linkButton:SetPos(50, 150)
        linkButton:SetSize(300, 30)

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
    end
end)
