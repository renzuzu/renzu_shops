return {
	[1] = {
		moneytype = 'money',
		label = 'Burgershot 1', -- identifier for each stores. do not rename once player already buy this store
		coord = vec3(-1178.3872070313,-895.81164550781,13.97), -- owner manage coord
		cashier = vec3(-1194.4945068359,-895.02117919922,13.97), -- cashier coord for robbing or onduty ondemand
		price = 1000000,
		supplieritem = shared.Storeitems.Burgershot,
		playertoplayer = true,
		stash = vec3(-1200.7606201172,-901.37634277344,13.97),
		crafting = {
			coord = vec3(-1200.5224609375,-897.31774902344,13.9741),
			label = 'Cook',
		},

	}
}