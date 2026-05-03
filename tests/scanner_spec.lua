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
		assert.equal(captured.maxCount, ns.DEFAULTS.units.focus.maxAuras)
		assert.equal(captured.sortRule, ns.SORT_RULE.EXPIRATION)
		assert.equal(captured.sortDirection, "Normal")
	end)

	runner:test("ScanUnitAuraType includes optional filter mode", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		ns.SetUnitGroupFilterMode(ns.UNIT_GROUP.PET, ns.FILTER_MODE.PLAYER)

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
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PARTY, ns.DB_KEY.MAX_AURAS, 7)

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
			ns.SetUnitGroupFilterMode(ns.UNIT_GROUP.PET, cases[index][1])
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
			ns.SetUnitGroupSortRule(ns.UNIT_GROUP.PARTY, ns.SORT_RULE_ORDER[index])
			ns.ScanUnitAuraType("party1", ns.AURA_TYPE.BUFF)
			assert.equal(captured[index], ns.SORT_RULE_ORDER[index])
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
end
