AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Config.OrigMatchInfo = lib.table.deepclone(Config.MatchInfo)
        Config.OrigTeamData = lib.table.deepclone(Config.TeamData)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, v in pairs(Config.TeamData) do
            if DoesEntityExist(NetworkGetEntityFromNetworkId(v['flagNet'])) then
                DeleteEntity(NetworkGetEntityFromNetworkId(v['flagNet']))
            end
        end
        if Config.MatchInfo['powerups'] then
            for _, v in pairs(Config.MatchInfo['powerups']) do
                if DoesEntityExist(NetworkGetEntityFromNetworkId(v['propNet'])) then
                    DeleteEntity(NetworkGetEntityFromNetworkId(v['propNet']))
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function(reason)
    if Config.MatchInfo.started then
        local src = source
        for k, v in pairs(Config.TeamData) do
            if v.enemyFlagCarrier == src then
                if DoesEntityExist(NetworkGetEntityFromNetworkId(Config.TeamData[k]['flagNet'])) then
                    DeleteEntity(NetworkGetEntityFromNetworkId(Config.TeamData[k]['flagNet']))
                end
                local respawnCoords = Config.TeamData[k]['baseflagCoords']
                local ent = CreateObject(Config.TeamData[k]['prop'], respawnCoords.x, respawnCoords.y, respawnCoords.z-1.0, true, true, false)
                while not DoesEntityExist(ent) do
                    Wait(10)
                end
                Wait(100)
                SetEntityHeading(ent, respawnCoords.w)
                FreezeEntityPosition(ent, true)
                Config.TeamData[k]['currentflagCoords'] = respawnCoords
                Config.TeamData[k]['flagNet'] = NetworkGetNetworkIdFromEntity(ent)
                Config.TeamData[k]['enemyFlagCarrier'] = nil
                Config.TeamData[k]['flagStatus'] = 'returned'

                SendMatchNotification(Capitalize(k) .. ' flag has been returned due to disconnect.', k)
                local scores = {['red'] = Config.TeamData['red']['points'], ['blue'] = Config.TeamData['blue']['points']}
                TriggerClientEvent('js5m-ctf:client:flagStatus', -1, k, Config.TeamData[k]['flagStatus'], Config.TeamData[k]['currentflagCoords'], Config.TeamData[k]['flagNet'], source, scores)
                --TODO: need to remove source from teammembers
                break
            end
        end
    end
end)

local function Capitalize(str)
    return (str:gsub("^%l", string.upper))
end

local function SendMatchNotification(message, team)
    local messageStyle = Config.MatchInfo['notifyStyle'][team]
    for i = 1, #Config.MatchInfo.sources, 1 do
        TriggerClientEvent('ox_lib:notify', Config.MatchInfo.sources[i], {title = 'CTF', description = message, type = 'inform', style = messageStyle})
    end
end

function CheckRestrictedUsers(src)
    local response = false
    if not Config.Rules['restrictedCreation'] then return true end
    local identifiers = GetPlayerIdentifiers(src)
    local license = identifiers[2]
    for _, v in pairs(Config.Rules['restrictedCreators']) do
        if v == license then
            response = true
            break
        end
    end
    if not response then
        TriggerClientEvent('ox_lib:notify', src, {title = 'CTF', description = 'You are not authorized to create a match.', type = "error"})
    end
    return response
end

local function EndCTFMatch(winnerTeam, loserTeam, draw)
    Config.MatchInfo.started = false
    if not draw then
        for _, v in pairs(Config.TeamData[winnerTeam]['members']) do
            TriggerClientEvent('js5m-ctf:client:endGame', v.src, 'WINNER')
        end
        for _, v in pairs(Config.TeamData[loserTeam]['members']) do
            TriggerClientEvent('js5m-ctf:client:endGame', v.src, 'LOSER')
        end
    else
        for _, v in pairs(Config.TeamData[winnerTeam]['members']) do
            TriggerClientEvent('js5m-ctf:client:endGame', v.src, 'DRAW')
        end
        for _, v in pairs(Config.TeamData[loserTeam]['members']) do
            TriggerClientEvent('js5m-ctf:client:endGame', v.src, 'DRAW')
        end
    end
    for _, v in pairs(Config.TeamData) do
        if DoesEntityExist(NetworkGetEntityFromNetworkId(v.flagNet)) then
            DeleteEntity(NetworkGetEntityFromNetworkId(v.flagNet))
        end
    end
    for _, v in pairs(Config.MatchInfo['powerups']) do
        if DoesEntityExist(NetworkGetEntityFromNetworkId(v['propNet'])) then
            DeleteEntity(NetworkGetEntityFromNetworkId(v['propNet']))
        end
    end
    Config.MatchInfo = lib.table.deepclone(Config.OrigMatchInfo)
    Config.TeamData = lib.table.deepclone(Config.OrigTeamData)
end

local function isCTFPlayer(source)
    local response = false
    for i = 1, #Config.MatchInfo['sources'], 1 do
        if Config.MatchInfo['sources'][i] == source then
            response = true
            break
        end
    end
    return response
end

function CreatePowerupModel(powerup)
    if not Config.MatchInfo.started then return end
    if not Config.Rules['enablePowerups'] then return end
    local coords = Config.MatchInfo['powerups'][powerup]['coords']
    local ent = CreateObject(Config.MatchInfo['powerups'][powerup]['prop'], coords.x, coords.y, coords.z, true, true, false) --can we color the models?
    while not DoesEntityExist(ent) do
        Wait(10)
    end
    Wait(10)
    SetEntityHeading(ent, coords.w)
    Config.MatchInfo['powerups'][powerup]['propNet'] = NetworkGetNetworkIdFromEntity(ent)
    Config.MatchInfo['powerups'][powerup]['active'] = true
    TriggerClientEvent('js5m-ctf:client:activatePowerup', -1, Config.MatchInfo['powerups'][powerup]['active'], powerup)
end

function ActivatePowerUp(powerup)
    if not Config.MatchInfo.started then return end
    if not Config.Rules['enablePowerups'] then return end
    CreateThread(function()
        Wait((Config.Rules['powerupDelay'] * 1000) + 5000)
        CreatePowerupModel(powerup)
    end)
end

RegisterServerEvent('js5m-ctf:server:flagStatus', function(team, status, coords)
    if Config.MatchInfo.started then
        if status == 'dropped' then
            if DoesEntityExist(NetworkGetEntityFromNetworkId(Config.TeamData[team]['flagNet'])) then
                DeleteEntity(NetworkGetEntityFromNetworkId(Config.TeamData[team]['flagNet']))
            end
            local ent = CreateObject(Config.TeamData[team]['prop'], coords.x, coords.y, coords.z, true, true, false)
            while not DoesEntityExist(ent) do
                Wait(10)
            end
            Wait(100)
            SetEntityHeading(ent, coords.w)
            FreezeEntityPosition(ent, true)
            Config.TeamData[team]['currentflagCoords'] = coords
            Config.TeamData[team]['flagNet'] = NetworkGetNetworkIdFromEntity(ent)
            Config.TeamData[team]['enemyFlagCarrier'] = nil

            SendMatchNotification(Capitalize(team) .. ' flag has been dropped.', team)
        elseif status == 'returned' then
            if DoesEntityExist(NetworkGetEntityFromNetworkId(Config.TeamData[team]['flagNet'])) then
                DeleteEntity(NetworkGetEntityFromNetworkId(Config.TeamData[team]['flagNet']))
            end
            local respawnCoords = Config.TeamData[team]['baseflagCoords']
            local ent = CreateObject(Config.TeamData[team]['prop'], respawnCoords.x, respawnCoords.y, respawnCoords.z-1.0, true, true, false)
            while not DoesEntityExist(ent) do
                Wait(10)
            end
            Wait(100)
            SetEntityHeading(ent, respawnCoords.w)
            FreezeEntityPosition(ent, true)
            Config.TeamData[team]['currentflagCoords'] = GetEntityCoords(ent)
            Config.TeamData[team]['flagNet'] = NetworkGetNetworkIdFromEntity(ent)
            Config.TeamData[team]['enemyFlagCarrier'] = nil

            SendMatchNotification(Capitalize(team) .. ' flag has been returned.', team)
        elseif status == 'picked' then
            Config.TeamData[team]['enemyFlagCarrier'] = source
            SendMatchNotification(Capitalize(team) .. ' flag has been picked up.', team)
        elseif status == 'capture' then
            local enemyTeam = nil
            if team == 'blue' then 
                enemyTeam = 'red'
            elseif team == 'red' then 
                enemyTeam = 'blue'
            end

            if #(coords - Config.TeamData[team]['baseflagCoords'].xyz) < 4 then
                if DoesEntityExist(NetworkGetEntityFromNetworkId(Config.TeamData[enemyTeam]['flagNet'])) then
                    DeleteEntity(NetworkGetEntityFromNetworkId(Config.TeamData[enemyTeam]['flagNet']))
                end

                Wait(100)
                local respawnCoords = Config.TeamData[enemyTeam]['baseflagCoords']
                local ent = CreateObject(Config.TeamData[enemyTeam]['prop'], respawnCoords.x, respawnCoords.y, respawnCoords.z-1.0, true, true, false)
                while not DoesEntityExist(ent) do
                    Wait(10)
                end
                Wait(100)
                SetEntityHeading(ent, respawnCoords.w)
                FreezeEntityPosition(ent, true)
                SendMatchNotification(Capitalize(enemyTeam) .. ' flag has been captured.', enemyTeam)
                Config.TeamData[enemyTeam]['currentflagCoords'] = GetEntityCoords(ent)
                Config.TeamData[enemyTeam]['flagNet'] = NetworkGetNetworkIdFromEntity(ent)
                Config.TeamData[team]['points'] = Config.TeamData[team]['points'] + 1

                if Config.TeamData[team]['points'] == Config.Rules['maxScore'] then
                    EndCTFMatch(team, enemyTeam, false)
                end
                status = 'returned'
            end
            team = enemyTeam
        end
        Config.TeamData[team]['flagStatus'] = status
        local scores = {['red'] = Config.TeamData['red']['points'], ['blue'] = Config.TeamData['blue']['points']}
        TriggerClientEvent('js5m-ctf:client:flagStatus', -1, team, Config.TeamData[team]['flagStatus'], Config.TeamData[team]['currentflagCoords'], Config.TeamData[team]['flagNet'], source, scores)
    end
end)

lib.callback.register('js5m-ctf:server:joinTeam', function(source, team)
    for k, v in pairs(Config.TeamData) do
        for a, s in pairs(v['members']) do
            if source == s.src then
                table.remove(Config.TeamData[k]['members'], a)
                break
            end
        end
    end
    table.insert(Config.TeamData[team]['members'], {src = source, name = GetPlayerName(source)})
    return true
end)

lib.callback.register('js5m-ctf:server:removeFromTeam', function(source, team)
    if not CheckRestrictedUsers(source) then return true end
    for k, v in pairs(Config.TeamData[team]['members']) do
        if source == v.src then
            table.remove(Config.TeamData[team]['members'], k)
            break
        end
    end
    return true
end)

lib.callback.register('js5m-ctf:server:selectMap', function(source, map)
    if GetPlayerName(source) ~= Config.MatchInfo['owner'] then return end
    Config.MatchInfo['chosenMap'] = map
    local redCoords = Config.Maps[map]['red']
    local blueCoords = Config.Maps[map]['blue']
    Config.TeamData['red']['currentflagCoords'] = redCoords
    Config.TeamData['red']['baseflagCoords'] = redCoords

    Config.TeamData['blue']['currentflagCoords'] = blueCoords
    Config.TeamData['blue']['baseflagCoords'] = blueCoords
    return true
end)

lib.callback.register('js5m-ctf:server:createMatch', function(source)
    if not CheckRestrictedUsers(source) then return end
    if Config.MatchInfo.owner == nil then
        
        Config.MatchInfo.owner = GetPlayerName(source)
        TriggerClientEvent('js5m-ctf:client:matchInit', -1, true)
        return true
    elseif Config.MatchInfo.owner == GetPlayerName(source) then
        return true
    else
        return false
    end
end)

lib.callback.register('js5m-ctf:server:getMatchData', function(source)
    return {teamdata = Config.TeamData, map = Config.MatchInfo['chosenMap']}
end)

lib.callback.register('js5m-ctf:server:revivePlayer', function(source)
    if not isCTFPlayer(source) then return false end
    TriggerClientEvent('hospital:client:Revive', source, true) --qb revive event
    TriggerClientEvent('esx_ambulancejob:revive', source) --esx revive event
    return true
end)

lib.callback.register('js5m-ctf:server:adminEndMatch', function(source)
    if Config.MatchInfo.owner ~= GetPlayerName(source) then return end
    SendMatchNotification('Admin has ended the match.', 'admin')

    if Config.TeamData['red']['points'] > Config.TeamData['blue']['points'] then
        EndCTFMatch('red', 'blue', false)
    elseif Config.TeamData['blue']['points'] > Config.TeamData['red']['points'] then
        EndCTFMatch('red', 'blue', false)
    elseif Config.TeamData['blue']['points'] == Config.TeamData['red']['points'] then
        EndCTFMatch('red', 'blue', true)
    end    
end)

RegisterServerEvent('js5m-ctf:server:startCTF', function()
    local src = source
    if Config.MatchInfo.owner ~= GetPlayerName(src) then return end
    if Config.MatchInfo.started == true then return end
    if Config.MatchInfo.chosenMap == 0 then return end
    Config.MatchInfo['powerups'] = lib.table.deepclone(Config.Maps[Config.MatchInfo.chosenMap]['powerups'])
    local playerCount = 0
    local sources = {}
    for k, v in pairs(Config.TeamData) do
        local ent = CreateObject(Config.TeamData[k]['prop'], v.currentflagCoords.x, v.currentflagCoords.y, v.currentflagCoords.z-1.0, true, true, false)
        while not DoesEntityExist(ent) do
            Wait(10)
        end
        Wait(100)
        SetEntityHeading(ent, v.currentflagCoords.w)
        FreezeEntityPosition(ent, true)
        Config.TeamData[k]['flagNet'] = NetworkGetNetworkIdFromEntity(ent)
        for i = 1, #v.members, 1 do
            table.insert(sources, v.members[i]['src'])
            playerCount = playerCount + 1
        end
    end

    if playerCount > 0 then
        Config.MatchInfo.sources = sources
        TriggerClientEvent('js5m-ctf:client:startCTF', -1, Config.TeamData, Config.MatchInfo.chosenMap)
        Config.MatchInfo.started = true
        Wait(Config.Rules['powerupDelay'] * 1000)
        if Config.Rules['enablePowerups'] then
            for i = 1, #Config.MatchInfo['powerups'], 1 do
                CreatePowerupModel(i)
            end
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'CTF', description = 'Cannot start match with 0 players.', type = 'error'})
    end
end)

RegisterServerEvent('js5m-ctf:server:endCTF', function()
    if not Config.MatchInfo.started then return end
    if Config.MatchInfo.owner ~= GetPlayerName(source) then return end
    SendMatchNotification('Admin has ended the match.', 'admin')

    if Config.TeamData['red']['points'] > Config.TeamData['blue']['points'] then
        EndCTFMatch('red', 'blue', false)
    elseif Config.TeamData['blue']['points'] > Config.TeamData['red']['points'] then
        EndCTFMatch('red', 'blue', false)
    elseif Config.TeamData['blue']['points'] == Config.TeamData['red']['points'] then
        EndCTFMatch('red', 'blue', true)
    end
end)

RegisterServerEvent('js5m-ctf:server:missingFlags', function()
    print('[' .. GetCurrentResourceName() .. '] Missing ctf flag models')
end)

lib.callback.register('js5m-ctf:server:getPowerup', function(source, powerup)
    if not Config.MatchInfo.started then return end
    if not Config.Rules['enablePowerups'] then return end
    if not Config.MatchInfo['powerups'][powerup]['active'] then return false end

    if DoesEntityExist(NetworkGetEntityFromNetworkId(Config.MatchInfo['powerups'][powerup]['propNet'])) then
        DeleteEntity(NetworkGetEntityFromNetworkId(Config.MatchInfo['powerups'][powerup]['propNet']))
    end

    Config.MatchInfo['powerups'][powerup]['active'] = false
    TriggerClientEvent('js5m-ctf:client:activatePowerup', -1, Config.MatchInfo['powerups'][powerup]['active'], powerup)
    ActivatePowerUp(powerup)
    return true
end)