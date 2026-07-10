---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

return function(runner, ns)
	local createAuraButton = ns.CreateAuraButton
	local applyAuraButton = ns.ApplyAuraButton

	runner:test("CreateAuraButton disables mouse clicks on icon and cooldown", function()
		local parent = {}
		local button = createAuraButton(parent)

		assert.equal(button.mouseClickEnabled, false)
		assert.equal(button.cooldown.mouseClickEnabled, false)
		assert.equal(button.cooldown.mouseEnabled, false)
	end)

	-- Real Secret Values never throw on read and still pass type() checks -
	-- only using them (SetText/SetTexture, which stringify their argument)
	-- throws. Vanilla Lua can't fake that exactly (string/number relational
	-- and concat ops bypass metamethods for primitive operands), so these
	-- tests stand in a specific sentinel value for "a secret reached this
	-- widget call" by making the fake widget itself throw for it, and assert
	-- ApplyAuraButton still finishes and falls back instead of crashing.
	local SECRET_NAME = "\1SECRET_AURA_NAME\1"
	local SECRET_ICON = 918273

	local function build_entry(aura)
		return {
			key = "focus:buff:1",
			unit = "focus",
			auraType = ns.AURA_TYPE.BUFF,
			auraInstanceID = 1,
			aura = aura,
		}
	end

	local BAR_APPEARANCE = {
		style = ns.AURA_STYLE.BAR,
		barWidth = 100,
		showIcon = true,
	}

	runner:test("ApplyAuraButton falls back to placeholder text instead of crashing when aura.name is secret", function()
		local button = createAuraButton({})

		-- First pass with a plain aura creates button.barName via the real
		-- ensure_bar_widgets path; ensure_bar_widgets only creates it once,
		-- so overriding SetText afterward persists into the next call -
		-- mirroring a real button being reused/updated across refreshes.
		applyAuraButton(button, build_entry({ name = "Alpha", icon = 1, duration = 10, expirationTime = 20 }), 20, BAR_APPEARANCE)
		assert.equal(button.barName ~= nil, true)

		button.barName.SetText = function(self, text)
			if text == SECRET_NAME then
				error("attempt to compare field 'name' (a secret string value)")
			end
			self.text = text
		end

		applyAuraButton(button, build_entry({ name = SECRET_NAME, icon = 1, duration = 10, expirationTime = 20 }), 20, BAR_APPEARANCE)

		assert.equal(button.barName.text, ns.TEXT.AURA_TOOLTIP_FALLBACK)
	end)

	runner:test("ApplyAuraButton falls back to the placeholder icon instead of crashing when aura.icon is secret", function()
		local button = createAuraButton({})
		button.icon.SetTexture = function(self, texture)
			if texture == SECRET_ICON then
				error("attempt to compare field 'icon' (a secret number value)")
			end
			self.texture = texture
		end

		applyAuraButton(button, build_entry({ name = "Alpha", icon = SECRET_ICON, duration = 10, expirationTime = 20 }), 20, BAR_APPEARANCE)

		assert.equal(button.icon.texture, ns.AURA_BUTTON.QUESTION_MARK_ICON)
	end)
end
