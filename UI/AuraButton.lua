SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local function set_count_text(button, entry, appearance)
	if not button.count then
		return
	end
	local text = ns.TEXT.EMPTY
	if not appearance.showCounts then
		text = ns.TEXT.EMPTY
	elseif entry.applicationDisplayCount then
		text = entry.applicationDisplayCount
	end
	button.count:SetText(text)
end

local function set_cooldown(button, entry, appearance)
	local style = appearance.style or ns.AURA_STYLE.ICON
	button.cooldown:SetHideCountdownNumbers(not appearance.showCountdown)
	button.cooldown:SetDrawSwipe(style ~= ns.AURA_STYLE.BAR and appearance.showSwipe == true)
	button.cooldown:SetDrawEdge(false)
	if button.cooldown.SetUseAuraDisplayTime then
		button.cooldown:SetUseAuraDisplayTime(true)
	end

	-- In Midnight, aura duration fields can be secret. Retrieve Blizzard's
	-- duration object by non-secret unit/instance ID and pass that to the
	-- cooldown widget instead of reading expirationTime/duration directly.
	if entry.durationObject and button.cooldown.SetCooldownFromDurationObject then
		button.cooldown:SetCooldownFromDurationObject(entry.durationObject, true)
		return
	end

	-- Non-Midnight fallback for local testing on older clients.
	local aura = entry.aura
	if not aura then
		button.cooldown:Clear()
		return
	end
	local duration = aura.duration
	local expirationTime = aura.expirationTime
	if duration and expirationTime and duration > ns.AURA_BUTTON.FALLBACK_MIN_DURATION then
		button.cooldown:SetCooldown(expirationTime - duration, duration, aura.timeMod or ns.AURA_BUTTON.FALLBACK_MOD_RATE)
	else
		button.cooldown:Clear()
	end
end

local function is_unlocked_standalone_icon(button)
	if ns.DB().locked then
		return false
	end

	local current = button
	while current do
		if current.mode == ns.DISPLAY_MODE.STANDALONE or current.containerKey then
			return true
		end
		current = current.GetParent and current:GetParent()
	end
	return false
end

local function add_standalone_move_tooltip_line(button)
	if not is_unlocked_standalone_icon(button) or not GameTooltip.AddLine then
		return
	end

	local entry = button.entry
	local unitLabel = entry and (ns.UNIT_LABEL[entry.unit] or entry.unit)
	GameTooltip:AddLine(
		ns.TEXT.TOOLTIP_DIVIDER,
		ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_R,
		ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_G,
		ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_B
	)
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
end

local function on_enter(self)
	local entry = self.entry
	if not GameTooltip or not entry then
		return
	end
	GameTooltip:SetOwner(self, ns.UI.ANCHOR_RIGHT)
	if entry.auraType == ns.AURA_TYPE.DEBUFF and GameTooltip.SetUnitDebuffByAuraInstanceID and entry.auraInstanceID then
		GameTooltip:SetUnitDebuffByAuraInstanceID(entry.unit, entry.auraInstanceID, ns.AURA_FILTER[entry.auraType])
	elseif entry.auraType == ns.AURA_TYPE.BUFF and GameTooltip.SetUnitBuffByAuraInstanceID and entry.auraInstanceID then
		GameTooltip:SetUnitBuffByAuraInstanceID(entry.unit, entry.auraInstanceID, ns.AURA_FILTER[entry.auraType])
	else
		GameTooltip:SetText(
			(ns.UNIT_LABEL[entry.unit] or entry.unit) .. ns.TEXT.SPACE .. (ns.AURA_LABEL[entry.auraType] or ns.TEXT.AURA_TOOLTIP_FALLBACK),
			ns.AURA_BUTTON.TOOLTIP_COLOR_R,
			ns.AURA_BUTTON.TOOLTIP_COLOR_G,
			ns.AURA_BUTTON.TOOLTIP_COLOR_B
		)
	end
	add_standalone_move_tooltip_line(self)
	GameTooltip:Show()
end

local function on_leave()
	if GameTooltip then
		GameTooltip:Hide()
	end
end

local function on_drag_start(self)
	if ns.StartStandaloneDrag then
		ns.StartStandaloneDrag(self)
	end
end

local function on_drag_stop(self)
	if ns.StopStandaloneDrag then
		ns.StopStandaloneDrag(self)
	end
end

local function apply_clickthrough(button)
	if button.SetMouseClickEnabled then
		button:SetMouseClickEnabled(false)
	end

	local cooldown = button.cooldown
	if not cooldown then
		return
	end

	if cooldown.SetMouseClickEnabled then
		cooldown:SetMouseClickEnabled(false)
	end
	if cooldown.EnableMouse then
		cooldown:EnableMouse(false)
	end
end

local function apply_icon(button, aura)
	button.icon:SetTexture(ns.AURA_BUTTON.QUESTION_MARK_ICON)
	if not aura then
		return
	end

	local ok, icon = pcall(function()
		return aura.icon
	end)
	if not ok then
		return
	end

	local iconType = type(icon)
	if iconType == ns.LUA_TYPE.NUMBER or iconType == ns.LUA_TYPE.STRING then
		button.icon:SetTexture(icon)
	end
end

local function apply_name(fontString, aura)
	if not fontString then
		return
	end

	local text = ns.TEXT.AURA_TOOLTIP_FALLBACK
	if aura then
		local ok, name = pcall(function()
			return aura.name
		end)
		if ok and type(name) == ns.LUA_TYPE.STRING then
			text = name
		end
	end
	fontString:SetText(text)
end

local function ensure_bar_widgets(button)
	if button.statusBar then
		return
	end

	local statusBar = CreateFrame(ns.UI.STATUS_BAR, nil, button)
	statusBar:SetStatusBarTexture(ns.TEXTURE.BAR_STATUS)
	button.statusBar = statusBar

	local background = statusBar:CreateTexture(nil, ns.UI.BACKGROUND)
	background:SetAllPoints()
	background:SetColorTexture(ns.BAR_ROW.BACKGROUND_R, ns.BAR_ROW.BACKGROUND_G, ns.BAR_ROW.BACKGROUND_B, ns.BAR_ROW.BACKGROUND_A)
	button.statusBarBackground = background

	local barName = statusBar:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	barName:SetJustifyH(ns.UI.ANCHOR_LEFT)
	button.barName = barName
end

local function get_countdown_text(button)
	if not button.cooldown.GetCountdownFontString then
		return nil
	end
	return button.cooldown:GetCountdownFontString()
end

local function capture_default_countdown_point(button, countdownText)
	if button.countdownDefaultPoint or not countdownText or not countdownText.GetPoint then
		return
	end
	local point, relativeTo, relativePoint, x, y = countdownText:GetPoint(1)
	if point then
		button.countdownDefaultPoint = { point = point, relativeTo = relativeTo, relativePoint = relativePoint, x = x, y = y }
	end
end

local function restore_default_countdown_point(button, countdownText)
	if not countdownText or not button.countdownDefaultPoint then
		return
	end
	local saved = button.countdownDefaultPoint
	countdownText:ClearAllPoints()
	countdownText:SetPoint(saved.point, saved.relativeTo, saved.relativePoint, saved.x, saved.y)
end

local function apply_bar_layout(button, size, barWidth, showIcon)
	ensure_bar_widgets(button)

	button.icon:SetShown(showIcon)

	local statusBar = button.statusBar
	statusBar:ClearAllPoints()
	if showIcon then
		button.icon:ClearAllPoints()
		button.icon:SetPoint(ns.UI.ANCHOR_LEFT, button, ns.UI.ANCHOR_LEFT, ns.LAYOUT_METRIC.ORIGIN_X, ns.LAYOUT_METRIC.ORIGIN_Y)
		button.icon:SetSize(size, size)
		statusBar:SetPoint(ns.UI.ANCHOR_LEFT, button.icon, ns.UI.ANCHOR_RIGHT, ns.BAR_ROW.ICON_GAP_X, ns.LAYOUT_METRIC.ORIGIN_Y)
	else
		statusBar:SetPoint(ns.UI.ANCHOR_LEFT, button, ns.UI.ANCHOR_LEFT, ns.LAYOUT_METRIC.ORIGIN_X, ns.LAYOUT_METRIC.ORIGIN_Y)
	end
	statusBar:SetPoint(ns.UI.ANCHOR_RIGHT, button, ns.UI.ANCHOR_RIGHT, ns.LAYOUT_METRIC.ORIGIN_X, ns.LAYOUT_METRIC.ORIGIN_Y)
	statusBar:SetHeight(size)
	statusBar:Show()

	local iconReserve = showIcon and (size + ns.BAR_ROW.ICON_GAP_X) or ns.NUMBER.ZERO
	local nameWidth = math.max(ns.LAYOUT_METRIC.MIN_SIZE, barWidth - iconReserve - ns.BAR_ROW.NAME_TEXT_INSET_X - ns.BAR_ROW.COUNTDOWN_RESERVE - ns.BAR_ROW.COUNT_RESERVE)
	button.barName:ClearAllPoints()
	button.barName:SetPoint(ns.UI.ANCHOR_LEFT, statusBar, ns.UI.ANCHOR_LEFT, ns.BAR_ROW.NAME_TEXT_INSET_X, ns.LAYOUT_METRIC.ORIGIN_Y)
	button.barName:SetWidth(nameWidth)
	button.barName:Show()

	local countdownText = get_countdown_text(button)
	if countdownText then
		capture_default_countdown_point(button, countdownText)
		countdownText:ClearAllPoints()
		countdownText:SetPoint(ns.UI.ANCHOR_RIGHT, button, ns.UI.ANCHOR_RIGHT, -ns.BAR_ROW.COUNTDOWN_OFFSET_X, ns.LAYOUT_METRIC.ORIGIN_Y)
	end

	button.count:ClearAllPoints()
	button.count:SetPoint(ns.UI.ANCHOR_RIGHT, button, ns.UI.ANCHOR_RIGHT, -ns.BAR_ROW.COUNT_OFFSET_X, ns.LAYOUT_METRIC.ORIGIN_Y)
end

local function apply_icon_layout(button, size)
	button.icon:ClearAllPoints()
	button.icon:SetAllPoints()

	if button.statusBar then
		button.statusBar:Hide()
	end
	if button.barName then
		button.barName:Hide()
	end

	local countdownText = get_countdown_text(button)
	restore_default_countdown_point(button, countdownText)

	button.count:ClearAllPoints()
	button.count:SetPoint(ns.UI.ANCHOR_BOTTOMRIGHT, button, ns.UI.ANCHOR_BOTTOMRIGHT, ns.AURA_BUTTON.COUNT_OFFSET_X, ns.AURA_BUTTON.COUNT_OFFSET_Y)
end

local function set_bar_timer(button, entry)
	local statusBar = button.statusBar
	if not statusBar then
		return
	end

	if entry.durationObject and statusBar.SetTimerDuration then
		local fillDirection = Enum and Enum.StatusBarFillDirection and Enum.StatusBarFillDirection.Reverse
		statusBar:SetTimerDuration(entry.durationObject, fillDirection)
		return
	end

	-- Non-Midnight fallback for local testing on older clients.
	local aura = entry.aura
	local duration = aura and aura.duration
	local expirationTime = aura and aura.expirationTime
	if statusBar.SetMinMaxValues and statusBar.SetValue then
		statusBar:SetMinMaxValues(ns.NUMBER.ZERO, duration and duration > ns.AURA_BUTTON.FALLBACK_MIN_DURATION and duration or ns.NUMBER.ONE)
		if duration and expirationTime and duration > ns.AURA_BUTTON.FALLBACK_MIN_DURATION then
			statusBar:SetValue(math.max(ns.NUMBER.ZERO, expirationTime - (GetTime and GetTime() or ns.NUMBER.ZERO)))
		else
			statusBar:SetValue(ns.NUMBER.ONE)
		end
	end
end

function ns.CreateAuraButton(parent)
	local button = CreateFrame(ns.UI.BUTTON, nil, parent)
	button.icon = button:CreateTexture(nil, ns.UI.BACKGROUND)
	button.icon:SetAllPoints()
	button.icon:SetTexCoord(ns.AURA_BUTTON.TEX_COORD_LEFT, ns.AURA_BUTTON.TEX_COORD_RIGHT, ns.AURA_BUTTON.TEX_COORD_TOP, ns.AURA_BUTTON.TEX_COORD_BOTTOM)

	button.cooldown = CreateFrame(ns.UI.COOLDOWN, nil, button, ns.UI.COOLDOWN_FRAME_TEMPLATE)
	button.cooldown:SetAllPoints()
	button.cooldown:SetReverse(true)

	button.count = button:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.NUMBER_FONT_NORMAL_SMALL)
	button.count:SetPoint(ns.UI.ANCHOR_BOTTOMRIGHT, button, ns.UI.ANCHOR_BOTTOMRIGHT, ns.AURA_BUTTON.COUNT_OFFSET_X, ns.AURA_BUTTON.COUNT_OFFSET_Y)

	button:RegisterForDrag(ns.UI.LEFT_BUTTON)
	button:SetScript(ns.UI.ON_ENTER, on_enter)
	button:SetScript(ns.UI.ON_LEAVE, on_leave)
	button:SetScript(ns.UI.ON_DRAG_START, on_drag_start)
	button:SetScript(ns.UI.ON_DRAG_STOP, on_drag_stop)
	apply_clickthrough(button)

	return button
end

function ns.ApplyAuraButton(button, entry, size, appearance)
	local style = appearance.style or ns.AURA_STYLE.ICON
	local width = style == ns.AURA_STYLE.BAR and (appearance.barWidth or size) or size
	button:SetSize(width, size)
	button.entry = entry
	button.entryKey = entry.key
	button.unit = entry.unit
	button.auraType = entry.auraType

	local aura = entry.aura
	apply_icon(button, aura)

	set_cooldown(button, entry, appearance)
	set_count_text(button, entry, appearance)

	if style == ns.AURA_STYLE.BAR then
		apply_bar_layout(button, size, width, appearance.showIcon ~= false)
		apply_name(button.barName, aura)
		set_bar_timer(button, entry)
	else
		apply_icon_layout(button, size)
	end

	button:Show()
end
