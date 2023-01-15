-- Buyable Shops

-- SAMPLE
	-- General = { -- @1
	-- 	[1] = { -- @2
	-- 		moneytype = 'money', -- @3
	-- 		label = 'General Store #1', -- @4
	-- 		coord = vec3(25.931,-1350.181,29.32), -- @5
	-- 		cashier = vec3(24.48,-1347.23,29.49), -- @6
	-- 		price = 1000000, -- @7
	-- 		supplieritem = shared.Storeitems.General, -- @8
	-- 	},
	-- }

-- @1 Shop Type . ex. General  ( must be same with config/defaultshops.lua )
-- @2 Shop Index 
	-- Same Index Number must be the same with config/defaultshops.lua #locations
	-- locations = {
	-- 	vec3(2748.0, 3473.0, 55.67), <-- Shop index 1
	-- 	vec3(342.99, -1298.26, 32.51) <-- Shop index 2
	-- }
-- @3 Money Type. eg. money, black_money. or any custom currency (must be item)
-- @4 Shop Label name Aka Shop identifier for Owned Shops. ex General Store #3 (3 is the Shop index for example)
-- @5 Store Owner Coordinates or Buy Store Coordinates vec3 format
-- @6 Cashier Coordinates. this can be disable by removing the cashier by commenting it via -- cashier = {}. cashier coordinates are the same with robber trigger location
-- @7 Shop Price
-- @8 Item data table for items. { name = 'burger', price = 100} or the config table the same with the sample above.
return {
	['General'] = request('config/ownedshops/General'),
	['Ammunation'] = request('config/ownedshops/Ammunation'),
	['VehicleShop'] = request('config/ownedshops/VehicleShop'),
	['BlackMarketArms'] = request('config/ownedshops/BlackMarketArms'),
	['BlackMarketArms2'] = request('config/ownedshops/BlackMarketArms2'),
	['Burgershot'] = request('config/ownedshops/Burgershot'),
	['EclipseSupply'] = request('config/ownedshops/EclipseSupply'),
	['Pharmacy'] = request('config/ownedshops/Pharmacy'),
	['PoliceArmoury'] = request('config/ownedshops/PoliceArmoury'),
	['MechanicSupply'] = request('config/ownedshops/MechanicSupply'),
	['BeanMachine'] = request('config/ownedshops/BeanMachine'),
	['PondCafe'] = request('config/ownedshops/PondCafe'),
	['8Balls'] = request('config/ownedshops/8Balls'),
	['ClothingShop'] = request('config/ownedshops/ClothingShop'),
	['Petshop'] = request('config/ownedshops/Petshop'),
	['LiquorStore'] = request('config/ownedshops/LiquorStore'),

}