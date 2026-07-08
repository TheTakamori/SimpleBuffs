SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local copyFromSelections = {}

local function register_tab_child(tab, child)
	if not child then
		return nil
	end
	return ns.RegisterOptionsChild(tab, child)
end

local function get_copy_from_selection(groupKey)
	local values = ns.GetCopyFromUnitGroupValues(groupKey)
	local selection = copyFromSelections[groupKey]
	if not ns.IsKnownValue(values, selection) then
		selection = values[1]
		copyFromSelections[groupKey] = selection
	end
	return selection
end

local function create_standalone_move_hint(parent, groupKey, x, y)
	local label = parent:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	label:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	label:SetWidth(ns.OPTIONS_LAYOUT.MOVE_HINT_WIDTH)
	label:SetText(ns.TEXT.OPTIONS_STANDALONE_MOVE_HELP)
	label.RefreshFromDB = function(self)
		local mode = ns.GetUnitGroupDisplayMode(groupKey)
		self:SetShown(mode == ns.DISPLAY_MODE.STANDALONE or mode == ns.DISPLAY_MODE.BOTH)
	end
	return label
end

local function create_unit_reset_button(tab, groupKey, panelState, y)
	local resetUnitButton = ns.CreateOptionsButton(tab, ns.TEXT.OPTIONS_RESET_UNIT_DEFAULTS_FORMAT:format(ns.UNIT_GROUP_LABEL[groupKey] or groupKey), ns.NUMBER.ZERO, y, ns.OPTIONS_LAYOUT.TAB_RESET_BUTTON_WIDTH, function()
		ns.ResetUnitGroupOptions(groupKey)
		ns.RefreshOptionsDisplays()
		if panelState.frame then
			panelState.frame:RefreshFromDB()
		end
	end, {
		refreshDisplays = false,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_RESET_UNIT_DEFAULTS,
	})
	resetUnitButton:ClearAllPoints()
	resetUnitButton:SetPoint(ns.UI.ANCHOR_TOPRIGHT, tab, ns.UI.ANCHOR_TOPRIGHT, ns.OPTIONS_LAYOUT.TAB_RESET_BUTTON_RIGHT_X, y)
	return resetUnitButton
end

local function create_copy_from_row(tab, groupKey, panelState, y)
	local label = ns.CreateOptionsRowLabel(tab, ns.TEXT.OPTIONS_COPY_FROM, ns.NUMBER.ZERO, y)
	register_tab_child(tab, label)
	register_tab_child(tab, ns.CreateOptionsTooltipRegion(tab, ns.NUMBER.ZERO, y, ns.OPTIONS_LAYOUT.TAB_PRIMARY_CONTROL_X, ns.OPTIONS_LAYOUT.OPTIONS_BUTTON_HEIGHT, ns.TEXT.OPTIONS_TOOLTIP_COPY_FROM))

	register_tab_child(tab, ns.CreateOptionsDropdownOnRow(
		tab,
		ns.OPTIONS_LAYOUT.TAB_PRIMARY_CONTROL_X,
		y,
		ns.OPTIONS_LAYOUT.TAB_DROPDOWN_WIDTH,
		ns.GetCopyFromUnitGroupValues(groupKey),
		function()
			return get_copy_from_selection(groupKey)
		end,
		function(value)
			copyFromSelections[groupKey] = value
		end,
		ns.UNIT_GROUP_LABEL,
		ns.TEXT.OPTIONS_TOOLTIP_COPY_FROM
	))

	local copyButton = ns.CreateOptionsButton(tab, ns.TEXT.OPTIONS_COPY, ns.OPTIONS_LAYOUT.TAB_COPY_BUTTON_X, y, ns.OPTIONS_LAYOUT.OPTIONS_BUTTON_WIDTH, function()
		local sourceGroupKey = get_copy_from_selection(groupKey)
		if ns.CopyUnitGroupOptions(sourceGroupKey, groupKey) then
			ns.RefreshOptionsDisplays()
			if panelState.frame then
				panelState.frame:RefreshFromDB()
			end
		end
	end, {
		refreshDisplays = false,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_COPY,
	})
	copyButton:ClearAllPoints()
	copyButton:SetPoint(ns.UI.ANCHOR_LEFT, tab, ns.UI.ANCHOR_TOPLEFT, ns.OPTIONS_LAYOUT.TAB_COPY_BUTTON_X, y)
	register_tab_child(tab, copyButton)
end

local function create_dropdown_row(tab, groupKey, column, y, resolveAuraType)
	local rowY = column.sameRowAsPrevious and y + ns.OPTIONS_LAYOUT.TAB_ROW_GAP_Y or y
	local controlX = column.x or ns.OPTIONS_LAYOUT.TAB_PRIMARY_CONTROL_X
	local labelX = controlX - ns.OPTIONS_LAYOUT.TAB_PRIMARY_CONTROL_X
	if not column.hideLabel then
		local label = ns.CreateOptionsRowLabel(tab, column.header, labelX, rowY)
		local labelHover = ns.CreateOptionsTooltipRegion(tab, labelX, rowY, ns.OPTIONS_LAYOUT.TAB_PRIMARY_CONTROL_X, ns.OPTIONS_LAYOUT.OPTIONS_BUTTON_HEIGHT, column.tooltip)
		if column.showWhen then
			label.RefreshFromDB = function(self)
				self:SetShown(column.showWhen(groupKey, resolveAuraType()))
			end
			if labelHover then
				labelHover.RefreshFromDB = function(self)
					self:SetShown(column.showWhen(groupKey, resolveAuraType()))
				end
			end
		end
		register_tab_child(tab, label)
		register_tab_child(tab, labelHover)
	end

	local values = type(column.values) == ns.LUA_TYPE.FUNCTION and column.values(groupKey) or column.values
	local dropdown = ns.CreateOptionsDropdownOnRow(
		tab,
		controlX,
		rowY,
		ns.OPTIONS_LAYOUT.TAB_DROPDOWN_WIDTH,
		values,
		function()
			if column.perAura then
				return column.get(groupKey, resolveAuraType())
			end
			return column.get(groupKey)
		end,
		function(value)
			if column.perAura then
				column.set(groupKey, resolveAuraType(), value)
			else
				column.set(groupKey, value)
			end
		end,
		column.labels,
		column.tooltip,
		column.refresh
	)
	if column.showWhen then
		local refreshDropdown = dropdown.RefreshFromDB
		dropdown.RefreshFromDB = function(self)
			if refreshDropdown then
				refreshDropdown(self)
			end
			self:SetShown(column.showWhen(groupKey, resolveAuraType()))
		end
	end
	register_tab_child(tab, dropdown)
end

local function create_style_slider(tab, groupKey, slider, y, resolveAuraType)
	local widget = ns.CreateOptionsSlider(
		tab,
		slider.text,
		y,
		slider.min,
		slider.max,
		slider.step,
		function()
			if slider.get then
				return slider.get(groupKey, resolveAuraType())
			end
			return ns.GetUnitGroupAppearance(groupKey, resolveAuraType())[slider.key]
		end,
		function(value)
			if slider.set then
				slider.set(groupKey, resolveAuraType(), value)
				return
			end
			ns.SetUnitGroupAppearanceValue(groupKey, resolveAuraType(), slider.key, value)
		end,
		slider.format,
		ns.OPTIONS_LAYOUT.TAB_PRIMARY_CONTROL_X,
		slider.tooltip,
		slider.refresh
	)
	if slider.showWhen then
		local refreshSlider = widget.RefreshFromDB
		widget.RefreshFromDB = function(self)
			if refreshSlider then
				refreshSlider(self)
			end
			local shown = slider.showWhen(groupKey, resolveAuraType())
			self:SetShown(shown)
			if self.ValueText then
				self.ValueText:SetShown(shown)
			end
		end
	end
	return widget
end

local function create_check_row(tab, groupKey, check, y, resolveAuraType)
	local rowY = check.sameRowAsPrevious and y + ns.OPTIONS_LAYOUT.CHECK_ROW_GAP_Y or y
	local widget = ns.CreateOptionsCheck(tab, check.text, rowY, function()
		return ns.GetUnitGroupAppearance(groupKey, resolveAuraType())[check.key]
	end, function(value)
		ns.SetUnitGroupAppearanceValue(groupKey, resolveAuraType(), check.key, value)
	end, check.x or ns.NUMBER.ZERO, check.refresh)
	if check.showWhen then
		local refreshCheck = widget.RefreshFromDB
		widget.RefreshFromDB = function(self)
			if refreshCheck then
				refreshCheck(self)
			end
			self:SetShown(check.showWhen(groupKey, resolveAuraType()))
		end
	end
	register_tab_child(tab, widget)
end

function ns.CreateOptionsGroupTab(parent, groupKey, panelState)
	local tab = CreateFrame(ns.UI.FRAME, nil, parent)
	tab.groupKey = groupKey
	tab:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, ns.OPTIONS_LAYOUT.TAB_CONTENT_X, ns.OPTIONS_LAYOUT.TAB_CONTENT_Y)
	tab:SetSize(ns.OPTIONS_LAYOUT.TAB_CONTENT_WIDTH, ns.OPTIONS_LAYOUT.TAB_CONTENT_HEIGHT)

	panelState.selectedAuraTabByGroup = panelState.selectedAuraTabByGroup or {}

	local function resolveSubTab()
		local selected = panelState.selectedAuraTabByGroup[groupKey]
		if not ns.IsKnownValue(ns.GROUP_SUBTAB_ORDER, selected) then
			selected = ns.GROUP_SUBTAB.BUFF
			panelState.selectedAuraTabByGroup[groupKey] = selected
		end
		return selected
	end

	-- The settings-block helpers below (dropdowns/sliders/checks) are all
	-- keyed by buff/debuff only; Manage Auras has no per-aura-type settings,
	-- so it never reaches them (the whole block is hidden while it's active).
	local function resolveAuraType()
		local subTab = resolveSubTab()
		if subTab == ns.GROUP_SUBTAB.MANAGE then
			return ns.AURA_TYPE.BUFF
		end
		return subTab
	end

	local y = ns.NUMBER.ZERO
	ns.CreateOptionsLabelAt(tab, ns.UNIT_GROUP_LABEL[groupKey] or groupKey, ns.NUMBER.ZERO, y, true)
	register_tab_child(tab, create_unit_reset_button(tab, groupKey, panelState, y))
	y = y - ns.OPTIONS_LAYOUT.TAB_TITLE_AURA_GAP_Y

	local auraTabButtons = ns.CreateAuraTypeTabButtons(tab, groupKey, panelState, y)
	for index = 1, #auraTabButtons do
		register_tab_child(tab, auraTabButtons[index])
	end
	y = y - ns.OPTIONS_LAYOUT.TAB_AURA_BUTTON_HEIGHT - ns.OPTIONS_LAYOUT.TAB_AURA_TO_CHECK_GAP_Y

	local settingsSection = CreateFrame(ns.UI.FRAME, nil, tab)
	settingsSection:SetAllPoints()

	register_tab_child(settingsSection, ns.CreateOptionsCheck(settingsSection, ns.TEXT.OPTIONS_AURA_FRAME_ENABLED, y, function()
		return ns.GetUnitGroupOptions(groupKey)[resolveAuraType()] == true
	end, function(value)
		ns.SetUnitGroupAuraEnabled(groupKey, resolveAuraType(), value)
	end, ns.NUMBER.ZERO, nil, ns.TEXT.OPTIONS_TOOLTIP_AURA_FRAME_ENABLED))
	register_tab_child(settingsSection, create_standalone_move_hint(settingsSection, groupKey, ns.OPTIONS_LAYOUT.TAB_CHECK_HINT_X, y))
	y = y - ns.OPTIONS_LAYOUT.TAB_CHECK_DROPDOWN_GAP_Y

	for index = 1, #ns.OPTIONS_UNIT_DROPDOWN_COLUMNS do
		local column = ns.OPTIONS_UNIT_DROPDOWN_COLUMNS[index]
		create_dropdown_row(settingsSection, groupKey, column, y, resolveAuraType)
		if not column.sameRowAsPrevious then
			y = y - ns.OPTIONS_LAYOUT.TAB_ROW_GAP_Y
		end
	end

	y = y - ns.OPTIONS_LAYOUT.TAB_DROPDOWN_SLIDER_GAP_Y

	for index = 1, #ns.OPTIONS_STYLE_SLIDERS do
		register_tab_child(settingsSection, create_style_slider(settingsSection, groupKey, ns.OPTIONS_STYLE_SLIDERS[index], y, resolveAuraType))
		y = y - ns.OPTIONS_LAYOUT.TAB_ROW_GAP_Y
	end

	for index = 1, #ns.OPTIONS_STYLE_CHECKS do
		local check = ns.OPTIONS_STYLE_CHECKS[index]
		create_check_row(settingsSection, groupKey, check, y, resolveAuraType)
		if not check.sameRowAsPrevious then
			y = y - ns.OPTIONS_LAYOUT.CHECK_ROW_GAP_Y
		end
	end

	settingsSection.RefreshFromDB = function(self)
		self:SetShown(resolveSubTab() ~= ns.GROUP_SUBTAB.MANAGE)
		for _, child in ipairs(self.children or {}) do
			if child.RefreshFromDB then
				child:RefreshFromDB()
			end
		end
	end
	register_tab_child(tab, settingsSection)

	local manageSection = ns.CreateOptionsManageTab(tab, groupKey, panelState)
	register_tab_child(tab, manageSection)

	create_copy_from_row(tab, groupKey, panelState, ns.OPTIONS_LAYOUT.TAB_COPY_FROM_Y)

	tab.RefreshFromDB = function(self)
		self:SetShown(panelState.selectedGroup == groupKey)
		for _, child in ipairs(self.children or {}) do
			if child.RefreshFromDB then
				child:RefreshFromDB()
			end
		end
	end
	return tab
end
