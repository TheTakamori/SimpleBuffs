SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local panelState = {
	frame = nil,
	category = nil,
	categoryID = nil,
}

local function build_panel()
	local frame = CreateFrame("Frame", "SimpleBuffsOptionsPanel", UIParent)
	frame.name = ns.TEXT.OPTIONS_TITLE
	frame:SetSize(620, 560)

	local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 0)

	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(560, 840)
	scroll:SetScrollChild(content)
	frame.scroll = scroll
	frame.content = content

	ns.CreateOptionsLabel(content, ns.TEXT.OPTIONS_TITLE, -16, true)
	local subtitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subtitle:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -42)
	subtitle:SetText(ns.TEXT.OPTIONS_SUBTITLE)

	ns.CreateOptionsLabel(content, "Units", -78)
	ns.CreateOptionsLabelAt(content, "Group", 16, -104)
	ns.CreateOptionsLabelAt(content, "Enabled", 112, -104)
	ns.CreateOptionsLabelAt(content, "Buffs", 190, -104)
	ns.CreateOptionsLabelAt(content, "Debuffs", 260, -104)
	local y = -130
	for _, groupKey in ipairs(ns.UNIT_GROUP_ORDER) do
		ns.CreateOptionsLabelAt(content, ns.UNIT_GROUP_LABEL[groupKey] or groupKey, 16, y + 2)
		ns.RegisterOptionsChild(content, ns.CreateOptionsCheckAt(content, "", 112, y, function()
			return ns.GetUnitGroupOptions(groupKey).enabled
		end, function(value)
			ns.SetUnitGroupEnabled(groupKey, value)
		end))
		ns.RegisterOptionsChild(content, ns.CreateOptionsCheckAt(content, "", 190, y, function()
			return ns.GetUnitGroupOptions(groupKey).buff
		end, function(value)
			ns.SetUnitGroupAuraEnabled(groupKey, ns.AURA_TYPE.BUFF, value)
		end))
		ns.RegisterOptionsChild(content, ns.CreateOptionsCheckAt(content, "", 260, y, function()
			return ns.GetUnitGroupOptions(groupKey).debuff
		end, function(value)
			ns.SetUnitGroupAuraEnabled(groupKey, ns.AURA_TYPE.DEBUFF, value)
		end))
		y = y - 24
	end

	ns.CreateOptionsLabel(content, "Display", -362)
	ns.RegisterOptionsChild(content, ns.CreateOptionsCycle(content, "Mode", -388, ns.DISPLAY_MODE_ORDER, ns.GetDisplayMode, ns.SetDisplayMode, ns.DISPLAY_MODE_LABEL))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCycle(content, "Layout", -416, ns.LAYOUT_ORDER, function()
		return ns.GetAppearance().layout
	end, function(value)
		ns.SetAppearanceValue("layout", value)
	end, ns.LAYOUT_LABEL))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCycle(content, "Sort", -444, ns.SORT_RULE_ORDER, function()
		return ns.GetAppearance().sortRule
	end, function(value)
		ns.SetAppearanceValue("sortRule", value)
	end, ns.SORT_RULE_LABEL))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCycle(content, "Filter", -472, ns.FILTER_MODE_ORDER, function()
		return ns.GetAppearance().filterMode
	end, function(value)
		ns.SetAppearanceValue("filterMode", value)
	end, ns.FILTER_MODE_LABEL))

	ns.CreateOptionsLabel(content, "Style", -512)
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, "Icon Size", -548, ns.LIMITS.ICON_SIZE_MIN, ns.LIMITS.ICON_SIZE_MAX, 1, function()
		return ns.GetAppearance().iconSize
	end, function(value)
		ns.SetAppearanceValue("iconSize", value)
	end))
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, "Spacing", -598, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, 1, function()
		return ns.GetAppearance().spacing
	end, function(value)
		ns.SetAppearanceValue("spacing", value)
	end))
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, "Max Auras", -648, ns.LIMITS.MAX_AURAS_MIN, ns.LIMITS.MAX_AURAS_MAX, 1, function()
		return ns.GetAppearance().maxAuras
	end, function(value)
		ns.SetAppearanceValue("maxAuras", value)
	end))
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, "Scale", -698, ns.LIMITS.SCALE_MIN * 100, ns.LIMITS.SCALE_MAX * 100, 5, function()
		return ns.GetAppearance().scale * 100
	end, function(value)
		ns.SetAppearanceValue("scale", value / 100)
	end, function(value)
		return tostring(math.floor(value)) .. "%"
	end))

	ns.RegisterOptionsChild(content, ns.CreateOptionsCheck(content, "Show Countdown Text", -746, function()
		return ns.GetAppearance().showCountdown
	end, function(value)
		ns.SetAppearanceValue("showCountdown", value)
	end))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCheck(content, "Show Cooldown Swipe", -772, function()
		return ns.GetAppearance().showSwipe
	end, function(value)
		ns.SetAppearanceValue("showSwipe", value)
	end))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCheck(content, "Show Stack Counts", -798, function()
		return ns.GetAppearance().showCounts
	end, function(value)
		ns.SetAppearanceValue("showCounts", value)
	end))
	function content:RefreshFromDB()
		self.ignoreCallbacks = true
		for _, child in ipairs(self.children or {}) do
			if child.RefreshFromDB then
				child:RefreshFromDB()
			end
		end
		self.ignoreCallbacks = false
	end
	function frame:RefreshFromDB()
		content:RefreshFromDB()
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
		local getID = type(category) == "table" and rawget(category, "GetID") or nil
		if type(getID) == "function" then
			panelState.categoryID = getID(category)
		elseif type(category) == "table" then
			panelState.categoryID = rawget(category, "ID")
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
