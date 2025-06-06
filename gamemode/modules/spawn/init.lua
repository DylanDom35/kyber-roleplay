-- Spawn module initialization
KYBER.Spawn = KYBER.Spawn or {}

-- Spawn module configuration
KYBER.Spawn.Config = {
    DefaultSpawnPoints = {
        Vector(0, 0, 0),
        Vector(100, 100, 0),
        Vector(-100, 100, 0),
        Vector(100, -100, 0),
        Vector(-100, -100, 0)
    },
    SpawnProtection = {
        Enabled = true,
        Duration = 5, -- seconds
        Invulnerable = true,
        NoCollide = true
    },
    DefaultLoadout = {
        weapons = {
            "weapon_crowbar",
            "weapon_pistol"
        },
        ammo = {
            ["Pistol"] = 60
        }
    },
    RespawnDelay = 3, -- seconds
    MaxSpawnAttempts = 5
}

-- Spawn module functions
function KYBER.Spawn:Initialize()
    print("[Kyber] Spawn module initialized")
    return true
end

function KYBER.Spawn:GetSpawnPoint(ply)
    if not IsValid(ply) then return nil end
    
    -- Try to find a valid spawn point
    local spawnPoints = self:GetSpawnPoints()
    local attempts = 0
    
    while attempts < self.Config.MaxSpawnAttempts do
        local spawnPoint = table.Random(spawnPoints)
        local trace = util.TraceLine({
            start = spawnPoint + Vector(0, 0, 32),
            endpos = spawnPoint + Vector(0, 0, -32),
            filter = function(ent)
                return ent:IsPlayer() and ent != ply
            end
        })
        
        if not trace.Hit then
            return spawnPoint
        end
        
        attempts = attempts + 1
    end
    
    -- If no valid spawn point found, return a default one
    return table.Random(self.Config.DefaultSpawnPoints)
end

function KYBER.Spawn:GetSpawnPoints()
    -- Get all info_player_start entities
    local spawnPoints = {}
    for _, ent in ipairs(ents.FindByClass("info_player_start")) do
        table.insert(spawnPoints, ent:GetPos())
    end
    
    -- If no spawn points found, use defaults
    if #spawnPoints == 0 then
        spawnPoints = self.Config.DefaultSpawnPoints
    end
    
    return spawnPoints
end

function KYBER.Spawn:SpawnPlayer(ply)
    if not IsValid(ply) then return false end
    
    -- Get spawn point
    local spawnPoint = self:GetSpawnPoint(ply)
    if not spawnPoint then return false end
    
    -- Set spawn position
    ply:SetPos(spawnPoint)
    ply:SetEyeAngles(Angle(0, 0, 0))
    
    -- Give loadout
    self:GiveLoadout(ply)
    
    -- Apply spawn protection
    if self.Config.SpawnProtection.Enabled then
        self:ApplySpawnProtection(ply)
    end
    
    return true
end

function KYBER.Spawn:GiveLoadout(ply)
    if not IsValid(ply) then return false end
    
    -- Strip existing weapons
    ply:StripWeapons()
    
    -- Give weapons
    for _, weapon in ipairs(self.Config.DefaultLoadout.weapons) do
        ply:Give(weapon)
    end
    
    -- Give ammo
    for ammoType, amount in pairs(self.Config.DefaultLoadout.ammo) do
        ply:SetAmmo(amount, ammoType)
    end
    
    -- Set spawn protection flags
    if self.Config.SpawnProtection.Invulnerable then
        ply:GodEnable()
    end
    
    if self.Config.SpawnProtection.NoCollide then
        ply:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    end
    
    -- Create protection timer
    timer.Create("Kyber_SpawnProtection_" .. ply:SteamID(), self.Config.SpawnProtection.Duration, 1, function()
        if IsValid(ply) then
            self:RemoveSpawnProtection(ply)
        end
    end)
    
    return true
end

function KYBER.Spawn:RemoveSpawnProtection(ply)
    if not IsValid(ply) then return false end
    
    -- Remove protection flags
    if self.Config.SpawnProtection.Invulnerable then
        ply:GodDisable()
    end
    
    if self.Config.SpawnProtection.NoCollide then
        ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    end
    
    -- Remove timer
    timer.Remove("Kyber_SpawnProtection_" .. ply:SteamID())
    
    return true
end

-- Initialize the module
KYBER.Spawn:Initialize() 