SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local QUESTION_MARK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local function set_count_text(button, entry, appearance)
	if not button.count then
		return
	end
	if not appearance.showCounts then
		button.count:SetText("")
		return
	end

	if C_UnitAuras and C_UnitAuras.GetAuraApplicationDisplayCount and entry.auraInstanceID then
		button.count:SetText(C_UnitAuras.GetAuraApplicationDisplayCount(entry.unit, entry.auraInstanceID, 2, 99))
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
	if duration and expirationTime and duration > 0 then
		button.cooldown:SetCooldown(expirationTime - duration, duration, aura.timeMod or 1)
	else
		button.cooldown:Clear()
	end
end

local function on_enter(self)
	local entry = self.entry
	if not GameTooltip or not entry then
		return
	end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if entry.auraType == ns.AURA_TYPE.DEBUFF and GameTooltip.SetUnitDebuffByAuraInstanceID and entry.auraInstanceID then
		GameTooltip:SetUnitDebuffByAuraInstanceID(entry.unit, entry.auraInstanceID, ns.AURA_FILTER[entry.auraType])
	elseif entry.auraType == ns.AURA_TYPE.BUFF and GameTooltip.SetUnitBuffByAuraInstanceID and entry.auraInstanceID then
		GameTooltip:SetUnitBuffByAuraInstanceID(entry.unit, entry.auraInstanceID, ns.AURA_FILTER[entry.auraType])
	else
		GameTooltip:SetText((ns.UNIT_LABEL[entry.unit] or entry.unit) .. " " .. (ns.AURA_LABEL[entry.auraType] or "Aura"), 1, 1, 1)
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
	button.icon:SetTexture(QUESTION_MARK_ICON)
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
	if iconType == "number" or iconType == "string" then
		button.icon:SetTexture(icon)
	end
end

function ns.CreateAuraButton(parent)
	local button = CreateFrame("Button", nil, parent)
	button.icon = button:CreateTexture(nil, "BACKGROUND")
	button.icon:SetAllPoints()
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	button.cooldown:SetAllPoints()
	button.cooldown:SetReverse(true)

	button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)

	button.auraTypeBorder = button:CreateTexture(nil, "BORDER")
	button.auraTypeBorder:SetAllPoints()
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnEnter", on_enter)
	button:SetScript("OnLeave", on_leave)
	button:SetScript("OnDragStart", on_drag_start)
	button:SetScript("OnDragStop", on_drag_stop)

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
		button.auraTypeBorder:SetColorTexture(0.8, 0.2, 0.2, 0.55)
	else
		button.auraTypeBorder:SetColorTexture(0.2, 0.6, 1, 0.35)
	end

	if aura then
		set_cooldown(button, entry, appearance)
	end
	set_count_text(button, entry, appearance)
	button:Show()
end
