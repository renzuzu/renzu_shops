local dbdata = {['financedata'] = {['columns'] = '`identifier`,`max`,`financed`',['values'] = '?,?,?'},['renzu_stores'] = {['columns'] = '`shop`,`owner`,`money`,`items`,`employee`,`cashier`,`customitems`,`job`',['values'] = '?,?,?,?,?,?,?,?'},['movableshops'] = {['columns'] = '`identifier`,`owner`,`money`,`items`,`plate`,`type`,`shopname`',['values'] = '?,?,?,?,?,?,?'},}

local db = setmetatable({},{
	__call = function(self)

		self.insert = function(name, data)
			local str = 'INSERT INTO %s (%s) VALUES(%s)'
			return MySQL.insert.await(str:format(name,dbdata[name].columns,dbdata[name].values),data)
		end

		self.update = function(name, column, where, update, data)
			local str = 'UPDATE %s SET %s = ? WHERE %s = ?'
			return MySQL.query(str:format(name,column,where),{data,update})
		end

		self.delete = function(name, where, update)
			local str = 'DELETE FROM %s WHERE %s = ?'
			return MySQL.query(str:format(name,where),{update})
		end

		self.save = function(data)
			Citizen.CreateThreadNow(function()
				for shopname,v in pairs(data) do
					local select = MySQL.query.await('SELECT * FROM `renzu_stores` WHERE `shop` = ?', {shopname})
					if select then
						for k,v in pairs(v) do
							if type(v) == 'table' then
								self.update('renzu_stores',k,'shop',shopname,json.encode(v))
							else
								self.update('renzu_stores',k,'shop',shopname,v)
							end
						end
					else
						self.insert('renzu_stores',{
							shopname,
							v.owner,
							json.encode(v['money'] or {}),
							json.encode(v['items'] or {}),
							json.encode(v['employee'] or {}),
							json.encode(v['cashier'] or {}),
							json.encode(v['customitems'] or {}),
							v['job'],
						})
					end
				end
			end)
		end
		return self
	end
})
local Sql = db()

local success, result = pcall(MySQL.scalar.await, 'SELECT 1 FROM renzu_stores')

if not success then
	MySQL.query([[CREATE TABLE `renzu_stores` (
		`id` int NOT NULL AUTO_INCREMENT KEY,
		`shop` varchar(60) DEFAULT NULL,
		`owner` varchar(64) DEFAULT NULL,
		`money` longtext DEFAULT NULL,
		`items` longtext DEFAULT NULL,
		`employee` longtext DEFAULT NULL,
		`cashier` longtext DEFAULT NULL,
		`customitems` longtext DEFAULT NULL,
		`job` varchar(64) DEFAULT NULL
	)]])
end
local success, result = pcall(MySQL.scalar.await, 'SELECT 1 FROM movableshops')

if not success then
	MySQL.query([[CREATE TABLE `movableshops` (
		`identifier` varchar(64) DEFAULT NULL,
		`owner` varchar(64) DEFAULT NULL,
		`money` longtext DEFAULT NULL,
		`items` longtext DEFAULT NULL,
		`plate` varchar(64) DEFAULT NULL,
		`type` varchar(64) DEFAULT NULL,
		`shopname` varchar(64) DEFAULT NULL,
		UNIQUE KEY `identifier` (`identifier`)
	)]])
end

local success, result = pcall(MySQL.scalar.await, 'SELECT 1 FROM financedata')

if not success then
	MySQL.query([[CREATE TABLE `financedata` (
		`identifier` varchar(64) DEFAULT NULL,
		`max` INT(64) DEFAULT NULL,
		`financed` longtext DEFAULT NULL,
		UNIQUE KEY `identifier` (`identifier`)
	)]])
end

local success, result = pcall(MySQL.scalar.await, 'ALTER TABLE `movableshops` MODIFY COLUMN `identifier` VARCHAR(100)')

local convert = function()
	if GetResourceKvpString('renzu_stores') then
		for k,v in pairs(json.decode(GetResourceKvpString('renzu_stores'))) do
			local columns = {}
			columns['shop'] = k
			local data = {}
			for k,v in pairs(v) do
				columns[k] = v
			end
			Sql.insert('renzu_stores',{
				columns['shop'],
				columns['owner'],
				json.encode(columns['money'] or {}),
				json.encode(columns['items'] or {}),
				json.encode(columns['employee'] or {}),
				json.encode(columns['cashier'] or {}),
				json.encode(columns['customitems'] or {}),
				columns['job'],
			})
		end
	end

	if GetResourceKvpString('movableshops') then
		for k,v in pairs(json.decode(GetResourceKvpString('movableshops'))) do
			local columns = {}
			columns['shopidentifier'] = k
			local data = {}
			for k,v in pairs(v) do
				columns[k] = v
			end
			Sql.insert('movableshops',{
				columns['shopidentifier'],
				columns['identifier'],
				json.encode(columns['money'] or {}),
				json.encode(columns['items'] or {}),
				columns['plate'],
				columns['type'],
				columns['shopname'],
			})
		end
	end
	if GetResourceKvpString('financedata') then
		for k,v in pairs(json.decode(GetResourceKvpString('financedata'))) do
			local columns = {}
			columns['identifier'] = k
			local data = {}
			for k,v in pairs(v) do
				columns[k] = v
			end
			Sql.insert('financedata',{
				columns['identifier'],
				tonumber(columns['max']),
				json.encode(columns['financed'] or {}),
			})
		end
	end
end
--DeleteResourceKvp('renzu_stores_convert')
if not GetResourceKvpString('renzu_stores_convert') then
	convert()
	SetResourceKvp('renzu_stores_convert', 'true')
end

local Stores = {}
for k,v in pairs(MySQL.query.await('SELECT * FROM renzu_stores', {  }) or {}) do
	Stores[v.shop] = {}
	for column,data in pairs(v) do
		if string.find(data, '{') then
			Stores[v.shop][column] = json.decode(data)
		elseif data == '[]' then
			Stores[v.shop][column] = {}
		else
			Stores[v.shop][column] = data
		end
	end
end

local Movable = {}
for k,v in pairs(MySQL.query.await('SELECT * FROM movableshops', {  }) or {}) do
	Movable[v.identifier] = {}
	for column,data in pairs(v) do
		if string.find(data, '{') then
			Movable[v.identifier][column] = json.decode(data)
		elseif data == '[]' then
			Movable[v.identifier][column] = {}
		else
			Movable[v.identifier][column] = data
		end
	end
end

local Financed = {}
for k,v in pairs(MySQL.query.await('SELECT * FROM financedata', {  }) or {}) do
	Financed[v.identifier] = {}
	for column,data in pairs(v) do
		if string.find(data, '{') then
			Financed[v.identifier][column] = json.decode(data)
		elseif data == '[]' then
			Financed[v.identifier][column] = {}
		else
			Financed[v.identifier][column] = data
		end
	end
end

for k,v in pairs(shared.OwnedShops) do
	local str = 'Stores_%s'
	for k,v in pairs(v) do
		GlobalState[str:format(v.label)] = nil
	end
end
AddStateBagChangeHandler("Stores", "global", function(bagName, key, value)
	Wait(0)
	if not value then return end
	for shop,data in pairs(value) do -- Split datas to dedicated bags to prevent byte size limits
		local str = 'Stores_%s'
		GlobalState[str:format(shop)] = data
	end
end)

GlobalState.Shipping = json.decode(GetResourceKvpString('shippingcompany') or '[]') or {}
GlobalState.Stores = Stores
GlobalState.MovableShops = Movable
GlobalState.FinanceData = Financed
GlobalState.JobShop = {}
return Sql