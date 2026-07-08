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
		tokens = { ns.UNIT_TOKEN.PLAYER },
	},
	target = {
		tokens = { ns.UNIT_TOKEN.TARGET },
	},
	focus = {
		tokens = { ns.UNIT_TOKEN.FOCUS },
	},
	pet = {
		tokens = { ns.UNIT_TOKEN.PET },
	},
	party = {
		prefix = ns.UNIT_TOKEN.PARTY_PREFIX,
		count = ns.GROUP_SIZE.PARTY,
	},
	partyPets = {
		prefix = ns.UNIT_TOKEN.PARTY_PET_PREFIX,
		count = ns.GROUP_SIZE.PARTY,
	},
	raid = {
		prefix = ns.UNIT_TOKEN.RAID_PREFIX,
		count = ns.GROUP_SIZE.RAID,
	},
	raidPets = {
		prefix = ns.UNIT_TOKEN.RAID_PET_PREFIX,
		count = ns.GROUP_SIZE.RAID,
	},
	boss = {
		prefix = ns.UNIT_TOKEN.BOSS_PREFIX,
		count = ns.GROUP_SIZE.BOSS,
	},
	arena = {
		prefix = ns.UNIT_TOKEN.ARENA_PREFIX,
		count = ns.GROUP_SIZE.ARENA,
	},
	arenaPets = {
		prefix = ns.UNIT_TOKEN.ARENA_PET_PREFIX,
		count = ns.GROUP_SIZE.ARENA,
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

-- Base screen position per standalone container group, before Buffs/Debuffs
-- are split into independently-movable containers below.
local BASE_STANDALONE_DEFAULTS = {
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

-- How far below its Buffs counterpart a Debuffs container defaults to, so
-- the two don't spawn stacked exactly on top of each other before the user
-- drags them apart.
local STANDALONE_DEBUFF_DEFAULT_Y_OFFSET = -70

ns.STANDALONE_DEFAULTS = {}
for baseKey, position in pairs(BASE_STANDALONE_DEFAULTS) do
	ns.STANDALONE_DEFAULTS[baseKey .. ns.STANDALONE_CONTAINER_KEY_SEPARATOR .. ns.AURA_TYPE.BUFF] = {
		point = position.point,
		relativePoint = position.relativePoint,
		x = position.x,
		y = position.y,
	}
	ns.STANDALONE_DEFAULTS[baseKey .. ns.STANDALONE_CONTAINER_KEY_SEPARATOR .. ns.AURA_TYPE.DEBUFF] = {
		point = position.point,
		relativePoint = position.relativePoint,
		x = position.x,
		y = position.y + STANDALONE_DEBUFF_DEFAULT_Y_OFFSET,
	}
end
