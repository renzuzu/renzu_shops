return {
	[1] = {
		--groups = 'valmoriamafia',
		AttachmentsCustomiseOnly = true,
		moneytype = 'black_money',
		label = 'Black Market Takuza',
		coord = vec3(155.3530, -1273.9305, 21.1496),
		price = 3000000,
		supplieritem = shared.Storeitems.BlackMarketArms2,
		selfdeliver = {model = `gburrito`, coord = vec4(186.7238, -1257.3043, 28.5245, 258.5253)},
		ped = function()
			local model = `a_m_m_eastsa_01`
			lib.requestModel(model)
			local ped = CreatePed(4, model, 162.8677, -1239.0018, 13.2988, 262.4971, false,true)
			while not DoesEntityExist(ped) do Wait(1) end
			SetBlockingOfNonTemporaryEvents(ped,true)
			SetEntityInvincible(ped,true)
			FreezeEntityPosition(ped,true)
		end,
	}
}