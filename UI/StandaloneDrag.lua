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

function ns.ApplyStandaloneDrag(frame)
	frame:SetMovable(true)
	frame:RegisterForDrag(ns.UI.LEFT_BUTTON)
	frame:SetScript(ns.UI.ON_DRAG_START, function(self)
		ns.StartStandaloneDrag(self)
	end)
	frame:SetScript(ns.UI.ON_DRAG_STOP, function(self)
		ns.StopStandaloneDrag(self)
	end)
end
