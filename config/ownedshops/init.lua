-- Buyable Shops


-- @ moneytype . eg. money, black_money. or any custom currency (can be item or from framework accounts if its supported)
-- @ item = declare money type as item
--- @ groups = {'mehcanic','police'} -- array of job names
--- @stash = coordinates in vec3
--- @work = table of functions (TASK) example can be seen from police armoury or pondcafe
--- @proccessed = talbe of functions (TASKS / convert to item) example can be seen from police armoury or pondcafe
--- @ped = function to spawn ped . example can be seen from pondcafe
--- @tasks table of functions with tasks . example can be seen from pondcafe
--- @supplieritem = lists of for sale items . this can be a table linked from storeitems.lua  ex. shared.Storeitems.PondCafe
-- @restock only used in vehicle shop. this is where to place the delivered vehicles to stock the dealership
-- @showcase = lists of displays vehicle to vehicleshop type. example is on Vehicleshop
-- @ Shop Label name Aka Shop identifier for Owned Shops. ex General Store #3 (3 is the Shop index for example)
-- @ Store Owner Coordinates or Buy Store Coordinates vec3 format
-- @ Cashier Coordinates. this can be disable by removing the cashier by commenting it via -- cashier = {}. cashier coordinates are the same with robber trigger location
-- @ Shop Price
-- @ Item data table for items. { name = 'burger', price = 100} or the config table the same with the sample above.
return {
	['General'] = request('config/ownedshops/General'),
	['Ammunation'] = request('config/ownedshops/Ammunation'),
	['VehicleShop'] = request('config/ownedshops/VehicleShop'),
	['BlackMarketArms'] = request('config/ownedshops/BlackMarketArms'),
	--['Burgershot'] = request('config/ownedshops/Burgershot'),
	--['EclipseSupply'] = request('config/ownedshops/EclipseSupply'),
	--['Pharmacy'] = request('config/ownedshops/Pharmacy'),
	['PoliceArmoury'] = request('config/ownedshops/PoliceArmoury'),
	['MechanicSupply'] = request('config/ownedshops/MechanicSupply'),
	--['BeanMachine'] = request('config/ownedshops/BeanMachine'),
	['PondCafe'] = request('config/ownedshops/PondCafe'),
	['Balls8'] = request('config/ownedshops/Balls8'),
	['ClothingShop'] = request('config/ownedshops/ClothingShop'),
	--['Petshop'] = request('config/ownedshops/Petshop'),
	['LiquorStore'] = request('config/ownedshops/LiquorStore'),

}