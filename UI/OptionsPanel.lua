SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local panelState = {
	frame = nil,
	category = nil,
	categoryID = nil,
}

local UNIT_ROW_HEIGHT = 24
local UNIT_ROW_START_Y = -116
local RIGHT_COLUMN_X = 320

local function build_panel()
	local frame = CreateFrame("Frame", "SimpleBuffsOptionsPanel", UIParent)
	frame.name = ns.TEXT.OPTIONS_TITLE
	frame:SetSize(760, 560)
	frame.content = frame
	local content = frame

	ns.CreateOptionsLabel(content, ns.TEXT.OPTIONS_TITLE, -16, true)
	local subtitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subtitle:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -42)
	subtitle:SetText(ns.TEXT.OPTIONS_SUBTITLE)

	ns.CreateOptionsLabelAt(content, "Unit / Group", 16, -78)
	ns.CreateOptionsLabelAt(content, "Buffs", 112, -78)
	ns.CreateOptionsLabelAt(content, "Debuffs", 190, -78)
	local y = UNIT_ROW_START_Y
	for _, groupKey in ipairs(ns.UNIT_GROUP_ORDER) do
		ns.CreateOptionsRowLabel(content, ns.UNIT_GROUP_LABEL[groupKey] or groupKey, 16, y)
		ns.RegisterOptionsChild(content, ns.CreateOptionsCheckOnRow(content, "", 112, y, function()
			return ns.GetUnitGroupOptions(groupKey).buff
		end, function(value)
			ns.SetUnitGroupAuraEnabled(groupKey, ns.AURA_TYPE.BUFF, value)
		end))
		ns.RegisterOptionsChild(content, ns.CreateOptionsCheckOnRow(content, "", 190, y, function()
			return ns.GetUnitGroupOptions(groupKey).debuff
		end, function(value)
			ns.SetUnitGroupAuraEnabled(groupKey, ns.AURA_TYPE.DEBUFF, value)
		end))
		y = y - UNIT_ROW_HEIGHT
	end

	local displayY = -78
	local styleY = displayY - 154
	local showCountdownY = styleY - 234
	local showSwipeY = showCountdownY - 26
	local showCountsY = showSwipeY - 26

	ns.CreateOptionsLabelAt(content, "Display", RIGHT_COLUMN_X, displayY)
	ns.RegisterOptionsChild(content, ns.CreateOptionsCycle(content, "Mode", displayY - 26, ns.DISPLAY_MODE_ORDER, ns.GetDisplayMode, ns.SetDisplayMode, ns.DISPLAY_MODE_LABEL, RIGHT_COLUMN_X + 6))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCycle(content, "Layout", displayY - 54, ns.LAYOUT_ORDER, function()
		return ns.GetAppearance().layout
	end, function(value)
		ns.SetAppearanceValue("layout", value)
	end, ns.LAYOUT_LABEL, RIGHT_COLUMN_X + 6))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCycle(content, "Sort", displayY - 82, ns.SORT_RULE_ORDER, function()
		return ns.GetAppearance().sortRule
	end, function(value)
		ns.SetAppearanceValue("sortRule", value)
	end, ns.SORT_RULE_LABEL, RIGHT_COLUMN_X + 6))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCycle(content, "Filter", displayY - 110, ns.FILTER_MODE_ORDER, function()
		return ns.GetAppearance().filterMode
	end, function(value)
		ns.SetAppearanceValue("filterMode", value)
	end, ns.FILTER_MODE_LABEL, RIGHT_COLUMN_X + 6))

	ns.CreateOptionsLabelAt(content, "Style", RIGHT_COLUMN_X, styleY)
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, "Icon Size", styleY - 36, ns.LIMITS.ICON_SIZE_MIN, ns.LIMITS.ICON_SIZE_MAX, 1, function()
		return ns.GetAppearance().iconSize
	end, function(value)
		ns.SetAppearanceValue("iconSize", value)
	end, nil, RIGHT_COLUMN_X + 8))
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, "Spacing", styleY - 86, ns.LIMITS.SPACING_MIN, ns.LIMITS.SPACING_MAX, 1, function()
		return ns.GetAppearance().spacing
	end, function(value)
		ns.SetAppearanceValue("spacing", value)
	end, nil, RIGHT_COLUMN_X + 8))
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, "Max Auras", styleY - 136, ns.LIMITS.MAX_AURAS_MIN, ns.LIMITS.MAX_AURAS_MAX, 1, function()
		return ns.GetAppearance().maxAuras
	end, function(value)
		ns.SetAppearanceValue("maxAuras", value)
	end, nil, RIGHT_COLUMN_X + 8))
	ns.RegisterOptionsChild(content, ns.CreateOptionsSlider(content, "Scale", styleY - 186, ns.LIMITS.SCALE_MIN * 100, ns.LIMITS.SCALE_MAX * 100, 5, function()
		return ns.GetAppearance().scale * 100
	end, function(value)
		ns.SetAppearanceValue("scale", value / 100)
	end, function(value)
		return tostring(math.floor(value)) .. "%"
	end, RIGHT_COLUMN_X + 8))

	ns.RegisterOptionsChild(content, ns.CreateOptionsCheck(content, "Show Countdown Text", showCountdownY, function()
		return ns.GetAppearance().showCountdown
	end, function(value)
		ns.SetAppearanceValue("showCountdown", value)
	end, RIGHT_COLUMN_X))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCheck(content, "Show Cooldown Swipe", showSwipeY, function()
		return ns.GetAppearance().showSwipe
	end, function(value)
		ns.SetAppearanceValue("showSwipe", value)
	end, RIGHT_COLUMN_X))
	ns.RegisterOptionsChild(content, ns.CreateOptionsCheck(content, "Show Stack Counts", showCountsY, function()
		return ns.GetAppearance().showCounts
	end, function(value)
		ns.SetAppearanceValue("showCounts", value)
	end, RIGHT_COLUMN_X))
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
