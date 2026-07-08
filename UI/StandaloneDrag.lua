SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local MODE_STANDALONE = ns.DISPLAY_MODE.STANDALONE

local function shift_is_down()
	return IsShiftKeyDown and IsShiftKeyDown() == true
end

local function find_standalone_drag_frame(frame)
	local current = frame
	while current do
		if current.containerKey then
			return current, current.containerKey
		end
		if current.mode == MODE_STANDALONE then
			local parent = current.GetParent and current:GetParent()
			if parent and parent.containerKey then
				return parent, parent.containerKey
			end
			return current, current.unit
		end
		current = current.GetParent and current:GetParent()
	end
	return nil, nil
end

function ns.CanStartStandaloneDrag()
	return not ns.DB().locked and shift_is_down()
end

function ns.StartStandaloneDrag(frame)
	if not ns.CanStartStandaloneDrag() then
		return
	end

	local movableFrame, positionKey = find_standalone_drag_frame(frame)
	if not movableFrame or not positionKey or not movableFrame.StartMoving then
		return
	end

	movableFrame.isSimpleBuffsMoving = true
	movableFrame.simpleBuffsPositionKey = positionKey
	movableFrame:StartMoving()
end

function ns.StopStandaloneDrag(frame)
	local movableFrame = find_standalone_drag_frame(frame)
	if not movableFrame or not movableFrame.isSimpleBuffsMoving then
		return
	end

	movableFrame.isSimpleBuffsMoving = nil
	movableFrame:StopMovingOrSizing()
	ns.SaveStandalonePosition(movableFrame.simpleBuffsPositionKey, movableFrame)
	movableFrame.simpleBuffsPositionKey = nil
end

-- Buffs and Debuffs are independently movable containers, so the tooltip
-- names which group AND which aura type is being dragged (e.g. "Player
-- Buffs"), not just the group.
local function get_standalone_container_label(baseContainerKey)
	if baseContainerKey == ns.STANDALONE_CONTAINER_KEY.ENEMY then
		return ns.CONTAINER_LABEL.ENEMY
	end
	return ns.UNIT_GROUP_CONTAINER[baseContainerKey] or baseContainerKey
end

local function get_standalone_frame_label(frame)
	if not frame then
		return nil
	end

	if frame.baseContainerKey then
		local groupLabel = get_standalone_container_label(frame.baseContainerKey)
		local auraLabel = ns.AURA_LABEL[frame.auraType]
		if auraLabel then
			return groupLabel .. ns.TEXT.SPACE .. auraLabel
		end
		return groupLabel
	end

	local unit = frame.unit
	if not unit then
		return nil
	end
	if ns.UNIT_LABEL[unit] then
		return ns.UNIT_LABEL[unit]
	end
	local groupKey = ns.GetUnitGroup(unit) or unit
	return ns.UNIT_GROUP_LABEL[groupKey] or unit
end

local function show_move_tooltip(self)
	if ns.DB().locked or not GameTooltip then
		return
	end

	GameTooltip:SetOwner(self, ns.UI.ANCHOR_RIGHT)
	GameTooltip:ClearLines()
	local unitLabel = get_standalone_frame_label(self)
	if unitLabel then
		GameTooltip:AddLine(
			ns.TEXT.STANDALONE_TOOLTIP_UNIT:format(unitLabel),
			ns.OPTIONS_LAYOUT.TOOLTIP_UNIT_COLOR_R,
			ns.OPTIONS_LAYOUT.TOOLTIP_UNIT_COLOR_G,
			ns.OPTIONS_LAYOUT.TOOLTIP_UNIT_COLOR_B
		)
	end
	GameTooltip:AddLine(
		ns.TEXT.STANDALONE_MOVE_TOOLTIP,
		ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_R,
		ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_G,
		ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_B,
		true
	)
	GameTooltip:Show()
end

local function hide_move_tooltip(self)
	if not GameTooltip then
		return
	end
	if GameTooltip.IsOwned and not GameTooltip:IsOwned(self) then
		return
	end
	GameTooltip:Hide()
end

function ns.ApplyStandaloneDrag(frame)
	frame:SetMovable(true)
	frame:RegisterForDrag(ns.UI.LEFT_BUTTON)
	frame:SetScript(ns.UI.ON_ENTER, show_move_tooltip)
	frame:SetScript(ns.UI.ON_LEAVE, hide_move_tooltip)
	frame:SetScript(ns.UI.ON_DRAG_START, function(self)
		ns.StartStandaloneDrag(self)
	end)
	frame:SetScript(ns.UI.ON_DRAG_STOP, function(self)
		ns.StopStandaloneDrag(self)
	end)
end
