---@diagnostic disable: undefined-global

local support = require("support")
local rawassert = assert
local assert = support.assert

return function(runner, ns)
	-- Reloads the module for a fresh hooked-frames registry and installs
	-- fresh fake Blizzard frames, so each test starts unhooked.
	local function fresh_frames()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		local buffFrame = CreateFrame(ns.UI.FRAME, ns.BLIZZARD_FRAME.PLAYER_BUFF_FRAME)
		local enchantFrame = CreateFrame(ns.UI.FRAME, ns.BLIZZARD_FRAME.TEMPORARY_ENCHANT_FRAME)
		_G[ns.BLIZZARD_FRAME.PLAYER_BUFF_FRAME] = buffFrame
		_G[ns.BLIZZARD_FRAME.TEMPORARY_ENCHANT_FRAME] = enchantFrame
		rawassert(loadfile(SIMPLEBUFFS_TEST_ROOT .. "/UI/BlizzardBuffFrame.lua"))()
		return buffFrame, enchantFrame
	end

	runner:test("refresh hides both Blizzard buff frames when the setting is on", function()
		local buffFrame, enchantFrame = fresh_frames()
		ns.SetBlizzardPlayerBuffsHidden(true)
		ns.RefreshBlizzardPlayerBuffsVisibility()
		assert.equal(buffFrame:IsShown(), false)
		assert.equal(enchantFrame:IsShown(), false)
	end)

	runner:test("refresh shows the frames again when the setting is off", function()
		local buffFrame, enchantFrame = fresh_frames()
		ns.SetBlizzardPlayerBuffsHidden(true)
		ns.RefreshBlizzardPlayerBuffsVisibility()
		ns.SetBlizzardPlayerBuffsHidden(false)
		ns.RefreshBlizzardPlayerBuffsVisibility()
		assert.equal(buffFrame:IsShown(), true)
		assert.equal(enchantFrame:IsShown(), true)
	end)

	runner:test("OnShow hook re-hides Blizzard re-shows only while hidden is on", function()
		local buffFrame = fresh_frames()
		ns.SetBlizzardPlayerBuffsHidden(true)
		ns.RefreshBlizzardPlayerBuffsVisibility()

		-- Blizzard shows the frame again on its own (zoning, combat, ...).
		buffFrame:Show()
		buffFrame.hookScripts[ns.UI.ON_SHOW](buffFrame)
		assert.equal(buffFrame:IsShown(), false)

		ns.SetBlizzardPlayerBuffsHidden(false)
		buffFrame:Show()
		buffFrame.hookScripts[ns.UI.ON_SHOW](buffFrame)
		assert.equal(buffFrame:IsShown(), true)
	end)

	runner:test("frames are hooked once across repeated refreshes", function()
		local buffFrame = fresh_frames()
		local hookCount = 0
		local originalHookScript = buffFrame.HookScript
		buffFrame.HookScript = function(self, event, handler)
			hookCount = hookCount + 1
			originalHookScript(self, event, handler)
		end
		ns.SetBlizzardPlayerBuffsHidden(true)
		ns.RefreshBlizzardPlayerBuffsVisibility()
		ns.RefreshBlizzardPlayerBuffsVisibility()
		assert.equal(hookCount, 1)
	end)
end
