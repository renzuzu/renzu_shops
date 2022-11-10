ESX,QBCORE = nil, nil
config = {}
config.framework = 'ESX' -- ESX || QBCORE
config.allowplayercreateitem = false -- if false only admin can create new items via /stores
config.target = false -- if true all lib zones for markers and oxlib textui will be disable.
if config.framework == 'ESX' then
	ESX = exports['es_extended']:getSharedObject()
elseif config.framework == 'QBCORE' then
	QBCore = exports['qb-core']:GetCoreObject()
end
Shops = {}
MultiCategory = function(blacklist,whitelist,...)
	local newtable = {}
	local i = 1
	local whitelisted = false
	for k,v in pairs(whitelist) do whitelisted = true end
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
	Shops = request('client/main')
	Shops.LoadJobShops = function()
		for k,zones in pairs(Shops.JobSpheres) do
			if zones then
				if not config.target and zones.remove then
					zones:remove()
				else
					exports.ox_target:removeZone(zones)
				end
			end
		end
		local jobshop = GlobalState.JobShop
		for k,shops in pairs(config.OwnedShops) do
			for k,shop in pairs(shops) do
				if jobshop[shop.label] == Shops.PlayerData.job?.name then
					if not config.target then
						Shops.temporalspheres[shop.label] = Shops.Add(shop.coord,'My Store '..shop.label,Shops.StoreOwner,false,shop)
						Shops.JobSpheres[Shops.PlayerData.job.name] = Shops.temporalspheres[shop.label]
					else
						local zone = Shops.addTarget(shop.coord,'My Store '..shop.label,Shops.StoreOwner,false,shop)
						Shops.JobSpheres[Shops.PlayerData.job.name] = zone
					end
				end
			end
		end
	end
	Shops.Playerloaded = function()
		if config.framework == 'ESX' then
			RegisterNetEvent('esx:playerLoaded', function(xPlayer)
				Shops.PlayerData = xPlayer
				Shops.LoadShops()
				Shops.LoadJobShops()
			end)
		elseif config.framework == 'QBCORE' then
			RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
				QBCore.Functions.GetPlayerData(function(p)
					Shops.PlayerData = p
					Shops.LoadShops()
					Shops.LoadJobShops()
					if PlayerData.job ~= nil then
						Shops.PlayerData.job.grade = Shops.PlayerData.job.grade.level
					end
					if PlayerData.identifier == nil then
						Shops.PlayerData.identifier = Shops.PlayerData.license
					end
				end)
			end)
		end
	end
	
	Shops.GetPlayerData = function()
		if config.framework == 'ESX' then
			return ESX.GetPlayerData()
		else
			local data = promise:new()
			QBCore.Functions.GetPlayerData(function(playerdata)
				data:resolve(playerdata)
			end)
			return Citizen.Await(data)
		end
	end
	
	Shops.SetJob = function()
		if config.framework == 'ESX' then
			RegisterNetEvent('esx:setJob', function(job)
				Shops.PlayerData.job = job
				Shops.LoadJobShops()
			end)
		elseif config.framework == 'QBCORE' then
			RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
				Shops.PlayerData.job = job
				Shops.PlayerData.job.grade = Shops.PlayerData.job.grade.level
				Shops.LoadJobShops()
			end)
		end
	end
	Shops.Playerloaded()
	Shops.SetJob()
	Shops.Handlers()
	Shops.StartUp()
	exports('Shops', function ()
		return Shops
	end)
	RegisterCommand('bubble', function(source,args)
		local Functions = exports.renzu_shops:Shops()
		Functions.CreateBubbleSpeechSync({id = GetPlayerServerId(PlayerId()), title = GetPlayerName(PlayerId()), message = args[1], bagname = 'player:', ms = 5000})
	end)
end
-- example:
-- local Shop = exports.renzu_shops:Shops()
-- Shop.StoreOwner({label = 'Ammunation #1'})
