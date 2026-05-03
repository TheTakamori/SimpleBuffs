SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local function print_line(message)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(message)
	else
		print(message)
	end
end

local function refresh()
	if ns.RefreshAllDisplays then
		ns.RefreshAllDisplays()
	end
	if ns.EnsureOptionsPanel then
		ns.EnsureOptionsPanel()
	end
end

local function show_help()
	print_line(ns.TEXT.SLASH_HELP_TITLE)
	print_line(ns.TEXT.SLASH_HELP_OPEN)
	print_line(ns.TEXT.SLASH_HELP_LOCK)
	print_line(ns.TEXT.SLASH_HELP_UNLOCK)
	print_line(ns.TEXT.SLASH_HELP_RESET)
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
			print_line(ns.TEXT.LOCKED)
		elseif command == ns.SLASH_COMMAND.UNLOCK then
			ns.SetLocked(false)
			refresh()
			print_line(ns.TEXT.UNLOCKED)
		elseif command == ns.SLASH_COMMAND.RESET then
			ns.ResetDB()
			refresh()
			print_line(ns.TEXT.RESET)
		elseif command == ns.SLASH_COMMAND.HELP then
			show_help()
		else
			show_help()
		end
	end
end
