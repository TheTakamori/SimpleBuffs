SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local panelState = {
	frame = nil,
	category = nil,
	categoryID = nil,
	selectedGroup = nil,
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
			ns.RefreshOptionsDisplays()
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
	ns.RefreshOptionsDisplays()
	frame:RefreshFromDB()
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
	local subtitle = frame:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.GAME_FONT_NORMAL_SMALL)
	subtitle:SetPoint(ns.UI.ANCHOR_TOPLEFT, frame, ns.UI.ANCHOR_TOPLEFT, ns.OPTIONS_LAYOUT.SUBTITLE_X, ns.OPTIONS_LAYOUT.SUBTITLE_Y)
	subtitle:SetText(ns.TEXT.OPTIONS_SUBTITLE)

	local content = create_options_content(frame)
	frame.content = content
	content.tabs = {}
	local divider = content:CreateTexture(nil, ns.UI.ARTWORK)
	divider:SetPoint(ns.UI.ANCHOR_TOPLEFT, content, ns.UI.ANCHOR_TOPLEFT, ns.OPTIONS_LAYOUT.TAB_DIVIDER_X, ns.OPTIONS_LAYOUT.TAB_DIVIDER_TOP_Y)
	divider:SetSize(ns.NUMBER.ONE, ns.OPTIONS_LAYOUT.TAB_DIVIDER_HEIGHT)
	divider:SetColorTexture(
		ns.OPTIONS_LAYOUT.TAB_DIVIDER_R,
		ns.OPTIONS_LAYOUT.TAB_DIVIDER_G,
		ns.OPTIONS_LAYOUT.TAB_DIVIDER_B,
		ns.OPTIONS_LAYOUT.TAB_DIVIDER_A
	)

	panelState.selectedGroup = panelState.selectedGroup or ns.UNIT_GROUP_ORDER[ns.NUMBER.ONE]
	local y = ns.OPTIONS_LAYOUT.TAB_BUTTON_START_Y
	for _, groupKey in ipairs(ns.UNIT_GROUP_ORDER) do
		ns.RegisterOptionsChild(content, ns.CreateUnitTabButton(content, groupKey, y, panelState))
		local tab = ns.CreateOptionsGroupTab(content, groupKey, panelState)
		content.tabs[#content.tabs + 1] = tab
		ns.RegisterOptionsChild(content, tab)
		y = y - ns.OPTIONS_LAYOUT.TAB_BUTTON_GAP_Y
	end
	local buttonY = y - ns.OPTIONS_LAYOUT.UNIT_BUTTON_GAP_Y
	ns.RegisterOptionsChild(content, ns.CreateOptionsCheck(content, ns.TEXT.LOCK_STATE_LOCKED, buttonY, function()
		return ns.DB().locked
	end, function(value)
		ns.SetLocked(value)
	end, ns.OPTIONS_LAYOUT.TAB_SIDEBAR_X, ns.RefreshOptionsDisplays, {
		title = ns.TEXT.LOCK_STATE_LOCKED,
		text = ns.TEXT.OPTIONS_TOOLTIP_LOCKED,
	}))
	buttonY = buttonY - ns.OPTIONS_LAYOUT.TAB_LOCK_BUTTON_GAP_Y
	ns.RegisterOptionsChild(content, ns.CreateOptionsButton(content, ns.TEXT.OPTIONS_DISABLE_ALL, ns.OPTIONS_LAYOUT.TAB_SIDEBAR_X, buttonY, ns.OPTIONS_LAYOUT.TAB_BUTTON_WIDTH, function()
		ns.SetAllUnitAurasEnabled(not ns.AreAllUnitAurasEnabled())
	end, {
		refresh = function(self)
			self:SetText(ns.AreAllUnitAurasEnabled() and ns.TEXT.OPTIONS_DISABLE_ALL or ns.TEXT.OPTIONS_ENABLE_ALL)
		end,
	}))
	ns.RegisterOptionsChild(content, ns.CreateOptionsButton(content, ns.TEXT.OPTIONS_RESET_DEFAULTS, ns.OPTIONS_LAYOUT.TAB_SIDEBAR_X, buttonY - ns.OPTIONS_LAYOUT.TAB_ACTION_BUTTON_GAP_Y, ns.OPTIONS_LAYOUT.TAB_BUTTON_WIDTH, function()
		confirm_reset_defaults(frame)
	end, {
		refreshDisplays = false,
	}))
	function frame:RefreshFromDB()
		content.ignoreCallbacks = true
		for _, tab in ipairs(content.tabs or {}) do
			tab.ignoreCallbacks = true
		end
		for _, child in ipairs(content.children or {}) do
			if child.RefreshFromDB then
				child:RefreshFromDB()
			end
		end
		for _, tab in ipairs(content.tabs or {}) do
			tab.ignoreCallbacks = false
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

function ns.RefreshOptionsPanel()
	if not panelState.frame then
		return false
	end
	panelState.frame:RefreshFromDB()
	return true
end

function ns.OpenOptionsPanel()
	local frame = ns.EnsureOptionsPanel()
	if Settings and Settings.OpenToCategory and panelState.categoryID then
		Settings.OpenToCategory(panelState.categoryID)
	elseif InterfaceOptionsFrame_OpenToCategory then
		open_legacy_options_category(frame)
	end
end
