local taxiPed = nil
local taxiPedCoords = vec4(-1038.698853, -2730.804443, 20.164062, 189.921265)
local isTaxiRideActive = false

CreateThread(function()
    while not ESX do
        Wait(1000)
    end
    
    Wait(2000)
    
    CreateTaxiPed()
end)

function CreateTaxiPed()
    local pedModel = `a_m_m_business_01`
    
    RequestModel(pedModel)
    
    local attempts = 0
    while not HasModelLoaded(pedModel) and attempts < 100 do
        attempts = attempts + 1
        Wait(100)
    end
    
    if not HasModelLoaded(pedModel) then
        return
    end
    
    local success, ped = pcall(function()
        return CreatePed(4, pedModel, taxiPedCoords.x, taxiPedCoords.y, taxiPedCoords.z - 1.0, taxiPedCoords.w, false, true)
    end)
    
    if not success or not ped or not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(pedModel)
        return
    end
    
    taxiPed = ped
    
    SetEntityAsMissionEntity(taxiPed, true, true)
    SetBlockingOfNonTemporaryEvents(taxiPed, true)
    SetPedCanRagdoll(taxiPed, false)
    SetPedCanBeTargetted(taxiPed, false)
    FreezeEntityPosition(taxiPed, true)
    SetEntityInvincible(taxiPed, true)
    
    SetModelAsNoLongerNeeded(pedModel)
    
    local targetSuccess = pcall(function()
        exports.ox_target:addLocalEntity(taxiPed, {
            {
                name = 'taxi_ped_interaction',
                icon = 'fas fa-taxi',
                label = 'Mluvit s taxikářem',
                onSelect = function()
                    HandleTaxiInteraction()
                end
            }
        })
    end)
    
    if not targetSuccess then
        DeleteEntity(taxiPed)
        taxiPed = nil
        return
    end
end

function HandleTaxiInteraction()
    if isTaxiRideActive then
        lib.notify({
            title = 'Taxikář',
            description = 'Počkej, už tě převážím!',
            type = 'error'
        })
        return
    end
    
    ESX.TriggerServerCallback('taxi:canPlayerUseTaxi', function(canUse)
        if canUse then
            local alert = lib.alertDialog({
                header = 'Taxikář',
                content = 'Ahoj! Potřebuješ svezení někam?',
                centered = true,
                cancel = true,
                labels = {
                    confirm = 'Ano',
                    cancel = 'Ne'
                }
            })
            
            if alert == 'confirm' then
                StartTaxiRide()
            elseif alert == 'cancel' then
                lib.notify({
                    title = 'Taxikář',
                    description = 'Dobře, možná příště!',
                    type = 'error'
                })
            end
        else
            ESX.TriggerServerCallback('taxi:getRemainingCooldown', function(remainingMinutes)
                local hours = math.floor(remainingMinutes / 60)
                local minutes = remainingMinutes % 60
                local timeText = ''
                
                if hours > 0 then
                    timeText = string.format('%d hodin a %d minut', hours, minutes)
                else
                    timeText = string.format('%d minut', minutes)
                end
                
                lib.notify({
                    title = 'Taxikář',
                    description = string.format('Musíš počkat ještě %s před dalším použitím.', timeText),
                    type = 'error'
                })
            end)
        end
    end)
end

function StartTaxiRide()
    isTaxiRideActive = true
    
    if taxiPed and DoesEntityExist(taxiPed) then
        DeleteEntity(taxiPed)
        taxiPed = nil
    end
    
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        type = 'showBlackScreen',
        show = true
    })
    
    if lib.progressBar({
        duration = 15000,
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true,
            sprint = true
        }
    }) then
        SendNUIMessage({
            type = 'showBlackScreen',
            show = false
        })
        
        CompleteTaxiRide()
    end
end

function CompleteTaxiRide()
    local destination = vec4(150.052750, -1040.690063, 29.364136, 155.905502)
    local playerPed = PlayerPedId()
    
    SetEntityCoords(playerPed, destination.x, destination.y, destination.z, false, false, false, true)
    SetEntityHeading(playerPed, destination.w)
    
    lib.notify({
        title = 'Taxikář',
        description = 'Jsme tu! Užij si pobyt!',
        type = 'success'
    })
    
    PlayTalkingAnimation(playerPed)
    
    Wait(2000)
    CreateTaxiPed()
    
    isTaxiRideActive = false
end

function PlayTalkingAnimation(playerPed)
    local talkingDict = "amb@world_human_stand_guard@male_a@base"
    local talkingAnim = "base"
    
    RequestAnimDict(talkingDict)
    while not HasAnimDictLoaded(talkingDict) do
        Wait(10)
    end
    
    TaskPlayAnim(playerPed, talkingDict, talkingAnim, 8.0, -8.0, 5000, 0, 0, false, false, false)
    
    Wait(5000)
    
    ClearPedTasks(playerPed)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName and taxiPed then
        DeleteEntity(taxiPed)
    end
end)
