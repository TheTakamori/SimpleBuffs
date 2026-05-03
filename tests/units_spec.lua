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

	runner:test("unit registry iterates units by standalone container", function()
		local units = {}
		ns.ForEachUnitInStandaloneContainer(ns.STANDALONE_CONTAINER_KEY.ENEMY, function(unit)
			units[#units + 1] = unit
		end)

		assert.equal(#units, 18)
		assert.equal(units[1], "boss1")
		assert.equal(units[9], "arena1")
		assert.equal(units[18], "arenapet5")
	end)

	runner:test("attached anchors resolve confirmed Blizzard frame paths", function()
		local partyFrame = make_frame("party1")
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
		_G.CompactPartyFrameMember1 = partyFrame
		_G.Boss3TargetFrame = bossFrame
		_G.ArenaEnemyMatchFrame4 = arenaFrame
		_G.ArenaEnemyMatchFrame2PetFrame = arenaPetFrame

		assert.equal(ns.GetAttachedDisplayAnchor("party1"), partyFrame)
		assert.equal(ns.GetAttachedDisplayAnchor("raid14"), raidFrame)
		assert.equal(ns.GetAttachedDisplayAnchor("raidpet2"), raidPetFrame)
		assert.equal(ns.GetAttachedDisplayAnchor("partypet1"), partyPetFrame)
		assert.equal(ns.GetAttachedDisplayAnchor("boss3"), bossFrame)
		assert.equal(ns.GetAttachedDisplayAnchor("arena4"), arenaFrame)
		assert.equal(ns.GetAttachedDisplayAnchor("arenapet2"), arenaPetFrame)

		_G.CompactRaidFrameContainer = nil
		_G.CompactPartyFrameMember1 = nil
		_G.Boss3TargetFrame = nil
		_G.ArenaEnemyMatchFrame4 = nil
		_G.ArenaEnemyMatchFrame2PetFrame = nil
	end)

	runner:test("party and party pet attached anchors use right-side positions", function()
		local partyFrame = make_frame("party1")
		local partyPetFrame = make_frame("partypet1")
		_G.CompactPartyFrameMember1 = partyFrame
		_G.CompactRaidFrameContainer = {
			IsShown = function()
				return true
			end,
			IsVisible = function()
				return true
			end,
			GetChildren = function()
				return partyPetFrame
			end,
		}

		local _, partyPosition = ns.GetAttachedDisplayAnchor("party1")
		local _, partyPetPosition = ns.GetAttachedDisplayAnchor("partypet1")

		assert.equal(partyPosition.relativePoint, ns.UI.ANCHOR_TOPRIGHT)
		assert.equal(partyPosition.x, ns.ATTACHED_LAYOUT.PARTY_CONTAINER_X)
		assert.equal(partyPosition.y, ns.ATTACHED_LAYOUT.PARTY_CONTAINER_Y)
		assert.equal(partyPetPosition.relativePoint, ns.UI.ANCHOR_TOPRIGHT)
		assert.equal(partyPetPosition.x, ns.ATTACHED_LAYOUT.PARTY_CONTAINER_X)
		assert.equal(partyPetPosition.y, ns.ATTACHED_LAYOUT.PARTY_CONTAINER_Y)

		_G.CompactPartyFrameMember1 = nil
		_G.CompactRaidFrameContainer = nil
	end)

	runner:test("party container fallback positions are cached independently", function()
		local container = make_frame(nil)
		_G.CompactPartyFrame = container

		ns.BeginAttachedAnchorCache()
		local _, partyOnePosition = ns.GetAttachedDisplayAnchor("party1")
		local _, partyTwoPosition = ns.GetAttachedDisplayAnchor("party2")
		ns.EndAttachedAnchorCache()

		assert.equal(partyOnePosition == partyTwoPosition, false)
		assert.equal(partyOnePosition.y, ns.ATTACHED_LAYOUT.PARTY_CONTAINER_Y)
		assert.equal(partyTwoPosition.y, ns.ATTACHED_LAYOUT.PARTY_CONTAINER_Y - ns.ATTACHED_LAYOUT.PARTY_ROW_SPACING)

		_G.CompactPartyFrame = nil
	end)

	runner:test("attached anchor cache tolerates nested begin and end", function()
		local playerFrame = make_frame("player")
		_G.PlayerFrame = playerFrame

		ns.BeginAttachedAnchorCache()
		ns.BeginAttachedAnchorCache()
		assert.equal(ns.GetAttachedDisplayAnchor("player"), playerFrame)
		ns.EndAttachedAnchorCache()
		assert.equal(ns.GetAttachedDisplayAnchor("player"), playerFrame)
		ns.EndAttachedAnchorCache()

		_G.PlayerFrame = nil
	end)
end
