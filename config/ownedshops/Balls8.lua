return {
	[1] = {
		groups = '8balls',
		moneytype = 'money',
		label = '8Balls', -- identifier for each stores. do not rename once player already buy this store
		coord = vec3(-1577.8411865234,-983.45098876953,12.923707962036), -- owner manage coord
		cashier = vec3(-1587.1876220703,-995.619140625,13.162528991699), -- cashier coord for robbing or onduty ondemand
		price = 1000000,
		supplieritem = shared.Storeitems['8Balls'],
		stash = vec3(-1574.5544433594,-982.14953613281,12.676588058472),
		-- ped = function()
		-- 	local model = `a_f_m_beach_01`
		-- 	lib.requestModel(model)
		-- 	local ped = CreatePed(4, model, 1104.39453125,-645.82153320313,55.815998077393,222.87367248535, false,true)
		-- 	while not DoesEntityExist(ped) do Wait(1) end
		-- 	SetBlockingOfNonTemporaryEvents(ped,true)
		-- 	SetEntityInvincible(ped,true)
		-- 	FreezeEntityPosition(ped,true)
		-- end,
		tasks = {
			{
				--groups = 'pondcafe',
				coord = {
					[1] = vec3(-1581.7034912109,-990.57873535156,13.236403465271),
				},
				label = 'Fridge',
				onSelect = function()
					print('aso')
					Utils.CreateMenu({
						id = '8ballfridge',
						title = '8Balls Fridge Stocks',
						options = {
							{
								title = 'Meat',
								icon = 'meat',
								description = 'required for cooking',
								image = 'nui://ox_inventory/web/images/meat.png',
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Taking Meat',
										reward = 'meat',
										required = false,
										value = 1,
										dict = 'mini@repair',
										clip = 'fixing_a_ped',
										duration = 2000,
									})
								end
							},
							{
								title = 'BBQ Meat',
								icon = 'meat',
								description = 'required for cooking',
								image = 'nui://ox_inventory/web/images/bbqmeatmeat.png',
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Taking BBQ Meat',
										reward = 'bbqmeat',
										required = false,
										value = 1,
										dict = 'mini@repair',
										clip = 'fixing_a_ped',
										duration = 2000,
									})
								end
							},
							{
								title = 'Pig Brain',
								icon = 'meat',
								description = 'required for cooking',
								image = 'nui://ox_inventory/web/images/pigbrain.png',
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Taking Pig Brain',
										reward = 'pigbrain',
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
					[1] = vec3(-1582.9682617188,-992.25140380859,12.595446586609),
				},
				label = 'Drinks',
				onSelect = function()
					print('aso')
					Utils.CreateMenu({
						id = '8balldrinks',
						title = '8Balls Drinks',
						options = {
							{
								title = 'Red Horse',
								--icon = 'beer',
								description = 'Take a Red Horse',
								image = 'nui://ox_inventory/web/images/red_horse.png',

								onSelect = function(args)
									Utils.Proccesed({
										label = 'Taking Red Horse',
										reward = 'red_horse',
										required = false,
										value = 1,
										dict = 'mini@repair',
										clip = 'fixing_a_player',
										duration = 3000,
									})
								end
							},
							{
								title = 'Sprite',
								--icon = 'beer',
								description = 'Take a Sprite',
								image = 'nui://ox_inventory/web/images/sprite.png',

								onSelect = function(args)
									Utils.Proccesed({
										label = 'Taking Sprite',
										reward = 'sprite',
										required = false,
										value = 1,
										dict = 'mini@repair',
										clip = 'fixing_a_player',
										duration = 3000,
									})
								end
							},
							{
								title = 'Grape Juice',
								--icon = 'beer',
								description = 'Take a Grape Juice',
								image = 'nui://ox_inventory/web/images/grapejuice.png',
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Taking Grape Juice',
										reward = 'grapejuice',
										required = false,
										value = 1,
										dict = 'mini@repair',
										clip = 'fixing_a_player',
										duration = 3000,
									})
								end
							},
							{
								title = 'San Miguel Beer',
								--icon = 'beer',
								description = 'Take a San Miguel Beer',
								image = 'nui://ox_inventory/web/images/sanmig.png',

								onSelect = function(args)
									Utils.Proccesed({
										label = 'Taking San Miguel Beer',
										reward = 'sanmig',
										required = false,
										value = 1,
										dict = 'mini@repair',
										clip = 'fixing_a_player',
										duration = 3000,
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
					[1] = vec3(-1584.5264892578,-994.38739013672,13.304310798645),
				},
				label = 'Cook',
				onSelect = function()
					print('aso')
					Utils.CreateMenu({
						id = '8ballcook',
						title = '8Balls Cook',
						options = {
							{
								title = 'Sisig',
								icon = 'meat',
								description = 'Cook a Sizzling Sisig',
								image = 'nui://ox_inventory/web/images/sisig.png',
								metadata = {
									[1] = 'Pig Brain x2',
								},
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Cooking Sisig',
										reward = 'sisig',
										required = {
											[1] = { item = 'pigbrain', amount = 2},
										},
										value = 1,
										dict = 'amb@prop_human_bbq@male@idle_a',
										clip = 'idle_b',
										duration = 2000,
									})
								end
							},
							{
								title = 'Liempo',
								icon = 'meat',
								description = 'Cook a Liempo',
								image = 'nui://ox_inventory/web/images/liempo.png',
								metadata = {
									[1] = 'meat x2',
								},
								onSelect = function(args)
									Utils.Proccesed({
										label = 'Cooking Liempo',
										reward = 'liempo',
										required = {
											[1] = { item = 'meat', amount = 2},
										},
										value = 1,
										dict = 'amb@prop_human_bbq@male@idle_a',
										clip = 'idle_b',
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
					[1] = vec3(-1582.6984863281,-986.40588378906,13.064616203308),
				},
				label = 'Register Ticket',
				onSelect = function()
					local data = {
						label = 'Registering 8Balls Ticket',
						reward = 'poolticket',
						required = false,
						value = 1
					}
					lib.progressBar({
						duration = 5000,
						label = data.label,
						useWhileDead = false,
						canCancel = false,
						anim = {
							dict = 'mini@repair',
							clip = 'fixing_a_ped',
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
					[1] = vec3(-1585.916015625,-996.10333251953,13.278351783752),
				},
				label = 'Cook BBQ',
				onSelect = function()
					local data = {
						label = 'Cooking BBQ',
						reward = 'bbq1',
						required = 'bbqmeat',
						value = 1
					}
					lib.progressBar({
						duration = 5000,
						label = data.label,
						useWhileDead = false,
						canCancel = false,
						anim = {
							dict = 'amb@prop_human_bbq@male@idle_a',
							clip = 'idle_b',
						},
						disable = {
							car = true,
						}
					})
					lib.callback.await('renzu_shops:proccessed',100, data)
				end
			},
		}
	}
}