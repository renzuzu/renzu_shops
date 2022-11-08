config = {}
config.target = false -- if true all lib zones for markers and oxlib textui will be disable.
ESX = exports['es_extended']:getSharedObject()
Shops = {}
MultiCategory = function(blacklist,whitelist,...)
	local newtable = {}
	local i = 1
	local whitelisted = false
	for k,v in pairs(whitelist) do print(k,v) whitelisted = true end
	if not whitelisted then
		local t = {...}
		for k,v in pairs(t) do
			if type(v) == 'table' then
				for k,v in pairs(v) do
					if not blacklist[v.type] then
						newtable[i] = v
						i += 1
					end
				end
			end
		end
	else
		for k,v in pairs(AllVehicles) do
			if whitelist[v.type] then
				newtable[i] = v
				i += 1
			end
		end
	end
	return newtable
end

function request(file)
	local name = ('%s.lua'):format(file)
	local content = LoadResourceFile(GetCurrentResourceName(),name)
	local f, err = load(content)
	return f()
end

-- do not edit
config.Storeitems = request('config/storeitems')
config.Shops = request('config/defaultshops')
config.OwnedShops = request('config/ownedshops/init')
config.MovableShops = request('config/movableshop')
request('config/shipping')
-- insert additional datas
for k,v in pairs(Components) do
	table.insert(config.Storeitems.Ammunation,v)
	table.insert(config.Storeitems.BlackMarketArms,v)
end

if not IsDuplicityVersion() then
	Shops.init = function()
		return request('client/main')
	end
	local Shop = Shops.init()
	Shop.StartUp()
	Shop.Handlers()
	exports('Shops', Shops.init)
	RegisterCommand('bubble', function(source,args)
		local Functions = exports.renzu_shops:Shops()
		Functions.CreateBubbleSpeechSync({id = GetPlayerServerId(PlayerId()), title = GetPlayerName(PlayerId()), message = args[1], bagname = 'player:', ms = 5000})
	end)
end
-- example:
-- local Shop = exports.renzu_shops:Shops()
-- Shop.StoreOwner({label = 'Ammunation #1'})
