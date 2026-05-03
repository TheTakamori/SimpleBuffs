SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local function refresh_displays()
	if ns.RefreshAllDisplays then
		ns.RefreshAllDisplays()
	end
end

function ns.CreateOptionsLabel(parent, text, y, large)
	local label = parent:CreateFontString(nil, "OVERLAY", large and "GameFontNormalLarge" or "GameFontNormal")
	label:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
	label:SetText(text)
	return label
end

function ns.CreateOptionsLabelAt(parent, text, x, y, large)
	local label = ns.CreateOptionsLabel(parent, text, y, large)
	label:ClearAllPoints()
	label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	return label
end

function ns.CreateOptionsCheck(parent, text, y, getter, setter)
	local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	check:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
	check.Text = check.Text or check:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	check.Text:SetPoint("LEFT", check, "RIGHT", 2, 0)
	check.Text:SetText(text)
	check:SetScript("OnClick", function(self)
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
	check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	return check
end

function ns.CreateOptionsCycle(parent, text, y, values, getter, setter, labels)
	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", parent, "TOPLEFT", 22, y)
	label:SetText(text)

	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(160, 22)
	button:SetPoint("LEFT", label, "RIGHT", 12, 0)
	button:SetScript("OnClick", function()
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
	return button
end

function ns.CreateOptionsSlider(parent, text, y, minValue, maxValue, step, getter, setter, formatter)
	local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, y)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetValueStep(step)
	if slider.SetObeyStepOnDrag then
		slider:SetObeyStepOnDrag(true)
	end
	slider:SetWidth(220)
	slider.Text:SetText(text)
	slider.Low:SetText(tostring(minValue))
	slider.High:SetText(tostring(maxValue))
	slider.ValueText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	slider.ValueText:SetPoint("LEFT", slider, "RIGHT", 12, 0)
	slider:SetScript("OnValueChanged", function(self, value)
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
	return slider
end

function ns.RegisterOptionsChild(panel, child)
	panel.children = panel.children or {}
	panel.children[#panel.children + 1] = child
	return child
end
