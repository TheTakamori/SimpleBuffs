---@diagnostic disable: undefined-global

local support = require("support")
local rawassert = assert
local assert = support.assert

return function(runner, ns)
	-- Bootstrap creates its event frame at load time; capture it by wrapping
	-- CreateFrame around a fresh load of the file.
	local function load_bootstrap()
		local originalCreateFrame = _G.CreateFrame
		local eventFrame = nil
		_G.CreateFrame = function(...)
			local frame = originalCreateFrame(...)
			eventFrame = eventFrame or frame
			return frame
		end
		rawassert(loadfile(SIMPLEBUFFS_TEST_ROOT .. "/Core/Bootstrap.lua"))()
		_G.CreateFrame = originalCreateFrame
		return eventFrame
	end

	-- Fires an event through the captured OnEvent handler with unit-refresh
	-- collaborators stubbed, returning the units that were refreshed.
	local function fire_event(eventFrame, event, arg1)
		local refreshedUnits = {}
		local layoutCalls = 0
		local originalRefreshUnit = ns.RefreshAndUpdateUnit
		local originalLayout = ns.LayoutStandaloneContainers
		ns.RefreshAndUpdateUnit = function(unit)
			refreshedUnits[#refreshedUnits + 1] = unit
		end
		ns.LayoutStandaloneContainers = function()
			layoutCalls = layoutCalls + 1
		end

		local ok, err = pcall(eventFrame.scripts[ns.UI.ON_EVENT], eventFrame, event, arg1)

		ns.RefreshAndUpdateUnit = originalRefreshUnit
		ns.LayoutStandaloneContainers = originalLayout
		if not ok then
			error(err, 2)
		end
		return refreshedUnits, layoutCalls
	end

	runner:test("Bootstrap registers every handled event", function()
		local eventFrame = load_bootstrap()
		for _, event in pairs(ns.EVENT) do
			assert.equal(eventFrame.registeredEvents[event], true, "missing " .. event)
		end
	end)

	runner:test("ADDON_LOADED for this addon initializes the DB and announces", function()
		local eventFrame = load_bootstrap()
		_G.SimpleBuffsDB = nil
		_G.SlashCmdList = {}
		local messages = {}
		local originalPrint = ns.PrintMessage
		ns.PrintMessage = function(message)
			messages[#messages + 1] = message
		end

		eventFrame.scripts[ns.UI.ON_EVENT](eventFrame, ns.EVENT.ADDON_LOADED, "SomeOtherAddon")
		assert.equal(_G.SimpleBuffsDB, nil)

		eventFrame.scripts[ns.UI.ON_EVENT](eventFrame, ns.EVENT.ADDON_LOADED, ns.ADDON_NAME)
		ns.PrintMessage = originalPrint

		assert.equal(type(_G.SimpleBuffsDB), "table")
		assert.same(messages, { ns.TEXT.LOADED })
		assert.equal(type(SlashCmdList.SIMPLEBUFFS), "function")
	end)

	runner:test("target and focus changes refresh exactly that unit", function()
		local eventFrame = load_bootstrap()
		local refreshed, layoutCalls = fire_event(eventFrame, ns.EVENT.PLAYER_TARGET_CHANGED)
		assert.same(refreshed, { ns.UNIT_TOKEN.TARGET })
		assert.equal(layoutCalls, 1)
		refreshed = fire_event(eventFrame, ns.EVENT.PLAYER_FOCUS_CHANGED)
		assert.same(refreshed, { ns.UNIT_TOKEN.FOCUS })
	end)

	runner:test("UNIT_PET refreshes the player pet or the pet groups", function()
		local eventFrame = load_bootstrap()
		local refreshed = fire_event(eventFrame, ns.EVENT.UNIT_PET, ns.UNIT_TOKEN.PLAYER)
		assert.same(refreshed, { ns.UNIT_TOKEN.PET })

		refreshed = fire_event(eventFrame, ns.EVENT.UNIT_PET, "party2")
		assert.equal(#refreshed, ns.GROUP_SIZE.PARTY + ns.GROUP_SIZE.RAID)
		assert.equal(refreshed[1], "partypet1")
		assert.equal(refreshed[#refreshed], "raidpet" .. ns.GROUP_SIZE.RAID)
	end)

	runner:test("roster updates refresh party, party pets, raid, and raid pets", function()
		local eventFrame = load_bootstrap()
		for _, event in ipairs({ ns.EVENT.GROUP_ROSTER_UPDATE, ns.EVENT.RAID_ROSTER_UPDATE }) do
			local refreshed, layoutCalls = fire_event(eventFrame, event)
			assert.equal(#refreshed, (ns.GROUP_SIZE.PARTY + ns.GROUP_SIZE.RAID) * 2)
			assert.equal(refreshed[1], "party1")
			assert.equal(layoutCalls, 1)
		end
	end)

	runner:test("encounter and arena events refresh boss and arena groups", function()
		local eventFrame = load_bootstrap()
		local refreshed = fire_event(eventFrame, ns.EVENT.INSTANCE_ENCOUNTER_ENGAGE_UNIT)
		assert.equal(#refreshed, ns.GROUP_SIZE.BOSS)
		assert.equal(refreshed[1], "boss1")

		refreshed = fire_event(eventFrame, ns.EVENT.ARENA_OPPONENT_UPDATE)
		assert.equal(#refreshed, ns.GROUP_SIZE.ARENA * 2)
		assert.equal(refreshed[1], "arena1")
		assert.equal(refreshed[#refreshed], "arenapet" .. ns.GROUP_SIZE.ARENA)
	end)

	runner:test("UNIT_AURA marks tracked units dirty and coalesces into one OnUpdate", function()
		local eventFrame = load_bootstrap()
		local dirtyUnits = {}
		local dirtyRefreshes = 0
		local originalMark = ns.MarkUnitDirty
		local originalDirty = ns.RefreshAndUpdateDirtyUnits
		ns.MarkUnitDirty = function(unit)
			dirtyUnits[#dirtyUnits + 1] = unit
		end
		ns.RefreshAndUpdateDirtyUnits = function()
			dirtyRefreshes = dirtyRefreshes + 1
		end

		local handler = eventFrame.scripts[ns.UI.ON_EVENT]
		handler(eventFrame, ns.EVENT.UNIT_AURA, "nonsenseunit")
		handler(eventFrame, ns.EVENT.UNIT_AURA, "player")
		handler(eventFrame, ns.EVENT.UNIT_AURA, "target")

		assert.same(dirtyUnits, { "player", "target" })
		assert.equal(type(eventFrame.scripts[ns.UI.ON_UPDATE]), "function")

		eventFrame.scripts[ns.UI.ON_UPDATE]()
		ns.MarkUnitDirty = originalMark
		ns.RefreshAndUpdateDirtyUnits = originalDirty

		assert.equal(dirtyRefreshes, 1)
		assert.equal(eventFrame.scripts[ns.UI.ON_UPDATE], nil)
	end)
end
