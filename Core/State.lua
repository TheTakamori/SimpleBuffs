SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local appearanceCache = {}

function ns.DB()
	return SimpleBuffsDB or ns.InitDB()
end

function ns.GetAppearance()
	return ns.DB().appearance
end

function ns.GetUnitGroupAppearance(groupKey)
	groupKey = groupKey or ns.UNIT_GROUP.PLAYER
	local options = ns.GetUnitGroupOptions(groupKey) or {}
	local fallback = ns.DEFAULTS.units[groupKey] or ns.DEFAULTS.appearance
	local appearance = appearanceCache[groupKey] or {}
	appearanceCache[groupKey] = appearance
	appearance.iconSize = options.iconSize or fallback.iconSize
	appearance.spacing = options.spacing or fallback.spacing
	appearance.rowSpacing = ns.GetAppearance().rowSpacing
	appearance.maxAuras = options.maxAuras or fallback.maxAuras
	appearance.scale = options.scale or fallback.scale
	appearance.showCountdown = options.showCountdown ~= false
	appearance.showSwipe = options.showSwipe ~= false
	appearance.showCounts = options.showCounts ~= false
	return appearance
end

function ns.GetUnitAppearance(unit)
	return ns.GetUnitGroupAppearance(ns.GetUnitGroup(unit) or unit)
end

function ns.GetUnitMaxAuras(unit)
	local groupKey = ns.GetUnitGroup(unit) or unit
	local options = ns.GetUnitGroupOptions(groupKey) or {}
	local fallback = ns.DEFAULTS.units[groupKey] or ns.DEFAULTS.appearance
	return options.maxAuras or fallback.maxAuras
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

function ns.GetUnitGroupLayout(groupKey)
	local options = ns.GetUnitGroupOptions(groupKey)
	return options and options.layout or ns.DEFAULTS.appearance.layout
end

function ns.GetUnitLayout(unit)
	return ns.GetUnitGroupLayout(ns.GetUnitGroup(unit) or unit)
end

function ns.SetUnitGroupLayout(groupKey, layout)
	if not ns.GetUnitGroupOptions(groupKey) or not ns.IsKnownValue(ns.LAYOUT_ORDER, layout) then
		return false
	end
	ns.DB().units[groupKey].layout = layout
	return true
end

function ns.GetUnitGroupSortRule(groupKey)
	local options = ns.GetUnitGroupOptions(groupKey)
	return options and options.sortRule or ns.DEFAULTS.appearance.sortRule
end

function ns.GetUnitSortRule(unit)
	return ns.GetUnitGroupSortRule(ns.GetUnitGroup(unit) or unit)
end

function ns.SetUnitGroupSortRule(groupKey, sortRule)
	if not ns.GetUnitGroupOptions(groupKey) or not ns.IsKnownValue(ns.SORT_RULE_ORDER, sortRule) then
		return false
	end
	ns.DB().units[groupKey].sortRule = sortRule
	return true
end

function ns.GetUnitGroupFilterMode(groupKey)
	local options = ns.GetUnitGroupOptions(groupKey)
	return options and options.filterMode or ns.DEFAULTS.appearance.filterMode
end

function ns.GetUnitFilterMode(unit)
	return ns.GetUnitGroupFilterMode(ns.GetUnitGroup(unit) or unit)
end

function ns.SetUnitGroupFilterMode(groupKey, filterMode)
	if not ns.GetUnitGroupOptions(groupKey) or not ns.IsKnownValue(ns.FILTER_MODE_ORDER, filterMode) then
		return false
	end
	ns.DB().units[groupKey].filterMode = filterMode
	return true
end

function ns.AnyUnitGroupUsesStandaloneDisplay()
	for _, groupKey in ipairs(ns.UNIT_GROUP_ORDER) do
		local mode = ns.GetUnitGroupDisplayMode(groupKey)
		if mode == ns.DISPLAY_MODE.STANDALONE or mode == ns.DISPLAY_MODE.BOTH then
			return true
		end
	end
	return false
end

local function apply_appearance_value(target, key, value, fallback, allowGlobalOnly)
	if key == ns.DB_KEY.ICON_SIZE then
		target.iconSize = math.floor(ns.Clamp(value, ns.LIMITS.ICON_SIZE_MIN, ns.LIMITS.ICON_SIZE_MAX, fallback.iconSize))
	elseif key == ns.DB_KEY.SPACING then
		target.spacing = math.floor(ns.Clamp(value, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, fallback.spacing))
	elseif allowGlobalOnly and key == ns.DB_KEY.ROW_SPACING then
		target.rowSpacing = math.floor(ns.Clamp(value, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, fallback.rowSpacing))
	elseif key == ns.DB_KEY.MAX_AURAS then
		target.maxAuras = math.floor(ns.Clamp(value, ns.LIMITS.MAX_AURAS_MIN, ns.LIMITS.MAX_AURAS_MAX, fallback.maxAuras))
	elseif key == ns.DB_KEY.SCALE then
		target.scale = ns.Clamp(value, ns.LIMITS.SCALE_MIN, ns.LIMITS.SCALE_MAX, fallback.scale)
	elseif key == ns.DB_KEY.SHOW_COUNTDOWN then
		target.showCountdown = value == true
	elseif key == ns.DB_KEY.SHOW_SWIPE then
		target.showSwipe = value == true
	elseif key == ns.DB_KEY.SHOW_COUNTS then
		target.showCounts = value == true
	else
		return false
	end
	return true
end

function ns.SetAppearanceValue(key, value)
	return apply_appearance_value(ns.GetAppearance(), key, value, ns.DEFAULTS.appearance, true)
end

function ns.SetUnitGroupAppearanceValue(groupKey, key, value)
	local options = ns.GetUnitGroupOptions(groupKey)
	if not options then
		return false
	end
	return apply_appearance_value(options, key, value, ns.DEFAULTS.units[groupKey], false)
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
