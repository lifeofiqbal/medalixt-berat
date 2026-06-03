fx_version 'cerulean'
game 'gta5'

name 'medalixt_berat'
description 'custom berat untuk ox_inventory'
version '1.0.0'

dependency 'oxmysql'
dependency 'ox_lib'
dependency 'ox_inventory'

shared_scripts {
    '@ox_lib/init.lua',
}

server_scripts {
    'sv_setweight.lua',
}

client_scripts {
    'cl_setweight.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
}
