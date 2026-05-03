---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

local function find_column(ns, header)
	for index = 1, #ns.OPTIONS_UNIT_DROPDOWN_COLUMNS do
		local column = ns.OPTIONS_UNIT_DROPDOWN_COLUMNS[index]
		if column.header == header then
			return column
		end
	end
	return nil
end

return function(runner, ns)
	runner:test("RunOptionsRefresh handles defaults custom refresh and no-op", function()
		local refreshCount = 0
		local customCount = 0
		ns.RefreshAllDisplays = function()
			refreshCount = refreshCount + 1
		end

		ns.RunOptionsRefresh(false)
		assert.equal(refreshCount, 0)

		ns.RunOptionsRefresh()
		assert.equal(refreshCount, 1)

		ns.RunOptionsRefresh(function()
			customCount = customCount + 1
		end)
		assert.equal(customCount, 1)
	end)

	runner:test("Attached position metadata only shows for attached-capable modes", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		local attachedColumn = find_column(ns, nil)

		assert.equal(attachedColumn.hideLabel, true)
		assert.equal(attachedColumn.sameRowAsPrevious, true)

		ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER, ns.DISPLAY_MODE.STANDALONE)
		assert.equal(attachedColumn.showWhen(ns.UNIT_GROUP.PLAYER), false)

		ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER, ns.DISPLAY_MODE.ATTACHED)
		assert.equal(attachedColumn.showWhen(ns.UNIT_GROUP.PLAYER), true)

		ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER, ns.DISPLAY_MODE.BOTH)
		assert.equal(attachedColumn.showWhen(ns.UNIT_GROUP.PLAYER), true)
	end)
end
