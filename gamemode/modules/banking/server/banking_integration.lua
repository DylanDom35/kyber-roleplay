-- kyber/modules/banking/integration.lua
-- Integration with other systems

-- Add banking info to datapad
if CLIENT then
    hook.Add("Kyber_Datapad_AddTabs", "AddBankingTab", function(tabSheet)
        local bankPanel = vgui.Create("DPanel", tabSheet)
        bankPanel:Dock(FILL)
        
        bankPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20))
        end
        
        -- Title
        local title = vgui.Create("DLabel", bankPanel)
        title:SetText("Banking & Storage")
        title:SetFont("DermaLarge")
        title:Dock(TOP)
        title:DockMargin(20, 20, 20, 10)
        title:SetContentAlignment(5)
        
        -- Personal banking info
        local personalPanel = vgui.Create("DPanel", bankPanel)
        personalPanel:Dock(TOP)
        personalPanel:DockMargin(20, 0, 20, 20)
        personalPanel:SetTall(150)
        
        personalPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            
            local bankData = LocalPlayer().KyberBanking or {}
            
            draw.SimpleText("Personal Banking", "DermaDefaultBold", 10, 10, Color(255, 255, 255))
            
            -- Balance
            local balance = bankData.credits or 0
            draw.SimpleText("Bank Balance: " .. balance .. " credits", "DermaDefault", 20, 35, Color(100, 255, 100))
            
            -- Interest rate
            local interest = KYBER.Banking.Config.interestRate * 100
            draw.SimpleText("Daily Interest: " .. interest .. "%", "DermaDefault", 20, 55, Color(200, 200, 200))
            
            -- Storage
            local slots = bankData.slots or KYBER.Banking.Config.personalSlots
            local used = 0
            for _, item in pairs(bankData.storage or {}) do
                if item then used = used + 1 end
            end
            
            draw.SimpleText("Storage: " .. used .. "/" .. slots .. " slots used", "DermaDefault", 20, 75, Color(200, 200, 200))
            
            -- Security level
            local security = bankData.security or 1
            draw.SimpleText("Security Level: " .. security, "DermaDefault", 20, 95, Color(200, 200, 200))
            
            -- Rented boxes
            local boxes = bankData.rentedBoxes or {}
            draw.SimpleText("Safety Deposit Boxes: " .. #boxes, "DermaDefault", 20, 115, Color(200, 200, 200))
        end
        
        -- Faction banking info
        local faction = LocalPlayer():GetNWString("kyber_faction", "")
        if faction ~= "" then
            local factionPanel = vgui.Create("DPanel", bankPanel)
            factionPanel:Dock(TOP)
            factionPanel:DockMargin(20, 0, 20, 20)
            factionPanel:SetTall(120)
            
            factionPanel.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
                
                local factionData = LocalPlayer().KyberFactionBanking or {}
                local factionInfo = KYBER.Factions[faction]
                
                draw.SimpleText("Faction Treasury", "DermaDefaultBold", 10, 10, Color(255, 255, 255))
                
                if factionInfo then
                    draw.SimpleText(factionInfo.name, "DermaDefault", 20, 35, factionInfo.color or Color(200, 200, 200))
                end
                
                -- Balance
                local balance = factionData.credits or 0
                draw.SimpleText("Treasury: " .. balance .. " credits", "DermaDefault", 20, 55, Color(100, 255, 100))
                
                -- Access level
                local rank = LocalPlayer():GetNWString("kyber_rank", "")
                local access = factionData.accessLevels and factionData.accessLevels[rank] or "none"
                
                local accessColor = Color(255, 100, 100)
                if access == "deposit" then
                    accessColor = Color(255, 255, 100)
                elseif access == "full" then
                    accessColor = Color(100, 255, 100)
                end
                
                draw.SimpleText("Your Access: " .. access, "DermaDefault", 20, 75, accessColor)
                
                -- Storage
                local slots = factionData.slots or KYBER.Banking.Config.factionBaseSlots
                draw.SimpleText("Storage Capacity: " .. slots .. " slots", "DermaDefault", 20, 95, Color(200, 200, 200))
            end
        end
        
        -- Banking tips
        local tipsPanel = vgui.Create("DPanel", bankPanel)
        tipsPanel:Dock(TOP)
        tipsPanel:DockMargin(20, 0, 20, 20)
        tipsPanel:SetTall(100)
        
        tipsPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            
            draw.SimpleText("Banking Tips:", "DermaDefaultBold", 10, 10, Color(255, 255, 255))
            draw.SimpleText("• Store valuable items in your bank vault for safekeeping", "DermaDefault", 20, 30, Color(200, 200, 200))
            draw.SimpleText("• Deposit credits to earn daily interest", "DermaDefault", 20, 48, Color(200, 200, 200))
            draw.SimpleText("• Faction treasuries can fund group projects", "DermaDefault", 20, 66, Color(200, 200, 200))
        end
        
        tabSheet:AddSheet("Banking", bankPanel, "icon16/money.png")
    end)
end

-- Character sheet integration
if SERVER then
    hook.Add("Kyber_CharacterSheet_AddInfo", "AddBankingInfo", function(ply)
        local info = {}
        
        local bankData = ply.KyberBanking or {}
        
        table.insert(info, {
            label = "Bank Balance",
            value = (bankData.credits or 0) .. " credits"
        })
        
        table.insert(info, {
            label = "Storage Slots",
            value = tostring(bankData.slots or KYBER.Banking.Config.personalSlots)
        })
        
        return info
    end)
end

-- Grand Exchange integration - allow direct deposits from sales
if SERVER then
    hook.Add("Kyber_GrandExchange_ItemSold", "BankingDirectDeposit", function(seller, amount)
        -- Option to deposit directly to bank
        if seller:GetNWBool("kyber_auto_deposit", false) then
            local bankData = seller.KyberBanking
            if bankData then
                bankData.credits = bankData.credits + amount
                KYBER.Banking:Save(seller)
                
                seller:ChatPrint("Sale proceeds deposited directly to bank: " .. amount .. " credits")
                return true -- Prevent adding to wallet
            end
        end
    end)
end

-- Death penalty - lose carried credits but not banked
if SERVER then
    hook.Add("PlayerDeath", "BankingDeathProtection", function(victim, inflictor, attacker)
        local credits = KYBER:GetPlayerData(victim, "credits") or 0
        
        if credits > 0 then
            -- Drop a percentage of carried credits
            local dropPercent = 0.1 -- 10% of carried credits
            local dropped = math.floor(credits * dropPercent)
            
            if dropped > 0 then
                KYBER:SetPlayerData(victim, "credits", credits - dropped)
                
                -- Create dropped credits entity (if you have one)
                -- Or give to attacker
                if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
                    local attackerCredits = KYBER:GetPlayerData(attacker, "credits") or 0
                    KYBER:SetPlayerData(attacker, "credits", attackerCredits + dropped)
                    
                    attacker:ChatPrint("Looted " .. dropped .. " credits")
                end
                
                victim:ChatPrint("You lost " .. dropped .. " credits! (Bank deposits are safe)")
            end
        end
    end)
end

-- Crafting integration - pay from bank
if SERVER then
    hook.Add("Kyber_Crafting_PayForRecipe", "BankingCraftingPayment", function(ply, cost)
        -- Try wallet first
        local walletCredits = KYBER:GetPlayerData(ply, "credits") or 0
        
        if walletCredits >= cost then
            return true -- Can pay from wallet
        end
        
        -- Try bank
        local bankData = ply.KyberBanking
        if bankData and bankData.credits >= cost then
            -- Offer to pay from bank
            ply:ChatPrint("Insufficient wallet funds. Pay " .. cost .. " from bank? (Type /confirm)")
            
            ply.PendingBankPayment = {
                amount = cost,
                reason = "crafting",
                expires = CurTime() + 30
            }
            
            return false
        end
        
        return false
    end)
end

-- Shop system integration
if SERVER then
    -- Create simple shop entity
    local ENT = {}
    ENT.Type = "anim"
    ENT.Base = "base_gmodentity"
    ENT.PrintName = "Player Shop"
    ENT.Author = "Kyber"
    ENT.Spawnable = true
    ENT.Category = "Kyber RP"
    
    function ENT:SetupDataTables()
        self:NetworkVar("Entity", 0, "ShopOwner")
        self:NetworkVar("String", 0, "ShopName")
    end
    
    function ENT:Initialize()
        self:SetModel("models/props_c17/cashregister01a.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
        
        self.Storage = {}
        self.Prices = {}
    end
    
    function ENT:Use(activator, caller)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        
        if activator == self:GetShopOwner() then
            -- Owner menu
            activator:ChatPrint("Opening shop management...")
            -- Would open shop management UI
        else
            -- Customer menu
            activator:ChatPrint("Welcome to " .. self:GetShopName())
            -- Would open shop buying UI
        end
    end
    
    scripted_ents.Register(ENT, "kyber_player_shop")
end

-- Faction permissions for banking
if SERVER then
    hook.Add("Kyber_Faction_SetRank", "UpdateBankingPermissions", function(ply, faction, newRank)
        -- Update banking permissions based on rank
        local storage = KYBER.Banking.FactionStorage[faction]
        if not storage then return end
        
        -- Example rank permissions
        local rankPermissions = {
            ["Leader"] = "full",
            ["Officer"] = "full",
            ["Member"] = "deposit",
            ["Recruit"] = "none"
        }
        
        -- Set access level
        storage.accessLevels = storage.accessLevels or {}
        storage.accessLevels[newRank] = rankPermissions[newRank] or "none"
        
        KYBER.Banking:SaveFactionStorage(faction)
    end)
end

-- Admin commands
if SERVER then
    concommand.Add("kyber_bank_give", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local target = args[1] and player.GetBySteamID(args[1]) or ply
        local amount = tonumber(args[2]) or 1000
        
        if IsValid(target) then
            target.KyberBanking = target.KyberBanking or {}
            target.KyberBanking.credits = (target.KyberBanking.credits or 0) + amount
            KYBER.Banking:Save(target)
            
            ply:ChatPrint("Gave " .. amount .. " bank credits to " .. target:Nick())
            target:ChatPrint("An admin deposited " .. amount .. " credits to your bank")
        end
    end)
    
    concommand.Add("kyber_bank_set_faction_access", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local faction = args[1]
        local rank = args[2]
        local access = args[3] -- none, deposit, full
        
        if not faction or not rank or not access then
            ply:ChatPrint("Usage: kyber_bank_set_faction_access <faction> <rank> <none|deposit|full>")
            return
        end
        
        KYBER.Banking:LoadFactionStorage(faction)
        local storage = KYBER.Banking.FactionStorage[faction]
        
        if storage then
            storage.accessLevels = storage.accessLevels or {}
            storage.accessLevels[rank] = access
            KYBER.Banking:SaveFactionStorage(faction)
            
            ply:ChatPrint("Set " .. faction .. " " .. rank .. " banking access to: " .. access)
        end
    end)
end

-- HUD indicator for bank notifications
if CLIENT then
    local bankNotifications = {}
    
    hook.Add("HUDPaint", "KyberBankingNotifications", function()
        local y = ScrH() - 300
        
        for i, notif in ipairs(bankNotifications) do
            if CurTime() < notif.expires then
                local alpha = math.min(255, (notif.expires - CurTime()) * 255)
                
                draw.SimpleText(notif.text, "DermaDefault", 10, y, Color(255, 215, 0, alpha))
                y = y - 20
            else
                table.remove(bankNotifications, i)
            end
        end
    end)
    
    -- Add notification function
    function KYBER.Banking:AddNotification(text)
        table.insert(bankNotifications, {
            text = text,
            expires = CurTime() + 5
        })
    end
end

-- Console command to check bank status
if CLIENT then
    concommand.Add("kyber_bank_status", function()
        local bankData = LocalPlayer().KyberBanking or {}
        
        print("=== Banking Status ===")
        print("Balance: " .. (bankData.credits or 0) .. " credits")
        print("Storage: " .. (bankData.slots or KYBER.Banking.Config.personalSlots) .. " slots")
        print("Security Level: " .. (bankData.security or 1))
        
        local used = 0
        for _, item in pairs(bankData.storage or {}) do
            if item then used = used + 1 end
        end
        print("Items Stored: " .. used)
        
        local faction = LocalPlayer():GetNWString("kyber_faction", "")
        if faction ~= "" then
            print("\n=== Faction Banking ===")
            local factionData = LocalPlayer().KyberFactionBanking or {}
            print("Faction Treasury: " .. (factionData.credits or 0) .. " credits")
        end
    end)
end

print("[Kyber] Banking system loaded")