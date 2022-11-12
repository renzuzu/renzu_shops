ESX,QBCORE = nil, nil
shared = {}
shared.framework = 'ESX' -- ESX || QBCORE
-- use ox_inventory Shops UI (experimental feature) only with my forked ox_inventory REPO https://github.com/renzuzu/ox_inventory
shared.oxShops = false -- if true this resource will use ox_inventory Shops UI instead of built in UI
shared.allowplayercreateitem = false -- if false only admin can create new items via /stores
shared.target = false -- if true all lib zones for markers and oxlib textui will be disable.
shared.defaultStock = {
	General = 100, 
	Ammunation = 20,
	VehicleShop = 10,
	BlackMarketArms = 20,
} -- default to all items in store when newly purchased

shared.VehicleKeys = function(plate,source) -- vehicle keys (replace the exports with your vehicle keys script) (server export)
	-- first parameter expected is plate
	local sendvehiclekeys
	func = function()
		sendvehiclekeys = exports.renzu_garage.GiveVehicleKey
	end
	if pcall(func, result or false) then
		return sendvehiclekeys(nil,plate,source)
	end
end

if shared.framework == 'ESX' then
	ESX = exports['es_extended']:getSharedObject()
elseif shared.framework == 'QBCORE' then
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
shared.Storeitems = request('config/storeitems')
shared.Shops = request('config/defaultshops')
shared.OwnedShops = request('config/ownedshops/init')
shared.MovableShops = request('config/movableshop')
request('config/shipping')
-- insert additional datas
for k,v in pairs(Components) do
	table.insert(shared.Storeitems.Ammunation,v)
	table.insert(shared.Storeitems.BlackMarketArms,v)
end

if not IsDuplicityVersion() then
	Shops = setmetatable(Shops, {
		__call = function(self)
			self = request('client/main')
			self.LoadJobShops = function()
				for k,zones in pairs(self.JobSpheres) do
					if zones then
						if not shared.target and zones.remove then
							zones:remove()
						else
							exports.ox_target:removeZone(zones)
						end
					end
				end
				local jobshop = GlobalState.JobShop
				for k,shops in pairs(shared.OwnedShops) do
					for k,shop in pairs(shops) do
						if jobshop[shop.label] == self.PlayerData.job?.name then
							if not shared.target then
								self.temporalspheres[shop.label] = self.Add(shop.coord,'My Store '..shop.label,self.StoreOwner,false,shop)
								self.JobSpheres[self.PlayerData.job?.name] = self.temporalspheres[shop.label]
							else
								local zone = self.addTarget(shop.coord,'My Store '..shop.label,self.StoreOwner,false,shop)
								self.JobSpheres[self.PlayerData.job?.name] = zone
							end
						end
					end
				end
			end
			self.Playerloaded = function()
				if shared.framework == 'ESX' then
					RegisterNetEvent('esx:playerLoaded', function(xPlayer)
						self.PlayerData = xPlayer
						self.LoadShops()
						self.LoadJobShops()
					end)
				elseif shared.framework == 'QBCORE' then
					RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
						QBCore.Functions.GetPlayerData(function(p)
							self.PlayerData = p
							self.LoadShops()
							self.LoadJobShops()
							if PlayerData.job ~= nil then
								self.PlayerData.job.grade = self.PlayerData.job.grade.level
							end
							if PlayerData.identifier == nil then
								self.PlayerData.identifier = self.PlayerData.license
							end
						end)
					end)
				end
			end
			
			self.GetPlayerData = function()
				if shared.framework == 'ESX' then
					return ESX.GetPlayerData()
				else
					local data = promise:new()
					QBCore.Functions.GetPlayerData(function(playerdata)
						data:resolve(playerdata)
					end)
					return Citizen.Await(data)
				end
			end
			
			self.SetJob = function()
				if shared.framework == 'ESX' then
					RegisterNetEvent('esx:setJob', function(job)
						self.PlayerData.job = job
						self.LoadJobShops()
					end)
				elseif shared.framework == 'QBCORE' then
					RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
						self.PlayerData.job = job
						self.PlayerData.job.grade = self.PlayerData.job.grade.level
						self.LoadJobShops()
					end)
				end
			end
			self.Playerloaded()
			self.SetJob()
			self.Handlers()
			self.StartUp()
			exports('Shops', function ()
				return self
			end)
			RegisterCommand('bubble', function(source,args)
				local Functions = exports.renzu_shops:Shops()
				Functions.CreateBubbleSpeechSync({id = GetPlayerServerId(PlayerId()), title = GetPlayerName(PlayerId()), message = args[1], bagname = 'player:', ms = 5000})
			end)
		end
	})
	return Shops()
end
-- example:
-- local Shop = exports.renzu_shops:Shops()
-- Shop.StoreOwner({label = 'Ammunation #1'})
