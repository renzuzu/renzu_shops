function Initialized()
	if config.framework == 'ESX' then
		vehicletable = 'owned_vehicles'
		vehiclemod = 'vehicle'
	elseif config.framework == 'QBCORE' then
		vehicletable = 'player_vehicles '
		vehiclemod = 'mods'
		owner = 'license'
		stored = 'state'
		garage_id = 'garage'
		type_ = 'vehicle'
	end
end

function GetPlayerFromId(src)
	self = {}
	self.src = src
	if config.framework == 'ESX' then
		return ESX.GetPlayerFromId(self.src)
	elseif config.framework == 'QBCORE' then
		selfcore = {}
		selfcore.data = QBCore.Functions.GetPlayer(self.src)
		if selfcore.data.identifier == nil then
			selfcore.data.identifier = selfcore.data.PlayerData.license
		end
		if selfcore.data.citizenid == nil then
			selfcore.data.citizenid = selfcore.data.PlayerData.citizenid
		end
		if selfcore.data.job == nil then
			selfcore.data.job = selfcore.data.PlayerData.job
		end

		selfcore.data.getMoney = function(value)
			return selfcore.data.PlayerData.money['cash']
		end
		selfcore.data.addMoney = function(value)
				QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.AddMoney('cash',tonumber(value))
			return true
		end
		selfcore.data.removeMoney = function(value)
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.RemoveMoney('cash',tonumber(value))
			return true
		end
		selfcore.data.getAccount = function(type)
			if type == 'money' then
				type = 'cash'
			end
			return {money = selfcore.data.PlayerData.money[type]}
		end
		selfcore.data.removeAccountMoney = function(type,val)
			if type == 'money' then
				type = 'cash'
			end
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.RemoveMoney(type,tonumber(val))
			return true
		end
		selfcore.data.showNotification = function(msg)
			TriggerEvent('QBCore:Notify',self.src, msg)
			return true
		end
		selfcore.data.addInventoryItem = function(item,amount,info,slot)
			local info = info
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.AddItem(item,amount,slot or false,info)
		end
		selfcore.data.removeInventoryItem = function(item,amount,slot)
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.RemoveItem(item, amount, slot or false)
		end
		selfcore.data.getInventoryItem = function(item)
			local gi = QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.GetItemByName(item) or {count = 0}
			gi.count = gi.amount or 0
			return gi
		end
		selfcore.data.getGroup = function()
			return QBCore.Functions.IsOptin(self.src)
		end
		if selfcore.data.source == nil then
			selfcore.data.source = self.src
		end
		return selfcore.data
	end
end