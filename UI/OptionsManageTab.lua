SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

-- hint may be a plain string or a function called fresh on every hover, so
-- callers can build row-specific text (e.g. including the aura's own name)
-- without needing a dedicated tooltip helper per widget.
local function add_row_tooltip(widget, hint)
	widget:SetScript(ns.UI.ON_ENTER, function(self)
		if not GameTooltip then
			return
		end
		GameTooltip:SetOwner(self, ns.UI.ANCHOR_RIGHT)
		GameTooltip:ClearLines()
		local text = type(hint) == ns.LUA_TYPE.FUNCTION and hint() or hint
		if text then
			GameTooltip:AddLine(text, ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_R, ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_G, ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_B, true)
		end
		GameTooltip:Show()
	end)
	widget:SetScript(ns.UI.ON_LEAVE, function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
end

-- Shows the spell's own Blizzard tooltip (name, icon, description) fetched
-- live by spellId, not read from the (possibly currently-secret) live aura -
-- spell tooltip data is public regardless of whether this specific
-- application's timing is a Secret Value. Falls back to the plain hint text
-- if the spellId lookup isn't available.
local function add_row_spell_tooltip(widget, row, hint)
	widget:SetScript(ns.UI.ON_ENTER, function(self)
		if not GameTooltip then
			return
		end
		GameTooltip:SetOwner(self, ns.UI.ANCHOR_RIGHT)
		local shownSpell = false
		if row.spellId and GameTooltip.SetSpellByID then
			shownSpell = pcall(GameTooltip.SetSpellByID, GameTooltip, tonumber(row.spellId))
		end
		if not shownSpell then
			GameTooltip:ClearLines()
		end
		if hint then
			GameTooltip:AddLine(hint, ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_R, ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_G, ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_B, true)
		end
		GameTooltip:Show()
	end)
	widget:SetScript(ns.UI.ON_LEAVE, function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
end

-- Rows are pooled and scrolled, so they can't reuse ns.CreateOptionsCheck /
-- ns.CreateOptionsButton as-is: those helpers couple the widget's visual
-- parent (which must be the scroll child here) to a "refresh owner" frame
-- with its own RefreshFromDB/ignoreCallbacks contract. Mirror their look
-- directly instead. SetChecked() doesn't fire OnClick, so there's no
-- feedback-loop risk in skipping the ignoreCallbacks guard here.
local function create_manage_row(scrollChild, manageTab, groupKey)
	local row = CreateFrame(ns.UI.FRAME, nil, scrollChild)
	row:SetHeight(ns.OPTIONS_LAYOUT.MANAGE_ROW_HEIGHT)

	local check = CreateFrame(ns.UI.CHECK_BUTTON, nil, row, ns.UI.UICHECK_BUTTON_TEMPLATE)
	check:SetPoint(ns.UI.ANCHOR_LEFT, row, ns.UI.ANCHOR_LEFT, ns.OPTIONS_LAYOUT.MANAGE_CHECKBOX_X, ns.NUMBER.ZERO)
	check.Text = check.Text or check:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	check.Text:SetPoint(ns.UI.ANCHOR_LEFT, check, ns.UI.ANCHOR_RIGHT, ns.OPTIONS_LAYOUT.CHECK_LABEL_OFFSET_X, ns.OPTIONS_LAYOUT.CHECK_LABEL_OFFSET_Y)
	check:SetScript(ns.UI.ON_CLICK, function(self)
		if not row.spellId then
			return
		end
		ns.SetAuraHidden(groupKey, row.spellId, self:GetChecked() ~= true)
		ns.RefreshOptionsDisplays()
	end)
	add_row_spell_tooltip(check, row, ns.TEXT.OPTIONS_TOOLTIP_MANAGE_CHECK)
	row.check = check

	local forgetButton = CreateFrame(ns.UI.BUTTON, nil, row, ns.UI.UIPANEL_BUTTON_TEMPLATE)
	forgetButton:SetSize(ns.OPTIONS_LAYOUT.MANAGE_FORGET_BUTTON_WIDTH, ns.OPTIONS_LAYOUT.OPTIONS_BUTTON_HEIGHT)
	forgetButton:SetPoint(ns.UI.ANCHOR_LEFT, row, ns.UI.ANCHOR_LEFT, ns.OPTIONS_LAYOUT.MANAGE_FORGET_BUTTON_X, ns.NUMBER.ZERO)
	forgetButton:SetText(ns.TEXT.OPTIONS_FORGET)
	forgetButton:SetScript(ns.UI.ON_CLICK, function()
		if not row.spellId then
			return
		end
		ns.ForgetAura(groupKey, row.spellId)
		ns.RefreshOptionsDisplays()
		ns.RefreshManageAurasList(manageTab, groupKey)
	end)
	add_row_tooltip(forgetButton, function()
		if row.name then
			return ns.TEXT.OPTIONS_TOOLTIP_FORGET_FORMAT:format(row.name)
		end
		return ns.TEXT.OPTIONS_TOOLTIP_FORGET
	end)
	row.forgetButton = forgetButton

	return row
end

local function apply_manage_row(row, entry, width)
	row.spellId = entry.spellId
	row.name = entry.name
	row:SetWidth(width)
	row.check:SetChecked(not entry.hidden)
	local typeLabel = ns.AURA_TYPE_SHORT_LABEL[entry.auraType] or entry.auraType
	row.check.Text:SetText(ns.TEXT.OPTIONS_MANAGE_ROW_NAME_FORMAT:format(entry.name, typeLabel))
	row:Show()
end

function ns.RefreshManageAurasList(tab, groupKey)
	local filter = ns.GetUnitGroupManageFilter(groupKey)
	local sortMode = ns.GetUnitGroupManageSort(groupKey)
	local entries = ns.GetSortedKnownAuraEntries(groupKey, filter, sortMode)

	for key in pairs(tab.activeKeys) do
		tab.activeKeys[key] = nil
	end
	for index = 1, #entries do
		tab.activeKeys[entries[index].spellId] = true
	end

	for index = 1, #tab.staleKeys do
		tab.staleKeys[index] = nil
	end
	for key in pairs(tab.rows) do
		if not tab.activeKeys[key] then
			tab.staleKeys[#tab.staleKeys + 1] = key
		end
	end
	for index = 1, #tab.staleKeys do
		local key = tab.staleKeys[index]
		local row = tab.rows[key]
		tab.rows[key] = nil
		row:Hide()
		row.spellId = nil
		row.name = nil
		tab.freeRows[#tab.freeRows + 1] = row
		tab.staleKeys[index] = nil
	end

	local rowWidth = ns.OPTIONS_LAYOUT.MANAGE_LIST_WIDTH
	for index = 1, #entries do
		local entry = entries[index]
		local row = tab.rows[entry.spellId]
		if not row then
			row = table.remove(tab.freeRows) or create_manage_row(tab.scrollChild, tab, groupKey)
			tab.rows[entry.spellId] = row
		end
		apply_manage_row(row, entry, rowWidth)
		row:ClearAllPoints()
		row:SetPoint(
			ns.UI.ANCHOR_TOPLEFT,
			tab.scrollChild,
			ns.UI.ANCHOR_TOPLEFT,
			ns.LAYOUT_METRIC.ORIGIN_X,
			-(ns.OPTIONS_LAYOUT.MANAGE_LIST_TOP_PADDING + (index - ns.LAYOUT_METRIC.INDEX_OFFSET) * (ns.OPTIONS_LAYOUT.MANAGE_ROW_HEIGHT + ns.OPTIONS_LAYOUT.MANAGE_ROW_GAP_Y))
		)
	end

	-- Top padding keeps row 1's button border art from sitting flush against
	-- the scroll frame's clip edge, where it would render partially cut off.
	local totalHeight = ns.OPTIONS_LAYOUT.MANAGE_LIST_TOP_PADDING + #entries * (ns.OPTIONS_LAYOUT.MANAGE_ROW_HEIGHT + ns.OPTIONS_LAYOUT.MANAGE_ROW_GAP_Y)
	tab.scrollChild:SetSize(rowWidth, math.max(totalHeight, ns.LAYOUT_METRIC.MIN_SIZE))
	tab.emptyLabel:SetShown(#entries == ns.NUMBER.ZERO)
end

function ns.CreateOptionsManageTab(parent, groupKey, panelState)
	local tab = CreateFrame(ns.UI.FRAME, nil, parent)
	tab.groupKey = groupKey
	tab:SetPoint(ns.UI.ANCHOR_TOPLEFT, parent, ns.UI.ANCHOR_TOPLEFT, ns.NUMBER.ZERO, ns.OPTIONS_LAYOUT.MANAGE_LIST_Y)
	tab:SetSize(ns.OPTIONS_LAYOUT.MANAGE_TAB_WIDTH, ns.OPTIONS_LAYOUT.MANAGE_LIST_HEIGHT)

	-- Filter/sort are view preferences only (they never change the game's
	-- live aura data), so their dropdowns just re-run the list refresh
	-- (refresh = false below) instead of the default full display refresh.
	local filterDropdown = ns.CreateOptionsDropdownOnRow(
		tab,
		ns.NUMBER.ZERO,
		ns.NUMBER.ZERO,
		ns.OPTIONS_LAYOUT.MANAGE_FILTER_DROPDOWN_WIDTH,
		ns.MANAGE_FILTER_ORDER,
		function()
			return ns.GetUnitGroupManageFilter(groupKey)
		end,
		function(value)
			ns.SetUnitGroupManageFilter(groupKey, value)
		end,
		ns.MANAGE_FILTER_LABEL,
		ns.TEXT.OPTIONS_TOOLTIP_MANAGE_FILTER,
		false
	)
	ns.RegisterOptionsChild(tab, filterDropdown)

	local sortDropdown = ns.CreateOptionsDropdownOnRow(
		tab,
		ns.OPTIONS_LAYOUT.MANAGE_SORT_DROPDOWN_X,
		ns.NUMBER.ZERO,
		ns.OPTIONS_LAYOUT.MANAGE_SORT_DROPDOWN_WIDTH,
		ns.MANAGE_SORT_ORDER,
		function()
			return ns.GetUnitGroupManageSort(groupKey)
		end,
		function(value)
			ns.SetUnitGroupManageSort(groupKey, value)
		end,
		ns.MANAGE_SORT_LABEL,
		ns.TEXT.OPTIONS_TOOLTIP_MANAGE_SORT,
		false
	)
	ns.RegisterOptionsChild(tab, sortDropdown)

	local scrollFrame = CreateFrame(ns.UI.SCROLL_FRAME, nil, tab, ns.UI.UIPANEL_SCROLL_FRAME_TEMPLATE)
	scrollFrame:SetPoint(ns.UI.ANCHOR_TOPLEFT, tab, ns.UI.ANCHOR_TOPLEFT, ns.NUMBER.ZERO, ns.OPTIONS_LAYOUT.MANAGE_SCROLL_Y)
	scrollFrame:SetPoint(ns.UI.ANCHOR_BOTTOMRIGHT, tab, ns.UI.ANCHOR_BOTTOMRIGHT, ns.NUMBER.ZERO, ns.NUMBER.ZERO)

	local scrollChild = CreateFrame(ns.UI.FRAME, nil, scrollFrame)
	scrollChild:SetSize(ns.OPTIONS_LAYOUT.MANAGE_LIST_WIDTH, ns.LAYOUT_METRIC.MIN_SIZE)
	scrollFrame:SetScrollChild(scrollChild)
	tab.scrollFrame = scrollFrame
	tab.scrollChild = scrollChild

	tab.rows = {}
	tab.freeRows = {}
	tab.activeKeys = {}
	tab.staleKeys = {}

	local emptyLabel = scrollChild:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	emptyLabel:SetPoint(ns.UI.ANCHOR_TOPLEFT, scrollChild, ns.UI.ANCHOR_TOPLEFT, ns.OPTIONS_LAYOUT.MANAGE_CHECKBOX_X, ns.OPTIONS_LAYOUT.MANAGE_EMPTY_LABEL_Y)
	emptyLabel:SetWidth(ns.OPTIONS_LAYOUT.MANAGE_LIST_WIDTH - ns.OPTIONS_LAYOUT.MANAGE_CHECKBOX_X)
	emptyLabel:SetJustifyH(ns.UI.ANCHOR_LEFT)
	emptyLabel:SetText(ns.TEXT.OPTIONS_MANAGE_EMPTY)
	tab.emptyLabel = emptyLabel

	tab.RefreshFromDB = function(self)
		local selected = panelState.selectedAuraTabByGroup and panelState.selectedAuraTabByGroup[groupKey]
		local isSelected = selected == ns.GROUP_SUBTAB.MANAGE
		self:SetShown(isSelected)
		for _, child in ipairs(self.children or {}) do
			if child.RefreshFromDB then
				child:RefreshFromDB()
			end
		end
		if isSelected then
			-- Reset scroll position only on the transition into this
			-- sub-tab, not on every refresh, so toggling a checkbox while
			-- already scrolled down doesn't snap the view back to the top.
			if not self.wasSelected and self.scrollFrame then
				self.scrollFrame:SetVerticalScroll(ns.NUMBER.ZERO)
			end
			ns.RefreshManageAurasList(self, groupKey)
		end
		self.wasSelected = isSelected
	end

	return tab
end
