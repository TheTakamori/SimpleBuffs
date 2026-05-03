SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local UNKNOWN_KEY_PART = "unknown"

local function build_key(unit, auraType, auraInstanceID, fallbackIndex)
	return (unit or UNKNOWN_KEY_PART) .. ":" .. (auraType or UNKNOWN_KEY_PART) .. ":" .. tostring(auraInstanceID or fallbackIndex or UNKNOWN_KEY_PART)
end

local function build_type_model(unit, auraType, scanRows)
	local model = {
		unit = unit,
		auraType = auraType,
		rows = {},
		byKey = {},
	}

	for index = 1, #(scanRows or {}) do
		local row = scanRows[index]
		local key = build_key(unit, auraType, row.auraInstanceID, index)
		local entry = {
			key = key,
			unit = unit,
			auraType = auraType,
			index = index,
			auraInstanceID = row.auraInstanceID,
			applicationDisplayCount = row.applicationDisplayCount,
			durationObject = row.durationObject,
			aura = row.aura,
		}
		model.rows[#model.rows + 1] = entry
		model.byKey[key] = entry
	end

	return model
end

function ns.BuildAuraKey(unit, auraType, auraInstanceID, fallbackIndex)
	return build_key(unit, auraType, auraInstanceID, fallbackIndex)
end

function ns.RefreshUnitModel(unit)
	if not ns.IsTrackedUnit(unit) then
		return nil
	end

	local runtime = ns.RuntimeEnsure()
	local scans = ns.ScanUnitAuras(unit)
	local nextModel = {
		unit = unit,
	}

	for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
		nextModel[auraType] = build_type_model(unit, auraType, scans[auraType])
	end

	runtime.models[unit] = nextModel
	runtime.dirtyUnits[unit] = nil
	return nextModel
end

function ns.GetUnitModel(unit)
	local runtime = ns.RuntimeEnsure()
	return runtime.models[unit] or ns.RefreshUnitModel(unit)
end

function ns.RefreshAllModels()
	ns.ForEachConfiguredUnit(function(unit)
		ns.RefreshUnitModel(unit)
	end)
end

function ns.MarkUnitDirty(unit)
	if not ns.IsTrackedUnit(unit) then
		return
	end
	local runtime = ns.RuntimeEnsure()
	if runtime.dirtyUnits[unit] then
		return
	end
	runtime.dirtyUnits[unit] = true
	runtime.dirtyUnitList[#runtime.dirtyUnitList + 1] = unit
end
