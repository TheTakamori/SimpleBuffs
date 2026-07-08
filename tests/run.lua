---@diagnostic disable: undefined-global

local source = debug.getinfo(1, "S").source
local script_path = source:sub(1, 1) == "@" and source:sub(2) or source
if script_path:sub(1, 1) ~= "/" then
	script_path = (os.getenv("PWD") or ".") .. "/" .. script_path
end
local script_dir = script_path:match("^(.*)/[^/]+$") or "."
local root = script_dir:gsub("/tests$", "")

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
assert(loadfile(root .. "/Core/PositionState.lua"))()
assert(loadfile(root .. "/UI/DisplayAnchors.lua"))()
assert(loadfile(root .. "/UI/StandaloneDrag.lua"))()
assert(loadfile(root .. "/Core/Units.lua"))()
assert(loadfile(root .. "/Core/Scanner.lua"))()
assert(loadfile(root .. "/Core/Model.lua"))()
assert(loadfile(root .. "/UI/OptionsRefresh.lua"))()
assert(loadfile(root .. "/UI/OptionsPanelData.lua"))()

local function make_test_frame()
	return {
		scripts = {},
		CreateTexture = function()
			return {
				SetAllPoints = function() end,
				SetTexCoord = function() end,
				SetTexture = function() end,
			}
		end,
		CreateFontString = function()
			return {
				SetPoint = function() end,
				SetText = function() end,
			}
		end,
		SetSize = function() end,
		SetAllPoints = function() end,
		SetReverse = function() end,
		SetHideCountdownNumbers = function() end,
		SetDrawSwipe = function() end,
		SetDrawEdge = function() end,
		RegisterForDrag = function() end,
		SetScript = function(self, event, handler)
			self.scripts[event] = handler
		end,
		SetMouseClickEnabled = function(self, enabled)
			self.mouseClickEnabled = enabled
		end,
		EnableMouse = function(self, enabled)
			self.mouseEnabled = enabled
		end,
	}
end

_G.CreateFrame = function(frameType, _, parentFrame, template)
	if frameType == SimpleBuffs.UI.COOLDOWN then
		return make_test_frame()
	end
	local button = make_test_frame()
	button.parent = parentFrame
	return button
end

assert(loadfile(root .. "/UI/AuraButton.lua"))()
assert(loadfile(root .. "/UI/DisplayLayout.lua"))()

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

os.exit(runner:run())
