local DEFAULT_WEIGHT = 50000 -- 50 KG

local function ApplyPlayerWeight(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    local result = MySQL.single.await(
        'SELECT maxweight FROM players WHERE citizenid = ?',
        { citizenid }
    )

    local weight = result and result.maxweight or DEFAULT_WEIGHT

    exports.ox_inventory:SetMaxWeight(source, weight)
end

AddEventHandler('QBCore:Server:OnPlayerLoaded', function(source)
    Wait(1000)
    ApplyPlayerWeight(source)
end)

AddEventHandler('playerJoining', function()
    local src = source
    Wait(3000)
    ApplyPlayerWeight(src)
end)

RegisterCommand('setweight', function(source, args)
    local target = tonumber(args[1])
    local kg = tonumber(args[2])

    if source ~= 0 and not IsPlayerAceAllowed(source, 'command.setweight') then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Inventory',
            description = 'Kamu tidak punya izin.',
            type = 'error'
        })
        return
    end

    if not target or not kg then
        if source ~= 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Inventory',
                description = 'Gunakan: /setweight [id] [kg]',
                type = 'error'
            })
        end
        return
    end

    local Player = exports.qbx_core:GetPlayer(target)
    if not Player then
        if source ~= 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Inventory',
                description = 'Player tidak ditemukan.',
                type = 'error'
            })
        end
        return
    end

    local weight = kg * 1000
    local citizenid = Player.PlayerData.citizenid

    MySQL.update.await(
        'UPDATE players SET maxweight = ? WHERE citizenid = ?',
        { weight, citizenid }
    )

    exports.ox_inventory:SetMaxWeight(target, weight)

    TriggerClientEvent('ox_lib:notify', target, {
        title = 'Inventory',
        description = ('Max weight kamu sekarang %s KG'):format(kg),
        type = 'success'
    })

    if source ~= 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Inventory',
            description = ('Berhasil set weight ID %s menjadi %s KG'):format(target, kg),
            type = 'success'
        })
    end
end)
