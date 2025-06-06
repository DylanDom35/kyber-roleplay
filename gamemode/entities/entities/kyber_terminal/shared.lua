ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Data Terminal"
ENT.Author = "Acrowe"
ENT.Spawnable = true
ENT.Category = "Kyber RP"

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "TerminalActive")
    self:NetworkVar("Bool", 1, "AlarmActive")
    self:NetworkVar("Int", 0, "FailedAttempts")
    self:NetworkVar("String", 0, "LastUser")
    -- Log table will be managed server-side
end
