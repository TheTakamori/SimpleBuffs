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
		player = {
			buff = true,
			debuff = true,
		},
		target = {
			buff = true,
			debuff = true,
		},
		focus = {
			buff = true,
			debuff = true,
		},
		pet = {
			buff = true,
			debuff = true,
		},
		vehicle = {
			buff = true,
			debuff = true,
		},
		party = {
			buff = true,
			debuff = true,
		},
		partyPets = {
			buff = true,
			debuff = true,
		},
		raid = {
			buff = true,
			debuff = true,
		},
		raidPets = {
			buff = true,
			debuff = true,
		},
		boss = {
			buff = true,
			debuff = true,
		},
		arena = {
			buff = true,
			debuff = true,
		},
		arenaPets = {
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
		player = {
			point = ns.STANDALONE_DEFAULTS.player.point,
			relativePoint = ns.STANDALONE_DEFAULTS.player.relativePoint,
			x = ns.STANDALONE_DEFAULTS.player.x,
			y = ns.STANDALONE_DEFAULTS.player.y,
		},
		target = {
			point = ns.STANDALONE_DEFAULTS.target.point,
			relativePoint = ns.STANDALONE_DEFAULTS.target.relativePoint,
			x = ns.STANDALONE_DEFAULTS.target.x,
			y = ns.STANDALONE_DEFAULTS.target.y,
		},
		focus = {
			point = ns.STANDALONE_DEFAULTS.focus.point,
			relativePoint = ns.STANDALONE_DEFAULTS.focus.relativePoint,
			x = ns.STANDALONE_DEFAULTS.focus.x,
			y = ns.STANDALONE_DEFAULTS.focus.y,
		},
		pet = {
			point = ns.STANDALONE_DEFAULTS.pet.point,
			relativePoint = ns.STANDALONE_DEFAULTS.pet.relativePoint,
			x = ns.STANDALONE_DEFAULTS.pet.x,
			y = ns.STANDALONE_DEFAULTS.pet.y,
		},
		vehicle = {
			point = ns.STANDALONE_DEFAULTS.vehicle.point,
			relativePoint = ns.STANDALONE_DEFAULTS.vehicle.relativePoint,
			x = ns.STANDALONE_DEFAULTS.vehicle.x,
			y = ns.STANDALONE_DEFAULTS.vehicle.y,
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
	},
}
