-- kyber/gamemode/shared.lua

-- Gamemode info
GM.Name = "Kyber RP"
GM.Author = "Kyber Development Team"
GM.Email = ""
GM.Website = ""
GM.Base = "base" -- Set base gamemode

-- Initialize KYBER table
KYBER = KYBER or {}

-- Utility functions
function KYBER:IsValidPlayer(ply)
    return IsValid(ply) and ply:IsPlayer()
end

function KYBER:GetPlayerFaction(ply)
    if not self:IsValidPlayer(ply) then return nil end
    local factionID = ply:GetNWString("kyber_faction", "")
    return self.Factions[factionID]
end

function KYBER:GetPlayerRank(ply)
    if not self:IsValidPlayer(ply) then return nil end
    return ply:GetNWString("kyber_rank", "")
end

-- Character system utilities
function KYBER:GetCharacterData(ply)
    if not self:IsValidPlayer(ply) then return nil end
    return ply.KyberCharacter
end

function KYBER:SetCharacterData(ply, data)
    if not self:IsValidPlayer(ply) then return false end
    ply.KyberCharacter = data
    return true
end

function KYBER:HasCharacter(ply)
    if not self:IsValidPlayer(ply) then return false end
    return ply.KyberCharacter ~= nil
end

-- Basic faction definitions (shared between client and server)
-- These are now just examples/templates that players can reference
KYBER.Factions = {
    ["jedi"] = {
        name = "Jedi Order",
        color = Color(100, 200, 255),
        description = "Guardians of peace and justice",
        isTemplate = true -- Marks this as a template faction
    },
    ["sith"] = {
        name = "Sith Order",
        color = Color(255, 50, 50),
        description = "Dark side Force users",
        isTemplate = true
    },
    ["imperial"] = {
        name = "Imperial Remnant",
        color = Color(150, 150, 150),
        description = "Remains of the Galactic Empire",
        isTemplate = true
    },
    ["rebel"] = {
        name = "Rebel Alliance",
        color = Color(255, 150, 50),
        description = "Freedom fighters",
        isTemplate = true
    }
}

-- Player Groups System (for organic group formation)
KYBER.Groups = {
    -- Groups are stored in a table with the group ID as the key
    -- Each group has its own structure and rules
    Create = function(name, leader)
        if not KYBER:IsValidPlayer(leader) then return nil end
        
        local groupID = "group_" .. os.time() .. "_" .. math.random(1000, 9999)
        local group = {
            id = groupID,
            name = name,
            leader = leader:SteamID(),
            members = {leader:SteamID()},
            created = os.time(),
            description = "",
            color = Color(255, 255, 255),
            
            -- Enhanced customization options
            customization = {
                logo = "", -- Path to custom logo
                banner = "", -- Path to custom banner
                tag = "", -- Group tag/short name
                theme = {
                    primary = Color(255, 255, 255),
                    secondary = Color(200, 200, 200),
                    accent = Color(100, 100, 100)
                },
                uniforms = {
                    enabled = false,
                    required = false,
                    options = {
                        {
                            name = "Standard",
                            model = "models/player/group01/male_01.mdl",
                            bodygroups = {},
                            materials = {},
                            colors = {
                                primary = Color(255, 255, 255),
                                secondary = Color(200, 200, 200)
                            }
                        }
                    }
                },
                ranks = {
                    {
                        name = "Member",
                        color = Color(200, 200, 200),
                        prefix = "",
                        suffix = "",
                        permissions = {},
                        customBadge = "",
                        salary = 0
                    },
                    {
                        name = "Officer",
                        color = Color(150, 150, 255),
                        prefix = "",
                        suffix = "",
                        permissions = {},
                        customBadge = "",
                        salary = 0
                    },
                    {
                        name = "Leader",
                        color = Color(255, 200, 50),
                        prefix = "",
                        suffix = "",
                        permissions = {},
                        customBadge = "",
                        salary = 0
                    }
                },
                chat = {
                    prefix = "",
                    suffix = "",
                    color = Color(255, 255, 255),
                    format = "{rank} {name}: {message}"
                },
                announcements = {
                    style = "default",
                    color = Color(255, 255, 255),
                    sound = ""
                }
            },
            
            -- Enhanced permissions system
            permissions = {
                -- Basic permissions
                invite = {"Officer", "Leader"},
                kick = {"Officer", "Leader"},
                promote = {"Leader"},
                demote = {"Leader"},
                disband = {"Leader"},
                
                -- Resource permissions
                withdraw = {"Officer", "Leader"},
                deposit = {"Member", "Officer", "Leader"},
                manageResources = {"Officer", "Leader"},
                
                -- Territory permissions
                claimTerritory = {"Officer", "Leader"},
                unclaimTerritory = {"Leader"},
                buildInTerritory = {"Member", "Officer", "Leader"},
                destroyInTerritory = {"Officer", "Leader"},
                
                -- Custom permissions
                custom = {}
            },
            
            -- Enhanced territory system
            territory = {
                claims = {}, -- List of claimed areas
                maxClaims = 3, -- Maximum number of territories
                influence = 0, -- Group's influence in the galaxy
                protectedAreas = {}, -- Areas with special protection
                buildRules = {
                    allowedProps = {}, -- List of allowed props
                    restrictedProps = {}, -- List of restricted props
                    maxProps = 100 -- Maximum props per territory
                },
                -- New territory features
                resourceNodes = {
                    types = {
                        ["kyber_crystal"] = {
                            name = "Kyber Crystal Deposit",
                            rarity = "rare",
                            yield = 1,
                            respawnTime = 3600,
                            requiredTool = "mining_laser"
                        },
                        ["beskar"] = {
                            name = "Beskar Vein",
                            rarity = "epic",
                            yield = 1,
                            respawnTime = 7200,
                            requiredTool = "mining_laser"
                        },
                        ["credits"] = {
                            name = "Credit Cache",
                            rarity = "common",
                            yield = 1000,
                            respawnTime = 1800,
                            requiredTool = "lockpick"
                        }
                    },
                    nodes = {} -- Active resource nodes
                },
                specialAreas = {
                    types = {
                        ["temple"] = {
                            name = "Ancient Temple",
                            effects = {
                                forceRegen = 1.5,
                                meditationBonus = true
                            }
                        },
                        ["market"] = {
                            name = "Trading Post",
                            effects = {
                                tradeBonus = 1.2,
                                taxRate = 0.1
                            }
                        },
                        ["shipyard"] = {
                            name = "Shipyard",
                            effects = {
                                shipRepair = true,
                                shipModification = true
                            }
                        }
                    },
                    areas = {} -- Active special areas
                },
                defenses = {
                    turrets = {},
                    shields = {},
                    sensors = {},
                    maxDefenses = 10
                },
                infrastructure = {
                    powerGrid = {},
                    communicationNetwork = {},
                    transportSystem = {}
                }
            },
            
            -- Enhanced reputation system
            reputation = {
                score = 0, -- Overall reputation score
                history = {}, -- Reputation change history
                relationships = {}, -- Relationships with other groups
                achievements = {}, -- Group achievements
                influence = {
                    military = 0,
                    economic = 0,
                    political = 0,
                    cultural = 0
                },
                -- New reputation features
                standing = {
                    ["jedi"] = 0,
                    ["sith"] = 0,
                    ["imperial"] = 0,
                    ["rebel"] = 0
                },
                reputationEvents = {}, -- Major events affecting reputation
                reputationModifiers = {}, -- Active modifiers
                reputationGoals = {} -- Reputation objectives
            },
            
            -- Enhanced resource system
            resources = {
                credits = 0,
                materials = {},
                inventory = {},
                sharedItems = {},
                resourceRules = {
                    withdrawalLimits = {
                        Member = 1000,
                        Officer = 5000,
                        Leader = 10000
                    },
                    depositLimits = {
                        Member = 5000,
                        Officer = 20000,
                        Leader = 100000
                    }
                },
                -- New resource features
                production = {
                    facilities = {},
                    recipes = {},
                    efficiency = 1.0,
                    workers = {}
                },
                storage = {
                    warehouses = {},
                    capacity = 1000,
                    items = {}
                },
                trade = {
                    contracts = {},
                    prices = {},
                    history = {}
                },
                research = {
                    projects = {},
                    discoveries = {},
                    technology = {}
                }
            },
            
            -- Enhanced diplomacy system
            diplomacy = {
                allies = {},
                enemies = {},
                neutral = {},
                treaties = {},
                tradeAgreements = {},
                warDeclarations = {},
                -- New diplomacy features
                diplomaticStatus = {
                    type = "neutral", -- neutral, allied, hostile
                    modifiers = {},
                    history = {}
                },
                alliances = {
                    active = {},
                    pending = {},
                    history = {}
                },
                conflicts = {
                    active = {},
                    history = {},
                    casualties = {}
                },
                negotiations = {
                    active = {},
                    history = {},
                    proposals = {}
                },
                embassies = {
                    locations = {},
                    staff = {},
                    functions = {}
                }
            },
            
            -- Enhanced event system
            events = {
                scheduled = {},
                active = {},
                history = {},
                -- New event features
                types = {
                    ["meeting"] = {
                        name = "Group Meeting",
                        duration = 3600,
                        maxParticipants = 50,
                        requirements = {}
                    },
                    ["training"] = {
                        name = "Training Session",
                        duration = 7200,
                        maxParticipants = 20,
                        requirements = {
                            location = "training_ground"
                        }
                    },
                    ["celebration"] = {
                        name = "Celebration",
                        duration = 14400,
                        maxParticipants = 100,
                        requirements = {
                            resources = {
                                credits = 5000
                            }
                        }
                    }
                },
                rewards = {
                    experience = 0,
                    credits = 0,
                    items = {},
                    reputation = 0
                },
                participation = {
                    required = false,
                    minimum = 0,
                    maximum = 100
                }
            },
            
            -- Activity tracking
            activity = {
                lastActive = os.time(),
                memberActivity = {},
                events = {},
                announcements = {},
                -- New activity features
                statistics = {
                    totalMembers = 1,
                    activeMembers = 1,
                    totalEvents = 0,
                    totalResources = 0
                },
                milestones = {
                    achieved = {},
                    pending = {},
                    rewards = {}
                },
                leaderboard = {
                    members = {},
                    contributions = {},
                    achievements = {}
                }
            }
        }
        
        -- Store the group
        KYBER.Groups[groupID] = group
        
        -- Set the player's group
        leader:SetNWString("kyber_group", groupID)
        leader:SetNWString("kyber_group_rank", "Leader")
        
        return groupID
    end,
    
    -- Basic group management
    Get = function(groupID)
        return KYBER.Groups[groupID]
    end,
    
    GetPlayerGroup = function(ply)
        if not KYBER:IsValidPlayer(ply) then return nil end
        local groupID = ply:GetNWString("kyber_group", "")
        return KYBER.Groups[groupID]
    end,
    
    GetPlayerRank = function(ply)
        if not KYBER:IsValidPlayer(ply) then return nil end
        return ply:GetNWString("kyber_group_rank", "")
    end,
    
    -- Enhanced member management
    AddMember = function(groupID, ply, inviter)
        local group = KYBER.Groups[groupID]
        if not group then return false end
        
        -- Check if inviter has permission
        local inviterRank = KYBER.Groups.GetPlayerRank(inviter)
        if not table.HasValue(group.permissions.invite, inviterRank) then
            return false
        end
        
        -- Add member
        table.insert(group.members, ply:SteamID())
        ply:SetNWString("kyber_group", groupID)
        ply:SetNWString("kyber_group_rank", "Member")
        
        -- Update activity
        group.activity.memberActivity[ply:SteamID()] = {
            joined = os.time(),
            lastActive = os.time()
        }
        
        -- Update statistics
        group.activity.statistics.totalMembers = group.activity.statistics.totalMembers + 1
        group.activity.statistics.activeMembers = group.activity.statistics.activeMembers + 1
        
        return true
    end,
    
    RemoveMember = function(groupID, ply, remover)
        local group = KYBER.Groups[groupID]
        if not group then return false end
        
        -- Check if remover has permission
        local removerRank = KYBER.Groups.GetPlayerRank(remover)
        if not table.HasValue(group.permissions.kick, removerRank) then
            return false
        end
        
        -- Remove member
        for k, v in ipairs(group.members) do
            if v == ply:SteamID() then
                table.remove(group.members, k)
                break
            end
        end
        
        -- Clear member data
        ply:SetNWString("kyber_group", "")
        ply:SetNWString("kyber_group_rank", "")
        group.activity.memberActivity[ply:SteamID()] = nil
        
        -- Update statistics
        group.activity.statistics.activeMembers = group.activity.statistics.activeMembers - 1
        
        return true
    end,
    
    -- Enhanced territory management
    ClaimTerritory = function(groupID, pos, radius, claimer)
        local group = KYBER.Groups[groupID]
        if not group then return false end
        
        -- Check if claimer has permission
        local claimerRank = KYBER.Groups.GetPlayerRank(claimer)
        if not table.HasValue(group.permissions.claimTerritory, claimerRank) then
            return false
        end
        
        -- Check if group can claim more territory
        if #group.territory.claims >= group.territory.maxClaims then
            return false
        end
        
        -- Add claim
        local claim = {
            pos = pos,
            radius = radius,
            claimed = os.time(),
            claimedBy = claimer:SteamID(),
            resources = {},
            specialAreas = {},
            defenses = {},
            infrastructure = {}
        }
        
        table.insert(group.territory.claims, claim)
        
        return true
    end,
    
    -- Enhanced resource management
    AddResource = function(groupID, resourceType, amount, contributor)
        local group = KYBER.Groups[groupID]
        if not group then return false end
        
        -- Check if contributor has permission
        local contributorRank = KYBER.Groups.GetPlayerRank(contributor)
        if not table.HasValue(group.permissions.deposit, contributorRank) then
            return false
        end
        
        -- Check deposit limits
        if amount > group.resources.resourceRules.depositLimits[contributorRank] then
            return false
        end
        
        -- Add resource
        if resourceType == "credits" then
            group.resources.credits = group.resources.credits + amount
        else
            group.resources.materials[resourceType] = (group.resources.materials[resourceType] or 0) + amount
        end
        
        -- Update statistics
        group.activity.statistics.totalResources = group.activity.statistics.totalResources + amount
        
        return true
    end,
    
    -- Enhanced reputation management
    UpdateReputation = function(groupID, amount, reason, updater)
        local group = KYBER.Groups[groupID]
        if not group then return false end
        
        -- Add to history
        table.insert(group.reputation.history, {
            amount = amount,
            reason = reason,
            time = os.time(),
            updatedBy = updater:SteamID()
        })
        
        -- Update score
        group.reputation.score = group.reputation.score + amount
        
        -- Check for reputation events
        if math.abs(amount) >= 100 then
            table.insert(group.reputation.reputationEvents, {
                type = amount > 0 and "major_positive" or "major_negative",
                amount = amount,
                reason = reason,
                time = os.time()
            })
        end
        
        return true
    end,
    
    -- Enhanced event management
    CreateEvent = function(groupID, eventType, data, creator)
        local group = KYBER.Groups[groupID]
        if not group then return false end
        
        -- Check if event type exists
        if not group.events.types[eventType] then
            return false
        end
        
        -- Create event
        local event = {
            type = eventType,
            data = data,
            creator = creator:SteamID(),
            created = os.time(),
            participants = {},
            status = "scheduled"
        }
        
        -- Add to scheduled events
        table.insert(group.events.scheduled, event)
        
        -- Update statistics
        group.activity.statistics.totalEvents = group.activity.statistics.totalEvents + 1
        
        return true
    end,
    
    -- Custom permission management
    AddCustomPermission = function(groupID, permissionName, allowedRanks, adder)
        local group = KYBER.Groups[groupID]
        if not group then return false end
        
        -- Check if adder has permission
        local adderRank = KYBER.Groups.GetPlayerRank(adder)
        if adderRank ~= "Leader" then
            return false
        end
        
        -- Add custom permission
        group.permissions.custom[permissionName] = allowedRanks
        
        return true
    end
}

-- Species definitions
KYBER.Species = {
    ["Human"] = {
        name = "Human",
        description = "The most common species in the galaxy",
        attributes = {
            strength = 1.0,
            agility = 1.0,
            intelligence = 1.0,
            charisma = 1.0
        }
    },
    ["Twi'lek"] = {
        name = "Twi'lek",
        description = "Known for their head-tails and natural charm",
        attributes = {
            strength = 0.9,
            agility = 1.1,
            intelligence = 1.0,
            charisma = 1.2
        }
    },
    ["Zabrak"] = {
        name = "Zabrak",
        description = "Distinguished by their facial horns and natural resilience",
        attributes = {
            strength = 1.2,
            agility = 1.0,
            intelligence = 1.0,
            charisma = 0.9
        }
    },
    ["Wookiee"] = {
        name = "Wookiee",
        description = "Strong and loyal warriors from Kashyyyk",
        attributes = {
            strength = 1.5,
            agility = 0.8,
            intelligence = 1.0,
            charisma = 0.9
        }
    },
    ["Trandoshan"] = {
        name = "Trandoshan",
        description = "Reptilian species known for their hunting skills",
        attributes = {
            strength = 1.3,
            agility = 1.1,
            intelligence = 0.9,
            charisma = 0.8
        }
    },
    ["Miraluka"] = {
        name = "Miraluka",
        description = "Force-sensitive species that can see through the Force",
        attributes = {
            strength = 0.9,
            agility = 1.0,
            intelligence = 1.2,
            charisma = 1.1
        }
    },
    ["Sith Pureblood"] = {
        name = "Sith Pureblood",
        description = "Ancient species with strong connection to the dark side",
        attributes = {
            strength = 1.1,
            agility = 1.0,
            intelligence = 1.1,
            charisma = 1.0
        }
    }
}

-- Network strings
if SERVER then
    util.AddNetworkString("Kyber_ShowLoadingScreen")
    util.AddNetworkString("Kyber_Character_OpenCreation")
    util.AddNetworkString("Kyber_Character_OpenSelection")
    util.AddNetworkString("Kyber_Character_Select")
    util.AddNetworkString("Kyber_Character_Delete")
    util.AddNetworkString("Kyber_Character_Load")
    
    -- Group-related network strings
    util.AddNetworkString("Kyber_Group_Create")
    util.AddNetworkString("Kyber_Group_Invite")
    util.AddNetworkString("Kyber_Group_Leave")
    util.AddNetworkString("Kyber_Group_Update")
    util.AddNetworkString("Kyber_Group_ClaimTerritory")
    util.AddNetworkString("Kyber_Group_UnclaimTerritory")
    util.AddNetworkString("Kyber_Group_AddResource")
    util.AddNetworkString("Kyber_Group_RemoveResource")
    util.AddNetworkString("Kyber_Group_UpdateReputation")
    util.AddNetworkString("Kyber_Group_UpdateCustomization")
    util.AddNetworkString("Kyber_Group_UpdatePermissions")
    util.AddNetworkString("Kyber_Group_CreateEvent")
    util.AddNetworkString("Kyber_Group_JoinEvent")
    util.AddNetworkString("Kyber_Group_LeaveEvent")
    util.AddNetworkString("Kyber_Group_UpdateEvent")
    util.AddNetworkString("Kyber_Group_ResourceNode")
    util.AddNetworkString("Kyber_Group_SpecialArea")
    util.AddNetworkString("Kyber_Group_Diplomacy")
end

KYBER.Credits = {
    Get = function(ply) return ply:GetNWInt("kyber_credits", 0) end,
    Set = function(ply, amount) ply:SetNWInt("kyber_credits", amount) end,
    Add = function(ply, amount) 
        local current = KYBER.Credits.Get(ply)
        KYBER.Credits.Set(ply, current + amount)
    end,
    Remove = function(ply, amount)
        local current = KYBER.Credits.Get(ply)
        KYBER.Credits.Set(ply, math.max(0, current - amount))
    end
}

function KYBER.SQL.Query(query, callback, errorCallback)
    -- Add timeout
    local timeout = timer.Simple(30, function()
        if errorCallback then
            errorCallback("Query timeout")
        end
    end)
    
    -- Add connection pool
    local conn = KYBER.SQL.GetConnection()
    if not conn then
        if errorCallback then
            errorCallback("No database connection available")
        end
        return false
    end
    
    -- Execute query with error handling
    local success, result = pcall(function()
        return conn:query(query)
    end)
    
    -- Cleanup
    KYBER.SQL.ReleaseConnection(conn)
    timer.Remove(timeout)
    
    if not success then
        if errorCallback then
            errorCallback(result)
        end
        return false
    end
    
    if callback then
        callback(result)
    end
    
    return true
end

function KYBER.SQL.Transaction(queries, callback, errorCallback)
    local conn = KYBER.SQL.GetConnection()
    if not conn then
        if errorCallback then
            errorCallback("No database connection available")
        end
        return false
    end
    
    -- Start transaction
    conn:query("START TRANSACTION")
    
    local success = true
    for _, query in ipairs(queries) do
        local result = conn:query(query)
        if not result then
            success = false
            break
        end
    end
    
    if success then
        conn:query("COMMIT")
        if callback then callback() end
    else
        conn:query("ROLLBACK")
        if errorCallback then errorCallback("Transaction failed") end
    end
    
    KYBER.SQL.ReleaseConnection(conn)
    return success
end

function KYBER.LogError(message, data)
    local log = {
        timestamp = os.time(),
        level = "ERROR",
        message = message,
        data = data
    }
    
    -- Log to file
    file.Append("kyber/logs/error.log", util.TableToJSON(log) .. "\n")
    
    -- Log to console
    print("[KYBER ERROR] " .. message)
    
    -- Notify admins if critical
    if data and data.critical then
        KYBER.Admin.Notify(log)
    end
end

function KYBER.Character.Validate(data)
    if not data then return false end
    
    -- Validate required fields
    if not data.name or not data.species then
        return false
    end
    
    -- Validate name format
    if not string.match(data.name, "^[%w%s-]{3,32}$") then
        return false
    end
    
    -- Validate species
    if not KYBER.Config.Get("species")[data.species] then
        return false
    end
    
    return true
end

function KYBER.UI.Panel:Cleanup()
    -- Remove all timers
    for _, timerName in ipairs(self.timers or {}) do
        timer.Remove(timerName)
    end
    
    -- Remove all hooks
    for _, hookName in ipairs(self.hooks or {}) do
        hook.Remove(hookName)
    end
    
    -- Remove all children
    for _, child in pairs(self:GetChildren()) do
        if IsValid(child) then
            child:Remove()
        end
    end
    
    -- Remove panel
    self:Remove()
end

-- Fixed version
local function CreateSafeTimer(name, interval, repetitions, callback)
    -- Remove existing timer if it exists
    timer.Remove(name)
    
    -- Create new timer with cleanup
    timer.Create(name, interval, repetitions, function()
        if not IsValid(game.GetWorld()) then
            timer.Remove(name)
            return
        end
        
        local success, err = pcall(callback)
        if not success then
            print("[KYBER ERROR] Timer " .. name .. " failed: " .. tostring(err))
            timer.Remove(name)
        end
    end)
end

-- Add to your network handling
local messageCooldowns = {}
local function IsRateLimited(ply, messageType, cooldown)
    local key = ply:SteamID64() .. "_" .. messageType
    local lastTime = messageCooldowns[key] or 0
    
    if CurTime() - lastTime < cooldown then
        return true
    end
    
    messageCooldowns[key] = CurTime()
    return false
end

-- Use in network handlers
net.Receive("Kyber_SomeMessage", function(len, ply)
    if IsRateLimited(ply, "SomeMessage", 0.5) then return end
    -- Handle message
end)

-- Add to your gamemode
function KYBER.RecoverFromError()
    -- Clear all caches
    for _, system in pairs(KYBER) do
        if type(system) == "table" and system.ClearCache then
            system:ClearCache()
        end
    end
    
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

-- Add error handling to critical functions
function KYBER.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        print("[KYBER ERROR] " .. tostring(result))
        KYBER.RecoverFromError()
        return false
    end
    return result
end

-- Add to your gamemode
function KYBER.Cleanup()
    -- Remove all timers
    for _, timerName in ipairs(timer.GetTable()) do
        if string.find(timerName, "Kyber") then
            timer.Remove(timerName)
        end
    end
    
    -- Remove all hooks
    for _, hookName in ipairs(hook.GetTable()) do
        if string.find(hookName, "Kyber") then
            hook.Remove(hookName)
        end
    end
    
    -- Cleanup UI
    for _, panel in pairs(KYBER.UI.ActivePanels) do
        if IsValid(panel) then
            panel:Cleanup()
        end
    end
    
    -- Clear tables
    KYBER.UI.ActivePanels = {}
    KYBER.Cache = {}
end

hook.Add("ShutDown", "KyberCleanup", KYBER.Cleanup)

-- Add to your UI system
local lastUpdate = 0
local UPDATE_INTERVAL = 1/30 -- 30 FPS

function KYBER.UI.Update()
    local currentTime = CurTime()
    if currentTime - lastUpdate < UPDATE_INTERVAL then
        return
    end
    
    lastUpdate = currentTime
    
    -- Update UI elements
    for _, panel in pairs(KYBER.UI.ActivePanels) do
        if IsValid(panel) then
            panel:Update()
        else
            KYBER.UI.ActivePanels[panel] = nil
        end
    end
end

hook.Add("Think", "KyberUIUpdate", KYBER.UI.Update)

-- Add to your file operations
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

-- Use in your file operations
function KYBER.Banking:Save(ply)
    if not IsValid(ply) or not ply.KyberBanking then return end
    
    local path = "kyber/banking/" .. ply:SteamID64() .. ".json"
    
    SafeFileOperation(path, function()
        -- Create backup
        if file.Exists(path, "DATA") then
            file.Write(path .. ".backup", file.Read(path, "DATA"))
        end
        
        -- Write new data
        file.Write(path, util.TableToJSON(ply.KyberBanking))
    end)
end

-- Add to your equipment system
local statCache = {}
local CACHE_DURATION = 1 -- seconds

function KYBER.Equipment:GetCachedStats(ply)
    local key = ply:SteamID64()
    local cache = statCache[key]
    
    if cache and (CurTime() - cache.time) < CACHE_DURATION then
        return cache.stats
    end
    
    local stats = self:CalculateStats(ply)
    statCache[key] = {
        time = CurTime(),
        stats = stats
    }
    
    return stats
end

-- Cleanup old cache entries
timer.Create("KyberEquipmentCacheCleanup", 60, 0, function()
    local currentTime = CurTime()
    for key, cache in pairs(statCache) do
        if (currentTime - cache.time) > CACHE_DURATION then
            statCache[key] = nil
        end
    end
end)

-- Add to your gamemode
function KYBER.MemoryOptimize()
    -- Clear unused caches
    for _, system in pairs(KYBER) do
        if type(system) == "table" and system.ClearCache then
            system:ClearCache()
        end
    end
    
    -- Force garbage collection
    collectgarbage("collect")
end

-- Run optimization periodically
timer.Create("KyberMemoryOptimize", 300, 0, KYBER.MemoryOptimize)

-- Add to your Think hooks
local lastThink = 0
local THINK_INTERVAL = 1/30 -- 30 FPS

function KYBER.OptimizedThink()
    local currentTime = CurTime()
    if currentTime - lastThink < THINK_INTERVAL then
        return
    end
    
    lastThink = currentTime
    
    -- Run heavy calculations
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            KYBER.Equipment:GetCachedStats(ply)
        end
    end
end

hook.Add("Think", "KyberOptimizedThink", KYBER.OptimizedThink)

-- Add to your inventory system
function KYBER.Inventory:GetPage(ply, page, pageSize)
    pageSize = pageSize or 10
    local start = (page - 1) * pageSize + 1
    local finish = start + pageSize - 1
    
    local items = {}
    for i = start, finish do
        if ply.KyberInventory[i] then
            items[i] = ply.KyberInventory[i]
        end
    end
    
    return items
end

-- Add to your gamemode
function KYBER.MonitorPerformance()
    local stats = {
        memory = collectgarbage("count"),
        players = #player.GetAll(),
        entities = #ents.GetAll(),
        timers = #timer.GetTable(),
        hooks = #hook.GetTable()
    }
    
    -- Log if any metric is concerning
    if stats.memory > 1000000 then -- 1GB
        print("[KYBER WARNING] High memory usage: " .. stats.memory .. "KB")
    end
    
    if stats.timers > 100 then
        print("[KYBER WARNING] High timer count: " .. stats.timers)
    end
    
    -- Store stats for analysis
    KYBER.PerformanceStats = KYBER.PerformanceStats or {}
    table.insert(KYBER.PerformanceStats, stats)
    
    -- Keep only last hour of stats
    if #KYBER.PerformanceStats > 3600 then
        table.remove(KYBER.PerformanceStats, 1)
    end
end

timer.Create("KyberPerformanceMonitor", 1, 0, KYBER.MonitorPerformance)