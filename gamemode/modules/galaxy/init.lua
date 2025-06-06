-- Galaxy module initialization
KYBER.Galaxy = KYBER.Galaxy or {}

-- Galaxy module configuration
KYBER.Galaxy.Config = {
    Planets = {
        ["coruscant"] = {
            name = "Coruscant",
            description = "The capital of the Galactic Republic",
            type = "ecumenopolis",
            faction = "republic",
            resources = {
                ["credits"] = 1000,
                ["technology"] = 800,
                ["population"] = 1000000
            },
            locations = {
                ["jedi_temple"] = {
                    name = "Jedi Temple",
                    description = "The headquarters of the Jedi Order",
                    type = "temple",
                    faction = "jedi",
                    requirements = {
                        forceAlignment = "light",
                        minForceLevel = 10
                    }
                },
                ["senate"] = {
                    name = "Galactic Senate",
                    description = "The center of galactic politics",
                    type = "government",
                    faction = "republic",
                    requirements = {
                        minReputation = 50
                    }
                }
            }
        },
        ["tatooine"] = {
            name = "Tatooine",
            description = "A desert planet in the Outer Rim",
            type = "desert",
            faction = "neutral",
            resources = {
                ["credits"] = 500,
                ["minerals"] = 300,
                ["population"] = 100000
            },
            locations = {
                ["mos_eisley"] = {
                    name = "Mos Eisley",
                    description = "A spaceport town",
                    type = "city",
                    faction = "neutral",
                    requirements = {}
                },
                ["jabba_palace"] = {
                    name = "Jabba's Palace",
                    description = "The residence of Jabba the Hutt",
                    type = "criminal",
                    faction = "hutt",
                    requirements = {
                        minReputation = 20
                    }
                }
            }
        },
        ["kashyyyk"] = {
            name = "Kashyyyk",
            description = "The homeworld of the Wookiees",
            type = "forest",
            faction = "republic",
            resources = {
                ["credits"] = 300,
                ["wood"] = 1000,
                ["population"] = 500000
            },
            locations = {
                ["wookiee_village"] = {
                    name = "Wookiee Village",
                    description = "A traditional Wookiee settlement",
                    type = "settlement",
                    faction = "wookiee",
                    requirements = {}
                },
                ["shadowlands"] = {
                    name = "Shadowlands",
                    description = "The dangerous lower levels of the forest",
                    type = "wilderness",
                    faction = "neutral",
                    requirements = {
                        minLevel = 20
                    }
                }
            }
        }
    },
    SpaceStations = {
        ["death_star"] = {
            name = "Death Star",
            description = "The Empire's ultimate weapon",
            type = "battle_station",
            faction = "imperial",
            resources = {
                ["credits"] = 5000,
                ["technology"] = 2000,
                ["personnel"] = 1000000
            },
            locations = {
                ["throne_room"] = {
                    name = "Throne Room",
                    description = "The Emperor's personal chamber",
                    type = "command",
                    faction = "imperial",
                    requirements = {
                        minRank = 5,
                        faction = "imperial"
                    }
                },
                ["docking_bay"] = {
                    name = "Docking Bay",
                    description = "A massive spaceport",
                    type = "port",
                    faction = "imperial",
                    requirements = {
                        minRank = 2,
                        faction = "imperial"
                    }
                }
            }
        }
    },
    TravelCosts = {
        ["coruscant"] = {
            ["tatooine"] = 1000,
            ["kashyyyk"] = 800
        },
        ["tatooine"] = {
            ["coruscant"] = 1000,
            ["kashyyyk"] = 1200
        },
        ["kashyyyk"] = {
            ["coruscant"] = 800,
            ["tatooine"] = 1200
        }
    }
}

-- Galaxy module functions
function KYBER.Galaxy:Initialize()
    print("[Kyber] Galaxy module initialized")
    return true
end

function KYBER.Galaxy:CreateGalaxyData(ply)
    if not IsValid(ply) then return false end
    
    -- Create galaxy data table if it doesn't exist
    ply.KyberGalaxy = ply.KyberGalaxy or {
        currentPlanet = nil,
        currentLocation = nil,
        discoveredPlanets = {},
        discoveredLocations = {},
        travelHistory = {}
    }
    
    return true
end

function KYBER.Galaxy:GetCurrentPlanet(ply)
    if not IsValid(ply) then return nil end
    if not self:CreateGalaxyData(ply) then return nil end
    
    return ply.KyberGalaxy.currentPlanet
end

function KYBER.Galaxy:GetCurrentLocation(ply)
    if not IsValid(ply) then return nil end
    if not self:CreateGalaxyData(ply) then return nil end
    
    return ply.KyberGalaxy.currentLocation
end

function KYBER.Galaxy:CanTravelTo(ply, destination)
    if not IsValid(ply) then return false end
    if not self:CreateGalaxyData(ply) then return false end
    
    -- Get current planet
    local currentPlanet = ply.KyberGalaxy.currentPlanet
    if not currentPlanet then return false end
    
    -- Check if destination exists
    if not self.Config.Planets[destination] and not self.Config.SpaceStations[destination] then
        return false
    end
    
    -- Check travel cost
    local cost = self.Config.TravelCosts[currentPlanet] and self.Config.TravelCosts[currentPlanet][destination]
    if not cost then return false end
    
    -- Check if player has enough credits
    local credits = KYBER.Economy:GetCredits(ply)
    if credits < cost then
        return false
    end
    
    return true
end

function KYBER.Galaxy:TravelTo(ply, destination)
    if not IsValid(ply) then return false end
    if not self:CanTravelTo(ply, destination) then return false end
    
    -- Get current planet
    local currentPlanet = ply.KyberGalaxy.currentPlanet
    
    -- Get travel cost
    local cost = self.Config.TravelCosts[currentPlanet][destination]
    
    -- Remove credits
    KYBER.Economy:RemoveCredits(ply, cost)
    
    -- Update current planet
    ply.KyberGalaxy.currentPlanet = destination
    ply.KyberGalaxy.currentLocation = nil
    
    -- Add to discovered planets
    ply.KyberGalaxy.discoveredPlanets[destination] = true
    
    -- Add to travel history
    table.insert(ply.KyberGalaxy.travelHistory, {
        from = currentPlanet,
        to = destination,
        time = os.time()
    })
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Galaxy_Travel")
        net.WriteEntity(ply)
        net.WriteString(destination)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Galaxy:CanEnterLocation(ply, locationId)
    if not IsValid(ply) then return false end
    if not self:CreateGalaxyData(ply) then return false end
    
    -- Get current planet
    local currentPlanet = ply.KyberGalaxy.currentPlanet
    if not currentPlanet then return false end
    
    -- Get planet data
    local planet = self.Config.Planets[currentPlanet]
    if not planet then return false end
    
    -- Get location data
    local location = planet.locations[locationId]
    if not location then return false end
    
    -- Check requirements
    if location.requirements then
        -- Check force alignment
        if location.requirements.forceAlignment then
            local alignment = KYBER.Force:GetAlignment(ply)
            if alignment ~= location.requirements.forceAlignment then
                return false
            end
        end
        
        -- Check force level
        if location.requirements.minForceLevel then
            local forceLevel = KYBER.Force:GetLevel(ply)
            if forceLevel < location.requirements.minForceLevel then
                return false
            end
        end
        
        -- Check reputation
        if location.requirements.minReputation then
            local reputation = KYBER.Reputation:GetReputation(ply)
            if reputation < location.requirements.minReputation then
                return false
            end
        end
        
        -- Check level
        if location.requirements.minLevel then
            local level = KYBER.Character:GetLevel(ply)
            if level < location.requirements.minLevel then
                return false
            end
        end
        
        -- Check rank
        if location.requirements.minRank then
            local rank = KYBER.Factions:GetRank(ply)
            if rank < location.requirements.minRank then
                return false
            end
        end
        
        -- Check faction
        if location.requirements.faction then
            local faction = KYBER.Factions:GetFaction(ply)
            if faction ~= location.requirements.faction then
                return false
            end
        end
    end
    
    return true
end

function KYBER.Galaxy:EnterLocation(ply, locationId)
    if not IsValid(ply) then return false end
    if not self:CanEnterLocation(ply, locationId) then return false end
    
    -- Get current planet
    local currentPlanet = ply.KyberGalaxy.currentPlanet
    if not currentPlanet then return false end
    
    -- Get planet data
    local planet = self.Config.Planets[currentPlanet]
    if not planet then return false end
    
    -- Get location data
    local location = planet.locations[locationId]
    if not location then return false end
    
    -- Update current location
    ply.KyberGalaxy.currentLocation = locationId
    
    -- Add to discovered locations
    ply.KyberGalaxy.discoveredLocations[locationId] = true
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Galaxy_EnterLocation")
        net.WriteEntity(ply)
        net.WriteString(locationId)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Galaxy:LeaveLocation(ply)
    if not IsValid(ply) then return false end
    if not self:CreateGalaxyData(ply) then return false end
    
    -- Check if in a location
    if not ply.KyberGalaxy.currentLocation then
        return false
    end
    
    -- Clear current location
    ply.KyberGalaxy.currentLocation = nil
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Galaxy_LeaveLocation")
        net.WriteEntity(ply)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Galaxy:GetDiscoveredPlanets(ply)
    if not IsValid(ply) then return {} end
    if not self:CreateGalaxyData(ply) then return {} end
    
    local planets = {}
    for planetId, _ in pairs(ply.KyberGalaxy.discoveredPlanets) do
        planets[planetId] = self.Config.Planets[planetId]
    end
    
    return planets
end

function KYBER.Galaxy:GetDiscoveredLocations(ply)
    if not IsValid(ply) then return {} end
    if not self:CreateGalaxyData(ply) then return {} end
    
    local locations = {}
    for locationId, _ in pairs(ply.KyberGalaxy.discoveredLocations) do
        -- Find which planet this location belongs to
        for planetId, planet in pairs(self.Config.Planets) do
            if planet.locations[locationId] then
                locations[locationId] = {
                    planet = planetId,
                    data = planet.locations[locationId]
                }
                break
            end
        end
    end
    
    return locations
end

function KYBER.Galaxy:GetTravelHistory(ply)
    if not IsValid(ply) then return {} end
    if not self:CreateGalaxyData(ply) then return {} end
    
    return ply.KyberGalaxy.travelHistory
end

function KYBER.Galaxy:GetAvailableLocations(ply)
    if not IsValid(ply) then return {} end
    if not self:CreateGalaxyData(ply) then return {} end
    
    -- Get current planet
    local currentPlanet = ply.KyberGalaxy.currentPlanet
    if not currentPlanet then return {} end
    
    -- Get planet data
    local planet = self.Config.Planets[currentPlanet]
    if not planet then return {} end
    
    local locations = {}
    for locationId, location in pairs(planet.locations) do
        if self:CanEnterLocation(ply, locationId) then
            locations[locationId] = location
        end
    end
    
    return locations
end

-- Initialize the module
KYBER.Galaxy:Initialize() 