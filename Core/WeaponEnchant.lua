SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

-- Temporary weapon enchants (weapon oils/stones, Windfury Weapon, etc.) never
-- come from UnitAura/C_UnitAuras - Blizzard only exposes them through
-- GetWeaponEnchantInfo(), a completely separate, player-only API with no
-- name field and no total-duration field (only milliseconds remaining), so
-- they can't flow through Core/Scanner.lua's normal scan path unmodified.
-- This builds synthetic rows shaped like the real ones so they can be
-- appended into the player's Buff scan and rendered by the existing
-- Icon/Bar Stack pipeline as-is.

local MAINHAND_SLOT = _G.INVSLOT_MAINHAND or 16
local OFFHAND_SLOT = _G.INVSLOT_OFFHAND or 17
local MS_PER_SECOND = 1000
-- How much later than the cached window's own expiration a freshly reported
-- remaining time may fall before it's treated as scan jitter rather than a
-- genuine reapplication. Small and only needs to absorb sub-frame timing
-- noise between GetTime() and the live GetWeaponEnchantInfo() read.
local REAPPLY_SLACK_SECONDS = 2

ns.WEAPON_ENCHANT_INSTANCE_ID = {
	MAINHAND = -1,
	OFFHAND = -2,
}

-- Resolved via a tooltip line match (see resolve_enchant_name below), keyed
-- by enchant ID so the lookup only runs once per distinct enchant rather
-- than on every refresh while it's active.
local nameByEnchantID = {}

-- Each slot's currently-tracked application window, keyed by slot key (see
-- resolve_window below).
local appliedWindow = {}

local SLOT_INFO = {
	mainhand = { slot = MAINHAND_SLOT, instanceID = ns.WEAPON_ENCHANT_INSTANCE_ID.MAINHAND, fallbackName = "Main-Hand Enchant" },
	offhand = { slot = OFFHAND_SLOT, instanceID = ns.WEAPON_ENCHANT_INSTANCE_ID.OFFHAND, fallbackName = "Off-Hand Enchant" },
}

-- The negative sentinel instanceIDs above aren't real aura instance IDs, so
-- GameTooltip:SetUnitBuffByAuraInstanceID (which expects an actual uint32
-- from C_UnitAuras) rejects them outright. UI/AuraButton.lua uses this to
-- fall back to GameTooltip:SetInventoryItem on the enchanted weapon instead -
-- the same tooltip Blizzard's own default UI shows for these buffs.
ns.WEAPON_ENCHANT_SLOT_BY_INSTANCE_ID = {
	[SLOT_INFO.mainhand.instanceID] = SLOT_INFO.mainhand.slot,
	[SLOT_INFO.offhand.instanceID] = SLOT_INFO.offhand.slot,
}

local function enchanted_line_pattern()
	local template = _G.ENCHANTED_TOOLTIP_LINE or "Enchanted: %s"
	return "^" .. template:gsub("%%s", "(.+)") .. "$"
end

-- C_TooltipInfo.GetInventoryItem returns structured tooltip line data
-- without needing a hidden GameTooltip widget. The enchant's own display
-- name isn't exposed by any other API, so this is the only way to show the
-- real oil/stone name instead of a generic "Main-Hand Enchant" fallback.
local function resolve_enchant_name(slot, enchantID, fallback)
	if not enchantID then
		return fallback
	end
	local cached = nameByEnchantID[enchantID]
	if cached then
		return cached
	end
	if not C_TooltipInfo or not C_TooltipInfo.GetInventoryItem then
		return fallback
	end
	local ok, tooltipData = pcall(C_TooltipInfo.GetInventoryItem, ns.UNIT_TOKEN.PLAYER, slot)
	if not ok or not tooltipData or not tooltipData.lines then
		return fallback
	end
	local pattern = enchanted_line_pattern()
	for index = 1, #tooltipData.lines do
		local text = tooltipData.lines[index] and tooltipData.lines[index].leftText
		if type(text) == ns.LUA_TYPE.STRING then
			local matched = text:match(pattern)
			if matched then
				nameByEnchantID[enchantID] = matched
				return matched
			end
		end
	end
	return fallback
end

-- GetWeaponEnchantInfo only ever reports milliseconds remaining, never the
-- enchant's original total duration, so there's no way to know how much of
-- it has already elapsed. Cache each application's own (appliedAt,
-- expirationTime) window the first time it's seen, so re-scanning the same
-- still-active application - which happens on every player buff refresh,
-- not just when the enchant itself changes - keeps reusing the same
-- cooldown window instead of restarting the countdown from "full" on every
-- refresh. A freshly reported remaining time noticeably larger than what
-- the cached window predicts means the enchant was (re)applied, so the
-- window is recomputed.
local function resolve_window(slotKey, enchantID, remainingMs)
	local now = GetTime and GetTime() or ns.NUMBER.ZERO
	local remaining = (remainingMs or ns.NUMBER.ZERO) / MS_PER_SECOND
	local cached = appliedWindow[slotKey]
	if cached and cached.enchantID == enchantID and (now + remaining) <= (cached.expirationTime + REAPPLY_SLACK_SECONDS) then
		return cached
	end
	cached = { enchantID = enchantID, appliedAt = now, expirationTime = now + remaining }
	appliedWindow[slotKey] = cached
	return cached
end

local function build_row(slotKey, hasEnchant, expirationMs, charges, enchantID)
	local info = SLOT_INFO[slotKey]
	if not hasEnchant then
		appliedWindow[slotKey] = nil
		return nil
	end

	local window = resolve_window(slotKey, enchantID, expirationMs)
	local ok, icon = pcall(GetInventoryItemTexture, ns.UNIT_TOKEN.PLAYER, info.slot)
	local hasCharges = type(charges) == ns.LUA_TYPE.NUMBER and charges > ns.NUMBER.ZERO

	return {
		unit = ns.UNIT_TOKEN.PLAYER,
		auraType = ns.AURA_TYPE.BUFF,
		auraInstanceID = info.instanceID,
		applicationDisplayCount = hasCharges and charges or nil,
		aura = {
			name = resolve_enchant_name(info.slot, enchantID, info.fallbackName),
			icon = (ok and icon) or ns.AURA_BUTTON.QUESTION_MARK_ICON,
			duration = window.expirationTime - window.appliedAt,
			expirationTime = window.expirationTime,
			applications = hasCharges and charges or ns.NUMBER.ONE,
			spellId = enchantID,
			timeMod = ns.AURA_BUTTON.FALLBACK_MOD_RATE,
		},
	}
end

-- Weapon enchants aren't gated by Filter Mode (Player/Important/Crowd
-- Control) the way real HELPFUL auras are - they're inherently the
-- player's own effect - so they're appended unconditionally whenever the
-- player's Buffs are enabled, independent of that setting.
function ns.ScanWeaponEnchantRows()
	if not GetWeaponEnchantInfo then
		return {}
	end
	local ok, hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID =
		pcall(GetWeaponEnchantInfo)
	if not ok then
		return {}
	end

	local rows = {}
	local mainRow = build_row("mainhand", hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID)
	if mainRow then
		rows[#rows + 1] = mainRow
	end
	local offRow = build_row("offhand", hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID)
	if offRow then
		rows[#rows + 1] = offRow
	end
	return rows
end
