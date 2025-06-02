-- kyber/gamemode/modules/character/creator.lua

if SERVER then
    util.AddNetworkString("Kyber_OpenCharacterCreator")
    util.AddNetworkString("Kyber_CreateCharacter")
    util.AddNetworkString("Kyber_CheckFirstSpawn")
    
    -- Check if player needs character creation
    hook.Add("PlayerInitialSpawn", "KyberCheckCharacterCreation", function(ply)
        timer.Simple(2, function()
            if not IsValid(ply) then return end
            
            -- Check if this is their first spawn or they have no character data
            local hasCharacter = ply:GetPData("kyber_has_character", "false") == "true"
            
            if not hasCharacter then
                net.Start("Kyber_OpenCharacterCreator")
                net.WriteBool(true) -- Force open
                net.Send(ply)
            else
                -- Load existing character data
                local name = ply:GetPData("kyber_name", ply:Nick())
                local species = ply:GetPData("kyber_species", "Human")
                local alignment = ply:GetPData("kyber_alignment", "Neutral")
                
                ply:SetNWString("kyber_name", name)
                ply:SetNWString("kyber_species", species)
                ply:SetNWString("kyber_alignment", alignment)
            end
        end)
    end)
    
    -- Handle character creation
    net.Receive("Kyber_CreateCharacter", function(len, ply)
        local charData = net.ReadTable()
        
        -- Validate character data
        if not charData.name or string.len(charData.name) < 2 or string.len(charData.name) > 32 then
            ply:ChatPrint("Invalid character name. Must be 2-32 characters.")
            return
        end
        
        if not charData.species or string.len(charData.species) < 2 or string.len(charData.species) > 32 then
            ply:ChatPrint("Invalid species. Must be 2-32 characters.")
            return
        end
        
        -- Set character data
        ply:SetNWString("kyber_name", charData.name)
        ply:SetNWString("kyber_species", charData.species)
        ply:SetNWString("kyber_alignment", charData.alignment or "Neutral")
        
        -- Save to persistent data
        ply:SetPData("kyber_name", charData.name)
        ply:SetPData("kyber_species", charData.species)
        ply:SetPData("kyber_alignment", charData.alignment or "Neutral")
        ply:SetPData("kyber_backstory", charData.backstory or "")
        ply:SetPData("kyber_skills", charData.skills or "")
        ply:SetPData("kyber_has_character", "true")
        
        -- Set faction if selected
        if charData.faction and charData.faction ~= "" and KYBER.Factions[charData.faction] then
            KYBER:SetFaction(ply, charData.faction)
        end
        
        -- Welcome message
        ply:ChatPrint("Welcome to the galaxy, " .. charData.name .. "!")
        ply:ChatPrint("Your character has been created. Use F1 to view your character sheet.")
        
        -- Trigger respawn with new character
        ply.IsCharacterSwitch = true
        ply:Spawn()
    end)
    
    -- Command to recreate character
    concommand.Add("kyber_recreate", function(ply)
        net.Start("Kyber_OpenCharacterCreator")
        net.WriteBool(false) -- Not forced
        net.Send(ply)
    end)
    
else -- CLIENT
    
    net.Receive("Kyber_OpenCharacterCreator", function()
        local forced = net.ReadBool()
        KYBER:OpenCharacterCreator(forced)
    end)
    
    function KYBER:OpenCharacterCreator(forced)
        if IsValid(CharacterCreatorFrame) then CharacterCreatorFrame:Remove() end
        
        CharacterCreatorFrame = vgui.Create("DFrame")
        CharacterCreatorFrame:SetSize(800, 700)
        CharacterCreatorFrame:Center()
        CharacterCreatorFrame:SetTitle("")
        CharacterCreatorFrame:MakePopup()
        
        if forced then
            CharacterCreatorFrame:ShowCloseButton(false)
        end
        
        -- Custom paint
        CharacterCreatorFrame.Paint = function(self, w, h)
            -- Animated background
            local time = CurTime()
            local stars = {}
            math.randomseed(12345) -- Fixed seed for consistent stars
            for i = 1, 50 do
                table.insert(stars, {
                    x = math.random(0, w),
                    y = math.random(0, h),
                    size = math.random(1, 3),
                    alpha = math.sin(time + i) * 50 + 100
                })
            end
            
            -- Background
            draw.RoundedBox(8, 0, 0, w, h, Color(5, 10, 20, 250))
            
            -- Draw stars
            for _, star in ipairs(stars) do
                surface.SetDrawColor(255, 255, 255, star.alpha)
                surface.DrawRect(star.x, star.y, star.size, star.size)
            end
            
            -- Overlay
            draw.RoundedBox(8, 2, 2, w-4, h-4, Color(20, 30, 50, 200))
            
            -- Title
            draw.SimpleText("CHARACTER CREATION", "DermaLarge", w/2, 30, Color(100, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Create your identity in the galaxy", "DermaDefault", w/2, 55, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Decorative line
            surface.SetDrawColor(100, 150, 255, 100)
            surface.DrawRect(50, 75, w-100, 2)
        end
        
        -- Main container
        local container = vgui.Create("DScrollPanel", CharacterCreatorFrame)
        container:SetPos(50, 90)
        container:SetSize(CharacterCreatorFrame:GetWide() - 100, CharacterCreatorFrame:GetTall() - 140)
        
        local y = 20
        
        -- Name section
        local namePanel = vgui.Create("DPanel", container)
        namePanel:SetPos(0, y)
        namePanel:SetSize(container:GetWide(), 80)
        namePanel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(30, 40, 60, 150))
            draw.SimpleText("CHARACTER NAME", "DermaDefaultBold", 15, 15, Color(100, 150, 255))
        end
        
        local nameEntry = vgui.Create("DTextEntry", namePanel)
        nameEntry:SetPos(15, 40)
        nameEntry:SetSize(namePanel:GetWide() - 30, 25)
        nameEntry:SetPlaceholderText("Enter your character's full name...")
        nameEntry.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(20, 30, 50))
            draw.RoundedBox(4, 1, 1, w-2, h-2, Color(40, 50, 70))
            self:DrawTextEntryText(Color(255, 255, 255), Color(100, 150, 255), Color(255, 255, 255))
        end
        y = y + 100
        
        -- Species section
        local speciesPanel = vgui.Create("DPanel", container)
        speciesPanel:SetPos(0, y)
        speciesPanel:SetSize(container:GetWide(), 80)
        speciesPanel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(30, 40, 60, 150))
            draw.SimpleText("SPECIES", "DermaDefaultBold", 15, 15, Color(100, 150, 255))
        end
        
        local speciesCombo = vgui.Create("DComboBox", speciesPanel)
        speciesCombo:SetPos(15, 40)
        speciesCombo:SetSize(speciesPanel:GetWide() - 30, 25)
        speciesCombo:SetValue("Select Species")
        
        -- Add species options
        local species = {
            "Human", "Twi'lek", "Rodian", "Wookiee", "Zabrak", "Togruta", 
            "Chiss", "Nautolan", "Bothan", "Mon Calamari", "Sullustan", 
            "Cathar", "Miraluka", "Epicanthix", "Arkanian", "Other"
        }
        
        for _, spec in ipairs(species) do
            speciesCombo:AddChoice(spec)
        end
        
        speciesCombo.Paint = nameEntry.Paint
        y = y + 100
        
        -- Alignment section
        local alignPanel = vgui.Create("DPanel", container)
        alignPanel:SetPos(0, y)
        alignPanel:SetSize(container:GetWide(), 120)
        alignPanel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(30, 40, 60, 150))
            draw.SimpleText("MORAL ALIGNMENT", "DermaDefaultBold", 15, 15, Color(100, 150, 255))
            draw.SimpleText("This affects your character's worldview and potential faction options", "DermaDefault", 15, 35, Color(200, 200, 200))
        end
        
        local alignmentButtons = {}
        local alignments = {
            {name = "Light Side", desc = "Compassionate, selfless, protective", color = Color(100, 150, 255)},
            {name = "Neutral", desc = "Balanced, pragmatic, adaptive", color = Color(200, 200, 200)},
            {name = "Dark Side", desc = "Ambitious, passionate, powerful", color = Color(255, 100, 100)}
        }
        
        local selectedAlignment = "Neutral"
        
        for i, align in ipairs(alignments) do
            local btn = vgui.Create("DButton", alignPanel)
            btn:SetPos(15 + (i-1) * 220, 60)
            btn:SetSize(200, 40)
            btn:SetText("")
            
            btn.Paint = function(self, w, h)
                local col = (selectedAlignment == align.name) and align.color or Color(50, 50, 50)
                if self:IsHovered() then
                    col = Color(col.r + 30, col.g + 30, col.b + 30)
                end
                
                draw.RoundedBox(6, 0, 0, w, h, col)
                draw.SimpleText(align.name, "DermaDefaultBold", w/2, 12, Color(255, 255, 255), TEXT_ALIGN_CENTER)
                draw.SimpleText(align.desc, "DermaDefault", w/2, 28, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            end
            
            btn.DoClick = function()
                selectedAlignment = align.name
            end
            
            alignmentButtons[align.name] = btn
        end
        y = y + 140
        
        -- Faction section (optional)
        local factionPanel = vgui.Create("DPanel", container)
        factionPanel:SetPos(0, y)
        factionPanel:SetSize(container:GetWide(), 100)
        factionPanel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(30, 40, 60, 150))
            draw.SimpleText("STARTING FACTION (Optional)", "DermaDefaultBold", 15, 15, Color(100, 150, 255))
            draw.SimpleText("You can join factions later in-game", "DermaDefault", 15, 35, Color(200, 200, 200))
        end
        
        local factionCombo = vgui.Create("DComboBox", factionPanel)
        factionCombo:SetPos(15, 60)
        factionCombo:SetSize(factionPanel:GetWide() - 30, 25)
        factionCombo:SetValue("Independent (No Faction)")
        factionCombo:AddChoice("Independent", "")
        
        if KYBER and KYBER.Factions then
            for id, faction in pairs(KYBER.Factions) do
                factionCombo:AddChoice(faction.name, id)
            end
        end
        
        factionCombo.Paint = nameEntry.Paint
        y = y + 120
        
        -- Backstory section
        local backstoryPanel = vgui.Create("DPanel", container)
        backstoryPanel:SetPos(0, y)
        backstoryPanel:SetSize(container:GetWide(), 140)
        backstoryPanel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(30, 40, 60, 150))
            draw.SimpleText("BACKSTORY", "DermaDefaultBold", 15, 15, Color(100, 150, 255))
            draw.SimpleText("Tell us about your character's history and motivations", "DermaDefault", 15, 35, Color(200, 200, 200))
        end
        
        local backstoryEntry = vgui.Create("DTextEntry", backstoryPanel)
        backstoryEntry:SetPos(15, 55)
        backstoryEntry:SetSize(backstoryPanel:GetWide() - 30, 70)
        backstoryEntry:SetMultiline(true)
        backstoryEntry:SetPlaceholderText("Where were you born? What drives you? What are your goals?")
        backstoryEntry.Paint = nameEntry.Paint
        y = y + 160
        
        -- Skills section
        local skillsPanel = vgui.Create("DPanel", container)
        skillsPanel:SetPos(0, y)
        skillsPanel:SetSize(container:GetWide(), 140)
        skillsPanel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(30, 40, 60, 150))
            draw.SimpleText("SKILLS & ABILITIES", "DermaDefaultBold", 15, 15, Color(100, 150, 255))
            draw.SimpleText("What is your character good at?", "DermaDefault", 15, 35, Color(200, 200, 200))
        end
        
        local skillsEntry = vgui.Create("DTextEntry", skillsPanel)
        skillsEntry:SetPos(15, 55)
        skillsEntry:SetSize(skillsPanel:GetWide() - 30, 70)
        skillsEntry:SetMultiline(true)
        skillsEntry:SetPlaceholderText("e.g., Piloting, Mechanics, Combat, Diplomacy, Force sensitivity...")
        skillsEntry.Paint = nameEntry.Paint
        y = y + 160
        
        -- Create character button
        local createBtn = vgui.Create("DButton", CharacterCreatorFrame)
        createBtn:SetPos(CharacterCreatorFrame:GetWide()/2 - 150, CharacterCreatorFrame:GetTall() - 40)
        createBtn:SetSize(300, 35)
        createBtn:SetText("")
        
        createBtn.Paint = function(self, w, h)
            local col = self:IsHovered() and Color(120, 170, 255) or Color(100, 150, 255)
            draw.RoundedBox(8, 0, 0, w, h, col)
            
            -- Animated glow effect
            local glow = math.sin(CurTime() * 3) * 30 + 50
            draw.RoundedBox(8, 2, 2, w-4, h-4, Color(col.r + glow, col.g + glow, col.b + glow, 100))
            
            draw.SimpleText("CREATE CHARACTER", "DermaDefaultBold", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        createBtn.DoClick = function()
            -- Validate inputs
            local name = nameEntry:GetValue()
            if string.len(name) < 2 then
                Derma_Message("Please enter a valid character name (at least 2 characters).", "Invalid Name", "OK")
                return
            end
            
            local _, species = speciesCombo:GetSelected()
            if not species then
                Derma_Message("Please select a species for your character.", "No Species Selected", "OK")
                return
            end
            
            local _, faction = factionCombo:GetSelected()
            
            -- Create character data
            local charData = {
                name = name,
                species = species,
                alignment = selectedAlignment,
                faction = faction or "",
                backstory = backstoryEntry:GetValue(),
                skills = skillsEntry:GetValue()
            }
            
            -- Confirmation dialog
            local confirmText = "Create character with the following details?\n\n"
            confirmText = confirmText .. "Name: " .. charData.name .. "\n"
            confirmText = confirmText .. "Species: " .. charData.species .. "\n"
            confirmText = confirmText .. "Alignment: " .. charData.alignment .. "\n"
            if charData.faction ~= "" then
                local factionName = "Unknown"
                if KYBER.Factions and KYBER.Factions[charData.faction] then
                    factionName = KYBER.Factions[charData.faction].name
                end
                confirmText = confirmText .. "Starting Faction: " .. factionName .. "\n"
            end
            
            Derma_Query(
                confirmText,
                "Confirm Character Creation",
                "Create Character", function()
                    net.Start("Kyber_CreateCharacter")
                    net.WriteTable(charData)
                    net.SendToServer()
                    
                    CharacterCreatorFrame:Close()
                end,
                "Go Back", function() end
            )
        end
    end
    
    -- Add console command to open character creator
    concommand.Add("kyber_charcreate", function()
        KYBER:OpenCharacterCreator(false)
    end)
end