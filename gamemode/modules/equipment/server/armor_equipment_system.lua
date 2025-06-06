-- kyber/modules/equipment/system.lua
KYBER.Equipment = KYBER.Equipment or {}

-- Equipment slots
KYBER.Equipment.Slots = {
    ["head"] = {name = "Head", icon = "icon16/user_gray.png"},
    ["chest"] = {name = "Chest", icon = "icon16/shield.png"},
    ["legs"] = {name = "Legs", icon = "icon16/user_suit.png"},
    ["feet"] = {name = "Feet", icon = "icon16/user_go.png"},
    ["hands"] = {name = "Hands", icon = "icon16/hand_paper.png"},
    ["back"] = {name = "Back", icon = "icon16/arrow_turn_left.png"},
    ["weapon1"] = {name = "Primary Weapon", icon = "icon16/gun.png"},
    ["weapon2"] = {name = "Secondary Weapon", icon = "icon16/bomb.png"},
    ["utility1"] = {name = "Utility 1", icon = "icon16/wrench.png"},
    ["utility2"] = {name = "Utility 2", icon = "icon16/cog.png"}
}

-- Armor definitions
KYBER.Equipment.Items = {
    -- Head armor
    ["helmet_trooper"] = {
        name = "Stormtrooper Helmet",
        description = "Standard Imperial trooper helmet",
        slot = "head",
        icon = "icon16/user_gray.png",
        model = "models/player/stormtrooper/helmet.mdl", -- For future PAC3
        stats = {
            armor = 5,
            accuracy = -2, -- Reduced accuracy (canon joke)
            intimidation = 3
        },
        requirements = {
            faction = "imperial"
        },
        value = 500
    },
    
    ["helmet_mandalorian"] = {
        name = "Mandalorian Helmet",
        description = "Traditional Beskar helmet",
        slot = "head",
        icon = "icon16/user_gray.png",
        model = "models/player/mandalorian/helmet.mdl",
        stats = {
            armor = 15,
            perception = 5,
            intimidation = 10
        },
        requirements = {
            reputation_mandalorian = 100
        },
        value = 5000
    },
    
    -- Chest armor
    ["armor_trooper"] = {
        name = "Stormtrooper Armor",
        description = "Standard Imperial chest plate",
        slot = "chest",
        icon = "icon16/shield.png",
        model = "models/player/stormtrooper/chest.mdl",
        stats = {
            armor = 20,
            speed = -5
        },
        requirements = {
            faction = "imperial"
        },
        value = 1000
    },
    
    ["armor_beskar"] = {
        name = "Beskar Chestplate",
        description = "Nearly indestructible Mandalorian iron",
        slot = "chest",
        icon = "icon16/shield.png",
        model = "models/player/mandalorian/chest.mdl",
        stats = {
            armor = 50,
            blaster_resist = 30,
            speed = -10
        },
        requirements = {
            reputation_mandalorian = 500
        },
        value = 25000
    },
    
    ["armor_jedi_robes"] = {
        name = "Jedi Robes",
        description = "Traditional Jedi garments",
        slot = "chest",
        icon = "icon16/shield.png",
        model = "models/player/jedi/robes.mdl",
        stats = {
            armor = 5,
            force_regen = 10,
            agility = 10,
            stealth = 5
        },
        requirements = {
            force_sensitive = true,
            alignment = "light"
        },
        value = 2000
    },
    
    -- Utility items
    ["jetpack_standard"] = {
        name = "Z-6 Jetpack",
        description = "Personal flight device",
        slot = "back",
        icon = "icon16/arrow_up.png",
        model = "models/equipment/jetpack.mdl",
        stats = {
            flight_time = 10,
            speed = -5
        },
        abilities = {
            "jetpack_flight"
        },
        requirements = {
            skill_piloting = 5
        },
        value = 8000
    },
    
    ["utility_medkit"] = {
        name = "Field Medkit",
        description = "Portable medical supplies",
        slot = "utility1",
        icon = "icon16/heart.png",
        stats = {
            healing_bonus = 20
        },
        abilities = {
            "field_heal"
        },
        value = 1000
    },
    
    ["utility_scanner"] = {
        name = "Life Form Scanner",
        description = "Detects nearby life signs",
        slot = "utility2",
        icon = "icon16/magnifier.png",
        stats = {
            perception = 10,
            scan_range = 500
        },
        abilities = {
            "life_scan"
        },
        value = 2000
    }
}

if SERVER then
    util.AddNetworkString("Kyber_Equipment_Open")
    util.AddNetworkString("Kyber_Equipment_Equip")
    util.AddNetworkString("Kyber_Equipment_Unequip")
    util.AddNetworkString("Kyber_Equipment_Update")
    util.AddNetworkString("Kyber_Equipment_Drop")
    
    -- Initialize equipment for player
    function KYBER.Equipment:Initialize(ply)
        ply.KyberEquipment = {}
        
        -- Load saved equipment
        local steamID = ply:SteamID64()
        local charName = ply:GetNWString("kyber_name", "default")
        local path = "kyber/equipment/" .. steamID .. "_" .. charName .. ".json"
        
        if file.Exists(path, "DATA") then
            local data = file.Read(path, "DATA")
            ply.KyberEquipment = util.JSONToTable(data) or {}
        end
        
        -- Apply equipment stats
        self:RecalculateStats(ply)
    end
    
    function KYBER.Equipment:Save(ply)
        if not IsValid(ply) or not ply.KyberEquipment then return end
        
        local steamID = ply:SteamID64()
        local charName = ply:GetNWString("kyber_name", "default")
        local path = "kyber/equipment/" .. steamID .. "_" .. charName .. ".json"
        
        if not file.Exists("kyber/equipment", "DATA") then
            file.CreateDir("kyber/equipment")
        end
        
        file.Write(path, util.TableToJSON(ply.KyberEquipment))
    end
    
    -- Equip an item
    function KYBER.Equipment:EquipItem(ply, itemID, fromSlot)
        local item = self.Items[itemID]
        if not item then return false, "Invalid item" end
        
        -- Check if player has the item in inventory
        local inventorySlot = ply.KyberInventory[fromSlot]
        if not inventorySlot or inventorySlot.id ~= itemID then
            return false, "Item not in inventory"
        end
        
        -- Check requirements
        local canEquip, reason = self:CheckRequirements(ply, item)
        if not canEquip then
            return false, reason
        end
        
        -- Check if slot is occupied
        local equipmentSlot = item.slot
        if ply.KyberEquipment[equipmentSlot] then
            -- Unequip current item first
            self:UnequipItem(ply, equipmentSlot)
        end
        
        -- Move item from inventory to equipment
        ply.KyberEquipment[equipmentSlot] = {
            id = itemID,
            equipped_at = os.time()
        }
        
        -- Remove from inventory
        ply.KyberInventory[fromSlot] = nil
        
        -- Apply stats and abilities
        self:RecalculateStats(ply)
        
        -- Grant abilities
        if item.abilities then
            for _, ability in ipairs(item.abilities) do
                self:GrantAbility(ply, ability)
            end
        end
        
        -- Update client
        KYBER.Inventory:SendInventoryUpdate(ply)
        self:SendEquipmentUpdate(ply)
        
        -- Save
        self:Save(ply)
        KYBER.Inventory:Save(ply)
        
        return true
    end
    
    -- Unequip an item
    function KYBER.Equipment:UnequipItem(ply, slot)
        local equipped = ply.KyberEquipment[slot]
        if not equipped then return false, "No item equipped" end
        
        local item = self.Items[equipped.id]
        if not item then return false, "Invalid equipped item" end
        
        -- Try to add to inventory
        local success, err = KYBER.Inventory:GiveItem(ply, equipped.id, 1)
        if not success then
            return false, "Cannot unequip: " .. err
        end
        
        -- Remove abilities
        if item.abilities then
            for _, ability in ipairs(item.abilities) do
                self:RemoveAbility(ply, ability)
            end
        end
        
        -- Remove from equipment
        ply.KyberEquipment[slot] = nil
        
        -- Recalculate stats
        self:RecalculateStats(ply)
        
        -- Update client
        self:SendEquipmentUpdate(ply)
        
        -- Save
        self:Save(ply)
        
        return true
    end
    
    -- Check equipment requirements
    function KYBER.Equipment:CheckRequirements(ply, item)
        if not item.requirements then return true end
        
        for req, value in pairs(item.requirements) do
            if req == "faction" then
                if ply:GetNWString("kyber_faction") ~= value then
                    return false, "Wrong faction"
                end
            elseif req == "force_sensitive" then
                if not ply:GetNWBool("kyber_force_sensitive") then
                    return false, "Must be Force sensitive"
                end
            elseif req == "alignment" then
                if ply:GetNWString("kyber_alignment") ~= value then
                    return false, "Wrong alignment"
                end
            elseif string.StartWith(req, "reputation_") then
                local faction = string.sub(req, 12)
                local rep = KYBER:GetPlayerData(ply, "rep_" .. faction) or 0
                if rep < value then
                    return false, "Insufficient " .. faction .. " reputation"
                end
            elseif string.StartWith(req, "skill_") then
                local skill = string.sub(req, 7)
                local level = KYBER:GetPlayerData(ply, "skill_" .. skill) or 0
                if level < value then
                    return false, "Requires " .. skill .. " level " .. value
                end
            end
        end
        
        return true
    end
    
    -- Calculate total stats from equipment
    function KYBER.Equipment:RecalculateStats(ply)
        local stats = {
            armor = 0,
            speed = 0,
            accuracy = 0,
            perception = 0,
            stealth = 0,
            intimidation = 0,
            force_regen = 0,
            agility = 0,
            blaster_resist = 0,
            healing_bonus = 0
        }
        
        -- Sum up all equipment stats
        for slot, equipped in pairs(ply.KyberEquipment) do
            local item = self.Items[equipped.id]
            if item and item.stats then
                for stat, value in pairs(item.stats) do
                    stats[stat] = (stats[stat] or 0) + value
                end
            end
        end
        
        -- Apply stat effects
        self:ApplyStats(ply, stats)
        
        -- Store for reference
        ply.KyberStats = stats
    end
    
    -- Apply stat effects to player
    function KYBER.Equipment:ApplyStats(ply, stats)
        -- Armor
        local baseArmor = 0
        ply:SetArmor(baseArmor + stats.armor)
        
        -- Speed
        local baseSpeed = 200
        local speedMult = 1 + (stats.speed / 100)
        ply:SetWalkSpeed(baseSpeed * speedMult)
        ply:SetRunSpeed(baseSpeed * 2 * speedMult)
        
        -- Other stats would affect various gameplay elements
        -- These can be accessed via ply.KyberStats for other systems
    end
    
    -- Grant ability from equipment
    function KYBER.Equipment:GrantAbility(ply, ability)
        -- This would integrate with your ability system
        -- For now, just store it
        ply.KyberAbilities = ply.KyberAbilities or {}
        ply.KyberAbilities[ability] = true
        
        -- Example abilities
        if ability == "jetpack_flight" then
            -- Give jetpack SWEP or enable jetpack functionality
            -- ply:Give("weapon_jetpack")
        elseif ability == "field_heal" then
            -- Enable healing ability
        elseif ability == "life_scan" then
            -- Enable scanner ability
        end
    end
    
    function KYBER.Equipment:RemoveAbility(ply, ability)
        if ply.KyberAbilities then
            ply.KyberAbilities[ability] = nil
        end
        
        -- Remove specific ability effects
        if ability == "jetpack_flight" then
            -- Remove jetpack functionality
            -- ply:StripWeapon("weapon_jetpack")
        end
    end
    
    -- Network functions
    function KYBER.Equipment:SendEquipmentUpdate(ply)
        net.Start("Kyber_Equipment_Update")
        net.WriteTable(ply.KyberEquipment or {})
        net.WriteTable(ply.KyberStats or {})
        net.Send(ply)
    end
    
    -- Network receivers
    net.Receive("Kyber_Equipment_Equip", function(len, ply)
        local itemID = net.ReadString()
        local fromSlot = net.ReadInt(8)
        
        local success, err = KYBER.Equipment:EquipItem(ply, itemID, fromSlot)
        
        if not success then
            ply:ChatPrint("Cannot equip: " .. err)
        else
            ply:ChatPrint("Equipped " .. KYBER.Equipment.Items[itemID].name)
        end
    end)
    
    net.Receive("Kyber_Equipment_Unequip", function(len, ply)
        local slot = net.ReadString()
        
        local success, err = KYBER.Equipment:UnequipItem(ply, slot)
        
        if not success then
            ply:ChatPrint("Cannot unequip: " .. err)
        end
    end)
    
    -- Hooks
    hook.Add("PlayerInitialSpawn", "KyberEquipmentInit", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                KYBER.Equipment:Initialize(ply)
            end
        end)
    end)
    
    hook.Add("PlayerDisconnected", "KyberEquipmentSave", function(ply)
        KYBER.Equipment:Save(ply)
    end)
    
    -- Commands
    concommand.Add("kyber_equipment", function(ply)
        net.Start("Kyber_Equipment_Open")
        net.WriteTable(ply.KyberEquipment or {})
        net.WriteTable(ply.KyberStats or {})
        net.Send(ply)
    end)
    
else -- CLIENT
    
    local EquipmentPanel = nil
    
    net.Receive("Kyber_Equipment_Open", function()
        local equipment = net.ReadTable()
        local stats = net.ReadTable()
        
        KYBER.Equipment:OpenUI(equipment, stats)
    end)
    
    net.Receive("Kyber_Equipment_Update", function()
        local equipment = net.ReadTable()
        local stats = net.ReadTable()
        
        LocalPlayer().KyberEquipment = equipment
        LocalPlayer().KyberStats = stats
        
        if IsValid(EquipmentPanel) then
            KYBER.Equipment:UpdateUI(equipment, stats)
        end
    end)
    
    function KYBER.Equipment:OpenUI(equipment, stats)
        if IsValid(EquipmentPanel) then
            EquipmentPanel:Remove()
            return
        end
        
        EquipmentPanel = vgui.Create("DFrame")
        EquipmentPanel:SetSize(800, 600)
        EquipmentPanel:Center()
        EquipmentPanel:SetTitle("Equipment")
        EquipmentPanel:MakePopup()
        
        -- Main container
        local container = vgui.Create("DPanel", EquipmentPanel)
        container:Dock(FILL)
        container:DockMargin(10, 10, 10, 10)
        container.Paint = function() end
        
        -- Left side - Character model and slots
        local leftPanel = vgui.Create("DPanel", container)
        leftPanel:Dock(LEFT)
        leftPanel:SetWide(350)
        leftPanel:DockMargin(0, 0, 10, 0)
        
        leftPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        end
        
        -- Character model
        local modelPanel = vgui.Create("DModelPanel", leftPanel)
        modelPanel:SetSize(300, 300)
        modelPanel:SetPos(25, 25)
        modelPanel:SetModel(LocalPlayer():GetModel())
        
        local ent = modelPanel:GetEntity()
        ent:SetSequence(ent:LookupSequence("idle_all_01"))
        
        modelPanel:SetFOV(45)
        modelPanel:SetCamPos(Vector(100, 0, 60))
        modelPanel:SetLookAt(Vector(0, 0, 40))
        
        function modelPanel:LayoutEntity(ent)
            ent:SetAngles(Angle(0, RealTime() * 30, 0))
        end
        
        -- Equipment slots around the model
        local slotPositions = {
            head = {x = 175, y = 50},
            chest = {x = 175, y = 120},
            hands = {x = 100, y = 150},
            legs = {x = 175, y = 190},
            feet = {x = 175, y = 260},
            back = {x = 250, y = 120},
            weapon1 = {x = 25, y = 350},
            weapon2 = {x = 100, y = 350},
            utility1 = {x = 175, y = 350},
            utility2 = {x = 250, y = 350}
        }
        
        EquipmentPanel.slots = {}
        
        for slotID, slotData in pairs(KYBER.Equipment.Slots) do
            local pos = slotPositions[slotID]
            if not pos then continue end
            
            local slot = vgui.Create("DPanel", leftPanel)
            slot:SetPos(pos.x, pos.y)
            slot:SetSize(60, 60)
            slot.slotID = slotID
            
            slot.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50))
                
                if self:IsHovered() then
                    draw.RoundedBox(4, 0, 0, w, h, Color(100, 100, 100, 50))
                end
                
                -- Draw equipped item
                local equipped = equipment[slotID]
                if equipped then
                    local item = KYBER.Equipment.Items[equipped.id]
                    if item then
                        -- Item background
                        draw.RoundedBox(4, 5, 5, w-10, h-10, Color(100, 100, 100))
                        
                        -- Item name
                        draw.SimpleText(string.sub(item.name, 1, 6), "Default", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                else
                    -- Empty slot
                    draw.SimpleText(slotData.name, "Default", w/2, h/2, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
            
            slot:Receiver("equipment_item", function(self, panels, dropped)
                if dropped then
                    local item = panels[1]
                    if item.itemData then
                        net.Start("Kyber_Equipment_Equip")
                        net.WriteString(item.itemData.id)
                        net.WriteInt(item.fromSlot, 8)
                        net.SendToServer()
                    end
                end
            end)
            
            slot.DoRightClick = function(self)
                if equipment[slotID] then
                    local menu = DermaMenu()
                    
                    menu:AddOption("Unequip", function()
                        net.Start("Kyber_Equipment_Unequip")
                        net.WriteString(slotID)
                        net.SendToServer()
                    end):SetIcon("icon16/delete.png")
                    
                    menu:Open()
                end
            end
            
            EquipmentPanel.slots[slotID] = slot
        end
        
        -- Right side - Stats and inventory
        local rightPanel = vgui.Create("DPanel", container)
        rightPanel:Dock(FILL)
        
        rightPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        end
        
        -- Stats display
        local statsPanel = vgui.Create("DPanel", rightPanel)
        statsPanel:Dock(TOP)
        statsPanel:DockMargin(10, 10, 10, 10)
        statsPanel:SetTall(150)
        
        statsPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
            
            draw.SimpleText("Character Stats", "DermaDefaultBold", 10, 10, Color(255, 255, 255))
            
            local y = 30
            local x = 10
            
            for stat, value in pairs(stats or {}) do
                if value ~= 0 then
                    local statName = string.gsub(stat, "_", " ")
                    statName = string.upper(string.sub(statName, 1, 1)) .. string.sub(statName, 2)
                    
                    local color = value > 0 and Color(100, 255, 100) or Color(255, 100, 100)
                    local prefix = value > 0 and "+" or ""
                    
                    draw.SimpleText(statName .. ": " .. prefix .. value, "DermaDefault", x, y, color)
                    
                    y = y + 18
                    if y > 130 then
                        y = 30
                        x = x + 200
                    end
                end
            end
        end
        
        -- Inventory equipment items
        local invLabel = vgui.Create("DLabel", rightPanel)
        invLabel:SetText("Equipment in Inventory:")
        invLabel:SetFont("DermaDefaultBold")
        invLabel:Dock(TOP)
        invLabel:DockMargin(10, 0, 10, 5)
        
        local invScroll = vgui.Create("DScrollPanel", rightPanel)
        invScroll:Dock(FILL)
        invScroll:DockMargin(10, 0, 10, 10)
        
        -- Populate with equipment items from inventory
        local inventory = LocalPlayer().KyberInventory or {}
        
        for slot, itemData in pairs(inventory) do
            if itemData then
                local itemDef = KYBER.Equipment.Items[itemData.id]
                if itemDef then
                    local itemPanel = vgui.Create("DPanel", invScroll)
                    itemPanel:Dock(TOP)
                    itemPanel:DockMargin(0, 0, 0, 5)
                    itemPanel:SetTall(60)
                    itemPanel.itemData = itemData
                    itemPanel.fromSlot = slot
                    
                    itemPanel.Paint = function(self, w, h)
                        draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50))
                        
                        if self:IsHovered() then
                            draw.RoundedBox(4, 0, 0, w, h, Color(100, 100, 100, 50))
                        end
                        
                        -- Item info
                        draw.SimpleText(itemDef.name, "DermaDefaultBold", 10, 10, Color(255, 255, 255))
                        draw.SimpleText("Slot: " .. KYBER.Equipment.Slots[itemDef.slot].name, "DermaDefault", 10, 25, Color(200, 200, 200))
                        
                        -- Stats preview
                        local statText = ""
                        if itemDef.stats then
                            for stat, value in pairs(itemDef.stats) do
                                if value ~= 0 then
                                    local prefix = value > 0 and "+" or ""
                                    statText = statText .. stat .. ": " .. prefix .. value .. " "
                                end
                            end
                        end
                        draw.SimpleText(statText, "DermaDefault", 10, 40, Color(150, 150, 150))
                    end
                    
                    -- Make draggable
                    itemPanel:Droppable("equipment_item")
                    
                    -- Double click to equip
                    itemPanel.DoDoubleClick = function(self)
                        net.Start("Kyber_Equipment_Equip")
                        net.WriteString(self.itemData.id)
                        net.WriteInt(self.fromSlot, 8)
                        net.SendToServer()
                    end
                end
            end
        end
    end
    
    function KYBER.Equipment:UpdateUI(equipment, stats)
        -- Update would refresh the UI with new equipment/stats
        if IsValid(EquipmentPanel) then
            EquipmentPanel:Remove()
            self:OpenUI(equipment, stats)
        end
    end
    
    -- Add keybind
    hook.Add("PlayerButtonDown", "KyberEquipmentKey", function(ply, key)
        if key == KEY_C then
            RunConsoleCommand("kyber_equipment")
        end
    end)
end

function KYBER.Equipment:GetCachedStats(ply)
    return KYBER.Optimization.GetCached("equipment_stats", ply:SteamID64(), function()
        return self:CalculateStats(ply)
    end)
end

function KYBER.Equipment:CalculateStats(ply)
    local stats = {
        armor = 0,
        speed = 0,
        accuracy = 0,
        perception = 0,
        stealth = 0,
        intimidation = 0,
        force_regen = 0,
        agility = 0,
        blaster_resist = 0,
        healing_bonus = 0
    }
    
    -- Sum up all equipment stats
    for slot, equipped in pairs(ply.KyberEquipment) do
        local item = self.Items[equipped.id]
        if item and item.stats then
            for stat, value in pairs(item.stats) do
                stats[stat] = (stats[stat] or 0) + value
            end
        end
    end
    
    -- Apply stat effects
    self:ApplyStats(ply, stats)
    
    -- Store for reference
    ply.KyberStats = stats
    
    return stats
end