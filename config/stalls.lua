PlayerBooth = {

	-- items sample from /config/storeitems.lua
	-- { lvl = 1, name = 'playerbooth', price = 50000 , category = 'misc', 
	-- 		metadata = { -- ox_inventory supported only
	-- 			label = 'Market Booth', -- custom label name to set from metadatas
	-- 			model = `ch_prop_ch_gazebo_01`,
	-- 			description = 'can be used for market booth',
	-- 			type = 'legal',
	-- 			blacklists = { -- blacklist the list of items here from appearing to shop
	-- 				['weapon_pistol'] = true,
	-- 			},
	-- 		}
	-- 	},
	-- 	{ lvl = 1, name = 'playerbooth', price = 50000 , category = 'misc', 
	-- 		metadata = { -- ox_inventory supported only
	-- 			label = 'Black Market Booth', -- custom label name to set from metadatas
	-- 			model = `ch_prop_ch_gazebo_01`,
	-- 			description = 'can be used for black market booth',
	-- 			type = 'illegal',
	-- 			whitelist = { -- if whitelist. only this items will appear on the shops
	-- 				['weapon_pistol'] = true,
	-- 			}
	-- 		}
	-- 	},
	blacklistarea = {
		[1] = vec3(280.03,-584.29,43.29), -- pillbox hospital
		[2] = vec3(416.77,-975.46,29.43), -- mrpd
	},
	objects = { -- you can add more objects here
		-- types (fn) : 
		-- stash (private stash for owner) : 
		-- storage (the items from shop) : 
		-- cashier (where the shop marker will appear)
		-- others is just a display or for more future updates
		['v_corp_deskdrawdark01'] = { label = 'Desk Drawer', fn = 'stash'},
		['v_club_vu_drawer'] = { label = 'Item Storage 1', fn = 'storage'},
		['v_res_tre_storagebox'] = { label = 'Item Storage 2', fn = 'storage'},
		['prop_mb_crate_01a'] = { label = 'Item Storage 3', fn = 'storage'},

		['v_ret_gc_cashreg'] = { label = 'Cash Register', fn = 'cashier'},
		['prop_table_01'] = { label = 'Table'},
		['v_club_roc_ctable'] = { label = 'Table 2'},
		['v_corp_cd_rectable'] = { label = 'Table 3'},
		['v_res_d_coffeetable'] = { label = 'Table 4'},
		['v_ind_dc_table'] = { label = 'Table 5'},
		['v_ind_rc_lowtable'] = { label = 'Table 5'},

		['sf_int1_snack_display'] = { label = 'Snack Display'},
		['prop_display_unit_02'] = { label = 'Clothe Display'},
		['prop_display_unit_01'] = { label = 'Hats Display'},
		['v_club_shoerack'] = { label = 'Shoes Display'},

		['v_res_fh_coftablea'] = { label = 'Coffee Table 1'},

		['v_res_fh_coftableb'] = { label = 'Coffee Table 2'},
		['v_res_j_lowtable'] = { label = 'Coffee Table 3'},
		['v_res_j_coffeetable'] = { label = 'Coffee Table 4'},
		['v_res_fh_tableplace'] = { label = 'Table place'},

		['prop_chair_01a'] = { label = 'Chair 1'},

		['prop_chair_01b'] = { label = 'Chair 2'},

		['prop_chair_02'] = { label = 'Chair 3'},
		['prop_chair_03'] = { label = 'Chair 4'},
		['prop_chair_04a'] = { label = 'Chair 5'},

		['prop_food_bs_soda_02'] = { label = 'Soda', fn = 'items'},
		['prop_cooker_03'] = { label = 'Cooker', fn = 'cook'},
		['v_ret_fh_kitchtable'] = { label = 'Table Cooker', fn = 'cook'},

		['prop_griddle_02'] = { label = 'Griddle 1', fn = 'cook'},
		['prop_griddle_01'] = { label = 'Griddle 2', fn = 'cook'},
		['prop_coolbox_01'] = { label = 'Cooler', fn = 'cook'},
		['v_ret_247shelves02'] = { label = 'Drinks Shelves', fn = 'items'},
		['prop_food_bs_soda_01'] = { label = 'Drinks Shelves 2', fn = 'items'},

		['v_ret_247shelves01'] = { label = 'Item Shelves 1', fn = 'items'},
		['v_ret_247shelves03'] = { label = 'Item Shelves 2', fn = 'items'},
		['imp_prop_impexp_hub_rack_01a'] = { label = 'Item Rack 1', fn = 'items'},
		['ex_prop_crate_ammo_sc'] = { label = 'Weapon Crate', fn = 'items'},
		['ba_trad_pay_counter'] = { label = 'Counter 1', fn = 'items'},
		['ba_glam_pay_counter'] = { label = 'Counter 2', fn = 'counter'},
		['ba_edgy_counter'] = { label = 'Counter 3', fn = 'counter'},
		['prop_ff_counter_02'] = { label = 'Counter 4', fn = 'counter'},
		['prop_ff_counter_01'] = { label = 'Counter 5', fn = 'counter'},
		['ch_chint02_counter'] = { label = 'Counter 6', fn = 'counter'},
		['vw_vwint01_shop_counter'] = { label = 'Counter 7', fn = 'counter'},
		['prop_venice_counter_02'] = { label = 'Hookah', fn = 'counter'},
		['prop_venice_counter_01'] = { label = 'Empty Counter', fn = 'counter'},
		['prop_venice_counter_04'] = { label = 'Empty Counter 2', fn = 'counter'},
		['prop_food_bin_02'] = { label = 'Bin', fn = 'counter'},
		['prop_food_bs_bshelf'] = { label = 'Food Shelf', fn = 'counter'},
		['prop_food_cb_bshelf'] = { label = 'Food Shelf 2', fn = 'counter'},
		['v_ret_247_donuts'] = { label = 'Food Shelf 3', fn = 'counter'},



		['prop_bar_beerfridge_01'] = { label = 'Liquor Fridge 1', fn = 'counter'},


	}
}
if IsDuplicityVersion() then
	if not lib then return end
	local cacheslot = {}
	local gazebo = {}
	local applications = {}
	GlobalState.Booths = json.decode(GetResourceKvpString('Booths') or '[]') or {}

	lib.callback.register('renzu_shops:createbooth', function(source,data)
		return CreateBooth(source,data)
	end)

	CreateBooth = function(source, data)
		local booth = CreateObject(data.metadata?.model, data.coords, true, true, false)
		while not DoesEntityExist(booth) do Wait(0) end
		local state = Entity(booth).state
		local xPlayer = GetPlayerFromId(source)
		local boothid = 'market:'..math.random(999,99999)
		if data.metadata?.boothid then
			boothid = data.metadata.boothid
		end
		gazebo[boothid] = booth
		local booths = GlobalState.Booths
		if not booths[boothid] then
			booths[boothid] = {
				owner = xPlayer.identifier,
				placedapplications = {},
				storedapplications = {},
				money = {money = 0, black_money = 0},
				employee = {},
				items = {},
				label = data.metadata.label or 'Market Booth',
				name = data.metadata.name or 'playerbooth',
				type = data.metadata.type,
				whitelists = data.metadata.whitelists,
				blacklists = data.metadata.blacklists
			}
			SetResourceKvp('Booths', json.encode(booths))
			GlobalState.Booths = booths
		else
			Citizen.CreateThreadNow(function()
				Wait(1500)
				for k,v in pairs(booths[boothid].placedapplications) do
					local app, id = CreateApp({heading = v.coord.w, id = boothid, appid = v.appid, coord = vec3(v.coord.x,v.coord.y,v.coord.z), model = v.model, data = v.data, type = v.type, ts = v.ts}, v.type)
					applications[id] = {appid = id, entity = app}
					Wait(111)
				end
			end)
		end
		SetEntityHeading(booth,data.heading)
		state:set('playerbooth',{
			owner = xPlayer.identifier,
			metadata = cacheslot[slot],
			boothid = boothid,
			ts = os.time()
		},true)
	end

	CreateApp = function(data,fn, new)
		local booths = GlobalState.Booths
		local offset = GetEntityCoords(gazebo[data.id]) + vec3(data.coord.x,data.coord.y,data.coord.z)
		local application = CreateObjectNoOffset(joaat(data.model), offset.x,offset.y,offset.z, true, true, false)
		while not DoesEntityExist(application) do Wait(1) end
		while NetworkGetEntityOwner(application) == -1 do Wait(1) end
		local appid = 'APP:'..math.random(1100,999999)
		if data.appid then
			appid = data.appid
		end
		local state = Entity(application).state
		if not applications[data.id] then applications[data.id] = {} end
		table.insert(applications[data.id],{appid = appid, entity = application})
		if not booths[data.id].placedapplications[appid] or booths[data.id].placedapplications[appid] and tonumber(booths[data.id].placedapplications[appid].ts) ~= tonumber(data.ts) then
			booths[data.id].placedapplications[appid] = {appid = appid, coord = vec4(data.coord.x,data.coord.y,data.coord.z,data.heading), model = data.model, data = {}, type = fn, ts = os.time()}
			SetResourceKvp('Booths', json.encode(booths))
			GlobalState.Booths = booths
		end
		if fn == 'stash' or fn == 'storage' then
			if shared.inventory == 'ox_inventory' then
				exports.ox_inventory:RegisterStash(tostring(appid), 'Private Stash', 40, 40000, false)
			elseif shared.inventory == 'qb-inventory' then
				exports['qb-inventory']:RegisterStash(tostring(appid))
			end
		end
		FreezeEntityPosition(application,true)
		SetEntityHeading(application,data.heading)
		state:set('boothapplication',{gazebonet = NetworkGetNetworkIdFromEntity(gazebo[data.id]), new = data.new, id = data.id, owner = booths[data.id].owner, appid = appid, coord = vec3(data.coord.x,data.coord.y,data.coord.z), model = data.model, data = {}, type = fn},true)
		return application, appid
	end

	lib.callback.register('renzu_shops:placeapplication', function(source,data)
		for k,v in pairs(PlayerBooth.objects) do
			if k == data.model then
				local application = CreateApp(data, v.fn)
				return NetworkGetNetworkIdFromEntity(application)
			end
		end
	end)
	
	lib.callback.register('renzu_shops:removeapp', function(source,data)
		local booths = GlobalState.Booths
		if booths[data.id] then
			for k,v in pairs(booths[data.id].placedapplications) do
				if k == data.appid then
					booths[data.id].placedapplications[k] = nil
					DeleteEntity(NetworkGetEntityFromNetworkId(data.net))
				end
			end
			GlobalState.Booths = booths
			SetResourceKvp('Booths', json.encode(booths))
		end
	end)

	GlobalState.UninstallBooth = {}
	lib.callback.register('renzu_shops:uninstallbooth', function(source,id)
		if DoesEntityExist(gazebo[id]) then
			DeleteEntity(gazebo[id])
		end
		for k,v in pairs(applications[id] or {}) do
			if DoesEntityExist(v.entity) then
				DeleteEntity(v.entity)
			end
		end
		applications[id] = {}
		local booths = GlobalState.Booths
		Inventory.AddItem(source, 'playerbooth', 1, {
			label = booths[id].label..' #'..id,
			model = `ch_prop_ch_gazebo_01`,
			description = 'can be used for '..booths[id].name,
			serial = id,
			boothid = id,
			name = booths[id].name,
			type = booths[id].type,
			blacklists = booths[id].blacklists,
			whitelists = booths[id].whitelists,
		})
		GlobalState.UninstallBooth = {id = id, ts = os.time()}
	end)

	GlobalState.BoothShops = {}

	lib.callback.register('renzu_shops:boothshop', function(source,id)
		local booths = GlobalState.BoothShops
		booths[id] = not booths[id]
		GlobalState.BoothShops = booths
	end)

	GlobalState.BoothItems = json.decode(GetResourceKvpString('BoothItems') or '[]') or {}
	
	lib.callback.register('renzu_shops:boothitems', function(source,data)
		local boothitems = GlobalState.BoothItems
		if not boothitems[data.id] then boothitems[data.id] = {} end
		if not boothitems[data.id][data.item] then boothitems[data.id][data.item] = {} end
		boothitems[data.id][data.item] = data
		GlobalState.BoothItems = boothitems
		SetResourceKvp('BoothItems', json.encode(boothitems))
	end)
	if shared.framework == 'QBCORE' and shared.inventory == 'qb-inventory' then
		exports['qb-inventory']:CreateUsableItem('playerbooth',function(source,item)
			item.metadata = item.info
			item.count = item.amount
			local canuse = true
			for k,v in pairs(PlayerBooth.blacklistarea) do
				if #(GetEntityCoords(GetPlayerPed(source)) - v) < 50 then
					canuse = false
				end
			end
			if canuse then
				TriggerClientEvent('playerbooth', source, item)
			else
				TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'You cant install booth in this place' })
			end
		end)
	end
else
	local gazebo = {}
	local boothzones = {}

	RegisterNetEvent('playerbooth', function(data) -- compatibility with server usable callbacks
		if data then
			local app = PlaceApplications({model = data.metadata.model, id = data.boothid}, true)
			local booth = lib.callback.await('renzu_shops:createbooth', false, {
				boothid = data.metadata?.boothid,
				metadata = data.metadata,
				coords = app.coord,
				heading = app.heading
			})
		end
	end)

	exports('playerbooth', function(data, slot)
		local canuse = true
		for k,v in pairs(PlayerBooth.blacklistarea) do
			if #(GetEntityCoords(cache.ped) - v) < 50 then
				canuse = false
			end
		end
		if canuse then
			exports.ox_inventory:useItem(data, function(data)
				if data then
					local app = PlaceApplications({model = data.metadata.model, id = data.boothid}, true)
					local booth = lib.callback.await('renzu_shops:createbooth', false, {
						boothid = data.metadata?.boothid,
						metadata = data.metadata,
						coords = app.coord,
						heading = app.heading
					})
				end
			end)
		else
			local Shops = exports.renzu_shops:Shops()
			Shops.SetNotify({
				description = 'You cant install booth in this place',
				type = 'error'
			})
		end
	end)

	AddStateBagChangeHandler('playerbooth' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
		Wait(0)
		local Shops = exports.renzu_shops:Shops()
		local player = Shops.GetPlayerData()
		if not value then return end
		local net = tonumber(bagName:gsub('entity:', ''), 10)
		gazebo[value.boothid] = NetworkGetEntityFromNetworkId(net)
		if player.identifier == value.owner then
			local entity = NetworkGetEntityFromNetworkId(net)
			Shops.SetEntityControlable(entity)
			PlaceObjectOnGroundProperly(entity)
			FreezeEntityPosition(entity,true)
			local offset = GetOffsetFromEntityInWorldCoords(entity,2.01,2.264,0.01)+vec3(0.0,0.0,0.5)
			if not boothzones[value.boothid] then boothzones[value.boothid] = {} end
			boothzones[value.boothid]['stall'] = Shops.Add(offset,'Booth Menu',MyBooth,false,{booth = value.owner, boothid = value.boothid})
		end
	end)

	local apps = {}
	AddStateBagChangeHandler("UninstallBooth", "global", function(bagName, key, value)
		Wait(0)
		for k,v in pairs(boothzones) do
			if value.id == k then
				for k,v in pairs(v) do
					v:remove()
				end
			end
		end
	end)

	AddStateBagChangeHandler('boothapplication' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
		Wait(0)
		local Shops = exports.renzu_shops:Shops()
		local player = Shops.GetPlayerData()
		if not value then return end
		local net = tonumber(bagName:gsub('entity:', ''), 10)
		print(net)
		while not DoesEntityExist(NetworkGetEntityFromNetworkId(net)) do Wait(1) end
		local booths = GlobalState.Booths
		gazebo[value.id] = NetworkGetEntityFromNetworkId(value.gazebonet)
		local offset = GetOffsetFromEntityInWorldCoords(gazebo[value.id],value.coord.x,value.coord.y,value.coord.z)
		local offset = GetEntityCoords(gazebo[value.id]) + vec3(value.coord.x,value.coord.y,value.coord.z)
		if not boothzones[value.id] then boothzones[value.id] = {} end
		if not value.new then
			SetEntityCoordsNoOffset(NetworkGetEntityFromNetworkId(net),offset)
		end
		if value.type == 'stash' and value.owner == player.identifier then
			offset = offset + vec3(0.0,-0.5,0.15)
			boothzones[value.id][value.appid..'_'..value.type] = Shops.Add(offset,'Stash',BoothStash,false,{booth = value.owner, boothid = value.id, coord = offset, appid = value.appid})
		end
		if value.type == 'storage' and value.owner == player.identifier then
			offset = offset + vec3(0.0,-0.5,0.15)
			boothzones[value.id][value.appid..'_'..value.type] = Shops.Add(offset,'Stash',BoothStash,false,{booth = value.owner, boothid = value.id, coord = offset, appid = value.appid})
		end
		print(value.type)
		if value.type == 'cashier' then
			offset = offset + vec3(0.0,0.5,0.0)
			print("add zone")
			boothzones[value.id][value.appid..'_Shop'] = Shops.Add(offset,'Booth Shop',Shops.OpenShopBooth,false,{identifier = value.id, shop = { label = 'Booth Shop', inventory = {}, }})
			print(boothzones[value.id][value.appid..'_Shop'],offset)
		end
		if not apps[value.id] then apps[value.id] = {} end

		apps[value.id][value.appid] = {net = net, label = PlayerBooth.objects[value.model].label}
		FreezeEntityPosition(NetworkGetEntityFromNetworkId(net),true)
	end)

	Cashier = function()

	end
	BoothStash = function(data)
		if shared.inventory == 'ox_inventory' then
			TriggerEvent('ox_inventory:openInventory', 'stash', {id = tostring(data.appid), name = 'Stash', slots = 40, weight = 40000, coords = data.coord})
		elseif shared.inventory == 'qb-inventory' then
			TriggerServerEvent('inventory:server:OpenInventory', 'stash', tostring(data.appid), {})
			TriggerServerEvent("InteractSound_SV:PlayOnSource", "StashOpen", 0.4)
			TriggerEvent("inventory:client:SetCurrentStash", tostring(data.appid))
		end
	end

	Uninstall = function(data)
		local net = lib.callback.await('renzu_shops:uninstallbooth', false, data.boothid)

	end

	MyBooth = function(data)
		local options = {}
		table.insert(options,{
			title = 'Add Applications',
			description = 'Place Application can be used to this Booth',
			arrow = true,
			onSelect = function(args)
				Applications(data)
			end
		})
		table.insert(options,{
			title = 'Remove Application',
			description = 'Delete Application from your booth',
			arrow = true,
			onSelect = function(args)
				RemoveApplications(data)
			end
		})
		table.insert(options,{
			title = 'Manage Items',
			description = 'Here you can assign a price for each items',
			arrow = true,
			onSelect = function(args)
				OrganizeItems(data)
			end
		})
		table.insert(options,{
			title = 'Uninstall Booth',
			description = 'Close your booth',
			arrow = true,
			onSelect = function(args)
				Uninstall(data)
			end
		})
		table.insert(options,{
			title = 'Enable/Disable Shop',
			description = 'Start or Stop Selling',
			arrow = true,
			onSelect = function(args)
				lib.callback.await('renzu_shops:boothshop', false, data.boothid)
			end
		})
		lib.registerContext({
			id = 'boothmenu',
			title = 'Booth Menu',
			onExit = function()
			end,
			options = options
		})
		lib.showContext('boothmenu')
	end
	
	RemoveApplications = function(data)
		local options = {}
		for k,v in pairs(apps[data.boothid] or {}) do
			table.insert(options,{
				title = v.label,
				description = 'remove '..v.label,
				arrow = true,
				onSelect = function(args)
					local removed = lib.callback.await('renzu_shops:removeapp', false, {id = data.boothid, appid = k, net = v.net})
				end
			})
		end
		lib.registerContext({
			id = 'boothapplications',
			title = 'Remove Application',
			onExit = function()
			end,
			options = options
		})
		lib.showContext('boothapplications')
	end

	Applications = function(data)
		local options = {}
		for k,v in pairs(PlayerBooth.objects) do
			table.insert(options,{
				title = v.label,
				description = 'Choose '..v.label,
				arrow = true,
				onSelect = function(args)
					Citizen.CreateThreadNow(function()
						PlaceApplications({model = k, id = data.boothid})
					end)
				end
			})
		end
		lib.registerContext({
			id = 'boothapplications',
			title = 'Applications Menu',
			onExit = function()
			end,
			options = options
		})
		lib.showContext('boothapplications')
	end

	OrganizeItems = function(data)
		local Shops = exports.renzu_shops:Shops()
		local options = {}
		local stash = lib.callback.await('renzu_shops:GetInventoryData', false, data.boothid)
		for category,v in pairs(stash) do
			if string.find(v.name:upper(),'WEAPON') then
				v.name = v.name:upper()
			end
			local label = v.metadata and v.metadata.name and v.metadata.label or Shops.Items[v.name] or v.name
			local name = v.metadata and v.metadata.name or v.name
			if string.find(name:lower(), 'weapon') then
				name = name:upper()
			end
			table.insert(options,{
				title = label,
				description = 'Modify Sales of '..label,
				arrow = true,
				onSelect = function(args)
					local options = {}
					local index = 3
					table.insert(options,{ type = "number", label = "Price", placeholder = 50 , disabled = false})
					table.insert(options,{ type = "input", label = "Category", placeholder = 'Food' , disabled = false})
					local input = lib.inputDialog('Modify '..label, options)
					if input and input[1] then
						lib.callback.await('renzu_shops:boothitems', false, {id = data.boothid, item = name, price = input[1] or 50, category = input[2] or 'Default'})
					end
				end
			})
		end
		lib.registerContext({
			id = 'boothitems',
			title = 'Booth Items',
			onExit = function()
			end,
			options = options
		})
		lib.showContext('boothitems')
	end

	PlaceApplications = function(data,booth)
		local Shops = exports.renzu_shops:Shops()
		Shops.OxlibTextUi("Press [E] to Install  \n  Press [NUM4] Left  \n  Press [NUM6] right  \n  Press [NUM5] forward  \n  Press [NUM8] Downward  \n  Press [Mouse Scroll] Height  \n  Press [Caps] - Speed")
		local model = joaat(data.model)
		lib.requestModel(model)
		local appliance = CreateObjectNoOffset(model,GetEntityCoords(cache.ped)+vec3(1.0,2.0,0.0), false, true, false)
		while not DoesEntityExist(appliance) do Wait(0) end
		local moveSpeed = 0.001
		PlaceObjectOnGroundProperly(appliance)
		FreezeEntityPosition(appliance, true)
		SetEntityAlpha(appliance, 200, true)
		print(gazebo[data.id],DoesEntityExist(gazebo[data.id]))
		local gazebocoord = GetEntityCoords(gazebo[data.id])
		while appliance ~= nil do
			Citizen.Wait(1)
			DisableControlAction(0, 51)
			DisableControlAction(0, 96)
			DisableControlAction(0, 97)
			for i = 108, 112 do
				DisableControlAction(0, i)
			end
			DisableControlAction(0, 117)
			DisableControlAction(0, 118)
			DisableControlAction(0, 171)
			DisableControlAction(0, 254)
			if IsDisabledControlPressed(0, 171) then -- caps
				moveSpeed = moveSpeed + 0.001
			end
			if IsDisabledControlPressed(0, 254) then -- L shift
				moveSpeed = moveSpeed - 0.001
			end
			if moveSpeed > 1.0 or moveSpeed < 0.001 then
				moveSpeed = 0.001
			end
			HudWeaponWheelIgnoreSelection()
			for i = 123, 128 do
				DisableControlAction(0, i)
			end
			if not booth and IsDisabledControlJustPressed(0, 51) and #(GetEntityCoords(appliance) - gazebocoord) < 4 or booth and IsDisabledControlJustPressed(0, 51) then
				lib.hideTextUI()
				local heading = GetEntityHeading(appliance)
				if booth then
					local coord = GetEntityCoords(appliance)
					DeleteEntity(appliance) 
					return {coord = coord, heading = heading} 
				end
				local offset = GetEntityCoords(appliance) - GetEntityCoords(gazebo[data.id])
				local net = lib.callback.await('renzu_shops:placeapplication', false, {id = data.id , model = data.model, coord = offset, heading = heading, new = true})
				DeleteEntity(appliance)
				Wait(500)
				local entity = NetworkGetEntityFromNetworkId(net)
				Shops.SetEntityControlable(entity)
				SetEntityHeading(entity, heading)
				SetEntityCollision(entity,true,true)
				FreezeEntityPosition(entity,true)
				break
			end
			if not booth and IsDisabledControlJustPressed(0, 51) and #(GetEntityCoords(appliance) - gazebocoord) > 4 then
				Shops.SetNotify({
					description = 'Placement is out of bounds',
					type = 'error'
				})
			end
			if IsDisabledControlPressed(0, 96) then -- wheel scroll
				SetEntityCoords(appliance, GetOffsetFromEntityInWorldCoords(appliance, 0.0, 0.0, moveSpeed))
			end
			if IsDisabledControlPressed(0, 97) then -- wheel scroll
				SetEntityCoords(appliance, GetOffsetFromEntityInWorldCoords(appliance, 0.0, 0.0, -moveSpeed))
			end
			if IsDisabledControlPressed(0, 108) then -- num4
				SetEntityHeading(appliance, GetEntityHeading(appliance) + 0.5)
			end
			if IsDisabledControlPressed(0, 109) then -- num6
				SetEntityHeading(appliance, GetEntityHeading(appliance) - 0.5)
			end
			if IsDisabledControlPressed(0, 111) then
				SetEntityCoords(appliance, GetOffsetFromEntityInWorldCoords(appliance, 0.0, -moveSpeed, 0.0))
			end
			if IsDisabledControlPressed(0, 110) then
				SetEntityCoords(appliance, GetOffsetFromEntityInWorldCoords(appliance, 0.0, moveSpeed, 0.0))
			end
			if IsDisabledControlPressed(0, 117) then
				SetEntityCoords(appliance, GetOffsetFromEntityInWorldCoords(appliance, moveSpeed, 0.0, 0.0))
			end
			if IsDisabledControlPressed(0, 118) then
				SetEntityCoords(appliance, GetOffsetFromEntityInWorldCoords(appliance, -moveSpeed, 0.0, 0.0))
			end
		end
	end
end