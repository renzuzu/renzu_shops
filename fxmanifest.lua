fx_version 'cerulean'
lua54 'yes'
game 'gta5'
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
	'@oxmysql/lib/MySQL.lua',
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