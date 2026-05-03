SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

ns.UNIT_GROUP = {
	CORE = "core",
	PARTY = "party",
	PARTY_PETS = "partyPets",
	RAID = "raid",
	RAID_PETS = "raidPets",
	BOSS = "boss",
	ARENA = "arena",
	ARENA_PETS = "arenaPets",
	NAMEPLATES = "nameplates",
}

ns.UNIT_GROUP_ORDER = {
	ns.UNIT_GROUP.CORE,
	ns.UNIT_GROUP.PARTY,
	ns.UNIT_GROUP.PARTY_PETS,
	ns.UNIT_GROUP.RAID,
	ns.UNIT_GROUP.RAID_PETS,
	ns.UNIT_GROUP.BOSS,
	ns.UNIT_GROUP.ARENA,
	ns.UNIT_GROUP.ARENA_PETS,
	ns.UNIT_GROUP.NAMEPLATES,
}

ns.UNIT_GROUP_LABEL = {
	core = "Core",
	party = "Party",
	partyPets = "Party Pets",
	raid = "Raid",
	raidPets = "Raid Pets",
	boss = "Bosses",
	arena = "Arena",
	arenaPets = "Arena Pets",
	nameplates = "Nameplates",
}

ns.UNIT_GROUP_CONTAINER = {
	core = "Player/Core",
	party = "Party",
	partyPets = "Party Pets",
	raid = "Raid",
	raidPets = "Raid Pets",
	boss = "Enemy/Boss/Arena",
	arena = "Enemy/Boss/Arena",
	arenaPets = "Enemy/Boss/Arena",
	nameplates = "Nameplates",
}

ns.CORE_UNITS = {
	"player",
	"target",
	"focus",
	"pet",
	"vehicle",
	"mouseover",
}

ns.UNIT_GROUP_DEFINITIONS = {
	core = {
		tokens = ns.CORE_UNITS,
	},
	party = {
		prefix = "party",
		count = 4,
	},
	partyPets = {
		prefix = "partypet",
		count = 4,
	},
	raid = {
		prefix = "raid",
		count = 40,
	},
	raidPets = {
		prefix = "raidpet",
		count = 40,
	},
	boss = {
		prefix = "boss",
		count = 8,
	},
	arena = {
		prefix = "arena",
		count = 5,
	},
	arenaPets = {
		prefix = "arenapet",
		count = 5,
	},
	nameplates = {
		prefix = "nameplate",
		count = 40,
		dynamic = true,
	},
}

ns.UNIT_LABEL = {
	player = "Player",
	target = "Target",
	focus = "Focus",
	pet = "Pet",
	vehicle = "Vehicle",
	mouseover = "Mouseover",
}

ns.ANCHOR_DEFAULTS = {
	player = {
		point = "TOPLEFT",
		relativePoint = "BOTTOMLEFT",
		x = 0,
		y = -6,
	},
	target = {
		point = "TOPLEFT",
		relativePoint = "BOTTOMLEFT",
		x = 0,
		y = -6,
	},
	focus = {
		point = "TOPLEFT",
		relativePoint = "BOTTOMLEFT",
		x = 0,
		y = -6,
	},
	pet = {
		point = "TOPLEFT",
		relativePoint = "BOTTOMLEFT",
		x = 0,
		y = -6,
	},
}

ns.STANDALONE_DEFAULTS = {
	core = {
		point = "CENTER",
		relativePoint = "CENTER",
		x = -180,
		y = 120,
	},
	party = {
		point = "CENTER",
		relativePoint = "CENTER",
		x = -180,
		y = 40,
	},
	partyPets = {
		point = "CENTER",
		relativePoint = "CENTER",
		x = -180,
		y = -40,
	},
	raid = {
		point = "CENTER",
		relativePoint = "CENTER",
		x = 120,
		y = 120,
	},
	raidPets = {
		point = "CENTER",
		relativePoint = "CENTER",
		x = 120,
		y = 40,
	},
	enemy = {
		point = "CENTER",
		relativePoint = "CENTER",
		x = 120,
		y = -40,
	},
	nameplates = {
		point = "CENTER",
		relativePoint = "CENTER",
		x = 120,
		y = -120,
	},
}
