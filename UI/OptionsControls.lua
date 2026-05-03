SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local function refresh_displays()
	if ns.RefreshAllDisplays then
		ns.RefreshAllDisplays()
	end
end

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

function ns.CreateOptionsCheck(parent, text, y, getter, setter, x)
	local check = CreateFrame(ns.UI.CHECK_BUTTON, nil, parent, ns.UI.UICHECK_BUTTON_TEMPLATE)
	check:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x or ns.OPTIONS_LAYOUT.SUBTITLE_X, y)
	check.Text = check.Text or check:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	check.Text:SetPoint(ns.UI.ANCHOR_LEFT, check, ns.UI.ANCHOR_RIGHT, ns.OPTIONS_LAYOUT.CHECK_LABEL_OFFSET_X, ns.OPTIONS_LAYOUT.CHECK_LABEL_OFFSET_Y)
	check.Text:SetText(text)
	check:SetScript(ns.UI.ON_CLICK, function(self)
		if parent.ignoreCallbacks then
			return
		end
		setter(self:GetChecked() == true)
		refresh_displays()
		parent:RefreshFromDB()
	end)
	check.RefreshFromDB = function(self)
		self:SetChecked(getter() == true)
	end
	return check
end

function ns.CreateOptionsCheckAt(parent, text, x, y, getter, setter)
	local check = ns.CreateOptionsCheck(parent, text, y, getter, setter)
	check:ClearAllPoints()
	check:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	return check
end

function ns.CreateOptionsCheckOnRow(parent, text, x, y, getter, setter)
	local check = ns.CreateOptionsCheck(parent, text, y, getter, setter)
	check:ClearAllPoints()
	check:SetPoint(ns.UI.ANCHOR_LEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	return check
end

function ns.CreateOptionsCycle(parent, text, y, values, getter, setter, labels, x, tooltip)
	x = x or ns.OPTIONS_LAYOUT.SUBTITLE_X
	local label = parent:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	label:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	label:SetText(text)

	local button = CreateFrame(ns.UI.BUTTON, nil, parent, ns.UI.UIPANEL_BUTTON_TEMPLATE)
	button:SetSize(ns.OPTIONS_LAYOUT.CYCLE_BUTTON_WIDTH, ns.OPTIONS_LAYOUT.CYCLE_BUTTON_HEIGHT)
	button:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x + ns.OPTIONS_LAYOUT.CYCLE_BUTTON_LABEL_GAP_X, y + ns.OPTIONS_LAYOUT.CYCLE_BUTTON_OFFSET_Y)
	button:SetScript(ns.UI.ON_CLICK, function()
		local current = getter()
		local nextIndex = 1
		for index = 1, #values do
			if values[index] == current then
				nextIndex = index + 1
				break
			end
		end
		if nextIndex > #values then
			nextIndex = 1
		end
		setter(values[nextIndex])
		refresh_displays()
		parent:RefreshFromDB()
	end)
	button.RefreshFromDB = function(self)
		local value = getter()
		self:SetText((labels and labels[value]) or value)
	end
	add_tooltip(button, tooltip)
	return button
end

function ns.CreateOptionsButton(parent, text, x, y, width, onClick, refresh)
	local button = CreateFrame(ns.UI.BUTTON, nil, parent, ns.UI.UIPANEL_BUTTON_TEMPLATE)
	button:SetSize(width or ns.OPTIONS_LAYOUT.OPTIONS_BUTTON_WIDTH, ns.OPTIONS_LAYOUT.OPTIONS_BUTTON_HEIGHT)
	button:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	button:SetText(text)
	button:SetScript(ns.UI.ON_CLICK, function(self)
		if parent.ignoreCallbacks then
			return
		end
		onClick(self)
		refresh_displays()
		parent:RefreshFromDB()
	end)
	if refresh then
		button.RefreshFromDB = refresh
	end
	return button
end

function ns.CreateOptionsSlider(parent, text, y, minValue, maxValue, step, getter, setter, formatter, x, tooltip)
	x = x or ns.OPTIONS_LAYOUT.SUBTITLE_X
	local slider = CreateFrame(ns.UI.SLIDER, nil, parent, ns.UI.OPTIONS_SLIDER_TEMPLATE)
	slider:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x, y)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetValueStep(step)
	if slider.SetObeyStepOnDrag then
		slider:SetObeyStepOnDrag(true)
	end
	slider:SetWidth(ns.OPTIONS_LAYOUT.SLIDER_WIDTH)
	slider.Text:SetText(text)
	slider.Low:SetText(tostring(minValue))
	slider.High:SetText(tostring(maxValue))
	slider.ValueText = parent:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	slider.ValueText:SetPoint(ns.UI.ANCHOR_LEFT, slider, ns.UI.ANCHOR_RIGHT, ns.OPTIONS_LAYOUT.SLIDER_VALUE_OFFSET_X, ns.OPTIONS_LAYOUT.SLIDER_VALUE_OFFSET_Y)
	slider:SetScript(ns.UI.ON_VALUE_CHANGED, function(self, value)
		if parent.ignoreCallbacks then
			return
		end
		setter(value)
		self.ValueText:SetText(formatter and formatter(value) or tostring(math.floor(value)))
		refresh_displays()
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
