---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

return function(runner, ns)
	local function reset_db()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		_G.SimpleBuffs.Runtime = nil
		ns.RuntimeEnsure()
		rawset(_G, "UnitExists", function()
			return true
		end)
		rawset(_G, "GetTime", function()
			return 1000
		end)
		ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER, ns.DISPLAY_MODE.STANDALONE)
	end

	local function player_container(auraType)
		local runtime = ns.RuntimeEnsure()
		local containerKey = ns.GetStandaloneContainerInstanceKey(ns.UNIT_GROUP.PLAYER, auraType)
		return runtime.containers[containerKey]
	end

	runner:test("Buffs and Debuffs get separate, independently positioned standalone containers", function()
		reset_db()
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.DEBUFF, true)

		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		local buffContainer = player_container(ns.AURA_TYPE.BUFF)
		local debuffContainer = player_container(ns.AURA_TYPE.DEBUFF)
		assert.equal(buffContainer ~= nil, true)
		assert.equal(debuffContainer ~= nil, true)
		assert.equal(buffContainer ~= debuffContainer, true)

		-- They default to different screen positions (not stacked exactly on
		-- top of each other) and are tracked under separate DB keys.
		local buffKey = ns.GetStandaloneContainerInstanceKey(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF)
		local debuffKey = ns.GetStandaloneContainerInstanceKey(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.DEBUFF)
		assert.equal(buffKey ~= debuffKey, true)
		assert.equal(ns.DB().standalone[buffKey] ~= ns.DB().standalone[debuffKey], true)
		assert.equal(ns.DB().standalone[buffKey].y ~= ns.DB().standalone[debuffKey].y, true)

		-- Only the Buffs frame is parented under the Buffs container.
		local runtime = ns.RuntimeEnsure()
		local playerFrames = runtime.frames[ns.DISPLAY_MODE.STANDALONE].player
		assert.equal(playerFrames.buff:GetParent(), buffContainer)
		assert.equal(playerFrames.debuff:GetParent(), debuffContainer)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.DEBUFF, false)
	end)

	runner:test("dragging/saving the Buffs container does not move the Debuffs container", function()
		reset_db()
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.DEBUFF, true)
		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		local debuffKey = ns.GetStandaloneContainerInstanceKey(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.DEBUFF)
		local debuffBefore = { x = ns.DB().standalone[debuffKey].x, y = ns.DB().standalone[debuffKey].y }

		local buffKey = ns.GetStandaloneContainerInstanceKey(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF)
		ns.SaveStandalonePosition(buffKey, {
			GetPoint = function()
				return ns.UI.ANCHOR_CENTER, nil, ns.UI.ANCHOR_CENTER, 999, 999
			end,
		})

		assert.equal(ns.DB().standalone[buffKey].x, 999)
		assert.equal(ns.DB().standalone[debuffKey].x, debuffBefore.x)
		assert.equal(ns.DB().standalone[debuffKey].y, debuffBefore.y)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.DEBUFF, false)
	end)

	runner:test("standalone container uses the saved drag point by default (Icon style, no Bar Anchor pin)", function()
		reset_db()
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)

		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		local container = player_container(ns.AURA_TYPE.BUFF)
		assert.equal(container ~= nil, true)
		assert.equal(container.pinnedEdge, nil)
		local saved = ns.DB().standalone[ns.GetStandaloneContainerInstanceKey(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF)]
		assert.equal(container.point, saved.point)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
	end)

	runner:test("Bar Anchor Top pins the container's bottom edge instead of reusing the saved point/offset", function()
		reset_db()
		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)
		ns.SetUnitGroupBarAnchor(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.BAR_ANCHOR.TOP)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)

		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		local container = player_container(ns.AURA_TYPE.BUFF)
		assert.equal(container.pinnedEdge, ns.UI.ANCHOR_BOTTOM)
		assert.equal(container.point, ns.UI.ANCHOR_BOTTOMLEFT)

		-- The regression this guards against: naively reusing saved.x/saved.y
		-- under the new BOTTOMLEFT point (they were captured for a different
		-- point, e.g. the CENTER default) would put the frame at an
		-- unrelated screen location. The rebase must instead be derived from
		-- the container's own current rect, so its bottom edge stays exactly
		-- where it was before the pin was applied.
		local bottomBeforeMoreBars = container:GetBottom()

		-- Adding more simulated bars grows the container. If the bottom is
		-- truly pinned, GetBottom() must stay the same afterward - only the
		-- height/top should change.
		ns.AdvanceSimulatePhase()
		ns.AdvanceSimulatePhase()
		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		assert.equal(container:GetBottom(), bottomBeforeMoreBars)
		assert.equal(container.pinnedEdge, ns.UI.ANCHOR_BOTTOM)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
	end)

	runner:test("Bar Anchor Bottom pins the container's top edge (the setting that was previously a no-op)", function()
		reset_db()
		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)
		ns.SetUnitGroupBarAnchor(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.BAR_ANCHOR.BOTTOM)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)

		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		local container = player_container(ns.AURA_TYPE.BUFF)
		assert.equal(container.pinnedEdge, ns.UI.ANCHOR_TOP)
		assert.equal(container.point, ns.UI.ANCHOR_TOPLEFT)

		local topBeforeMoreBars = container:GetTop()

		-- If the top is truly pinned, GetTop() must stay the same as more
		-- bars are added - only the height/bottom should change. Before this
		-- fix, Bar Anchor Bottom never overrode the saved/CENTER point at
		-- all, so both Top and Bottom looked identical (always centered).
		ns.AdvanceSimulatePhase()
		ns.AdvanceSimulatePhase()
		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		assert.equal(container:GetTop(), topBeforeMoreBars)
		assert.equal(container.pinnedEdge, ns.UI.ANCHOR_TOP)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
	end)

	runner:test("Debuffs container keeps using the saved point while Buffs is bottom-pinned", function()
		reset_db()
		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)
		ns.SetUnitGroupBarAnchor(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.BAR_ANCHOR.TOP)
		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.DEBUFF, ns.AURA_STYLE.ICON)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.DEBUFF, true)

		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		-- Each aura type's own container is judged independently now - the
		-- other aura type's style/anchor has no bearing on it, since they're
		-- no longer sharing one container.
		assert.equal(player_container(ns.AURA_TYPE.BUFF).pinnedEdge, ns.UI.ANCHOR_BOTTOM)
		assert.equal(player_container(ns.AURA_TYPE.DEBUFF).pinnedEdge, nil)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.DEBUFF, false)
	end)

	runner:test("switching Bar Anchor from Top to Bottom re-pins the opposite edge", function()
		reset_db()
		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)
		ns.SetUnitGroupBarAnchor(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.BAR_ANCHOR.TOP)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)

		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()
		local container = player_container(ns.AURA_TYPE.BUFF)
		assert.equal(container.pinnedEdge, ns.UI.ANCHOR_BOTTOM)

		ns.SetUnitGroupBarAnchor(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.BAR_ANCHOR.BOTTOM)
		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		assert.equal(container.pinnedEdge, ns.UI.ANCHOR_TOP)
		assert.equal(container.point, ns.UI.ANCHOR_TOPLEFT)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
	end)

	runner:test("Bar Anchor Bottom (Grow Down) position survives a relogin with a different aura count", function()
		reset_db()
		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)
		ns.SetUnitGroupBarAnchor(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.BAR_ANCHOR.BOTTOM)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)

		-- "Login #1": never dragged, so this pins from the CENTER default.
		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		local key = ns.GetStandaloneContainerInstanceKey(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF)
		local topAfterFirstLogin = player_container(ns.AURA_TYPE.BUFF):GetTop()
		assert.equal(ns.DB().standalone[key].point, ns.UI.ANCHOR_TOPLEFT)

		-- "Login #2": DB persists, but the runtime (and thus pinnedEdge and
		-- the container object) is torn down, and this session happens to
		-- have a different number of active buffs.
		_G.SimpleBuffs.Runtime = nil
		ns.RuntimeEnsure()
		ns.AdvanceSimulatePhase()
		ns.AdvanceSimulatePhase()
		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		assert.equal(player_container(ns.AURA_TYPE.BUFF):GetTop(), topAfterFirstLogin)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
	end)

	runner:test("Bar Anchor Top (Grow Up) position survives a relogin with a different aura count", function()
		reset_db()
		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)
		ns.SetUnitGroupBarAnchor(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.BAR_ANCHOR.TOP)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)

		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		local key = ns.GetStandaloneContainerInstanceKey(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF)
		local bottomAfterFirstLogin = player_container(ns.AURA_TYPE.BUFF):GetBottom()
		assert.equal(ns.DB().standalone[key].point, ns.UI.ANCHOR_BOTTOMLEFT)

		_G.SimpleBuffs.Runtime = nil
		ns.RuntimeEnsure()
		ns.AdvanceSimulatePhase()
		ns.AdvanceSimulatePhase()
		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		assert.equal(player_container(ns.AURA_TYPE.BUFF):GetBottom(), bottomAfterFirstLogin)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
	end)

	runner:test("switching Bar Anchor persists the new corner, not just the in-memory point", function()
		reset_db()
		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)
		ns.SetUnitGroupBarAnchor(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.BAR_ANCHOR.TOP)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)

		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		ns.SetUnitGroupBarAnchor(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.BAR_ANCHOR.BOTTOM)
		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		local key = ns.GetStandaloneContainerInstanceKey(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF)
		assert.equal(ns.DB().standalone[key].point, ns.UI.ANCHOR_TOPLEFT)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
	end)

	runner:test("a manually dragged position is not disturbed by the pin-save on the next layout pass", function()
		reset_db()
		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)
		ns.SetUnitGroupBarAnchor(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.BAR_ANCHOR.BOTTOM)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)

		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		local key = ns.GetStandaloneContainerInstanceKey(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF)
		local container = player_container(ns.AURA_TYPE.BUFF)
		ns.SaveStandalonePosition(key, container)
		local draggedX, draggedY = ns.DB().standalone[key].x, ns.DB().standalone[key].y

		-- Re-running layout without adding/removing bars should be a no-op
		-- for the pinned edge (already at desiredEdge), so it must not
		-- re-save and must not move the dragged spot.
		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		assert.equal(ns.DB().standalone[key].x, draggedX)
		assert.equal(ns.DB().standalone[key].y, draggedY)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
	end)

	runner:test("switching Style back to Icon un-pins and restores the saved point", function()
		reset_db()
		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)
		ns.SetUnitGroupBarAnchor(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.BAR_ANCHOR.TOP)
		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, true)

		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()
		local container = player_container(ns.AURA_TYPE.BUFF)
		assert.equal(container.pinnedEdge, ns.UI.ANCHOR_BOTTOM)

		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.ICON)
		ns.RefreshAndUpdateUnit("player")
		ns.LayoutStandaloneContainers()

		assert.equal(container.pinnedEdge, nil)
		local saved = ns.DB().standalone[ns.GetStandaloneContainerInstanceKey(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF)]
		assert.equal(container.point, saved.point)

		ns.SetSimulateEnabled(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, false)
	end)
end
