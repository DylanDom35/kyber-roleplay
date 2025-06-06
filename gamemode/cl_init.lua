-- kyber/gamemode/cl_init.lua
-- Client-side initialization

-- Initialize the KYBER table first
KYBER = KYBER or {}

print("[Kyber] Starting client initialization...")

-- Include shared code first
include("shared.lua")

-- Utility function for safe includes with error handling
local function safeInclude(path, description)
    local success, err = pcall(include, path)
    if not success then
        print("[Kyber] ERROR loading " .. (description or path) .. ": " .. tostring(err))
        return false
    else
        print("[Kyber] ✓ Loaded " .. (description or path))
        return true
    end
end

-- Load core systems first
safeInclude("modules/playerdata/core.lua", "Player Data Core")

-- Character system
safeInclude("modules/character/sheet.lua", "Character Sheet")
safeInclude("modules/character/creation.lua", "Character Creation")
safeInclude("modules/character/selection.lua", "Character Selection")

-- Admin system
safeInclude("modules/admin/core.lua", "Admin Core")
safeInclude("modules/admin/ui.lua", "Admin UI")
safeInclude("modules/admin/integration.lua", "Admin Integration")

-- Inventory system
safeInclude("modules/inventory/system.lua", "Inventory System")
safeInclude("modules/inventory/trading.lua", "Trading System")
safeInclude("modules/inventory/integration.lua", "Inventory Integration")

-- Equipment system
safeInclude("modules/equipment/system.lua", "Equipment System")
safeInclude("modules/equipment/integration.lua", "Equipment Integration")

-- Medical system
safeInclude("modules/medical/system.lua", "Medical System")
safeInclude("modules/medical/integration.lua", "Medical Integration")

-- Communication system
safeInclude("modules/communication/system.lua", "Communication System")

-- Reputation system
safeInclude("modules/reputation/system.lua", "Reputation System")
safeInclude("modules/reputation/integration.lua", "Reputation Integration")

-- Banking system
safeInclude("modules/banking/system.lua", "Banking System")
safeInclude("modules/banking/integration.lua", "Banking Integration")

-- Crafting system
safeInclude("modules/crafting/system.lua", "Crafting System")
safeInclude("modules/crafting/integration.lua", "Crafting Integration")

-- Grand Exchange system
safeInclude("modules/economy/grand_exchange.lua", "Grand Exchange")

-- Force lottery system
safeInclude("modules/force/lottery.lua", "Force Lottery System")
safeInclude("modules/force/lottery_ui.lua", "Force Lottery UI")

-- Faction creation system
safeInclude("modules/factions/creation.lua", "Faction Creation")

-- Legendary character system
safeInclude("modules/legendary/system.lua", "Legendary Characters")

-- Galaxy travel system
safeInclude("modules/galaxy/travel.lua", "Galaxy Travel")

-- Loading screen
local loadingScreen = nil
local loadingProgress = 0
local loadingText = "Initializing Kyber RP..."

-- Create loading screen
local function CreateLoadingScreen()
    if IsValid(loadingScreen) then return end
    
    loadingScreen = vgui.Create("DFrame")
    loadingScreen:SetSize(ScrW(), ScrH())
    loadingScreen:Center()
    loadingScreen:SetTitle("")
    loadingScreen:ShowCloseButton(false)
    loadingScreen:SetDraggable(false)
    loadingScreen:MakePopup()
    
    -- Background
    local bg = vgui.Create("DPanel", loadingScreen)
    bg:Dock(FILL)
    bg.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 255))
        
        -- Star Wars themed background
        local stars = {}
        for i = 1, 100 do
            stars[i] = {
                x = math.random(0, w),
                y = math.random(0, h),
                size = math.random(1, 3),
                alpha = math.random(100, 255)
            }
        end
        
        for _, star in ipairs(stars) do
            draw.RoundedBox(0, star.x, star.y, star.size, star.size, Color(255, 255, 255, star.alpha))
        end
    end
    
    -- Logo
    local logo = vgui.Create("DImage", loadingScreen)
    logo:SetSize(400, 200)
    logo:SetPos(ScrW()/2 - 200, ScrH()/2 - 250)
    logo:SetImage("materials/kyber/logo.png") -- You'll need to create this
    
    -- Loading bar
    local loadingBar = vgui.Create("DPanel", loadingScreen)
    loadingBar:SetSize(600, 20)
    loadingBar:SetPos(ScrW()/2 - 300, ScrH()/2 + 50)
    loadingBar.Paint = function(self, w, h)
        -- Background
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))
        
        -- Progress
        local progress = math.Clamp(loadingProgress, 0, 1)
        draw.RoundedBox(4, 2, 2, (w-4) * progress, h-4, Color(255, 215, 0, 255))
    end
    
    -- Loading text
    local loadingLabel = vgui.Create("DLabel", loadingScreen)
    loadingLabel:SetSize(600, 20)
    loadingLabel:SetPos(ScrW()/2 - 300, ScrH()/2 + 80)
    loadingLabel:SetText(loadingText)
    loadingLabel:SetFont("DermaLarge")
    loadingLabel:SetTextColor(Color(255, 255, 255))
    loadingLabel:SetContentAlignment(5)
    
    -- Version text
    local versionLabel = vgui.Create("DLabel", loadingScreen)
    versionLabel:SetSize(200, 20)
    versionLabel:SetPos(ScrW() - 220, ScrH() - 40)
    versionLabel:SetText("Kyber RP v1.0.0")
    versionLabel:SetFont("DermaDefault")
    versionLabel:SetTextColor(Color(200, 200, 200))
    
    -- Update loading progress
    local startTime = SysTime()
    local function UpdateLoading()
        if not IsValid(loadingScreen) then return end
        
        local elapsed = SysTime() - startTime
        loadingProgress = math.Clamp(elapsed / 3, 0, 1) -- 3 second loading
        
        if loadingProgress >= 1 then
            loadingScreen:Remove()
            loadingScreen = nil
        end
    end
    
    hook.Add("Think", "Kyber_LoadingScreen", UpdateLoading)
end

-- Network string for showing loading screen
util.AddNetworkString("Kyber_ShowLoadingScreen")

-- Receive loading screen command
net.Receive("Kyber_ShowLoadingScreen", function()
    CreateLoadingScreen()
end)

print("[Kyber] Client initialization complete")