SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local function set_count_text(button, entry, appearance)
	if not button.count then
		return
	end
	if not appearance.showCounts then
		button.count:SetText("")
		return
	end

	if entry.applicationDisplayCount then
		button.count:SetText(entry.applicationDisplayCount)
		return
	end

	local applications = entry.aura and entry.aura.applications
	button.count:SetText(applications and tostring(applications) or "")
end

local function set_cooldown(button, entry, appearance)
	button.cooldown:SetHideCountdownNumbers(not appearance.showCountdown)
	button.cooldown:SetDrawSwipe(appearance.showSwipe == true)
	button.cooldown:SetDrawEdge(false)
	if button.cooldown.SetUseAuraDisplayTime then
		button.cooldown:SetUseAuraDisplayTime(true)
	end

	-- In Midnight, aura duration fields can be secret. Retrieve Blizzard's
	-- duration object by non-secret unit/instance ID and pass that to the
	-- cooldown widget instead of reading expirationTime/duration directly.
	if entry.durationObject and button.cooldown.SetCooldownFromDurationObject then
		button.cooldown:SetCooldownFromDurationObject(entry.durationObject, true)
		return
	end

	-- Non-Midnight fallback for local testing on older clients.
	local aura = entry.aura
	local duration = aura.duration
	local expirationTime = aura.expirationTime
	if duration and expirationTime and duration > ns.AURA_BUTTON.FALLBACK_MIN_DURATION then
		button.cooldown:SetCooldown(expirationTime - duration, duration, aura.timeMod or ns.AURA_BUTTON.FALLBACK_MOD_RATE)
	else
		button.cooldown:Clear()
	end
end

local function is_unlocked_standalone_icon(button)
	if ns.DB().locked then
		return false
	end

	local current = button
	while current do
		if current.mode == ns.DISPLAY_MODE.STANDALONE or current.containerKey then
			return true
		end
		current = current.GetParent and current:GetParent()
	end
	return false
end

local function add_standalone_move_tooltip_line(button)
	if not is_unlocked_standalone_icon(button) or not GameTooltip.AddLine then
		return
	end

	local entry = button.entry
	local unitLabel = entry and (ns.UNIT_LABEL[entry.unit] or entry.unit)
	GameTooltip:AddLine(
		ns.TEXT.TOOLTIP_DIVIDER,
		ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_R,
		ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_G,
		ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_B
	)
	if unitLabel then
		GameTooltip:AddLine(
			ns.TEXT.STANDALONE_TOOLTIP_UNIT:format(unitLabel),
			ns.OPTIONS_LAYOUT.TOOLTIP_UNIT_COLOR_R,
			ns.OPTIONS_LAYOUT.TOOLTIP_UNIT_COLOR_G,
			ns.OPTIONS_LAYOUT.TOOLTIP_UNIT_COLOR_B
		)
	end
	GameTooltip:AddLine(
		ns.TEXT.STANDALONE_MOVE_TOOLTIP,
		ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_R,
		ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_G,
		ns.OPTIONS_LAYOUT.TOOLTIP_COLOR_B,
		true
	)
end

local function on_enter(self)
	local entry = self.entry
	if not GameTooltip or not entry then
		return
	end
	GameTooltip:SetOwner(self, ns.UI.ANCHOR_RIGHT)
	if entry.auraType == ns.AURA_TYPE.DEBUFF and GameTooltip.SetUnitDebuffByAuraInstanceID and entry.auraInstanceID then
		GameTooltip:SetUnitDebuffByAuraInstanceID(entry.unit, entry.auraInstanceID, ns.AURA_FILTER[entry.auraType])
	elseif entry.auraType == ns.AURA_TYPE.BUFF and GameTooltip.SetUnitBuffByAuraInstanceID and entry.auraInstanceID then
		GameTooltip:SetUnitBuffByAuraInstanceID(entry.unit, entry.auraInstanceID, ns.AURA_FILTER[entry.auraType])
	else
		GameTooltip:SetText(
			(ns.UNIT_LABEL[entry.unit] or entry.unit) .. ns.TEXT.SPACE .. (ns.AURA_LABEL[entry.auraType] or ns.TEXT.AURA_TOOLTIP_FALLBACK),
			ns.AURA_BUTTON.TOOLTIP_COLOR_R,
			ns.AURA_BUTTON.TOOLTIP_COLOR_G,
			ns.AURA_BUTTON.TOOLTIP_COLOR_B
		)
	end
	add_standalone_move_tooltip_line(self)
	GameTooltip:Show()
end

local function on_leave()
	if GameTooltip then
		GameTooltip:Hide()
	end
end

local function on_drag_start(self)
	if ns.StartStandaloneDrag then
		ns.StartStandaloneDrag(self)
	end
end

local function on_drag_stop(self)
	if ns.StopStandaloneDrag then
		ns.StopStandaloneDrag(self)
	end
end

local function apply_icon(button, aura)
	button.icon:SetTexture(ns.AURA_BUTTON.QUESTION_MARK_ICON)
	if not aura then
		return
	end

	local ok, icon = pcall(function()
		return aura.icon
	end)
	if not ok then
		return
	end

	local iconType = type(icon)
	if iconType == ns.LUA_TYPE.NUMBER or iconType == ns.LUA_TYPE.STRING then
		button.icon:SetTexture(icon)
	end
end

function ns.CreateAuraButton(parent)
	local button = CreateFrame(ns.UI.BUTTON, nil, parent)
	button.icon = button:CreateTexture(nil, ns.UI.BACKGROUND)
	button.icon:SetAllPoints()
	button.icon:SetTexCoord(ns.AURA_BUTTON.TEX_COORD_LEFT, ns.AURA_BUTTON.TEX_COORD_RIGHT, ns.AURA_BUTTON.TEX_COORD_TOP, ns.AURA_BUTTON.TEX_COORD_BOTTOM)

	button.cooldown = CreateFrame(ns.UI.COOLDOWN, nil, button, ns.UI.COOLDOWN_FRAME_TEMPLATE)
	button.cooldown:SetAllPoints()
	button.cooldown:SetReverse(true)

	button.count = button:CreateFontString(nil, ns.UI.OVERLAY, ns.UI.NUMBER_FONT_NORMAL_SMALL)
	button.count:SetPoint(ns.UI.ANCHOR_BOTTOMRIGHT, button, ns.UI.ANCHOR_BOTTOMRIGHT, ns.AURA_BUTTON.COUNT_OFFSET_X, ns.AURA_BUTTON.COUNT_OFFSET_Y)

	button:RegisterForDrag(ns.UI.LEFT_BUTTON)
	button:SetScript(ns.UI.ON_ENTER, on_enter)
	button:SetScript(ns.UI.ON_LEAVE, on_leave)
	button:SetScript(ns.UI.ON_DRAG_START, on_drag_start)
	button:SetScript(ns.UI.ON_DRAG_STOP, on_drag_stop)

	return button
end

function ns.ApplyAuraButton(button, entry, size, appearance)
	button:SetSize(size, size)
	button.entry = entry
	button.entryKey = entry.key
	button.unit = entry.unit
	button.auraType = entry.auraType

	local aura = entry.aura
	apply_icon(button, aura)

	if aura then
		set_cooldown(button, entry, appearance)
	end
	set_count_text(button, entry, appearance)
	button:Show()
end
