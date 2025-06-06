-- Entity Optimization Module
KYBER.EntityOptimization = KYBER.EntityOptimization or {}

-- Cache for entity data
KYBER.EntityOptimization.EntityCache = {}

-- Performance monitoring
KYBER.EntityOptimization.PerformanceStats = {
    thinkTimes = {},
    updateTimes = {},
    networkTimes = {}
}

-- Safe entity operations
function KYBER.EntityOptimization.SafeEntityOperation(ent, operation)
    if not IsValid(ent) then return false end
    return KYBER.Optimization.SafeCall(function()
        return operation(ent)
    end)
end

-- Entity cleanup
function KYBER.EntityOptimization.CleanupEntity(ent)
    if not IsValid(ent) then return end
    KYBER.Optimization.SafeCall(function()
        -- Remove from cache
        KYBER.EntityOptimization.EntityCache[ent:EntIndex()] = nil
        -- Perform cleanup
        if ent.Effects then
            for _, effect in pairs(ent.Effects) do
                if IsValid(effect) then
                    effect:Remove()
                end
            end
        end
        ent:Remove()
    end)
end

-- Entity networking optimization
function KYBER.EntityOptimization.OptimizeNetworking(ent)
    if not IsValid(ent) then return end
    -- Set network optimization
    ent:SetNWVarProxy("kyber_entity_data", function(ent, name, old, new)
        if old == new then return end
        -- Only network changes
        ent:SetNWString(name, new)
    end)
end

-- Performance monitoring
function KYBER.EntityOptimization.MonitorPerformance(ent, operationType, startTime)
    local endTime = SysTime()
    local duration = endTime - startTime
    
    -- Store performance data
    if not KYBER.EntityOptimization.PerformanceStats[operationType] then
        KYBER.EntityOptimization.PerformanceStats[operationType] = {}
    end
    
    table.insert(KYBER.EntityOptimization.PerformanceStats[operationType], {
        entity = ent:GetClass(),
        duration = duration,
        time = CurTime()
    })
    
    -- Clean up old data
    if #KYBER.EntityOptimization.PerformanceStats[operationType] > 1000 then
        table.remove(KYBER.EntityOptimization.PerformanceStats[operationType], 1)
    end
    
    -- Log if performance is poor
    if duration > 0.1 then
        KYBER.Optimization.LogPerformanceIssue("Entity", ent:GetClass(), 
            operationType .. " delay: " .. duration)
    end
end

-- Entity error recovery
function KYBER.EntityOptimization.RecoverFromError(ent)
    if not IsValid(ent) then return end
    KYBER.Optimization.SafeCall(function()
        -- Reset entity state
        ent:SetPos(ent:GetPos())
        ent:SetAngles(ent:GetAngles())
        
        -- Reset physics
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:EnableMotion(true)
        end
        
        -- Clear any error states
        ent:SetNWBool("kyber_error_state", false)
    end)
end

-- Entity initialization helper
function KYBER.EntityOptimization.InitializeEntity(ent, model, solidType)
    KYBER.Optimization.SafeCall(function()
        -- Basic setup
        ent:SetModel(model or ent.Model)
        ent:PhysicsInit(solidType or SOLID_VPHYSICS)
        ent:SetMoveType(MOVETYPE_VPHYSICS)
        ent:SetSolid(solidType or SOLID_VPHYSICS)
        
        -- Add to cache
        KYBER.EntityOptimization.EntityCache[ent:EntIndex()] = {
            lastUpdate = CurTime(),
            data = {}
        }
        
        -- Optimize networking
        KYBER.EntityOptimization.OptimizeNetworking(ent)
        
        -- Initialize physics
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end)
end

-- Entity think optimization
function KYBER.EntityOptimization.OptimizedThink(ent, thinkFunc)
    if not IsValid(ent) then return end
    
    local startTime = SysTime()
    KYBER.Optimization.SafeCall(function()
        -- Update cache
        local cache = KYBER.EntityOptimization.EntityCache[ent:EntIndex()]
        if cache then
            cache.lastUpdate = CurTime()
            cache.data = {
                position = ent:GetPos(),
                angles = ent:GetAngles(),
                velocity = ent:GetVelocity()
            }
        end
        
        -- Execute think function
        if thinkFunc then
            thinkFunc(ent)
        end
    end)
    
    -- Monitor performance
    KYBER.EntityOptimization.MonitorPerformance(ent, "Think", startTime)
end

-- Entity update optimization
function KYBER.EntityOptimization.OptimizedUpdate(ent, updateFunc)
    if not IsValid(ent) then return end
    
    local startTime = SysTime()
    KYBER.Optimization.SafeCall(function()
        if updateFunc then
            updateFunc(ent)
        end
    end)
    
    -- Monitor performance
    KYBER.EntityOptimization.MonitorPerformance(ent, "Update", startTime)
end

-- Entity networking optimization
function KYBER.EntityOptimization.OptimizedNetwork(ent, networkFunc)
    if not IsValid(ent) then return end
    
    local startTime = SysTime()
    KYBER.Optimization.SafeCall(function()
        if networkFunc then
            networkFunc(ent)
        end
    end)
    
    -- Monitor performance
    KYBER.EntityOptimization.MonitorPerformance(ent, "Network", startTime)
end

-- Entity cleanup optimization
function KYBER.EntityOptimization.OptimizedCleanup(ent, cleanupFunc)
    if not IsValid(ent) then return end
    
    local startTime = SysTime()
    KYBER.Optimization.SafeCall(function()
        if cleanupFunc then
            cleanupFunc(ent)
        end
        KYBER.EntityOptimization.CleanupEntity(ent)
    end)
    
    -- Monitor performance
    KYBER.EntityOptimization.MonitorPerformance(ent, "Cleanup", startTime)
end

-- Entity error handling
function KYBER.EntityOptimization.HandleError(ent, errorFunc)
    if not IsValid(ent) then return end
    
    KYBER.Optimization.SafeCall(function()
        -- Set error state
        ent:SetNWBool("kyber_error_state", true)
        
        -- Execute error handler
        if errorFunc then
            errorFunc(ent)
        end
        
        -- Attempt recovery
        KYBER.EntityOptimization.RecoverFromError(ent)
    end)
end

-- Entity validation
function KYBER.EntityOptimization.ValidateEntity(ent)
    if not IsValid(ent) then return false end
    
    -- Check if entity is in cache
    if not KYBER.EntityOptimization.EntityCache[ent:EntIndex()] then
        KYBER.EntityOptimization.EntityCache[ent:EntIndex()] = {
            lastUpdate = CurTime(),
            data = {}
        }
    end
    
    return true
end

-- Entity state management
function KYBER.EntityOptimization.SetEntityState(ent, state)
    if not KYBER.EntityOptimization.ValidateEntity(ent) then return end
    
    KYBER.Optimization.SafeCall(function()
        ent:SetNWString("kyber_entity_state", state)
        
        -- Update cache
        local cache = KYBER.EntityOptimization.EntityCache[ent:EntIndex()]
        if cache then
            cache.data.state = state
        end
    end)
end

function KYBER.EntityOptimization.GetEntityState(ent)
    if not KYBER.EntityOptimization.ValidateEntity(ent) then return nil end
    
    return ent:GetNWString("kyber_entity_state", "")
end

-- Entity data management
function KYBER.EntityOptimization.SetEntityData(ent, key, value)
    if not KYBER.EntityOptimization.ValidateEntity(ent) then return end
    
    KYBER.Optimization.SafeCall(function()
        -- Update network variable
        local data = ent:GetNWString("kyber_entity_data", "{}")
        local decoded = util.JSONToTable(data) or {}
        decoded[key] = value
        ent:SetNWString("kyber_entity_data", util.TableToJSON(decoded))
        
        -- Update cache
        local cache = KYBER.EntityOptimization.EntityCache[ent:EntIndex()]
        if cache then
            cache.data[key] = value
        end
    end)
end

function KYBER.EntityOptimization.GetEntityData(ent, key)
    if not KYBER.EntityOptimization.ValidateEntity(ent) then return nil end
    
    local data = ent:GetNWString("kyber_entity_data", "{}")
    local decoded = util.JSONToTable(data) or {}
    return decoded[key]
end

-- Entity effect management
function KYBER.EntityOptimization.AddEntityEffect(ent, effect)
    if not KYBER.EntityOptimization.ValidateEntity(ent) then return end
    
    KYBER.Optimization.SafeCall(function()
        if not ent.Effects then
            ent.Effects = {}
        end
        
        table.insert(ent.Effects, effect)
    end)
end

function KYBER.EntityOptimization.RemoveEntityEffect(ent, effect)
    if not KYBER.EntityOptimization.ValidateEntity(ent) then return end
    
    KYBER.Optimization.SafeCall(function()
        if not ent.Effects then return end
        
        for k, v in pairs(ent.Effects) do
            if v == effect then
                table.remove(ent.Effects, k)
                break
            end
        end
    end)
end

-- Entity performance reporting
function KYBER.EntityOptimization.GetPerformanceReport()
    local report = {
        think = {},
        update = {},
        network = {},
        cleanup = {}
    }
    
    -- Calculate averages
    for operationType, data in pairs(KYBER.EntityOptimization.PerformanceStats) do
        local total = 0
        local count = 0
        
        for _, stat in pairs(data) do
            total = total + stat.duration
            count = count + 1
        end
        
        if count > 0 then
            report[operationType] = {
                average = total / count,
                total = total,
                count = count
            }
        end
    end
    
    return report
end

-- Entity system cleanup
function KYBER.EntityOptimization.CleanupSystem()
    KYBER.Optimization.SafeCall(function()
        -- Clear cache
        KYBER.EntityOptimization.EntityCache = {}
        
        -- Clear performance stats
        KYBER.EntityOptimization.PerformanceStats = {
            thinkTimes = {},
            updateTimes = {},
            networkTimes = {}
        }
    end)
end

-- Hook into gamemode cleanup
hook.Add("ShutDown", "KYBER_EntityOptimization_Cleanup", function()
    KYBER.EntityOptimization.CleanupSystem()
end) 