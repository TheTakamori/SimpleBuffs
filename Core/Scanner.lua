SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs
local EMPTY_ROWS = {}

local function get_enum_value(enumTable, key)
	if enumTable and key and enumTable[key] ~= nil then
		return enumTable[key]
	end
	return key
end

local function build_filter(unit, auraType)
	local baseFilter = ns.AURA_FILTER[auraType]
	local mode = ns.GetUnitFilterMode(unit)
	if mode == ns.FILTER_MODE.PLAYER then
		return baseFilter .. "|" .. ns.AURA_FILTER_SUFFIX.PLAYER
	elseif mode == ns.FILTER_MODE.IMPORTANT then
		return baseFilter .. "|" .. ns.AURA_FILTER_SUFFIX.IMPORTANT
	elseif mode == ns.FILTER_MODE.CROWD_CONTROL then
		return baseFilter .. "|" .. ns.AURA_FILTER_SUFFIX.CROWD_CONTROL
	end
	return baseFilter
end

local function get_sort_rule(unit)
	local enumTable = Enum and Enum.UnitAuraSortRule
	return get_enum_value(enumTable, ns.GetUnitSortRule(unit))
end

local function get_sort_direction()
	local enumTable = Enum and Enum.UnitAuraSortDirection
	return get_enum_value(enumTable, ns.AURA_SORT_DIRECTION.NORMAL)
end

local function unit_exists(unit)
	if UnitExists then
		return UnitExists(unit) == true
	end
	return true
end

local function build_scan_row(unit, auraType, auraInstanceID, aura)
	local row = {
		unit = unit,
		auraType = auraType,
		auraInstanceID = auraInstanceID,
		aura = aura,
	}
	if C_UnitAuras and auraInstanceID then
		if C_UnitAuras.GetAuraApplicationDisplayCount then
			row.applicationDisplayCount = C_UnitAuras.GetAuraApplicationDisplayCount(unit, auraInstanceID, ns.AURA_BUTTON.COUNT_MIN, ns.AURA_BUTTON.COUNT_MAX)
		end
		if C_UnitAuras.GetAuraDuration then
			row.durationObject = C_UnitAuras.GetAuraDuration(unit, auraInstanceID)
		end
	end
	return row
end

local function scan_with_instance_ids(unit, auraType)
	if not C_UnitAuras or not C_UnitAuras.GetUnitAuraInstanceIDs then
		return nil
	end

	local maxCount = ns.GetAppearance().maxAuras
	local filter = build_filter(unit, auraType)
	local instanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs(unit, filter, maxCount, get_sort_rule(unit), get_sort_direction())
	local results = {}
	for index = 1, #(instanceIDs or {}) do
		local auraInstanceID = instanceIDs[index]
		local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
		if aura then
			results[#results + 1] = build_scan_row(unit, auraType, auraInstanceID, aura)
		end
	end
	return results
end

local function scan_with_unit_auras(unit, auraType)
	if not C_UnitAuras or not C_UnitAuras.GetUnitAuras then
		return nil
	end

	local maxCount = ns.GetAppearance().maxAuras
	local filter = build_filter(unit, auraType)
	local auras = C_UnitAuras.GetUnitAuras(unit, filter, maxCount, get_sort_rule(unit), get_sort_direction())
	local results = {}
	for index = 1, #(auras or {}) do
		local aura = auras[index]
		if aura then
			results[#results + 1] = build_scan_row(unit, auraType, aura.auraInstanceID, aura)
		end
	end
	return results
end

local function scan_with_index(unit, auraType)
	if not C_UnitAuras then
		return {}
	end

	local getter = auraType == ns.AURA_TYPE.BUFF
		and C_UnitAuras.GetBuffDataByIndex
		or C_UnitAuras.GetDebuffDataByIndex
	if not getter then
		return {}
	end

	local maxCount = ns.GetAppearance().maxAuras
	local filter = build_filter(unit, auraType)
	local results = {}
	for index = 1, maxCount do
		local aura = getter(unit, index, filter)
		if not aura then
			break
		end
		results[#results + 1] = build_scan_row(unit, auraType, aura.auraInstanceID, aura)
	end
	return results
end

function ns.ScanUnitAuraType(unit, auraType)
	if not ns.IsUnitAuraEnabled(unit, auraType) or not unit_exists(unit) then
		return EMPTY_ROWS
	end

	return scan_with_instance_ids(unit, auraType)
		or scan_with_unit_auras(unit, auraType)
		or scan_with_index(unit, auraType)
end

function ns.ScanUnitAuras(unit)
	local result = {}
	for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
		result[auraType] = ns.ScanUnitAuraType(unit, auraType)
	end
	return result
end

function ns.ScanAllAuras()
	local result = {}
	ns.ForEachConfiguredUnit(function(unit)
		result[unit] = ns.ScanUnitAuras(unit)
	end)
	return result
end
