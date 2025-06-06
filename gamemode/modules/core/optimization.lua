-- kyber/gamemode/modules/core/optimization.lua
-- Core optimization module for the Kyber gamemode

KYBER.Optimization = KYBER.Optimization or {}

-- Configuration
KYBER.Optimization.Config = {
    THINK_INTERVAL = 1/30, -- 30 FPS
    CACHE_DURATION = 1, -- seconds
    MEMORY_WARNING_THRESHOLD = 1000000, -- 1GB
    TIMER_WARNING_THRESHOLD = 100,
    PERFORMANCE_LOG_DURATION = 3600, -- 1 hour
    FILE_OPERATION_TIMEOUT = 5 -- seconds
}

-- File system optimization
local fileLocks = {}
local function SafeFileOperation(path, operation)
    if fileLocks[path] then
        return false, "File is locked"
    end
    
    fileLocks[path] = true
    
    local success, result = pcall(function()
        return operation()
    end)
    
    fileLocks[path] = nil
    
    if not success then
        print("[KYBER ERROR] File operation failed: " .. tostring(result))
        return false, result
    end
    
    return true, result
end

-- Cache system
local caches = {}
function KYBER.Optimization.CreateCache(name, duration)
    caches[name] = {
        data = {},
        duration = duration or KYBER.Optimization.Config.CACHE_DURATION
    }
end

function KYBER.Optimization.GetCached(name, key, generator)
    local cache = caches[name]
    if not cache then return generator() end
    
    local entry = cache.data[key]
    if entry and (CurTime() - entry.time) < cache.duration then
        return entry.value
    end
    
    local value = generator()
    cache.data[key] = {
        time = CurTime(),
        value = value
    }
    
    return value
end

function KYBER.Optimization.ClearCache(name)
    if name then
        caches[name] = nil
    else
        caches = {}
    end
end

-- Performance monitoring
local performanceStats = {}
function KYBER.Optimization.MonitorPerformance()
    local stats = {
        timestamp = CurTime(),
        memory = collectgarbage("count"),
        players = #player.GetAll(),
        entities = #ents.GetAll(),
        timers = #timer.GetTable(),
        hooks = #hook.GetTable()
    }
    
    -- Log warnings
    if stats.memory > KYBER.Optimization.Config.MEMORY_WARNING_THRESHOLD then
        print("[KYBER WARNING] High memory usage: " .. stats.memory .. "KB")
    end
    
    if stats.timers > KYBER.Optimization.Config.TIMER_WARNING_THRESHOLD then
        print("[KYBER WARNING] High timer count: " .. stats.timers)
    end
    
    -- Store stats
    table.insert(performanceStats, stats)
    
    -- Keep only recent stats
    while #performanceStats > KYBER.Optimization.Config.PERFORMANCE_LOG_DURATION do
        table.remove(performanceStats, 1)
    end
end

-- Memory optimization
function KYBER.Optimization.OptimizeMemory()
    -- Clear all caches
    KYBER.Optimization.ClearCache()
    
    -- Reset file locks
    fileLocks = {}
    
    -- Force garbage collection
    collectgarbage("collect")
end

-- Error recovery
function KYBER.Optimization.RecoverFromError()
    -- Clear all caches
    KYBER.Optimization.ClearCache()
    
    -- Reset file locks
    fileLocks = {}
    
    -- Force garbage collection
    collectgarbage("collect")
    
    -- Reinitialize systems
    for _, system in pairs(KYBER) do
        if type(system) == "table" and system.Initialize then
            system:Initialize()
        end
    end
end

-- Safe function execution
function KYBER.Optimization.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        print("[KYBER ERROR] " .. tostring(result))
        KYBER.Optimization.RecoverFromError()
        return false
    end
    return result
end

-- Think optimization
local lastThink = 0
function KYBER.Optimization.OptimizedThink()
    local currentTime = CurTime()
    if currentTime - lastThink < KYBER.Optimization.Config.THINK_INTERVAL then
        return
    end
    
    lastThink = currentTime
    
    -- Run heavy calculations
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            KYBER.Optimization.SafeCall(function()
                if KYBER.Equipment then
                    KYBER.Equipment:GetCachedStats(ply)
                end
            end)
        end
    end
end

-- Initialize
function KYBER.Optimization.Initialize()
    -- Create caches
    KYBER.Optimization.CreateCache("equipment_stats", 1)
    KYBER.Optimization.CreateCache("inventory", 5)
    KYBER.Optimization.CreateCache("banking", 5)
    
    -- Start monitoring
    timer.Create("KyberPerformanceMonitor", 1, 0, KYBER.Optimization.MonitorPerformance)
    
    -- Start optimization
    timer.Create("KyberMemoryOptimize", 300, 0, KYBER.Optimization.OptimizeMemory)
    
    -- Start think optimization
    hook.Add("Think", "KyberOptimizedThink", KYBER.Optimization.OptimizedThink)
    
    -- Add shutdown hook
    hook.Add("ShutDown", "KyberOptimizationCleanup", function()
        KYBER.Optimization.OptimizeMemory()
    end)
end

-- Initialize on load
KYBER.Optimization.Initialize() 