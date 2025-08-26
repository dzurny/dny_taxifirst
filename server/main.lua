local playerCooldowns = {}
local COOLDOWN_HOURS = 1
local COOLDOWN_MS = COOLDOWN_HOURS * 60 * 60 * 1000

function CanPlayerUseTaxi(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return false
    end
    
    local playerId = source
    local currentTime = GetGameTimer()
    local lastUseTime = playerCooldowns[playerId]
    
    if not lastUseTime or (currentTime - lastUseTime) >= COOLDOWN_MS then
        return true
    end
    
    return false
end

function MarkPlayerAsUsedTaxi(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local playerId = source
        playerCooldowns[playerId] = GetGameTimer()
    end
end

function GetRemainingCooldownMinutes(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return 0
    end
    
    local playerId = source
    local currentTime = GetGameTimer()
    local lastUseTime = playerCooldowns[playerId]
    
    if not lastUseTime then
        return 0
    end
    
    local timeElapsed = currentTime - lastUseTime
    local remainingMs = COOLDOWN_MS - timeElapsed
    
    if remainingMs <= 0 then
        return 0
    end
    
    return math.ceil(remainingMs / (60 * 1000))
end

ESX.RegisterServerCallback('taxi:canPlayerUseTaxi', function(source, cb)
    local canUse = CanPlayerUseTaxi(source)
    cb(canUse)
end)

ESX.RegisterServerCallback('taxi:getRemainingCooldown', function(source, cb)
    local remainingMinutes = GetRemainingCooldownMinutes(source)
    cb(remainingMinutes)
end)

RegisterNetEvent('taxi:playerUsed')
AddEventHandler('taxi:playerUsed', function()
    MarkPlayerAsUsedTaxi(source)
end)

exports('GetTaxiUsageCount', function()
    local count = 0
    for _ in pairs(playerCooldowns) do
        count = count + 1
    end
    return count
end)

exports('GetPlayerCooldownInfo', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return nil
    end
    
    local playerId = source
    local lastUseTime = playerCooldowns[playerId]
    
    if not lastUseTime then
        return {
            canUse = true,
            remainingMinutes = 0,
            lastUseTime = nil
        }
    end
    
    local currentTime = GetGameTimer()
    local timeElapsed = currentTime - lastUseTime
    local remainingMs = COOLDOWN_MS - timeElapsed
    local canUse = remainingMs <= 0
    
    return {
        canUse = canUse,
        remainingMinutes = canUse and 0 or math.ceil(remainingMs / (60 * 1000)),
        lastUseTime = lastUseTime
    }
end)

AddEventHandler('playerDropped', function()
    local playerId = source
    if playerCooldowns[playerId] then
        playerCooldowns[playerId] = nil
    end
end)
