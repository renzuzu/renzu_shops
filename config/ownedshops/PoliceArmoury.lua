return {
	[1] = {
		groups = 'police',
		moneytype = 'policecredit',
		label = 'PoliceArmoury 1', -- identifier for each stores. do not rename once player already buy this store
		coord = vec3(440.82601928711,-987.30114746094,32.107872009277), -- owner manage coord
		--cashier = vec3(-1194.4945068359,-895.02117919922,13.97), -- cashier coord for robbing or onduty ondemand
		price = 1000000,
		supplieritem = shared.Storeitems.PoliceArmoury,
		--stash = vec3(-1200.7606201172,-901.37634277344,13.97),
		-- crafting = {
		-- 	coord = vec3(-1200.5224609375,-897.31774902344,13.9741),
		-- 	label = 'Cook',
		-- },
		work = {
			groups = 'police',
			coord = {
				[1] = vec3(441.2809753418,-991.30987548828,29.018440246582),
				[2] = vec3(437.58261108398,-994.244140625,29.020122528076),
				[3] = vec3(438.12753295898,-987.95947265625,29.019540786743),
				[4] = vec3(441.40307617188,-983.84924316406,29.019678115845),
				[5] = vec3(437.86807250977,-981.15588378906,29.33895111084)
			},
			label = 'Proccesed Documents',
			animation = {
				dict = 'mp_fbi_heist',
				clip = 'loop'
			},
			reward = 'policedocuments'
		},
		proccessed = {
			groups = 'police',
			label = 'Sending Documents',
			coord = vec3(-550.94702148438,-192.32469177246,38.312446594238),
			reward = 'policecredit',
			required = 'policedocuments',
			value = math.random(50,100)
		}

	}
}