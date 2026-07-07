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
