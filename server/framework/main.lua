if shared.framework == 'ESX' then
	vehicletable = 'owned_vehicles'
	vehiclemod = 'vehicle'
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
		Player = QBCore.Functions.GetPlayer(self.src)
		if not Player then return end
		if Player.identifier == nil then
			Player.identifier = Player.PlayerData.license
		end
		if Player.citizenid == nil then
			Player.citizenid = Player.PlayerData.citizenid
		end
		if Player.job == nil then
			Player.job = Player.PlayerData.job
		end

		Player.getMoney = function(value)
			return Player.PlayerData.money['cash']
		end
		Player.addMoney = function(value)
				QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.AddMoney('cash',tonumber(value))
			return true
		end
		Player.addAccountMoney = function(type, value)
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.AddMoney(type,tonumber(value))
			return true
		end
		Player.removeMoney = function(value)
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.RemoveMoney('cash',tonumber(value))
			return true
		end
		Player.getAccount = function(type)
			if type == 'money' then
				type = 'cash'
			end
			return {money = Player.PlayerData.money[type]}
		end
		Player.removeAccountMoney = function(type,val)
			if type == 'money' then
				type = 'cash'
			end
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.RemoveMoney(type,tonumber(val))
			return true
		end
		Player.showNotification = function(msg)
			TriggerEvent('QBCore:Notify',self.src, msg)
			return true
		end
		Player.addInventoryItem = function(item,amount,info,slot)
			local info = info
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.AddItem(item,amount,slot or false,info)
		end
		Player.removeInventoryItem = function(item,amount,slot)
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.RemoveItem(item, amount, slot or false)
		end
		Player.getInventoryItem = function(item)
			local gi = QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.GetItemByName(item) or {count = 0}
			gi.count = gi.amount or 0
			return gi
		end
		Player.getGroup = function()
			return QBCore.Functions.IsOptin(self.src)
		end
		if Player.source == nil then
			Player.source = self.src
		end
		return Player
	end
end

Inventory.AddItem = function(source,item,count,metadata,slot)
	if shared.inventory == 'ox_inventory' then
		return exports.ox_inventory:AddItem(source,item,count,metadata,slot)
	else
		if item == 'money' then
			local Player = GetPlayerFromId(source)

			if not Player then 
				if not tonumber(source) then
					source = source:gsub('Hotdog:','')
					source = source:gsub('Burger:','')
					source = source:gsub('Taco:','')
					GetPlayerFromIdentifier(source).addAccountMoney('money',count)
				end
				return
			end
			Player.addMoney(count)
		else
			local added = exports['qb-inventory']:AddItem(source, item, count, slot, metadata)
			if not added then
				if not slot then
					local stash = exports['qb-inventory']:GetStashItems(source)
					slot = exports['qb-inventory']:GetFirstSlotByItem(stash, item, info)
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
			local Player = GetPlayerFromId(source)
			if not tonumber(source) then
				source = source:gsub('Hotdog:','')
				source = source:gsub('Burger:','')
				source = source:gsub('Taco:','')
				GetPlayerFromIdentifier(source).removeMoney('money',count)
			end
			Player.removeMoney(count)
		else
			local removed = exports['qb-inventory']:RemoveItem(source, item, count, slot, metadata) 
			if not removed then
				if not slot then
					local stash = exports['qb-inventory']:GetStashItems(source)
					slot = exports['qb-inventory']:GetFirstSlotByItem(stash, item, info)
				end
				exports['qb-inventory']:RemoveFromStash(source, slot, item, count, metadata) 
			end
		end
	end
end