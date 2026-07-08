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

-- auraInstanceID is never a Secret Value (only the aura's own fields like
-- .spellId/.name/.duration can be), but it's also ephemeral: it changes each
-- time an aura is reapplied, so it can't be the persistent Manage Auras key.
-- To hide auras during combat without ever reading a live secret spellId,
-- remember each instanceID's spellId whenever it's safe to read (out of
-- combat, or simply not secret this particular pass) and reuse that cached,
-- already-plain value to decide hiding on later passes where the live aura
-- data may be secret. A brand-new hidden aura applied for the first time
-- while already in a restricted context can't be identified yet and will
-- briefly show until it's next seen outside that context - an honest
-- platform limitation, not a bug.
local spellIdByInstance = {}

local function remember_spell_id(unit, auraInstanceID, spellId)
	if not auraInstanceID or not spellId then
		return
	end
	spellIdByInstance[unit] = spellIdByInstance[unit] or {}
	spellIdByInstance[unit][auraInstanceID] = spellId
end

local function recall_spell_id(unit, auraInstanceID)
	local unitCache = spellIdByInstance[unit]
	return unitCache and unitCache[auraInstanceID]
end

local function is_row_hidden(unit, groupKey, row)
	local spellId = recall_spell_id(unit, row.auraInstanceID)
	if not spellId then
		return false
	end
	return ns.IsAuraHidden(groupKey, spellId)
end

local function build_type_model(unit, groupKey, auraType, scanRows)
	local model = {
		unit = unit,
		auraType = auraType,
		rows = {},
		byKey = {},
	}

	for index = 1, #(scanRows or {}) do
		local row = scanRows[index]
		if not is_row_hidden(unit, groupKey, row) then
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
	end

	apply_bar_sort(unit, auraType, model.rows)

	return model
end

-- Discovery uses a separate, uncapped scan (Core/Scanner.lua) so the Manage
-- Auras tab lists every aura that's ever appeared, independent of the unit's
-- current enabled/Filter Mode/Max Auras display settings. aura.spellId/.name
-- can be Secret Values in restricted content (combat, instances, PvP, M+) —
-- reading one successfully doesn't make it safe to use: even comparing a
-- secret value against a literal (== / ~=) throws outside of a pcall, so the
-- whole read-decide-register step for one aura has to be a single pcall unit
-- rather than pcall-guarding just the raw field reads.
local function try_register_discovered_aura(unit, groupKey, auraType, auraInstanceID, aura)
	local spellId = aura and aura.spellId
	local name = aura and aura.name
	if spellId and type(name) == ns.LUA_TYPE.STRING and name ~= ns.TEXT.EMPTY then
		remember_spell_id(unit, auraInstanceID, spellId)
		return ns.RegisterDiscoveredAura(groupKey, auraType, spellId, name)
	end
	return false
end

-- Drop cached entries for instanceIDs that are no longer present, so
-- spellIdByInstance stays bounded to currently-active auras instead of
-- growing for the whole session. An instanceID still returned by the
-- (uncapped) discovery scan counts as active even if its fields are secret
-- this pass, so a cached value survives across combat as long as the aura
-- itself is still applied.
local function prune_spell_id_cache(unit, activeInstanceIds)
	local unitCache = spellIdByInstance[unit]
	if not unitCache then
		return
	end
	for auraInstanceID in pairs(unitCache) do
		if not activeInstanceIds[auraInstanceID] then
			unitCache[auraInstanceID] = nil
		end
	end
end

local function discover_auras(unit, groupKey)
	local discoveredNew = false
	local discoveryScans = ns.ScanUnitAurasForDiscovery(unit)
	local activeInstanceIds = {}
	for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
		local rows = discoveryScans[auraType] or {}
		for index = 1, #rows do
			local row = rows[index]
			if row.auraInstanceID then
				activeInstanceIds[row.auraInstanceID] = true
			end
			local ok, isNew = pcall(try_register_discovered_aura, unit, groupKey, auraType, row.auraInstanceID, row.aura)
			if ok and isNew then
				discoveredNew = true
			end
		end
	end
	prune_spell_id_cache(unit, activeInstanceIds)
	return discoveredNew
end

function ns.BuildAuraKey(unit, auraType, auraInstanceID, fallbackIndex)
	return build_key(unit, auraType, auraInstanceID, fallbackIndex)
end

function ns.RefreshUnitModel(unit)
	if not ns.IsTrackedUnit(unit) then
		return nil
	end

	local runtime = ns.RuntimeEnsure()
	local groupKey = ns.GetUnitGroup(unit) or unit
	local scans = ns.ScanUnitAuras(unit)
	local discoveredNew = discover_auras(unit, groupKey)
	local nextModel = {
		unit = unit,
	}

	for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
		nextModel[auraType] = build_type_model(unit, groupKey, auraType, scans[auraType])
	end

	runtime.models[unit] = nextModel
	runtime.dirtyUnits[unit] = nil

	if discoveredNew and ns.RefreshOptionsPanel then
		ns.RefreshOptionsPanel()
	end

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
