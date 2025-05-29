-- kyber/modules/crafting/integration.lua
-- Integration with other systems and adding crafting materials

-- Add crafting materials to Grand Exchange
hook.Add("Initialize", "KyberCraftingMaterials", function()
    timer.Simple(1, function()
        -- Basic materials
        local materials = {
            -- Metals
            ["durasteel_ore"] = {
                name = "Durasteel Ore",
                description = "Raw durasteel ore",
                category = "materials",
                basePrice = 50,
                stackable = true,
                maxStack = 20
            },
            ["durasteel_plate"] = {
                name = "Durasteel Plate",
                description = "Refined armor plating",
                category = "materials",
                basePrice = 150,
                stackable = true,
                maxStack = 10
            },
            ["cortosis_weave"] = {
                name = "Cortosis Weave",
                description = "Lightsaber-resistant material",
                category = "materials",
                basePrice = 2000,
                stackable = true,
                maxStack = 5
            },
            ["durasteel_frame"] = {
                name = "Durasteel Frame",
                description = "Weapon frame component",
                category = "materials",
                basePrice = 200,
                stackable = true,
                maxStack = 10
            },
            ["durasteel_blade"] = {
                name = "Durasteel Blade",
                description = "Sharpened blade blank",
                category = "materials",
                basePrice = 300,
                stackable = true,
                maxStack = 5
            },
            
            -- Fabrics
            ["fiber_mesh"] = {
                name = "Fiber Mesh",
                description = "Lightweight armor material",
                category = "materials",
                basePrice = 80,
                stackable = true,
                maxStack = 20
            },
            ["armor_mesh"] = {
                name = "Armor Mesh",
                description = "Reinforced fabric weave",
                category = "materials",
                basePrice = 120,
                stackable = true,
                maxStack = 15
            },
            
            -- Electronics
            ["energy_cell"] = {
                name = "Energy Cell",
                description = "Power source for equipment",
                category = "materials",
                basePrice = 100,
                stackable = true,
                maxStack = 10
            },
            ["power_cell"] = {
                name = "Power Cell",
                description = "High-capacity power source",
                category = "materials",
                basePrice = 200,
                stackable = true,
                maxStack = 10
            },
            ["processing_chip"] = {
                name = "Processing Chip",
                description = "Computer processing unit",
                category = "materials",
                basePrice = 300,
                stackable = true,
                maxStack = 10
            },
            ["targeting_chip"] = {
                name = "Targeting Chip",
                description = "Weapon targeting system",
                category = "materials",
                basePrice = 400,
                stackable = true,
                maxStack = 5
            },
            ["sensor_array"] = {
                name = "Sensor Array",
                description = "Detection equipment",
                category = "materials",
                basePrice = 350,
                stackable = true,
                maxStack = 5
            },
            
            -- Weapon parts
            ["blaster_core"] = {
                name = "Blaster Core",
                description = "Energy weapon core component",
                category = "materials",
                basePrice = 500,
                stackable = true,
                maxStack = 5
            },
            ["focusing_crystal"] = {
                name = "Focusing Crystal",
                description = "Energy beam focusing element",
                category = "materials",
                basePrice = 600,
                stackable = true,
                maxStack = 5
            },
            ["vibro_motor"] = {
                name = "Vibro Motor",
                description = "High-frequency motor",
                category = "materials",
                basePrice = 400,
                stackable = true,
                maxStack = 5
            },
            
            -- Chemicals
            ["bonding_agent"] = {
                name = "Bonding Agent",
                description = "Industrial adhesive",
                category = "materials",
                basePrice = 50,
                stackable = true,
                maxStack = 20
            },
            ["carbon_compound"] = {
                name = "Carbon Compound",
                description = "Carbon-based material",
                category = "materials",
                basePrice = 30,
                stackable = true,
                maxStack = 30
            },
            ["purifying_agent"] = {
                name = "Purifying Agent",
                description = "Metal purification chemical",
                category = "materials",
                basePrice = 200,
                stackable = true,
                maxStack = 10
            },
            ["stim_compound"] = {
                name = "Stim Compound",
                description = "Medical stimulant base",
                category = "materials",
                basePrice = 150,
                stackable = true,
                maxStack = 15
            },
            
            -- Medical supplies
            ["medical_supplies"] = {
                name = "Medical Supplies",
                description = "Basic medical equipment",
                category = "materials",
                basePrice = 80,
                stackable = true,
                maxStack = 20
            },
            
            -- Fuel
            ["tibanna_gas"] = {
                name = "Tibanna Gas",
                description = "Blaster gas and fuel",
                category = "materials",
                basePrice = 300,
                stackable = true,
                maxStack = 10
            },
            ["fuel_cell"] = {
                name = "Fuel Cell",
                description = "Portable fuel container",
                category = "materials",
                basePrice = 100,
                stackable = true,
                maxStack = 15
            },
            
            -- Modifications
            ["optical_lens"] = {
                name = "Optical Lens",
                description = "Precision optics",
                category = "materials",
                basePrice = 250,
                stackable = true,
                maxStack = 10
            },
            ["mounting_bracket"] = {
                name = "Mounting Bracket",
                description = "Weapon attachment mount",
                category = "materials",
                basePrice = 50,
                stackable = true,
                maxStack = 20
            }
        }
        
        -- Add all materials to Grand Exchange
        for itemID, item in pairs(materials) do
            KYBER.GrandExchange.Items[itemID] = item
        end
        
        -- Add crafted items
        local craftedItems = {
            -- Crafted armor
            ["armor_reinforced"] = {
                name = "Reinforced Armor Plating",
                description = "Heavy duty armor plating",
                category = "armor",
                basePrice = 1500,
                stackable = false
            },
            ["armor_scout"] = {
                name = "Scout Armor",
                description = "Lightweight reconnaissance armor",
                category = "armor",
                basePrice = 1000,
                stackable = false
            },
            
            -- Crafted weapons
            ["blaster_pistol_custom"] = {
                name = "Custom Blaster Pistol",
                description = "Personalized sidearm",
                category = "weapons",
                basePrice = 2500,
                stackable = false
            },
            ["vibroblade"] = {
                name = "Vibroblade",
                description = "High-frequency blade",
                category = "weapons",
                basePrice = 2000,
                stackable = false
            },
            
            -- Crafted consumables
            ["medpac_advanced"] = {
                name = "Advanced Medpac",
                description = "Military-grade healing",
                category = "consumables",
                basePrice = 300,
                stackable = true,
                maxStack = 10
            },
            ["stim_pack"] = {
                name = "Combat Stim",
                description = "Temporary enhancement",
                category = "consumables",
                basePrice = 200,
                stackable = true,
                maxStack = 10
            },
            
            -- Crafted utilities
            ["scanner_enhanced"] = {
                name = "Enhanced Scanner",
                description = "Improved scanning range",
                category = "utilities",
                basePrice = 1500,
                stackable = false
            },
            ["jetpack_fuel"] = {
                name = "Jetpack Fuel",
                description = "High-grade fuel",
                category = "consumables",
                basePrice = 50,
                stackable = true,
                maxStack = 20
            },
            
            -- Modifications
            ["mod_scope"] = {
                name = "Precision Scope",
                description = "Weapon accuracy mod",
                category = "modifications",
                basePrice = 800,
                stackable = false
            },
            
            -- Refined materials
            ["beskar_refined"] = {
                name = "Refined Beskar",
                description = "Purified Mandalorian iron",
                category = "materials",
                basePrice = 20000,
                stackable = true,
                maxStack = 5
            }
        }
        
        -- Add crafted items to Grand Exchange
        for itemID, item in pairs(craftedItems) do
            KYBER.GrandExchange.Items[itemID] = item
        end
        
        -- Also add these items to equipment system if they're equipment
        local equipmentItems = {
            ["armor_reinforced"] = {
                name = "Reinforced Armor Plating",
                description = "Heavy duty armor plating",
                slot = "chest",
                icon = "icon16/shield.png",
                stats = {
                    armor = 30,
                    speed = -15
                },
                value = 1500
            },
            ["armor_scout"] = {
                name = "Scout Armor",
                description = "Lightweight reconnaissance armor",
                slot = "chest",
                icon = "icon16/shield.png",
                stats = {
                    armor = 15,
                    speed = 5,
                    stealth = 10
                },
                value = 1000
            }
        }
        
        for itemID, item in pairs(equipmentItems) do
            KYBER.Equipment.Items[itemID] = item
        end
    end)
end)

-- Add crafting to datapad
if CLIENT then
    hook.Add("Kyber_Datapad_AddTabs", "AddCraftingTab", function(tabSheet)
        local craftPanel = vgui.Create("DPanel", tabSheet)
        craftPanel:Dock(FILL)
        
        local title = vgui.Create("DLabel", craftPanel)
        title:SetText("Crafting System")
        title:SetFont("DermaLarge")
        title:Dock(TOP)
        title:DockMargin(20, 20, 20, 10)
        title:SetContentAlignment(5)
        
        -- Crafting stats
        local statsPanel = vgui.Create("DPanel", craftPanel)
        statsPanel:Dock(TOP)
        statsPanel:DockMargin(20, 0, 20, 20)
        statsPanel:SetTall(150)
        
        statsPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30))
            
            local craftingData = LocalPlayer().KyberCrafting or {}
            local skill = LocalPlayer():GetNWInt("kyber_crafting_skill", 1)
            local exp = craftingData.experience or 0
            local expNeeded = skill * 100
            
            draw.SimpleText("Crafting Level: " .. skill, "DermaDefaultBold", 20, 20, Color(255, 255, 255))
            
            -- Experience bar
            draw.SimpleText("Experience: " .. exp .. "/" .. expNeeded, "DermaDefault", 20, 45, Color(200, 200, 200))
            
            draw.RoundedBox(2, 20, 65, w - 40, 20, Color(50, 50, 50))
            draw.RoundedBox(2, 20, 65, (w - 40) * (exp / expNeeded), 20, Color(100, 200, 100))
            
            -- Statistics
            if craftingData.statistics then
                draw.SimpleText("Items Crafted: " .. (craftingData.statistics.itemsCrafted or 0), "DermaDefault", 20, 95, Color(200, 200, 200))
                draw.SimpleText("Total Value: " .. (craftingData.statistics.totalValue or 0) .. " credits", "DermaDefault", 20, 115, Color(200, 200, 200))
            end
        end
        
        -- Known recipes
        local recipeLabel = vgui.Create("DLabel", craftPanel)
        recipeLabel:SetText("Known Recipes:")
        recipeLabel:SetFont("DermaDefaultBold")
        recipeLabel:Dock(TOP)
        recipeLabel:DockMargin(20, 0, 20, 10)
        
        local recipeScroll = vgui.Create("DScrollPanel", craftPanel)
        recipeScroll:Dock(FILL)
        recipeScroll:DockMargin(20, 0, 20, 20)
        
        local knownRecipes = LocalPlayer().KyberCrafting and LocalPlayer().KyberCrafting.knownRecipes or {}
        
        for _, recipeID in ipairs(knownRecipes) do
            local recipe = KYBER.Crafting.Recipes[recipeID]
            if recipe then
                local recipePanel = vgui.Create("DPanel", recipeScroll)
                recipePanel:Dock(TOP)
                recipePanel:DockMargin(0, 0, 0, 5)
                recipePanel:SetTall(60)
                
                recipePanel.Paint = function(self, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
                    
                    draw.SimpleText(recipe.name, "DermaDefaultBold", 10, 10, Color(255, 255, 255))
                    draw.SimpleText(recipe.description, "DermaDefault", 10, 28, Color(200, 200, 200))
                    
                    local station = KYBER.Crafting.Stations[recipe.requirements.station]
                    if station then
                        draw.SimpleText("Station: " .. station.name, "DermaDefault", w - 200, 20, Color(150, 150, 150))
                    end
                end
            end
        end
        
        tabSheet:AddSheet("Crafting", craftPanel, "icon16/wrench.png")
    end)
end

-- Recipe learning items
if SERVER then
    -- Command to give recipe datapads
    concommand.Add("kyber_give_recipe", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local recipeID = args[1]
        if not recipeID or not KYBER.Crafting.Recipes[recipeID] then
            ply:ChatPrint("Invalid recipe ID")
            return
        end
        
        local target = ply:GetEyeTrace().Entity
        if IsValid(target) and target:IsPlayer() then
            local success, err = KYBER.Crafting:LearnRecipe(target, recipeID)
            if success then
                ply:ChatPrint("Taught " .. target:Nick() .. " the recipe: " .. KYBER.Crafting.Recipes[recipeID].name)
                target:ChatPrint("You learned a new recipe: " .. KYBER.Crafting.Recipes[recipeID].name)
            else
                ply:ChatPrint("Failed: " .. err)
            end
        end
    end)
    
    -- Command to spawn crafting stations
    concommand.Add("kyber_spawn_station", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local stationType = args[1] or "armor_bench"
        if not KYBER.Crafting.Stations[stationType] then
            ply:ChatPrint("Invalid station type. Available types:")
            for id, station in pairs(KYBER.Crafting.Stations) do
                ply:ChatPrint("- " .. id .. " (" .. station.name .. ")")
            end
            return
        end
        
        local tr = ply:GetEyeTrace()
        local ent = ents.Create("kyber_crafting_station")
        ent:SetPos(tr.HitPos + tr.HitNormal * 10)
        ent:SetStationType(stationType)
        ent:Spawn()
        
        ply:ChatPrint("Spawned " .. KYBER.Crafting.Stations[stationType].name)
    end)
end

-- Add crafting materials as loot drops
if SERVER then
    hook.Add("OnNPCKilled", "KyberCraftingDrops", function(npc, attacker, inflictor)
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        
        -- Random chance to drop crafting materials
        if math.random() < 0.3 then
            local materials = {
                "durasteel_ore",
                "fiber_mesh",
                "energy_cell",
                "medical_supplies",
                "carbon_compound"
            }
            
            local material = materials[math.random(#materials)]
            local amount = math.random(1, 3)
            
            -- Spawn dropped item
            local ent = ents.Create("kyber_dropped_item")
            ent:SetPos(npc:GetPos() + Vector(0, 0, 10))
            ent:SetItem(material, amount)
            ent:Spawn()
            
            -- Give it some physics
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(VectorRand() * 100 + Vector(0, 0, 200))
            end
        end
    end)
end