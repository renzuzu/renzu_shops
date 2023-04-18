Inventory = setmetatable({},{})
local Items = {}
local purchaseorders = {}
sql = {}

local canregister = false

if not lib then return print('^1 ox_lib is '..GetResourceState('ox_lib')..' - This Resource will not work without ox_lib https://github.com/overextended/ox_lib ^0') end
if GetResourceState('oxmysql') ~= 'started' then return print('^1 oxmysql is '..GetResourceState('oxmysql')..' - This Resource will not work without oxmysql https://github.com/overextended/oxmysql ^0') end
local checkox = function()
    _ = exports.ox_inventory.RegisterSingleShop
end

CreateThread(function()
	Wait(1000)
	sql = request('server/db/sql')
	if pcall(checkox) then canregister = true end
	request('server/framework/main')
	-- shared.ox_Shops = true . try ox_inventory single create shop
	-- this logic will only work on my forked ox_inventory https://github.com/renzuzu/ox_inventory
	if shared.oxShops and canregister then -- replace datas from default and ignore if shops is not owned
		local stores = GlobalState.Stores
		for shopname,shops in pairs(shared.Shops) do
			if shopname ~= 'VehicleShop' then
				for index,shop in pairs(shared.OwnedShops[shopname] or {}) do
					local items = {}
					local storeitems = stores[shop.label] and stores[shop.label].items
					for k,v in pairs(shop.supplieritem) do
						local name = v.metadata and v.metadata.name or v.name
						v.currency = shop.moneytype
						if storeitems then
							v.count = storeitems and storeitems['custom'] and storeitems['custom'][name] and storeitems['custom'][name].stock 
							or storeitems and storeitems['normal'] and storeitems['normal'][name] and storeitems['normal'][name].stock or not storeitems and nil
							v.count = tonumber(v.count) or 0
						elseif not storeitems then 
							v.count = nil 
						end
						table.insert(items,v)
					end
					exports.ox_inventory:RegisterSingleShop(shopname, {
						name = shopname, 
						inventory = items,
						coord = shops.locations[index]
					}, index,false,true)
				end
			end
		end
	elseif shared.inventory == 'ox_inventory' then -- if above condition is not possible , we will override ox_inventory shops
		if GetResourceState('ox_inventory') ~= 'started' then print('^1ox_inventory is not started or this resource started before ox_inventory^0') StopResource('renzu_shops') end
		for k,v in pairs(shared.Shops) do -- overide default ox inventory shops. temporary logic
			exports.ox_inventory:RegisterShop(k, {
				name = k, 
				inventory = {
					{name = 'burger', price = 999}
				}, 
				locations = {
					vec3(9999.0,9999.0,9999.0),
				}
			})
		end
	end
	local items = Inventory.GetItems()
	for k,v in pairs(items) do
		Items[v.name] = v.label
	end
	local jobshop = {}
	for k,v in pairs(GlobalState.Stores) do
		if v.job then
			jobshop[k] = v.job
		end
	end
	GlobalState.JobShop = jobshop
	for k,v in pairs(shared.OwnedShops) do
		for k,v in pairs(v) do
			if v.stash then
				if shared.inventory == 'ox_inventory' then
					exports.ox_inventory:RegisterStash(v.label..'_storage', 'Storage', 80, 200000, false)
				elseif shared.inventory == 'qb-inventory' then
					exports['qb-inventory']:RegisterStash(v.label..'_storage')
				end
			end
		end
	end
	TryInstallItems()
	Citizen.CreateThreadNow(function()
		local success, result = pcall(MySQL.scalar.await,'SELECT `job` FROM `'..vehicletable..'`') -- check if job column is exist
		if not success then
			SqlFunc('oxmysql','execute','ALTER TABLE `'..vehicletable..'` ADD COLUMN `job` VARCHAR(32) NULL') -- add job column
		end
		local success, result = pcall(MySQL.scalar.await,'SELECT `type` FROM `'..vehicletable..'`') -- check if job column is exist
		if not success then
			SqlFunc('oxmysql','execute','ALTER TABLE `'..vehicletable..'` ADD COLUMN `type` VARCHAR(32) NULL') -- add job column
		end
	end)
end)

Inventory.SearchItems = function(source, method, item)
	if shared.inventory == 'ox_inventory' then
		return exports.ox_inventory:Search(source, method, item)
	else
		local Player = QBCore.Functions.GetPlayer(source)
		local items = {}
		if item == 'money' then
			return Player.PlayerData.money['cash']
		end
		if not Player then
			items = exports['qb-inventory']:GetStashItems(source)
			if not items then return {} end
		else
			items = Player.PlayerData.items
		end
		local count = 0
		if method == 'count' then
			for k,v in pairs(items) do
				if item:lower() == v.name:lower() then
					count += v.amount
				end
			end
			return count
		else
			local data = {}
			for k,v in pairs(items) do
				if item:lower() == v.name:lower() then
					v.count = v.amount
					v.metadata = v.info
					v.slot = k
					data[k] = v
				end
			end
			return data
		end
	end
end

Inventory.GetItems = function()
	if GetResourceState('ox_inventory') ~= 'started' then
		return QBCore.Shared.Items
	else
		return exports.ox_inventory:Items()
	end
end

getShopDataByLabel = function(id)
	local stores = GlobalState.Stores
	local shop = false
	for name,shops in pairs(shared.OwnedShops) do
		for k,v in pairs(shops) do
			if v.label == id then
				return name,k,v
			end
		end
	end
	return false
end

exports('getShopDataByLabel', getShopDataByLabel)

GetShopItem = function(storeid,type,item)
	local stores = GlobalState.Stores
	local shop = false
	for name,shops in pairs(stores) do
		if name == storeid then
			for k,v in pairs(shops.items[type]) do
				if k == item then
					return v
				end
			end
		end
	end
	return false
end

exports('GetShopItem', GetShopItem)

isStoreOwned = function(store,index)
	local stores = GlobalState.Stores
	local shop = false
	local shoptype = nil
	for type,v in pairs(shared.OwnedShops) do
		if store == type then
			for k,v in pairs(v) do
				if index == k and stores[v.label] then
					shop = v.label
					shoptype = type
					break
				end
			end
		end
	end
	return shop, shop and stores[shop], shoptype
end

exports('isStoreOwned', isStoreOwned)

isMovableShop = function(type)
	return shared.MovableShops[type] or false
end

exports('isMovableShop', isMovableShop)

CheckItemData = function(data)
	local found = false
	for k,v in pairs(shared.Storeitems[data.shop]) do
		local name = v.metadata and v.metadata.name or v.name
		if data.item == name then
			found = true
			return v.price
		end
	end
	if not found then -- try vehicles
		for k,v in pairs(AllVehicles) do
			if data.item == v.name then
				price = v.price
				found = true
				return price
			end
		end
	end
	return false
end

if not shared.oxShops and shared.inventory == 'ox_inventory' then
	lib.callback.register('ox_inventory:openShop', function(source, data)
		TriggerClientEvent('renzu_shop:OpenShops',source, {type = data.type, id = data.id})
		SetTimeout(1,function()
			TriggerClientEvent('ox_inventory:closeInventory', source) -- temporary logic. this will avoid having error notification thrown by ox_inventory due to distance checks
		end)
	end)
end

if shared.inventory == 'ox_inventory' then
	exports.ox_inventory:registerHook('buyItem', function(payload)
		if not shared.oxShops then return end
		local data = payload
		local conf = shared.OwnedShops[data.ShopName]
		local stores = GlobalState.Stores
		data.ShopIndex = tonumber(data.ShopIndex)
		if conf then
			local store = conf[data.ShopIndex] and conf[data.ShopIndex].label
			local name = data.metadata and data.metadata.name or data.item
			if stores[store] then
				RemoveStockFromStore({shop = data.ShopName, metadata = data.metadata, index = data.ShopIndex, item = data.item, amount = tonumber(data.count), price = data.price, money = data.currency})
			end
		end
	end)
end

ModifyFromBankOffline = function(id,amount,minus,type)
	if type == nil then type = 'bank' end
	local result = SqlFunc('oxmysql','fetchAll','SELECT '..playeraccounts..' FROM '..playertable..' WHERE '..playeridentifier..' = ?', { id })
	local accounts = json.decode(result[1][playeraccounts])
	if not minus then
		accounts[type] += amount
	else
		accounts[type] -= amount
	end
	SqlFunc('oxmysql','execute','UPDATE '..playertable..' SET '..playeraccounts..' = ? WHERE '..playeridentifier..' = ?', {json.encode(accounts), id})
end

GetMoneyFromBankOffline = function(id)
	local result = SqlFunc('oxmysql','fetchAll','SELECT '..playeraccounts..' FROM '..playertable..' WHERE '..playeridentifier..' = ?', { id })
	if not result[1] then return end
	local accounts = json.decode(result[1][playeraccounts])
	return accounts.bank
end

SendMoneytoStoreAccount = function(identifier,money,plus)
	local owner = GetPlayerFromIdentifier(identifier)
	if owner then
		owner.addAccountMoney('bank',money)
	else
		ModifyFromBankOffline(identifier, money)
	end
end

RemoveStockFromStore = function(data)
	local stores = GlobalState.Stores
	local success = false
	for k,v in pairs(shared.OwnedShops) do
		if k == data.shop then
			for k,v in pairs(v) do
				if data.index == k and stores[v.label] then
					itemtype = data.metadata and data.metadata.name and 'custom' or 'normal'
					itemname = data.metadata and data.metadata.name or data.item
					data.item = itemname
					if stores[v.label].items[itemtype][itemname] == nil then stores[v.label].items[itemtype][itemname] = {} end
					if stores[v.label].items[itemtype][itemname].stock and tonumber(stores[v.label].items[itemtype][itemname].stock) >= data.amount then
						stores[v.label].items[itemtype][itemname].stock = tonumber(stores[v.label].items[itemtype][itemname].stock) - data.amount
						sql.update('renzu_stores','items','shop',v.label,json.encode(stores[v.label].items))
						local price = not data.originalprice and stores[v.label].items[itemtype][itemname].price and tonumber(stores[v.label].items[itemtype][itemname].price) or CheckItemData(data)
						if price then
							if shared.SendtoBank and data.money == 'bank' then
								-- todo
								-- exports.bankingresource:SendToBank(source,money)
								local receive = (tonumber(price) * data.amount) * 0.95 -- 5% fee
								SendMoneytoStoreAccount(stores[v.label].owner,receive)
							else
								if v.cashier then -- if cashier is enable store money to cashier
									if not stores[v.label].cashier then stores[v.label].cashier = {} end
									data.money = data.money:gsub('bank', 'money')
									if stores[v.label].cashier[data.money] == nil then stores[v.label].cashier[data.money] = 0 end
									stores[v.label].cashier[data.money] = tonumber(stores[v.label].cashier[data.money]) + (tonumber(price) * data.amount)
									sql.update('renzu_stores','cashier','shop',v.label,json.encode(stores[v.label].cashier))
								else
									data.money = data.money:gsub('bank', 'money')
									data.money = data.money:gsub('policecredit', 'money')
									stores[v.label].money[data.money] = tonumber(stores[v.label].money[data.money]) + (tonumber(price) * data.amount)
									sql.update('renzu_stores','money','shop',v.label,json.encode(stores[v.label].money))
								end
							end
						end
						success = true
					end
					break
				end
			end
		end
	end
	GlobalState.Stores = stores
	return success
end

exports('RemoveStockFromStore', RemoveStockFromStore)

RemoveStockFromStash = function(data)
	local stash = {}
	if not data.booth then
		local shopdata = shared.MovableShops[data.type].menu
		local items = {}
		for category,v in pairs(shopdata) do
			for k,v in pairs(v) do
				table.insert(items, {name = v.name, price = v.price, metadata = v.metadata})
			end
		end
		data.items = items
		stash = GetStashData(data)
	else
		local items = GetInventoryData(data.identifier)
		for k,v in pairs(items) do
			if not stash[v.metadata and v.metadata.name or v.name] then stash[v.metadata and v.metadata.name or v.name] = 0 end
			stash[v.metadata and v.metadata.name or v.name] += v.count
		end
	end
	if stash[data.metadata and data.metadata.name or data.item] >= data.amount then
		if not data.booth then
			Inventory.RemoveItem(data.identifier, data.item, data.amount, data.metadata) -- remove item from stash inventory
		else
			RemoveBoothItem(data.identifier, data.item, data.amount, data.metadata)
		end
		if data.addmoney then
			Inventory.AddItem(data.owner or data.identifier, data.money, data.price * data.amount) -- add money directly to stash inventory or player inventory
		end
		return true
	end
	return false
end

exports('RemoveStockFromStash', RemoveStockFromStash)

-- @args[1] = store type
-- @args[2] = storeindex
-- @args[3] = amount to add to all items
-- /addstockall General 1 999
lib.addCommand({'addstockall', 'addstock'}, {
    help = 'Add Stock to Shops',
    params = {
        {
            name = 'shop',
            type = 'string',
            help = 'Target Shop', },
        {
            name = 'index',
            type = 'string',
            help = 'Index # of Shop',
        },
        {
            name = 'count',
            type = 'number',
            help = 'Amount of stock',
        },
        {
            name = 'item',
			type = 'string',
            help = 'item name',
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    AddStockInternal(args.shop,args.index,args.count,args.item)
end)

AddStockInternal = function(shop,index,count,item)
	local stores = GlobalState.Stores
	local success = false
	for k,v in pairs(shared.OwnedShops) do
		if k == shop then
			for k,v2 in pairs(v) do
				if tonumber(index) == k and stores[v2.label] then
					local storeitems = lib.table.deepclone(v2.supplieritem)
					if stores[v2.label].customitems then
						for k,v in pairs(stores[v2.label].customitems) do
							table.insert(storeitems,v)
						end
					end
					if storeitems then
						for k,v in pairs(storeitems) do
							itemtype = v.metadata and v.metadata.name and 'custom' or 'normal'
							itemname = v.metadata and v.metadata.name or v.name
							if item == itemname or not item then
								success = true
								if stores[v2.label].items[itemtype][itemname] == nil then stores[v2.label].items[itemtype][itemname] = {} end
								if stores[v2.label].items[itemtype][itemname].stock == nil then stores[v2.label].items[itemtype][itemname].stock = 0 end
								stores[v2.label].items[itemtype][itemname].stock += tonumber(count) or 100
								if stores[v2.label].items[itemtype][itemname].stock <= 0 then stores[v2.label].items[itemtype][itemname].stock = 0 end
								sql.update('renzu_stores','items','shop',v2.label,json.encode(stores[v2.label].items))
							end
						end
					end
				end
			end
		end
	end
	GlobalState.Stores = stores
	return success
end

exports('AddStockInternal', AddStockInternal)
lib.addCommand({'storeadmin', 'stores'}, {
    help = 'Open Admin Store manage',
    params = {},
    restricted = 'group.admin'
}, function(source, args, raw)
    local stores = GlobalState.Stores
	local ply = Player(source).state
	ply:set('storemanage',{data = stores, ts = os.time()}, true)
end)

function tprint (tbl, indent,supplier)
	if type(tbl) ~= 'table' then return end
	if not indent then indent = 0 end
	local toprint = string.rep(" ", 0) .. "{\r\n"
	indent = indent + 4 
	local p = #tbl > 0 and ipairs or pairs
	for k, v in p(tbl) do
		toprint = toprint .. string.rep(" ", indent)
		if (type(k) == "number") then
			toprint = toprint .. "[" .. k .. "] = "
		elseif (type(k) == "string") then
			toprint = toprint  .. k ..  " = "   
		end
		if (type(v) == "number") then
			toprint = toprint .. v .. ",\r\n"
		elseif (type(v) == "string") then
			toprint = toprint .. "\"" .. v .. "\",\r\n"
		elseif (type(v) == "table") and k ~= 'supplieritem' then
			toprint = toprint .. tprint(v, indent + 1,supplier) .. ",\r\n"
		elseif (type(v) == "table") and k == 'supplieritem' then
			toprint = toprint .. supplier .. ",\r\n"
		elseif type(v) == 'vector3' then
			toprint = toprint .. vec3(v.x,v.y,v.z) .. ",\r\n"
		elseif type(v) == 'vector4' then
			toprint = toprint .. vec4(v.x,v.y,v.z,v.w) .. ",\r\n"
		else
			toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
		end
	end
	toprint = toprint .. string.rep(" ", indent-2) .. "}"
	return toprint
end

GlobalState.CreateShop = {}

CreateShop = function(data)
	local path = 'config/ownedshops/'..data.type..'.lua'
	local path2 = 'config/defaultshops.lua'
	local defaultshops = shared.Shops
	local ownedshop = shared.OwnedShops[data.type]
	local index = #ownedshop+1
	if not data.config.Shop then return false end
	if not data.config.Storeowner then return false end
	if ownedshop then
		table.insert(ownedshop,{
			moneytype = ownedshop[1].moneytype,
			label = data.type..' #'..index,
			coord = data.config.Storeowner,
			cashier = data.config.Cashier,
			price = ownedshop[1].price,
			supplieritem = {}
		})
		table.insert(shared.Shops[data.type].locations,vec3(data.config.Shop.x,data.config.Shop.y,data.config.Shop.z))
		local StoreItem = 'shared.Storeitems.'..data.type
		local ownedshops = 'return '
		ownedshops = ownedshops..tprint(ownedshop,nil,StoreItem)
		SaveResourceFile('renzu_shops', path, ownedshops, -1)
		local default = 'return '
		default = default..tprint(defaultshops,nil,StoreItem)
		SaveResourceFile('renzu_shops', path2, default, -1)
		GlobalState.CreateShop = {
			loc = vec3(data.config.Shop.x,data.config.Shop.y,data.config.Shop.z),
			coord = data.config.Storeowner,
			cashier = data.config.Cashier,
			index = index,
			type = data.type,
			label = data.type..' #'..index,
			shop = {
				moneytype = ownedshop[1].moneytype,
				label = data.type..' #'..index,
				coord = data.config.Storeowner,
				cashier = data.config.Cashier,
				price = ownedshop[1].price,
				inventory = shared.Storeitems[data.type],
				supplieritem = shared.Storeitems[data.type],
			},
			ts = os.time()
		}
		if canregister and shared.oxShops then
			local items = {}
			local storeitems = shared.Storeitems[data.type]
			for k,v in pairs(storeitems) do
				local name = v.metadata and v.metadata.name or v.name
				v.currency = ownedshop[1].moneytype
				v.count = shared.defaultStock[data.type]
				table.insert(items,v)
			end
			exports.ox_inventory:RegisterSingleShop(data.type, {
				name = data.type, 
				inventory = items,
				coord = vec3(data.config.Shop.x,data.config.Shop.y,data.config.Shop.z)
			}, index,false,true)
		end
		return true
	end
	return false
end

exports('CreateShop', CreateShop)

lib.callback.register('renzu_shops:createShop', function(source,data)
	return CreateShop(data)
end)

lib.callback.register('renzu_shops:addstock', function(source,data)
	-- lets secure by adding group check? not now another framework shit. is there a way to check ACL groups via libs? not yet?
	return AddStockInternal(data.shop,data.index,data.count,data.item)
end)

RemoveStock = function(data)
	local storeowned, shopdata = isStoreOwned(data.type,data.index) -- check if this store has been owned by player
	if storeowned then
		if data.customer and GetItemCountSingle(data.money:lower(), data.customer) >= (data.price * data.count) or not data.customer then
			local removed = RemoveStockFromStore({originalprice = not data.customer and true or false, shop = data.type, metadata = data.metadata, index = data.index, item = data.name, amount = tonumber(data.count), price = data.price, money = data.money:lower()})
			if removed and data.customer then
				Inventory.RemoveItem(data.customer, data.money:lower(), (data.price * data.count)) -- remove money from buyer
				Inventory.AddItem(data.customer, data.name, data.count, data.metadata) -- add money directly to stash inventory
				local carts = GlobalState.ShopCarts
				local shopcart = carts[storeowned]?.cart or {}
				for k,v in pairs(shopcart) do
					if v.serialid.cartid == data.serialid.cartid then
						carts[storeowned].cart[k] = nil
					end
				end
				GlobalState.ShopCarts = carts
				TriggerClientEvent('renzu_shops:removecart',data.customer,data.serialid)
				return true
			elseif removed then
				return true
			else
				return false
			end
		else
			TriggerClientEvent('renzu_shops:removecart',data.customer,data.serialid,true)
			TriggerClientEvent('renzu_shops:customernomoney',source,data.serialid,true)
		end
	else
		return RemoveStockFromStash({identifier = data.identifier, metadata = data.metadata, item = data.name, amount = tonumber(data.count), price = data.price, type = data.type, money = 'money'})
	end
end

exports('RemoveStock', RemoveStock)

lib.callback.register('renzu_shops:shopduty', function(source,data)
	local store = GlobalState['Stores_'..data.id]
	if store then
		store.duty = data.duty
	end
	GlobalState['Stores_'..data.id] = store
end)

lib.callback.register('renzu_shops:removestock', function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	data.identifier = data.type..':'..xPlayer.identifier
	return RemoveStock(data)
end)

function hasLicense(name, xPlayer)
	if shared.framework == 'ESX' then
		local result = SqlFunc('oxmysql','fetchAll','SELECT 1 FROM user_licenses WHERE type = ? AND owner = ?', { name, xPlayer.identifier })
		return result and result[1]
	else
		return xPlayer?.PlayerData?.metadata?.licences[name]
	end
end

exports('hasLicense', hasLicense)

lib.callback.register('renzu_shops:buyitem', function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local storeowned, shopdata, shoptype = isStoreOwned(data.shop,data.index) -- check if this store has been owned by player
	local movableshop = isMovableShop(data.index) -- check if this store is a movable type
	local boothshop = string.find(data.shop, 'market')
	local hasitem = false
	local total = 0
	local customparts = {}
	for k,v in pairs(data.items) do -- iterate total prices in server and manage customise item data
		hasitem = true
		local name = v.data.metadata and v.data.metadata.name or v.data.name
		if v.count > 0 then
			if shared.inventory == 'ox_inventory' and data.shop ~= 'VehicleShop' then
				if not exports.ox_inventory:CanCarryItem(source, v.data.name, v.count, v.data.metadata)  then
					data.items[k] = nil
				else
					total = total + tonumber(data.data[name].price) * tonumber(v.count)
				end
			else
				total = total + tonumber(data.data[name].price) * tonumber(v.count)
			end
		else
			data.items[k] = nil
		end
		if string.find(name:upper(), "WEAPON_") and v.data.license and not hasLicense(v.data.license,xPlayer) then
			return 'license'
		end
		local customise = v.metadatas or {}
		local metadata = {}
		local newdata = false
		local desc = ''
		local uniquestats = {}
		for _,v2 in pairs(customise) do
			for k,v in pairs(data.items) do
				local name = v.data.metadata and v.data.metadata.name or v.data.name
				if v2 == name then -- recheck if item is in cart before adding it as metadata
					newdata = true
					table.insert(metadata,v2)
					local customdata = Customise[v2] or {}
					for k,v in pairs(customdata) do -- add custom description for customise item
						if not uniquestats[k] then
							uniquestats[k] = true
							local itemdesc = CustomiseLabel[k] or ''
							desc = desc..'    \n '..itemdesc
						end
					end
					if not v.data.metadata then v.data.metadata = {} end
					if not customparts[k] then customparts[k] = {} end
					table.insert(customparts[k],{name = v2, count = v.count})
					break
				end
			end
		end
		if newdata then
			if string.find(name:upper(), "WEAPON_") then
				local component = 'components'
				if shared.framework == 'QBCORE' then
					component = 'attachments'
				end
				if not data.items[k].data.metadata then data.items[k].data.metadata = {} end -- incase metadata is not define in shop items.
				if not data.items[k].data.metadata[component] then data.items[k].data.metadata[component] = {} end
				local meta = {}
				if shared.framework == 'QBCORE' then
					for k,item in pairs(metadata) do
						local componentsdata = Components[item]
						table.insert(meta, {
							component = componentsdata?.client?.component[1],
							label = componentsdata.label,
							item = item,
							type = componentsdata.type,
						})
						metadata = meta
					end
				end
				data.items[k].data.metadata[component] = metadata
			else
				if not data.items[k].data.metadata then data.items[k].data.metadata = {} end
				if not data.items[k].data.metadata['customise'] then data.items[k].data.metadata['customise'] = {} end
				data.items[k].data.metadata['customise'] = metadata
				data.items[k].data.metadata.description = desc
			end
		end
	end
	if data.finance then
		total = data.finance.downpayment
	end
	if total == 0 then
		return 'invalidamount'
	end
	if not hasitem then
		return 'invalidamount'
	end
	local moneytype = data.type

	moneytype = moneytype:gsub('Wallet',moneytype) -- check payment type
	moneytype = moneytype:gsub('finance','money')
	local money = GetItemCountSingle(moneytype:lower(),source)
	if moneytype == 'bank' then
		money  = xPlayer.getAccount('bank').money
	end
	if money >= total and total > 0 then
		if moneytype == 'bank' then
			xPlayer.removeAccountMoney('bank', total)
		else
			Inventory.RemoveItem(source,moneytype:lower(),total)
		end
		callback = 'success'
		for k,v in pairs(customparts) do -- remove custom items from cart as its inserted as custom item metadatas from the recent loop above
			for k,item in pairs(v) do
				for k2,v in pairs(data.items) do
					local name = v.data.metadata and v.data.metadata.name or v.data.name
					if item.name == name then
						if storeowned then -- storeowned Ownableshops data handler
							RemoveStockFromStore({shop = data.shop, metadata = v.data.metadata, index = data.index, item = v.data.name, amount = tonumber(v.count), money = moneytype:lower()})
						elseif movableshop then -- movable shops logic data handler
							RemoveStockFromStash({addmoney = true, identifier = data.shop, metadata = v.data.metadata, item = v.data.name, amount = tonumber(v.count), type = data.index, money = moneytype:lower()})
						end
						if v.count > item.count then
							data.items[k2].count -= item.count
						else
							data.items[k2] = nil
						end
						break
					end
				end
			end
		end
		callback = {}
		for k,v in pairs(data.items) do
			if storeowned then -- storeowned Ownableshops data handler
				RemoveStockFromStore({shop = data.shop, metadata = v.data.metadata, index = data.index, item = v.data.name, amount = tonumber(v.count), money = moneytype:lower()})
			elseif movableshop or boothshop then -- movable shops and boothshop logic data handler
				RemoveStockFromStash({owner = data.owner, booth = boothshop, addmoney = true, identifier = data.shop, metadata = v.data.metadata, item = v.data.name, amount = tonumber(v.count), price = data.data[v.data.name].price, type = data.index, money = moneytype:lower()})
			end
			if data.shop ~= 'VehicleShop' then -- add new item if its not a vehicle type
				Inventory.AddItem(source,v.data.name,v.count,v.data.metadata, false)
			else -- else if vehicle type add it to player vehicles table
				for i = 1, tonumber(v.count) do
					local plate = GenPlate()
					callback[v.data.name] = plate
					local group = data.groups and xPlayer?.job?.name and GetJobFromData(data.groups,xPlayer) == xPlayer.job.name and xPlayer.job.name
					local sqldata = {
						plate,
						json.encode({model = GetHashKey(v.data.name), plate = plate, modLivery = tonumber(v.vehicle?.livery or -1), color1 = tonumber(v.vehicle?.color or 0)}),
						xPlayer.identifier,
						1,
						group or 'civ'
					}
					if shared.framework == 'QBCORE' then
						table.insert(sqldata,xPlayer.citizenid)
						table.insert(sqldata,joaat(v.data.name))
						table.insert(sqldata,'pillboxgarage')
						table.insert(sqldata,v.data.name)
					end
					table.insert(sqldata,data.vehicletype)
					MySQL.insert.await(insertstr:format(vehicletable,columns,values),sqldata)
					Wait(100)
					shared.VehicleKeys(plate,source)
				end
			end
			Wait(500)
		end
		local stores = GlobalState.Stores
		if storeowned and data.finance and stores[storeowned] then
			local daily = data.finance.daily
			local days = data.finance.days
			local finance = {
				days = days,
				daily = daily,
				total = daily * days,
				owner = stores[storeowned].owner,
				shop = storeowned,
				identifier = xPlayer.identifier,
				bank = xPlayer.getAccount('bank').money
			}
			RegisterFinance(finance)
		end
		return callback
	else
		return 'notenoughmoney'
	end
end)

RegisterFinance = function(data)
	local finance = GlobalState.FinanceData
	if not finance[data.identifier] then
		sql.insert('financedata',{data.identifier,shared.MaxDebt + data.bank,'[]'})
		finance[data.identifier] = {max = shared.MaxDebt + data.bank, financed = {}}
	end
	if finance[data.identifier].financed then
		local financedata = {
			total = data.total,
			daily = data.daily,
			shop = data.shop,
			owner = data.owner,
			days = data.days
		}
		finance[data.identifier].max -= data.total
		table.insert(finance[data.identifier].financed,financedata)
		GlobalState.FinanceData = finance
		sql.update('financedata','max','identifier',data.identifier,finance[data.identifier].max)
		sql.update('financedata','financed','identifier',data.identifier,json.encode(finance[data.identifier].financed))
		--SetResourceKvp('financedata', json.encode(finance))
	end
end

exports('RegisterFinance', RegisterFinance)

Citizen.CreateThread(function()
	while true do
		time = os.date("*t")
		if time.hour == 0 and time.min == 0 and time.sec == 1 then
			local finance = GlobalState.FinanceData
			for debtor,v in pairs(finance) do
				for k,v in pairs(v.financed) do
					local xPlayer = GetPlayerFromIdentifier(debtor)
					if xPlayer then
						if xPlayer.getAccount('bank').money >= v.daily then
							xPlayer.removeAccountMoney('bank',v.daily,' Bank Financing')
							finance[debtor].max += v.daily
							finance[debtor].financed[k].total -= v.daily
							finance[debtor].financed[k].days -= 1
							if finance[debtor].financed[k].total <= 0 or finance[debtor].financed[k].days == 0 then
								finance[debtor].financed[k] = nil
							end
						else -- penalty fee
							finance[debtor].max -= finance[debtor].max/10
							finance[debtor].financed[k].total += v.daily/10
						end
					else -- if player is offline
						local money = GetMoneyFromBankOffline(debtor)
						if money and tonumber(money) >= v.daily then
							ModifyFromBankOffline(debtor,v.daily,true)
							finance[debtor].max += v.daily
							finance[debtor].financed[k].days -= 1
							finance[debtor].financed[k].total -= v.daily
							if finance[debtor].financed[k].total <= 0 or finance[debtor].financed[k].days == 0 then
								finance[debtor].financed[k] = nil
							end
						else -- penalty fee
							finance[debtor].max -= finance[debtor].max/10
							finance[debtor].financed[k].total += v.daily/10
						end
					end
					sql.update('financedata','max','identifier',debtor,finance[debtor].max)
					sql.update('financedata','financed','identifier',debtor,finance[debtor].financed)
				end
			end
			--SetResourceKvp('financedata', json.encode(finance))
			GlobalState.FinanceData = finance
		end
		Wait(1000)
	end
end)

isShopAlreadyOwned = function(id)
	return GlobalState.Stores[id] ~= nil
end

exports('isShopAlreadyOwned', isShopAlreadyOwned)

BuyStore = function(data)
	local stores = GlobalState.Stores
	stores[data.label] = {owner = data.identifier, money = {money = 0, black_money = 0}, items = {normal = {}, custom = {}}, employee = {}, cashier = { money = 0, black_money = 0}}
	sql.insert('renzu_stores',{
		data.label,
		data.identifier,
		json.encode({money = 0, black_money = 0}),
		json.encode({normal = {}, custom = {}}),
		'[]',
		json.encode({ money = 0, black_money = 0}),
		'[]',
		nil,
	})
	GlobalState.Stores = stores
	AddStockInternal(data.shopName,data.shopIndex,shared.defaultStock[data.shopName])
	if shared.oxShops and canregister and data.shopName ~= 'VehicleShop' then
		local items = {}
		local stores = GlobalState.Stores
		local storeitems = stores[data.label].items
		for k,v in pairs(data.supplieritem) do
			local name = v.metadata and v.metadata.name or v.name
			local itemtype = v.metadata and v.metadata.name and 'custom' or 'normal'
			v.currency = data.moneytype or 'money'
			v.count = storeitems[itemtype] and storeitems[itemtype][name] and storeitems[itemtype][name].stock 
			or shared.defaultStock[data.shopName]
			v.count = tonumber(v.count) or shared.defaultStock[data.shopName]
			table.insert(items,v)
		end
		exports.ox_inventory:RegisterSingleShop(data.shopName, {
			name = data.label, 
			inventory = items,
			coord = shared.Shops[data.shopName].locations[data.shopIndex]
		}, data.shopIndex,false,true)
	end
	return true
end

exports('BuyStore', BuyStore)

lib.callback.register("renzu_shops:buystore", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	if xPlayer.getAccount('money').money >= data.price then
		data.identifier = xPlayer.identifier
		if not isShopAlreadyOwned(data.label) then
			xPlayer.removeAccountMoney('money', data.price)
			return BuyStore(data)
		end
	end
end)

local RemoveStore = function(id)
	local stores = GlobalState.Stores
	stores[id] = nil
	--SetResourceKvp('renzu_stores', json.encode(stores))
	sql.delete('renzu_stores','shop',id)
	GlobalState.Stores = stores
	GlobalState['Stores_'..id] = nil
	return true
end

exports('RemoveStore', RemoveStore)

GlobalState.AvailableStore = {}
lib.callback.register("renzu_shops:sellstore", function(source,store)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local stores = GlobalState.Stores
	if stores[store] and stores[store].owner == xPlayer.identifier then
		for k,shops in pairs(shared.OwnedShops) do
			for k,v in pairs(shops) do
				if v.label == store then
					xPlayer.addAccountMoney('money', v.price / 2)
					break
				end
			end
		end
		Wait(1000)
		GlobalState.AvailableStore = {ts = os.time(), store = store}
		RemoveStore(store)
		return true
	end
end)

CreateCustomItem = function(data)
	local stores = GlobalState.Stores
	if not stores[data.store].customitems then stores[data.store].customitems = {} end
	local url = string.find(data.image or '', "http") or false
	local metadata = { -- ox_inventory supported only
		label = data.label, -- custom label name to set from metadatas
		name = data.itemname, -- identifier important
		[data.status] = data.statusvalue,
		description = data.description,
		functions = data.functions,
		animations = data.animations,
	}
	if string.find(data.image or '', "http") then
		metadata.imageurl = data.image
	else
		metadata.image = data.image
	end
	local itemdata = {name = CustomItems.Default, price = data.price , category = data.category, metadata = metadata}
	stores[data.store].customitems[data.itemname] = itemdata
	sql.update('renzu_stores','customitems','shop',store,json.encode(stores[data.store].customitems))
	--SetResourceKvp('renzu_stores', json.encode(stores))
	GlobalState.Stores = stores
	return true
end

exports('CreateCustomItem', CreateCustomItem)

lib.callback.register("renzu_shops:createitem", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local stores = GlobalState.Stores
	if stores[data.store] and stores[data.store].owner == xPlayer.identifier then
		return CreateCustomItem(data)
	end
end)

lib.callback.register("renzu_shops:work", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	if GetJobFromData(data.groups,xPlayer) == xPlayer.job.name then
		Inventory.AddItem(source, data.reward, 1)
	end
end)

lib.callback.register("renzu_shops:proccessed", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local amount = 1
	if type(data.required) == 'string' or data.required == false then
		amount = data.required and GetItemCountSingle(data.required,source)
		if amount and amount > 0 or not data.required then
			if data.required then
				Inventory.RemoveItem(source,data.required,amount)
			end
			if data.reward then
				Inventory.AddItem(source, data.reward, amount and amount * data.value or data.value)
			end
			return true
		end
	elseif type(data.required) == 'table' then
		local hasingredients = true
		for k,v in pairs(data.required) do
			if GetItemCountSingle(v.item,source) < v.amount then
				hasingredients = false
			end
		end
		if hasingredients then
			for k,v in pairs(data.required) do
				if GetItemCountSingle(v.item,source) >= v.amount then
					Inventory.RemoveItem(source,v.item,v.amount)
				end
			end
			if data.reward then
				Inventory.AddItem(source, data.reward, data.value)
			end
			return true
		end
	end
	return false
end)

lib.callback.register("renzu_shops:transfershop", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local toPlayer = GetPlayerFromId(data.id)
	local stores = GlobalState.Stores
	if toPlayer and stores[data.store] and stores[data.store].owner == xPlayer.identifier then
		stores[data.store].owner = toPlayer.identifier
		stores[data.store]?.employee[xPlayer.identifier] = GetPlayerName(source)
		GlobalState.Stores = stores
		sql.update('renzu_stores','owner','shop',data.store,toPlayer.identifier)
		--SetResourceKvp('renzu_stores', json.encode(stores))
		return true
	end
	return false
end)

ModifyJobAccess = function(data)
	local stores = GlobalState.Stores
	stores[data.store].job = data.job
	GlobalState.Stores = stores
	--SetResourceKvp('renzu_stores', json.encode(stores))
	sql.update('renzu_stores','job','shop',data.store,data.job)
	local jobshop = GlobalState.JobShop
	jobshop[data.store] = data.job
	GlobalState.JobShop = jobshop
	GlobalState.JobShopNotify = {store = data.store, job = data.job, ts = os.time(), owner = data.owner}
	return true
end

GlobalState.JobShopNotify = {}
lib.callback.register("renzu_shops:shopjobaccess", function(source,store,add)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local stores = GlobalState.Stores
	if stores[store] and stores[store].owner == xPlayer.identifier then
		ModifyJobAccess({
			job = add and xPlayer.job.name or nil,
			owner = xPlayer.identifier,
			store = store,
		})
	end
	return false
end)

GlobalState.RobableStore = {}

Priority = function() -- your custom priority logic
	return GlobalState.Priority == 'NEUTRAL' or false
end

GlobalState.ShopAlerts = {}
RobNotification = function(data) -- your custom Alert Notification
	GlobalState.ShopAlerts = {store = data.store, coord = data.coord, ts = os.time()}
	return true
end

local robbers = {}
lib.callback.register("renzu_shops:canrobstore", function(source,data)
	local rob = GlobalState.RobableStore
	if not rob[data.store] and Priority() or rob[data.store] and rob[data.store] <= os.time() and Priority() then
		robbers[source] = true
		data.coord = GetEntityCoords(GetPlayerPed(source))
		RobNotification(data)
		return true
	end
	return false
end)

lib.callback.register("renzu_shops:robstore", function(source,data)
	if robbers[source] then
		robbers[source] = nil
		local rob = GlobalState.RobableStore
		rob[data.store] = os.time() + 1800
		GlobalState.RobableStore = rob
		local stores = GlobalState.Stores
		if not stores[data.store] then -- if store is not owned
			local amount = math.random(2000,20000)
			Inventory.AddItem(source, 'black_money', amount)
			GlobalState.Priority = 'ACTIVE'

			return true
		else -- if store is owned by player
			local money = stores[data.store].cashier[data.item] or 0
			stores[data.store].cashier[data.item] = 0
			Inventory.AddItem(source, 'black_money', money)
			sql.update('renzu_stores','cashier','shop',data.store,stores[data.store].cashier)
			GlobalState.Stores = stores
			GlobalState.Priority = 'ACTIVE'

			return true
		end
	end
	return false
end)

lib.callback.register("renzu_shops:GetInventoryData", function(source,identifier)
	return GetInventoryData(identifier)
end)

GetInventoryData = function(source)
	local booths = GlobalState.Booths
	local items = {}
	for k,v in pairs(booths) do
		if k == source then
			for k,v in pairs(v.placedapplications) do
				if v.type == 'storage' then
					local inventory
					if shared.inventory == 'qb-inventory' then
						inventory = exports['qb-inventory']:GetStashItems(v.appid)
						for k,v in pairs(inventory) do
							v.metadata = v.info
							v.count = v.amount
							table.insert(items,v)
						end
					elseif shared.inventory == 'ox_inventory' then
						inventory = exports.ox_inventory:GetInventoryItems(v.appid)
						for k,v in pairs(inventory) do
							table.insert(items,v)
						end
					end
				end
			end
		end
	end
	return items
end

RemoveBoothItem = function(source,item,amount,metadata)
	local booths = GlobalState.Booths
	local items = {}
	local toremove = amount
	for k,v in pairs(booths) do
		if k == source then
			for k,v in pairs(v.placedapplications) do
				if v.type == 'storage' then
					local inventory
					if shared.inventory == 'qb-inventory' then
						inventory = exports['qb-inventory']:GetStashItems(v.appid)
						local stashid = v.appid
						for k,v in pairs(inventory) do
							v.metadata = v.info
							v.count = v.amount
							if item == v.metadata and v.metadata.name or item == v.name then
								Inventory.RemoveItem(stashid,item,toremove,v.metadata)
								break
							end
						end
					elseif shared.inventory == 'ox_inventory' then
						inventory = exports.ox_inventory:GetInventoryItems(v.appid)
						local stashid = v.appid
						for k,v in pairs(inventory) do
							if item == v.metadata and v.metadata.name or item == v.name then
								Inventory.RemoveItem(stashid,item,toremove,v.metadata)
								break
							end
						end
					end
				end
			end
		end
	end
	return true
end

GetStashData = function(data)
	local items = {}
	for k,v in pairs(data.items) do
		table.insert(items,v.name)
	end
	local result = {}
	local slot = {}
	for k,v in pairs(data.items) do
		local item = v.name
		local label = Items[item]
		local metadata = false
		if v.metadata and v.metadata.name then
			item = v.metadata.name
			metadata = true
		end
		local data = Inventory.SearchItems(data.identifier, 'slots', v.name)
		result[item] = 0
		if data then
			for k,v in pairs(data) do
				if metadata and result[v.metadata.name] and not slot[v.slot] then
					result[v.metadata.name] += v.count
					slot[v.slot] = true
				elseif v.metadata and not v.metadata.name and not metadata and not slot[v.slot] or not metadata and not v.metadata and not slot[v.slot] then
					result[v.name] += v.count
					slot[v.slot] = true
				end
			end
		end
	end
	return result
end

exports('GetStashData', GetStashData)

lib.callback.register("renzu_shops:getStashData", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local identifier = data.identifier
	return GetStashData(data)
end)

GetItemCountSingle = function(item,source)
	return Inventory.SearchItems(source,'count', item)
end

CraftItems = function(data)
	for k,v in pairs(data.items) do
		if v.metadata and v.metadata.name and v.metadata.name == data.item then
			local haverequired = true
			for k,v in pairs(v.ingredients) do
				if GetItemCountSingle(k,data.inv) < v then
					haverequired = false
				end
			end
			if haverequired then
				for k,v in pairs(v.ingredients or {}) do
					Inventory.RemoveItem(data.inv, k, v, nil)
				end
				if not data.dontreceive then
					Inventory.AddItem(data.inv, v.name, 1, v.metadata or {})
				end
			end
		elseif v.metadata and not v.metadata.name and v.name == data.item or not v.metadata and v.name == data.item then
			local haverequired = true
			for k,v in pairs(v.ingredients or {}) do
				if GetItemCountSingle(k,data.inv) < v then
					haverequired = false
				end
			end
			if haverequired then
				for k,v in pairs(v.ingredients) do
					Inventory.RemoveItem(data.inv, k, v, nil)
				end
				if not data.dontreceive then
					Inventory.AddItem(data.inv, v.name, 1, nil)
				end
			end
		end
	end
end

exports('CraftItems', CraftItems)

lib.callback.register("renzu_shops:craftitem", function(source,data)
	local source = source
	local items = not data.items and shared.MovableShops[data.type].menu[data.menu] or data.items
	local xPlayer = GetPlayerFromId(source)
	local identifier = not data.items and data.type..':'..xPlayer.identifier or data.identifier
	data.inv = data.stash and identifier or source -- declare where the inventory will be used for removing and adding items
	data.items = items
	return CraftItems(data)
end)

lib.callback.register("renzu_shops:getmovableshopdata", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local identifier = data.type..':'..xPlayer.identifier
	if shared.inventory == 'ox_inventory' then
		exports.ox_inventory:RegisterStash(identifier, data.type, 40, 40000, false)
	elseif shared.inventory == 'qb-inventory' then
		exports['qb-inventory']:RegisterStash(identifier)
	end
	return GlobalState.MovableShops[identifier]
end)

GetJobFromData = function(job,xPlayer)
	if not job then return end
	if type(job) == 'string' then return job end
	for k,v in pairs(job) do
		if v == xPlayer.job.name then
			return v
		end
	end
	return false
end

AddMovableShopToPlayer = function(data,source)
	local plate = nil
	local movable = GlobalState.MovableShops
	if data.shop.type == 'vehicle' then
		plate = GenPlate()
		local sqldata = {plate,json.encode({model = data.shop.model, plate = plate, modLivery = -1}),data.owner,1,'civ','car'}
		if shared.framework == 'QBCORE' then
			table.insert(sqldata,data.citizenid)
			table.insert(sqldata,data.shop.model)
			table.insert(sqldata,'pillboxgarage')
			table.insert(sqldata,data.shop.modelname)
			table.insert(sqldata,'car')
		end
		MySQL.insert.await(insertstr:format(vehicletable,columns,values),sqldata)
	end
	movable[data.identifier] = {identifier = data.owner, money = {money = 0, black_money = 0}, items = {}, plate = plate, type = data.shop.type, shopname = data.type} -- literally plate and type is the only thing we save here as the other datas like money and items are saved using ox_inventory. first plan is to used owned inventory, same with the shop stocking system logic using ox contextmenus,  but instead i tried and successfully used ox inventory since this does not saved vehicle stocks datas.
	sql.insert('movableshops',{
		data.identifier,
		data.owner,
		json.encode({money = 0, black_money = 0}),
		'[]',
		plate,
		data.shop.type,
		data.type,
	})
	--SetResourceKvp('movableshops', json.encode(movable))
	GlobalState.MovableShops = movable
	return movable[data.identifier]
end

exports('AddMovableShopToPlayer', AddMovableShopToPlayer)

lib.callback.register("renzu_shops:buymovableshop", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local identifier = data.type..':'..xPlayer.identifier
	local movable = GlobalState.MovableShops
	if not movable[identifier] then
		if xPlayer.getAccount('money').money >= data.price then
			xPlayer.removeAccountMoney('money', data.price)
			data.owner = xPlayer.identifier
			data.identifier = identifier
			data.citizenid = xPlayer.citizenid
			return AddMovableShopToPlayer(data,source)
		else
			return false
		end
	else
		return movable[identifier]
	end
end)

lib.callback.register("renzu_shops:getMovableVehicle", function(source,plate)
	local plate = string.gsub(tostring(plate), '^%s*(.-)%s*$', '%1'):upper()
	local vehicle = SqlFunc('oxmysql','fetchAll','SELECT * FROM '..vehicletable..' WHERE TRIM(plate) = ? ',{plate})
	if vehicle[1] then
		shared.VehicleKeys(plate,source)
	end
	return vehicle[1]
end)

AddEventHandler('entityCreated', function(entity)
    if DoesEntityExist(entity) and GetEntityPopulationType(entity) ~= 7 and GetEntityType(entity) ~= 2 or DoesEntityExist(entity) and GetEntityPopulationType(entity) ~= 7 then return end
    local entity = entity
	Wait(1000) -- wait 1 second for script plate setter
	local movableshops = GlobalState.MovableShops
	if DoesEntityExist(entity) then
		for identifier,v in pairs(movableshops) do
			local plate = string.gsub(tostring(v.plate), '^%s*(.-)%s*$', '%1'):upper()
			local entityplate = string.gsub(tostring(GetVehicleNumberPlateText(entity)), '^%s*(.-)%s*$', '%1'):upper()
			if v.type == 'vehicle' and plate == entityplate then
				local ent = Entity(entity).state
				Wait(1)
				ent:set('movableshop', {identifier = identifier, type = v.shopname, selling = true}, true)
				ent:set('movableshopspawned', {identifier = v.identifier, type = v.shopname}, true)
				if shared.inventory == 'ox_inventory' then
					exports.ox_inventory:RegisterStash(identifier, v.shopname, 40, 40000, false)
				elseif shared.inventory == 'qb-inventory' then
					exports['qb-inventory']:RegisterStash(identifier)
				end
			end
		end
	end
end)

local deliver = {}
lib.callback.register("renzu_shops:createshoporder", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local stores = GlobalState.Stores
	local amount = data.item.price * data.amount * shared.discount
	if tonumber(stores[data.store].money[data.moneytype]) >= amount then
		stores[data.store].money[data.moneytype] = tonumber(stores[data.store].money[data.moneytype]) - amount
		local type = data.ShopType or 'item'
		local randompoints = shared.deliverypoints[type][math.random(1,#shared.deliverypoints[type])]
		data.item.amount = data.amount
		local t = {type = type, id = math.random(9999,999999), point = randompoints, item = data.item, amount = amount, moneytype = data.moneytype}
		if data.moneytype == 'money' then
			local shippping = GlobalState.Shipping
			if not shippping[data.store] then
				shippping[data.store] = {}
			end
			table.insert(shippping[data.store],t)
			SetResourceKvp('shippingcompany', json.encode(shippping))
			GlobalState.Shipping = shippping
			TriggerClientEvent('okokNotify:Alert', -1, "Fedex Express", "New Shipping Job is Available", 5000, 'info')
		end
		GlobalState.Stores = stores
		return t
	else return false
	end
end)

GlobalState.OngoingShip = {}
lib.callback.register("renzu_shops:startdelivery", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	for k,v in pairs(deliver) do
		for k,v in pairs(v) do
			if v == xPlayer.identifier then
				return 'alreadyongoing'
			end
		end
	end
	if not deliver[data.store] then deliver[data.store] = {} end
	if not deliver[data.store][data.index] then 
		deliver[data.store][data.index] = xPlayer.identifier
		GlobalState.OngoingShip = deliver
		return data
	else
		return 'taken'
	end
	return false
end)

lib.callback.register("renzu_shops:stockdelivered", function(source,data)
	local shipping = GlobalState.Shipping
	local add = false
	for k3,v in pairs(shipping) do
		if data.store == k3 then
			for k4,v in pairs(v) do
				if v.id == data.index then
					shipping[k3][k4] = nil
					add = true
					break
				end
			end
		end
	end
	if add or data.selfdeliver then
		SetResourceKvp('shippingcompany', json.encode(shipping))
		GlobalState.Shipping = shipping
		AddStockstoStore(data)
		return true
	end
	return false
end)

lib.callback.register("renzu_shops:jobdone", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local found = false
	for k,v in pairs(deliver) do
		for k2,v in pairs(v) do
			if v == xPlayer.identifier then
				found = true
				deliver[k][k2] = nil
				break
			end
		end
	end
	if found then
		local amount = data.dist * shared.shipping.payperdistance
		xPlayer.addAccountMoney('money',amount)
		return true
	end
	return false
end)

local requests = {}
lib.callback.register("renzu_shops:confirmationfeedback", function(source,data)
	local source = source
	requests[source] = data.answer
	Wait(1000)
	requests[source] = nil
	local player = Player(source).state
	player:set('confirmation',nil,true)
end)

lib.callback.register("renzu_shops:removeemployee", function(source,data)
	local stores = GlobalState.Stores
	if stores[data.store].employee[data.id] then
		stores[data.store].employee[data.id] = nil
		sql.update('renzu_stores','employee','shop',data.store,json.encode(stores[data.store].employee))
		--SetResourceKvp('renzu_stores', json.encode(stores))
		GlobalState.Stores = stores
		return true
	end
end)

lib.callback.register("renzu_shops:addemployee", function(source,data)
	local player = Player(data.id).state
	local data = data
	local employee = GetPlayerFromId(data.id)
	local stores = GlobalState.Stores
	if stores[data.store].employee[employee.identifier] then
		return 'already'
	end
	player:set('confirmation',{store = data.store, ts = os.time()},true)
	local c = 0
	while not requests[data.id] and c <= 5 do
		c = c + 1
		if c == 4 then
			requests[data.id] = 'cancel'
		end
		Wait(1000)
	end
	local accepted = requests[data.id] ~= 'cancel'
	if accepted then
		local stores = GlobalState.Stores
		stores[data.store].employee[employee.identifier] = employee.name
		--SetResourceKvp('renzu_stores', json.encode(stores))
		sql.update('renzu_stores','employee','shop',data.store,json.encode(stores[data.store].employee))
		GlobalState.Stores = stores
	end
	return accepted
end)

GetStoreItemPrice = function(data)
	local inventory = {}
	for k,v in pairs(shared.OwnedShops) do
		for k,v in pairs(v) do
			if v.label == data.store then
				inventory = v.supplieritem
			end
		end
	end
	for k,v in pairs(inventory) do
		if data.data.item.name == v.name then
			return v.price
		end
	end
	return false
end

AddStockstoStore = function(data)
	local stocks = {}
	local inventory = {}
	local stores = GlobalState.Stores
	for k,v in pairs(stores) do
		if v.owner == GlobalState.Stores[k]?.owner and k == data.store then
			itemtype = data.data.item.metadata and data.data.item.metadata.name and 'custom' or 'normal'
			itemname = data.data.item.metadata and data.data.item.metadata.name or data.data.item.name
			if stores[k].items[itemtype][itemname] == nil then stores[k].items[itemtype][itemname] = {} end
			if stores[k].items[itemtype][itemname].stock == nil then stores[k].items[itemtype][itemname].stock = 0 end
			stores[k].items[itemtype][itemname].stock = tonumber(stores[k].items[itemtype][itemname].stock) + data.data.item.amount
			if canregister and shared.oxShops then
				local name, index, storedata = getShopDataByLabel(k)
				SetOxInvShopStock({name = name, index = index, item = itemname, value = data.data.item.amount})
			end
			sql.update('renzu_stores','items','shop',k,json.encode(stores[k].items))
		end
	end
	--SetResourceKvp('renzu_stores', json.encode(stores))
	GlobalState.Stores = stores
end

exports('AddStockstoStore', AddStockstoStore)

GetItemCount = function(item,metadata,source)
	local data = Inventory.SearchItems(source, 'slots', item)
	local count = 0
	local slot = {}
	for k,v in pairs(data) do
		if v.metadata and v.metadata.name == metadata and not slot[v.slot] then -- our identifier to identify custom items
			count += v.count
			slot[v.slot] = true
		end
	end
	return count
end

SetShopitemPrice = function(data)
	local stores = GlobalState.Stores
	if stores[data.store].items[data.itemtype][data.itemname] == nil then stores[data.store].items[data.itemtype][data.itemname] = {} end
	stores[data.store].items[data.itemtype][data.itemname].price = data.value
	--SetResourceKvp('renzu_stores', json.encode(stores))
	sql.update('renzu_stores','items','shop',data.store,json.encode(stores[data.store].items))
	GlobalState.Stores = stores
end

exports('SetShopitemPrice', SetShopitemPrice)

DepositItemToStore = function(source,data)
	local count = 0
	local stores = GlobalState.Stores
	if data.metadata and data.metadata.name then
		count = GetItemCount(data.item,data.metadata.name,source)
	else
		count = Inventory.SearchItems(source, 'count', data.item)
	end
	if tonumber(data.value) and count >= data.value and data.value > 0 then
		Inventory.RemoveItem(source, data.item, data.value, data.metadata and data.metadata.name and data.metadata or nil, slot)
		if stores[data.store].items[data.itemtype][data.itemname] == nil then stores[data.store].items[data.itemtype][data.itemname] = {} end
		local stock = stores[data.store].items[data.itemtype][data.itemname].stock
		if not stock then stores[data.store].items[data.itemtype][data.itemname].stock = 0 end
		stores[data.store].items[data.itemtype][data.itemname].stock = tonumber(stores[data.store].items[data.itemtype][data.itemname].stock) + data.value
		--SetResourceKvp('renzu_stores', json.encode(stores))
		sql.update('renzu_stores','items','shop',data.store,json.encode(stores[data.store].items))
		GlobalState.Stores = stores
		if canregister and shared.oxShops then
			local name, index, storedata = getShopDataByLabel(data.store)
			SetOxInvShopStock({name = name, index = index, item = data.itemname, value = data.value})
		end
		return 'success'
	end
end

exports('DepositItemToStore', DepositItemToStore)

WithdrawItemFromStore = function(source, data)
	local stores = GlobalState.Stores
	if stores[data.store].items[data.itemtype][data.itemname] == nil then stores[data.store].items[data.itemtype][data.itemname] = {} end
	local count = tonumber(stores[data.store].items[data.itemtype][data.itemname].stock)
	if tonumber(data.value) and count and count >= data.value and data.value > 0 then
		stores[data.store].items[data.itemtype][data.itemname].stock = tonumber(stores[data.store].items[data.itemtype][data.itemname].stock) - data.value
		--SetResourceKvp('renzu_stores', json.encode(stores))
		sql.update('renzu_stores','items','shop',data.store,json.encode(stores[data.store].items))
		GlobalState.Stores = stores
		Inventory.AddItem(source, data.item, data.value, data.metadata or {})
		if canregister and shared.oxShops then
			local name, index, storedata = getShopDataByLabel(data.store)
			SetOxInvShopStock({name = name, index = index, item = data.itemname, value = -data.value})
		end
		return 'success'
	end
end

exports('WithdrawItemFromStore', WithdrawItemFromStore)

AddMoneyToStore = function(data)
	local stores = GlobalState.Stores
	if not stores[data.store].money[data.item] then stores[data.store].money[data.item] = 0 end
	stores[data.store].money[data.item] = tonumber(stores[data.store].money[data.item]) + data.value
	--SetResourceKvp('renzu_stores', json.encode(stores))
	sql.update('renzu_stores','money','shop',data.store,json.encode(stores[data.store].money))
	GlobalState.Stores = stores
end

exports('AddMoneyToStore', AddMoneyToStore)

RemoveMoneyStore = function(data)
	local stores = GlobalState.Stores
	if not stores[data.store].money[data.item] then stores[data.store].money[data.item] = 0 end
	stores[data.store].money[data.item] = tonumber(stores[data.store].money[data.item]) - data.value
	--SetResourceKvp('renzu_stores', json.encode(stores))
	sql.update('renzu_stores','money','shop',data.store,json.encode(stores[data.store].money))
	GlobalState.Stores = stores
end

exports('RemoveMoneyStore', RemoveMoneyStore)

RemoveMoneyFromCashier = function(data)
	local stores = GlobalState.Stores
	if stores[data.store].cashier[data.item] == nil then stores[data.store].cashier[data.item] = 0 end
	stores[data.store].cashier[data.item] = tonumber(stores[data.store].cashier[data.item]) - data.value
	--SetResourceKvp('renzu_stores', json.encode(stores))
	sql.update('renzu_stores','cashier','shop',data.store,json.encode(stores[data.store].cashier))
	GlobalState.Stores = stores
end

exports('RemoveMoneyFromCashier', RemoveMoneyFromCashier)

EnableDisableStoreItems = function(data)
	local stores = GlobalState.Stores
	itemtype = data.metadata and data.metadata.name and 'custom' or 'normal'
	itemname = data.metadata and data.metadata.name or data.item
	if stores[data.store].items[itemtype][itemname] == nil then stores[data.store].items[itemtype][itemname] = {} end
	if data.value == 'disable' then
		stores[data.store].items[itemtype][itemname].disable = 'disable'
		--SetResourceKvp('renzu_stores', json.encode(stores))
		GlobalState.Stores = stores
	elseif data.value == 'enable' then
		stores[data.store].items[itemtype][itemname].disable = nil
		--SetResourceKvp('renzu_stores', json.encode(stores))
		GlobalState.Stores = stores
	end
	sql.update('renzu_stores','items','shop',data.store,json.encode(stores[data.store].items))
	return 'success'
end

exports('EnableDisableStoreItems', EnableDisableStoreItems)

GetAccounts = function(xPlayer, name, item)
	if item then
		return Inventory.SearchItems(xPlayer.source, 'count', name)
	end

	return xPlayer.getAccount(name).money
end

AddAccount = function(xPlayer, name, total, item)
	if item then
		return 	Inventory.AddItem(xPlayer.source, name, total)
	end

	return xPlayer.addAccountMoney(name,total)
end

RemoveAccount = function(xPlayer, name, total, item)
	if item then
		return Inventory.RemoveItem(xPlayer.source, name, total)
	end

	return xPlayer.removeAccountMoney(name,total)
end

lib.callback.register('renzu_shops:editstore', function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local stores = GlobalState.Stores
	local employed = stores[data.store].employee[xPlayer.identifier]
	local owned = stores[data.store].owner == xPlayer.identifier 
	or employed 
	or stores[data.store].job == xPlayer.job.name
	or xPlayer.getGroup() == 'admin'
	local itemtype = nil
	local itemname = nil
	if tonumber(data.value) and data.value >= 0 and owned and stores[data.store] and data.type == 'price' then
		data.itemtype = data.metadata and data.metadata.name and 'custom' or 'normal'
		data.itemname = data.metadata and data.metadata.name or data.item
		SetShopitemPrice(data)
		return 'success'
	elseif owned and stores[data.store] and data.type == 'deposit_item' then
		data.itemtype = data.metadata and data.metadata.name and 'custom' or 'normal'
		data.itemname = data.metadata and data.metadata.name or data.item
		return DepositItemToStore(source,data)
	elseif owned and stores[data.store] and data.type == 'withdraw_item' then
		data.itemtype = data.metadata and data.metadata.name and 'custom' or 'normal'
		data.itemname = data.metadata and data.metadata.name or data.item
		return WithdrawItemFromStore(source, data)
	elseif owned and stores[data.store] and data.type == 'deposit_money' then
		local count = GetAccounts(xPlayer,data.item,data.item ~= 'money')
		if tonumber(data.value) and count and count >= data.value and data.value > 0 then
			AddMoneyToStore(data)
			RemoveAccount(xPlayer,data.item,data.value,data.item ~= 'money')
			return 'success'
		end
	elseif owned and stores[data.store] and data.type == 'withdraw_money' then
		local count = tonumber(stores[data.store]?.money[data.item])
		if tonumber(data.value) and count and count >= data.value and data.value > 0 then
			RemoveMoneyStore(data)
			AddAccount(xPlayer,data.item,data.value,data.item ~= 'money')
			return 'success'
		end
	elseif owned and stores[data.store] and data.type == 'withdraw_cashier' then
		local count = tonumber(stores[data.store]?.cashier[data.item])
		if tonumber(data.value) and count and count >= data.value and data.value > 0 then
			RemoveMoneyFromCashier(data)
			AddAccount(xPlayer,data.item,data.value,data.item ~= 'money')
			return 'success'
		end
	elseif owned and stores[data.store] and data.type == 'listing_edit' then
		return EnableDisableStoreItems(data)
	end
	return false
end)

GlobalState.ItemShowCase = json.decode(GetResourceKvpString('itemshowcase') or '[]') or {}

getShopName = function(data)
	local ownedshops = lib.table.deepclone(shared.OwnedShops)
	local storename = nil
	for type,v in pairs(ownedshops) do
		for k,v2 in pairs(v) do
			if k == data.index and type == data.type then
				return v2.label
			end
		end
	end
end

GlobalState.ShopCarts = {}
lib.callback.register('renzu_shops:updateshopcart', function(source, data)
	local carts = GlobalState.ShopCarts
	carts[data.shop] = data
	GlobalState.ShopCarts = carts
end)

--DeleteResourceKvp('itemshowcase')
lib.callback.register('renzu_shops:editshowcase', function(source, method, name, data)
	local showcases = GlobalState.ItemShowCase
	local shop = getShopName(data.shop)
	if shop then
		if method == 'add' then
			if not showcases[shop] then showcases[shop] = {} end
			if not showcases[shop][data.index] then showcases[shop][data.index] = {} end
			table.insert(showcases[shop][data.index], data.item)
		end
		if method == 'modify' then
			for k,v in pairs(showcases) do
				if name == 'remove' then
					for k2,v2 in pairs(showcases[k]) do
						for k3,v3 in pairs(v2) do
							if v3.name == data.name then
								showcases[k][k2][k3] = nil
							end
						end
					end
				else
					for k2,v2 in pairs(showcases[k]) do
						for k3,v3 in pairs(v2) do
							if v3.name == data.name then
								showcases[k][k2][k3][name] = data.value
							end
						end
					end
				end
			end
		end
		SetResourceKvp('itemshowcase', json.encode(showcases))
		GlobalState.ItemShowCase = showcases
		return true
	end
end)

lib.callback.register('renzu_shops:ondemandpay', function(source,data)
	local source = source
	local total = 0
	if purchaseorders[source] then
		for k,v in pairs(purchaseorders[source]) do
			local movable = shared.MovableShops[v.shop]
			if movable and movable.menu[v.menu] then
				for k2,v2 in pairs(movable.menu[v.menu]) do
					local name = v2.metadata and v2.metadata.name or v2.name or v2.name
					if v.name == name then
						total += v2.price * v.count
					end
				end
			end
		end
		if total > 0 then
			purchaseorders[source] = nil
			Inventory.AddItem(source, 'money', total)
		end
	end
end)

local movableentity = {}
lib.callback.register('renzu_shops:playerStateBags', function(source,value)
	local entity = NetworkGetEntityFromNetworkId(value.entity)
	local state = Entity(entity).state
	value.data.ts = os.time()
	if value.data.bagname == 'player:' then
		state = Player(tonumber(value.entity)).state
	end
	state:set(value.name, value.data, true)
	if value.data.remove then
		Wait(2000)
		state:set(value.name, nil, true)
	end
end)

AddStateBagChangeHandler('movableentity' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated) -- saves entities from client
	Wait(0)
	local net = tonumber(bagName:gsub('player:', ''), 10)
	if not movableentity[net] then movableentity[net] = {} end
	table.insert(movableentity[net],value.nets)
end)

RegisterCommand('delmov', function(source, args)
	local source = source
	DeletePlayerMovableEntity(source)
end)

AddStateBagChangeHandler('createpurchaseorder' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
	Wait(0)
	local net = tonumber(bagName:gsub('player:', ''), 10)
	if not value then return end
	purchaseorders[net] = value.purchase
end)

DeletePlayerMovableEntity = function(src, all) -- Delete Entities owned by player
	for id,entities in pairs(movableentity) do
		for k,v in pairs(entities) do
			for _,v in pairs(v) do
				local entity = NetworkGetEntityFromNetworkId(v)
				if all or src and id == src and DoesEntityExist(entity) then
					local ent = Entity(entity).state
					ent:set('movableshop', {identifier = ent.movableshop.identifier, type = ent.movableshop.type, selling = false}, true)
					Wait(1000)
					DeleteEntity(NetworkGetEntityFromNetworkId(v))
				end
			end
		end
		if id == src then
			movableentity[id] = nil
		end
	end
end

AddEventHandler('onResourceStop', function(re)
	if re == GetCurrentResourceName() then
		--SetResourceKvp('renzu_stores', json.encode(GlobalState.Stores))
		DeletePlayerMovableEntity(false,src)
		Wait(1210)
	end
end)

RegisterNetEvent('esx_multicharacter:relog', function()
	local source = source
	local xPlayer = GetPlayerFromId(source)
	for k,v in pairs(deliver) do
		for k2,v in pairs(v) do
			if v == xPlayer.identifier then
				deliver[k][k2] = nil
			end
		end
	end
	GlobalState.OngoingShip = deliver
	DeletePlayerMovableEntity(source)
end)

RegisterNetEvent("playerDropped",function()
	local source = source
	local xPlayer = GetPlayerFromId(source)
	for k,v in pairs(deliver) do
		for k2,v in pairs(v) do
			if v == xPlayer.identifier then
				deliver[k][k2] = nil
			end
		end
	end
	GlobalState.OngoingShip = deliver
	DeletePlayerMovableEntity(source)
end)

AddEventHandler('esx:onPlayerJoined', function(src, char, data)
	local src = src
	local char = char
	local data = data
	Wait(1000)
	local xPlayer = GetPlayerFromId(src)
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(src,j,old)
	local xPlayer = GetPlayerFromId(src)
	local new = false

end)


function SqlFunc(plugin,type,query,var)
	local wait = promise.new()
    if type == 'execute' and plugin == 'oxmysql' then
        exports.oxmysql:query(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'fetchAll' and plugin == 'oxmysql' then
		exports['oxmysql']:query(query, var, function(result)
			wait:resolve(result)
		end)
    end
	return Citizen.Await(wait)
end

local Charset = {}
for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end
local NumberCharset = {}
for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end
local temp = {}
CreateThread(function() -- get all existing plates and save to temp table for faster unique checking upon plate generation
    Wait(1000)
    local vehicles = SqlFunc('oxmysql','fetchAll','SELECT plate FROM  '..vehicletable..'',{})
    for k,v in pairs(vehicles) do
        if v.plate ~= nil then
            temp[v.plate] = v
        end
    end
end)

function GetRandomLetter(length)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)]
	else
		return ''
	end
end

function GenPlate(prefix)
    local plate = LetterRand()..' '..NumRand()
    if prefix then plate = prefix..' '..NumRand() end
    if temp[plate] == nil then
        return plate
    end
    Wait(1)
    return GenPlate(prefix)
end

exports('GenPlate', GenPlate)

function LetterRand()
    local emptyString = {}
    local randomLetter;
    while (#emptyString < 6) do
        randomLetter = GetRandomLetter(1)
        table.insert(emptyString,randomLetter)
        Wait(0)
    end
    local a = string.format("%s%s%s", table.unpack(emptyString)):upper()  -- "2 words"
    return a
end

function NumRand()
    local emptyString = {}
    local randomLetter;
    while (#emptyString < 6) do
        randomLetter = GetRandomNumber(1)
        table.insert(emptyString,randomLetter)
        Wait(0)
    end
    local a = string.format("%i%i%i", table.unpack(emptyString))  -- "2 words"
    return a
end

function GetRandomNumber(length)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
	else
		return ''
	end
end

TryInstallItems = function()
	local items = request('data/item_install')
	if canregister then -- will only work on my forked ox_inventory
		for k,v in pairs(items) do
			exports.ox_inventory:AddUsableItem(k, {
				label = v.label,
				description = v.description or '',
				weight = v.weight,
				client = v.client
			})
		end
	end
end

SetOxInvShopStock = function(data)
	exports.ox_inventory:ModifyShop({
		shopname = data.name,
		shopindex = data.index,
		item = data.itemname,
		value = data.value, -- can be string or number. eg if count should be number. currency are string. this
		parameter = 'count' -- count, price, currency. or any shop parameter. count will add if item count is existed
	})
end

AddEventHandler('onResourceStop', function(re)
	if re == 'ox_inventory' and shared.inventory == 'ox_inventory' then
		print("^1ox_inventory is stopped, ox_inventory is a dependency, make sure this resource is always started before ox_inventory^0")
		StopResource('renzu_shops')
	end
end)



exports('Inventory', Inventory)
lib.versionCheck('renzuzu/renzu_shops')