-- kyber/modules/inventory/system.lua
KYBER.Inventory = KYBER.Inventory or {}

-- Inventory configuration
KYBER.Inventory.Config = {
    slots = 28, -- Default inventory size
    maxStackSize = 64, -- Default max stack
    dropOnDeath = false,
    saveInterval = 300 -- 5 minutes
}

if SERVER then
    util.AddNetworkString("Kyber_Inventory_Open")
    util.AddNetworkString("Kyber_Inventory_Update")
    util.AddNetworkString("Kyber_Inventory_Move")
    util.AddNetworkString("Kyber_Inventory_Drop")
    util.AddNetworkString("Kyber_Inventory_Use")
    util.AddNetworkString("Kyber_Inventory_Split")
    
    -- Initialize inventory for a player
    function KYBER.Inventory:Initialize(ply)
        local steamID = ply:SteamID64()
        
        -- Load from file
        local path = "kyber/inventories/" .. steamID .. ".json"
        if file.Exists(path, "DATA") then
            local data = file.Read(path, "DATA")
            ply.KyberInventory = util.JSONToTable(data) or {}
        else
            ply.KyberInventory = {}
        end
        
        -- Validate inventory
        self:ValidateInventory(ply)
    end
    
    function KYBER.Inventory:ValidateInventory(ply)
        if not ply.KyberInventory then
            ply.KyberInventory = {}
        end
        
        -- Ensure all slots exist
        for i = 1, KYBER.Inventory.Config.slots do
            if not ply.KyberInventory[i] then
                ply.KyberInventory[i] = nil
            end
        end
    end
    
    function KYBER.Inventory:Save(ply)
        if not IsValid(ply) or not ply.KyberInventory then return end
        
        local steamID = ply:SteamID64()
        local path = "kyber/inventories/" .. steamID .. ".json"
        
        if not file.Exists("kyber/inventories", "DATA") then
            file.CreateDir("kyber/inventories")
        end
        
        file.Write(path, util.TableToJSON(ply.KyberInventory))
    end
    
    -- Item management
    function KYBER.Inventory:GiveItem(ply, itemID, amount)
        amount = amount or 1
        local item = KYBER.GrandExchange.Items[itemID]
        if not item then return false, "Invalid item" end
        
        local remaining = amount
        
        -- Try to stack with existing items first
        if item.stackable then
            for slot, slotData in pairs(ply.KyberInventory) do
                if slotData and slotData.id == itemID then
                    local space = (item.maxStack or KYBER.Inventory.Config.maxStackSize) - slotData.amount
                    if space > 0 then
                        local toAdd = math.min(space, remaining)
                        slotData.amount = slotData.amount + toAdd
                        remaining = remaining - toAdd
                        
                        if remaining <= 0 then
                            self:SendInventoryUpdate(ply)
                            return true
                        end
                    end
                end
            end
        end
        
        -- Add to empty slots
        for i = 1, KYBER.Inventory.Config.slots do
            if not ply.KyberInventory[i] and remaining > 0 then
                local toAdd = remaining
                if item.stackable then
                    toAdd = math.min(remaining, item.maxStack or KYBER.Inventory.Config.maxStackSize)
                else
                    toAdd = 1
                end
                
                ply.KyberInventory[i] = {
                    id = itemID,
                    amount = toAdd
                }
                
                remaining = remaining - toAdd
                
                if remaining <= 0 then
                    self:SendInventoryUpdate(ply)
                    return true
                end
            end
        end
        
        if remaining > 0 then
            self:SendInventoryUpdate(ply)
            return false, "Not enough inventory space (need " .. remaining .. " more slots)"
        end
        
        self:SendInventoryUpdate(ply)
        return true
    end
    
    function KYBER.Inventory:RemoveItem(ply, itemID, amount)
        amount = amount or 1
        local removed = 0
        
        for slot, slotData in pairs(ply.KyberInventory) do
            if slotData and slotData.id == itemID then
                local toRemove = math.min(slotData.amount, amount - removed)
                slotData.amount = slotData.amount - toRemove
                removed = removed + toRemove
                
                if slotData.amount <= 0 then
                    ply.KyberInventory[slot] = nil
                end
                
                if removed >= amount then
                    self:SendInventoryUpdate(ply)
                    return true
                end
            end
        end
        
        self:SendInventoryUpdate(ply)
        return removed > 0, removed
    end
    
    function KYBER.Inventory:HasItem(ply, itemID, amount)
        amount = amount or 1
        local count = 0
        
        for _, slotData in pairs(ply.KyberInventory) do
            if slotData and slotData.id == itemID then
                count = count + slotData.amount
            end
        end
        
        return count >= amount, count
    end
    
    function KYBER.Inventory:GetItemCount(ply, itemID)
        local count = 0
        
        for _, slotData in pairs(ply.KyberInventory) do
            if slotData and slotData.id == itemID then
                count = count + slotData.amount
            end
        end
        
        return count
    end
    
    -- Networking
    function KYBER.Inventory:SendInventoryUpdate(ply)
        net.Start("Kyber_Inventory_Update")
        net.WriteTable(ply.KyberInventory)
        net.Send(ply)
    end
    
    -- Network receivers
    net.Receive("Kyber_Inventory_Move", function(len, ply)
        local fromSlot = net.ReadInt(8)
        local toSlot = net.ReadInt(8)
        
        if fromSlot < 1 or fromSlot > KYBER.Inventory.Config.slots then return end
        if toSlot < 1 or toSlot > KYBER.Inventory.Config.slots then return end
        
        local fromItem = ply.KyberInventory[fromSlot]
        local toItem = ply.KyberInventory[toSlot]
        
        -- Swap items
        ply.KyberInventory[fromSlot] = toItem
        ply.KyberInventory[toSlot] = fromItem
        
        KYBER.Inventory:SendInventoryUpdate(ply)
    end)
    
    net.Receive("Kyber_Inventory_Drop", function(len, ply)
        local slot = net.ReadInt(8)
        local amount = net.ReadInt(16)
        
        if slot < 1 or slot > KYBER.Inventory.Config.slots then return end
        
        local slotData = ply.KyberInventory[slot]
        if not slotData then return end
        
        amount = math.min(amount, slotData.amount)
        
        -- Create dropped item entity
        local ent = ents.Create("kyber_dropped_item")
        if IsValid(ent) then
            ent:SetPos(ply:GetPos() + ply:GetForward() * 50 + Vector(0, 0, 10))
            ent:SetItemID(slotData.id)
            ent:SetAmount(amount)
            ent:Spawn()
            
            -- Apply physics
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(ply:GetAimVector() * 200 + Vector(0, 0, 100))
            end
        end
        
        -- Remove from inventory
        slotData.amount = slotData.amount - amount
        if slotData.amount <= 0 then
            ply.KyberInventory[slot] = nil
        end
        
        KYBER.Inventory:SendInventoryUpdate(ply)
    end)
    
    net.Receive("Kyber_Inventory_Use", function(len, ply)
        local slot = net.ReadInt(8)
        
        if slot < 1 or slot > KYBER.Inventory.Config.slots then return end
        
        local slotData = ply.KyberInventory[slot]
        if not slotData then return end
        
        local item = KYBER.GrandExchange.Items[slotData.id]
        if not item then return end
        
        -- Handle item use based on category
        if item.category == "consumables" then
            -- Example: Bacta vial healing
            if slotData.id == "bacta_vial" then
                ply:SetHealth(math.min(ply:Health() + 50, ply:GetMaxHealth()))
                ply:EmitSound("items/medshot4.wav")
                
                -- Consume item
                slotData.amount = slotData.amount - 1
                if slotData.amount <= 0 then
                    ply.KyberInventory[slot] = nil
                end
                
                KYBER.Inventory:SendInventoryUpdate(ply)
            end
        end
    end)
    
    net.Receive("Kyber_Inventory_Split", function(len, ply)
        local slot = net.ReadInt(8)
        local amount = net.ReadInt(16)
        
        if slot < 1 or slot > KYBER.Inventory.Config.slots then return end
        
        local slotData = ply.KyberInventory[slot]
        if not slotData or slotData.amount <= 1 then return end
        
        amount = math.min(amount, math.floor(slotData.amount / 2))
        
        -- Find empty slot
        for i = 1, KYBER.Inventory.Config.slots do
            if not ply.KyberInventory[i] then
                ply.KyberInventory[i] = {
                    id = slotData.id,
                    amount = amount
                }
                
                slotData.amount = slotData.amount - amount
                KYBER.Inventory:SendInventoryUpdate(ply)
                break
            end
        end
    end)
    
    -- Hooks
    hook.Add("PlayerInitialSpawn", "KyberInventoryInit", function(ply)
        KYBER.Inventory:Initialize(ply)
    end)
    
    hook.Add("PlayerDisconnected", "KyberInventorySave", function(ply)
        KYBER.Inventory:Save(ply)
    end)
    
    -- Periodic save
    timer.Create("KyberInventorySave", KYBER.Inventory.Config.saveInterval, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            KYBER.Inventory:Save(ply)
        end
    end)
    
    -- Commands
    concommand.Add("kyber_inventory", function(ply)
        net.Start("Kyber_Inventory_Open")
        net.WriteTable(ply.KyberInventory)
        net.Send(ply)
    end)
    
    -- Debug commands
    concommand.Add("kyber_giveitem", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local target = ply
        if args[1] then
            target = player.GetBySteamID(args[1]) or ply
        end
        
        local itemID = args[2] or "bacta_vial"
        local amount = tonumber(args[3]) or 1
        
        local success, err = KYBER.Inventory:GiveItem(target, itemID, amount)
        if success then
            ply:ChatPrint("Gave " .. amount .. "x " .. itemID .. " to " .. target:Nick())
        else
            ply:ChatPrint("Failed: " .. err)
        end
    end)
    
else -- CLIENT
    
    local InventoryPanel = nil
    
    net.Receive("Kyber_Inventory_Open", function()
        local inventory = net.ReadTable()
        KYBER.Inventory:OpenUI(inventory)
    end)
    
    net.Receive("Kyber_Inventory_Update", function()
        local inventory = net.ReadTable()
        
        if IsValid(InventoryPanel) then
            KYBER.Inventory:UpdateUI(inventory)
        end
        
        -- Store locally for UI updates
        LocalPlayer().KyberInventory = inventory
    end)
    
    function KYBER.Inventory:OpenUI(inventory)
        if IsValid(InventoryPanel) then
            InventoryPanel:Remove()
            return
        end
        
        InventoryPanel = vgui.Create("DFrame")
        InventoryPanel:SetSize(400, 500)
        InventoryPanel:SetPos(100, ScrH() / 2 - 250)
        InventoryPanel:SetTitle("Inventory")
        InventoryPanel:MakePopup()
        
        local grid = vgui.Create("DGrid", InventoryPanel)
        grid:SetPos(10, 30)
        grid:SetCols(7)
        grid:SetColWide(52)
        grid:SetRowHeight(52)
        
        -- Store slots for updates
        InventoryPanel.slots = {}
        
        -- Create inventory slots
        for i = 1, KYBER.Inventory.Config.slots do
            local slot = vgui.Create("DPanel")
            slot:SetSize(50, 50)
            slot.slotID = i
            
            slot.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50))
                
                if self:IsHovered() then
                    draw.RoundedBox(4, 0, 0, w, h, Color(100, 100, 100, 50))
                end
                
                -- Draw item
                if self.itemData then
                    local item = KYBER.GrandExchange.Items[self.itemData.id]
                    if item then
                        -- Item icon placeholder
                        draw.RoundedBox(4, 5, 5, w-10, h-10, Color(100, 100, 100))
                        
                        -- Item name (abbreviated)
                        local name = string.sub(item.name, 1, 8)
                        draw.SimpleText(name, "Default", w/2, h/2 - 5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        
                        -- Stack count
                        if self.itemData.amount > 1 then
                            draw.SimpleText(self.itemData.amount, "DermaDefault", w-5, h-5, Color(255, 255, 0), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
                        end
                    end
                end
            end
            
            -- Set item data
            slot.itemData = inventory[i]
            
            -- Drag and drop
            slot:Receiver("inventory_slot", function(self, panels, dropped)
                if dropped then
                    local from = panels[1]
                    if from.slotID and from.slotID ~= self.slotID then
                        net.Start("Kyber_Inventory_Move")
                        net.WriteInt(from.slotID, 8)
                        net.WriteInt(self.slotID, 8)
                        net.SendToServer()
                    end
                end
            end)
            
            -- Right click menu
            slot.DoRightClick = function(self)
                if not self.itemData then return end
                
                local menu = DermaMenu()
                
                local item = KYBER.GrandExchange.Items[self.itemData.id]
                if item then
                    menu:AddOption("Use", function()
                        net.Start("Kyber_Inventory_Use")
                        net.WriteInt(self.slotID, 8)
                        net.SendToServer()
                    end):SetIcon("icon16/accept.png")
                    
                    if self.itemData.amount > 1 then
                        menu:AddOption("Split Stack", function()
                            Derma_StringRequest("Split Stack", "Amount to split:", tostring(math.floor(self.itemData.amount / 2)), 
                                function(text)
                                    local amount = tonumber(text)
                                    if amount and amount > 0 then
                                        net.Start("Kyber_Inventory_Split")
                                        net.WriteInt(self.slotID, 8)
                                        net.WriteInt(amount, 16)
                                        net.SendToServer()
                                    end
                                end
                            )
                        end):SetIcon("icon16/arrow_divide.png")
                    end
                    
                    menu:AddOption("Drop", function()
                        local amount = self.itemData.amount
                        if amount > 1 then
                            Derma_StringRequest("Drop Item", "Amount to drop:", tostring(amount), 
                                function(text)
                                    local dropAmount = tonumber(text)
                                    if dropAmount and dropAmount > 0 then
                                        net.Start("Kyber_Inventory_Drop")
                                        net.WriteInt(self.slotID, 8)
                                        net.WriteInt(dropAmount, 16)
                                        net.SendToServer()
                                    end
                                end
                            )
                        else
                            net.Start("Kyber_Inventory_Drop")
                            net.WriteInt(self.slotID, 8)
                            net.WriteInt(1, 16)
                            net.SendToServer()
                        end
                    end):SetIcon("icon16/arrow_down.png")
                    
                    menu:AddSpacer()
                    
                    menu:AddOption("Examine", function()
                        chat.AddText(Color(255, 255, 100), "[" .. item.name .. "]", Color(255, 255, 255), " " .. item.description)
                    end):SetIcon("icon16/magnifier.png")
                end
                
                menu:Open()
            end
            
            -- Make draggable
            if slot.itemData then
                slot:Droppable("inventory_slot")
            end
            
            -- Tooltip
            slot:SetTooltip(slot.itemData and KYBER.GrandExchange.Items[slot.itemData.id].name or "Empty slot")
            
            grid:AddItem(slot)
            InventoryPanel.slots[i] = slot
        end
        
        -- Weight/capacity display
        local infoPanel = vgui.Create("DPanel", InventoryPanel)
        infoPanel:SetPos(10, 450)
        infoPanel:SetSize(380, 40)
        infoPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            
            local used = 0
            for _, data in pairs(inventory) do
                if data then used = used + 1 end
            end
            
            draw.SimpleText("Inventory: " .. used .. "/" .. KYBER.Inventory.Config.slots, "DermaDefault", 10, 10, Color(255, 255, 255))
            
            local credits = LocalPlayer():GetNWString("kyberdata_credits", "0")
            draw.SimpleText("Credits: " .. credits, "DermaDefault", 10, 25, Color(255, 215, 0))
        end
        
        -- Trade button
        local tradeBtn = vgui.Create("DButton", InventoryPanel)
        tradeBtn:SetText("Trade")
        tradeBtn:SetPos(300, 10)
        tradeBtn:SetSize(80, 20)
        tradeBtn.DoClick = function()
            KYBER.Trading:OpenTradeRequest()
        end
    end
    
    function KYBER.Inventory:UpdateUI(inventory)
        if not IsValid(InventoryPanel) then return end
        
        for i = 1, KYBER.Inventory.Config.slots do
            if InventoryPanel.slots[i] then
                InventoryPanel.slots[i].itemData = inventory[i]
            end
        end
    end
    
    -- Keybind
    hook.Add("PlayerButtonDown", "KyberInventoryKey", function(ply, key)
        if key == KEY_I then
            RunConsoleCommand("kyber_inventory")
        end
    end)
end