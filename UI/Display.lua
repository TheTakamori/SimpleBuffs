SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local MODE_ATTACHED = ns.DISPLAY_MODE.ATTACHED
local MODE_STANDALONE = ns.DISPLAY_MODE.STANDALONE
local DISPLAY_MODES = { MODE_ATTACHED, MODE_STANDALONE }
local DEFAULT_ATTACHED_POSITION = {
	point = "TOPLEFT",
	relativePoint = "BOTTOMLEFT",
	x = 0,
	y = -6,
}
local PARTY_CONTAINER_ATTACHED_POSITION = {
	point = "TOPLEFT",
	relativePoint = "TOPRIGHT",
	x = 8,
	y = 0,
}

local function get_display_name(unit, mode)
	local label = (ns.UNIT_LABEL[unit] or unit):gsub("%W", "")
	return "SimpleBuffs" .. label .. mode:gsub("^%l", string.upper) .. "Display"
end

local function unit_exists(unit)
	if UnitExists then
		return UnitExists(unit) == true
	end
	return true
end

local function get_frame_unit(frame)
	if not frame then
		return nil
	end
	if frame.GetAttribute then
		local ok, unit = pcall(frame.GetAttribute, frame, "unit")
		if ok and unit then
			return unit
		end
	end
	return frame.unit or frame.displayedUnit or frame.unitToken
end

local function frame_matches_unit(frame, unit)
	return get_frame_unit(frame) == unit
end

local function frame_is_visible(frame)
	if not frame then
		return false
	end
	if frame.IsVisible then
		local ok, visible = pcall(frame.IsVisible, frame)
		if ok then
			return visible == true
		end
	end
	if frame.IsShown then
		local ok, shown = pcall(frame.IsShown, frame)
		if ok then
			return shown == true
		end
	end
	return true
end

local function frame_can_anchor(frame)
	return frame and frame.GetObjectType and frame.SetPoint and frame.ClearAllPoints
end

local function find_member_frame(container, unit)
	if not container then
		return nil
	end

	local fallback = nil
	local memberFrames = container.memberUnitFrames or container.MemberFrames
	if type(memberFrames) == "table" then
		for _, memberFrame in pairs(memberFrames) do
			if frame_matches_unit(memberFrame, unit) then
				if frame_is_visible(memberFrame) then
					return memberFrame
				end
				fallback = fallback or memberFrame
			end
		end
	end

	if container.GetChildren then
		local children = { container:GetChildren() }
		for index = 1, #children do
			local child = children[index]
			if frame_matches_unit(child, unit) then
				if frame_is_visible(child) then
					return child
				end
				fallback = fallback or child
			end
		end
	end

	return fallback
end

local function find_global_unit_frame(unit)
	local fallback = nil
	for _, value in pairs(_G) do
		if frame_can_anchor(value) and frame_matches_unit(value, unit) then
			if frame_is_visible(value) then
				return value
			end
			fallback = fallback or value
		end
	end
	return fallback
end

local function get_party_anchor(unit, partyIndex)
	local partyFrame = _G["PartyFrame"]
	local compactPartyFrame = _G["CompactPartyFrame"]
	local directAnchors = {
		_G["CompactPartyFrameMember" .. partyIndex],
		_G["PartyMemberFrame" .. partyIndex],
		_G["PartyFrameMember" .. partyIndex],
		partyFrame and partyFrame["MemberFrame" .. partyIndex],
	}
	for index = 1, #directAnchors do
		local directAnchor = directAnchors[index]
		if directAnchor and frame_is_visible(directAnchor) then
			local frameUnit = get_frame_unit(directAnchor)
			if not frameUnit or frameUnit == unit then
				return directAnchor, nil
			end
		end
	end

	local memberAnchor = find_member_frame(compactPartyFrame, unit)
		or find_member_frame(partyFrame, unit)
		or find_global_unit_frame(unit)
	if memberAnchor then
		return memberAnchor, nil
	end

	local containerAnchor = compactPartyFrame or partyFrame
	if containerAnchor and frame_is_visible(containerAnchor) then
		local position = {
			point = PARTY_CONTAINER_ATTACHED_POSITION.point,
			relativePoint = PARTY_CONTAINER_ATTACHED_POSITION.relativePoint,
			x = PARTY_CONTAINER_ATTACHED_POSITION.x,
			y = PARTY_CONTAINER_ATTACHED_POSITION.y - ((tonumber(partyIndex) or 1) - 1) * 44,
		}
		return containerAnchor, position
	end

	return nil, nil
end

local function get_blizzard_anchor(unit)
	if unit == "player" then
		return _G["PlayerFrame"]
	elseif unit == "target" then
		return _G["TargetFrame"]
	elseif unit == "focus" then
		return _G["FocusFrame"]
	elseif unit == "pet" then
		return _G["PetFrame"]
	end

	local partyIndex = unit:match("^party(%d+)$")
	if partyIndex then
		return get_party_anchor(unit, partyIndex)
	end

	return nil
end

local function mode_is_visible(mode)
	local current = ns.GetDisplayMode()
	return current == mode or current == ns.DISPLAY_MODE.BOTH
end

local function place_frame(frame, unit, mode)
	frame:ClearAllPoints()
	if mode == MODE_ATTACHED then
		local anchor, overridePosition = get_blizzard_anchor(unit)
		if not anchor then
			frame:Hide()
			return false
		end
		local saved = overridePosition or ns.GetAttachedPosition(unit) or DEFAULT_ATTACHED_POSITION
		frame:SetParent(anchor)
		frame:SetPoint(saved.point, anchor, saved.relativePoint, saved.x, saved.y)
		return true
	end

	return true
end

local function apply_standalone_drag(frame, unit)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		if not ns.DB().locked then
			self:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		ns.SaveStandalonePosition(unit, self)
	end)
end

local function create_display(unit, mode)
	local frame = CreateFrame("Frame", get_display_name(unit, mode), UIParent)
	frame.unit = unit
	frame.mode = mode
	frame:SetSize(180, 64)
	frame:SetFrameStrata(mode == MODE_STANDALONE and "MEDIUM" or "LOW")

	frame.background = frame:CreateTexture(nil, "BACKGROUND")
	frame.background:SetAllPoints()
	if mode == MODE_STANDALONE then
		frame.background:SetColorTexture(0, 0, 0, 0.25)
		apply_standalone_drag(frame, unit)
	else
		frame.background:SetColorTexture(0, 0, 0, 0)
	end

	return frame
end

local function get_container_key_for_unit(unit)
	return ns.GetStandaloneContainerKey(ns.GetUnitGroup(unit))
end

local function get_or_create_container(containerKey)
	local runtime = ns.RuntimeEnsure()
	if runtime.containers[containerKey] then
		return runtime.containers[containerKey]
	end

	local frame = CreateFrame("Frame", "SimpleBuffs" .. containerKey:gsub("^%l", string.upper) .. "Container", UIParent)
	frame.containerKey = containerKey
	frame.unit = containerKey
	frame:SetSize(220, 64)
	frame:SetFrameStrata("MEDIUM")
	frame.background = frame:CreateTexture(nil, "BACKGROUND")
	frame.background:SetAllPoints()
	frame.background:SetColorTexture(0, 0, 0, 0.18)
	apply_standalone_drag(frame, containerKey)
	runtime.containers[containerKey] = frame
	return frame
end

local function place_container(frame)
	frame:ClearAllPoints()
	local saved = ns.DB().standalone[frame.containerKey] or ns.STANDALONE_DEFAULTS[frame.containerKey]
	frame:SetParent(UIParent)
	frame:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y)
end

local function ensure_display(unit, mode)
	local runtime = ns.RuntimeEnsure()
	runtime.frames[mode] = runtime.frames[mode] or {}
	if not runtime.frames[mode][unit] then
		runtime.frames[mode][unit] = create_display(unit, mode)
	end
	return runtime.frames[mode][unit]
end

local function hide_unit_displays(unit)
	local runtime = ns.RuntimeEnsure()
	for _, mode in ipairs(DISPLAY_MODES) do
		local frame = runtime.frames[mode] and runtime.frames[mode][unit]
		if frame then
			frame:Hide()
		end
	end
	runtime.models[unit] = nil
end

function ns.UpdateUnitDisplays(unit, forceRefresh)
	if not ns.IsTrackedUnit(unit) then
		return
	end

	local options = ns.GetUnitOptions(unit)
	local shouldShow = options and (options.buff or options.debuff) and unit_exists(unit)
	if not shouldShow then
		hide_unit_displays(unit)
		return
	end

	local model = forceRefresh and ns.RefreshUnitModel(unit) or ns.GetUnitModel(unit)
	local runtime = ns.RuntimeEnsure()
	local displayMode = ns.GetDisplayMode()

	for _, mode in ipairs(DISPLAY_MODES) do
		local visibleMode = displayMode == mode or displayMode == ns.DISPLAY_MODE.BOTH
		local existingFrame = runtime.frames[mode] and runtime.frames[mode][unit]
		if not visibleMode then
			if existingFrame then
				existingFrame:Hide()
			end
		else
			local frame = existingFrame or ensure_display(unit, mode)
			if mode == MODE_STANDALONE then
				frame:SetParent(get_or_create_container(get_container_key_for_unit(unit)))
			end
			if place_frame(frame, unit, mode) then
				ns.UpdateAuraDisplayFrame(frame, model)
				frame:Show()
			else
				frame:Hide()
			end
		end
	end
end

function ns.RefreshAndUpdateUnit(unit)
	ns.UpdateUnitDisplays(unit, true)
end

function ns.LayoutStandaloneContainers()
	local runtime = ns.RuntimeEnsure()
	local appearance = ns.GetAppearance()

	for containerKey, container in pairs(runtime.containers) do
		place_container(container)
		container:EnableMouse(not ns.DB().locked)

		local y = 0
		local maxWidth = 1
		local totalHeight = 0
		local visibleCount = 0
		ns.ForEachConfiguredUnit(function(unit)
			if get_container_key_for_unit(unit) ~= containerKey then
				return
			end
			local frame = runtime.frames[MODE_STANDALONE] and runtime.frames[MODE_STANDALONE][unit]
			if frame and frame:IsShown() then
				frame:ClearAllPoints()
				frame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, y)
				local width = frame:GetWidth() or 1
				local height = frame:GetHeight() or appearance.iconSize
				if width > maxWidth then
					maxWidth = width
				end
				y = y - height - appearance.rowSpacing
				totalHeight = totalHeight + height + appearance.rowSpacing
				visibleCount = visibleCount + 1
			end
		end)

		container:SetSize(math.max(maxWidth, 64), math.max(totalHeight, appearance.iconSize))
		container:SetShown(visibleCount > 0)
	end
end

function ns.RefreshAllDisplays()
	ns.ForEachConfiguredUnit(function(unit)
		ns.RefreshAndUpdateUnit(unit)
	end)
	ns.LayoutStandaloneContainers()
end

function ns.EnsureDisplays()
	ns.RuntimeEnsure()
	ns.RefreshAllDisplays()
end
