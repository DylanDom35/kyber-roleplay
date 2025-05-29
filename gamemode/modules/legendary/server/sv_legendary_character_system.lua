-- kyber/modules/legendary/system.lua
KYBER.Legendary = KYBER.Legendary or {}

-- Legendary character definitions
KYBER.Legendary.Characters = {
    ["luke_skywalker"] = {
        name = "Luke Skywalker",
        description = "Last of the Jedi, son of Anakin",
        model = "models/player/luke/luke.mdl", -- Replace with actual model
        faction = "jedi",
        forceSensitive = true,
        abilities = {"force_push", "force_jump", "lightsaber_mastery"},
        priority = 1 -- Lower number = higher priority
    },
    
    ["leia_organa"] = {
        name = "Leia Organa",
        description = "Princess of Alderaan, Rebel leader",
        model = "models/player/leia/leia.mdl",
        faction = "rebel",
        forceSensitive = true,
        abilities = {"leadership", "diplomacy", "force_sense"},
        priority = 1
    },
    
    ["boba_fett"] = {
        name = "Boba Fett",
        description = "The galaxy's most feared bounty hunter",
        model = "models/player/boba/boba.mdl",
        faction = "bounty",
        forceSensitive = false,
        abilities = {"jetpack", "flamethrower", "tracking"},
        priority = 2
    },
    
    ["mara_jade"] = {
        name = "Mara Jade",
        description = "Former Emperor's Hand turned Jedi",
        model = "models/player/mara/mara.mdl",
        faction = "jedi",
        forceSensitive = true,
        abilities = {"stealth", "force_cloak", "lightsaber_mastery"},
        priority = 2
    },
    
    ["thrawn"] = {
        name = "Grand Admiral Thrawn",
        description = "Brilliant Imperial strategist",
        model = "models/player/thrawn/thrawn.mdl",
        faction = "imperial",
        forceSensitive = false,
        abilities = {"tactics", "art_analysis", "command"},
        priority = 2
    }
}

if SERVER then
    util.AddNetworkString("Kyber_RequestLegendaryChar")
    util.AddNetworkString("Kyber_OpenLegendaryMenu")
    util.AddNetworkString("Kyber_UpdateLegendaryStatus")
    util.AddNetworkString("Kyber_AdminSetLegendary")
    
    -- Store whitelist data
    function KYBER:LoadLegendaryWhitelist()
        if not file.Exists("kyber/legendary", "DATA") then
            file.CreateDir("kyber/legendary")
        end
        
        if file.Exists("kyber/legendary/whitelist.json", "DATA") then
            local data = file.Read("kyber/legendary/whitelist.json", "DATA")
            KYBER.Legendary.Whitelist = util.JSONToTable(data) or {}
        else
            KYBER.Legendary.Whitelist = {}
        end
        
        -- Active characters tracking
        if file.Exists("kyber/legendary/active.json", "DATA") then
            local data = file.Read("kyber/legendary/active.json", "DATA")
            KYBER.Legendary.Active = util.JSONToTable(data) or {}
        else
            KYBER.Legendary.Active = {}
        end
    end
    
    function KYBER:SaveLegendaryData()
        file.Write("kyber/legendary/whitelist.json", util.TableToJSON(KYBER.Legendary.Whitelist))
        file.Write("kyber/legendary/active.json", util.TableToJSON(KYBER.Legendary.Active))
    end
    
    -- Initialize
    hook.Add("Initialize", "KyberLoadLegendary", function()
        KYBER:LoadLegendaryWhitelist()
    end)
    
    -- Whitelist management
    function KYBER:AddToLegendaryWhitelist(steamID, priority)
        KYBER.Legendary.Whitelist[steamID] = {
            priority = priority or 3,
            added = os.time()
        }
        KYBER:SaveLegendaryData()
    end
    
    function KYBER:RemoveFromLegendaryWhitelist(steamID)
        KYBER.Legendary.Whitelist[steamID] = nil
        KYBER:SaveLegendaryData()
    end
    
    function KYBER:GetPlayerLegendaryPriority(ply)
        local steamID = ply:SteamID64()
        local data = KYBER.Legendary.Whitelist[steamID]
        return data and data.priority or 999 -- 999 = not whitelisted
    end
    
    -- Check if player can claim a legendary character
    function KYBER:CanClaimLegendary(ply, charID)
        local char = KYBER.Legendary.Characters[charID]
        if not char then return false, "Invalid character" end
        
        local playerPriority = KYBER:GetPlayerLegendaryPriority(ply)
        
        -- Check if not whitelisted
        if playerPriority >= 999 then
            return false, "You are not whitelisted for legendary characters"
        end
        
        -- Check if character is already taken
        local currentHolder = KYBER.Legendary.Active[charID]
        if currentHolder and currentHolder.steamID ~= ply:SteamID64() then
            -- Check priority override
            local currentPly = player.GetBySteamID64(currentHolder.steamID)
            if IsValid(currentPly) then
                local currentPriority = KYBER:GetPlayerLegendaryPriority(currentPly)
                
                if playerPriority < currentPriority then
                    -- Higher priority player can override
                    return true
                else
                    return false, "Character already claimed by equal or higher priority player"
                end
            end
        end
        
        -- Check character priority requirement
        if playerPriority > char.priority then
            return false, "Your whitelist level (" .. playerPriority .. ") is too low for this character (requires " .. char.priority .. ")"
        end
        
        return true
    end
    
    -- Claim a legendary character
    function KYBER:ClaimLegendaryCharacter(ply, charID)
        local canClaim, reason = KYBER:CanClaimLegendary(ply, charID)
        if not canClaim then
            return false, reason
        end
        
        local char = KYBER.Legendary.Characters[charID]
        
        -- Remove previous holder if being overridden
        local currentHolder = KYBER.Legendary.Active[charID]
        if currentHolder then
            local oldPly = player.GetBySteamID64(currentHolder.steamID)
            if IsValid(oldPly) then
                oldPly:SetNWString("kyber_legendary", "")
                oldPly:ChatPrint("Your legendary character has been claimed by a higher priority player.")
                
                -- Reset them to normal character
                KYBER:ResetToNormalCharacter(oldPly)
            end
        end
        
        -- Clear any other legendary character the player might have
        for id, data in pairs(KYBER.Legendary.Active) do
            if data.steamID == ply:SteamID64() then
                KYBER.Legendary.Active[id] = nil
            end
        end
        
        -- Set the new legendary character
        KYBER.Legendary.Active[charID] = {
            steamID = ply:SteamID64(),
            claimed = os.time()
        }
        
        -- Apply character settings
        ply:SetNWString("kyber_legendary", charID)
        ply:SetNWString("kyber_name", char.name)
        ply:SetModel(char.model)
        
        -- Set faction if specified
        if char.faction and KYBER.Factions[char.faction] then
            KYBER:SetFaction(ply, char.faction)
        end
        
        -- Grant abilities (implement based on your ability system)
        -- KYBER:GrantAbilities(ply, char.abilities)
        
        KYBER:SaveLegendaryData()
        
        -- Announce
        for _, p in ipairs(player.GetAll()) do
            p:ChatPrint(ply:Nick() .. " has become " .. char.name)
        end
        
        return true
    end
    
    function KYBER:ResetToNormalCharacter(ply)
        -- Reset to their normal character data
        ply:SetNWString("kyber_legendary", "")
        ply:SetNWString("kyber_name", ply:GetPData("kyber_name", ply:Nick()))
        ply:SetModel("models/player/group01/male_02.mdl") -- Default model
        
        -- Restore normal faction
        local savedFaction = ply:GetPData("kyber_faction", "")
        if savedFaction ~= "" then
            KYBER:SetFaction(ply, savedFaction)
        end
    end
    
    -- Network handlers
    net.Receive("Kyber_RequestLegendaryChar", function(len, ply)
        local charID = net.ReadString()
        local useCustom = net.ReadBool()
        
        if useCustom then
            -- Player chose to use custom character instead
            KYBER:ResetToNormalCharacter(ply)
            ply:ChatPrint("Using your custom character.")
        else
            local success, reason = KYBER:ClaimLegendaryCharacter(ply, charID)
            if not success then
                ply:ChatPrint("Failed to claim character: " .. reason)
            end
        end
    end)
    
    -- Admin commands
    concommand.Add("kyber_legendary_whitelist", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        if #args < 2 then
            ply:PrintMessage(HUD_PRINTCONSOLE, "Usage: kyber_legendary_whitelist <add|remove> <steamid> [priority]")
            return
        end
        
        local action = args[1]
        local steamID = args[2]
        
        if action == "add" then
            local priority = tonumber(args[3]) or 3
            KYBER:AddToLegendaryWhitelist(steamID, priority)
            ply:PrintMessage(HUD_PRINTCONSOLE, "Added " .. steamID .. " to whitelist with priority " .. priority)
        elseif action == "remove" then
            KYBER:RemoveFromLegendaryWhitelist(steamID)
            ply:PrintMessage(HUD_PRINTCONSOLE, "Removed " .. steamID .. " from whitelist")
        end
    end)
    
    -- Check legendary status on spawn
    hook.Add("PlayerSpawn", "KyberCheckLegendary", function(ply)
        timer.Simple(0.5, function()
            if not IsValid(ply) then return end
            
            -- Check if whitelisted
            if KYBER:GetPlayerLegendaryPriority(ply) < 999 then
                -- Check for available legendary characters
                local available = {}
                for charID, char in pairs(KYBER.Legendary.Characters) do
                    local canClaim = KYBER:CanClaimLegendary(ply, charID)
                    if canClaim then
                        table.insert(available, charID)
                    end
                end
                
                if #available > 0 then
                    -- Notify player
                    timer.Simple(2, function()
                        if IsValid(ply) then
                            net.Start("Kyber_OpenLegendaryMenu")
                            net.WriteTable(available)
                            net.Send(ply)
                        end
                    end)
                end
            end
        end)
    end)
    
else -- CLIENT
    
    net.Receive("Kyber_OpenLegendaryMenu", function()
        local available = net.ReadTable()
        
        if IsValid(LegendaryFrame) then LegendaryFrame:Remove() end
        
        LegendaryFrame = vgui.Create("DFrame")
        LegendaryFrame:SetSize(600, 400)
        LegendaryFrame:Center()
        LegendaryFrame:SetTitle("Choose Your Path")
        LegendaryFrame:MakePopup()
        
        local info = vgui.Create("DLabel", LegendaryFrame)
        info:SetText("You are whitelisted for legendary characters. Choose your path:")
        info:SetWrap(true)
        info:SetAutoStretchVertical(true)
        info:Dock(TOP)
        info:DockMargin(10, 10, 10, 10)
        
        local scroll = vgui.Create("DScrollPanel", LegendaryFrame)
        scroll:Dock(FILL)
        scroll:DockMargin(10, 0, 10, 10)
        
        -- Show available legendary characters
        for _, charID in ipairs(available) do
            local char = KYBER.Legendary.Characters[charID]
            if not char then continue end
            
            local btn = vgui.Create("DButton", scroll)
            btn:SetText("")
            btn:SetTall(80)
            btn:Dock(TOP)
            btn:DockMargin(0, 0, 0, 5)
            
            btn.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50))
                
                if self:IsHovered() then
                    draw.RoundedBox(4, 0, 0, w, h, Color(100, 100, 100, 50))
                end
                
                -- Character info
                draw.SimpleText(char.name, "DermaLarge", 10, 10, Color(255, 255, 255))
                draw.SimpleText(char.description, "DermaDefault", 10, 35, Color(200, 200, 200))
                draw.SimpleText("Faction: " .. (char.faction or "None"), "DermaDefault", 10, 55, Color(150, 150, 150))
            end
            
            btn.DoClick = function()
                net.Start("Kyber_RequestLegendaryChar")
                net.WriteString(charID)
                net.WriteBool(false) -- Not using custom
                net.SendToServer()
                
                LegendaryFrame:Close()
            end
        end
        
        -- Option to use custom character
        local customBtn = vgui.Create("DButton", LegendaryFrame)
        customBtn:SetText("Use My Custom Character")
        customBtn:SetTall(40)
        customBtn:Dock(BOTTOM)
        customBtn:DockMargin(10, 0, 10, 10)
        
        customBtn.DoClick = function()
            net.Start("Kyber_RequestLegendaryChar")
            net.WriteString("")
            net.WriteBool(true) -- Using custom
            net.SendToServer()
            
            LegendaryFrame:Close()
        end
    end)
end