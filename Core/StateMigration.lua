SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs
local GLOBAL_SETTINGS_MIGRATION_VERSION = 5

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

local function migrated_number(current, migration, minValue, maxValue, default, rawValue, round)
	local source = tonumber(rawValue) ~= nil and current or migration
	local value = clamp(source, minValue, maxValue, default)
	return round and math.floor(value) or value
end

local function migrated_boolean(current, migration, rawValue)
	if type(rawValue) == ns.LUA_TYPE.BOOLEAN then
		return current == true
	end
	if type(migration) == ns.LUA_TYPE.BOOLEAN then
		return migration == true
	end
	return current ~= false
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
	unitOptions.attachedPosition = migration_or_default(ns.ATTACHED_POSITION_ORDER, unitOptions.attachedPosition, nil, ns.DEFAULTS.units[groupKey].attachedPosition, rawUnitOptions.attachedPosition)
	unitOptions.sortRule = migration_or_default(ns.SORT_RULE_ORDER, unitOptions.sortRule, migrations.sortRule, ns.DEFAULTS.units[groupKey].sortRule, rawUnitOptions.sortRule)
	unitOptions.filterMode = migration_or_default(ns.FILTER_MODE_ORDER, unitOptions.filterMode, migrations.filterMode, ns.DEFAULTS.units[groupKey].filterMode, rawUnitOptions.filterMode)
	unitOptions.iconSize = migrated_number(unitOptions.iconSize, migrations.iconSize, ns.LIMITS.ICON_SIZE_MIN, ns.LIMITS.ICON_SIZE_MAX, ns.DEFAULTS.units[groupKey].iconSize, rawUnitOptions.iconSize, true)
	unitOptions.spacing = migrated_number(unitOptions.spacing, migrations.spacing, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, ns.DEFAULTS.units[groupKey].spacing, rawUnitOptions.spacing, true)
	unitOptions.maxAuras = migrated_number(unitOptions.maxAuras, migrations.maxAuras, ns.LIMITS.MAX_AURAS_MIN, ns.LIMITS.MAX_AURAS_MAX, ns.DEFAULTS.units[groupKey].maxAuras, rawUnitOptions.maxAuras, true)
	unitOptions.scale = migrated_number(unitOptions.scale, migrations.scale, ns.LIMITS.SCALE_MIN, ns.LIMITS.SCALE_MAX, ns.DEFAULTS.units[groupKey].scale, rawUnitOptions.scale, false)
	unitOptions.showCountdown = migrated_boolean(unitOptions.showCountdown, migrations.showCountdown, rawUnitOptions.showCountdown)
	unitOptions.showSwipe = migrated_boolean(unitOptions.showSwipe, migrations.showSwipe, rawUnitOptions.showSwipe)
	unitOptions.showCounts = migrated_boolean(unitOptions.showCounts, migrations.showCounts, rawUnitOptions.showCounts)
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
	appearance.iconSize = nil
	appearance.spacing = nil
	appearance.maxAuras = nil
	appearance.scale = nil
	appearance.layout = nil
	appearance.sortRule = nil
	appearance.filterMode = nil
	appearance.showCountdown = nil
	appearance.showSwipe = nil
	appearance.showCounts = nil
	appearance.showTitles = nil
	appearance.rowSpacing = clamp(appearance.rowSpacing, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, ns.DEFAULTS.appearance.rowSpacing)

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
				attachedPosition = options.attachedPosition,
				layout = options.layout,
				sortRule = options.sortRule,
				filterMode = options.filterMode,
				iconSize = options.iconSize,
				spacing = options.spacing,
				maxAuras = options.maxAuras,
				scale = options.scale,
				showCountdown = options.showCountdown,
				showSwipe = options.showSwipe,
				showCounts = options.showCounts,
			}
		end
	end
	return snapshot
end

local function legacy_boolean_migration(shouldMigrate, value)
	if shouldMigrate and type(value) == ns.LUA_TYPE.BOOLEAN then
		return value
	end
	return nil
end

function ns.InitDB()
	local existing = SimpleBuffsDB or {}
	local previousVersion = tonumber(existing.version) or ns.NUMBER.ZERO
	local migrateGlobalSettings = previousVersion < GLOBAL_SETTINGS_MIGRATION_VERSION
	local existingAppearance = type(existing.appearance) == ns.LUA_TYPE.TABLE and existing.appearance or {}
	local rawUnits = capture_raw_unit_options(existing.units)
	local migrations = {
		mode = migrateGlobalSettings and contains(ns.DISPLAY_MODE_ORDER, existing.displayMode) and existing.displayMode or nil,
		layout = migrateGlobalSettings and contains(ns.LAYOUT_ORDER, existingAppearance.layout) and existingAppearance.layout or nil,
		sortRule = migrateGlobalSettings and contains(ns.SORT_RULE_ORDER, existingAppearance.sortRule) and existingAppearance.sortRule or nil,
		filterMode = migrateGlobalSettings and contains(ns.FILTER_MODE_ORDER, existingAppearance.filterMode) and existingAppearance.filterMode or nil,
		iconSize = migrateGlobalSettings and existingAppearance.iconSize or nil,
		spacing = migrateGlobalSettings and existingAppearance.spacing or nil,
		maxAuras = migrateGlobalSettings and existingAppearance.maxAuras or nil,
		scale = migrateGlobalSettings and existingAppearance.scale or nil,
		showCountdown = legacy_boolean_migration(migrateGlobalSettings, existingAppearance.showCountdown),
		showSwipe = legacy_boolean_migration(migrateGlobalSettings, existingAppearance.showSwipe),
		showCounts = legacy_boolean_migration(migrateGlobalSettings, existingAppearance.showCounts),
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

function ns.ResetUnitGroupOptions(groupKey)
	if not ns.DEFAULTS.units[groupKey] then
		return false
	end
	ns.DB().units[groupKey] = copy_table(ns.DEFAULTS.units[groupKey], {})
	return true
end

function ns.Clamp(value, minValue, maxValue, fallback)
	return clamp(value, minValue, maxValue, fallback)
end

function ns.IsKnownValue(values, value)
	return contains(values, value)
end
