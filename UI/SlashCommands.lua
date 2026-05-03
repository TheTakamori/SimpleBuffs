SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local function refresh()
	if ns.RefreshAllDisplays then
		ns.RefreshAllDisplays()
	end
	if ns.RefreshOptionsPanel then
		ns.RefreshOptionsPanel()
	end
end

local function show_help()
	ns.PrintMessage(ns.TEXT.SLASH_HELP_TITLE)
	ns.PrintMessage(ns.TEXT.SLASH_HELP_OPEN)
	ns.PrintMessage(ns.TEXT.SLASH_HELP_LOCK)
	ns.PrintMessage(ns.TEXT.SLASH_HELP_UNLOCK)
	ns.PrintMessage(ns.TEXT.SLASH_HELP_RESET)
end

function ns.RegisterSlashCommands()
	SLASH_SIMPLEBUFFS1 = ns.SLASH_COMMANDS[1]
	SLASH_SIMPLEBUFFS2 = nil
	SlashCmdList.SIMPLEBUFFS = function(msg)
		local command = (msg or ""):match("^%s*(%S*)")
		command = command and command:lower() or ""

		if command == ns.TEXT.EMPTY or command == ns.SLASH_COMMAND.OPTIONS or command == ns.SLASH_COMMAND.CONFIG then
			ns.OpenOptionsPanel()
		elseif command == ns.SLASH_COMMAND.LOCK then
			ns.SetLocked(true)
			refresh()
			ns.PrintMessage(ns.TEXT.LOCKED)
		elseif command == ns.SLASH_COMMAND.UNLOCK then
			ns.SetLocked(false)
			refresh()
			ns.PrintMessage(ns.TEXT.UNLOCKED)
		elseif command == ns.SLASH_COMMAND.RESET then
			ns.ResetDB()
			refresh()
			ns.PrintMessage(ns.TEXT.RESET)
		elseif command == ns.SLASH_COMMAND.HELP then
			show_help()
		else
			show_help()
		end
	end
end
