-- Buyable Shops

-- SAMPLE
	-- General = { -- @1
	-- 	[1] = { -- @2
	-- 		moneytype = 'money', -- @3
	-- 		label = 'General Store #1', -- @4
	-- 		coord = vec3(25.931,-1350.181,29.32), -- @5
	-- 		cashier = vec3(24.48,-1347.23,29.49), -- @6
	-- 		price = 1000000, -- @7
	-- 		supplieritem = config.Storeitems.General, -- @8
	-- 	},
	-- }

-- @1 Shop Type . ex. General  ( must be same with config/defaultshops.lua )
-- @2 Shop Index 
	-- Same Index Number must be the same with config/defaultshops.lua #locations
	-- locations = {
	-- 	vec3(2748.0, 3473.0, 55.67), <-- Shop index 1
	-- 	vec3(342.99, -1298.26, 32.51) <-- Shop index 2
	-- }
-- @3 Money Type. eg. money, black_money. or any custom currency (must be item)
-- @4 Shop Label name Aka Shop identifier for Owned Shops. ex General Store #3 (3 is the Shop index for example)
-- @5 Store Owner Coordinates or Buy Store Coordinates vec3 format
-- @6 Cashier Coordinates. this can be disable by removing the cashier by commenting it via -- cashier = {}. cashier coordinates are the same with robber trigger location
-- @7 Shop Price
-- @8 Item data table for items. { name = 'burger', price = 100} or the config table the same with the sample above.
return {
	General = { -- General Stores 24/7
		[1] = {
			moneytype = 'money',
			label = 'General Store #1', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(25.931,-1350.181,29.32), -- owner manage coord
			cashier = vec3(24.48,-1347.23,29.49), -- cashier coord for robbing or onduty ondemand
			price = 1000000,
			supplieritem = config.Storeitems.General,
		},
		[2] = {
			moneytype = 'money',
			label = 'General Store #2', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(-3047.7958984375,585.60412597656,7.90892), -- owner manage coord
			cashier = vec3(-3038.9069824219,584.55187988281,7.9089), -- cashier coord for robbing or onduty ondemand
			price = 1000000,
			supplieritem = config.Storeitems.General,
		},
		[3] = {
			moneytype = 'money',
			label = 'General Store #3', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(-3249.9851074219,1004.5347900391,12.830), -- owner manage coord
			cashier = vec3(-3242.2158203125,999.91192626953,12.8307075), -- cashier coord for robbing or onduty ondemand
			price = 1000000,
			supplieritem = config.Storeitems.General,
		},
		[4] = {
			moneytype = 'money',
			label = 'General Store #4', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(1734.8125,6420.7963867188,35.03), -- owner manage coord
			cashier = vec3(1727.7747802734,6415.20703125,35.03722), -- cashier coord for robbing or onduty ondemand
			price = 1000000,
			supplieritem = config.Storeitems.General,
		},
		[5] = {
			moneytype = 'money',
			label = 'General Store #5', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(1959.6505126953,3748.9572753906,32.3437), -- owner manage coord
			cashier = vec3(1960.0518798828,3739.9448242188,32.343746), -- cashier coord for robbing or onduty ondemand
			price = 1000000,
			supplieritem = config.Storeitems.General,
		},
		[6] = {
			moneytype = 'money',
			label = 'General Store #6', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(1959.6505126953,3748.9572753906,32.3437), -- owner manage coord
			cashier = vec3(1960.0518798828,3739.9448242188,32.343746), -- cashier coord for robbing or onduty ondemand
			price = 1000000,
			supplieritem = config.Storeitems.General,
		},
		[7] = {
			moneytype = 'money',
			label = 'General Store #7', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(545.80249023438,2662.8833007813,42.156), -- owner manage coord
			cashier = vec3(549.03118896484,2671.3017578125,42.15), -- cashier coord for robbing or onduty ondemand
			price = 1000000,
			supplieritem = config.Storeitems.General,
		},
		[8] = {
			moneytype = 'money',
			label = 'General Store #8', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(2672.8837890625,3286.7370605469,55.241), -- owner manage coord
			cashier = vec3(2678.169921875,3279.3405761719,55.24113), -- cashier coord for robbing or onduty ondemand
			price = 1000000,
			supplieritem = config.Storeitems.General,
		},
		[9] = {
			moneytype = 'money',
			label = 'General Store #9', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(2549.4145507813,385.2060546875,108.622), -- owner manage coord
			cashier = vec3(2557.4404296875,380.73937988281,108.62), -- cashier coord for robbing or onduty ondemand
			price = 1000000,
			supplieritem = config.Storeitems.General,
		},
		[10] = {
			moneytype = 'money',
			label = 'General Store #10', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(378.58612060547,333.1130065918,103.56), -- owner manage coord
			cashier = vec3(372.51177978516,326.31723022461,103.566), -- cashier coord for robbing or onduty ondemand
			price = 1000000,
			supplieritem = config.Storeitems.General,
		},
	},
	Ammunation = {
		[1] = {
			moneytype = 'money',
			label = 'Ammunation #1', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(14.60,-1106.49,29.79),
			cashier = vec3(23.79,-1105.89,29.79),
			price = 3000000,
			supplieritem = config.Storeitems.Ammunation,
		},
		[2] = {
			moneytype = 'money',
			label = 'Ammunation #2', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(-666.68981933594,-933.82214355469,21.82),
			cashier = vec3(-661.03424072266,-933.60925292969,21.829),
			price = 3000000,
			supplieritem = config.Storeitems.Ammunation,
		},
		[3] = {
			moneytype = 'money',
			label = 'Ammunation #3', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(817.93695068359,-2155.3342285156,29.619),
			cashier = vec3(808.84484863281,-2159.0754394531,29.61),
			price = 3000000,
			supplieritem = config.Storeitems.Ammunation,
		},
		[4] = {
			moneytype = 'money',
			label = 'Ammunation #4', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(1689.4692382813,3757.6884765625,34.70531),
			cashier = vec3(1692.9857177734,3761.8244628906,34.705),
			price = 3000000,
			supplieritem = config.Storeitems.Ammunation,
		},
		[5] = {
			moneytype = 'money',
			label = 'Ammunation #5', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(-334.61535644531,6081.859375,31.454),
			cashier = vec3(-330.73712158203,6085.865234375,31.4547),
			price = 3000000,
			supplieritem = config.Storeitems.Ammunation,
		},
		[6] = {
			moneytype = 'money',
			label = 'Ammunation #6', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(255.1056060791,-46.409656524658,69.9410),
			cashier = vec3(253.49932861328,-51.409084320068,69.941),
			price = 3000000,
			supplieritem = config.Storeitems.Ammunation,
		},
		[7] = {
			moneytype = 'money',
			label = 'Ammunation #7', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(2572.2485351563,293.04409790039,108.73),
			cashier = vec3(2566.80859375,292.54428100586,108.73),
			price = 3000000,
			supplieritem = config.Storeitems.Ammunation,
		},
		[8] = {
			moneytype = 'money',
			label = 'Ammunation #8', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(-1122.0476074219,2696.7319335938,18.55),
			cashier = vec3(-1118.0738525391,2700.548828125,18.554),
			price = 3000000,
			supplieritem = config.Storeitems.Ammunation,
		},
		[9] = {
			moneytype = 'money',
			label = 'Ammunation #9', -- identifier for each stores. do not rename once player already buy this store
			coord = vec3(846.80895996094,-1035.1741943359,28.34),
			cashier = vec3(841.24395751953,-1035.2589111328,28.19),
			price = 3000000,
			supplieritem = config.Storeitems.Ammunation,
		},
	},
	VehicleShop = {
		[1] = {
			moneytype = 'money',
			type = 'vehicle',
			label = 'Premium Deluxe Motorsports',
			coord = vec3(-31.42,-1106.44,26.422),
			purchase = vec4(-31.88,-1091.17,25.74,337.1),
			spawn = vec4(-46.166618347168,-1095.1260986328,25.746654510498,149.61434936523),
			restock = vec4(-49.725978851318,-1077.2698974609,27.09181022644,68.993782043457),
			cashier = vec3(-55.57,-1097.97,26.42),
			blip = {
				id = 402, colour = 69, scale = 0.8
			},
			price = 3000000,
			supplieritem = config.Storeitems.VehicleShop,
			camerasetting = {offset = vec3(0.0,-1.2,0.0), fov = 25}
		},
		[2] = {
			moneytype = 'money',
			type = 'vehicle',
			label = 'Premium Deluxe Motorsports Patoche',
			coord = vec3(-1248.3510742188,-350.24868774414,37.33287),
			purchase = vec4(-1231.9196777344,-349.27304077148,36.66028213501,30.436424255371),
			spawn = vec4(-1256.2485351563,-366.36083984375,36.495769500732,355.48330688477),
			restock = vec4(-1241.8355712891,-328.19290161133,37.422836303711,297.9235534668),
			cashier = vec3(-1252.7078857422,-348.5173034668,36.90762),
			blip = {
				id = 402, colour = 69, scale = 0.8
			},
			price = 3000000,
			supplieritem = MultiCategory(
				{['boats'] = true, ['planes'] = true}, -- blacklisted types
				{
					--['boats'] = true
				}, -- whitelisted types, if you want to whitelist only, doing whitelist will disable category table below
				Vehicles.Annis,
				Vehicles.Shitzu
			),
			camerasetting = {offset = vec3(0.0,1.0,0.0), fov = -10}
		},
		[3] = { -- boat shop
			moneytype = 'money',
			type = 'vehicle',
			label = 'Premium Boat Shop',
			coord = vec3(-752.83978271484,-1510.9036865234,5.0079083),
			purchase = vec4(-797.05767822266,-1503.3923339844,0.41423982381821,104.68099975586),
			spawn = vec4(-810.53790283203,-1517.4093017578,-0.052975848317146,282.99340820313),
			restock = vec4(-742.36212158203,-1498.0222167969,5.022264957428,115.97137451172),
			cashier = vec3(-759.65838623047,-1515.3922119141,4.976915),
			blip = {
				id = 402, colour = 69, scale = 0.8
			},
			price = 3000000,
			supplieritem = MultiCategory(
				{}, -- blacklisted types
				{['boats'] = true} -- whitelisted types, if you want to whitelist only, doing whitelist will only show whats in whitelisted
			),
			camerasetting = {offset = vec3(0.0,0.7,0.0), fov = 1}
		},
	},

	BlackMarketArms = {
		[1] = {
			moneytype = 'black_money',
			label = 'Black Market (Arms)',
			coord = vec3(588.88385009766,-3281.7673339844,6.069561),
			price = 3000000,
			supplieritem = config.Storeitems.BlackMarketArms,
			selfdeliver = {model = `youga3`, coord = vec4(488.18109130859,-3159.7514648438,6.2411198616028,0.62522822618484)}
		}
	},
}