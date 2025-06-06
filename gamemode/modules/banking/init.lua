-- Banking module
local Banking = {}
Banking.__index = Banking

-- Banking module configuration
KYBER.Banking.Config = {
    MaxAccounts = 3,
    MaxBalance = 999999999,
    MinBalance = 0,
    InterestRate = 0.01, -- 1% interest per day
    InterestInterval = 86400, -- 24 hours in seconds
    TransactionFee = 0.05, -- 5% fee on transactions
    MinTransactionAmount = 1,
    MaxTransactionAmount = 1000000,
    AccountTypes = {
        ["personal"] = {
            name = "Personal Account",
            maxBalance = 1000000,
            interestRate = 0.01,
            monthlyFee = 0
        },
        ["business"] = {
            name = "Business Account",
            maxBalance = 10000000,
            interestRate = 0.02,
            monthlyFee = 1000
        },
        ["savings"] = {
            name = "Savings Account",
            maxBalance = 100000,
            interestRate = 0.03,
            monthlyFee = 0
        }
    }
}

-- Initialize the module
function Banking:Initialize()
    print("[Kyber] Initializing Banking module")
    
    -- Register network strings
    util.AddNetworkString("Kyber_Banking_Open")
    util.AddNetworkString("Kyber_Banking_Update")
    util.AddNetworkString("Kyber_Banking_Deposit")
    util.AddNetworkString("Kyber_Banking_Withdraw")
    util.AddNetworkString("Kyber_Banking_Transfer")
    
    -- Initialize banking data
    self.Accounts = {}
    self.InterestRate = 0.01 -- 1% daily interest
    self.MinBalance = 0
    self.MaxBalance = 1000000
    
    -- Load accounts
    self:LoadAccounts()
    
    -- Register the module
    KYBER.RegisterModule("banking", self)
    
    -- Start interest timer
    if SERVER then
        timer.Create("Kyber_Banking_Interest", self.Config.InterestInterval, 0, function()
            self:ProcessInterest()
        end)
    end
    
    return true
end

-- Load accounts
function Banking:LoadAccounts()
    -- TODO: Implement account loading from database
    print("[Kyber] Loading account data")
end

-- Get player account
function Banking:GetAccount(ply)
    if not IsValid(ply) then return nil end
    
    -- TODO: Implement account retrieval
    return {
        balance = 0,
        interest = 0,
        lastInterest = os.time()
    }
end

-- Deposit money
function Banking:Deposit(ply, amount)
    if not IsValid(ply) then return false end
    
    -- TODO: Implement money deposit
    print("[Kyber] Depositing " .. amount .. " credits for " .. ply:Nick())
    return true
end

-- Withdraw money
function Banking:Withdraw(ply, amount)
    if not IsValid(ply) then return false end
    
    -- TODO: Implement money withdrawal
    print("[Kyber] Withdrawing " .. amount .. " credits for " .. ply:Nick())
    return true
end

-- Transfer money
function Banking:Transfer(ply, target, amount)
    if not IsValid(ply) or not IsValid(target) then return false end
    
    -- TODO: Implement money transfer
    print("[Kyber] Transferring " .. amount .. " credits from " .. ply:Nick() .. " to " .. target:Nick())
    return true
end

-- Calculate interest
function Banking:CalculateInterest(account)
    if not account then return 0 end
    
    local timeDiff = os.time() - account.lastInterest
    local days = timeDiff / 86400 -- Convert seconds to days
    
    return account.balance * self.InterestRate * days
end

-- Apply interest
function Banking:ApplyInterest(account)
    if not account then return false end
    
    local interest = self:CalculateInterest(account)
    account.balance = account.balance + interest
    account.lastInterest = os.time()
    
    return true
end

function Banking:Save(ply)
    if not IsValid(ply) or not ply.KyberBanking then return end
    
    local path = "kyber/banking/" .. ply:SteamID64() .. ".json"
    
    -- Create backup
    if file.Exists(path, "DATA") then
        file.Write(path .. ".backup", file.Read(path, "DATA"))
    end
    
    -- Write new data
    file.Write(path, util.TableToJSON(ply.KyberBanking))
end

function Banking:CreateBankingData(ply)
    if not IsValid(ply) then return false end
    
    -- Create banking data table if it doesn't exist
    ply.KyberBanking = ply.KyberBanking or {
        accounts = {},
        lastInterest = CurTime()
    }
    
    return true
end

function Banking:CreateAccount(ply, accountType)
    if not IsValid(ply) then return false end
    if not self:CreateBankingData(ply) then return false end
    
    -- Validate account type
    if not self.Config.AccountTypes[accountType] then
        return false
    end
    
    -- Check account limit
    if table.Count(ply.KyberBanking.accounts) >= self.Config.MaxAccounts then
        return false
    end
    
    -- Generate account number
    local accountNumber = "ACC" .. os.time() .. math.random(1000, 9999)
    
    -- Create account
    ply.KyberBanking.accounts[accountNumber] = {
        type = accountType,
        balance = 0,
        created = os.time(),
        lastInterest = CurTime()
    }
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Banking_Update")
        net.WriteEntity(ply)
        net.WriteTable(ply.KyberBanking)
        net.Send(ply)
    end
    
    return accountNumber
end

function Banking:CloseAccount(ply, accountNumber)
    if not IsValid(ply) then return false end
    if not ply.KyberBanking or not ply.KyberBanking.accounts[accountNumber] then
        return false
    end
    
    -- Get account data
    local account = ply.KyberBanking.accounts[accountNumber]
    
    -- Return balance to player
    if account.balance > 0 then
        KYBER.Economy:AddCredits(ply, account.balance)
    end
    
    -- Remove account
    ply.KyberBanking.accounts[accountNumber] = nil
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Banking_Update")
        net.WriteEntity(ply)
        net.WriteTable(ply.KyberBanking)
        net.Send(ply)
    end
    
    return true
end

function Banking:GetBalance(ply, accountNumber)
    if not IsValid(ply) then return 0 end
    if not ply.KyberBanking or not ply.KyberBanking.accounts[accountNumber] then
        return 0
    end
    
    return ply.KyberBanking.accounts[accountNumber].balance
end

function Banking:SetBalance(ply, accountNumber, amount)
    if not IsValid(ply) then return false end
    if not ply.KyberBanking or not ply.KyberBanking.accounts[accountNumber] then
        return false
    end
    
    -- Get account data
    local account = ply.KyberBanking.accounts[accountNumber]
    local accountType = self.Config.AccountTypes[account.type]
    
    -- Clamp balance
    amount = math.Clamp(amount, self.Config.MinBalance, accountType.maxBalance)
    
    -- Set balance
    account.balance = amount
    
    -- Notify client
    if SERVER then
        net.Start("Kyber_Banking_Update")
        net.WriteEntity(ply)
        net.WriteTable(ply.KyberBanking)
        net.Send(ply)
    end
    
    return true
end

function Banking:ProcessInterest()
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply.KyberBanking then continue end
        
        for accountNumber, account in pairs(ply.KyberBanking.accounts) do
            local accountType = self.Config.AccountTypes[account.type]
            if accountType and account.balance > 0 then
                local interest = math.floor(account.balance * accountType.interestRate)
                self:SetBalance(ply, accountNumber, account.balance + interest)
            end
        end
    end
end

function Banking:LogTransaction(fromPly, toPly, fromAccount, toAccount, amount, fee)
    if not SERVER then return end
    
    local log = string.format(
        "[%s] Transfer: %s (%s) -> %s (%s): %d credits (Fee: %d)",
        os.date("%Y-%m-%d %H:%M:%S"),
        fromPly:Nick(),
        fromAccount,
        toPly:Nick(),
        toAccount,
        amount,
        fee
    )
    
    print(log)
    -- TODO: Add proper logging system
end

function Banking:GetAccounts(ply)
    if not IsValid(ply) then return nil end
    if not self:CreateBankingData(ply) then return nil end
    
    return ply.KyberBanking.accounts
end

-- Initialize the module
Banking:Initialize()

-- Register the module
KYBER.Modules.banking = Banking
return Banking

-- Initialize banking module
KYBER.Banking = KYBER.Banking or {}

-- Include banking system files
include("kyber/gamemode/modules/banking/core.lua")
include("kyber/gamemode/modules/banking/transactions.lua")

-- Register network strings
KYBER.Management.Network:Register("Kyber_Banking_Update")
KYBER.Management.Network:Register("Kyber_Banking_Deposit")
KYBER.Management.Network:Register("Kyber_Banking_Withdraw")
KYBER.Management.Network:Register("Kyber_Banking_Transfer")

-- Initialize banking system
local success, err = pcall(function()
    -- Create banking directory if it doesn't exist
    if not file.Exists("kyber/banking", "DATA") then
        file.CreateDir("kyber/banking")
    end
end)

if not success then
    KYBER.Management.ErrorHandler:Handle(err, "Failed to initialize banking system")
end

-- Cleanup function
function KYBER.Banking:Cleanup()
    -- Add any cleanup code here
end 