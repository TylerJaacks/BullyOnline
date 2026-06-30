-- limit total vehicle spawns to MAX_TOTAL_SPAWNED
MAX_TOTAL_SPAWNED = 70

-- limit vehicle spawns within MAX_NEARBY_DISTANCE to MAX_NEARBY_SPAWNED
MAX_NEARBY_SPAWNED = 3
MAX_NEARBY_DISTANCE = 30

-- vehicles can despawn if not interacted with for a while *and* far away from any player
DESPAWN_TIMER = 300000
DESPAWN_DISTANCE = 100

-- default spawn settings
gDefaultSpawnMin = 45
gDefaultSpawnMax = 60
gDefaultSpawnChance = 39

-- common model pools
gBikeModels = {
	{10, 272}, -- bmxrace
	{10, 273}, -- retro
	{10, 274}, -- crapbmx
	{10, 277}, -- bike
	{10, 278}, -- custombike
	{10, 279}, -- banbike
	{10, 280}, -- mtnbike
	{10, 281}, -- oladbike
	{10, 282}, -- racer
	{10, 283}, -- aquabike
}
gCivilianCarModels = {
	{10, 286}, -- Taxicab
	{10, 290}, -- Limo
	{10, 291}, -- Delivery Truck
	{10, 292}, -- Foreign
	{10, 293}, -- Cargreen
	{10, 294}, -- 70wagon
	{10, 296}, -- Domestic
	{10, 297}, -- Truck
}

-- vehicle spawn locations and models
gVehicleSpawns = {
	-- Bullworth Town (Ambulance)
	{ -- Alleyway next to Bullworth Town infirmary
		spawn = {560.90, -114.22, 6.79, -89.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{80, "ambulance"}, -- Ambulance
			{20, 296}, -- Domestic
		},
	},
	-- Bullworth Town (Bikes)
	{ -- Shiny Bikes bike rack
		spawn = {485.37, -79.58, 5.91, 5.5},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Yum Yum Market alleyway
		spawn = {537.05, -77.11, 5.55, -178.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Fire Station bike rack
		spawn = {598.98, -12.75, 7.01, -84.5},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Bank bike rack
		spawn = {518.30, -33.06, 6.76, 13.8},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Cinema bike rack
		spawn = {513.22, -152.25, 5.75, -166.2},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Dragon's Wing alleyway
		spawn = {503.55, -57.73, 6.28, 1.4},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	-- Bullworth Town (Other)
	{ -- Police Station
		spawn = {615.60, -112.05, 5.84, 5.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{50, "electric_scooter"}, -- Electric Scooter
			{50, "skateboard_electric"}, -- Electric Skateboard
		},
	},
	-- Bullworth Town (Mopeds)
	{ -- Gas Station
		spawn = {552.72, 1.18, 5.47, -176.3},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100, 276}, -- Moped
		},
	},
	-- Bullworth Town (Cars)
	{ -- Gas Station
		spawn = {559.16, 1.09, 6.56, 2.5},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Motel 1
		spawn = {474.28, -179.51, 3.86, -165.5},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Motel 2
		spawn = {470.07, -204.21, 4.03, 14.1},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Behind Bank 1
		spawn = {498.89, -19.86, 7.22, -177.3},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Behind Bank 2
		spawn = {487.83, -20.35, 7.01, -0.2},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Fire Station 1
		spawn = {593.99, -20.40, 7.32, -71.9},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Fire Station 2
		spawn = {593.87, -13.25, 7.39, 107.2},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	-- New Coventry (Bikes)
	{ -- Yum Yum Market front
		spawn = {490.56, -277.12, 2.98, -1.3},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Golden Horseshoe side
		spawn = {536.12, -370.98, 2.88, -93.6},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Blue Balls side
		spawn = {528.68, -411.10, 2.65, 8.1},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Apartment Building bike rack
		spawn = {522.63, -486.93, 4.94, 170.8},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Tenements front
		spawn = {580.17, -461.64, 4.98, 50.4},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Mini Junkyard
		spawn = {425.45, -453.93, 3.20, -106.2},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Traincart
		spawn = {463.02, -245.91, 4.26, 173.2},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Bar back
		spawn = {524.19, -307.42, 3.26, 85.6},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	-- New Coventry (Other)
	{ -- Secret spot 1
		spawn = {615.60, -112.05, 5.84, 5.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100, "electric_scooter"}, -- Electric Scooter
		},
	},
	{ -- Secret Spot 2
		spawn = {506.20, -338.10, 9.71, -0.2},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100, "soapbox"}, -- Soapbox
		},
	},
	{ -- Alleyway 4
		spawn = {522.20, -345.32, 3.00, 6.4},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100, "minicar"},
		},
	},
	-- New Coventry (Cars)
	{ -- Alleyway 1
		spawn = {546.30, -461.71, 5.36, -16.3},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Warehouse
		spawn = {430.69, -425.76, 3.45, 73.5},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Blue Balls
		spawn = {516.49, -407.95, 3.09, 9.8},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Golden Horseshoe
		spawn = {533.37, -375.79, 3.28, -3.4},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Alleyway 2
		spawn = {532.95, -357.77, 4.17, -85.3},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Bar Back 1
		spawn = {527.51, -309.66, 3.62, 91.4},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Bar Back 2
		spawn = {528.62, -315.90, 3.77, -89.8},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Alleyway 3
		spawn = {517.25, -269.82, 3.28, 93.4},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	-- Blue Skies (Other)
	{ -- Clint's Garage
		spawn = {615.60, -112.05, 5.84, 5.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100, "homemade_gokart"}, -- Homemade Gokart
		},
	},
	{ -- Storage Unit 2
		spawn = {192.63, -468.90, 9.37, 121.6},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100, "skateboard_electric"}, -- Electric Skateboard
		},
	},
	{ -- Shipping Lot
		spawn = {112.86, -405.43, 7.67, -63.3},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100, "electric_scooter"}, -- Electric Scooter
		},
	},
	{ -- Happy Volts Asylum
		spawn = {-98.98, -313.27, 4.98, 129.1},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100, "soapbox"}, -- Soapbox
		},
	},
	-- Blue Skies (Cars)
	{ -- Townie Hidout
		spawn = {159.37, -375.98, 3.52, -81.3},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Paint Shop
		spawn = {209.95, -373.40, 3.58, 103.6},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Chemplant
		spawn = {164.98, -492.88, 3.55, 32.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Shipping Lot
		spawn = {103.59, -406.93, 2.83, 11.0},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- House 3
		spawn = {310.63, -326.48, 3.61, 174.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- House 10
		spawn = {263.22, -445.45, 4.48, 14.2},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Harbor
		spawn = {232.76, -312.75, 4.44, 98.6},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	-- Blue Skies (Mopeds)
	{ -- House 1
		spawn = {250.52, -337.08, 2.64, -89.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100, 276}, -- Moped
		},
	},
	-- Blue Skies (Bikes)
	{ -- Infirmary side
		spawn = {269.99, -369.46, 3.20, -3.0},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Harbor bike rack
		spawn = {223.60, -303.71, 4.00, 8.1},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Shipping lot bike rack
		spawn = {130.02, -407.65, 3.17, 105.6},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Chemplant bike rack
		spawn = {117.91, -517.63, 3.84, -140.2},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Townie Hidout
		spawn = {133.51, -351.03, 3.42, 145.9},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Spencer Shipping
		spawn = {165.69, -351.79, 3.52, -171.4},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- House 3
		spawn = {299.33, -328.20, 3.83, 86.1},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- House 4 bike rack
		spawn = {315.54, -382.41, 3.20, -152.1},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Warehouse bike rack
		spawn = {237.86, -439.46, 3.26, -154.6},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	-- Bullworth Academy (Bikes)
	{ -- Front gate bike rack 1
		spawn = {306.40, -66.58, 6.12, 89.5},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Front gate bike rack 2
		spawn = {306.38, -65.51, 6.06, 92.9},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Autoshop 1
		spawn = {146.43, 1.75, 6.72, 89.9},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Autoshop 2
		spawn = {122.98, -9.38, 6.74, -2.5},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Jock Clubhouse
		spawn = {-18.65, -21.19, 2.61, -175.9},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	-- Bullworth Academy (Cars)
	{ -- Parking Lot 1
		spawn = {175.16, -10.76, 6.70, 180.0},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Parking Lot 2
		spawn = {198.86, -10.99, 6.57, -179.8},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Parking Lot 3
		spawn = {202.22, 5.77, 6.42, 0.6},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Parking Lot 4
		spawn = {193.81, 6.37, 6.38, -1.1},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	-- Bullworth Academy (Other)
	{ -- Boys' Dorm back
		spawn = {255.52, -137.97, 6.12, -89.4},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100,"electric_scooter"}, -- Electric Scooter
		},
	},
	{ -- Observatory
		spawn = {53.56, -115.92, 3.62, 93.0},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100,"homemade_gokart"}, -- Homemade Gokart
		},
	},
	{ -- Harrington House
		spawn = {125.87, -140.38, 7.42, -2.8},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100,284},
		},
	},
	-- Old Bullworth Vale (Bikes)
	{ -- Bridge bike rack
		spawn = {348.90, 124.95, 5.88, -89.6},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Boxing Gym bike rack
		spawn = {396.57, 148.57, 5.76, -88.0},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Shiny Bikes bike rack
		spawn = {331.99, 270.63, 6.40, -85.0},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Burger Joint
		spawn = {405.53, 262.81, 9.56, -81.8},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Newspaper Stand
		spawn = {411.53, 239.29, 9.72, -86.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Apartment building bike rack
		spawn = {445.19, 236.55, 10.25, -88.2},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- House bike rack
		spawn = {547.66, 247.14, 17.34, -85.4},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- House bike rack
		spawn = {603.23, 393.72, 17.03, -95.5},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Spencer Estate back
		spawn = {451.25, 456.78, 23.77, 177.6},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Spencer Estate garage bike rack
		spawn = {387.88, 393.47, 22.01, -173.3},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Apartment building bike rack
		spawn = {401.29, 189.98, 7.21, -177.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Cemetery front
		spawn = {625.69, 215.63, 18.18, -24.4},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Carnival bike rack
		spawn = {219.07, 424.36, 4.94, 59.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	{ -- Burger Joint
		spawn = {420.46, 300.24, 9.90, -174.0},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gBikeModels,
	},
	-- Old Bullworth Vale (Other)
	{ -- House garage side
		spawn = {581.82, 448.33, 18.69, 0.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100,"electric_scooter"}, -- Electric Scooter
		},
	},
	{ -- Beach pier
		spawn = {284.56, 220.93, 5.79, -176.5},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100,"foodvan"}, -- Food Van
		},
	},
	{ -- Hills House back
		spawn = {300.00, 385.97, 24.59, 177.0},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100,"electric_scooter"}, -- Electric Scooter
		},
	},
	{ -- Carnival Squid Ride back
		spawn = {167.43, 481.41, 5.73, 79.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100,"unicycle"}, -- Unicycle
		},
	},
	-- Old Bullworth Vale (Mopeds)
	{ -- Marketplace
		spawn = {438.91, 101.61, 5.28, 157.2},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100,276},
		},
	},
	{ -- Carnival
		spawn = {212.06, 412.03, 4.25, -94.4},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100,276},
		},
	},
	-- Old Bullworth Vale (Cars)
	{ -- Boxing Gym Alleyway
		spawn = {429.18, 163.38, 7.02, 92.9},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Carnival 1
		spawn = {234.96, 439.72, 5.22, -35.2},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Carnival 2
		spawn = {234.56, 424.33, 5.19, 52.9},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Alleyway
		spawn = {341.15, 174.05, 6.20, -46.2},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Hills House front
		spawn = {317.20, 401.52, 25.51, -35.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Spencer Estate garage
		spawn = {402.00, 409.11, 22.28, -90.8},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100,290},
		},
	},
	{ -- Hattrick manor
		spawn = {392.75, 527.61, 24.29, 40.1},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100,297},
		},
	},
	{ -- Spencer Estate front
		spawn = {434.77, 483.71, 24.23, 178.1},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = {
			{100,297},
		},
	},
	{ -- House
		spawn = {576.25, 456.05, 19.48, 1.1},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- Happy Endings Retirement Home
		spawn = {536.66, 371.78, 17.78, 88.9},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
	{ -- House
		spawn = {528.21, 214.11, 17.56, -92.7},
		minimum = gDefaultSpawnMin,
		maximum = gDefaultSpawnMax,
		chance = gDefaultSpawnChance,
		models = gCivilianCarModels,
	},
}

-- assert vehicle spawns (if you get an error, gVehicleSpawns is probably bad)
for _,spot in ipairs(gVehicleSpawns) do
	assert(type(spot.spawn) == "table")
	assert(table.getn(spot.spawn) == 4)
	assert(type(spot.minimum) == "number")
	assert(type(spot.maximum) == "number")
	assert(type(spot.chance) == "number" and spot.chance >= 0 and spot.chance <= 100)
	assert(type(spot.models) == "table")
	for _,v in ipairs(spot.models) do
		assert(type(v) == "table")
		assert(type(v[1]) == "number")
		assert(type(v[2]) == "number" or type(v[2]) == "string")
	end
end
