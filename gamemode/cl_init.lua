-- kyber/gamemode/cl_init.lua
-- Client-side initialization

-- Include shared code
include("kyber/gamemode/shared.lua")

-- Include management system
include("kyber/gamemode/core/management.lua")

-- Initialize client-side state
KYBER.Management.State:Set("escapeMenuOpen", false)
KYBER.Management.State:Set("loadingScreen", nil)
KYBER.Management.State:Set("loginScreen", nil)

-- Create loading screen
local function CreateLoadingScreen()
    print("[Kyber] Creating loading screen...")
    local frame = vgui.Create("DFrame")
    if not IsValid(frame) then
        print("[Kyber] ERROR: Failed to create loading screen frame!")
        KYBER.Management.ErrorHandler:Handle("Failed to create loading screen frame", "CreateLoadingScreen")
        return
    end
    
    frame:SetSize(ScrW(), ScrH())
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    
    -- Add Star Wars themed background
    local bg = vgui.Create("DPanel", frame)
    if IsValid(bg) then
        bg:Dock(FILL)
        bg.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 255))
        end
    else
        print("[Kyber] WARNING: Failed to create loading screen background panel!")
    end
    
    -- Add loading text
    local loadingText = vgui.Create("DLabel", frame)
    if IsValid(loadingText) then
        loadingText:SetText("Loading Kyber...")
        loadingText:SetFont("DermaLarge")
        loadingText:SetTextColor(Color(255, 255, 255))
        loadingText:SizeToContents()
        loadingText:Center()
    else
        print("[Kyber] WARNING: Failed to create loading text label!")
    end
    
    -- Add progress bar
    local progress = vgui.Create("DProgress", frame)
    if IsValid(progress) then
        progress:SetSize(ScrW() * 0.6, 20)
        progress:Center()
        progress:SetPos(progress:GetX(), progress:GetY() + 50)
        progress:SetFraction(0)
    else
        print("[Kyber] WARNING: Failed to create loading progress bar!")
    end
    
    -- Add logo
    local logo = vgui.Create("DImage", frame)
    if IsValid(logo) then
        logo:SetSize(256, 256)
        logo:Center()
        logo:SetPos(logo:GetX(), logo:GetY() - 100)
        logo:SetImage("kyber/logo.png")
    else
        print("[Kyber] WARNING: Failed to create loading logo image!")
    end
    
    -- Simulate loading progress
    local startTime = SysTime()
    KYBER.Management.Hooks:Add("Think", "KyberLoadingProgress", function()
        if not IsValid(progress) then print("[Kyber] Progress bar invalid during loading!") return end
        local elapsed = SysTime() - startTime
        local targetProgress = math.min(elapsed / 3, 1)
        progress:SetFraction(targetProgress)
        if targetProgress >= 1 then
            print("[Kyber] Loading progress complete, removing loading screen...")
            KYBER.Management.Hooks:Remove("KyberLoadingProgress")
            KYBER.Management.Timers:Create("KyberLoadingComplete", 0.5, 1, function()
                if IsValid(frame) then
                    frame:Remove()
                end
                CreateLoginScreen()
            end)
        end
    end)
    
    -- Failsafe: forcibly remove loading screen after 10 seconds
    timer.Simple(10, function()
        if IsValid(frame) then
            print("[Kyber] Failsafe: Forcibly removing loading screen after 10 seconds!")
            frame:Remove()
            CreateLoginScreen()
        end
    end)
    
    KYBER.Management.State:Set("loadingScreen", frame)
    return frame
end

-- Make login and datapad functions global
function CreateLoginScreen()
    print("[Kyber] Creating login screen...")
    local frame = vgui.Create("DFrame")
    if not IsValid(frame) then
        print("[Kyber] ERROR: Failed to create login screen frame!")
        KYBER.Management.ErrorHandler:Handle("Failed to create login screen frame", "CreateLoginScreen")
        return
    end
    frame:SetSize(ScrW() * 0.4, ScrH() * 0.6)
    frame:Center()
    frame:SetTitle("Kyber Login")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    -- Solid background only
    local bg = vgui.Create("DPanel", frame)
    if IsValid(bg) then
        bg:Dock(FILL)
        bg.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 255))
        end
    end
    local logo = vgui.Create("DImage", frame)
    if IsValid(logo) then
        logo:SetSize(256, 256)
        logo:Center()
        logo:SetPos(logo:GetX(), logo:GetY() - 150)
        logo:SetImage("kyber/logo.png")
    end
    local welcomeText = vgui.Create("DLabel", frame)
    if IsValid(welcomeText) then
        welcomeText:SetText("Welcome to Kyber")
        welcomeText:SetFont("DermaLarge")
        welcomeText:SetTextColor(Color(255, 255, 255))
        welcomeText:SizeToContents()
        welcomeText:Center()
        welcomeText:SetPos(welcomeText:GetX(), welcomeText:GetY() + 50)
    end
    local loginButton = vgui.Create("DButton", frame)
    if IsValid(loginButton) then
        loginButton:SetSize(ScrW() * 0.2, 40)
        loginButton:Center()
        loginButton:SetPos(loginButton:GetX(), loginButton:GetY() + 100)
        loginButton:SetText("Login")
        loginButton:SetTextColor(Color(255, 255, 255))
        loginButton.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 200))
            if self:IsHovered() then
                draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 50))
            end
        end
        loginButton.DoClick = function()
            print("[Kyber] Login button clicked, checking character...")
            net.Start("Kyber_Character_Check")
            net.SendToServer()
        end
    end
    KYBER.Management.State:Set("loginScreen", frame)
    return frame
end

function CreateDatapad()
    if IsValid(KYBER.Management.State:Get("datapad")) then
        KYBER.Management.State:Get("datapad"):Remove()
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW() * 0.7, ScrH() * 0.8)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(true)
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        draw.RoundedBox(16, 0, 0, w, h, Color(10, 10, 30, 245))
        surface.SetDrawColor(0, 200, 255, 180)
        surface.DrawOutlinedRect(0, 0, w, h, 4)
    end
    KYBER.Management.State:Set("datapad", frame)

    -- Top Tab Bar
    local tabBar = vgui.Create("DPanel", frame)
    tabBar:SetTall(60)
    tabBar:Dock(TOP)
    tabBar.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 40, 220))
        surface.SetDrawColor(0, 200, 255, 120)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    local tabs = {
        {name = "Inventory", icon = "icon16/box.png"},
        {name = "Equipment", icon = "icon16/gun.png"},
        {name = "Notes", icon = "icon16/note.png"},
        {name = "Missions", icon = "icon16/flag.png"},
    }
    local selectedTab = 1
    local tabButtons = {}

    local function SelectTab(idx)
        selectedTab = idx
        for i, btn in ipairs(tabButtons) do
            btn:SetSelected(i == idx)
        end
        -- Update right panel content
        if idx == 1 then
            rightLabel:SetText("Inventory List\n- Blaster Pistol\n- Medkit\n- Credits: 500")
        elseif idx == 2 then
            rightLabel:SetText("Equipment List\n- Vibroblade (Equipped)\n- Light Armor")
        elseif idx == 3 then
            rightLabel:SetText("Notes\n- Meet with the Jedi Council\n- Find the missing droid")
        elseif idx == 4 then
            rightLabel:SetText("Missions\n- Rescue the senator\n- Investigate the ruins")
        end
    end

    -- Tab Buttons
    for i, tab in ipairs(tabs) do
        local btn = vgui.Create("DButton", tabBar)
        btn:SetSize(100, 48)
        btn:SetPos(20 + (i-1)*110, 6)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            if self:IsHovered() or self.selected then
                draw.RoundedBox(8, 0, 0, w, h, Color(0, 200, 255, 60))
                surface.SetDrawColor(0, 200, 255, 180)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            else
                draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 40, 0))
                surface.SetDrawColor(0, 200, 255, 80)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            surface.SetDrawColor(255,255,255,255)
            surface.SetMaterial(Material(tab.icon))
            surface.DrawTexturedRect(w/2-12, h/2-12, 24, 24)
        end
        btn.DoClick = function()
            SelectTab(i)
        end
        function btn:SetSelected(sel) self.selected = sel end
        tabButtons[i] = btn
    end

    -- Left: Character Info
    local charPanel = vgui.Create("DPanel", frame)
    charPanel:SetWide(frame:GetWide() * 0.22)
    charPanel:Dock(LEFT)
    charPanel:DockMargin(12, 0, 0, 0)
    charPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(15, 15, 30, 230))
        surface.SetDrawColor(0, 200, 255, 100)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end
    -- Portrait
    local avatar = vgui.Create("AvatarImage", charPanel)
    avatar:SetSize(96, 96)
    avatar:SetPos(20, 20)
    avatar:SetPlayer(LocalPlayer(), 128)
    -- Stats
    local stats = {
        {label = "Health", value = LocalPlayer():Health()},
        {label = "Armor", value = LocalPlayer():Armor()},
        {label = "Credits", value = LocalPlayer():GetNWInt("Credits", 0)},
        {label = "Faction", value = LocalPlayer():GetNWString("Faction", "None")},
        {label = "Rank", value = LocalPlayer():GetNWString("Rank", "")},
    }
    for i, stat in ipairs(stats) do
        local lbl = vgui.Create("DLabel", charPanel)
        lbl:SetFont("DermaDefaultBold")
        lbl:SetText(stat.label .. ": " .. tostring(stat.value))
        lbl:SetTextColor(Color(0, 200, 255))
        lbl:SizeToContents()
        lbl:SetPos(20, 130 + (i-1)*28)
    end

    -- Right: List Panel
    local rightPanel = vgui.Create("DPanel", frame)
    rightPanel:SetWide(frame:GetWide() * 0.28)
    rightPanel:Dock(RIGHT)
    rightPanel:DockMargin(0, 0, 12, 0)
    rightPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(15, 15, 30, 230))
        surface.SetDrawColor(0, 200, 255, 100)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end
    rightLabel = vgui.Create("DLabel", rightPanel)
    rightLabel:SetFont("DermaDefaultBold")
    rightLabel:SetTextColor(Color(0, 200, 255))
    rightLabel:SetPos(20, 20)
    rightLabel:SetSize(rightPanel:GetWide()-40, rightPanel:GetTall()-40)
    rightLabel:SetWrap(true)
    rightLabel:SetAutoStretchVertical(true)

    -- Center: Main Content (Equipment slots visual)
    local mainPanel = vgui.Create("DPanel", frame)
    mainPanel:Dock(FILL)
    mainPanel:DockMargin(8, 0, 8, 8)
    mainPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 40, 220))
        surface.SetDrawColor(0, 200, 255, 60)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        -- Equipment slots (visual only)
        local slotNames = {"Head", "Body", "Hands", "Legs", "Feet", "Weapon", "Shield"}
        local cx, cy = w/2, h/2
        for i, name in ipairs(slotNames) do
            local sx = cx + math.cos((i-1)/#slotNames*math.pi*2) * 100
            local sy = cy + math.sin((i-1)/#slotNames*math.pi*2) * 100
            draw.RoundedBox(6, sx-32, sy-32, 64, 64, Color(10, 30, 60, 180))
            surface.SetDrawColor(0, 200, 255, 120)
            surface.DrawOutlinedRect(sx-32, sy-32, 64, 64, 2)
            draw.SimpleText(name, "DermaDefault", sx, sy+40, Color(0, 200, 255), TEXT_ALIGN_CENTER)
        end
    end

    -- Select default tab
    SelectTab(1)
end

-- Create escape menu
local function CreateEscapeMenu()
    if KYBER.Management.State:Get("escapeMenuOpen") then return end
    
    local frame = vgui.Create("DFrame")
    if not IsValid(frame) then
        KYBER.Management.ErrorHandler:Handle("Failed to create escape menu frame", "CreateEscapeMenu")
        return
    end
    
    frame:SetSize(ScrW() * 0.3, ScrH() * 0.5)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    
    -- Add Star Wars themed background
    local bg = vgui.Create("DPanel", frame)
    if IsValid(bg) then
        bg:Dock(FILL)
        bg.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 200))
        end
    end
    
    -- Add buttons
    local buttons = {
        {text = "Resume", func = function() 
            frame:Remove()
            KYBER.Management.State:Set("escapeMenuOpen", false)
        end},
        {text = "Datapad", func = function() 
            frame:Remove()
            KYBER.Management.State:Set("escapeMenuOpen", false)
            CreateDatapad()
        end},
        {text = "Settings", func = function()
            frame:Remove()
            KYBER.Management.State:Set("escapeMenuOpen", false)
            -- TODO: Implement settings menu
        end},
        {text = "Console", func = function()
            frame:Remove()
            KYBER.Management.State:Set("escapeMenuOpen", false)
            gui.ActivateGameUI()
            LocalPlayer():ConCommand("toggleconsole")
        end},
        {text = "Disconnect", func = function()
            frame:Remove()
            KYBER.Management.State:Set("escapeMenuOpen", false)
            RunConsoleCommand("disconnect")
        end}
    }
    
    local buttonHeight = 40
    local spacing = 10
    local totalHeight = (#buttons * buttonHeight) + ((#buttons - 1) * spacing)
    local startY = (frame:GetTall() - totalHeight) / 2
    
    for i, buttonData in ipairs(buttons) do
        local button = vgui.Create("DButton", frame)
        if IsValid(button) then
            button:SetSize(frame:GetWide() * 0.8, buttonHeight)
            button:SetPos(frame:GetWide() * 0.1, startY + ((i - 1) * (buttonHeight + spacing)))
            button:SetText(buttonData.text)
            button:SetTextColor(Color(255, 255, 255))
            button.Paint = function(self, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 200))
                if self:IsHovered() then
                    draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 50))
                end
            end
            button.DoClick = buttonData.func
        end
    end
    
    KYBER.Management.State:Set("escapeMenuOpen", true)
    return frame
end

-- Handle escape key
hook.Add("Think", "KyberEscapeMenu", function()
    if input.IsKeyDown(KEY_ESCAPE) and not KYBER.Management.State:Get("escapeMenuOpen") then
        CreateEscapeMenu()
    end
end)

-- Network receivers
net.Receive("Kyber_Character_CheckResponse", function()
    local hasCharacter = net.ReadBool()
    
    if hasCharacter then
        -- Has character, open selection
        if IsValid(KYBER.Management.State:Get("loginScreen")) then
            KYBER.Management.State:Get("loginScreen"):Remove()
        end
        net.Start("Kyber_Character_OpenSelection")
        net.SendToServer()
    else
        -- No character, open creation
        if IsValid(KYBER.Management.State:Get("loginScreen")) then
            KYBER.Management.State:Get("loginScreen"):Remove()
        end
        net.Start("Kyber_Character_OpenCreation")
        net.SendToServer()
    end
end)

net.Receive("Kyber_Datapad_Update", function()
    local data = net.ReadTable()
    -- TODO: Update datapad UI with received data
end)

-- Initialize client
hook.Add("InitPostEntity", "KyberClientInit", function()
    CreateLoadingScreen()
end)

-- Hook for cleanup
KYBER.Management.Hooks:Add("ShutDown", "KyberClientCleanup", function()
    -- Clean up any open panels
    if KYBER.Management.State:Get("loadingScreen") and IsValid(KYBER.Management.State:Get("loadingScreen")) then
        KYBER.Management.State:Get("loadingScreen"):Remove()
    end
    
    if KYBER.Management.State:Get("loginScreen") and IsValid(KYBER.Management.State:Get("loginScreen")) then
        KYBER.Management.State:Get("loginScreen"):Remove()
    end
end)

-- Add F4 keybind for Datapad
hook.Add("PlayerButtonDown", "KyberF4Datapad", function(ply, button)
    if button == KEY_F4 and ply == LocalPlayer() then
        if not IsValid(KYBER.Management.State:Get("datapad")) then
            CreateDatapad()
        end
    end
end)

-- Custom Scoreboard
local scoreboardPanel = nil

function CreateScoreboard()
    if IsValid(scoreboardPanel) then scoreboardPanel:Remove() end
    scoreboardPanel = vgui.Create("DFrame")
    scoreboardPanel:SetSize(ScrW() * 0.5, ScrH() * 0.7)
    scoreboardPanel:Center()
    scoreboardPanel:SetTitle("")
    scoreboardPanel:SetDraggable(false)
    scoreboardPanel:ShowCloseButton(false)
    scoreboardPanel:MakePopup()
    scoreboardPanel.Paint = function(self, w, h)
        draw.RoundedBox(12, 0, 0, w, h, Color(10, 10, 30, 240))
        draw.SimpleText("KYBER SCOREBOARD", "DermaLarge", w/2, 30, Color(0, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    local scroll = vgui.Create("DScrollPanel", scoreboardPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(20, 70, 20, 20)

    for _, ply in ipairs(player.GetAll()) do
        local row = scroll:Add("DPanel")
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 8)
        row:SetTall(56)
        row.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 40, 200))
        end

        local avatar = vgui.Create("AvatarImage", row)
        avatar:SetSize(48, 48)
        avatar:SetPlayer(ply, 64)
        avatar:SetPos(8, 4)

        local name = vgui.Create("DLabel", row)
        name:SetFont("DermaLarge")
        name:SetText(ply:Nick())
        name:SetTextColor(Color(255, 255, 255))
        name:SizeToContents()
        name:SetPos(64, 8)

        local ping = vgui.Create("DLabel", row)
        ping:SetFont("DermaDefault")
        ping:SetText("Ping: " .. ply:Ping())
        ping:SetTextColor(Color(180, 220, 255))
        ping:SizeToContents()
        ping:SetPos(64, 32)

        -- Faction/Team (if available)
        local faction = ply:GetNWString("Faction", "None")
        local rank = ply:GetNWString("Rank", "")
        local factionLabel = vgui.Create("DLabel", row)
        factionLabel:SetFont("DermaDefault")
        factionLabel:SetText("Faction: " .. faction .. (rank ~= "" and (" ("..rank..")") or ""))
        factionLabel:SetTextColor(Color(0, 200, 255))
        factionLabel:SizeToContents()
        factionLabel:SetPos(row:GetWide() - 200, 18)
        factionLabel:SetWide(180)
        factionLabel:SetContentAlignment(6)
    end
end

function RemoveScoreboard()
    if IsValid(scoreboardPanel) then
        scoreboardPanel:Remove()
        scoreboardPanel = nil
    end
end

hook.Add("ScoreboardShow", "KyberCustomScoreboardShow", function()
    CreateScoreboard()
    return false -- Block default scoreboard
end)

hook.Add("ScoreboardHide", "KyberCustomScoreboardHide", function()
    RemoveScoreboard()
    return false
end)

print("[Kyber] Client initialization complete")