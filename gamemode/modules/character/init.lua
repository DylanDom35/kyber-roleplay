-- Character module
local Character = {}
Character.__index = Character

-- Character module configuration
KYBER.Character = KYBER.Character or {}

KYBER.Character.Config = {
    MaxCharacters = 3,
    MinNameLength = 3,
    MaxNameLength = 32,
    StartingCredits = 1000,
    StartingLocation = Vector(0, 0, 0),
    DefaultModel = "models/player/group01/male_01.mdl",
    AllowedSpecies = {
        ["human"] = {
            name = "Human",
            description = "Standard human species",
            models = {
                "models/player/group01/male_01.mdl",
                "models/player/group01/male_02.mdl",
                "models/player/group01/male_03.mdl",
                "models/player/group01/male_04.mdl",
                "models/player/group01/male_05.mdl",
                "models/player/group01/male_06.mdl",
                "models/player/group01/male_07.mdl",
                "models/player/group01/male_08.mdl",
                "models/player/group01/male_09.mdl"
            }
        },
        ["twilek"] = {
            name = "Twi'lek",
            description = "Humanoid species with head-tails",
            models = {
                "models/player/group01/female_01.mdl",
                "models/player/group01/female_02.mdl",
                "models/player/group01/female_03.mdl",
                "models/player/group01/female_04.mdl",
                "models/player/group01/female_05.mdl",
                "models/player/group01/female_06.mdl"
            }
        }
    }
}

-- Initialize the module
function Character:Initialize()
    print("[Kyber] Initializing Character module")
    
    -- Register network strings
    util.AddNetworkString("Kyber_Character_Open")
    util.AddNetworkString("Kyber_Character_Create")
    util.AddNetworkString("Kyber_Character_Delete")
    util.AddNetworkString("Kyber_Character_Select")
    
    -- Initialize character data
    self.Characters = {}
    
    -- Load characters
    self:LoadCharacters()
    
    -- Register hooks
    if SERVER then
        hook.Add("PlayerInitialSpawn", "Kyber_Character_InitialSpawn", function(ply)
            timer.Simple(1, function()
                if IsValid(ply) then
                    self:OpenSelection(ply)
                end
            end)
        end)
    end
    
    -- Register the module
    KYBER.Modules.character = self
end

-- Load characters
function Character:LoadCharacters()
    -- TODO: Implement character loading from database
    print("[Kyber] Loading character data")
end

-- Get player characters
function Character:GetCharacters(ply)
    if not IsValid(ply) then return {} end
    
    -- TODO: Implement character retrieval
    return {}
end

-- Create character
function Character:Create(ply, data)
    if not IsValid(ply) then return false end
    
    -- TODO: Implement character creation
    print("[Kyber] Creating character for " .. ply:Nick())
    return true
end

-- Delete character
function Character:Delete(ply, charId)
    if not IsValid(ply) then return false end
    
    -- TODO: Implement character deletion
    print("[Kyber] Deleting character " .. charId .. " for " .. ply:Nick())
    return true
end

-- Select character
function Character:Select(ply, charId)
    if not IsValid(ply) then return false end
    
    -- TODO: Implement character selection
    print("[Kyber] Selecting character " .. charId .. " for " .. ply:Nick())
    return true
end

-- Get character data
function Character:GetData(ply, charID)
    if not IsValid(ply) then return nil end
    
    -- TODO: Implement character data retrieval
    return nil
end

-- Open character selection
function Character:OpenSelection(ply)
    if SERVER then
        -- TODO: Get character data from database
        local characters = {}
        
        -- Send character data to client
        net.Start("Kyber_Character_Open")
            net.WriteTable(characters)
        net.Send(ply)
    end
end

-- Client-side UI
if CLIENT then
    local function OpenCharacterMenu()
        if IsValid(KYBER.Character.Menu) then
            KYBER.Character.Menu:Remove()
        end
        
        KYBER.Character.Menu = vgui.Create("DFrame")
        KYBER.Character.Menu:SetSize(800, 600)
        KYBER.Character.Menu:Center()
        KYBER.Character.Menu:SetTitle("Character Selection")
        KYBER.Character.Menu:MakePopup()
        
        -- Character list
        local charList = vgui.Create("DPanelList", KYBER.Character.Menu)
        charList:SetSize(300, 500)
        charList:SetPos(20, 50)
        charList:EnableVerticalScrollbar(true)
        charList:SetSpacing(10)
        
        -- Character preview
        local preview = vgui.Create("DModelPanel", KYBER.Character.Menu)
        preview:SetSize(400, 500)
        preview:SetPos(340, 50)
        preview:SetFOV(50)
        preview:SetCamPos(Vector(50, 50, 50))
        preview:SetLookAt(Vector(0, 0, 0))
        
        -- Create character button
        local createBtn = vgui.Create("DButton", KYBER.Character.Menu)
        createBtn:SetSize(200, 30)
        createBtn:SetPos(20, 560)
        createBtn:SetText("Create New Character")
        createBtn.DoClick = function()
            OpenCreateCharacterMenu()
        end
        
        -- Update character list
        local function UpdateCharacterList()
            charList:Clear()
            
            for _, char in ipairs(LocalPlayer().KyberCharacters or {}) do
                local btn = vgui.Create("DButton")
                btn:SetSize(280, 60)
                btn:SetText(char.name .. " (" .. KYBER.Character.Config.AllowedSpecies[char.species].name .. ")")
                btn.DoClick = function()
                    -- Update preview
                    preview:SetModel(char.model)
                    
                    -- Select character
                    net.Start("Kyber_Character_Select")
                    net.WriteString(char.id)
                    net.SendToServer()
                    
                    KYBER.Character.Menu:Remove()
                end
                
                charList:AddItem(btn)
            end
        end
        
        -- Create character menu
        function OpenCreateCharacterMenu()
            if IsValid(KYBER.Character.CreateMenu) then
                KYBER.Character.CreateMenu:Remove()
            end
            
            KYBER.Character.CreateMenu = vgui.Create("DFrame")
            KYBER.Character.CreateMenu:SetSize(400, 500)
            KYBER.Character.CreateMenu:Center()
            KYBER.Character.CreateMenu:SetTitle("Create Character")
            KYBER.Character.CreateMenu:MakePopup()
            
            -- Name input
            local nameLabel = vgui.Create("DLabel", KYBER.Character.CreateMenu)
            nameLabel:SetPos(20, 40)
            nameLabel:SetText("Character Name:")
            
            local nameInput = vgui.Create("DTextEntry", KYBER.Character.CreateMenu)
            nameInput:SetPos(20, 60)
            nameInput:SetSize(360, 30)
            
            -- Species selection
            local speciesLabel = vgui.Create("DLabel", KYBER.Character.CreateMenu)
            speciesLabel:SetPos(20, 100)
            speciesLabel:SetText("Species:")
            
            local speciesCombo = vgui.Create("DComboBox", KYBER.Character.CreateMenu)
            speciesCombo:SetPos(20, 120)
            speciesCombo:SetSize(360, 30)
            
            for id, species in pairs(KYBER.Character.Config.AllowedSpecies) do
                speciesCombo:AddChoice(species.name, id)
            end
            
            -- Model selection
            local modelLabel = vgui.Create("DLabel", KYBER.Character.CreateMenu)
            modelLabel:SetPos(20, 160)
            modelLabel:SetText("Model:")
            
            local modelCombo = vgui.Create("DComboBox", KYBER.Character.CreateMenu)
            modelCombo:SetPos(20, 180)
            modelCombo:SetSize(360, 30)
            
            -- Update models when species changes
            speciesCombo.OnSelect = function(_, _, data)
                modelCombo:Clear()
                for _, model in ipairs(KYBER.Character.Config.AllowedSpecies[data].models) do
                    modelCombo:AddChoice(model)
                end
            end
            
            -- Create button
            local createBtn = vgui.Create("DButton", KYBER.Character.CreateMenu)
            createBtn:SetSize(200, 30)
            createBtn:SetPos(100, 440)
            createBtn:SetText("Create Character")
            createBtn.DoClick = function()
                local name = nameInput:GetValue()
                local _, species = speciesCombo:GetSelected()
                local model = modelCombo:GetSelected()
                
                if name and species and model then
                    net.Start("Kyber_Character_Create")
                    net.WriteTable({
                        name = name,
                        species = species,
                        model = model
                    })
                    net.SendToServer()
                    
                    KYBER.Character.CreateMenu:Remove()
                end
            end
        end
        
        -- Network handlers
        net.Receive("Kyber_Character_Open", function()
            LocalPlayer().KyberCharacters = net.ReadTable()
            UpdateCharacterList()
        end)
        
        -- Initial update
        UpdateCharacterList()
    end
    
    -- Register F4 key
    hook.Add("InitPostEntity", "Kyber_Character_InitKeyBindings", function()
        bind.Register("kyber_character_menu", function(ply)
            OpenCharacterMenu()
        end)
        
        bind.Add("F4", "kyber_character_menu")
    end)
end

-- Initialize character module
KYBER.Character = KYBER.Character or {}

-- Include character system files
include("kyber/gamemode/modules/character/creation.lua")
include("kyber/gamemode/modules/character/selection.lua")

-- Register network strings
KYBER.Management.Network:Register("Kyber_Character_Create")
KYBER.Management.Network:Register("Kyber_Character_Delete")
KYBER.Management.Network:Register("Kyber_Character_Select")
KYBER.Management.Network:Register("Kyber_Character_Update")
KYBER.Management.Network:Register("Kyber_Character_OpenSelection")
KYBER.Management.Network:Register("Kyber_Character_OpenCreation")
KYBER.Management.Network:Register("Kyber_Character_Check")
KYBER.Management.Network:Register("Kyber_Character_CheckResponse")
KYBER.Management.Network:Register("Kyber_Datapad_Open")
KYBER.Management.Network:Register("Kyber_Datapad_Update")
KYBER.Management.Network:Register("Kyber_Datapad_Save")

-- Initialize character system
local success, err = pcall(function()
    -- Create character directory if it doesn't exist
    if not file.Exists("kyber/characters", "DATA") then
        file.CreateDir("kyber/characters")
    end
end)

if not success then
    KYBER.Management.ErrorHandler:Handle(err, "Failed to initialize character system")
end

-- Handle character check requests
net.Receive("Kyber_Character_Check", function(len, ply)
    local success, err = pcall(function()
        local steamID = ply:SteamID64()
        local files = file.Find("kyber/characters/" .. steamID .. "_*.json", "DATA")
        
        net.Start("Kyber_Character_CheckResponse")
        net.WriteBool(#files > 0)
        net.Send(ply)
    end)
    
    if not success then
        KYBER.Management.ErrorHandler:Handle(err, "Failed to check character for " .. ply:SteamID64())
    end
end)

-- Cleanup function
function KYBER.Character:Cleanup()
    -- Add any cleanup code here
end

function KYBER.Character:Save(ply)
    if not IsValid(ply) or not ply.KyberCharacters then return end
    local path = "kyber/characters/" .. ply:SteamID64() .. ".json"
    -- Create backup
    if file.Exists(path, "DATA") then
        file.Write(path .. ".backup", file.Read(path, "DATA"))
    end
    -- Write new data (placeholder)
    file.Write(path, util.TableToJSON(ply.KyberCharacters))
end

return Character 