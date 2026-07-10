---@diagnostic disable: undefined-global

local source = debug.getinfo(1, "S").source
local script_path = source:sub(1, 1) == "@" and source:sub(2) or source
if script_path:sub(1, 1) ~= "/" then
	script_path = (os.getenv("PWD") or ".") .. "/" .. script_path
end
local script_dir = script_path:match("^(.*)/[^/]+$") or "."
local root = script_dir:gsub("/tests$", "")
-- Specs that need to (re)load an addon file themselves (for isolated
-- module-local state or to capture frames created at load time) use this.
_G.SIMPLEBUFFS_TEST_ROOT = root

package.path = table.concat({
	root .. "/tests/?.lua",
	package.path,
}, ";")

_G.SimpleBuffs = {}
_G.time = os.time
_G.Enum = {
	UnitAuraSortRule = {
		Default = "Default",
		Expiration = "Expiration",
		ExpirationOnly = "ExpirationOnly",
		Unsorted = "Unsorted",
		NameOnly = "NameOnly",
	},
	UnitAuraSortDirection = {
		Normal = "Normal",
	},
	StatusBarFillDirection = {
		Reverse = "Reverse",
	},
}

assert(loadfile(root .. "/Core/Constants.lua"))()
assert(loadfile(root .. "/Core/WoWConstants.lua"))()
assert(loadfile(root .. "/Core/UIConstants.lua"))()
assert(loadfile(root .. "/Core/Text.lua"))()
assert(loadfile(root .. "/Core/UnitRegistry.lua"))()
assert(loadfile(root .. "/Core/Defaults.lua"))()
assert(loadfile(root .. "/Core/Runtime.lua"))()
assert(loadfile(root .. "/Core/StateMigration.lua"))()
assert(loadfile(root .. "/Core/State.lua"))()
assert(loadfile(root .. "/Core/KnownAuras.lua"))()
assert(loadfile(root .. "/Core/PositionState.lua"))()
assert(loadfile(root .. "/UI/DisplayAnchors.lua"))()
assert(loadfile(root .. "/UI/StandaloneDrag.lua"))()
assert(loadfile(root .. "/Core/Units.lua"))()
assert(loadfile(root .. "/Core/Scanner.lua"))()
assert(loadfile(root .. "/Core/Model.lua"))()
assert(loadfile(root .. "/UI/OptionsRefresh.lua"))()
assert(loadfile(root .. "/UI/OptionsPanelData.lua"))()
assert(loadfile(root .. "/UI/SlashCommands.lua"))()

local function make_test_frame(name)
	local frame
	frame = {
		name = name,
		scripts = {},
		shown = true,
		width = 0,
		height = 0,
		anchorX = 0,
		anchorY = 0,
		CreateTexture = function()
			return {
				SetAllPoints = function() end,
				ClearAllPoints = function() end,
				SetPoint = function() end,
				SetTexCoord = function() end,
				SetTexture = function() end,
				SetColorTexture = function() end,
				SetSize = function() end,
				SetShown = function(self, shown)
					self.shown = shown == true
				end,
			}
		end,
		CreateFontString = function()
			return {
				SetPoint = function() end,
				ClearAllPoints = function() end,
				SetText = function() end,
				SetJustifyH = function() end,
				SetWidth = function() end,
				Show = function() end,
			}
		end,
		SetSize = function(self, width, height)
			self.width = width
			self.height = height
		end,
		SetHeight = function(self, height)
			self.height = height
		end,
		GetWidth = function(self)
			return self.width
		end,
		GetHeight = function(self)
			return self.height
		end,
		SetAllPoints = function() end,
		SetReverse = function() end,
		SetHideCountdownNumbers = function() end,
		SetDrawSwipe = function() end,
		SetDrawEdge = function() end,
		SetCooldown = function(self, start, duration, modRate)
			self.cooldownStart = start
			self.cooldownDuration = duration
			self.cooldownModRate = modRate
		end,
		Clear = function(self)
			self.cooldownStart = nil
			self.cooldownDuration = nil
		end,
		SetStatusBarTexture = function(self, texture)
			self.statusBarTexture = texture
		end,
		RegisterForDrag = function() end,
		SetScript = function(self, event, handler)
			self.scripts[event] = handler
		end,
		HookScript = function(self, event, handler)
			self.hookScripts = self.hookScripts or {}
			self.hookScripts[event] = handler
		end,
		RegisterEvent = function(self, event)
			self.registeredEvents = self.registeredEvents or {}
			self.registeredEvents[event] = true
		end,
		SetMouseClickEnabled = function(self, enabled)
			self.mouseClickEnabled = enabled
		end,
		EnableMouse = function(self, enabled)
			self.mouseEnabled = enabled
		end,
		ClearAllPoints = function(self)
			self.point = nil
			self.relativeTo = nil
			self.relativePoint = nil
		end,
		SetPoint = function(self, point, relativeTo, relativePoint, x, y)
			self.point = point
			self.relativeTo = relativeTo
			self.relativePoint = relativePoint
			self.x = x
			self.y = y
			-- Resolve the anchor's absolute coordinate so GetLeft/GetTop/
			-- GetBottom behave like real WoW frames for the anchor-rebasing
			-- logic under test. anchorY is whatever edge `point` names
			-- (TOPLEFT's y IS the top, BOTTOMLEFT's y IS the bottom); the
			-- other edge is derived from the frame's current height in
			-- GetTop/GetBottom below, not frozen here, since SetSize can
			-- change height after SetPoint.
			local baseLeft, baseBottom = 0, 0
			if relativeTo and relativeTo.GetLeft then
				baseLeft = relativeTo:GetLeft() or 0
				baseBottom = relativeTo:GetBottom() or 0
			end
			self.anchorX = baseLeft + (x or 0)
			self.anchorY = baseBottom + (y or 0)
		end,
		GetPoint = function(self)
			return self.point, self.relativeTo, self.relativePoint, self.x, self.y
		end,
		GetLeft = function(self)
			return self.anchorX
		end,
		GetBottom = function(self)
			local anchorY = self.anchorY or 0
			if self.point == SimpleBuffs.UI.ANCHOR_TOPLEFT or self.point == SimpleBuffs.UI.ANCHOR_TOP or self.point == SimpleBuffs.UI.ANCHOR_TOPRIGHT then
				return anchorY - (self.height or 0)
			end
			if self.point == SimpleBuffs.UI.ANCHOR_CENTER then
				return anchorY - (self.height or 0) / 2
			end
			return anchorY
		end,
		GetTop = function(self)
			local anchorY = self.anchorY or 0
			if self.point == SimpleBuffs.UI.ANCHOR_BOTTOMLEFT or self.point == SimpleBuffs.UI.ANCHOR_BOTTOM or self.point == SimpleBuffs.UI.ANCHOR_BOTTOMRIGHT then
				return anchorY + (self.height or 0)
			end
			if self.point == SimpleBuffs.UI.ANCHOR_CENTER then
				return anchorY + (self.height or 0) / 2
			end
			return anchorY
		end,
		Show = function(self)
			self.shown = true
		end,
		Hide = function(self)
			self.shown = false
		end,
		SetShown = function(self, shown)
			self.shown = shown == true
		end,
		IsShown = function(self)
			return self.shown == true
		end,
		IsVisible = function(self)
			return self.shown == true
		end,
		SetFrameStrata = function(self, strata)
			self.strata = strata
		end,
		GetFrameStrata = function(self)
			return self.strata
		end,
		SetFrameLevel = function(self, level)
			self.level = level
		end,
		GetFrameLevel = function(self)
			return self.level or 0
		end,
		SetParent = function(self, parent)
			self.parentFrame = parent
		end,
		GetParent = function(self)
			return self.parentFrame
		end,
		SetScale = function(self, scale)
			self.scale = scale
		end,
		SetMovable = function() end,
		StartMoving = function() end,
		StopMovingOrSizing = function() end,
		SetAttribute = function() end,
		GetAttribute = function()
			return nil
		end,
	}
	return frame
end

_G.UIParent = make_test_frame("UIParent")
_G.UIParent.anchorX = 0
_G.UIParent.anchorY = 0

_G.CreateFrame = function(frameType, name, parentFrame, template)
	if frameType == SimpleBuffs.UI.COOLDOWN then
		return make_test_frame(name)
	end
	local button = make_test_frame(name)
	button.parent = parentFrame
	return button
end

assert(loadfile(root .. "/UI/AuraButton.lua"))()
assert(loadfile(root .. "/UI/DisplayLayout.lua"))()
assert(loadfile(root .. "/UI/Display.lua"))()

local support = require("support")
local runner = support.new_runner()

require("units_spec")(runner, SimpleBuffs)
require("state_spec")(runner, SimpleBuffs)
require("position_state_spec")(runner, SimpleBuffs)
require("scanner_spec")(runner, SimpleBuffs)
require("model_spec")(runner, SimpleBuffs)
require("options_spec")(runner, SimpleBuffs)
require("aura_button_spec")(runner, SimpleBuffs)
require("display_layout_spec")(runner, SimpleBuffs)
require("display_spec")(runner, SimpleBuffs)
require("slash_commands_spec")(runner, SimpleBuffs)
require("blizzard_buff_frame_spec")(runner, SimpleBuffs)
require("bootstrap_spec")(runner, SimpleBuffs)

os.exit(runner:run())
