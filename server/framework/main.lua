insertstr = 'INSERT INTO %s (%s) VALUES (%s)'
if shared.framework == 'ESX' then
	vehicletable = 'owned_vehicles'
	vehiclemod = 'vehicle'
	garage = 'Garage A'
	owner = 'owner'
	stored = 'stored'
	playertable = 'users'
	playeridentifier = 'identifier'
	playeraccounts = 'accounts'
	columns = '`plate`, `'..vehiclemod..'`, `'..owner..'`, `'..stored..'`, `job`, `type`'
	values = '?, ?, ?, ?, ?, ?'
elseif shared.framework == 'QBCORE' then
	vehicletable = 'player_vehicles'
	vehiclemod = 'mods'
	owner = 'license'
	stored = 'state'
	garage_id = 'garage'
	type_ = 'vehicle'
	playertable = 'players'
	playeridentifier = 'citizenid'
	playeraccounts = 'money'
	garage = 'pillboxgarage'
	columns = '`plate`, `'..vehiclemod..'`, `'..owner..'`, `'..stored..'`, `job`, `citizenid`, `hash`, `garage`, `vehicle`, `type`'
	values = '?, ?, ?, ?, ?, ?, ?, ?, ?, ?'
end

function GetPlayerFromIdentifier(identifier)
	self = {}
	if shared.framework == 'ESX' then
		local player = ESX.GetPlayerFromIdentifier(identifier)
		self.src = player and player.source
		return player
	else
		local getsrc = QBCore.Functions.GetSource(identifier)
		if not getsrc then return end
		self.src = getsrc
		return GetPlayerFromId(self.src)
	end
end

function GetPlayerFromId(src)
	self = {}
	self.src = src
	if shared.framework == 'ESX' then
		return ESX.GetPlayerFromId(self.src)
	elseif shared.framework == 'QBCORE' then
		xPlayer = QBCore.Functions.GetPlayer(self.src)
		if not xPlayer then return end
		if xPlayer.identifier == nil then
			xPlayer.identifier = xPlayer.PlayerData.license
		end
		if xPlayer.citizenid == nil then
			xPlayer.citizenid = xPlayer.PlayerData.citizenid
		end
		if xPlayer.job == nil then
			xPlayer.job = xPlayer.PlayerData.job
		end

		xPlayer.getMoney = function(value)
			return xPlayer.PlayerData.money['cash']
		end
		xPlayer.addMoney = function(value)
				QBCore.Functions.GetPlayer(self.src).Functions.AddMoney('cash',tonumber(value))
			return true
		end
		xPlayer.addAccountMoney = function(type, value)
			type = type:gsub('money', 'cash')
			QBCore.Functions.GetPlayer(self.src).Functions.AddMoney(type,tonumber(value))
			return true
		end
		xPlayer.removeMoney = function(value)
			QBCore.Functions.GetPlayer(self.src).Functions.RemoveMoney('cash',tonumber(value))
			return true
		end
		xPlayer.getAccount = function(type)
			if type == 'money' then
				type = 'cash'
			end
			return {money = xPlayer.PlayerData.money[type]}
		end
		xPlayer.removeAccountMoney = function(type,val)
			if type == 'money' then
				type = 'cash'
			end
			QBCore.Functions.GetPlayer(self.src).Functions.RemoveMoney(type,tonumber(val))
			return true
		end
		xPlayer.showNotification = function(msg)
			TriggerEvent('QBCore:Notify',self.src, msg)
			return true
		end
		xPlayer.addInventoryItem = function(item,amount,info,slot)
			local info = info
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.AddItem(item,amount,slot or false,info)
		end
		xPlayer.removeInventoryItem = function(item,amount,slot)
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.RemoveItem(item, amount, slot or false)
		end
		xPlayer.getInventoryItem = function(item)
			local gi = QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.GetItemByName(item) or {count = 0}
			gi.count = gi.amount or 0
			return gi
		end
		xPlayer.getGroup = function()
			return QBCore.Functions.IsOptin(self.src)
		end
		if xPlayer.source == nil then
			xPlayer.source = self.src
		end
		return xPlayer
	end
end

Inventory.AddItem = function(source,item,count,metadata,slot)
	if shared.inventory == 'ox_inventory' then
		return exports.ox_inventory:AddItem(source,item,count,metadata,slot)
	else
		if item == 'money' then
			local xPlayer = GetPlayerFromId(source)
			if not xPlayer then 
				if not tonumber(source) then
					source = source:gsub('Hotdog:','')
					source = source:gsub('Burger:','')
					source = source:gsub('Taco:','')
					GetPlayerFromIdentifier(source).addAccountMoney('money',count)
				end
				return
			end
			xPlayer.addAccountMoney('money',count)
		else
			local added = exports['qb-inventory']:AddItem(source, item, count, slot, metadata)
			if not added then
				if not slot then
					local stash = exports['qb-inventory']:GetStashItems(source)
					slot = exports['qb-inventory']:GetFirstSlotByItem(stash, item, metadata)
					if not slot then
						for i = 1, 50 do
							if not stash[i] then
								slot = i
								break
							end
						end
					end
				end
				exports['qb-inventory']:AddToStash(source, slot, otherslot, item, count, metadata)
			end
		end
	end
end

Inventory.RemoveItem = function(source,item,count,metadata,slot)
	if shared.inventory == 'ox_inventory' then
		return exports.ox_inventory:RemoveItem(source, item, count, metadata, slot)
	else
		if item == 'money' then
			local xPlayer = GetPlayerFromId(source)
			if not tonumber(source) then
				source = source:gsub('Hotdog:','')
				source = source:gsub('Burger:','')
				source = source:gsub('Taco:','')
				GetPlayerFromIdentifier(source).removeMoney('money',count)
			end
			xPlayer.removeMoney(count)
		else
			local removed = exports['qb-inventory']:RemoveItem(source, item, count, slot, metadata)
			if not removed then
				if not slot then
					local stash = exports['qb-inventory']:GetStashItems(source)
					slot = exports['qb-inventory']:GetFirstSlotByItem(stash, item, metadata)
					if not slot then
						for i = 1, 50 do
							if not stash[i] then
								slot = i
								break
							end
						end
					end
				end
				exports['qb-inventory']:RemoveFromStash(source, slot, item, count, metadata) 
			end
		end
	end
end
