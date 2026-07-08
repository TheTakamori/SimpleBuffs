---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

local function aura(id, name)
	return {
		auraInstanceID = id,
		name = name,
		icon = 1,
		duration = 10,
		expirationTime = 20,
		timeMod = 1,
		applications = 1,
	}
end

return function(runner, ns)
	runner:test("ScanUnitAuraType returns independent empty rows", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		ns.SetUnitGroupAuraEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)

		local first = ns.ScanUnitAuraType(ns.UNIT_TOKEN.PLAYER, ns.AURA_TYPE.BUFF)
		local second = ns.ScanUnitAuraType(ns.UNIT_TOKEN.PLAYER, ns.AURA_TYPE.BUFF)

		assert.equal(first == second, false)
		assert.equal(#first, 0)
		assert.equal(#second, 0)
	end)

	runner:test("ScanUnitAuraType reads focus buffs with bounded filters", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		local captured = {}
		rawset(_G, "UnitExists", function(unit)
			return unit == "focus"
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function(unit, filter, maxCount, sortRule, sortDirection)
				captured = {
					unit = unit,
					filter = filter,
					maxCount = maxCount,
					sortRule = sortRule,
					sortDirection = sortDirection,
				}
				return { 11, 12 }
			end,
			GetAuraDataByAuraInstanceID = function(_, auraInstanceID)
				return aura(auraInstanceID, "Aura " .. tostring(auraInstanceID))
			end,
			GetAuraApplicationDisplayCount = function(_, auraInstanceID)
				return auraInstanceID
			end,
			GetAuraDuration = function(_, auraInstanceID)
				return "duration-" .. tostring(auraInstanceID)
			end,
		})

		local rows = ns.ScanUnitAuraType("focus", ns.AURA_TYPE.BUFF)

		assert.equal(#rows, 2)
		assert.equal(rows[1].auraInstanceID, 11)
		assert.equal(rows[2].aura.name, "Aura 12")
		assert.equal(rows[2].applicationDisplayCount, 12)
		assert.equal(rows[2].durationObject, "duration-12")
		assert.equal(captured.unit, "focus")
		assert.equal(captured.filter, "HELPFUL")
		assert.equal(captured.maxCount, ns.DEFAULTS.units.focus.aura.buff.maxAuras)
		assert.equal(captured.sortRule, ns.SORT_RULE.EXPIRATION)
		assert.equal(captured.sortDirection, "Normal")
	end)

	runner:test("ScanUnitAuraType includes optional filter mode", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		ns.SetUnitGroupFilterMode(ns.UNIT_GROUP.PET, ns.AURA_TYPE.DEBUFF, ns.FILTER_MODE.PLAYER)

		local capturedFilter
		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function(_, filter)
				capturedFilter = filter
				return {}
			end,
			GetAuraDataByAuraInstanceID = function()
				return nil
			end,
		})

		ns.ScanUnitAuraType("pet", ns.AURA_TYPE.DEBUFF)

		assert.equal(capturedFilter, "HARMFUL|PLAYER")
	end)

	runner:test("ScanUnitAuraType uses per-group max aura count", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PARTY, ns.AURA_TYPE.BUFF, ns.DB_KEY.MAX_AURAS, 7)

		local capturedMaxCount
		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function(_, _, maxCount)
				capturedMaxCount = maxCount
				return {}
			end,
			GetAuraDataByAuraInstanceID = function()
				return nil
			end,
		})

		ns.ScanUnitAuraType("party1", ns.AURA_TYPE.BUFF)

		assert.equal(capturedMaxCount, 7)
	end)


	runner:test("ScanUnitAuraType maps every per-group filter mode", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		local captured = {}
		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function(_, filter)
				captured[#captured + 1] = filter
				return {}
			end,
			GetAuraDataByAuraInstanceID = function()
				return nil
			end,
		})

		local cases = {
			{ ns.FILTER_MODE.ALL, "HELPFUL" },
			{ ns.FILTER_MODE.PLAYER, "HELPFUL|PLAYER" },
			{ ns.FILTER_MODE.IMPORTANT, "HELPFUL|IMPORTANT" },
			{ ns.FILTER_MODE.CROWD_CONTROL, "HELPFUL|CROWD_CONTROL" },
		}
		for index = 1, #cases do
			ns.SetUnitGroupFilterMode(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, cases[index][1])
			ns.ScanUnitAuraType("pet", ns.AURA_TYPE.BUFF)
			assert.equal(captured[index], cases[index][2])
		end
	end)

	runner:test("ScanUnitAuraType maps per-group sort rules", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		local captured = {}
		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function(_, _, _, sortRule)
				captured[#captured + 1] = sortRule
				return {}
			end,
			GetAuraDataByAuraInstanceID = function()
				return nil
			end,
		})

		for index = 1, #ns.SORT_RULE_ORDER do
			ns.SetUnitGroupSortRule(ns.UNIT_GROUP.PARTY, ns.AURA_TYPE.BUFF, ns.SORT_RULE_ORDER[index])
			ns.ScanUnitAuraType("party1", ns.AURA_TYPE.BUFF)
			assert.equal(captured[index], ns.SORT_RULE_ORDER[index])
		end
	end)

	runner:test("ScanUnitAuraType picks native rule from Bar Sort when style is bar", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PARTY, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)

		local captured = {}
		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function(_, _, _, sortRule)
				captured[#captured + 1] = sortRule
				return {}
			end,
			GetAuraDataByAuraInstanceID = function()
				return nil
			end,
		})

		local cases = {
			{ ns.BAR_SORT.ALPHA_ASC, ns.SORT_RULE.NAME_ONLY },
			{ ns.BAR_SORT.ALPHA_DESC, ns.SORT_RULE.NAME_ONLY },
			{ ns.BAR_SORT.TIME_LEFT_ASC, ns.SORT_RULE.EXPIRATION },
			{ ns.BAR_SORT.TIME_LEFT_DESC, ns.SORT_RULE.EXPIRATION },
			{ ns.BAR_SORT.MAX_DURATION_ASC, ns.SORT_RULE.DEFAULT },
			{ ns.BAR_SORT.MAX_DURATION_DESC, ns.SORT_RULE.DEFAULT },
		}
		for index = 1, #cases do
			ns.SetUnitGroupBarSort(ns.UNIT_GROUP.PARTY, ns.AURA_TYPE.BUFF, cases[index][1])
			ns.ScanUnitAuraType("party1", ns.AURA_TYPE.BUFF)
			assert.equal(captured[index], cases[index][2])
		end
	end)

	runner:test("ScanUnitAuraType returns empty rows for missing units", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		rawset(_G, "UnitExists", function()
			return false
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function()
				error("scanner should not query missing units")
			end,
		})

		local rows = ns.ScanUnitAuraType("pet", ns.AURA_TYPE.BUFF)

		assert.equal(#rows, 0)
	end)

	runner:test("ScanUnitAuraType falls back to index APIs", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetBuffDataByIndex = function(unit, index, filter)
				if unit == "pet" and filter == "HELPFUL" and index == 1 then
					return aura(31, "Fallback Buff")
				end
				return nil
			end,
		})

		local rows = ns.ScanUnitAuraType("pet", ns.AURA_TYPE.BUFF)

		assert.equal(#rows, 1)
		assert.equal(rows[1].auraInstanceID, 31)
		assert.equal(rows[1].aura.name, "Fallback Buff")
	end)

	runner:test("ScanUnitAuraTypeForDiscovery ignores enabled toggle, filter suffix, and configured max", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		ns.SetUnitGroupAuraEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
		ns.SetUnitGroupFilterMode(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.FILTER_MODE.PLAYER)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.DB_KEY.MAX_AURAS, 3)

		local captured = {}
		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function(_, filter, maxCount)
				captured.filter = filter
				captured.maxCount = maxCount
				return { 1, 2 }
			end,
			GetAuraDataByAuraInstanceID = function(_, auraInstanceID)
				return aura(auraInstanceID, "Aura " .. tostring(auraInstanceID))
			end,
		})

		local rows = ns.ScanUnitAuraTypeForDiscovery("player", ns.AURA_TYPE.BUFF)

		assert.equal(#rows, 2)
		assert.equal(captured.filter, "HELPFUL")
		assert.equal(captured.maxCount, ns.LIMITS.MAX_AURAS_MAX)
	end)

	runner:test("ScanUnitAuraTypeForDiscovery returns empty rows for missing units", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		rawset(_G, "UnitExists", function()
			return false
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function()
				error("discovery scan should not query missing units")
			end,
		})

		local rows = ns.ScanUnitAuraTypeForDiscovery("pet", ns.AURA_TYPE.BUFF)

		assert.equal(#rows, 0)
	end)

	runner:test("ScanUnitAurasForDiscovery covers both aura types", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function(_, filter)
				if filter == "HELPFUL" then
					return { 1 }
				end
				return { 2 }
			end,
			GetAuraDataByAuraInstanceID = function(_, auraInstanceID)
				return aura(auraInstanceID, "Aura " .. tostring(auraInstanceID))
			end,
		})

		local result = ns.ScanUnitAurasForDiscovery("player")

		assert.equal(#result.buff, 1)
		assert.equal(#result.debuff, 1)
	end)

	runner:test("Simulate is off by default and resets per group/aura type", function()
		assert.equal(ns.IsSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), false)

		assert.equal(ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true), true)
		assert.equal(ns.IsSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), true)
		assert.equal(ns.IsSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.DEBUFF), false)
		assert.equal(ns.IsSimulateEnabled(ns.UNIT_GROUP.TARGET, ns.AURA_TYPE.BUFF), false)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
		assert.equal(ns.IsSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), false)
	end)

	runner:test("Simulate phase advances and resets to 0 whenever freshly enabled", function()
		assert.equal(ns.GetSimulatePhase(), 0)

		ns.AdvanceSimulatePhase()
		ns.AdvanceSimulatePhase()
		assert.equal(ns.GetSimulatePhase(), 2)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)
		assert.equal(ns.GetSimulatePhase(), 0)

		ns.AdvanceSimulatePhase()
		assert.equal(ns.GetSimulatePhase(), 1)

		-- Phase wraps rather than growing unbounded.
		for _ = 1, #ns.SIMULATE.GROWTH_FRACTIONS do
			ns.AdvanceSimulatePhase()
		end
		assert.equal(ns.GetSimulatePhase() < #ns.SIMULATE.GROWTH_FRACTIONS, true)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
	end)

	runner:test("ScanUnitAuraType returns varied sample rows when Simulate is enabled", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)

		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function()
				error("Simulate should bypass the real scan APIs entirely")
			end,
		})

		-- Simulate's phase resets to 0 (the smallest sample count) whenever
		-- it's freshly enabled; advance to the full-count phase so this
		-- assertion sees the whole deliberately-varied sample set.
		while ns.GetSimulatePhase() ~= #ns.SIMULATE.GROWTH_FRACTIONS - ns.NUMBER.TWO do
			ns.AdvanceSimulatePhase()
		end

		local rows = ns.ScanUnitAuraType("player", ns.AURA_TYPE.BUFF)

		assert.equal(#rows > 0, true)
		local sawStacks, sawSingle = false, false
		for index = 1, #rows do
			local row = rows[index]
			assert.equal(row.unit, "player")
			assert.equal(row.auraType, ns.AURA_TYPE.BUFF)
			assert.equal(type(row.aura.name), "string")
			assert.equal(type(row.aura.icon), "string")
			assert.equal(row.aura.isSimulated, true)
			assert.equal(row.aura.duration ~= nil, true)
			assert.equal(row.aura.expirationTime ~= nil, true)
			if row.applicationDisplayCount then
				sawStacks = true
			else
				sawSingle = true
			end
		end
		-- The sample set is deliberately varied (some stacking, some not).
		assert.equal(sawStacks, true)
		assert.equal(sawSingle, true)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
	end)

	runner:test("ScanUnitAuraType cycles the sample count as Simulate's phase advances", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)

		local counts = {}
		for _ = 1, #ns.SIMULATE.GROWTH_FRACTIONS do
			counts[#counts + 1] = #ns.ScanUnitAuraType("player", ns.AURA_TYPE.BUFF)
			ns.AdvanceSimulatePhase()
		end

		-- Enabling Simulate always starts at phase 0 (the smallest count);
		-- the cycle should grow to the full sample set and shrink back down
		-- rather than staying fixed, so the display visibly resizes.
		local minCount, maxCount = counts[1], counts[1]
		for index = 2, #counts do
			minCount = math.min(minCount, counts[index])
			maxCount = math.max(maxCount, counts[index])
		end
		assert.equal(minCount < maxCount, true)
		assert.equal(minCount >= 1, true)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
	end)

	runner:test("ScanUnitAuraType ignores Simulate when the aura type is disabled or the unit is missing", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)

		ns.SetUnitGroupAuraEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
		rawset(_G, "UnitExists", function()
			return true
		end)
		assert.equal(#ns.ScanUnitAuraType("player", ns.AURA_TYPE.BUFF), 0)

		ns.SetUnitGroupAuraEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)
		rawset(_G, "UnitExists", function()
			return false
		end)
		assert.equal(#ns.ScanUnitAuraType("player", ns.AURA_TYPE.BUFF), 0)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
	end)
end
