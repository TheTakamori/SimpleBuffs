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

local LEGACY_UNIT_AURA_KEYS = {
	"layout",
	"sortRule",
	"filterMode",
	"iconSize",
	"spacing",
	"maxAuras",
	"scale",
	"showCountdown",
	"showSwipe",
	"showCounts",
	"showIcon",
	"style",
	"barWidth",
	"barSort",
}

local function absorb_legacy_flat_into_aura(unitOptions)
	local hasFlat = false
	for index = 1, #LEGACY_UNIT_AURA_KEYS do
		if unitOptions[LEGACY_UNIT_AURA_KEYS[index]] ~= nil then
			hasFlat = true
			break
		end
	end
	if not hasFlat then
		return
	end
	if type(unitOptions.aura) ~= ns.LUA_TYPE.TABLE then
		unitOptions.aura = {}
	end
	for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
		if type(unitOptions.aura[auraType]) ~= ns.LUA_TYPE.TABLE then
			unitOptions.aura[auraType] = {}
		end
		local block = unitOptions.aura[auraType]
		for flatIndex = 1, #LEGACY_UNIT_AURA_KEYS do
			local key = LEGACY_UNIT_AURA_KEYS[flatIndex]
			if unitOptions[key] ~= nil then
				block[key] = unitOptions[key]
			end
		end
	end
	for flatIndex = 1, #LEGACY_UNIT_AURA_KEYS do
		unitOptions[LEGACY_UNIT_AURA_KEYS[flatIndex]] = nil
	end
end

local function sanitize_aura_options(groupKey, auraType, auraOpts, rawUnitOptions, migrations)
	local defaultsAura = ns.DEFAULTS.units[groupKey].aura[auraType]
	local rawAuraOpts = type(rawUnitOptions.aura) == ns.LUA_TYPE.TABLE and rawUnitOptions.aura[auraType] or {}
	rawAuraOpts = type(rawAuraOpts) == ns.LUA_TYPE.TABLE and rawAuraOpts or {}

	local function raw_first(key)
		local fromAura = rawAuraOpts[key]
		if fromAura ~= nil then
			return fromAura
		end
		return rawUnitOptions[key]
	end

	auraOpts.layout = migration_or_default(ns.LAYOUT_ORDER, auraOpts.layout, migrations.layout, defaultsAura.layout, raw_first("layout"))
	auraOpts.sortRule = migration_or_default(ns.SORT_RULE_ORDER, auraOpts.sortRule, migrations.sortRule, defaultsAura.sortRule, raw_first("sortRule"))
	auraOpts.filterMode = migration_or_default(ns.FILTER_MODE_ORDER, auraOpts.filterMode, migrations.filterMode, defaultsAura.filterMode, raw_first("filterMode"))
	auraOpts.iconSize = migrated_number(auraOpts.iconSize, migrations.iconSize, ns.LIMITS.ICON_SIZE_MIN, ns.LIMITS.ICON_SIZE_MAX, defaultsAura.iconSize, raw_first("iconSize"), true)
	auraOpts.spacing = migrated_number(auraOpts.spacing, migrations.spacing, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, defaultsAura.spacing, raw_first("spacing"), true)
	auraOpts.maxAuras = migrated_number(auraOpts.maxAuras, migrations.maxAuras, ns.LIMITS.MAX_AURAS_MIN, ns.LIMITS.MAX_AURAS_MAX, defaultsAura.maxAuras, raw_first("maxAuras"), true)
	auraOpts.scale = migrated_number(auraOpts.scale, migrations.scale, ns.LIMITS.SCALE_MIN, ns.LIMITS.SCALE_MAX, defaultsAura.scale, raw_first("scale"), false)
	auraOpts.showCountdown = migrated_boolean(auraOpts.showCountdown, migrations.showCountdown, raw_first("showCountdown"))
	auraOpts.showSwipe = migrated_boolean(auraOpts.showSwipe, migrations.showSwipe, raw_first("showSwipe"))
	auraOpts.showCounts = migrated_boolean(auraOpts.showCounts, migrations.showCounts, raw_first("showCounts"))
	auraOpts.showIcon = migrated_boolean(auraOpts.showIcon, migrations.showIcon, raw_first("showIcon"))
	auraOpts.style = migration_or_default(ns.AURA_STYLE_ORDER, auraOpts.style, migrations.style, defaultsAura.style, raw_first("style"))
	auraOpts.barWidth = migrated_number(auraOpts.barWidth, migrations.barWidth, ns.LIMITS.BAR_WIDTH_MIN, ns.LIMITS.BAR_WIDTH_MAX, defaultsAura.barWidth, raw_first("barWidth"), true)
	auraOpts.barSort = migration_or_default(ns.BAR_SORT_ORDER, auraOpts.barSort, migrations.barSort, defaultsAura.barSort, raw_first("barSort"))
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

	unitOptions.attachedPosition = migration_or_default(ns.ATTACHED_POSITION_ORDER, unitOptions.attachedPosition, nil, ns.DEFAULTS.units[groupKey].attachedPosition, rawUnitOptions.attachedPosition)

	absorb_legacy_flat_into_aura(unitOptions)

	if type(unitOptions.aura) ~= ns.LUA_TYPE.TABLE then
		unitOptions.aura = {}
	end
	for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
		if type(unitOptions.aura[auraType]) ~= ns.LUA_TYPE.TABLE then
			unitOptions.aura[auraType] = {}
		end
		sanitize_aura_options(groupKey, auraType, unitOptions.aura[auraType], rawUnitOptions, migrations)
	end
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
	appearance.showIcon = nil
	appearance.style = nil
	appearance.barWidth = nil
	appearance.barSort = nil
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
			local auraSnapshot = {}
			if type(options.aura) == ns.LUA_TYPE.TABLE then
				for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
					local block = options.aura[auraType]
					if type(block) == ns.LUA_TYPE.TABLE then
						auraSnapshot[auraType] = {
							layout = block.layout,
							sortRule = block.sortRule,
							filterMode = block.filterMode,
							iconSize = block.iconSize,
							spacing = block.spacing,
							maxAuras = block.maxAuras,
							scale = block.scale,
							showCountdown = block.showCountdown,
							showSwipe = block.showSwipe,
							showCounts = block.showCounts,
							showIcon = block.showIcon,
							style = block.style,
							barWidth = block.barWidth,
							barSort = block.barSort,
						}
					end
				end
			end
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
				showIcon = options.showIcon,
				style = options.style,
				barWidth = options.barWidth,
				barSort = options.barSort,
				aura = auraSnapshot,
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
