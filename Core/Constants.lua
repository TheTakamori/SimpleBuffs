SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

ns.ADDON_NAME = "SimpleBuffs"
ns.VERSION = "1.5.0"
ns.DB_VERSION = 9
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

ns.AURA_TYPE_SHORT_LABEL = {
	buff = "Buff",
	debuff = "Debuff",
}

ns.GROUP_SUBTAB = {
	BUFF = ns.AURA_TYPE.BUFF,
	DEBUFF = ns.AURA_TYPE.DEBUFF,
	MANAGE = "manage",
}

ns.GROUP_SUBTAB_ORDER = {
	ns.GROUP_SUBTAB.BUFF,
	ns.GROUP_SUBTAB.DEBUFF,
	ns.GROUP_SUBTAB.MANAGE,
}

ns.GROUP_SUBTAB_LABEL = {
	buff = ns.AURA_LABEL.buff,
	debuff = ns.AURA_LABEL.debuff,
	manage = "Manage Auras",
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
	NAME_ONLY = "NameOnly",
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

ns.AURA_STYLE = {
	ICON = "icon",
	BAR = "bar",
}

ns.AURA_STYLE_ORDER = {
	ns.AURA_STYLE.ICON,
	ns.AURA_STYLE.BAR,
}

ns.AURA_STYLE_LABEL = {
	icon = "Icons",
	bar = "Bar Stack",
}

ns.BAR_SORT = {
	ALPHA_ASC = "alpha-asc",
	ALPHA_DESC = "alpha-desc",
	TIME_LEFT_ASC = "time-left-asc",
	TIME_LEFT_DESC = "time-left-desc",
	MAX_DURATION_ASC = "max-duration-asc",
	MAX_DURATION_DESC = "max-duration-desc",
}

ns.BAR_SORT_ORDER = {
	ns.BAR_SORT.ALPHA_ASC,
	ns.BAR_SORT.ALPHA_DESC,
	ns.BAR_SORT.TIME_LEFT_ASC,
	ns.BAR_SORT.TIME_LEFT_DESC,
	ns.BAR_SORT.MAX_DURATION_ASC,
	ns.BAR_SORT.MAX_DURATION_DESC,
}

ns.BAR_SORT_LABEL = {
	["alpha-asc"] = "A-Z",
	["alpha-desc"] = "Z-A",
	["time-left-asc"] = "Time Left: Short to Long",
	["time-left-desc"] = "Time Left: Long to Short",
	["max-duration-asc"] = "Max Duration: Short to Long",
	["max-duration-desc"] = "Max Duration: Long to Short",
}

ns.MANAGE_FILTER = {
	BOTH = "both",
	BUFF = ns.AURA_TYPE.BUFF,
	DEBUFF = ns.AURA_TYPE.DEBUFF,
}

ns.MANAGE_FILTER_ORDER = {
	ns.MANAGE_FILTER.BOTH,
	ns.MANAGE_FILTER.BUFF,
	ns.MANAGE_FILTER.DEBUFF,
}

ns.MANAGE_FILTER_LABEL = {
	both = "Both",
	buff = "Buffs Only",
	debuff = "Debuffs Only",
}

ns.MANAGE_SORT = {
	ALPHA_ASC = "alpha-asc",
	ALPHA_DESC = "alpha-desc",
	FIRST_SEEN_ASC = "first-seen-asc",
	FIRST_SEEN_DESC = "first-seen-desc",
	LAST_SEEN_ASC = "last-seen-asc",
	LAST_SEEN_DESC = "last-seen-desc",
}

ns.MANAGE_SORT_ORDER = {
	ns.MANAGE_SORT.ALPHA_ASC,
	ns.MANAGE_SORT.ALPHA_DESC,
	ns.MANAGE_SORT.FIRST_SEEN_ASC,
	ns.MANAGE_SORT.FIRST_SEEN_DESC,
	ns.MANAGE_SORT.LAST_SEEN_ASC,
	ns.MANAGE_SORT.LAST_SEEN_DESC,
}

ns.MANAGE_SORT_LABEL = {
	["alpha-asc"] = "A-Z",
	["alpha-desc"] = "Z-A",
	["first-seen-asc"] = "First Seen: Oldest First",
	["first-seen-desc"] = "First Seen: Newest First",
	["last-seen-asc"] = "Last Seen: Oldest First",
	["last-seen-desc"] = "Last Seen: Newest First",
}
