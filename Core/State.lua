SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local function copy_table(source, target)
	target = target or {}
	for key, value in pairs(source or {}) do
		if type(value) == ns.LUA_TYPE.TABLE then
			target[key] = copy_table(value, type(target[key]) == ns.LUA_TYPE.TABLE and target[key] or {})
		elseif target[key] == nil then
			target[key] = value
		end
	end
	return target
end

local function contains(values, needle)
	for index = 1, #values do
		if values[index] == needle then
			return true
		end
	end
	return false
end

local function clamp(value, minValue, maxValue, fallback)
	local numeric = tonumber(value)
	if numeric == nil then
		numeric = fallback
	end
	if numeric < minValue then
		return minValue
	end
	if numeric > maxValue then
		return maxValue
	end
	return numeric
end

local function sanitize_position(saved, fallback)
	saved.point = type(saved.point) == ns.LUA_TYPE.STRING and saved.point or fallback.point
	saved.relativePoint = type(saved.relativePoint) == ns.LUA_TYPE.STRING and saved.relativePoint or fallback.relativePoint
	saved.x = tonumber(saved.x) or fallback.x
	saved.y = tonumber(saved.y) or fallback.y
	return saved
end

local function migration_or_default(values, current, migration, default, rawValue)
	if contains(values, rawValue) then
		return current
	end
	if migration and contains(values, migration) then
		return migration
	end
	if contains(values, current) then
		return current
	end
	return default
end

local function sanitize_unit_options(groupKey, unitOptions, migrations)
	local rawUnitOptions = migrations.rawUnits and migrations.rawUnits[groupKey] or {}
	rawUnitOptions = type(rawUnitOptions) == ns.LUA_TYPE.TABLE and rawUnitOptions or {}
	unitOptions.buff = unitOptions.buff ~= false
	unitOptions.debuff = unitOptions.debuff ~= false
	if not ns.UnitGroupSupportsAttached(groupKey) then
		unitOptions.mode = ns.DISPLAY_MODE.STANDALONE
	else
		unitOptions.mode = migration_or_default(
			ns.GetUnitGroupDisplayModes(groupKey),
			unitOptions.mode,
			migrations.mode,
			ns.DEFAULTS.units[groupKey].mode,
			rawUnitOptions.mode
		)
	end

	unitOptions.layout = migration_or_default(ns.LAYOUT_ORDER, unitOptions.layout, migrations.layout, ns.DEFAULTS.units[groupKey].layout, rawUnitOptions.layout)
	unitOptions.sortRule = migration_or_default(ns.SORT_RULE_ORDER, unitOptions.sortRule, migrations.sortRule, ns.DEFAULTS.units[groupKey].sortRule, rawUnitOptions.sortRule)
	unitOptions.filterMode = migration_or_default(ns.FILTER_MODE_ORDER, unitOptions.filterMode, migrations.filterMode, ns.DEFAULTS.units[groupKey].filterMode, rawUnitOptions.filterMode)
end

local function sanitize_db(db, migrations)
	migrations = migrations or {}
	db.version = ns.DB_VERSION
	db.appearance = type(db.appearance) == ns.LUA_TYPE.TABLE and db.appearance or {}
	db.units = type(db.units) == ns.LUA_TYPE.TABLE and db.units or {}
	db.attached = type(db.attached) == ns.LUA_TYPE.TABLE and db.attached or {}
	db.standalone = type(db.standalone) == ns.LUA_TYPE.TABLE and db.standalone or {}
	db.minimap = type(db.minimap) == ns.LUA_TYPE.TABLE and db.minimap or {}
	db.minimap.angle = clamp(db.minimap.angle, ns.NUMBER.ZERO, ns.MINIMAP_MATH.FULL_CIRCLE_DEGREES, ns.DEFAULTS.minimap.angle)
	db.minimap.hide = db.minimap.hide == true
	db.displayMode = nil
	db.locked = db.locked == true

	local appearance = db.appearance
	appearance.iconSize = clamp(appearance.iconSize, ns.LIMITS.ICON_SIZE_MIN, ns.LIMITS.ICON_SIZE_MAX, ns.DEFAULTS.appearance.iconSize)
	appearance.spacing = clamp(appearance.spacing, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, ns.DEFAULTS.appearance.spacing)
	appearance.rowSpacing = clamp(appearance.rowSpacing, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, ns.DEFAULTS.appearance.rowSpacing)
	appearance.maxAuras = math.floor(clamp(appearance.maxAuras, ns.LIMITS.MAX_AURAS_MIN, ns.LIMITS.MAX_AURAS_MAX, ns.DEFAULTS.appearance.maxAuras))
	appearance.scale = clamp(appearance.scale, ns.LIMITS.SCALE_MIN, ns.LIMITS.SCALE_MAX, ns.DEFAULTS.appearance.scale)
	appearance.layout = nil
	appearance.sortRule = nil
	appearance.filterMode = nil
	appearance.showCountdown = appearance.showCountdown ~= false
	appearance.showSwipe = appearance.showSwipe ~= false
	appearance.showCounts = appearance.showCounts ~= false
	appearance.showTitles = appearance.showTitles ~= false

	for _, groupKey in ipairs(ns.UNIT_GROUP_ORDER) do
		db.units[groupKey] = type(db.units[groupKey]) == ns.LUA_TYPE.TABLE and db.units[groupKey] or {}
		sanitize_unit_options(groupKey, db.units[groupKey], migrations)
	end

	for unit, fallback in pairs(ns.ANCHOR_DEFAULTS) do
		db.attached[unit] = type(db.attached[unit]) == ns.LUA_TYPE.TABLE and db.attached[unit] or {}
		sanitize_position(db.attached[unit], fallback)
	end

	for containerKey, fallback in pairs(ns.STANDALONE_DEFAULTS) do
		db.standalone[containerKey] = type(db.standalone[containerKey]) == ns.LUA_TYPE.TABLE and db.standalone[containerKey] or {}
		sanitize_position(db.standalone[containerKey], fallback)
	end
end

local function capture_raw_unit_options(units)
	local snapshot = {}
	if type(units) ~= ns.LUA_TYPE.TABLE then
		return snapshot
	end
	for groupKey, options in pairs(units) do
		if type(options) == ns.LUA_TYPE.TABLE then
			snapshot[groupKey] = {
				mode = options.mode,
				layout = options.layout,
				sortRule = options.sortRule,
				filterMode = options.filterMode,
			}
		end
	end
	return snapshot
end

function ns.InitDB()
	local existing = SimpleBuffsDB or {}
	local previousVersion = tonumber(existing.version) or ns.NUMBER.ZERO
	local existingAppearance = type(existing.appearance) == ns.LUA_TYPE.TABLE and existing.appearance or {}
	local rawUnits = capture_raw_unit_options(existing.units)
	local migrations = {
		mode = previousVersion < ns.DB_VERSION and contains(ns.DISPLAY_MODE_ORDER, existing.displayMode) and existing.displayMode or nil,
		layout = previousVersion < ns.DB_VERSION and contains(ns.LAYOUT_ORDER, existingAppearance.layout) and existingAppearance.layout or nil,
		sortRule = previousVersion < ns.DB_VERSION and contains(ns.SORT_RULE_ORDER, existingAppearance.sortRule) and existingAppearance.sortRule or nil,
		filterMode = previousVersion < ns.DB_VERSION and contains(ns.FILTER_MODE_ORDER, existingAppearance.filterMode) and existingAppearance.filterMode or nil,
		rawUnits = rawUnits,
	}
	SimpleBuffsDB = copy_table(ns.DEFAULTS, existing)
	sanitize_db(SimpleBuffsDB, migrations)
	return SimpleBuffsDB
end

function ns.ResetDB()
	SimpleBuffsDB = copy_table(ns.DEFAULTS, {})
	sanitize_db(SimpleBuffsDB)
	return SimpleBuffsDB
end

function ns.DB()
	return SimpleBuffsDB or ns.InitDB()
end

function ns.Clamp(value, minValue, maxValue, fallback)
	return clamp(value, minValue, maxValue, fallback)
end

function ns.IsKnownValue(values, value)
	return contains(values, value)
end

function ns.GetAppearance()
	return ns.DB().appearance
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
	if not ns.GetUnitGroupOptions(groupKey) or not contains(ns.GetUnitGroupDisplayModes(groupKey), mode) then
		return false
	end
	ns.DB().units[groupKey].mode = mode
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
	if not ns.GetUnitGroupOptions(groupKey) or not contains(ns.LAYOUT_ORDER, layout) then
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
	if not ns.GetUnitGroupOptions(groupKey) or not contains(ns.SORT_RULE_ORDER, sortRule) then
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
	if not ns.GetUnitGroupOptions(groupKey) or not contains(ns.FILTER_MODE_ORDER, filterMode) then
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

function ns.SetAppearanceValue(key, value)
	local appearance = ns.GetAppearance()
	if key == ns.DB_KEY.ICON_SIZE then
		appearance.iconSize = math.floor(clamp(value, ns.LIMITS.ICON_SIZE_MIN, ns.LIMITS.ICON_SIZE_MAX, ns.DEFAULTS.appearance.iconSize))
	elseif key == ns.DB_KEY.SPACING then
		appearance.spacing = math.floor(clamp(value, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, ns.DEFAULTS.appearance.spacing))
	elseif key == ns.DB_KEY.ROW_SPACING then
		appearance.rowSpacing = math.floor(clamp(value, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, ns.DEFAULTS.appearance.rowSpacing))
	elseif key == ns.DB_KEY.MAX_AURAS then
		appearance.maxAuras = math.floor(clamp(value, ns.LIMITS.MAX_AURAS_MIN, ns.LIMITS.MAX_AURAS_MAX, ns.DEFAULTS.appearance.maxAuras))
	elseif key == ns.DB_KEY.SCALE then
		appearance.scale = clamp(value, ns.LIMITS.SCALE_MIN, ns.LIMITS.SCALE_MAX, ns.DEFAULTS.appearance.scale)
	elseif key == ns.DB_KEY.SHOW_COUNTDOWN then
		appearance.showCountdown = value == true
	elseif key == ns.DB_KEY.SHOW_SWIPE then
		appearance.showSwipe = value == true
	elseif key == ns.DB_KEY.SHOW_COUNTS then
		appearance.showCounts = value == true
	elseif key == ns.DB_KEY.SHOW_TITLES then
		appearance.showTitles = value == true
	else
		return false
	end
	return true
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
