-- sv_setweight.lua
local customWeights = {}

-- ─────────────────────────────────────────────
-- Buat tabel jika belum ada
-- ─────────────────────────────────────────────
AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    exports.oxmysql:query([[
        CREATE TABLE IF NOT EXISTS `player_custom_weight` (
            `identifier` VARCHAR(60) NOT NULL,
            `max_weight` INT NOT NULL DEFAULT 30000,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function()
        print("[medalixt_berat] Tabel player_custom_weight siap.")
    end)
end)

-- ─────────────────────────────────────────────
-- Helper: identifier
-- ─────────────────────────────────────────────
local function getIdentifier(playerId)
    return GetPlayerIdentifierByType(playerId, "license2")
        or GetPlayerIdentifierByType(playerId, "license")
        or GetPlayerIdentifierByType(playerId, "steam")
end

-- ─────────────────────────────────────────────
-- Helper: cek admin
-- ─────────────────────────────────────────────
local function isAdmin(source)
    if IsPlayerAceAllowed(source, "command.setweight") then
        return true
    end
    -- Qbox: local Player = exports.qbx_core:GetPlayer(source)
    -- if Player and (Player.PlayerData.group == 'admin' or Player.PlayerData.group == 'superadmin') then return true end
    return false
end

-- ─────────────────────────────────────────────
-- Helper: simpan ke DB
-- ─────────────────────────────────────────────
local function saveWeight(playerId, weightGram)
    local identifier = getIdentifier(playerId)
    if not identifier then
        print("[medalixt_berat] ERROR: identifier nil untuk player " .. tostring(playerId))
        return
    end
    exports.oxmysql:query(
        "INSERT INTO player_custom_weight (identifier, max_weight) VALUES (?, ?) ON DUPLICATE KEY UPDATE max_weight = ?",
        { identifier, weightGram, weightGram },
        function()
            print(("[medalixt_berat] Tersimpan: %s = %d gram"):format(identifier, weightGram))
        end
    )
end

-- ─────────────────────────────────────────────
-- Helper: load dari DB
-- ─────────────────────────────────────────────
local function loadWeight(playerId, callback)
    local identifier = getIdentifier(playerId)
    if not identifier then
        print("[medalixt_berat] ERROR: identifier nil saat load untuk player " .. tostring(playerId))
        callback(nil)
        return
    end
    exports.oxmysql:scalar(
        "SELECT max_weight FROM player_custom_weight WHERE identifier = ?",
        { identifier },
        function(result)
            callback(result)
        end
    )
end

-- ─────────────────────────────────────────────
-- Helper: hapus dari DB
-- ─────────────────────────────────────────────
local function deleteWeight(playerId)
    local identifier = getIdentifier(playerId)
    if not identifier then return end
    exports.oxmysql:query(
        "DELETE FROM player_custom_weight WHERE identifier = ?",
        { identifier },
        function()
            print(("[medalixt_berat] Dihapus dari DB: %s"):format(identifier))
        end
    )
end

-- ─────────────────────────────────────────────
-- Helper: terapkan ke ox_inventory
-- ─────────────────────────────────────────────
local function applyWeight(playerId, weightGram)
    exports.ox_inventory:SetMaxWeight(playerId, weightGram)
    customWeights[playerId] = weightGram
end

-- ─────────────────────────────────────────────
-- Load weight saat player ready (dipanggil dari client)
-- ─────────────────────────────────────────────
RegisterNetEvent("medalixt_berat:playerReady", function()
    local src = source
    local name = GetPlayerName(src)

    loadWeight(src, function(result)
        if result then
            Citizen.Wait(1500)
            if GetPlayerName(src) then
                applyWeight(src, result)
                print(("[medalixt_berat] Loaded: %s (ID:%d) = %d gram"):format(name, src, result))
            end
        else
            print(("[medalixt_berat] Tidak ada custom weight untuk: %s"):format(tostring(name)))
        end
    end)
end)

-- ─────────────────────────────────────────────
-- Command: /setweight [id] [kg]
-- ─────────────────────────────────────────────
RegisterCommand("setweight", function(source, args, rawCommand)
    if not isAdmin(source) then
        TriggerClientEvent("ox_lib:notify", source, { title = "Akses Ditolak", description = "Tidak punya izin.", type = "error" })
        return
    end

    local targetId = tonumber(args[1])
    local newWeightKg = tonumber(args[2])

    if not targetId or not newWeightKg then
        TriggerClientEvent("ox_lib:notify", source, { title = "Salah", description = "Gunakan: /setweight [id] [kg]", type = "warning" })
        return
    end

    if not GetPlayerName(targetId) then
        TriggerClientEvent("ox_lib:notify", source, { title = "Error", description = "Player tidak ditemukan.", type = "error" })
        return
    end

    local weightGram = newWeightKg * 1000
    applyWeight(targetId, weightGram)
    saveWeight(targetId, weightGram)

    TriggerClientEvent("ox_lib:notify", source, {
        title = "Berhasil",
        description = ("Berat %s → %d kg (tersimpan)"):format(GetPlayerName(targetId), newWeightKg),
        type = "success"
    })
    TriggerClientEvent("ox_lib:notify", targetId, {
        title = "Kapasitas Diubah",
        description = ("Kapasitas tas kamu: %d kg"):format(newWeightKg),
        type = "inform"
    })
end, false)

-- ─────────────────────────────────────────────
-- Command: /resetweight [id]
-- ─────────────────────────────────────────────
RegisterCommand("resetweight", function(source, args, rawCommand)
    if not isAdmin(source) then return end

    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent("ox_lib:notify", source, { title = "Error", description = "Player tidak ditemukan.", type = "error" })
        return
    end

    local defaultWeight = GlobalState.PlayerWeight or 30000
    applyWeight(targetId, defaultWeight)
    deleteWeight(targetId)
    customWeights[targetId] = nil

    TriggerClientEvent("ox_lib:notify", source, {
        title = "Direset",
        description = ("Berat %s direset ke default (%d kg)"):format(GetPlayerName(targetId), math.floor(defaultWeight/1000)),
        type = "success"
    })
    TriggerClientEvent("ox_lib:notify", targetId, {
        title = "Kapasitas Direset",
        description = ("Kapasitas tas kamu kembali ke default: %d kg"):format(math.floor(defaultWeight/1000)),
        type = "inform"
    })
end, false)

-- ─────────────────────────────────────────────
-- Command: /checkweight [id]
-- ─────────────────────────────────────────────
RegisterCommand("checkweight", function(source, args, rawCommand)
    if not isAdmin(source) then return end

    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then return end

    local inventory = exports.ox_inventory:GetInventory(targetId)
    if inventory then
        TriggerClientEvent("ox_lib:notify", source, {
            title = ("Berat: %s"):format(GetPlayerName(targetId)),
            description = ("%d / %d kg%s"):format(
                math.floor(inventory.weight / 1000),
                math.floor(inventory.maxWeight / 1000),
                customWeights[targetId] and " [Custom]" or " [Default]"
            ),
            type = "inform"
        })
    end
end, false)

-- ─────────────────────────────────────────────
-- Event: Buka panel NUI
-- ─────────────────────────────────────────────
RegisterNetEvent("medalixt_berat:openPanel", function()
    local src = source
    if not isAdmin(src) then return end

    local playerList = {}
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        local inventory = exports.ox_inventory:GetInventory(pid)
        table.insert(playerList, {
            id = pid,
            name = GetPlayerName(pid),
            currentWeight = inventory and math.floor(inventory.weight / 1000) or 0,
            maxWeight = inventory and math.floor(inventory.maxWeight / 1000) or 0,
            isCustom = customWeights[pid] ~= nil
        })
    end

    TriggerClientEvent("medalixt_berat:receivePlayerList", src, playerList)
end)

-- ─────────────────────────────────────────────
-- Event: Set weight dari panel NUI
-- ─────────────────────────────────────────────
RegisterNetEvent("medalixt_berat:setFromPanel", function(targetId, newWeightKg)
    local src = source
    if not isAdmin(src) then return end

    targetId = tonumber(targetId)
    newWeightKg = tonumber(newWeightKg)

    if not targetId or not newWeightKg or newWeightKg <= 0 then
        TriggerClientEvent("medalixt_berat:callback", src, false, "Input tidak valid!")
        return
    end

    if not GetPlayerName(targetId) then
        TriggerClientEvent("medalixt_berat:callback", src, false, "Player tidak ditemukan!")
        return
    end

    local weightGram = newWeightKg * 1000
    applyWeight(targetId, weightGram)
    saveWeight(targetId, weightGram)

    local targetName = GetPlayerName(targetId)
    TriggerClientEvent("medalixt_berat:callback", src, true, targetName, newWeightKg)
    TriggerClientEvent("ox_lib:notify", targetId, {
        title = "Kapasitas Diubah",
        description = ("Kapasitas tas kamu: %d kg"):format(newWeightKg),
        type = "inform"
    })
end)

-- ─────────────────────────────────────────────
-- Bersihkan cache saat disconnect
-- ─────────────────────────────────────────────
AddEventHandler("playerDropped", function()
    customWeights[source] = nil
end)
