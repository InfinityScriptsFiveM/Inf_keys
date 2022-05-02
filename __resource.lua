resource_manifest_version "44febabe-d386-4d18-afbe-5e627f4af937"

client_scripts {
    '@menuv/menuv.lua',
    "locales/language.lua",
    "config.lua",
    "client/main.lua",
}

server_scripts {
    "@mysql-async/lib/MySQL.lua",
    "locales/language.lua",
    "config.lua",
    "server/main.lua",
    'versioncheck.lua',
}