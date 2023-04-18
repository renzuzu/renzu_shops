
	return {
		[1] = {
			--groups = 'police',
			vehicletype = 'car', -- type column from sql database.
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
	[2] = { -- boat shop
		--groups = 'police',
		marker = true,
		vehicletype = 'boat', -- type column from sql database.
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
}