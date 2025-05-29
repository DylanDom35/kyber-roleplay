-- kyber/modules/crafting/system.lua
KYBER.Crafting = KYBER.Crafting or {}

-- Crafting categories
KYBER.Crafting.Categories = {
    ["armor"] = {name = "Armor", icon = "icon16/shield.png"},
    ["weapons"] = {name = "Weapons", icon = "icon16/gun.png"},
    ["consumables"] = {name = "Consumables", icon = "icon16/pill.png"},
    ["utilities"] = {name = "Utilities", icon = "icon16/wrench.png"},
    ["materials"] = {name = "Materials", icon = "icon16/box.png"},
    ["modifications"] = {name = "Modifications", icon = "icon16/cog.png"}
}

-- Crafting recipes
KYBER.Crafting.Recipes = {
    -- Armor crafting
    ["armor_reinforced"] = {
        name = "Reinforced Armor Plating",
        description = "Heavy duty armor plating",
        category = "armor",
        result = {
            id = "armor_reinforced",
            amount = 1
        },
        ingredients = {
            {id = "durasteel_plate", amount = 3},
            {id = "armor_mesh", amount = 2},
            {id = "bonding_agent", amount = 1}
        },
        requirements = {
            skill = 5,
            station = "armor_bench"
        },
        time = 30,
        experience = 25
    },
    
    ["armor_scout"] = {
        name = "Scout Armor",
        description = "Lightweight armor for reconnaissance",
        category = "armor",
        result = {
            id = "armor_scout",
            amount = 1
        },
        ingredients = {
            {id = "fiber_mesh", amount = 4},
            {id = "durasteel_plate", amount = 1},
            {id = "energy_cell", amount = 1}
        },
        requirements = {
            skill = 3,
            station = "armor_bench"
        },
        time = 20,
        experience = 15
    },
    
    -- Weapon crafting
    ["blaster_pistol_custom"] = {
        name = "Custom Blaster Pistol",
        description = "A personalized sidearm",
        category = "weapons",
        result = {
            id = "blaster_pistol_custom",
            amount = 1
        },
        ingredients = {
            {id = "blaster_core", amount = 1},
            {id = "focusing_crystal", amount = 1},
            {id = "durasteel_frame", amount = 2},
            {id = "power_cell", amount = 2}
        },
        requirements = {
            skill = 7,
            station = "weapon_bench"
        },
        time = 45,
        experience = 35
    },
    
    ["vibroblade"] = {
        name = "Vibroblade",
        description = "High-frequency vibrating blade",
        category = "weapons",
        result = {
            id = "vibroblade",
            amount = 1
        },
        ingredients = {
            {id = "cortosis_weave", amount = 1},
            {id = "vibro_motor", amount = 1},
            {id = "durasteel_blade", amount = 1},
            {id = "power_cell", amount = 1}
        },
        requirements = {
            skill = 6,
            station = "weapon_bench"
        },
        time = 35,
        experience = 30
    },
    
    -- Consumables
    ["medpac_advanced"] = {
        name = "Advanced Medpac",
        description = "Military-grade medical supplies",
        category = "consumables",
        result = {
            id = "medpac_advanced",
            amount = 3
        },
        ingredients = {
            {id = "bacta_vial", amount = 2},
            {id = "medical_supplies", amount = 3},
            {id = "stim_compound", amount = 1}
        },
        requirements = {
            skill = 4,
            station = "medical_station"
        },
        time = 15,
        experience = 10
    },
    
    ["stim_pack"] = {
        name = "Combat Stim",
        description = "Temporary combat enhancement",
        category = "consumables",
        result = {
            id = "stim_pack",
            amount = 5
        },
        ingredients = {
            {id = "stim_compound", amount = 2},
            {id = "medical_supplies", amount = 1}
        },
        requirements = {
            skill = 2,
            station = "medical_station"
        },
        time = 10,
        experience = 5
    },
    
    -- Utilities
    ["scanner_upgrade"] = {
        name = "Enhanced Scanner Module",
        description = "Improved scanning capabilities",
        category = "utilities",
        result = {
            id = "scanner_enhanced",
            amount = 1
        },
        ingredients = {
            {id = "utility_scanner", amount = 1},
            {id = "sensor_array", amount = 2},
            {id = "processing_chip", amount = 1}
        },
        requirements = {
            skill = 5,
            station = "tech_bench"
        },
        time = 25,
        experience = 20
    },
    
    ["jetpack_fuel"] = {
        name = "Jetpack Fuel Canister",
        description = "High-grade jetpack fuel",
        category = "utilities",
        result = {
            id = "jetpack_fuel",
            amount = 10
        },
        ingredients = {
            {id = "tibanna_gas", amount = 2},
            {id = "fuel_cell", amount = 3}
        },
        requirements = {
            skill = 1,
            station = "tech_bench"
        },
        time = 8,
        experience = 3
    },
    
    -- Material processing
    ["durasteel_plate"] = {
        name = "Durasteel Plate",
        description = "Refined armor plating",
        category = "materials",
        result = {
            id = "durasteel_plate",
            amount = 2
        },
        ingredients = {
            {id = "durasteel_ore", amount = 5},
            {id = "carbon_compound", amount = 1}
        },
        requirements = {
            skill = 2,
            station = "forge"
        },
        time = 20,
        experience = 8
    },
    
    ["beskar_refined"] = {
        name = "Refined Beskar",
        description = "Purified Mandalorian iron",
        category = "materials",
        result = {
            id = "beskar_refined",
            amount = 1
        },
        ingredients = {
            {id = "beskar_ingot", amount = 3},
            {id = "purifying_agent", amount = 1}
        },
        requirements = {
            skill = 10,
            station = "mandalorian_forge",
            reputation_mandalorian = 100
        },
        time = 60,
        experience = 50
    },
    
    -- Modifications
    ["scope_attachment"] = {
        name = "Precision Scope",
        description = "Weapon accuracy modification",
        category = "modifications",
        result = {
            id = "mod_scope",
            amount = 1
        },
        ingredients = {
            {id = "optical_lens", amount = 2},
            {id = "mounting_bracket", amount = 1},
            {id = "targeting_chip", amount = 1}
        },
        requirements = {
            skill = 4,
            station = "mod_bench"
        },
        time = 15,
        experience = 12
    }
}

-- Crafting stations
KYBER.Crafting.Stations = {
    ["armor_bench"] = {name = "Armor Workbench", model = "models/props_c17/FurnitureTable002a.mdl"},
    ["weapon_bench"] = {name = "Weapon Workbench", model = "models/props_c17/FurnitureTable001a.mdl"},
    ["medical_station"] = {name = "Medical Station", model = "models/props_lab/crematorcase.mdl"},
    ["tech_bench"] = {name = "Tech Workbench", model = "models/props_lab/serverrack.mdl"},
    ["forge"] = {name = "Industrial Forge", model = "models/props_c17/furniturefireplace001a.mdl"},
    ["mandalorian_forge"] = {name = "Mandalorian Forge", model = "models/props_c17/furniturefireplace001a.mdl"},
    ["mod_bench"] = {name = "Modification Bench", model = "models/props_c17/bench01a.mdl"}
}

if SERVER then
    util.AddNetworkString("Kyber_Crafting_Open")
    util.AddNetworkString("Kyber_Crafting_Start")
    util.AddNetworkString("Kyber_Crafting_Cancel")
    util.AddNetworkString("Kyber_Crafting_Complete")
    util.AddNetworkString("Kyber_Crafting_Progress")
    util.AddNetworkString("Kyber_Crafting_LearnRecipe")
    
    -- Initialize crafting for player
    function KYBER.Crafting:Initialize(ply)
        -- Load crafting data
        local steamID = ply:SteamID64()
        local path = "kyber/crafting/" .. steamID .. ".json"
        
        if file.Exists(path, "DATA") then
            local data = file.Read(path, "DATA")
            local craftingData = util.JSONToTable(data) or {}
            
            ply.KyberCrafting = {
                skill = craftingData.skill or 1,
                experience = craftingData.experience or 0,
                knownRecipes = craftingData.knownRecipes or {"medpac_advanced", "stim_pack"}, -- Start with basic recipes
                statistics = craftingData.statistics or {}
            }
        else
            -- New player
            ply.KyberCrafting = {
                skill = 1,
                experience = 0,
                knownRecipes = {"medpac_advanced", "stim_pack"}, -- Starting recipes
                statistics = {
                    itemsCrafted = 0,
                    totalValue = 0,
                    favoriteRecipe = nil
                }
            }
        end
        
        -- Set networked skill level
        ply:SetNWInt("kyber_crafting_skill", ply.KyberCrafting.skill)
    end
    
    function KYBER.Crafting:Save(ply)
        if not IsValid(ply) or not ply.KyberCrafting then return end
        
        local steamID = ply:SteamID64()
        local path = "kyber/crafting/" .. steamID .. ".json"
        
        if not file.Exists("kyber/crafting", "DATA") then
            file.CreateDir("kyber/crafting")
        end
        
        file.Write(path, util.TableToJSON(ply.KyberCrafting))
    end
    
    -- Check if player can craft recipe
    function KYBER.Crafting:CanCraft(ply, recipeID, stationType)
        local recipe = self.Recipes[recipeID]
        if not recipe then return false, "Invalid recipe" end
        
        -- Check if player knows the recipe
        if not table.HasValue(ply.KyberCrafting.knownRecipes, recipeID) then
            return false, "You don't know this recipe"
        end
        
        -- Check skill requirement
        if ply.KyberCrafting.skill < recipe.requirements.skill then
            return false, "Requires crafting level " .. recipe.requirements.skill
        end
        
        -- Check station requirement
        if recipe.requirements.station ~= stationType then
            return false, "Wrong crafting station"
        end
        
        -- Check special requirements
        if recipe.requirements.reputation_mandalorian then
            local rep = KYBER:GetPlayerData(ply, "rep_mandalorian") or 0
            if rep < recipe.requirements.reputation_mandalorian then
                return false, "Requires Mandalorian reputation"
            end
        end
        
        -- Check ingredients
        for _, ingredient in ipairs(recipe.ingredients) do
            local hasItem, count = KYBER.Inventory:HasItem(ply, ingredient.id, ingredient.amount)
            if not hasItem then
                local item = KYBER.GrandExchange.Items[ingredient.id]
                local itemName = item and item.name or ingredient.id
                return false, "Missing " .. (ingredient.amount - count) .. "x " .. itemName
            end
        end
        
        return true
    end
    
    -- Start crafting
    function KYBER.Crafting:StartCrafting(ply, recipeID, station)
        local canCraft, reason = self:CanCraft(ply, recipeID, station:GetStationType())
        if not canCraft then
            return false, reason
        end
        
        local recipe = self.Recipes[recipeID]
        
        -- Remove ingredients
        for _, ingredient in ipairs(recipe.ingredients) do
            KYBER.Inventory:RemoveItem(ply, ingredient.id, ingredient.amount)
        end
        
        -- Start crafting timer
        ply.CraftingData = {
            recipe = recipeID,
            station = station,
            startTime = CurTime(),
            endTime = CurTime() + recipe.time
        }
        
        -- Send progress updates
        timer.Create("KyberCrafting_" .. ply:SteamID64(), 0.1, recipe.time * 10, function()
            if not IsValid(ply) or not ply.CraftingData then
                timer.Remove("KyberCrafting_" .. ply:SteamID64())
                return
            end
            
            local progress = (CurTime() - ply.CraftingData.startTime) / recipe.time
            
            net.Start("Kyber_Crafting_Progress")
            net.WriteFloat(progress)
            net.Send(ply)
            
            if progress >= 1 then
                self:CompleteCrafting(ply)
            end
        end)
        
        return true
    end
    
    -- Complete crafting
    function KYBER.Crafting:CompleteCrafting(ply)
        if not ply.CraftingData then return end
        
        local recipe = self.Recipes[ply.CraftingData.recipe]
        if not recipe then return end
        
        -- Give result
        local success, err = KYBER.Inventory:GiveItem(ply, recipe.result.id, recipe.result.amount)
        
        if success then
            -- Grant experience
            self:GrantExperience(ply, recipe.experience)
            
            -- Update statistics
            ply.KyberCrafting.statistics.itemsCrafted = (ply.KyberCrafting.statistics.itemsCrafted or 0) + recipe.result.amount
            
            -- Track value
            local item = KYBER.GrandExchange.Items[recipe.result.id]
            if item then
                ply.KyberCrafting.statistics.totalValue = (ply.KyberCrafting.statistics.totalValue or 0) + (item.basePrice * recipe.result.amount)
            end
            
            -- Sound and notification
            ply:EmitSound("buttons/button3.wav")
            
            net.Start("Kyber_Crafting_Complete")
            net.WriteString(recipe.name)
            net.WriteInt(recipe.result.amount, 8)
            net.Send(ply)
        else
            -- Return ingredients if inventory full
            for _, ingredient in ipairs(recipe.ingredients) do
                KYBER.Inventory:GiveItem(ply, ingredient.id, ingredient.amount)
            end
            
            ply:ChatPrint("Crafting failed: " .. err)
        end
        
        -- Clear crafting data
        ply.CraftingData = nil
        timer.Remove("KyberCrafting_" .. ply:SteamID64())
        
        self:Save(ply)
    end
    
    -- Grant crafting experience
    function KYBER.Crafting:GrantExperience(ply, amount)
        ply.KyberCrafting.experience = ply.KyberCrafting.experience + amount
        
        -- Calculate level from experience
        local expNeeded = ply.KyberCrafting.skill * 100
        
        while ply.KyberCrafting.experience >= expNeeded do
            ply.KyberCrafting.experience = ply.KyberCrafting.experience - expNeeded
            ply.KyberCrafting.skill = ply.KyberCrafting.skill + 1
            
            -- Update networked value
            ply:SetNWInt("kyber_crafting_skill", ply.KyberCrafting.skill)
            
            -- Notification
            ply:ChatPrint("Crafting skill increased to level " .. ply.KyberCrafting.skill .. "!")
            ply:EmitSound("buttons/button9.wav")
            
            -- Unlock new recipes
            self:CheckRecipeUnlocks(ply)
            
            expNeeded = ply.KyberCrafting.skill * 100
        end
    end
    
    -- Check for new recipe unlocks
    function KYBER.Crafting:CheckRecipeUnlocks(ply)
        for recipeID, recipe in pairs(self.Recipes) do
            if not table.HasValue(ply.KyberCrafting.knownRecipes, recipeID) then
                if ply.KyberCrafting.skill >= recipe.requirements.skill then
                    -- Random chance to learn recipe on level up
                    if math.random() < 0.3 then
                        table.insert(ply.KyberCrafting.knownRecipes, recipeID)
                        ply:ChatPrint("New recipe learned: " .. recipe.name .. "!")
                    end
                end
            end
        end
    end
    
    -- Learn recipe from item/datapad
    function KYBER.Crafting:LearnRecipe(ply, recipeID)
        if table.HasValue(ply.KyberCrafting.knownRecipes, recipeID) then
            return false, "You already know this recipe"
        end
        
        local recipe = self.Recipes[recipeID]
        if not recipe then
            return false, "Invalid recipe"
        end
        
        if ply.KyberCrafting.skill < recipe.requirements.skill then
            return false, "Requires crafting level " .. recipe.requirements.skill
        end
        
        table.insert(ply.KyberCrafting.knownRecipes, recipeID)
        self:Save(ply)
        
        return true
    end
    
    -- Network receivers
    net.Receive("Kyber_Crafting_Start", function(len, ply)
        local recipeID = net.ReadString()
        local station = net.ReadEntity()
        
        if not IsValid(station) or station:GetClass() ~= "kyber_crafting_station" then
            ply:ChatPrint("Invalid crafting station")
            return
        end
        
        if ply:GetPos():Distance(station:GetPos()) > 100 then
            ply:ChatPrint("Too far from crafting station")
            return
        end
        
        if ply.CraftingData then
            ply:ChatPrint("Already crafting something")
            return
        end
        
        local success, err = KYBER.Crafting:StartCrafting(ply, recipeID, station)
        
        if not success then
            ply:ChatPrint("Cannot craft: " .. err)
        end
    end)
    
    net.Receive("Kyber_Crafting_Cancel", function(len, ply)
        if not ply.CraftingData then return end
        
        -- Return ingredients
        local recipe = KYBER.Crafting.Recipes[ply.CraftingData.recipe]
        if recipe then
            for _, ingredient in ipairs(recipe.ingredients) do
                KYBER.Inventory:GiveItem(ply, ingredient.id, ingredient.amount)
            end
        end
        
        ply.CraftingData = nil
        timer.Remove("KyberCrafting_" .. ply:SteamID64())
        
        ply:ChatPrint("Crafting cancelled")
    end)
    
    -- Hooks
    hook.Add("PlayerInitialSpawn", "KyberCraftingInit", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                KYBER.Crafting:Initialize(ply)
            end
        end)
    end)
    
    hook.Add("PlayerDisconnected", "KyberCraftingSave", function(ply)
        -- Cancel crafting if in progress
        if ply.CraftingData then
            KYBER.Crafting:CancelCrafting(ply)
        end
        
        KYBER.Crafting:Save(ply)
    end)
    
else -- CLIENT
    
    local CraftingMenu = nil
    
    net.Receive("Kyber_Crafting_Open", function()
        local station = net.ReadEntity()
        local stationType = net.ReadString()
        
        KYBER.Crafting:OpenMenu(station, stationType)
    end)
    
    net.Receive("Kyber_Crafting_Progress", function()
        local progress = net.ReadFloat()
        
        if IsValid(CraftingMenu) and CraftingMenu.progressBar then
            CraftingMenu.progressBar:SetFraction(progress)
        end
    end)
    
    net.Receive("Kyber_Crafting_Complete", function()
        local itemName = net.ReadString()
        local amount = net.ReadInt(8)
        
        surface.PlaySound("buttons/button3.wav")
        notification.AddLegacy("Crafted " .. amount .. "x " .. itemName, NOTIFY_GENERIC, 3)
        
        if IsValid(CraftingMenu) then
            CraftingMenu:Close()
        end
    end)
    
    function KYBER.Crafting:OpenMenu(station, stationType)
        if IsValid(CraftingMenu) then CraftingMenu:Remove() end
        
        CraftingMenu = vgui.Create("DFrame")
        CraftingMenu:SetSize(800, 600)
        CraftingMenu:Center()
        CraftingMenu:SetTitle("Crafting - " .. KYBER.Crafting.Stations[stationType].name)
        CraftingMenu:MakePopup()
        
        local container = vgui.Create("DPanel", CraftingMenu)
        container:Dock(FILL)
        container:DockMargin(10, 10, 10, 10)
        container.Paint = function() end
        
        -- Category selector
        local catPanel = vgui.Create("DPanel", container)
        catPanel:Dock(LEFT)
        catPanel:SetWide(150)
        catPanel:DockMargin(0, 0, 10, 0)
        
        catPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        end
        
        local catLabel = vgui.Create("DLabel", catPanel)
        catLabel:SetText("Categories")
        catLabel:SetFont("DermaDefaultBold")
        catLabel:Dock(TOP)
        catLabel:DockMargin(10, 10, 10, 10)
        
        local selectedCategory = "all"
        
        -- All recipes button
        local allBtn = vgui.Create("DButton", catPanel)
        allBtn:SetText("All Recipes")
        allBtn:Dock(TOP)
        allBtn:DockMargin(5, 0, 5, 2)
        
        allBtn.DoClick = function()
            selectedCategory = "all"
            self:RefreshRecipes(stationType, selectedCategory)
        end
        
        -- Category buttons
        for catID, cat in pairs(KYBER.Crafting.Categories) do
            local btn = vgui.Create("DButton", catPanel)
            btn:SetText(cat.name)
            btn:Dock(TOP)
            btn:DockMargin(5, 0, 5, 2)
            
            btn.DoClick = function()
                selectedCategory = catID
                self:RefreshRecipes(stationType, selectedCategory)
            end
        end
        
        -- Crafting info
        local infoPanel = vgui.Create("DPanel", catPanel)
        infoPanel:Dock(BOTTOM)
        infoPanel:SetTall(100)
        infoPanel:DockMargin(5, 10, 5, 5)
        
        infoPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
            
            local skill = LocalPlayer():GetNWInt("kyber_crafting_skill", 1)
            
            draw.SimpleText("Crafting Level", "DermaDefaultBold", w/2, 10, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            draw.SimpleText(tostring(skill), "DermaLarge", w/2, 30, Color(100, 255, 100), TEXT_ALIGN_CENTER)
            
            -- Experience bar placeholder
            draw.RoundedBox(2, 10, 60, w-20, 20, Color(50, 50, 50))
        end
        
        -- Recipe list
        local recipePanel = vgui.Create("DPanel", container)
        recipePanel:Dock(FILL)
        
        recipePanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
        end
        
        local recipeScroll = vgui.Create("DScrollPanel", recipePanel)
        recipeScroll:Dock(FILL)
        recipeScroll:DockMargin(10, 10, 10, 10)
        
        CraftingMenu.recipeScroll = recipeScroll
        CraftingMenu.station = station
        
        -- Progress bar (hidden initially)
        local progressBar = vgui.Create("DProgress", CraftingMenu)
        progressBar:SetPos(10, CraftingMenu:GetTall() - 40)
        progressBar:SetSize(CraftingMenu:GetWide() - 20, 30)
        progressBar:SetFraction(0)
        progressBar:SetVisible(false)
        
        CraftingMenu.progressBar = progressBar
        
        -- Load recipes
        self:RefreshRecipes(stationType, selectedCategory)
    end
    
    function KYBER.Crafting:RefreshRecipes(stationType, category)
        if not IsValid(CraftingMenu) or not IsValid(CraftingMenu.recipeScroll) then return end
        
        CraftingMenu.recipeScroll:Clear()
        
        local myRecipes = LocalPlayer().KyberCrafting and LocalPlayer().KyberCrafting.knownRecipes or {}
        
        for recipeID, recipe in pairs(KYBER.Crafting.Recipes) do
            -- Filter by station
            if recipe.requirements.station ~= stationType then continue end
            
            -- Filter by category
            if category ~= "all" and recipe.category ~= category then continue end
            
            -- Check if player knows recipe
            local knows = table.HasValue(myRecipes, recipeID)
            
            local recipePanel = vgui.Create("DPanel", CraftingMenu.recipeScroll)
            recipePanel:Dock(TOP)
            recipePanel:DockMargin(0, 0, 0, 5)
            recipePanel:SetTall(100)
            
            recipePanel.Paint = function(self, w, h)
                local col = knows and Color(50, 50, 50) or Color(30, 30, 30)
                
                if self:IsHovered() and knows then
                    col = Color(70, 70, 70)
                end
                
                draw.RoundedBox(4, 0, 0, w, h, col)
                
                -- Recipe name
                local nameCol = knows and Color(255, 255, 255) or Color(100, 100, 100)
                draw.SimpleText(recipe.name, "DermaDefaultBold", 10, 10, nameCol)
                
                -- Description
                draw.SimpleText(recipe.description, "DermaDefault", 10, 28, Color(200, 200, 200))
                
                -- Requirements
                local reqText = "Level " .. recipe.requirements.skill
                local reqCol = LocalPlayer():GetNWInt("kyber_crafting_skill", 1) >= recipe.requirements.skill and Color(100, 255, 100) or Color(255, 100, 100)
                draw.SimpleText(reqText, "DermaDefault", 10, 46, reqCol)
                
                -- Result
                local resultItem = KYBER.GrandExchange.Items[recipe.result.id]
                if resultItem then
                    draw.SimpleText("Creates: " .. recipe.result.amount .. "x " .. resultItem.name, "DermaDefault", 10, 64, Color(255, 255, 100))
                end
                
                -- Ingredients
                local x = 300
                draw.SimpleText("Requires:", "DermaDefault", x, 10, Color(200, 200, 200))
                
                local y = 28
                for _, ingredient in ipairs(recipe.ingredients) do
                    local item = KYBER.GrandExchange.Items[ingredient.id]
                    if item then
                        local has = KYBER.Inventory:GetItemCount(LocalPlayer(), ingredient.id)
                        local textCol = has >= ingredient.amount and Color(100, 255, 100) or Color(255, 100, 100)
                        
                        draw.SimpleText(ingredient.amount .. "x " .. item.name .. " (" .. has .. ")", "DermaDefault", x + 10, y, textCol)
                        y = y + 16
                    end
                end
                
                -- Craft time
                draw.SimpleText("Time: " .. recipe.time .. "s", "DermaDefault", w - 100, 10, Color(200, 200, 200))
            end
            
            if knows then
                recipePanel:SetCursor("hand")
                
                recipePanel.DoClick = function()
                    -- Check if already crafting
                    if CraftingMenu.progressBar:IsVisible() then
                        LocalPlayer():ChatPrint("Already crafting!")
                        return
                    end
                    
                    Derma_Query(
                        "Craft " .. recipe.name .. "?",
                        "Confirm Crafting",
                        "Yes", function()
                            net.Start("Kyber_Crafting_Start")
                            net.WriteString(recipeID)
                            net.WriteEntity(CraftingMenu.station)
                            net.SendToServer()
                            
                            -- Show progress bar
                            CraftingMenu.progressBar:SetVisible(true)
                            CraftingMenu.progressBar:SetFraction(0)
                        end,
                        "No", function() end
                    )
                end
            else
                -- Unknown recipe
                recipePanel:SetTooltip("You don't know this recipe yet!")
            end
        end
    end
    
    -- Add crafting info to character sheet
    hook.Add("Kyber_CharacterSheet_AddInfo", "AddCraftingInfo", function(ply)
        local info = {}
        
        local skill = ply:GetNWInt("kyber_crafting_skill", 1)
        table.insert(info, {
            label = "Crafting Level",
            value = tostring(skill)
        })
        
        return info
    end)
end
                        