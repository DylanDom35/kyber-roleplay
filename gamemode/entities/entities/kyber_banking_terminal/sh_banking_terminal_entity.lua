-- kyber/entities/entities/kyber_banking_terminal/init.lua
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_lab/servers.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
    
    -- Default to personal banking
    if not self:GetTerminalType() or self:GetTerminalType() == "" then
        self:SetTerminalType("personal")
    end
    
    self:SetTerminalActive(true)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    if not self:GetTerminalActive() then
        activator:ChatPrint("This terminal is offline.")
        return
    end
    
    -- Check distance for security
    if activator:GetPos():Distance(self:GetPos()) > 100 then
        activator:ChatPrint("You must be closer to use the terminal.")
        return
    end
    
    -- Open banking interface
    net.Start("Kyber_Banking_Open")
    net.WriteEntity(self)
    net.WriteString(self:GetTerminalType())
    net.Send(activator)
    
    -- Sound effect
    self:EmitSound("buttons/button14.wav")
end

function ENT:OnRemove()
    -- Any cleanup needed
end

-- kyber/entities/entities/kyber_banking_terminal/cl_init.lua
include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos()
    local ang = self:GetAngles()
    
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    
    -- Terminal info display
    cam.Start3D2D(pos + ang:Up() * 30 + ang:Forward() * -15, ang, 0.1)
        local active = self:GetTerminalActive()
        
        -- Background
        draw.RoundedBox(6, -150, -100, 300, 200, Color(0, 0, 0, 200))
        
        -- Terminal type
        local terminalName = "Banking Terminal"
        local terminalType = self:GetTerminalType()
        
        if terminalType == "faction" then
            terminalName = "Faction Treasury"
        elseif terminalType == "exchange" then
            terminalName = "Credit Exchange"
        end
        
        -- Title
        draw.SimpleText(terminalName, "DermaLarge", 0, -70, active and Color(100, 255, 100) or Color(255, 50, 50), TEXT_ALIGN_CENTER)
        
        if active then
            -- Holographic effect
            local pulse = math.sin(CurTime() * 2) * 0.3 + 0.7
            
            -- Credit symbol
            surface.SetDrawColor(100 * pulse, 200 * pulse, 255 * pulse, 200)
            draw.NoTexture()
            
            -- Draw credit symbol (simplified)
            local size = 40
            for i = 0, 360, 45 do
                local x1 = math.sin(math.rad(i)) * size
                local y1 = math.cos(math.rad(i)) * size
                local x2 = math.sin(math.rad(i + 45)) * size
                local y2 = math.cos(math.rad(i + 45)) * size
                
                surface.DrawLine(x1, y1 - 20, x2, y2 - 20)
            end
            
            -- Instructions
            draw.SimpleText("Press E to access", "DermaDefault", 0, 40, Color(200, 200, 200), TEXT_ALIGN_CENTER)
            
            -- Security level
            draw.SimpleText("Security: Maximum", "DermaDefault", 0, 60, Color(100, 255, 100), TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("OFFLINE", "DermaLarge", 0, 0, Color(255, 50, 50, math.sin(CurTime() * 5) * 127 + 128), TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end

function ENT:GetOverlayText()
    if self:GetTerminalActive() then
        return "Banking Terminal\nPress E to access"
    else
        return "Banking Terminal\nOFFLINE"
    end
end

-- kyber/entities/entities/kyber_banking_terminal/shared.lua
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Banking Terminal"
ENT.Author = "Kyber"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Kyber RP"

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "TerminalType") -- personal, faction, exchange
    self:NetworkVar("Bool", 0, "TerminalActive")
    self:NetworkVar("String", 1, "OwnerFaction") -- For faction terminals
end