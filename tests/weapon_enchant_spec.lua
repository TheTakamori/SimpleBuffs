---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

local function no_enchant()
	return false, 0, 0, nil, false, 0, 0, nil
end

return function(runner, ns)
	local function reset()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		rawset(_G, "GetTime", function()
			return 1000
		end)
		rawset(_G, "GetWeaponEnchantInfo", no_enchant)
		rawset(_G, "GetInventoryItemTexture", function()
			return "Interface\\Icons\\INV_Weapon_Bow_07"
		end)
		rawset(_G, "C_TooltipInfo", nil)
	end

	runner:test("ScanWeaponEnchantRows returns nothing when no enchant is applied", function()
		reset()
		assert.equal(#ns.ScanWeaponEnchantRows(), 0)
	end)

	runner:test("ScanWeaponEnchantRows builds a main-hand row with a fallback name", function()
		reset()
		rawset(_G, "GetWeaponEnchantInfo", function()
			return true, 3600000, 0, 12345, false, 0, 0, nil
		end)

		local rows = ns.ScanWeaponEnchantRows()

		assert.equal(#rows, 1)
		local row = rows[1]
		assert.equal(row.unit, ns.UNIT_TOKEN.PLAYER)
		assert.equal(row.auraType, ns.AURA_TYPE.BUFF)
		assert.equal(row.auraInstanceID, ns.WEAPON_ENCHANT_INSTANCE_ID.MAINHAND)
		assert.equal(row.aura.name, "Main-Hand Enchant")
		assert.equal(row.aura.icon, "Interface\\Icons\\INV_Weapon_Bow_07")
		assert.equal(row.aura.spellId, 12345)
		assert.equal(row.aura.expirationTime, 1000 + 3600)
		assert.equal(row.applicationDisplayCount, nil)
	end)

	runner:test("ScanWeaponEnchantRows builds both hands independently", function()
		reset()
		rawset(_G, "GetWeaponEnchantInfo", function()
			return true, 60000, 3, 111, true, 30000, 0, 222
		end)

		local rows = ns.ScanWeaponEnchantRows()

		assert.equal(#rows, 2)
		assert.equal(rows[1].auraInstanceID, ns.WEAPON_ENCHANT_INSTANCE_ID.MAINHAND)
		assert.equal(rows[1].applicationDisplayCount, 3)
		assert.equal(rows[2].auraInstanceID, ns.WEAPON_ENCHANT_INSTANCE_ID.OFFHAND)
		assert.equal(rows[2].aura.name, "Off-Hand Enchant")
	end)

	runner:test("ScanWeaponEnchantRows resolves the real enchant name via tooltip lines", function()
		reset()
		rawset(_G, "GetWeaponEnchantInfo", function()
			return true, 3600000, 0, 555, false, 0, 0, nil
		end)
		rawset(_G, "C_TooltipInfo", {
			GetInventoryItem = function(unit, slot)
				assert.equal(unit, ns.UNIT_TOKEN.PLAYER)
				assert.equal(slot, _G.INVSLOT_MAINHAND)
				return {
					lines = {
						{ leftText = "Shadowcore Oil" },
						{ leftText = "Enchanted: Shadowcore Oil" },
					},
				}
			end,
		})

		local rows = ns.ScanWeaponEnchantRows()

		assert.equal(rows[1].aura.name, "Shadowcore Oil")
	end)

	runner:test("ScanWeaponEnchantRows falls back to a generic name when the tooltip has no enchant line", function()
		reset()
		-- A distinct enchant ID from the previous test's, since resolved names
		-- are cached by enchant ID for the lifetime of the addon session.
		rawset(_G, "GetWeaponEnchantInfo", function()
			return true, 3600000, 0, 556, false, 0, 0, nil
		end)
		rawset(_G, "C_TooltipInfo", {
			GetInventoryItem = function()
				return { lines = { { leftText = "Some Weapon" } } }
			end,
		})

		local rows = ns.ScanWeaponEnchantRows()

		assert.equal(rows[1].aura.name, "Main-Hand Enchant")
	end)

	runner:test("ScanWeaponEnchantRows caches a resolved name instead of re-scanning every call", function()
		reset()
		rawset(_G, "GetWeaponEnchantInfo", function()
			return true, 3600000, 0, 777, false, 0, 0, nil
		end)
		local lookups = 0
		rawset(_G, "C_TooltipInfo", {
			GetInventoryItem = function()
				lookups = lookups + 1
				return { lines = { { leftText = "Enchanted: Elemental Sharpening Stone" } } }
			end,
		})

		ns.ScanWeaponEnchantRows()
		local rows = ns.ScanWeaponEnchantRows()

		assert.equal(lookups, 1)
		assert.equal(rows[1].aura.name, "Elemental Sharpening Stone")
	end)

	runner:test("ScanWeaponEnchantRows keeps the same cooldown window across repeated scans of one application", function()
		reset()
		local now = 1000
		rawset(_G, "GetTime", function()
			return now
		end)
		rawset(_G, "GetWeaponEnchantInfo", function()
			-- Remaining time genuinely ticking down between scans, as it would
			-- in a real session, not a fresh application each time.
			return true, (3600 - (now - 1000)) * 1000, 0, 999, false, 0, 0, nil
		end)

		local first = ns.ScanWeaponEnchantRows()[1]
		now = 1005
		local second = ns.ScanWeaponEnchantRows()[1]

		assert.equal(second.aura.expirationTime, first.aura.expirationTime)
		assert.equal(second.aura.duration, first.aura.duration)
	end)

	runner:test("ScanWeaponEnchantRows starts a fresh window when the enchant is reapplied", function()
		reset()
		local now = 1000
		rawset(_G, "GetTime", function()
			return now
		end)
		rawset(_G, "GetWeaponEnchantInfo", function()
			return true, 5000, 0, 999, false, 0, 0, nil
		end)

		local first = ns.ScanWeaponEnchantRows()[1]

		-- Re-applied with a full fresh duration well beyond what a continuous
		-- countdown from the first window would allow.
		now = 1004
		rawset(_G, "GetWeaponEnchantInfo", function()
			return true, 3600000, 0, 999, false, 0, 0, nil
		end)
		local second = ns.ScanWeaponEnchantRows()[1]

		assert.equal(second.aura.expirationTime ~= first.aura.expirationTime, true)
		assert.equal(second.aura.expirationTime, now + 3600)
	end)

	runner:test("ScanWeaponEnchantRows clears its cached window once the enchant is gone", function()
		reset()
		rawset(_G, "GetWeaponEnchantInfo", function()
			return true, 3600000, 0, 999, false, 0, 0, nil
		end)
		ns.ScanWeaponEnchantRows()

		rawset(_G, "GetWeaponEnchantInfo", no_enchant)
		assert.equal(#ns.ScanWeaponEnchantRows(), 0)

		-- Reapplying afterward should not resurrect the stale window from
		-- before it was removed.
		rawset(_G, "GetTime", function()
			return 5000
		end)
		rawset(_G, "GetWeaponEnchantInfo", function()
			return true, 3600000, 0, 999, false, 0, 0, nil
		end)
		local row = ns.ScanWeaponEnchantRows()[1]
		assert.equal(row.aura.expirationTime, 5000 + 3600)
	end)

	runner:test("ScanUnitAuraType appends weapon enchant rows to the player's buff scan", function()
		reset()
		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function()
				return {}
			end,
			GetAuraDataByAuraInstanceID = function()
				return nil
			end,
		})
		rawset(_G, "GetWeaponEnchantInfo", function()
			return true, 3600000, 0, 999, false, 0, 0, nil
		end)

		local rows = ns.ScanUnitAuraType(ns.UNIT_TOKEN.PLAYER, ns.AURA_TYPE.BUFF)

		assert.equal(#rows, 1)
		assert.equal(rows[1].auraInstanceID, ns.WEAPON_ENCHANT_INSTANCE_ID.MAINHAND)
	end)

	runner:test("ScanUnitAuraType never appends weapon enchant rows for other units or debuffs", function()
		reset()
		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function()
				return {}
			end,
			GetAuraDataByAuraInstanceID = function()
				return nil
			end,
		})
		rawset(_G, "GetWeaponEnchantInfo", function()
			return true, 3600000, 0, 999, false, 0, 0, nil
		end)

		assert.equal(#ns.ScanUnitAuraType(ns.UNIT_TOKEN.TARGET, ns.AURA_TYPE.BUFF), 0)
		assert.equal(#ns.ScanUnitAuraType(ns.UNIT_TOKEN.PLAYER, ns.AURA_TYPE.DEBUFF), 0)
	end)

	runner:test("ScanUnitAuraType respects Max Auras when appending weapon enchant rows", function()
		reset()
		ns.SetUnitGroupAppearanceValue(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.DB_KEY.MAX_AURAS, 1)
		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "C_UnitAuras", {
			GetUnitAuraInstanceIDs = function()
				return { 1 }
			end,
			GetAuraDataByAuraInstanceID = function(_, auraInstanceID)
				return { auraInstanceID = auraInstanceID, name = "Real Buff", icon = 1, duration = 10, expirationTime = 20 }
			end,
		})
		rawset(_G, "GetWeaponEnchantInfo", function()
			return true, 3600000, 0, 999, true, 3600000, 0, 998
		end)

		local rows = ns.ScanUnitAuraType(ns.UNIT_TOKEN.PLAYER, ns.AURA_TYPE.BUFF)

		-- Max Auras is already met by the one real buff, so neither weapon
		-- enchant row gets to squeeze in over the configured cap.
		assert.equal(#rows, 1)
		assert.equal(rows[1].aura.name, "Real Buff")
	end)
end
