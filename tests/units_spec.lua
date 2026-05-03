---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

local function make_frame(unit)
	return {
		unit = unit,
		IsShown = function()
			return true
		end,
		IsVisible = function()
			return true
		end,
	}
end

return function(runner, ns)
	runner:test("unit registry maps supported groups", function()
		assert.equal(ns.GetUnitGroup("player"), ns.UNIT_GROUP.PLAYER)
		assert.equal(ns.GetUnitGroup("target"), ns.UNIT_GROUP.TARGET)
		assert.equal(ns.GetUnitGroup("focus"), ns.UNIT_GROUP.FOCUS)
		assert.equal(ns.GetUnitGroup("pet"), ns.UNIT_GROUP.PET)
		assert.equal(ns.GetUnitGroup("vehicle"), nil)
		assert.equal(ns.GetUnitGroup("mouseover"), nil)
		assert.equal(ns.GetUnitGroup("party4"), ns.UNIT_GROUP.PARTY)
		assert.equal(ns.GetUnitGroup("raid40"), ns.UNIT_GROUP.RAID)
		assert.equal(ns.GetUnitGroup("boss8"), ns.UNIT_GROUP.BOSS)
		assert.equal(ns.GetUnitGroup("arena5"), ns.UNIT_GROUP.ARENA)
		assert.equal(ns.GetUnitGroup("nameplate40"), nil)
	end)

	runner:test("unit registry iterates units by group", function()
		local units = {}
		ns.ForEachUnitInGroup(ns.UNIT_GROUP.ARENA, function(unit)
			units[#units + 1] = unit
		end)

		assert.equal(#units, 5)
		assert.equal(units[1], "arena1")
		assert.equal(units[5], "arena5")
	end)

	runner:test("attached anchors resolve confirmed Blizzard frame paths", function()
		local raidFrame = make_frame("raid14")
		local raidPetFrame = make_frame("raidpet2")
		local partyPetFrame = make_frame("partypet1")
		local bossFrame = make_frame("boss3")
		local arenaFrame = make_frame("arena4")
		local arenaPetFrame = make_frame("arenapet2")

		_G.CompactRaidFrameContainer = {
			IsShown = function()
				return true
			end,
			IsVisible = function()
				return true
			end,
			GetChildren = function()
				return raidFrame, raidPetFrame, partyPetFrame
			end,
		}
		_G.Boss3TargetFrame = bossFrame
		_G.ArenaEnemyMatchFrame4 = arenaFrame
		_G.ArenaEnemyMatchFrame2PetFrame = arenaPetFrame

		assert.equal(ns.GetAttachedDisplayAnchor("raid14"), raidFrame)
		assert.equal(ns.GetAttachedDisplayAnchor("raidpet2"), raidPetFrame)
		assert.equal(ns.GetAttachedDisplayAnchor("partypet1"), partyPetFrame)
		assert.equal(ns.GetAttachedDisplayAnchor("boss3"), bossFrame)
		assert.equal(ns.GetAttachedDisplayAnchor("arena4"), arenaFrame)
		assert.equal(ns.GetAttachedDisplayAnchor("arenapet2"), arenaPetFrame)

		_G.CompactRaidFrameContainer = nil
		_G.Boss3TargetFrame = nil
		_G.ArenaEnemyMatchFrame4 = nil
		_G.ArenaEnemyMatchFrame2PetFrame = nil
	end)
end
