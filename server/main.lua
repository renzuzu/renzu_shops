GlobalState.Shipping = json.decode(GetResourceKvpString('shippingcompany') or '[]') or {}
GlobalState.Stores = json.decode(GetResourceKvpString('renzu_stores') or '[]') or {}
GlobalState.MovableShops = json.decode(GetResourceKvpString('movableshops') or '[]') or {}
GlobalState.JobShop = {}
local Items = {}
local purchaseorders = {}
vehicletable = 'owned_vehicles'
vehiclemod = 'vehicle'
owner = 'owner'
stored = 'stored'
local ox = exports.ox_inventory
local canregister = false
local checkox = function()
    _ = exports.ox_inventory.RegisterSingleShop
end

CreateThread(function()
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
	else -- if above condition is not possible , we will override ox_inventory shops
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
	local items = exports.ox_inventory:Items()
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
	TryInstallItems()
end)

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

isStoreOwned = function(store,index)
	local stores = GlobalState.Stores
	local shop = false
	for k,v in pairs(shared.OwnedShops) do
		if store == k then
			for k,v in pairs(v) do
				if index == k and stores[v.label] then
					shop = v.label
					break
				end
			end
		end
	end
	return shop, shop and stores[shop]
end

isMovableShop = function(type)
	return shared.MovableShops[type] or false
end

CheckItemData = function(data)
	for k,v in pairs(shared.Storeitems[data.shop]) do
		if data.item == v.name then
			return v.price
		end
	end
	return false
end

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

RemoveStockFromStore = function(data)
	local stores = GlobalState.Stores
	local success = false
	for k,v in pairs(shared.OwnedShops) do
		if k == data.shop then
			for k,v in pairs(v) do
				if data.index == k and stores[v.label] then
					itemtype = data.metadata and data.metadata.name and 'custom' or 'normal'
					itemname = data.metadata and data.metadata.name or data.item
					if stores[v.label].items[itemtype][itemname] == nil then stores[v.label].items[itemtype][itemname] = {} end
					if stores[v.label].items[itemtype][itemname].stock and tonumber(stores[v.label].items[itemtype][itemname].stock) >= data.amount then
						stores[v.label].items[itemtype][itemname].stock = tonumber(stores[v.label].items[itemtype][itemname].stock) - data.amount
						local price = stores[v.label].items[itemtype][itemname].price and tonumber(stores[v.label].items[itemtype][itemname].price) or CheckItemData(data)
						if price then
							if v.cashier then -- if cashier is enable store money to cashier
								if not stores[v.label].cashier then stores[v.label].cashier = {} end
								if stores[v.label].cashier[data.money] == nil then stores[v.label].cashier[data.money] = 0 end
								stores[v.label].cashier[data.money] = tonumber(stores[v.label].cashier[data.money]) + tonumber(price)
							else
								stores[v.label].money[data.money] = tonumber(stores[v.label].money[data.money]) + tonumber(price)
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

RemoveStockFromStash = function(data)
	local shopdata = shared.MovableShops[data.type].menu
	local items = {}
	for category,v in pairs(shopdata) do
		for k,v in pairs(v) do
			table.insert(items, {name = v.name, price = v.price, metadata = v.metadata})
		end
	end
	data.items = items
	local stash = GetStashData(data)
	if stash[data.metadata and data.metadata.name or data.item] >= data.amount then
		exports.ox_inventory:RemoveItem(data.identifier, data.item, data.amount, data.metadata) -- remove item from stash inventory
		if data.addmoney then
			exports.ox_inventory:AddItem(data.identifier, data.money, data.price * data.amount) -- add money directly to stash inventory
		end
		return true
	end
	return false
end

-- @args[1] = store type
-- @args[2] = storeindex
-- @args[3] = amount to add to all items
-- /addstockall General 1 999
lib.addCommand('group.admin', {'addstockall', 'addstock'}, function(source, args)
    AddStockInternal(args.shop,args.index,args.count,args.item)
end, {'shop:string', 'index:string', 'count:number', 'item:string'})

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
								stores[v2.label].items[itemtype][itemname].stock += tonumber(count)
								if stores[v2.label].items[itemtype][itemname].stock <= 0 then stores[v2.label].items[itemtype][itemname].stock = 0 end
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

lib.addCommand('group.admin', {'storeadmin', 'stores'}, function(source, args)
	local stores = GlobalState.Stores
	local ply = Player(source).state
	ply:set('storemanage',{data = stores, ts = os.time()}, true)
end, {})

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
lib.callback.register('renzu_shops:createShop', function(source,data)
	local path = 'config/ownedshops/'..data.type..'.lua'
	local path2 = 'config/defaultshops.lua'
	local defaultshops = shared.Shops
	local ownedshop = shared.OwnedShops[data.type]
	local index = #ownedshop+1
	if not data.shared.Shop then return false end
	if not data.shared.Storeowner then return false end
	if ownedshop then
		table.insert(ownedshop,{
			moneytype = ownedshop[1].moneytype,
			label = data.type..' #'..index,
			coord = data.shared.Storeowner,
			cashier = data.shared.Cashier,
			price = ownedshop[1].price,
			supplieritem = {}
		})
		table.insert(shared.Shops[data.type].locations,vec3(data.shared.Shop.x,data.shared.Shop.y,data.shared.Shop.z))
		local StoreItem = 'shared.Storeitems.'..data.type
		local ownedshops = 'return '
		ownedshops = ownedshops..tprint(ownedshop,nil,StoreItem)
		SaveResourceFile('renzu_shops', path, ownedshops, -1)
		local default = 'return '
		default = default..tprint(defaultshops,nil,StoreItem)
		SaveResourceFile('renzu_shops', path2, default, -1)
		GlobalState.CreateShop = {
			loc = vec3(data.shared.Shop.x,data.shared.Shop.y,data.shared.Shop.z),
			coord = data.shared.Storeowner,
			cashier = data.shared.Cashier,
			index = index,
			type = data.type,
			label = data.type..' #'..index,
			shop = {
				moneytype = ownedshop[1].moneytype,
				label = data.type..' #'..index,
				coord = data.shared.Storeowner,
				cashier = data.shared.Cashier,
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
				coord = vec3(data.shared.Shop.x,data.shared.Shop.y,data.shared.Shop.z)
			}, index,false,true)
		end
		return true
	end
	return false
end)

lib.callback.register('renzu_shops:addstock', function(source,data)
	-- lets secure by adding group check? not now another framework shit. is there a way to check ACL groups via libs? not yet?
	return AddStockInternal(data.shop,data.index,data.count,data.item)
end)

lib.callback.register('renzu_shops:removestock', function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local identifier = data.type..':'..xPlayer.identifier
	local storeowned, shopdata = isStoreOwned(data.type,data.index) -- check if this store has been owned by player
	if storeowned then
		local removed = RemoveStockFromStore({shop = data.type, metadata = data.metadata, index = data.index, item = data.name, amount = tonumber(data.count), price = data.price, money = data.money:lower()})
		if removed and data.citizen then
			exports.ox_inventory:AddItem(data.citizen, data.name, data.count, data.metadata) -- add money directly to stash inventory
			return true
		elseif removed then
			return true
		else
			return false
		end
	else
		return RemoveStockFromStash({identifier = identifier, metadata = data.metadata, item = data.name, amount = tonumber(data.count), price = data.price, type = data.type, money = 'money'})
	end
end)

lib.callback.register('renzu_shops:buyitem', function(source,data)
	local xPlayer = GetPlayerFromId(source)
	local storeowned, shopdata = isStoreOwned(data.shop,data.index) -- check if this store has been owned by player
	local movableshop = isMovableShop(data.index) -- check if this store is a movable type
	local hasitem = false
	local total = 0
	local customparts = {}
	for k,v in pairs(data.items) do -- iterate total prices in server and manage customise item data
		hasitem = true
		local name = v.data.metadata and v.data.metadata.name or v.data.name
		if v.count > 0 then
			total = total + tonumber(data.data[name].price) * tonumber(v.count)
		else
			data.items[k] = nil
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
				if not data.items[k].data.metadata then data.items[k].data.metadata = {} end -- incase metadata is not define in shop items.
				if not data.items[k].data.metadata['components'] then data.items[k].data.metadata['components'] = {} end
				data.items[k].data.metadata['components'] = metadata
			else
				if not data.items[k].data.metadata then data.items[k].data.metadata = {} end
				if not data.items[k].data.metadata['customise'] then data.items[k].data.metadata['customise'] = {} end
				data.items[k].data.metadata['customise'] = metadata
				data.items[k].data.metadata.description = desc
			end
		end
	end
	if not hasitem then
		return 'invalidamount'
	end
	data.type = data.type:gsub('Wallet',data.moneytype) -- check payment type
	local money = xPlayer.getAccount(data.type:lower()).money
	if xPlayer.getAccount(data.type:lower()).money >= total then
		xPlayer.removeAccountMoney(data.type:lower(),total)
		callback = 'success'
		for k,v in pairs(customparts) do -- remove custom items from cart as its inserted as custom item metadatas from the recent loop above
			for k,item in pairs(v) do
				for k2,v in pairs(data.items) do
					local name = v.data.metadata and v.data.metadata.name or v.data.name
					if item.name == name then
						if storeowned then -- storeowned Ownableshops data handler
							RemoveStockFromStore({shop = data.shop, metadata = v.data.metadata, require = v.data.require, index = data.index, item = v.data.name, amount = tonumber(v.count), price = data.data[v.data.name].price, money = data.type:lower()})
						elseif movableshop then -- movable shops logic data handler
							RemoveStockFromStash({addmoney = true, identifier = data.shop, metadata = v.data.metadata, item = v.data.name, amount = tonumber(v.count), price = data.data[v.data.name].price, type = data.index, money = data.type:lower()})
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
		for k,v in pairs(data.items) do
			if storeowned then -- storeowned Ownableshops data handler
				RemoveStockFromStore({shop = data.shop, metadata = v.data.metadata, require = v.data.require, index = data.index, item = v.data.name, amount = tonumber(v.count), price = data.data[v.data.name].price, money = data.type:lower()})
			elseif movableshop then -- movable shops logic data handler
				RemoveStockFromStash({addmoney = true, identifier = data.shop, metadata = v.data.metadata, item = v.data.name, amount = tonumber(v.count), price = data.data[v.data.name].price, type = data.index, money = data.type:lower()})
			end
			if data.shop ~= 'VehicleShop' then -- add new item if its not a vehicle type
				exports.ox_inventory:AddItem(source,v.data.name,v.count,v.data.metadata, false)
			else -- else if vehicle type add it to player vehicles table
				for i = 1, tonumber(v.count) do
					callback = GenPlate()
					SqlFunc('oxmysql','execute','INSERT INTO '..vehicletable..' (plate, '..vehiclemod..', '..owner..', '..stored..') VALUES (@plate, @'..vehiclemod..', @'..owner..', @'..stored..')',{
						['@plate']   = callback,
						['@'..vehiclemod..'']   = json.encode({model = GetHashKey(v.data.name), plate = callback, modLivery = tonumber(v.vehicle?.livery or -1), color1 = tonumber(v.vehicle?.color or 0)}),
						['@'..owner..'']   = xPlayer.identifier,
						['@'..stored..''] = 1
					})
				end
			end
			Wait(500)
		end
		return callback
	else
		return 'notenoughmoney'
	end
end)

lib.callback.register("renzu_shops:buystore", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	if xPlayer.getAccount('money').money >= data.price then
		local stores = GlobalState.Stores
		if not stores[data.label] then
			xPlayer.removeAccountMoney('money', data.price)
			stores[data.label] = {owner = xPlayer.identifier, money = {money = 0, black_money = 0}, items = {normal = {}, custom = {}}, employee = {}, cashier = { money = 0, black_money = 0}}
			SetResourceKvp('renzu_stores', json.encode(stores))
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
	end
end)

GlobalState.AvailableStore = {}
lib.callback.register("renzu_shops:sellstore", function(source,store)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local stores = GlobalState.Stores
	if stores[store] and stores[store].owner == xPlayer.identifier then
		stores[store] = nil
		SetResourceKvp('renzu_stores', json.encode(stores))
		GlobalState.Stores = stores
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
		return true
	end
end)

lib.callback.register("renzu_shops:createitem", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local stores = GlobalState.Stores
	if stores[data.store] and stores[data.store].owner == xPlayer.identifier then
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
		SetResourceKvp('renzu_stores', json.encode(stores))
		GlobalState.Stores = stores
		return true
	end
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
		SetResourceKvp('renzu_stores', json.encode(stores))
		return true
	end
	return false
end)

GlobalState.JobShopNotify = {}
lib.callback.register("renzu_shops:shopjobaccess", function(source,store)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local stores = GlobalState.Stores
	if stores[store] and stores[store].owner == xPlayer.identifier then
		stores[store].job = xPlayer.job.name
		GlobalState.Stores = stores
		SetResourceKvp('renzu_stores', json.encode(stores))
		local jobshop = GlobalState.JobShop
		jobshop[store] = xPlayer.job.name
		GlobalState.JobShop = jobshop
		GlobalState.JobShopNotify = {store = store, job = xPlayer.job.name, ts = os.time(), owner = xPlayer.identifier}
		return true
	end
	return false
end)

GlobalState.RobableStore = {}

Priority = function() -- your custom priority logic
	return true
end

GlobalState.ShopAlerts = {}
RobNotification = function(data) -- your custom Alert Notification
	GlobalState.ShopAlerts = {store = data.store, coord = data.coord, ts = os.time()}
	return true
end

local robbers = {}
lib.callback.register("renzu_shops:canrobstore", function(source,data)
	local rob = GlobalState.RobableStore
	if not rob[data.store] and Priority() or rob[data.store] <= os.time() and Priority() then
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
			local amount = math.random(15000,30000)
			exports.ox_inventory:AddItem(source, data.item, amount)
			return true
		else -- if store is owned by player
			local money = stores[data.store].cashier[data.item] or 0
			stores[data.store].cashier[data.item] = 0
			exports.ox_inventory:AddItem(source, data.item, money)
			GlobalState.Stores = stores
			return true
		end
	end
	return false
end)

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
		local data = exports.ox_inventory:Search(data.identifier, 'slots', v.name)
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

lib.callback.register("renzu_shops:getStashData", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local identifier = data.identifier
	return GetStashData(data)
end)

GetItemCountSingle = function(item,source)
	return exports.ox_inventory:Search(source,'count', item)
end

lib.callback.register("renzu_shops:craftitem", function(source,data)
	local source = source
	local items = shared.MovableShops[data.type].menu[data.menu]
	local xPlayer = GetPlayerFromId(source)
	local identifier = data.type..':'..xPlayer.identifier
	local inventoryid = data.stash and identifier or source -- declare where the inventory will be used for removing and adding items
	for k,v in pairs(items) do
		if v.metadata and v.metadata.name and v.metadata.name == data.item then
			local haverequired = true
			for k,v in pairs(v.ingredients) do
				if GetItemCountSingle(k,inventoryid) < v then
					haverequired = false
				end
			end
			if haverequired then
				for k,v in pairs(v.ingredients or {}) do
					exports.ox_inventory:RemoveItem(inventoryid, k, v, nil)
				end
				if not data.dontreceive then
					exports.ox_inventory:AddItem(inventoryid, v.name, 1, v.metadata or {})
				end
			end
		elseif v.metadata and not v.metadata.name and v.name == data.item or not v.metadata and v.name == data.item then
			local haverequired = true
			for k,v in pairs(v.ingredients or {}) do
				if GetItemCountSingle(k,inventoryid) < v then
					haverequired = false
				end
			end
			if haverequired then
				for k,v in pairs(v.ingredients) do
					exports.ox_inventory:RemoveItem(inventoryid, k, v, nil)
				end
				if not data.dontreceive then
					exports.ox_inventory:AddItem(inventoryid, v.name, 1, nil)
				end
			end
		end
	end
end)

lib.callback.register("renzu_shops:getmovableshopdata", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local identifier = data.type..':'..xPlayer.identifier
	exports.ox_inventory:RegisterStash(identifier, data.type, 40, 40000, false)
	return GlobalState.MovableShops[identifier]
end)

lib.callback.register("renzu_shops:buymovableshop", function(source,data)
	local source = source
	local xPlayer = GetPlayerFromId(source)
	local movable = GlobalState.MovableShops
	local identifier = data.type..':'..xPlayer.identifier
	if not movable[identifier] then
		if xPlayer.getAccount('money').money >= data.price then
			local plate = nil
			if data.shop.type == 'vehicle' then
				plate = GenPlate()
				SqlFunc('oxmysql','execute','INSERT INTO '..vehicletable..' (plate, '..vehiclemod..', '..owner..', '..stored..') VALUES (@plate, @'..vehiclemod..', @'..owner..', @'..stored..')',{
					['@plate']   = plate,
					['@'..vehiclemod..'']   = json.encode({model = data.model, plate = plate, modLivery = -1}),
					['@'..owner..'']   = xPlayer.identifier,
					['@'..stored..''] = 1
				})
			end
			xPlayer.removeAccountMoney('money', data.price)
			movable[identifier] = {identifier = xPlayer.identifier, money = {money = 0, black_money = 0}, items = {}, plate = plate, type = data.shop.type, shopname = data.type} -- literally plate and type is the only thing we save here as the other datas like money and items are saved using ox_inventory. first plan is to used owned inventory, same with the shop stocking system logic using ox contextmenus,  but instead i tried and successfully used ox inventory since this does not saved vehicle stocks datas.
			SetResourceKvp('movableshops', json.encode(movable))
			GlobalState.MovableShops = movable
			return movable[identifier]
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
				exports.ox_inventory:RegisterStash(identifier, v.shopname, 40, 40000, false)
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
		local type = data.type or 'item'
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
		SetResourceKvp('renzu_stores', json.encode(stores))
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
		SetResourceKvp('renzu_stores', json.encode(stores))
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
		end
	end
	SetResourceKvp('renzu_stores', json.encode(stores))
	GlobalState.Stores = stores
end

GetItemCount = function(item,metadata,source) -- temporary until ox search functions works correctly as i am having issues getting correct results with search with the metadata table or strings, bite me
	local data = exports.ox_inventory:Search(source, 'slots', item)
	local count = 0
	for k,v in pairs(data) do
		if v.metadata and v.metadata.name == metadata then -- our identifier to identify custom items
			count = count + 1
		end
	end
	return count
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
		itemtype = data.metadata and data.metadata.name and 'custom' or 'normal'
		itemname = data.metadata and data.metadata.name or data.item
		if stores[data.store].items[itemtype][itemname] == nil then stores[data.store].items[itemtype][itemname] = {} end
		stores[data.store].items[itemtype][itemname].price = data.value
		SetResourceKvp('renzu_stores', json.encode(stores))
		GlobalState.Stores = stores
		return 'success'
	elseif owned and stores[data.store] and data.type == 'deposit_item' then
		itemtype = data.metadata and data.metadata.name and 'custom' or 'normal'
		itemname = data.metadata and data.metadata.name or data.item
		local count = 0
		if data.metadata and data.metadata.name then
			count = GetItemCount(data.item,data.metadata.name,source)
		else
			count = exports.ox_inventory:Search(source, 'count', data.item)
		end
		if tonumber(data.value) and count >= data.value and data.value > 0 then
			exports.ox_inventory:RemoveItem(source, data.item, data.value, data.metadata and data.metadata.name and data.metadata or nil, slot)
			if stores[data.store].items[itemtype][itemname] == nil then stores[data.store].items[itemtype][itemname] = {} end
			local stock = stores[data.store].items[itemtype][itemname].stock
			if not stock then stores[data.store].items[itemtype][itemname].stock = 0 end
			stores[data.store].items[itemtype][itemname].stock = tonumber(stores[data.store].items[itemtype][itemname].stock) + data.value
			SetResourceKvp('renzu_stores', json.encode(stores))
			GlobalState.Stores = stores
			if canregister and shared.oxShops then
				local name, index, storedata = getShopDataByLabel(data.store)
				SetOxInvShopStock({name = name, index = index, item = itemname, value = data.value})
			end
			return 'success'
		end
	elseif owned and stores[data.store] and data.type == 'withdraw_item' then
		itemtype = data.metadata and data.metadata.name and 'custom' or 'normal'
		itemname = data.metadata and data.metadata.name or data.item
		if stores[data.store].items[itemtype][itemname] == nil then stores[data.store].items[itemtype][itemname] = {} end
		local count = tonumber(stores[data.store].items[itemtype][itemname].stock)
		if tonumber(data.value) and count and count >= data.value and data.value > 0 then
			stores[data.store].items[itemtype][itemname].stock = tonumber(stores[data.store].items[itemtype][itemname].stock) - data.value
			SetResourceKvp('renzu_stores', json.encode(stores))
			GlobalState.Stores = stores
			exports.ox_inventory:AddItem(source, data.item, data.value, data.metadata or {})
			if canregister and shared.oxShops then
				local name, index, storedata = getShopDataByLabel(data.store)
				SetOxInvShopStock({name = name, index = index, item = itemname, value = -data.value})
			end
			return 'success'
		end
	elseif owned and stores[data.store] and data.type == 'deposit_money' then
		local count = xPlayer.getAccount(data.item).money
		if tonumber(data.value) and count and count >= data.value and data.value > 0 then
			stores[data.store].money[data.item] = tonumber(stores[data.store].money[data.item]) + data.value
			SetResourceKvp('renzu_stores', json.encode(stores))
			GlobalState.Stores = stores
			xPlayer.removeAccountMoney(data.item,data.value)
			return 'success'
		end
	elseif owned and stores[data.store] and data.type == 'withdraw_money' then
		local count = tonumber(stores[data.store]?.money[data.item])
		if tonumber(data.value) and count and count >= data.value and data.value > 0 then
			stores[data.store].money[data.item] = tonumber(stores[data.store].money[data.item]) - data.value
			SetResourceKvp('renzu_stores', json.encode(stores))
			GlobalState.Stores = stores
			xPlayer.addAccountMoney(data.item,data.value)
			return 'success'
		end
	elseif owned and stores[data.store] and data.type == 'withdraw_cashier' then
		local count = tonumber(stores[data.store]?.cashier[data.item])
		if tonumber(data.value) and count and count >= data.value and data.value > 0 then
			if stores[data.store].cashier[data.item] == nil then stores[data.store].cashier[data.item] = 0 end
			stores[data.store].cashier[data.item] = tonumber(stores[data.store].cashier[data.item]) - data.value
			SetResourceKvp('renzu_stores', json.encode(stores))
			GlobalState.Stores = stores
			xPlayer.addAccountMoney(data.item,data.value)
			return 'success'
		end
	elseif owned and stores[data.store] and data.type == 'listing_edit' then
		itemtype = data.metadata and data.metadata.name and 'custom' or 'normal'
		itemname = data.metadata and data.metadata.name or data.item
		if stores[data.store].items[itemtype][itemname] == nil then stores[data.store].items[itemtype][itemname] = {} end
		if data.value == 'disable' then
			stores[data.store].items[itemtype][itemname].disable = 'disable'
			SetResourceKvp('renzu_stores', json.encode(stores))
			GlobalState.Stores = stores
			return 'success'
		elseif data.value == 'enable' then
			stores[data.store].items[itemtype][itemname].disable = nil
			SetResourceKvp('renzu_stores', json.encode(stores))
			GlobalState.Stores = stores
			return 'success'
		end
	end
	return false
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
			exports.ox_inventory:AddItem(source, 'money', total)
		end
	end
end)

local movableentity = {}
AddStateBagChangeHandler('renzu_shops:playerStateBags' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated) -- replicate Client State
	Wait(0)
	local net = tonumber(bagName:gsub('player:', ''), 10)
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
	table.insert(movableentity[net],value)
end)

RegisterCommand('delmov', function(source, args)
	local source = source
	DeletePlayerMovableEntity(source)
end)

AddStateBagChangeHandler('createpurchaseorder' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
	Wait(0)
	local net = tonumber(bagName:gsub('player:', ''), 10)
	if not value then return end
	purchaseorders[net] = value
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
		SetResourceKvp('renzu_stores', json.encode(GlobalState.Stores))
		DeletePlayerMovableEntity(false,src)
	end
end)

RegisterServerEvent("esx_multicharacter:relog")
AddEventHandler('esx_multicharacter:relog', function()
	local source = source
	DeletePlayerMovableEntity(source)
end)

AddEventHandler("playerDropped",function()
	local source = source
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