-- kyber/modules/galaxy/travel.lua
KYBER.Galaxy = KYBER.Galaxy or {}

-- Planet definitions
KYBER.Galaxy.Planets = {
    ["coruscant"] = {
        name = "Coruscant",
        description = "The galaxy's capital, a planet-wide city",
        icon = "icon16/building.png",
        coordinates = {x = 0, y = 0},
        color = Color(150, 150, 255),
        
        -- Local teleport points within the map
        localPoints = {
            {name = "Senate District", pos = Vector(0, 0, 100), ang = Angle(0, 0, 0)},
            {name = "Lower Levels", pos = Vector(0, 0, -1000), ang = Angle(0, 0, 0)},
            {name = "Jedi Temple", pos = Vector(2000, 0, 500), ang = Angle(0, 90, 0)}
        },
        
        -- Cross-server option
        serverIP = nil -- Set this if this planet is on another server
    },
    
    ["tatooine"] = {
        name = "Tatooine",
        description = "Desert world on the Outer Rim",
        icon = "icon16/weather_sun.png",
        coordinates = {x = 300, y = 200},
        color = Color(255, 200, 100),
        
        localPoints = {
            {name = "Mos Eisley", pos = Vector(1000, 1000, 100), ang = Angle(0, 0, 0)},
            {name = "Jabba's Palace", pos = Vector(-2000, 3000, 200), ang = Angle(0, 45, 0)},
            {name = "Sarlacc Pit", pos = Vector(5000, -1000, 0), ang = Angle(0, 0, 0)}
        },
        
        serverIP = nil
    },
    
    ["hoth"] = {
        name = "Hoth",
        description = "Frozen wasteland",
        icon = "icon16/weather_snow.png",
        coordinates = {x = -200, y = 300},
        color = Color(200, 200, 255),
        
        localPoints = {
            {name = "Echo Base", pos = Vector(0, 0, 100), ang = Angle(0, 0, 0)},
            {name = "Wampa Cave", pos = Vector(3000, 2000, -200), ang = Angle(0, 0, 0)}
        },
        
        serverIP = "123.456.789.0:27015" -- Example cross-server
    }
}

-- Current planet (set this based on your map)
KYBER.Galaxy.CurrentPlanet = "coruscant" -- Change per server/map

if SERVER then
    util.AddNetworkString("Kyber_OpenGalaxyMap")
    util.AddNetworkString("Kyber_TravelToPlanet")
    util.AddNetworkString("Kyber_TravelLocal")
    
    -- Travel cooldown system
    local travelCooldowns = {}
    
    function KYBER:CanPlayerTravel(ply)
        local steamID = ply:SteamID64()
        local cooldown = travelCooldowns[steamID]
        
        if cooldown and cooldown > CurTime() then
            return false, math.ceil(cooldown - CurTime())
        end
        
        -- Check if in combat (optional)
        if ply:Health() < ply:GetMaxHealth() then
            return false, "Cannot travel while injured"
        end
        
        return true
    end
    
    function KYBER:SetTravelCooldown(ply, duration)
        travelCooldowns[ply:SteamID64()] = CurTime() + (duration or 30)
    end
    
    -- Local teleportation
    net.Receive("Kyber_TravelLocal", function(len, ply)
        local pointIndex = net.ReadInt(8)
        local planet = KYBER.Galaxy.Planets[KYBER.Galaxy.CurrentPlanet]
        
        if not planet or not planet.localPoints[pointIndex] then return end
        
        local canTravel, reason = KYBER:CanPlayerTravel(ply)
        if not canTravel then
            if type(reason) == "number" then
                ply:ChatPrint("Travel cooldown: " .. reason .. " seconds remaining")
            else
                ply:ChatPrint(reason)
            end
            return
        end
        
        local point = planet.localPoints[pointIndex]
        
        -- Fade effect
        ply:ScreenFade(SCREENFADE.OUT, Color(255, 255, 255), 1, 0.5)
        
        timer.Simple(1, function()
            if IsValid(ply) then
                ply:SetPos(point.pos)
                ply:SetEyeAngles(point.ang)
                ply:ScreenFade(SCREENFADE.IN, Color(255, 255, 255), 1, 0)
                
                -- Set cooldown
                KYBER:SetTravelCooldown(ply, 30)
                
                -- Announcement
                ply:ChatPrint("Arrived at " .. point.name)
            end
        end)
    end)
    
    -- Cross-server travel
    net.Receive("Kyber_TravelToPlanet", function(len, ply)
        local planetID = net.ReadString()
        local planet = KYBER.Galaxy.Planets[planetID]
        
        if not planet then return end
        
        -- Check if it's cross-server
        if planet.serverIP then
            local canTravel, reason = KYBER:CanPlayerTravel(ply)
            if not canTravel then
                if type(reason) == "number" then
                    ply:ChatPrint("Travel cooldown: " .. reason .. " seconds remaining")
                else
                    ply:ChatPrint(reason)
                end
                return
            end
            
            -- Save player data before transfer
            KYBER:SavePlayerDataForTransfer(ply)
            
            -- Show loading screen
            ply:SendLua([[
                surface.PlaySound("ambient/machines/teleport4.wav")
                LocalPlayer():ScreenFade(SCREENFADE.OUT, Color(0, 0, 0), 2, 3)
            ]])
            
            timer.Simple(2, function()
                if IsValid(ply) then
                    -- Connect to other server
                    ply:SendLua([[RunConsoleCommand("connect", "]] .. planet.serverIP .. [[")]])
                end
            end)
        else
            ply:ChatPrint("This planet is on the current server. Use local travel points.")
        end
    end)
    
    -- Save player data for cross-server transfer
    function KYBER:SavePlayerDataForTransfer(ply)
        local data = {
            name = ply:GetNWString("kyber_name"),
            species = ply:GetNWString("kyber_species"),
            alignment = ply:GetNWString("kyber_alignment"),
            faction = ply:GetNWString("kyber_faction"),
            rank = ply:GetNWString("kyber_rank"),
            credits = KYBER:GetPlayerData(ply, "credits"),
            -- Add more data as needed
        }
        
        -- Save to file for retrieval on other server
        local path = "kyber/transfers/" .. ply:SteamID64() .. ".json"
        if not file.Exists("kyber/transfers", "DATA") then
            file.CreateDir("kyber/transfers")
        end
        
        file.Write(path, util.TableToJSON(data))
    end
    
    -- Load transfer data on spawn
    hook.Add("PlayerInitialSpawn", "KyberLoadTransferData", function(ply)
        timer.Simple(2, function()
            if not IsValid(ply) then return end
            
            local path = "kyber/transfers/" .. ply:SteamID64() .. ".json"
            if file.Exists(path, "DATA") then
                local data = util.JSONToTable(file.Read(path, "DATA"))
                
                -- Restore player data
                ply:SetNWString("kyber_name", data.name or ply:Nick())
                ply:SetNWString("kyber_species", data.species or "Human")
                ply:SetNWString("kyber_alignment", data.alignment or "Neutral")
                ply:SetNWString("kyber_faction", data.faction or "")
                ply:SetNWString("kyber_rank", data.rank or "")
                KYBER:SetPlayerData(ply, "credits", data.credits or 100)
                
                -- Delete transfer file
                file.Delete(path)
                
                ply:ChatPrint("Character data restored from galactic travel.")
            end
        end)
    end)
    
else -- CLIENT
    
    -- Galaxy map UI
    function KYBER:OpenGalaxyMap()
        if IsValid(GalaxyFrame) then GalaxyFrame:Remove() end
        
        GalaxyFrame = vgui.Create("DFrame")
        GalaxyFrame:SetSize(800, 600)
        GalaxyFrame:Center()
        GalaxyFrame:SetTitle("Galaxy Map")
        GalaxyFrame:MakePopup()
        
        -- Main panel for the map
        local mapPanel = vgui.Create("DPanel", GalaxyFrame)
        mapPanel:Dock(FILL)
        mapPanel:DockMargin(10, 10, 10, 10)
        
        -- Starfield background
        mapPanel.Paint = function(self, w, h)
            surface.SetDrawColor(0, 0, 20)
            surface.DrawRect(0, 0, w, h)
            
            -- Draw stars
            math.randomseed(1337)
            for i = 1, 100 do
                local x = math.random(0, w)
                local y = math.random(0, h)
                local size = math.random(1, 3)
                local brightness = math.random(100, 255)
                
                surface.SetDrawColor(brightness, brightness, brightness)
                surface.DrawRect(x, y, size, size)
            end
            
            -- Draw hyperspace lines between planets
            surface.SetDrawColor(50, 50, 100, 100)
            for id1, planet1 in pairs(KYBER.Galaxy.Planets) do
                for id2, planet2 in pairs(KYBER.Galaxy.Planets) do
                    if id1 < id2 then
                        local x1 = planet1.coordinates.x + w/2
                        local y1 = planet1.coordinates.y + h/2
                        local x2 = planet2.coordinates.x + w/2
                        local y2 = planet2.coordinates.y + h/2
                        
                        surface.DrawLine(x1, y1, x2, y2)
                    end
                end
            end
        end
        
        -- Create planet buttons
        for planetID, planet in pairs(KYBER.Galaxy.Planets) do
            local btn = vgui.Create("DButton", mapPanel)
            btn:SetText("")
            btn:SetSize(80, 80)
            
            local x = planet.coordinates.x + mapPanel:GetWide()/2 - 40
            local y = planet.coordinates.y + mapPanel:GetTall()/2 - 40
            btn:SetPos(x, y)
            
            -- Highlight current planet
            local isCurrent = (planetID == KYBER.Galaxy.CurrentPlanet)
            
            btn.Paint = function(self, w, h)
                -- Planet circle
                if isCurrent then
                    draw.RoundedBox(40, 0, 0, w, h, Color(100, 255, 100, 50))
                end
                
                draw.RoundedBox(35, 5, 5, w-10, h-10, planet.color)
                
                -- Planet name
                draw.SimpleText(planet.name, "DermaDefault", w/2, h + 5, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            end
            
            btn.DoClick = function()
                KYBER:ShowPlanetInfo(planetID)
            end
            
            -- Tooltip
            btn:SetTooltip(planet.description)
        end
        
        -- Current location indicator
        local locLabel = vgui.Create("DLabel", GalaxyFrame)
        locLabel:SetText("Current Location: " .. KYBER.Galaxy.Planets[KYBER.Galaxy.CurrentPlanet].name)
        locLabel:SetFont("DermaLarge")
        locLabel:Dock(BOTTOM)
        locLabel:DockMargin(10, 0, 10, 10)
        locLabel:SetContentAlignment(5)
    end
    
    -- Planet info panel
    function KYBER:ShowPlanetInfo(planetID)
        if IsValid(PlanetInfoFrame) then PlanetInfoFrame:Remove() end
        
        local planet = KYBER.Galaxy.Planets[planetID]
        if not planet then return end
        
        PlanetInfoFrame = vgui.Create("DFrame")
        PlanetInfoFrame:SetSize(400, 500)
        PlanetInfoFrame:Center()
        PlanetInfoFrame:SetTitle(planet.name)
        PlanetInfoFrame:MakePopup()
        
        local scroll = vgui.Create("DScrollPanel", PlanetInfoFrame)
        scroll:Dock(FILL)
        scroll:DockMargin(10, 10, 10, 10)
        
        -- Description
        local desc = vgui.Create("DLabel", scroll)
        desc:SetText(planet.description)
        desc:SetWrap(true)
        desc:SetAutoStretchVertical(true)
        desc:Dock(TOP)
        desc:DockMargin(0, 0, 0, 20)
        
        -- Check if on current planet
        if planetID == KYBER.Galaxy.CurrentPlanet then
            local label = vgui.Create("DLabel", scroll)
            label:SetText("=== Local Travel Points ===")
            label:SetFont("DermaDefaultBold")
            label:Dock(TOP)
            label:DockMargin(0, 0, 0, 10)
            
            -- Show local teleport points
            for i, point in ipairs(planet.localPoints) do
                local btn = vgui.Create("DButton", scroll)
                btn:SetText(point.name)
                btn:Dock(TOP)
                btn:DockMargin(0, 0, 0, 5)
                btn:SetTall(30)
                
                btn.DoClick = function()
                    net.Start("Kyber_TravelLocal")
                    net.WriteInt(i, 8)
                    net.SendToServer()
                    
                    PlanetInfoFrame:Close()
                    if IsValid(GalaxyFrame) then GalaxyFrame:Close() end
                end
            end
        else
            -- Cross-server travel option
            if planet.serverIP then
                local label = vgui.Create("DLabel", scroll)
                label:SetText("This planet is on another server.")
                label:SetWrap(true)
                label:SetAutoStretchVertical(true)
                label:Dock(TOP)
                label:DockMargin(0, 0, 0, 10)
                
                local travelBtn = vgui.Create("DButton", scroll)
                travelBtn:SetText("Travel to " .. planet.name)
                travelBtn:SetTall(40)
                travelBtn:Dock(TOP)
                travelBtn:DockMargin(0, 10, 0, 0)
                
                travelBtn.DoClick = function()
                    Derma_Query(
                        "Travel to " .. planet.name .. "?\n\nThis will connect you to another server.",
                        "Galactic Travel",
                        "Travel", function()
                            net.Start("Kyber_TravelToPlanet")
                            net.WriteString(planetID)
                            net.SendToServer()
                        end,
                        "Cancel", function() end
                    )
                end
            else
                local label = vgui.Create("DLabel", scroll)
                label:SetText("This planet is on the current server but you are not there. Use a spaceport to travel between planets.")
                label:SetWrap(true)
                label:SetAutoStretchVertical(true)
                label:Dock(TOP)
                label:DockMargin(0, 0, 0, 10)
            end
        end
    end
    
    -- Bind to a key or command
    concommand.Add("kyber_galaxy", function()
        KYBER:OpenGalaxyMap()
    end)
    
    -- Add to F4 datapad
    hook.Add("Kyber_Datapad_AddTabs", "AddGalaxyTab", function(tabSheet)
        local galaxyPanel = vgui.Create("DPanel", tabSheet)
        galaxyPanel:Dock(FILL)
        
        local openMapBtn = vgui.Create("DButton", galaxyPanel)
        openMapBtn:SetText("Open Galaxy Map")
        openMapBtn:SetSize(200, 50)
        openMapBtn:SetPos(galaxyPanel:GetWide()/2 - 100, 50)
        openMapBtn.DoClick = function()
            KYBER:OpenGalaxyMap()
        end
        
        tabSheet:AddSheet("Galaxy", galaxyPanel, "icon16/world.png")
    end)
end