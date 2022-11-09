local self = setmetatable({}, Shops)
self.shopopen = false
self.Items = {}
self.temporalspheres = {}
self.Active = {}
self.Spheres = {}
self.__index = {}
self.currentstore = {}
self.moneytype = {}
self.itemLists = {}
self.PlayerData = {}
self.StartUp = function()
	self.PlayerData = self.GetPlayerData()
	Citizen.CreateThread(function()
		player = LocalPlayer.state
		Wait(2000)
		itemLists = exports.ox_inventory:Items()
		for k,v in pairs(itemLists) do
			self.Items[v.name] = v.label
		end
		for k,shop in pairs(config.Shops) do
			if shop.locations then
				for shopindex,v in ipairs(shop.locations) do
					shop.shoptype = k
					local ownedshopdata = self.GetShopData(k,shopindex)
					shop.groups = ownedshopdata and ownedshopdata.groups
					if not config.target then
						self.Add(v,shop.name,self.OpenShop,false,{shop = shop, index = shopindex, type = k, coord = v})
					elseif not shop.groups or shop.groups == self.PlayerData.job.name then
						self.addTarget(v,shop.name,self.OpenShop,false,{shop = shop, index = shopindex, type = k, coord = v})
					end
					self.ShopBlip({coord = v, text = shop.name, blip = shop.blip or false})
				end
			end
		end
		for k,shop in pairs(config.MovableShops) do
			if not config.target then
				self.Add(shop.coord,shop.label,self.MovableShop,false,{shop = shop, type = k, price = shop.price, label = shop.label})
			else
				self.addTarget(shop.coord,shop.label,self.MovableShop,false,{shop = shop, type = k, price = shop.price, label = shop.label})
			end
			self.ShopBlip({coord = shop.coord, text = shop.label, blip = shop.blip or false})
		end
		self.LoadShops()
	end)
end

self.SetNotify = function(data)
	lib.notify({title = data.title, description = data.description, type = data.type, style = {zIndex = 9999999}})
end

self.lastdata = nil
self.addTarget = function(coord,msg,callback,server,var,delete,auto)
	return exports.ox_target:addBoxZone({
		coords = coord+vec3(0.0,0.0,0.2),
		size = vec3(1.5, 2, 1.5),
		rotation = 45,
		debug = false,
		drawSprite = true,
		options = {
			{
				distance = 1.5,
				groups = var.shop?.groups,
				onSelect = function()
					self.Active = lib.table.deepclone(var)
					self.lastdata = var.index
					self.movabletype = var.type
					callback(var)
				end,
				name = msg,
				icon = 'fas fa-shopping-basket',
				label = msg,
				canInteract = function(entity, distance, coords, name)
					return true
				end
			}
		}
	})
end

self.Add = function(coord,msg,callback,server,var,delete,auto)
	local var = var
	local textui = false
	function onExit(data)
		textui = false
		lib.hideTextUI()
		self.Active = nil
		self.lastdata = nil
	end

	function inside(data)
		local data = data
		local group = data?.var?.shop?.groups
		if group and group ~= self.PlayerData?.job?.name then return end
		local shopboss = self.delivery and callback == self.StoreOwner
		local drawdist = 1.1
		if self.shoptype == 'vehicle' then
			drawdist = 7.5
		end
		if data.var.type and config.MovableShops[data.var.type] and callback == self.OpenShopMovable then
			if not NetworkDoesNetworkIdExist(data.var.net) 
				or not DoesEntityExist(NetworkGetEntityFromNetworkId(data.var.net)) then
				data:remove()
				return
			end
		end
		if data.distance < 1.1 and self.lastdata ~= data.index then
			self.Active = lib.table.deepclone(data.var)
			self.lastdata = data.index
			self.movabletype = data.var.type
		end
		if config.MovableShops[data.var.type] and self.clerkmode then Wait(20) end
		if not self.clerkmode then
			DrawMarker(21, data.coords.x, data.coords.y, data.coords.z, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 200, 255, 255, 255, 0, 0, 1, 1, 0, 0, 0)
		end
		if not textui and data.distance < drawdist then textui = true self.OxlibTextUi("Press [E] "..msg) elseif data.distance > drawdist+1 and textui then textui = false data.onExit() end
		if data.distance < drawdist and IsControlJustReleased(0,38) and not shopboss or auto then
			LocalPlayer.state.invOpen = callback == self.OpenShop and true
			if delete then
				data:remove()
			end
			callback(data.var)
			while LocalPlayer.state.invOpen and callback == self.OpenShop do
				TriggerEvent('ox_inventory:closeInventory')
				Wait(10)
			end
			if callback == self.OpenShop then
				TriggerScreenblurFadeIn(0)
			end
		end
	end
	SetRandomSeed(GetGameTimer()+math.random(1,99))
	local sphere = lib.zones.sphere({ index = GetRandomIntInRange() ,var = lib.table.deepclone(var) , coords = coord, radius = 10, debug = false, inside = inside, onEnter = onEnter, onExit = onExit })
	table.insert(self.Spheres,sphere)
	return sphere
end

self.ShopBlip = function(data)
	if not data.blip then return end
	local blip = AddBlipForCoord(data.coord.x,data.coord.y,data.coord.z)
	SetBlipSprite(blip,data.blip.id)
	SetBlipColour(blip,data.blip.colour)
	SetBlipScale(blip,data.blip.scale)
	SetBlipAsShortRange(blip,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName(data.text)
	EndTextCommandSetBlipName(blip)
end

self.LoadShops = function()
	if self.PlayerData.identifier == nil then return end
	local stores = GlobalState.Stores or {}
	for name,shops in pairs(config.OwnedShops) do
		for k,shop in pairs(shops) do
			if self.temporalspheres[shop.label] then
				self.temporalspheres[shop.label]:remove()
			end
			if not stores[shop.label] then
				if not config.target then
					local spheres = self.Add(shop.coord,'Buy '..name..' #'..k,self.BuyStore,false,shop)
					self.temporalspheres[shop.label] = {spheres = spheres, coord = shop.coord, shop = shop, label = 'My Store '..shop.label}
				else
					self.addTarget(shop.coord,'Buy '..name..' #'..k,self.BuyStore,false,shop)
				end
			elseif stores[shop.label]?.owner == self.PlayerData.identifier or stores[shop.label]?.employee[self.PlayerData.identifier] then
				if not config.target then
					self.temporalspheres[shop.label] = self.Add(shop.coord,'My Store '..shop.label,self.StoreOwner,false,shop)
				else
					self.addTarget(shop.coord,'My Store '..shop.label,self.StoreOwner,false,shop)
				end
				self.ShopBlip({coord = shop.coord, text = 'My Store '..shop.label, blip = {colour = 38, id = 374, scale = 0.6}})
			end
			if shop.cashier then
				shop.index = k
				shop.type = name
				shop.offset = config.Shops[name].locations[k]
				if not config.target then
					self.Add(shop.cashier,'Cashier '..shop.label,self.Cashier,false,shop)
				else
					self.addTarget(shop.cashier,'Cashier '..shop.label,self.Cashier,false,shop)
				end
			end
		end
	end
	if not config.target then
		self.Add(config.shipping.coord,config.shipping.label,self.Shipping,false,{})
	else
		self.addTarget(config.shipping.coord,config.shipping.label,self.Shipping,false,{})
	end
	self.ShopBlip({coord = config.shipping.coord, text = config.shipping.label, blip = config.shipping.blip})
end
self.duty = {}
self.Cashier = function(data)
	local storedata = {index = data.index, type = data.type, offset = data.offset, money = data.moneytype}
	local options = {}
	local stores = GlobalState.Stores
	if self.duty[data.label] and stores[data.label].owner == self.PlayerData.identifier then
		local cashier = stores[data.label].cashier and stores[data.label].cashier[data.moneytype] or 0
		table.insert(options,{
			title = 'Withdraw Money from Cashier',
			description = 'Money in Cashier : '..cashier,
			arrow = true,
			onSelect = function(args)
				local input = lib.inputDialog('Withdraw Cashier Money', {'How many:'})
				if not input then return end
				local value = tonumber(input[1])
				local reason = lib.callback.await('renzu_shops:editstore', false, {store = data.label, type = 'withdraw_cashier', item = data.moneytype, value = value})
				if reason == 'success' then
					self.SetNotify({
						title = 'Store Business',
						description = 'Successfully Withdraw '..value..'$',
						type = 'success'
					})
				end
			end
		})
		table.insert(options,{
			title = 'Ongoing Purchase Order',
			description = 'See list of purchase orders from nearby people',
			arrow = true,
			onSelect = function(args)
				self.PurchaseOrderList(data,storedata)
			end
		})
		table.insert(options,{
			title = 'Duty Off',
			description = 'Duty of as Store Clerk : Stop Ondemand Selling',
			arrow = true,
			onSelect = function(args)
				self.duty[data.label] = false
				self.OnDemand(data,'store',storedata)
			end
		})
	elseif not self.duty[data.label] and stores[data.label] and stores[data.label].owner == self.PlayerData.identifier then
		table.insert(options,{
			title = 'Duty On & Ondemand Selling',
			description = 'Duty as a Store Clerk : Start Ondemand Selling',
			arrow = true,
			onSelect = function(args)
				self.duty[data.label] = not self.duty[data.label]
				self.SetNotify({
					title = 'Store Business',
					description = 'Successfully Duty as Store Clerk',
					type = 'success'
				})
				self.Cashier(data)
				self.OnDemand(data,'store',storedata)
			end
		})
	elseif not self.duty[data.label] then
		table.insert(options,{
			title = 'Rob the Cashier',
			description = 'Force to open the cashier?',
			arrow = true,
			onSelect = function(args)
				local confirm = lib.alertDialog({
					header = 'Confirm',
					content = 'Do you really want to rob this store?',
					centered = true,
					cancel = true
				})
				if confirm ~= 'cancel' then
					local canrob = lib.callback.await('renzu_shops:canrobstore', false, {store = data.label, item = data.moneytype})
					if canrob then
						local success = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 2}, 'hard'})
						if success then
							local rob = lib.callback.await('renzu_shops:robstore', false, {store = data.label, item = data.moneytype})
							if rob then
								self.SetNotify({
									title = 'Store Business',
									description = ' You Successfully Rob This Store',
									type = 'success'
								})
							end
						end
					else
						self.SetNotify({
							title = 'Store Business',
							description = ' This store cannot be rob right now',
							type = 'error'
						})
					end
					-- local reason = lib.callback.await('renzu_shops:editstore', false, {store = data.label, type = 'withdraw_cashier', item = data.moneytype, value = value})
					-- if reason == 'success' then
					-- 	self.SetNotify({
					-- 		title = 'Store Business',
					-- 		description = 'Successfully Withdraw '..value..'$',
					-- 		type = 'success'
					-- 	})
					-- end
				end
			end
		})
	end
	lib.registerContext({
		id = 'cashier',
		title = 'My Cashier',
		onExit = function()
		end,
		options = options
	})
	lib.showContext('cashier')
end

self.StoreManage = function(store)
	self.adminmode = false
	local options = {
		{
			title = 'Manage Store',
			description = 'Manage Store items and Store Finance',
			arrow = true,
			menu = 'manage_store',
		}
	}
	local stores = GlobalState.Stores
	if stores[store].owner == self.PlayerData.identifier then
		table.insert(options,{
			title = 'Sell Store',
			description = 'Sell your store',
			arrow = true,
			onSelect = function(args)
				CreateThread(function()
					local confirm = lib.alertDialog({
						header = 'Confirm',
						content = 'Do you really want to sell this store?',
						centered = true,
						cancel = true
					})
					local reason = lib.callback.await('renzu_shops:sellstore', false, store)
					if reason then
						self.SetNotify({
							title = 'Store Business',
							description = store..' has been Sold',
							type = 'success'
						})
						if self.temporalspheres[store] then
							self.temporalspheres[store]:remove()
						end
					end
				end)
			end,
		})
	end
	lib.registerContext({
		id = 'storeowner',
		title = 'My Bussiness',
		onExit = function()
		end,
		options = options
	})
end

self.ManageStoreMenu = function(store)
	local options = {
		{
			title = 'Store Inventory',
			description = 'Manage Store Stocks',
			arrow = true,
			onSelect = function(args)
				return self.ManageInventory(store)
			end
		},
		{
			title = 'Finance Management',
			description = 'Here you can withdraw and deposit a money',
			arrow = true,
			menu = 'finance_manage',
		}
	}
	local stores = GlobalState.Stores
	if stores[store].owner == self.PlayerData.identifier or self.adminmode then
		table.insert(options,{
			title = 'Employee Management',
			description = 'Here you can add employee to help you manage your store',
			arrow = true,
			menu = 'employee_manage',
		})
	end
	lib.registerContext({
		id = 'manage_store',
		title = 'Manage Store',
		menu = self.adminmode and 'storeadminlist' or 'storeowner',
		onExit = function()
		end,
		options = options
	})
end

self.StoreOwner = function(data)
	local stores = GlobalState.Stores
	self.currentstore = data.label
	self.shoptype = data.type
	self.moneytype = data.moneytype
	if stores[self.currentstore] and stores[self.currentstore].owner == self.PlayerData.identifier
	or stores[self.currentstore] and stores[self.currentstore]?.employee[self.PlayerData.identifier] then
		self.FinanceManage(self.currentstore,data.moneytype)
		self.EmployeeManage(self.currentstore)
		self.ManageStoreMenu(self.currentstore)
		self.StoreManage(self.currentstore)
		lib.showContext('storeowner')
	else
		self.SetNotify({title = 'Store Business',description = 'You Are Fired',type = 'error'})
		if self.temporalspheres[self.currentstore] then
			self.temporalspheres[self.currentstore].spheres:remove()
		end
	end
end

self.RemoveEmployee = function(data)
	local options = {}
	for k,v in pairs(data.employee) do
		table.insert(options,{
			title = 'Fire '..v,
			description = 'Remove '..v..' to your Store Employees',
			arrow = true,
			onSelect = function(args)
				local reason = lib.callback.await('renzu_shops:removeemployee', false, {store = data.store, id = k})
				self.SetNotify({title = 'Store Business',description = 'Successfully Remove '..v,type = 'success'})
			end
		})
	end
	lib.registerContext({
		id = 'remove_employee',
		title = 'Fire Employees',
		menu = 'employee_manage',
		onExit = function()

		end,
		options = options
	})
	lib.showContext('remove_employee')
end

self.AddEmployee = function(data)
	local options = {}
	for k,v in pairs(data.players) do
		table.insert(options,{
			title = GetPlayerName(v.id),
			description = 'Citizen ID #'..GetPlayerServerId(v.id),
			arrow = true,
			onSelect = function(args)
				local reason = lib.callback.await('renzu_shops:addemployee', false, {store = data.store, id = GetPlayerServerId(v.id)})
				if reason == true then
					self.SetNotify({
						title = 'Store Business',
						description = 'Offer Accepted by '..GetPlayerName(v.id),
						type = 'success'
					})
				elseif reason == 'already' then
					self.SetNotify({
						title = 'Store Business',
						description = GetPlayerName(v.id)..' is Already Employed to this Store',
						type = 'error'
					})
				else
					self.SetNotify({
						title = 'Store Business',
						description = 'Offer Declined by '..GetPlayerName(v.id),
						type = 'error'
					})
				end
			end
		})
	end
	lib.registerContext({
		id = 'add_employee',
		title = 'Invite Employees',
		menu = 'employee_manage',
		onExit = function()
		end,
		options = options
	})
	lib.showContext('add_employee')
end

self.EmployeeManage = function(store)
	lib.registerContext({
		id = 'employee_manage',
		title = 'Manage Employees',
		menu = 'manage_store',
		onExit = function()
		end,
		options = {
			{
				title = 'Add Employee',
				description = 'Add nearby citizen to your employee list',
				arrow = true,
				onSelect = function(args)
					local players = lib.getNearbyPlayers(cache.coords, 50.0, true)
					self.AddEmployee({players = players, store = store})
				end
			},
			{
				title = 'Remove Employee',
				description = 'Remove Your Employees',
				arrow = true,
				onSelect = function(args)
					local stores = GlobalState.Stores
					if stores[store].employee then
						self.RemoveEmployee({employee = stores[store].employee, store = store})
					end
				end
			}
		}
	})
end

self.FinanceManage = function(store,money)
	lib.registerContext({
		id = 'finance_manage',
		title = 'Manage Finance',
		menu = 'manage_store',
		onExit = function()
		end,
		options = {
			{
				title = 'Total Money in Vault: '..GlobalState.Stores[store].money[money]..'$',
			},
			{
				title = 'Withdraw Money',
				description = 'withdraw money to your pocket',
				arrow = true,
				onSelect = function(args)
					local input = lib.inputDialog('Withdraw Store Money', {'How many:'})
					if not input then return end
					local value = tonumber(input[1])
					local reason = lib.callback.await('renzu_shops:editstore', false, {store = store, type = 'withdraw_money', item = money, value = value})
					if reason == 'success' then
						self.SetNotify({
							title = 'Store Business',
							description = 'Successfully Withdraw '..value..'$',
							type = 'success'
						})
					else
						self.SetNotify({
							title = 'Store Business',
							description = 'Not Enough '..self.Items[money]..' Withdraw '..value..'$',
							type = 'error'
						})
					end
				end
			},
			{
				title = 'Deposit Money',
				description = 'deposit money from your pocket',
				arrow = true,
				onSelect = function(args)
					local input = lib.inputDialog('Deposit Money to Store :', {'How many:'})
					if not input then return end
					local value = tonumber(input[1])
					local reason = lib.callback.await('renzu_shops:editstore', false, {store = store, type = 'deposit_money', item = money, value = value})
					if reason == 'success' then
						self.SetNotify({
							title = 'Store Business',
							description = 'Successfully Deposit '..value..'$',
							type = 'success'
						})
					else
						self.SetNotify({
							title = 'Store Business',
							description = 'Not Enough '..self.Items[money]..' Deposit '..value..'$',
							type = 'error'
						})
					end
				end
			}
		}
	})
end

self.getShopTypeAndIndex = function(store)
	for type,shop in pairs(config.OwnedShops) do
		for index,v in pairs(shop) do
			if v.label == store then
				return type, index, v
			end
		end
	end
	return false
end

self.EditItem = function(data, store, cat)
	local data = data
	local item = data.label
	local options = {}
	if self.adminmode then
		table.insert(options,{
			title = 'Add / Remove '..item..'',
			description = 'Add Supply '..item..' to this Store',
			arrow = true,
			onSelect = function(args)
				local input = lib.inputDialog('How Many :'..item..'   \n Min: -999 Max 999', {'Value can be Positive or Negative:'})
				if not input then return end
				local amount = tonumber(input[1])
				if amount < -1000 then return end
				if amount > 1000 then return end
				local confirm = lib.alertDialog({
					header = 'Confirm',
					content = 'Do you really want to Add this '..item..'? \n Total : '..amount..' $',
					centered = true,
					cancel = true
				})
				if confirm ~= 'cancel' then
					local shop, index = self.getShopTypeAndIndex(store)
					local data = lib.callback.await('renzu_shops:addstock', false, {shop = shop, index = index, count = amount, item = data.nameindex})
					if data then
						self.SetNotify({
							title = 'Store Business',
							description = 'Item Supply has been Added to this Store',
							type = 'success'
						})
					end
				end
			end
		})
	else
		table.insert(options,{
			title = 'Order '..item..' from Supplier',
			description = 'Create a Order for 100x '..item..'',
			arrow = true,
			onSelect = function(args)
				local input = lib.inputDialog('How Many :'..item..'   \n Min: 5 Max 100', {'Whole Sale Price: '..data.pricing.original * config.discount..'$'})
				if not input then return end
				local wholesaleorder = tonumber(input[1])
				if wholesaleorder < 5 then return end
				if wholesaleorder > 100 then return end
				local fee = data.pricing.original * wholesaleorder * config.discount
				local confirm = lib.alertDialog({
					header = 'Confirm',
					content = 'Do you really want order this to supplier? \n Total Funds Needed: '..fee..' $',
					centered = true,
					cancel = true
				})
				if confirm ~= 'cancel' then
					local data = lib.callback.await('renzu_shops:createshoporder', false, {moneytype = self.moneytype, item = data, store = store, metadata = data.metadata, amount = wholesaleorder, type = self.shoptype})
					if data then
						if data.moneytype == 'money' then
							self.SetNotify({
								title = 'Store Business',
								description = 'Order Success - The Shipping Company will handle the Delivery',
								type = 'success'
							})
						else
							self.SetNotify({
								title = 'Store Business',
								description = 'Order Success - Go and Pickup Your Order',
								type = 'success'
							})
							self.StartDelivery({dist = 0, store = store, index = 0, data = data, type = data.type, selfdeliver = config.OwnedShops[self.ShopType][self.ShopIndex].selfdeliver})
						end
					else
						self.SetNotify({
							title = 'Store Business',
							description = 'Order Failed - Not Enough Funds in Vault',
							type = 'error'
						})
					end
				end
			end
		})
	end
		table.insert(options,{
			title = 'Change Price of '..item,
			description = 'Modify the Value of '..item..'',
			arrow = true,
			onSelect = function(args)
				local input = lib.inputDialog('Edit Price :'..item, {'Current value: '..data.pricing.shop..'$'})
				if not input then return end
				local newprice = tonumber(input[1])
				local reason = lib.callback.await('renzu_shops:editstore', false, {store = store, type = 'price', item = data.name, value = newprice, metadata = data.metadata})
				if reason == 'success' then
					self.SetNotify({
						title = 'Store Business',
						description = 'Price has been updated',
						type = 'success'
					})
				elseif reason == 'invalidvalue' then

				elseif reason == 'invalidamount' then

				end
			end
		})
		table.insert(options,{
			title = 'Deposit '..item,
			description = 'Deposit '..item..' from your inventory',
			arrow = true,
			onSelect = function(args)
				local input = lib.inputDialog('Deposit :'..item, {'How many:'})
				if not input then return end
				local value = tonumber(input[1])
				local reason = lib.callback.await('renzu_shops:editstore', false, {store = store, type = 'deposit_item', item = data.name, value = value, metadata = data.metadata})
				if reason == 'success' then
					self.SetNotify({
						title = 'Store Business',
						description = 'Successfully Deposit x'..value..' '..item,
						type = 'success'
					})
				end
			end
		})
		table.insert(options,{
			title = 'Withdraw '..item,
			description = 'Withdraw '..item..' to your inventory',
			arrow = true,
			onSelect = function(args)
				local input = lib.inputDialog('Withdraw :'..item, {'How many:'})
				if not input then return end
				local value = tonumber(input[1])
				local reason = lib.callback.await('renzu_shops:editstore', false, {store = store, type = 'withdraw_item', item = data.name, value = value, metadata = data.metadata})
				if reason == 'success' then
					self.SetNotify({
						title = 'Store Business',
						description = 'Successfully Withdraw x'..value..' '..item,
						type = 'success'
					})
				end
			end
		})

	if data.disable then
		table.insert(options, {
			title = 'Enable '..item,
			description = 'Enable '..item..' from your Sales lists',
			arrow = true,
			onSelect = function(args)
				local confirm = lib.alertDialog({
					header = 'Confirm',
					content = 'Do you really want Enable the item on sale lists?',
					centered = true,
					cancel = true
				})
				if confirm ~= 'cancel' then
					local reason = lib.callback.await('renzu_shops:editstore', false, {store = store, type = 'listing_edit', item = data.name, value = 'enable', metadata = data.metadata})
					if reason == 'success' then
						self.SetNotify({
							title = 'Store Business',
							description = 'Successfully Enable '..item..' from Sales lists',
							type = 'success'
						})
					end
				end
	
			end
		})
	else
		table.insert(options, {
			title = 'Remove '..item,
			description = 'Remove '..item..' from your Sales lists',
			arrow = true,
			onSelect = function(args)
				local confirm = lib.alertDialog({
					header = 'Confirm',
					content = 'Do you really want Remove the item on sale lists? \n You can add it back later',
					centered = true,
					cancel = true
				})
				if confirm ~= 'cancel' then
					local reason = lib.callback.await('renzu_shops:editstore', false, {store = store, type = 'listing_edit', item = data.name, value = 'disable', metadata = data.metadata})
					if reason == 'success' then
						self.SetNotify({
							title = 'Store Business',
							description = 'Successfully Disable '..item..' from Sales lists',
							type = 'success'
						})
					end
				end

			end
		})
	end
	lib.registerContext({
		id = 'edititem'..item,
		title = 'Edit '..item,
		menu = cat,
		onExit = function()
		end,
		options = options
	})
end

self.CheckItemPrice = function(item)
	local price = 0
	local items = config.Storeitems[self.ShopType]
	for k,v in pairs(items) do
		if item == v.name then
			price = v.price
			return price
		end
	end
	return false
end

self.ManageInventory = function(store)
	local data = GlobalState.Stores
	local inventory = {}
	local stocks = {}
	local prices = {}
	local disable = {}
	local store = store
	for shoptype,v in pairs(config.OwnedShops) do
		for k,v in pairs(v) do
			if v.label == store then
				inventory = v.supplieritem
				self.ShopType = shoptype
				self.ShopIndex = k
			end
		end
	end
	local storeinventory = {}
	local options = {}
	local stores = data
	local cats = {}
	local catitems = {}
	for k,v in pairs(inventory) do
		local item = v
		local storedata = stores[store]
		local storeitems = storedata.items
		local itemdata = storeitems.normal[item.name]
		local originalprice = self.CheckItemPrice(item.name)
		local pricing = {original = originalprice, shop = itemdata?.price or originalprice}
		local category = itemdata?.category or item.category or 'No Category'
		local stock = itemdata?.stock
		local disable = itemdata?.disable
		local label = self.Items[item.name] or item.label or item.name
		local metadata = item.metadata
		local name = item.name
		if item.metadata and item.metadata.name then
			label = metadata.label or label
			itemdata = storeitems.custom[metadata.name]
			stock = itemdata?.stock
			category = itemdata?.category or item.category or 'No Category'
			pricing = {original = originalprice, shop = itemdata?.price or originalprice}
			disable = itemdata?.disable
			name = item.metadata.name
		end
		--local item = self.Items[v.name]
		if item then
			item.nameindex = name
			item.disable = false
			item.label = label
			if disable then item.disable = true end
			item.pricing = pricing
			storeinventory[item.name] = stock or 0
			if not catitems[category] then catitems[category] = {} end
			--table.insert(catitems[category],)
			table.insert(catitems[category], {
				title = label..' : instock: '..tostring(storeinventory[item.name]),
				arrow = true,
				menu = 'edititem'..label,
			})
			if not cats[category] then
				cats[category] = true
				table.insert(options, {
					title = category:upper(),
					arrow = true,
					menu = 'category_'..category,
					onSelect = function(args)
						--self.EditItem(item,store,'category_'..category)
					end
				})
			end
			self.EditItem(item,store,'category_'..category)
		end
	end
	for k,v in pairs(catitems) do
		lib.registerContext({
			id = 'category_'..k,
			title = 'Manage '..k:upper(),
			menu = 'manage_inventory',
			onExit = function()
			end,
			options = catitems[k]
		})
	end
	lib.registerContext({
		id = 'manage_inventory',
		title = 'Store Inventory',
		menu = 'manage_store',
		onExit = function()
		end,
		options = options
	})
	lib.showContext('manage_inventory')
	--lib.showContext('manage_inventory')
end

self.BoxObject = function(dict,anim,prop,flag,hand)
	local ped = self.playerPed
	lib.requestModel(GetHashKey(prop))
	lib.requestAnimDict(dict)
	TaskPlayAnim(ped,dict,anim,3.0,3.0,-1,flag,0,0,0,0)
	local coords = GetOffsetFromEntityInWorldCoords(ped,0.0,0.0,-5.0)
	object = CreateObjectNoOffset(GetHashKey(prop),coords.x,coords.y,coords.z,true,true)
	while not DoesEntityExist(object) do Wait(0) end
	SetEntityCollision(object,false,false)
	AttachEntityToEntity(object,ped,GetPedBoneIndex(ped,hand),0.0,0.0,0.0,0.0,0.0,0.0,false,false,false,false,2,true)
	Citizen.InvokeNative(0xAD738C3085FE7E11,object,true,true)
	return object
end

self.SetBlip = function(blip,sprite,color,text)
	local blip = blip
	SetBlipSprite(blip,sprite)
	SetBlipColour(blip,color)
	SetBlipAsShortRange(blip,false)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandSetBlipName(blip)
end

self.pickupzone = nil
self.Vehicle = nil
self.deliverydata = nil
self.StartDelivery = function(var)
	self.deliverydata = var
	CreateThread(function()
		local data = var.data
		local success = lib.callback.await('renzu_shops:startdelivery', false, var)
		if success == 'alreadyongoing' then
			self.SetNotify({
				title = 'Store Business',
				description = 'You have ongoing Delivery',
				type = 'error'
			})
			return
		end
		local type = var.type or 'item'
		self.shoptype = type
		local label = self.Items[data.item.name] or data.item.label
		local spawn = config.shipping.spawn
		local model = config.shipping.model[type]
		if var.selfdeliver then
			spawn = var.selfdeliver.coord
			model = var.selfdeliver.model
		end
		lib.requestModel(model)
		self.Vehicle = CreateVehicle(model, spawn.x,spawn.y,spawn.z, spawn.w, true, true) -- Spawns a networked self.Vehicle on your current coords
		while not DoesEntityExist(self.Vehicle) do Wait(1) end
		if type == 'vehicle' then
			self.pickupzone = self.Add(data.point,'Pick Up '..label,self.DelivertoVehicleShop,false,var,false)
		else
			self.pickupzone = self.Add(data.point,'Pick Up '..label,self.DelivertoStore,false,var,false)
		end
		truckblip = AddBlipForEntity(self.Vehicle)
		self.SetBlip(truckblip,477,26,'My Delivery Truck')
		DoScreenFadeIn(333)
		SetNewWaypoint(vec3(data.point[1],data.point[2],data.point[3]))
		deliveryblip = AddBlipForCoord(data.point[1],data.point[2],data.point[3])
		self.SetBlip(deliveryblip,358,26,'My Pick Up Point')
		SetBlipRoute(deliveryblip,true)
		SetBlipRouteColour(deliveryblip,3)
		self.SetNotify({
			title = 'Store Business',
			description = 'Go to the Pick Up Location and Pick Up The Item',
			type = 'inform'
		})
	end)
end

self.deliveryzone = nil
self.delivery = false
self.trailertransport = nil
self.DelivertoVehicleShop = function(var)
	local data = var.data
	self.pickupzone:remove()
	if DoesBlipExist(deliveryblip) then
		RemoveBlip(deliveryblip)
	end
	self.delivery = true
	self.trailertransport = CreateVehicle(GetHashKey('tr4'), data.point[1],data.point[2],data.point[3],data.point[4], true, true)
	while not DoesEntityExist(self.trailertransport) do Wait(1) end
	SetEntityHeading(self.Vehicle,data.point[4])
	AttachVehicleToTrailer(self.Vehicle,self.trailertransport, 1.00)
	while not GetVehicleTrailerVehicle(self.Vehicle) == self.trailertransport do Wait(100) end
	local data = var
	local storecoord = vec3(0.0,0.0,0.0)
	local restockcoord = nil
	for k,v in pairs(config.OwnedShops) do
		for k,v in pairs(v) do
			if v.label == data.store then
				storecoord = v.coord
				restockcoord = v.restock
			end
		end
	end
	if restockcoord then
		storecoord = restockcoord
	end
	SetNewWaypoint(storecoord)
	deliveryblip = AddBlipForCoord(storecoord.x,storecoord.y,storecoord.z)
	self.SetBlip(deliveryblip,358,26,'My Delivery Point')
	SetBlipRoute(deliveryblip,true)
	SetBlipRouteColour(deliveryblip,3)
	textui = false
	self.SetNotify({
		title = 'Store Business',
		description = 'Deliver the vehicle to the Store Location',
		type = 'inform'
	})
	self.Add(vec3(storecoord.x,storecoord.y,storecoord.z),'Deliver Vehicles',self.DeliverDone,false,data,true)
end

self.DelivertoStore = function(data)
	self.pickupzone:remove()
	if DoesBlipExist(deliveryblip) then
		RemoveBlip(deliveryblip)
	end
	self.delivery = true
	local object = self.BoxObject("anim@heists@box_carry@","idle","hei_prop_heist_box",50,28422)
	SetVehicleDoorOpen(self.Vehicle,2,0,0)
	SetVehicleDoorOpen(self.Vehicle,3,0,0)
	SetVehicleDoorOpen(self.Vehicle,5,0,0)

	local xa,ya,za = table.unpack(GetWorldPositionOfEntityBone(self.Vehicle,GetEntityBoneIndexByName(self.Vehicle,"door_dside_r")))
	local xb,yb,zb = table.unpack(GetWorldPositionOfEntityBone(self.Vehicle,GetEntityBoneIndexByName(self.Vehicle,"door_pside_r")))

	local x = (xa+xb)/2
	local y = (ya+yb)/2
	local z = (za+zb)/2
	local textui = false
	self.SetNotify({
		title = 'Store Business',
		description = 'Put the Item to your Delivery Truck',
		type = 'inform'
	})
	while true do
		Wait(1)
		DrawMarker(39,x,y,z-0.5,0,0,0,0.0,0,0,1.0,1.0,1.0,255,0,0,50,0,0,0,1)
		if not textui then textui = true self.OxlibTextUi("Press [E] to Pickup") end
		if #(GetEntityCoords(self.playerPed) - vector3(x,y,z-1.0)) < 3 and IsControlJustPressed(0,38) then
			SetTimeout(3000,function()
				SetVehicleDoorShut(self.Vehicle,2,0)
				SetVehicleDoorShut(self.Vehicle,3,0)
				SetVehicleDoorShut(self.Vehicle,5,0)
			end)
			DeleteEntity(object)
			break
		end
	end
	lib.hideTextUI()
	local data = data
	local storecoord = vec3(0.0,0.0,0.0)
	for k,v in pairs(config.OwnedShops) do
		for k,v in pairs(v) do
			if v.label == data.store then
				storecoord = v.coord
			end
		end
	end
	SetNewWaypoint(storecoord)
	deliveryblip = AddBlipForCoord(storecoord.x,storecoord.y,storecoord.z)
	self.SetBlip(deliveryblip,358,26,'My Delivery Point')
	SetBlipRoute(deliveryblip,true)
	SetBlipRouteColour(deliveryblip,3)
	textui = false
	self.SetNotify({
		title = 'Store Business',
		description = 'Deliver the item to the Store Location',
		type = 'inform'
	})
	local boxhand = false
	local object = nil
	local deliver = false
	while not deliver do
		local sleep = 1000
		local dist = #(GetEntityCoords(self.playerPed) - vector3(storecoord.x,storecoord.y,storecoord.z-1.0))
		if dist < 50 then
			sleep = 1
		end
		local box = DoesEntityExist(object)
		if dist < 30 and not IsPedInAnyVehicle(self.playerPed) and not box then
			SetVehicleDoorOpen(self.Vehicle,2,0,0)
			SetVehicleDoorOpen(self.Vehicle,3,0,0)
			SetVehicleDoorOpen(self.Vehicle,5,0,0)

			local xa,ya,za = table.unpack(GetWorldPositionOfEntityBone(self.Vehicle,GetEntityBoneIndexByName(self.Vehicle,"door_dside_r")))
			local xb,yb,zb = table.unpack(GetWorldPositionOfEntityBone(self.Vehicle,GetEntityBoneIndexByName(self.Vehicle,"door_pside_r")))

			local x = (xa+xb)/2
			local y = (ya+yb)/2
			local z = (za+zb)/2
			while #(GetEntityCoords(self.playerPed) - vector3(x,y,z-1.0)) > 2 and not box do
				Wait(1)
			end
			self.OxlibTextUi("Press [E] to Pick Up Box")
			while not DoesEntityExist(object) do 
				Wait(1) 
				if IsControlJustPressed(0,38) then
					object = self.BoxObject("anim@heists@box_carry@","idle","hei_prop_heist_box",50,28422)
				end
			end
			lib.hideTextUI()
		end
		DrawMarker(39,storecoord.x,storecoord.y,storecoord.z-0.5,0,0,0,0.0,0,0,1.0,1.0,1.0,255,0,0,50,0,0,0,1)
		--if DoesEntityExist(object) and dist < 3 and not textui then textui = true self.OxlibTextUi("Press [E] to Deliver") end
		if DoesEntityExist(object) and not deliver and dist < 3 and IsControlJustPressed(0,38) then
			deliver = true
			SetTimeout(3000,function()
				SetVehicleDoorShut(self.Vehicle,2,0)
				SetVehicleDoorShut(self.Vehicle,3,0)
				SetVehicleDoorShut(self.Vehicle,5,0)
			end)
			DeleteEntity(object)
			break
		end
		Wait(sleep)
	end
	self.deliveryzone = self.Add(storecoord,'Deliver '..self.Items[data.data.item.name],self.DeliverDone,false,data,true,true)
end

self.DeliverDone = function(data)
	lib.hideTextUI()
	if DoesBlipExist(deliveryblip) then
		RemoveBlip(deliveryblip)
	end
	if DoesEntityExist(self.trailertransport) then
		DeleteEntity(self.trailertransport)
	end
	local delivered = lib.callback.await('renzu_shops:stockdelivered', false, data)
	if data.selfdeliver then
		self.SetNotify({
			title = 'Store Business',
			description = 'Stock ha been Updated',
			type = 'inform'
		})
	else
		self.SetNotify({
			title = 'Store Business',
			description = 'Go back to Shipping Garage to Finish the job',
			type = 'inform'
		})
		SetNewWaypoint(config.shipping.spawn)
		deliveryblip = AddBlipForCoord(config.shipping.spawn.x,config.shipping.spawn.y,config.shipping.spawn.z)
		self.SetBlip(deliveryblip,358,26,'Shipping Garage')
		SetBlipRoute(deliveryblip,true)
		SetBlipRouteColour(deliveryblip,3)
		self.Add(vec3(config.shipping.spawn.x,config.shipping.spawn.y,config.shipping.spawn.z),'Finish Delivery Job',self.JobDone,false,data,true)
	end
end

self.JobDone = function(data)
	if DoesBlipExist(deliveryblip) then
		RemoveBlip(deliveryblip)
	end
	DeleteEntity(self.Vehicle)
	self.delivery = false
	lib.hideTextUI()
	local success = lib.callback.await('renzu_shops:jobdone', false, data)
	if success then
		self.SetNotify({
			title = 'Store Business',
			description = 'You Successfully Finish the Delivery Job',
			type = 'success'
		})
	end
end

self.Shipping = function(data)
	local data = GlobalState.Shipping
	local options = {}
	for store,v in pairs(data) do
		for k,v in pairs(v) do
			local loc = vec3(v.point[1],v.point[2],v.point[3])
			local hashstreet = GetStreetNameAtCoord(loc.x,loc.y,loc.z)
			local streetname = GetStreetNameFromHashKey(hashstreet)
			local dist = math.floor(#(GetEntityCoords(self.playerPed) - loc)+0.5)
			if not GlobalState.OngoingShip[store] or GlobalState.OngoingShip[store] and GlobalState.OngoingShip[store][v.id] == nil then
				local pay = dist * config.shipping.payperdistance
				local label = self.Items[v.item.name] or v.item.label
				if v.item.metadata then
					label = v.item.metadata.label
				end
				table.insert(options,{
					title = store..' - '..label,
					description = streetname..' \n Distance: '..dist,
					arrow = true,
					onSelect = function(args)
						local confirm = lib.alertDialog({
							header = 'Shipping Job',
							content = 'Pickup the '..label..' from '..streetname..'   \n Distance : '..dist..'  \n Do you want to Accept the job?  \n Possible Pay Amount: '..pay..'$',
							centered = true,
							cancel = true
						})
						if confirm ~= 'cancel' then
							self.StartDelivery({dist = dist, store = store, index = v.id, data = v, type = v.type})
						end
					end
				})
			end
		end
	end
	lib.registerContext({
		id = 'shipping',
		title = 'Manage Pickup and Delivery',
		onExit = function()
		end,
		options = options
	})
	lib.showContext('shipping')
end

self.BuyStore = function(data)
	local data = data
	local stores = GlobalState.Stores
	if stores[data.label] then return end
	local confirm = lib.alertDialog({
		header = data.label,
		content = 'Do you really want to purchase ?\n Price: '..data.price..' $',
		centered = true,
		cancel = true
	})
	if confirm ~= 'cancel' then
		local success = lib.callback.await('renzu_shops:buystore', false, data)
		if success then
			self.SetNotify({
				title = 'Store Business',
				description = 'You Successfully Bought the store '..data.label,
				type = 'success'
			})
			

			if self.temporalspheres[data.label] then
				self.temporalspheres[data.label].spheres:remove()
				local spheredata = self.temporalspheres[data.label]
				local sphere = self.Add(spheredata.coord,spheredata.label,self.StoreOwner,false,spheredata.shop)
				self.temporalspheres[data.label] = sphere
			end
		end
	end
end

self.OpenShop = function(data)
	local data = lib.table.deepclone(data)
	local stores = GlobalState.Stores
	-- shop data of defaults shops
	if not self.Active or  not self.Active.shop then return end
	data.shop.inventory = data.shop.inventory or config.Storeitems[data.type]
	self.Active.shop.inventory = data.shop.inventory
	self.Active.shop.type = data.type
	for k,v in pairs(data.shop.inventory) do
		data.shop.inventory[k].disable = false
		data.shop.inventory[k].label = v.metadata and v.metadata.label or self.Items[v.name] or v.label
	end
	self.moneytype = data.shop.moneytype
	-- shop data for owned shops
	local ownedshops = lib.table.deepclone(config.OwnedShops)
	for type,v in pairs(ownedshops) do
		for k,v2 in pairs(v) do
			if k == data.index and type == data.type then
				self.moneytype = v2.moneytype
				data.shop.label = v2.label
				data.shop.inventory = v2.supplieritem
				self.Active.shop.inventory = v2.supplieritem
				self.Active.camerasetting = v2.camerasetting
				for k,v in pairs(data.shop.inventory) do
					data.shop.inventory[k].disable = false
					data.shop.inventory[k].label = v.metadata and v.metadata.label or self.Items[v.name] or v.label
				end
				if stores[v2.label] then
					for k,item in pairs(v2.supplieritem) do
						local storedata = stores[v2.label]
						local storeitems = storedata.items
						local itemdata = storeitems.normal[item.name]
						local price = itemdata?.price
						local category = itemdata?.category
						local stock = itemdata?.stock
						local disable = itemdata?.disable
						local label = self.Items[item.name] or item.label
						local metadata = item.metadata
						if item.metadata and item.metadata.name then
							label = metadata.label or label
							itemdata = storeitems.custom[metadata.name]
							stock = itemdata?.stock
							category = itemdata?.category
							price = itemdata?.price
							disable = itemdata?.disable
						end
						if not data.shop.inventory[k] then data.shop.inventory[k] = {name = item.name, price = item.price, label = label} end
						if price then
							data.shop.inventory[k].price = price
						end
						data.shop.inventory[k].category = category or item.category
						data.shop.inventory[k].stock = stock or 0
						data.shop.inventory[k].label = label
						if disable or item.disable then
							data.shop.inventory[k].disable = true
						else
							data.shop.inventory[k].disable = false
							if metadata then
								data.shop.inventory[k].metadata = metadata
							end
						end
					end
					self.Active.shop.type = data.type
					self.Active.shop.inventory = data.shop.inventory
				end
			end
		end
	end
	local money = self.GetItemCount('money')
	local black_money = self.GetItemCount('black_money')
	SendNUIMessage({
		type = 'shop',
		data = {moneytype = self.moneytype, type = data.type, open = not self.shopopen, shop = data.shop, label = data.shop.label or data.shop.name, wallet = {money = self.format_int(money), black_money = self.format_int(black_money)}}
	})
	SetNuiFocus(not self.shopopen,not self.shopopen)
	SetNuiFocusKeepInput(false)
	self.shopopen = not self.shopopen
end

self.format_int = function(number)
	local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
	
	-- reverse the int-string and append a comma to all blocks of 3 digits
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	
	-- reverse the int-string back remove an optional comma and put the 
	-- optional minus and fractional part back
	return minus .. int:reverse():gsub("^,", "") .. fraction
end

self.OxlibTextUi = function(msg)
	lib.showTextUI(msg, {
		position = "left-center",
		icon = 'fas fa-shopping-basket',
		style = {
			borderRadius = 5,
			backgroundColor = '#212121',
			color = 'white'
		}
	})
end

self.Closeui = function()
	SendNUIMessage({
		type = 'shop',
		data = {open = not self.shopopen, shop = data}
	})
	SetNuiFocus(not self.shopopen,not self.shopopen)
	SetNuiFocusKeepInput(false)
	self.shopopen = not self.shopopen
	TriggerScreenblurFadeOut(0)
	self.view = false
	RenderScriptCams(false)
	DestroyAllCams(true)
	ClearFocus()
	if DoesEntityExist(self.chosenvehicle) then
		DeleteEntity(self.chosenvehicle)
	end
end

self.GetItemCount = function(item)
	return exports.ox_inventory:Search('count', item)
end

self.worldoffset = {}
self.playerPed = cache.ped
self.Handlers = function()
	lib.onCache('ped', function(ped)
		self.playerPed = ped
	end)

	AddStateBagChangeHandler("CreateShop", "global", function(bagName, key, value)
		Wait(1000)
		config.OwnedShops = request('config/ownedshops/init')
		if value then
			local data = {shop = value.shop, index = value.index, type = value.type, coord = value.loc}
			if not config.target then
				self.Add(value.loc,value.label,self.OpenShop,false,data)
				local spheres = self.Add(value.coord,'Buy '..value.type..' #'..value.index,self.BuyStore,false,value.shop)
				self.temporalspheres[value.label] = {spheres = spheres, coord = value.coord, shop = value.shop, label = 'My Store '..value.label}
			else
				self.addTarget(value.loc,value.label,self.OpenShop,false,data)
				self.addTarget(value.coord,'Buy '..value.type..' #'..value.index,self.BuyStore,false,value.shop)
			end
			value.shop.index = value.index
			value.shop.type = value.type
			value.shop.offset = config.Shops[value.type].locations[value.index]
			if not config.target then
				self.Add(value.cashier,'Cashier '..value.label,self.Cashier,false,value.shop)
			else
				self.addTarget(value.cashier,'Cashier '..value.label,self.Cashier,false,value.shop)
			end
		end
	end)

	AddStateBagChangeHandler("AvailableStore", "global", function(bagName, key, value)
		Wait(1000)
		local stores = GlobalState.Stores
		if not stores[value.store] then
			for name,shop in pairs(config.OwnedShops) do
				for k,v in pairs(shop) do
					if v.label == value.store then
						local spheres = self.Add(v.coord,'Buy '..name..' #'..k,self.BuyStore,false,v)
						self.temporalspheres[v.label] = {spheres = spheres, coord = v.coord, shop = v, label = 'My Store '..v.label}
						break
					end
				end
			end
		end
	end)

	AddStateBagChangeHandler("ShopAlerts", "global", function(bagName, key, value)
		Wait(0)
		if not value then return end
		local blip = nil
		local radius = AddBlipForRadius(value.coord.x,value.coord.y,value.coord.z, 50.0)
		SetBlipColour(radius,1)
		SetBlipAlpha(radius,60)
		if self.PlayerData?.job?.name == 'police' then
			-- INSERT YOUR CUSTOM ALERTS HERE 
			-- ALERT MUST BE CLIENT SIDE
			-- REMOVE THIS DEFAULT NOTIFICATION WHEN YOU DO
			local hashstreet = GetStreetNameAtCoord(value.coord.x,value.coord.y,value.coord.z)
			local streetname = GetStreetNameFromHashKey(hashstreet)
			-- default notif
			blip = AddBlipForCoord(value.coord.x,value.coord.y,value.coord.z)
			SetBlipSprite(blip,303)
			for i = 0, 5 do
				lib.defaultNotify({
					title = 'Store Robbery',
					description = 'Ongoing Robbery at '..value.store..' in '..streetname,
					status = 'warning'
				})
			end
		end
		SetTimeout(300000,function()
			if DoesBlipExist(radius) then
				RemoveBlip(radius)
			end
			if DoesBlipExist(blip) then
				RemoveBlip(blip)
			end
		end)
		-- default notif
	end)

	local spheres = {}
	AddStateBagChangeHandler('movableshopspawned' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
		Wait(0)
		if not value then return end
		local net = tonumber(bagName:gsub('entity:', ''), 10)
		local entity = NetworkGetEntityFromNetworkId(net)
		local ent = Entity(entity).state
		if value.identifier == self.PlayerData.identifier and self.movableentity[value.type] ~= entity then
			self.movabletype = value.type
			self.movableentity[value.type] = entity
			local data = config.MovableShops[value.type]
			self.MovableShopStart(data)
		end
	end)

	AddStateBagChangeHandler('storemanage' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
		Wait(0)
		if not value then return end
		local net = tonumber(bagName:gsub('player:', ''), 10)
		if GetPlayerServerId(PlayerId()) == net then
			self.StoreAdmin(value.data)
		end
	end)

	AddStateBagChangeHandler('bubblespeech' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
		Wait(0)
		if not value then return end
		local net = tonumber(bagName:gsub(value.bagname, ''), 10)
		local entity = NetworkGetEntityFromNetworkId(net)
		if value.bagname == 'player:' then
			entity = GetPlayerPed(GetPlayerFromServerId(net))
		end
		if #(GetEntityCoords(self.playerPed) - GetEntityCoords(entity)) < 10 then
			self.CreateBubbleSpeech({id = entity, title = value.title, message = value.message, ms = value.ms})
		end
	end)

	AddStateBagChangeHandler('movableshop' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
		Wait(0)
		local value = value
		Wait(math.random(1,200))
		if not value then return end
		local net = tonumber(bagName:gsub('entity:', ''), 10)
		local entity = NetworkGetEntityFromNetworkId(net)
		local ent = Entity(entity).state
		local coord = GetEntityCoords(entity)
		local worldoffset = vec3(0.0,-1.0,0.5)
		local data = config.MovableShops[value.type]
		if data and data.type == 'vehicle' then
			worldoffset = vec3(2.0,-2.0,0.5)
		end
		local offset = GetOffsetFromEntityInWorldCoords(entity,worldoffset.x,worldoffset.y,worldoffset.z)
		if value.selling and not spheres[value.identifier] then
			spheres[value.identifier] = self.Add(offset,value.type,self.OpenShopMovable,false,{type = value.type, identifier = value.identifier, net = net})
		elseif not value.selling then
			spheres[value.identifier]:remove()
			spheres[value.identifier] = nil
		end
	end)

	AddStateBagChangeHandler('confirmation' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
		Wait(0)
		if not value then return end
		local net = tonumber(bagName:gsub('player:', ''), 10)
		local bag = NetworkGetEntityFromNetworkId(net)
		local ent = Entity(bag).state
		if GetPlayerServerId(PlayerId()) == tonumber(net) then
			CreateThread(function()
				Wait(5000)
				lib.closeAlertDialog()
			end)
			local confirm = lib.alertDialog({
				header = 'Job Invitation',
				content = value.store..' is Inviting you to become a Employee \n Do you want to Accept?',
				centered = true,
				cancel = true
			})
			local reason = lib.callback.await('renzu_shops:confirmationfeedback', false, {store = value.store, id = net, answer = confirm})
			if confirm ~= 'cancel' and confirm ~= nil then
				self.SetNotify({
					title = 'Store Business',
					description = 'You are now Employee of '..value.store,
					type = 'success'
				})
				for k,shops in pairs(config.OwnedShops) do
					for k,shop in pairs(shops) do
						if value.store == shop.label then
							self.Add(shop.coord,'My Store '..shop.label,StoreOwner,false,shop)
						end
					end
				end
			else
				self.SetNotify({
					title = 'Store Business',
					description = 'You Decline the offer of '..value.store,
					type = 'error'
				})
			end
		end
	end)
	livery = false,
	RegisterNUICallback('nuicb', function(data, cb)
		local shop = self.Active.shop.inventory
		local itemdata = {}
		for k,v in pairs(shop) do
			if data.item == v.name then
				itemdata = v
			end
		end
		itemdata.amount = data.amount
		local label = self.Items[itemdata.name] or itemdata.label
		if data.msg == 'outofstock' then
			self.SetNotify({
				title = 'Store Business',
				description = label..' is Out of Stock',
				type = 'error'
			})
		elseif data.msg == 'limitreached' then
			self.SetNotify({
				title = 'Store Business',
				description = 'Your amount is greater than the current available stock',
				type = 'error'
			})
		elseif data.msg == 'invalidamount' then
			self.SetNotify({
				title = 'Store Business',
				description = 'Your amount is Funny',
				type = 'error'
			})
		elseif data.msg == 'cart' then
			self.SetNotify({
				title = 'Store Business',
				description = 'You Added x'..itemdata.amount..' '..label..' to your cart',
				type = 'inform'
			})
		elseif data.msg == 'buy' then
			local total = 0
			local itemdata = {}
			for k,v in pairs(shop) do
				itemdata[v.metadata and v.metadata.name or v.name] = v
			end
			for k,v in pairs(data.items) do
				total = total + tonumber(itemdata[v.data.metadata and v.data.metadata.name or v.data.name].price) * tonumber(v.count)
			end
			local confirm = lib.alertDialog({
				header = 'Confirm Buy',
				content = 'Are you sure you want to buy?   \n Amount : '..total..' $  \n Method : '..data.type,
				centered = true,
				cancel = true
			})
			if confirm ~= 'cancel' then
				lib.callback("renzu_shops:buyitem", false, function(reason)
					if reason == 'notenoughmoney' then
						self.SetNotify({
							title = 'Store Business',
							description = 'not enough money to purchase ',
							type = 'error'
						})
					elseif reason == 'invalidamount' then
						self.SetNotify({
							title = 'Store Business',
							description = 'Invalid Amount to purchase ',
							type = 'error'
						})
					else
						self.SetNotify({
							title = 'Store',
							description = 'Successfully Purchase',
							type = 'success'
						})
						if self.Active.shop.type == 'VehicleShop' then
							local chosen = nil
							for k,v in pairs(data.items) do
								chosen = v
							end
							local model = GetHashKey(chosen.data.name)
							lib.requestModel(model)
							local shopdata = self.GetShopData(self.Active.type,self.Active.index)
							local vehicle = CreateVehicle(model, shopdata.purchase.x,shopdata.purchase.y,shopdata.purchase.z, shopdata.purchase.w, true, true)
							while not DoesEntityExist(vehicle) do Wait(0) end
							-- for server setter vehicle incase you dont owned the entity.
							SetEntityAsMissionEntity(vehicle,true,true)
							NetworkRequestControlOfEntity(vehicle)
							local attempt = 0
							while not NetworkHasControlOfEntity(vehicle) and attempt < 500 and DoesEntityExist(vehicle) do
								NetworkRequestControlOfEntity(vehicle)
								Citizen.Wait(0)
								attempt = attempt + 1
							end
							SetVehicleDirtLevel(vehicle, 0.0)
							SetVehicleModKit(vehicle,0)
							SetVehicleNumberPlateText(vehicle,reason)
							if chosen.vehicle and tonumber(chosen.vehicle?.livery) and tonumber(chosen.vehicle?.livery) ~= -1 then
								if chosen.vehicle.liverymod then
									SetVehicleLivery(vehicle,tonumber(chosen.vehicle.livery))
								else
									SetVehicleMod(vehicle, 48, tonumber(chosen.vehicle.livery), false)
								end
							end
							local primary, secondary = GetVehicleColours(vehicle)
							if chosen.vehicle?.color then
								SetVehicleColours(vehicle,tonumber(chosen.vehicle?.color),secondary)
							end
							self.Closeui()
							TaskWarpPedIntoVehicle(self.playerPed, vehicle, -1)
						end
						cb(true)
					end
				end,{items = data.items, data = itemdata, index = self.Active.index, type = data.type, shop = self.Active.shop.type or self.shopidentifier, moneytype = self.moneytype})
			end
		elseif data.msg == 'close' then
			self.Closeui()
		elseif data.msg == 'vehicle' then
			self.VehicleCam()
			Wait(1000)
			TriggerScreenblurFadeOut(0)
			self.view = true
		elseif data.msg == 'vehicleview' then
			TriggerScreenblurFadeOut(0)
			self.view = true
			local vehicle = self.SpawnVehicleLocal(data.model)
			self.livery = false
			SetVehicleModKit(vehicle,0)
			local max = GetNumVehicleMods(vehicle, 48) + 1
			if max == -1 then
				max = GetVehicleLiveryCount(vehicle) + 1
				self.livery = true
			end
			local list = {}
			if max > 0 then
				for i = 0, max do
					if self.livery and i >= 1 then
						list[i] = GetLabelText(GetLiveryName(vehicle,i-1))
					elseif GetLabelText(GetModTextLabel(vehicle, 48, i-1)) ~= 'NULL' and i >= 1 then
						list[i] = GetLabelText(GetModTextLabel(vehicle, 48, i-1))
					end
				end
			end
			cb({ livery = list,color = GetVehicleColours(self.chosenvehicle), liverymod = self.livery})
		elseif data.msg == 'changecolor' then
			local primary, secondary = GetVehicleColours(self.chosenvehicle)
			SetVehicleColours(self.chosenvehicle,tonumber(data.color),secondary)
		elseif data.msg == 'changelivery' then
			if self.livery then
				SetVehicleLivery(self.chosenvehicle,tonumber(data.livery))
			else
				SetVehicleMod(self.chosenvehicle, 48, tonumber(data.livery), false)
			end
		elseif data.msg == 'getAvailableAttachments' then
			local componentitems = {}
			for item,v in pairs(Components) do
				if v.client and v.client.component then
					--componentitems[item] = v.client.component
					for k,componenthash in pairs(v.client.component) do
						if DoesWeaponTakeWeaponComponent(GetHashKey(data.item), componenthash) then
							table.insert(componentitems,{name = v.name, label = v.label})
						end
					end
				end
			end
			cb(componentitems)
		end
	end)
end
self.view = false
self.downloading = false
self.chosenvehicle = nil
self.GetShopData = function(si,li)
	for k,v in pairs(config.OwnedShops) do
		if si == k then
			for k,v in pairs(v) do
				if li == k then
					return v
				end
			end
		end
	end
	return false
end
self.SpawnVehicleLocal = function(model)
	model = GetHashKey(model)
	if self.downloading or not IsModelInCdimage(model) then return end
	local ped = self.playerPed
	SetNuiFocus(true, true)
	local shopdata = self.GetShopData(self.Active.type,self.Active.index)
	local spawn = vec3(shopdata.spawn.x,shopdata.spawn.y,shopdata.spawn.z)
	for i = 1, 2 do
		local nearveh = GetClosestVehicle(spawn, 2.000, 0, 70)
		if DoesEntityExist(nearveh) then
			DeleteEntity(nearveh)
		end
		while DoesEntityExist((nearveh)) do DeleteEntity(nearveh) Wait(100) end
	end

	local dist = #(spawn - GetEntityCoords(self.playerPed))
	if dist <= 40.0 then
		if not HasModelLoaded(model) then
			SetNuiFocus(false, false)
			BusyspinnerOff()
			Wait(10)
			AddTextEntry("CUSTOMLOADSTR", 'Downloading Vehicle Assets..')
			BeginTextCommandBusyspinnerOn("CUSTOMLOADSTR")
			EndTextCommandBusyspinnerOn(4)
			self.downloading = true
			local c = 0
			lib.requestModel(model)
			BusyspinnerOff()
			SetNuiFocus(true, true)
			loading = true
			self.downloading = false
		end
		if DoesEntityExist(self.chosenvehicle) then DeleteEntity(self.chosenvehicle) end
		self.chosenvehicle = CreateVehicle(model, spawn.x,spawn.y,spawn.z, shopdata.spawn.w, false, true)
		while not DoesEntityExist(self.chosenvehicle) do Wait(0) end
		SetEntityHeading(self.chosenvehicle, shopdata.spawn.w)
		FreezeEntityPosition(self.chosenvehicle, true)
		SetEntityCollision(self.chosenvehicle,false)
		SetVehicleDirtLevel(self.chosenvehicle, 0.0)
		SetModelAsNoLongerNeeded(model)
		SetVehicleEngineOn(self.chosenvehicle,true,true,false)
		local minDim, maxDim = GetModelDimensions(GetEntityModel(self.chosenvehicle))
		local modelSize = maxDim - minDim
		local coord = GetEntityCoords(self.chosenvehicle)
		local height = GetEntityHeight(self.chosenvehicle,coord.x,coord.y,coord.z,true,true)
		local offset = GetOffsetFromEntityGivenWorldCoords(self.chosenvehicle,self.Active.coord)

		--local offset = GetOffsetFromEntityInWorldCoords(self.chosenvehicle,offset.x,offset.y,1.9)
		--PointCamAtCoord(self.cam, vec3(offset.x,offset.y,offset.z-1.5))
		--SetCamCoord(self.cam,vec3(offset.x,offset.y,offset.z-0.15))
		local Y = modelSize.y
		local Z = modelSize.z
		if Y > 3 then
			Y = 3
		end
		if Z > 3 then
			Z = 3
		end
		local fovval = modelSize.x * Y * Z
		local dist = #(self.Active.coord - GetEntityCoords(self.chosenvehicle))
		fov = fovval + (dist/2 * Y) + self.Active.camerasetting.fov
		local offset = self.Active.camerasetting.offset
		PointCamAtEntity(self.cam,self.chosenvehicle,offset.x,offset.y,offset.z)
		local camcoord = self.Active.coord+vec3(0.0,0.0,0.8)
		SetCamParams(self.cam, camcoord.x,camcoord.y,camcoord.z, 360.00, 0.00, 0.00, fov, 1000, 0, 0, 2);
		--SetCamFov(self.cam, fov)
		--PointCamAtEntity(self.cam,self.chosenvehicle,self.Active.camerasetting.offset)
		RenderScriptCams(true, true, 1000, true, true)
	end
	return self.chosenvehicle
end
self.cam = nil
self.VehicleCam = function()
	NetworkConcealPlayer(PlayerId(),false)
	for k,v in pairs(GetActivePlayers()) do
		if v ~= PlayerId() then
			NetworkConcealPlayer(v,true)
		end
	end
	local shopdata = self.GetShopData(self.Active.type,self.Active.index)
	local spawn = vec3(shopdata.spawn.x,shopdata.spawn.y,shopdata.spawn.z)
	local camcoord = self.Active.coord+vec3(0.0,0.0,0.8)
	self.cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camcoord.x,camcoord.y,camcoord.z, 360.00, 0.00, 0.00, 60.00, false, 0)
	--PointCamAtCoord(self.cam, spawn.x, spawn.y, spawn.z+0.1)
	while not DoesEntityExist(self.chosenvehicle) do Wait(0) end
	local offset = self.Active.camerasetting.offset
	PointCamAtEntity(self.cam,self.chosenvehicle,offset.x,offset.y,offset.z)
	SetCamActive(self.cam, true)
	SetCamFov(self.cam, 45.0)
	SetCamRot(self.cam, -15.0, 0.0, 252.063)
	RenderScriptCams(true, true, 3000, true, true)
	SetFocusPosAndVel(spawn.x, spawn.y, spawn.z, 0.0, 0.0, 0.0)
	DisplayHud(false)
	DisplayRadar(false)
	Citizen.CreateThread(function()
		local coord = vector3(spawn.x, spawn.y, spawn.z)
		--SetEntityAlpha(PlayerPedId(),1,true)
		while not self.view do Wait(1) end
		while self.view do
			Citizen.Wait(0)
			if self.chosenvehicle ~= nil then
				SetEntityHeading(self.chosenvehicle, GetEntityHeading(self.chosenvehicle) - 0.1)
			end
			SetEntityLocallyInvisible(self.playerPed)
			DrawLightWithRange(coord.x-4.0, coord.y-3.0, coord.z+ 0.3, 255,255,255, 40.0, 15.0)
			DrawSpotLight(coord.x-4.0, coord.y+5.0, coord.z, coord, 255, 255, 255, 20.0, 1.0, 1.0, 20.0, 0.95)
		end
		for k,v in pairs(GetActivePlayers()) do
			if v ~= PlayerId() then
				NetworkConcealPlayer(v,false)
			end
		end
	end)
end

self.ReturnMovable = function()
	if DoesEntityExist(self.movableentity[self.movabletype]) then
		DeleteEntity(self.movableentity[self.movabletype])
	end
	if DoesEntityExist(self.bike[self.movabletype]) then
		DeleteEntity(self.bike[self.movabletype])
	end
end

self.MovableShop = function(data)
	self.movabletype = data.type
	local owned = lib.callback.await('renzu_shops:getmovableshopdata', false, data)
	if owned and not DoesEntityExist(self.movableentity[self.movabletype]) then
		local options = {}
		table.insert(options,{
			title = 'Get a Cart',
			description = 'Start Selling '..data.label,
			arrow = true,
			onSelect = function(args)
				self.MovableShopStart(data.shop)
			end
		})
		lib.registerContext({
			id = 'movable_shopdata',
			title = data.label,
			onExit = function()
			end,
			options = options
		})
		lib.showContext('movable_shopdata')
	elseif DoesEntityExist(self.movableentity[self.movabletype]) then
		return self.ReturnMovable()
	else
		local confirm = lib.alertDialog({
			header = data.label,
			content = 'Do you want to purchase a Franchise ?\n Price: '..data.price..' $',
			centered = true,
			cancel = true
		})
		if confirm ~= 'cancel' then
			local success = lib.callback.await('renzu_shops:buymovableshop', false, data)
			if success then
				self.SetNotify({
					title = 'Store Business',
					description = 'You Successfully Bought a license to sell '..data.label,
					type = 'success'
				})
			end
		end
	end
end
self.movableentity = {}
self.MovableShopStart = function(data)
	if not DoesEntityExist(self.movableentity[self.movabletype]) then
		self.movableentity[self.movabletype] = self.SpawnMovableEntity(data)
	end
	local nets = {}
	table.insert(nets,NetworkGetNetworkIdFromEntity(self.movableentity[self.movabletype]))
	LocalPlayer.state:set('movableentity',nets,true)
	local identifier = self.movabletype..':'..self.PlayerData.identifier
	self.SetClientStateBags({
		entity = self.movableentity[self.movabletype], 
		name = 'movableshop', 
		data = {identifier = identifier, type = self.movabletype, selling = true}
	})
	local ent = Entity(self.movableentity[self.movabletype]).state
	self.driving = false
	self.worldoffset[self.movabletype] = vec3(0.0,1.0,0.5)
	if data.type == 'vehicle' then
		self.worldoffset[self.movabletype] = vec3(0.0,-5.0,0.5)
	end
	self.incockpit = false
	while not ent.movableshop do Wait(10) end
	CreateThread(function()
		local entity = self.movableentity[self.movabletype]
		self.startingsell = false
		while DoesEntityExist(entity) do
			local sleep = 1000
			local worldoffset = self.worldoffset[self.movabletype]
			local offset = GetOffsetFromEntityInWorldCoords(entity,worldoffset.x,worldoffset.y,worldoffset.z)
			self.clerkmode = false
			if not self.startingsell and #(GetEntityCoords(self.playerPed) - offset) < 1 then
				sleep = 5
				self.clerkmode = true
			elseif not self.clerkmode and not ent.movableshop.selling and data.type == 'object' then
				sleep = 5
				DisableControlAction(0,75,true)
				DisableControlAction(27, 75, true)
				--SetVehicleIndividualDoorsLocked(self.bike[self.movabletype],-1,2)
				--SetVehicleDoorsLocked(self.bike[self.movabletype],4)
				if DoesEntityExist(self.bike[self.movabletype]) and not IsPedInAnyVehicle(self.playerPed) then
					self.startingsell = false
					local identifier = self.movabletype..':'..self.PlayerData.identifier
					self.SetClientStateBags({
						entity = self.movableentity[self.movabletype], 
						name = 'movableshop', 
						data = {identifier = identifier, type = self.movabletype, selling = true}
					})
					if data.type == 'object' then
						SetEntityCollision(self.bike[self.movabletype],false,true)
						FreezeEntityPosition(self.bike[self.movabletype],true)
						SetEntityAlpha(self.bike[self.movabletype],1,true)
						DetachEntity(self.movableentity[self.movabletype],true)
						PlaceObjectOnGroundProperly(self.movableentity[self.movabletype])
						ClearPedTasks(self.playerPed)
						ResetPedMovementClipset(self.playerPed,1.0)
						--SetEntityCoords(self.playerPed,coord)
					end
				end
			else
				ent = Entity(entity).state
				if data.type == 'vehicle' and GetEntitySpeed(entity) < 1 then
					if not ent.movableshop.selling and self.driving then
						self.SetClientStateBags({
							entity = self.movableentity[self.movabletype], 
							name = 'movableshop', 
							data = {identifier = identifier, type = self.movabletype, selling = true}
						})
					end
					self.driving = false
				elseif data.type == 'vehicle' and GetEntitySpeed(entity) > 2 then
					self.driving = true
					if ent.movableshop.selling then
						SetVehicleDoorShut(entity,5,0)
						self.SetClientStateBags({
							entity = self.movableentity[self.movabletype], 
							name = 'movableshop', 
							data = {identifier = identifier, type = self.movabletype, selling = false}
						})
					end
				end
				local movabletype = self.movabletype -- supports multiple shop in same loops for the same identifier
				while data.type == 'vehicle' and #(GetEntityCoords(self.playerPed) - offset) > 2 and not IsPedInAnyVehicle(self.playerPed)
				or data.type == 'object' and #(GetEntityCoords(self.playerPed) - offset) > 2 do Wait(100) end
				self.movabletype = movabletype
			end
			if sleep == 5 then 
				DisableControlAction(0,75,true)
				DisableControlAction(27, 75, true)
				DrawMarker(21, offset, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 200, 255, 255, 255, 0, 0, 1, 1, 0, 0, 0)
			end
			if IsControlJustPressed(0,38) then
				if data.type == 'vehicle' and not self.incockpit then
					self.GotoCockpit(data)
				else
					Wait(400)
					self.OpenMovableShop(data)
				end
			end
			if IsDisabledControlJustPressed(0,49) and IsPedInAnyVehicle(self.playerPed) then self.startingsell = true ClearPedTasks(self.playerPed) TaskLeaveVehicle(self.playerPed,self.bike[self.movabletype],262144) end
			Wait(sleep)
		end
	end)
end

self.GotoCockpit = function(data)
	if data.type ~= 'vehicle' then return end
	SetVehicleDoorOpen(self.movableentity[self.movabletype],2,0,0)
	SetVehicleDoorOpen(self.movableentity[self.movabletype],3,0,0)
	SetVehicleDoorOpen(self.movableentity[self.movabletype],5,0,0)
	if not self.incockpit then
		Wait(2000)
		self.incockpit = true
		gameplaycam = GetRenderingCam()
		self.OpenMovableShop(data)
		self.worldoffset[self.movabletype] = vec3(0.0,-1.0,0.5)
		AttachEntityToEntity(self.playerPed, self.movableentity[self.movabletype], 19, 1.1, -3.2, 0.6, 0.0, 0.0, -90.0, false, false, false, false, 20, true)
		FreezeEntityPosition(self.playerPed,true)
		SetGameplayCamVehicleCamera('taco')
		SetGameplayCamVehicleCameraName(`taco`)
		DisableCamCollisionForEntity(self.movableentity[self.movabletype])
		DisableCamCollisionForEntity(self.playerPed)
		SetEntityCompletelyDisableCollision(self.playerPed,true,true)
		SetCamFov(gameplaycam,100.0)
		local cockpit = GetOffsetFromEntityInWorldCoords(self.movableentity[self.movabletype], 8.0,-7.0,2.1)
		self.cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", cockpit, 360.00, 0.00, 0.00, 60.00, false, 0)
		--PointCamAtCoord(self.cam, spawn.x, spawn.y, spawn.z+0.1)
		PointCamAtEntity(self.cam,self.movableentity[self.movabletype],1.0,-1.0,-0.2)
		SetCamActive(self.cam, true)
		SetCamFov(self.cam, 45.0)
		SetCamRot(self.cam, -15.0, 0.0, 252.063)
		RenderScriptCams(true, true, 3000, true, true)
		SetVehicleDoorShut(self.movableentity[self.movabletype],2,0)
		SetVehicleDoorShut(self.movableentity[self.movabletype],3,0)
	else
		DetachEntity(self.playerPed)
		self.incockpit = false
		local cockpit = GetOffsetFromEntityInWorldCoords(self.movableentity[self.movabletype], 0.0, -6.0, 0.0)
		SetEntityCoords(self.playerPed,cockpit)
		SetEntityHeading(self.playerPed,GetEntityHeading(self.movableentity[self.movabletype]))
		FreezeEntityPosition(self.playerPed,false)
		self.worldoffset[self.movabletype] = vec3(0.0,-5.0,0.5)
		SetEntityCompletelyDisableCollision(self.playerPed,false,true)
		SetEntityCollision(self.playerPed,true,true)
		RenderScriptCams(false)
		DestroyAllCams(true)
		ClearFocus()
		SetVehicleDoorShut(self.movableentity[self.movabletype],2,0)
		SetVehicleDoorShut(self.movableentity[self.movabletype],3,0)
	end
end

self.SpawnMovableEntity = function(data)
	local model = data.model
	lib.requestModel(model)
	local ent = nil
	if data.type == 'vehicle' then
		local identifier = self.movabletype..':'..self.PlayerData.identifier
		local movabledata = GlobalState.MovableShops
		local vehicledata = lib.callback.await('renzu_shops:getMovableVehicle', false, movabledata[identifier].plate)
		if not vehicledata then
			self.SetNotify({
				title = 'Store Business',
				description = 'Vehicle is not in garage',
				type = 'error'
			})
			return
		end
		ent = CreateVehicle(model, data.spawn, true, true)
		local plate = vehicledata.plate
		lib.setVehicleProperties(ent, json.decode(vehicledata.vehicle))
		SetVehicleNumberPlateText(ent,plate)
	else
		ent = CreateObject(model, GetEntityCoords(self.playerPed)+vec3(1.0,3.0,0.5), true, true, false)
	end
	while not DoesEntityExist(ent) do Wait(1) end
	while not NetworkGetEntityIsNetworked(ent) do Wait(1) NetworkRegisterEntityAsNetworked(ent) end
	PlaceObjectOnGroundProperly(ent)
	return ent
	--AttachEntityToEntity(ent, ped, bone, data["x"], y, data["z"], data["x_rotation"], data["y_rotation"], data["z_rotation"], 0, 1, 0, 1, 0, 1)
end
self.SetClientStateBags = function(value)
	local entity = NetworkGetNetworkIdFromEntity(value.entity)
	if value.data.bagname == 'player:' then
		entity = value.entity
	end
	LocalPlayer.state:set('renzu_shops:playerStateBags', {
		entity = entity, 
		name = value.name, 
		data = value.data,
		ts = GetGameTimer()+math.random(1,999)
	}, true)
end
self.bike = {}
self.OpenMovableShop = function(data)
	local options = {}
	if not DoesEntityExist(self.movableentity[self.movabletype]) then
		return
	end
	TaskVehicleTempAction(self.playerPed,self.bike[self.movabletype],1,2000)
	table.insert(options,{
		title = 'Move & Stop selling',
		description = 'Stop Selling on this Location',
		arrow = true,
		onSelect = function(args)
			local ent = Entity(self.movableentity[self.movabletype]).state
			if ent.movableshop.selling then
				local identifier = self.movabletype..':'..self.PlayerData.identifier
				self.SetClientStateBags({
					entity = self.movableentity[self.movabletype], 
					name = 'movableshop', 
					data = {identifier = identifier, type = self.movabletype, selling = false}
				})
				if data.type == 'object' then
					local bone = GetPedBoneIndex(self.playerPed, 0)
					local forward = GetEntityForwardVector(self.movableentity[self.movabletype]) * 1.2
					-- lib.requestAnimDict('anim@amb@casino@valet_scenario@pose_a@')
					-- TaskPlayAnim(self.playerPed, 'anim@amb@casino@valet_scenario@pose_a@', 'base_a_m_y_vinewood_01', 2.0, 2.0, -1, 49, 0, false, false,false)
					-- AttachEntityToEntity(self.movableentity[self.movabletype], self.playerPed, bone, data.pos.x,data.pos.y,data.pos.z, data.rot.x,data.rot.y,data.rot.z, 1, 0, 0, 0, 1, 1)
					-- lib.requestAnimDict('move_characters@jimmy@slow@')
					-- SetPedMovementClipset(self.playerPed, 'move_characters@jimmy@slow@', 0.2)
					local model = `cruiser`
					lib.requestModel(model)
					if not DoesEntityExist(self.bike[self.movabletype]) then
						self.bike[self.movabletype] = CreateVehicle(model, GetEntityCoords(self.playerPed)+vec3(1.0,1.0,0.0), true, true)
					end
					SetEntityCollision(self.bike[self.movabletype],true,true)
					SetEntityAlpha(self.bike[self.movabletype],255,true)
					FreezeEntityPosition(self.bike[self.movabletype],false)
					while not DoesEntityExist(self.bike[self.movabletype]) do Wait(1) end
					while not NetworkGetEntityIsNetworked(self.bike[self.movabletype]) do Wait(1) NetworkRegisterEntityAsNetworked(self.bike[self.movabletype]) end
					SetPedIntoVehicle(self.playerPed,self.bike[self.movabletype],-1)
					AttachEntityToEntity(self.movableentity[self.movabletype], self.bike[self.movabletype], GetEntityBoneIndexByName(self.bike[self.movabletype], 'engine'), -0.7,0.1,-0.6, -1.5,2.3,-87.199999999999, 1, 0, 0, 0, 1, 1)
				end
			else
				local identifier = self.movabletype..':'..self.PlayerData.identifier
				self.SetClientStateBags({
					entity = self.movableentity[self.movabletype], 
					name = 'movableshop', 
					data = {identifier = identifier, type = self.movabletype, selling = true}
				})
				if data.type == 'object' then
					local coord = GetEntityCoords(self.playerPed)+vec3(1.0,1.0,0.0)
					TaskLeaveVehicle(self.playerPed,self.bike[self.movabletype],262144)
					Wait(1000)
					SetEntityCollision(self.bike[self.movabletype],false,true)
					FreezeEntityPosition(self.bike[self.movabletype],true)
					SetEntityAlpha(self.bike[self.movabletype],1,true)
					DetachEntity(self.movableentity[self.movabletype],true)
					PlaceObjectOnGroundProperly(self.movableentity[self.movabletype])
					ClearPedTasks(self.playerPed)
					ResetPedMovementClipset(self.playerPed,1.0)
					--SetEntityCoords(self.playerPed,coord)
				end
			end
		end
	})
	table.insert(options,{
		title = 'Open Inventory',
		description = 'Open Movable shop inventory',
		arrow = true,
		onSelect = function(args)
			local identifier = self.movabletype..':'..self.PlayerData.identifier
			TriggerEvent('ox_inventory:openInventory', 'stash', {id = identifier, name = self.movabletype, slots = 40, weight = 40000, coords = GetEntityCoords(self.movableentity[self.movabletype])})
		end
	})
	table.insert(options,{
		title = 'Cook',
		description = 'Start Cooking items from Menu',
		arrow = true,
		onSelect = function(args)
			self.CookMenu(data)
		end
	})
	table.insert(options,{
		title = 'Enable/Disable Ondemand mode.',
		description = '(Serve newly cooked items to locals and citizens on the spot)',
		arrow = true,
		onSelect = function(args)
			self.OnDemand(data.menu,'movableshop')
		end
	})
	table.insert(options,{
		title = 'Ongoing Purchase Order',
		description = 'See list of purchase orders from nearby people',
		arrow = true,
		onSelect = function(args)
			self.PurchaseOrderList(data)
		end
	})
	lib.registerContext({
		id = 'movable_shopdata',
		title = data.label,
		onExit = function()
			CreateThread(function()
				self.GotoCockpit(data)
			end)
		end,
		options = options
	})
	lib.showContext('movable_shopdata')
end

self.PlayAnim = function(data)
	lib.requestAnimDict(data.dict)
	TaskPlayAnim(self.playerPed,data.dict,data.anim,3.0,3.0,-1,48,0,0,0,0)
end

self.ServePurchaseOrder = function(var,i,storedata)
	if not var.ingredients then
		local items = {}
		table.insert(items,{name = var.name, count = 1})
		local type = self.movabletype
		if storedata then
			type = storedata.type
		end
		local removed = lib.callback.await('renzu_shops:removestock', false, {type = type, name = var.name, count = 1, price = var.data.price, metadata = var.data.metadata, index = storedata and storedata.index, money = storedata and storedata.money})
		if removed then
			self.PlayAnim({dict = 'creatures@rottweiler@tricks@', anim = 'petting_franklin'})
			lib.progressBar({
				duration = 4000,
				label = 'Packing '..var.label,
				useWhileDead = false,
				canCancel = true,
				disable = {
					car = true,
				},
				anim = {
					dict = 'creatures@rottweiler@tricks@',
					clip = 'petting_franklin' 
				}
			})
			lib.progressBar({
				duration = 1000,
				label = 'Giving '..var.label,
				useWhileDead = false,
				canCancel = true,
				disable = {
					car = true,
				},
				anim = {
					dict = 'mp_common',
					clip = 'givetake1_a' 
				},
				prop = {
					model = `prop_food_bag1`,
					pos = vec3(0.3800, 0.0, -0.0300),
					rot = vec3(0.0017365, -79.9999997, 110.0651988),
					bone = 57005,
				},
			})
			lib.requestModel(`prop_food_bag1`)
			if not self.foodbox or not DoesEntityExist(self.foodbox) then
				self.foodbox = CreateObject(`prop_food_bag1`,GetEntityCoords(self.playerPed),true,true)
				while not DoesEntityExist(self.foodbox) do Wait(0) end
				AttachEntityToEntity(self.foodbox, self.currentcustomer, GetPedBoneIndex(self.currentcustomer, 57005), 0.3800, 0.0, -0.0300, 0.0017365, -79.9999997, 110.0651988, true, true,
				false, true, 1, true)
			end
			self.SetNotify({
				title = 'Store Business',
				description = 'You Serve '..var.label..' to '..var.customer,
				type = 'inform'
			})
			self.purchaseorder[i] = nil
		else
			self.SetNotify({
				title = 'Store Business',
				description = 'You dont have enough stock for '..var.label,
				type = 'inform'
			})
		end
	elseif var.ingredients then
		local cb = self.StartCook(var.data,var.name,var.menu,true)
		if cb == 'success' then
			self.purchaseorder[i] = nil
			self.SetNotify({
				title = 'Store Business',
				description = 'You Serve '..var.label..' to '..var.customer,
				type = 'inform'
			})
		else
			self.SetNotify({
				title = 'Store Business',
				description = 'You dont have enough stock for '..var.label,
				type = 'inform'
			})
		end
	else
		self.SetNotify({
			title = 'Store Business',
			description = 'You dont have enough stock for '..var.label,
			type = 'error'
		})
	end
end

self.PurchaseOrderList = function(data,storedata)
	local options = {}
	for k,v in pairs(self.purchaseorder) do
		table.insert(options,{
			title = v.label..' : Customer - '..v.customer,
			description = v.customer..' Wants a 1x of '..v.label,
			arrow = true,
			onSelect = function(args)
				self.ServePurchaseOrder(v,k,storedata)
			end
		})
	end
	lib.registerContext({
		id = 'purchase_orders',
		title = 'List of Current Food Order',
		onExit = function()

		end,
		options = options
	})
	lib.showContext('purchase_orders')
end
self.ondemand = false
self.peds = {}
self.allpeds = {}
self.OnDemand = function(items,type,storedata)
	if self.ondemand then 
		self.ondemand = false 
		for k,v in pairs(self.allpeds) do 
			DeleteEntity(v) 
		end
		self.peds = {}
		return 
	end
	self.ondemand = true
	self.SetNotify({
		title = 'Store Business',
		description = 'Ondemand Selling Started',
		type = 'inform'
	})
	CreateThread(function()
		local pedcounts = 3
		local loc = GetEntityCoords(self.playerPed)
		local models = {'hc_hacker',
		'ig_agent',
		'ig_andreas',
		'ig_avon',
		'ig_bankman',
		'ig_barry',
		'ig_brad',
		'ig_car3guy1',
		'ig_car3guy2',
		'ig_chengsr',
		'ig_dale',
		'ig_devin',
		'ig_djgeneric_01',
		'ig_djsolfotios',
		'ig_djsolmanager'}
		while self.ondemand do
			for i = 1 , pedcounts do
				SetRandomSeed(math.random(1,7900001111))
				local randped = models[GetRandomIntInRange(1,#models)]
				if IsModelInCdimage(GetHashKey(randped)) then
					lib.requestModel(GetHashKey(randped))
					local coord = loc+vec3(GetRandomIntInRange(-41,41),GetRandomIntInRange(-41,41),0.0)
					local found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(coord.x,coord.y, coord.z, 0, 3, 0)
					local foundSafeCoords, safeCoords = GetSafeCoordForPed(spawnPos.x, spawnPos.y, spawnPos.z, false , 1)
					if foundSafeCoords then
						coord = safeCoords
					end
					local _, groundz = GetGroundZFor_3dCoord(coord.x,coord.y,coord.z+20,true)
					self.peds[i] = CreatePed(4,GetHashKey(randped),coord.x,coord.y,groundz,0.0,true,true)
					table.insert(self.allpeds,self.peds[i])
					while not DoesEntityExist(self.peds[i]) and self.ondemand do Wait(1) end
					self.currentcustomer = self.peds[i]
					worldoffset = vec3(2.0,-2.0,0.5)
					local offset = GetOffsetFromEntityInWorldCoords(self.movableentity[self.movabletype],worldoffset.x,worldoffset.y,worldoffset.z)
					--TaskGoToEntity(peds[i],self.movableentity[self.movabletype],-1,3.0,1.0)
					if storedata then
						offset = storedata.offset
					end
					TaskGoToCoordAnyMeans(self.peds[i],offset.x,offset.y,offset.z,1.0, 0, 0, 786603, 0xbf800000)
					SetBlockingOfNonTemporaryEvents(self.peds[i], true)
					local blip = AddBlipForEntity(self.peds[i])
					SetBlipSprite(blip,280)
					SetBlipColour(blip, 2)
					while #(GetEntityCoords(self.peds[i]) - offset) > 1 and self.ondemand and not IsPedDeadOrDying(self.peds[i]) do Wait(100) end
					TaskTurnPedToFaceEntity(self.peds[i],self.playerPed,5000)
					local purchasedata = self.purchaseorder
					SetPedTalk(self.peds[i])
					PlayPedAmbientSpeechNative(self.peds[i],'GENERIC_HI', 'SPEECH_PARAMS_FORCE')
					local purchaseorder = self.ondemand and self.CreateOndemandOrder(items,self.peds[i],type,storedata)
					if purchaseorder then
						-- payment
						lib.callback.await('renzu_shops:ondemandpay', false, purchasedata)
						self.SetNotify({
							title = 'Store Business',
							description = 'You Serve Successfully',
							type = 'success'
						})
					end
					self.purchaseorder = {}
					TaskWanderStandard(self.peds[i],10.0,10)
					SetEntityAsNoLongerNeeded(self.peds[i])
					local cacheped = self.peds[i]
					SetTimeout(15000,function()
						if DoesEntityExist(cacheped) then
							DeleteEntity(cacheped)
						end
						if DoesEntityExist(self.foodbox) then
							DeleteEntity(self.foodbox)
						end
					end)
					if not self.ondemand then break end
				end
			end
		end
		self.SetNotify({
			title = 'Store Business',
			description = 'You Stopped Ondemand Selling',
			type = 'inform'
		})
	end)
end
self.purchaseorder = {}
self.CreateOndemandOrder = function(items,ped,type,storedata)
	local customer = 'Local #'..math.random(1,99)
	if storedata then
		local data = items
		items = {}
		local purchasableitems = data.supplieritem
		math.randomseed(math.random(1000,10000)+GetGameTimer())
		for i = #purchasableitems, 2, -1 do
			local j = math.random(i)
			purchasableitems[i], purchasableitems[j] = purchasableitems[j], purchasableitems[i]
		end
		for k,v in pairs(purchasableitems) do
			if not items[v.category]  then items[v.category] = {} end
			table.insert(items[v.category],v)
		end
	end
	local maxpurchase = 2
	local purchase = 0
	for k,v in pairs(items) do
		purchase += 1
		if not self.purchaseorder[k] then self.purchaseorder[k] = {} end
		local data = v[math.random(1,#v)]
		local img = data.metadata?.image or data.name
		local name = data.metadata and data.metadata.name or data.name or data.name
		local label = data.metadata and data.metadata.label or data.label or self.Items[data.name] or data.name
		data.label = label
		local category = data.category or k
		self.purchaseorder[k] = {ts = GetGameTimer()+math.random(1,99), data = data, img = img, name = name, count = 1, label = label, customer = customer, ingredients = data.ingredients, menu = category, shop = self.movabletype, type = type}
		if purchase == maxpurchase then break end
	end
	local message = ''
	for k,v in pairs(self.purchaseorder) do
		message = message..'<img src="https://cfx-nui-ox_inventory/web/images/'..v.img..'.png" style="height:40px; width:40px;"> i want 1x of '..v.label..' <br>'
	end
	LocalPlayer.state:set('createpurchaseorder', self.purchaseorder, true)
	local wait_time = math.random(20000,40000)
	self.CreateBubbleSpeechSync({id = ped, title = customer, message = message, bagname = 'entity:', ms = wait_time, store = storedata})
	local allserve = true
	for k,v in pairs(self.purchaseorder) do
		allserve = false
	end
	local ms = wait_time
	local purchaseorder = self.purchaseorder
	while not allserve and ms > 0 and self.ondemand do
		Wait(1000)
		ms -= 1000
		allserve = true
		for k,v in pairs(self.purchaseorder) do
			allserve = false
		end
	end
	self.bubblems = 0
	return allserve and self.purchaseorder == purchaseorder
end

self.CookMenu = function(data)
	local options = {}
	for k,v in pairs(data.menu) do
		table.insert(options,{
			title = k,
			description = 'See List of Available '..k,
			arrow = true,
			onSelect = function(args)
				self.CookMenuList(v,k,data)
			end
		})
	end
	lib.registerContext({
		id = 'cookmenu',
		menu = 'movable_shopdata',
		title = 'Cook menu',
		onExit = function()
		end,
		options = options
	})
	lib.showContext('cookmenu')
end

self.StartCook = function(data,item,title,dontreceive)
	local cancook = data.ingredients and true
	local items = {}
	for k,v in pairs(data.ingredients or {}) do
		table.insert(items,{name = k, count = v})
	end
	local ingredients = lib.callback.await('renzu_shops:getStashData', false, {items = items, type = self.movabletype})
	for k,v in pairs(items or {}) do
		if ingredients[v.name] <= v.count then
			cancook = false
		end
	end
	if cancook then
		--TaskStartScenarioInPlace(self.playerPed, 'PROP_HUMAN_BBQ', 0, true)
		SetTimeout(0,function()
			lib.progressBar({
				duration = 10000,
				label = 'Cooking '..data.label,
				useWhileDead = false,
				canCancel = true,
				disable = {
					car = true,
				},
				anim = {
					dict = 'amb@prop_human_bbq@male@idle_a',
					clip = 'idle_b' 
				},
				prop = {
					bone = 28422,
					model = `prop_fish_slice_01`,
					pos = vec3(0.00, 0.00, 0.00),
					rot = vec3(0.0, 0.0, 0.0) 
				},
			})
		end)
		Wait(1000)
		local success = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 2}, 'easy'})
		if lib.progressActive() then
			lib.cancelProgress()
		end
		ClearPedTasks(self.playerPed)
		if data.type == 'vehicle' then
			Wait(10)
			FreezeEntityPosition(self.playerPed,true)
			DetachEntity(self.playerPed,true,true)
			AttachEntityToEntity(self.playerPed, self.movableentity[self.movabletype], 19, 1.1, -3.2, 0.6, 0.0, 0.0, -90.0, false, false, false, false, 20, true)
			Wait(0)
			SetEntityCoordsNoOffset(self.playerPed,GetEntityCoords(self.playerPed))
		end
		if not success then return end
		local item = lib.callback.await('renzu_shops:craftitem', false, {metadata = data.metadata, item = item, type = self.movabletype, menu = title, shop = 'movableshop', dontreceive = dontreceive, stash = true})
		self.SetNotify({
			title = 'Store Business',
			description = 'Successfully Cooked a '..data.label,
			type = 'success'
		})
		return 'success'
	elseif data.ingredients then
		self.SetNotify({
			title = 'Store Business',
			description = 'Your missing one of the ingredients',
			type = 'error'
		})
		return 'missing'
	elseif not data.ingredients then
		self.SetNotify({
			title = 'Store Business',
			description = 'This Item is not craftable',
			type = 'error'
		})
		return 'not craftable'
	end
end

self.CookMenuList = function(items,title,data)
	local options = {}
	local identifier = self.movabletype..':'..self.PlayerData.identifier
	local itemdata = lib.callback.await('renzu_shops:getStashData', false, {items = items, type = self.movabletype})
	local movabledata = GlobalState.MovableShops[identifier]
	for k,v in pairs(items) do
		local item = v.name
		local label = self.Items[item]
		local amount = itemdata[item] or 0
		if v.metadata and v.metadata.name then
			label = v.metadata.label
			amount = itemdata[v.metadata.name] or 0
			item = v.metadata.name
		end
		local ingredients = {}
		for k,v in pairs(v.ingredients or {}) do
			ingredients[self.Items[k]] = 'x'..v
		end
		v.label = label
		table.insert(options,{
			title = label,
			description = 'Available : '..amount,
			arrow = true,
			metadata = ingredients,
			onSelect = function(args)
				self.StartCook(v,item,title)
			end
		})
	end
	lib.registerContext({
		id = 'cooklist',
		menu = 'cookmenu',
		title = title,
		onExit = function()
		end,
		options = options
	})
	lib.showContext('cooklist')
end

self.OpenShopMovable = function(data)
	self.Active.shop = {}
	self.shopidentifier = data.identifier
	data.shop = {}
	data.shop.label = data.type
	self.Active.index = data.type
	self.moneytype = 'money'
	local shopdata = config.MovableShops[data.type].menu
	local items = {}
	for category,v in pairs(shopdata) do
		for k,v in pairs(v) do
			table.insert(items, {name = v.name, price = v.price, metadata = v.metadata})
		end
	end
	local inventory = {}
	local itemdata = lib.callback.await('renzu_shops:getStashData', false, {items = items, type = data.type})
	for category,v in pairs(shopdata) do
		for k,v in pairs(v) do
			local name = v.metadata and v.metadata.name or v.name
			table.insert(inventory, {stock = itemdata[name],name = v.name, category = category, price = v.price, metadata = v.metadata, disable = false, label = self.Items[name] or v.metadata and v.metadata.label or v.name})
		end
	end
	data.shop.inventory = inventory
	self.Active.shop.inventory = inventory
	local money = self.GetItemCount('money')
	local black_money = self.GetItemCount('black_money')
	SendNUIMessage({
		type = 'shop',
		data = {moneytype = self.moneytype, type = data.type, open = not self.shopopen, shop = data.shop, label = data.shop.label or data.shop.name, wallet = {money = self.format_int(money), black_money = self.format_int(black_money)}}
	})
	SetNuiFocus(not self.shopopen,not self.shopopen)
	SetNuiFocusKeepInput(false)
	self.shopopen = not self.shopopen
end

self.CreateBubbleSpeechSync = function(data)
	self.SetClientStateBags({
		entity = data.id, -- entity net id 
		name = 'bubblespeech',  -- state bags name
		data = {title = data.title, message = data.message, bagname = data.bagname, ms = data.ms, remove = true}
	})
end
self.CreateBubbleSpeech = function(data)
	if not DoesEntityExist(data.id) then return end
	if not data.message then return end
	local coord = GetEntityCoords(data.id)
	local zoffset = 2.5
	if GetInteriorFromEntity(data.id) then
		zoffset = 1.5
	end
	local onScreen, x, y = GetScreenCoordFromWorldCoord(coord.x,coord.y+0.1,coord.z+zoffset)
	self.bubblems = data.ms or 2000
	--local ui = '<div class="bubble-speech bubble-right"> <h2 class="author"> '..title..' </h2> <div class="message"> <span style="font-size:45px;"> &hearts;</span> '..message..' </div> </div>'
	CreateThread(function()
		while self.bubblems > 0 do
			Wait(100)
			self.bubblems -= 100
		end
		return
	end)
	while self.bubblems > 0 do
		coord = GetEntityCoords(data.id)
		local onScreen, x, y = GetScreenCoordFromWorldCoord(coord.x,coord.y+0.1,coord.z+zoffset)
		SendNUIMessage({
			data = {
				type = 'bubble',
				id = data.id, 
				x = x, 
				y = y,
				title = data.title,
				message = data.message,
				wait = self.bubblems / data.ms * 100,
				metadata = data.metadata
			}
		})
		Wait(100)
	end
	SendNUIMessage({data = {id = data.id, type = 'bubbleremove'}})
	return true
end

self.StoreAdmin = function(data)
	self.adminmode = true
	self.shopconfig = {}
	local options = {}
	table.insert(options,{
		title = 'Manage Stores',
		description = 'See List of Player Owned Shops and manage its stock internaly',
		arrow = true,
		onSelect = function(args)
			self.AdminStoreLists(data)
		end
	})
	table.insert(options,{
		title = 'Add New Shop',
		description = 'Enable you to add new Shop type',
		arrow = true,
		onSelect = function(args)
			self.AddNewShop(data)
		end
	})
	lib.registerContext({
		id = 'storeadmin',
		title = 'Store Admin Manage',
		onExit = function()
			self.adminmode = false
		end,
		options = options
	})
	lib.showContext('storeadmin')
end

self.AdminStoreLists = function(data)
	local options = {}
	for shopname,v in pairs(data) do
		table.insert(options,{
			title = shopname,
			description = 'Manage '..shopname,
			arrow = true,
			onSelect = function(args)
				self.ManageStoreMenu(shopname)
				lib.showContext('manage_store')
			end
		})
	end
	lib.registerContext({
		menu = 'storeadmin',
		id = 'storeadminlist',
		title = 'Shops List',
		onExit = function()
		end,
		options = options
	})
	lib.showContext('storeadminlist')
end

self.AddNewShop = function()
	local options = {}
	for type,v in pairs(config.OwnedShops) do
		if type ~= 'VehicleShop' then
			table.insert(options,{
				title = type,
				description = 'Create a Shop type with '..type,
				arrow = true,
				onSelect = function(args)
					self.ConfigureShop(type)
				end
			})
		end
	end
	lib.registerContext({
		id = 'Addshop',
		menu = 'storeadminlist',
		title = 'Select Shop Type',
		onExit = function()
			self.adminmode = false
		end,
		options = options
	})
	lib.showContext('Addshop')
end

self.shopconfig = {}
self.ConfigureShop = function(type)
	local options = {}
	table.insert(options,{
		title = 'Store Owner Location',
		description = self.shopconfig['Storeowner'] and 'Configured ✅' or 'Configure Store Owner Coordinates',
		arrow = true,
		onSelect = function(args)
			self.CreateConfig('Storeowner',type)
		end
	})
	table.insert(options,{
		title = 'Shop Menu Location',
		description = self.shopconfig['Shop'] and 'Configured ✅' or 'Configure Shop Menu Coordinates',
		arrow = true,
		onSelect = function(args)
			self.CreateConfig('Shop',type)
		end
	})
	table.insert(options,{
		title = 'Cashier Location (Optional)',
		description = self.shopconfig['Cashier'] and 'Configured ✅' or 'Configure Cashier Coordinates',
		arrow = true,
		onSelect = function(args)
			self.CreateConfig('Cashier',type)
		end
	})
	table.insert(options,{
		title = 'Create Shop',
		description = 'Create '..type..' Shop with your Configure options',
		arrow = true,
		onSelect = function(args)
			self.CreateShop({type = type, config = self.shopconfig})
		end
	})
	lib.registerContext({
		id = 'ShopConfig',
		menu = 'Addshop',
		title = 'Shop Config',
		onExit = function()
			self.adminmode = false
		end,
		options = options
	})
	lib.showContext('ShopConfig')
end

self.CreateConfig = function(conf,type)
	self.OxlibTextUi("Press [E] to Save Current Coordinates for "..conf)
	while true do
		Wait(1)
		local coord = GetEntityCoords(cache.ped)+vec3(0.0,0.2,0.02)
		DrawMarker(21, coord.x,coord.y,coord.z, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 200, 255, 255, 255, 0, 0, 1, 1, 0, 0, 0)
		if IsControlJustPressed(0,38) then
			self.shopconfig[conf] = coord
			break
		end
	end
	lib.hideTextUI()
	Wait(100)
	self.ConfigureShop(type)
end

self.CreateShop = function(data)
	local created = lib.callback.await('renzu_shops:createShop', false, data)
	self.SetNotify({
		title = 'Store Business',
		description = 'New Shop has been Added',
		type = 'success'
	})
end

self.RemoveShop = function(data)

end

return self