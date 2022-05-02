Config = {}

Config.PlateSpace = true -- enable / disable plate spaces (compatibility with esx 1.1?)
Config.Mysql = 'mysql-async' -- "ghmattisql", "mysql-async"
Config.RegisterKeyPrice 	= 300	
Config.KeyPayBankMoney		= true	-- set to false to pay with cash instead of bank moeny

-- generel menu settings
Config.NativeUI 			= true
Config.MenuColorR			= 65 -- Red channel
Config.MenuColorG			= 105 -- Green channel
Config.MenuColorB			= 225 -- Blue channel
Config.Position				= 'topleft'	-- topleft | topcenter | topright | centerleft | center | centerright | bottomleft | bottomcenter | bottomright


-- Locksmith Shop:
Config.Locksmith = {{
	Pos = {170.18,-1799.42,29.32},
	Key = 38,
	Marker = {
		Enable = true,
		DrawDist = 10.0,
		Type = 27,
		Scale = {x = 1.0, y = 1.0, z = 1.0},
		Color = {r = 240, g = 52, b = 52, a = 100},
	},
	Blip = {
		Enable 	= true,
		Pos 	= {170.18,-1799.42,29.32},
		Sprite 	= 134,
		Color 	= 1,
		Name 	= "Schlüsseldienst",
		Scale 	= 1.0,
		Display = 4,
	}
}}

-- Add Police/EMS Vehicles or other whitelisted vehicles and set job permissions
Config.WhitelistCars = {
    [1] = {model = GetHashKey('vchmp'), job = {"police", "ambulance"}},
	-- ambulance
    [2] = {model = GetHashKey('ambulance'), job = {"ambulance"}},
	[18] = {model = GetHashKey('dodgeEMS'), job = {"ambulance"}},
	[19] = {model = GetHashKey('engine'), job = {"ambulance"}},
	[20] = {model = GetHashKey('enladder'), job = {"ambulance"}},
	[21] = {model = GetHashKey('firehazmat2'), job = {"ambulance"}},
	[22] = {model = GetHashKey('hvywrecker'), job = {"ambulance", "mechanic"}},
	-- mechaniker
	[23] = {model = GetHashKey('17silv'), job = {"mechanic"}},
	[24] = {model = GetHashKey('road1'), job = {"mechanic"}},
	[25] = {model = GetHashKey('road2'), job = {"mechanic"}},
	[26] = {model = GetHashKey('tow'), job = {"mechanic"}},
	-- police
    [3] = {model = GetHashKey('vapup'), job = {"police"}},
	[4] = {model = GetHashKey('police'), job = {"police"}},
	[6] = {model = GetHashKey('police2'), job = {"police"}},
	[7] = {model = GetHashKey('police3'), job = {"police"}},
	[8] = {model = GetHashKey('police4'), job = {"police"}},
	[9] = {model = GetHashKey('pdcharger'), job = {"police"}},
	[10] = {model = GetHashKey('pdcvpi'), job = {"police"}},
	[11] = {model = GetHashKey('pdfpiu'), job = {"police"}},
	[12] = {model = GetHashKey('umtahoe'), job = {"police"}},
	[13] = {model = GetHashKey('pdimpala'), job = {"police"}},
	[14] = {model = GetHashKey('polgs350'), job = {"police"}},
	[15] = {model = GetHashKey('bmwm5'), job = {"police"}},
	[16] = {model = GetHashKey('waterandpower'), job = {"gitrdone"}},
	[17] = {model = GetHashKey('tahoe'), job = {"police"}},
	[27] = {model = GetHashKey('demon'), job = {"police"}},
	[28] = {model = GetHashKey('lapd10'), job = {"police"}},
	[29] = {model = GetHashKey('taurus'), job = {"police"}},
}