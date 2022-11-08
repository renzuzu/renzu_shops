fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'
shared_script '@renzu_shield/init.lua'
shared_scripts {
	'@ox_lib/init.lua',
	'data/*.lua',
	'init.lua',
}
ui_page {
    'web/index.html',
}

client_scripts {
	'client/main.lua'
}

server_scripts {
	'server/*.lua'
}

files {
	'web/index.html',
	'web/script.js',
	'web/style.css',
	'web/levelup.gif',
    'web/audio/*.ogg',
	'config/ownedshops/*.lua',
	'config/*.lua',
}