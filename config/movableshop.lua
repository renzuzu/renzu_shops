return {
	Hotdog = {
		label = 'Chihuahua Hot Dogs',
		type = 'object',
		model = `prop_hotdogstand_01`,
		coord = vec3(40.149337768555,-1000.8768920898,29.408),
		price = 500000,
		menu = {
			Food = {
				[1] = {name = 'hotdogsandwich', price = 50, metadata = {}, ingredients = {hotdog = 1, bread = 1, tomatosauce = 1}},
				[2] = {name = 'hotdogsandwich', price = 80, ingredients = {hotdog = 1, bread = 1, cheese = 1, tomatosauce = 1}, metadata = {name = 'cheesedogsandwich', hunger = 150000, label = 'Cheese Dog  Sandwich', image = 'hotdog'}},
				[3] = {name = 'hotdogsandwich', price = 120, ingredients = {hotdog = 2, bread = 1, tomatosauce = 1}, metadata = {name = 'jumbohotdogsandwich', hunger = 350000, label = 'Jumbo Hot Dog Sandwich', image = 'hotdog'}},
			},
			Drinks = {
				[1] = {name = 'water', price = 20},
				[2] = {name = 'cola', price = 50},
				[3] = {name = 'cola', price = 80, metadata = {name = 'ecoladiet', thirst = 250000, label = 'Diet Coke', image = 'cola'}}
			}
		},
		blip = {
			id = 375, colour = 69, scale = 0.6
		},
		pos = vec3(-0.2 ,1.4,-0.95),
		rot = vec3(2.55,0.65,100.2)
	},

	Burger = {
		label = 'Beefy Bills Burger Bar',
		type = 'object',
		model = `prop_burgerstand_01`,
		coord = vec3(369.01425170898,-371.02331542969,46.757801055908),
		price = 500000,
		menu = {
			Food = {
				[1] = {name = 'burger', price = 50, metadata = {}, ingredients = {burgerpatty = 1, bread = 1, tomatosauce = 1}},
				[2] = {name = 'burger', price = 80, ingredients = {burgerpatty = 1, bread = 1, cheese = 1, tomatosauce = 1}, metadata = {name = 'cheeseburger', hunger = 150000, label = 'Cheesy Burger', image = 'burger'}},
				[3] = {name = 'burger', price = 120, ingredients = {burgerpatty = 2, bread = 1, tomatosauce = 1}, metadata = {name = 'doublebartburger', hunger = 350000, label = 'Double Bart Burger', image = 'burger'}},
			},
			Drinks = {
				[1] = {name = 'water', price = 20},
				[2] = {name = 'sprunk', price = 50},
				[3] = {name = 'cola', price = 80, metadata = {name = 'ecoladiet', thirst = 250000, label = 'Diet Coke', image = 'cola'}}
			}
		},
		blip = {
			id = 375, colour = 69, scale = 0.6
		},
		pos = vec3(-0.2 ,1.4,-0.95),
		rot = vec3(2.55,0.65,100.2)
	},
	Taco = {
		label = 'Attack A Taco', -- name of shop
		type = 'vehicle', -- declare type of movable shop. Object is spawnable object, while vehicle is a automobile.
		model = `taco`, -- model name
		coord = vec3(21.721435546875,-1600.9423828125,29.282648086), -- buying coordinates
		spawn = vec4(25.488815307617,-1590.5723876953,29.102367401123,227.42039489746), -- spawn location of vehicle
		price = 500000,
		menu = { -- products . Food and Drinks are automatically assign as Category
			Food = {
				[1] = {name = 'taco', price = 90, metadata = {}, ingredients = {tacoshells = 1, ground_beef = 1, lettuce = 1, tomato = 1}},
				[2] = {name = 'taco', price = 210, ingredients =  {tacoshells = 1, ground_beef = 1, lettuce = 1, tomato = 1, tomatosauce = 1, pasta = 1}, metadata = {name = 'spaghettitacos', hunger = 150000, label = 'Fiesta Spaghetti Tacos', image = 'taco'}},
				[3] = {name = 'taco', price = 250, ingredients =  {tacoshells = 1, ground_beef = 3, lettuce = 1, tomato = 1, onion = 1, mayonaise = 1}, metadata = {name = 'partybeeftaco', hunger = 350000, label = 'Party Beef Tacos', image = 'taco'}},
			},
			Drinks = {
				[1] = {name = 'water', price = 20},
				[2] = {name = 'sprunk', price = 50},
				[3] = {name = 'cola', price = 80, metadata = {name = 'ecoladiet', thirst = 250000, label = 'Diet Coke', image = 'cola'}}
			}
		},
		blip = {
			id = 375, colour = 69, scale = 0.6
		},
		pos = vec3(-0.2 ,1.4,-0.95),
		rot = vec3(2.55,0.65,100.2)
	},
}