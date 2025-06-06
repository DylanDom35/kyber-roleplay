-- Economy module initialization
KYBER.Economy = KYBER.Economy or {}

-- Economy module configuration
KYBER.Economy.Config = {
    StartingCredits = 1000,
    MaxCredits = 999999999,
    MinTransactionAmount = 1,
    MaxTransactionAmount = 1000000,
    TransactionFee = 0.05, -- 5% fee on transactions
    InterestRate = 0.01, -- 1% interest per day
    InterestInterval = 86400, -- 24 hours in seconds
    Jobs = {
        {
            id = "citizen",
            name = "Citizen",
            baseSalary = 100,
            description = "A regular citizen"
        },
        {
            id = "police",
            name = "Police Officer",
            baseSalary = 200,
            description = "Maintains law and order"
        },
        {
            id = "medic",
            name = "Medic",
            baseSalary = 200,
            description = "Provides medical assistance"
        }
    }
}

-- Economy module functions
function KYBER.Economy:Initialize()
    print("[Kyber] Economy module initialized")
    
    -- Start interest timer
    if SERVER then
        timer.Create("Kyber_Economy_Interest", self.Config.InterestInterval, 0, function()
            self:ProcessInterest()
        end)
    end
    
    return true
end

function KYBER.Economy:GetCredits(ply)
    if not IsValid(ply) then return 0 end
    
    return ply.KyberCredits or self.Config.StartingCredits
end

function KYBER.Economy:SetCredits(ply, amount)
    if not IsValid(ply) then return false end
    
    amount = math.Clamp(amount, 0, self.Config.MaxCredits)
    ply.KyberCredits = amount
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Economy_UpdateCredits")
        net.WriteEntity(ply)
        net.WriteInt(amount, 32)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Economy:AddCredits(ply, amount)
    if not IsValid(ply) then return false end
    
    local currentCredits = self:GetCredits(ply)
    return self:SetCredits(ply, currentCredits + amount)
end

function KYBER.Economy:RemoveCredits(ply, amount)
    if not IsValid(ply) then return false end
    
    local currentCredits = self:GetCredits(ply)
    return self:SetCredits(ply, currentCredits - amount)
end

function KYBER.Economy:TransferCredits(from, to, amount)
    if not IsValid(from) or not IsValid(to) then return false end
    if amount < self.Config.MinTransactionAmount then return false end
    if amount > self.Config.MaxTransactionAmount then return false end
    
    -- Calculate fee
    local fee = math.floor(amount * self.Config.TransactionFee)
    local totalAmount = amount + fee
    
    -- Check if sender has enough credits
    if self:GetCredits(from) < totalAmount then
        return false
    end
    
    -- Perform transaction
    if not self:RemoveCredits(from, totalAmount) then return false end
    if not self:AddCredits(to, amount) then
        -- Refund if transfer fails
        self:AddCredits(from, totalAmount)
        return false
    end
    
    -- Log transaction
    if SERVER then
        self:LogTransaction(from, to, amount, fee)
    end
    
    return true
end

function KYBER.Economy:GetJob(ply)
    if not IsValid(ply) then return nil end
    
    return ply.KyberJob or "citizen"
end

function KYBER.Economy:SetJob(ply, jobId)
    if not IsValid(ply) then return false end
    
    -- Validate job
    local jobExists = false
    for _, job in ipairs(self.Config.Jobs) do
        if job.id == jobId then
            jobExists = true
            break
        end
    end
    
    if not jobExists then return false end
    
    -- Set job
    ply.KyberJob = jobId
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Economy_UpdateJob")
        net.WriteEntity(ply)
        net.WriteString(jobId)
        net.Send(ply)
    end
    
    return true
end

function KYBER.Economy:GetSalary(ply)
    if not IsValid(ply) then return 0 end
    
    local jobId = self:GetJob(ply)
    for _, job in ipairs(self.Config.Jobs) do
        if job.id == jobId then
            return job.baseSalary
        end
    end
    
    return 0
end

function KYBER.Economy:ProcessInterest()
    for _, ply in ipairs(player.GetAll()) do
        local credits = self:GetCredits(ply)
        if credits > 0 then
            local interest = math.floor(credits * self.Config.InterestRate)
            self:AddCredits(ply, interest)
        end
    end
end

function KYBER.Economy:LogTransaction(from, to, amount, fee)
    if not SERVER then return end
    
    local log = string.format(
        "[%s] Transaction: %s -> %s: %d credits (Fee: %d)",
        os.date("%Y-%m-%d %H:%M:%S"),
        from:Nick(),
        to:Nick(),
        amount,
        fee
    )
    
    print(log)
    -- TODO: Add proper logging system
end

-- Initialize the module
KYBER.Economy:Initialize() 