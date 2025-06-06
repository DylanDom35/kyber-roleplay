-- kyber/modules/banking/system.lua
KYBER.Banking = KYBER.Banking or {}

-- Banking configuration
KYBER.Banking.Config = {
    -- Personal storage
    personalSlots = 50,              -- Base storage slots
    slotUpgradeCost = 1000,         -- Cost per additional slot
    maxSlots = 200,                 -- Maximum storage slots
    
    -- Faction storage
    factionBaseSlots = 100,         -- Base faction storage
    factionSlotCost = 5000,         -- Cost per faction slot
    factionMaxSlots = 500,          -- Maximum faction storage
    
    -- Safety deposit boxes
    boxRentalCost = 100,            -- Daily rental cost
    boxSizes = {
        small = {slots = 10, cost = 100},
        medium = {slots = 25, cost = 250},
        large = {slots = 50, cost = 500}
    },
    
    -- Credit storage
    withdrawFee = 0,                -- Percentage fee for withdrawals
    interestRate = 0.001,           -- Daily interest rate (0.1%)
    maxInterest = 10000,            -- Maximum daily interest earnings
    
    -- Security
    hackDifficulty = 20,            -- Difficulty to hack storage
    securityUpgradeCost = 5000,    -- Cost to upgrade security
}

-- Storage types
KYBER.Banking.StorageTypes = {
    ["personal"] = {
        name = "Personal Vault",
        icon = "icon16/lock.png",
        description = "Your private storage vault"
    },
    ["faction"] = {
        name = "Faction Treasury",
        icon = "icon16/group.png",
        description = "Shared faction storage"
    },
    ["deposit"] = {
        name = "Safety Deposit Box",
        icon = "icon16/box.png",
        description = "Rentable secure storage"
    }
}

if SERVER then
    util.AddNetworkString("Kyber_Banking_Open")
    util.AddNetworkString("Kyber_Banking_Deposit")
    util.AddNetworkString("Kyber_Banking_Withdraw")
    util.AddNetworkString("Kyber_Banking_Transfer")
    util.AddNetworkString("Kyber_Banking_UpgradeSlots")
    util.AddNetworkString("Kyber_Banking_Update")
    util.AddNetworkString("Kyber_Banking_FactionAccess")
    util.AddNetworkString("Kyber_Banking_RentBox")
    
    -- Initialize banking data
    function KYBER.Banking:Initialize(ply)
        local steamID = ply:SteamID64()
        local charName = ply:GetNWString("kyber_name", "default")
        
        -- Personal storage
        local personalPath = "kyber/banking/" .. steamID .. "_" .. charName .. ".json"
        if file.Exists(personalPath, "DATA") then
            local data = file.Read(personalPath, "DATA")
            ply.KyberBanking = util.JSONToTable(data) or {}
        else
            ply.KyberBanking = {
                credits = 0,
                slots = KYBER.Banking.Config.personalSlots,
                storage = {},
                lastInterest = os.time(),
                security = 1,
                rentedBoxes = {}
            }
        end
        
        -- Calculate interest
        self:CalculateInterest(ply)
        
        -- Load faction storage access
        local faction = ply:GetNWString("kyber_faction", "")
        if faction ~= "" then
            self:LoadFactionStorage(faction)
        end
    end
    
    function KYBER.Banking:Save(ply)
        if not IsValid(ply) or not ply.KyberBanking then return end
        
        local steamID = ply:SteamID64()
        local charName = ply:GetNWString("kyber_name", "default")
        local path = "kyber/banking/" .. steamID .. "_" .. charName .. ".json"
        
        KYBER.Optimization.SafeCall(function()
            if not file.Exists("kyber/banking", "DATA") then
                file.CreateDir("kyber/banking")
            end
            
            -- Create backup
            if file.Exists(path, "DATA") then
                file.Write(path .. ".backup", file.Read(path, "DATA"))
            end
            
            file.Write(path, util.TableToJSON(ply.KyberBanking))
        end)
    end
    
    -- Load faction storage
    function KYBER.Banking:LoadFactionStorage(factionID)
        if not KYBER.Banking.FactionStorage then
            KYBER.Banking.FactionStorage = {}
        end
        
        if KYBER.Banking.FactionStorage[factionID] then
            return -- Already loaded
        end
        
        local path = "kyber/banking/faction_" .. factionID .. ".json"
        if file.Exists(path, "DATA") then
            local data = file.Read(path, "DATA")
            KYBER.Banking.FactionStorage[factionID] = util.JSONToTable(data) or {}
        else
            KYBER.Banking.FactionStorage[factionID] = {
                credits = 0,
                slots = KYBER.Banking.Config.factionBaseSlots,
                storage = {},
                accessLevels = {}, -- Rank-based access
                logs = {}
            }
        end
    end
    
    function KYBER.Banking:SaveFactionStorage(factionID)
        if not KYBER.Banking.FactionStorage or not KYBER.Banking.FactionStorage[factionID] then
            return
        end
        
        local path = "kyber/banking/faction_" .. factionID .. ".json"
        
        KYBER.Optimization.SafeCall(function()
            -- Create backup
            if file.Exists(path, "DATA") then
                file.Write(path .. ".backup", file.Read(path, "DATA"))
            end
            
            file.Write(path, util.TableToJSON(KYBER.Banking.FactionStorage[factionID]))
        end)
    end
    
    -- Calculate interest
    function KYBER.Banking:CalculateInterest(ply)
        if not ply.KyberBanking then return end
        
        local lastTime = ply.KyberBanking.lastInterest or os.time()
        local currentTime = os.time()
        local daysPassed = math.floor((currentTime - lastTime) / 86400)
        
        if daysPassed > 0 and ply.KyberBanking.credits > 0 then
            local interest = math.min(
                ply.KyberBanking.credits * KYBER.Banking.Config.interestRate * daysPassed,
                KYBER.Banking.Config.maxInterest * daysPassed
            )
            
            ply.KyberBanking.credits = ply.KyberBanking.credits + interest
            ply.KyberBanking.lastInterest = currentTime
            
            if interest > 0 then
                ply:ChatPrint("Bank interest earned: " .. math.floor(interest) .. " credits")
            end
        end
    end
    
    -- Deposit credits
    function KYBER.Banking:DepositCredits(ply, amount, storageType, factionID)
        amount = math.floor(amount)
        if amount <= 0 then return false, "Invalid amount" end
        
        local playerCredits = KYBER:GetPlayerData(ply, "credits") or 0
        if playerCredits < amount then
            return false, "Insufficient credits"
        end
        
        if storageType == "personal" then
            ply.KyberBanking.credits = ply.KyberBanking.credits + amount
            KYBER:SetPlayerData(ply, "credits", playerCredits - amount)
            self:Save(ply)
            return true
            
        elseif storageType == "faction" and factionID then
            local storage = KYBER.Banking.FactionStorage[factionID]
            if not storage then
                return false, "Faction storage not available"
            end
            
            -- Check permission
            if not self:CanAccessFactionStorage(ply, factionID, "deposit") then
                return false, "No permission to deposit"
            end
            
            storage.credits = storage.credits + amount
            KYBER:SetPlayerData(ply, "credits", playerCredits - amount)
            
            -- Log transaction
            table.insert(storage.logs, {
                player = ply:Nick(),
                steamID = ply:SteamID64(),
                action = "deposit",
                amount = amount,
                time = os.time()
            })
            
            self:SaveFactionStorage(factionID)
            return true
        end
        
        return false, "Invalid storage type"
    end
    
    -- Withdraw credits
    function KYBER.Banking:WithdrawCredits(ply, amount, storageType, factionID)
        amount = math.floor(amount)
        if amount <= 0 then return false, "Invalid amount" end
        
        if storageType == "personal" then
            if ply.KyberBanking.credits < amount then
                return false, "Insufficient funds"
            end
            
            ply.KyberBanking.credits = ply.KyberBanking.credits - amount
            local playerCredits = KYBER:GetPlayerData(ply, "credits") or 0
            KYBER:SetPlayerData(ply, "credits", playerCredits + amount)
            self:Save(ply)
            return true
            
        elseif storageType == "faction" and factionID then
            local storage = KYBER.Banking.FactionStorage[factionID]
            if not storage then
                return false, "Faction storage not available"
            end
            
            -- Check permission
            if not self:CanAccessFactionStorage(ply, factionID, "withdraw") then
                return false, "No permission to withdraw"
            end
            
            if storage.credits < amount then
                return false, "Insufficient faction funds"
            end
            
            storage.credits = storage.credits - amount
            local playerCredits = KYBER:GetPlayerData(ply, "credits") or 0
            KYBER:SetPlayerData(ply, "credits", playerCredits + amount)
            
            -- Log transaction
            table.insert(storage.logs, {
                player = ply:Nick(),
                steamID = ply:SteamID64(),
                action = "withdraw",
                amount = amount,
                time = os.time()
            })
            
            self:SaveFactionStorage(factionID)
            return true
        end
        
        return false, "Invalid storage type"
    end
    
    -- Store item
    function KYBER.Banking:StoreItem(ply, itemID, amount, slot, storageType, factionID)
        -- Check if player has the item
        local hasItem, count = KYBER.Inventory:HasItem(ply, itemID, amount)
        if not hasItem then
            return false, "Don't have enough items"
        end
        
        local storage
        local maxSlots
        
        if storageType == "personal" then
            storage = ply.KyberBanking.storage
            maxSlots = ply.KyberBanking.slots
        elseif storageType == "faction" and factionID then
            if not self:CanAccessFactionStorage(ply, factionID, "deposit") then
                return false, "No permission"
            end
            storage = KYBER.Banking.FactionStorage[factionID].storage
            maxSlots = KYBER.Banking.FactionStorage[factionID].slots
        else
            return false, "Invalid storage type"
        end
        
        -- Check slot availability
        if slot > maxSlots then
            return false, "Invalid slot"
        end
        
        -- Stack with existing items
        local item = KYBER.GrandExchange.Items[itemID]
        if item and item.stackable then
            for i = 1, maxSlots do
                if storage[i] and storage[i].id == itemID then
                    local space = (item.maxStack or 64) - storage[i].amount
                    if space > 0 then
                        local toAdd = math.min(space, amount)
                        storage[i].amount = storage[i].amount + toAdd
                        amount = amount - toAdd
                        
                        if amount <= 0 then
                            break
                        end
                    end
                end
            end
        end
        
        -- Add to empty slots
        if amount > 0 then
            if storage[slot] then
                return false, "Slot occupied"
            end
            
            storage[slot] = {
                id = itemID,
                amount = amount
            }
        end
        
        -- Remove from inventory
        KYBER.Inventory:RemoveItem(ply, itemID, amount)
        
        -- Save
        if storageType == "personal" then
            self:Save(ply)
        else
            self:SaveFactionStorage(factionID)
        end
        
        return true
    end
    
    -- Retrieve item
    function KYBER.Banking:RetrieveItem(ply, slot, amount, storageType, factionID)
        local storage
        
        if storageType == "personal" then
            storage = ply.KyberBanking.storage
        elseif storageType == "faction" and factionID then
            if not self:CanAccessFactionStorage(ply, factionID, "withdraw") then
                return false, "No permission"
            end
            storage = KYBER.Banking.FactionStorage[factionID].storage
        else
            return false, "Invalid storage type"
        end
        
        local storedItem = storage[slot]
        if not storedItem then
            return false, "Empty slot"
        end
        
        amount = math.min(amount, storedItem.amount)
        
        -- Try to give to player
        local success, err = KYBER.Inventory:GiveItem(ply, storedItem.id, amount)
        if not success then
            return false, err
        end
        
        -- Remove from storage
        storedItem.amount = storedItem.amount - amount
        if storedItem.amount <= 0 then
            storage[slot] = nil
        end
        
        -- Save
        if storageType == "personal" then
            self:Save(ply)
        else
            self:SaveFactionStorage(factionID)
        end
        
        return true
    end
    
    -- Check faction storage permissions
    function KYBER.Banking:CanAccessFactionStorage(ply, factionID, action)
        if ply:GetNWString("kyber_faction", "") ~= factionID then
            return false
        end
        
        local storage = KYBER.Banking.FactionStorage[factionID]
        if not storage then return false end
        
        local rank = ply:GetNWString("kyber_rank", "")
        local accessLevel = storage.accessLevels[rank] or "none"
        
        if action == "deposit" then
            return accessLevel == "deposit" or accessLevel == "full"
        elseif action == "withdraw" then
            return accessLevel == "full"
        end
        
        return false
    end
    
    -- Upgrade storage slots
    function KYBER.Banking:UpgradeSlots(ply, storageType, factionID)
        local cost = KYBER.Banking.Config.slotUpgradeCost
        local currentSlots
        local maxSlots
        
        if storageType == "personal" then
            currentSlots = ply.KyberBanking.slots
            maxSlots = KYBER.Banking.Config.maxSlots
        elseif storageType == "faction" and factionID then
            if not self:CanAccessFactionStorage(ply, factionID, "withdraw") then
                return false, "No permission"
            end
            currentSlots = KYBER.Banking.FactionStorage[factionID].slots
            maxSlots = KYBER.Banking.Config.factionMaxSlots
            cost = KYBER.Banking.Config.factionSlotCost
        else
            return false, "Invalid storage type"
        end
        
        if currentSlots >= maxSlots then
            return false, "Maximum slots reached"
        end
        
        local playerCredits = KYBER:GetPlayerData(ply, "credits") or 0
        if playerCredits < cost then
            return false, "Insufficient credits"
        end
        
        -- Upgrade
        KYBER:SetPlayerData(ply, "credits", playerCredits - cost)
        
        if storageType == "personal" then
            ply.KyberBanking.slots = ply.KyberBanking.slots + 10
            self:Save(ply)
        else
            KYBER.Banking.FactionStorage[factionID].slots = KYBER.Banking.FactionStorage[factionID].slots + 10
            self:SaveFactionStorage(factionID)
        end
        
        return true
    end
    
    -- Transfer between players
    function KYBER.Banking:TransferCredits(sender, recipientName, amount)
        amount = math.floor(amount)
        if amount <= 0 then return false, "Invalid amount" end
        
        -- Find recipient
        local recipient = nil
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetNWString("kyber_name", ply:Nick()) == recipientName then
                recipient = ply
                break
            end
        end
        
        if not recipient then
            return false, "Recipient not found"
        end
        
        if sender == recipient then
            return false, "Cannot transfer to yourself"
        end
        
        -- Check sender balance
        if sender.KyberBanking.credits < amount then
            return false, "Insufficient funds"
        end
        
        -- Transfer
        sender.KyberBanking.credits = sender.KyberBanking.credits - amount
        recipient.KyberBanking.credits = (recipient.KyberBanking.credits or 0) + amount
        
        -- Save both
        self:Save(sender)
        self:Save(recipient)
        
        -- Notify
        sender:ChatPrint("Transferred " .. amount .. " credits to " .. recipientName)
        recipient:ChatPrint("Received " .. amount .. " credits from " .. sender:GetNWString("kyber_name", sender:Nick()))
        
        return true
    end
    
    -- Network handlers
    net.Receive("Kyber_Banking_Deposit", function(len, ply)
        local amount = net.ReadInt(32)
        local storageType = net.ReadString()
        local factionID = net.ReadString()
        
        local success, err = KYBER.Banking:DepositCredits(ply, amount, storageType, factionID ~= "" and factionID or nil)
        
        if success then
            ply:ChatPrint("Deposited " .. amount .. " credits")
            KYBER.Banking:SendUpdate(ply)
        else
            ply:ChatPrint("Deposit failed: " .. err)
        end
    end)
    
    net.Receive("Kyber_Banking_Withdraw", function(len, ply)
        local amount = net.ReadInt(32)
        local storageType = net.ReadString()
        local factionID = net.ReadString()
        
        local success, err = KYBER.Banking:WithdrawCredits(ply, amount, storageType, factionID ~= "" and factionID or nil)
        
        if success then
            ply:ChatPrint("Withdrew " .. amount .. " credits")
            KYBER.Banking:SendUpdate(ply)
        else
            ply:ChatPrint("Withdrawal failed: " .. err)
        end
    end)
    
    net.Receive("Kyber_Banking_Transfer", function(len, ply)
        local recipient = net.ReadString()
        local amount = net.ReadInt(32)
        
        local success, err = KYBER.Banking:TransferCredits(ply, recipient, amount)
        
        if not success then
            ply:ChatPrint("Transfer failed: " .. err)
        end
        
        KYBER.Banking:SendUpdate(ply)
    end)
    
    net.Receive("Kyber_Banking_UpgradeSlots", function(len, ply)
        local storageType = net.ReadString()
        local factionID = net.ReadString()
        
        local success, err = KYBER.Banking:UpgradeSlots(ply, storageType, factionID ~= "" and factionID or nil)
        
        if success then
            ply:ChatPrint("Storage upgraded!")
            KYBER.Banking:SendUpdate(ply)
        else
            ply:ChatPrint("Upgrade failed: " .. err)
        end
    end)
    
    -- Send banking data to client
    function KYBER.Banking:SendUpdate(ply)
        net.Start("Kyber_Banking_Update")
        net.WriteTable(ply.KyberBanking)
        
        -- Include faction storage if applicable
        local faction = ply:GetNWString("kyber_faction", "")
        if faction ~= "" and KYBER.Banking.FactionStorage[faction] then
            net.WriteBool(true)
            net.WriteTable(KYBER.Banking.FactionStorage[faction])
        else
            net.WriteBool(false)
        end
        
        net.Send(ply)
    end
    
    -- Hooks
    hook.Add("PlayerInitialSpawn", "KyberBankingInit", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                KYBER.Banking:Initialize(ply)
            end
        end)
    end)
    
    hook.Add("PlayerDisconnected", "KyberBankingSave", function(ply)
        KYBER.Banking:Save(ply)
    end)
    
    -- Periodic save
    timer.Create("KyberBankingSave", 300, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            KYBER.Banking:Save(ply)
        end
        
        -- Save faction storages
        if KYBER.Banking.FactionStorage then
            for factionID, _ in pairs(KYBER.Banking.FactionStorage) do
                KYBER.Banking:SaveFactionStorage(factionID)
            end
        end
    end)
    
else -- CLIENT
    
    local BankingFrame = nil
    
    net.Receive("Kyber_Banking_Open", function()
        local terminal = net.ReadEntity()
        local terminalType = net.ReadString()
        
        KYBER.Banking:OpenUI(terminal, terminalType)
    end)
    
    net.Receive("Kyber_Banking_Update", function()
        local personalData = net.ReadTable()
        local hasFaction = net.ReadBool()
        local factionData = hasFaction and net.ReadTable() or nil
        
        LocalPlayer().KyberBanking = personalData
        LocalPlayer().KyberFactionBanking = factionData
        
        if IsValid(BankingFrame) then
            KYBER.Banking:RefreshUI()
        end
    end)
    
    function KYBER.Banking:OpenUI(terminal, terminalType)
        if IsValid(BankingFrame) then BankingFrame:Remove() end
        
        BankingFrame = vgui.Create("DFrame")
        BankingFrame:SetSize(900, 600)
        BankingFrame:Center()
        BankingFrame:SetTitle("Banking Terminal")
        BankingFrame:MakePopup()
        
        local sheet = vgui.Create("DPropertySheet", BankingFrame)
        sheet:Dock(FILL)
        sheet:DockMargin(10, 10, 10, 10)
        
        -- Personal banking tab
        local personalPanel = vgui.Create("DPanel", sheet)
        self:CreatePersonalBankingPanel(personalPanel)
        sheet:AddSheet("Personal Vault", personalPanel, "icon16/lock.png")
        
        -- Faction banking tab (if in faction)
        local faction = LocalPlayer():GetNWString("kyber_faction", "")
        if faction ~= "" then
            local factionPanel = vgui.Create("DPanel", sheet)
            self:CreateFactionBankingPanel(factionPanel, faction)
            sheet:AddSheet("Faction Treasury", factionPanel, "icon16/group.png")
        end
        
        -- Transfer tab
        local transferPanel = vgui.Create("DPanel", sheet)
        self:CreateTransferPanel(transferPanel)
        sheet:AddSheet("Transfer", transferPanel, "icon16/arrow_right.png")
        
        -- Request initial data
        net.Start("Kyber_Banking_Update")
        net.SendToServer()
    end
    
    function KYBER.Banking:CreatePersonalBankingPanel(parent)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        end
        
        -- Credit display
        local creditPanel = vgui.Create("DPanel", parent)
        creditPanel:Dock(TOP)
        creditPanel:SetTall(80)
        creditPanel:DockMargin(10, 10, 10, 10)
        
        creditPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
            
            local bankData = LocalPlayer().KyberBanking or {}
            local balance = bankData.credits or 0
            local wallet = LocalPlayer():GetNWString("kyberdata_credits", "0")
            
            draw.SimpleText("Bank Balance: " .. balance .. " credits", "DermaLarge", 20, 20, Color(100, 255, 100))
            draw.SimpleText("Wallet: " .. wallet .. " credits", "DermaDefault", 20, 50, Color(200, 200, 200))
            
            -- Slot info
            local slots = bankData.slots or KYBER.Banking.Config.personalSlots
            local usedSlots = 0
            for _, item in pairs(bankData.storage or {}) do
                if item then usedSlots = usedSlots + 1 end
            end
            
            draw.SimpleText("Storage: " .. usedSlots .. "/" .. slots .. " slots", "DermaDefault", w - 200, 30, Color(200, 200, 200))
        end
        
        -- Deposit/Withdraw controls
        local controlPanel = vgui.Create("DPanel", parent)
        controlPanel:Dock(TOP)
        controlPanel:SetTall(40)
        controlPanel:DockMargin(10, 0, 10, 10)
        controlPanel.Paint = function() end
        
        local amountEntry = vgui.Create("DNumberWang", controlPanel)
        amountEntry:Dock(LEFT)
        amountEntry:SetWide(150)
        amountEntry:SetMin(0)
        amountEntry:SetMax(999999)
        amountEntry:SetValue(0)
        
        local depositBtn = vgui.Create("DButton", controlPanel)
        depositBtn:SetText("Deposit")
        depositBtn:Dock(LEFT)
        depositBtn:SetWide(100)
        depositBtn:DockMargin(10, 0, 0, 0)
        
        depositBtn.DoClick = function()
            local amount = amountEntry:GetValue()
            if amount > 0 then
                net.Start("Kyber_Banking_Deposit")
                net.WriteInt(amount, 32)
                net.WriteString("personal")
                net.WriteString("")
                net.SendToServer()
            end
        end
        
        local withdrawBtn = vgui.Create("DButton", controlPanel)
        withdrawBtn:SetText("Withdraw")
        withdrawBtn:Dock(LEFT)
        withdrawBtn:SetWide(100)
        withdrawBtn:DockMargin(10, 0, 0, 0)
        
        withdrawBtn.DoClick = function()
            local amount = amountEntry:GetValue()
            if amount > 0 then
                net.Start("Kyber_Banking_Withdraw")
                net.WriteInt(amount, 32)
                net.WriteString("personal")
                net.WriteString("")
                net.SendToServer()
            end
        end
        
        local upgradeBtn = vgui.Create("DButton", controlPanel)
        upgradeBtn:SetText("Upgrade Storage (+10 slots)")
        upgradeBtn:Dock(RIGHT)
        upgradeBtn:SetWide(200)
        
        upgradeBtn.DoClick = function()
            Derma_Query(
                "Upgrade storage for " .. KYBER.Banking.Config.slotUpgradeCost .. " credits?",
                "Confirm Upgrade",
                "Yes", function()
                    net.Start("Kyber_Banking_UpgradeSlots")
                    net.WriteString("personal")
                    net.WriteString("")
                    net.SendToServer()
                end,
                "No", function() end
            )
        end
        
        -- Storage grid
        local storageScroll = vgui.Create("DScrollPanel", parent)
        storageScroll:Dock(FILL)
        storageScroll:DockMargin(10, 0, 10, 10)
        
        local storageGrid = vgui.Create("DGrid", storageScroll)
        storageGrid:SetPos(10, 10)
        storageGrid:SetCols(10)
        storageGrid:SetColWide(52)
        storageGrid:SetRowHeight(52)
        
        -- Create storage slots
        local bankData = LocalPlayer().KyberBanking or {}
        local slots = bankData.slots or KYBER.Banking.Config.personalSlots
        
        for i = 1, slots do
            local slot = vgui.Create("DPanel")
            slot:SetSize(50, 50)
            slot.slotID = i
            
            slot.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50))
                
                if self:IsHovered() then
                    draw.RoundedBox(4, 0, 0, w, h, Color(100, 100, 100, 50))
                end
                
                -- Draw item
                local storage = LocalPlayer().KyberBanking and LocalPlayer().KyberBanking.storage or {}
                local itemData = storage[i]
                
                if itemData then
                    local item = KYBER.GrandExchange.Items[itemData.id]
                    if item then
                        draw.RoundedBox(4, 5, 5, w-10, h-10, Color(100, 100, 100))
                        
                        local name = string.sub(item.name, 1, 8)
                        draw.SimpleText(name, "Default", w/2, h/2 - 5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        
                        if itemData.amount > 1 then
                            draw.SimpleText(itemData.amount, "DermaDefault", w-5, h-5, Color(255, 255, 0), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
                        end
                    end
                end
            end
            
            -- Make slots interactive
            slot:Receiver("inventory_item", function(self, panels, dropped)
                if dropped then
                    local fromPanel = panels[1]
                    if fromPanel.itemData and fromPanel.fromSlot then
                        -- Store item from inventory
                        net.Start("Kyber_Banking_StoreItem")
                        net.WriteString(fromPanel.itemData.id)
                        net.WriteInt(fromPanel.itemData.amount, 16)
                        net.WriteInt(self.slotID, 8)
                        net.WriteString("personal")
                        net.WriteString("")
                        net.SendToServer()
                    end
                end
            end)
            
            slot.DoRightClick = function(self)
                local storage = LocalPlayer().KyberBanking and LocalPlayer().KyberBanking.storage or {}
                local itemData = storage[self.slotID]
                
                if itemData then
                    local menu = DermaMenu()
                    
                    menu:AddOption("Retrieve All", function()
                        net.Start("Kyber_Banking_RetrieveItem")
                        net.WriteInt(self.slotID, 8)
                        net.WriteInt(itemData.amount, 16)
                        net.WriteString("personal")
                        net.WriteString("")
                        net.SendToServer()
                    end):SetIcon("icon16/arrow_down.png")
                    
                    if itemData.amount > 1 then
                        menu:AddOption("Retrieve Amount...", function()
                            Derma_StringRequest("Retrieve Items", "Amount to retrieve:", "1",
                                function(text)
                                    local amount = tonumber(text)
                                    if amount and amount > 0 then
                                        net.Start("Kyber_Banking_RetrieveItem")
                                        net.WriteInt(self.slotID, 8)
                                        net.WriteInt(amount, 16)
                                        net.WriteString("personal")
                                        net.WriteString("")
                                        net.SendToServer()
                                    end
                                end
                            )
                        end):SetIcon("icon16/arrow_divide.png")
                    end
                    
                    menu:Open()
                end
            end
            
            storageGrid:AddItem(slot)
        end
    end
    
    function KYBER.Banking:CreateFactionBankingPanel(parent, factionID)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        end
        
        -- Similar to personal but for faction
        local creditPanel = vgui.Create("DPanel", parent)
        creditPanel:Dock(TOP)
        creditPanel:SetTall(100)
        creditPanel:DockMargin(10, 10, 10, 10)
        
        creditPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
            
            local factionData = LocalPlayer().KyberFactionBanking or {}
            local balance = factionData.credits or 0
            
            local faction = KYBER.Factions[factionID]
            local factionName = faction and faction.name or factionID
            
            draw.SimpleText(factionName .. " Treasury", "DermaLarge", 20, 10, Color(255, 255, 255))
            draw.SimpleText("Balance: " .. balance .. " credits", "DermaDefaultBold", 20, 40, Color(100, 255, 100))
            
            -- Access level
            local rank = LocalPlayer():GetNWString("kyber_rank", "")
            local accessLevel = factionData.accessLevels and factionData.accessLevels[rank] or "none"
            
            local accessColor = Color(255, 100, 100)
            if accessLevel == "deposit" then
                accessColor = Color(255, 255, 100)
            elseif accessLevel == "full" then
                accessColor = Color(100, 255, 100)
            end
            
            draw.SimpleText("Your Access: " .. accessLevel, "DermaDefault", 20, 65, accessColor)
            
            -- Slot info
            local slots = factionData.slots or KYBER.Banking.Config.factionBaseSlots
            draw.SimpleText("Storage: " .. slots .. " slots", "DermaDefault", w - 200, 40, Color(200, 200, 200))
        end
        
        -- Controls (similar to personal)
        local controlPanel = vgui.Create("DPanel", parent)
        controlPanel:Dock(TOP)
        controlPanel:SetTall(40)
        controlPanel:DockMargin(10, 0, 10, 10)
        controlPanel.Paint = function() end
        
        local amountEntry = vgui.Create("DNumberWang", controlPanel)
        amountEntry:Dock(LEFT)
        amountEntry:SetWide(150)
        amountEntry:SetMin(0)
        amountEntry:SetMax(999999)
        amountEntry:SetValue(0)
        
        local depositBtn = vgui.Create("DButton", controlPanel)
        depositBtn:SetText("Deposit")
        depositBtn:Dock(LEFT)
        depositBtn:SetWide(100)
        depositBtn:DockMargin(10, 0, 0, 0)
        
        depositBtn.DoClick = function()
            local amount = amountEntry:GetValue()
            if amount > 0 then
                net.Start("Kyber_Banking_Deposit")
                net.WriteInt(amount, 32)
                net.WriteString("faction")
                net.WriteString(factionID)
                net.SendToServer()
            end
        end
        
        local withdrawBtn = vgui.Create("DButton", controlPanel)
        withdrawBtn:SetText("Withdraw")
        withdrawBtn:Dock(LEFT)
        withdrawBtn:SetWide(100)
        withdrawBtn:DockMargin(10, 0, 0, 0)
        
        withdrawBtn.DoClick = function()
            local amount = amountEntry:GetValue()
            if amount > 0 then
                net.Start("Kyber_Banking_Withdraw")
                net.WriteInt(amount, 32)
                net.WriteString("faction")
                net.WriteString(factionID)
                net.SendToServer()
            end
        end
        
        -- Transaction log
        local logLabel = vgui.Create("DLabel", parent)
        logLabel:SetText("Recent Transactions:")
        logLabel:SetFont("DermaDefaultBold")
        logLabel:Dock(TOP)
        logLabel:DockMargin(10, 0, 10, 5)
        
        local logScroll = vgui.Create("DScrollPanel", parent)
        logScroll:Dock(FILL)
        logScroll:DockMargin(10, 0, 10, 10)
        
        local factionData = LocalPlayer().KyberFactionBanking or {}
        local logs = factionData.logs or {}
        
        -- Show last 20 transactions
        for i = math.max(1, #logs - 20), #logs do
            local log = logs[i]
            if log then
                local logPanel = vgui.Create("DPanel", logScroll)
                logPanel:Dock(TOP)
                logPanel:DockMargin(0, 0, 0, 2)
                logPanel:SetTall(25)
                
                logPanel.Paint = function(self, w, h)
                    draw.RoundedBox(2, 0, 0, w, h, Color(40, 40, 40))
                    
                    local actionColor = log.action == "deposit" and Color(100, 255, 100) or Color(255, 100, 100)
                    local actionText = log.action == "deposit" and "+" or "-"
                    
                    draw.SimpleText(os.date("%m/%d %H:%M", log.time), "DermaDefault", 5, h/2, Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(log.player, "DermaDefault", 120, h/2, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(actionText .. log.amount, "DermaDefault", w - 100, h/2, actionColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
        end
    end
    
    function KYBER.Banking:CreateTransferPanel(parent)
        parent.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        end
        
        -- Instructions
        local info = vgui.Create("DLabel", parent)
        info:SetText("Transfer credits from your bank account to another player's bank account.")
        info:SetWrap(true)
        info:SetAutoStretchVertical(true)
        info:Dock(TOP)
        info:DockMargin(20, 20, 20, 20)
        
        -- Transfer form
        local formPanel = vgui.Create("DPanel", parent)
        formPanel:Dock(TOP)
        formPanel:SetTall(200)
        formPanel:DockMargin(20, 0, 20, 20)
        
        formPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
        end
        
        -- Recipient
        local recipLabel = vgui.Create("DLabel", formPanel)
        recipLabel:SetText("Recipient Character Name:")
        recipLabel:SetPos(20, 20)
        recipLabel:SizeToContents()
        
        local recipEntry = vgui.Create("DTextEntry", formPanel)
        recipEntry:SetPos(20, 40)
        recipEntry:SetSize(300, 25)
        recipEntry:SetPlaceholderText("Enter character name...")
        
        -- Amount
        local amountLabel = vgui.Create("DLabel", formPanel)
        amountLabel:SetText("Amount:")
        amountLabel:SetPos(20, 80)
        amountLabel:SizeToContents()
        
        local amountEntry = vgui.Create("DNumberWang", formPanel)
        amountEntry:SetPos(20, 100)
        amountEntry:SetSize(300, 25)
        amountEntry:SetMin(1)
        amountEntry:SetMax(999999)
        
        -- Balance display
        local balanceLabel = vgui.Create("DLabel", formPanel)
        balanceLabel:SetPos(20, 140)
        balanceLabel:SetSize(300, 20)
        
        balanceLabel.Think = function(self)
            local bankData = LocalPlayer().KyberBanking or {}
            local balance = bankData.credits or 0
            self:SetText("Your bank balance: " .. balance .. " credits")
        end
        
        -- Transfer button
        local transferBtn = vgui.Create("DButton", formPanel)
        transferBtn:SetText("Transfer Credits")
        transferBtn:SetPos(350, 100)
        transferBtn:SetSize(150, 40)
        
        transferBtn.DoClick = function()
            local recipient = recipEntry:GetValue()
            local amount = amountEntry:GetValue()
            
            if recipient == "" then
                LocalPlayer():ChatPrint("Please enter a recipient name")
                return
            end
            
            if amount <= 0 then
                LocalPlayer():ChatPrint("Please enter a valid amount")
                return
            end
            
            Derma_Query(
                "Transfer " .. amount .. " credits to " .. recipient .. "?",
                "Confirm Transfer",
                "Yes", function()
                    net.Start("Kyber_Banking_Transfer")
                    net.WriteString(recipient)
                    net.WriteInt(amount, 32)
                    net.SendToServer()
                    
                    recipEntry:SetValue("")
                    amountEntry:SetValue(0)
                end,
                "No", function() end
            )
        end
    end
    
    function KYBER.Banking:RefreshUI()
        -- This would refresh the UI with new data
        -- For now, just close and reopen
        if IsValid(BankingFrame) then
            local terminal = BankingFrame.terminal
            local terminalType = BankingFrame.terminalType
            BankingFrame:Close()
            self:OpenUI(terminal, terminalType)
        end
    end
end

-- Add missing network strings
if SERVER then
    util.AddNetworkString("Kyber_Banking_StoreItem")
    util.AddNetworkString("Kyber_Banking_RetrieveItem")
    
    net.Receive("Kyber_Banking_StoreItem", function(len, ply)
        local itemID = net.ReadString()
        local amount = net.ReadInt(16)
        local slot = net.ReadInt(8)
        local storageType = net.ReadString()
        local factionID = net.ReadString()
        
        local success, err = KYBER.Banking:StoreItem(
            ply, 
            itemID, 
            amount, 
            slot, 
            storageType, 
            factionID ~= "" and factionID or nil
        )
        
        if success then
            ply:ChatPrint("Item stored")
            KYBER.Banking:SendUpdate(ply)
        else
            ply:ChatPrint("Storage failed: " .. err)
        end
    end)
    
    net.Receive("Kyber_Banking_RetrieveItem", function(len, ply)
        local slot = net.ReadInt(8)
        local amount = net.ReadInt(16)
        local storageType = net.ReadString()
        local factionID = net.ReadString()
        
        local success, err = KYBER.Banking:RetrieveItem(
            ply,
            slot,
            amount,
            storageType,
            factionID ~= "" and factionID or nil
        )
        
        if success then
            ply:ChatPrint("Item retrieved")
            KYBER.Banking:SendUpdate(ply)
            KYBER.Inventory:SendInventoryUpdate(ply)
        else
            ply:ChatPrint("Retrieval failed: " .. err)
        end
    end)
end

function KYBER.Banking:GetCachedData(ply)
    return KYBER.Optimization.GetCached("banking", ply:SteamID64(), function()
        return {
            personal = ply.KyberBanking,
            faction = KYBER.Banking.FactionStorage[ply:GetNWString("kyber_faction", "")]
        }
    end)
end
            