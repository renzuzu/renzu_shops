-- Default Shops . this table inventory is being used if shops dont have a owner. the rest data is a copy of OX shops format
-- location indexes
return {

	['ClothingShop'] = {
		moneytype = 'money',
		name = 'ClothingShop',

		locations = {
			vec3(425.44613647461,-805.49926757813,29.49),
		},
		targets = {
			vec3(426.23623657227,-805.77111816406,29.438510894775),
		},
		blip = {
			id = 59, colour = 69, scale = 0.8
		},
	},

	['Balls8'] = {
		moneytype = 'money',
		name = '8Balls',
		groups = '8balls',
		blip = {
			id = 59, colour = 69, scale = 0.8
		},
		locations = {
			vector3(-1587.4376220703,-995.98486328125,13.342629432678),
		}
	},
	
	PondCafe = {
		moneytype = 'money',
		name = 'PondCafe',
		--groups = 'ambulance',
		blip = {
			id = 59, colour = 69, scale = 0.8
		},
		locations = {
			vector3(1116.9136962891,-640.98645019531,56.825714111328),
		}
	},
	
	MechanicSupply = {
		groups = {'mechanic','police'},
		moneytype = 'money',
		name = 'Mechanic Supply',
		blip = {
			id = 59, colour = 69, scale = 0.8
		}, 
		locations = {
			vector3(-213.81652832031,-1334.6248779297,30.13641166687),
		}
	},

	General = {
		moneytype = 'money',
		name = 'Shop 24/7',
		blip = {
			id = 59, colour = 69, scale = 0.8
		}, 
		locations = {
			vec3(25.811580657959,-1347.5052490234,29.49),
			vec3(-3039.0856933594,586.32489013672,7.90),
			vec3(-3241.6772460938,1001.6383056641,12.83),
			vec3(1729.1169433594,6414.3364257813,35.03),
			vec3(1698.2921142578,4924.8232421875,42.06),
			vec3(1961.76171875,3740.5964355469,32.34),
			vec3(547.32012939453,2671.7282714844,42.15),
			vec3(2679.0603027344,3280.791015625,55.24),
			vec3(2557.8103027344,382.42199707031,108.62),
			vec3(374.03216552734,325.38217163086,103.56),
			vec3(1163.3712158203,-324.0290222168,69.20)
		},
		targets = {
			vec3(25.213895797729,-1347.9556884766,29.492767333984),
			vec3(-3038.7204589844,585.35150146484,7.9046649932861),
			vec3(-3241.5505371094,1000.6616210938,12.826445579529),
			vec3(1728.2154541016,6414.3764648438,35.055946350098),
			vec3(1697.5864257813,4924.0048828125,42.059429168701),
			vec3(1960.9213867188,3739.9482421875,32.339492797852),
			vec3(548.30883789063,2671.8112792969,42.152244567871),
			vec3(2678.9006347656,3279.7360839844,55.259853363037),
			vec3(2557.8576660156,381.53189086914,108.6187210083),
			vec3(373.07611083984,325.69644165039,103.58511352539),
			vec3(1164.1829833984,-323.73614501953,69.200874328613)
		}
	},

	VehicleShop = {
		moneytype = 'money',
		type = 'vehicle',
		name = 'Vehicle Shop',
		blip = {
			id = 595, colour = 38, scale = 0.8
		},
		locations = {
			vec3(-53.079696655273,-1096.7937011719,26.42),
			vec3(-797.6484375,-1512.2006835938,1.595212),
		},
		targets = {
			vec3(-54.497680664063,-1097.7269287109,26.323600769043),
			vec3(-797.6484375,-1512.2006835938,1.595212697982),
		}
	},

	YouTool = {
		--groups = 'police',
		moneytype = 'black_money',
		name = 'YouTool',
		blip = {
			id = 402, colour = 69, scale = 0.8
		}, inventory = {
			{ name = 'lockpick', price = 2000 ,grade = 0},

		}, locations = {
			vec3(2747.025390625,3473.0822753906,55.683399200439),
			vec3(343.35479736328,-1297.6322021484,32.688446044922)
		}
	},

	Ammunation = {
		moneytype = 'money',
		name = 'Ammunation',
		blip = {
			id = 110, colour = 69, scale = 0.8
		}, 
		locations = {
			vec3(21.417778015137,-1106.8083496094,29.79),
			vec3(-662.79046630859,-935.12713623047,21.82),
			vec3(810.58520507813,-2157.458984375,29.61),
			vec3(1693.1014404297,3759.5517578125,34.70),
			vec3(-330.88055419922,6083.3168945313,31.45),
			vec3(252.47393798828,-49.140110015869,69.94),
			vec3(2568.6403808594,294.39981079102,108.73),
			vec3(-1118.3720703125,2697.9167480469,18.55),
			vec3(842.66595458984,-1033.5245361328,28.19)
		},
		targets = {
			vec3(22.223720550537,-1106.1149902344,29.797040939331),
			vec3(-662.64953613281,-934.39453125,21.82918548584),
			vec3(810.5126953125,-2158.2407226563,29.619028091431),
			vec3(1692.6358642578,3760.1484375,34.705295562744),
			vec3(-331.31820678711,6084.0048828125,31.454734802246),
			vec3(253.2212677002,-49.650302886963,69.941062927246),
			vec3(2568.4680175781,293.5110168457,108.73485565186),
			vec3(-1118.8206787109,2698.6801757813,18.554098129272),
			vec3(842.81329345703,-1034.3870849609,28.194812774658)
		}
	},

	PoliceArmoury = {
		moneytype = 'policecredit',
		name = 'Police Armoury',
		groups = 'police',
		blip = {
			id = 110, colour = 84, scale = 0.8
		}, inventory = {
			{ name = 'ammo-9', price = 2, },
			{ name = 'ammo-rifle', price = 2, },
			{ name = 'ammo-shotgun', price = 2, },
			{ name = 'WEAPON_FLASHLIGHT', price = 200 },
			{ name = 'WEAPON_NIGHTSTICK', price = 100 },
			{ name = 'WEAPON_PISTOL', price = 500, metadata = { registered = true, serial = 'POL' }, license = 'weapon' },
			{ name = 'WEAPON_CARBINERIFLE', price = 800, grade = 5, metadata = { registered = true, serial = 'POL' }, license = 'weapon', grade = 3 },
			{ name = 'WEAPON_STUNGUN', price = 300, metadata = { registered = true, serial = 'POL'} },
			{ name = 'WEAPON_PUMPSHOTGUN', price = 600, metadata = { registered = true, serial = 'POL'} },
			{ name = 'WEAPON_COMBATPDW', price = 700, metadata = { registered = true, serial = 'POL'} },

			{ lvl = 2, name = 'armour', category = 'Tools', price = 200, metadata = { description = 'pang pakunat' } },

		}, locations = {
			vec3(454.99395751953,-983.08898925781,30.689611434)
		}
	},

	LiquorStore = {
		name = 'Liquor Store',
		blip = {
			id = 93, colour = 69, scale = 0.8
		},
		locations = {
			vec3(1135.6799316406,-981.05126953125,46.41),
			vec3(-1224.2336425781,-907.26556396484,12.32),
			vec3(-1486.5960693359,-380.41864013672,40.16),
			vec3(-2968.2321777344,389.49346923828,15.04),
			vec3(1167.6383056641,2708.9777832031,38.15),
			vec3(1395.5361328125,3605.6745605469,34.98),
			vec3(-1392.7979736328,-606.52185058594,30.557426452637)
		},
		targets = {
			vec3(1135.0822753906,-982.25408935547,46.524444580078),
			vec3(-1222.5571289063,-907.63452148438,12.437350273132),
			vec3(-1486.82421875,-378.71246337891,40.330924987793),
			vec3(-2967.3071289063,390.77975463867,15.211061477661),
			vec3(1165.8991699219,2709.9206542969,38.273204803467),
			vec3(1393.2454833984,3605.7229003906,35.130367279053),
			vec3(-1392.7979736328,-606.52185058594,30.557426452637)
		}
	},

	BlackMarketArms = {
		moneytype = 'black_money',
		name = 'Black Market (Arms)',
		locations = {
			vec3(591.57434082031,-3279.8911132813,6.06),
			--vec3(163.0451, -1238.1116, 15.0734)
		}
	},
}