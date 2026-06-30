-- SYNC+ | ai configuration | Xx_Yubari_xX
--  this file is used by sv_ai.lua and cl_ai.lua

-- all tasks in here idiosyncratically represent normal ped tasks in the game
-- that means each task is based on a normal game task but scripted individually

-- to add a new task, you must do the following
--  1. add a new task in gTasks (this file)
--  2. add a server api function (sv_ai.lua)
--  3. add client behavior for it (cl_ai.lua)

-- utility:
TASK = setmetatable({},{__index = function(_,id)
	for index,task in ipairs(gAiTasks) do
		if task.id == id then
			return index
		end
	end
	error("invalid task",2)
end})

-- trees:
gAiTrees = {
	-- the index within this table is used to sync trees
	-- if a tree is not here then it is not supported
	{"/GLOBAL/AI","AI.ACT"},
	{"/GLOBAL/AI_DOG","AI_DOG.ACT"},
	{"/GLOBAL/AI_RAT","AI_RAT.ACT"},
	{"/GLOBAL/PLAYERAI","PLAYERAI.ACT"},
}

-- tasks:
gAiTasks = {
	-- the index within this table is used to sync tasks
	{
		id = "IDLE",
		nodes = {
			"/GLOBAL/AI/GENERALOBJECTIVES/IDLE",
			"/GLOBAL/AI_DOG/DUMMYIDLE",
			"/GLOBAL/AI_RAT/DUMMYIDLE",
			"/GLOBAL/PLAYERAI/DEFAULT",
		},
	},
	{
		id = "WANDER",
		nodes = {
			"/GLOBAL/AI/GENERALOBJECTIVES/WANDER",
			"/GLOBAL/AI_DOG/GENERALOBJECTIVES/WANDER",
			"/GLOBAL/AI_RAT/RATLOCO",
		},
	},
	{
		id = "ATTACK",
		nodes = {
			"/GLOBAL/AI/COMBAT",
			"/GLOBAL/AI_DOG/COMBAT",
		},
	},
	{
		id = "FLEE",
		nodes = {
			"/GLOBAL/AI/GENERALOBJECTIVES/FLEEOBJECTIVE",
			"/GLOBAL/AI_DOG/GENERALOBJECTIVES/FLEEOBJECTIVE",
		},
	},
	{
		id = "MOVE_XYZ",
		nodes = {
			"/GLOBAL/AI/GENERALOBJECTIVES/MOVEOBJECTIVE",
			"/GLOBAL/AI_DOG/GENERALOBJECTIVES/MOVEOBJECTIVE",
			"/GLOBAL/PLAYERAI/OBJECTIVES/MOVEOBJECTIVE",
		},
	},
	{
		id = "FACE_HEADING",
		nodes = {
			"/GLOBAL/AI/GENERALOBJECTIVES/FACEOBJECTIVE",
			"/GLOBAL/AI_DOG/GENERALOBJECTIVES/FACEOBJECTIVE",
			"/GLOBAL/PLAYERAI/OBJECTIVES/FACEOBJECTIVE",
		},
	},
}
