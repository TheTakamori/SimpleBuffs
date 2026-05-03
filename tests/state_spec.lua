---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

return function(runner, ns)
	runner:test("InitDB fills defaults", function()
		_G.SimpleBuffsDB = nil

		local db = ns.InitDB()

		assert.equal(db.displayMode, nil)
		assert.equal(db.version, ns.DB_VERSION)
		assert.equal(db.units.player.buff, true)
		assert.equal(db.units.target.debuff, true)
		assert.equal(db.units.focus.buff, true)
		assert.equal(db.units.pet.debuff, true)
		assert.equal(db.units.player.mode, ns.DISPLAY_MODE.ATTACHED)
		assert.equal(db.units.player.attachedPosition, ns.ATTACHED_POSITION.BELOW)
		assert.equal(db.units.player.layout, ns.LAYOUT.HORIZONTAL)
		assert.equal(db.units.player.sortRule, ns.SORT_RULE.EXPIRATION)
		assert.equal(db.units.player.filterMode, ns.FILTER_MODE.ALL)
		assert.equal(db.units.player.iconSize, ns.DEFAULTS.units.player.iconSize)
		assert.equal(db.units.player.spacing, ns.DEFAULTS.units.player.spacing)
		assert.equal(db.units.player.maxAuras, ns.DEFAULTS.units.player.maxAuras)
		assert.equal(db.units.player.scale, ns.DEFAULTS.units.player.scale)
		assert.equal(db.units.player.showCountdown, true)
		assert.equal(db.units.party.mode, ns.DISPLAY_MODE.ATTACHED)
		assert.equal(db.units.party.attachedPosition, ns.ATTACHED_POSITION.RIGHT)
		assert.equal(db.units.partyPets.attachedPosition, ns.ATTACHED_POSITION.RIGHT)
		assert.equal(db.units.raid.mode, ns.DISPLAY_MODE.ATTACHED)
		assert.equal(db.units.arenaPets.mode, ns.DISPLAY_MODE.ATTACHED)
		assert.equal(db.units.vehicle, nil)
		assert.equal(db.units.raid.debuff, true)
		assert.equal(db.appearance.layout, nil)
		assert.equal(db.appearance.sortRule, nil)
		assert.equal(db.appearance.filterMode, nil)
		assert.equal(db.appearance.iconSize, nil)
		assert.equal(db.appearance.showTitles, nil)
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
					mode = "floating",
					attachedPosition = "sideways",
					layout = "diagonal",
					sortRule = "random",
					filterMode = "mine",
					iconSize = 999,
					spacing = -20,
					maxAuras = 0,
					scale = 9,
				},
				party = {},
				raid = {
					mode = ns.DISPLAY_MODE.BOTH,
				},
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

		assert.equal(db.displayMode, nil)
		assert.equal(db.appearance.iconSize, nil)
		assert.equal(db.appearance.spacing, nil)
		assert.equal(db.appearance.maxAuras, nil)
		assert.equal(db.appearance.scale, nil)
		assert.equal(db.units.player.buff, false)
		assert.equal(db.units.player.debuff, true)
		assert.equal(db.units.player.mode, ns.DEFAULTS.units.player.mode)
		assert.equal(db.units.player.attachedPosition, ns.DEFAULTS.units.player.attachedPosition)
		assert.equal(db.units.player.layout, ns.DEFAULTS.units.player.layout)
		assert.equal(db.units.player.sortRule, ns.DEFAULTS.units.player.sortRule)
		assert.equal(db.units.player.filterMode, ns.DEFAULTS.units.player.filterMode)
		assert.equal(db.units.player.iconSize, ns.LIMITS.ICON_SIZE_MAX)
		assert.equal(db.units.player.spacing, ns.LIMITS.SPACING_MIN)
		assert.equal(db.units.player.maxAuras, ns.LIMITS.MAX_AURAS_MIN)
		assert.equal(db.units.player.scale, ns.LIMITS.SCALE_MAX)
		assert.equal(db.units.party.buff, true)
		assert.equal(db.units.raid.mode, ns.DISPLAY_MODE.BOTH)
		assert.equal(db.appearance.layout, nil)
		assert.equal(db.appearance.sortRule, nil)
		assert.equal(db.appearance.filterMode, nil)
		assert.equal(db.minimap.angle, 360)
		assert.equal(db.minimap.hide, true)
	end)

	runner:test("lock state toggles and persists", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		assert.equal(ns.DB().locked, false)
		assert.equal(ns.SetLocked(true), true)
		assert.equal(ns.DB().locked, true)
		assert.equal(ns.ToggleLocked(), false)
		assert.equal(ns.DB().locked, false)
	end)

	runner:test("all unit aura toggles update together", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		assert.equal(ns.AreAllUnitAurasEnabled(), true)
		assert.equal(ns.SetAllUnitAurasEnabled(false), false)
		assert.equal(ns.AreAllUnitAurasEnabled(), false)
		assert.equal(ns.DB().units.player.buff, false)
		assert.equal(ns.DB().units.raidPets.debuff, false)

		assert.equal(ns.SetAllUnitAurasEnabled(true), true)
		assert.equal(ns.AreAllUnitAurasEnabled(), true)
		assert.equal(ns.DB().units.party.buff, true)
		assert.equal(ns.DB().units.arenaPets.debuff, true)
	end)

	runner:test("ResetDB restores settings and all unit toggles", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER, ns.DISPLAY_MODE.BOTH)
		ns.SetUnitGroupAttachedPosition(ns.UNIT_GROUP.PLAYER, ns.ATTACHED_POSITION.ABOVE)
		ns.SetUnitGroupLayout(ns.UNIT_GROUP.PLAYER, ns.LAYOUT.VERTICAL)
		ns.SetUnitGroupSortRule(ns.UNIT_GROUP.PLAYER, ns.SORT_RULE.UNSORTED)
		ns.SetUnitGroupFilterMode(ns.UNIT_GROUP.PLAYER, ns.FILTER_MODE.PLAYER)
		ns.SetAllUnitAurasEnabled(false)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PLAYER, ns.DB_KEY.ICON_SIZE, ns.LIMITS.ICON_SIZE_MAX)
		ns.SetLocked(true)

		local db = ns.ResetDB()

		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER), ns.DEFAULTS.units.player.mode)
		assert.equal(ns.GetUnitGroupAttachedPosition(ns.UNIT_GROUP.PLAYER), ns.DEFAULTS.units.player.attachedPosition)
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PLAYER), ns.DEFAULTS.units.player.layout)
		assert.equal(ns.GetUnitGroupSortRule(ns.UNIT_GROUP.PLAYER), ns.DEFAULTS.units.player.sortRule)
		assert.equal(ns.GetUnitGroupFilterMode(ns.UNIT_GROUP.PLAYER), ns.DEFAULTS.units.player.filterMode)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER).iconSize, ns.DEFAULTS.units.player.iconSize)
		assert.equal(db.locked, false)
		assert.equal(ns.AreAllUnitAurasEnabled(), true)
	end)

	runner:test("ResetUnitGroupOptions restores only one unit group", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER, ns.DISPLAY_MODE.BOTH)
		ns.SetUnitGroupAttachedPosition(ns.UNIT_GROUP.PLAYER, ns.ATTACHED_POSITION.LEFT)
		ns.SetUnitGroupLayout(ns.UNIT_GROUP.PLAYER, ns.LAYOUT.VERTICAL)
		ns.SetUnitGroupAuraEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PLAYER, ns.DB_KEY.ICON_SIZE, ns.LIMITS.ICON_SIZE_MAX)
		ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PET, ns.DISPLAY_MODE.BOTH)

		assert.equal(ns.ResetUnitGroupOptions(ns.UNIT_GROUP.PLAYER), true)

		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER), ns.DEFAULTS.units.player.mode)
		assert.equal(ns.GetUnitGroupAttachedPosition(ns.UNIT_GROUP.PLAYER), ns.DEFAULTS.units.player.attachedPosition)
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PLAYER), ns.DEFAULTS.units.player.layout)
		assert.equal(ns.GetUnitGroupOptions(ns.UNIT_GROUP.PLAYER).buff, true)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER).iconSize, ns.DEFAULTS.units.player.iconSize)
		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.PET), ns.DISPLAY_MODE.BOTH)
		assert.equal(ns.ResetUnitGroupOptions("unknown"), false)
	end)

	runner:test("standalone dragging requires unlocked state and Shift", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		rawset(_G, "IsShiftKeyDown", function()
			return false
		end)
		assert.equal(ns.CanStartStandaloneDrag(), false)

		rawset(_G, "IsShiftKeyDown", function()
			return true
		end)
		assert.equal(ns.CanStartStandaloneDrag(), true)

		ns.SetLocked(true)
		assert.equal(ns.CanStartStandaloneDrag(), false)
	end)

	runner:test("SetUnitGroupAppearanceValue clamps numeric settings", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PET, ns.DB_KEY.ICON_SIZE, 500)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PET, ns.DB_KEY.SPACING, -1)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PET, ns.DB_KEY.MAX_AURAS, 999)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PET, ns.DB_KEY.SCALE, 0)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PET, ns.DB_KEY.SHOW_COUNTS, false)

		local appearance = ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PET)
		assert.equal(appearance.iconSize, ns.LIMITS.ICON_SIZE_MAX)
		assert.equal(appearance.spacing, ns.LIMITS.SPACING_MIN)
		assert.equal(appearance.maxAuras, ns.LIMITS.MAX_AURAS_MAX)
		assert.equal(appearance.scale, ns.LIMITS.SCALE_MIN)
		assert.equal(appearance.showCounts, false)
	end)

	runner:test("unit appearance is cached and max aura lookup avoids table allocation", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PLAYER, ns.DB_KEY.MAX_AURAS, 9)
		local first = ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER)
		local second = ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER)

		assert.equal(first, second)
		assert.equal(ns.GetUnitMaxAuras(ns.UNIT_TOKEN.PLAYER), 9)
		assert.equal(ns.GetUnitGroupAppearance(nil).iconSize, ns.DEFAULTS.units.player.iconSize)
	end)

	runner:test("per-group display modes validate allowed modes", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		assert.equal(ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER, ns.DISPLAY_MODE.BOTH), true)
		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER), ns.DISPLAY_MODE.BOTH)
		assert.equal(ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER, "floating"), false)
		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER), ns.DISPLAY_MODE.BOTH)
		assert.equal(ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.RAID, ns.DISPLAY_MODE.BOTH), true)
		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.RAID), ns.DISPLAY_MODE.BOTH)
	end)

	runner:test("per-group attached positions validate allowed values", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		assert.equal(ns.SetUnitGroupAttachedPosition(ns.UNIT_GROUP.PLAYER, ns.ATTACHED_POSITION.LEFT), true)
		assert.equal(ns.GetUnitGroupAttachedPosition(ns.UNIT_GROUP.PLAYER), ns.ATTACHED_POSITION.LEFT)
		assert.equal(ns.GetUnitAttachedPosition("player"), ns.ATTACHED_POSITION.LEFT)
		assert.equal(ns.SetUnitGroupAttachedPosition(ns.UNIT_GROUP.PLAYER, "diagonal"), false)
		assert.equal(ns.GetUnitGroupAttachedPosition(ns.UNIT_GROUP.PLAYER), ns.ATTACHED_POSITION.LEFT)
	end)

	runner:test("per-group layout sort and filter validate allowed values", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		assert.equal(ns.SetUnitGroupLayout(ns.UNIT_GROUP.PET, ns.LAYOUT.VERTICAL_REVERSE), true)
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PET), ns.LAYOUT.VERTICAL_REVERSE)
		assert.equal(ns.SetUnitGroupLayout(ns.UNIT_GROUP.PET, "diagonal"), false)
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PET), ns.LAYOUT.VERTICAL_REVERSE)
		assert.equal(ns.GetUnitLayout("pet"), ns.LAYOUT.VERTICAL_REVERSE)

		assert.equal(ns.SetUnitGroupSortRule(ns.UNIT_GROUP.PET, ns.SORT_RULE.UNSORTED), true)
		assert.equal(ns.GetUnitGroupSortRule(ns.UNIT_GROUP.PET), ns.SORT_RULE.UNSORTED)
		assert.equal(ns.SetUnitGroupSortRule(ns.UNIT_GROUP.PET, "random"), false)
		assert.equal(ns.GetUnitSortRule("pet"), ns.SORT_RULE.UNSORTED)

		assert.equal(ns.SetUnitGroupFilterMode(ns.UNIT_GROUP.PET, ns.FILTER_MODE.PLAYER), true)
		assert.equal(ns.GetUnitGroupFilterMode(ns.UNIT_GROUP.PET), ns.FILTER_MODE.PLAYER)
		assert.equal(ns.SetUnitGroupFilterMode(ns.UNIT_GROUP.PET, "mine"), false)
		assert.equal(ns.GetUnitFilterMode("pet"), ns.FILTER_MODE.PLAYER)
	end)

	runner:test("legacy global display mode migrates to supported groups", function()
		_G.SimpleBuffsDB = {
			version = 2,
			displayMode = ns.DISPLAY_MODE.BOTH,
			appearance = {
				iconSize = 36,
				spacing = 5,
				maxAuras = 20,
				scale = 1.25,
				layout = ns.LAYOUT.VERTICAL,
				sortRule = ns.SORT_RULE.UNSORTED,
				filterMode = ns.FILTER_MODE.PLAYER,
				showCountdown = false,
				showSwipe = false,
				showCounts = false,
			},
		}

		ns.InitDB()

		assert.equal(ns.DB().displayMode, nil)
		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER), ns.DISPLAY_MODE.BOTH)
		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.PARTY), ns.DISPLAY_MODE.BOTH)
		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.RAID), ns.DISPLAY_MODE.BOTH)
		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.ARENA_PETS), ns.DISPLAY_MODE.BOTH)
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PLAYER), ns.LAYOUT.VERTICAL)
		assert.equal(ns.GetUnitGroupSortRule(ns.UNIT_GROUP.PARTY), ns.SORT_RULE.UNSORTED)
		assert.equal(ns.GetUnitGroupFilterMode(ns.UNIT_GROUP.ARENA_PETS), ns.FILTER_MODE.PLAYER)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER).iconSize, 36)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PARTY).spacing, 5)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.RAID).maxAuras, 20)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.ARENA_PETS).scale, 1.25)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER).showCountdown, false)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PARTY).showSwipe, false)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.RAID).showCounts, false)
		assert.equal(ns.DB().appearance.layout, nil)
		assert.equal(ns.DB().appearance.sortRule, nil)
		assert.equal(ns.DB().appearance.filterMode, nil)
	end)

	runner:test("legacy global migration preserves valid per-group settings", function()
		_G.SimpleBuffsDB = {
			version = 2,
			displayMode = ns.DISPLAY_MODE.BOTH,
			appearance = {
				iconSize = 36,
				spacing = 5,
				maxAuras = 20,
				scale = 1.25,
				layout = ns.LAYOUT.VERTICAL,
				sortRule = ns.SORT_RULE.UNSORTED,
				filterMode = ns.FILTER_MODE.PLAYER,
				showCounts = false,
			},
			units = {
				player = {
					mode = ns.DISPLAY_MODE.ATTACHED,
					attachedPosition = ns.ATTACHED_POSITION.LEFT,
					layout = ns.LAYOUT.HORIZONTAL_REVERSE,
					sortRule = ns.SORT_RULE.DEFAULT,
					filterMode = ns.FILTER_MODE.IMPORTANT,
					iconSize = 44,
					spacing = 7,
					maxAuras = 8,
					scale = 1.5,
					showCounts = true,
				},
				party = {},
			},
		}

		ns.InitDB()

		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER), ns.DISPLAY_MODE.ATTACHED)
		assert.equal(ns.GetUnitGroupAttachedPosition(ns.UNIT_GROUP.PLAYER), ns.ATTACHED_POSITION.LEFT)
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PLAYER), ns.LAYOUT.HORIZONTAL_REVERSE)
		assert.equal(ns.GetUnitGroupSortRule(ns.UNIT_GROUP.PLAYER), ns.SORT_RULE.DEFAULT)
		assert.equal(ns.GetUnitGroupFilterMode(ns.UNIT_GROUP.PLAYER), ns.FILTER_MODE.IMPORTANT)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER).iconSize, 44)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER).spacing, 7)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER).maxAuras, 8)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER).scale, 1.5)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER).showCounts, true)
		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.PARTY), ns.DISPLAY_MODE.BOTH)
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PARTY), ns.LAYOUT.VERTICAL)
		assert.equal(ns.GetUnitGroupSortRule(ns.UNIT_GROUP.PARTY), ns.SORT_RULE.UNSORTED)
		assert.equal(ns.GetUnitGroupFilterMode(ns.UNIT_GROUP.PARTY), ns.FILTER_MODE.PLAYER)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PARTY).iconSize, 36)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PARTY).showCounts, false)
	end)

	runner:test("minimap settings persist with clamped angle", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		assert.equal(ns.SetMinimapButtonAngle(-90), 0)
		assert.equal(ns.SetMinimapButtonHidden(true), true)
		assert.equal(ns.IsMinimapButtonHidden(), true)
	end)
end
