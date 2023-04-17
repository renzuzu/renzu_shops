self = {}
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
self.JobSpheres = {}
self.Store = 'Stores_%s'
self.Blips = {}
self.StartUp = function()
	self.PlayerData = self.GetPlayerData()
	self.GetItems = function()
		if GetResourceState('ox_inventory') ~= 'started' then
			if self.QbItems == nil then
				local items = {}
				for k,v in pairs(QBCore.Shared.Items) do
					if string.find(v.name:upper(), 'WEAPON_') then
						v.name = v.name:upper()
						items[v.name:upper()] = v
					end
					items[v.name] = v
				end
				self.QbItems = items
			end
			return self.QbItems
		else
			return exports.ox_inventory:Items()
		end
	end
	Citizen.CreateThread(function()
		player = LocalPlayer.state
		Wait(2000)
		itemLists = self.GetItems()
		for k,v in pairs(itemLists) do
			self.Items[v.name] = v.label
		end
		self.LoadDefaultShops()
		for k,shop in pairs(shared.MovableShops) do
			if not shared.target then
				self.Add(shop.coord,shop.label,self.MovableShop,false,{shop = shop, type = k, price = shop.price, label = shop.label})
			else
				self.addTarget(shop.coord,shop.label,self.MovableShop,false,{shop = shop, type = k, price = shop.price, label = shop.label})
			end
			self.ShopBlip({coord = shop.coord, text = shop.label, blip = shop.blip or false})
		end
		self.LoadShops()
		self.LoadJobShops()
	end)
end

self.LoadDefaultShops = function()
	for k,shop in pairs(shared.Shops) do
		if shop.locations then
			local coordinates = shared.target and shop.targets or shop.locations
			for shopindex,v in ipairs(coordinates) do
				if not shared.oxShops or k == 'VehicleShop' then
					local shop = lib.table.deepclone(shop)
					shop.shoptype = k
					local ownedshopdata = self.GetShopData(k,shopindex)
					shop.groups = ownedshopdata and ownedshopdata.groups or shop.groups
					shop.StoreName = ownedshopdata and ownedshopdata.label
					shop.AttachmentsCustomiseOnly = ownedshopdata and ownedshopdata.AttachmentsCustomiseOnly
					shop.labelname = k..'_'..shopindex
					shop.playertoplayer = ownedshopdata and ownedshopdata.playertoplayer
					shop.moneytype = ownedshopdata and ownedshopdata.moneytype or shop.moneytype
					if shop.StoreName and self.temporalspheres[shop.labelname] and type(self.temporalspheres[shop.labelname]) == 'table' and self.temporalspheres[shop.labelname].remove then
						self.temporalspheres[shop.labelname]:remove()
					elseif shop.StoreName and self.temporalspheres[shop.labelname] and type(self.temporalspheres[shop.StoreName]) == 'number' and shared.target then
						--exports.ox_target:removeZone(self.temporalspheres[shop.labelname])
					end
					if not shared.target or ownedshopdata and ownedshopdata.marker then
						self.temporalspheres[shop.labelname] = self.Add(v,shop.name,self.OpenShop,false,{shop = shop, index = shopindex, type = k, coord = v})
					elseif not shop.groups or self.GetJobFromData(shop.groups) == self.PlayerData?.job?.name then
						self.temporalspheres[shop.labelname] = self.addTarget(v,shop.name..' '..shopindex,self.OpenShop,false,{shop = shop, index = shopindex, type = k, coord = v})
					end
				end
				self.ShopBlip({id = k..'_'..shopindex, coord = v, text = shop.name, blip = shop.blip or false})
			end
		end
	end
end

self.SetNotify = function(data)
	lib.notify({title = data.title, description = data.description, type = data.type, style = {zIndex = 9999999}})
end

self.lastdata = nil
self.addTarget = function(coord,msg,callback,server,var,delete,auto)
	local var = lib.table.deepclone(var)
	local target = nil
	local id = msg
	local targetid = exports['qb-target']:AddBoxZone(id, coord+vec3(0.0,0.0,0.0), 0.45,0.45, {
		name = msg,
		drawSprite = true,
		debugPoly = false,
		distance = 1.5,
		minZ = coord.z,
		maxZ = coord.z+0.39,
		useZ = true
	}, {
		options = {
			{
				distance = 5.5,
				icon = 'fas fa-shopping-basket',
				label = msg,
				job = var.shop?.groups,
				useZ = true,
				canInteract = function(entity, distance, coords, name)
					return distance < 1.5
				end,
				action = function()
					self.Active = lib.table.deepclone(var)
					self.lastdata = var.index
					self.movabletype = var.type
					SetNuiFocus(false,false)
					SetNuiFocusKeepInput(false)
					SetTimeout(100,function()
						callback(var)
					end)
				end
			},
		},
	})
	return shared.framework == 'QBCORE' and id or targetid
end

self.nearest = {}
self.NearestPoint = function(data,msg,callback,server,var,delete,auto)
	local drawdist = 0.6

	if self.shoptype == 'vehicle' or var.type == 'storeowner' then
		drawdist = 1.2
	end

	local nearest = data.distance < drawdist and data

	local count = 0

	if not nearest then return end

	local data = nearest

	local group = data?.var?.shop?.groups

	if group and self.GetJobFromData(group) ~= self.PlayerData?.job?.name then return end

	local shopboss = self.delivery and callback == self.StoreOwner
	
	if data.var.type and shared.MovableShops[data.var.type] and callback == self.OpenShopMovable then

		if not NetworkDoesNetworkIdExist(data.var.net) or NetworkDoesNetworkIdExist(data.var.net) and not DoesEntityExist(NetworkGetEntityFromNetworkId(data.var.net)) then

				if data.remove then
					data:remove()
				end

			return
		end
	end

	if data and data.distance < drawdist and self.lastdata ~= data.index then

		self.Active = lib.table.deepclone(data.var)

		self.lastdata = data.index

		self.movabletype = data.var.type

	end

	if not self.clerkmode then

		DrawMarker(21, data.coords.x, data.coords.y, data.coords.z, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 200, 255, 255, 255, 0, 0, 1, 1, 0, 0, 0)

	end

	if not textui and data.distance < drawdist then textui = true self.OxlibTextUi("Press [E] "..msg) elseif data.distance > drawdist+1 and textui then textui = false data.onExit() end

	if data.distance < drawdist and IsControlJustReleased(0,38) and not shopboss or auto then

		LocalPlayer.state.invOpen = callback == self.OpenShop and true
		 
		callback(data.var)

		while LocalPlayer.state.invOpen and callback == self.OpenShop and shared.inventory == 'ox_inventory' do

			TriggerEvent('ox_inventory:closeInventory')

			Wait(10)
		end

		if callback == self.OpenShop then

			Wait(1000)

			if self.shopopen then
				SetNuiFocus(true,true)
				SetNuiFocusKeepInput(false)
			end
		end

		if delete and data.remove then

			data:remove()

		end
	end

	return nearest
end

self.Add = function(coord,msg,callback,server,var,delete,auto)
	local var = var
	local textui = false
	function onExit(data)
		textui = false
		lib.hideTextUI()
		self.lastdata = nil
	end

	function inside(data)
		local data = data
		local data = self.NearestPoint(data,msg,callback,server,var,delete,auto)
	end

	SetRandomSeed(GetGameTimer()+math.random(1,99))
	local sphere = lib.zones.sphere({ index = GetRandomIntInRange(1,9999) ,var = lib.table.deepclone(var) , coords = coord, radius = 10, debug = false, inside = inside, onEnter = onEnter, onExit = onExit })
	table.insert(self.Spheres,sphere)
	return sphere
end

self.ShopBlip = function(data)
	if not data.blip then return end
	if data.id and self.Blips[data.id] and DoesBlipExist(self.Blips[data.id]) then
		RemoveBlip(self.Blips[data.id])
	end
	local blip = AddBlipForCoord(data.coord.x,data.coord.y,data.coord.z)
	SetBlipSprite(blip,data.blip.id)
	SetBlipColour(blip,data.blip.colour)
	SetBlipScale(blip,data.blip.scale)
	SetBlipAsShortRange(blip,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName(data.text)
	EndTextCommandSetBlipName(blip)
	self.Blips[data.id or data.text] = blip
	return blip
end

self.StoreData = function(id)
	return GlobalState[self.Store:format(id)]
end

self.LoadShops = function()
	if self.PlayerData.identifier == nil then return end
	for name,shops in pairs(shared.OwnedShops) do
		for k,shop in pairs(shops) do
			shop.type = 'storeowner'
			local storedata = self.StoreData(shop.label)
			if type(self.temporalspheres[shop.label]) == 'table' and self.temporalspheres[shop.label].remove then
				self.temporalspheres[shop.label]:remove()
			end
			if shop.ped then
				shop.ped()
			end
			if not storedata then
				shop.shopName = name
				shop.shopIndex = k
				if not shared.target then
					local spheres = self.Add(shop.coord,'Buy '..name..' #'..k,self.BuyStore,false,shop)
					self.temporalspheres[shop.label] = {spheres = spheres, coord = shop.coord, shop = shop, label = 'My Store '..shop.label, type = 'storeowner'}
				else
					local id = self.addTarget(shop.coord,'Buy '..name..' #'..k,self.BuyStore,false,shop)
					self.temporalspheres[shop.label] = {target = id, spheres = spheres, coord = shop.coord, shop = shop, label = 'My Store '..shop.label, type = 'storeowner'}
				end
			elseif storedata and storedata?.owner == self.PlayerData.identifier 
				or storedata and storedata.employee[self.PlayerData.identifier] or shop.groups and self.PlayerData?.job?.name and self.PlayerData?.job?.name == self.GetJobFromData(shop.groups) then
				if not shared.target then
					self.temporalspheres[shop.label] = self.Add(shop.coord,'My Store '..shop.label,self.StoreOwner,false,shop)
				else
					self.temporalspheres[shop.label] = self.addTarget(shop.coord,'My Store '..shop.label,self.StoreOwner,false,shop)
				end
				self.ShopBlip({id = name..'_'..k, coord = shop.coord, text = 'My Store '..shop.label, blip = {colour = 38, id = 374, scale = 0.6}})
				if shop.crafting then
					if not shared.target then
						self.temporalspheres[shop.label..'_crafting'] = self.Add(shop.crafting.coord,shop.crafting.label,self.Crafting,false,shop)
					else
						self.temporalspheres[shop.label..'_crafting'] = self.addTarget(shop.crafting.coord,shop.crafting.label,self.Crafting,false,shop)
					end
				end
				if shop.stash then
					if not shared.target then
						self.temporalspheres[shop.label..'_stash'] = self.Add(shop.stash,'Storage',self.Stash,false,shop)
					else
						self.temporalspheres[shop.label..'_stash'] = self.addTarget(shop.stash,'Storage',self.Stash,false,shop)
					end
				end

				if shop.work then
					for k,v in pairs(shop.work.coord) do
						if not shared.target then
							self.temporalspheres[shop.label..'_work'] = self.Add(v,shop.work.label,self.Work,false,shop.work)
						else
							self.temporalspheres[shop.label..'_work'] = self.addTarget(v,shop.work.label,self.Work,false,shop.work)
						end
					end
				end
				if shop.tasks then
					for k,task in pairs(shop.tasks) do
						for k,v in pairs(task.coord) do
							if not shared.target then
								self.temporalspheres[task.label..'_work'] = self.Add(v,task.label,task.onSelect,false,task)
							else
								self.temporalspheres[task.label..'_work'] = self.addTarget(v,task.label,task.onSelect,false,task)
							end
						end
					end
				end
				if shop.ped then
					shop.ped()
				end
				if shop.proccessed then
					if not shared.target then
						self.temporalspheres[shop.label..'_proccessed'] = self.Add(shop.proccessed.coord,shop.proccessed.label,self.Proccessed,false,shop.proccessed)
					else
						self.temporalspheres[shop.label..'_proccessed'] = self.addTarget(shop.proccessed.coord,shop.proccessed.label,self.Proccessed,false,shop.proccessed)
					end
				end
			end
			if name == 'VehicleShop' then
				for index,showcase in pairs(shop.showcase or {}) do
					if not shared.target then
						self.Add(showcase.coord,'Display '..showcase.label,self.SpotShowcase,false,{label = shop.label, owner = storedata and storedata?.owner , index = index, shop = {type = name, index = k}, showcase = showcase})
					else
						self.addTarget(showcase.coord,'Display '..showcase.label,self.SpotShowcase,false,{label = shop.label, owner = storedata and storedata?.owner , index = index, shop = {type = name, index = k}, showcase = showcase})
					end
					self.SpotZone({label = shop.label, owner = storedata and storedata?.owner == self.PlayerData.identifier , index = index, shop = {type = name, index = k}, showcase = showcase})
				end
			end
			if shop.cashier then
				local shopdata = lib.table.deepclone(shop)
				shopdata.index = k
				shopdata.type = name
				shopdata.offset = shared.Shops[name].locations[k]
				if not shared.target then
					self.Add(shopdata.cashier,'Cashier '..shopdata.label,self.Cashier,false,shopdata)
				else
					self.addTarget(shopdata.cashier,'Cashier '..shopdata.label,self.Cashier,false,shopdata)
				end
			end
		end
	end
	if not shared.target then
		self.Add(shared.shipping.coord,shared.shipping.label,self.Shipping,false,{})
	else
		self.addTarget(shared.shipping.coord,shared.shipping.label,self.Shipping,false,{})
	end
	self.ShopBlip({id = 'Shipping', coord = shared.shipping.coord, text = shared.shipping.label, blip = shared.shipping.blip})
end
self.duty = {}
self.Cashier = function(data)
	local storedatas = {index = data.index, type = data.type, offset = data.offset, money = data.moneytype}
	local options = {}
	local storedata = self.StoreData(data.label)
	if self.duty[data.label] and storedata.owner == self.PlayerData.identifier
	or storedata and storedata?.employee[self.PlayerData.identifier]
	or storedata and storedata?.job == self.PlayerData.job.name then
		local cashier = storedata?.cashier[data.moneytype] or 0
		table.insert(options,{
			title = shared.locales.withdrawcashier,
			description = shared.locales.moneyincashier:format(cashier),
			arrow = true,
			onSelect = function(args)
				local input = lib.inputDialog(shared.locales.withdrawcashiermoney, {shared.locales.cashierhowmany})
				if not input then return end
				local value = tonumber(input[1]) or 1
				local reason = lib.callback.await('renzu_shops:editstore', false, {store = data.label, type = 'withdraw_cashier', item = data.moneytype, value = value})
				if reason == 'success' then
					self.SetNotify({
						title = shared.locales.notify_title,
						description = shared.locales.successwithdraw:format(value),
						type = 'success'
					})
				end
			end
		})
		table.insert(options,{
			title = shared.locales.ongoingpurchaseorder,
			description = shared.locales.listofpurchaseorder,
			arrow = true,
			onSelect = function(args)
				self.PurchaseOrderList(data,storedatas)
			end
		})
		table.insert(options,{
			title = 'Citizen Orders',
			description = 'See list of orders from nearby players',
			arrow = true,
			onSelect = function(args)
				self.PurchaseOrderList(data,storedatas,true)
			end
		})
		table.insert(options,{
			title = shared.locales.dutyoff,
			description = shared.locales.dutyoffasclerk,
			arrow = true,
			onSelect = function(args)
				self.duty[data.label] = false
				self.OnDemand(data,'store',storedatas)
				lib.callback.await('renzu_shops:shopduty', 100, {id = data.label, duty = false})
			end
		})
		lib.callback.await('renzu_shops:shopduty', 100, {id = data.label, duty = true})
	elseif not self.duty[data.label] and storedata?.owner == self.PlayerData.identifier
		or storedata and storedata?.employee[self.PlayerData.identifier]
		or storedata and storedata?.job == self.PlayerData.job.name then
		table.insert(options,{
			title = shared.locales.dutyonclerk,
			description = shared.locales.dutyasclerk,
			arrow = true,
			onSelect = function(args)
				self.duty[data.label] = not self.duty[data.label]
				self.SetNotify({
					title = shared.locales.notify_title,
					description = shared.locales.successduty,
					type = 'success'
				})
				self.Cashier(data)
				self.OnDemand(data,'store',storedatas)
			end
		})
	elseif not self.duty[data.label] then
		table.insert(options,{
			title = shared.locales.robtitle,
			description = shared.locales.robdesc,
			arrow = true,
			onSelect = function(args)
				local confirm = lib.alertDialog({
					header = shared.locales.robconfirmhead,
					content = shared.locales.confirmrob,
					centered = true,
					cancel = true
				})
				if confirm ~= 'cancel' then
					local canrob = lib.callback.await('renzu_shops:canrobstore', false, {store = data.label, item = data.moneytype})
					if canrob then
						local success = lib.skillCheck({'normal', 'normal', {areaSize = 60, speedMultiplier = 2}, 'hard'})
						if success then
							lib.progressCircle({
								duration = 180000,
								position = 'bottom',
								useWhileDead = false,
								canCancel = false,
								disable = {
									move = true,
									car = true,
								},
							})
							local rob = lib.callback.await('renzu_shops:robstore', false, {store = data.label, item = data.moneytype})
							if rob then
								self.SetNotify({
									title = shared.locales.notify_title,
									description = shared.locales.successrob,
									type = 'success'
								})
							end
						end
					else
						self.SetNotify({
							title = shared.locales.notify_title,
							description = shared.locales.successrobdesc,
							type = 'error'
						})
					end
				end
			end
		})
	end
	lib.registerContext({
		id = 'cashier',
		title = shared.locales.mycashier,
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
			title = shared.locales.managestore,
			description = shared.locales.managestoredesc,
			arrow = true,
			menu = 'manage_store',
		}
	}
	local storedata = self.StoreData(store)
	if storedata?.owner == self.PlayerData.identifier then
		table.insert(options,{
			title = shared.locales.tranferowner,
			description = shared.locales.transferownerdesc,
			arrow = true,
			onSelect = function(args)
				self.TransferOwnerShip(store)
			end,
		})
		table.insert(options,{
			title = shared.locales.sellstoretitle,
			description = shared.locales.sellstoredesc,
			arrow = true,
			onSelect = function(args)
				CreateThread(function()
					local confirm = lib.alertDialog({
						header = shared.locales.confirmtitle,
						content = shared.locales.confirmsell,
						centered = true,
						cancel = true
					})
					if confirm ~= 'cancel' then
						local reason = lib.callback.await('renzu_shops:sellstore', false, store)
						if reason then
							self.SetNotify({
								title = shared.locales.notify_title,
								description = shared.locales.hasbeensold:format(store),
								type = 'success'
							})
							if not shared.target then
								if self.temporalspheres[store] and self.temporalspheres[store].remove then
									self.temporalspheres[store]:remove()
								elseif self.temporalspheres[store] and self.temporalspheres[store].spheres then
									self.temporalspheres[store].spheres:remove()
								end
							else
								if type(self.temporalspheres[store]) == 'table' and tonumber(self.temporalspheres[store].target) then
									exports.ox_target:removeZone(self.temporalspheres[store].target)
								elseif tonumber(self.temporalspheres[store]) then
									exports.ox_target:removeZone(self.temporalspheres[store])
								end
							end
						end
					end
				end)
			end,
		})
	end
	lib.registerContext({
		id = 'storeowner',
		title = shared.locales.mybusinesstitle,
		onExit = function()
		end,
		options = options
	})
end

self.ManageStoreMenu = function(store)
	local options = {
		{
			title = shared.locales.storeinventorytitle,
			description = shared.locales.managestocks,
			arrow = true,
			onSelect = function(args)
				return self.ManageInventory(store)
			end
		},
		{
			title = shared.locales.financemanagement,
			description = shared.locales.financedesc,
			arrow = true,
			menu = 'finance_manage',
		}
	}
	local storedata = self.StoreData(store)
	if storedata?.owner == self.PlayerData.identifier or self.adminmode then
		table.insert(options,{
			title = shared.locales.employeemanage,
			description = shared.locales.employeedesc,
			arrow = true,
			menu = 'employee_manage',
		})
	end
	lib.registerContext({
		id = 'manage_store',
		title = shared.locales.managestore,
		menu = self.adminmode and 'storeadminlist' or 'storeowner',
		onExit = function()
		end,
		options = options
	})
end

self.StoreOwner = function(data)
	local storedata = self.StoreData(data.label)
	self.currentstore = data.label
	self.shoptype = data.type
	self.moneytype = data.moneytype
	if storedata?.owner == self.PlayerData.identifier
	or storedata?.employee[self.PlayerData.identifier]
	or storedata?.job == self.PlayerData.job.name then
		self.FinanceManage(self.currentstore,data.moneytype)
		self.EmployeeManage(self.currentstore)
		self.ManageStoreMenu(self.currentstore)
		self.StoreManage(self.currentstore)
		lib.showContext('storeowner')
	else
		self.SetNotify({title = shared.locales.notify_title,description = shared.locales.fired,type = 'error'})
		if type(self.temporalspheres[self.currentstore]) == 'table' and self.temporalspheres[self.currentstore] and self.temporalspheres[self.currentstore].spheres?.remove then
			self.temporalspheres[self.currentstore].spheres:remove()
		elseif self.temporalspheres[self.currentstore] and self.temporalspheres[self.currentstore].remove then
			self.temporalspheres[self.currentstore]:remove()
		end
		if self.temporalspheres[self.currentstore] and self.temporalspheres[self.currentstore].target then
			removeZone = function()
				remove = exports.ox_target:removeZone(self.temporalspheres[self.currentstore].target)
			end
			if pcall(removeZone) then end
		end
	end
end

self.RemoveEmployee = function(data)
	local options = {}
	for k,v in pairs(data.employee) do
		table.insert(options,{
			title = shared.locales.firetitle:format(v),
			description = shared.locales.firedesc:format(v),
			arrow = true,
			onSelect = function(args)
				local reason = lib.callback.await('renzu_shops:removeemployee', false, {store = data.store, id = k})
				self.SetNotify({title = shared.locales.notify_title,description = shared.locales.successfiredesc:format(v),type = 'success'})
			end
		})
	end
	lib.registerContext({
		id = 'remove_employee',
		title = shared.locales.fireheader,
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
			description = shared.locales.citizenid:format(GetPlayerServerId(v.id)),
			arrow = true,
			onSelect = function(args)
				local reason = lib.callback.await('renzu_shops:addemployee', false, {store = data.store, id = GetPlayerServerId(v.id)})
				if reason == true then
					self.SetNotify({
						title = shared.locales.notify_title,
						description = shared.locales.offeracceptedby:format(GetPlayerServerId(v.id)),
						type = 'success'
					})
				elseif reason == 'already' then
					self.SetNotify({
						title = shared.locales.notify_title,
						description = shared.locales.alreadyemployed:format(GetPlayerServerId(v.id)),
						type = 'error'
					})
				else
					self.SetNotify({
						title = shared.locales.notify_title,
						description = shared.locales.offerdeclined:format(GetPlayerServerId(v.id)),
						type = 'error'
					})
				end
			end
		})
	end
	lib.registerContext({
		id = 'add_employee',
		title = shared.locales.inviteemployee,
		menu = 'employee_manage',
		onExit = function()
		end,
		options = options
	})
	lib.showContext('add_employee')
end

self.EmployeeManage = function(store)
	local storedata = self.StoreData(store)
	local options = {
		{
			title = shared.locales.addemployee,
			description = shared.locales.addemployeedesc,
			arrow = true,
			onSelect = function(args)
				local players = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 50.0, true)
				self.AddEmployee({players = players, store = store})
			end
		},
		{
			title = shared.locales.removeemployee,
			description = shared.locales.removeemployeedesc,
			arrow = true,
			onSelect = function(args)
				if storedata?.employee then
					self.RemoveEmployee({employee = storedata.employee, store = store})
				end
			end
		},
	}
	if storedata?.owner == self.PlayerData.identifier and storedata.job == nil then
		table.insert(options,{ -- will be improved later, like with grade system
			title = shared.locales.addjobaccess,
			description = shared.locales.addjobtocurrent:format(self.PlayerData.job.name),
			arrow = true,
			onSelect = function(args)
				local reason = lib.callback.await('renzu_shops:shopjobaccess', false, store, true)
				if reason then
					self.SetNotify({
						title = shared.locales.notify_title,
						description = shared.locales.successfulladdjob:format(self.PlayerData.job.name),
						type = 'success'
					})
				end
			end
		})
	end
	if storedata?.owner == self.PlayerData.identifier and storedata.job then
		table.insert(options,{ -- will be improved later, like with grade system
			title = 'Remove Current Job Access',
			arrow = true,
			onSelect = function(args)
				local reason = lib.callback.await('renzu_shops:shopjobaccess', false, store, false)
				if reason then
					self.SetNotify({
						title = 'Job access has been removed',
						type = 'success'
					})
				end
			end
		})
	end
	lib.registerContext({
		id = 'employee_manage',
		title = shared.locales.manageemployee,
		menu = 'manage_store',
		onExit = function()
		end,
		options = options
	})
end

self.FinanceManage = function(store,money)
	local storedata = self.StoreData(store)
	lib.registerContext({
		id = 'finance_manage',
		title = shared.locales.financemanage,
		menu = 'manage_store',
		onExit = function()
		end,
		options = {
			{
				title = shared.locales.totalmoneyvault:format(storedata.money[money] or 0),
			},
			{
				title = shared.locales.withdrawvault,
				description = shared.locales.topocket,
				arrow = true,
				onSelect = function(args)
					local input = lib.inputDialog(shared.locales.withdrawvault, {shared.locales.cashierhowmany})
					if not input then return end
					local value = tonumber(input[1]) or 1
					local reason = lib.callback.await('renzu_shops:editstore', false, {store = store, type = 'withdraw_money', item = money, value = value})
					if reason == 'success' then
						self.SetNotify({
							title = shared.locales.notify_title,
							description = shared.locales.successwithdrawvault:format(value),
							type = 'success'
						})
					else
						self.SetNotify({
							title = shared.locales.notify_title,
							description = shared.locales.notenoughtvaultmoney:format(self.Items[money],value),
							type = 'error'
						})
					end
				end
			},
			{
				title = shared.locales.depositmoneytitle,
				description = shared.locales.depositpocket,
				arrow = true,
				onSelect = function(args)
					local input = lib.inputDialog(shared.locales.deposittostore, {shared.locales.cashierhowmany})
					if not input then return end
					local value = tonumber(input[1]) or 1
					local reason = lib.callback.await('renzu_shops:editstore', false, {store = store, type = 'deposit_money', item = money, value = value})
					if reason == 'success' then
						self.SetNotify({
							title = shared.locales.notify_title,
							description = shared.locales.successdeposit:format(value),
							type = 'success'
						})
					else
						self.SetNotify({
							title = shared.locales.notify_title,
							description =shared.locales.successdeposit:format(self.Items[money],value),
							type = 'error'
						})
					end
				end
			}
		}
	})
end

self.getShopTypeAndIndex = function(store)
	for type,shop in pairs(shared.OwnedShops) do
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
				local amount = tonumber(input[1]) or 1
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
				local input = lib.inputDialog('How Many :'..item..'   \n Min: 5 Max 100', {'Whole Sale Price: '..data.pricing.original * shared.discount..'$'})
				if not input then return end
				local wholesaleorder = tonumber(input[1]) or 1
				if wholesaleorder < 5 then 
					self.SetNotify({
						title = 'Store Business',
						description = 'Order Failed - Minimum is 5',
						type = 'error'
					})
					return 
				end
				if wholesaleorder > 100 then return end
				local fee = data.pricing.original * wholesaleorder * shared.discount
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
							self.StartDelivery({dist = 0, store = store, index = 0, data = data, type = data.type, selfdeliver = shared.OwnedShops[self.ShopType][self.ShopIndex].selfdeliver})
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
				local newprice = tonumber(input[1]) or 1
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
		if self.ShopType ~= 'VehicleShop' then
			table.insert(options,{
				title = 'Deposit '..item,
				description = 'Deposit '..item..' from your inventory',
				arrow = true,
				onSelect = function(args)
					local input = lib.inputDialog('Deposit :'..item, {'How many:'})
					if not input then return end
					local value = tonumber(input[1]) or 1
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
					local value = tonumber(input[1]) or 1
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
		end

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
	local found = false
	local items = shared.Storeitems[self.ShopType]
	for k,v in pairs(items) do
		if item == v.name then
			price = v.price
			found = true
			return price
		end
	end
	if not found then -- try vehicles
		for k,v in pairs(AllVehicles) do
			if item == v.name then
				price = v.price
				found = true
				return price
			end
		end
	end
	return found
end

self.temporarycats = {}
self.CreateCategory = function(store)
	local input = lib.inputDialog('Create Category', {'Category Name:'})
	if not input then return end
	if input[1] and input[1]:gsub(' ','') == '' then return end
	if input[1] then
		self.temporarycats[input[1]] = true
		self.SetNotify({
			title = 'Store Business',
			description = 'Successfully Added new Category to Store',
			type = 'inform'
		})
		Wait(1000)
		self.SetNotify({
			title = 'Store Business',
			description = 'This Category '..input[1]..' is Temporary until you add item',
			type = 'inform'
		})
	end
end

self.CreateItem = function(data)
	local options = {}
	-- needs to be write like this since ox_lib input dialog returns values and number index only. so the order is predictable
	table.insert(options,{ type = "input", label = "Item Name", placeholder = CustomItems.Default })
	table.insert(options,{ type = "input", label = "Label Name", placeholder = 'Fat Burger' })
	table.insert(options,{ type = "input", label = "Description", placeholder = 'a delicious burger' })
	table.insert(options,{ type = "input", label = "Image", placeholder = 'insert Image URL or itemname' })
	table.insert(options,{ type = "checkbox", label = "Create Serial ID", checked = true })
	local dropdownmenu = {{ value = false, label = 'none' }}
	for k,v in pairs(CustomItems.options.Functions) do
		table.insert(dropdownmenu,{ value = k, label = k })
	end
	table.insert(options,{ type = 'select', label = 'Functions', options = dropdownmenu })
	local dropdownmenu = {{ value = false, label = 'none' }}
	for k,v in pairs(CustomItems.options.Animations) do
		table.insert(dropdownmenu,{ value = k, label = k })
	end
	table.insert(options,{ type = 'select', label = 'Animations', options = dropdownmenu })
	local dropdownmenu = {{ value = false, label = 'none' }}
	for k,v in pairs(CustomItems.options.Status) do
		table.insert(dropdownmenu,{ value = k, label = k })
	end
	table.insert(options,{ type = 'select', label = 'Status', options = dropdownmenu })
	table.insert(options,{ type = "slider", label = "Status Value", min = 1, max =  1000000, step = 1000})
	table.insert(options,{ type = "number", label = "Price", default = 50 })
	local input = lib.inputDialog('Create Custom Item', options)
	if input then
		local baseitem , label, description, image, serial, functions, animations, status, statusvalue, price = table.unpack(input)
		if baseitem and baseitem:gsub(' ','') == '' then baseitem = nil end
		if label and label:gsub(' ','') == '' then label = nil end
		if image and image:gsub(' ','') == '' then image = nil end
		if price == nil then price = 50 end
		if image and string.find(image, "http") then
			if image and image:match("^.+(%..+)$") ~= '.png' then image = nil end
		end
		local data = {store = data.store, category = data.category, image = image, description = description, itemname = baseitem , label = label, serial = serial, functions = functions, animations = animations, status = status, statusvalue = statusvalue, price = price}
		if not baseitem or not label or not image then
			self.SetNotify({
				title = 'Store Business',
				description = 'One of required fields are empty',
				type = 'error'
			})
			return false
		end
		local success = lib.callback.await('renzu_shops:createitem', false, data)
		self.SetNotify({
			title = 'Store Business',
			description = 'Successfully Added new Item to Store',
			type = 'inform'
		})
	end
end

self.ManageInventory = function(store)
	local inventory = {}
	local stocks = {}
	local prices = {}
	local disable = {}
	local store = store
	for shoptype,v in pairs(shared.OwnedShops) do
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
	local storedata = self.StoreData(store)
	local cats = {}
	local catitems = {}
	local ItemInventory = lib.table.deepclone(inventory)
	if storedata?.customitems then
		for k,v in pairs(storedata.customitems) do
			table.insert(ItemInventory,v)
		end
	end
	local additem = {}
	local addcategory = false
	for k,v in pairs(ItemInventory) do
		local item = v
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
			if not additem[category] and shared.allowplayercreateitem or not additem[category] and self.adminmode then
				additem[category] = true
				table.insert(catitems[category], {
					title = "Add New Item",
					arrow = true,
					onSelect = function()
						self.CreateItem({store = store, category = category})
					end
				})
			end
			if not addcategory and shared.allowplayercreateitem or not addcategory and self.adminmode then
				for k,v in pairs(self.temporarycats) do
					table.insert(options,{
						title = k:upper(),
						arrow = true,
						menu = 'category_'..k,
						onSelect = function(args)
							--self.EditItem(item,store,'category_'..category)
						end
					})
					if not catitems[k] then
						if not catitems[k] then catitems[k] = {} end
						table.insert(catitems[k], {
							title = "Add New Item",
							arrow = true,
							onSelect = function()
								self.CreateItem({store = store, category = k})
							end
						})
					end
					self.temporarycats[k] = nil
				end
				addcategory = true
				table.insert(options, {
					title = 'Add New Category',
					arrow = true,
					onSelect = function(args)
						self.CreateCategory({store = store})
					end
				})
			end
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
	SetModelAsNoLongerNeeded(GetHashKey(prop))
	lib.requestAnimDict(dict)
	TaskPlayAnim(ped,dict,anim,3.0,3.0,-1,flag,0,0,0,0)
	local coords = GetOffsetFromEntityInWorldCoords(ped,0.0,0.0,-5.0)
	object = CreateObject(GetHashKey(prop),coords.x,coords.y,coords.z,true,true)
	while not DoesEntityExist(object) do Wait(0) end
	SetEntityCollision(object,false,false)
	self.SetEntityControlable(object)
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
		local spawn = shared.shipping.spawn
		local model = shared.shipping.model[type]
		if var.selfdeliver then
			spawn = var.selfdeliver.coord
			model = var.selfdeliver.model
		end
		lib.requestModel(model)
		SetModelAsNoLongerNeeded(model)
		self.Vehicle = CreateVehicle(model, spawn.x,spawn.y,spawn.z, spawn.w, true, true) -- Spawns a networked self.Vehicle on your current coords
		while not DoesEntityExist(self.Vehicle) do Wait(1) end
		if type == 'vehicle' then
			self.pickupzone = self.Add(data.point,'Pick Up '..label,self.DelivertoVehicleShop,false,var,false)
		else
			self.pickupzone = self.Add(data.point,'Pick Up '..label,self.DelivertoStore,false,var,false)
		end
		shared.VehicleKeys(GetVehicleNumberPlateText(self.Vehicle))
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
		Wait(1000)
	end)
end

self.deliveryzone = nil
self.delivery = false
self.trailertransport = nil
DoScreenFadeIn(533)
self.DelivertoVehicleShop = function(var)
	local data = var.data
	self.pickupzone:remove()
	if DoesBlipExist(deliveryblip) then
		RemoveBlip(deliveryblip)
	end
	self.delivery = true
	DoScreenFadeOut(333)
	Wait(350)
	lib.requestModel(joaat('tr4'))
	self.trailertransport = CreateVehicle(joaat('tr4'), data.point[1],data.point[2],data.point[3],data.point[4], true, true)
	while not DoesEntityExist(self.trailertransport) do Wait(1) end
	self.SetEntityControlable(self.trailertransport)
	SetEntityHeading(self.Vehicle,data.point[4])
	SetVehicleOnGroundProperly(self.trailertransport)
	AttachVehicleToTrailer(self.Vehicle,self.trailertransport, 1.00)
	while not GetVehicleTrailerVehicle(self.Vehicle) == self.trailertransport do AttachVehicleToTrailer(self.Vehicle,self.trailertransport, 1.00) Wait(100) end
	Wait(1000)
	DoScreenFadeIn(533)
	local data = var
	local storecoord = vec3(0.0,0.0,0.0)
	local restockcoord = nil
	for k,v in pairs(shared.OwnedShops) do
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
			self.DeleteEntity(object)
			ClearPedTasks(cache.ped)
			break
		end
	end
	lib.hideTextUI()
	local data = data
	local storecoord = vec3(0.0,0.0,0.0)
	for k,v in pairs(shared.OwnedShops) do
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
	local boxobject = nil
	local deliver = false
	local hasobject = false
	Citizen.CreateThreadNow(function()
		while not hasobject do
			local sleep = 1000
			local dist = #(GetEntityCoords(self.playerPed) - vector3(storecoord.x,storecoord.y,storecoord.z-1.0))
			if dist < 50 then
				sleep = 1
			end
			local box = DoesEntityExist(boxobject)
			if dist < 50 and not IsPedInAnyVehicle(self.playerPed) and not box and not hasobject then
				SetVehicleDoorOpen(self.Vehicle,2,0,0)
				SetVehicleDoorOpen(self.Vehicle,3,0,0)
				SetVehicleDoorOpen(self.Vehicle,5,0,0)
	
				local xa,ya,za = table.unpack(GetWorldPositionOfEntityBone(self.Vehicle,GetEntityBoneIndexByName(self.Vehicle,"door_dside_r")))
				local xb,yb,zb = table.unpack(GetWorldPositionOfEntityBone(self.Vehicle,GetEntityBoneIndexByName(self.Vehicle,"door_pside_r")))
	
				local x = (xa+xb)/2
				local y = (ya+yb)/2
				local z = (za+zb)/2
				while #(GetEntityCoords(self.playerPed) - vector3(x,y,z-1.0)) > 8 and not box and not hasobject do
					Wait(1)
				end
				self.OxlibTextUi("Press [E] to Pick Up Box")
				 while not hasobject do 
					Wait(1) 
					DrawMarker(39,x,y,z-0.5,0,0,0,0.0,0,0,1.0,1.0,1.0,255,0,0,50,0,0,0,1)
					if IsControlJustPressed(0,38) then
						hasobject = true
						boxobject = self.BoxObject("anim@heists@box_carry@","idle","hei_prop_heist_box",50,28422)
						Wait(500)
						break
					end
				end
				lib.hideTextUI()
			end
			Wait(sleep)
		end
		if hasobject then
			--if DoesEntityExist(object) and dist < 3 and not textui then textui = true self.OxlibTextUi("Press [E] to Deliver") end
			while hasobject do
				dist = #(GetEntityCoords(self.playerPed) - vector3(storecoord.x,storecoord.y,storecoord.z-1.0))
				DrawMarker(39,storecoord.x,storecoord.y,storecoord.z-0.5,0,0,0,0.0,0,0,1.0,1.0,1.0,255,0,0,50,0,0,0,1)
				if DoesEntityExist(boxobject) and not deliver and dist < 5 and IsControlJustPressed(0,38) then
					deliver = true
					SetVehicleDoorShut(self.Vehicle,2,0)
					SetVehicleDoorShut(self.Vehicle,3,0)
					SetVehicleDoorShut(self.Vehicle,5,0)
					 break
				end
				Wait(1)
			end
		end
		self.DeleteEntity(boxobject)
		Wait(2000)
		self.Add(storecoord,'Deliver '..self.Items[data.data.item.name],self.DeliverDone,false,data,true,true)
	end)
	return true
end

self.DeliverDone = function(data)
	ClearPedTasks(cache.ped)
	lib.hideTextUI()
	if DoesBlipExist(deliveryblip) then
		RemoveBlip(deliveryblip)
	end
	if DoesEntityExist(self.trailertransport) then
		self.DeleteEntity(self.trailertransport)
	end
	local delivered = lib.callback.await('renzu_shops:stockdelivered', false, data)
	if data.selfdeliver then
		self.SetNotify({
			title = 'Store Business',
			description = 'Stock ha been Updated',
			type = 'inform'
		})
		self.DeleteEntity(self.Vehicle)
	else
		self.SetNotify({
			title = 'Store Business',
			description = 'Go back to Shipping Garage to Finish the job',
			type = 'inform'
		})
		SetNewWaypoint(shared.shipping.spawn)
		deliveryblip = AddBlipForCoord(shared.shipping.spawn.x,shared.shipping.spawn.y,shared.shipping.spawn.z)
		self.SetBlip(deliveryblip,358,26,'Shipping Garage')
		SetBlipRoute(deliveryblip,true)
		SetBlipRouteColour(deliveryblip,3)
		self.Add(vec3(shared.shipping.spawn.x,shared.shipping.spawn.y,shared.shipping.spawn.z),'Finish Delivery Job',self.JobDone,false,data,true)
	end
end

self.JobDone = function(data)
	if DoesBlipExist(deliveryblip) then
		RemoveBlip(deliveryblip)
	end
	self.DeleteEntity(self.Vehicle)
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
	local ongoing = GlobalState.OngoingShip
	for store,v in pairs(data) do
		for k,v in pairs(v) do
			local loc = vec3(v.point[1],v.point[2],v.point[3])
			local hashstreet = GetStreetNameAtCoord(loc.x,loc.y,loc.z)
			local streetname = GetStreetNameFromHashKey(hashstreet)
			local dist = math.floor(#(GetEntityCoords(self.playerPed) - loc)+0.5)
			if not ongoing[store] or ongoing[store] and ongoing[store][v.id] == nil then
				local pay = dist * shared.shipping.payperdistance
				local label = self.Items[v.item.name] or v.item.label
				if v.item.metadata and v.item.metadata.label then
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
							Wait(500)
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
	local storedata = self.StoreData(data.label)
	if storedata then return end
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
				local spheredata = self.temporalspheres[data.label]
				if not shared.target then
					if self.temporalspheres[data.label].spheres?.remove then
						self.temporalspheres[data.label].spheres:remove()
					end
					local sphere = self.Add(spheredata.coord,spheredata.label,self.StoreOwner,false,spheredata.shop)
					self.temporalspheres[data.label].spheres = sphere
				else
					if spheredata then
						exports.ox_target:removeZone(spheredata.target)
					end
					local id = self.addTarget(spheredata.coord,spheredata.label,self.StoreOwner,false,spheredata.shop)
					self.temporalspheres[data.label].target = id
				end
			end
		end
	end
end

self.OpenShop = function(data)
	if self.shopopen then return end
	local data = lib.table.deepclone(data)
	local grade = self.PlayerData?.job?.grade
	-- shop data of defaults shops
	if not self.Active or  not self.Active.shop then return end
	data.shop.inventory = data.shop.inventory or shared.Storeitems[data.type] or {}
	self.Active.shop.inventory = data.shop.inventory or {}
	self.Active.shop.type = data.type
	self.Active.shop.StoreName = data.shop.StoreName
	for k,v in pairs(data.shop.inventory or {}) do
		data.shop.inventory[k].disable = data.shop.inventory[k].disable or false
		data.shop.inventory[k].label = v.metadata and v.metadata.label or self.Items[v.name] or v.label
		if data.type == 'Ammunation' or data.type == 'BlackMarketArms' then
			data.shop.inventory[k].component = self.GetWeaponComponents(v.name,true)
		end
		if v.grade and v.grade > grade then
			data.shop.inventory[k].disable = true
		end
		if data.type == 'VehicleShop' then
			data.shop.inventory[k].hash = joaat(data.shop.inventory[k].name or 'null')
		end
		if data.shop?.AttachmentsCustomiseOnly and data.shop?.inventory[k].category == 'attachments' then
			data.shop.inventory[k].disable = true
		end
	end
	self.moneytype = data.shop.moneytype

	self.Active.shop.moneytype = self.moneytype
	-- shop data for owned shops
	local ownedshops = lib.table.deepclone(shared.OwnedShops)
	local storename = nil
	for type,v in pairs(ownedshops) do
		for k,v2 in pairs(v) do
			if k == data.index and type == data.type then
				local storedata = self.StoreData(v2.label)
				self.moneytype = v2.moneytype
				self.itemType = v2.item
				data.shop.label = v2.label
				data.shop.inventory = v2.supplieritem
				self.Active.shop.inventory = v2.supplieritem
				self.Active.camerasetting = v2.camerasetting
				for k,v in pairs(data.shop.inventory) do
					data.shop.inventory[k].disable = data.shop.inventory[k].disable or false
					data.shop.inventory[k].label = v.metadata and v.metadata.label or self.Items[v.name] or v.label
					if data.type == 'Ammunation' or data.type == 'BlackMarketArms' then
						data.shop.inventory[k].component = self.GetWeaponComponents(v.name,true)
					end
					if v.grade and v.grade > grade then
						data.shop.inventory[k].disable = true
					end
					if v2.AttachmentsCustomiseOnly and data.shop.inventory[k].category == 'attachments' then
						data.shop.inventory[k].disable = true
					end
				end
				if storedata then
					storename = v2.label
					local ItemInventory = lib.table.deepclone(v2.supplieritem)
					if storedata.customitems then
						for k,v in pairs(storedata.customitems) do
							v.disable = false
							table.insert(ItemInventory,v)
						end
					end
					for k,item in pairs(ItemInventory) do
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
						if data.type == 'Ammunation' or data.type == 'BlackMarketArms' then
							data.shop.inventory[k].component = self.GetWeaponComponents(item.name,true)
						end
						if item.grade and item.grade > grade then
							data.shop.inventory[k].disable = true
						end
					end
					self.Active.shop.type = data.type
					self.Active.shop.inventory = data.shop.inventory
					if data.type == 'VehicleShop' then
						data.shop.inventory[k].hash = joaat(data.shop.inventory[k].name or 'null')
					end
					if v2.AttachmentsCustomiseOnly and data.shop.inventory[k].category == 'attachments' then
						data.shop.inventory[k].disable = true
					end
				end
			end
		end
	end
	local money = self.GetAccounts(self.moneytype or 'money',self.itemType)
	local black_money = self.GetAccounts('black_money')
	local bank = self.GetAccounts('bank')
	local shop_data = self.StoreData(data.shop.label)
	SendNUIMessage({
		type = 'shop',
		data = {
			duty = shop_data?.duty,
			vImageCreator = GlobalState?.VehicleImages or {}, 
			imgpath = self.ImagesPath(), 
			itemtype = self.itemType, 
			moneytype = self.moneytype or 'money', 
			type = data.type, 
			open = true, 
			shop = data.shop, 
			label = data.shop.label or data.shop.name, 
			wallet = {money = self.format_int(money), black_money = self.format_int(black_money), bank = self.format_int(bank)}
		}
	})
	SetNuiFocus(true,true)
	SetNuiFocusKeepInput(false)
	self.shopopen = true
end

self.format_int = function(n)
	return tostring(math.floor(n)):reverse():gsub("(%d%d%d)","%1,"):gsub(",(%-?)$","%1"):reverse()
end

self.OxlibTextUi = function(msg,fa)
	lib.showTextUI(msg, {
		position = "left-center",
		icon = fa or 'fas fa-shopping-basket',
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
		data = {open = false, shop = data}
	})
	SetNuiFocus(false,false)
	SetNuiFocusKeepInput(false)
	self.shopopen = not self.shopopen
	TriggerScreenblurFadeOut(0)
	self.view = false
	RenderScriptCams(false)
	DestroyAllCams(true)
	ClearFocus()
	if DoesEntityExist(self.chosenvehicle) then
		self.DeleteEntity(self.chosenvehicle)
	end
end

self.GetAccounts = function(name,item)
	local xPlayer = self.GetPlayerData()

	if item then
		return self.getInventoryItems(name)
	end

	if shared.framework == 'ESX' then
		local xPlayer = self.GetPlayerData()
		for k,v in ipairs(xPlayer.accounts) do
			if v.name == name then
				return v.money or 0
			end
		end
	else
		return xPlayer.money[name == 'money' and 'cash' or name] or 0
	end
end

self.worldoffset = {}
self.playerPed = cache.ped

self.GetJobFromData = function(job)
	if not job then return end
	if type(job) == 'string' then return job end
	for k,v in pairs(job) do
		if v == self.PlayerData?.job?.name then
			return v
		end
	end
	return false
end

self.Handlers = function()
	lib.onCache('ped', function(ped)
		self.playerPed = ped
	end)
	RegisterNetEvent('renzu_shops:removecart', function(id,nomoney)
		SendNUIMessage({removecart = id})
		if nomoney then
			lib.defaultNotify({
				title = 'You dont have enough money',
				status = 'warning'
			})
		end
	end)
	RegisterNetEvent('renzu_shops:customernomoney', function(id,nomoney)
		if nomoney then
			lib.defaultNotify({
				title = 'Customer dont have enough money',
				status = 'warning'
			})
		end
	end)
	RegisterNetEvent('renzu_shop:Vehiclekeys', function(plate)
		return shared.VehicleKeys(plate)
	end)
	RegisterNetEvent('renzu_shop:OpenShops', function(data)
		Wait(500)
		local ownedshopdata = self.GetShopData(data.type,data.id)
		local group = ownedshopdata?.groups or shared.Shops[data.type].groups
		if self.shopopen then return end
		if group and self.GetJobFromData(group) ~= self.PlayerData?.job?.name then return end
		local shop = shared.Shops[data.type]
		local coord = shared.Shops[data.type].locations[data.id]
		local closest = nil
		for k,v in pairs(shared.Shops[data.type].locations) do
			local dist = #(GetEntityCoords(cache.ped) - v)
			if closest and dist < closest or closest == nil then
				data.id = k
				coord = v
				closest = dist
			end
		end
		local shopdata = {index = data.id, type = data.type, coord = coord, shop = shop}
		self.Active = lib.table.deepclone(shopdata)
		self.movabletype = data.type
		self.OpenShop(shopdata)
	end)
	AddStateBagChangeHandler("CreateShop", "global", function(bagName, key, value)
		Wait(1000)
		shared.OwnedShops = request('config/ownedshops/init')
		if value then
			local data = {shop = value.shop, index = value.index, type = value.type, coord = value.loc}
			if not shared.target then
				if not shared.oxShops then
					self.Add(value.loc,value.label,self.OpenShop,false,data)
				end
				value.shop.shopName = value.type
				value.shop.shopIndex = value.index
				local spheres = self.Add(value.coord,'Buy '..value.type..' #'..value.index,self.BuyStore,false,value.shop)
				self.temporalspheres[value.label] = {spheres = spheres, coord = value.coord, shop = value.shop, label = 'My Store '..value.label}
			else
				self.addTarget(value.loc,value.label,self.OpenShop,false,data)
				self.addTarget(value.coord,'Buy '..value.type..' #'..value.index,self.BuyStore,false,value.shop)
			end
			value.shop.index = value.index
			value.shop.type = value.type
			value.shop.offset = shared.Shops[value.type].locations[value.index]
			if not shared.target then
				self.Add(value.cashier,'Cashier '..value.label,self.Cashier,false,value.shop)
			else
				self.addTarget(value.cashier,'Cashier '..value.label,self.Cashier,false,value.shop)
			end
		end
	end)

	AddStateBagChangeHandler("AvailableStore", "global", function(bagName, key, value)
		Wait(1000)
		local storedata = self.StoreData(value.store)
		if not storedata then
			for name,shop in pairs(shared.OwnedShops) do
				for k,v in pairs(shop) do
					if v.label == value.store then
						v.shopName = name
						v.shopIndex = k
						if not shared.target then
							local spheres = self.Add(v.coord,'Buy '..name..' #'..k,self.BuyStore,false,v)
							self.temporalspheres[v.label] = {spheres = spheres, coord = v.coord, shop = v, label = 'My Store '..v.label}
						else
							local target = self.addTarget(v.coord,'Buy '..name..' #'..k,self.BuyStore,false,v)
							self.temporalspheres[v.label] = {target = target, spheres = spheres, coord = v.coord, shop = v, label = 'My Store '..v.label}
						end
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
			local data = shared.MovableShops[value.type]
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
		local data = shared.MovableShops[value.type]
		if data and data.type == 'vehicle' then
			worldoffset = vec3(2.0,-2.0,0.5)
		end
		local offset = GetOffsetFromEntityInWorldCoords(entity,worldoffset.x,worldoffset.y,worldoffset.z)
		if value.selling and not spheres[value.identifier] then
			spheres[value.identifier] = self.Add(offset,value.type,self.OpenShopMovable,false,{type = value.type, identifier = value.identifier, net = net})
			if string.find(value.identifier,self.PlayerData.identifier) then
				self.movableentity[value.type] = entity
			end
		elseif spheres[value.identifier].remove then
			spheres[value.identifier]:remove()
			spheres[value.identifier] = nil
			Wait(100)
			if value.selling then
				spheres[value.identifier] = self.Add(offset,value.type,self.OpenShopMovable,false,{type = value.type, identifier = value.identifier, net = net})
			end
		end
	end)

	AddStateBagChangeHandler("JobShopNotify", "global", function(bagName, key, value)
		Wait(1000)
		if not value then return end
		if value.job ~= self.PlayerData.job.name then return end
		if value.owner == self.PlayerData.identifier then return end
		for name,shop in pairs(shared.OwnedShops) do
			for k,v in pairs(shop) do
				if v.label == value.store then
					if not shared.target then
						self.temporalspheres[shop.label] = self.Add(v.coord,'My Store '..v.label,self.StoreOwner,false,v)
					else
						self.addTarget(shop.coord,'My Store '..v.label,self.StoreOwner,false,v)
					end
					break
				end
			end
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
				for k,shops in pairs(shared.OwnedShops) do
					for k,shop in pairs(shops) do
						if value.store == shop.label then
							if not shared.target then
								self.Add(shop.coord,'Manage '..shop.label,self.StoreOwner,false,shop)
							else
								self.addTarget(shop.coord,'Manage '..shop.label,self.StoreOwner,false,shop)
							end
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
		local shop = self.Active?.shop?.inventory
		local itemdata = {}
		if not shop then self.Closeui() return end
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
		elseif data.msg == 'playercarts' then
			local playerid = GetPlayerServerId(PlayerId())
				lib.callback.await('renzu_shops:updateshopcart',100, {playerid = playerid, cart = data.cart, bagname = 'player:', shop = self.Active?.shop?.StoreName})
		elseif data.msg == 'buy' then
			local total = 0
			local itemdata = {}
			for k,v in pairs(shop) do
				itemdata[v.metadata and v.metadata.name or v.name] = v
			end
			local totalamount = 0

			for k,v in pairs(data.items) do
				totalamount += tonumber(v.count)
				total = total + tonumber(itemdata[v.data.metadata and v.data.metadata.name or v.data.name].price) * tonumber(v.count)
			end

			data.type = self.PaymentMethod({amount = total, total = totalamount, type = self.Active.shop.type, name = self.Active.shop.StoreName, money = self.Active?.shop?.moneytype or 'money'}) or self.Active?.shop?.moneytype or 'money'
			if data.type == 'cancel' then return end
			local financedata
			if data.type == 'finance' then
				finance, financedata = self.Finance({amount = total, total = totalamount, type = self.Active.shop.type, name = self.Active.shop.StoreName})
				total = financedata.downpayment
			end
			if data.type == 'finance' and finance == 'cancel' then
				return
			end
			local confirm = lib.alertDialog({
				header = 'Confirm Buy',
				content = 'Are you sure you want to pay?   \n Amount : '..total..' $  \n Method : '..data.type,
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
					elseif reason == 'license' then
						self.SetNotify({
							title = 'Store Business',
							description = 'You dont have a licensed to purchase ',
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
							local plate = nil
							for k,v in pairs(data.items) do
								chosen = v
								plate = reason[v.data.name]
								break
							end
							local model = GetHashKey(chosen.data.name)
							lib.requestModel(model)
							SetModelAsNoLongerNeeded(model)
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
							SetVehicleNumberPlateText(vehicle,plate)
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
				end,{owner = self.Owner, groups = self.Active?.shop?.groups, finance = financedata, items = data.items, data = itemdata, index = self.Active.index, type = data.type, shop = self.Active.shop.type or self.shopidentifier, moneytype = self.moneytype})
				self.Owner = nil
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
			local componentitems = self.GetWeaponComponents(data.item)
			cb(componentitems)
		elseif data.msg == 'testdrive' then
			local model = GetHashKey(data.vehicle.model)
			lib.requestModel(model)
			SetModelAsNoLongerNeeded(model)
			local shopdata = self.GetShopData(self.Active.type,self.Active.index)
			local vehicle = CreateVehicle(model, shopdata.purchase.x,shopdata.purchase.y,shopdata.purchase.z, shopdata.purchase.w, true, true)
			while not DoesEntityExist(vehicle) do Wait(0) end
			-- for server setter vehicle incase you dont owned the entity.
			SetEntityAsMissionEntity(vehicle,true,true)
			self.Closeui()
			TaskWarpPedIntoVehicle(self.playerPed, vehicle, -1)
			local second = 60
			self.SetNotify({
				title = 'Test Drive Start',
				type = 'inform'
			})
			while second > 0 do
				self.OxlibTextUi("Test Drive: "..second, '<i class="fas fa-car"></i>')
				Wait(1000)
				second -= 1
				if GetVehiclePedIsIn(self.playerPed) == 0 then break end
			end
			self.DeleteEntity(vehicle)
			RequestCollisionAtCoord(self.playerPed,shopdata.purchase.x,shopdata.purchase.y,shopdata.purchase.z)
			SetEntityCoords(self.playerPed,shopdata.purchase.x,shopdata.purchase.y,shopdata.purchase.z)
			self.SetNotify({
				title = 'Test Drive Complete',
				type = 'inform'
			})
			lib.hideTextUI()
			cb(true)
		end
	end)
end
self.view = false
self.downloading = false
self.chosenvehicle = nil

self.GetWeaponComponents = function(weapon,check)
	local componentitems = {}
	local hascomponents = false
	for item,v in pairs(Components) do
		if v.client and v.client.component then
			for k,componenthash in pairs(v.client.component) do
				if DoesWeaponTakeWeaponComponent(GetHashKey(weapon), componenthash) then
					if check then
						hascomponents = true
						break
					end
					table.insert(componentitems,{name = v.name, label = v.label})
				end
			end
			if hascomponents then break end
		end
	end
	if check then return hascomponents end
	return componentitems
end

self.GetShopData = function(si,li)
	for k,v in pairs(shared.OwnedShops) do
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
			self.DeleteEntity(nearveh)
		end
		while DoesEntityExist((nearveh)) do self.DeleteEntity(nearveh) Wait(100) end
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
			SetModelAsNoLongerNeeded(model)
			BusyspinnerOff()
			SetNuiFocus(true, true)
			loading = true
			self.downloading = false
		end
		if DoesEntityExist(self.chosenvehicle) then self.DeleteEntity(self.chosenvehicle) end
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
	local conceals = {}
	for k,v in pairs(GetGamePool('CVehicle')) do
		table.insert(conceals,v)
		SetEntityVisible(v, false, 0)
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
		for k,v in pairs(conceals) do
			SetEntityVisible(v, true, 0)
		end
		conceals = {}
	end)
end

self.ReturnMovable = function()
	if DoesEntityExist(self.movableentity[self.movabletype]) then
		self.DeleteEntity(self.movableentity[self.movabletype])
	end
	if DoesEntityExist(self.bike[self.movabletype]) then
		self.DeleteEntity(self.bike[self.movabletype])
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
		self.ondemand = false
		self.movablemode = false
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
self.startingsell = {}
self.movablemode = false
self.MovableShopStart = function(data)
	local movabletype = self.movabletype
	if not DoesEntityExist(self.movableentity[movabletype]) then
		self.movableentity[movabletype] = self.SpawnMovableEntity(data)
	end
	self.movablemode = true
	local nets = {}
	table.insert(nets,NetworkGetNetworkIdFromEntity(self.movableentity[movabletype]))
	--LocalPlayer.state:set('movableentity',nets,true)
	self.SetClientStateBags({
		entity = GetPlayerServerId(PlayerId()), 
		name = 'movableentity', 
		data = {bagname = 'player:', nets = nets},
	})
	local identifier = movabletype..':'..self.PlayerData.identifier
	self.SetClientStateBags({
		entity = self.movableentity[movabletype], 
		name = 'movableshop', 
		data = {identifier = identifier, type = movabletype, selling = true}
	})
	local ent = Entity(self.movableentity[movabletype]).state
	self.driving = false
	self.worldoffset[movabletype] = vec3(0.0,1.0,0.5)
	if data.type == 'vehicle' then
		self.worldoffset[movabletype] = vec3(0.0,-5.0,0.5)
	end
	self.incockpit = false
	while not ent.movableshop do Wait(10) end
	self.movabletextui = false
	CreateThread(function()
		local entity = self.movableentity[movabletype]
		self.startingsell[movabletype] = false
		while self.movableentity[movabletype] or self.movablemode do
			local sleep = 1000
			local worldoffset = self.worldoffset[movabletype]
			local offset
			if worldoffset then
				offset = GetOffsetFromEntityInWorldCoords(self.movableentity[movabletype],worldoffset.x,worldoffset.y,worldoffset.z)
				self.clerkmode = false
				if not self.startingsell[movabletype] and #(GetEntityCoords(self.playerPed) - offset) < 1 then
					sleep = 5
					if not self.movabletextui then
						self.movabletextui = true
						self.OxlibTextUi("Press [E] Open Shop Menu")
					end
					self.clerkmode = true
				elseif not self.clerkmode and not ent.movableshop.selling and data.type == 'object' then
					sleep = 5
					DisableControlAction(0,75,true)
					DisableControlAction(27, 75, true)
					--SetVehicleIndividualDoorsLocked(self.bike[movabletype],-1,2)
					--SetVehicleDoorsLocked(self.bike[movabletype],4)
					if DoesEntityExist(self.bike[movabletype]) and not IsPedInAnyVehicle(self.playerPed) then
						self.startingsell[movabletype] = false
						local identifier = movabletype..':'..self.PlayerData.identifier
						self.SetClientStateBags({
							entity = self.movableentity[movabletype], 
							name = 'movableshop', 
							data = {identifier = identifier, type = movabletype, selling = true}
						})
						if data.type == 'object' then
							SetEntityCollision(self.bike[movabletype],false,true)
							FreezeEntityPosition(self.bike[movabletype],true)
							SetEntityAlpha(self.bike[movabletype],1,true)
							DetachEntity(self.movableentity[movabletype],true)
							PlaceObjectOnGroundProperly(self.movableentity[movabletype])
							ClearPedTasks(self.playerPed)
							ResetPedMovementClipset(self.playerPed)
							local bikecoord = GetEntityCoords(self.bike[movabletype])
							self.bikecoords[movabletype] = vec4(bikecoord.x,bikecoord.y,bikecoord.z,GetEntityHeading(self.bike[movabletype]))
							self.DeleteEntity(self.bike[movabletype])
							--SetEntityCoords(self.playerPed,coord)
						end
					end
				else
					if self.movabletextui then
						self.movabletextui = false
						lib.hideTextUI()
					end
					ent = Entity(self.movableentity[movabletype]).state
					if data.type == 'vehicle' and GetEntitySpeed(entity) < 1 then
						if not ent.movableshop.selling and self.driving then
							self.SetClientStateBags({
								entity = self.movableentity[movabletype], 
								name = 'movableshop', 
								data = {identifier = identifier, type = movabletype, selling = true}
							})
						end
						self.driving = false
					elseif data.type == 'vehicle' and GetEntitySpeed(entity) > 2 then
						self.driving = true
						if ent.movableshop.selling then
							SetVehicleDoorShut(entity,5,0)
							self.SetClientStateBags({
								entity = self.movableentity[movabletype], 
								name = 'movableshop', 
								data = {identifier = identifier, type = movabletype, selling = false}
							})
						end
					end
					local type = movabletype -- supports multiple shop in same loops for the same identifier
					while data.type == 'vehicle' and #(GetEntityCoords(self.playerPed) - offset) > 2 and not IsPedInAnyVehicle(self.playerPed)
					or data.type == 'object' and not data.truck and #(GetEntityCoords(self.playerPed) - offset) > 2
					or data.type == 'object' and data.truck and IsPedInAnyVehicle(self.playerPed) do Wait(100) end
					self.movabletype = type
				end
			end
			if sleep == 5 and offset then 
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
			if IsDisabledControlJustPressed(0,49) and IsPedInAnyVehicle(self.playerPed) then self.startingsell[movabletype] = true ClearPedTasks(self.playerPed) TaskLeaveVehicle(self.playerPed,self.bike[movabletype],262144) end
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
		self.SetEntityControlable(self.movableentity[self.movabletype])
		AttachEntityToEntity(self.playerPed, self.movableentity[self.movabletype], 19, 1.1, -3.2, 0.6, 0.0, 0.0, -90.0, false, false, false, false, 20, true)
		FreezeEntityPosition(self.playerPed,true)
		SetGameplayCamVehicleCamera('phantom')
		SetGameplayCamVehicleCameraName(`phantom`)
		SetCamFov(gameplaycam,200.0)
		local cockpit = GetOffsetFromEntityInWorldCoords(self.movableentity[self.movabletype], 8.0,-7.0,2.1)
		--self.cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", cockpit, 360.00, 0.00, 0.00, 60.00, false, 0)
		--PointCamAtCoord(self.cam, spawn.x, spawn.y, spawn.z+0.1)
		--PointCamAtEntity(self.cam,self.movableentity[self.movabletype],1.0,-1.0,-0.2)
		--SetCamActive(self.cam, true)
		--SetCamFov(self.cam, 45.0)
		--SetCamRot(self.cam, -15.0, 0.0, 252.063)
		--RenderScriptCams(true, true, 3000, true, true)
		SetVehicleDoorShut(self.movableentity[self.movabletype],2,0)
		SetVehicleDoorShut(self.movableentity[self.movabletype],3,0)
		Citizen.CreateThreadNow(function()
			while self.incockpit do
				Wait(1)
				SetFollowPedCamViewMode(2)
				DisableCamCollisionForEntity(self.movableentity[self.movabletype])
			end
		end)
	else
		DetachEntity(self.playerPed)
		self.incockpit = false
		local cockpit = GetOffsetFromEntityInWorldCoords(self.movableentity[self.movabletype], 0.0, -6.0, 0.0)
		SetEntityCoords(self.playerPed,cockpit.x,cockpit.y,cockpit.z)
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
		ent = CreateVehicle(model, data.spawn.x,data.spawn.y,data.spawn.z,data.spawn.w, true, true)
		while not DoesEntityExist(ent) do Wait(1) end
		local plate = vehicledata.plate
		SetVehicleNumberPlateText(ent,plate)
	else
		local coord = GetEntityCoords(self.playerPed)
		ent = CreateObject(model, coord.x+1.0,coord.y+3.0,coord.z+0.5, true, true, false)
		while not DoesEntityExist(ent) do Wait(1) end
	end
	--while not NetworkGetEntityIsNetworked(ent) do Wait(1) NetworkRegisterEntityAsNetworked(ent) end
	self.SetEntityControlable(ent)
	PlaceObjectOnGroundProperly(ent)
	SetModelAsNoLongerNeeded(model)
	return ent
	--AttachEntityToEntity(ent, ped, bone, data["x"], y, data["z"], data["x_rotation"], data["y_rotation"], data["z_rotation"], 0, 1, 0, 1, 0, 1)
end
self.SetClientStateBags = function(value)
	local entity = NetworkGetNetworkIdFromEntity(value.entity)
	if value.data.bagname == 'player:' then
		entity = value.entity
	end
	local setState = lib.callback.await('renzu_shops:playerStateBags', false, {
		entity = entity, 
		name = value.name, 
		data = value.data,
		ts = GetGameTimer()+math.random(1,999)
	})
	-- LocalPlayer.state:set('renzu_shops:playerStateBags', {
	-- 	entity = entity, 
	-- 	name = value.name, 
	-- 	data = value.data,
	-- 	ts = GetGameTimer()+math.random(1,999)
	-- }, true)
end
self.bike = {}
self.bikecoords = {}
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
					local model = data.vehicle
					lib.requestModel(model)
					SetModelAsNoLongerNeeded(model)
					local bikecoord = self.bikecoords[self.movabletype]
					or GetEntityCoords(self.playerPed)+vec3(0.7,0.5,0.0)
					if not DoesEntityExist(self.bike[self.movabletype]) then
						self.bike[self.movabletype] = CreateVehicle(model, bikecoord.x,bikecoord.y,bikecoord.z+10.0, true, true)
					end
					while not DoesEntityExist(self.bike[self.movabletype]) do Wait(0) end
					while not NetworkGetEntityIsNetworked(self.bike[self.movabletype]) do Wait(0) NetworkRegisterEntityAsNetworked(self.bike[self.movabletype]) end
					FreezeEntityPosition(self.bike[self.movabletype],true)
					self.SetEntityControlable(self.bike[self.movabletype])
					SetEntityCoordsNoOffset(self.bike[self.movabletype],bikecoord.x,bikecoord.y,bikecoord.z-0.5)
					SetVehicleOnGroundProperly(self.bike[self.movabletype])
					SetEntityNoCollisionEntity(self.bike[self.movabletype],self.movableentity[self.movabletype],false)
					SetEntityHeading(self.bike[self.movabletype],bikecoord.w or 0)
					SetPedIntoVehicle(self.playerPed,self.bike[self.movabletype],-1)
					self.SetEntityControlable(self.movableentity[self.movabletype])
					FreezeEntityPosition(self.bike[self.movabletype],false)
					AttachEntityToEntity(self.movableentity[self.movabletype], self.bike[self.movabletype], GetEntityBoneIndexByName(self.bike[self.movabletype], 'engine'), data.pos.x,data.pos.y,data.pos.z, data.rot.x,data.rot.y,data.rot.z, 1, 0, 0, 0, 1, 1)
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
					FreezeEntityPosition(self.bike[self.movabletype],true)
					DetachEntity(self.movableentity[self.movabletype],true)
					PlaceObjectOnGroundProperly(self.movableentity[self.movabletype])
					ClearPedTasks(self.playerPed)
					ResetPedMovementClipset(self.playerPed)
					local bikecoord = GetEntityCoords(self.bike[self.movabletype])
					self.bikecoords[self.movabletype] = vec4(bikecoord.x,bikecoord.y,bikecoord.z,GetEntityHeading(self.bike[self.movabletype]))
					self.DeleteEntity(self.bike[self.movabletype])
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
			if shared.inventory == 'ox_inventory' then
				TriggerEvent('ox_inventory:openInventory', 'stash', {id = identifier, name = self.movabletype, slots = 40, weight = 40000, coords = GetEntityCoords(self.movableentity[self.movabletype])})
			elseif shared.inventory == 'qb-inventory' then
				TriggerServerEvent('inventory:server:OpenInventory', 'stash', identifier, {})
				TriggerServerEvent("InteractSound_SV:PlayOnSource", "StashOpen", 0.4)
				TriggerEvent("inventory:client:SetCurrentStash", identifier)
			end
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
		description = 'See list of orders from nearby locals',
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

self.ServePurchaseOrder = function(var,i,storedata,player)
	if self.ongoingpack then return end
	self.ongoingpack = true
	if not var.ingredients then
		local items = {}
		table.insert(items,{name = var.name, count = var.count or 1})
		local type = self.movabletype
		if storedata then
			type = storedata.type
		end
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
		local removed = lib.callback.await('renzu_shops:removestock', false, {serialid = var.serialid, type = type, name = var.name, count = var.count or 1, price = var.data.price, metadata = var.data.metadata, index = storedata and storedata.index, money = storedata and storedata.money, customer = player and var.customer})
		if removed then
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
			self.PlayAnim({dict = 'creatures@rottweiler@tricks@', anim = 'petting_franklin'})
			lib.requestModel(`prop_food_bag1`)
			if not self.foodbox or not DoesEntityExist(self.foodbox) and not player then
				local coord = GetEntityCoords(self.playerPed)
				self.foodbox = CreateObject(`prop_food_bag1`,coord.x,coord.y,coord.z,true,true)
				while not DoesEntityExist(self.foodbox) do Wait(0) end
				self.SetEntityControlable(self.foodbox)
				AttachEntityToEntity(self.foodbox, self.currentcustomer, GetPedBoneIndex(self.currentcustomer, 57005), 0.3800, 0.0, -0.0300, 0.0017365, -79.9999997, 110.0651988, true, true,
				false, true, 1, true)
			end
			self.SetNotify({
				title = 'Store Business',
				description = 'You Serve '..var.label..' to '..var.customer,
				type = 'inform'
			})
			self.purchaseorder[i] = nil
			self.ongoingpack = false
		else
			self.SetNotify({
				title = 'Store Business',
				description = 'You dont have enough stock for '..var.label,
				type = 'inform'
			})
			self.ongoingpack = false
		end
	elseif var.ingredients then
		local identifier = self.movabletype..':'..self.PlayerData.identifier
		local cb = self.StartCook(var.data,var.name,var.menu,true,identifier)
		if cb == 'success' then
			self.purchaseorder[i] = nil
			self.SetNotify({
				title = 'Store Business',
				description = 'You Serve '..var.label..' to '..var.customer,
				type = 'inform'
			})
			self.ongoingpack = false
		else
			self.SetNotify({
				title = 'Store Business',
				description = 'You dont have enough stock for '..var.label,
				type = 'inform'
			})
			self.ongoingpack = false
		end
	else
		self.SetNotify({
			title = 'Store Business',
			description = 'You dont have enough stock for '..var.label,
			type = 'error'
		})
		self.ongoingpack = false
	end
end

self.ongoingpack = false
self.PurchaseOrderList = function(data,storedata,player)
	local options = {}
	if not player then
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
	else
		local playercarts = GlobalState.ShopCarts
		local cart = {}
		local shopname = self.GetShopData(storedata.type,storedata.index).label
		local shopdata = playercarts[shopname]
		for k,v in pairs(shopdata?.cart or {}) do
			local data = v.data
			local img = data.metadata?.image or data.name
			local name = data.metadata and data.metadata.name or data.name or data.name
			local label = data.metadata and data.metadata.label or data.label or self.Items[data.name] or data.name
			data.label = label
			local category = data.category or k
			table.insert(cart,{serialid = v.serialid, data = data, img = img, name = name, count = v.count, label = label, customer = shopdata.playerid, shop = shopname, type = type})
		end

		for k,v in pairs(cart) do
			local amount = v.count or 1
			local name = IsPedAPlayer(GetPlayerPed(GetPlayerFromServerId(tonumber(v.customer) or 0))) and GetPlayerName(GetPlayerFromServerId(tonumber(v.customer) or 0)) or v.customer
			table.insert(options,{
				title = v.label..' : Customer - '..name,
				description = name..' Wants a '..amount..'x of '..v.label,
				arrow = true,
				onSelect = function(args)
					self.ServePurchaseOrder(v,k,storedata,true)
				end
			})
		end
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
			self.DeleteEntity(v) 
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
					self.SetEntityControlable(self.peds[i])
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
							self.DeleteEntity(cacheped)
						end
						if DoesEntityExist(self.foodbox) then
							self.DeleteEntity(self.foodbox)
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
		message = message..'<img src="'..self.ImagesPath(v.img)..'" style="height:40px; width:40px;"> i want 1x of '..v.label..' <br>'
	end
	--LocalPlayer.state:set('createpurchaseorder', self.purchaseorder, true)
	self.SetClientStateBags({
		entity = GetPlayerServerId(PlayerId()), 
		name = 'createpurchaseorder', 
		data = {bagname = 'player:', purchase = self.purchaseorder}
	})
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

self.StartCook = function(data,item,title,dontreceive,identifier,storeitems)
	local cancook = data.ingredients and true
	local items = {}
	for k,v in pairs(data.ingredients or {}) do
		table.insert(items,{name = k, count = v})
	end
	local ingredients = lib.callback.await('renzu_shops:getStashData', false, {items = items, type = self.movabletype, identifier = identifier})
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
			self.SetEntityControlable(self.movableentity[self.movabletype])
			AttachEntityToEntity(self.playerPed, self.movableentity[self.movabletype], 19, 1.1, -3.2, 0.6, 0.0, 0.0, -90.0, false, false, false, false, 20, true)
			Wait(0)
			SetEntityCoordsNoOffset(self.playerPed,GetEntityCoords(self.playerPed))
		end
		if not success then return end
		local item = lib.callback.await('renzu_shops:craftitem', false, {identifier = identifier, items = storeitems, metadata = data.metadata, item = item, type = self.movabletype, menu = title, shop = 'movableshop', dontreceive = dontreceive, stash = true})
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

self.Stash = function(data)
	local identifier = data.label..'_storage'
	if shared.inventory == 'ox_inventory' then
		TriggerEvent('ox_inventory:openInventory', 'stash', {id = identifier, name = 'Storage', slots = 80, weight = 200000, coords = GetEntityCoords(cache.ped)})
	elseif shared.inventory == 'qb-inventory' then
		TriggerServerEvent('inventory:server:OpenInventory', 'stash', identifier, {})
		TriggerServerEvent("InteractSound_SV:PlayOnSource", "StashOpen", 0.4)
		TriggerEvent("inventory:client:SetCurrentStash", identifier)
	end
end

self.Crafting = function(data)
	self.CookMenuList(data.supplieritem, data.label..' Cook',data,true)
end

self.CookMenuList = function(items,title,data,store)
	local options = {}
	local identifier = not store and self.movabletype..':'..self.PlayerData.identifier or data.label..'_storage'
	local itemdata = lib.callback.await('renzu_shops:getStashData', false, {items = items, identifier = identifier})
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
		if v.ingredients then
			v.label = label
			table.insert(options,{
				title = label,
				description = 'Available : '..amount,
				arrow = true,
				metadata = ingredients,
				onSelect = function(args)
					self.StartCook(v,item,title,false,identifier,items)
				end
			})
		end
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
	self.Active.shop.StoreName = 'movable'
	local shopdata = shared.MovableShops[data.type].menu
	local items = {}
	for category,v in pairs(shopdata) do
		for k,v in pairs(v) do
			table.insert(items, {name = v.name, price = v.price, metadata = v.metadata})
		end
	end
	local inventory = {}
	local itemdata = lib.callback.await('renzu_shops:getStashData', false, {items = items, type = data.type, identifier = data.identifier})
	for category,v in pairs(shopdata) do
		for k,v in pairs(v) do
			local name = v.metadata and v.metadata.name or v.name
			table.insert(inventory, {stock = itemdata[name],name = v.name, category = category, price = v.price, metadata = v.metadata, disable = false, label = self.Items[name] or v.metadata and v.metadata.label or v.name})
		end
	end
	data.shop.inventory = inventory
	self.Active.shop.inventory = inventory
	local money = self.GetAccounts(self.moneytype or 'money')
	local black_money = self.GetAccounts('black_money')
	local bank = self.GetAccounts('bank')
	SendNUIMessage({
		type = 'shop',
		data = {imgpath = self.ImagesPath(), moneytype = self.moneytype, type = data.type, open = true, shop = data.shop, label = data.shop.label or data.shop.name, wallet = {money = self.format_int(money), black_money = self.format_int(black_money), bank = self.format_int(bank)}}
	})
	SetNuiFocus(true,true)
	SetNuiFocusKeepInput(false)
	self.shopopen = not self.shopopen
end

self.OpenShopBooth = function(data)
	if GlobalState.BoothShops[data.identifier] ~= nil and GlobalState.BoothShops[data.identifier] then return end
	if not self.Active then self.Closeui() return end
	self.Active.shop = {}
	self.shopidentifier = data.identifier
	data.shop = {}
	data.shop.label = data.type
	self.Active.index = data.type
	self.moneytype = 'money'
	self.Active.shop.StoreName = 'Booth'
	local booths = GlobalState.Booths
	local inventory = {}
	local boothdata = GlobalState.BoothItems[data.identifier]
	local stash = lib.callback.await('renzu_shops:GetInventoryData', false, data.identifier)
	for category,v in pairs(stash) do
		local name = v.metadata and v.metadata.name or v.name
		local label = self.Items[name]
		if booths[data.identifier].whitelists and booths[data.identifier]?.whitelists[name:lower()]
		or booths[data.identifier]?.blacklists and not booths[data.identifier]?.whitelists and not booths[data.identifier]?.blacklists[name:lower()]
		or not booths[data.identifier]?.whitelists and not booths[data.identifier]?.blacklists then
			if string.find(name:lower(),'weapon') then
				label = self.Items[name:upper()]
				name = name:upper()
			end
			table.insert(inventory, {stock = v.count,name = v.name, category = boothdata and boothdata[name] and boothdata[name].category or 'Default', price = boothdata and boothdata[name] and boothdata[name].price or 99999999, metadata = v.metadata, disable = false, label = label or v.metadata and v.metadata.label or v.name})
		end
	end
	data.shop.inventory = inventory
	self.Active.shop.inventory = inventory
	local money = self.GetAccounts(self.moneytype or 'money')
	local black_money = self.GetAccounts('black_money')
	local bank = self.GetAccounts('bank')
	self.Owner = GlobalState.Booths[data.identifier].owner
	SendNUIMessage({
		type = 'shop',
		data = {imgpath = self.ImagesPath(), moneytype = self.moneytype, type = data.type, open = not self.shopopen, shop = data.shop, label = data.shop.label or data.shop.name or data.identifier, wallet = {money = self.format_int(money), black_money = self.format_int(black_money), bank = self.format_int(bank)}}
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
	for type,v in pairs(shared.OwnedShops) do
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
	if created then
		self.SetNotify({
			title = 'Store Business',
			description = 'New Shop has been Added',
			type = 'success'
		})
	else
		self.SetNotify({
			title = 'Store Business',
			description = 'something is missing from config',
			type = 'error'
		})
	end
end

self.TransferOwnerShip = function(store)
	local options = {}
	local players = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 50.0, true)
	for k,v in pairs(players) do
		table.insert(options,{
			title = GetPlayerName(v.id),
			description = 'Citizen ID #'..GetPlayerServerId(v.id),
			arrow = true,
			onSelect = function(args)
				local confirm = lib.alertDialog({
					header = 'Confirm',
					content = 'Do you really want to Transfer this Shop to '..GetPlayerName(v.id)..'?',
					centered = true,
					cancel = true
				})
				if confirm ~= 'cancel' then
					local reason = lib.callback.await('renzu_shops:transfershop', false, {store = store, id = GetPlayerServerId(v.id)})
					if reason == true then
						self.SetNotify({
							title = 'Store Business',
							description = 'Shop Ownership has been Transfered to '..GetPlayerName(v.id),
							type = 'success'
						})
					end
				end
			end
		})
	end
	lib.registerContext({
		id = 'transfershop',
		title = 'Transfer Shop',
		menu = 'storeowner',
		onExit = function()
		end,
		options = options
	})
	lib.showContext('transfershop')
end

self.PaymentMethod = function(data)
	local options = {}
	local index = 3
	table.insert(options,{ type = "input", label = "Total in Cart", placeholder = data.total , disabled = true})
	table.insert(options,{ type = "input", label = "Amount to Pay", placeholder = data.amount , disabled = true})
	local dropdownmenu = {
		{ value = 'money', label = 'Cash' }
	}
	if data.money == 'money' or data.money == nil then
		table.insert(dropdownmenu,{ value = 'bank', label = 'Bank' })
	else
		dropdownmenu[1] = { value = data.money, label = self.Items[data.money] or data.money }
	end
	if data.amount >= shared.FinanceMinimum and data.type ~= 'BlackMarketArms' and self.StoreData(data.name) then
		table.insert(dropdownmenu, { value = 'finance', label = 'Finance' })
	end
	table.insert(options,{ type = 'select', label = 'Payment Type', options = dropdownmenu })
	local input = lib.inputDialog('Select Payment', options)
	return type(input) == 'table' and input[index] or 'cancel'
end

self.Finance = function(data) -- simple financing only. since ox_lib input does not return real time  (like the ox_lib menus) changed amount ex. from slider value. so we cant make advanced finance. unless i implement another NEW UI just for this.
	local options = {}
	local retval = 'cancel'
	local downpayment = data.amount * shared.FinanceDownPayment/100
	local interest = shared.FinanceInterest/100
	table.insert(options,{ type = "slider", label = "Down Payment", min = downpayment, max =  downpayment * 2, step = 1})
	--table.insert(options,{ type = "input", label = "Amount Financed (Interest Rate: "..shared.FinanceInterest.."%)", placeholder = amountfinanced  , disabled = true})
	table.insert(options,{ type = "slider", label = "Finance Duration (days)", min = 5, max =  shared.FinanceMaxDays, step = 1})
	local input = lib.inputDialog('Finance Page 1', options)
	local initialpayment, days = table.unpack(input)
	local finaldailyamount
	if input ~= 'cancel' then
		local options = {}
		local total = data.amount - initialpayment
		local amountfinanced = data.amount * (1.0 - (initialpayment / data.amount))
		local dailyamount = amountfinanced / days
		local daytomax = days / shared.FinanceMaxDays
		local interestrate = shared.FinanceInterest/100 - (shared.FinanceInterest - (shared.FinanceInterest * daytomax)) / 100
		finaldailyamount = dailyamount * ( 1.0 + interestrate )
		local interestpercent = interestrate * 100
		table.insert(options,{ type = "input", label = "Initial Payment", placeholder = initialpayment  , disabled = true})
		table.insert(options,{ type = "input", label = "Amount Financed (Interest Rate: "..interestpercent.."%)", placeholder = amountfinanced  , disabled = true})
		table.insert(options,{ type = "input", label = "Daily Amount", placeholder = finaldailyamount  , disabled = true})
		local input = lib.inputDialog('Finance Confirmation', options)
		retval = true
		if not input or input == 'cancel' then
			retval = 'cancel'
		end
	end
	return retval, {daily = finaldailyamount, downpayment = initialpayment, days = days}
end

self.RemoveShop = function(data)

end

self.SetEntityControlable = function(entity) -- server based entities. incase you are not the owner. server entities are a little complicated
    local netid = NetworkGetNetworkIdFromEntity(entity)
    SetNetworkIdExistsOnAllMachines(netid,true)
    SetEntityAsMissionEntity(entity,true,true)
    NetworkRequestControlOfEntity(entity)
    local attempt = 0
    while not NetworkHasControlOfEntity(entity) and attempt < 2000 and DoesEntityExist(entity) do
        NetworkRequestControlOfEntity(entity)
        Citizen.Wait(0)
        attempt = attempt + 1
    end
end

self.DeleteEntity = function(entity)
	self.SetEntityControlable(entity)
	return DeleteEntity(entity)
end

self.ItemShowCase = function(data,owner)
	local showcases = GlobalState.ItemShowCase[data.label] or {}
	self.ShowCase(data,owner)
end

self.SpotShowcase = function(data)
	local options = {}
	local storedata = self.StoreData(data.label)
	data.owner = storedata?.owner == self.PlayerData.identifier
	if data.owner then
		table.insert(options,{
			title = 'Manage Listing',
			description = 'Add / Remove item from showcase',
			arrow = true,
			onSelect = function(args)
				self.VehicleShowcase(data)
			end
		})
		table.insert(options,{
			title = 'View Showcase',
			description = 'See list of available displays',
			arrow = true,
			onSelect = function(args)
				self.ItemShowCase(data,false)
			end
		})
		lib.registerContext({
			id = 'displayoption',
			title = 'Display Option',
			onExit = function()

			end,
			options = options
		})
		lib.showContext('displayoption')
	else
		self.ItemShowCase(data,false)
	end
end

self.VehicleShowcase = function(data)
	local options = {}
	local showcase = GlobalState.VehicleShowcase or {}
	table.insert(options,{
		title = 'Add Vehicle Show Case',
		description = 'Add new vehicle to this show space',
		arrow = true,
		onSelect = function(args)
			self.ShowCase(data,true)
		end
	})
	table.insert(options,{
		title = 'Edit Current Listing',
		description = 'Modify current list',
		arrow = true,
		onSelect = function(args)
			self.ShowCase(data,false,true)
		end
	})
	lib.registerContext({
		id = 'vehicleshow',
		title = 'Vehicle List Manage',
		onExit = function()

		end,
		options = options
	})
	lib.showContext('vehicleshow')
end

RegisterCommand('showcase', function()
    moveSpeed = 0.001
    spawnedFurn = nil
    lib.showMenu('itemlistshowcase')
end)

self.getShop = function(data)
	local ownedshops = shared.OwnedShops
	local storename = nil
	for type,v in pairs(ownedshops) do
		for k,v2 in pairs(v) do
			if k == data.index and type == data.type then
				local storedata = self.StoreData(v2.label)
				return v2.supplieritem
			end
		end
	end
end

self.VehicleShowcases = {}
self.lastmodel = nil
self.ShowItem = function(data,scrollIndex,args)
	if DoesEntityExist(self.VehicleShowcases[data.index]) then
		DeleteEntity(self.VehicleShowcases[data.index])
	end
	if args[scrollIndex] and args[scrollIndex].name ~= self.lastmodel then
		self.lastmodel = args[scrollIndex].name
		local model = joaat(args[scrollIndex].name)
		lib.requestModel(model)
		SetModelAsNoLongerNeeded(model)
		self.VehicleShowcases[data.index] = CreateVehicle(model, data.showcase.position.x,data.showcase.position.y,data.showcase.position.z, data.showcase.position.w, false, true) -- Spawns a networked self.Vehicle on your current coords
		while not DoesEntityExist(self.VehicleShowcases[data.index]) do Wait(1) end
		SetEntityCompletelyDisableCollision(self.VehicleShowcases[data.index],false)
		FreezeEntityPosition(self.VehicleShowcases[data.index],true)
		Wait(10)
		SetEntityCollision(self.VehicleShowcases[data.index],true)
		SetVehicleDoorsLocked(self.VehicleShowcases[data.index],2)
		SetEntityInvincible(self.VehicleShowcases[data.index],true)
		local vehstats = self.GetVehicleStats(self.VehicleShowcases[data.index])
		local stats = {
			topspeed = vehstats.topspeed / 300 * 100,
			acceleration = vehstats.acceleration * 150,
			brakes = vehstats.brakes * 80,
			traction = vehstats.handling * 10,
			label = args[scrollIndex].label
		}
		SendNUIMessage({ stats = stats})
	end
end

self.getItemsFromSpot = function(data)
	local showcases = GlobalState.ItemShowCase
	local shop = showcases[data.label] or {}
	return shop[data.index] or {}
end

self.DoesItemExistinSpot = function(data, item)
	local showcases = self.getItemsFromSpot(data)
	for k,v in pairs(showcases) do
		if v.name == item then
			return true
		end
	end
	return false
end

self.SpotZone = function(data)
	local Shops = self
	local data = data
	local point = lib.points.new(vec3(data.showcase.position.x,data.showcase.position.y,data.showcase.position.z), 50, {data = data})
	function point:onEnter()
		Shops.SpawnedSpotProducts(data)
		point:remove()
	end
end

self.SpawnedSpotProducts = function(data)
	local showcases = self.getItemsFromSpot(data)
	local displays = {}

	local displayProduct = function(name,data)
		if DoesEntityExist(self.VehicleShowcases[data.index]) then
			DeleteEntity(self.VehicleShowcases[data.index])
		end
		self.lastmodel = name
		local model = joaat(name)
		lib.requestModel(model)
		SetModelAsNoLongerNeeded(model)
		self.VehicleShowcases[data.index] = CreateVehicle(model, data.showcase.position.x,data.showcase.position.y,data.showcase.position.z, data.showcase.position.w, false, true) -- Spawns a networked self.Vehicle on your current coords
		while not DoesEntityExist(self.VehicleShowcases[data.index]) do Wait(1) end
		SetEntityCompletelyDisableCollision(self.VehicleShowcases[data.index],false)
		SetEntityNoCollisionEntity(PlayerPedId(),self.VehicleShowcases[data.index],true)
		Wait(1)
		SetEntityCollision(self.VehicleShowcases[data.index],true)
		SetVehicleOnGroundProperly(self.VehicleShowcases[data.index])
		SetVehicleDoorsLocked(self.VehicleShowcases[data.index],2)
		SetEntityInvincible(self.VehicleShowcases[data.index],true)
	end
	for k,v in pairs(showcases or {}) do
		if not displays[data.index] and v.priority then
			displays[data.index] = true
			displayProduct(v.name,data)
			break
		end
	end
	for k,v in pairs(showcases or {}) do
		if not displays[data.index] then
			displays[data.index] = true
			displayProduct(v.name,data)
		end
	end
end

self.MenuCallback = function(selected, scrollIndex, args, data, owner, edit)
	lib.progressCircle({
		duration = 2000,
		position = 'bottom',
		useWhileDead = false,
		canCancel = true,
		disable = {
			car = true,
		},
	})
	if owner then
		local purchase = false
		if not self.DoesItemExistinSpot(data, args[scrollIndex].name) then
			purchase = lib.callback.await('renzu_shops:editshowcase', false, 'add', false, {
				item = args[scrollIndex],
				index = data.index,
				shop = data.shop,
			})
		end
		if purchase then
			lib.notify({
				title = 'Successfully Added',
				type = 'success'
			})
		else
			lib.notify({
				title = 'Listing Failed or already exist',
				type = 'error'
			})
		end
	elseif not edit then
		self.Active.index = data.shop.index
		self.Active.shop = {}
		self.Active.shop.type = data.shop.type
		self.Active.type = data.shop.type
		self.Active.shop.StoreName = data.label
		self.Active.shop.inventory = {{name = args[scrollIndex].name, price = args[scrollIndex].price}}
		lib.hideMenu(true)
		Wait(100)
		SendNUIMessage({
			displaybuy = {
				name = args[scrollIndex].name,
				price = args[scrollIndex].price,
				label = args[scrollIndex].label,
			}
		})
		SetNuiFocusKeepInput(false)
	elseif edit then
		lib.hideMenu(true)
		Wait(111)
		local spotdata = self.getItemsFromSpot(data)
		local bool = false
		for k,v in pairs(spotdata or {}) do
			if v.name == args[scrollIndex].name then
				if v.priority then
					bool = true
					break
				end
			end
		end
		lib.registerMenu({
			id = 'editshowcase',
			title = 'Edit Product',
			position = 'top-right',
			onCheck = function(selected, checked, _)
				lib.callback.await('renzu_shops:editshowcase', false, 'modify', 'priority', {
					shop = data.shop,
					name = args[scrollIndex].name,
					value = checked,
				})
			end,
			onClose = function(keyPressed)
				self.lastmodel = nil
				SendNUIMessage({ stats = false})
			end,
			options = {
				{label = 'Priority', checked = bool, close = false, description = 'Show first in display'},
				{label = 'Edit Price', close = false, description = 'Modify the default value'},
				{label = 'Remove', close = false, description = 'Remove this product on display lists'},
			}
		}, function(selected, _, _)
			if selected == 2 then
				lib.hideMenu(true)
				Wait(111)
				local input = lib.inputDialog('Edit Price', {
					{ type = "number", label = "New Price", default = 1 }
				})
				if not input then return end
				local price = tonumber(input[1])
				lib.callback.await('renzu_shops:editshowcase', false, 'modify', 'price', {
					shop = data.shop,
					name = args[scrollIndex].name,
					value = price,
				})
				lib.notify({
					title = 'Price has been updated',
					type = 'inform'
				})
			elseif selected == 3 then
				lib.callback.await('renzu_shops:editshowcase', false, 'modify', 'remove', {
					shop = data.shop,
					name = args[scrollIndex].name,
				})
				lib.notify({
					title = 'Product has been removed',
					type = 'inform'
				})
			end
		end)
		lib.showMenu('editshowcase')
	end
end

self.ShowCase = function(data,owner,edit)
	lib.progressCircle({
		duration = 2000,
		position = 'bottom',
		useWhileDead = false,
		canCancel = true,
		disable = {
			car = true,
		},
	})
	local lists = {}
	local vehicles = {}
	local args = {}
	local availableitems = not edit and owner and self.getShop(data.shop) or self.getItemsFromSpot(data) or {}
	local havedata = false
	for k,v in pairs(availableitems or {}) do
		if not vehicles[v.category] then vehicles[v.category] = {} end
		if not args[v.category] then args[v.category] = {} end
		table.insert(vehicles[v.category],{label = v.label, description = 'Price: '..v.price, close = false})
		table.insert(args[v.category],v)
	end
	for cat,v in pairs(vehicles) do
		table.insert(lists,{label = cat, values = vehicles[cat], args = args[cat], close = false})
		havedata = true
	end
	if not havedata then 
		lib.notify({
			title = 'Listing is empty',
			type = 'inform'
		})
		return 
	end

	lastob = nil
	local moveSpeed = 0.001

	lib.registerMenu({
		id = 'itemlistshowcase',
		title = owner and 'Show Case Manage' or ' Displays Lists',
		position = 'top-right',
		onSideScroll = function(selected, scrollIndex, args)
			self.ShowItem(data,scrollIndex,args)
		end,
		onSelected = function(selected, secondary, args)
			if not secondary then
			else
				if args.isScroll and self.lastmodel ~= args[secondary].name then
					self.ShowItem(data,secondary,args)
				end
			end
		end,

		onClose = function(keyPressed)
			self.lastmodel = nil
			SendNUIMessage({ stats = false})
		end,
		options = lists
	}, function(selected, scrollIndex, args)
		return self.MenuCallback(selected, scrollIndex, args ,data, owner, edit)
	end)
	lib.showMenu('itemlistshowcase')
	SetNuiFocusKeepInput(false)
end

self.GetVehicleStats = function(vehicle)
    local data = {}
    data.acceleration = GetVehicleModelAcceleration(GetEntityModel(vehicle))
    data.brakes = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce')
    local fInitialDriveMaxFlatVel = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel')
    data.topspeed = math.ceil(fInitialDriveMaxFlatVel * 1.3)
    local fTractionBiasFront = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionBiasFront')
    local fTractionCurveMax = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax')
    local fTractionCurveMin = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMin')
    data.handling = (fTractionBiasFront + fTractionCurveMax * fTractionCurveMin)
    return data
end

self.Work = function(data)
	if GetResourceState('ox_target') then
		exports.ox_target:disableTargeting(true)

		ExecuteCommand('-ox_target')
	end
	Citizen.CreateThread(function()
		Wait(500)
		local success = lib.skillCheck({'easy', 'easy', 'easy', 'easy'})
		if success then
			lib.progressBar({
				duration = 2000,
				label = data.label,
				useWhileDead = false,
				canCancel = false,
				disable = {
					car = true,
				},
				anim = {
					dict = data.animation.dict,
					clip = data.animation.clip
				}
			})
			lib.callback.await('renzu_shops:work',100, data)
		end
		exports.ox_target:disableTargeting(false)
	end)
end

self.Proccessed = function(data)
	lib.progressBar({
		duration = 2000,
		label = data.label,
		useWhileDead = false,
		canCancel = false,
		disable = {
			car = true,
		}
	})
	lib.callback.await('renzu_shops:proccessed',100, data)
end