
	return {
		[1] = {
			--groups = 'police',
			moneytype = 'money',
			ShopType = 'vehicle',
			label = 'Premium Deluxe Motorsports',
			coord = vec3(-30.46854019165,-1106.2268066406,26.247138977051),
			purchase = vec4(-30.913764953613,-1089.8571777344,25.747234344482,334.17758178711),
			spawn = vec4(-46.073593139648,-1094.2202148438,25.748180389404,133.15704345703),
			restock = vec4(-47.952449798584,-1075.3367919922,26.63140296936,70.053443908691),
			--	cashier = vec3(-55.57,-1097.97,26.42),
			blip = {
				id = 402, colour = 69, scale = 0.8
			},
			price = 3000000,
			supplieritem = shared.Storeitems.VehicleShop,
			camerasetting = {offset = vec3(0.0,-1.19,0.0), fov = 25},
			showcase = {
				[1] = {
					coord = vec3(-48.404075622559,-1096.7774658203,25.932521820068), 
					label = 'Spot 1',
					position = vec4(-48.951812744141,-1094.5797119141,25.748212814331,193.69998168945),
				},
				[2] = {
					coord = vec3(-47.933681488037,-1100.0953369141,25.9255371093756), 
					label = 'Spot 2',
					position = vec4(-46.62230682373,-1101.9412841797,25.749835968018,35.80154800415),
				},
				[3] = {
					coord = vec3(-43.023063659668,-1096.8151855469,25.938526153564), 
					label = 'Spot 3',
					position = vec4(-40.979015350342,-1095.8538818359,25.750080108643,112.35222625732),
				},
				[4] = {
					coord = vec3(-38.440307617188,-1101.0833740234,25.922176361084), 
					label = 'Spot 4',
					position = vec4(-40.159378051758,-1102.5537109375,25.749704360962,309.24661254883),
				},
			}
		},
	[2] = {
		--groups = 'police',
		moneytype = 'money',
		ShopType = 'vehicle',
		label = 'Premium Deluxe Motorsports Patoche',
		coord = vec3(-1248.3510742188,-350.24868774414,37.33287),
		purchase = vec4(-1231.9196777344,-349.27304077148,36.66028213501,30.436424255371),
		spawn = vec4(-1256.2485351563,-366.36083984375,36.495769500732,355.48330688477),
		restock = vec4(-1241.8355712891,-328.19290161133,37.422836303711,297.9235534668),
	--	cashier = vec3(-1252.7078857422,-348.5173034668,36.90762),     
		blip = {
			id = 402, colour = 69, scale = 0.8
		},
		price = 3000000,
		supplieritem = MultiCategory(
			{['boats'] = true, ['planes'] = true}, -- blacklisted types
			{
				--['boats'] = true
			}, -- whitelisted types, if you want to whitelist only, doing whitelist will disable category table below
			AllVehicles,
			Vehicles.Annis,
			Vehicles.Shitzu
		),
		camerasetting = {offset = vec3(0.0,1.0,0.0), fov = -10},
		showcase = {
			[1] = {
				coord = vec3(-1262.4072265625,-356.31912231445,37.01580), 
				label = 'Spot 1',
				position = vec4(-1263.5510253906,-353.92984008789,36.510929107666,208.12538146973),
			},
			[2] = {
				coord = vec3(-1267.3598632813,-357.88278198242,37.1833), 
				label = 'Spot 2',
				position = vec4(-1267.8084716797,-356.44583129883,36.697582244873,219.08364868164),

			},
			[3] = {
				coord = vec3(-1267.1409912109,-361.76306152344,36.941), 
				label = 'Spot 3',
				position = vec4(-1269.6141357422,-362.91970825195,37.11107635498,297.50491333008),
			},
		}
	},
	[3] = { -- boat shop
		--groups = 'police',
		marker = true,

		moneytype = 'money',
		ShopType = 'vehicle',
		label = 'Premium Boat Shop',
		coord = vec3(-753.24609375,-1512.6853027344,4.9496669769287),
		purchase = vec4(-797.05767822266,-1503.3923339844,0.41423982381821,104.68099975586),
		spawn = vec4(-810.53790283203,-1517.4093017578,-0.052975848317146,282.99340820313),
		restock = vec4(-742.36212158203,-1498.0222167969,5.022264957428,115.97137451172),
	--	cashier = vec3(-759.65838623047,-1515.3922119141,4.976915),
		blip = {
			id = 402, colour = 69, scale = 0.8
		},
		price = 3000000,
		supplieritem = MultiCategory(
			{}, -- blacklisted types
			{['boats'] = true}, -- whitelisted types, if you want to whitelist only, doing whitelist will only show whats in whitelisted
			AllVehicles
		),
		camerasetting = {offset = vec3(0.0,0.7,0.0), fov = 1}
	},
	[4] = { -- boat shop
		marker = true,
		groups = 'police',
		moneytype = 'money',
		ShopType = 'vehicle',
		label = 'Police Vehicle',
		coord = vec3(0.0,0.0,0.0),
		purchase = vec4(471.13262939453,-1011.2862548828,28.212493896484,95.421531677246),
		spawn = vec4(451.82864379883,-1012.940246582,28.480855941772,78.403732299805),
		restock = vec4(0.0,0.0,0.0,0.0),
		--cashier = vec3(-759.65838623047,-1515.3922119141,4.976915),
		blip = {
			id = 402, colour = 69, scale = 0.8
		},
		price = 3000000,
		supplieritem = {
			{name='police',price=10000,label='Police Vehicle',grade=0},
			--{name='21c34x4',price=10000,label='Open 4x4',grade=6},
			{name='21c310sedan',price=10000,label='Police Sedan',grade=6},
			--{name='21c318muscle',price=10000,label='Police GT',grade=6},
			{name='21c318suv',price=10000,label='Police SUV',grade=6},
			{name='27c34x4',price=10000,label='Close 4x4',grade=6},
			{name='c3bikeu',price=10000,label='Police Bike',grade=6},
			{name='slc3202500',price=10000,label='Police Pick-up',grade=6},
			--{name='HellcatRed',price=10000,label='Police Hell Cat',grade=6},
			--{name='rmodzl1police',price=10000,label='Police Camaro',grade=6},
			{name='sjcop1',price=10000,label='Police Dodge',grade=6},
		},
		camerasetting = {offset = vec3(0.0,0.7,0.0), fov = 1}
	},
	[5] = { -- boat shop
		groups = 'ambulance',
		marker = true,

		moneytype = 'money',
		ShopType = 'vehicle',
		label = 'Ems Vehicle',
		coord = vec3(0.0,0.0,0.0),
		purchase = vec4(1136.1715087891,-1586.9890136719,34.046848297119,147.81546020508),
		spawn = vec4(1136.1715087891,-1586.9890136719,34.046848297119,147.81546020508),
		restock = vec4(0.0,0.0,0.0,0.0),
		--cashier = vec3(-759.65838623047,-1515.3922119141,4.976915),
		blip = {
			id = 402, colour = 69, scale = 0.8
		},
		price = 3000000,
		supplieritem = {
			{name='qrv',price=10000,label='Ems Vehicle',grade=0},
			{name='ambulance',price=10000,label='Ems Vehicle',grade=0},
			{name='sprinter1',price=10000,label='Ems Ambulance',grade=7},
			{name='mini',price=10000,label='Ems Mini',grade=7},
			{name='polgs350',price=10000,label='Ems Lexus',grade=7},
			{name='pol718',price=10000,label='Ems Porsche',grade=7},
			{name='polaventa',price=10000,label='Ems Aventa',grade=7},
		},
		camerasetting = {offset = vec3(0.0,0.7,0.0), fov = 1}
	},
	[6] = { -- boat shop
		groups = 'mechanic',
		marker = true,

		moneytype = 'money',
		ShopType = 'vehicle',
		label = 'Mechanic Vehicle',
		coord = vec3(0.0,0.0,0.0),
		purchase = vec4(-391.08364868164,-122.03777313232,38.015823364258,300.07522583008),
		spawn = vec4(-362.779296875,-115.99820709229,38.042308807373,199.43936157227),
		restock = vec4(0.0,0.0,0.0,0.0),
		--cashier = vec3(-759.65838623047,-1515.3922119141,4.976915),
		blip = {
			id = 402, colour = 69, scale = 0.8
		},
		price = 3000000,
		supplieritem = {
			{name='towtruck',price=10000,label='Mechanic Vehicle',grade=0},
			{name='towtruck2',price=10000,label='Mechanic Vehicle',grade=6},
			{name='rumpo',price=10000,label='Mechanic Vehicle',grade=6},
			{name='flatbed',price=10000,label='Mechanic Vehicle',grade=6},
			{name='21raptor',price=10000,label='Mechanic Raptor',grade=6},
			{name='x3gladiator9',price=10000,label='Mechanic Gladiator',grade=6},
		},
		camerasetting = {offset = vec3(0.0,0.7,0.0), fov = 1}
	},
}