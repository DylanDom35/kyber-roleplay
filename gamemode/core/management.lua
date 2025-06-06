-- Core Management System for Kyber
-- Handles hooks, timers, network strings, file operations, and module dependencies

-- Initialize management systems
KYBER.Management = KYBER.Management or {}

-- Hook Management System
KYBER.Management.Hooks = {
    active = {},
    Add = function(self, name, id, func)
        if self.active[id] then
            hook.Remove(name, id)
        end
        hook.Add(name, id, func)
        self.active[id] = {name = name, func = func}
    end,
    Remove = function(self, id)
        if self.active[id] then
            hook.Remove(self.active[id].name, id)
            self.active[id] = nil
        end
    end,
    Cleanup = function(self)
        for id, data in pairs(self.active) do
            hook.Remove(data.name, id)
        end
        self.active = {}
    end
}

-- Timer Management System
KYBER.Management.Timers = {
    active = {},
    Create = function(self, name, interval, reps, func)
        if self.active[name] then
            timer.Remove(name)
        end
        timer.Create(name, interval, reps, function()
            if not IsValid(game.GetWorld()) then
                self:Remove(name)
                return
            end
            local success, err = pcall(func)
            if not success then
                print("[KYBER ERROR] Timer " .. name .. " failed: " .. tostring(err))
                self:Remove(name)
            end
        end)
        self.active[name] = true
    end,
    Remove = function(self, name)
        if self.active[name] then
            timer.Remove(name)
            self.active[name] = nil
        end
    end,
    Cleanup = function(self)
        for name in pairs(self.active) do
            timer.Remove(name)
        end
        self.active = {}
    end
}

-- Network String Registry
KYBER.Management.Network = {
    strings = {},
    Register = function(self, name)
        if not self.strings[name] then
            util.AddNetworkString(name)
            self.strings[name] = true
        end
    end,
    IsRegistered = function(self, name)
        return self.strings[name] or false
    end,
    Cleanup = function(self)
        self.strings = {}
    end
}

-- Safe File Operations
KYBER.Management.FileSystem = {
    Write = function(self, path, data)
        local tempPath = path .. ".tmp"
        if file.Write(tempPath, data) then
            if file.Exists(path, "DATA") then
                file.Delete(path)
            end
            return file.Rename(tempPath, path)
        end
        return false
    end,
    Read = function(self, path)
        if file.Exists(path, "DATA") then
            return file.Read(path, "DATA")
        end
        return nil
    end,
    Delete = function(self, path)
        if file.Exists(path, "DATA") then
            return file.Delete(path)
        end
        return false
    end,
    Exists = function(self, path)
        return file.Exists(path, "DATA")
    end
}

-- Module Dependency Resolution
KYBER.Management.ModuleLoader = {
    dependencies = {},
    AddDependency = function(self, module, dependsOn)
        self.dependencies[module] = self.dependencies[module] or {}
        table.insert(self.dependencies[module], dependsOn)
    end,
    GetLoadOrder = function(self)
        local order = {}
        local visited = {}
        local temp = {}
        
        local function visit(module)
            if temp[module] then
                error("Circular dependency detected: " .. module)
            end
            if visited[module] then return end
            
            temp[module] = true
            if self.dependencies[module] then
                for _, dep in ipairs(self.dependencies[module]) do
                    visit(dep)
                end
            end
            temp[module] = nil
            visited[module] = true
            table.insert(order, module)
        end
        
        for module in pairs(self.dependencies) do
            visit(module)
        end
        
        return order
    end,
    Cleanup = function(self)
        self.dependencies = {}
    end
}

-- Error Handling System
KYBER.Management.ErrorHandler = {
    errors = {},
    Handle = function(self, err, context)
        local errorData = {
            timestamp = os.time(),
            error = tostring(err),
            context = context,
            stack = debug.traceback()
        }
        
        table.insert(self.errors, errorData)
        
        -- Log to file
        KYBER.Management.FileSystem:Write(
            "kyber/logs/errors.log",
            util.TableToJSON(errorData) .. "\n"
        )
        
        -- Print to console
        print("[KYBER ERROR] " .. tostring(err))
        print("[KYBER ERROR] Context: " .. tostring(context))
        print("[KYBER ERROR] Stack: " .. errorData.stack)
        
        return errorData
    end,
    GetErrors = function(self)
        return self.errors
    end,
    ClearErrors = function(self)
        self.errors = {}
    end
}

-- State Management System
KYBER.Management.State = {
    states = {},
    Set = function(self, key, value)
        self.states[key] = value
    end,
    Get = function(self, key)
        return self.states[key]
    end,
    Remove = function(self, key)
        self.states[key] = nil
    end,
    Cleanup = function(self)
        self.states = {}
    end
}

-- Initialize all management systems
function KYBER.Management:Initialize()
    -- Create necessary directories
    if not file.Exists("kyber/logs", "DATA") then
        file.CreateDir("kyber/logs")
    end
    
    -- Register cleanup hooks
    KYBER.Management.Hooks:Add("ShutDown", "KyberManagementCleanup", function()
        self:Cleanup()
    end)
    
    print("[KYBER] Management systems initialized")
    return true
end

-- Cleanup all management systems
function KYBER.Management:Cleanup()
    KYBER.Management.Hooks:Cleanup()
    KYBER.Management.Timers:Cleanup()
    KYBER.Management.Network:Cleanup()
    KYBER.Management.ModuleLoader:Cleanup()
    KYBER.Management.State:Cleanup()
    print("[KYBER] Management systems cleaned up")
end

-- Initialize the management system
KYBER.Management:Initialize() 