-- kyber/modules/inventory/trading.lua
KYBER.Trading = KYBER.Trading or {}

if SERVER then
    util.AddNetworkString("Kyber_Trade_Request")
    util.AddNetworkString("Kyber_Trade_Accept")
    util.AddNetworkString("Kyber_Trade_Decline")
    util.AddNetworkString("Kyber_Trade_Open")
    util.AddNetworkString("Kyber_Trade_Close")
    util.AddNetworkString("Kyber_Trade_UpdateOffer")
    util.AddNetworkString("Kyber_Trade_UpdateCredits")
    util.AddNetworkString("Kyber_Trade_Confirm")
    util.AddNetworkString("Kyber_Trade_Cancel")
    util.AddNetworkString("Kyber_Trade_Complete")
    
    -- Active trades
    KYBER.Trading.ActiveTrades = {}
    
    -- Trade structure
    function KYBER.Trading:CreateTrade(ply1, ply2)
        local tradeID = "TRADE_" .. os.time() .. "_" .. math.random(1000, 9999)
        
        local trade = {
            id = tradeID,
            players = {ply1, ply2},
            offers = {
                [ply1] = {
                    items = {},
                    credits = 0,
                    confirmed = false
                },
                [ply2] = {
                    items = {},
                    credits = 0,
                    confirmed = false
                }
            },
            startTime = CurTime()
        }
        
        self.ActiveTrades[tradeID] = trade
        ply1.ActiveTrade = tradeID
        ply2.ActiveTrade = tradeID
        
        return tradeID
    end
    
    function KYBER.Trading:GetTrade(ply)
        if not ply.ActiveTrade then return nil end
        return self.ActiveTrades[ply.ActiveTrade]
    end
    
    function KYBER.Trading:GetTradePartner(ply)
        local trade = self:GetTrade(ply)
        if not trade then return nil end
        
        for _, p in ipairs(trade.players) do
            if p ~= ply then return p end
        end
    end
    
    function KYBER.Trading:CancelTrade(tradeID, reason)
        local trade = self.ActiveTrades[tradeID]
        if not trade then return end
        
        -- Notify both players
        for _, ply in ipairs(trade.players) do
            if IsValid(ply) then
                ply.ActiveTrade = nil
                
                net.Start("Kyber_Trade_Close")
                net.WriteString(reason or "Trade cancelled")
                net.Send(ply)
            end
        end
        
        self.ActiveTrades[tradeID] = nil
    end
    
    -- Trade request handling
    net.Receive("Kyber_Trade_Request", function(len, ply)
        local target = net.ReadEntity()
        
        if not IsValid(target) or not target:IsPlayer() then
            ply:ChatPrint("Invalid trade target")
            return
        end
        
        if target == ply then
            ply:ChatPrint("You cannot trade with yourself")
            return
        end
        
        if ply:GetPos():Distance(target:GetPos()) > 200 then
            ply:ChatPrint("Target is too far away")
            return
        end
        
        if ply.ActiveTrade then
            ply:ChatPrint("You are already in a trade")
            return
        end
        
        if target.ActiveTrade then
            ply:ChatPrint("Target is already in a trade")
            return
        end
        
        -- Send request to target
        target.PendingTradeRequest = ply
        
        net.Start("Kyber_Trade_Request")
        net.WriteEntity(ply)
        net.Send(target)
        
        ply:ChatPrint("Trade request sent to " .. target:Nick())
    end)
    
    net.Receive("Kyber_Trade_Accept", function(len, ply)
        local requester = ply.PendingTradeRequest
        
        if not IsValid(requester) then
            ply:ChatPrint("Trade request expired")
            return
        end
        
        if requester.ActiveTrade or ply.ActiveTrade then
            ply:ChatPrint("Trade no longer available")
            return
        end
        
        -- Create trade
        local tradeID = KYBER.Trading:CreateTrade(requester, ply)
        
        -- Open trade window for both players
        for _, p in ipairs({requester, ply}) do
            net.Start("Kyber_Trade_Open")
            net.WriteEntity(KYBER.Trading:GetTradePartner(p))
            net.Send(p)
        end
        
        ply.PendingTradeRequest = nil
    end)
    
    net.Receive("Kyber_Trade_Decline", function(len, ply)
        local requester = ply.PendingTradeRequest
        
        if IsValid(requester) then
            requester:ChatPrint(ply:Nick() .. " declined your trade request")
        end
        
        ply.PendingTradeRequest = nil
    end)
    
    -- Trade offer handling
    net.Receive("Kyber_Trade_UpdateOffer", function(len, ply)
        local trade = KYBER.Trading:GetTrade(ply)
        if not trade then return end
        
        local slot = net.ReadInt(8)
        local adding = net.ReadBool()
        
        if adding then
            -- Add item to trade
            local itemData = ply.KyberInventory[slot]
            if not itemData then return end
            
            -- Check if already offering this item
            for _, offer in ipairs(trade.offers[ply].items) do
                if offer.slot == slot then
                    return -- Already offering
                end
            end
            
            table.insert(trade.offers[ply].items, {
                slot = slot,
                id = itemData.id,
                amount = itemData.amount
            })
        else
            -- Remove item from trade
            for i, offer in ipairs(trade.offers[ply].items) do
                if offer.slot == slot then
                    table.remove(trade.offers[ply].items, i)
                    break
                end
            end
        end
        
        -- Reset confirmations
        trade.offers[ply].confirmed = false
        trade.offers[KYBER.Trading:GetTradePartner(ply)].confirmed = false
        
        -- Update both players
        KYBER.Trading:SendTradeUpdate(trade)
    end)
    
    net.Receive("Kyber_Trade_UpdateCredits", function(len, ply)
        local trade = KYBER.Trading:GetTrade(ply)
        if not trade then return end
        
        local amount = net.ReadInt(32)
        local playerCredits = KYBER:GetPlayerData(ply, "credits") or 0
        
        -- Validate amount
        amount = math.max(0, math.min(amount, playerCredits))
        
        trade.offers[ply].credits = amount
        
        -- Reset confirmations
        trade.offers[ply].confirmed = false
        trade.offers[KYBER.Trading:GetTradePartner(ply)].confirmed = false
        
        -- Update both players
        KYBER.Trading:SendTradeUpdate(trade)
    end)
    
    net.Receive("Kyber_Trade_Confirm", function(len, ply)
        local trade = KYBER.Trading:GetTrade(ply)
        if not trade then return end
        
        trade.offers[ply].confirmed = true
        
        -- Check if both confirmed
        local partner = KYBER.Trading:GetTradePartner(ply)
        if trade.offers[partner].confirmed then
            -- Execute trade
            KYBER.Trading:ExecuteTrade(trade)
        else
            -- Update UI
            KYBER.Trading:SendTradeUpdate(trade)
        end
    end)
    
    net.Receive("Kyber_Trade_Cancel", function(len, ply)
        local trade = KYBER.Trading:GetTrade(ply)
        if not trade then return end
        
        KYBER.Trading:CancelTrade(trade.id, ply:Nick() .. " cancelled the trade")
    end)
    
    function KYBER.Trading:SendTradeUpdate(trade)
        for _, ply in ipairs(trade.players) do
            if IsValid(ply) then
                local partner = self:GetTradePartner(ply)
                
                net.Start("Kyber_Trade_UpdateOffer")
                net.WriteTable(trade.offers[ply])
                net.WriteTable(trade.offers[partner])
                net.Send(ply)
            end
        end
    end
    
    function KYBER.Trading:ExecuteTrade(trade)
        local ply1, ply2 = trade.players[1], trade.players[2]
        
        if not IsValid(ply1) or not IsValid(ply2) then
            self:CancelTrade(trade.id, "Player disconnected")
            return
        end
        
        -- Validate trade one more time
        local offer1 = trade.offers[ply1]
        local offer2 = trade.offers[ply2]
        
        -- Check items still exist
        for _, item in ipairs(offer1.items) do
            if not ply1.KyberInventory[item.slot] or 
               ply1.KyberInventory[item.slot].id ~= item.id or
               ply1.KyberInventory[item.slot].amount ~= item.amount then
                self:CancelTrade(trade.id, "Items changed during trade")
                return
            end
        end
        
        for _, item in ipairs(offer2.items) do
            if not ply2.KyberInventory[item.slot] or 
               ply2.KyberInventory[item.slot].id ~= item.id or
               ply2.KyberInventory[item.slot].amount ~= item.amount then
                self:CancelTrade(trade.id, "Items changed during trade")
                return
            end
        end
        
        -- Check credits
        local ply1Credits = KYBER:GetPlayerData(ply1, "credits") or 0
        local ply2Credits = KYBER:GetPlayerData(ply2, "credits") or 0
        
        if offer1.credits > ply1Credits or offer2.credits > ply2Credits then
            self:CancelTrade(trade.id, "Insufficient credits")
            return
        end
        
        -- Execute the trade
        -- First, remove all items from inventories
        for _, item in ipairs(offer1.items) do
            ply1.KyberInventory[item.slot] = nil
        end
        
        for _, item in ipairs(offer2.items) do
            ply2.KyberInventory[item.slot] = nil
        end
        
        -- Give items to opposite players
        for _, item in ipairs(offer1.items) do
            KYBER.Inventory:GiveItem(ply2, item.id, item.amount)
        end
        
        for _, item in ipairs(offer2.items) do
            KYBER.Inventory:GiveItem(ply1, item.id, item.amount)
        end
        
        -- Exchange credits
        if offer1.credits > 0 then
            KYBER:SetPlayerData(ply1, "credits", ply1Credits - offer1.credits)
            KYBER:SetPlayerData(ply2, "credits", ply2Credits + offer1.credits)
        end
        
        if offer2.credits > 0 then
            KYBER:SetPlayerData(ply2, "credits", ply2Credits - offer2.credits)
            KYBER:SetPlayerData(ply1, "credits", ply1Credits + offer2.credits)
        end
        
        -- Send success notification
        for _, ply in ipairs(trade.players) do
            if IsValid(ply) then
                net.Start("Kyber_Trade_Complete")
                net.Send(ply)
                
                ply:ChatPrint("Trade completed successfully!")
                ply.ActiveTrade = nil
                
                -- Update inventory
                KYBER.Inventory:SendInventoryUpdate(ply)
            end
        end
        
        -- Log trade
        self:LogTrade(trade)
        
        -- Remove trade
        self.ActiveTrades[trade.id] = nil
    end
    
    function KYBER.Trading:LogTrade(trade)
        -- Log trades for record keeping
        if not file.Exists("kyber/trades", "DATA") then
            file.CreateDir("kyber/trades")
        end
        
        local log = {
            id = trade.id,
            timestamp = os.time(),
            player1 = {
                steamID = trade.players[1]:SteamID64(),
                name = trade.players[1]:Nick(),
                offered = trade.offers[trade.players[1]]
            },
            player2 = {
                steamID = trade.players[2]:SteamID64(),
                name = trade.players[2]:Nick(),
                offered = trade.offers[trade.players[2]]
            }
        }
        
        local logFile = "kyber/trades/" .. os.date("%Y-%m-%d") .. ".json"
        local existing = {}
        
        if file.Exists(logFile, "DATA") then
            existing = util.JSONToTable(file.Read(logFile, "DATA")) or {}
        end
        
        table.insert(existing, log)
        file.Write(logFile, util.TableToJSON(existing))
    end
    
    -- Clean up on disconnect
    hook.Add("PlayerDisconnected", "KyberTradingCleanup", function(ply)
        if ply.ActiveTrade then
            KYBER.Trading:CancelTrade(ply.ActiveTrade, "Player disconnected")
        end
    end)
    
else -- CLIENT
    
    local TradeWindow = nil
    
    -- Trade request popup
    net.Receive("Kyber_Trade_Request", function()
        local requester = net.ReadEntity()
        
        if not IsValid(requester) then return end
        
        Derma_Query(
            requester:Nick() .. " wants to trade with you.",
            "Trade Request",
            "Accept", function()
                net.Start("Kyber_Trade_Accept")
                net.SendToServer()
            end,
            "Decline", function()
                net.Start("Kyber_Trade_Decline")
                net.SendToServer()
            end
        )
    end)
    
    -- Open trade window
    net.Receive("Kyber_Trade_Open", function()
        local partner = net.ReadEntity()
        
        if not IsValid(partner) then return end
        
        KYBER.Trading:OpenTradeWindow(partner)
    end)
    
    -- Close trade window
    net.Receive("Kyber_Trade_Close", function()
        local reason = net.ReadString()
        
        if IsValid(TradeWindow) then
            TradeWindow:Remove()
            TradeWindow = nil
        end
        
        chat.AddText(Color(255, 100, 100), "[Trade] ", Color(255, 255, 255), reason)
    end)
    
    -- Update trade offers
    net.Receive("Kyber_Trade_UpdateOffer", function()
        local myOffer = net.ReadTable()
        local theirOffer = net.ReadTable()
        
        if IsValid(TradeWindow) then
            KYBER.Trading:UpdateTradeWindow(myOffer, theirOffer)
        end
    end)
    
    -- Trade completed
    net.Receive("Kyber_Trade_Complete", function()
        if IsValid(TradeWindow) then
            TradeWindow:Remove()
            TradeWindow = nil
        end
        
        surface.PlaySound("ambient/levels/labs/coinslot1.wav")
    end)
    
    function KYBER.Trading:OpenTradeRequest()
        local frame = vgui.Create("DFrame")
        frame:SetSize(300, 400)
        frame:SetTitle("Select Trade Partner")
        frame:Center()
        frame:MakePopup()
        
        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:Dock(FILL)
        scroll:DockMargin(10, 10, 10, 10)
        
        local ply = LocalPlayer()
        
        for _, target in ipairs(player.GetAll()) do
            if target ~= ply then
                local dist = ply:GetPos():Distance(target:GetPos())
                
                if dist <= 200 then
                    local btn = vgui.Create("DButton", scroll)
                    btn:SetText("")
                    btn:SetTall(40)
                    btn:Dock(TOP)
                    btn:DockMargin(0, 0, 0, 5)
                    
                    btn.Paint = function(self, w, h)
                        draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50))
                        
                        if self:IsHovered() then
                            draw.RoundedBox(4, 0, 0, w, h, Color(100, 100, 100, 50))
                        end
                        
                        draw.SimpleText(target:Nick(), "DermaDefault", 10, 10, Color(255, 255, 255))
                        draw.SimpleText("Distance: " .. math.Round(dist) .. " units", "DermaDefault", 10, 25, Color(200, 200, 200))
                    end
                    
                    btn.DoClick = function()
                        net.Start("Kyber_Trade_Request")
                        net.WriteEntity(target)
                        net.SendToServer()
                        
                        frame:Close()
                    end
                end
            end
        end
    end
    
    function KYBER.Trading:OpenTradeWindow(partner)
        if IsValid(TradeWindow) then TradeWindow:Remove() end
        
        TradeWindow = vgui.Create("DFrame")
        TradeWindow:SetSize(800, 600)
        TradeWindow:Center()
        TradeWindow:SetTitle("Trading with " .. partner:Nick())
        TradeWindow:MakePopup()
        
        TradeWindow.OnClose = function()
            net.Start("Kyber_Trade_Cancel")
            net.SendToServer()
        end
        
        -- Main container
        local container = vgui.Create("DPanel", TradeWindow)
        container:Dock(FILL)
        container:DockMargin(10, 10, 10, 10)
        container.Paint = function() end
        
        -- Your side
        local yourSide = vgui.Create("DPanel", container)
        yourSide:Dock(LEFT)
        yourSide:SetWide(380)
        yourSide:DockMargin(0, 0, 10, 0)
        
        yourSide.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            draw.SimpleText("Your Offer", "DermaDefaultBold", w/2, 10, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        end
        
        -- Your inventory display
        local yourInv = vgui.Create("DScrollPanel", yourSide)
        yourInv:SetPos(10, 30)
        yourInv:SetSize(180, 300)
        
        -- Your trade slots
        TradeWindow.yourOfferSlots = vgui.Create("DPanel", yourSide)
        TradeWindow.yourOfferSlots:SetPos(200, 30)
        TradeWindow.yourOfferSlots:SetSize(170, 300)
        TradeWindow.yourOfferSlots.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50))
        end
        
        -- Credits input
        local creditsLabel = vgui.Create("DLabel", yourSide)
        creditsLabel:SetText("Credits to offer:")
        creditsLabel:SetPos(10, 340)
        creditsLabel:SizeToContents()
        
        TradeWindow.creditsInput = vgui.Create("DNumberWang", yourSide)
        TradeWindow.creditsInput:SetPos(10, 360)
        TradeWindow.creditsInput:SetSize(180, 25)
        TradeWindow.creditsInput:SetMin(0)
        TradeWindow.creditsInput:SetMax(999999)
        TradeWindow.creditsInput:SetValue(0)
        
        TradeWindow.creditsInput.OnValueChanged = function(self, val)
            net.Start("Kyber_Trade_UpdateCredits")
            net.WriteInt(val, 32)
            net.SendToServer()
        end
        
        -- Confirm button
        TradeWindow.confirmBtn = vgui.Create("DButton", yourSide)
        TradeWindow.confirmBtn:SetText("Confirm Trade")
        TradeWindow.confirmBtn:SetPos(10, 400)
        TradeWindow.confirmBtn:SetSize(360, 40)
        
        TradeWindow.confirmBtn.DoClick = function()
            net.Start("Kyber_Trade_Confirm")
            net.SendToServer()
        end
        
        -- Status
        TradeWindow.yourStatus = vgui.Create("DLabel", yourSide)
        TradeWindow.yourStatus:SetText("Status: Not Confirmed")
        TradeWindow.yourStatus:SetPos(10, 450)
        TradeWindow.yourStatus:SetSize(360, 20)
        
        -- Their side
        local theirSide = vgui.Create("DPanel", container)
        theirSide:Dock(FILL)
        
        theirSide.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            draw.SimpleText(partner:Nick() .. "'s Offer", "DermaDefaultBold", w/2, 10, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        end
        
        -- Their offer display
        TradeWindow.theirOfferPanel = vgui.Create("DScrollPanel", theirSide)
        TradeWindow.theirOfferPanel:SetPos(10, 30)
        TradeWindow.theirOfferPanel:SetSize(360, 300)
        
        -- Their credits
        TradeWindow.theirCredits = vgui.Create("DLabel", theirSide)
        TradeWindow.theirCredits:SetText("Credits offered: 0")
        TradeWindow.theirCredits:SetPos(10, 340)
        TradeWindow.theirCredits:SetSize(360, 20)
        
        -- Their status
        TradeWindow.theirStatus = vgui.Create("DLabel", theirSide)
        TradeWindow.theirStatus:SetText("Status: Not Confirmed")
        TradeWindow.theirStatus:SetPos(10, 450)
        TradeWindow.theirStatus:SetSize(360, 20)
        
        -- Populate your inventory
        self:PopulateInventory(yourInv)
    end
    
    function KYBER.Trading:PopulateInventory(parent)
        parent:Clear()
        
        local inventory = LocalPlayer().KyberInventory or {}
        
        for slot, itemData in pairs(inventory) do
            if itemData then
                local item = KYBER.GrandExchange.Items[itemData.id]
                if item then
                    local btn = vgui.Create("DButton", parent)
                    btn:SetText("")
                    btn:SetTall(40)
                    btn:Dock(TOP)
                    btn:DockMargin(0, 0, 0, 2)
                    btn.slot = slot
                    btn.isOffered = false
                    
                    btn.Paint = function(self, w, h)
                        local col = self.isOffered and Color(100, 50, 50) or Color(50, 50, 50)
                        draw.RoundedBox(4, 0, 0, w, h, col)
                        
                        draw.SimpleText(item.name, "DermaDefault", 5, 5, Color(255, 255, 255))
                        draw.SimpleText("x" .. itemData.amount, "DermaDefault", 5, 20, Color(200, 200, 200))
                    end
                    
                    btn.DoClick = function(self)
                        self.isOffered = not self.isOffered
                        
                        net.Start("Kyber_Trade_UpdateOffer")
                        net.WriteInt(self.slot, 8)
                        net.WriteBool(self.isOffered)
                        net.SendToServer()
                    end
                end
            end
        end
    end
    
    function KYBER.Trading:UpdateTradeWindow(myOffer, theirOffer)
        if not IsValid(TradeWindow) then return end
        
        -- Update your offer display
        TradeWindow.yourOfferSlots:Clear()
        
        for _, item in ipairs(myOffer.items) do
            local itemInfo = KYBER.GrandExchange.Items[item.id]
            if itemInfo then
                local panel = vgui.Create("DPanel", TradeWindow.yourOfferSlots)
                panel:SetSize(160, 30)
                panel:Dock(TOP)
                panel:DockMargin(5, 5, 5, 0)
                
                panel.Paint = function(self, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, Color(70, 70, 70))
                    draw.SimpleText(itemInfo.name .. " x" .. item.amount, "DermaDefault", 5, h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
        end
        
        -- Update their offer display
        TradeWindow.theirOfferPanel:Clear()
        
        for _, item in ipairs(theirOffer.items) do
            local itemInfo = KYBER.GrandExchange.Items[item.id]
            if itemInfo then
                local panel = vgui.Create("DPanel", TradeWindow.theirOfferPanel)
                panel:SetSize(350, 30)
                panel:Dock(TOP)
                panel:DockMargin(0, 0, 0, 2)
                
                panel.Paint = function(self, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, Color(70, 70, 70))
                    draw.SimpleText(itemInfo.name .. " x" .. item.amount, "DermaDefault", 5, h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
        end
        
        -- Update credits
        TradeWindow.theirCredits:SetText("Credits offered: " .. theirOffer.credits)
        
        -- Update status
        TradeWindow.yourStatus:SetText("Status: " .. (myOffer.confirmed and "Confirmed" or "Not Confirmed"))
        TradeWindow.yourStatus:SetTextColor(myOffer.confirmed and Color(100, 255, 100) or Color(255, 255, 255))
        
        TradeWindow.theirStatus:SetText("Status: " .. (theirOffer.confirmed and "Confirmed" or "Not Confirmed"))
        TradeWindow.theirStatus:SetTextColor(theirOffer.confirmed and Color(100, 255, 100) or Color(255, 255, 255))
        
        -- Update confirm button
        if myOffer.confirmed then
            TradeWindow.confirmBtn:SetText("Waiting for partner...")
            TradeWindow.confirmBtn:SetEnabled(false)
        else
            TradeWindow.confirmBtn:SetText("Confirm Trade")
            TradeWindow.confirmBtn:SetEnabled(true)
        end
    end
end