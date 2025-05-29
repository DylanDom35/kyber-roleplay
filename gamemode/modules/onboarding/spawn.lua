if SERVER then
    util.AddNetworkString("Kyber_RequestOnboarding")
    util.AddNetworkString("Kyber_SubmitOnboarding")

    hook.Add("PlayerInitialSpawn", "KyberTriggerOnboarding", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                -- Only send if this player has no stored name/species yet
                if not ply:GetPData("kyber_name") then
                    net.Start("Kyber_RequestOnboarding")
                    net.Send(ply)
                else
                    -- Restore existing character data
                    ply:SetNWString("kyber_name", ply:GetPData("kyber_name", ply:Nick()))
                    ply:SetNWString("kyber_species", ply:GetPData("kyber_species", "Human"))
                    ply:SetNWString("kyber_alignment", ply:GetPData("kyber_alignment", "Neutral"))
                end
            end
        end)
    end)

    net.Receive("Kyber_SubmitOnboarding", function(len, ply)
        local name = net.ReadString()
        local species = net.ReadString()
        local alignment = net.ReadString()

        ply:SetPData("kyber_name", name)
        ply:SetPData("kyber_species", species)
        ply:SetPData("kyber_alignment", alignment)

        ply:SetNWString("kyber_name", name)
        ply:SetNWString("kyber_species", species)
        ply:SetNWString("kyber_alignment", alignment)
    end)
else
    net.Receive("Kyber_RequestOnboarding", function()
        Kyber_OpenOnboarding()
    end)

    function Kyber_OpenOnboarding()
        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 300)
        frame:Center()
        frame:SetTitle("Create Your Character")
        frame:MakePopup()

        local nameEntry = vgui.Create("DTextEntry", frame)
        nameEntry:SetPlaceholderText("Enter character name")
        nameEntry:SetSize(300, 25)
        nameEntry:SetPos(50, 50)

        local speciesEntry = vgui.Create("DTextEntry", frame)
        speciesEntry:SetPlaceholderText("Enter species (e.g. Human, Twi'lek)")
        speciesEntry:SetSize(300, 25)
        speciesEntry:SetPos(50, 90)

        local alignmentSelect = vgui.Create("DComboBox", frame)
        alignmentSelect:SetPos(50, 130)
        alignmentSelect:SetSize(300, 25)
        alignmentSelect:SetValue("Choose Alignment")
        alignmentSelect:AddChoice("Light")
        alignmentSelect:AddChoice("Neutral")
        alignmentSelect:AddChoice("Dark")

        local submitButton = vgui.Create("DButton", frame)
        submitButton:SetText("Confirm")
        submitButton:SetSize(300, 30)
        submitButton:SetPos(50, 180)

        submitButton.DoClick = function()
            local name = nameEntry:GetValue()
            local species = speciesEntry:GetValue()
            local alignment = alignmentSelect:GetValue()

            if name == "" or species == "" or alignment == "Choose Alignment" then
                LocalPlayer():ChatPrint("Please complete all fields.")
                return
            end

            net.Start("Kyber_SubmitOnboarding")
            net.WriteString(name)
            net.WriteString(species)
            net.WriteString(alignment)
            net.SendToServer()

            frame:Close()
        end
    end
end
