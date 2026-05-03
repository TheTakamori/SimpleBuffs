---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

local function make_row()
	return {
		buttons = {},
		freeButtons = {},
		activeKeys = {},
		SetSize = function(self, width, height)
			self.width = width
			self.height = height
		end,
		SetShown = function(self, shown)
			self.shown = shown
		end,
	}
end

local function make_button()
	return {
		SetSize = function(self, width, height)
			self.width = width
			self.height = height
		end,
		ClearAllPoints = function(self)
			self.point = nil
		end,
		SetPoint = function(self, point, _, relativePoint, x, y)
			self.point = point
			self.relativePoint = relativePoint
			self.x = x
			self.y = y
		end,
		Show = function(self)
			self.shown = true
		end,
		Hide = function(self)
			self.shown = false
		end,
	}
end

local function model(...)
	local rows = {}
	for index = 1, select("#", ...) do
		local key = select(index, ...)
		rows[index] = {
			key = key,
			unit = "player",
			auraType = "buff",
			aura = {},
		}
	end
	return { rows = rows }
end

return function(runner, ns)
	local created
	ns.CreateAuraButton = function()
		created = created + 1
		return make_button()
	end
	ns.ApplyAuraButton = function(button, entry, size)
		button.entry = entry
		button:SetSize(size, size)
		button:Show()
	end

	runner:test("UpdateAuraDisplayRow positions vertical reverse layouts", function()
		created = 0
		local row = make_row()

		ns.UpdateAuraDisplayRow(row, model("a", "b"), {
			iconSize = 20,
			spacing = 4,
		}, ns.LAYOUT.VERTICAL_REVERSE)

		assert.equal(row.width, 20)
		assert.equal(row.height, 44)
		assert.equal(row.buttons.a.point, ns.UI.ANCHOR_BOTTOMLEFT)
		assert.equal(row.buttons.a.y, 0)
		assert.equal(row.buttons.b.y, 24)
	end)

	runner:test("UpdateAuraDisplayRow reuses stale aura buttons", function()
		created = 0
		local row = make_row()
		local appearance = {
			iconSize = 20,
			spacing = 4,
		}

		ns.UpdateAuraDisplayRow(row, model("a", "b"), appearance, ns.LAYOUT.HORIZONTAL)
		ns.UpdateAuraDisplayRow(row, model("c"), appearance, ns.LAYOUT.HORIZONTAL)

		assert.equal(created, 2)
		assert.equal(row.buttons.a, nil)
		assert.equal(row.buttons.b, nil)
		assert.equal(row.buttons.c ~= nil, true)
		assert.equal(#row.freeButtons, 1)
	end)
end
