SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local function add_tooltip(frame, tooltip)
	if not tooltip then
		return
	end

	frame:SetScript(ns.UI.ON_ENTER, function(self)
		if not GameTooltip then
			return
		end
		GameTooltip:SetOwner(self, ns.UI.ANCHOR_RIGHT)
		GameTooltip:ClearLines()
		if type(tooltip) == ns.LUA_TYPE.TABLE then
			if tooltip.title then
				GameTooltip:AddLine(
					tooltip.title,
					ns.OPTIONS_LAYOUT.TAB_TEXT_SELECTED_R,
					ns.OPTIONS_LAYOUT.TAB_TEXT_SELECTED_G,
					ns.OPTIONS_LAYOUT.TAB_TEXT_SELECTED_B
				)
			end
			if tooltip.text then
				GameTooltip:AddLine(
					tooltip.text,
					ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_R,
					ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_G,
					ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_B,
					true
				)
			end
			GameTooltip:Show()
			return
		end
		GameTooltip:AddLine(
			tooltip,
			ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_R,
			ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_G,
			ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_B,
			true
		)
		GameTooltip:Show()
	end)
	frame:SetScript(ns.UI.ON_LEAVE, function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
end

function ns.CreateOptionsTooltipRegion(parent, x, y, width, height, tooltip)
	if not tooltip then
		return nil
	end
	local region = CreateFrame(ns.UI.FRAME, nil, parent)
	region:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	region:SetSize(width, height)
	add_tooltip(region, tooltip)
	return region
end

local function schedule_slider_refresh(slider, refresh)
	slider.refreshElapsed = ns.NUMBER.ZERO
	slider.pendingRefresh = refresh
	slider:SetScript(ns.UI.ON_UPDATE, function(self, elapsed)
		self.refreshElapsed = (self.refreshElapsed or ns.NUMBER.ZERO) + elapsed
		if self.refreshElapsed < ns.OPTIONS_LAYOUT.SLIDER_REFRESH_DELAY then
			return
		end
		local pendingRefresh = self.pendingRefresh
		self.pendingRefresh = nil
		self.refreshElapsed = nil
		self:SetScript(ns.UI.ON_UPDATE, nil)
		ns.RunOptionsRefresh(pendingRefresh)
	end)
end

function ns.CreateOptionsLabel(parent, text, y, large)
	local label = parent:CreateFontString(nil, ns.UI.OVERLAY, large and ns.UI.GAME_FONT_NORMAL_LARGE or ns.UI.GAME_FONT_NORMAL)
	label:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, ns.OPTIONS_LAYOUT.SUBTITLE_X, y)
	label:SetText(text)
	return label
end

function ns.CreateOptionsLabelAt(parent, text, x, y, large)
	local label = ns.CreateOptionsLabel(parent, text, y, large)
	label:ClearAllPoints()
	label:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	return label
end

function ns.CreateOptionsRowLabel(parent, text, x, y)
	local label = parent:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL)
	label:SetPoint(ns.UI.ANCHOR_LEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	label:SetText(text)
	return label
end

function ns.CreateOptionsCheck(parent, text, y, getter, setter, x, refresh, tooltip)
	local check = CreateFrame(ns.UI.CHECK_BUTTON, nil, parent, ns.UI.UICHECK_BUTTON_TEMPLATE)
	check:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x or ns.OPTIONS_LAYOUT.SUBTITLE_X, y)
	check.Text = check.Text or check:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	check.Text:SetPoint(ns.UI.ANCHOR_LEFT, check, ns.UI.ANCHOR_RIGHT, ns.OPTIONS_LAYOUT.CHECK_LABEL_OFFSET_X, ns.OPTIONS_LAYOUT.CHECK_LABEL_OFFSET_Y)
	check.Text:SetText(text)
	if tooltip and check.SetHitRectInsets then
		check:SetHitRectInsets(ns.NUMBER.ZERO, -ns.OPTIONS_LAYOUT.CHECK_TOOLTIP_HIT_RECT_RIGHT, ns.NUMBER.ZERO, ns.NUMBER.ZERO)
	end
	check:SetScript(ns.UI.ON_CLICK, function(self)
		if parent.ignoreCallbacks then
			return
		end
		setter(self:GetChecked() == true)
		ns.RunOptionsRefresh(refresh)
		parent:RefreshFromDB()
	end)
	check.RefreshFromDB = function(self)
		self:SetChecked(getter() == true)
	end
	add_tooltip(check, tooltip)
	return check
end

function ns.CreateOptionsCheckAt(parent, text, x, y, getter, setter, refresh)
	local check = ns.CreateOptionsCheck(parent, text, y, getter, setter, nil, refresh)
	check:ClearAllPoints()
	check:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	return check
end

function ns.CreateOptionsCheckOnRow(parent, text, x, y, getter, setter, refresh)
	local check = ns.CreateOptionsCheck(parent, text, y, getter, setter, nil, refresh)
	check:ClearAllPoints()
	check:SetPoint(ns.UI.ANCHOR_LEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	return check
end

function ns.CreateOptionsDropdownOnRow(parent, x, y, width, values, getter, setter, labels, tooltip, refresh)
	local dropdown = CreateFrame(ns.UI.DROPDOWN_BUTTON, nil, parent, ns.UI.WOW_STYLE_DROPDOWN_TEMPLATE)
	dropdown:SetSize(width or ns.OPTIONS_LAYOUT.DROPDOWN_BUTTON_WIDTH, ns.OPTIONS_LAYOUT.DROPDOWN_BUTTON_HEIGHT)
	dropdown:SetPoint(ns.UI.ANCHOR_LEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	local function get_label()
		local value = getter()
		return (labels and labels[value]) or value
	end
	local function is_selected(value)
		return getter() == value
	end
	local function set_selected(value)
		if getter() == value then
			return
		end
		setter(value)
		ns.RunOptionsRefresh(refresh)
		parent:RefreshFromDB()
	end
	if dropdown.SetDefaultText then
		dropdown:SetDefaultText(get_label())
	end
	if dropdown.SetSelectionText then
		dropdown:SetSelectionText(get_label)
	end
	dropdown:SetupMenu(function(_, rootDescription)
		for index = 1, #values do
			local value = values[index]
			rootDescription:CreateRadio((labels and labels[value]) or value, is_selected, set_selected, value)
		end
	end)
	dropdown.RefreshFromDB = function(self)
		if self.GenerateMenu then
			self:GenerateMenu()
		elseif self.OverrideText then
			self:OverrideText(get_label())
		end
	end
	add_tooltip(dropdown, tooltip)
	return dropdown
end

function ns.CreateOptionsButton(parent, text, x, y, width, onClick, refresh, refreshDisplays)
	local button = CreateFrame(ns.UI.BUTTON, nil, parent, ns.UI.UIPANEL_BUTTON_TEMPLATE)
	button:SetSize(width or ns.OPTIONS_LAYOUT.OPTIONS_BUTTON_WIDTH, ns.OPTIONS_LAYOUT.OPTIONS_BUTTON_HEIGHT)
	button:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	button:SetText(text)
	button:SetScript(ns.UI.ON_CLICK, function(self)
		if parent.ignoreCallbacks then
			return
		end
		onClick(self)
		ns.RunOptionsRefresh(refreshDisplays)
		parent:RefreshFromDB()
	end)
	if refresh then
		button.RefreshFromDB = refresh
	end
	return button
end

function ns.CreateOptionsSlider(parent, text, y, minValue, maxValue, step, getter, setter, formatter, x, tooltip, refresh)
	x = x or ns.OPTIONS_LAYOUT.SUBTITLE_X
	local slider = CreateFrame(ns.UI.SLIDER, nil, parent, ns.UI.OPTIONS_SLIDER_TEMPLATE)
	slider:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetValueStep(step)
	if slider.SetObeyStepOnDrag then
		slider:SetObeyStepOnDrag(true)
	end
	slider:SetWidth(ns.OPTIONS_LAYOUT.SLIDER_WIDTH)
	slider.Text:ClearAllPoints()
	slider.Text:SetWidth(ns.OPTIONS_LAYOUT.SLIDER_LABEL_WIDTH)
	slider.Text:SetJustifyH(ns.UI.ANCHOR_LEFT)
	slider.Text:SetPoint(ns.UI.ANCHOR_RIGHT, slider, ns.UI.ANCHOR_LEFT, -ns.OPTIONS_LAYOUT.SLIDER_LABEL_GAP_X, ns.NUMBER.ZERO)
	slider.Text:SetText(text)
	if tooltip then
		local titleHover = CreateFrame(ns.UI.FRAME, nil, parent)
		titleHover:SetPoint(ns.UI.ANCHOR_RIGHT, slider, ns.UI.ANCHOR_LEFT, -ns.OPTIONS_LAYOUT.SLIDER_LABEL_GAP_X, ns.NUMBER.ZERO)
		titleHover:SetSize(ns.OPTIONS_LAYOUT.SLIDER_LABEL_WIDTH, ns.OPTIONS_LAYOUT.OPTIONS_BUTTON_HEIGHT)
		add_tooltip(titleHover, tooltip)
	end
	slider.Low:SetText(tostring(minValue))
	slider.High:SetText(tostring(maxValue))
	slider.ValueText = parent:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	slider.ValueText:SetPoint(ns.UI.ANCHOR_LEFT, slider, ns.UI.ANCHOR_RIGHT, ns.OPTIONS_LAYOUT.SLIDER_VALUE_OFFSET_X, ns.OPTIONS_LAYOUT.SLIDER_VALUE_OFFSET_Y)
	slider:SetScript(ns.UI.ON_VALUE_CHANGED, function(self, value)
		if parent.ignoreCallbacks then
			return
		end
		local previousValue = getter()
		setter(value)
		if getter() == previousValue then
			return
		end
		self.ValueText:SetText(formatter and formatter(value) or tostring(math.floor(value)))
		schedule_slider_refresh(self, refresh or ns.RepaintOptionsDisplays)
	end)
	slider.RefreshFromDB = function(self)
		local value = getter()
		self:SetValue(value)
		self.ValueText:SetText(formatter and formatter(value) or tostring(math.floor(value)))
	end
	add_tooltip(slider, tooltip)
	return slider
end

function ns.RegisterOptionsChild(panel, child)
	panel.children = panel.children or {}
	panel.children[#panel.children + 1] = child
	return child
end
