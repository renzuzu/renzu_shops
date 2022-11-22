--- preconfigured items in this resources are here
-- install it if you want all items to fully work.
-- or modify the items in config/*.lua, data/item_customise.lua
--- LIST of items you need to install to ox_inventory/data/items.lua
return {
	['playerbooth'] = {
		label = 'Market Booth Stall',
		weight = 0,
		client = {
			anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
			usetime = 2500,
			notification = 'Setup your Stall',
			export = 'renzu_shops.playerbooth'
		},
	},
	['burger'] = {
		label = 'Burger',
		weight = 350,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500
		},
	},
	['hotdogsandwich'] = {
		label = 'Hot Dog Sandwich',
		weight = 350,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500
		},
	},
	['hotdog'] = {
		label = 'Hotdog',
		weight = 50
	},
	['cola'] = {
		label = 'Cola',
		weight = 50
	},
	['bread'] = {
		label = 'Bread',
		weight = 50
	},
	['tomatosauce'] = {
		label = 'Tomato Sauce',
		weight = 50
	},
	['cheese'] = {
		label = 'Cheese',
		weight = 50
	},
	['burgerpatty'] = {
		label = 'Burger Patty',
		weight = 50
	},
	['burgerpatty'] = {
		label = 'Burger Patty',
		weight = 50
	},
	['sprunk'] = {
		label = 'Sprunk',
		weight = 50
	},
	['taco'] = {
		label = 'Taco',
		weight = 50
	},
	['tacoshells'] = {
		label = 'Taco Shells',
		weight = 50
	},
	['ground_beef'] = {
		label = 'Ground Beef',
		weight = 50
	},
	['lettuce'] = {
		label = 'Lettuce',
		weight = 50
	},
	['lettuce'] = {
		label = 'Lettuce',
		weight = 50
	},
	['tomato'] = {
		label = 'Tomato',
		weight = 50
	},
	['pasta'] = {
		label = 'Pasta',
		weight = 50
	},
	['onion'] = {
		label = 'Onion',
		weight = 50
	},
	['mayonaise'] = {
		label = 'Mayonaise',
		weight = 50
	},
	['martini'] = {
		label = 'Martini',
		weight = 50
	},
	['chicken'] = {
		label = 'Chicken',
		weight = 50
	},
	['beef'] = {
		label = 'Beef',
		weight = 50
	},
	['fish'] = {
		label = 'Fish',
		weight = 50
	},
	['tacosauce'] = {
		label = 'Tacosauce',
		weight = 50
	},
	['latte'] = {
		label = 'Latte',
		weight = 50
	},
	['hotsauce'] = {
		label = 'Hot Sauce',
		weight = 50
	},
	['item'] = {
		label = 'Default Item',
		weight = 50
	},
}
