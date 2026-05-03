SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

ns.UNIT_GROUP = {
	PLAYER = "player",
	TARGET = "target",
	FOCUS = "focus",
	PET = "pet",
	PARTY = "party",
	PARTY_PETS = "partyPets",
	RAID = "raid",
	RAID_PETS = "raidPets",
	BOSS = "boss",
	ARENA = "arena",
	ARENA_PETS = "arenaPets",
}

ns.UNIT_GROUP_ORDER = {
	ns.UNIT_GROUP.PLAYER,
	ns.UNIT_GROUP.TARGET,
	ns.UNIT_GROUP.FOCUS,
	ns.UNIT_GROUP.PET,
	ns.UNIT_GROUP.PARTY,
	ns.UNIT_GROUP.PARTY_PETS,
	ns.UNIT_GROUP.RAID,
	ns.UNIT_GROUP.RAID_PETS,
	ns.UNIT_GROUP.BOSS,
	ns.UNIT_GROUP.ARENA,
	ns.UNIT_GROUP.ARENA_PETS,
}

ns.UNIT_GROUP_LABEL = {
	player = "Player",
	target = "Target",
	focus = "Focus",
	pet = "Pet",
	party = "Party",
	partyPets = "Party Pets",
	raid = "Raid",
	raidPets = "Raid Pets",
	boss = "Bosses",
	arena = "Arena",
	arenaPets = "Arena Pets",
}

ns.CONTAINER_LABEL = {
	ENEMY = "Enemy/Boss/Arena",
}

ns.STANDALONE_CONTAINER_KEY = {
	ENEMY = "enemy",
}

ns.UNIT_GROUP_CONTAINER = {
	player = "Player",
	target = "Target",
	focus = "Focus",
	pet = "Pet",
	party = "Party",
	partyPets = "Party Pets",
	raid = "Raid",
	raidPets = "Raid Pets",
	boss = ns.CONTAINER_LABEL.ENEMY,
	arena = ns.CONTAINER_LABEL.ENEMY,
	arenaPets = ns.CONTAINER_LABEL.ENEMY,
}

ns.UNIT_GROUP_SUPPORTS_ATTACHED = {
	player = true,
	target = true,
	focus = true,
	pet = true,
	party = true,
	partyPets = true,
	raid = true,
	raidPets = true,
	boss = true,
	arena = true,
	arenaPets = true,
}

function ns.UnitGroupSupportsAttached(groupKey)
	return ns.UNIT_GROUP_SUPPORTS_ATTACHED[groupKey] == true
end

function ns.GetUnitGroupDisplayModes(groupKey)
	if ns.UnitGroupSupportsAttached(groupKey) then
		return ns.DISPLAY_MODE_ORDER
	end
	return ns.STANDALONE_DISPLAY_MODE_ORDER
end

ns.UNIT_GROUP_DEFINITIONS = {
	player = {
		tokens = { "player" },
	},
	target = {
		tokens = { "target" },
	},
	focus = {
		tokens = { "focus" },
	},
	pet = {
		tokens = { "pet" },
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
}

ns.UNIT_LABEL = {
	player = "Player",
	target = "Target",
	focus = "Focus",
	pet = "Pet",
}

ns.ANCHOR_DEFAULTS = {
	player = {
		point = ns.UI.ANCHOR_TOPLEFT,
		relativePoint = ns.UI.ANCHOR_BOTTOMLEFT,
		x = 0,
		y = -6,
	},
	target = {
		point = ns.UI.ANCHOR_TOPLEFT,
		relativePoint = ns.UI.ANCHOR_BOTTOMLEFT,
		x = 0,
		y = -6,
	},
	focus = {
		point = ns.UI.ANCHOR_TOPLEFT,
		relativePoint = ns.UI.ANCHOR_BOTTOMLEFT,
		x = 0,
		y = -6,
	},
	pet = {
		point = ns.UI.ANCHOR_TOPLEFT,
		relativePoint = ns.UI.ANCHOR_BOTTOMLEFT,
		x = 0,
		y = -6,
	},
}

ns.STANDALONE_DEFAULTS = {
	player = {
		point = ns.UI.ANCHOR_CENTER,
		relativePoint = ns.UI.ANCHOR_CENTER,
		x = -180,
		y = 120,
	},
	target = {
		point = ns.UI.ANCHOR_CENTER,
		relativePoint = ns.UI.ANCHOR_CENTER,
		x = -180,
		y = 70,
	},
	focus = {
		point = ns.UI.ANCHOR_CENTER,
		relativePoint = ns.UI.ANCHOR_CENTER,
		x = -180,
		y = 20,
	},
	pet = {
		point = ns.UI.ANCHOR_CENTER,
		relativePoint = ns.UI.ANCHOR_CENTER,
		x = -180,
		y = -30,
	},
	party = {
		point = ns.UI.ANCHOR_CENTER,
		relativePoint = ns.UI.ANCHOR_CENTER,
		x = -40,
		y = 120,
	},
	partyPets = {
		point = ns.UI.ANCHOR_CENTER,
		relativePoint = ns.UI.ANCHOR_CENTER,
		x = -40,
		y = 40,
	},
	raid = {
		point = ns.UI.ANCHOR_CENTER,
		relativePoint = ns.UI.ANCHOR_CENTER,
		x = 120,
		y = 120,
	},
	raidPets = {
		point = ns.UI.ANCHOR_CENTER,
		relativePoint = ns.UI.ANCHOR_CENTER,
		x = 120,
		y = 40,
	},
	enemy = {
		point = ns.UI.ANCHOR_CENTER,
		relativePoint = ns.UI.ANCHOR_CENTER,
		x = 120,
		y = -40,
	},
}
