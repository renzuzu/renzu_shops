return {
	[1] = {
		groups = 'mechanic',
		moneytype = 'money',
		label = 'MechanicSupply 1', -- identifier for each stores. do not rename once player already buy this store
		coord = vec3(-342.44241333008,-169.92474365234,38.949729919434), -- owner manage coord
		--cashier = vec3(-1194.4945068359,-895.02117919922,13.97), -- cashier coord for robbing or onduty ondemand
		price = 1000000,
		supplieritem = shared.Storeitems.MechanicSupply,
		--stash = vec3(-1200.7606201172,-901.37634277344,13.97),
		-- crafting = {
		-- 	coord = vec3(-1200.5224609375,-897.31774902344,13.9741),
		-- 	label = 'Cook',
		-- },
		-- work = {
		-- 	groups = 'mechanic',
		-- 	coord = {
		-- 		[1] = vec3(441.15505981445,-991.92419433594,29.072),
		-- 		[2] = vec3(438.12197875977,-994.64831542969,29.072),
		-- 		[3] = vec3(438.10763549805,-981.50042724609,29.072),
		-- 		[4] = vec3(441.43545532227,-983.39562988281,29.072),
		-- 		[5] = vec3(438.70629882813,-987.91796875,29.072)
		-- 	},
		-- 	label = 'Proccesed Documents',
		-- 	animation = {
		-- 		dict = 'mp_fbi_heist',
		-- 		clip = 'loop'
		-- 	},
		-- 	reward = 'policedocuments'
		-- },
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