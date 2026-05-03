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

	if C_UnitAuras and C_UnitAuras.GetAuraApplicationDisplayCount and entry.auraInstanceID then
		button.count:SetText(C_UnitAuras.GetAuraApplicationDisplayCount(entry.unit, entry.auraInstanceID, ns.AURA_BUTTON.COUNT_MIN, ns.AURA_BUTTON.COUNT_MAX))
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
	if C_UnitAuras and C_UnitAuras.GetAuraDuration and button.cooldown.SetCooldownFromDurationObject and entry.auraInstanceID then
		button.cooldown:SetCooldownFromDurationObject(C_UnitAuras.GetAuraDuration(entry.unit, entry.auraInstanceID), true)
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

	button.auraTypeBorder = button:CreateTexture(nil, ns.UI.BORDER)
	button.auraTypeBorder:SetAllPoints()
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
	if entry.auraType == ns.AURA_TYPE.DEBUFF then
		button.auraTypeBorder:SetColorTexture(ns.AURA_BUTTON.DEBUFF_BORDER_R, ns.AURA_BUTTON.DEBUFF_BORDER_G, ns.AURA_BUTTON.DEBUFF_BORDER_B, ns.AURA_BUTTON.DEBUFF_BORDER_A)
	else
		button.auraTypeBorder:SetColorTexture(ns.AURA_BUTTON.BUFF_BORDER_R, ns.AURA_BUTTON.BUFF_BORDER_G, ns.AURA_BUTTON.BUFF_BORDER_B, ns.AURA_BUTTON.BUFF_BORDER_A)
	end

	if aura then
		set_cooldown(button, entry, appearance)
	end
	set_count_text(button, entry, appearance)
	button:Show()
end
