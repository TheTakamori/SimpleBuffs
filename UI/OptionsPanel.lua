SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local panelState = {
	frame = nil,
	category = nil,
	categoryID = nil,
}

local function refresh_displays()
	if ns.RefreshAllDisplays then
		ns.RefreshAllDisplays()
	end
end

local function register_reset_confirmation(frame)
	if not StaticPopupDialogs or StaticPopupDialogs[ns.POPUP.RESET_DEFAULTS_CONFIRM] then
		return
	end

	StaticPopupDialogs[ns.POPUP.RESET_DEFAULTS_CONFIRM] = {
		text = ns.TEXT.OPTIONS_RESET_CONFIRM,
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			ns.ResetDB()
			refresh_displays()
			frame:RefreshFromDB()
		end,
		timeout = ns.OPTIONS_LAYOUT.POPUP_TIMEOUT,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = ns.OPTIONS_LAYOUT.POPUP_PREFERRED_INDEX,
	}
end

local function confirm_reset_defaults(frame)
	if StaticPopup_Show then
		register_reset_confirmation(frame)
		StaticPopup_Show(ns.POPUP.RESET_DEFAULTS_CONFIRM)
		return
	end

	ns.ResetDB()
	refresh_displays()
	frame:RefreshFromDB()
end

local function display_mode_uses_standalone()
	local mode = ns.GetDisplayMode()
	return mode == ns.DISPLAY_MODE.STANDALONE or mode == ns.DISPLAY_MODE.BOTH
end

local function create_standalone_move_help(parent, relativeTo)
	local label = parent:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	label:SetPoint(ns.UI.ANCHOR_BOTTOMLEFT, relativeTo, ns.UI.ANCHOR_TOPLEFT, ns.OPTIONS_LAYOUT.MODE_HELP_OFFSET_X, ns.OPTIONS_LAYOUT.MODE_HELP_PADDING_Y)
	label:SetWidth(ns.OPTIONS_LAYOUT.MODE_HELP_WIDTH)
	label:SetText(ns.TEXT.OPTIONS_STANDALONE_MOVE_HELP)
	label.RefreshFromDB = function(self)
		if display_mode_uses_standalone() then
			self:Show()
		else
			self:Hide()
		end
	end
	return label
end

local function build_panel()
	local frame = CreateFrame(ns.UI.FRAME, ns.FRAME_NAME.OPTIONS_PANEL, UIParent)
	frame.name = ns.TEXT.OPTIONS_TITLE
	frame:SetSize(ns.OPTIONS_LAYOUT.PANEL_WIDTH, ns.OPTIONS_LAYOUT.PANEL_HEIGHT)
	frame.content = frame
	local content = frame

	ns.CreateOptionsLabel(content, ns.TEXT.OPTIONS_TITLE, ns.OPTIONS_LAYOUT.TITLE_Y, true)
	local subtitle = content:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	subtitle:SetPoint(ns.UI.ANCHOR_TOPLEFT, content, ns.UI.ANCHOR_TOPLEFT, ns.OPTIONS_LAYOUT.SUBTITLE_X, ns.OPTIONS_LAYOUT.SUBTITLE_Y)
	subtitle:SetText(ns.TEXT.OPTIONS_SUBTITLE)

	ns.CreateOptionsLabelAt(content, ns.TEXT.OPTIONS_UNIT_GROUP, ns.OPTIONS_LAYOUT.UNIT_LABEL_X, ns.OPTIONS_LAYOUT.UNIT_HEADER_Y)
	ns.CreateOptionsLabelAt(content, ns.TEXT.OPTIONS_BUFFS, ns.OPTIONS_LAYOUT.BUFF_COLUMN_X, ns.OPTIONS_LAYOUT.UNIT_HEADER_Y)
	ns.CreateOptionsLabelAt(content, ns.TEXT.OPTIONS_DEBUFFS, ns.OPTIONS_LAYOUT.DEBUFF_COLUMN_X, ns.OPTIONS_LAYOUT.UNIT_HEADER_Y)
	local y = ns.OPTIONS_LAYOUT.UNIT_ROW_START_Y
	for _, groupKey in ipairs(ns.UNIT_GROUP_ORDER) do
		ns.CreateOptionsRowLabel(content, ns.UNIT_GROUP_LABEL[groupKey] or groupKey, ns.OPTIONS_LAYOUT.UNIT_LABEL_X, y)
		ns.RegisterOptionsChild(content, ns.CreateOptionsCheckOnRow(content, ns.TEXT.EMPTY, ns.OPTIONS_LAYOUT.BUFF_COLUMN_X, y, function()
			return ns.GetUnitGroupOptions(groupKey).buff
		end, function(value)
			ns.SetUnitGroupAuraEnabled(groupKey, ns.AURA_TYPE.BUFF, value)
		end))
		ns.RegisterOptionsChild(content, ns.CreateOptionsCheckOnRow(content, ns.TEXT.EMPTY, ns.OPTIONS_LAYOUT.DEBUFF_COLUMN_X, y, function()
			return ns.GetUnitGroupOptions(groupKey).debuff
		end, function(value)
			ns.SetUnitGroupAuraEnabled(groupKey, ns.AURA_TYPE.DEBUFF, value)
		end))
		y = y - ns.OPTIONS_LAYOUT.UNIT_ROW_HEIGHT
	end
	local buttonY = y - ns.OPTIONS_LAYOUT.UNIT_BUTTON_GAP_Y
	ns.RegisterOptionsChild(content, ns.CreateOptionsButton(content, ns.TEXT.OPTIONS_DISABLE_ALL, ns.OPTIONS_LAYOUT.UNIT_LABEL_X, buttonY, ns.OPTIONS_LAYOUT.UNIT_TOGGLE_BUTTON_WIDTH, function()
		ns.SetAllUnitAurasEnabled(not ns.AreAllUnitAurasEnabled())
	end, function(self)
		self:SetText(ns.AreAllUnitAurasEnabled() and ns.TEXT.OPTIONS_DISABLE_ALL or ns.TEXT.OPTIONS_ENABLE_ALL)
	end))
	ns.CreateOptionsButton(content, ns.TEXT.OPTIONS_RESET_DEFAULTS, ns.OPTIONS_LAYOUT.RESET_BUTTON_X, buttonY, ns.OPTIONS_LAYOUT.RESET_BUTTON_WIDTH, function()
		confirm_reset_defaults(frame)
	end)

	local displayY = ns.OPTIONS_LAYOUT.UNIT_HEADER_Y
	local styleY = displayY - ns.OPTIONS_LAYOUT.DISPLAY_STYLE_GAP_Y
	local showCountdownY = styleY - ns.OPTIONS_LAYOUT.STYLE_CHECK_GAP_Y
	local showSwipeY = showCountdownY - ns.OPTIONS_LAYOUT.CHECK_ROW_GAP_Y
	local showCountsY = showSwipeY - ns.OPTIONS_LAYOUT.CHECK_ROW_GAP_Y

	ns.CreateOptionsLabelAt(content, ns.TEXT.OPTIONS_DISPLAY, ns.OPTIONS_LAYOUT.RIGHT_COLUMN_X, displayY)
	local modeButton = ns.CreateOptionsCycle(content, ns.TEXT.OPTIONS_MODE, displayY - ns.OPTIONS_LAYOUT.CYCLE_MODE_OFFSET_Y, ns.DISPLAY_MODE_ORDER, ns.GetDisplayMode, ns.SetDisplayMode, ns.DISPLAY_MODE_LABEL, ns.OPTIONS_LAYOUT.RIGHT_COLUMN_X + ns.OPTIONS_LAYOUT.RIGHT_COLUMN_INSET, ns.TEXT.OPTIONS_TOOLTIP_MODE)
	ns.RegisterOptionsChild(content, modeButton)
	ns.RegisterOptionsChild(content, create_standalone_move_help(content, modeButton))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCycle(content, ns.TEXT.OPTIONS_LAYOUT, displayY - ns.OPTIONS_LAYOUT.CYCLE_LAYOUT_OFFSET_Y, ns.LAYOUT_ORDER, function()
		return ns.GetAppearance().layout
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.LAYOUT, value)
	end, ns.LAYOUT_LABEL, ns.OPTIONS_LAYOUT.RIGHT_COLUMN_X + ns.OPTIONS_LAYOUT.RIGHT_COLUMN_INSET, ns.TEXT.OPTIONS_TOOLTIP_LAYOUT))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCycle(content, ns.TEXT.OPTIONS_SORT, displayY - ns.OPTIONS_LAYOUT.CYCLE_SORT_OFFSET_Y, ns.SORT_RULE_ORDER, function()
		return ns.GetAppearance().sortRule
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.SORT_RULE, value)
	end, ns.SORT_RULE_LABEL, ns.OPTIONS_LAYOUT.RIGHT_COLUMN_X + ns.OPTIONS_LAYOUT.RIGHT_COLUMN_INSET, ns.TEXT.OPTIONS_TOOLTIP_SORT))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCycle(content, ns.TEXT.OPTIONS_FILTER, displayY - ns.OPTIONS_LAYOUT.CYCLE_FILTER_OFFSET_Y, ns.FILTER_MODE_ORDER, function()
		return ns.GetAppearance().filterMode
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.FILTER_MODE, value)
	end, ns.FILTER_MODE_LABEL, ns.OPTIONS_LAYOUT.RIGHT_COLUMN_X + ns.OPTIONS_LAYOUT.RIGHT_COLUMN_INSET, ns.TEXT.OPTIONS_TOOLTIP_FILTER))

	ns.CreateOptionsLabelAt(content, ns.TEXT.OPTIONS_STYLE, ns.OPTIONS_LAYOUT.RIGHT_COLUMN_X, styleY)
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, ns.TEXT.OPTIONS_ICON_SIZE, styleY - ns.OPTIONS_LAYOUT.SLIDER_ICON_SIZE_OFFSET_Y, ns.LIMITS.ICON_SIZE_MIN, ns.LIMITS.ICON_SIZE_MAX, ns.OPTIONS_LAYOUT.SLIDER_STEP, function()
		return ns.GetAppearance().iconSize
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.ICON_SIZE, value)
	end, nil, ns.OPTIONS_LAYOUT.RIGHT_COLUMN_X + ns.OPTIONS_LAYOUT.SLIDER_COLUMN_INSET, ns.TEXT.OPTIONS_TOOLTIP_ICON_SIZE))
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, ns.TEXT.OPTIONS_SPACING, styleY - ns.OPTIONS_LAYOUT.SLIDER_SPACING_OFFSET_Y, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, ns.OPTIONS_LAYOUT.SLIDER_STEP, function()
		return ns.GetAppearance().spacing
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.SPACING, value)
	end, nil, ns.OPTIONS_LAYOUT.RIGHT_COLUMN_X + ns.OPTIONS_LAYOUT.SLIDER_COLUMN_INSET, ns.TEXT.OPTIONS_TOOLTIP_SPACING))
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, ns.TEXT.OPTIONS_MAX_AURAS, styleY - ns.OPTIONS_LAYOUT.SLIDER_MAX_AURAS_OFFSET_Y, ns.LIMITS.MAX_AURAS_MIN, ns.LIMITS.MAX_AURAS_MAX, ns.OPTIONS_LAYOUT.SLIDER_STEP, function()
		return ns.GetAppearance().maxAuras
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.MAX_AURAS, value)
	end, nil, ns.OPTIONS_LAYOUT.RIGHT_COLUMN_X + ns.OPTIONS_LAYOUT.SLIDER_COLUMN_INSET, ns.TEXT.OPTIONS_TOOLTIP_MAX_AURAS))
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, ns.TEXT.OPTIONS_SCALE, styleY - ns.OPTIONS_LAYOUT.SLIDER_SCALE_OFFSET_Y, ns.LIMITS.SCALE_MIN * ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER, ns.LIMITS.SCALE_MAX * ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER, ns.OPTIONS_LAYOUT.SCALE_STEP_PERCENT, function()
		return ns.GetAppearance().scale * ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.SCALE, value / ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER)
	end, function(value)
		return tostring(math.floor(value)) .. ns.TEXT.PERCENT
	end, ns.OPTIONS_LAYOUT.RIGHT_COLUMN_X + ns.OPTIONS_LAYOUT.SLIDER_COLUMN_INSET, ns.TEXT.OPTIONS_TOOLTIP_SCALE))

	ns.RegisterOptionsChild(content, ns.CreateOptionsCheck(content, ns.TEXT.OPTIONS_SHOW_COUNTDOWN, showCountdownY, function()
		return ns.GetAppearance().showCountdown
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.SHOW_COUNTDOWN, value)
	end, ns.OPTIONS_LAYOUT.RIGHT_COLUMN_X))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCheck(content, ns.TEXT.OPTIONS_SHOW_SWIPE, showSwipeY, function()
		return ns.GetAppearance().showSwipe
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.SHOW_SWIPE, value)
	end, ns.OPTIONS_LAYOUT.RIGHT_COLUMN_X))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCheck(content, ns.TEXT.OPTIONS_SHOW_COUNTS, showCountsY, function()
		return ns.GetAppearance().showCounts
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.SHOW_COUNTS, value)
	end, ns.OPTIONS_LAYOUT.RIGHT_COLUMN_X))
	function frame:RefreshFromDB()
		self.ignoreCallbacks = true
		for _, child in ipairs(self.children or {}) do
			if child.RefreshFromDB then
				child:RefreshFromDB()
			end
		end
		self.ignoreCallbacks = false
	end

	return frame
end

function ns.EnsureOptionsPanel()
	if panelState.frame then
		panelState.frame:RefreshFromDB()
		return panelState.frame
	end

	local frame = build_panel()
	panelState.frame = frame

	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
		local category = Settings.RegisterCanvasLayoutCategory(frame, ns.TEXT.OPTIONS_TITLE)
		Settings.RegisterAddOnCategory(category)
		panelState.category = category
		local getID = type(category) == ns.LUA_TYPE.TABLE and rawget(category, ns.FRAME_ATTR.GET_ID) or nil
		if type(getID) == ns.LUA_TYPE.FUNCTION then
			panelState.categoryID = getID(category)
		elseif type(category) == ns.LUA_TYPE.TABLE then
			panelState.categoryID = rawget(category, ns.FRAME_ATTR.ID)
		end
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(frame)
	end

	frame:RefreshFromDB()
	return frame
end

function ns.OpenOptionsPanel()
	local frame = ns.EnsureOptionsPanel()
	if Settings and Settings.OpenToCategory and panelState.categoryID then
		Settings.OpenToCategory(panelState.categoryID)
	elseif InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(frame)
		InterfaceOptionsFrame_OpenToCategory(frame)
	end
end
