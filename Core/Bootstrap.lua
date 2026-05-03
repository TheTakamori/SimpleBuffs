SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local frame = CreateFrame(ns.UI.FRAME)
frame:RegisterEvent(ns.EVENT.ADDON_LOADED)
frame:RegisterEvent(ns.EVENT.PLAYER_LOGIN)
frame:RegisterEvent(ns.EVENT.PLAYER_ENTERING_WORLD)
frame:RegisterEvent(ns.EVENT.PLAYER_FOCUS_CHANGED)
frame:RegisterEvent(ns.EVENT.PLAYER_TARGET_CHANGED)
frame:RegisterEvent(ns.EVENT.UNIT_AURA)
frame:RegisterEvent(ns.EVENT.UNIT_PET)
frame:RegisterEvent(ns.EVENT.GROUP_ROSTER_UPDATE)
frame:RegisterEvent(ns.EVENT.RAID_ROSTER_UPDATE)
frame:RegisterEvent(ns.EVENT.INSTANCE_ENCOUNTER_ENGAGE_UNIT)
frame:RegisterEvent(ns.EVENT.ARENA_OPPONENT_UPDATE)

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
	ns.ForEachUnitInGroup(groupKey, function(unit)
		refresh_unit(unit, true)
	end)
	if ns.LayoutStandaloneContainers then
		ns.LayoutStandaloneContainers()
	end
end

local function refresh_groups(...)
	local groups = { ... }
	for index = 1, #groups do
		local groupKey = groups[index]
		ns.ForEachUnitInGroup(groupKey, function(unit)
			refresh_unit(unit, true)
		end)
	end
	if ns.LayoutStandaloneContainers then
		ns.LayoutStandaloneContainers()
	end
end

frame:SetScript(ns.UI.ON_EVENT, function(_, event, arg1)
	if event == ns.EVENT.ADDON_LOADED then
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
	elseif event == ns.EVENT.PLAYER_LOGIN or event == ns.EVENT.PLAYER_ENTERING_WORLD then
		if ns.EnsureMinimapButton then
			ns.EnsureMinimapButton()
		end
		if ns.EnsureDisplays then
			ns.EnsureDisplays()
		end
	elseif event == ns.EVENT.PLAYER_FOCUS_CHANGED then
		refresh_unit(ns.UNIT_TOKEN.FOCUS)
	elseif event == ns.EVENT.PLAYER_TARGET_CHANGED then
		refresh_unit(ns.UNIT_TOKEN.TARGET)
	elseif event == ns.EVENT.UNIT_PET then
		if arg1 == ns.UNIT_TOKEN.PLAYER then
			refresh_unit(ns.UNIT_TOKEN.PET)
		else
			refresh_groups(ns.UNIT_GROUP.PARTY_PETS, ns.UNIT_GROUP.RAID_PETS)
		end
	elseif event == ns.EVENT.GROUP_ROSTER_UPDATE or event == ns.EVENT.RAID_ROSTER_UPDATE then
		refresh_groups(ns.UNIT_GROUP.PARTY, ns.UNIT_GROUP.PARTY_PETS, ns.UNIT_GROUP.RAID, ns.UNIT_GROUP.RAID_PETS)
	elseif event == ns.EVENT.INSTANCE_ENCOUNTER_ENGAGE_UNIT then
		refresh_group(ns.UNIT_GROUP.BOSS)
	elseif event == ns.EVENT.ARENA_OPPONENT_UPDATE then
		refresh_groups(ns.UNIT_GROUP.ARENA, ns.UNIT_GROUP.ARENA_PETS)
	elseif event == ns.EVENT.UNIT_AURA then
		if ns.IsTrackedUnit(arg1) then
			refresh_unit(arg1)
		end
	end
end)
