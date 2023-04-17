return {
	[1] = {
		moneytype = 'money',
		label = 'Pond Cafe', -- identifier for each stores. do not rename once player already buy this store
		coord = vec3(1114.2652587891,-636.93481445313,56.635738372803), -- owner manage coord
		--cashier = vec3(1115.9930419922,-640.60797119141,57.934638), -- cashier coord for robbing or onduty ondemand
		price = 1000000,
		supplieritem = shared.Storeitems.PondCafe,
		stash = vec3(1114.525390625,-635.08990478516,57.244316101074),
		ped = function()
			local model = `a_f_m_beach_01`
			lib.requestModel(model)
			local ped = CreatePed(4, model, 1104.39453125,-645.82153320313,55.815998077393,222.87367248535, false,true)
			while not DoesEntityExist(ped) do Wait(1) end
			SetBlockingOfNonTemporaryEvents(ped,true)
			SetEntityInvincible(ped,true)
			FreezeEntityPosition(ped,true)
		end,
		tasks = {
			{
				groups = 'pondcafe',
				coord = {
					[1] = vec3(1104.4926757813,-646.05145263672,56.982025146484),
				},
				label = 'Rent a Jetski',
				onSelect = function()
					print('aso')
					Utils.CreateMenu({
						id = 'rentjetski',
						title = 'Jetski Rental',
						options = {
							{
								title = 'Rent Sea Shark',
								description = 'requires a Jetski Ticket',
								onSelect = function(args)
									local data = {
										reward = false,
										required = 'jetskiticket',
										value = 1
									}
									local hasticket = lib.callback.await('renzu_shops:proccessed',100, data)
									if hasticket then
										local model = `seashark`
										lib.requestModel(model)
										local seashark = CreateVehicle(model,1101.1252441406,-644.48785400391,55.21460723877,103.3373260498,true,true)
										while not DoesEntityExist(seashark) do Wait(1) end
										TaskEnterVehicle(cache.ped,seashark,-1,-1,1.0,3)
										Citizen.CreateThreadNow(function()
											local point = lib.points.new(vec3(1101.1252441406,-644.48785400391,55.21460723877), 10)
											function point:nearby()
												DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0, 1.0, 1.0, 200, 20, 20, 50, false, true, 2, nil, nil, false)
											
												if self.currentDistance < 1 and IsControlJustReleased(0, 38) then
													DeleteEntity(seashark)
													self:remove()
												end
											end
										end)
									end
								end
							},
						}
					})
				end
			},
			{
				groups = 'pondcafe',
				coord = {
					[1] = vec3(1116.1516113281,-633.89752197266,56.784858703613),
				},
				label = 'Water',
				onSelect = function()
					local data = {
						label = 'Taking Water',
						reward = 'water',
						required = false,
						value = 1
					}
					lib.progressBar({
						duration = 2000,
						label = data.label,
						useWhileDead = false,
						canCancel = false,
						anim = {
							dict = 'mini@repair',
							clip = 'fixing_a_ped'
						},
						disable = {
							car = true,
						}
					})
					lib.callback.await('renzu_shops:proccessed',100, data)
				end
			},

			{
				groups = 'pondcafe',
				coord = {
					[1] = vec3(1117.3211669922,-633.75616455078,56.901302337646),
				},
				label = 'Flour',
				onSelect = function()
					local data = {
						label = 'Taking Flour',
						reward = 'bread_flour',
						required = false,
						value = 1
					}
					lib.progressBar({
						duration = 2000,
						label = data.label,
						useWhileDead = false,
						canCancel = false,
						anim = {
							dict = 'mini@repair',
							clip = 'fixing_a_ped'
						},
						disable = {
							car = true,
						}
					})
					lib.callback.await('renzu_shops:proccessed',100, data)
				end
			},
			{
				groups = 'pondcafe',
				coord = {
					[1] = vec3(1118.0491943359,-636.99688720703,56.955459594727),
				},
				label = 'Milk',
				onSelect = function()
					local data = {
						label = 'Taking Milk',
						reward = 'milk',
						required = false,
						value = 1
					}
					lib.progressBar({
						duration = 2000,
						label = data.label,
						useWhileDead = false,
						canCancel = false,
						anim = {
							dict = 'mini@repair',
							clip = 'fixing_a_ped'
						},
						disable = {
							car = true,
						}
					})
					lib.callback.await('renzu_shops:proccessed',100, data)
				end
			},
			{
				groups = 'pondcafe',
				coord = {
					[1] = vec3(1116.7874755859,-633.72552490234,56.855403900146),
				},
				label = 'Coffee Seed',
				onSelect = function()
					local data = {
						label = 'Taking Coffee Seed',
						reward = 'coffeeseed',
						required = false,
						value = 1
					}
					lib.progressBar({
						duration = 2000,
						label = data.label,
						useWhileDead = false,
						canCancel = false,
						anim = {
							dict = 'mini@repair',
							clip = 'fixing_a_ped'
						},
						disable = {
							car = true,
						}
					})
					lib.callback.await('renzu_shops:proccessed',100, data)
				end
			},
			{
				groups = 'pondcafe',
				coord = {
					[1] = vec3(1116.3332519531,-637.76391601563,56.9807472229),
				},
				label = 'Brew Coffee',
				onSelect = function()
					local data = {
						label = 'Brewing Coffee Seed',
						reward = 'coffeepowder',
						required = 'coffeeseed',
						value = 1
					}
					lib.progressBar({
						duration = 2000,
						label = data.label,
						useWhileDead = false,
						canCancel = false,
						anim = {
							dict = 'mini@repair',
							clip = 'fixing_a_ped'
						},
						disable = {
							car = true,
						}
					})
					lib.callback.await('renzu_shops:proccessed',100, data)
				end
			},
			{
				groups = 'pondcafe',
				coord = {
					[1] = vec3(1115.5305175781,-633.90905761719,56.82986831665),
				},
				label = 'Chocolate',
				onSelect = function()
					local data = {
						label = 'Taking Chocolate',
						reward = 'chocolate',
						required = false,
						value = 1
					}
					lib.progressBar({
						duration = 2000,
						label = data.label,
						useWhileDead = false,
						canCancel = false,
						anim = {
							dict = 'mini@repair',
							clip = 'fixing_a_ped'
						},
						disable = {
							car = true,
						}
					})
					lib.callback.await('renzu_shops:proccessed',100, data)
				end
			},
			{
				groups = 'pondcafe',
				coord = {
					[1] = vec3(1115.7751464844,-633.85919189453,56.861865997314),
				},
				label = 'Sugar',
				onSelect = function()
					local data = {
						label = 'Taking Sugar',
						reward = 'sugar',
						required = false,
						value = 1
					}
					lib.progressBar({
						duration = 2000,
						label = data.label,
						useWhileDead = false,
						canCancel = false,
						anim = {
							dict = 'mini@repair',
							clip = 'fixing_a_ped'
						},
						disable = {
							car = true,
						}
					})
					lib.callback.await('renzu_shops:proccessed',100, data)
				end
			},
			{
				groups = 'pondcafe',
				coord = {
					[1] = vec3(1117.0270996094,-637.79559326172,56.859069824219),
				},
				label = 'Mocha',
				onSelect = function()
					local data = {
						label = 'Taking mocha',
						reward = 'mocha',
						required = false,
						value = 1
					}
					lib.progressBar({
						duration = 2000,
						label = data.label,
						useWhileDead = false,
						canCancel = false,
						anim = {
							dict = 'mini@repair',
							clip = 'fixing_a_ped'
						},
						disable = {
							car = true,
						}
					})
					lib.callback.await('renzu_shops:proccessed',100, data)
				end
			},
			{
				groups = 'pondcafe',
				coord = {
					[1] = vec3(1117.3264160156,-640.42303466797,56.862201690674),
				},
				label = 'Ticket',
				animation = {
					dict = 'mp_fbi_heist',
					clip = 'loop'
				},
				onSelect = function()
					local data = {
						label = 'Getting Ticket',
						reward = 'jetskiticket',
						required = false,
						value = 1
					}
					lib.progressBar({
						duration = 2000,
						label = data.label,
						useWhileDead = false,
						canCancel = false,
						anim = {
							dict = 'mini@repair',
							clip = 'fixing_a_ped'
						},
						disable = {
							car = true,
						}
					})
					lib.callback.await('renzu_shops:proccessed',100, data)
				end
			},
			{
				groups = 'pondcafe',
				coord = {
					[1] = vec3(1117.7862548828,-640.75573730469,57.836),
				},
				label = 'Juice Ingredients',
				onSelect = function()
					print('aso')
					Utils.CreateMenu({
						id = 'juiceingredients',
						title = 'Juice Ingredients',
						options = {
							{
								title = 'Mango Fruit',
								icon = 'lemon',
								description = 'Manga Fruit required for Juice Maker',
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Taking Mango Fruit',
										reward = 'mangofruit',
										required = false,
										value = 1,
										dict = 'mini@repair',
										clip = 'fixing_a_ped',
										duration = 2000,
									})
								end
							},
							{
								title = 'Orange Fruit',
								description = 'Orange Fruit required for Juice Maker',
								icon = 'lemon',
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Taking Orange Fruit',
										reward = 'orangefruit',
										required = false,
										value = 1,
										dict = 'mini@repair',
										clip = 'fixing_a_ped',
										duration = 2000,
									})
								end
							},
						}
					})
				end
			},
			{
				groups = 'pondcafe',
				coord = {
					[1] = vec3(1116.6389160156,-637.68084716797,57.024711608887),
				},
				label = 'Coffee Maker',
				onSelect = function()
					print('aso')
					Utils.CreateMenu({
						id = 'coffeemaker',
						title = 'Brewer',
						options = {
							{
								title = 'Cappucino',
								description = 'Brew a Cappuccino',
								image = 'nui://ox_inventory/web/images/cappuccino.png',
								metadata = {
									[1] = 'coffeepowder x1',
									[2] = 'milk x1',
									[3] = 'water x1',
								},
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Creating Cappuccino',
										reward = 'cappuccino',
										required = {
											[1] = { item = 'coffeepowder', amount = 1},
											[2] = { item = 'milk', amount = 1},
											[3] = { item = 'water', amount = 1},
										},
										value = 1,
										dict = 'mini@repair',
										clip = 'fixing_a_ped',
										duration = 2000,
									})
								end
							},
							{
								title = 'Expresso',
								description = 'Brew a Expresso',
								image = 'nui://ox_inventory/web/images/cappuccino.png',
								metadata = {
									[1] = 'coffeepowder x1',
									[2] = 'water x1',
									[3] = 'milk x1',
								},
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Creating Expresso',
										reward = 'espresso',
										required = {
											[1] = { item = 'coffeepowder', amount = 1},
											[2] = { item = 'milk', amount = 1},
											[3] = { item = 'water', amount = 1},
										},
										value = 1,
										dict = 'mini@repair',
										clip = 'fixing_a_ped',
										duration = 2000,
									})
								end
							},
							{
								title = 'Latte',
								description = 'Brew a Latte',
								image = 'nui://ox_inventory/web/images/cappuccino.png',
								metadata = {
									[1] = 'coffeepowder x1',
									[2] = 'milk x2',
								},
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Creating Latte',
										reward = 'latte',
										required = {
											[1] = { item = 'coffeepowder', amount = 1},
											[2] = { item = 'milk', amount = 2},
										},
										value = 1,
										dict = 'mini@repair',
										clip = 'fixing_a_ped',
										duration = 2000,
									})
								end
							},
						}
					})
				end
			},
			{
				groups = 'pondcafe',
				coord = {
					[1] = vec3(1117.6920166016,-636.00854492188,56.784484863281),
				},
				label = 'Cook',
				onSelect = function()
					print('aso')
					Utils.CreateMenu({
						id = 'cooking',
						title = 'Cooking',
						options = {
							{
								title = 'Double Cupcake',
								description = 'Cook a Double Cupcake',
								image = 'nui://ox_inventory/web/images/double_cupcake.png',
								metadata = {
									[1] = 'sugar x1',
									[2] = 'mocha x1',
									[3] = 'chocolate x1',
									[4] = 'bread flour x1'
								},
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Cooking Double Cupcake',
										reward = 'double_cupcake',
										required = {
											[1] = { item = 'sugar', amount = 1},
											[2] = { item = 'mocha', amount = 1},
											[3] = { item = 'chocolate', amount = 1},
											[4] = { item = 'bread_flour', amount = 1},
										},
										value = 1,
										dict = 'amb@prop_human_bbq@male@idle_a',
										clip = 'idle_b',
										duration = 4000,
									})
								end
							},
							{
								title = 'Vanilla Cupcake',
								description = 'Cook a Vanilla Cupcake',
								image = 'nui://ox_inventory/web/images/vanilla_cupcake.png',
								metadata = {
									[1] = 'sugar x1',
									[2] = 'mocha x1',
									[3] = 'chocolate x1',
									[4] = 'bread flour x1'
								},
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Cooking Vanilla Cupcake',
										reward = 'vanilla_cupcake',
										required = {
											[1] = { item = 'sugar', amount = 1},
											[2] = { item = 'mocha', amount = 1},
											[3] = { item = 'chocolate', amount = 1},
											[4] = { item = 'bread_flour', amount = 1},
										},
										value = 1,
										dict = 'amb@prop_human_bbq@male@idle_a',
										clip = 'idle_b',
										duration = 4000,
									})
								end
							},
							{
								title = 'Strawberry Cupcake',
								description = 'Cook a Strawberry Cupcake',
								image = 'nui://ox_inventory/web/images/strawberry_cupcake.png',
								metadata = {
									[1] = 'sugar x1',
									[2] = 'mocha x1',
									[3] = 'chocolate x1',
									[4] = 'bread flour x1'
								},
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Cooking Strawberry Cupcake',
										reward = 'strawberry_cupcake',
										required = {
											[1] = { item = 'sugar', amount = 1},
											[2] = { item = 'mocha', amount = 1},
											[3] = { item = 'chocolate', amount = 1},
											[4] = { item = 'bread_flour', amount = 1},
										},
										value = 1,
										dict = 'amb@prop_human_bbq@male@idle_a',
										clip = 'idle_b',
										duration = 4000,
									})
								end
							},
						}
					})
				end
			},
			{
				groups = 'pondcafe',
				coord = {
					[1] = vec3(1118.7666015625,-638.25756835938,57.070735931396),
				},
				label = 'Create Juice',
				onSelect = function()
					print('aso')
					Utils.CreateMenu({
						id = 'juicemaker',
						title = 'Juice Maker',
						options = {
							{
								title = 'Mango Juice',
								description = 'Create a Freh Milk tea',
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Taking Mango Fruit',
										reward = 'mangojuice',
										required = false,
										value = 1,
										dict = 'anim@mp_player_intupperspray_champagne',
										clip = 'idle_a',
										duration = 4000,
									})
								end
							},
							{
								title = 'Milk Tea',
								description = 'Create a Fresh Milk tea cafe',
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Taking Cafe',
										reward = 'milkteacafe',
										required = false,
										value = 1,
										dict = 'anim@mp_player_intupperspray_champagne',
										clip = 'idle_a',
										duration = 4000,
									})
								end
							},
							{
								title = 'Milk Tea',
								description = 'Create a Fresh Mango Juice',
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Taking Cafe',
										reward = 'milktea2',
										required = false,
										value = 1,
										dict = 'anim@mp_player_intupperspray_champagne',
										clip = 'idle_a',
										duration = 4000,
									})
								end
							},
							{
								title = 'Orange Juice',
								description = 'Create a Fresh Orange Juice',
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Taking Orange Fruit',
										reward = 'orangejuice',
										required = false,
										value = 1,
										dict = 'anim@mp_player_intupperspray_champagne',
										clip = 'idle_a',
										duration = 4000,
									})
								end
							},
						}
					})
				end
			},
			-- {
			-- 	groups = 'pondcafe',
			-- 	coord = {
			-- 		[1] = vec3(1118.6413574219,-638.33074951172,57.171211242676),
			-- 	},
			-- 	label = 'Create Mango Juice',
			-- 	animation = {
			-- 		dict = 'mp_fbi_heist',
			-- 		clip = 'loop'
			-- 	},
			-- 	reward = 'cooked'
			-- },
		}
		-- proccessed = {
		-- 	groups = 'police',
		-- 	label = 'Sending Documents',
		-- 	coord = vec3(-550.56921386719,-192.46615600586,38.219),
		-- 	reward = 'policecredit',
		-- 	required = 'policedocuments',
		-- 	value = math.random(50,100)
		-- }

	}
}