gCharacters = {}

local count = 0
local character = function(info)
	count = count + 1
	gCharacters[count] = info
end

local textures = {
	unknown = 0,
	Algernon = 1,
	Angie = 2,
	Beatrice = 3,
	Bif = 4,
	Bo = 5,
	Bryce = 6,
	Bucky = 7,
	Casey = 8,
	Chad = 9,
	Christy = 10,
	Constantinos = 11,
	Cornelius = 12,
	Damon = 13,
	Dan = 14,
	Darby = 15,
	Davis = 16,
	Donald = 17,
	Earnest = 18,
	Ethan = 19,
	Eunice = 20,
	Fatty = 21,
	Gary = 22,
	Gloria = 23,
	Gord = 24,
	Gordon = 25,
	Hal = 26,
	Ivan = 27,
	Jimmy = 28,
	Johnny = 29,
	Juri = 30,
	Justin = 31,
	Karen = 32,
	Kirby = 33,
	Lance = 34,
	Lefty = 35,
	Lola = 36,
	Lucky = 37,
	Luis = 38,
	Mandy = 39,
	Melody = 40,
	Melvin = 41,
	Norton = 42,
	Parker = 43,
	Peanut = 44,
	Pedro = 45,
	Peter = 46,
	Pinky = 47,
	Ray = 48,
	Ricky = 49,
	Russell = 50,
	Sheldon = 51,
	Tad = 52,
	Ted = 53,
	Thad = 54,
	Tom = 55,
	Trent = 56,
	Trevor = 57,
	Troy = 58,
	Vance = 59,
	Wade = 60,
	Zoe = 61,
}

-- Non-Cliques
character({ -- Gary Smith
	id = "gary",
	name = "Gary Smith",
	icon = textures.Gary,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 500,
	variants = {
		{id = "default", name = "Academy Uniform", model = 130, locked = true, price = 500}, -- gary (default): hours 30
		{id = "ween", name = "Halloween Costume", model = 160, locked = true, price = 500}, -- gary (ween): can only be bought during Halloween event
	},
})
character({ -- Peter Kowalski
	id = "peter",
	name = "Peter Kowalski",
	icon = textures.Peter,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 500,
	variants = {
		{id = "default", name = "Academy Uniform", model = 134, locked = true, price = 500}, -- peter (default): hours 30
		{id = "ween", name = "Halloween Costume", model = 165, locked = true, price = 500}, -- peter (ween): can only be bought during Halloween event
		{id = "nutcrack", name = "Christmas Costume", model = 255, locked = true, price = 500}, -- peter (nutcrack): can only be bought during Christmas event
	},
})
character({ -- Sheldon Thompson
	id = "sheldon",
	name = "Sheldon Thompson",
	icon = textures.Sheldon,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 66, locked = false, price = 100},
		{id = "pj", name = "Pajamas", model = 225, locked = false, price = 100},
	},
})
character({ -- Christy Martin
	id = "christy",
	name = "Christy Martin",
	icon = textures.Christy,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 67, locked = false, price = 100},
		{id = "pj", name = "Pajamas", model = 90, locked = false, price = 100},
		{id = "ch", name = "Cheerleader Outfit", model = 181, locked = false, price = 250},
	},
})
character({ -- Gloria Jackson
	id = "gloria",
	name = "Gloria Jackson",
	icon = textures.Gloria,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 68, locked = false, price = 100},
	},
})
character({ -- Pedro De La Hoya
	id = "pedro",
	name = "Pedro De La Hoya",
	icon = textures.Pedro,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 69, locked = false, price = 100},
		{id = "ween", name = "Halloween Costume", model = 159, locked = true, price = 500}, -- pedro (ween): can only be bought during Halloween event
		{id = "pj", name = "Pajamas", model = 226, locked = false, price = 100},
		{id = "nutcrack", name = "Christmas Costume", model = 258, locked = true, price = 500}, -- pedro (nutcrack): can only be bought during Christmas event
	},
})
character({ -- Constantinos Brakus
	id = "constantinos",
	name = "Constantinos Brakus",
	icon = textures.Constantinos,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 70, locked = false, price = 100},
		{id = "mascot", name = "Mascot Costume", model = 88, locked = false, price = 750},
		{id = "uw", name = "Underwear", model = 235, locked = true, price = 300}, -- constantinos (underwear): rw_kills 50
	},
})
character({ -- Ray Hughes
	id = "ray",
	name = "Ray Hughes",
	icon = textures.Ray,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 71, locked = false, price = 100},
	},
})
character({ -- Ivan Alexander
	id = "ivan",
	name = "Ivan Alexander",
	icon = textures.Ivan,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 72, locked = false, price = 100},
		{id = "pj", name = "Pajamas", model = 227, locked = false, price = 100},
	},
})
character({ -- Trevor Moore
	id = "trevor",
	name = "Trevor Moore",
	icon = textures.Trevor,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 73, locked = false, price = 100},
		{id = "ween", name = "Halloween Costume", model = 171, locked = true, price = 500}, -- trevor (ween): can only be bought during Halloween event
		{id = "pj", name = "Pajamas", model = 228, locked = true, price = 500},
	},
})
character({ -- Eunice Pound
	id = "eunice",
	name = "Eunice Pound",
	icon = textures.Eunice,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 74, locked = false, price = 100},
		{id = "nutcrack", name = "Christmas Costume", model = 256, locked = true, price = 500}, -- eunice (nutcrack): can only be bought during Christmas event
	},
})
character({ -- Melody Adams
	id = "melody",
	name = "Melody Adams",
	icon = textures.Melody,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 137, locked = false, price = 100},
		{id = "nutcrack", name = "Christmas Costume", model = 257, locked = true, price = 500}, -- melody (nutcrack): can only be bought during Christmas event
	},
})
character({ -- Karen Johnson
	id = "karen",
	name = "Karen Johnson",
	icon = textures.Karen,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 138, locked = false, price = 100},
	},
})
character({ -- Gordon Wakefield
	id = "gordon",
	name = "Gordon Wakefield",
	icon = textures.Gordon,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 139, locked = false, price = 100},
		{id = "ween", name = "Halloween Costume", model = 169, locked = true, price = 500}, -- gordon (ween): can only be bought during Halloween event
	},
})
character({ -- Lance Jackson
	id = "lance",
	name = "Lance Jackson",
	icon = textures.Lance,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 142, locked = false, price = 100},
	},
})
character({ -- Angie Ng
	id = "angie",
	name = "Angie Ng",
	icon = textures.Angie,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 39, locked = false, price = 100},
		{id = "ween", name = "Halloween Costume", model = 166, locked = true, price = 500}, -- angie (ween): can only be bought during Halloween event
		{id = "ch", name = "Cheerleader Outfit", model = 180, locked = false, price = 250},
	},
})

-- Nerds
character({ -- Earnest Jones
	id = "earnest",
	name = "Earnest Jones",
	icon = textures.Earnest,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 1000,
	variants = {
		{id = "default", name = "Academy Uniform", model = 10, locked = true, price = 1000}, -- earnest (default): hours 20
		{id = "eg", name = "Complete Mayhem", model = 215, locked = true, price = 1000}, -- earnest (eg): fight_as_char 2000
	},
})
character({ -- Beatrice Trudaeu
	id = "beatrice",
	name = "Beatrice Trudaeu",
	icon = textures.Beatrice,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 3, locked = false, price = 100},
		{id = "pj", name = "Pajamas", model = 95, locked = false, price = 100},
	},
})
character({ -- Algernon Papadopoulos
	id = "algernon",
	name = "Algernon Papadopoulos",
	icon = textures.Algernon,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 4, locked = false, price = 100},
		{id = "gs", name = "Gym Clothes", model = 208, locked = false, price = 250},
	},
})
character({ -- Fatty Johnson
	id = "fatty",
	name = "Fatty Johnson",
	icon = textures.Fatty,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 5, locked = false, price = 100},
		{id = "wres", name = "Wrestling Outfit", model = 122, locked = false, price = 250},
		{id = "choc", name = "Chocolate Smear", model = 155, locked = false, price = 100},
		{id = "ween", name = "Halloween Costume", model = 186, locked = true, price = 500}, -- fatty (ween): can only be bought during Halloween event
	},
})
character({ -- Melvin O'Connor
	id = "melvin",
	name = "Melvin O'Connor",
	icon = textures.Melvin,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 6, locked = false, price = 100},
	},
})
character({ -- Thad Carlson
	id = "thad",
	name = "Thad Carlson",
	icon = textures.Thad,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 7, locked = false, price = 100},
		{id = "ween", name = "Halloween Costume", model = 174, locked = true, price = 500}, -- thad (ween): can only be bought during Halloween event
		{id = "gs", name = "Gym Clothes", model = 210, locked = false, price = 250},
		{id = "pj", name = "Pajamas", model = 224, locked = false, price = 100},
	},
})
character({ -- Bucky Pasteur
	id = "bucky",
	name = "Bucky Pasteur",
	icon = textures.Bucky,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 8, locked = false, price = 100},
		{id = "gs", name = "Gym Clothes", model = 209, locked = false, price = 250},
	},
})
character({ -- Cornelius Johnson
	id = "cornelius",
	name = "Cornelius Johnson",
	icon = textures.Cornelius,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 9, locked = false, price = 100},
	},
})
character({ -- Donald Anderson
	id = "donald",
	name = "Donald Anderson",
	icon = textures.Donald,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 11, locked = false, price = 100},
		{id = "ween", name = "Halloween Costume", model = 162, locked = true, price = 500}, -- donald (ween): can only be bought during Halloween event
	},
})

-- Bullies
character({ -- Russell Northrop
	id = "russell",
	name = "Russell Northrop",
	icon = textures.Russell,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 1000,
	variants = {
		{id = "default", name = "Academy Uniform", model = 75, locked = true, price = 1000}, -- russell (default): hours 20
		{id = "eg", name = "Complete Mayhem", model = 176, locked = true, price = 1000}, -- russell (eg): fight_as_char 2000
	},
})
character({ -- Davis White
	id = "davis",
	name = "Davis White",
	icon = textures.Davis,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 99, locked = false, price = 100},
	},
})
character({ -- Trent Northwick
	id = "trent",
	name = "Trent Northwick",
	icon = textures.Trent,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 85, locked = false, price = 100},
	},
})
character({ -- Ethan Robinson
	id = "ethan",
	name = "Ethan Robinson",
	icon = textures.Ethan,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 145, locked = false, price = 100},
	},
})
character({ -- Wade Martin
	id = "wade",
	name = "Wade Martin",
	icon = textures.Wade,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 146, locked = false, price = 100},
	},
})
character({ -- Tom Gurney
	id = "tom",
	name = "Tom Gurney",
	icon = textures.Tom,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 147, locked = false, price = 100},
	},
})
character({ -- Troy Miller
	id = "troy",
	name = "Troy Miller",
	icon = textures.Troy,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 102, locked = false, price = 100},
		{id = "ween", name = "Halloween Costume", model = 170, locked = true, price = 500}, -- troy (ween): can only be bought during Halloween event
	},
})

-- Jocks
character({ -- Ted Thompson
	id = "ted",
	name = "Ted Thompson",
	icon = textures.Ted,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 1000,
	variants = {
		{id = "default", name = "Academy Uniform", model = 19, locked = true, price = 1000}, -- ted (default): hours 20
		{id = "fb", name = "Football Uniform", model = 110, locked = true, price = 100}, -- ted (football): race_wins 50
		{id = "eg", name = "Complete Mayhem", model = 216, locked = true, price = 1000}, -- ted (eg): fight_as_char 2000
	},
})
character({ -- Mandy Wiles
	id = "mandy",
	name = "Mandy Wiles",
	icon = textures.Mandy,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Cheerleader Outfit", model = 14, locked = false, price = 100},
		{id = "pj", name = "Pajamas", model = 93, locked = false, price = 100},
		{id = "towel", name = "Towel", model = 230, locked = true, price = 300}, -- mandy (towel): rw_kills 100
	},
})
character({ -- Damon West
	id = "damon",
	name = "Damon West",
	icon = textures.Damon,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 12, locked = false, price = 100},
		{id = "fb", name = "Football Uniform", model = 112, locked = true, price = 100}, -- damon (football): race_wins 50
		{id = "ween", name = "Halloween Costume", model = 168, locked = true, price = 500}, -- damon (ween): can only be bought during Halloween event
		{id = "gs", name = "Gym Clothes", model = 205, locked = false, price = 250},
	},
})
character({ -- Kirby Olsen
	id = "kirby",
	name = "Kirby Olsen",
	icon = textures.Kirby,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 13, locked = false, price = 100},
		{id = "fb", name = "Football Uniform", model = 109, locked = true, price = 100}, -- kirby (football): race_wins 50
		{id = "gs", name = "Gym Clothes", model = 207, locked = false, price = 250},
	},
})
character({ -- Dan Wilson
	id = "dan",
	name = "Dan Wilson",
	icon = textures.Dan,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 15, locked = false, price = 100},
		{id = "fb", name = "Football Uniform", model = 111, locked = true, price = 100}, -- dan (football): race_wins 50
	},
})
character({ -- Luis Luna
	id = "luis",
	name = "Luis Luna",
	icon = textures.Luis,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 16, locked = false, price = 100},
		{id = "wres", name = "Wrestling Outfit", model = 92, locked = false, price = 250},
	},
})
character({ -- Casey Harris
	id = "casey",
	name = "Casey Harris",
	icon = textures.Casey,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 17, locked = false, price = 100},
		{id = "ween", name = "Halloween Costume", model = 164, locked = true, price = 500}, -- casey (ween): can only be bought during Halloween event
		{id = "fb", name = "Football Uniform", model = 232, locked = true, price = 100}, -- casey (football): race_wins 50
	},
})
character({ -- Bo Jackson
	id = "bo",
	name = "Bo Jackson",
	icon = textures.Bo,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 18, locked = false, price = 100},
		{id = "gs", name = "Gym Clothes", model = 204, locked = false, price = 250},
		{id = "fb", name = "Football Uniform", model = 231, locked = true, price = 100}, -- bo (football): race_wins 50
	},
})
character({ -- Juri Karamazov
	id = "juri",
	name = "Juri Karamazov",
	icon = textures.Juri,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 20, locked = false, price = 100},
		{id = "gs", name = "Gym Clothes", model = 206, locked = false, price = 250},
	},
})
character({ -- Bob
	id = "bob",
	name = "Bob",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Wrestling Outfit", model = 121, locked = false, price = 100},
	},
})

-- Greasers
character({ -- Johnny Vincent
	id = "johnny",
	name = "Johnny Vincent",
	icon = textures.Johnny,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 1000,
	variants = {
		{id = "default", name = "Academy Uniform", model = 23, locked = true, price = 1000}, -- johnny (default): hours 20
		{id = "eg", name = "Complete Mayhem", model = 217, locked = true, price = 1000}, -- johnny (eg): fight_as_char 2000
	},
})
character({ -- Lola Lombardi
	id = "lola",
	name = "Lola Lombardi",
	icon = textures.Lola,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 25, locked = false, price = 100},
		{id = "pj", name = "Pajamas", model = 96, locked = false, price = 100},
	},
})
character({ -- Peanut Romano
	id = "peanut",
	name = "Peanut Romano",
	icon = textures.Peanut,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 21, locked = false, price = 100},
		{id = "gs", name = "Gym Clothes", model = 202, locked = false, price = 250},
	},
})
character({ -- Hal Esposito
	id = "hal",
	name = "Hal Esposito",
	icon = textures.Hal,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 22, locked = false, price = 100},
		{id = "gs", name = "Gym Clothes", model = 200, locked = false, price = 250},
	},
})
character({ -- Lefty Mancini
	id = "lefty",
	name = "Lefty Mancini",
	icon = textures.Lefty,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 24, locked = false, price = 100},
	},
})
character({ -- Lucky De Luca
	id = "lucky",
	name = "Lucky De Luca",
	icon = textures.Lucky,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 26, locked = false, price = 100},
		{id = "ween", name = "Halloween Costume", model = 161, locked = true, price = 500}, -- lucky (ween): can only be bought during Halloween event
	},
})
character({ -- Vance Medici
	id = "vance",
	name = "Vance Medici",
	icon = textures.Vance,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 27, locked = false, price = 100},
		{id = "ween", name = "Halloween Costume", model = 173, locked = true, price = 500}, -- vance (ween): can only be bought during Halloween event
		{id = "gs", name = "Gym Clothes", model = 203, locked = false, price = 250},
	},
})
character({ -- Ricky Pucino
	id = "ricky",
	name = "Ricky Pucino",
	icon = textures.Ricky,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 28, locked = false, price = 100},
	},
})
character({ -- Norton Williams
	id = "norton",
	name = "Norton Williams",
	icon = textures.Norton,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 29, locked = false, price = 100},
		{id = "gs", name = "Gym Clothes", model = 201, locked = false, price = 250},
	},
})

-- Preps
character({ -- Darby Harrington
	id = "darby",
	name = "Darby Harrington",
	icon = textures.Darby,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 1000,
	variants = {
		{id = "default", name = "Academy Uniform", model = 37, locked = true, price = 1000}, -- darby (default): hours 20
		{id = "eg", name = "Complete Mayhem", model = 218, locked = true, price = 1000}, -- darby (eg): fight_as_char 2000
	},
})
character({ -- Pinky Gauthier
	id = "pinky",
	name = "Pinky Gauthier",
	icon = textures.Pinky,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 38, locked = false, price = 100},
		{id = "pj", name = "Pajamas", model = 94, locked = false, price = 100},
		{id = "ween", name = "Halloween Costume", model = 167, locked = true, price = 500}, -- pinky (ween): can only be bought during Halloween event
		{id = "bw", name = "Aquaberry Casual", model = 175, locked = false, price = 300},
		{id = "ch", name = "Cheerleader Outfit", model = 182, locked = false, price = 250},
	},
})
character({ -- Gord Vendome
	id = "gord",
	name = "Gord Vendome",
	icon = textures.Gord,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 30, locked = false, price = 100},
		{id = "gs", name = "Gym Clothes", model = 214, locked = false, price = 250},
	},
})
character({ -- Tad Spencer
	id = "tad",
	name = "Tad Spencer",
	icon = textures.Tad,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 31, locked = false, price = 100},
		{id = "bw", name = "Aquaberry Casual", model = 177, locked = false, price = 300},
		{id = "gs", name = "Gym Clothes", model = 213, locked = false, price = 250},
	},
})
character({ -- Chad Morris
	id = "chad",
	name = "Chad Morris",
	icon = textures.Chad,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 32, locked = false, price = 100},
		{id = "box", name = "Boxing Outfit 1", model = 117, locked = true, price = 100},  -- chad (boxing1): rw_specific library
		{id = "box", name = "Boxing Outfit 2", model = 241, locked = true, price = 100},  -- chad (boxing2): rw_specific library
		{id = "box", name = "Boxing Outfit 3", model = 242, locked = true, price = 100},  -- chad (boxing3): rw_specific library
	},
})
character({ -- Bif Taylor
	id = "bif",
	name = "Bif Taylor",
	icon = textures.Bif,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 33, locked = false, price = 100},
		{id = "box", name = "Boxing Outfit 1", model = 133, locked = true, price = 100},  -- bif (boxing1): rw_specific warehouse
		{id = "box", name = "Boxing Outfit 2", model = 172, locked = true, price = 100},  -- bif (boxing2): rw_specific warehouse
		{id = "box", name = "Boxing Outfit 3", model = 243, locked = true, price = 100},  -- bif (boxing3): rw_specific warehouse
	},
})
character({ -- Justin Vandervelde
	id = "justin",
	name = "Justin Vandervelde",
	icon = textures.Justin,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 34, locked = false, price = 100},
		{id = "box", name = "Boxing Outfit 1", model = 118, locked = true, price = 100},  -- justin (boxing1): rw_specific hattrick_manor
		{id = "box", name = "Boxing Outfit 2", model = 244, locked = true, price = 100},  -- justin (boxing2): rw_specific hattrick_manor
		{id = "box", name = "Boxing Outfit 3", model = 245, locked = true, price = 100},  -- justin (boxing3): rw_specific hattrick_manor
		{id = "bw", name = "Aquaberry Casual", model = 179, locked = false, price = 300},
		{id = "gs", name = "Gym Clothes", model = 212, locked = false, price = 250},
	},
})
character({ -- Bryce Montrose
	id = "bryce",
	name = "Bryce Montrose",
	icon = textures.Bryce,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 35, locked = false, price = 100},
		{id = "box", name = "Boxing Outfit 1", model = 36, locked = true, price = 100},  -- bryce (boxing1): rw_specific the_tenements
		{id = "box", name = "Boxing Outfit 2", model = 239, locked = true, price = 100},  -- bryce (boxing2): rw_specific the_tenements
		{id = "box", name = "Boxing Outfit 3", model = 240, locked = true, price = 100},  -- bryce (boxing3): rw_specific the_tenements
		{id = "bw", name = "Aquaberry Casual", model = 178, locked = false, price = 300},
	},
})
character({ -- Parker Ogilvie
	id = "parker",
	name = "Parker Ogilvie",
	icon = textures.Parker,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 40, locked = false, price = 100},
		{id = "box", name = "Boxing Outfit 1", model = 119, locked = true, price = 100},  -- parker (boxing1): rw_specific happy_volts_asylum
		{id = "box", name = "Boxing Outfit 2", model = 246, locked = true, price = 100},  -- parker (boxing2): rw_specific happy_volts_asylum
		{id = "box", name = "Boxing Outfit 3", model = 247, locked = true, price = 100},  -- parker (boxing3): rw_specific happy_volts_asylum
		{id = "ween", name = "Halloween Costume", model = 163, locked = true, price = 500}, -- parker (ween): can only be bought during Halloween event
		{id = "gs", name = "Gym Clothes", model = 211, locked = false, price = 250},
	},
})

-- Townies
character({ -- Edgar Munsen
	id = "edgar",
	name = "Edgar Munsen",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 1000,
	variants = {
		{id = "default", name = "Casual Outfit", model = 91, locked = true, price = 1000}, -- edgar (default): hours 20
		{id = "gs", name = "Gym Clothes", model = 196, locked = false, price = 250},
	},
})
character({ -- Zoe Taylor
	id = "zoe",
	name = "Zoe Taylor",
	icon = textures.Zoe,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Outfit", model = 48, locked = false, price = 100},
		{id = "school", name = "Academy Uniform", model = 2, locked = false, price = 250},
	},
})
character({ -- Jerry
	id = "jerry",
	name = "Jerry",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Outfit", model = 41, locked = false, price = 100},
		{id = "gs", name = "Gym Clothes", model = 198, locked = false, price = 250},
	},
})
character({ -- Otto Tyler
	id = "otto",
	name = "Otto Tyler",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Outfit", model = 42, locked = false, price = 100},
		{id = "inmate", name = "Happy Volts Patient Gown", model = 150, locked = false, price = 250},
	},
})
character({ -- Leon
	id = "leon",
	name = "Leon",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Outfit", model = 43, locked = false, price = 100},
		{id = "inmate", name = "Happy Volts Patient Gown", model = 153, locked = false, price = 250},
		{id = "gs", name = "Gym Clothes", model = 199, locked = false, price = 250},
	},
})
character({ -- Duncan
	id = "duncan",
	name = "Duncan",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Outfit", model = 44, locked = false, price = 100},
	},
})
character({ -- Clint (aka Henry)
	id = "clint",
	name = "Clint (aka Henry)",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Outfit", model = 45, locked = false, price = 100},
		{id = "inmate", name = "Happy Volts Patient Gown", model = 154, locked = false, price = 250},
	},
})
character({ -- Gurney
	id = "gurney",
	name = "Gurney",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Outfit", model = 46, locked = false, price = 100},
		{id = "gs", name = "Gym Clothes", model = 197, locked = false, price = 250},
	},
})
character({ -- Omar
	id = "omar",
	name = "Omar",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Outfit", model = 47, locked = false, price = 100},
	},
})

-- Prefects
character({ -- Max MacTavish
	id = "max",
	name = "Max MacTavish",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 49, locked = false, price = 100},
	},
})
character({ -- Seth Kolbe
	id = "seth",
	name = "Seth Kolbe",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 50, locked = false, price = 100},
	},
})
character({ -- Edward Seymour II
	id = "edward",
	name = "Edward Seymour II",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 51, locked = false, price = 100},
	},
})
character({ -- Karl Branting
	id = "karl",
	name = "Karl Branting",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Academy Uniform", model = 52, locked = false, price = 100},
	},
})

-- School Faculty
character({ -- Mrs. Peabody
	id = "peabody",
	name = "Mrs. Peabody",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 54, locked = false, price = 100},
	},
})
character({ -- Mr. Burton
	id = "burton",
	name = "Mr. Burton",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 55, locked = false, price = 100},
		{id = "incognito", name = "Incognito Outfit", model = 229, locked = false, price = 100},
	},
})
character({ -- Mr. Luntz
	id = "luntz",
	name = "Mr. Luntz",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 56, locked = false, price = 100},
	},
})
character({ -- Lionel Galloway
	id = "galloway",
	name = "Lionel Galloway",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 57, locked = false, price = 100},
		{id = "asylum", name = "Happy Volts Patient Clothes", model = 129, locked = false, price = 100},
	},
})
character({ -- Edna
	id = "edna",
	name = "Edna",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 58, locked = false, price = 100},
		{id = "default", name = "Date Outfit", model = 221, locked = false, price = 100},
	},
})
character({ -- Miss Danvers
	id = "danvers",
	name = "Miss Danvers",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 59, locked = false, price = 100},
	},
})
character({ -- Mrs. McRae
	id = "mcrae",
	name = "Mrs. McRae",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 60, locked = false, price = 100},
	},
})
character({ -- Mr. Hattrick
	id = "hattrick",
	name = "Mr. Hattrick",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 61, locked = false, price = 100},
	},
})
character({ -- Mrs. Carvin
	id = "carvin",
	name = "Mrs. Carvin",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 62, locked = false, price = 100},
	},
})
character({ -- Deirdre Philips
	id = "philips",
	name = "Deirdre Philips",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 63, locked = false, price = 100},
	},
})
character({ -- Dr. Slawter
	id = "slawter",
	name = "Dr. Slawter",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 64, locked = false, price = 100},
	},
})
character({ -- Ralph Crabblesnitch
	id = "crabblesnitch",
	name = "Ralph Crabblesnitch",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 65, locked = false, price = 100},
	},
})
character({ -- Neil
	id = "neil",
	name = "Neil",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 126, locked = false, price = 100},
	},
})
character({ -- Mr. Matthews
	id = "matthews",
	name = "Mr. Matthews",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 248, locked = false, price = 100},
	},
})
character({ -- Miss Peters
	id = "peters",
	name = "Miss Peters",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 249, locked = false, price = 100},
	},
})
character({ -- Mr. Wiggins
	id = "wiggins",
	name = "Mr. Wiggins",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 151, locked = false, price = 100},
	},
})
character({ -- Dr. Watts
	id = "watts",
	name = "Dr. Watts",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 106, locked = false, price = 100},
	},
})
character({ -- Mr. Grant
	id = "grant",
	name = "Mr. Grant",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 87, locked = false, price = 100},
	},
})

-- Public Servants & Asylum/Nursing Home Residents
character({ -- Mr. Svenson
	id = "svenson",
	name = "Mr. Svenson",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Mailman Uniform", model = 127, locked = false, price = 100},
	},
})
character({ -- O'Rourke
	id = "orourke",
	name = "O'Rourke",
	icon = textures.unknown,
	description = "",
	starter = false, -- Locked due to ped's broken animations.
	locked = true, -- Locked due to ped's broken animations.
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Fireman Uniform", model = 82, locked = false, price = 100},
	},
})
character({ -- Officer Monson
	id = "monson",
	name = "Officer Monson",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Police Uniform", model = 83, locked = false, price = 100},
	},
})
character({ -- Officer Williams
	id = "williams",
	name = "Officer Williams",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Police Uniform", model = 97, locked = false, price = 100},
	},
})
character({ -- Officer Ivanovich
	id = "ivanovich",
	name = "Officer Ivanovich",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Police Uniform", model = 238, locked = false, price = 100},
	},
})
character({ -- Officer Morrison
	id = "morrison",
	name = "Officer Morrison",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Police Uniform", model = 234, locked = false, price = 100},
	},
})
character({ -- Theo
	id = "theo",
	name = "Theo",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Orderly Uniform", model = 53, locked = false, price = 100},
	},
})
character({ -- Gregory
	id = "gregory",
	name = "Gregory",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Orderly Uniform", model = 158, locked = false, price = 100},
	},
})
character({ -- Fenwick
	id = "fenwick",
	name = "Fenwick",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Happy Volts Patient Gown", model = 125, locked = false, price = 100},
	},
})
character({ -- Mr. Bubas
	id = "bubas",
	name = "Mr. Bubas",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Pajamas", model = 183, locked = false, price = 100},
	},
})
character({ -- Mr. Gordon
	id = "mrgordon",
	name = "Mr. Gordon",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Pajamas", model = 184, locked = false, price = 100},
	},
})
character({ -- Mrs. Lisburn
	id = "lisburn",
	name = "Mrs. Lisburn",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Pajamas", model = 185, locked = false, price = 100},
	},
})

-- Townsfolk
character({ -- Mr. Breckindale
	id = "breckindale",
	name = "Mr. Breckindale",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 100, locked = false, price = 100},
	},
})
character({ -- Mr. Doolin
	id = "doolin",
	name = "Mr. Doolin",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 101, locked = false, price = 100},
	},
})
character({ -- Dr. Bambillo
	id = "bambillo",
	name = "Dr. Bambillo",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 76, locked = false, price = 100},
	},
})
character({ -- Mr. Sullivan
	id = "sullivan",
	name = "Mr. Sullivan",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 77, locked = false, price = 100},
	},
})
character({ -- Miss Kopke
	id = "kopke",
	name = "Miss Kopke",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 78, locked = false, price = 100},
	},
})
character({ -- Ms. Rushinski
	id = "rushinski",
	name = "Ms. Rushinski",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 79, locked = false, price = 100},
	},
})
character({ -- Ms. Isaacs
	id = "isaacs",
	name = "Ms. Isaacs",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 80, locked = false, price = 100},
	},
})
character({ -- Bethany Jones
	id = "bethany",
	name = "Bethany Jones",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 81, locked = false, price = 100},
	},
})
character({ -- Mr. Martin
	id = "martin",
	name = "Mr. Martin",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 144, locked = false, price = 100},
	},
})
character({ -- Mr. Ramirez
	id = "ramirez",
	name = "Mr. Ramirez",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 148, locked = false, price = 100},
	},
})
character({ -- Mr. Huntingdon
	id = "huntingdon",
	name = "Mr. Huntingdon",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 149, locked = false, price = 100},
	},
})
character({ -- Alon Smith
	id = "alon",
	name = "Alon Smith",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 135, locked = false, price = 100},
	},
})
character({ -- Mihailovich
	id = "mihailovich",
	name = "Mihailovich",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 108, locked = false, price = 100},
	},
})
character({ -- Handy
	id = "handy",
	name = "Handy",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 157, locked = false, price = 100},
	},
})
character({ -- Osbourne
	id = "osbourne",
	name = "Osbourne",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 116, locked = false, price = 100},
	},
})
character({ -- Krakauer
	id = "krakauer",
	name = "Krakauer",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 131, locked = false, price = 100},
	},
})
character({ -- Miss Abby
	id = "abby",
	name = "Miss Abby",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 107, locked = false, price = 100},
	},
})

-- Shopkeepers
character({ -- Stan
	id = "stan",
	name = "Stan",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 156, locked = false, price = 100},
	},
})
character({ -- Mr. Oh
	id = "oh",
	name = "Mr. Oh",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 89, locked = false, price = 100},
	},
})
character({ -- Floyd
	id = "floyd",
	name = "Floyd",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 152, locked = false, price = 100},
	},
})
character({ -- Ian
	id = "ian",
	name = "Ian",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 124, locked = false, price = 100},
	},
})
character({ -- Nate
	id = "nate",
	name = "Nate",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 103, locked = false, price = 100},
	},
})
character({ -- Maria Theresa
	id = "maria",
	name = "Maria Theresa",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 120, locked = false, price = 100},
	},
})
character({ -- Mr. Moratti
	id = "moratti",
	name = "Mr. Moratti",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 132, locked = false, price = 100},
	},
})
character({ -- Betty
	id = "betty",
	name = "Betty",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 187, locked = false, price = 100},
	},
})
character({ -- Denny
	id = "denny",
	name = "Denny",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 128, locked = false, price = 100},
	},
})
character({ -- Zack Owens
	id = "zack",
	name = "Zack Owens",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 84, locked = false, price = 100},
	},
})
character({ -- Tobias Mason
	id = "tobias",
	name = "Tobias Mason",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 86, locked = false, price = 100},
	},
})
character({ -- Mr. Carmichael
	id = "carmichael",
	name = "Mr. Carmichael",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 104, locked = false, price = 100},
	},
})
character({ -- Nicky Charles
	id = "nicky",
	name = "Nicky Charles",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 105, locked = false, price = 100},
	},
})

-- Carnies
character({ -- Freeley
	id = "freeley",
	name = "Freeley",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 113, locked = false, price = 100},
	},
})
character({ -- Dorsey
	id = "dorsey",
	name = "Dorsey",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 114, locked = false, price = 100},
	},
})
character({ -- Hector
	id = "hector",
	name = "Hector",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 115, locked = false, price = 100},
	},
})
character({ -- Brandy
	id = "brandy",
	name = "Brandy",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 140, locked = false, price = 100},
	},
})
character({ -- Crystal
	id = "crystal",
	name = "Crystal",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 143, locked = false, price = 100},
	},
})
character({ -- Lightning
	id = "lightning",
	name = "Lightning",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 188, locked = false, price = 100},
	},
})
character({ -- Zeke
	id = "zeke",
	name = "Zeke",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 189, locked = false, price = 100},
	},
})
character({ -- Alfred
	id = "alfred",
	name = "Alfred",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 190, locked = false, price = 100},
	},
})
character({ -- Paris
	id = "paris",
	name = "Paris",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 191, locked = false, price = 100},
	},
})
character({ -- Courtney
	id = "courtney",
	name = "Courtney",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 192, locked = false, price = 100},
	},
})
character({ -- Delilah
	id = "delilah",
	name = "Delilah",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 193, locked = false, price = 100},
	},
})
character({ -- Drew
	id = "drew",
	name = "Drew",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Casual Clothes", model = 194, locked = false, price = 100},
	},
})

-- Industrial Workers
character({ -- Mr. Salvatore
	id = "salvatore",
	name = "Mr. Salvatore",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 236, locked = false, price = 100},
	},
})
character({ -- Mr. Buckingham
	id = "buckingham",
	name = "Mr. Buckingham",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 237, locked = false, price = 100},
	},
})
character({ -- McInnis
	id = "mcInnis",
	name = "McInnis",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 222, locked = false, price = 100},
	},
})
character({ -- Mr. Johnson
	id = "johnson",
	name = "Mr. Johnson",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 223, locked = false, price = 100},
	},
})
character({ -- Mr. Castillo
	id = "castillo",
	name = "Mr. Castillo",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 195, locked = false, price = 100},
	},
})
character({ -- Chuck
	id = "chuck",
	name = "Chuck",
	icon = textures.unknown,
	description = "",
	starter = true,
	locked = false,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Work Uniform", model = 123, locked = false, price = 100},
	},
})

-- Christmas Characters
character({ -- Tinsel
	id = "tinsel",
	name = "Tinsel",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Christmas Costume", model = 250, locked = false, price = 100},
	},
})
character({ -- Jolly
	id = "jolly",
	name = "Jolly",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Christmas Costume", model = 251, locked = false, price = 100},
	},
})
character({ -- Santa
	id = "santa",
	name = "Santa",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Christmas Costume", model = 253, locked = false, price = 100},
		{id = "altsanta", name = "Christmas Costume (Clean Shaven)", model = 254, locked = false, price = 100},
	},
})
character({ -- Rudy
	id = "rudy",
	name = "Rudy",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = false,
	price = 100,
	variants = {
		{id = "default", name = "Christmas Costume", model = 252, locked = false, price = 100},
	},
})

-- Animals & Others
character({ -- Punchingbag
	id = "punchingbag",
	name = "Punchingbag",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = true,
	price = 100,
	variants = {
		{id = "default", name = "Naked", model = 233, locked = false, price = 100},
	},
})
character({ -- George
	id = "george",
	name = "George",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = true,
	price = 100,
	variants = {
		{id = "default", name = "Naked", model = 136, locked = false, price = 100},
	},
})
character({ -- Chester
	id = "chester",
	name = "Chester",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = true,
	price = 100,
	variants = {
		{id = "default", name = "Naked", model = 141, locked = false, price = 100},
	},
})
character({ -- Fido
	id = "fido",
	name = "Fido",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = true,
	price = 100,
	variants = {
		{id = "default", name = "Naked", model = 219, locked = false, price = 100},
	},
})
character({ -- Buster
	id = "buster",
	name = "Buster",
	icon = textures.unknown,
	description = "",
	starter = false,
	locked = true,
	hidden = true,
	price = 100,
	variants = {
		{id = "default", name = "Naked", model = 220, locked = false, price = 100},
	},
})
