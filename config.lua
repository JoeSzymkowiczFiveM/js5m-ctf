Config = {}

Config.Maps = {
    {
        name = 'Paleto Carnage',
        red = vector4(118.48, 6580.36, 31.73, 142.1),
        blue = vector4(-426.43, 6029.43, 31.49, 316.55),
        zone = {
            style = 'box',
            coords = vec3(-204.74, 6322.84, 41.45),
            size = vec3(250, 900, 40),
            rotation = 315.75,
        }
    },
    {
        name = 'Redwood Rampage',
        red = vector4(1159.52, 2252.03, 50.01, 45.16),
        blue = vector4(895.33, 2469.98, 50.92, 244.78),
        zone = {
            style = 'box',
            coords = vec3(1028.42, 2375.92, 49.16),
            size = vec3(310, 320, 40),
            rotation = 0,
        }
    },
}

Config.Rules = {
    ['allowVehicles'] = false, --prevents players from entering vehicles if false
    ['maxScore'] = 3, --sets the score limit to win the match
    ['autoRespawn'] = true, --automatically respawn at base on death
    ['respawnTime'] = 5, --in seconds. delay before respawn, when you die, if autoRespawn
    ['restrictedCreation'] = true, --if true, restricts match creation to a list of user licenses.
    ['restrictedCreators'] = { --this is the lise of licenses that can create matches if restrictedCreation is true
        'license:b73e3e039dc918c533efd909722eb1da07231c2a',
        'license:asdfopiu1234567890asdfasdf12345678900000',
    },
    ['showZoneBorder'] = false, --this turns zones debug setting on. I could see why you want this on, but I personally things its stupid. 
}

Config.MatchInfo = {
    owner = nil,
    started = false,
    sources = {},
    notifyStyle = {
        ['red'] = {
            backgroundColor = '#d62828',
            color = '#ffffff'
        },
        ['blue'] = {
            backgroundColor = '#0077b6',
            color = '#ffffff'
        },
        ['admin'] = {
            backgroundColor = '#42464D',
            color = '#ffffff'
        },
    },
    chosenMap = 0
}

Config.TeamData = {
    ['red'] = {
        members = {},
        flagStatus = 'returned',
        flagNet = nil,
        flagObj = nil,
        flagBlip = nil,
        currentflagCoords = nil,
        baseflagCoords = nil,
        blipColor = 79,
        points = 0,
        enemyFlagCarrier = nil,
        prop = `ctfredflag`
    }, 
    ['blue'] = {
        members = {},
        flagStatus = 'returned',
        flagNet = nil,
        flagObj = nil,
        flagBlip = nil,
        currentflagCoords = nil,
        baseflagCoords = nil,
        blipColor = 80,
        points = 0,
        enemyFlagCarrier = nil,
        prop = `ctfblueflag`
    }
}