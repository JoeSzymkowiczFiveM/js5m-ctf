local carryingFlag = false

local myTeam = nil
local enemyTeam = nil

local matchOwner = false
local matchMap = 0
local matchInit = false
local matchStarted = false

local isDead = false

local matchZone = nil

-- local particleColors = {
--     ['red'] = {r = 255.0, g = 0, b = 0},
--     ['blue'] = {r = 0.0, g = 0, b = 255.0},
-- }

CreateThread(function()
    local missing = true
    for _, v in pairs(Config.TeamData) do
        local model = v['prop']
        if IsModelValid(v['prop']) then
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(10)
            end
            missing = false
        end
    end
    if missing then
        TriggerServerEvent('js5m-ctf:server:missingFlags')
    end
end)

-- AddEventHandler('onResourceStart', function(resourceName)
--     if GetCurrentResourceName() == resourceName then
--     end
-- end)

-- AddEventHandler('onResourceStop', function(resourceName)
--     if GetCurrentResourceName() == resourceName then
--     end
-- end)


-- local function CarryingFlag(src, team) --still buggy, disabling for the moment
--     CreateThread(function()
--         RequestNamedPtfxAsset("scr_bike_adversary")
--         -- Wait for the particle dictionary to load.
--         while not HasNamedPtfxAssetLoaded("scr_bike_adversary") do
--             Citizen.Wait(1)
--         end

--         UseParticleFxAssetNextCall("scr_bike_adversary")

--         local rgb = particleColors[team]

--         --local lastCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(src)))
--         local ptfx
--         local particleRunning = false
--         while Config.TeamData[team]['flagStatus'] == 'picked' do
--             local targetPed = GetPlayerPed(GetPlayerFromServerId(src))
--             local ped = PlayerPedId()
--             if #(GetEntityCoords(targetPed) - GetEntityCoords(ped)) <= 50 and not particleRunning then
--                 particleRunning = true
--                 ptfx = StartParticleFxLoopedOnEntity('scr_adversary_trail_lightning', targetPed, 0.0, -1.0, 1.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
--                 --SetParticleFxLoopedEvolution(ptfx, "speed", 1.0, false)               -- SetParticleFxLoopedEvolution(ptfx, "speed", 1.0, false)
--                 SetParticleFxLoopedColour(ptfx, rgb.r, rgb.g, rgb.b)
--                 SetParticleFxLoopedAlpha(ptfx, 1.0)
--             elseif #(GetEntityCoords(targetPed) - GetEntityCoords(ped)) > 50 and particleRunning then
--                 particleRunning = false
--                 --StopParticleFxLooped(ptfx, 0)
--                 --RemoveParticleFxFromEntity(targetPed)
--                 StopParticleFxLooped(ptfx)
--                 --ptfx = nil
--             end
--             Wait(1000)
--         end
--         particleRunning = false
--         --StopParticleFxLooped(ptfx, 0)
--         --RemoveParticleFxFromEntity(targetPed)
--         StopParticleFxLooped(ptfx)
--         --ptfx = nil
--     end)
-- end

local function GetDroppedFlagPos(team, coords)
    local object = CreateObject(Config.TeamData[team]['prop'], coords.x, coords.y, coords.z+2.0, false)
    while not DoesEntityExist(object) do Wait(0) end
    SetEntityAlpha(object, 0)
    PlaceObjectOnGroundProperly(object)
    Wait(15)
    local newCoords = GetEntityCoords(object)
    local newHeading = GetEntityHeading(object)
    Wait(15)
    DeleteObject(object)
    local newPosition = vector4(newCoords.x, newCoords.y, newCoords.z, newHeading)
    return newPosition
end

local function DetachFlag()
    carryingFlag = false
    Config.TeamData[enemyTeam]['flagStatus'] = 'dropped'
    local coords = GetEntityCoords(PlayerPedId())
    local newCoords = GetDroppedFlagPos(enemyTeam, coords)
    TriggerServerEvent('js5m-ctf:server:flagStatus', enemyTeam, 'dropped', newCoords)
end

local function GetRandomBaseSpawn(team)
    local randX = math.random(-3, 3)
    local randY = math.random(-3, 3)
    local coords = vector4(Config.TeamData[team]['baseflagCoords'].x+randX, Config.TeamData[team]['baseflagCoords'].y+randY, Config.TeamData[team]['baseflagCoords'].z-.5, Config.TeamData[team]['baseflagCoords'].w)
    return coords
end

local function RespawnAtBase()
    lib.callback('js5m-ctf:server:revivePlayer', false, function(response)
        if response then
            local randomBaseSpawn = GetRandomBaseSpawn(myTeam)
            SetEntityCoords(cache.ped, randomBaseSpawn.xyz)
            SetEntityHeading(cache.ped, randomBaseSpawn.w)
            isDead = false
        end
    end)
end

local function GetDeaded()
    if not isDead then
        isDead = true
        if carryingFlag then
            DetachFlag()
        end
        if Config.Rules['autoRespawn'] then
            Wait(Config.Rules['respawnTime']*1000)
            RespawnAtBase()
        end
    end
end

local function ReturnFlag()
    TriggerServerEvent('js5m-ctf:server:flagStatus', myTeam, 'returned', nil)
end

local function SetEnemyTeam()
    if myTeam == 'red' then 
        enemyTeam = 'blue'
    elseif myTeam == 'blue' then
        enemyTeam = 'red'
    end
end

local function AttachFlag(net)
    carryingFlag = true
    Config.TeamData[enemyTeam]['flagStatus'] = 'picked'
    local flag = NetworkGetEntityFromNetworkId(net)
    NetworkRequestControlOfEntity(flag)
    while not NetworkHasControlOfEntity(flag) do
        NetworkRequestControlOfEntity(flag)
        Wait(10)
    end
    FreezeEntityPosition(flag, false)
    local bone = GetPedBoneIndex(cache.ped, 24818)
    AttachEntityToEntity(flag, cache.ped, bone, 0.0, -0.17, 0.0, 0.0, 90.0, 270.0, 0, 1, 0, 1, 1, 1)
    SetEntityCompletelyDisableCollision(flag, false, true)
    TriggerServerEvent('js5m-ctf:server:flagStatus', enemyTeam, 'picked', GetEntityCoords(flag))
end

local function CaptureFlag(net)
    local flag = NetworkGetEntityFromNetworkId(net)
    carryingFlag = false
    TriggerServerEvent('js5m-ctf:server:flagStatus', myTeam, 'capture', GetEntityCoords(flag))
end

local function UpdateScoreboard(action)
    if not myTeam then return end
    local data = {}
    data.allData = {}
    local myTeamData = {
        color = Config.MatchInfo['notifyStyle'][myTeam]['backgroundColor'],
        text = Config.TeamData[myTeam]['points'],
    }

    local enemyTeamData = {
        color = Config.MatchInfo['notifyStyle'][enemyTeam]['backgroundColor'],
        text = Config.TeamData[enemyTeam]['points'],
    }

    data.allData[#data.allData+1] = myTeamData
    data.allData[#data.allData+1] = enemyTeamData

    SendNUIMessage({
        action = action,
        data = data
    })
end

local function StartMatch()
    CreateThread(function()
        while matchStarted do
            local sleep = 1000
            local coords = GetEntityCoords(cache.ped)
            if myTeam then
                if not IsPedDeadOrDying(cache.ped) then
                    if Config.TeamData[enemyTeam]['flagStatus'] ~= 'picked' then
                        if #(coords - Config.TeamData[enemyTeam]['currentflagCoords'].xyz) < 10 then
                            sleep = 10
                            if #(coords - Config.TeamData[enemyTeam]['currentflagCoords'].xyz) < 1.5 then
                                --TaskPlayAnim(ped, "pickup_object" ,"putdown_low" ,8.0, -8.0, -1, 1, 0, false, false, false )
                                AttachFlag(Config.TeamData[enemyTeam]['flagNet'])
                                Wait(2000)
                            end
                        end
                    end
                    if Config.TeamData[myTeam]['flagStatus'] == 'dropped' then
                        if #(coords - Config.TeamData[myTeam]['currentflagCoords'].xyz) < 10 then
                            sleep = 10
                            if #(coords - Config.TeamData[myTeam]['currentflagCoords'].xyz) < 1.5 then
                                ReturnFlag()
                                Wait(2000)
                            end
                        end
                    end
                    if Config.TeamData[myTeam]['flagStatus'] == 'returned' and carryingFlag then
                        if #(coords - Config.TeamData[myTeam]['currentflagCoords'].xyz) < 10 then
                            sleep = 10
                            if #(coords - Config.TeamData[myTeam]['currentflagCoords'].xyz) < 1.5 then
                                CaptureFlag(Config.TeamData[enemyTeam]['flagNet'])
                                Wait(2000)
                            end
                        end
                    end
                else
                    GetDeaded()
                end
            end
            Wait(sleep)
        end
    end)
end

RegisterNetEvent('js5m-ctf:client:flagStatus', function(team, status, coords, net, src, scores)
    Config.TeamData[team]['flagStatus'] = status
    Config.TeamData[team]['currentflagCoords'] = coords
    Config.TeamData[team]['flagNet'] = net
    -- if status == 'picked' then
    --     CarryingFlag(src, team)
    -- end
    for k, v in pairs(scores) do
        Config.TeamData[k]['points'] = v
    end
    UpdateScoreboard('update')
end)

RegisterNetEvent('js5m-ctf:client:setBlip', function(team, incCoords)
    if Config.TeamData[team]['flagBlip'] then
        RemoveBlip(Config.TeamData[team]['flagBlip'])
        Config.TeamData[team]['flagBlip'] = nil
    end
    Config.TeamData[team]['flagBlip'] = AddBlipForRadius(incCoords.xyz, 150.0)
    SetBlipColour(Config.TeamData[team]['flagBlip'], 80)
end)

RegisterCommand("dropflag", function()
    DetachFlag()
end)

-- local function onEnter(self)
--     print('entered zone', self.id)
-- end

local function onExit(self)
    if matchStarted and carryingFlag then
        TriggerServerEvent('js5m-ctf:server:flagStatus', enemyTeam, 'returned', nil)
        carryingFlag = false
    end
end

RegisterNetEvent('js5m-ctf:client:startCTF', function(config)
    Config.OrigMatchInfo = lib.table.deepclone(Config.MatchInfo)
    Config.OrigTeamData = lib.table.deepclone(Config.TeamData)
    Config.TeamData = config
    local randomBaseSpawn = GetRandomBaseSpawn(myTeam)
    SetEntityHeading(cache.ped, randomBaseSpawn.w)
    SetEntityCoords(cache.ped, randomBaseSpawn.x, randomBaseSpawn.y, randomBaseSpawn.z-1.0)
    Wait(1000)
    for k, v in pairs(Config.TeamData) do
        Config.TeamData[k]['flagBlip'] = AddBlipForRadius(v.currentflagCoords.xyz, 40.0)
        SetBlipColour(v.flagBlip, v.blipColor)

        Config.TeamData[k]['flagObj'] = NetToObj(v.flagNet)
    end

    local chosenZone = Config.Maps[matchMap].zone
    if chosenZone.style == 'box' then
        matchZone = lib.zones.box({
            coords = chosenZone.coords,
            size = chosenZone.size,
            rotation = chosenZone.rotation,
            debug = Config.Rules.showZoneBorder,
            onExit = onExit
        })
    end

    matchStarted = true
    FreezeEntityPosition(cache.ped, true)
    lib.showTextUI('CTF Starting in...')
    Wait(1000)
    lib.hideTextUI()
    lib.showTextUI('3...')
    Wait(1000)
    lib.hideTextUI()
    lib.showTextUI('2...')
    Wait(1000)
    lib.hideTextUI()
    lib.showTextUI('1...')
    Wait(1000)
    lib.hideTextUI()
    lib.showTextUI('GO', { style = { backgroundColor = '#138A36', } })
    Wait(1000)
    lib.hideTextUI()
    FreezeEntityPosition(cache.ped, false)
    UpdateScoreboard('open')
    StartMatch()
end)

RegisterCommand("initctf", function()
    local response = lib.callback.await('js5m-ctf:server:createMatch', false)
    if response then
        matchOwner = true
    else
        matchOwner = false
    end
end)

RegisterNetEvent("js5m-ctf:client:matchInit",function(init)
    matchInit = init
    if not init then return end
    lib.notify({ title = 'CTF', description = 'A CTF match has been created.', type = 'success' })
end)

RegisterCommand("ctfmenu", function()
    if not matchInit then return end
    lib.callback('js5m-ctf:server:getMatchData', false, function(data)
        CTFMenu(data.teamdata, data.map)
    end)
end)

RegisterNetEvent('js5m-ctf:client:joinTeam', function(args)
    local team = args.team
    if myTeam then return end
    lib.callback('js5m-ctf:server:joinTeam', false, function(response)
        if response then
            myTeam = team
            SetEnemyTeam()
        end
    end, team)
    return true
end)

RegisterNetEvent('js5m-ctf:client:selectMap', function(args)
    local map = args.map
    if not matchOwner then return end
    lib.callback('js5m-ctf:server:selectMap', false, function(response) -- fix this
    end, map)
    return true
end)

function CTFMenu(matchData, map)
    matchMap = map
    local registeredMenu = {
        id = 'js5m-ctf_menu',
        title = 'CTF Match Menu',
        options = {}
    }
    local options = {}
    local mapOptions = {}
    
    if matchMap == 0 then
        mapMessage = "No map chosen yet."
    else
        mapMessage = "Match will be played on " .. Config.Maps[matchMap]['name'] .. "."
    end

    options[#options+1] = {
        title = 'Current Map',
        description = mapMessage,
        icon = 'fa-solid fa-map',
    }

    if matchMap ~= 0 then
        local redTeam = {}
        if #matchData['red']['members'] > 0 then
            for r = 1, #matchData['red']['members'], 1 do
                redTeam[#redTeam+1] = {label = r, value = matchData['red']['members'][r]['name']}
            end
        else
            redTeam[#redTeam+1] = {label = '1', value = 'No players on Red Team yet'}
        end

        options[#options+1] = {
            title = 'Red Team',
            description = "Join the Red Team",
            metadata = redTeam,
            event = 'js5m-ctf:client:joinTeam',
            args = {team = 'red'},
            icon = 'fa-solid fa-user-plus',
            iconColor = Config.MatchInfo['notifyStyle']['red']['backgroundColor'],
        }

        local blueTeam = {}
        if #matchData['blue']['members'] > 0 then
            for b = 1, #matchData['blue']['members'], 1 do
                blueTeam[#blueTeam+1] = {label = b, value = matchData['blue']['members'][b]['name']}
            end
        else
            blueTeam[#blueTeam+1] = {label = '1', value = 'No players on Blue Team yet'}
        end

        options[#options+1] = {
            title = 'Blue Team',
            description = "Join the Blue Team",
            metadata = blueTeam,
            event = 'js5m-ctf:client:joinTeam',
            args = {team = 'blue'},
            icon = 'fa-solid fa-user-plus',
            iconColor = Config.MatchInfo['notifyStyle']['blue']['backgroundColor'],
        }
    end

    if matchOwner then
        if matchStarted then
            options[#options+1] = {
                title = 'End Match',
                description = "End the CTF match immediately",
                serverEvent = 'js5m-ctf:server:endCTF',
                icon = 'fa-solid fa-stop'
            }
        elseif not matchStarted and matchMap ~= 0 then
            options[#options+1] = {
                title = 'Start Match',
                description = "Start the CTF match",
                serverEvent = 'js5m-ctf:server:startCTF',
                icon = 'fa-solid fa-play'
            }
        end

        options[#options+1] = {
            title = 'Map Selection',
            menu = 'js5m-ctf_map_menu',
            description = 'Select the map to play on',
        }
    
        
        for k, v in pairs(Config.Maps) do
            mapOptions[#mapOptions+1] = {
                title = v['name'],
                description = 'Select this map',
                event = 'js5m-ctf:client:selectMap',
                args = {map = k},
            }
        end
        
    end
    registeredMenu[#registeredMenu+1] = {
        id = 'js5m-ctf_map_menu',
        title = 'Map Selection',
        menu = 'js5m-ctf_menu',
        options = mapOptions
    }

    registeredMenu["options"] = options
    
    lib.registerContext(registeredMenu)
    lib.showContext('js5m-ctf_menu')
end

if not Config.Rules['allowVehicles'] then
    AddEventHandler('ox_lib:cache:vehicle', function(value)
        if matchStarted then
            CreateThread(function()
                while cache.vehicle do
                    Wait(100)
                    if IsPedInAnyVehicle(cache.ped, false) and not IsEntityDead(cache.ped) then
                        Wait(150)
                        if IsPedInAnyVehicle(cache.ped, false) then
                            TaskLeaveVehicle(cache.ped, value, 0)
                        end
                    end
                end
            end)
        end
    end)
end

RegisterNetEvent("js5m-ctf:client:endGame",function(message)
    matchStarted = false
	Citizen.CreateThread(function()
		local scaleform = RequestScaleformMovie("mp_big_message_freemode")
		while not HasScaleformMovieLoaded(scaleform) do Citizen.Wait(0) end
		BeginScaleformMovieMethod(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
		PushScaleformMovieMethodParameterString("~w~"..message)
		EndScaleformMovieMethod()
		PlaySoundFrontend(-1, "LOSER", "HUD_AWARDS")
		local drawing = true
		Citizen.SetTimeout((7.5 * 1000),function() drawing = false end)
		while drawing do
			Citizen.Wait(0)
			DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
		end
		SetScaleformMovieAsNoLongerNeeded(scaleform)
	end)
    UpdateScoreboard('forceClose')
    for _, v in pairs(Config.TeamData) do
        RemoveBlip(v['flagBlip'])
    end
    carryingFlag = false
    myTeam = nil
    enemyTeam = nil

    matchOwner = false
    matchMap = 0
    matchInit = false
    matchZone:remove()
    Config.MatchInfo = lib.table.deepclone(Config.OrigMatchInfo)
    Config.TeamData = lib.table.deepclone(Config.OrigTeamData)
end)