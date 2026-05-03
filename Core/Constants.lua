SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

ns.ADDON_NAME = "SimpleBuffs"
ns.VERSION = "1.1.2"
ns.DB_VERSION = 5
ns.SELECT_COUNT = "#"

ns.SLASH_COMMANDS = {
	"/sbuff",
}

ns.SLASH_COMMAND = {
	OPTIONS = "options",
	CONFIG = "config",
	LOCK = "lock",
	UNLOCK = "unlock",
	RESET = "reset",
	HELP = "help",
}

ns.AURA_TYPE = {
	BUFF = "buff",
	DEBUFF = "debuff",
}

ns.AURA_TYPE_ORDER = {
	ns.AURA_TYPE.BUFF,
	ns.AURA_TYPE.DEBUFF,
}

ns.AURA_FILTER = {
	buff = "HELPFUL",
	debuff = "HARMFUL",
}

ns.AURA_LABEL = {
	buff = "Buffs",
	debuff = "Debuffs",
}

ns.DISPLAY_MODE = {
	ATTACHED = "attached",
	STANDALONE = "standalone",
	BOTH = "both",
}

ns.DISPLAY_MODE_ORDER = {
	ns.DISPLAY_MODE.ATTACHED,
	ns.DISPLAY_MODE.STANDALONE,
	ns.DISPLAY_MODE.BOTH,
}

ns.STANDALONE_DISPLAY_MODE_ORDER = {
	ns.DISPLAY_MODE.STANDALONE,
}

ns.DISPLAY_MODE_LABEL = {
	attached = "Attached",
	standalone = "Standalone",
	both = "Both",
}

ns.ATTACHED_POSITION = {
	ABOVE = "above",
	BELOW = "below",
	RIGHT = "right",
	LEFT = "left",
}

ns.ATTACHED_POSITION_ORDER = {
	ns.ATTACHED_POSITION.ABOVE,
	ns.ATTACHED_POSITION.BELOW,
	ns.ATTACHED_POSITION.RIGHT,
	ns.ATTACHED_POSITION.LEFT,
}

ns.ATTACHED_POSITION_LABEL = {
	above = "Above",
	below = "Below",
	right = "Right Hand",
	left = "Left Hand",
}

ns.LAYOUT = {
	HORIZONTAL = "horizontal",
	VERTICAL = "vertical",
	HORIZONTAL_REVERSE = "horizontal-reverse",
	VERTICAL_REVERSE = "vertical-reverse",
}

ns.LAYOUT_ORDER = {
	ns.LAYOUT.HORIZONTAL,
	ns.LAYOUT.VERTICAL,
	ns.LAYOUT.HORIZONTAL_REVERSE,
	ns.LAYOUT.VERTICAL_REVERSE,
}

ns.LAYOUT_LABEL = {
	horizontal = "Horizontal",
	vertical = "Vertical",
	["horizontal-reverse"] = "Horizontal Reverse",
	["vertical-reverse"] = "Vertical Reverse",
}

ns.SORT_RULE = {
	DEFAULT = "Default",
	EXPIRATION = "Expiration",
	EXPIRATION_ONLY = "ExpirationOnly",
	UNSORTED = "Unsorted",
}

ns.SORT_RULE_ORDER = {
	ns.SORT_RULE.DEFAULT,
	ns.SORT_RULE.EXPIRATION,
	ns.SORT_RULE.EXPIRATION_ONLY,
	ns.SORT_RULE.UNSORTED,
}

ns.SORT_RULE_LABEL = {
	Default = "Default",
	Expiration = "Expiration",
	ExpirationOnly = "Expiration Only",
	Unsorted = "Unsorted",
}

ns.FILTER_MODE = {
	ALL = "all",
	PLAYER = "player",
	IMPORTANT = "important",
	CROWD_CONTROL = "crowd-control",
}

ns.FILTER_MODE_ORDER = {
	ns.FILTER_MODE.ALL,
	ns.FILTER_MODE.PLAYER,
	ns.FILTER_MODE.IMPORTANT,
	ns.FILTER_MODE.CROWD_CONTROL,
}

ns.FILTER_MODE_LABEL = {
	all = "All",
	player = "Player/Pet Cast",
	important = "Important",
	["crowd-control"] = "Crowd Control",
}
