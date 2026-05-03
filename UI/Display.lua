SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local MODE_ATTACHED = ns.DISPLAY_MODE.ATTACHED
local MODE_STANDALONE = ns.DISPLAY_MODE.STANDALONE
local DISPLAY_MODES = { MODE_ATTACHED, MODE_STANDALONE }

local function get_display_name(unit, mode)
	local label = (ns.UNIT_LABEL[unit] or unit):gsub(ns.PATTERN.NON_WORD, ns.TEXT.EMPTY)
	return ns.FRAME_NAME.DISPLAY_PREFIX .. label .. mode:gsub(ns.PATTERN.FIRST_LOWERCASE, string.upper) .. ns.FRAME_NAME.DISPLAY_SUFFIX
end

local function unit_exists(unit)
	if UnitExists then
		return UnitExists(unit) == true
	end
	return true
end

local function raise_attached_frame(frame, anchor)
	if not frame or not anchor then
		return
	end

	if frame.SetFrameStrata and anchor.GetFrameStrata then
		local ok, strata = pcall(anchor.GetFrameStrata, anchor)
		if ok and strata then
			frame:SetFrameStrata(strata)
		end
	end

	if frame.SetFrameLevel and anchor.GetFrameLevel then
		local ok, level = pcall(anchor.GetFrameLevel, anchor)
		if ok and level then
			frame:SetFrameLevel(level + ns.DISPLAY_FRAME.ATTACHED_FRAME_LEVEL_OFFSET)
		end
	end
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
		raise_attached_frame(frame, anchor)
		frame:SetPoint(saved.point, anchor, saved.relativePoint, saved.x, saved.y)
		return true
	end

	return true
end

local function create_display(unit, mode)
	local frame = CreateFrame(ns.UI.FRAME, get_display_name(unit, mode), UIParent)
	frame.unit = unit
	frame.mode = mode
	frame:SetSize(ns.DISPLAY_FRAME.WIDTH, ns.DISPLAY_FRAME.HEIGHT)
	frame:SetFrameStrata(mode == MODE_STANDALONE and ns.UI.FRAME_STRATA_MEDIUM or ns.UI.FRAME_STRATA_LOW)

	if mode == MODE_STANDALONE then
		ns.ApplyStandaloneDrag(frame)
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

	local frame = CreateFrame(ns.UI.FRAME, ns.FRAME_NAME.DISPLAY_PREFIX .. containerKey:gsub(ns.PATTERN.FIRST_LOWERCASE, string.upper) .. ns.FRAME_NAME.CONTAINER_SUFFIX, UIParent)
	frame.containerKey = containerKey
	frame.unit = containerKey
	frame:SetSize(ns.DISPLAY_FRAME.CONTAINER_WIDTH, ns.DISPLAY_FRAME.CONTAINER_HEIGHT)
	frame:SetFrameStrata(ns.UI.FRAME_STRATA_MEDIUM)
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
	local displayMode = ns.GetUnitDisplayMode(unit)

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

function ns.RepaintAllDisplays()
	if ns.BeginAttachedAnchorCache then
		ns.BeginAttachedAnchorCache()
	end
	ns.ForEachConfiguredUnit(function(unit)
		ns.UpdateUnitDisplays(unit, false)
	end)
	if ns.EndAttachedAnchorCache then
		ns.EndAttachedAnchorCache()
	end
	ns.LayoutStandaloneContainers()
end

function ns.LayoutStandaloneContainers()
	local runtime = ns.RuntimeEnsure()
	local appearance = ns.GetAppearance()

	for containerKey, container in pairs(runtime.containers) do
		place_container(container)
		container:EnableMouse(not ns.DB().locked)

		local y = ns.LAYOUT_METRIC.ORIGIN_Y
		local maxWidth = ns.DISPLAY_FRAME.INITIAL_MAX_WIDTH
		local totalHeight = ns.LAYOUT_METRIC.ORIGIN_Y
		local visibleCount = ns.NUMBER.ZERO
		ns.ForEachConfiguredUnit(function(unit)
			if get_container_key_for_unit(unit) ~= containerKey then
				return
			end
			local frame = runtime.frames[MODE_STANDALONE] and runtime.frames[MODE_STANDALONE][unit]
			if frame and frame:IsShown() then
				frame:ClearAllPoints()
				frame:SetPoint(ns.UI.ANCHOR_TOPLEFT, container, ns.UI.ANCHOR_TOPLEFT, ns.LAYOUT_METRIC.ORIGIN_X, y)
				local width = frame:GetWidth() or ns.DISPLAY_FRAME.INITIAL_MAX_WIDTH
				local height = frame:GetHeight() or appearance.iconSize
				if width > maxWidth then
					maxWidth = width
				end
				y = y - height - appearance.rowSpacing
				totalHeight = totalHeight + height + appearance.rowSpacing
				visibleCount = visibleCount + ns.NUMBER.ONE
			end
		end)

		container:SetSize(math.max(maxWidth, ns.DISPLAY_FRAME.MIN_WIDTH), math.max(totalHeight, appearance.iconSize))
		container:SetShown(visibleCount > ns.NUMBER.ZERO)
	end
end

function ns.RefreshAllDisplays()
	if ns.BeginAttachedAnchorCache then
		ns.BeginAttachedAnchorCache()
	end
	ns.ForEachConfiguredUnit(function(unit)
		ns.RefreshAndUpdateUnit(unit)
	end)
	if ns.EndAttachedAnchorCache then
		ns.EndAttachedAnchorCache()
	end
	ns.LayoutStandaloneContainers()
end

function ns.EnsureDisplays()
	ns.RuntimeEnsure()
	ns.RefreshAllDisplays()
end
