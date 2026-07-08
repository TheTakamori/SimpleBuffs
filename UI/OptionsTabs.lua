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

local function update_aura_tab_button(tabButton)
	local selected = tabButton.panelState.selectedAuraTabByGroup and tabButton.panelState.selectedAuraTabByGroup[tabButton.groupKey]
	if not ns.IsKnownValue(ns.GROUP_SUBTAB_ORDER, selected) then
		selected = ns.GROUP_SUBTAB.BUFF
	end
	local isSelected = selected == tabButton.subTab
	if isSelected then
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

function ns.CreateAuraTypeTabButtons(parent, groupKey, panelState, y)
	panelState.selectedAuraTabByGroup = panelState.selectedAuraTabByGroup or {}
	local buttons = {}
	local x = ns.OPTIONS_LAYOUT.SUBTITLE_X
	local w = ns.OPTIONS_LAYOUT.TAB_AURA_BUTTON_WIDTH
	local gap = ns.OPTIONS_LAYOUT.TAB_AURA_GAP_X
	for index = 1, #ns.GROUP_SUBTAB_ORDER do
		local subTab = ns.GROUP_SUBTAB_ORDER[index]
		local tabButton = CreateFrame(ns.UI.BUTTON, nil, parent)
		tabButton.groupKey = groupKey
		tabButton.panelState = panelState
		tabButton.subTab = subTab
		tabButton:SetSize(w, ns.OPTIONS_LAYOUT.TAB_AURA_BUTTON_HEIGHT)
		tabButton:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, x + (index - ns.NUMBER.ONE) * (w + gap), y)

		tabButton.background = tabButton:CreateTexture(nil, ns.UI.BACKGROUND)
		tabButton.background:SetAllPoints()
		tabButton.text = tabButton:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
		tabButton.text:SetPoint(ns.UI.ANCHOR_CENTER, tabButton, ns.UI.ANCHOR_CENTER, ns.NUMBER.ZERO, ns.NUMBER.ZERO)
		tabButton.text:SetText(ns.GROUP_SUBTAB_LABEL[subTab])

		tabButton:SetScript(ns.UI.ON_CLICK, function()
			panelState.selectedAuraTabByGroup[groupKey] = subTab
			parent:RefreshFromDB()
		end)
		tabButton:SetScript(ns.UI.ON_ENTER, function(self)
			self.isHovering = true
			update_aura_tab_button(self)
		end)
		tabButton:SetScript(ns.UI.ON_LEAVE, function(self)
			self.isHovering = nil
			update_aura_tab_button(self)
		end)
		tabButton.RefreshFromDB = update_aura_tab_button
		buttons[#buttons + 1] = tabButton
	end
	return buttons
end
