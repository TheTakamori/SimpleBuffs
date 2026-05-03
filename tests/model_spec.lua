---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

local function aura(id)
	return {
		auraInstanceID = id,
		name = "Aura " .. tostring(id),
		icon = 1,
		duration = 10,
		expirationTime = 20,
		timeMod = 1,
		applications = 1,
	}
end

return function(runner, ns)
	runner:test("BuildAuraKey is stable", function()
		assert.equal(ns.BuildAuraKey("focus", ns.AURA_TYPE.DEBUFF, 42), "focus:debuff:42")
	end)

	runner:test("RefreshUnitModel rebuilds stable aura rows", function()
		_G.SimpleBuffsDB = nil
		ns.Runtime = nil
		ns.InitDB()
		ns.SetUnitAuraEnabled("focus", ns.AURA_TYPE.DEBUFF, false)

		local ids = { 1, 2 }
		rawset(_G, "UnitExists", function(unit)
			return unit == "focus"
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function(_, filter)
				if filter == "HELPFUL" then
					return ids
				end
				return {}
			end,
			GetAuraDataByAuraInstanceID = function(_, auraInstanceID)
				return aura(auraInstanceID)
			end,
		})

		local first = ns.RefreshUnitModel("focus")
		assert.equal(#first.buff.rows, 2)
		assert.equal(first.buff.rows[1].key, "focus:buff:1")

		ids = { 2 }
		local second = ns.RefreshUnitModel("focus")

		assert.equal(#second.buff.rows, 1)
		assert.equal(second.buff.rows[1].key, "focus:buff:2")
	end)

	runner:test("RefreshUnitModel ignores untracked units", function()
		_G.SimpleBuffsDB = nil
		ns.Runtime = nil
		ns.InitDB()

		assert.equal(ns.RefreshUnitModel("targettarget"), nil)
	end)

	runner:test("MarkUnitDirty queues each tracked unit once", function()
		ns.Runtime = nil
		ns.RuntimeEnsure()

		ns.MarkUnitDirty("player")
		ns.MarkUnitDirty("player")
		ns.MarkUnitDirty("targettarget")

		assert.equal(ns.Runtime.dirtyUnits.player, true)
		assert.equal(#ns.Runtime.dirtyUnitList, 1)
		assert.equal(ns.Runtime.dirtyUnitList[1], "player")
	end)
end
