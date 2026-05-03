---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

return function(runner, ns)
	runner:test("unit registry maps supported groups", function()
		assert.equal(ns.GetUnitGroup("player"), ns.UNIT_GROUP.PLAYER)
		assert.equal(ns.GetUnitGroup("target"), ns.UNIT_GROUP.TARGET)
		assert.equal(ns.GetUnitGroup("focus"), ns.UNIT_GROUP.FOCUS)
		assert.equal(ns.GetUnitGroup("pet"), ns.UNIT_GROUP.PET)
		assert.equal(ns.GetUnitGroup("vehicle"), nil)
		assert.equal(ns.GetUnitGroup("mouseover"), nil)
		assert.equal(ns.GetUnitGroup("party4"), ns.UNIT_GROUP.PARTY)
		assert.equal(ns.GetUnitGroup("raid40"), ns.UNIT_GROUP.RAID)
		assert.equal(ns.GetUnitGroup("boss8"), ns.UNIT_GROUP.BOSS)
		assert.equal(ns.GetUnitGroup("arena5"), ns.UNIT_GROUP.ARENA)
		assert.equal(ns.GetUnitGroup("nameplate40"), nil)
	end)
end
