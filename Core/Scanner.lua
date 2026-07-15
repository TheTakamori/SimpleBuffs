SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs
local filterCache = {}

local function get_enum_value(enumTable, key)
	if enumTable and key and enumTable[key] ~= nil then
		return enumTable[key]
	end
	return key
end

local function build_filter(unit, auraType)
	local baseFilter = ns.AURA_FILTER[auraType]
	local mode = ns.GetUnitFilterMode(unit, auraType)
	local groupKey = ns.GetUnitGroup(unit) or unit
	filterCache[groupKey] = filterCache[groupKey] or {}
	filterCache[groupKey][auraType] = filterCache[groupKey][auraType] or {}
	if filterCache[groupKey][auraType][mode] then
		return filterCache[groupKey][auraType][mode]
	end
	local filter = baseFilter
	if mode == ns.FILTER_MODE.PLAYER then
		filter = baseFilter .. ns.AURA_FILTER_SEPARATOR .. ns.AURA_FILTER_SUFFIX.PLAYER
	elseif mode == ns.FILTER_MODE.IMPORTANT then
		filter = baseFilter .. ns.AURA_FILTER_SEPARATOR .. ns.AURA_FILTER_SUFFIX.IMPORTANT
	elseif mode == ns.FILTER_MODE.CROWD_CONTROL then
		filter = baseFilter .. ns.AURA_FILTER_SEPARATOR .. ns.AURA_FILTER_SUFFIX.CROWD_CONTROL
	end
	filterCache[groupKey][auraType][mode] = filter
	return filter
end

local BAR_SORT_NATIVE_RULE = {
	[ns.BAR_SORT.ALPHA_ASC] = ns.SORT_RULE.NAME_ONLY,
	[ns.BAR_SORT.ALPHA_DESC] = ns.SORT_RULE.NAME_ONLY,
	[ns.BAR_SORT.TIME_LEFT_ASC] = ns.SORT_RULE.EXPIRATION,
	[ns.BAR_SORT.TIME_LEFT_DESC] = ns.SORT_RULE.EXPIRATION,
	[ns.BAR_SORT.MAX_DURATION_ASC] = ns.SORT_RULE.DEFAULT,
	[ns.BAR_SORT.MAX_DURATION_DESC] = ns.SORT_RULE.DEFAULT,
}

local function get_sort_rule(unit, auraType)
	local enumTable = Enum and Enum.UnitAuraSortRule
	if ns.GetUnitStyle(unit, auraType) == ns.AURA_STYLE.BAR then
		local nativeRule = BAR_SORT_NATIVE_RULE[ns.GetUnitBarSort(unit, auraType)] or ns.SORT_RULE.DEFAULT
		return get_enum_value(enumTable, nativeRule)
	end
	return get_enum_value(enumTable, ns.GetUnitSortRule(unit, auraType))
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

local function scan_with_instance_ids(unit, auraType, filter, maxCount, sortRule)
	if not C_UnitAuras or not C_UnitAuras.GetUnitAuraInstanceIDs then
		return nil
	end

	local instanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs(unit, filter, maxCount, sortRule, get_sort_direction())
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

local function scan_with_unit_auras(unit, auraType, filter, maxCount, sortRule)
	if not C_UnitAuras or not C_UnitAuras.GetUnitAuras then
		return nil
	end

	local auras = C_UnitAuras.GetUnitAuras(unit, filter, maxCount, sortRule, get_sort_direction())
	local results = {}
	for index = 1, #(auras or {}) do
		local aura = auras[index]
		if aura then
			results[#results + 1] = build_scan_row(unit, auraType, aura.auraInstanceID, aura)
		end
	end
	return results
end

local function scan_with_index(unit, auraType, filter, maxCount)
	if not C_UnitAuras then
		return {}
	end

	local getter = auraType == ns.AURA_TYPE.BUFF
		and C_UnitAuras.GetBuffDataByIndex
		or C_UnitAuras.GetDebuffDataByIndex
	if not getter then
		return {}
	end

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

-- Sample data for the Simulate preview: a small, deliberately varied set per
-- aura type (long/short duration, near-full/near-expired, with and without
-- stacks) so a unit tab's current Style/Layout/Sort/Filter settings can be
-- previewed even when the unit currently has no real auras. "remaining" is
-- seconds left; "duration" is the total/base duration those seconds are out
-- of, so some samples render as a mostly-full bar and some as nearly spent.
local SAMPLE_AURAS = {
	[ns.AURA_TYPE.BUFF] = {
		{ name = "Well Fed", icon = "Interface\\Icons\\INV_Misc_Food_15", duration = 3600, remaining = 3600 },
		{ name = "Arcane Intellect", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry", duration = 3600, remaining = 1800 },
		{ name = "Renewing Mist", icon = "Interface\\Icons\\Spell_Monk_RenewingMist", duration = 12, remaining = 8, applications = 3 },
		{ name = "Battle Shout", icon = "Interface\\Icons\\Ability_Warrior_BattleShout", duration = 30, remaining = 30 },
		{ name = "Ice Barrier", icon = "Interface\\Icons\\Spell_Frost_ArcticWinds", duration = 60, remaining = 4 },
		{ name = "Power Word: Fortitude", icon = "Interface\\Icons\\Spell_Holy_WordFortitude", duration = 3600, remaining = 3599 },
	},
	[ns.AURA_TYPE.DEBUFF] = {
		{ name = "Curse of Weakness", icon = "Interface\\Icons\\Spell_Shadow_CurseOfMannoroth", duration = 120, remaining = 90 },
		{ name = "Rend", icon = "Interface\\Icons\\Ability_Gouge", duration = 15, remaining = 9, applications = 3 },
		{ name = "Chilled", icon = "Interface\\Icons\\Spell_Frost_FrostArmor02", duration = 5, remaining = 1 },
		{ name = "Corruption", icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", duration = 18, remaining = 18 },
		{ name = "Polymorph", icon = "Interface\\Icons\\Spell_Nature_Polymorph", duration = 8, remaining = 6 },
		{ name = "Weakened Soul", icon = "Interface\\Icons\\Spell_Holy_PainSupression", duration = 15, remaining = 15 },
	},
}

local SAMPLE_SPELL_ID_BASE = 900000
local ROUND_HALF = 0.5

-- Ties the visible sample count to Core/Runtime.lua's Simulate phase, so the
-- preview cycles through fewer/more sample auras over time instead of
-- always showing every sample at once - this is what actually demonstrates
-- container growth/shrink behavior (e.g. Bar Anchor Top/Bottom) to the user.
local function simulated_sample_count(total)
	local fractions = ns.SIMULATE.GROWTH_FRACTIONS
	local phase = (ns.GetSimulatePhase and ns.GetSimulatePhase() or ns.NUMBER.ZERO) % #fractions
	local count = math.floor(total * fractions[phase + ns.LAYOUT_METRIC.INDEX_OFFSET] + ROUND_HALF)
	return math.max(ns.NUMBER.ONE, math.min(total, count))
end

local function build_sample_rows(unit, auraType)
	local samples = SAMPLE_AURAS[auraType] or {}
	local count = simulated_sample_count(#samples)
	local now = GetTime and GetTime() or ns.NUMBER.ZERO
	local results = {}
	for index = 1, count do
		local sample = samples[index]
		local spellId = SAMPLE_SPELL_ID_BASE + index
		results[index] = {
			unit = unit,
			auraType = auraType,
			auraInstanceID = spellId,
			applicationDisplayCount = sample.applications,
			aura = {
				name = sample.name,
				icon = sample.icon,
				duration = sample.duration,
				expirationTime = now + sample.remaining,
				timeMod = ns.AURA_BUTTON.FALLBACK_MOD_RATE,
				applications = sample.applications or ns.NUMBER.ONE,
				spellId = spellId,
				isSimulated = true,
			},
		}
	end
	return results
end

function ns.ScanUnitAuraType(unit, auraType)
	if not ns.IsUnitAuraEnabled(unit, auraType) or not unit_exists(unit) then
		return {}
	end

	if ns.IsSimulateEnabled((ns.GetUnitGroup(unit) or unit), auraType) then
		return build_sample_rows(unit, auraType)
	end

	local filter = build_filter(unit, auraType)
	local maxCount = ns.GetUnitMaxAuras(unit, auraType)
	local sortRule = get_sort_rule(unit, auraType)
	local rows = scan_with_instance_ids(unit, auraType, filter, maxCount, sortRule)
		or scan_with_unit_auras(unit, auraType, filter, maxCount, sortRule)
		or scan_with_index(unit, auraType, filter, maxCount)

	-- Weapon enchants (oils, stones, Windfury Weapon, etc.) never come back
	-- from the UnitAura scans above - see Core/WeaponEnchant.lua - so they're
	-- appended here, capped to the same Max Auras budget as everything else.
	if auraType == ns.AURA_TYPE.BUFF and unit == ns.UNIT_TOKEN.PLAYER and ns.ScanWeaponEnchantRows then
		local weaponRows = ns.ScanWeaponEnchantRows()
		for index = 1, #weaponRows do
			if #rows >= maxCount then
				break
			end
			rows[#rows + 1] = weaponRows[index]
		end
	end

	return rows
end

function ns.ScanUnitAuras(unit)
	local result = {}
	for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
		result[auraType] = ns.ScanUnitAuraType(unit, auraType)
	end
	return result
end

-- Discovery bypasses the unit's enabled-toggle, Filter Mode suffix, and
-- configured Max Auras so the Manage Auras tab can list every aura that's
-- ever appeared, independent of what's currently configured to display.
function ns.ScanUnitAuraTypeForDiscovery(unit, auraType)
	if not unit_exists(unit) then
		return {}
	end

	local filter = ns.AURA_FILTER[auraType]
	local maxCount = ns.LIMITS.MAX_AURAS_MAX
	local sortRule = get_enum_value(Enum and Enum.UnitAuraSortRule, ns.SORT_RULE.DEFAULT)
	return scan_with_instance_ids(unit, auraType, filter, maxCount, sortRule)
		or scan_with_unit_auras(unit, auraType, filter, maxCount, sortRule)
		or scan_with_index(unit, auraType, filter, maxCount)
end

function ns.ScanUnitAurasForDiscovery(unit)
	local result = {}
	for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
		result[auraType] = ns.ScanUnitAuraTypeForDiscovery(unit, auraType)
	end
	return result
end

