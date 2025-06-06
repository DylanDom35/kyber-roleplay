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

-- Load a single module
function KYBER.LoadModule(moduleName)
    local modulePath = "kyber/gamemode/modules/" .. moduleName
    local initPath = modulePath .. "/init.lua"
    
    if not file.Exists(initPath, "LUA") then
        KYBER.LogError("Module not found: " .. moduleName .. " (Path: " .. initPath .. ")")
        return false
    end
    
    -- Create module table
    KYBER.Modules[moduleName] = KYBER.Modules[moduleName] or {
        name = moduleName,
        files = {},
        errors = {},
        state = MODULE_STATES.UNLOADED
    }
    
    local module = KYBER.Modules[moduleName]
    
    -- Load init file
    local success, err = pcall(function()
        if SERVER then
            AddCSLuaFile(initPath)
        end
        include(initPath)
    end)
    
    if not success then
        module.state = MODULE_STATES.ERROR
        table.insert(module.errors, "Error loading init file: " .. tostring(err))
        KYBER.LogError("Failed to load module " .. moduleName .. ": " .. tostring(err))
        return false
    end
    
    -- Load additional files
    local files, _ = file.Find(modulePath .. "/*.lua", "LUA")
    if files then
        for _, file in ipairs(files) do
            if file ~= "init.lua" then
                local filePath = modulePath .. "/" .. file
                local success, err = pcall(function()
                    if SERVER then
                        AddCSLuaFile(filePath)
                    end
                    include(filePath)
                end)
                
                if not success then
                    table.insert(module.errors, "Error loading " .. file .. ": " .. tostring(err))
                    KYBER.LogError("Failed to load file " .. filePath .. ": " .. tostring(err))
                else
                    table.insert(module.files, file)
                end
            end
        end
    end
    
    module.state = MODULE_STATES.LOADED
    return true
end

-- Load all modules
function KYBER.LoadAllModules()
    local modulesPath = "kyber/gamemode/modules"
    local modules, _ = file.Find(modulesPath .. "/*", "LUA")

    if not modules then
        KYBER.LogError("No modules found in " .. modulesPath)
        return false
    end

    -- Load each module
    for _, moduleName in ipairs(modules) do
        if file.Exists(modulesPath .. "/" .. moduleName .. "/init.lua", "LUA") then
            if not KYBER.LoadModule(moduleName) then
                KYBER.LogError("Failed to load module: " .. moduleName)
            end
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
        errors = module.errors
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

    return KYBER.LoadModule(moduleName)
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

-- Initialize module loader
print("[Kyber] Module loader initialized") 