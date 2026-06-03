-- cl_setweight.lua
-- Dioptimasi: thread ESC hanya aktif saat panel terbuka

local isOpen = false

-- ─────────────────────────────────────────────
-- Load custom weight saat player ready
-- ─────────────────────────────────────────────
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    Citizen.Wait(2000)
    TriggerServerEvent("medalixt_berat:playerReady")
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Citizen.Wait(3000)
    TriggerServerEvent("medalixt_berat:playerReady")
end)

-- ─────────────────────────────────────────────
-- ESC handler: thread hanya spawn saat panel buka,
-- otomatis mati saat panel tutup → 0 overhead saat idle
-- ─────────────────────────────────────────────
local function startEscListener()
    Citizen.CreateThread(function()
        while isOpen do
            Citizen.Wait(100) -- cek 10x/detik, cukup responsif & hemat CPU
            if IsControlJustReleased(0, 200) then
                isOpen = false
                SetNuiFocus(false, false)
                SendNUIMessage({ action = "closePanel" })
            end
        end
    end)
end

-- ─────────────────────────────────────────────
-- Panel admin
-- ─────────────────────────────────────────────
RegisterCommand("swpanel", function()
    TriggerServerEvent("medalixt_berat:openPanel")
end, false)

RegisterNetEvent("medalixt_berat:receivePlayerList", function(players)
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openPanel", players = players })
    startEscListener() -- spawn thread hanya saat ini
end)

RegisterNetEvent("medalixt_berat:callback", function(success, nameOrErr, weight)
    if success then
        SendNUIMessage({ action = "setSuccess", targetName = nameOrErr, weight = weight })
    else
        SendNUIMessage({ action = "setError", message = nameOrErr or "Terjadi kesalahan!" })
    end
end)

RegisterNUICallback("setWeight", function(data, cb)
    TriggerServerEvent("medalixt_berat:setFromPanel", data.targetId, data.weight)
    cb("ok")
end)

RegisterNUICallback("closePanel", function(data, cb)
    isOpen = false
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("refreshPlayers", function(data, cb)
    TriggerServerEvent("medalixt_berat:openPanel")
    cb("ok")
end)
