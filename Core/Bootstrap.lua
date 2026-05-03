SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UNIT_PET")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("RAID_ROSTER_UPDATE")
frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
frame:RegisterEvent("ARENA_OPPONENT_UPDATE")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

local function print_loaded()
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(ns.TEXT.LOADED)
	else
		print(ns.TEXT.LOADED)
	end
end

local function refresh_unit(unit, skipLayout)
	if ns.RefreshAndUpdateUnit then
		ns.RefreshAndUpdateUnit(unit)
	end
	if not skipLayout and ns.LayoutStandaloneContainers then
		ns.LayoutStandaloneContainers()
	end
end

local function refresh_group(groupKey)
	ns.ForEachConfiguredUnit(function(unit)
		if ns.GetUnitGroup(unit) == groupKey then
			refresh_unit(unit, true)
		end
	end)
	if ns.LayoutStandaloneContainers then
		ns.LayoutStandaloneContainers()
	end
end

local function refresh_groups(...)
	local groups = { ... }
	for index = 1, #groups do
		local groupKey = groups[index]
		ns.ForEachConfiguredUnit(function(unit)
			if ns.GetUnitGroup(unit) == groupKey then
				refresh_unit(unit, true)
			end
		end)
	end
	if ns.LayoutStandaloneContainers then
		ns.LayoutStandaloneContainers()
	end
end

frame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 ~= ns.ADDON_NAME then
			return
		end
		ns.InitDB()
		ns.RuntimeEnsure()
		if ns.EnsureOptionsPanel then
			ns.EnsureOptionsPanel()
		end
		if ns.RegisterSlashCommands then
			ns.RegisterSlashCommands()
		end
		if ns.EnsureMinimapButton then
			ns.EnsureMinimapButton()
		end
		print_loaded()
	elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		if ns.EnsureMinimapButton then
			ns.EnsureMinimapButton()
		end
		if ns.EnsureDisplays then
			ns.EnsureDisplays()
		end
	elseif event == "PLAYER_FOCUS_CHANGED" then
		refresh_unit("focus")
	elseif event == "PLAYER_TARGET_CHANGED" then
		refresh_unit("target")
	elseif event == "UNIT_PET" then
		if arg1 == "player" then
			refresh_unit("pet")
		else
			refresh_groups(ns.UNIT_GROUP.PARTY_PETS, ns.UNIT_GROUP.RAID_PETS)
		end
	elseif event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE" then
		refresh_groups(ns.UNIT_GROUP.PARTY, ns.UNIT_GROUP.PARTY_PETS, ns.UNIT_GROUP.RAID, ns.UNIT_GROUP.RAID_PETS)
	elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
		refresh_group(ns.UNIT_GROUP.BOSS)
	elseif event == "ARENA_OPPONENT_UPDATE" then
		refresh_groups(ns.UNIT_GROUP.ARENA, ns.UNIT_GROUP.ARENA_PETS)
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		ns.MarkNameplateActive(arg1, true)
		refresh_unit(arg1)
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		ns.MarkNameplateActive(arg1, false)
		if ns.UpdateUnitDisplays then
			ns.UpdateUnitDisplays(arg1)
		end
		if ns.LayoutStandaloneContainers then
			ns.LayoutStandaloneContainers()
		end
	elseif event == "UNIT_AURA" then
		if ns.IsTrackedUnit(arg1) then
			refresh_unit(arg1)
		end
	end
end)
