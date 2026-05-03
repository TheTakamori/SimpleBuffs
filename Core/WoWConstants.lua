SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

ns.DB_KEY = {
	ICON_SIZE = "iconSize",
	SPACING = "spacing",
	ROW_SPACING = "rowSpacing",
	MAX_AURAS = "maxAuras",
	SCALE = "scale",
	LAYOUT = "layout",
	SORT_RULE = "sortRule",
	FILTER_MODE = "filterMode",
	SHOW_COUNTDOWN = "showCountdown",
	SHOW_SWIPE = "showSwipe",
	SHOW_COUNTS = "showCounts",
	SHOW_TITLES = "showTitles",
}

ns.AURA_FILTER_SUFFIX = {
	PLAYER = "PLAYER",
	IMPORTANT = "IMPORTANT",
	CROWD_CONTROL = "CROWD_CONTROL",
}

ns.AURA_SORT_DIRECTION = {
	NORMAL = "Normal",
}

ns.LUA_TYPE = {
	FUNCTION = "function",
	NUMBER = "number",
	STRING = "string",
	TABLE = "table",
}

ns.EVENT = {
	ADDON_LOADED = "ADDON_LOADED",
	PLAYER_LOGIN = "PLAYER_LOGIN",
	PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD",
	PLAYER_FOCUS_CHANGED = "PLAYER_FOCUS_CHANGED",
	PLAYER_TARGET_CHANGED = "PLAYER_TARGET_CHANGED",
	UNIT_AURA = "UNIT_AURA",
	UNIT_PET = "UNIT_PET",
	GROUP_ROSTER_UPDATE = "GROUP_ROSTER_UPDATE",
	RAID_ROSTER_UPDATE = "RAID_ROSTER_UPDATE",
	INSTANCE_ENCOUNTER_ENGAGE_UNIT = "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
	ARENA_OPPONENT_UPDATE = "ARENA_OPPONENT_UPDATE",
}

ns.FRAME_ATTR = {
	UNIT = "unit",
	GET_ID = "GetID",
	ID = "ID",
}

ns.BLIZZARD_FRAME = {
	PARTY_FRAME = "PartyFrame",
	COMPACT_PARTY_FRAME = "CompactPartyFrame",
	COMPACT_RAID_FRAME_CONTAINER = "CompactRaidFrameContainer",
	COMPACT_PARTY_FRAME_MEMBER_PREFIX = "CompactPartyFrameMember",
	PARTY_MEMBER_FRAME_PREFIX = "PartyMemberFrame",
	PARTY_MEMBER_PET_FRAME_SUFFIX = "PetFrame",
	PARTY_FRAME_MEMBER_PREFIX = "PartyFrameMember",
	MEMBER_FRAME_PREFIX = "MemberFrame",
	BOSS_TARGET_FRAME_PREFIX = "Boss",
	BOSS_TARGET_FRAME_SUFFIX = "TargetFrame",
	ARENA_ENEMY_FRAME_PREFIX = "ArenaEnemyFrame",
	ARENA_ENEMY_MATCH_FRAME_PREFIX = "ArenaEnemyMatchFrame",
	ARENA_ENEMY_PET_FRAME_SUFFIX = "PetFrame",
	PLAYER_FRAME = "PlayerFrame",
	TARGET_FRAME = "TargetFrame",
	FOCUS_FRAME = "FocusFrame",
	PET_FRAME = "PetFrame",
}

ns.UNIT_TOKEN = {
	PLAYER = "player",
	TARGET = "target",
	FOCUS = "focus",
	PET = "pet",
	PARTY_PREFIX = "party",
	PARTY_PET_PREFIX = "partypet",
	RAID_PREFIX = "raid",
	RAID_PET_PREFIX = "raidpet",
	BOSS_PREFIX = "boss",
	ARENA_PREFIX = "arena",
	ARENA_PET_PREFIX = "arenapet",
}
