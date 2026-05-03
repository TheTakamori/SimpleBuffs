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

local function repaint_displays()
	if ns.RepaintAllDisplays then
		ns.RepaintAllDisplays()
	else
		refresh_displays()
	end
end

local UNIT_DROPDOWN_COLUMNS = {
	{
		header = ns.TEXT.OPTIONS_MODE,
		x = ns.OPTIONS_LAYOUT.MODE_COLUMN_X,
		values = function(groupKey)
			return ns.GetUnitGroupDisplayModes(groupKey)
		end,
		get = function(groupKey)
			return ns.GetUnitGroupDisplayMode(groupKey)
		end,
		set = function(groupKey, value)
			ns.SetUnitGroupDisplayMode(groupKey, value)
		end,
		labels = ns.DISPLAY_MODE_LABEL,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_MODE,
		refresh = repaint_displays,
	},
	{
		header = ns.TEXT.OPTIONS_LAYOUT,
		x = ns.OPTIONS_LAYOUT.LAYOUT_COLUMN_X,
		values = ns.LAYOUT_ORDER,
		get = function(groupKey)
			return ns.GetUnitGroupLayout(groupKey)
		end,
		set = function(groupKey, value)
			ns.SetUnitGroupLayout(groupKey, value)
		end,
		labels = ns.LAYOUT_LABEL,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_LAYOUT,
		refresh = repaint_displays,
	},
	{
		header = ns.TEXT.OPTIONS_SORT,
		x = ns.OPTIONS_LAYOUT.SORT_COLUMN_X,
		values = ns.SORT_RULE_ORDER,
		get = function(groupKey)
			return ns.GetUnitGroupSortRule(groupKey)
		end,
		set = function(groupKey, value)
			ns.SetUnitGroupSortRule(groupKey, value)
		end,
		labels = ns.SORT_RULE_LABEL,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_SORT,
	},
	{
		header = ns.TEXT.OPTIONS_FILTER,
		x = ns.OPTIONS_LAYOUT.FILTER_COLUMN_X,
		values = ns.FILTER_MODE_ORDER,
		get = function(groupKey)
			return ns.GetUnitGroupFilterMode(groupKey)
		end,
		set = function(groupKey, value)
			ns.SetUnitGroupFilterMode(groupKey, value)
		end,
		labels = ns.FILTER_MODE_LABEL,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_FILTER,
	},
}

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

local function create_standalone_move_hint(parent, x, y)
	local label = parent:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	label:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	label:SetWidth(ns.OPTIONS_LAYOUT.MOVE_HINT_WIDTH)
	label:SetText(ns.TEXT.OPTIONS_STANDALONE_MOVE_HELP)
	label.RefreshFromDB = function(self)
		if ns.AnyUnitGroupUsesStandaloneDisplay() then
			self:Show()
		else
			self:Hide()
		end
	end
	return label
end

local function create_options_content(frame)
	local content = CreateFrame(ns.UI.FRAME, nil, frame)
	content:SetPoint(ns.UI.ANCHOR_TOPLEFT, frame, ns.UI.ANCHOR_TOPLEFT, ns.OPTIONS_LAYOUT.SUBTITLE_X, ns.OPTIONS_LAYOUT.CONTENT_Y)
	content:SetSize(ns.OPTIONS_LAYOUT.CONTENT_WIDTH, ns.OPTIONS_LAYOUT.CONTENT_HEIGHT)
	content.RefreshFromDB = function()
		frame:RefreshFromDB()
	end
	return content
end

local function create_centered_header(parent, text, x, y, width)
	local label = ns.CreateOptionsLabelAt(parent, text, x, y)
	label:SetWidth(width)
	label:SetJustifyH(ns.UI.ANCHOR_CENTER)
	return label
end

local function open_legacy_options_category(frame)
	-- Older Interface Options builds often need two calls to land on an addon category.
	InterfaceOptionsFrame_OpenToCategory(frame)
	InterfaceOptionsFrame_OpenToCategory(frame)
end

local function build_panel()
	local frame = CreateFrame(ns.UI.FRAME, ns.FRAME_NAME.OPTIONS_PANEL, UIParent)
	frame.name = ns.TEXT.OPTIONS_TITLE
	frame:SetSize(ns.OPTIONS_LAYOUT.PANEL_WIDTH, ns.OPTIONS_LAYOUT.PANEL_HEIGHT)

	ns.CreateOptionsLabel(frame, ns.TEXT.OPTIONS_TITLE, ns.OPTIONS_LAYOUT.TITLE_Y, true)
	local version = frame:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	version:SetPoint(ns.UI.ANCHOR_TOPRIGHT, frame, ns.UI.ANCHOR_TOPRIGHT, ns.OPTIONS_LAYOUT.VERSION_X, ns.OPTIONS_LAYOUT.VERSION_Y)
	version:SetWidth(ns.OPTIONS_LAYOUT.VERSION_WIDTH)
	version:SetJustifyH(ns.UI.ANCHOR_RIGHT)
	version:SetText(string.format(ns.TEXT.OPTIONS_VERSION_FORMAT, ns.VERSION))
	local resetButton = ns.CreateOptionsButton(frame, ns.TEXT.OPTIONS_RESET_DEFAULTS, ns.NUMBER.ZERO, ns.OPTIONS_LAYOUT.RESET_BUTTON_Y, ns.OPTIONS_LAYOUT.RESET_BUTTON_WIDTH, function()
		confirm_reset_defaults(frame)
	end, nil, false)
	resetButton:ClearAllPoints()
	resetButton:SetPoint(ns.UI.ANCHOR_TOPRIGHT, frame, ns.UI.ANCHOR_TOPRIGHT, ns.OPTIONS_LAYOUT.RESET_BUTTON_RIGHT_X, ns.OPTIONS_LAYOUT.RESET_BUTTON_Y)
	local subtitle = frame:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	subtitle:SetPoint(ns.UI.ANCHOR_TOPLEFT, frame, ns.UI.ANCHOR_TOPLEFT, ns.OPTIONS_LAYOUT.SUBTITLE_X, ns.OPTIONS_LAYOUT.SUBTITLE_Y)
	subtitle:SetText(ns.TEXT.OPTIONS_SUBTITLE)

	local content = create_options_content(frame)
	frame.content = content

	ns.CreateOptionsLabelAt(content, ns.TEXT.OPTIONS_UNIT_GROUP, ns.OPTIONS_LAYOUT.UNIT_LABEL_X, ns.OPTIONS_LAYOUT.UNIT_HEADER_Y)
	ns.CreateOptionsLabelAt(content, ns.TEXT.OPTIONS_BUFFS, ns.OPTIONS_LAYOUT.BUFF_COLUMN_X, ns.OPTIONS_LAYOUT.UNIT_HEADER_Y)
	ns.CreateOptionsLabelAt(content, ns.TEXT.OPTIONS_DEBUFFS, ns.OPTIONS_LAYOUT.DEBUFF_COLUMN_X, ns.OPTIONS_LAYOUT.UNIT_HEADER_Y)
	for index = 1, #UNIT_DROPDOWN_COLUMNS do
		local column = UNIT_DROPDOWN_COLUMNS[index]
		create_centered_header(content, column.header, column.x, ns.OPTIONS_LAYOUT.UNIT_HEADER_Y, ns.OPTIONS_LAYOUT.UNIT_DROPDOWN_WIDTH)
	end
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
		for index = 1, #UNIT_DROPDOWN_COLUMNS do
			local column = UNIT_DROPDOWN_COLUMNS[index]
			local values = type(column.values) == ns.LUA_TYPE.FUNCTION and column.values(groupKey) or column.values
			ns.RegisterOptionsChild(content, ns.CreateOptionsDropdownOnRow(
				content,
				column.x,
				y,
				ns.OPTIONS_LAYOUT.UNIT_DROPDOWN_WIDTH,
				values,
				function()
					return column.get(groupKey)
				end,
				function(value)
					column.set(groupKey, value)
				end,
				column.labels,
				column.tooltip,
				column.refresh
			))
		end
		y = y - ns.OPTIONS_LAYOUT.UNIT_ROW_HEIGHT
	end
	local buttonY = y - ns.OPTIONS_LAYOUT.UNIT_BUTTON_GAP_Y
	ns.RegisterOptionsChild(content, ns.CreateOptionsButton(content, ns.TEXT.OPTIONS_DISABLE_ALL, ns.OPTIONS_LAYOUT.UNIT_LABEL_X, buttonY, ns.OPTIONS_LAYOUT.UNIT_TOGGLE_BUTTON_WIDTH, function()
		ns.SetAllUnitAurasEnabled(not ns.AreAllUnitAurasEnabled())
	end, function(self)
		self:SetText(ns.AreAllUnitAurasEnabled() and ns.TEXT.OPTIONS_DISABLE_ALL or ns.TEXT.OPTIONS_ENABLE_ALL)
	end))

	local styleY = buttonY - ns.OPTIONS_LAYOUT.GLOBAL_OPTIONS_GAP_Y
	local showCountdownY = styleY - ns.OPTIONS_LAYOUT.STYLE_CHECK_START_OFFSET_Y
	local showSwipeY = showCountdownY - ns.OPTIONS_LAYOUT.CHECK_ROW_GAP_Y
	local showCountsY = showSwipeY - ns.OPTIONS_LAYOUT.CHECK_ROW_GAP_Y

	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, ns.TEXT.OPTIONS_ICON_SIZE, styleY - ns.OPTIONS_LAYOUT.SLIDER_ICON_SIZE_OFFSET_Y, ns.LIMITS.ICON_SIZE_MIN, ns.LIMITS.ICON_SIZE_MAX, ns.OPTIONS_LAYOUT.SLIDER_STEP, function()
		return ns.GetAppearance().iconSize
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.ICON_SIZE, value)
	end, nil, ns.OPTIONS_LAYOUT.GLOBAL_OPTIONS_X + ns.OPTIONS_LAYOUT.SLIDER_COLUMN_INSET, ns.TEXT.OPTIONS_TOOLTIP_ICON_SIZE, repaint_displays))
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, ns.TEXT.OPTIONS_SPACING, styleY - ns.OPTIONS_LAYOUT.SLIDER_SPACING_OFFSET_Y, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, ns.OPTIONS_LAYOUT.SLIDER_STEP, function()
		return ns.GetAppearance().spacing
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.SPACING, value)
	end, nil, ns.OPTIONS_LAYOUT.GLOBAL_OPTIONS_X + ns.OPTIONS_LAYOUT.SLIDER_COLUMN_INSET, ns.TEXT.OPTIONS_TOOLTIP_SPACING, repaint_displays))
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, ns.TEXT.OPTIONS_MAX_AURAS, styleY - ns.OPTIONS_LAYOUT.SLIDER_MAX_AURAS_OFFSET_Y, ns.LIMITS.MAX_AURAS_MIN, ns.LIMITS.MAX_AURAS_MAX, ns.OPTIONS_LAYOUT.SLIDER_STEP, function()
		return ns.GetAppearance().maxAuras
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.MAX_AURAS, value)
	end, nil, ns.OPTIONS_LAYOUT.GLOBAL_OPTIONS_X + ns.OPTIONS_LAYOUT.SLIDER_COLUMN_INSET, ns.TEXT.OPTIONS_TOOLTIP_MAX_AURAS))
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, ns.TEXT.OPTIONS_SCALE, styleY - ns.OPTIONS_LAYOUT.SLIDER_SCALE_OFFSET_Y, ns.LIMITS.SCALE_MIN * ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER, ns.LIMITS.SCALE_MAX * ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER, ns.OPTIONS_LAYOUT.SCALE_STEP_PERCENT, function()
		return ns.GetAppearance().scale * ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.SCALE, value / ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER)
	end, function(value)
		return tostring(math.floor(value)) .. ns.TEXT.PERCENT
	end, ns.OPTIONS_LAYOUT.GLOBAL_OPTIONS_X + ns.OPTIONS_LAYOUT.SLIDER_COLUMN_INSET, ns.TEXT.OPTIONS_TOOLTIP_SCALE, repaint_displays))

	ns.RegisterOptionsChild(content, ns.CreateOptionsCheck(content, ns.TEXT.OPTIONS_SHOW_COUNTDOWN, showCountdownY, function()
		return ns.GetAppearance().showCountdown
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.SHOW_COUNTDOWN, value)
	end, ns.OPTIONS_LAYOUT.STYLE_CHECK_COLUMN_X, repaint_displays))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCheck(content, ns.TEXT.OPTIONS_SHOW_SWIPE, showSwipeY, function()
		return ns.GetAppearance().showSwipe
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.SHOW_SWIPE, value)
	end, ns.OPTIONS_LAYOUT.STYLE_CHECK_COLUMN_X, repaint_displays))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCheck(content, ns.TEXT.OPTIONS_SHOW_COUNTS, showCountsY, function()
		return ns.GetAppearance().showCounts
	end, function(value)
		ns.SetAppearanceValue(ns.DB_KEY.SHOW_COUNTS, value)
	end, ns.OPTIONS_LAYOUT.STYLE_CHECK_COLUMN_X, repaint_displays))
	ns.RegisterOptionsChild(content, create_standalone_move_hint(content, ns.OPTIONS_LAYOUT.MOVE_HINT_X, buttonY))
	function frame:RefreshFromDB()
		content.ignoreCallbacks = true
		for _, child in ipairs(content.children or {}) do
			if child.RefreshFromDB then
				child:RefreshFromDB()
			end
		end
		content.ignoreCallbacks = false
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
		open_legacy_options_category(frame)
	end
end
