SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local MODE_ATTACHED = ns.DISPLAY_MODE.ATTACHED
local MODE_STANDALONE = ns.DISPLAY_MODE.STANDALONE
local DISPLAY_MODES = { MODE_ATTACHED, MODE_STANDALONE }

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

local function mode_is_visible(mode)
	local current = ns.GetDisplayMode()
	return current == mode or current == ns.DISPLAY_MODE.BOTH
end

local function place_frame(frame, unit, mode)
	frame:ClearAllPoints()
	if mode == MODE_ATTACHED then
		local anchor, overridePosition = ns.GetAttachedDisplayAnchor(unit)
		if not anchor then
			frame:Hide()
			return false
		end
		local saved = overridePosition or ns.GetAttachedPosition(unit) or ns.GetDefaultAttachedPosition()
		frame:SetParent(anchor)
		frame:SetPoint(saved.point, anchor, saved.relativePoint, saved.x, saved.y)
		return true
	end

	return true
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
		ns.ApplyStandaloneDrag(frame)
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
	ns.ApplyStandaloneDrag(frame)
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
