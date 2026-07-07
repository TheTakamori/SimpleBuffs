SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local DEFAULT_STYLE = {
	iconSize = 28,
	spacing = 3,
	maxAuras = 12,
	scale = 1,
	showCountdown = true,
	showSwipe = true,
	showCounts = true,
	showIcon = true,
	style = ns.AURA_STYLE.ICON,
	barWidth = 160,
	barSort = ns.BAR_SORT.ALPHA_ASC,
}

local function default_aura_options()
	return {
		layout = ns.LAYOUT.HORIZONTAL,
		sortRule = ns.SORT_RULE.EXPIRATION,
		filterMode = ns.FILTER_MODE.ALL,
		iconSize = DEFAULT_STYLE.iconSize,
		spacing = DEFAULT_STYLE.spacing,
		maxAuras = DEFAULT_STYLE.maxAuras,
		scale = DEFAULT_STYLE.scale,
		showCountdown = DEFAULT_STYLE.showCountdown,
		showSwipe = DEFAULT_STYLE.showSwipe,
		showCounts = DEFAULT_STYLE.showCounts,
		showIcon = DEFAULT_STYLE.showIcon,
		style = DEFAULT_STYLE.style,
		barWidth = DEFAULT_STYLE.barWidth,
		barSort = DEFAULT_STYLE.barSort,
	}
end

local function default_unit_options(attachedPosition)
	return {
		buff = true,
		debuff = true,
		mode = ns.DISPLAY_MODE.ATTACHED,
		attachedPosition = attachedPosition or ns.ATTACHED_POSITION.BELOW,
		aura = {
			buff = default_aura_options(),
			debuff = default_aura_options(),
		},
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
		iconSize = DEFAULT_STYLE.iconSize,
		spacing = DEFAULT_STYLE.spacing,
		rowSpacing = 5,
		maxAuras = DEFAULT_STYLE.maxAuras,
		layout = ns.LAYOUT.HORIZONTAL,
		sortRule = ns.SORT_RULE.EXPIRATION,
		filterMode = ns.FILTER_MODE.ALL,
		showCountdown = DEFAULT_STYLE.showCountdown,
		showSwipe = DEFAULT_STYLE.showSwipe,
		showCounts = DEFAULT_STYLE.showCounts,
		showIcon = DEFAULT_STYLE.showIcon,
		scale = DEFAULT_STYLE.scale,
		style = DEFAULT_STYLE.style,
		barWidth = DEFAULT_STYLE.barWidth,
		barSort = DEFAULT_STYLE.barSort,
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
