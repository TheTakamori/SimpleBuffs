---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

local function make_point_frame(point, relativePoint, x, y)
	return {
		GetPoint = function()
			return point, nil, relativePoint, x, y
		end,
	}
end

return function(runner, ns)
	runner:test("GetAttachedPosition reads the saved per-unit anchor", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		local saved = ns.GetAttachedPosition(ns.UNIT_TOKEN.PLAYER)

		assert.equal(saved.point, ns.ANCHOR_DEFAULTS.player.point)
		assert.equal(saved.x, ns.ANCHOR_DEFAULTS.player.x)
		assert.equal(saved.y, ns.ANCHOR_DEFAULTS.player.y)
	end)

	runner:test("SaveStandalonePosition persists a frame's current point", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		local frame = make_point_frame(ns.UI.ANCHOR_CENTER, ns.UI.ANCHOR_CENTER, 42, -7)
		ns.SaveStandalonePosition(ns.UNIT_GROUP.PLAYER, frame)

		local saved = ns.DB().standalone[ns.UNIT_GROUP.PLAYER]
		assert.equal(saved.point, ns.UI.ANCHOR_CENTER)
		assert.equal(saved.relativePoint, ns.UI.ANCHOR_CENTER)
		assert.equal(saved.x, 42)
		assert.equal(saved.y, -7)
	end)

	runner:test("SaveStandalonePosition ignores unknown containers and missing points", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		local before = ns.DB().standalone[ns.UNIT_GROUP.PLAYER].x

		ns.SaveStandalonePosition("unknown-container", make_point_frame(ns.UI.ANCHOR_CENTER, ns.UI.ANCHOR_CENTER, 1, 1))
		ns.SaveStandalonePosition(nil, make_point_frame(ns.UI.ANCHOR_CENTER, ns.UI.ANCHOR_CENTER, 1, 1))
		ns.SaveStandalonePosition(ns.UNIT_GROUP.PLAYER, nil)
		ns.SaveStandalonePosition(ns.UNIT_GROUP.PLAYER, make_point_frame(nil, nil, nil, nil))

		assert.equal(ns.DB().standalone[ns.UNIT_GROUP.PLAYER].x, before)
	end)
end
