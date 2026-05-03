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
	print_line("Simple Buffs commands:")
	print_line("/sbuff - Open options")
	print_line("/sbuff lock - Lock standalone displays")
	print_line("/sbuff unlock - Unlock Shift-drag for standalone displays")
	print_line("/sbuff reset - Reset settings")
end

function ns.RegisterSlashCommands()
	SLASH_SIMPLEBUFFS1 = ns.SLASH_COMMANDS[1]
	SLASH_SIMPLEBUFFS2 = nil
	SlashCmdList.SIMPLEBUFFS = function(msg)
		local command = (msg or ""):match("^%s*(%S*)")
		command = command and command:lower() or ""

		if command == "" or command == "options" or command == "config" then
			ns.OpenOptionsPanel()
		elseif command == "lock" then
			ns.SetLocked(true)
			refresh()
			print_line(ns.TEXT.LOCKED)
		elseif command == "unlock" then
			ns.SetLocked(false)
			refresh()
			print_line(ns.TEXT.UNLOCKED)
		elseif command == "reset" then
			ns.ResetDB()
			refresh()
			print_line(ns.TEXT.RESET)
		elseif command == "help" then
			show_help()
		else
			show_help()
		end
	end
end
