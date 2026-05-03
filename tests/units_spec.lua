---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

return function(runner, ns)
	runner:test("unit registry maps supported groups", function()
		assert.equal(ns.GetUnitGroup("player"), ns.UNIT_GROUP.CORE)
		assert.equal(ns.GetUnitGroup("party4"), ns.UNIT_GROUP.PARTY)
		assert.equal(ns.GetUnitGroup("raid40"), ns.UNIT_GROUP.RAID)
		assert.equal(ns.GetUnitGroup("boss8"), ns.UNIT_GROUP.BOSS)
		assert.equal(ns.GetUnitGroup("arena5"), ns.UNIT_GROUP.ARENA)
		assert.equal(ns.GetUnitGroup("nameplate40"), ns.UNIT_GROUP.NAMEPLATES)
	end)

	runner:test("nameplates are tracked only while active", function()
		ns.Runtime = nil
		ns.RuntimeEnsure()

		assert.equal(#ns.GetConfiguredUnits(), #ns.UNIT_ORDER)
		ns.MarkNameplateActive("nameplate7", true)
		assert.equal(#ns.GetConfiguredUnits(), #ns.UNIT_ORDER + 1)
		ns.MarkNameplateActive("nameplate7", false)
		assert.equal(#ns.GetConfiguredUnits(), #ns.UNIT_ORDER)
	end)
end
