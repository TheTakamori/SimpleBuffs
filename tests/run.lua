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
_G.Enum = {
	UnitAuraSortRule = {
		Default = "Default",
		Expiration = "Expiration",
		ExpirationOnly = "ExpirationOnly",
		Unsorted = "Unsorted",
	},
	UnitAuraSortDirection = {
		Normal = "Normal",
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
assert(loadfile(root .. "/UI/DisplayLayout.lua"))()

local support = require("support")
local runner = support.new_runner()

require("units_spec")(runner, SimpleBuffs)
require("state_spec")(runner, SimpleBuffs)
require("scanner_spec")(runner, SimpleBuffs)
require("model_spec")(runner, SimpleBuffs)
require("options_spec")(runner, SimpleBuffs)
require("display_layout_spec")(runner, SimpleBuffs)

os.exit(runner:run())
