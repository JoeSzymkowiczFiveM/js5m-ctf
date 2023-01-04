QBCore = nil
ESX = nil
invalid = false

if Config.Core == "QBCore" then
    TriggerEvent(Config.Core..':GetObject', function(obj) QBCore = obj end)
    if QBCore == nil then
        QBCore = exports[Config.CoreFolderName]:GetCoreObject()
    end
elseif Config.Core == "ESX" then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    if ESX == nil then
        ESX = exports[Config.CoreFolderName]:getSharedObject()
    end
else
    print("^1[Invalid Core] ^0You have You have not selected the right Config.Core in framework.lua ^0!")
    invalid = true
end

function RemoveWagerFee(src, amount)
    if Config.Framework == 'QBCore' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player.Functions.RemoveMoney('cash', amount, "ctf-wager-amount") then
            return true
        end
    end
    return false
end