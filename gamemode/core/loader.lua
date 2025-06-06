-- kyber/gamemode/core/loader.lua
-- Module loader system

local KYBER = KYBER or {}

-- Module registry
KYBER.Modules = KYBER.Modules or {}

-- Module states
local MODULE_STATES = {
    UNLOADED = "unloaded",
    LOADING = "loading",
    LOADED = "loaded",
    ERROR = "error"
}

-- Module metadata
local moduleMetadata = {
    name = "",
    version = "",
    author = "",
    description = "",
    dependencies = {},
    loadOrder = 0
}

-- Create a new module
function KYBER.CreateModule(name, metadata)
    if KYBER.Modules[name] then
        KYBER.LogError("Module already exists: " .. name)
        return nil
    end

    local module = {
        name = name,
        metadata = metadata or {},
        state = MODULE_STATES.UNLOADED,
        files = {},
        errors = {},
        hooks = {},
        netstrings = {},
        concommands = {}
    }

    KYBER.Modules[name] = module
    return module
end

-- Load a module's files
function KYBER.LoadModuleFiles(moduleName, path)
    local module = KYBER.Modules[moduleName]
    if not module then
        KYBER.LogError("Module not found: " .. moduleName)
        return false
    end

    module.state = MODULE_STATES.LOADING

    -- Get all Lua files in the module directory
    local files, dirs = file.Find(path .. "/*.lua", "LUA")
    if not files then
        module.state = MODULE_STATES.ERROR
        table.insert(module.errors, "No files found in " .. path)
        return false
    end

    -- Sort files by load order
    table.sort(files, function(a, b)
        local aOrder = module.metadata.loadOrder or 0
        local bOrder = module.metadata.loadOrder or 0
        return aOrder < bOrder
    end)

    -- Load each file
    for _, file in ipairs(files) do
        local filePath = path .. "/" .. file
        local success, err = pcall(function()
            if SERVER then
                AddCSLuaFile(filePath)
            end
            if CLIENT or file:sub(1, 3) == "sv_" then
                include(filePath)
            end
        end)

        if not success then
            table.insert(module.errors, "Error loading " .. file .. ": " .. tostring(err))
        else
            table.insert(module.files, file)
        end
    end

    module.state = MODULE_STATES.LOADED
    return true
end

-- Initialize a module
function KYBER.InitModule(moduleName)
    local module = KYBER.Modules[moduleName]
    if not module then
        KYBER.LogError("Module not found: " .. moduleName)
        return false
    end

    -- Check dependencies
    for _, dep in ipairs(module.metadata.dependencies or {}) do
        if not KYBER.Modules[dep] or KYBER.Modules[dep].state ~= MODULE_STATES.LOADED then
            KYBER.LogError("Dependency not met for " .. moduleName .. ": " .. dep)
            return false
        end
    end

    -- Initialize module
    local success, err = pcall(function()
        if module.Init then
            module:Init()
        end
    end)

    if not success then
        module.state = MODULE_STATES.ERROR
        table.insert(module.errors, "Initialization error: " .. tostring(err))
        return false
    end

    return true
end

-- Load all modules
function KYBER.LoadAllModules()
    local modulesPath = "kyber-roleplay/gamemode/modules"
    local modules, _ = file.Find(modulesPath .. "/*", "LUA")

    if not modules then
        KYBER.LogError("No modules found in " .. modulesPath)
        return false
    end

    -- First pass: Create all modules
    for _, moduleDir in ipairs(modules) do
        local modulePath = modulesPath .. "/" .. moduleDir
        local initFile = modulePath .. "/init.lua"

        if file.Exists(initFile, "LUA") then
            local success, moduleData = pcall(function()
                return include(initFile)
            end)

            if success and moduleData then
                KYBER.CreateModule(moduleDir, moduleData)
            end
        end
    end

    -- Second pass: Load and initialize modules
    for moduleName, module in pairs(KYBER.Modules) do
        local modulePath = modulesPath .. "/" .. moduleName
        if not KYBER.LoadModuleFiles(moduleName, modulePath) then
            KYBER.LogError("Failed to load module: " .. moduleName)
        end
    end

    -- Third pass: Initialize modules
    for moduleName, module in pairs(KYBER.Modules) do
        if not KYBER.InitModule(moduleName) then
            KYBER.LogError("Failed to initialize module: " .. moduleName)
        end
    end

    return true
end

-- Get module status
function KYBER.GetModuleStatus(moduleName)
    local module = KYBER.Modules[moduleName]
    if not module then return nil end

    return {
        name = module.name,
        state = module.state,
        files = module.files,
        errors = module.errors,
        metadata = module.metadata
    }
end

-- Reload a module
function KYBER.ReloadModule(moduleName)
    local module = KYBER.Modules[moduleName]
    if not module then
        KYBER.LogError("Module not found: " .. moduleName)
        return false
    end

    -- Clear module state
    module.state = MODULE_STATES.UNLOADED
    module.files = {}
    module.errors = {}

    -- Reload module
    local modulePath = "kyber-roleplay/gamemode/modules/" .. moduleName
    if not KYBER.LoadModuleFiles(moduleName, modulePath) then
        return false
    end

    return KYBER.InitModule(moduleName)
end

-- Register a hook for a module
function KYBER.RegisterModuleHook(moduleName, hookName, callback)
    local module = KYBER.Modules[moduleName]
    if not module then
        KYBER.LogError("Module not found: " .. moduleName)
        return false
    end

    if not module.hooks[hookName] then
        module.hooks[hookName] = {}
    end

    table.insert(module.hooks[hookName], callback)
    hook.Add(hookName, "KYBER_" .. moduleName .. "_" .. hookName, callback)

    return true
end

-- Register a netstring for a module
function KYBER.RegisterModuleNetstring(moduleName, netstringName)
    local module = KYBER.Modules[moduleName]
    if not module then
        KYBER.LogError("Module not found: " .. moduleName)
        return false
    end

    if SERVER then
        util.AddNetworkString("KYBER_" .. moduleName .. "_" .. netstringName)
    end

    table.insert(module.netstrings, netstringName)
    return true
end

-- Register a concommand for a module
function KYBER.RegisterModuleConcommand(moduleName, commandName, callback)
    local module = KYBER.Modules[moduleName]
    if not module then
        KYBER.LogError("Module not found: " .. moduleName)
        return false
    end

    concommand.Add("kyber_" .. moduleName .. "_" .. commandName, callback)
    table.insert(module.concommands, commandName)

    return true
end

-- Error logging
function KYBER.LogError(message)
    if SERVER then
        print("[KYBER ERROR] " .. message)
    else
        chat.AddText(Color(255, 50, 50), "[KYBER ERROR] ", Color(255, 255, 255), message)
    end
end

-- Initialize the loader
if SERVER then
    KYBER.LoadAllModules()
end 