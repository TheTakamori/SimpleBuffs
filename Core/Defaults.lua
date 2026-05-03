SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local function default_unit_options(attachedPosition)
	return {
		buff = true,
		debuff = true,
		mode = ns.DISPLAY_MODE.ATTACHED,
		attachedPosition = attachedPosition or ns.ATTACHED_POSITION.BELOW,
		layout = ns.LAYOUT.HORIZONTAL,
		sortRule = ns.SORT_RULE.EXPIRATION,
		filterMode = ns.FILTER_MODE.ALL,
		iconSize = 28,
		spacing = 3,
		maxAuras = 12,
		scale = 1,
		showCountdown = true,
		showSwipe = true,
		showCounts = true,
	}
end

local function copy_position(position)
	return {
		point = position.point,
		relativePoint = position.relativePoint,
		x = position.x,
		y = position.y,
	}
end

ns.DEFAULTS = {
	version = ns.DB_VERSION,
	locked = false,
	minimap = {
		angle = 225,
		hide = false,
	},
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
		scale = 1,
	},
	units = {
		player = default_unit_options(),
		target = default_unit_options(),
		focus = default_unit_options(),
		pet = default_unit_options(),
		party = default_unit_options(ns.ATTACHED_POSITION.RIGHT),
		partyPets = default_unit_options(ns.ATTACHED_POSITION.RIGHT),
		raid = default_unit_options(),
		raidPets = default_unit_options(),
		boss = default_unit_options(),
		arena = default_unit_options(),
		arenaPets = default_unit_options(),
	},
	attached = {
		focus = copy_position(ns.ANCHOR_DEFAULTS.focus),
		pet = copy_position(ns.ANCHOR_DEFAULTS.pet),
		player = copy_position(ns.ANCHOR_DEFAULTS.player),
		target = copy_position(ns.ANCHOR_DEFAULTS.target),
	},
	standalone = {
		player = copy_position(ns.STANDALONE_DEFAULTS.player),
		target = copy_position(ns.STANDALONE_DEFAULTS.target),
		focus = copy_position(ns.STANDALONE_DEFAULTS.focus),
		pet = copy_position(ns.STANDALONE_DEFAULTS.pet),
		party = copy_position(ns.STANDALONE_DEFAULTS.party),
		partyPets = copy_position(ns.STANDALONE_DEFAULTS.partyPets),
		raid = copy_position(ns.STANDALONE_DEFAULTS.raid),
		raidPets = copy_position(ns.STANDALONE_DEFAULTS.raidPets),
		enemy = copy_position(ns.STANDALONE_DEFAULTS.enemy),
	},
}
