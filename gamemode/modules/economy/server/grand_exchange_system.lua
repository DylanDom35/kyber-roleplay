-- kyber/modules/economy/grand_exchange.lua
KYBER.GrandExchange = KYBER.GrandExchange or {}

-- Item categories
KYBER.GrandExchange.Categories = {
    weapons = {name = "Weapons", icon = "icon16/gun.png"},
    armor = {name = "Armor", icon = "icon16/shield.png"},
    materials = {name = "Materials", icon = "icon16/box.png"},
    consumables = {name = "Consumables", icon = "icon16/pill.png"},
    artifacts = {name = "Artifacts", icon = "icon16/star.png"},
    misc = {name = "Miscellaneous", icon = "icon16/package.png"}
}

-- Example items (expand as needed)
KYBER.GrandExchange.Items = {
    ["beskar_ingot"] = {
        name = "Beskar Ingot",
        description = "Mandalorian iron, nearly indestructible",
        category = "materials",
        basePrice = 5000,
        stackable = true,
        maxStack = 10,
        icon = "icon16/brick.png"
    },
    
    ["kyber_crystal"] = {
        name = "Kyber Crystal",
        description = "Force-attuned crystal for lightsabers",
        category = "artifacts",
        basePrice = 10000,
        stackable = false,
        icon = "icon16/ruby.png"
    },
    
    ["bacta_vial"] = {
        name = "Bacta Vial",
        description = "Healing solution",
        category = "consumables",
        basePrice = 100,
        stackable = true,
        maxStack = 5,
        icon = "icon16/heart.png"
    }
}

if SERVER then
    util.AddNetworkString("Kyber_GE_Open")
    util.AddNetworkString("Kyber_GE_ListItem")
    util.AddNetworkString("Kyber_GE_BuyItem")
    util.AddNetworkString("Kyber_GE_CancelListing")
    util.AddNetworkString("Kyber_GE_UpdateListings")
    util.AddNetworkString("Kyber_GE_CollectEarnings")
    
    -- Network handlers with rate limiting
    local messageCooldowns = {}
    local function IsRateLimited(ply, messageType, cooldown)
        local key = ply:SteamID64() .. "_" .. messageType
        local lastTime = messageCooldowns[key] or 0
        
        if CurTime() - lastTime < cooldown then
            return true
        end
        
        messageCooldowns[key] = CurTime()
        return false
    end
    
    -- Database simulation (replace with actual MySQL/web API)
    function KYBER.GrandExchange:LoadDatabase()
        KYBER.Optimization.SafeCall(function()
            if not file.Exists("kyber/grandexchange", "DATA") then
                file.CreateDir("kyber/grandexchange")
            end
            
            if file.Exists("kyber/grandexchange/listings.json", "DATA") then
                local data = file.Read("kyber/grandexchange/listings.json", "DATA")
                self.Listings = util.JSONToTable(data) or {}
            else
                self.Listings = {}
            end
            
            if file.Exists("kyber/grandexchange/history.json", "DATA") then
                local data = file.Read("kyber/grandexchange/history.json", "DATA")
                self.History = util.JSONToTable(data) or {}
            else
                self.History = {}
            end
            
            -- Clean up expired listings
            self:CleanupExpiredListings()
        end)
    end
    
    function KYBER.GrandExchange:SaveDatabase()
        KYBER.Optimization.SafeCall(function()
            -- Create backups
            if file.Exists("kyber/grandexchange/listings.json", "DATA") then
                file.Write("kyber/grandexchange/listings.json.backup", file.Read("kyber/grandexchange/listings.json", "DATA"))
            end
            if file.Exists("kyber/grandexchange/history.json", "DATA") then
                file.Write("kyber/grandexchange/history.json.backup", file.Read("kyber/grandexchange/history.json", "DATA"))
            end
            
            file.Write("kyber/grandexchange/listings.json", util.TableToJSON(self.Listings))
            file.Write("kyber/grandexchange/history.json", util.TableToJSON(self.History))
        end)
    end
    
    -- Initialize
    hook.Add("Initialize", "KyberGEInit", function()
        KYBER.GrandExchange:LoadDatabase()
        
        -- Periodic save
        timer.Create("KyberGESave", 300, 0, function()
            KYBER.GrandExchange:SaveDatabase()
        end)
    end)
    
    -- Listing management
    function KYBER.GrandExchange:CreateListing(seller, itemID, quantity, price)
        local item = KYBER.GrandExchange.Items[itemID]
        if not item then return false, "Invalid item" end
        
        -- Check if player has the item (implement based on your inventory system)
        -- For now, we'll assume they have it
        
        -- Check minimum price (prevent market manipulation)
        local minPrice = math.floor(item.basePrice * 0.1)
        if price < minPrice then
            return false, "Price too low (minimum: " .. minPrice .. ")"
        end
        
        -- Create listing
        local listingID = "L" .. os.time() .. "_" .. math.random(1000, 9999)
        
        self.Listings[listingID] = {
            id = listingID,
            itemID = itemID,
            quantity = quantity,
            price = price,
            seller = {
                steamID = seller:SteamID64(),
                name = seller:Nick(),
                server = GetHostName() -- Track which server
            },
            created = os.time(),
            expires = os.time() + (7 * 24 * 60 * 60), -- 7 days
            status = "active"
        }
        
        -- Remove item from player inventory
        -- KYBER:RemovePlayerItem(seller, itemID, quantity)
        
        self:SaveDatabase()
        
        -- Log transaction
        self:LogTransaction("list", seller, itemID, quantity, price)
        
        return true, listingID
    end
    
    function KYBER.GrandExchange:BuyListing(buyer, listingID)
        local listing = self.Listings[listingID]
        if not listing then return false, "Listing not found" end
        
        if listing.status ~= "active" then
            return false, "Listing no longer available"
        end
        
        -- Check buyer funds
        local buyerCredits = KYBER:GetPlayerData(buyer, "credits") or 0
        local totalCost = listing.price * listing.quantity
        
        if buyerCredits < totalCost then
            return false, "Insufficient credits"
        end
        
        -- Process transaction
        KYBER:SetPlayerData(buyer, "credits", buyerCredits - totalCost)
        
        -- Give item to buyer
        -- KYBER:GivePlayerItem(buyer, listing.itemID, listing.quantity)
        
        -- Mark listing as sold
        listing.status = "sold"
        listing.buyer = {
            steamID = buyer:SteamID64(),
            name = buyer:Nick(),
            server = GetHostName()
        }
        listing.soldTime = os.time()
        
        -- Add earnings to seller
        self:AddSellerEarnings(listing.seller.steamID, totalCost)
        
        -- Log transaction
        self:LogTransaction("buy", buyer, listing.itemID, listing.quantity, totalCost)
        
        self:SaveDatabase()
        
        return true
    end
    
    function KYBER.GrandExchange:AddSellerEarnings(sellerSteamID, amount)
        if not file.Exists("kyber/grandexchange/earnings", "DATA") then
            file.CreateDir("kyber/grandexchange/earnings")
        end
        
        local path = "kyber/grandexchange/earnings/" .. sellerSteamID .. ".txt"
        local current = tonumber(file.Read(path, "DATA") or "0") or 0
        file.Write(path, tostring(current + amount))
    end
    
    function KYBER.GrandExchange:CollectEarnings(ply)
        local steamID = ply:SteamID64()
        local path = "kyber/grandexchange/earnings/" .. steamID .. ".txt"
        
        if not file.Exists(path, "DATA") then
            return 0
        end
        
        local earnings = tonumber(file.Read(path, "DATA") or "0") or 0
        
        if earnings > 0 then
            -- Give credits to player
            local currentCredits = KYBER:GetPlayerData(ply, "credits") or 0
            KYBER:SetPlayerData(ply, "credits", currentCredits + earnings)
            
            -- Clear earnings
            file.Delete(path)
            
            return earnings
        end
        
        return 0
    end
    
    function KYBER.GrandExchange:CancelListing(ply, listingID)
        local listing = self.Listings[listingID]
        if not listing then return false, "Listing not found" end
        
        if listing.seller.steamID ~= ply:SteamID64() then
            return false, "You don't own this listing"
        end
        
        if listing.status ~= "active" then
            return false, "Cannot cancel - listing already " .. listing.status
        end
        
        -- Return items to player
        -- KYBER:GivePlayerItem(ply, listing.itemID, listing.quantity)
        
        listing.status = "cancelled"
        listing.cancelledTime = os.time()
        
        self:SaveDatabase()
        
        return true
    end
    
    function KYBER.GrandExchange:GetActiveListings(itemID)
        local listings = {}
        
        for id, listing in pairs(self.Listings) do
            if listing.status == "active" and 
               (not itemID or listing.itemID == itemID) and
               listing.expires > os.time() then
                table.insert(listings, listing)
            end
        end
        
        -- Sort by price per unit
        table.sort(listings, function(a, b)
            return (a.price / a.quantity) < (b.price / b.quantity)
        end)
        
        return listings
    end
    
    function KYBER.GrandExchange:GetPlayerListings(ply)
        local steamID = ply:SteamID64()
        local listings = {}
        
        for id, listing in pairs(self.Listings) do
            if listing.seller.steamID == steamID then
                table.insert(listings, listing)
            end
        end
        
        return listings
    end
    
    function KYBER.GrandExchange:CleanupExpiredListings()
        local now = os.time()
        
        for id, listing in pairs(self.Listings) do
            if listing.status == "active" and listing.expires < now then
                listing.status = "expired"
                
                -- Return items to seller's "collection box"
                -- This would be collected when they next log in
            end
        end
    end
    
    function KYBER.GrandExchange:LogTransaction(type, ply, itemID, quantity, price)
        local entry = {
            type = type,
            player = {
                steamID = ply:SteamID64(),
                name = ply:Nick()
            },
            itemID = itemID,
            quantity = quantity,
            price = price,
            timestamp = os.time(),
            server = GetHostName()
        }
        
        table.insert(self.History, entry)
        
        -- Keep only last 1000 entries
        if #self.History > 1000 then
            table.remove(self.History, 1)
        end
    end
    
    -- Networking
    net.Receive("Kyber_GE_ListItem", function(len, ply)
        if IsRateLimited(ply, "ListItem", 2) then return end
        
        local itemID = net.ReadString()
        local amount = net.ReadInt(32)
        local price = net.ReadInt(32)
        
        KYBER.Optimization.SafeCall(function()
            local success, err = KYBER.GrandExchange:CreateListing(ply, itemID, amount, price)
            
            if not success then
                ply:ChatPrint("Failed to list item: " .. err)
            end
        end)
    end)
    
    net.Receive("Kyber_GE_BuyItem", function(len, ply)
        if IsRateLimited(ply, "BuyItem", 1) then return end
        
        local listingID = net.ReadString()
        
        KYBER.Optimization.SafeCall(function()
            local success, err = KYBER.GrandExchange:BuyListing(ply, listingID)
            
            if not success then
                ply:ChatPrint("Failed to purchase item: " .. err)
            end
        end)
    end)
    
    net.Receive("Kyber_GE_CancelListing", function(len, ply)
        local listingID = net.ReadString()
        
        local success, result = KYBER.GrandExchange:CancelListing(ply, listingID)
        
        if success then
            ply:ChatPrint("Listing cancelled")
            KYBER.GrandExchange:BroadcastUpdate()
        else
            ply:ChatPrint("Failed to cancel: " .. result)
        end
    end)
    
    net.Receive("Kyber_GE_CollectEarnings", function(len, ply)
        local collected = KYBER.GrandExchange:CollectEarnings(ply)
        
        if collected > 0 then
            ply:ChatPrint("Collected " .. collected .. " credits from sales!")
        else
            ply:ChatPrint("No earnings to collect")
        end
    end)
    
    function KYBER.GrandExchange:BroadcastUpdate()
        net.Start("Kyber_GE_UpdateListings")
        net.WriteTable(self:GetActiveListings())
        net.Broadcast()
    end
    
    concommand.Add("kyber_grandexchange", function(ply)
        net.Start("Kyber_GE_Open")
        net.WriteTable(KYBER.GrandExchange:GetActiveListings())
        net.WriteTable(KYBER.GrandExchange:GetPlayerListings(ply))
        net.Send(ply)
    end)
    
else -- CLIENT
    
    net.Receive("Kyber_GE_Open", function()
        local activeListings = net.ReadTable()
        local myListings = net.ReadTable()
        
        KYBER.GrandExchange:OpenUI(activeListings, myListings)
    end)
    
    net.Receive("Kyber_GE_UpdateListings", function()
        local listings = net.ReadTable()
        
        -- Update UI if open
        if IsValid(GrandExchangeFrame) then
            KYBER.GrandExchange:RefreshListings(listings)
        end
    end)
    
    function KYBER.GrandExchange:OpenUI(activeListings, myListings)
        if IsValid(GrandExchangeFrame) then GrandExchangeFrame:Remove() end
        
        GrandExchangeFrame = vgui.Create("DFrame")
        GrandExchangeFrame:SetSize(900, 600)
        GrandExchangeFrame:Center()
        GrandExchangeFrame:SetTitle("Grand Exchange - Galactic Marketplace")
        GrandExchangeFrame:MakePopup()
        
        local sheet = vgui.Create("DPropertySheet", GrandExchangeFrame)
        sheet:Dock(FILL)
        sheet:DockMargin(10, 10, 10, 10)
        
        -- Browse tab
        local browsePanel = vgui.Create("DPanel", sheet)
        browsePanel:Dock(FILL)
        
        -- Category selector
        local catPanel = vgui.Create("DPanel", browsePanel)
        catPanel:Dock(LEFT)
        catPanel:SetWide(150)
        catPanel:DockMargin(0, 0, 10, 0)
        
        local catLabel = vgui.Create("DLabel", catPanel)
        catLabel:SetText("Categories")
        catLabel:SetFont("DermaDefaultBold")
        catLabel:Dock(TOP)
        catLabel:DockMargin(5, 5, 5, 5)
        
        local selectedCategory = nil
        local categoryButtons = {}
        
        for catID, cat in pairs(KYBER.GrandExchange.Categories) do
            local btn = vgui.Create("DButton", catPanel)
            btn:SetText(cat.name)
            btn:Dock(TOP)
            btn:DockMargin(0, 0, 0, 2)
            btn:SetTall(30)
            
            categoryButtons[catID] = btn
            
            btn.DoClick = function()
                selectedCategory = catID
                KYBER.GrandExchange:FilterListings(selectedCategory)
                
                -- Update button states
                for _, b in pairs(categoryButtons) do
                    b:SetEnabled(true)
                end
                btn:SetEnabled(false)
            end
        end
        
        -- Listings display
        local listPanel = vgui.Create("DPanel", browsePanel)
        listPanel:Dock(FILL)
        
        local searchBar = vgui.Create("DTextEntry", listPanel)
        searchBar:SetPlaceholderText("Search items...")
        searchBar:Dock(TOP)
        searchBar:DockMargin(0, 0, 0, 10)
        
        local listingsScroll = vgui.Create("DScrollPanel", listPanel)
        listingsScroll:Dock(FILL)
        
        -- Store reference for updates
        GrandExchangeFrame.listingsScroll = listingsScroll
        
        -- Display listings
        KYBER.GrandExchange:PopulateListings(listingsScroll, activeListings)
        
        sheet:AddSheet("Browse", browsePanel, "icon16/cart.png")
        
        -- Sell tab
        local sellPanel = vgui.Create("DPanel", sheet)
        sellPanel:Dock(FILL)
        
        local sellLabel = vgui.Create("DLabel", sellPanel)
        sellLabel:SetText("Select an item from your inventory to sell:")
        sellLabel:Dock(TOP)
        sellLabel:DockMargin(10, 10, 10, 10)
        
        -- Item selector (placeholder - integrate with your inventory system)
        local itemSelect = vgui.Create("DComboBox", sellPanel)
        itemSelect:Dock(TOP)
        itemSelect:DockMargin(10, 0, 10, 10)
        itemSelect:SetValue("Select Item")
        
        -- Add items from inventory
        for itemID, item in pairs(KYBER.GrandExchange.Items) do
            itemSelect:AddChoice(item.name, itemID)
        end
        
        local quantityLabel = vgui.Create("DLabel", sellPanel)
        quantityLabel:SetText("Quantity:")
        quantityLabel:Dock(TOP)
        quantityLabel:DockMargin(10, 0, 10, 5)
        
        local quantityEntry = vgui.Create("DNumberWang", sellPanel)
        quantityEntry:Dock(TOP)
        quantityEntry:DockMargin(10, 0, 10, 10)
        quantityEntry:SetMin(1)
        quantityEntry:SetMax(100)
        quantityEntry:SetValue(1)
        
        local priceLabel = vgui.Create("DLabel", sellPanel)
        priceLabel:SetText("Price per unit:")
        priceLabel:Dock(TOP)
        priceLabel:DockMargin(10, 0, 10, 5)
        
        local priceEntry = vgui.Create("DNumberWang", sellPanel)
        priceEntry:Dock(TOP)
        priceEntry:DockMargin(10, 0, 10, 10)
        priceEntry:SetMin(1)
        priceEntry:SetMax(999999)
        
        local totalLabel = vgui.Create("DLabel", sellPanel)
        totalLabel:SetText("Total: 0 credits")
        totalLabel:SetFont("DermaDefaultBold")
        totalLabel:Dock(TOP)
        totalLabel:DockMargin(10, 0, 10, 10)
        
        -- Update total
        local function UpdateTotal()
            local total = quantityEntry:GetValue() * priceEntry:GetValue()
            totalLabel:SetText("Total: " .. total .. " credits")
        end
        
        quantityEntry.OnValueChanged = UpdateTotal
        priceEntry.OnValueChanged = UpdateTotal
        
        local listButton = vgui.Create("DButton", sellPanel)
        listButton:SetText("List Item")
        listButton:SetTall(40)
        listButton:Dock(TOP)
        listButton:DockMargin(10, 10, 10, 10)
        
        listButton.DoClick = function()
            local _, itemID = itemSelect:GetSelected()
            if not itemID then
                LocalPlayer():ChatPrint("Please select an item")
                return
            end
            
            net.Start("Kyber_GE_ListItem")
            net.WriteString(itemID)
            net.WriteInt(quantityEntry:GetValue(), 32)
            net.WriteInt(priceEntry:GetValue(), 32)
            net.SendToServer()
        end
        
        sheet:AddSheet("Sell", sellPanel, "icon16/money_add.png")
        
        -- My Listings tab
        local myPanel = vgui.Create("DPanel", sheet)
        myPanel:Dock(FILL)
        
        local myScroll = vgui.Create("DScrollPanel", myPanel)
        myScroll:Dock(FILL)
        myScroll:DockMargin(10, 10, 10, 10)
        
        KYBER.GrandExchange:PopulateMyListings(myScroll, myListings)
        
        sheet:AddSheet("My Listings", myPanel, "icon16/page_white_text.png")
        
        -- Collect earnings button
        local collectBtn = vgui.Create("DButton", GrandExchangeFrame)
        collectBtn:SetText("Collect Earnings")
        collectBtn:Dock(BOTTOM)
        collectBtn:DockMargin(10, 0, 10, 10)
        collectBtn:SetTall(30)
        
        collectBtn.DoClick = function()
            net.Start("Kyber_GE_CollectEarnings")
            net.SendToServer()
        end
    end
    
    function KYBER.GrandExchange:PopulateListings(parent, listings)
        parent:Clear()
        
        for _, listing in ipairs(listings) do
            local item = KYBER.GrandExchange.Items[listing.itemID]
            if not item then continue end
            
            local panel = vgui.Create("DPanel", parent)
            panel:Dock(TOP)
            panel:DockMargin(0, 0, 0, 5)
            panel:SetTall(80)
            
            panel.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50))
                
                if self:IsHovered() then
                    draw.RoundedBox(4, 0, 0, w, h, Color(100, 100, 100, 50))
                end
            end
            
            -- Item info
            local name = vgui.Create("DLabel", panel)
            name:SetText(item.name .. " x" .. listing.quantity)
            name:SetFont("DermaDefaultBold")
            name:SetPos(10, 10)
            name:SizeToContents()
            
            local price = vgui.Create("DLabel", panel)
            price:SetText(listing.price .. " credits each")
            price:SetPos(10, 30)
            price:SizeToContents()
            
            local seller = vgui.Create("DLabel", panel)
            seller:SetText("Seller: " .. listing.seller.name .. " (" .. listing.seller.server .. ")")
            seller:SetPos(10, 50)
            seller:SizeToContents()
            
            -- Buy button
            local buyBtn = vgui.Create("DButton", panel)
            buyBtn:SetText("Buy")
            buyBtn:SetSize(100, 30)
            buyBtn:SetPos(panel:GetWide() - 110, 25)
            
            buyBtn.DoClick = function()
                Derma_Query(
                    "Buy " .. item.name .. " x" .. listing.quantity .. " for " .. (listing.price * listing.quantity) .. " credits?",
                    "Confirm Purchase",
                    "Yes", function()
                        net.Start("Kyber_GE_BuyItem")
                        net.WriteString(listing.id)
                        net.SendToServer()
                    end,
                    "No", function() end
                )
            end
        end
    end
    
    function KYBER.GrandExchange:PopulateMyListings(parent, listings)
        parent:Clear()
        
        for _, listing in ipairs(listings) do
            local item = KYBER.GrandExchange.Items[listing.itemID]
            if not item then continue end
            
            local panel = vgui.Create("DPanel", parent)
            panel:Dock(TOP)
            panel:DockMargin(0, 0, 0, 5)
            panel:SetTall(80)
            
            local statusColor = Color(50, 50, 50)
            if listing.status == "active" then
                statusColor = Color(50, 100, 50)
            elseif listing.status == "sold" then
                statusColor = Color(100, 100, 50)
            elseif listing.status == "expired" then
                statusColor = Color(100, 50, 50)
            end
            
            panel.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, statusColor)
            end
            
            -- Item info
            local name = vgui.Create("DLabel", panel)
            name:SetText(item.name .. " x" .. listing.quantity)
            name:SetFont("DermaDefaultBold")
            name:SetPos(10, 10)
            name:SizeToContents()
            
            local status = vgui.Create("DLabel", panel)
            status:SetText("Status: " .. listing.status:upper())
            status:SetPos(10, 30)
            status:SizeToContents()
            
            local price = vgui.Create("DLabel", panel)
            price:SetText("Listed for: " .. listing.price .. " credits each")
            price:SetPos(10, 50)
            price:SizeToContents()
            
            -- Cancel button (only for active listings)
            if listing.status == "active" then
                local cancelBtn = vgui.Create("DButton", panel)
                cancelBtn:SetText("Cancel")
                cancelBtn:SetSize(100, 30)
                cancelBtn:SetPos(panel:GetWide() - 110, 25)
                
                cancelBtn.DoClick = function()
                    net.Start("Kyber_GE_CancelListing")
                    net.WriteString(listing.id)
                    net.SendToServer()
                end
            end
        end
    end
    
    function KYBER.GrandExchange:RefreshListings(listings)
        if IsValid(GrandExchangeFrame) and IsValid(GrandExchangeFrame.listingsScroll) then
            self:PopulateListings(GrandExchangeFrame.listingsScroll, listings)
        end
    end
    
    function KYBER.GrandExchange:FilterListings(category)
        -- Implement category filtering
        -- This would filter the displayed listings based on the selected category
    end
end