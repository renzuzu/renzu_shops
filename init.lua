ESX,QBCORE = nil, nil
shared = {}
shared.lang = 'en' -- look config/locales/%s.lua eg. 'en' for en.lua | to create new language, create a new file ex. es.lua
-- use ox_inventory Shops UI (experimental feature) only with my forked ox_inventory REPO https://github.com/renzuzu/ox_inventory
shared.oxShops = false -- if true this resource will use ox_inventory Shops UI instead of built in UI
shared.allowplayercreateitem = false -- if false only admin can create new items via /stores
shared.target = false -- if true all lib zones for markers and oxlib textui will be disable.
shared.FinanceMinimum = 500000 -- minimum amount for financing to be enable
shared.FinanceDownPayment = 20 -- 20%. this is the amount of minimum initial payment
shared.FinanceInterest = 10 -- 10%
shared.FinanceMaxDays = 30
shared.MaxDebt = 1000000 -- max amount of total debt from player in able to finance
shared.defaultStock = {
	General = 100, 
	Ammunation = 20,
	VehicleShop = 10,
	BlackMarketArms = 20,
} -- default to all items in store when newly purchased
shared.SendtoBank = false -- if true owner will receive money to owned bank account
shared.VehicleKeysType = {
	['export'] = false, -- if false it will use trigger events
	['client'] = true, -- if false it will use server event or server exports
}
shared.VehicleKeys = function(plate,source) -- vehicle keys
	-- first parameter expected is plate
	local sendvehiclekeys
	if IsDuplicityVersion() then
		if shared.VehicleKeysType['export'] then -- server export edit this if your using server exports vehicle keys
			func = function()
				sendvehiclekeys = exports.renzu_garage.GiveVehicleKey -- replace this
			end
			if pcall(func, result or false) then
				return sendvehiclekeys(nil,plate,source)
			end
		elseif shared.VehicleKeysType['client'] and shared.VehicleKeysType['export'] then -- do not edit this condition
			TriggerClientEvent('renzu_shops:Vehiclekeys', source, plate)

		elseif shared.VehicleKeysType['client'] then -- client events from server   edit this if your using client events vehicle keys
			-- Server Events Keys
			TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate) -- this is non existing and example only

		else -- server events from server edit this
			-- Server Events Keys
			-- ex TriggerEvent('GiveKeys', plate, source) -- this is non existing and example only

		end
	elseif not IsDuplicityVersion() then -- client exports edit this if your using exports in client
		if shared.VehicleKeysType['export'] then
			func = function()
				sendvehiclekeys = exports.renzu_garage.GiveVehicleKey -- replace this
			end
			if pcall(func, result or false) then
				return sendvehiclekeys(nil,plate)
			end
		else -- if triggered using client
			TriggerEvent('vehiclekeys:client:SetOwner', plate) -- this is non existing and example only
		end
	end
end

shared.framework = 'QBCORE' -- ESX || QBCORE
shared.inventory = 'qb-inventory' -- 'ox_inventory' or 'qb-inventory' https://github.com/renzuzu/qb-inventory

if GetResourceState('es_extended') == 'started' then
	shared.framework = 'ESX'
	ESX = exports['es_extended']:getSharedObject()
elseif GetResourceState('qb-core') == 'started' then
	shared.framework = 'QBCORE'
	QBCore = exports['qb-core']:GetCoreObject()
end

if GetResourceState('ox_inventory') == 'started' then
	shared.inventory = 'ox_inventory'
elseif GetResourceState('qb-inventory') == 'started' then
	shared.inventory = 'qb-inventory'
end

MultiCategory = function(blacklist,whitelist,data,...)
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
		for k,v in pairs(data) do
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
shared.locales = request('config/locales/'..shared.lang)
shared.playerbooth = request('config/stalls')
request('config/shipping')
-- insert additional datas
if shared.inventory == 'ox_inventory' then
	for k,v in pairs(Components) do
		table.insert(shared.Storeitems.Ammunation,v)
		table.insert(shared.Storeitems.BlackMarketArms,v)
	end
elseif shared.inventory == 'qb-inventory' then
	local weapons = {}
	Components = {}
	Citizen.CreateThreadNow(function()
		Wait(1000)
		local weaponshared = QBCore.Shared.Weapons
		for k,v in pairs(weaponshared) do
			Wait(0)
			local data = exports['qb-weapons']:getConfigWeaponAttachments(v.name:upper()) -- if there is a way to fetch single all the datas of weapon atachment from qbweapons it will be more opt
			if data then
				for k,weapon in pairs(data) do
					if not Components[weapon.item] then Components[weapon.item] = {} end
					Components[weapon.item] = {
						name = weapon.item,
						label = weaponshared[weapon.item] and weaponshared[weapon.item].label or k,
						type = weapon.type,
						price = 1500,
						category = 'attachments',
						client = { component = {weapon.component}}
					}
				end
			end
		end
		for k,v in pairs(Components) do
			table.insert(shared.Storeitems.Ammunation,v)
			table.insert(shared.Storeitems.BlackMarketArms,v)
		end
	end)
end

Utils = {}
if not IsDuplicityVersion() then
	Utils.CreateMenu = function(data)
		lib.registerContext({
			id = data.id,
			title = data.title,
			onExit = function()
				--data.OnExit()
			end,
			options = data.options
		})
		lib.showContext(data.id)
	end
	Utils.Proccesed = function(data)
		lib.progressBar({
			duration = data.duration,
			label = data.label,
			useWhileDead = false,
			canCancel = false,
			anim = {
				dict = data.dict,
				clip = data.clip
			},
			disable = {
				car = true,
			}
		})
		local callback = lib.callback.await('renzu_shops:proccessed',100, data)
		if not callback then
			lib.notify({
				title = 'Not Enough Ingredients',
				type = 'error'
			})
		end
	end
	self.ImagesPath = function(item)
		local url = ''
		if shared.inventory == 'ox_inventory' then
			if item then
				url = 'https://cfx-nui-ox_inventory/web/images/'..item..'.png'
			else
				url = 'https://cfx-nui-ox_inventory/web/images/'
			end
			return url
		else
			if item then
				url = 'https://cfx-nui-qb-inventory/html/images/'..item:lower()..'.png'
			else
				url = 'https://cfx-nui-qb-inventory/html/images/'
			end
			return url
		end
	end
	self.LoadJobShops = function()
		for k,zones in pairs(self.JobSpheres) do
			if zones then
				if not shared.target and zones.remove then
					zones:remove()
				else
					rzone = function()
						return exports.ox_target:removeZone(zones)
					end
					if pcall(rzone,ret or false) then end
				end
			end
		end
		local jobshop = GlobalState.JobShop
		for k,shops in pairs(shared.OwnedShops) do
			for k,shop in pairs(shops) do
				if self.PlayerData and self.PlayerData.job and jobshop[shop.label] == self.PlayerData.job?.name then
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
				self.LoadDefaultShops()

			end)
		elseif shared.framework == 'QBCORE' then
			RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
				Wait(1500)
				self.PlayerData = QBCore.Functions.GetPlayerData()
				if self.PlayerData.job ~= nil then
					self.PlayerData.job.grade = self.PlayerData.job.grade.level
				end
				if self.PlayerData.identifier == nil then
					self.PlayerData.identifier = self.PlayerData.license
				end
				self.LoadShops()
				self.LoadJobShops()
				self.LoadDefaultShops()

			end)
		end
	end

	self.GetPlayerData = function()
		if shared.framework == 'ESX' then
			return ESX.GetPlayerData()
		else
			local Player = QBCore.Functions.GetPlayerData()
			if Player.job ~= nil then
				Player.job.grade = Player.job.grade.level
			end
			if Player.identifier == nil then
				Player.identifier = Player.license
			end
			return Player
		end
	end

	self.SetJob = function()
		if shared.framework == 'ESX' then
			RegisterNetEvent('esx:setJob', function(job)
				self.PlayerData.job = job
				self.LoadDefaultShops()
				self.LoadJobShops()
				self.LoadShops()
			end)
		elseif shared.framework == 'QBCORE' then
			RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
				self.PlayerData.job = job
				self.PlayerData.job.grade = self.PlayerData.job.grade.level
				self.LoadDefaultShops()
				self.LoadJobShops()
				self.LoadShops()
			end)
		end
	end

	self.getInventoryItems = function(name)
		if shared.inventory == 'ox_inventory' then
			return exports.ox_inventory:Search('count', name)
		elseif shared.inventory == 'qb-inventory' then
			local count = 0
			local PlayerData = QBCore.Functions.GetPlayerData()
			for _, item in pairs(PlayerData.items) do
				if name == item.name then
					count += 1
				end
			end
			return count
		end
	end

	-- RUN RESOURCE
	self.Playerloaded()
	self.SetJob()
	self.Handlers()
	self.StartUp()

	-- EXPORTS FOR ALL FUNCTION
	exports('Shops', function ()
		return self
	end)

	-- SHITY 3dME
	RegisterCommand('bubble', function(source,args)
		local Functions = exports.renzu_shops:Shops()
		Functions.CreateBubbleSpeechSync({id = GetPlayerServerId(PlayerId()), title = GetPlayerName(PlayerId()), message = args[1], bagname = 'player:', ms = 5000})
	end)
end