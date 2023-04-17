return {
	[1] = {
		--groups = 'gagoman',
		AttachmentsCustomiseOnly = true,
		moneytype = 'black_money',
		label = 'Black Market (Arms)',
		coord = vec3(590.50170898438,-3282.548828125,6.1519684791565),
		price = 3000000,
		supplieritem = shared.Storeitems.BlackMarketArms,
		selfdeliver = {model = `gburrito`, coord = vec4(490.02072143555,-3147.8359375,5.3958415985107,359.46929931641)},
		-- ped = function()
		-- 	local model = `a_m_m_eastsa_01`
		-- 	lib.requestModel(model)
		-- 	local ped = CreatePed(4, model, 591.57434082031,-3279.8911132813,5.0695571899414,95.828338623047, false,true)
		-- 	while not DoesEntityExist(ped) do Wait(1) end
		-- 	SetBlockingOfNonTemporaryEvents(ped,true)
		-- 	SetEntityInvincible(ped,true)
		-- 	FreezeEntityPosition(ped,true)
		-- end,
	},
}