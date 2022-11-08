-- this the list of items can be used from item customisation when you click the image from shops.
Customise = {
	['cheese'] = {hunger = 100000, poison = true, customfunc = function() return print("THIS IS A FUNCTION") end },
	['lettuce'] = {hunger = 10000, melee = {duration = 300, amount = 0.1}},
	['hotsauce'] = {thirst = -10000, stress = -10000},
}

CustomiseLabel = {
	['hunger'] = 'Affects Hunger',
	['thirst'] = 'Affects Thirst',
	['stress'] = 'Affects Stress',
	['melee'] = 'Increase Physical Melee Attack'
}

Status = { -- registered any status name here
	['hunger'] = true,
	['thirst'] = true,
	['stress'] = true,
	--['poop'] = true -- <-- sample
}

-- TO USE THE EXPORTS BELOW. YOU NEED TO INSERT export variable in your items from data/items.lua in ox_inventory
-- SAMPLE FORMAT
-- ['burger'] = {
-- 	label = 'Burger',
-- 	weight = 0,
-- 	client = {
-- 		anim = 'eating',
-- 		prop = 'burger',
-- 		usetime = 2500,
-- 		notification = 'You ate a delicious burger',
-- 		export = 'renzu_shops.ItemUse'
-- 	},
-- },

exports('ItemUse', function(data,slot)
	exports.ox_inventory:useItem(data, function(data)
		if data then
			if data?.metadata?.customise then -- trigger effects from customise items
				for k,item in pairs(data.metadata.customise) do
					SetItemEffect(item)
				end
			end
			for effect,value in pairs(data?.metadata or {}) do -- find status effects from preconfigured item metadatas
				if Status[effect] then
					SetStatus({name = effect, value = value})
				end
			end
		end
	end)
end)

SetItemEffect = function(item)
	for k,v in pairs(Customise) do
		if k == item then
			print(item)
			Effect(v)
		end
	end
end

local cache = {}
-- Effects are samples only. you have to write whats you really desire on your own (ADVanced usage) or feel free to contribute improving this effects
Effect = function(data)
	for effect ,value in pairs(data) do
		if type(value) == 'table' then
			-- example table values
			if effect == 'melee' then
				if not cache[effect] then -- so it wont stack
					cache[effect] = GetPlayerMeleeWeaponDamageModifier(PlayerId())
				end
				SetPlayerMeleeWeaponDamageModifier(PlayerId(),cache[effect]+value.amount)
			end

			if effect == 'stamina' then
				-- effects here
			end
		elseif type(value) == 'function' then
			value()
		elseif Status[effect] then
			SetStatus({name = effect, value = value})
		else
			-- custom effects here
			-- example
			if effect == 'poison' then -- @format metadata.customise -> { hunger = 100, poison = true }
				SetEntityHealth(PlayerPedId(),0)
				print(GetEntityHealth(PlayerPedId()))
			end
		end
	end
end

SetStatus = function(data)
	if data.value > 0 then TriggerEvent('esx_status:add', data.name, data.value) else TriggerEvent('esx_status:remove', data.name, -data.value) end
end