return {
	General = { -- General Stores 24/7
		{ lvl = 1, name = 'burger', price = 50 , category = 'food', customise = {'cheese', 'lettuce', 'hotsauce', 'mayonaise', 'burgerpatty'}},
		{ lvl = 1, name = 'water', price = 10 , category = 'beverages', customise = {'mineralwater', 'purifiedwater'}},
		{ lvl = 1, name = 'cola', price = 30 , category = 'beverages'},
		{ lvl = 1, name = 'coffee', price = 30 , category = 'beverages'},
		{ lvl = 1, name = 'donut', price = 30 , category = 'food'},
		{ lvl = 1, name = 'sandwich', price = 30 , category = 'food'},
		{ lvl = 2, name = 'lighter', price = 20 , category = 'misc'},
		{ lvl = 2, name = 'phone', price = 1000 , category = 'gadget'},
		{ lvl = 2, name = 'parachute', price = 3000 , category = 'gadget'},
		{ lvl = 2, name = 'radio', price = 1000 , category = 'gadget'},
		{ lvl = 2, name = 'latte', price = 150 , category = 'beverages'},
		{ lvl = 1, name = 'tomatosauce', price = 15 , category = 'ingredients'},
		{ lvl = 1, name = 'burgerpatty', price = 15 , category = 'ingredients'},
		{ lvl = 1, name = 'tacoshells', price = 15 , category = 'ingredients'},
		{ lvl = 1, name = 'ground_beef', price = 15 , category = 'ingredients'},
		{ lvl = 1, name = 'tomato', price = 15 , category = 'ingredients'},
		{ lvl = 1, name = 'pasta', price = 15 , category = 'ingredients'},
		{ lvl = 1, name = 'onion', price = 15 , category = 'ingredients'},
		{ lvl = 1, name = 'mayonaise', price = 15 , category = 'ingredients'},
		{ lvl = 1, name = 'hotsauce', price = 5 , category = 'ingredients'},
		{ lvl = 1, name = 'lettuce', price = 5 , category = 'ingredients'},
		{ lvl = 1, name = 'tacosauce', price = 7 , category = 'ingredients', disable = true}, -- disable tag, to disable the item from showing in shop UI. while this can be disable and enable tru store manage
		{ lvl = 1, name = 'fish', price = 5 , category = 'wet foods'},
		{ lvl = 1, name = 'beef', price = 5 , category = 'wet foods'},
		{ lvl = 1, name = 'chicken', price = 5 , category = 'wet foods'},
		{ lvl = 1, name = 'martini', price = 5 , category = 'liquor'},


		-- metadatas type item
		{ lvl = 1, name = 'burger', price = 80 , category = 'food', metadata = { -- ox_inventory supported only
				label = 'Cheese Burger', -- custom label name to set from metadatas
				cheese = true,
				name = 'cheeseburger', -- identifier important
				hunger = 500000,
				image = 'cheeseburger',
				description = 'Burger with Cheese',
				customrandomname = 'custom text'
			},
		},
		{ lvl = 1, name = 'burger', price = 20 , category = 'food', metadata = { -- ox_inventory supported only
				label = 'Angels Burger', -- custom label name to set from metadatas
				cheese = true,
				name = 'angelsburger', -- identifier important
				hunger = 100000,
				image = 'burger',
				description = 'Burger less patty',
				customrandomname = 'custom text'
			},
		},
	},
	Ammunation = {
		{ lvl = 1, name = 'ammo-9', category = 'ammo', price = 5, },
		{ lvl = 1, name = 'ammo-9', category = 'ammo', price = 5, },
		{ lvl = 1, name = 'WEAPON_KNIFE', category = 'handheld', price = 200 },
		{ lvl = 1, name = 'WEAPON_BAT', category = 'handheld', price = 100 },
		{ lvl = 1, name = 'WEAPON_PISTOL', category = 'Handgun', price = 1000, metadata = { registered = true }, license = 'weapon' },
		{ lvl = 2, name = 'WEAPON_SMG', category = 'machine guns', price = 15000, metadata = { registered = true }, license = 'weapon' },
		{ lvl = 2, name = 'WEAPON_APPISTOL', category = 'Handgun', price = 10000, metadata = { registered = true }, license = 'weapon' },
		{ lvl = 2, name = 'WEAPON_BZGAS', category = 'throwable', price = 5000, metadata = { registered = true }, license = 'weapon' },
		{ lvl = 2, name = 'WEAPON_COMBATPDW', category = 'machine guns', price = 18000, metadata = { registered = true }, license = 'weapon' },
	},

	VehicleShop = MultiCategory(
		{
			['boats'] = true, -- blacklisted boats
			['planes'] = true, -- blacklisted planes
			['helicopters'] = true -- blacklisted helis
		},
		{}, -- whitelisted table
		AllVehicles -- all vehicles can be found /data/vehicles.lua
	),

	BlackMarketArms = {
		{ name = 'WEAPON_DAGGER', price = 5000, category = 'Handheld', metadata = { registered = false	}, currency = 'black_money' },
		{ name = 'WEAPON_CERAMICPISTOL', price = 20000, category = 'Handgun', metadata = { registered = false }, currency = 'black_money' },
		{ name = 'WEAPON_HEAVYPISTOL', price = 30000, category = 'Handgun',metadata = { registered = false }, currency = 'black_money' },
		{ name = 'WEAPON_HEAVYRIFLE', price = 70000, category = 'Rifle',metadata = { registered = false }, currency = 'black_money' },
		{ name = 'WEAPON_GUSENBERG', price = 50000, category = 'Rifle',metadata = { registered = false }, currency = 'black_money' },
		{ name = 'WEAPON_COMPACTRIFLE', price = 50000, category = 'Rifle',metadata = { registered = false }, currency = 'black_money' },
		{ name = 'WEAPON_BULLPUPRIFLE', price = 60000, category = 'Rifle',metadata = { registered = false }, currency = 'black_money' },

		{ name = 'at_suppressor_light', price = 50000, category = 'Attachements', currency = 'black_money' },
		{ name = 'ammo-rifle', price = 1000, category = 'Ammo', currency = 'black_money' },
		{ name = 'ammo-rifle2', price = 1000, category = 'Ammo', currency = 'black_money' }
	},
}