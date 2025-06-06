-- kyber/gamemode/modules/character/customization.lua

-- Initialize customization system
KYBER.Customization = KYBER.Customization or {}

-- Available customization categories
KYBER.Customization.Categories = {
    ["model"] = {
        name = "Model",
        icon = "icon16/user.png",
        order = 1
    },
    ["bodygroups"] = {
        name = "Body Groups",
        icon = "icon16/group.png",
        order = 2
    },
    ["materials"] = {
        name = "Materials",
        icon = "icon16/picture.png",
        order = 3
    },
    ["colors"] = {
        name = "Colors",
        icon = "icon16/color_wheel.png",
        order = 4
    },
    ["accessories"] = {
        name = "Accessories",
        icon = "icon16/star.png",
        order = 5
    },
    ["effects"] = {
        name = "Effects",
        icon = "icon16/lightning.png",
        order = 6
    },
    ["presets"] = {
        name = "Presets",
        icon = "icon16/book.png",
        order = 7
    }
}

-- Available models for each species
KYBER.Customization.Models = {
    ["Human"] = {
        "models/player/group01/male_01.mdl",
        "models/player/group01/male_02.mdl",
        "models/player/group01/male_03.mdl",
        "models/player/group01/male_04.mdl",
        "models/player/group01/male_05.mdl",
        "models/player/group01/male_06.mdl",
        "models/player/group01/male_07.mdl",
        "models/player/group01/male_08.mdl",
        "models/player/group01/male_09.mdl",
        "models/player/group01/female_01.mdl",
        "models/player/group01/female_02.mdl",
        "models/player/group01/female_03.mdl",
        "models/player/group01/female_04.mdl",
        "models/player/group01/female_05.mdl",
        "models/player/group01/female_06.mdl"
    },
    ["Twi'lek"] = {
        "models/player/group03m/twilek_male_01.mdl",
        "models/player/group03m/twilek_male_02.mdl",
        "models/player/group03f/twilek_female_01.mdl",
        "models/player/group03f/twilek_female_02.mdl"
    },
    ["Zabrak"] = {
        "models/player/group03m/zabrak_male_01.mdl",
        "models/player/group03m/zabrak_male_02.mdl",
        "models/player/group03f/zabrak_female_01.mdl",
        "models/player/group03f/zabrak_female_02.mdl"
    }
}

-- Species-specific customization options
KYBER.Customization.SpeciesOptions = {
    ["Human"] = {
        bodygroups = {
            ["head"] = {
                name = "Head",
                options = {
                    [0] = "Default",
                    [1] = "Bald",
                    [2] = "Short Hair",
                    [3] = "Long Hair"
                }
            },
            ["face"] = {
                name = "Face",
                options = {
                    [0] = "Default",
                    [1] = "Beard",
                    [2] = "Mustache",
                    [3] = "Goatee"
                }
            }
        },
        materials = {
            ["skin"] = {
                name = "Skin",
                options = {
                    ["default"] = "Default",
                    ["pale"] = "Pale",
                    ["tan"] = "Tan",
                    ["dark"] = "Dark"
                }
            }
        }
    },
    ["Twi'lek"] = {
        bodygroups = {
            ["lekku"] = {
                name = "Lekku",
                options = {
                    [0] = "Default",
                    [1] = "Short",
                    [2] = "Medium",
                    [3] = "Long"
                }
            },
            ["patterns"] = {
                name = "Patterns",
                options = {
                    [0] = "None",
                    [1] = "Stripes",
                    [2] = "Spots",
                    [3] = "Complex"
                }
            }
        },
        materials = {
            ["skin"] = {
                name = "Skin",
                options = {
                    ["default"] = "Default",
                    ["blue"] = "Blue",
                    ["green"] = "Green",
                    ["red"] = "Red",
                    ["purple"] = "Purple"
                }
            }
        }
    }
}

-- Available accessories
KYBER.Customization.Accessories = {
    ["head"] = {
        name = "Head",
        items = {
            ["jedi_hood"] = {
                name = "Jedi Hood",
                model = "models/pac/default.mdl",
                attachment = "eyes",
                offset = Vector(0, 0, 0),
                angle = Angle(0, 0, 0),
                scale = Vector(1, 1, 1),
                materials = {
                    ["default"] = "Default",
                    ["worn"] = "Worn",
                    ["damaged"] = "Damaged"
                }
            },
            ["sith_mask"] = {
                name = "Sith Mask",
                model = "models/pac/default.mdl",
                attachment = "eyes",
                offset = Vector(0, 0, 0),
                angle = Angle(0, 0, 0),
                scale = Vector(1, 1, 1),
                materials = {
                    ["default"] = "Default",
                    ["damaged"] = "Damaged",
                    ["gold"] = "Gold Trim"
                }
            },
            ["bounty_helmet"] = {
                name = "Bounty Hunter Helmet",
                model = "models/pac/default.mdl",
                attachment = "eyes",
                offset = Vector(0, 0, 0),
                angle = Angle(0, 0, 0),
                scale = Vector(1, 1, 1),
                materials = {
                    ["default"] = "Default",
                    ["scratched"] = "Scratched",
                    ["battle"] = "Battle Damaged"
                }
            }
        }
    },
    ["shoulders"] = {
        name = "Shoulders",
        items = {
            ["jedi_pauldron"] = {
                name = "Jedi Pauldron",
                model = "models/pac/default.mdl",
                attachment = "chest",
                offset = Vector(0, 0, 0),
                angle = Angle(0, 0, 0),
                scale = Vector(1, 1, 1),
                materials = {
                    ["default"] = "Default",
                    ["worn"] = "Worn",
                    ["damaged"] = "Damaged"
                }
            },
            ["mandalorian_pauldron"] = {
                name = "Mandalorian Pauldron",
                model = "models/pac/default.mdl",
                attachment = "chest",
                offset = Vector(0, 0, 0),
                angle = Angle(0, 0, 0),
                scale = Vector(1, 1, 1),
                materials = {
                    ["default"] = "Default",
                    ["beskar"] = "Beskar",
                    ["damaged"] = "Damaged"
                }
            }
        }
    },
    ["back"] = {
        name = "Back",
        items = {
            ["jedi_cloak"] = {
                name = "Jedi Cloak",
                model = "models/pac/default.mdl",
                attachment = "chest",
                offset = Vector(0, 0, 0),
                angle = Angle(0, 0, 0),
                scale = Vector(1, 1, 1),
                materials = {
                    ["default"] = "Default",
                    ["worn"] = "Worn",
                    ["damaged"] = "Damaged"
                }
            },
            ["cape"] = {
                name = "Cape",
                model = "models/pac/default.mdl",
                attachment = "chest",
                offset = Vector(0, 0, 0),
                angle = Angle(0, 0, 0),
                scale = Vector(1, 1, 1),
                materials = {
                    ["default"] = "Default",
                    ["royal"] = "Royal",
                    ["battle"] = "Battle"
                }
            }
        }
    },
    ["belt"] = {
        name = "Belt",
        items = {
            ["jedi_belt"] = {
                name = "Jedi Belt",
                model = "models/pac/default.mdl",
                attachment = "pelvis",
                offset = Vector(0, 0, 0),
                angle = Angle(0, 0, 0),
                scale = Vector(1, 1, 1),
                materials = {
                    ["default"] = "Default",
                    ["worn"] = "Worn",
                    ["damaged"] = "Damaged"
                }
            },
            ["utility_belt"] = {
                name = "Utility Belt",
                model = "models/pac/default.mdl",
                attachment = "pelvis",
                offset = Vector(0, 0, 0),
                angle = Angle(0, 0, 0),
                scale = Vector(1, 1, 1),
                materials = {
                    ["default"] = "Default",
                    ["tactical"] = "Tactical",
                    ["battle"] = "Battle"
                }
            }
        }
    }
}

-- Available effects
KYBER.Customization.Effects = {
    ["force"] = {
        name = "Force Effects",
        items = {
            ["force_aura"] = {
                name = "Force Aura",
                type = "particle",
                effect = "force_aura",
                color = Color(100, 200, 255),
                scale = 1.0,
                attachment = "chest"
            },
            ["dark_side"] = {
                name = "Dark Side Aura",
                type = "particle",
                effect = "dark_side",
                color = Color(255, 50, 50),
                scale = 1.0,
                attachment = "chest"
            }
        }
    },
    ["trail"] = {
        name = "Trail Effects",
        items = {
            ["lightsaber_trail"] = {
                name = "Lightsaber Trail",
                type = "trail",
                material = "trails/lightsaber",
                color = Color(100, 200, 255),
                width = 2,
                lifetime = 0.5
            }
        }
    }
}

-- Preset outfits
KYBER.Customization.Presets = {
    ["jedi_knight"] = {
        name = "Jedi Knight",
        model = "models/player/group01/male_01.mdl",
        bodygroups = {
            [0] = 0, -- Head
            [1] = 0  -- Face
        },
        materials = {
            ["skin"] = "default"
        },
        accessories = {
            ["head"] = {
                ["jedi_hood"] = {
                    material = "default"
                }
            },
            ["shoulders"] = {
                ["jedi_pauldron"] = {
                    material = "default"
                }
            },
            ["back"] = {
                ["jedi_cloak"] = {
                    material = "default"
                }
            }
        },
        effects = {
            ["force"] = {
                ["force_aura"] = {
                    color = Color(100, 200, 255),
                    scale = 1.0
                }
            }
        }
    },
    ["sith_lord"] = {
        name = "Sith Lord",
        model = "models/player/group01/male_02.mdl",
        bodygroups = {
            [0] = 1, -- Head
            [1] = 0  -- Face
        },
        materials = {
            ["skin"] = "pale"
        },
        accessories = {
            ["head"] = {
                ["sith_mask"] = {
                    material = "damaged"
                }
            },
            ["shoulders"] = {
                ["mandalorian_pauldron"] = {
                    material = "beskar"
                }
            },
            ["back"] = {
                ["cape"] = {
                    material = "royal"
                }
            }
        },
        effects = {
            ["force"] = {
                ["dark_side"] = {
                    color = Color(255, 50, 50),
                    scale = 1.2
                }
            }
        }
    }
}

-- Network strings
if SERVER then
    util.AddNetworkString("Kyber_Customization_Open")
    util.AddNetworkString("Kyber_Customization_Update")
    util.AddNetworkString("Kyber_Customization_Save")
    util.AddNetworkString("Kyber_Customization_Load")
    util.AddNetworkString("Kyber_Customization_SavePreset")
    util.AddNetworkString("Kyber_Customization_LoadPreset")
end

-- Server-side functions
if SERVER then
    -- Open customization menu
    function KYBER.Customization:OpenMenu(ply)
        if not IsValid(ply) then return end
        
        -- Get current customization data
        local data = self:GetData(ply)
        
        -- Send to client
        net.Start("Kyber_Customization_Open")
            net.WriteTable(data)
        net.Send(ply)
    end
    
    -- Get customization data
    function KYBER.Customization:GetData(ply)
        if not IsValid(ply) then return {} end
        
        -- Get from character data
        local charData = KYBER:GetCharacterData(ply)
        if not charData then return {} end
        
        return charData.customization or {}
    end
    
    -- Save customization data
    function KYBER.Customization:SaveData(ply, data)
        if not IsValid(ply) then return false end
        
        -- Get character data
        local charData = KYBER:GetCharacterData(ply)
        if not charData then return false end
        
        -- Update customization
        charData.customization = data
        
        -- Save character data
        KYBER:SetCharacterData(ply, charData)
        
        -- Apply customization
        self:ApplyCustomization(ply)
        
        return true
    end
    
    -- Apply customization to player
    function KYBER.Customization:ApplyCustomization(ply)
        if not IsValid(ply) then return end
        
        -- Get customization data
        local data = self:GetData(ply)
        if not data then return end
        
        -- Apply model
        if data.model then
            ply:SetModel(data.model)
        end
        
        -- Apply bodygroups
        if data.bodygroups then
            for k, v in pairs(data.bodygroups) do
                ply:SetBodygroup(k, v)
            end
        end
        
        -- Apply materials
        if data.materials then
            for k, v in pairs(data.materials) do
                ply:SetSubMaterial(k, v)
            end
        end
        
        -- Apply colors
        if data.colors then
            for k, v in pairs(data.colors) do
                ply:SetColor(v)
            end
        end
        
        -- Apply accessories
        if data.accessories then
            -- Clear existing accessories
            if ply.accessories then
                for _, acc in pairs(ply.accessories) do
                    if IsValid(acc) then
                        acc:Remove()
                    end
                end
            end
            
            -- Create new accessories
            ply.accessories = {}
            for category, items in pairs(data.accessories) do
                for itemID, itemData in pairs(items) do
                    local accData = self.Accessories[category].items[itemID]
                    if accData then
                        local acc = ents.Create("prop_dynamic")
                        acc:SetModel(accData.model)
                        acc:SetParent(ply)
                        acc:SetPos(ply:GetPos() + accData.offset)
                        acc:SetAngles(ply:GetAngles() + accData.angle)
                        acc:SetModelScale(accData.scale)
                        acc:SetMoveType(MOVETYPE_NONE)
                        acc:SetSolid(SOLID_NONE)
                        acc:SetNoDraw(false)
                        acc:DrawShadow(false)
                        acc:SetNotSolid(true)
                        acc:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
                        
                        -- Apply material if specified
                        if itemData.material then
                            acc:SetMaterial(itemData.material)
                        end
                        
                        acc:Spawn()
                        
                        table.insert(ply.accessories, acc)
                    end
                end
            end
        end
        
        -- Apply effects
        if data.effects then
            -- Clear existing effects
            if ply.effects then
                for _, effect in pairs(ply.effects) do
                    if IsValid(effect) then
                        effect:Remove()
                    end
                end
            end
            
            -- Create new effects
            ply.effects = {}
            for category, items in pairs(data.effects) do
                for itemID, itemData in pairs(items) do
                    local effectData = self.Effects[category].items[itemID]
                    if effectData then
                        if effectData.type == "particle" then
                            local effect = ents.Create("info_particle_system")
                            effect:SetPos(ply:GetPos())
                            effect:SetParent(ply)
                            effect:SetName(effectData.effect)
                            effect:SetKeyValue("effect_name", effectData.effect)
                            effect:SetKeyValue("start_active", "1")
                            effect:Spawn()
                            effect:Activate()
                            
                            table.insert(ply.effects, effect)
                        elseif effectData.type == "trail" then
                            local effect = ents.Create("env_sprite_trail")
                            effect:SetPos(ply:GetPos())
                            effect:SetParent(ply)
                            effect:SetKeyValue("material", effectData.material)
                            effect:SetKeyValue("width", tostring(effectData.width))
                            effect:SetKeyValue("lifetime", tostring(effectData.lifetime))
                            effect:Spawn()
                            effect:Activate()
                            
                            table.insert(ply.effects, effect)
                        end
                    end
                end
            end
        end
    end
    
    -- Handle network messages
    net.Receive("Kyber_Customization_Update", function(len, ply)
        local data = net.ReadTable()
        KYBER.Customization:SaveData(ply, data)
    end)
    
    net.Receive("Kyber_Customization_SavePreset", function(len, ply)
        local presetName = net.ReadString()
        local data = net.ReadTable()
        
        -- Save preset to character data
        local charData = KYBER:GetCharacterData(ply)
        if charData then
            charData.presets = charData.presets or {}
            charData.presets[presetName] = data
            KYBER:SetCharacterData(ply, charData)
        end
    end)
    
    net.Receive("Kyber_Customization_LoadPreset", function(len, ply)
        local presetName = net.ReadString()
        
        -- Load preset from character data
        local charData = KYBER:GetCharacterData(ply)
        if charData and charData.presets and charData.presets[presetName] then
            KYBER.Customization:SaveData(ply, charData.presets[presetName])
        end
    end)
end

-- Client-side functions
if CLIENT then
    -- Customization menu
    local function OpenCustomizationMenu(data)
        local frame = vgui.Create("DFrame")
        frame:SetSize(1000, 700)
        frame:Center()
        frame:SetTitle("Character Customization")
        frame:MakePopup()
        
        -- Create category list
        local categoryList = vgui.Create("DListView", frame)
        categoryList:SetPos(10, 30)
        categoryList:SetSize(150, 660)
        categoryList:AddColumn("Categories")
        
        -- Add categories
        for id, category in pairs(KYBER.Customization.Categories) do
            categoryList:AddLine(category.name)
        end
        
        -- Create content panel
        local contentPanel = vgui.Create("DPanel", frame)
        contentPanel:SetPos(170, 30)
        contentPanel:SetSize(820, 660)
        
        -- Create preview panel
        local previewPanel = vgui.Create("DModelPanel", contentPanel)
        previewPanel:SetSize(300, 400)
        previewPanel:SetPos(10, 10)
        previewPanel:SetModel(data.model or "models/player/group01/male_01.mdl")
        previewPanel:SetFOV(50)
        previewPanel:SetCamPos(Vector(50, 50, 50))
        previewPanel:SetLookAt(Vector(0, 0, 0))
        
        -- Add preview controls
        local controls = vgui.Create("DPanel", previewPanel)
        controls:SetSize(280, 30)
        controls:SetPos(10, 360)
        
        -- Rotation slider
        local rotationSlider = vgui.Create("DNumSlider", controls)
        rotationSlider:SetPos(10, 5)
        rotationSlider:SetSize(260, 20)
        rotationSlider:SetText("Rotation")
        rotationSlider:SetMin(0)
        rotationSlider:SetMax(360)
        rotationSlider:SetValue(0)
        rotationSlider.OnValueChanged = function(_, value)
            previewPanel:SetLookAng(Angle(0, value, 0))
        end
        
        -- Zoom slider
        local zoomSlider = vgui.Create("DNumSlider", controls)
        zoomSlider:SetPos(10, 35)
        zoomSlider:SetSize(260, 20)
        zoomSlider:SetText("Zoom")
        zoomSlider:SetMin(30)
        zoomSlider:SetMax(90)
        zoomSlider:SetValue(50)
        zoomSlider.OnValueChanged = function(_, value)
            previewPanel:SetFOV(value)
        end
        
        -- Function to update content panel
        local function UpdateContent(category)
            contentPanel:Clear()
            
            -- Add preview panel
            contentPanel:Add(previewPanel)
            
            if category == "model" then
                -- Model selection
                local modelList = vgui.Create("DListView", contentPanel)
                modelList:SetPos(320, 10)
                modelList:SetSize(490, 200)
                modelList:AddColumn("Models")
                
                -- Add models for current species
                local species = LocalPlayer():GetNWString("kyber_species", "Human")
                local models = KYBER.Customization.Models[species] or {}
                
                for _, model in ipairs(models) do
                    modelList:AddLine(model)
                end
                
                -- Update preview on selection
                modelList.OnRowSelected = function(_, _, row)
                    previewPanel:SetModel(row:GetValue(1))
                    data.model = row:GetValue(1)
                end
            elseif category == "bodygroups" then
                -- Bodygroup selection
                local bodygroupList = vgui.Create("DListView", contentPanel)
                bodygroupList:SetPos(320, 10)
                bodygroupList:SetSize(490, 200)
                bodygroupList:AddColumn("Body Groups")
                
                -- Add bodygroups
                local model = data.model or "models/player/group01/male_01.mdl"
                local bodygroups = LocalPlayer():GetBodyGroups()
                
                for _, bg in ipairs(bodygroups) do
                    bodygroupList:AddLine(bg.name)
                end
                
                -- Update preview on selection
                bodygroupList.OnRowSelected = function(_, _, row)
                    local bg = bodygroups[row:GetID()]
                    if bg then
                        previewPanel:GetEntity():SetBodygroup(bg.id, 1)
                        data.bodygroups = data.bodygroups or {}
                        data.bodygroups[bg.id] = 1
                    end
                end
            elseif category == "accessories" then
                -- Accessory selection
                local accessoryList = vgui.Create("DListView", contentPanel)
                accessoryList:SetPos(320, 10)
                accessoryList:SetSize(490, 200)
                accessoryList:AddColumn("Accessories")
                
                -- Add accessories
                for category, items in pairs(KYBER.Customization.Accessories) do
                    for id, item in pairs(items.items) do
                        accessoryList:AddLine(item.name)
                    end
                end
                
                -- Update preview on selection
                accessoryList.OnRowSelected = function(_, _, row)
                    local item = KYBER.Customization.Accessories[row:GetValue(1)]
                    if item then
                        -- Add accessory to preview
                        local acc = ents.Create("prop_dynamic")
                        acc:SetModel(item.model)
                        acc:SetParent(previewPanel:GetEntity())
                        acc:SetPos(previewPanel:GetEntity():GetPos() + item.offset)
                        acc:SetAngles(previewPanel:GetEntity():GetAngles() + item.angle)
                        acc:SetModelScale(item.scale)
                        acc:Spawn()
                        
                        data.accessories = data.accessories or {}
                        data.accessories[category] = data.accessories[category] or {}
                        data.accessories[category][id] = {
                            material = "default"
                        }
                    end
                end
            elseif category == "effects" then
                -- Effect selection
                local effectList = vgui.Create("DListView", contentPanel)
                effectList:SetPos(320, 10)
                effectList:SetSize(490, 200)
                effectList:AddColumn("Effects")
                
                -- Add effects
                for category, items in pairs(KYBER.Customization.Effects) do
                    for id, item in pairs(items.items) do
                        effectList:AddLine(item.name)
                    end
                end
                
                -- Update preview on selection
                effectList.OnRowSelected = function(_, _, row)
                    local item = KYBER.Customization.Effects[row:GetValue(1)]
                    if item then
                        data.effects = data.effects or {}
                        data.effects[category] = data.effects[category] or {}
                        data.effects[category][id] = {
                            color = item.color,
                            scale = item.scale
                        }
                    end
                end
            elseif category == "presets" then
                -- Preset selection
                local presetList = vgui.Create("DListView", contentPanel)
                presetList:SetPos(320, 10)
                presetList:SetSize(490, 200)
                presetList:AddColumn("Presets")
                
                -- Add presets
                for id, preset in pairs(KYBER.Customization.Presets) do
                    presetList:AddLine(preset.name)
                end
                
                -- Update preview on selection
                presetList.OnRowSelected = function(_, _, row)
                    local preset = KYBER.Customization.Presets[row:GetValue(1)]
                    if preset then
                        data = table.Copy(preset)
                        previewPanel:SetModel(preset.model)
                    end
                end
                
                -- Add save preset button
                local saveButton = vgui.Create("DButton", contentPanel)
                saveButton:SetPos(320, 220)
                saveButton:SetSize(100, 30)
                saveButton:SetText("Save Preset")
                saveButton.DoClick = function()
                    local name = "preset_" .. os.time()
                    net.Start("Kyber_Customization_SavePreset")
                        net.WriteString(name)
                        net.WriteTable(data)
                    net.SendToServer()
                end
            end
        end
        
        -- Handle category selection
        categoryList.OnRowSelected = function(_, _, row)
            local category = row:GetValue(1)
            UpdateContent(category)
        end
        
        -- Add save button
        local saveButton = vgui.Create("DButton", frame)
        saveButton:SetPos(170, 640)
        saveButton:SetSize(100, 30)
        saveButton:SetText("Save")
        saveButton.DoClick = function()
            net.Start("Kyber_Customization_Update")
                net.WriteTable(data)
            net.SendToServer()
            frame:Close()
        end
    end
    
    -- Handle network messages
    net.Receive("Kyber_Customization_Open", function()
        local data = net.ReadTable()
        OpenCustomizationMenu(data)
    end)
end 