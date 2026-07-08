---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

return function(runner, ns)
	-- Registers the handler with stubbed collaborators, runs the command,
	-- restores everything, and returns what the handler did.
	local function run_command(msg)
		_G.SlashCmdList = {}

		local calls = {
			openOptions = 0,
			refreshDisplays = 0,
			refreshPanel = 0,
			messages = {},
		}
		local originalOpen = ns.OpenOptionsPanel
		local originalRefreshDisplays = ns.RefreshAllDisplays
		local originalRefreshPanel = ns.RefreshOptionsPanel
		local originalPrint = ns.PrintMessage
		ns.OpenOptionsPanel = function()
			calls.openOptions = calls.openOptions + 1
		end
		ns.RefreshAllDisplays = function()
			calls.refreshDisplays = calls.refreshDisplays + 1
		end
		ns.RefreshOptionsPanel = function()
			calls.refreshPanel = calls.refreshPanel + 1
		end
		ns.PrintMessage = function(message)
			calls.messages[#calls.messages + 1] = message
		end

		ns.RegisterSlashCommands()
		local ok, err = pcall(SlashCmdList.SIMPLEBUFFS, msg)

		ns.OpenOptionsPanel = originalOpen
		ns.RefreshAllDisplays = originalRefreshDisplays
		ns.RefreshOptionsPanel = originalRefreshPanel
		ns.PrintMessage = originalPrint
		if not ok then
			error(err, 2)
		end
		return calls
	end

	runner:test("RegisterSlashCommands wires the /sbuff global", function()
		_G.SlashCmdList = {}
		ns.RegisterSlashCommands()
		assert.equal(SLASH_SIMPLEBUFFS1, ns.SLASH_COMMANDS[1])
		assert.equal(type(SlashCmdList.SIMPLEBUFFS), "function")
	end)

	runner:test("empty, options, and config open the options panel", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		assert.equal(run_command("").openOptions, 1)
		assert.equal(run_command("  ").openOptions, 1)
		assert.equal(run_command("options").openOptions, 1)
		assert.equal(run_command("CONFIG").openOptions, 1)
	end)

	runner:test("lock and unlock set locked state, refresh, and print", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		local calls = run_command("lock")
		assert.equal(ns.DB().locked, true)
		assert.equal(calls.refreshDisplays, 1)
		assert.equal(calls.refreshPanel, 1)
		assert.same(calls.messages, { ns.TEXT.LOCKED })

		calls = run_command("unlock")
		assert.equal(ns.DB().locked, false)
		assert.same(calls.messages, { ns.TEXT.UNLOCKED })
	end)

	runner:test("reset restores defaults, refreshes, and prints", function()
		_G.SlashCmdList = {}
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		ns.SetLocked(true)
		local calls = run_command("reset")
		assert.equal(ns.DB().locked, false)
		assert.equal(calls.refreshDisplays, 1)
		assert.same(calls.messages, { ns.TEXT.RESET })
	end)

	runner:test("help and unknown commands print the help text", function()
		for _, msg in ipairs({ "help", "bogus" }) do
			local calls = run_command(msg)
			assert.equal(calls.openOptions, 0)
			assert.same(calls.messages, {
				ns.TEXT.SLASH_HELP_TITLE,
				ns.TEXT.SLASH_HELP_OPEN,
				ns.TEXT.SLASH_HELP_LOCK,
				ns.TEXT.SLASH_HELP_UNLOCK,
				ns.TEXT.SLASH_HELP_RESET,
			})
		end
	end)
end
