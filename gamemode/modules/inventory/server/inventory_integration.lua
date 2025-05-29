-- kyber/modules/inventory/integration.lua
-- This file contains the integration hooks between inventory and other systems

if SERVER then
    -- Hook into Grand Exchange to use inventory system
    hook.Add("Initialize", "KyberInventoryGEIntegration", function()
        timer.Simple(1, function()
            -- Override GE functions to use inventory
            local oldCreateListing = KYBER.GrandExchange.CreateListing
            KYBER.GrandExchange.CreateListing = function(self, seller, itemID, quantity, price)
                -- Check if player has the item
                local hasItem, count = KYBER.Inventory:HasItem(seller, itemID, quantity)
                if not hasItem then
                    return false, "You don't have enough of this item (have " .. count .. ", need " .. quantity .. ")"
                end
                
                -- Remove item from inventory
                KYBER.Inventory:RemoveItem(seller, itemID, quantity)
                
                -- Call original function
                return oldCreateListing(self, seller, itemID, quantity, price)
            end
            
            local oldBuyListing = KYBER.GrandExchange.BuyListing
            KYBER.GrandExchange.BuyListing = function(self, buyer, listingID)
                local listing = self.Listings[listingID]
                if not listing then return false, "Listing not found" end
                
                -- Check inventory space
                local testSuccess = KYBER.Inventory:GiveItem(buyer, listing.itemID, listing.quantity)
                if not testSuccess then
                    return false, "Not enough inventory space"
                end
                
                -- Remove the test items
                KYBER.Inventory:RemoveItem(buyer, listing.itemID, listing.quantity)
                
                -- Call original function
                local success, err = oldBuyListing(self, buyer, listingID)
                
                if success then
                    -- Give items to buyer
                    KYBER.Inventory:GiveItem(buyer, listing.itemID, listing.quantity)
                end
                
                return success, err
            end
            
            local oldCancelListing = KYBER.GrandExchange.CancelListing
            KYBER.GrandExchange.CancelListing = function(self, ply, listingID)
                local listing = self.Listings[listingID]
                if not listing then return false, "Listing not found" end
                
                local success, err = oldCancelListing(self, ply, listingID)
                
                if success then
                    -- Return items to player
                    KYBER.Inventory:GiveItem(ply, listing.itemID, listing.quantity)
                end
                
                return success, err
            end
        end)
    end)
    
    -- Add inventory display to character sheet
    hook.Add("Kyber_CharacterSheet_AddInfo", "AddInventoryInfo", function(ply)
        local itemCount = 0
        local totalValue = 0
        
        for _, slotData in pairs(ply.KyberInventory or {}) do
            if slotData then
                itemCount = itemCount + 1
                local item = KYBER.GrandExchange.Items[slotData.id]
                if item then
                    totalValue = totalValue + (item.basePrice * slotData.amount)
                end
            end
        end
        
        return {
            {label = "Items Carried", value = itemCount .. "/" .. KYBER.Inventory.Config.slots},
            {label = "Inventory Value", value = totalValue .. " credits"}
        }
    end)
    
    -- Commands for testing
    concommand.Add("kyber_spawn_item", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local itemID = args[1] or "bacta_vial"
        local amount = tonumber(args[2]) or 1
        
        local ent = ents.Create("kyber_dropped_item")
        ent:SetPos(ply:GetEyeTrace().HitPos + Vector(0, 0, 10))
        ent:Spawn()
        ent:SetItem(itemID, amount)
        
        ply:ChatPrint("Spawned " .. amount .. "x " .. itemID)
    end)
    
else -- CLIENT
    
    -- Add inventory keybind to F4 datapad
    hook.Add("Kyber_Datapad_AddTabs", "AddInventoryTab", function(tabSheet)
        local invPanel = vgui.Create("DPanel", tabSheet)
        invPanel:Dock(FILL)
        
        local openInvBtn = vgui.Create("DButton", invPanel)
        openInvBtn:SetText("Open Full Inventory (I)")
        openInvBtn:SetSize(200, 50)
        openInvBtn:SetPos(20, 20)
        openInvBtn.DoClick = function()
            RunConsoleCommand("kyber_inventory")
        end
        
        local tradeBtn = vgui.Create("DButton", invPanel)
        tradeBtn:SetText("Start Trade")
        tradeBtn:SetSize(200, 50)
        tradeBtn:SetPos(20, 80)
        tradeBtn.DoClick = function()
            KYBER.Trading:OpenTradeRequest()
        end
        
        local geBtn = vgui.Create("DButton", invPanel)
        geBtn:SetText("Grand Exchange")
        geBtn:SetSize(200, 50)
        geBtn:SetPos(20, 140)
        geBtn.DoClick = function()
            RunConsoleCommand("kyber_grandexchange")
        end
        
        -- Quick inventory view
        local quickInv = vgui.Create("DPanel", invPanel)
        quickInv:SetPos(250, 20)
        quickInv:SetSize(400, 300)
        
        quickInv.Paint = function(self, w, h)
            draw.RoundedBox(4, 