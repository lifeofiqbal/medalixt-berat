-- cl_setweight.lua
local isOpen = false

-- Qbox/QBCore: trigger saat player sudah fully loaded
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    Citizen.Wait(2000) -- tunggu ox_inventory selesai load inventory
    TriggerServerEvent("medalixt_berat:playerReady")
end)

-- Jaga-jaga: trigger juga saat resource restart
AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Citizen.Wait(3000)
    TriggerServerEvent("medalixt_berat:playerReady")
end)

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

-- Tutup dengan ESC
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isOpen and IsControlJustReleased(0, 200) then
            isOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = "closePanel" })
        end
    end
end)
