-- kyber/modules/force/lottery_ui.lua
-- This file adds the Force Lottery UI to the datapad and character systems

if CLIENT then
    -- Add to datapad
    hook.Add("Kyber_Datapad_AddTabs", "AddForceLotteryTab", function(tabSheet)
        local lotteryPanel = vgui.Create("DPanel", tabSheet)
        lotteryPanel:Dock(FILL)
        
        lotteryPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20))
        end
        
        -- Title
        local title = vgui.Create("DLabel", lotteryPanel)
        title:SetText("Force Sensitivity Lottery")
        title:SetFont("DermaLarge")
        title:Dock(TOP)
        title:DockMargin(20, 20, 20, 10)
        title:SetContentAlignment(5)
        
        -- Description
        local desc = vgui.Create("DLabel", lotteryPanel)
        desc:SetText("The Force chooses its wielders through mysterious ways. Enter the lottery for a chance to become Force sensitive.")
        desc:SetWrap(true)
        desc:SetAutoStretchVertical(true)
        desc:Dock(TOP)
        desc:DockMargin(20, 0, 20, 20)
        desc:SetContentAlignment(5)
        
        -- Status panel
        local statusPanel = vgui.Create("DPanel", lotteryPanel)
        statusPanel:Dock(TOP)
        statusPanel:DockMargin(20, 0, 20, 20)
        statusPanel:SetTall(150)
        
        statusPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            
            -- Force sensitivity status
            local isForceSensitive = LocalPlayer():GetNWBool("kyber_force_sensitive", false)
            
            if isForceSensitive then
                draw.SimpleText("You are Force Sensitive", "DermaDefaultBold", w/2, 20, Color(100, 255, 100), TEXT_ALIGN_CENTER)
                draw.SimpleText("The Force flows through you", "DermaDefault", w/2, 40, Color(200, 200, 200), TEXT_ALIGN_CENTER)
            else
                draw.SimpleText("You are not Force Sensitive", "DermaDefaultBold", w/2, 20, Color(255, 100, 100), TEXT_ALIGN_CENTER)
                
                -- Lottery timer
                if KYBER.ForceLottery then
                    local timeLeft = (KYBER.ForceLottery.NextLotteryTime or 0) - os.time()
                    
                    if timeLeft > 0 then
                        local timeStr = string.NiceTime(timeLeft)
                        draw.SimpleText("Next Lottery: " .. timeStr, "DermaDefault", w/2, 60, Color(255, 255, 255), TEXT_ALIGN_CENTER)
                        
                        -- Participants
                        local participants = KYBER.ForceLottery.CurrentParticipants and #KYBER.ForceLottery.CurrentParticipants or 0
                        draw.SimpleText("Current Participants: " .. participants, "DermaDefault", w/2, 80, Color(200, 200, 200), TEXT_ALIGN_CENTER)
                        
                        -- Chances
                        local chance = KYBER.ForceLottery.Config and KYBER.ForceLottery.Config.baseChance or 0.05
                        draw.SimpleText("Win Chance: " .. (chance * 100) .. "%", "DermaDefault", w/2, 100, Color(200, 200, 200), TEXT_ALIGN_CENTER)
                    else
                        draw.SimpleText("Lottery drawing in progress...", "DermaDefault", w/2, 60, Color(255, 255, 100), TEXT_ALIGN_CENTER)
                    end
                else
                    draw.SimpleText("Loading lottery data...", "DermaDefault", w/2, 60, Color(200, 200, 200), TEXT_ALIGN_CENTER)
                end
            end
        end
        
        -- Enter lottery button
        local enterBtn = vgui.Create("DButton", lotteryPanel)
        enterBtn:SetText("Enter Force Lottery")
        enterBtn:SetTall(50)
        enterBtn:Dock(TOP)
        enterBtn:DockMargin(20, 0, 20, 20)
        
        enterBtn.Paint = function(self, w, h)
            local col = Color(50, 50, 150)
            
            if self:IsHovered() then
                col = Color(70, 70, 200)
            end
            
            if not self:IsEnabled() then
                col = Color(50, 50, 50)
            end
            
            draw.RoundedBox(4, 0, 0, w, h, col)
            
            local textCol = self:IsEnabled() and Color(255, 255, 255) or Color(100, 100, 100)
            draw.SimpleText(self:GetText(), "DermaDefaultBold", w/2, h/2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        enterBtn.Think = function(self)
            local isForceSensitive = LocalPlayer():GetNWBool("kyber_force_sensitive", false)
            
            if isForceSensitive then
                self:SetEnabled(false)
                self:SetText("You are already Force Sensitive")
            else
                -- Check if already entered
                local alreadyEntered = false
                if KYBER.ForceLottery and KYBER.ForceLottery.CurrentParticipants then
                    for _, p in ipairs(KYBER.ForceLottery.CurrentParticipants) do
                        if p.steamID == LocalPlayer():SteamID64() then
                            alreadyEntered = true
                            break
                        end
                    end
                end
                
                if alreadyEntered then
                    self:SetEnabled(false)
                    self:SetText("Already Entered")
                else
                    self:SetEnabled(true)
                    self:SetText("Enter Force Lottery")
                end
            end
        end
        
        enterBtn.DoClick = function()
            net.Start("Kyber_ForceLottery_Enter")
            net.SendToServer()
        end
        
        -- Requirements panel
        local reqPanel = vgui.Create("DPanel", lotteryPanel)
        reqPanel:Dock(TOP)
        reqPanel:DockMargin(20, 0, 20, 20)
        reqPanel:SetTall(120)
        
        reqPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            
            draw.SimpleText("Requirements:", "DermaDefaultBold", 10, 10, Color(255, 255, 255))
            
            local requirements = {
                "• Must not already be Force sensitive",
                "• Minimum 1 hour playtime",
                "• Must be in a Force-capable faction",
                "• 7 day cooldown between wins",
                "• 24 hour cooldown per character"
            }
            
            local y = 30
            for _, req in ipairs(requirements) do
                draw.SimpleText(req, "DermaDefault", 10, y, Color(200, 200, 200))
                y = y + 18
            end
        end
        
        -- History panel
        local historyLabel = vgui.Create("DLabel", lotteryPanel)
        historyLabel:SetText("Recent Winners:")
        historyLabel:SetFont("DermaDefaultBold")
        historyLabel:Dock(TOP)
        historyLabel:DockMargin(20, 0, 20, 10)
        
        local historyScroll = vgui.Create("DScrollPanel", lotteryPanel)
        historyScroll:Dock(FILL)
        historyScroll:DockMargin(20, 0, 20, 20)
        
        -- This would be populated with actual winner data
        local exampleWinners = {
            {name = "Luke Skywalker", time = "2 hours ago"},
            {name = "Rey Nobody", time = "1 day ago"},
            {name = "Ezra Bridger", time = "3 days ago"}
        }
        
        for _, winner in ipairs(exampleWinners) do
            local winnerPanel = vgui.Create("DPanel", historyScroll)
            winnerPanel:Dock(TOP)
            winnerPanel:DockMargin(0, 0, 0, 5)
            winnerPanel:SetTall(40)
            
            winnerPanel.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
                
                draw.SimpleText(winner.name, "DermaDefault", 10, h/2 - 8, Color(100, 200, 255))
                draw.SimpleText(winner.time, "DermaDefault", w - 10, h/2 - 8, Color(150, 150, 150), TEXT_ALIGN_RIGHT)
            end
        end
        
        tabSheet:AddSheet("Force Lottery", lotteryPanel, "icon16/star.png")
    end)
    
    -- Add Force status to character sheet
    hook.Add("Kyber_CharacterSheet_AddInfo", "AddForceStatus", function(ply)
        local info = {}
        
        local isForceSensitive = ply:GetNWBool("kyber_force_sensitive", false)
        
        table.insert(info, {
            label = "Force Sensitivity",
            value = isForceSensitive and "Force Sensitive" or "Not Force Sensitive"
        })
        
        if isForceSensitive then
            table.insert(info, {
                label = "Midi-chlorian Count",
                value = tostring(math.random(12000, 20000)) -- Just for flavor
            })
        end
        
        return info
    end)
end

if SERVER then
    -- Network lottery status to players
    util.AddNetworkString("Kyber_ForceLottery_RequestStatus")
    
    net.Receive("Kyber_ForceLottery_Status", function(len, ply)
        -- Send current lottery status
        net.Start("Kyber_ForceLottery_Status")
        net.WriteInt(KYBER.ForceLottery.NextLotteryTime or 0, 32)
        net.WriteTable(KYBER.ForceLottery.CurrentParticipants or {})
        net.Send(ply)
    end)
    
    -- Update all clients when lottery changes
    hook.Add("Kyber_ForceLottery_Updated", "BroadcastStatus", function()
        net.Start("Kyber_ForceLottery_Status")
        net.WriteInt(KYBER.ForceLottery.NextLotteryTime or 0, 32)
        net.WriteTable(KYBER.ForceLottery.CurrentParticipants or {})
        net.Broadcast()
    end)
end

-- Add visual effects for Force sensitive players
if CLIENT then
    -- Subtle aura effect
    hook.Add("PrePlayerDraw", "KyberForceAura", function(ply)
        if not ply:GetNWBool("kyber_force_sensitive", false) then return end
        
        -- Add subtle glow
        local dlight = DynamicLight(ply:EntIndex())
        if dlight then
            dlight.pos = ply:GetPos() + Vector(0, 0, 40)
            dlight.r = 100
            dlight.g = 100
            dlight.b = 255
            dlight.brightness = 0.5
            dlight.Decay = 1000
            dlight.Size = 128
            dlight.DieTime = CurTime() + 1
        end
    end)
    
    -- HUD indicator
    hook.Add("HUDPaint", "KyberForceIndicator", function()
        local ply = LocalPlayer()
        if not ply:GetNWBool("kyber_force_sensitive", false) then return end
        
        -- Small Force icon near health
        local x = 30
        local y = ScrH() - 150
        
        -- Pulsing effect
        local pulse = math.sin(CurTime() * 2) * 0.2 + 0.8
        
        surface.SetDrawColor(100 * pulse, 100 * pulse, 255 * pulse, 200)
        draw.NoTexture()
        
        -- Simple Force symbol (two crescents)
        local size = 20
        draw.Circle(x, y, size, 20)
        draw.Circle(x + 5, y, size, 20)
        
        -- Force text
        draw.SimpleText("Force Sensitive", "DermaDefault", x + 30, y, Color(100 * pulse, 100 * pulse, 255 * pulse, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end)
    
    -- Custom scoreboard column
    hook.Add("Kyber_Scoreboard_Columns", "AddForceColumn", function(columns)
        table.insert(columns, {
            header = "Force",
            width = 60,
            getData = function(ply)
                return ply:GetNWBool("kyber_force_sensitive", false) and "✦" or ""
            end,
            color = function(ply)
                return ply:GetNWBool("kyber_force_sensitive", false) and Color(100, 100, 255) or Color(255, 255, 255)
            end
        })
    end)
end

-- Helper function for circle drawing
if CLIENT then
    function draw.Circle(x, y, radius, seg)
        local cir = {}
        
        table.insert(cir, { x = x, y = y, u = 0.5, v = 0.5 })
        for i = 0, seg do
            local a = math.rad((i / seg) * -360)
            table.insert(cir, { x = x + math.sin(a) * radius, y = y + math.cos(a) * radius, u = math.sin(a) / 2 + 0.5, v = math.cos(a) / 2 + 0.5 })
        end
        
        local a = math.rad(0)
        table.insert(cir, { x = x + math.sin(a) * radius, y = y + math.cos(a) * radius, u = math.sin(a) / 2 + 0.5, v = math.cos(a) / 2 + 0.5 })
        
        surface.DrawPoly(cir)
    end
end