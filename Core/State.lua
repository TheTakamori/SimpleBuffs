SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local appearanceCache = {}

function ns.DB()
	return SimpleBuffsDB or ns.InitDB()
end

function ns.GetAppearance()
	return ns.DB().appearance
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
	local cacheKey = groupKey .. "\0" .. auraType
	local appearance = appearanceCache[cacheKey] or {}
	appearanceCache[cacheKey] = appearance

	local block = options and options.aura and options.aura[auraType]
	block = type(block) == "table" and block or {}

	appearance.iconSize = block.iconSize or fallback.iconSize
	appearance.spacing = block.spacing or fallback.spacing
	appearance.rowSpacing = ns.GetAppearance().rowSpacing
	appearance.maxAuras = block.maxAuras or fallback.maxAuras
	appearance.scale = block.scale or fallback.scale
	appearance.showCountdown = block.showCountdown ~= false
	appearance.showSwipe = block.showSwipe ~= false
	appearance.showCounts = block.showCounts ~= false
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

function ns.GetUnitGroupLayout(groupKey, auraType)
	auraType = auraType or ns.AURA_TYPE.BUFF
	local options = ns.GetUnitGroupOptions(groupKey)
	local fallback = ns.DEFAULTS.units[groupKey].aura[auraType]
	if not options or type(options.aura) ~= "table" or type(options.aura[auraType]) ~= "table" then
		return fallback.layout
	end
	return options.aura[auraType].layout or fallback.layout
end

function ns.GetUnitLayout(unit, auraType)
	return ns.GetUnitGroupLayout(ns.GetUnitGroup(unit) or unit, auraType)
end

function ns.SetUnitGroupLayout(groupKey, auraType, layout)
	if not ns.GetUnitGroupOptions(groupKey) or not ns.AURA_FILTER[auraType] or not ns.IsKnownValue(ns.LAYOUT_ORDER, layout) then
		return false
	end
	local block = ensure_unit_aura_block(groupKey, auraType)
	if not block then
		return false
	end
	block.layout = layout
	return true
end

function ns.GetUnitGroupSortRule(groupKey, auraType)
	auraType = auraType or ns.AURA_TYPE.BUFF
	local options = ns.GetUnitGroupOptions(groupKey)
	local fallback = ns.DEFAULTS.units[groupKey].aura[auraType]
	if not options or type(options.aura) ~= "table" or type(options.aura[auraType]) ~= "table" then
		return fallback.sortRule
	end
	return options.aura[auraType].sortRule or fallback.sortRule
end

function ns.GetUnitSortRule(unit, auraType)
	return ns.GetUnitGroupSortRule(ns.GetUnitGroup(unit) or unit, auraType)
end

function ns.SetUnitGroupSortRule(groupKey, auraType, sortRule)
	if not ns.GetUnitGroupOptions(groupKey) or not ns.AURA_FILTER[auraType] or not ns.IsKnownValue(ns.SORT_RULE_ORDER, sortRule) then
		return false
	end
	local block = ensure_unit_aura_block(groupKey, auraType)
	if not block then
		return false
	end
	block.sortRule = sortRule
	return true
end

function ns.GetUnitGroupFilterMode(groupKey, auraType)
	auraType = auraType or ns.AURA_TYPE.BUFF
	local options = ns.GetUnitGroupOptions(groupKey)
	local fallback = ns.DEFAULTS.units[groupKey].aura[auraType]
	if not options or type(options.aura) ~= "table" or type(options.aura[auraType]) ~= "table" then
		return fallback.filterMode
	end
	return options.aura[auraType].filterMode or fallback.filterMode
end

function ns.GetUnitFilterMode(unit, auraType)
	return ns.GetUnitGroupFilterMode(ns.GetUnitGroup(unit) or unit, auraType)
end

function ns.SetUnitGroupFilterMode(groupKey, auraType, filterMode)
	if not ns.GetUnitGroupOptions(groupKey) or not ns.AURA_FILTER[auraType] or not ns.IsKnownValue(ns.FILTER_MODE_ORDER, filterMode) then
		return false
	end
	local block = ensure_unit_aura_block(groupKey, auraType)
	if not block then
		return false
	end
	block.filterMode = filterMode
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
	for key in pairs(target or {}) do
		target[key] = nil
	end
	for key, value in pairs(source or {}) do
		if key == "aura" and type(value) == "table" then
			target[key] = copy_aura_table(value)
		else
			target[key] = value
		end
	end
	return target
end

function ns.SetAppearanceValue(key, value)
	return apply_appearance_value(ns.GetAppearance(), key, value, ns.DEFAULTS.appearance, true)
end

function ns.SetUnitGroupAppearanceValue(groupKey, auraType, key, value)
	local block = ensure_unit_aura_block(groupKey, auraType)
	if not block then
		return false
	end
	local fallback = ns.DEFAULTS.units[groupKey].aura[auraType]
	return apply_appearance_value(block, key, value, fallback, false)
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
