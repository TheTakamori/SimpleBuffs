---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

local function aura(id)
	return {
		auraInstanceID = id,
		name = "Aura " .. tostring(id),
		icon = 1,
		duration = 10,
		expirationTime = 20,
		timeMod = 1,
		applications = 1,
	}
end

return function(runner, ns)
	runner:test("BuildAuraKey is stable", function()
		assert.equal(ns.BuildAuraKey("focus", ns.AURA_TYPE.DEBUFF, 42), "focus:debuff:42")
	end)

	runner:test("RefreshUnitModel rebuilds stable aura rows", function()
		_G.SimpleBuffsDB = nil
		ns.Runtime = nil
		ns.InitDB()
		ns.SetUnitAuraEnabled("focus", ns.AURA_TYPE.DEBUFF, false)

		local ids = { 1, 2 }
		rawset(_G, "UnitExists", function(unit)
			return unit == "focus"
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function(_, filter)
				if filter == "HELPFUL" then
					return ids
				end
				return {}
			end,
			GetAuraDataByAuraInstanceID = function(_, auraInstanceID)
				return aura(auraInstanceID)
			end,
		})

		local first = ns.RefreshUnitModel("focus")
		assert.equal(#first.buff.rows, 2)
		assert.equal(first.buff.rows[1].key, "focus:buff:1")

		ids = { 2 }
		local second = ns.RefreshUnitModel("focus")

		assert.equal(#second.buff.rows, 1)
		assert.equal(second.buff.rows[1].key, "focus:buff:2")
	end)

	runner:test("RefreshUnitModel ignores untracked units", function()
		_G.SimpleBuffsDB = nil
		ns.Runtime = nil
		ns.InitDB()

		assert.equal(ns.RefreshUnitModel("targettarget"), nil)
	end)

	local function scan_row(id, name, duration)
		return {
			auraInstanceID = id,
			aura = { auraInstanceID = id, name = name, icon = 1, duration = duration },
		}
	end

	local function set_bar_scan(rows)
		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function()
				local ids = {}
				for index = 1, #rows do
					ids[index] = rows[index].auraInstanceID
				end
				return ids
			end,
			GetAuraDataByAuraInstanceID = function(_, auraInstanceID)
				for index = 1, #rows do
					if rows[index].auraInstanceID == auraInstanceID then
						return rows[index].aura
					end
				end
				return nil
			end,
		})
	end

	runner:test("bar sort orders rows for every Bar Sort option", function()
		_G.SimpleBuffsDB = nil
		ns.Runtime = nil
		ns.InitDB()
		ns.SetUnitGroupStyle(ns.UNIT_GROUP.FOCUS, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)

		set_bar_scan({
			scan_row(1, "Charlie", 30),
			scan_row(2, "Alpha", 10),
			scan_row(3, "Bravo", 20),
		})

		ns.SetUnitGroupBarSort(ns.UNIT_GROUP.FOCUS, ns.AURA_TYPE.BUFF, ns.BAR_SORT.ALPHA_ASC)
		local model = ns.RefreshUnitModel("focus")
		assert.same({ model.buff.rows[1].aura.name, model.buff.rows[2].aura.name, model.buff.rows[3].aura.name }, { "Charlie", "Alpha", "Bravo" })

		ns.SetUnitGroupBarSort(ns.UNIT_GROUP.FOCUS, ns.AURA_TYPE.BUFF, ns.BAR_SORT.ALPHA_DESC)
		model = ns.RefreshUnitModel("focus")
		assert.same({ model.buff.rows[1].aura.name, model.buff.rows[2].aura.name, model.buff.rows[3].aura.name }, { "Bravo", "Alpha", "Charlie" })

		ns.SetUnitGroupBarSort(ns.UNIT_GROUP.FOCUS, ns.AURA_TYPE.BUFF, ns.BAR_SORT.TIME_LEFT_ASC)
		model = ns.RefreshUnitModel("focus")
		assert.same({ model.buff.rows[1].aura.name, model.buff.rows[2].aura.name, model.buff.rows[3].aura.name }, { "Charlie", "Alpha", "Bravo" })

		ns.SetUnitGroupBarSort(ns.UNIT_GROUP.FOCUS, ns.AURA_TYPE.BUFF, ns.BAR_SORT.TIME_LEFT_DESC)
		model = ns.RefreshUnitModel("focus")
		assert.same({ model.buff.rows[1].aura.name, model.buff.rows[2].aura.name, model.buff.rows[3].aura.name }, { "Bravo", "Alpha", "Charlie" })

		ns.SetUnitGroupBarSort(ns.UNIT_GROUP.FOCUS, ns.AURA_TYPE.BUFF, ns.BAR_SORT.MAX_DURATION_ASC)
		model = ns.RefreshUnitModel("focus")
		assert.same({ model.buff.rows[1].aura.name, model.buff.rows[2].aura.name, model.buff.rows[3].aura.name }, { "Alpha", "Bravo", "Charlie" })

		ns.SetUnitGroupBarSort(ns.UNIT_GROUP.FOCUS, ns.AURA_TYPE.BUFF, ns.BAR_SORT.MAX_DURATION_DESC)
		model = ns.RefreshUnitModel("focus")
		assert.same({ model.buff.rows[1].aura.name, model.buff.rows[2].aura.name, model.buff.rows[3].aura.name }, { "Charlie", "Bravo", "Alpha" })
	end)

	runner:test("max duration sort falls back to native order when duration is unreadable", function()
		_G.SimpleBuffsDB = nil
		ns.Runtime = nil
		ns.InitDB()
		ns.SetUnitGroupStyle(ns.UNIT_GROUP.FOCUS, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)
		ns.SetUnitGroupBarSort(ns.UNIT_GROUP.FOCUS, ns.AURA_TYPE.BUFF, ns.BAR_SORT.MAX_DURATION_ASC)

		local secretMeta = {
			__index = function()
				error("secret value")
			end,
		}
		local secretAura = setmetatable({ auraInstanceID = 2 }, secretMeta)

		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function()
				return { 1, 2 }
			end,
			GetAuraDataByAuraInstanceID = function(_, auraInstanceID)
				if auraInstanceID == 2 then
					return secretAura
				end
				return { auraInstanceID = 1, name = "Alpha", icon = 1, duration = 10 }
			end,
		})

		local model = ns.RefreshUnitModel("focus")
		assert.equal(#model.buff.rows, 2)
		assert.equal(model.buff.rows[1].auraInstanceID, 1)
		assert.equal(model.buff.rows[2].auraInstanceID, 2)
	end)

	local function aura_with_spell(id, name, spellId)
		return {
			auraInstanceID = id,
			name = name,
			icon = 1,
			duration = 10,
			expirationTime = 20,
			timeMod = 1,
			applications = 1,
			spellId = spellId,
		}
	end

	local function set_discovery_scan(rows)
		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function()
				local ids = {}
				for index = 1, #rows do
					ids[index] = rows[index].auraInstanceID
				end
				return ids
			end,
			GetAuraDataByAuraInstanceID = function(_, auraInstanceID)
				for index = 1, #rows do
					if rows[index].auraInstanceID == auraInstanceID then
						return rows[index].aura
					end
				end
				return nil
			end,
			GetAuraDataBySpellID = function(_, spellId)
				for index = 1, #rows do
					if rows[index].aura.spellId == spellId then
						return rows[index].aura
					end
				end
				return nil
			end,
		})
	end

	runner:test("RefreshUnitModel discovers auras even when that aura type is disabled", function()
		_G.SimpleBuffsDB = nil
		ns.Runtime = nil
		ns.InitDB()
		ns.SetUnitAuraEnabled("focus", ns.AURA_TYPE.BUFF, false)

		set_discovery_scan({ { auraInstanceID = 1, aura = aura_with_spell(1, "Well Fed", 12345) } })

		ns.RefreshUnitModel("focus")

		local entries = ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.FOCUS)
		assert.equal(#entries, 1)
		assert.equal(entries[1].name, "Well Fed")
	end)

	runner:test("RefreshUnitModel excludes hidden auras from rows but keeps them known", function()
		_G.SimpleBuffsDB = nil
		ns.Runtime = nil
		ns.InitDB()

		set_discovery_scan({ { auraInstanceID = 1, aura = aura_with_spell(1, "Well Fed", 12345) } })

		local first = ns.RefreshUnitModel("focus")
		assert.equal(#first.buff.rows, 1)

		ns.SetAuraHidden(ns.UNIT_GROUP.FOCUS, 12345, true)
		local second = ns.RefreshUnitModel("focus")
		assert.equal(#second.buff.rows, 0)
		assert.equal(#ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.FOCUS), 1)

		ns.SetAuraHidden(ns.UNIT_GROUP.FOCUS, 12345, false)
		local third = ns.RefreshUnitModel("focus")
		assert.equal(#third.buff.rows, 1)
	end)

	runner:test("RefreshUnitModel keeps hiding a known aura once combat makes its live data secret", function()
		_G.SimpleBuffsDB = nil
		ns.Runtime = nil
		ns.InitDB()

		-- Seen once while readable (e.g. out of combat) so the addon has a
		-- chance to cache instanceID 1 -> spellId 777 and hide it.
		set_discovery_scan({ { auraInstanceID = 1, aura = aura_with_spell(1, "Well Fed", 777) } })
		ns.RefreshUnitModel("focus")
		ns.SetAuraHidden(ns.UNIT_GROUP.FOCUS, 777, true)
		local beforeCombat = ns.RefreshUnitModel("focus")
		assert.equal(#beforeCombat.buff.rows, 0)

		-- Combat starts while the same aura (same instanceID) is still up:
		-- its own fields throw on access (Secret Value), but auraInstanceID
		-- is never secret, and the addon should reuse the cached spellId
		-- rather than needing to re-read the now-secret one.
		local secretMeta = {
			__index = function(_, key)
				if key == "auraInstanceID" then
					return 1
				end
				error("secret value")
			end,
		}
		local secretAura = setmetatable({}, secretMeta)

		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function()
				return { 1 }
			end,
			GetAuraDataByAuraInstanceID = function()
				return secretAura
			end,
		})

		local duringCombat = ns.RefreshUnitModel("focus")
		assert.equal(#duringCombat.buff.rows, 0)
	end)

	runner:test("spellId cache prunes entries once an aura is no longer scanned", function()
		_G.SimpleBuffsDB = nil
		ns.Runtime = nil
		ns.InitDB()

		set_discovery_scan({ { auraInstanceID = 1, aura = aura_with_spell(1, "Well Fed", 777) } })
		ns.RefreshUnitModel("focus")
		ns.SetAuraHidden(ns.UNIT_GROUP.FOCUS, 777, true)
		local hidden = ns.RefreshUnitModel("focus")
		assert.equal(#hidden.buff.rows, 0)

		-- Aura 777 goes away entirely (no longer scanned at all).
		set_discovery_scan({})
		ns.RefreshUnitModel("focus")

		-- A later, unrelated aura reuses instanceID 1; it must not inherit
		-- aura 777's cached hidden state.
		set_discovery_scan({ { auraInstanceID = 1, aura = aura_with_spell(1, "Different Buff", 888) } })
		local model = ns.RefreshUnitModel("focus")
		assert.equal(#model.buff.rows, 1)
	end)

	runner:test("RefreshUnitModel refreshes the options panel only on genuine new discovery", function()
		_G.SimpleBuffsDB = nil
		ns.Runtime = nil
		ns.InitDB()

		local refreshCount = 0
		ns.RefreshOptionsPanel = function()
			refreshCount = refreshCount + 1
		end

		set_discovery_scan({ { auraInstanceID = 1, aura = aura_with_spell(1, "Well Fed", 12345) } })

		ns.RefreshUnitModel("focus")
		assert.equal(refreshCount, 1)

		ns.RefreshUnitModel("focus")
		assert.equal(refreshCount, 1)
	end)

	runner:test("RefreshUnitModel skips discovery when aura data is unreadable", function()
		_G.SimpleBuffsDB = nil
		ns.Runtime = nil
		ns.InitDB()

		local secretMeta = {
			__index = function()
				error("secret value")
			end,
		}
		local secretAura = setmetatable({ auraInstanceID = 1 }, secretMeta)

		set_discovery_scan({ { auraInstanceID = 1, aura = secretAura } })

		local model = ns.RefreshUnitModel("focus")

		-- A read failure fails "closed" for the known-aura registry (skip
		-- registration) but "open" for display (the row still renders,
		-- matching the fallback behavior used elsewhere for secret values).
		assert.equal(#ns.GetSortedKnownAuraEntries(ns.UNIT_GROUP.FOCUS), 0)
		assert.equal(#model.buff.rows, 1)
	end)

	runner:test("MarkUnitDirty queues each tracked unit once", function()
		ns.Runtime = nil
		ns.RuntimeEnsure()

		ns.MarkUnitDirty("player")
		ns.MarkUnitDirty("player")
		ns.MarkUnitDirty("targettarget")

		assert.equal(ns.Runtime.dirtyUnits.player, true)
		assert.equal(#ns.Runtime.dirtyUnitList, 1)
		assert.equal(ns.Runtime.dirtyUnitList[1], "player")
	end)
end
