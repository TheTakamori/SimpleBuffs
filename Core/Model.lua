SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local UNKNOWN_KEY_PART = "unknown"

local function build_key(unit, auraType, auraInstanceID, fallbackIndex)
	return (unit or UNKNOWN_KEY_PART) .. ":" .. (auraType or UNKNOWN_KEY_PART) .. ":" .. tostring(auraInstanceID or fallbackIndex or UNKNOWN_KEY_PART)
end

local function reverse_rows(rows)
	local count = #rows
	for index = 1, math.floor(count / 2) do
		rows[index], rows[count - index + 1] = rows[count - index + 1], rows[index]
	end
end

-- aura.duration can be a Secret Value in restricted content (combat, instances,
-- PvP, M+); read it defensively and bail out of the whole comparison rather
-- than risk table.sort erroring midway through and leaving rows half-swapped.
local function collect_durations(rows)
	local durations = {}
	for index = 1, #rows do
		local ok, duration = pcall(function()
			return rows[index].aura and rows[index].aura.duration
		end)
		if not ok or type(duration) ~= "number" then
			return nil
		end
		durations[index] = duration
	end
	return durations
end

local function sort_by_max_duration(rows, ascending)
	local durations = collect_durations(rows)
	if not durations then
		return
	end
	local order = {}
	for index = 1, #rows do
		order[index] = index
	end
	table.sort(order, function(left, right)
		if ascending then
			return durations[left] < durations[right]
		end
		return durations[left] > durations[right]
	end)
	local sorted = {}
	for index = 1, #order do
		sorted[index] = rows[order[index]]
	end
	for index = 1, #rows do
		rows[index] = sorted[index]
	end
end

local function apply_bar_sort(unit, auraType, rows)
	if ns.GetUnitStyle(unit, auraType) ~= ns.AURA_STYLE.BAR then
		return
	end
	local barSort = ns.GetUnitBarSort(unit, auraType)
	if barSort == ns.BAR_SORT.ALPHA_DESC or barSort == ns.BAR_SORT.TIME_LEFT_DESC then
		reverse_rows(rows)
	elseif barSort == ns.BAR_SORT.MAX_DURATION_ASC then
		sort_by_max_duration(rows, true)
	elseif barSort == ns.BAR_SORT.MAX_DURATION_DESC then
		sort_by_max_duration(rows, false)
	end
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

	apply_bar_sort(unit, auraType, model.rows)

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
