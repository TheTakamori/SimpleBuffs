SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local minimapShapes = {
	[ns.MINIMAP_SHAPE.ROUND] = { true, true, true, true },
	[ns.MINIMAP_SHAPE.SQUARE] = { false, false, false, false },
	[ns.MINIMAP_SHAPE.CORNER_TOPLEFT] = { false, false, false, true },
	[ns.MINIMAP_SHAPE.CORNER_TOPRIGHT] = { false, false, true, false },
	[ns.MINIMAP_SHAPE.CORNER_BOTTOMLEFT] = { false, true, false, false },
	[ns.MINIMAP_SHAPE.CORNER_BOTTOMRIGHT] = { true, false, false, false },
	[ns.MINIMAP_SHAPE.SIDE_LEFT] = { false, true, false, true },
	[ns.MINIMAP_SHAPE.SIDE_RIGHT] = { true, false, true, false },
	[ns.MINIMAP_SHAPE.SIDE_TOP] = { false, false, true, true },
	[ns.MINIMAP_SHAPE.SIDE_BOTTOM] = { true, true, false, false },
	[ns.MINIMAP_SHAPE.TRICORNER_TOPLEFT] = { false, true, true, true },
	[ns.MINIMAP_SHAPE.TRICORNER_TOPRIGHT] = { true, false, true, true },
	[ns.MINIMAP_SHAPE.TRICORNER_BOTTOMLEFT] = { true, true, false, true },
	[ns.MINIMAP_SHAPE.TRICORNER_BOTTOMRIGHT] = { true, true, true, false },
}

local function normalize_angle(angle)
	angle = tonumber(angle) or ns.DEFAULTS.minimap.angle
	angle = math.fmod(angle, ns.MINIMAP_MATH.FULL_CIRCLE_DEGREES)
	if angle < ns.NUMBER.ZERO then
		angle = angle + ns.MINIMAP_MATH.FULL_CIRCLE_DEGREES
	end
	return angle
end

local function atan2(y, x)
	if math.atan2 then
		return math.atan2(y, x)
	end
	if x > ns.NUMBER.ZERO then
		return math.atan(y / x)
	elseif x < ns.NUMBER.ZERO and y >= ns.NUMBER.ZERO then
		return math.atan(y / x) + math.pi
	elseif x < ns.NUMBER.ZERO and y < ns.NUMBER.ZERO then
		return math.atan(y / x) - math.pi
	elseif x == ns.NUMBER.ZERO and y > ns.NUMBER.ZERO then
		return math.pi / ns.MINIMAP_MATH.HALF_DIVISOR
	elseif x == ns.NUMBER.ZERO and y < ns.NUMBER.ZERO then
		return -math.pi / ns.MINIMAP_MATH.HALF_DIVISOR
	end
	return ns.NUMBER.ZERO
end

local function set_button_angle(button, angle)
	if not button or not Minimap then
		return
	end

	angle = normalize_angle(angle)
	local radians = math.rad(angle)
	local x = math.cos(radians)
	local y = math.sin(radians)
	local quadrant = ns.MINIMAP_MATH.QUADRANT_START
	if x < ns.NUMBER.ZERO then
		quadrant = quadrant + ns.MINIMAP_MATH.QUADRANT_LEFT_OFFSET
	end
	if y > ns.NUMBER.ZERO then
		quadrant = quadrant + ns.MINIMAP_MATH.QUADRANT_TOP_OFFSET
	end

	local radiusOffset = ns.LIMITS.MINIMAP_RADIUS_OFFSET
	local widthRadius = (Minimap:GetWidth() / ns.MINIMAP_MATH.HALF_DIVISOR) + radiusOffset
	local heightRadius = (Minimap:GetHeight() / ns.MINIMAP_MATH.HALF_DIVISOR) + radiusOffset
	local shape = GetMinimapShape and GetMinimapShape() or ns.MINIMAP_SHAPE.ROUND
	local quadrants = minimapShapes[shape] or minimapShapes[ns.MINIMAP_SHAPE.ROUND]
	if quadrants[quadrant] then
		x = x * widthRadius
		y = y * heightRadius
	else
		local diagonalWidth = math.sqrt(ns.MINIMAP_MATH.DIAGONAL_FACTOR * (widthRadius ^ ns.MINIMAP_MATH.DIAGONAL_POWER)) - ns.MINIMAP_MATH.DIAGONAL_PADDING
		local diagonalHeight = math.sqrt(ns.MINIMAP_MATH.DIAGONAL_FACTOR * (heightRadius ^ ns.MINIMAP_MATH.DIAGONAL_POWER)) - ns.MINIMAP_MATH.DIAGONAL_PADDING
		x = math.max(-widthRadius, math.min(x * diagonalWidth, widthRadius))
		y = math.max(-heightRadius, math.min(y * diagonalHeight, heightRadius))
	end

	button:ClearAllPoints()
	button:SetPoint(ns.UI.ANCHOR_CENTER, Minimap, ns.UI.ANCHOR_CENTER, x, y)
	button.currentAngle = angle
end

local function update_drag_position(button)
	if not button or not Minimap then
		return
	end

	local scale = Minimap:GetEffectiveScale()
	local cursorX, cursorY = GetCursorPosition()
	if button.dragStartX and button.dragStartY then
		local deltaX = cursorX - button.dragStartX
		local deltaY = cursorY - button.dragStartY
		if (deltaX * deltaX) + (deltaY * deltaY) > ns.MINIMAP_MATH.DRAG_CLICK_THRESHOLD_SQUARED then
			button.dragMoved = true
		end
	end
	local centerX, centerY = Minimap:GetCenter()
	centerX = (centerX or ns.NUMBER.ZERO) * scale
	centerY = (centerY or ns.NUMBER.ZERO) * scale
	set_button_angle(button, math.deg(atan2(cursorY - centerY, cursorX - centerX)))
end

local function show_tooltip(button)
	if not GameTooltip then
		return
	end
	GameTooltip:SetOwner(button, ns.UI.ANCHOR_LEFT)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(ns.TEXT.OPTIONS_TITLE, ns.MINIMAP_MATH.TOOLTIP_TITLE_R, ns.MINIMAP_MATH.TOOLTIP_TITLE_G, ns.MINIMAP_MATH.TOOLTIP_TITLE_B)
	GameTooltip:AddLine(ns.TEXT.MINIMAP_TOOLTIP_STATE:format(ns.DB().locked and ns.TEXT.LOCK_STATE_LOCKED or ns.TEXT.LOCK_STATE_UNLOCKED), ns.MINIMAP_MATH.TOOLTIP_STATE_R, ns.MINIMAP_MATH.TOOLTIP_STATE_G, ns.MINIMAP_MATH.TOOLTIP_STATE_B, true)
	GameTooltip:AddLine(ns.TEXT.MINIMAP_TOOLTIP_OPEN, ns.MINIMAP_MATH.TOOLTIP_ACTION_R, ns.MINIMAP_MATH.TOOLTIP_ACTION_G, ns.MINIMAP_MATH.TOOLTIP_ACTION_B, true)
	GameTooltip:AddLine(ns.TEXT.MINIMAP_TOOLTIP_LOCK, ns.MINIMAP_MATH.TOOLTIP_ACTION_R, ns.MINIMAP_MATH.TOOLTIP_ACTION_G, ns.MINIMAP_MATH.TOOLTIP_ACTION_B, true)
	GameTooltip:AddLine(ns.TEXT.MINIMAP_TOOLTIP_DRAG, ns.MINIMAP_MATH.TOOLTIP_DRAG_R, ns.MINIMAP_MATH.TOOLTIP_DRAG_G, ns.MINIMAP_MATH.TOOLTIP_DRAG_B, true)
	GameTooltip:Show()
end

local function print_lock_state(locked)
	local message = locked and ns.TEXT.LOCKED or ns.TEXT.UNLOCKED
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(message)
	else
		print(message)
	end
end

function ns.EnsureMinimapButton()
	if ns.MinimapButton then
		set_button_angle(ns.MinimapButton, ns.GetMinimapButtonAngle())
		ns.MinimapButton:SetShown(not ns.IsMinimapButtonHidden())
		return ns.MinimapButton
	end
	if not Minimap then
		return nil
	end

	local button = CreateFrame(ns.UI.BUTTON, ns.FRAME_NAME.MINIMAP_BUTTON, Minimap)
	button:SetFrameStrata(ns.UI.FRAME_STRATA_MEDIUM)
	button:SetFrameLevel((Minimap:GetFrameLevel() or ns.NUMBER.ZERO) + ns.MINIMAP_MATH.FRAME_LEVEL_OFFSET)
	button:SetSize(ns.LIMITS.MINIMAP_BUTTON_SIZE, ns.LIMITS.MINIMAP_BUTTON_SIZE)
	button:RegisterForClicks(ns.UI.ANY_UP)
	button:RegisterForDrag(ns.UI.LEFT_BUTTON)
	button:SetHighlightTexture(ns.TEXTURE.MINIMAP_HIGHLIGHT, ns.UI.ADD)

	local background = button:CreateTexture(nil, ns.UI.BACKGROUND)
	background:SetTexture(ns.TEXTURE.MINIMAP_BACKGROUND)
	background:SetSize(ns.LIMITS.MINIMAP_BUTTON_BACKGROUND_SIZE, ns.LIMITS.MINIMAP_BUTTON_BACKGROUND_SIZE)
	background:SetPoint(ns.UI.ANCHOR_CENTER, button, ns.UI.ANCHOR_CENTER)

	local icon = button:CreateTexture(nil, ns.UI.ARTWORK)
	icon:SetTexture(ns.TEXTURE.MINIMAP_ICON)
	icon:SetSize(ns.LIMITS.MINIMAP_BUTTON_ICON_SIZE, ns.LIMITS.MINIMAP_BUTTON_ICON_SIZE)
	icon:SetPoint(ns.UI.ANCHOR_TOPLEFT, button, ns.UI.ANCHOR_TOPLEFT, ns.LIMITS.MINIMAP_ICON_OFFSET_X, ns.LIMITS.MINIMAP_ICON_OFFSET_Y)
	icon:SetTexCoord(ns.MINIMAP_MATH.TEX_COORD_LEFT, ns.MINIMAP_MATH.TEX_COORD_RIGHT, ns.MINIMAP_MATH.TEX_COORD_TOP, ns.MINIMAP_MATH.TEX_COORD_BOTTOM)

	local border = button:CreateTexture(nil, ns.UI.OVERLAY)
	border:SetTexture(ns.TEXTURE.MINIMAP_BORDER)
	border:SetSize(ns.LIMITS.MINIMAP_BUTTON_OVERLAY_SIZE, ns.LIMITS.MINIMAP_BUTTON_OVERLAY_SIZE)
	border:SetPoint(ns.UI.ANCHOR_TOPLEFT, button, ns.UI.ANCHOR_TOPLEFT)

	button:SetScript(ns.UI.ON_CLICK, function(self, buttonName)
		if self.suppressNextClick then
			self.suppressNextClick = nil
			return
		end
		if buttonName == ns.UI.RIGHT_BUTTON then
			local locked = ns.ToggleLocked()
			if ns.RefreshAllDisplays then
				ns.RefreshAllDisplays()
			end
			if ns.RefreshOptionsPanel then
				ns.RefreshOptionsPanel()
			end
			print_lock_state(locked)
			show_tooltip(self)
			return
		end
		ns.OpenOptionsPanel()
	end)
	button:SetScript(ns.UI.ON_ENTER, show_tooltip)
	button:SetScript(ns.UI.ON_LEAVE, function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
	button:SetScript(ns.UI.ON_DRAG_START, function(self)
		self.dragMoved = nil
		self.dragStartX, self.dragStartY = GetCursorPosition()
		self:SetScript(ns.UI.ON_UPDATE, update_drag_position)
	end)
	button:SetScript(ns.UI.ON_DRAG_STOP, function(self)
		self:SetScript(ns.UI.ON_UPDATE, nil)
		update_drag_position(self)
		ns.SetMinimapButtonAngle(self.currentAngle)
		self.dragStartX = nil
		self.dragStartY = nil
		if self.dragMoved then
			self.suppressNextClick = true
			self.dragMoved = nil
		end
	end)

	set_button_angle(button, ns.GetMinimapButtonAngle())
	button:SetShown(not ns.IsMinimapButtonHidden())
	ns.MinimapButton = button
	return button
end
