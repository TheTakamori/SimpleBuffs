---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

return function(runner, ns)
	local createAuraButton = ns.CreateAuraButton

	runner:test("CreateAuraButton disables mouse clicks on icon and cooldown", function()
		local parent = {}
		local button = createAuraButton(parent)

		assert.equal(button.mouseClickEnabled, false)
		assert.equal(button.cooldown.mouseClickEnabled, false)
		assert.equal(button.cooldown.mouseEnabled, false)
	end)
end
