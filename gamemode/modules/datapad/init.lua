-- Initialize datapad module
KYBER.Datapad = KYBER.Datapad or {}

-- Register network strings
KYBER.Management.Network:Register("Kyber_Datapad_Open")
KYBER.Management.Network:Register("Kyber_Datapad_Update")
KYBER.Management.Network:Register("Kyber_Datapad_Save")

-- Handle datapad open requests
net.Receive("Kyber_Datapad_Open", function(len, ply)
    local success, err = pcall(function()
        -- Send datapad data to client
        net.Start("Kyber_Datapad_Update")
        net.WriteTable({
            notes = {},
            contacts = {},
            missions = {}
        })
        net.Send(ply)
    end)
    
    if not success then
        KYBER.Management.ErrorHandler:Handle(err, "Failed to open datapad for " .. ply:SteamID64())
    end
end)

-- Cleanup function
function KYBER.Datapad:Cleanup()
    -- Add any cleanup code here
end 