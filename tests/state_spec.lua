---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

return function(runner, ns)
	runner:test("InitDB fills defaults", function()
		_G.SimpleBuffsDB = nil

		local db = ns.InitDB()

		assert.equal(db.displayMode, ns.DISPLAY_MODE.ATTACHED)
		assert.equal(db.units.player.buff, true)
		assert.equal(db.units.target.debuff, true)
		assert.equal(db.units.focus.buff, true)
		assert.equal(db.units.pet.debuff, true)
		assert.equal(db.units.vehicle.buff, true)
		assert.equal(db.units.raid.debuff, true)
		assert.equal(db.appearance.iconSize, 28)
		assert.equal(db.appearance.showTitles, false)
		assert.equal(db.minimap.angle, ns.DEFAULTS.minimap.angle)
		assert.equal(db.minimap.hide, false)
	end)

	runner:test("InitDB sanitizes invalid values", function()
		_G.SimpleBuffsDB = {
			displayMode = "invalid",
			minimap = {
				angle = 999,
				hide = true,
			},
			appearance = {
				iconSize = 999,
				spacing = -20,
				maxAuras = 0,
				scale = 9,
				layout = "sideways",
				sortRule = "bad",
				filterMode = "bad",
			},
			units = {
				player = {
					buff = false,
					debuff = true,
				},
				party = {},
			},
			attached = {
				focus = {},
				pet = {},
			},
			standalone = {
				player = {},
				party = {},
			},
		}

		local db = ns.InitDB()

		assert.equal(db.displayMode, ns.DISPLAY_MODE.ATTACHED)
		assert.equal(db.appearance.iconSize, ns.LIMITS.ICON_SIZE_MAX)
		assert.equal(db.appearance.spacing, ns.LIMITS.SPACING_MIN)
		assert.equal(db.appearance.maxAuras, ns.LIMITS.MAX_AURAS_MIN)
		assert.equal(db.appearance.scale, ns.LIMITS.SCALE_MAX)
		assert.equal(db.appearance.layout, ns.DEFAULTS.appearance.layout)
		assert.equal(db.units.player.buff, false)
		assert.equal(db.units.player.debuff, true)
		assert.equal(db.units.party.buff, true)
		assert.equal(db.minimap.angle, 360)
		assert.equal(db.minimap.hide, true)
	end)

	runner:test("InitDB migrates old saved variables", function()
		_G.SimpleBuffsDB = nil
		_G.PetFocusBuffsDB = {
			appearance = {
				iconSize = 34,
			},
		}

		local db = ns.InitDB()

		assert.equal(db.appearance.iconSize, 34)
		assert.equal(db.units.player.buff, true)
		_G.PetFocusBuffsDB = nil
	end)

	runner:test("SetAppearanceValue clamps numeric settings", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		ns.SetAppearanceValue("iconSize", 500)
		ns.SetAppearanceValue("spacing", -1)
		ns.SetAppearanceValue("maxAuras", 999)
		ns.SetAppearanceValue("scale", 0)

		local appearance = ns.GetAppearance()
		assert.equal(appearance.iconSize, ns.LIMITS.ICON_SIZE_MAX)
		assert.equal(appearance.spacing, ns.LIMITS.SPACING_MIN)
		assert.equal(appearance.maxAuras, ns.LIMITS.MAX_AURAS_MAX)
		assert.equal(appearance.scale, ns.LIMITS.SCALE_MIN)
	end)

	runner:test("SetDisplayMode rejects unknown modes", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		assert.equal(ns.SetDisplayMode(ns.DISPLAY_MODE.BOTH), true)
		assert.equal(ns.GetDisplayMode(), ns.DISPLAY_MODE.BOTH)
		assert.equal(ns.SetDisplayMode("floating"), false)
		assert.equal(ns.GetDisplayMode(), ns.DISPLAY_MODE.BOTH)
	end)

	runner:test("minimap settings persist with clamped angle", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		assert.equal(ns.SetMinimapButtonAngle(-90), 0)
		assert.equal(ns.SetMinimapButtonHidden(true), true)
		assert.equal(ns.IsMinimapButtonHidden(), true)
	end)
end
