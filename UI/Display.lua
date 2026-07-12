SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local MODE_ATTACHED = ns.DISPLAY_MODE.ATTACHED
local MODE_STANDALONE = ns.DISPLAY_MODE.STANDALONE
local DISPLAY_MODES = { MODE_ATTACHED, MODE_STANDALONE }

local function get_display_name(unit, mode, auraType)
	local label = (ns.UNIT_LABEL[unit] or unit):gsub(ns.PATTERN.NON_WORD, ns.TEXT.EMPTY)
	local modeLabel = mode:gsub(ns.PATTERN.FIRST_LOWERCASE, string.upper)
	local auraLabel = auraType and auraType:gsub(ns.PATTERN.FIRST_LOWERCASE, string.upper) or ns.TEXT.EMPTY
	return ns.FRAME_NAME.DISPLAY_PREFIX .. label .. modeLabel .. auraLabel .. ns.FRAME_NAME.DISPLAY_SUFFIX
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

local function get_attached_position(unit, overridePosition)
	local attachedPosition = ns.GetUnitAttachedPosition(unit)
	local saved = ns.GetAttachedPosition(unit) or ns.GetDefaultAttachedPosition()
	local x = (overridePosition and overridePosition.x) or saved.x
	local y = (overridePosition and overridePosition.y) or saved.y
	if attachedPosition == ns.ATTACHED_POSITION.ABOVE then
		return ns.UI.ANCHOR_BOTTOMLEFT, ns.UI.ANCHOR_TOPLEFT, x, -y
	elseif attachedPosition == ns.ATTACHED_POSITION.RIGHT then
		return ns.UI.ANCHOR_TOPLEFT, ns.UI.ANCHOR_TOPRIGHT, x, y
	elseif attachedPosition == ns.ATTACHED_POSITION.LEFT then
		return ns.UI.ANCHOR_TOPRIGHT, ns.UI.ANCHOR_TOPLEFT, -x, y
	end
	return ns.UI.ANCHOR_TOPLEFT, ns.UI.ANCHOR_BOTTOMLEFT, x, y
end

local function place_attached_primary(frame, unit)
	local anchor, overridePosition = ns.GetAttachedDisplayAnchor(unit)
	if not anchor then
		frame:Hide()
		return false
	end
	local point, relativePoint, x, y = get_attached_position(unit, overridePosition)
	frame:SetParent(anchor)
	raise_attached_frame(frame, anchor)
	frame:SetPoint(point, anchor, relativePoint, x, y)
	return true
end

local function place_attached_below(frame, previousFrame)
	if not previousFrame then
		return false
	end
	local rowSpacing = ns.GetAppearance().rowSpacing
	frame:SetParent(previousFrame:GetParent())
	frame:ClearAllPoints()
	frame:SetPoint(ns.UI.ANCHOR_TOPLEFT, previousFrame, ns.UI.ANCHOR_BOTTOMLEFT, ns.LAYOUT_METRIC.ORIGIN_X, -rowSpacing)
	return true
end

local function place_frame(frame, unit, mode, previousAttachedFrame)
	frame:ClearAllPoints()
	if mode == MODE_ATTACHED then
		local previousSameUnit = previousAttachedFrame
			and previousAttachedFrame.unit == unit
			and previousAttachedFrame.mode == MODE_ATTACHED
			and previousAttachedFrame:IsShown()
		if previousSameUnit then
			return place_attached_below(frame, previousAttachedFrame)
		end
		return place_attached_primary(frame, unit)
	end

	return true
end

local function create_display(unit, mode, auraType)
	local frame = CreateFrame(ns.UI.FRAME, get_display_name(unit, mode, auraType), UIParent)
	frame.unit = unit
	frame.mode = mode
	frame.auraType = auraType
	frame:SetSize(ns.DISPLAY_FRAME.WIDTH, ns.DISPLAY_FRAME.HEIGHT)
	frame:SetFrameStrata(mode == MODE_STANDALONE and ns.UI.FRAME_STRATA_MEDIUM or ns.UI.FRAME_STRATA_LOW)

	if mode == MODE_STANDALONE then
		ns.ApplyStandaloneDrag(frame)
	end

	return frame
end

-- Buffs and Debuffs each get their own standalone container (independently
-- movable), identified by ns.GetStandaloneContainerInstanceKey. baseKey
-- (ns.GetStandaloneContainerKey) still identifies the underlying group of
-- units the container draws from - that grouping is unchanged, only the
-- Buffs/Debuffs split is new.
local function get_or_create_container(baseKey, auraType)
	local runtime = ns.RuntimeEnsure()
	local containerKey = baseKey .. ns.STANDALONE_CONTAINER_KEY_SEPARATOR .. auraType
	if runtime.containers[containerKey] then
		return runtime.containers[containerKey]
	end

	local label = baseKey:gsub(ns.PATTERN.FIRST_LOWERCASE, string.upper) .. auraType:gsub(ns.PATTERN.FIRST_LOWERCASE, string.upper)
	local frame = CreateFrame(ns.UI.FRAME, ns.FRAME_NAME.DISPLAY_PREFIX .. label .. ns.FRAME_NAME.CONTAINER_SUFFIX, UIParent)
	frame.containerKey = containerKey
	frame.baseContainerKey = baseKey
	frame.auraType = auraType
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

-- Re-anchors a container that's already on screen (via place_container) so
-- the given edge - not the saved drag point - stays fixed as its content
-- grows/shrinks: Bar Anchor Top pins the BOTTOM edge (bars push the top
-- upward), Bar Anchor Bottom pins the TOP edge (bars push the bottom
-- downward). This must be computed from the container's CURRENT on-screen
-- rect rather than reusing the saved drag x/y, because those coordinates
-- were captured under a different anchor point (whatever corner the user
-- last dragged, or the CENTER default) and reusing them verbatim under a
-- different point moves the frame to an unrelated screen position - this
-- was the cause of a prior regression where standalone displays ended up
-- stuck off-screen.
local function pin_container_edge(frame, edge)
	local left = frame:GetLeft()
	local edgeY = edge == ns.UI.ANCHOR_BOTTOM and frame:GetBottom() or frame:GetTop()
	if not left or not edgeY then
		return
	end
	local point = edge == ns.UI.ANCHOR_BOTTOM and ns.UI.ANCHOR_BOTTOMLEFT or ns.UI.ANCHOR_TOPLEFT
	local uiLeft = UIParent:GetLeft() or ns.NUMBER.ZERO
	local uiEdgeY = (edge == ns.UI.ANCHOR_BOTTOM and UIParent:GetBottom() or UIParent:GetTop()) or ns.NUMBER.ZERO
	frame:ClearAllPoints()
	frame:SetPoint(point, UIParent, point, left - uiLeft, edgeY - uiEdgeY)
end

local function ensure_display(unit, mode, auraType)
	local runtime = ns.RuntimeEnsure()
	runtime.frames[mode] = runtime.frames[mode] or {}
	runtime.frames[mode][unit] = runtime.frames[mode][unit] or {}
	if not runtime.frames[mode][unit][auraType] then
		runtime.frames[mode][unit][auraType] = create_display(unit, mode, auraType)
	end
	return runtime.frames[mode][unit][auraType]
end

local function hide_unit_displays(unit)
	local runtime = ns.RuntimeEnsure()
	for _, mode in ipairs(DISPLAY_MODES) do
		local unitFrames = runtime.frames[mode] and runtime.frames[mode][unit]
		if unitFrames then
			for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
				local frame = unitFrames[auraType]
				if frame then
					frame:Hide()
				end
			end
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
		local unitFrames = runtime.frames[mode] and runtime.frames[mode][unit]
		if not visibleMode then
			if unitFrames then
				for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
					local frame = unitFrames[auraType]
					if frame then
						frame:Hide()
					end
				end
			end
		else
			local previousAttachedFrame = nil
			for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
				if not ns.IsUnitAuraEnabled(unit, auraType) then
					-- Re-read the unit's frame table: ensure_display may have
					-- created it for an earlier aura type this same pass.
					local framesForUnit = runtime.frames[mode] and runtime.frames[mode][unit]
					local hiddenFrame = framesForUnit and framesForUnit[auraType]
					if hiddenFrame then
						hiddenFrame:Hide()
					end
				else
					local frame = ensure_display(unit, mode, auraType)
					if mode == MODE_STANDALONE then
						frame:SetParent(get_or_create_container(ns.GetStandaloneContainerKey(ns.GetUnitGroup(unit)), auraType))
					end
					if place_frame(frame, unit, mode, previousAttachedFrame) then
						ns.UpdateAuraDisplayFrame(frame, model)
						frame:Show()
						if mode == MODE_ATTACHED then
							previousAttachedFrame = frame
						end
					else
						frame:Hide()
					end
				end
			end
		end
	end
end

function ns.RefreshAndUpdateUnit(unit)
	ns.UpdateUnitDisplays(unit, true)
end

function ns.RefreshAndUpdateDirtyUnits()
	local runtime = ns.RuntimeEnsure()
	local didUpdate = false
	if ns.BeginAttachedAnchorCache then
		ns.BeginAttachedAnchorCache()
	end
	for index = 1, #runtime.dirtyUnitList do
		local unit = runtime.dirtyUnitList[index]
		if runtime.dirtyUnits[unit] then
			ns.UpdateUnitDisplays(unit, true)
			didUpdate = true
		end
		runtime.dirtyUnitList[index] = nil
	end
	if ns.EndAttachedAnchorCache then
		ns.EndAttachedAnchorCache()
	end
	if didUpdate then
		ns.LayoutStandaloneContainers()
	end
	return didUpdate
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
	local globalAppearance = ns.GetAppearance()

	for _, container in pairs(runtime.containers) do
		if not container.pinnedEdge then
			place_container(container)
		end
		container:EnableMouse(not ns.DB().locked)

		local y = ns.LAYOUT_METRIC.ORIGIN_Y
		local maxWidth = ns.DISPLAY_FRAME.INITIAL_MAX_WIDTH
		local totalHeight = ns.LAYOUT_METRIC.ORIGIN_Y
		local visibleCount = ns.NUMBER.ZERO
		-- A container can only keep one edge fixed on screen as it resizes
		-- (see pin_container_edge). Bar Anchor Top pins the bottom edge
		-- (bars grow upward); Bar Anchor Bottom pins the top edge (bars
		-- grow downward) - only applied when every visible frame in this
		-- container agrees on style and anchor, since mixed content (e.g.
		-- Icon style, which has no Bar Anchor of its own) has no single
		-- edge that makes sense to pin, and falls back to the saved/dragged
		-- point instead.
		local allBarStyle = true
		local commonBarAnchor = nil
		local barAnchorConsistent = true
		local auraType = container.auraType
		ns.ForEachUnitInStandaloneContainer(container.baseContainerKey, function(unit)
			local unitFrames = runtime.frames[MODE_STANDALONE] and runtime.frames[MODE_STANDALONE][unit]
			local frame = unitFrames and unitFrames[auraType]
			if frame and frame:IsShown() then
				local appearance = ns.GetUnitGroupAppearance(ns.GetUnitGroup(unit) or unit, auraType)
				frame:ClearAllPoints()
				frame:SetPoint(ns.UI.ANCHOR_TOPLEFT, container, ns.UI.ANCHOR_TOPLEFT, ns.LAYOUT_METRIC.ORIGIN_X, y)
				local width = frame:GetWidth() or ns.DISPLAY_FRAME.INITIAL_MAX_WIDTH
				local height = frame:GetHeight() or appearance.iconSize
				if width > maxWidth then
					maxWidth = width
				end
				y = y - height - globalAppearance.rowSpacing
				totalHeight = totalHeight + height + globalAppearance.rowSpacing
				visibleCount = visibleCount + ns.NUMBER.ONE
				if appearance.style ~= ns.AURA_STYLE.BAR then
					allBarStyle = false
				elseif commonBarAnchor == nil then
					commonBarAnchor = appearance.barAnchor
				elseif commonBarAnchor ~= appearance.barAnchor then
					barAnchorConsistent = false
				end
			end
		end)

		container:SetSize(math.max(maxWidth, ns.DISPLAY_FRAME.MIN_WIDTH), math.max(totalHeight, ns.DEFAULTS.appearance.iconSize))
		container:SetShown(visibleCount > ns.NUMBER.ZERO)

		local desiredEdge = nil
		if visibleCount > ns.NUMBER.ZERO and allBarStyle and barAnchorConsistent and commonBarAnchor then
			desiredEdge = commonBarAnchor == ns.BAR_ANCHOR.TOP and ns.UI.ANCHOR_BOTTOM or ns.UI.ANCHOR_TOP
		end

		if desiredEdge then
			if container.pinnedEdge ~= desiredEdge then
				pin_container_edge(container, desiredEdge)
				container.pinnedEdge = desiredEdge
				ns.SaveStandalonePosition(container.containerKey, container)
			end
		elseif container.pinnedEdge then
			container.pinnedEdge = nil
			place_container(container)
		end
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
