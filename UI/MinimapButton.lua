SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local minimapShapes = {
	["ROUND"] = { true, true, true, true },
	["SQUARE"] = { false, false, false, false },
	["CORNER-TOPLEFT"] = { false, false, false, true },
	["CORNER-TOPRIGHT"] = { false, false, true, false },
	["CORNER-BOTTOMLEFT"] = { false, true, false, false },
	["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
	["SIDE-LEFT"] = { false, true, false, true },
	["SIDE-RIGHT"] = { true, false, true, false },
	["SIDE-TOP"] = { false, false, true, true },
	["SIDE-BOTTOM"] = { true, true, false, false },
	["TRICORNER-TOPLEFT"] = { false, true, true, true },
	["TRICORNER-TOPRIGHT"] = { true, false, true, true },
	["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
	["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local function normalize_angle(angle)
	angle = tonumber(angle) or ns.DEFAULTS.minimap.angle
	angle = math.fmod(angle, 360)
	if angle < 0 then
		angle = angle + 360
	end
	return angle
end

local function atan2(y, x)
	if math.atan2 then
		return math.atan2(y, x)
	end
	if x > 0 then
		return math.atan(y / x)
	elseif x < 0 and y >= 0 then
		return math.atan(y / x) + math.pi
	elseif x < 0 and y < 0 then
		return math.atan(y / x) - math.pi
	elseif x == 0 and y > 0 then
		return math.pi / 2
	elseif x == 0 and y < 0 then
		return -math.pi / 2
	end
	return 0
end

local function set_button_angle(button, angle)
	if not button or not Minimap then
		return
	end

	angle = normalize_angle(angle)
	local radians = math.rad(angle)
	local x = math.cos(radians)
	local y = math.sin(radians)
	local quadrant = 1
	if x < 0 then
		quadrant = quadrant + 1
	end
	if y > 0 then
		quadrant = quadrant + 2
	end

	local radiusOffset = ns.LIMITS.MINIMAP_RADIUS_OFFSET
	local widthRadius = (Minimap:GetWidth() / 2) + radiusOffset
	local heightRadius = (Minimap:GetHeight() / 2) + radiusOffset
	local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
	local quadrants = minimapShapes[shape] or minimapShapes.ROUND
	if quadrants[quadrant] then
		x = x * widthRadius
		y = y * heightRadius
	else
		local diagonalWidth = math.sqrt(2 * (widthRadius ^ 2)) - 10
		local diagonalHeight = math.sqrt(2 * (heightRadius ^ 2)) - 10
		x = math.max(-widthRadius, math.min(x * diagonalWidth, widthRadius))
		y = math.max(-heightRadius, math.min(y * diagonalHeight, heightRadius))
	end

	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", x, y)
	button.currentAngle = angle
end

local function update_drag_position(button)
	if not button or not Minimap then
		return
	end

	local scale = Minimap:GetEffectiveScale()
	local cursorX, cursorY = GetCursorPosition()
	local centerX, centerY = Minimap:GetCenter()
	centerX = (centerX or 0) * scale
	centerY = (centerY or 0) * scale
	set_button_angle(button, math.deg(atan2(cursorY - centerY, cursorX - centerX)))
end

local function show_tooltip(button)
	if not GameTooltip then
		return
	end
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(ns.TEXT.OPTIONS_TITLE, 1, 0.82, 0)
	GameTooltip:AddLine(ns.TEXT.MINIMAP_TOOLTIP_OPEN, 0.85, 0.85, 0.85, true)
	GameTooltip:AddLine(ns.TEXT.MINIMAP_TOOLTIP_DRAG, 0.65, 0.65, 0.65, true)
	GameTooltip:Show()
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

	local button = CreateFrame("Button", "SimpleBuffsMinimapButton", Minimap)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 8)
	button:SetSize(ns.LIMITS.MINIMAP_BUTTON_SIZE, ns.LIMITS.MINIMAP_BUTTON_SIZE)
	button:RegisterForClicks("LeftButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture(ns.TEXTURE.MINIMAP_HIGHLIGHT, "ADD")

	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetTexture(ns.TEXTURE.MINIMAP_BACKGROUND)
	background:SetSize(ns.LIMITS.MINIMAP_BUTTON_BACKGROUND_SIZE, ns.LIMITS.MINIMAP_BUTTON_BACKGROUND_SIZE)
	background:SetPoint("CENTER", button, "CENTER")

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(ns.TEXTURE.MINIMAP_ICON)
	icon:SetSize(ns.LIMITS.MINIMAP_BUTTON_ICON_SIZE, ns.LIMITS.MINIMAP_BUTTON_ICON_SIZE)
	icon:SetPoint("TOPLEFT", button, "TOPLEFT", ns.LIMITS.MINIMAP_ICON_OFFSET_X, ns.LIMITS.MINIMAP_ICON_OFFSET_Y)
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetTexture(ns.TEXTURE.MINIMAP_BORDER)
	border:SetSize(ns.LIMITS.MINIMAP_BUTTON_OVERLAY_SIZE, ns.LIMITS.MINIMAP_BUTTON_OVERLAY_SIZE)
	border:SetPoint("TOPLEFT", button, "TOPLEFT")

	button:SetScript("OnClick", function(self)
		if self.suppressNextClick then
			self.suppressNextClick = nil
			return
		end
		ns.OpenOptionsPanel()
	end)
	button:SetScript("OnEnter", show_tooltip)
	button:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
	button:SetScript("OnDragStart", function(self)
		self.suppressNextClick = true
		self:SetScript("OnUpdate", update_drag_position)
	end)
	button:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
		update_drag_position(self)
		ns.SetMinimapButtonAngle(self.currentAngle)
	end)

	set_button_angle(button, ns.GetMinimapButtonAngle())
	button:SetShown(not ns.IsMinimapButtonHidden())
	ns.MinimapButton = button
	return button
end
