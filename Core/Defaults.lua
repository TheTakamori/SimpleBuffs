SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

ns.DEFAULTS = {
	version = ns.DB_VERSION,
	locked = false,
	minimap = {
		angle = 225,
		hide = false,
	},
	displayMode = ns.DISPLAY_MODE.ATTACHED,
	appearance = {
		iconSize = 28,
		spacing = 3,
		rowSpacing = 5,
		maxAuras = 12,
		layout = ns.LAYOUT.HORIZONTAL,
		sortRule = ns.SORT_RULE.EXPIRATION,
		filterMode = ns.FILTER_MODE.ALL,
		showCountdown = true,
		showSwipe = true,
		showCounts = true,
		showTitles = false,
		scale = 1,
	},
	units = {
		core = {
			enabled = true,
			buff = true,
			debuff = true,
		},
		party = {
			enabled = true,
			buff = true,
			debuff = true,
		},
		partyPets = {
			enabled = true,
			buff = true,
			debuff = true,
		},
		raid = {
			enabled = true,
			buff = true,
			debuff = true,
		},
		raidPets = {
			enabled = true,
			buff = true,
			debuff = true,
		},
		boss = {
			enabled = true,
			buff = true,
			debuff = true,
		},
		arena = {
			enabled = true,
			buff = true,
			debuff = true,
		},
		arenaPets = {
			enabled = true,
			buff = true,
			debuff = true,
		},
		nameplates = {
			enabled = true,
			buff = true,
			debuff = true,
		},
	},
	attached = {
		focus = {
			point = ns.ANCHOR_DEFAULTS.focus.point,
			relativePoint = ns.ANCHOR_DEFAULTS.focus.relativePoint,
			x = ns.ANCHOR_DEFAULTS.focus.x,
			y = ns.ANCHOR_DEFAULTS.focus.y,
		},
		pet = {
			point = ns.ANCHOR_DEFAULTS.pet.point,
			relativePoint = ns.ANCHOR_DEFAULTS.pet.relativePoint,
			x = ns.ANCHOR_DEFAULTS.pet.x,
			y = ns.ANCHOR_DEFAULTS.pet.y,
		},
		player = {
			point = ns.ANCHOR_DEFAULTS.player.point,
			relativePoint = ns.ANCHOR_DEFAULTS.player.relativePoint,
			x = ns.ANCHOR_DEFAULTS.player.x,
			y = ns.ANCHOR_DEFAULTS.player.y,
		},
		target = {
			point = ns.ANCHOR_DEFAULTS.target.point,
			relativePoint = ns.ANCHOR_DEFAULTS.target.relativePoint,
			x = ns.ANCHOR_DEFAULTS.target.x,
			y = ns.ANCHOR_DEFAULTS.target.y,
		},
	},
	standalone = {
		core = {
			point = ns.STANDALONE_DEFAULTS.core.point,
			relativePoint = ns.STANDALONE_DEFAULTS.core.relativePoint,
			x = ns.STANDALONE_DEFAULTS.core.x,
			y = ns.STANDALONE_DEFAULTS.core.y,
		},
		party = {
			point = ns.STANDALONE_DEFAULTS.party.point,
			relativePoint = ns.STANDALONE_DEFAULTS.party.relativePoint,
			x = ns.STANDALONE_DEFAULTS.party.x,
			y = ns.STANDALONE_DEFAULTS.party.y,
		},
		partyPets = {
			point = ns.STANDALONE_DEFAULTS.partyPets.point,
			relativePoint = ns.STANDALONE_DEFAULTS.partyPets.relativePoint,
			x = ns.STANDALONE_DEFAULTS.partyPets.x,
			y = ns.STANDALONE_DEFAULTS.partyPets.y,
		},
		raid = {
			point = ns.STANDALONE_DEFAULTS.raid.point,
			relativePoint = ns.STANDALONE_DEFAULTS.raid.relativePoint,
			x = ns.STANDALONE_DEFAULTS.raid.x,
			y = ns.STANDALONE_DEFAULTS.raid.y,
		},
		raidPets = {
			point = ns.STANDALONE_DEFAULTS.raidPets.point,
			relativePoint = ns.STANDALONE_DEFAULTS.raidPets.relativePoint,
			x = ns.STANDALONE_DEFAULTS.raidPets.x,
			y = ns.STANDALONE_DEFAULTS.raidPets.y,
		},
		enemy = {
			point = ns.STANDALONE_DEFAULTS.enemy.point,
			relativePoint = ns.STANDALONE_DEFAULTS.enemy.relativePoint,
			x = ns.STANDALONE_DEFAULTS.enemy.x,
			y = ns.STANDALONE_DEFAULTS.enemy.y,
		},
		nameplates = {
			point = ns.STANDALONE_DEFAULTS.nameplates.point,
			relativePoint = ns.STANDALONE_DEFAULTS.nameplates.relativePoint,
			x = ns.STANDALONE_DEFAULTS.nameplates.x,
			y = ns.STANDALONE_DEFAULTS.nameplates.y,
		},
	},
}
