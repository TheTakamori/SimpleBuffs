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

local function sanitize_unit_options(unitOptions)
	unitOptions.buff = unitOptions.buff ~= false
	unitOptions.debuff = unitOptions.debuff ~= false
end

local function sanitize_db(db)
	db.version = ns.DB_VERSION
	db.appearance = type(db.appearance) == ns.LUA_TYPE.TABLE and db.appearance or {}
	db.units = type(db.units) == ns.LUA_TYPE.TABLE and db.units or {}
	db.attached = type(db.attached) == ns.LUA_TYPE.TABLE and db.attached or {}
	db.standalone = type(db.standalone) == ns.LUA_TYPE.TABLE and db.standalone or {}
	db.minimap = type(db.minimap) == ns.LUA_TYPE.TABLE and db.minimap or {}
	db.minimap.angle = clamp(db.minimap.angle, ns.NUMBER.ZERO, ns.MINIMAP_MATH.FULL_CIRCLE_DEGREES, ns.DEFAULTS.minimap.angle)
	db.minimap.hide = db.minimap.hide == true
	if not contains(ns.DISPLAY_MODE_ORDER, db.displayMode) then
		db.displayMode = ns.DEFAULTS.displayMode
	end
	db.locked = db.locked == true

	local appearance = db.appearance
	appearance.iconSize = clamp(appearance.iconSize, ns.LIMITS.ICON_SIZE_MIN, ns.LIMITS.ICON_SIZE_MAX, ns.DEFAULTS.appearance.iconSize)
	appearance.spacing = clamp(appearance.spacing, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, ns.DEFAULTS.appearance.spacing)
	appearance.rowSpacing = clamp(appearance.rowSpacing, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, ns.DEFAULTS.appearance.rowSpacing)
	appearance.maxAuras = math.floor(clamp(appearance.maxAuras, ns.LIMITS.MAX_AURAS_MIN, ns.LIMITS.MAX_AURAS_MAX, ns.DEFAULTS.appearance.maxAuras))
	appearance.scale = clamp(appearance.scale, ns.LIMITS.SCALE_MIN, ns.LIMITS.SCALE_MAX, ns.DEFAULTS.appearance.scale)
	if not contains(ns.LAYOUT_ORDER, appearance.layout) then
		appearance.layout = ns.DEFAULTS.appearance.layout
	end
	if not contains(ns.SORT_RULE_ORDER, appearance.sortRule) then
		appearance.sortRule = ns.DEFAULTS.appearance.sortRule
	end
	if not contains(ns.FILTER_MODE_ORDER, appearance.filterMode) then
		appearance.filterMode = ns.DEFAULTS.appearance.filterMode
	end
	appearance.showCountdown = appearance.showCountdown ~= false
	appearance.showSwipe = appearance.showSwipe ~= false
	appearance.showCounts = appearance.showCounts ~= false
	appearance.showTitles = appearance.showTitles ~= false

	for _, groupKey in ipairs(ns.UNIT_GROUP_ORDER) do
		db.units[groupKey] = type(db.units[groupKey]) == ns.LUA_TYPE.TABLE and db.units[groupKey] or {}
		sanitize_unit_options(db.units[groupKey])
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

function ns.InitDB()
	SimpleBuffsDB = copy_table(ns.DEFAULTS, SimpleBuffsDB or {})
	sanitize_db(SimpleBuffsDB)
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

function ns.GetDisplayMode()
	return ns.DB().displayMode
end

function ns.SetDisplayMode(mode)
	if not contains(ns.DISPLAY_MODE_ORDER, mode) then
		return false
	end
	ns.DB().displayMode = mode
	return true
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
	elseif key == ns.DB_KEY.LAYOUT and contains(ns.LAYOUT_ORDER, value) then
		appearance.layout = value
	elseif key == ns.DB_KEY.SORT_RULE and contains(ns.SORT_RULE_ORDER, value) then
		appearance.sortRule = value
	elseif key == ns.DB_KEY.FILTER_MODE and contains(ns.FILTER_MODE_ORDER, value) then
		appearance.filterMode = value
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

function ns.SetLocked(locked)
	ns.DB().locked = locked == true
	return ns.DB().locked
end

function ns.ToggleLocked()
	return ns.SetLocked(not ns.DB().locked)
end

function ns.GetAttachedPosition(unit)
	return ns.DB().attached[unit]
end

function ns.GetStandalonePosition(unit)
	local groupKey = ns.GetUnitGroup(unit) or unit
	local containerKey = ns.GetStandaloneContainerKey(groupKey)
	return ns.DB().standalone[containerKey]
end

function ns.SaveStandalonePosition(unit, frame)
	if not frame or not ns.DB().standalone[unit] then
		return
	end
	local point, _, relativePoint, x, y = frame:GetPoint(ns.NUMBER.ONE)
	if not point then
		return
	end
	local saved = ns.DB().standalone[unit]
	saved.point = point
	saved.relativePoint = relativePoint or point
	saved.x = x or ns.NUMBER.ZERO
	saved.y = y or ns.NUMBER.ZERO
end

function ns.SetAttachedOffset(unit, x, y)
	local saved = ns.DB().attached[unit]
	if not saved then
		return false
	end
	saved.x = tonumber(x) or saved.x
	saved.y = tonumber(y) or saved.y
	return true
end

function ns.GetMinimapButtonAngle()
	return ns.DB().minimap.angle
end

function ns.SetMinimapButtonAngle(angle)
	ns.DB().minimap.angle = clamp(angle, ns.NUMBER.ZERO, ns.MINIMAP_MATH.FULL_CIRCLE_DEGREES, ns.DEFAULTS.minimap.angle)
	return ns.DB().minimap.angle
end

function ns.IsMinimapButtonHidden()
	return ns.DB().minimap.hide == true
end

function ns.SetMinimapButtonHidden(hidden)
	ns.DB().minimap.hide = hidden == true
	return ns.DB().minimap.hide
end
