SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local tokenGroup = {}

local function add_unit(units, unit, groupKey)
	units[#units + 1] = unit
	tokenGroup[unit] = groupKey
	if not ns.UNIT_LABEL[unit] then
		local number = unit:match("(%d+)$")
		local prefix = number and unit:sub(1, #unit - #number) or unit
		local groupLabel = ns.UNIT_GROUP_LABEL[groupKey] or prefix
		ns.UNIT_LABEL[unit] = number and (groupLabel .. " " .. number) or groupLabel
	end
end

local function build_static_units()
	local units = {}
	tokenGroup = {}
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

	local prefix = unit:match("^([%a]+)%d+$")
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
	local container = ns.UNIT_GROUP_CONTAINER[groupKey] or groupKey
	if container == "Enemy/Boss/Arena" then
		return "enemy"
	end
	return groupKey
end

function ns.IsTrackedUnit(unit)
	return ns.GetUnitGroup(unit) ~= nil
end

function ns.GetConfiguredUnits()
	local units = {}
	for index = 1, #ns.UNIT_ORDER do
		units[#units + 1] = ns.UNIT_ORDER[index]
	end

	return units
end

function ns.ForEachConfiguredUnit(callback)
	for index = 1, #ns.UNIT_ORDER do
		callback(ns.UNIT_ORDER[index])
	end
end
