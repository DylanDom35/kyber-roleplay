-- Initialize KYBER table if it doesn't exist
KYBER = KYBER or {}

-- Initialize Modules table
KYBER.Modules = KYBER.Modules or {}

-- Function to load a module
function KYBER.LoadModule(name)
    local modulePath = "kyber/gamemode/modules/" .. name .. "/init.lua"
    
    if not file.Exists(modulePath, "GAME") then
        print("[Kyber] Module not found: " .. name .. " (Path: " .. modulePath .. ")")
        return false
    end
    
    -- Create module table if it doesn't exist
    KYBER.Modules[name] = KYBER.Modules[name] or {}
    
    -- Load the module
    local success, module = pcall(function()
        return include(modulePath)
    end)
    
    if not success then
        print("[Kyber] Error loading module " .. name .. ": " .. tostring(module))
        return false
    end
    
    if not module then
        print("[Kyber] Module " .. name .. " returned nil")
        return false
    end
    
    -- Store the module
    KYBER.Modules[name] = module
    
    -- Initialize the module if it has an Initialize function
    if module.Initialize then
        local initSuccess, initErr = pcall(function()
            module:Initialize()
        end)
        
        if not initSuccess then
            print("[Kyber] Error initializing module " .. name .. ": " .. tostring(initErr))
            return false
        end
    end
    
    print("[Kyber] Successfully loaded module: " .. name)
    return true
end

-- Function to get a module
function KYBER.GetModule(name)
    if not KYBER.Modules[name] then
        print("[Kyber] Warning: Attempted to access non-existent module: " .. name)
        return nil
    end
    return KYBER.Modules[name]
end

-- Function to check if a module exists
function KYBER.HasModule(name)
    return KYBER.Modules[name] ~= nil
end

-- List of required modules
local requiredModules = {
    "character",
    "inventory",
    "equipment",
    "banking",
    "factions"
}

-- Load all required modules
for _, moduleName in ipairs(requiredModules) do
    KYBER.LoadModule(moduleName)
end

print("[Kyber] Module loader initialized") 