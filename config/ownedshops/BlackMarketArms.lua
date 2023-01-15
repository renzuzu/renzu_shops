return {
	[1] = {
		groups = 'valmoriamafia',
		AttachmentsCustomiseOnly = true,
		moneytype = 'black_money',
		label = 'Black Market (Arms)',
		coord = vec3(147.8766784668,-370.18817138672,-9.5960102081299),
		price = 3000000,
		supplieritem = shared.Storeitems.BlackMarketArms,
		selfdeliver = {model = `gburrito`, coord = vec4(96.93049621582,-383.89376831055,-13.230435371399,248.75256347656)},
		ped = function()
			local model = `a_m_m_eastsa_01`
			lib.requestModel(model)
			local ped = CreatePed(4, model, 147.89819335938,-369.93908691406,-10.7432117462158,168.91729736328, false,true)
			while not DoesEntityExist(ped) do Wait(1) end
			SetBlockingOfNonTemporaryEvents(ped,true)
			SetEntityInvincible(ped,true)
			FreezeEntityPosition(ped,true)
		end,
	},
}