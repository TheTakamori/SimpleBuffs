SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local tokenGroup = {}
local groupUnits = {}
local containerUnits = {}

local function get_standalone_container_key(groupKey)
	local container = ns.UNIT_GROUP_CONTAINER[groupKey] or groupKey
	if container == ns.CONTAINER_LABEL.ENEMY then
		return ns.STANDALONE_CONTAINER_KEY.ENEMY
	end
	return groupKey
end

local function add_unit(units, unit, groupKey)
	units[#units + 1] = unit
	groupUnits[groupKey] = groupUnits[groupKey] or {}
	groupUnits[groupKey][#groupUnits[groupKey] + 1] = unit
	local containerKey = get_standalone_container_key(groupKey)
	containerUnits[containerKey] = containerUnits[containerKey] or {}
	containerUnits[containerKey][#containerUnits[containerKey] + 1] = unit
	tokenGroup[unit] = groupKey
	if not ns.UNIT_LABEL[unit] then
		local number = unit:match(ns.PATTERN.UNIT_NUMBER_SUFFIX)
		local prefix = number and unit:sub(1, #unit - #number) or unit
		local groupLabel = ns.UNIT_GROUP_LABEL[groupKey] or prefix
		ns.UNIT_LABEL[unit] = number and (groupLabel .. " " .. number) or groupLabel
	end
end

local function build_static_units()
	local units = {}
	tokenGroup = {}
	groupUnits = {}
	containerUnits = {}
	for _, groupKey in ipairs(ns.UNIT_GROUP_ORDER) do
		local definition = ns.UNIT_GROUP_DEFINITIONS[groupKey]
		if definition.tokens then
			for index = 1, #definition.tokens do
				add_unit(units, definition.tokens[index], groupKey)
			end
		elseif definition.prefix and not definition.dynamic then
			for index = 1, definition.count do
				add_unit(units, definition.prefix .. index, groupKey)
			end
		end
	end
	return units
end

ns.UNIT_ORDER = build_static_units()

function ns.GetUnitGroup(unit)
	if not unit then
		return nil
	end

	local groupKey = tokenGroup[unit]
	if groupKey then
		return groupKey
	end

	local prefix = unit:match(ns.PATTERN.UNIT_PREFIX_WITH_NUMBER)
	if prefix then
		for _, groupKey in ipairs(ns.UNIT_GROUP_ORDER) do
			local definition = ns.UNIT_GROUP_DEFINITIONS[groupKey]
			if definition.prefix == prefix then
				tokenGroup[unit] = groupKey
				return groupKey
			end
		end
	end

	return nil
end

function ns.GetStandaloneContainerKey(groupKey)
	return get_standalone_container_key(groupKey)
end

function ns.IsTrackedUnit(unit)
	return ns.GetUnitGroup(unit) ~= nil
end

function ns.ForEachConfiguredUnit(callback)
	for index = 1, #ns.UNIT_ORDER do
		callback(ns.UNIT_ORDER[index])
	end
end

function ns.ForEachUnitInGroup(groupKey, callback)
	local units = groupUnits[groupKey] or {}
	for index = 1, #units do
		callback(units[index])
	end
end

function ns.ForEachUnitInStandaloneContainer(containerKey, callback)
	local units = containerUnits[containerKey] or {}
	for index = 1, #units do
		callback(units[index])
	end
end
