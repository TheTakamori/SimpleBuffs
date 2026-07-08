SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local appearanceCache = {}
-- "\0" cannot appear in a group key or aura type, so it makes an unambiguous
-- composite cache key.
local CACHE_KEY_SEPARATOR = "\0"
-- Saved unit-option field names with copy semantics of their own (see
-- copy_unit_group_options below).
local AURA_FIELD = "aura"
local KNOWN_AURAS_FIELD = "knownAuras"

function ns.DB()
	return SimpleBuffsDB or ns.InitDB()
end

function ns.GetAppearance()
	return ns.DB().appearance
end

-- Whether to hide Blizzard's own default player buff bar (BuffFrame /
-- TemporaryEnchantFrame). Orthogonal to the per-unit-group display settings
-- above (it toggles Blizzard's own UI, not one of our own aura displays), so
-- it lives in its own small top-level DB section instead of the shared
-- per-unit-group options schema.
function ns.IsBlizzardPlayerBuffsHidden()
	return ns.DB().blizzardFrames.hidePlayerBuffs == true
end

function ns.SetBlizzardPlayerBuffsHidden(hidden)
	ns.DB().blizzardFrames.hidePlayerBuffs = hidden == true
	return true
end

local function ensure_unit_aura_block(groupKey, auraType)
	local options = ns.GetUnitGroupOptions(groupKey)
	if not options or not ns.AURA_FILTER[auraType] then
		return nil
	end
	options.aura = options.aura or {}
	options.aura[auraType] = options.aura[auraType] or {}
	return options.aura[auraType]
end

function ns.GetUnitGroupAppearance(groupKey, auraType)
	groupKey = groupKey or ns.UNIT_GROUP.PLAYER
	auraType = auraType or ns.AURA_TYPE.BUFF
	local options = ns.GetUnitGroupOptions(groupKey)
	local defaultsUnit = ns.DEFAULTS.units[groupKey]
	local fallback = defaultsUnit.aura and defaultsUnit.aura[auraType] or ns.DEFAULTS.appearance
	local cacheKey = groupKey .. CACHE_KEY_SEPARATOR .. auraType
	local appearance = appearanceCache[cacheKey] or {}
	appearanceCache[cacheKey] = appearance

	local block = options and options.aura and options.aura[auraType]
	block = type(block) == ns.LUA_TYPE.TABLE and block or {}

	appearance.iconSize = block.iconSize or fallback.iconSize
	appearance.spacing = block.spacing or fallback.spacing
	appearance.rowSpacing = ns.GetAppearance().rowSpacing
	appearance.maxAuras = block.maxAuras or fallback.maxAuras
	appearance.scale = block.scale or fallback.scale
	appearance.showCountdown = block.showCountdown ~= false
	appearance.showSwipe = block.showSwipe ~= false
	appearance.showCounts = block.showCounts ~= false
	appearance.showIcon = block.showIcon ~= false
	appearance.style = block.style or fallback.style
	appearance.barWidth = block.barWidth or fallback.barWidth
	appearance.barAnchor = block.barAnchor or fallback.barAnchor
	return appearance
end

function ns.GetUnitAppearance(unit, auraType)
	return ns.GetUnitGroupAppearance(ns.GetUnitGroup(unit) or unit, auraType)
end

function ns.GetUnitMaxAuras(unit, auraType)
	local groupKey = ns.GetUnitGroup(unit) or unit
	auraType = auraType or ns.AURA_TYPE.BUFF
	return ns.GetUnitGroupAppearance(groupKey, auraType).maxAuras
end

function ns.GetUnitOptions(unit)
	local db = ns.DB()
	return db.units[ns.GetUnitGroup(unit) or unit]
end

function ns.GetUnitGroupOptions(groupKey)
	return ns.DB().units[groupKey]
end

function ns.IsUnitAuraEnabled(unit, auraType)
	local options = ns.GetUnitOptions(unit)
	return options and options[auraType] == true
end

function ns.GetUnitGroupDisplayMode(groupKey)
	local options = ns.GetUnitGroupOptions(groupKey)
	return options and options.mode or ns.DISPLAY_MODE.STANDALONE
end

function ns.GetUnitDisplayMode(unit)
	return ns.GetUnitGroupDisplayMode(ns.GetUnitGroup(unit) or unit)
end

function ns.SetUnitGroupDisplayMode(groupKey, mode)
	if not ns.GetUnitGroupOptions(groupKey) or not ns.IsKnownValue(ns.GetUnitGroupDisplayModes(groupKey), mode) then
		return false
	end
	ns.DB().units[groupKey].mode = mode
	return true
end

function ns.GetUnitGroupAttachedPosition(groupKey)
	local options = ns.GetUnitGroupOptions(groupKey)
	return options and options.attachedPosition or ns.DEFAULTS.units[groupKey].attachedPosition
end

function ns.GetUnitAttachedPosition(unit)
	return ns.GetUnitGroupAttachedPosition(ns.GetUnitGroup(unit) or unit)
end

function ns.SetUnitGroupAttachedPosition(groupKey, attachedPosition)
	if not ns.GetUnitGroupOptions(groupKey) or not ns.IsKnownValue(ns.ATTACHED_POSITION_ORDER, attachedPosition) then
		return false
	end
	ns.DB().units[groupKey].attachedPosition = attachedPosition
	return true
end

-- Layout, style, barSort, sortRule, and filterMode all follow the same
-- per-group/per-unit/per-aura-type get-or-fallback and validated-set shape;
-- this factory avoids five near-identical copies of that shape.
local function define_aura_field_accessor(fieldName, validValuesOrder, groupGetterName, unitGetterName, groupSetterName)
	ns[groupGetterName] = function(groupKey, auraType)
		auraType = auraType or ns.AURA_TYPE.BUFF
		local options = ns.GetUnitGroupOptions(groupKey)
		local fallback = ns.DEFAULTS.units[groupKey].aura[auraType]
		if not options or type(options.aura) ~= ns.LUA_TYPE.TABLE or type(options.aura[auraType]) ~= ns.LUA_TYPE.TABLE then
			return fallback[fieldName]
		end
		return options.aura[auraType][fieldName] or fallback[fieldName]
	end

	ns[unitGetterName] = function(unit, auraType)
		return ns[groupGetterName](ns.GetUnitGroup(unit) or unit, auraType)
	end

	ns[groupSetterName] = function(groupKey, auraType, value)
		if not ns.GetUnitGroupOptions(groupKey) or not ns.AURA_FILTER[auraType] or not ns.IsKnownValue(validValuesOrder, value) then
			return false
		end
		local block = ensure_unit_aura_block(groupKey, auraType)
		if not block then
			return false
		end
		block[fieldName] = value
		return true
	end
end

define_aura_field_accessor("layout", ns.LAYOUT_ORDER, "GetUnitGroupLayout", "GetUnitLayout", "SetUnitGroupLayout")
define_aura_field_accessor("style", ns.AURA_STYLE_ORDER, "GetUnitGroupStyle", "GetUnitStyle", "SetUnitGroupStyle")
define_aura_field_accessor("barSort", ns.BAR_SORT_ORDER, "GetUnitGroupBarSort", "GetUnitBarSort", "SetUnitGroupBarSort")
define_aura_field_accessor("barAnchor", ns.BAR_ANCHOR_ORDER, "GetUnitGroupBarAnchor", "GetUnitBarAnchor", "SetUnitGroupBarAnchor")
define_aura_field_accessor("sortRule", ns.SORT_RULE_ORDER, "GetUnitGroupSortRule", "GetUnitSortRule", "SetUnitGroupSortRule")
define_aura_field_accessor("filterMode", ns.FILTER_MODE_ORDER, "GetUnitGroupFilterMode", "GetUnitFilterMode", "SetUnitGroupFilterMode")

local function apply_appearance_value(target, key, value, fallback)
	if key == ns.DB_KEY.ICON_SIZE then
		target.iconSize = math.floor(ns.Clamp(value, ns.LIMITS.ICON_SIZE_MIN, ns.LIMITS.ICON_SIZE_MAX, fallback.iconSize))
	elseif key == ns.DB_KEY.SPACING then
		target.spacing = math.floor(ns.Clamp(value, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, fallback.spacing))
	elseif key == ns.DB_KEY.MAX_AURAS then
		target.maxAuras = math.floor(ns.Clamp(value, ns.LIMITS.MAX_AURAS_MIN, ns.LIMITS.MAX_AURAS_MAX, fallback.maxAuras))
	elseif key == ns.DB_KEY.BAR_WIDTH then
		target.barWidth = math.floor(ns.Clamp(value, ns.LIMITS.BAR_WIDTH_MIN, ns.LIMITS.BAR_WIDTH_MAX, fallback.barWidth))
	elseif key == ns.DB_KEY.SCALE then
		target.scale = ns.Clamp(value, ns.LIMITS.SCALE_MIN, ns.LIMITS.SCALE_MAX, fallback.scale)
	elseif key == ns.DB_KEY.SHOW_COUNTDOWN then
		target.showCountdown = value == true
	elseif key == ns.DB_KEY.SHOW_SWIPE then
		target.showSwipe = value == true
	elseif key == ns.DB_KEY.SHOW_COUNTS then
		target.showCounts = value == true
	elseif key == ns.DB_KEY.SHOW_ICON then
		target.showIcon = value == true
	else
		return false
	end
	return true
end

local function copy_aura_table(sourceAura)
	local out = {}
	for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
		out[auraType] = {}
		for k, v in pairs(sourceAura and sourceAura[auraType] or {}) do
			out[auraType][k] = v
		end
	end
	return out
end

local function copy_unit_group_options(source, target)
	-- knownAuras is content-specific (which spells this unit has hidden), not
	-- display config, so Copy From leaves the target's own list untouched.
	local preservedKnownAuras = target and type(target.knownAuras) == ns.LUA_TYPE.TABLE and target.knownAuras or nil
	for key in pairs(target or {}) do
		target[key] = nil
	end
	for key, value in pairs(source or {}) do
		if key == AURA_FIELD and type(value) == ns.LUA_TYPE.TABLE then
			target[key] = copy_aura_table(value)
		elseif key ~= KNOWN_AURAS_FIELD then
			target[key] = value
		end
	end
	target.knownAuras = preservedKnownAuras or {}
	return target
end

function ns.SetUnitGroupAppearanceValue(groupKey, auraType, key, value)
	local block = ensure_unit_aura_block(groupKey, auraType)
	if not block then
		return false
	end
	local fallback = ns.DEFAULTS.units[groupKey].aura[auraType]
	return apply_appearance_value(block, key, value, fallback)
end

function ns.SetUnitGroupAuraEnabled(groupKey, auraType, enabled)
	local options = ns.GetUnitGroupOptions(groupKey)
	if not options or not ns.AURA_FILTER[auraType] then
		return false
	end
	options[auraType] = enabled == true
	return true
end

function ns.SetUnitAuraEnabled(unit, auraType, enabled)
	return ns.SetUnitGroupAuraEnabled(ns.GetUnitGroup(unit) or unit, auraType, enabled)
end

function ns.CopyUnitGroupOptions(sourceGroupKey, targetGroupKey)
	if sourceGroupKey == targetGroupKey then
		return false
	end
	local source = ns.GetUnitGroupOptions(sourceGroupKey)
	local target = ns.GetUnitGroupOptions(targetGroupKey)
	if not source or not target then
		return false
	end

	copy_unit_group_options(source, target)
	if not ns.IsKnownValue(ns.GetUnitGroupDisplayModes(targetGroupKey), target.mode) then
		target.mode = ns.DEFAULTS.units[targetGroupKey].mode
	end
	return true
end

function ns.SetAllUnitAurasEnabled(enabled)
	local value = enabled == true
	for _, groupKey in ipairs(ns.UNIT_GROUP_ORDER) do
		local options = ns.GetUnitGroupOptions(groupKey)
		if options then
			options.buff = value
			options.debuff = value
		end
	end
	return value
end

function ns.AreAllUnitAurasEnabled()
	for _, groupKey in ipairs(ns.UNIT_GROUP_ORDER) do
		local options = ns.GetUnitGroupOptions(groupKey)
		if not options or not options.buff or not options.debuff then
			return false
		end
	end
	return true
end
