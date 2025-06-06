-- kyber/gamemode/modules/database/sql.lua
-- SQL database layer implementation

local KYBER = KYBER or {}

-- SQL database management
KYBER.SQL = KYBER.SQL or {}

-- Connection pool
local connectionPool = {}
local maxConnections = 5
local activeConnections = 0

-- Query queue
local queryQueue = {}
local isProcessingQueue = false

-- Initialize database connection
function KYBER.SQL.Initialize()
    if not mysqloo then
        KYBER.LogError("MySQLoo not found. Please install it to use SQL features.")
        return false
    end
    
    -- Load configuration
    local config = KYBER.Config.Get("kyber/config/database.json", "mysql", {
        host = "localhost",
        user = "root",
        password = "",
        database = "kyber",
        port = 3306
    })
    
    -- Create connection
    local db = mysqloo.connect(config.host, config.user, config.password, config.database, config.port)
    
    function db:onConnected()
        KYBER.LogInfo("Connected to MySQL database")
    end
    
    function db:onConnectionFailed(err)
        KYBER.LogError("Failed to connect to MySQL database: " .. err)
    end
    
    db:connect()
    return true
end

-- Get a connection from the pool
function KYBER.SQL.GetConnection()
    -- Check for available connection
    for i, conn in ipairs(connectionPool) do
        if not conn.inUse then
            conn.inUse = true
            return conn
        end
    end
    
    -- Create new connection if possible
    if activeConnections < maxConnections then
        local config = KYBER.Config.Get("kyber/config/database.json", "mysql")
        local conn = mysqloo.connect(config.host, config.user, config.password, config.database, config.port)
        conn.inUse = true
        activeConnections = activeConnections + 1
        table.insert(connectionPool, conn)
        return conn
    end
    
    return nil
end

-- Release a connection back to the pool
function KYBER.SQL.ReleaseConnection(conn)
    if not conn then return end
    
    for i, poolConn in ipairs(connectionPool) do
        if poolConn == conn then
            poolConn.inUse = false
            break
        end
    end
end

-- Queue a query
function KYBER.SQL.QueueQuery(query, callback, errorCallback)
    if not query then
        KYBER.LogError("Invalid query")
        if errorCallback then errorCallback("Invalid query") end
        return false
    end
    
    -- Add to queue
    table.insert(queryQueue, {
        query = query,
        callback = callback,
        errorCallback = errorCallback,
        timestamp = os.time()
    })
    
    -- Process queue if not already processing
    if not isProcessingQueue then
        KYBER.SQL.ProcessQueue()
    end
    
    return true
end

-- Process the query queue
function KYBER.SQL.ProcessQueue()
    if isProcessingQueue or #queryQueue == 0 then return end
    
    isProcessingQueue = true
    
    -- Get next query
    local queryData = table.remove(queryQueue, 1)
    if not queryData then
        isProcessingQueue = false
        return
    end
    
    -- Get connection
    local conn = KYBER.SQL.GetConnection()
    if not conn then
        -- No connection available, put query back in queue
        table.insert(queryQueue, 1, queryData)
        isProcessingQueue = false
        
        -- Try again in a second
        timer.Simple(1, function()
            KYBER.SQL.ProcessQueue()
        end)
        return
    end
    
    -- Execute query
    local query = conn:query(queryData.query)
    
    function query:onSuccess(data)
        KYBER.SQL.ReleaseConnection(conn)
        if queryData.callback then
            queryData.callback(data)
        end
        isProcessingQueue = false
        KYBER.SQL.ProcessQueue()
    end
    
    function query:onError(err)
        KYBER.SQL.ReleaseConnection(conn)
        KYBER.LogError("Query error: " .. err)
        if queryData.errorCallback then
            queryData.errorCallback(err)
        end
        isProcessingQueue = false
        KYBER.SQL.ProcessQueue()
    end
    
    query:start()
end

-- Execute a query immediately
function KYBER.SQL.Query(query, callback, errorCallback)
    if not query then
        KYBER.LogError("Invalid query")
        if errorCallback then errorCallback("Invalid query") end
        return false
    end
    
    -- Get connection
    local conn = KYBER.SQL.GetConnection()
    if not conn then
        KYBER.LogError("No database connection available")
        if errorCallback then errorCallback("No database connection available") end
        return false
    end
    
    -- Execute query
    local queryObj = conn:query(query)
    
    function queryObj:onSuccess(data)
        KYBER.SQL.ReleaseConnection(conn)
        if callback then
            callback(data)
        end
    end
    
    function queryObj:onError(err)
        KYBER.SQL.ReleaseConnection(conn)
        KYBER.LogError("Query error: " .. err)
        if errorCallback then
            errorCallback(err)
        end
    end
    
    queryObj:start()
    return true
end

-- Prepare a query
function KYBER.SQL.Prepare(query, ...)
    if not query then
        KYBER.LogError("Invalid query")
        return nil
    end
    
    -- Get connection
    local conn = KYBER.SQL.GetConnection()
    if not conn then
        KYBER.LogError("No database connection available")
        return nil
    end
    
    -- Prepare query
    local stmt = conn:prepare(query)
    if not stmt then
        KYBER.SQL.ReleaseConnection(conn)
        return nil
    end
    
    -- Set parameters
    local args = {...}
    for i, arg in ipairs(args) do
        stmt:setNumber(i, arg)
    end
    
    return stmt
end

-- Initialize database schema
function KYBER.SQL.InitializeSchema()
    local queries = {
        -- Characters table
        [[
        CREATE TABLE IF NOT EXISTS characters (
            id INT AUTO_INCREMENT PRIMARY KEY,
            steam_id VARCHAR(32) NOT NULL,
            name VARCHAR(32) NOT NULL,
            species VARCHAR(32) NOT NULL,
            faction VARCHAR(32),
            rank VARCHAR(32),
            credits INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_steam_id (steam_id)
        )
        ]],
        
        -- Factions table
        [[
        CREATE TABLE IF NOT EXISTS factions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(32) NOT NULL,
            description TEXT,
            color_r INT,
            color_g INT,
            color_b INT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_name (name)
        )
        ]],
        
        -- Faction ranks table
        [[
        CREATE TABLE IF NOT EXISTS faction_ranks (
            id INT AUTO_INCREMENT PRIMARY KEY,
            faction_id INT NOT NULL,
            name VARCHAR(32) NOT NULL,
            color_r INT,
            color_g INT,
            color_b INT,
            permissions TEXT,
            FOREIGN KEY (faction_id) REFERENCES factions(id) ON DELETE CASCADE,
            UNIQUE KEY unique_faction_rank (faction_id, name)
        )
        ]],
        
        -- Faction members table
        [[
        CREATE TABLE IF NOT EXISTS faction_members (
            id INT AUTO_INCREMENT PRIMARY KEY,
            faction_id INT NOT NULL,
            character_id INT NOT NULL,
            rank_id INT NOT NULL,
            joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (faction_id) REFERENCES factions(id) ON DELETE CASCADE,
            FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
            FOREIGN KEY (rank_id) REFERENCES faction_ranks(id) ON DELETE CASCADE,
            UNIQUE KEY unique_character (character_id)
        )
        ]],
        
        -- Territories table
        [[
        CREATE TABLE IF NOT EXISTS territories (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(32) NOT NULL,
            owner_id INT NOT NULL,
            type VARCHAR(32) NOT NULL,
            pos_x FLOAT NOT NULL,
            pos_y FLOAT NOT NULL,
            pos_z FLOAT NOT NULL,
            size FLOAT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (owner_id) REFERENCES factions(id) ON DELETE CASCADE
        )
        ]],
        
        -- Territory resources table
        [[
        CREATE TABLE IF NOT EXISTS territory_resources (
            id INT AUTO_INCREMENT PRIMARY KEY,
            territory_id INT NOT NULL,
            type VARCHAR(32) NOT NULL,
            amount INT NOT NULL,
            last_harvest TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (territory_id) REFERENCES territories(id) ON DELETE CASCADE
        )
        ]]
    }
    
    -- Execute queries
    for _, query in ipairs(queries) do
        KYBER.SQL.Query(query, function()
            KYBER.LogInfo("Schema initialized successfully")
        end, function(err)
            KYBER.LogError("Failed to initialize schema: " .. err)
        end)
    end
end

-- Initialize on server
if SERVER then
    KYBER.SQL.Initialize()
    KYBER.SQL.InitializeSchema()
end 