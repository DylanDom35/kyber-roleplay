-- Module loader system
KYBER.Modules = KYBER.Modules or {
    loaded = {},
    dependencies = {},
    loadOrder = {}
}

-- Register a module and its dependencies
function KYBER.Modules:Register(name, dependencies)
    self.dependencies[name] = dependencies or {}
end

-- Load a module and its dependencies
function KYBER.Modules:Load(name)
    if self.loaded[name] then return true end
    
    -- Check dependencies
    local deps = self.dependencies[name] or {}
    for _, dep in ipairs(deps) do
        if not self.loaded[dep] then
            if not self:Load(dep) then
                print("[Kyber] Failed to load dependency " .. dep .. " for module " .. name)
                return false
            end
        end
    end
    
    -- Load the module
    local path = "kyber/gamemode/modules/" .. name .. "/init.lua"
    local success, err = pcall(include, path)
    
    if success then
        self.loaded[name] = true
        table.insert(self.loadOrder, name)
        print("[Kyber] Loaded module: " .. name)
        return true
    else
        print("[Kyber] Failed to load module " .. name .. ": " .. tostring(err))
        return false
    end
end

-- Get load order for debugging
function KYBER.Modules:GetLoadOrder()
    return self.loadOrder
end 