SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

-- Persistent per-unit-group registry of every aura ever seen (the Manage
-- Auras tab's data): discovery, hide/forget state, and the filtered/sorted
-- view model. Display settings accessors stay in Core/State.lua.

function ns.GetUnitGroupKnownAuras(groupKey)
	local options = ns.GetUnitGroupOptions(groupKey)
	if not options or type(options.knownAuras) ~= ns.LUA_TYPE.TABLE then
		return {}
	end
	return options.knownAuras
end

function ns.RegisterDiscoveredAura(groupKey, auraType, spellId, name)
	local options = ns.GetUnitGroupOptions(groupKey)
	if not options or not ns.AURA_FILTER[auraType] or not spellId or type(name) ~= ns.LUA_TYPE.STRING or name == ns.TEXT.EMPTY then
		return false
	end
	options.knownAuras = type(options.knownAuras) == ns.LUA_TYPE.TABLE and options.knownAuras or {}
	local key = tostring(spellId)
	local entry = options.knownAuras[key]
	local now = time()
	if entry then
		entry.name = name
		entry.lastSeenAt = now
		return false
	end
	options.knownAuras[key] = {
		name = name,
		auraType = auraType,
		hidden = false,
		firstSeenAt = now,
		lastSeenAt = now,
	}
	return true
end

function ns.GetUnitGroupManageFilter(groupKey)
	local options = ns.GetUnitGroupOptions(groupKey)
	return (options and options.manageFilter) or ns.DEFAULTS.units[groupKey].manageFilter
end

function ns.SetUnitGroupManageFilter(groupKey, filter)
	if not ns.GetUnitGroupOptions(groupKey) or not ns.IsKnownValue(ns.MANAGE_FILTER_ORDER, filter) then
		return false
	end
	ns.DB().units[groupKey].manageFilter = filter
	return true
end

function ns.GetUnitGroupManageSort(groupKey)
	local options = ns.GetUnitGroupOptions(groupKey)
	return (options and options.manageSort) or ns.DEFAULTS.units[groupKey].manageSort
end

function ns.SetUnitGroupManageSort(groupKey, sortMode)
	if not ns.GetUnitGroupOptions(groupKey) or not ns.IsKnownValue(ns.MANAGE_SORT_ORDER, sortMode) then
		return false
	end
	ns.DB().units[groupKey].manageSort = sortMode
	return true
end

function ns.IsAuraHidden(groupKey, spellId)
	local entry = ns.GetUnitGroupKnownAuras(groupKey)[tostring(spellId)]
	return entry ~= nil and entry.hidden == true
end

function ns.SetAuraHidden(groupKey, spellId, hidden)
	local entry = ns.GetUnitGroupKnownAuras(groupKey)[tostring(spellId)]
	if not entry then
		return false
	end
	entry.hidden = hidden == true
	return true
end

function ns.ForgetAura(groupKey, spellId)
	local knownAuras = ns.GetUnitGroupKnownAuras(groupKey)
	local key = tostring(spellId)
	if not knownAuras[key] then
		return false
	end
	knownAuras[key] = nil
	return true
end

-- "firstSeenAt"/"lastSeenAt" are the saved known-aura entry field names.
local MANAGE_SORT_TIMESTAMP_FIELD = {
	[ns.MANAGE_SORT.FIRST_SEEN_ASC] = { field = "firstSeenAt", ascending = true },
	[ns.MANAGE_SORT.FIRST_SEEN_DESC] = { field = "firstSeenAt", ascending = false },
	[ns.MANAGE_SORT.LAST_SEEN_ASC] = { field = "lastSeenAt", ascending = true },
	[ns.MANAGE_SORT.LAST_SEEN_DESC] = { field = "lastSeenAt", ascending = false },
}

local function compare_alpha(left, right, ascending)
	local leftName, rightName = left.name:lower(), right.name:lower()
	if leftName == rightName then
		if ascending then
			return left.spellId < right.spellId
		end
		return left.spellId > right.spellId
	end
	if ascending then
		return leftName < rightName
	end
	return leftName > rightName
end

local function manage_sort_comparator(sortMode)
	if sortMode == ns.MANAGE_SORT.ALPHA_DESC then
		return function(left, right)
			return compare_alpha(left, right, false)
		end
	end
	local timestamp = MANAGE_SORT_TIMESTAMP_FIELD[sortMode]
	if timestamp then
		return function(left, right)
			local leftValue, rightValue = left[timestamp.field], right[timestamp.field]
			if leftValue == rightValue then
				return left.spellId < right.spellId
			end
			if timestamp.ascending then
				return leftValue < rightValue
			end
			return leftValue > rightValue
		end
	end
	return function(left, right)
		return compare_alpha(left, right, true)
	end
end

function ns.GetSortedKnownAuraEntries(groupKey, filter, sortMode)
	filter = ns.IsKnownValue(ns.MANAGE_FILTER_ORDER, filter) and filter or ns.MANAGE_FILTER.BOTH
	sortMode = ns.IsKnownValue(ns.MANAGE_SORT_ORDER, sortMode) and sortMode or ns.MANAGE_SORT.ALPHA_ASC
	local knownAuras = ns.GetUnitGroupKnownAuras(groupKey)
	local entries = {}
	for spellIdKey, entry in pairs(knownAuras) do
		if filter == ns.MANAGE_FILTER.BOTH or entry.auraType == filter then
			entries[#entries + 1] = {
				spellId = spellIdKey,
				name = entry.name,
				auraType = entry.auraType,
				hidden = entry.hidden == true,
				firstSeenAt = entry.firstSeenAt or ns.NUMBER.ZERO,
				lastSeenAt = entry.lastSeenAt or ns.NUMBER.ZERO,
			}
		end
	end
	table.sort(entries, manage_sort_comparator(sortMode))
	return entries
end
