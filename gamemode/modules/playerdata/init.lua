-- PlayerData module initialization
KYBER.PlayerData = KYBER.PlayerData or {}

-- PlayerData module configuration
KYBER.PlayerData.Config = {
    SaveInterval = 300, -- Save every 5 minutes
    MaxCharacters = 3
}

-- PlayerData module functions
function KYBER.PlayerData:Initialize()
    print("[Kyber] PlayerData module initialized")
    return true
end

function KYBER.PlayerData:SavePlayer(ply)
    if not IsValid(ply) then return false end
    
    local steamID = ply:SteamID()
    local data = {
        last_login = os.time(),
        characters = ply.KyberCharacters or {}
    }
    
    -- Save to SQL if available
    if KYBER.SQL then
        KYBER.SQL:Query(string.format([[
            INSERT OR REPLACE INTO kyber_players (steam_id, data, last_login)
            VALUES ('%s', '%s', %d)
        ]], steamID, util.TableToJSON(data), os.time()))
    end
    
    return true
end

function KYBER.PlayerData:LoadPlayer(ply)
    if not IsValid(ply) then return false end
    
    local steamID = ply:SteamID()
    
    -- Load from SQL if available
    if KYBER.SQL then
        KYBER.SQL:Query(string.format([[
            SELECT data FROM kyber_players WHERE steam_id = '%s'
        ]], steamID), function(result)
            if result and result[1] then
                local data = util.JSONToTable(result[1].data)
                if data then
                    ply.KyberCharacters = data.characters or {}
                end
            end
        end)
    end
    
    return true
end

-- Initialize the module
KYBER.PlayerData:Initialize() 