SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local MANAGED_FRAME_NAMES = {
	ns.BLIZZARD_FRAME.PLAYER_BUFF_FRAME,
	ns.BLIZZARD_FRAME.TEMPORARY_ENCHANT_FRAME,
}

local hookedFrameNames = {}

local function apply_frame_visibility(frame, hide)
	if hide then
		frame:Hide()
	elseif not frame:IsShown() then
		frame:Show()
	end
end

-- HookScript (not SetScript) adds our handler alongside Blizzard's own OnShow
-- logic instead of replacing it, so Blizzard's own frame setup still runs;
-- we just immediately re-hide afterward whenever the setting calls for it.
-- Blizzard shows these frames again on its own in response to game state
-- (entering combat, zoning, aura changes, etc.), so a one-time Hide() alone
-- would not stay hidden.
local function ensure_hook(frameName, frame)
	if hookedFrameNames[frameName] then
		return
	end
	hookedFrameNames[frameName] = true
	frame:HookScript(ns.UI.ON_SHOW, function(self)
		if ns.IsBlizzardPlayerBuffsHidden() then
			self:Hide()
		end
	end)
end

function ns.RefreshBlizzardPlayerBuffsVisibility()
	local hide = ns.IsBlizzardPlayerBuffsHidden()
	for index = 1, #MANAGED_FRAME_NAMES do
		local frameName = MANAGED_FRAME_NAMES[index]
		local frame = _G[frameName]
		if frame then
			ensure_hook(frameName, frame)
			apply_frame_visibility(frame, hide)
		end
	end
end
