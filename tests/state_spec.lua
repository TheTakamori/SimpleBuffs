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
		assert.equal(db.units.player.aura.buff.layout, ns.LAYOUT.HORIZONTAL)
		assert.equal(db.units.player.aura.buff.sortRule, ns.SORT_RULE.EXPIRATION)
		assert.equal(db.units.player.aura.buff.filterMode, ns.FILTER_MODE.ALL)
		assert.equal(db.units.player.aura.buff.iconSize, ns.DEFAULTS.units.player.aura.buff.iconSize)
		assert.equal(db.units.player.aura.buff.spacing, ns.DEFAULTS.units.player.aura.buff.spacing)
		assert.equal(db.units.player.aura.buff.maxAuras, ns.DEFAULTS.units.player.aura.buff.maxAuras)
		assert.equal(db.units.player.aura.buff.scale, ns.DEFAULTS.units.player.aura.buff.scale)
		assert.equal(db.units.player.aura.buff.showCountdown, true)
		assert.equal(db.units.player.aura.buff.style, ns.AURA_STYLE.ICON)
		assert.equal(db.units.player.aura.buff.barWidth, ns.DEFAULTS.units.player.aura.buff.barWidth)
		assert.equal(db.units.player.aura.buff.barSort, ns.BAR_SORT.ALPHA_ASC)
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
					style = "grid",
					barWidth = 5,
					barSort = "random",
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
		assert.equal(db.units.player.aura.buff.layout, ns.DEFAULTS.units.player.aura.buff.layout)
		assert.equal(db.units.player.aura.buff.sortRule, ns.DEFAULTS.units.player.aura.buff.sortRule)
		assert.equal(db.units.player.aura.buff.filterMode, ns.DEFAULTS.units.player.aura.buff.filterMode)
		assert.equal(db.units.player.aura.buff.iconSize, ns.LIMITS.ICON_SIZE_MAX)
		assert.equal(db.units.player.aura.buff.spacing, ns.LIMITS.SPACING_MIN)
		assert.equal(db.units.player.aura.buff.maxAuras, ns.LIMITS.MAX_AURAS_MIN)
		assert.equal(db.units.player.aura.buff.scale, ns.LIMITS.SCALE_MAX)
		assert.equal(db.units.player.aura.buff.style, ns.DEFAULTS.units.player.aura.buff.style)
		assert.equal(db.units.player.aura.buff.barWidth, ns.LIMITS.BAR_WIDTH_MIN)
		assert.equal(db.units.player.aura.buff.barSort, ns.DEFAULTS.units.player.aura.buff.barSort)
		assert.equal(db.version, ns.DB_VERSION)
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
		ns.SetUnitGroupLayout(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.LAYOUT.VERTICAL)
		ns.SetUnitGroupSortRule(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.SORT_RULE.UNSORTED)
		ns.SetUnitGroupFilterMode(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.FILTER_MODE.PLAYER)
		ns.SetAllUnitAurasEnabled(false)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.DB_KEY.ICON_SIZE, ns.LIMITS.ICON_SIZE_MAX)
		ns.SetLocked(true)

		local db = ns.ResetDB()

		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER), ns.DEFAULTS.units.player.mode)
		assert.equal(ns.GetUnitGroupAttachedPosition(ns.UNIT_GROUP.PLAYER), ns.DEFAULTS.units.player.attachedPosition)
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), ns.DEFAULTS.units.player.aura.buff.layout)
		assert.equal(ns.GetUnitGroupSortRule(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), ns.DEFAULTS.units.player.aura.buff.sortRule)
		assert.equal(ns.GetUnitGroupFilterMode(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), ns.DEFAULTS.units.player.aura.buff.filterMode)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF).iconSize, ns.DEFAULTS.units.player.aura.buff.iconSize)
		assert.equal(db.locked, false)
		assert.equal(ns.AreAllUnitAurasEnabled(), true)
	end)

	runner:test("ResetUnitGroupOptions restores only one unit group", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER, ns.DISPLAY_MODE.BOTH)
		ns.SetUnitGroupAttachedPosition(ns.UNIT_GROUP.PLAYER, ns.ATTACHED_POSITION.LEFT)
		ns.SetUnitGroupLayout(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.LAYOUT.VERTICAL)
		ns.SetUnitGroupAuraEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.DB_KEY.ICON_SIZE, ns.LIMITS.ICON_SIZE_MAX)
		ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PET, ns.DISPLAY_MODE.BOTH)

		assert.equal(ns.ResetUnitGroupOptions(ns.UNIT_GROUP.PLAYER), true)

		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER), ns.DEFAULTS.units.player.mode)
		assert.equal(ns.GetUnitGroupAttachedPosition(ns.UNIT_GROUP.PLAYER), ns.DEFAULTS.units.player.attachedPosition)
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), ns.DEFAULTS.units.player.aura.buff.layout)
		assert.equal(ns.GetUnitGroupOptions(ns.UNIT_GROUP.PLAYER).buff, true)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF).iconSize, ns.DEFAULTS.units.player.aura.buff.iconSize)
		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.PET), ns.DISPLAY_MODE.BOTH)
		assert.equal(ns.ResetUnitGroupOptions("unknown"), false)
	end)

	runner:test("CopyUnitGroupOptions copies source settings onto target group", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER, ns.DISPLAY_MODE.BOTH)
		ns.SetUnitGroupAttachedPosition(ns.UNIT_GROUP.PLAYER, ns.ATTACHED_POSITION.LEFT)
		ns.SetUnitGroupLayout(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.LAYOUT.VERTICAL)
		ns.SetUnitGroupSortRule(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.SORT_RULE.EXPIRATION_ONLY)
		ns.SetUnitGroupFilterMode(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.FILTER_MODE.PLAYER)
		ns.SetUnitGroupAuraEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.DB_KEY.ICON_SIZE, ns.LIMITS.ICON_SIZE_MAX)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.DB_KEY.SHOW_COUNTS, false)
		ns.GetUnitGroupOptions(ns.UNIT_GROUP.PET).staleSetting = true

		assert.equal(ns.CopyUnitGroupOptions(ns.UNIT_GROUP.PLAYER, ns.UNIT_GROUP.PET), true)

		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.PET), ns.DISPLAY_MODE.BOTH)
		assert.equal(ns.GetUnitGroupAttachedPosition(ns.UNIT_GROUP.PET), ns.ATTACHED_POSITION.LEFT)
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF), ns.LAYOUT.VERTICAL)
		assert.equal(ns.GetUnitGroupSortRule(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF), ns.SORT_RULE.EXPIRATION_ONLY)
		assert.equal(ns.GetUnitGroupFilterMode(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF), ns.FILTER_MODE.PLAYER)
		assert.equal(ns.GetUnitGroupOptions(ns.UNIT_GROUP.PET).buff, false)
		assert.equal(ns.GetUnitGroupOptions(ns.UNIT_GROUP.PET).staleSetting, nil)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF).iconSize, ns.LIMITS.ICON_SIZE_MAX)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF).showCounts, false)
		assert.equal(ns.CopyUnitGroupOptions(ns.UNIT_GROUP.PLAYER, ns.UNIT_GROUP.PLAYER), false)
		assert.equal(ns.CopyUnitGroupOptions("unknown", ns.UNIT_GROUP.PLAYER), false)
	end)

	runner:test("CopyUnitGroupOptions leaves the target's known auras untouched", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, 111, "Player Only Buff")
		ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, 222, "Pet Only Buff")

		assert.equal(ns.CopyUnitGroupOptions(ns.UNIT_GROUP.PLAYER, ns.UNIT_GROUP.PET), true)

		assert.equal(ns.IsAuraHidden(ns.UNIT_GROUP.PET, 111), false)
		assert.equal(#ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.PET), 1)
		assert.equal(ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.PET)[1].name, "Pet Only Buff")
	end)

	runner:test("RegisterDiscoveredAura creates once and IsAuraHidden/SetAuraHidden round-trip", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		assert.equal(ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, 12345, "Well Fed"), true)
		assert.equal(ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, 12345, "Well Fed"), false)
		assert.equal(ns.IsAuraHidden(ns.UNIT_GROUP.PLAYER, 12345), false)

		assert.equal(ns.SetAuraHidden(ns.UNIT_GROUP.PLAYER, 12345, true), true)
		assert.equal(ns.IsAuraHidden(ns.UNIT_GROUP.PLAYER, 12345), true)
		assert.equal(ns.SetAuraHidden(ns.UNIT_GROUP.PLAYER, 12345, false), true)
		assert.equal(ns.IsAuraHidden(ns.UNIT_GROUP.PLAYER, 12345), false)

		assert.equal(ns.SetAuraHidden(ns.UNIT_GROUP.PLAYER, 99999, true), false)
		assert.equal(ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, "unknown", 1, "Bad"), false)
	end)

	runner:test("ForgetAura removes an entry and allows fresh rediscovery", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.DEBUFF, 555, "Curse of Weakness")
		ns.SetAuraHidden(ns.UNIT_GROUP.PLAYER, 555, true)

		assert.equal(ns.ForgetAura(ns.UNIT_GROUP.PLAYER, 555), true)
		assert.equal(ns.ForgetAura(ns.UNIT_GROUP.PLAYER, 555), false)
		assert.equal(ns.IsAuraHidden(ns.UNIT_GROUP.PLAYER, 555), false)

		assert.equal(ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.DEBUFF, 555, "Curse of Weakness"), true)
		assert.equal(ns.IsAuraHidden(ns.UNIT_GROUP.PLAYER, 555), false)
	end)

	runner:test("GetSortedKnownAuraEntries merges buffs and debuffs alphabetically", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, 3, "Charlie Buff")
		ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.DEBUFF, 1, "alpha debuff")
		ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, 2, "Bravo Buff")

		local entries = ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.PLAYER)
		assert.equal(#entries, 3)
		assert.same({ entries[1].name, entries[2].name, entries[3].name }, { "alpha debuff", "Bravo Buff", "Charlie Buff" })
		assert.equal(entries[1].auraType, ns.AURA_TYPE.DEBUFF)
	end)

	runner:test("GetSortedKnownAuraEntries filters by aura type", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, 1, "A Buff")
		ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.DEBUFF, 2, "A Debuff")

		local both = ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.PLAYER, ns.MANAGE_FILTER.BOTH)
		assert.equal(#both, 2)

		local buffsOnly = ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.PLAYER, ns.MANAGE_FILTER.BUFF)
		assert.equal(#buffsOnly, 1)
		assert.equal(buffsOnly[1].name, "A Buff")

		local debuffsOnly = ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.PLAYER, ns.MANAGE_FILTER.DEBUFF)
		assert.equal(#debuffsOnly, 1)
		assert.equal(debuffsOnly[1].name, "A Debuff")
	end)

	runner:test("GetSortedKnownAuraEntries sorts by first/last seen in both directions", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		rawset(_G, "time", function()
			return 1000
		end)
		ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, 1, "First")

		rawset(_G, "time", function()
			return 2000
		end)
		ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, 2, "Second")

		-- Re-seeing "First" later updates only its lastSeenAt, not firstSeenAt.
		rawset(_G, "time", function()
			return 3000
		end)
		ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, 1, "First")

		local firstSeenAsc = ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.PLAYER, nil, ns.MANAGE_SORT.FIRST_SEEN_ASC)
		assert.same({ firstSeenAsc[1].name, firstSeenAsc[2].name }, { "First", "Second" })

		local firstSeenDesc = ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.PLAYER, nil, ns.MANAGE_SORT.FIRST_SEEN_DESC)
		assert.same({ firstSeenDesc[1].name, firstSeenDesc[2].name }, { "Second", "First" })

		-- "First" was re-seen most recently (t=3000), so it sorts last for
		-- "oldest first" and first for "newest first" by last-seen time.
		local lastSeenAsc = ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.PLAYER, nil, ns.MANAGE_SORT.LAST_SEEN_ASC)
		assert.same({ lastSeenAsc[1].name, lastSeenAsc[2].name }, { "Second", "First" })

		local lastSeenDesc = ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.PLAYER, nil, ns.MANAGE_SORT.LAST_SEEN_DESC)
		assert.same({ lastSeenDesc[1].name, lastSeenDesc[2].name }, { "First", "Second" })

		rawset(_G, "time", os.time)
	end)

	runner:test("per-group manage filter and sort validate allowed values", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		assert.equal(ns.GetUnitGroupManageFilter(ns.UNIT_GROUP.PLAYER), ns.MANAGE_FILTER.BOTH)
		assert.equal(ns.SetUnitGroupManageFilter(ns.UNIT_GROUP.PLAYER, ns.MANAGE_FILTER.BUFF), true)
		assert.equal(ns.GetUnitGroupManageFilter(ns.UNIT_GROUP.PLAYER), ns.MANAGE_FILTER.BUFF)
		assert.equal(ns.SetUnitGroupManageFilter(ns.UNIT_GROUP.PLAYER, "invalid"), false)
		assert.equal(ns.GetUnitGroupManageFilter(ns.UNIT_GROUP.PLAYER), ns.MANAGE_FILTER.BUFF)

		assert.equal(ns.GetUnitGroupManageSort(ns.UNIT_GROUP.PLAYER), ns.MANAGE_SORT.ALPHA_ASC)
		assert.equal(ns.SetUnitGroupManageSort(ns.UNIT_GROUP.PLAYER, ns.MANAGE_SORT.LAST_SEEN_DESC), true)
		assert.equal(ns.GetUnitGroupManageSort(ns.UNIT_GROUP.PLAYER), ns.MANAGE_SORT.LAST_SEEN_DESC)
		assert.equal(ns.SetUnitGroupManageSort(ns.UNIT_GROUP.PLAYER, "invalid"), false)
	end)

	runner:test("ResetUnitGroupOptions clears known auras", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		ns.RegisterDiscoveredAura(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, 1, "Aura")
		assert.equal(#ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.PLAYER), 1)

		assert.equal(ns.ResetUnitGroupOptions(ns.UNIT_GROUP.PLAYER), true)
		assert.equal(#ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.PLAYER), 0)
	end)

	runner:test("InitDB sanitizes malformed known aura entries", function()
		_G.SimpleBuffsDB = {
			units = {
				player = {
					knownAuras = {
						["1"] = { name = "Valid Aura", auraType = ns.AURA_TYPE.BUFF, hidden = true },
						["2"] = { name = "", auraType = ns.AURA_TYPE.BUFF },
						["3"] = { auraType = ns.AURA_TYPE.BUFF },
						["4"] = { name = "Bad Type", auraType = "unknown" },
						["5"] = "not-a-table",
					},
				},
			},
		}

		ns.InitDB()

		local entries = ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.PLAYER)
		assert.equal(#entries, 1)
		assert.equal(entries[1].name, "Valid Aura")
		assert.equal(entries[1].hidden, true)
	end)

	runner:test("InitDB backfills first/last seen on legacy known aura entries and sanitizes manage filter/sort", function()
		_G.SimpleBuffsDB = {
			units = {
				player = {
					manageFilter = "invalid",
					manageSort = "invalid",
					knownAuras = {
						["1"] = { name = "Legacy Aura", auraType = ns.AURA_TYPE.BUFF, hidden = false },
					},
				},
			},
		}

		rawset(_G, "time", function()
			return 5000
		end)
		ns.InitDB()
		rawset(_G, "time", os.time)

		assert.equal(ns.GetUnitGroupManageFilter(ns.UNIT_GROUP.PLAYER), ns.MANAGE_FILTER.BOTH)
		assert.equal(ns.GetUnitGroupManageSort(ns.UNIT_GROUP.PLAYER), ns.MANAGE_SORT.ALPHA_ASC)

		local entries = ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.PLAYER)
		assert.equal(entries[1].firstSeenAt, 5000)
		assert.equal(entries[1].lastSeenAt, 5000)
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

		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.DB_KEY.ICON_SIZE, 500)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.DB_KEY.SPACING, -1)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.DB_KEY.MAX_AURAS, 999)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.DB_KEY.SCALE, 0)
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.DB_KEY.SHOW_COUNTS, false)

		local appearance = ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF)
		assert.equal(appearance.iconSize, ns.LIMITS.ICON_SIZE_MAX)
		assert.equal(appearance.spacing, ns.LIMITS.SPACING_MIN)
		assert.equal(appearance.maxAuras, ns.LIMITS.MAX_AURAS_MAX)
		assert.equal(appearance.scale, ns.LIMITS.SCALE_MIN)
		assert.equal(appearance.showCounts, false)
	end)

	runner:test("unit appearance is cached and max aura lookup avoids table allocation", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.DB_KEY.MAX_AURAS, 9)
		local first = ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF)
		local second = ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF)

		assert.equal(first, second)
		assert.equal(ns.GetUnitMaxAuras(ns.UNIT_TOKEN.PLAYER, ns.AURA_TYPE.BUFF), 9)
		assert.equal(ns.GetUnitGroupAppearance(nil, ns.AURA_TYPE.BUFF).iconSize, ns.DEFAULTS.units.player.aura.buff.iconSize)
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

		assert.equal(ns.SetUnitGroupLayout(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.LAYOUT.VERTICAL_REVERSE), true)
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF), ns.LAYOUT.VERTICAL_REVERSE)
		assert.equal(ns.SetUnitGroupLayout(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, "diagonal"), false)
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF), ns.LAYOUT.VERTICAL_REVERSE)
		assert.equal(ns.GetUnitLayout("pet", ns.AURA_TYPE.BUFF), ns.LAYOUT.VERTICAL_REVERSE)

		assert.equal(ns.SetUnitGroupSortRule(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.SORT_RULE.UNSORTED), true)
		assert.equal(ns.GetUnitGroupSortRule(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF), ns.SORT_RULE.UNSORTED)
		assert.equal(ns.SetUnitGroupSortRule(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, "random"), false)
		assert.equal(ns.GetUnitSortRule("pet", ns.AURA_TYPE.BUFF), ns.SORT_RULE.UNSORTED)

		assert.equal(ns.SetUnitGroupFilterMode(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.FILTER_MODE.PLAYER), true)
		assert.equal(ns.GetUnitGroupFilterMode(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF), ns.FILTER_MODE.PLAYER)
		assert.equal(ns.SetUnitGroupFilterMode(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, "mine"), false)
		assert.equal(ns.GetUnitFilterMode("pet", ns.AURA_TYPE.BUFF), ns.FILTER_MODE.PLAYER)
	end)

	runner:test("per-aura-type and per-group fields stay isolated from each other", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		ns.SetUnitGroupLayout(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.LAYOUT.VERTICAL)
		ns.SetUnitGroupSortRule(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.SORT_RULE.UNSORTED)
		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)
		ns.SetUnitGroupBarSort(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.BAR_SORT.ALPHA_DESC)
		ns.SetUnitGroupFilterMode(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.FILTER_MODE.IMPORTANT)

		-- The debuff block for the same group must be untouched.
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PET, ns.AURA_TYPE.DEBUFF), ns.DEFAULTS.units.pet.aura.debuff.layout)
		assert.equal(ns.GetUnitGroupSortRule(ns.UNIT_GROUP.PET, ns.AURA_TYPE.DEBUFF), ns.DEFAULTS.units.pet.aura.debuff.sortRule)
		assert.equal(ns.GetUnitGroupStyle(ns.UNIT_GROUP.PET, ns.AURA_TYPE.DEBUFF), ns.DEFAULTS.units.pet.aura.debuff.style)
		assert.equal(ns.GetUnitGroupBarSort(ns.UNIT_GROUP.PET, ns.AURA_TYPE.DEBUFF), ns.DEFAULTS.units.pet.aura.debuff.barSort)
		assert.equal(ns.GetUnitGroupFilterMode(ns.UNIT_GROUP.PET, ns.AURA_TYPE.DEBUFF), ns.DEFAULTS.units.pet.aura.debuff.filterMode)

		-- The same aura type on a different group must also be untouched.
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), ns.DEFAULTS.units.player.aura.buff.layout)
		assert.equal(ns.GetUnitGroupSortRule(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), ns.DEFAULTS.units.player.aura.buff.sortRule)
		assert.equal(ns.GetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), ns.DEFAULTS.units.player.aura.buff.style)
		assert.equal(ns.GetUnitGroupBarSort(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), ns.DEFAULTS.units.player.aura.buff.barSort)
		assert.equal(ns.GetUnitGroupFilterMode(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), ns.DEFAULTS.units.player.aura.buff.filterMode)

		-- Invalid values must fall through to the previously-set value, not a shared default.
		assert.equal(ns.SetUnitGroupStyle(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, "grid"), false)
		assert.equal(ns.GetUnitGroupStyle(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF), ns.AURA_STYLE.BAR)
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
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), ns.LAYOUT.VERTICAL)
		assert.equal(ns.GetUnitGroupSortRule(ns.UNIT_GROUP.PARTY, ns.AURA_TYPE.BUFF), ns.SORT_RULE.UNSORTED)
		assert.equal(ns.GetUnitGroupFilterMode(ns.UNIT_GROUP.ARENA_PETS, ns.AURA_TYPE.BUFF), ns.FILTER_MODE.PLAYER)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF).iconSize, 36)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PARTY, ns.AURA_TYPE.BUFF).spacing, 5)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.RAID, ns.AURA_TYPE.BUFF).maxAuras, 20)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.ARENA_PETS, ns.AURA_TYPE.BUFF).scale, 1.25)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF).showCountdown, false)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PARTY, ns.AURA_TYPE.BUFF).showSwipe, false)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.RAID, ns.AURA_TYPE.BUFF).showCounts, false)
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
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), ns.LAYOUT.HORIZONTAL_REVERSE)
		assert.equal(ns.GetUnitGroupSortRule(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), ns.SORT_RULE.DEFAULT)
		assert.equal(ns.GetUnitGroupFilterMode(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), ns.FILTER_MODE.IMPORTANT)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF).iconSize, 44)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF).spacing, 7)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF).maxAuras, 8)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF).scale, 1.5)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF).showCounts, true)
		assert.equal(ns.GetUnitGroupDisplayMode(ns.UNIT_GROUP.PARTY), ns.DISPLAY_MODE.BOTH)
		assert.equal(ns.GetUnitGroupLayout(ns.UNIT_GROUP.PARTY, ns.AURA_TYPE.BUFF), ns.LAYOUT.VERTICAL)
		assert.equal(ns.GetUnitGroupSortRule(ns.UNIT_GROUP.PARTY, ns.AURA_TYPE.BUFF), ns.SORT_RULE.UNSORTED)
		assert.equal(ns.GetUnitGroupFilterMode(ns.UNIT_GROUP.PARTY, ns.AURA_TYPE.BUFF), ns.FILTER_MODE.PLAYER)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PARTY, ns.AURA_TYPE.BUFF).iconSize, 36)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PARTY, ns.AURA_TYPE.BUFF).showCounts, false)
	end)

	runner:test("per-group style and bar sort validate allowed values", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		assert.equal(ns.GetUnitGroupStyle(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF), ns.AURA_STYLE.ICON)
		assert.equal(ns.SetUnitGroupStyle(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR), true)
		assert.equal(ns.GetUnitGroupStyle(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF), ns.AURA_STYLE.BAR)
		assert.equal(ns.SetUnitGroupStyle(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, "grid"), false)
		assert.equal(ns.GetUnitGroupStyle(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF), ns.AURA_STYLE.BAR)
		assert.equal(ns.GetUnitStyle("pet", ns.AURA_TYPE.BUFF), ns.AURA_STYLE.BAR)

		assert.equal(ns.GetUnitGroupBarSort(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF), ns.BAR_SORT.ALPHA_ASC)
		assert.equal(ns.SetUnitGroupBarSort(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.BAR_SORT.MAX_DURATION_DESC), true)
		assert.equal(ns.GetUnitGroupBarSort(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF), ns.BAR_SORT.MAX_DURATION_DESC)
		assert.equal(ns.SetUnitGroupBarSort(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, "random"), false)
		assert.equal(ns.GetUnitBarSort("pet", ns.AURA_TYPE.BUFF), ns.BAR_SORT.MAX_DURATION_DESC)
	end)

	runner:test("appearance exposes style and clamped bar width", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF).style, ns.AURA_STYLE.ICON)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF).barWidth, ns.DEFAULTS.units.pet.aura.buff.barWidth)

		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.DB_KEY.BAR_WIDTH, 1000)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF).barWidth, ns.LIMITS.BAR_WIDTH_MAX)

		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.DB_KEY.BAR_WIDTH, 1)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF).barWidth, ns.LIMITS.BAR_WIDTH_MIN)
	end)

	runner:test("bar mode icon defaults on and can be toggled off", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF).showIcon, true)

		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.DB_KEY.SHOW_ICON, false)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF).showIcon, false)

		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF, ns.DB_KEY.SHOW_ICON, true)
		assert.equal(ns.GetUnitGroupAppearance(ns.UNIT_GROUP.PET, ns.AURA_TYPE.BUFF).showIcon, true)
	end)

	runner:test("minimap settings persist with clamped angle", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		assert.equal(ns.SetMinimapButtonAngle(-90), 0)
		assert.equal(ns.SetMinimapButtonHidden(true), true)
		assert.equal(ns.IsMinimapButtonHidden(), true)
	end)
end
