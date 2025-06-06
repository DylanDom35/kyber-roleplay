-- Crafting module initialization
KYBER.Crafting = KYBER.Crafting or {}

-- Crafting module configuration
KYBER.Crafting.Config = {
    MaxCraftingLevel = 100,
    ExperiencePerCraft = 10,
    ExperienceMultiplier = 1.0,
    CraftingTime = 5, -- seconds
    MaxQueueSize = 5,
    Categories = {
        "weapons",
        "armor",
        "tools",
        "consumables",
        "materials"
    },
    Recipes = {
        ["weapon_blaster"] = {
            name = "Blaster Pistol",
            category = "weapons",
            level = 10,
            time = 10,
            materials = {
                ["metal"] = 5,
                ["circuit"] = 3,
                ["power_cell"] = 1
            },
            tools = {
                "wrench",
                "screwdriver"
            },
            result = {
                id = "weapon_blaster",
                amount = 1
            }
        },
        ["armor_light"] = {
            name = "Light Armor",
            category = "armor",
            level = 5,
            time = 8,
            materials = {
                ["fabric"] = 10,
                ["metal"] = 3
            },
            tools = {
                "scissors"
            },
            result = {
                id = "armor_light",
                amount = 1
            }
        },
        ["medkit"] = {
            name = "Medkit",
            category = "consumables",
            level = 1,
            time = 5,
            materials = {
                ["bandage"] = 3,
                ["medicine"] = 2
            },
            tools = {},
            result = {
                id = "medkit",
                amount = 1
            }
        }
    },
    Tools = {
        ["wrench"] = {
            name = "Wrench",
            durability = 100,
            efficiency = 1.0
        },
        ["screwdriver"] = {
            name = "Screwdriver",
            durability = 100,
            efficiency = 1.0
        },
        ["scissors"] = {
            name = "Scissors",
            durability = 100,
            efficiency = 1.0
        }
    }
}

-- Crafting module functions
function KYBER.Crafting:Initialize()
    print("[Kyber] Crafting module initialized")
    return true
end

function KYBER.Crafting:CreateCraftingData(ply)
    if not IsValid(ply) then return false end
    
    -- Create crafting data table if it doesn't exist
    ply.KyberCrafting = ply.KyberCrafting or {
        level = 1,
        experience = 0,
        queue = {},
        activeCraft = nil,
        lastCraft = 0
    }
    
    return true
end

function KYBER.Crafting:GetLevel(ply)
    if not IsValid(ply) then return 1 end
    if not self:CreateCraftingData(ply) then return 1 end
    
    return ply.KyberCrafting.level
end

function KYBER.Crafting:GetExperience(ply)
    if not IsValid(ply) then return 0 end
    if not self:CreateCraftingData(ply) then return 0 end
    
    return ply.KyberCrafting.experience
end

function KYBER.Crafting:AddExperience(ply, amount)
    if not IsValid(ply) then return false end
    if not self:CreateCraftingData(ply) then return false end
    
    -- Calculate experience with multiplier
    local expGain = math.floor(amount * self.Config.ExperienceMultiplier)
    
    -- Add experience
    ply.KyberCrafting.experience = ply.KyberCrafting.experience + expGain
    
    -- Check for level up
    local expNeeded = self:GetExperienceForLevel(ply.KyberCrafting.level + 1)
    while ply.KyberCrafting.experience >= expNeeded and ply.KyberCrafting.level < self.Config.MaxCraftingLevel do
        ply.KyberCrafting.level = ply.KyberCrafting.level + 1
        ply.KyberCrafting.experience = ply.KyberCrafting.experience - expNeeded
        expNeeded = self:GetExperienceForLevel(ply.KyberCrafting.level + 1)
        
        -- Notify client of level up
        if SERVER then
            net.Start("Kyber_Crafting_LevelUp")
            net.WriteEntity(ply)
            net.WriteInt(ply.KyberCrafting.level, 32)
            net.Send(ply)
        end
    end
    
    -- Notify client of experience gain
    if SERVER then
        net.Start("Kyber_Crafting_Experience")
        net.WriteEntity(ply)
        net.WriteInt(expGain, 32)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Crafting:GetExperienceForLevel(level)
    return level * 100 -- Simple linear progression
end

function KYBER.Crafting:CanCraft(ply, recipeId)
    if not IsValid(ply) then return false end
    if not self:CreateCraftingData(ply) then return false end
    
    -- Get recipe data
    local recipe = self.Config.Recipes[recipeId]
    if not recipe then return false end
    
    -- Check level requirement
    if ply.KyberCrafting.level < recipe.level then
        return false
    end
    
    -- Check materials
    for material, amount in pairs(recipe.materials) do
        if not KYBER.Inventory:HasItem(ply, material, amount) then
            return false
        end
    end
    
    -- Check tools
    for _, tool in ipairs(recipe.tools) do
        if not KYBER.Inventory:HasItem(ply, tool) then
            return false
        end
    end
    
    -- Check queue size
    if #ply.KyberCrafting.queue >= self.Config.MaxQueueSize then
        return false
    end
    
    return true
end

function KYBER.Crafting:StartCrafting(ply, recipeId)
    if not IsValid(ply) then return false end
    if not self:CanCraft(ply, recipeId) then return false end
    
    -- Get recipe data
    local recipe = self.Config.Recipes[recipeId]
    
    -- Remove materials
    for material, amount in pairs(recipe.materials) do
        KYBER.Inventory:RemoveItem(ply, material, amount)
    end
    
    -- Add to queue
    table.insert(ply.KyberCrafting.queue, {
        recipe = recipeId,
        startTime = CurTime(),
        endTime = CurTime() + recipe.time
    })
    
    -- Start crafting timer if not already crafting
    if not ply.KyberCrafting.activeCraft then
        self:ProcessQueue(ply)
    end
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Crafting_Update")
        net.WriteEntity(ply)
        net.WriteTable(ply.KyberCrafting)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Crafting:ProcessQueue(ply)
    if not IsValid(ply) then return false end
    if not ply.KyberCrafting or #ply.KyberCrafting.queue == 0 then return false end
    
    -- Get next craft
    local craft = ply.KyberCrafting.queue[1]
    local recipe = self.Config.Recipes[craft.recipe]
    
    -- Set active craft
    ply.KyberCrafting.activeCraft = craft
    
    -- Create completion timer
    timer.Create("Kyber_Crafting_" .. ply:SteamID(), recipe.time, 1, function()
        if not IsValid(ply) then return end
        
        -- Complete craft
        self:CompleteCraft(ply)
        
        -- Process next in queue
        self:ProcessQueue(ply)
    end)
    
    return true
end

function KYBER.Crafting:CompleteCraft(ply)
    if not IsValid(ply) then return false end
    if not ply.KyberCrafting or not ply.KyberCrafting.activeCraft then return false end
    
    -- Get craft data
    local craft = ply.KyberCrafting.activeCraft
    local recipe = self.Config.Recipes[craft.recipe]
    
    -- Add result to inventory
    KYBER.Inventory:AddItem(ply, recipe.result.id, recipe.result.amount)
    
    -- Add experience
    self:AddExperience(ply, self.Config.ExperiencePerCraft)
    
    -- Remove from queue
    table.remove(ply.KyberCrafting.queue, 1)
    ply.KyberCrafting.activeCraft = nil
    ply.KyberCrafting.lastCraft = CurTime()
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Crafting_Update")
        net.WriteEntity(ply)
        net.WriteTable(ply.KyberCrafting)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Crafting:GetQueue(ply)
    if not IsValid(ply) then return nil end
    if not self:CreateCraftingData(ply) then return nil end
    
    return ply.KyberCrafting.queue
end

function KYBER.Crafting:GetActiveCraft(ply)
    if not IsValid(ply) then return nil end
    if not self:CreateCraftingData(ply) then return nil end
    
    return ply.KyberCrafting.activeCraft
end

function KYBER.Crafting:GetAvailableRecipes(ply)
    if not IsValid(ply) then return {} end
    if not self:CreateCraftingData(ply) then return {} end
    
    local recipes = {}
    for id, recipe in pairs(self.Config.Recipes) do
        if ply.KyberCrafting.level >= recipe.level then
            recipes[id] = recipe
        end
    end
    
    return recipes
end

-- Initialize the module
KYBER.Crafting:Initialize() 