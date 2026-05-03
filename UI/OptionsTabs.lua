SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local function update_tab_button(tabButton)
	local selected = tabButton.panelState.selectedGroup == tabButton.groupKey
	if selected then
		tabButton.background:SetColorTexture(
			ns.OPTIONS_LAYOUT.TAB_SELECTED_R,
			ns.OPTIONS_LAYOUT.TAB_SELECTED_G,
			ns.OPTIONS_LAYOUT.TAB_SELECTED_B,
			ns.OPTIONS_LAYOUT.TAB_SELECTED_A
		)
		tabButton.text:SetTextColor(ns.OPTIONS_LAYOUT.TAB_TEXT_SELECTED_R, ns.OPTIONS_LAYOUT.TAB_TEXT_SELECTED_G, ns.OPTIONS_LAYOUT.TAB_TEXT_SELECTED_B)
	elseif tabButton.isHovering then
		tabButton.background:SetColorTexture(
			ns.OPTIONS_LAYOUT.TAB_HOVER_R,
			ns.OPTIONS_LAYOUT.TAB_HOVER_G,
			ns.OPTIONS_LAYOUT.TAB_HOVER_B,
			ns.OPTIONS_LAYOUT.TAB_HOVER_A
		)
		tabButton.text:SetTextColor(ns.OPTIONS_LAYOUT.TAB_TEXT_HOVER_R, ns.OPTIONS_LAYOUT.TAB_TEXT_HOVER_G, ns.OPTIONS_LAYOUT.TAB_TEXT_HOVER_B)
	else
		tabButton.background:SetColorTexture(ns.OPTIONS_LAYOUT.TAB_CLEAR_R, ns.OPTIONS_LAYOUT.TAB_CLEAR_G, ns.OPTIONS_LAYOUT.TAB_CLEAR_B, ns.OPTIONS_LAYOUT.TAB_CLEAR_A)
		tabButton.text:SetTextColor(ns.OPTIONS_LAYOUT.TAB_TEXT_NORMAL_R, ns.OPTIONS_LAYOUT.TAB_TEXT_NORMAL_G, ns.OPTIONS_LAYOUT.TAB_TEXT_NORMAL_B)
	end
end

function ns.CreateUnitTabButton(parent, groupKey, y, panelState)
	local label = ns.UNIT_GROUP_LABEL[groupKey] or groupKey
	local tabButton = CreateFrame(ns.UI.BUTTON, nil, parent)
	tabButton.groupKey = groupKey
	tabButton.panelState = panelState
	tabButton:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, ns.OPTIONS_LAYOUT.TAB_SIDEBAR_X, y)
	tabButton:SetSize(ns.OPTIONS_LAYOUT.TAB_BUTTON_WIDTH, ns.OPTIONS_LAYOUT.TAB_BUTTON_HEIGHT)

	tabButton.background = tabButton:CreateTexture(nil, ns.UI.BACKGROUND)
	tabButton.background:SetAllPoints()
	tabButton.text = tabButton:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL)
	tabButton.text:SetPoint(ns.UI.ANCHOR_LEFT, tabButton, ns.UI.ANCHOR_LEFT, ns.OPTIONS_LAYOUT.TAB_BUTTON_TEXT_X, ns.NUMBER.ZERO)
	tabButton.text:SetText(label)

	tabButton:SetScript(ns.UI.ON_CLICK, function()
		panelState.selectedGroup = groupKey
		parent:RefreshFromDB()
	end)
	tabButton:SetScript(ns.UI.ON_ENTER, function(self)
		self.isHovering = true
		update_tab_button(self)
	end)
	tabButton:SetScript(ns.UI.ON_LEAVE, function(self)
		self.isHovering = nil
		update_tab_button(self)
	end)
	tabButton.RefreshFromDB = update_tab_button
	return tabButton
end
