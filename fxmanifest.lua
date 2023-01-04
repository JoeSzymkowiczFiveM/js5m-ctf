fx_version 'cerulean'
game 'gta5'

lua54 'yes'

ui_page 'web/build/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
	'server/main.lua',
    'server/functions.lua'
}

files {
    'web/build/index.html',
    'web/build/**/*'
}