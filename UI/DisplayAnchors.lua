SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local DEFAULT_ATTACHED_POSITION = {
	point = ns.UI.ANCHOR_TOPLEFT,
	relativePoint = ns.UI.ANCHOR_BOTTOMLEFT,
	x = ns.ATTACHED_LAYOUT.DEFAULT_X,
	y = ns.ATTACHED_LAYOUT.DEFAULT_Y,
}

local PARTY_CONTAINER_ATTACHED_POSITION = {
	point = ns.UI.ANCHOR_TOPLEFT,
	relativePoint = ns.UI.ANCHOR_TOPRIGHT,
	x = ns.ATTACHED_LAYOUT.PARTY_CONTAINER_X,
	y = ns.ATTACHED_LAYOUT.PARTY_CONTAINER_Y,
}

local function get_frame_unit(frame)
	if not frame then
		return nil
	end
	if frame.GetAttribute then
		local ok, unit = pcall(frame.GetAttribute, frame, ns.FRAME_ATTR.UNIT)
		if ok and unit then
			return unit
		end
	end
	return frame.unit or frame.displayedUnit or frame.unitToken
end

local function frame_matches_unit(frame, unit)
	return get_frame_unit(frame) == unit
end

local function frame_is_visible(frame)
	if not frame then
		return false
	end
	if frame.IsVisible then
		local ok, visible = pcall(frame.IsVisible, frame)
		if ok then
			return visible == true
		end
	end
	if frame.IsShown then
		local ok, shown = pcall(frame.IsShown, frame)
		if ok then
			return shown == true
		end
	end
	return true
end

local function find_member_frame(container, unit)
	if not container then
		return nil
	end

	local fallback = nil
	local memberFrames = container.memberUnitFrames or container.MemberFrames
	if type(memberFrames) == ns.LUA_TYPE.TABLE then
		for _, memberFrame in pairs(memberFrames) do
			if frame_matches_unit(memberFrame, unit) then
				if frame_is_visible(memberFrame) then
					return memberFrame
				end
				fallback = fallback or memberFrame
			end
		end
	end

	if container.GetChildren then
		local children = { container:GetChildren() }
		for index = 1, #children do
			local child = children[index]
			if frame_matches_unit(child, unit) then
				if frame_is_visible(child) then
					return child
				end
				fallback = fallback or child
			end
		end
	end

	return fallback
end

local function get_party_anchor(unit, partyIndex)
	local partyFrame = _G[ns.BLIZZARD_FRAME.PARTY_FRAME]
	local compactPartyFrame = _G[ns.BLIZZARD_FRAME.COMPACT_PARTY_FRAME]
	local directAnchors = {
		_G[ns.BLIZZARD_FRAME.COMPACT_PARTY_FRAME_MEMBER_PREFIX .. partyIndex],
		_G[ns.BLIZZARD_FRAME.PARTY_MEMBER_FRAME_PREFIX .. partyIndex],
		_G[ns.BLIZZARD_FRAME.PARTY_FRAME_MEMBER_PREFIX .. partyIndex],
		partyFrame and partyFrame[ns.BLIZZARD_FRAME.MEMBER_FRAME_PREFIX .. partyIndex],
	}
	for index = 1, #directAnchors do
		local directAnchor = directAnchors[index]
		if directAnchor and frame_is_visible(directAnchor) then
			local frameUnit = get_frame_unit(directAnchor)
			if not frameUnit or frameUnit == unit then
				return directAnchor, nil
			end
		end
	end

	local memberAnchor = find_member_frame(compactPartyFrame, unit)
		or find_member_frame(partyFrame, unit)
	if memberAnchor then
		return memberAnchor, nil
	end

	local containerAnchor = compactPartyFrame or partyFrame
	if containerAnchor and frame_is_visible(containerAnchor) then
		local position = {
			point = PARTY_CONTAINER_ATTACHED_POSITION.point,
			relativePoint = PARTY_CONTAINER_ATTACHED_POSITION.relativePoint,
			x = PARTY_CONTAINER_ATTACHED_POSITION.x,
			y = PARTY_CONTAINER_ATTACHED_POSITION.y - ((tonumber(partyIndex) or ns.ATTACHED_LAYOUT.PARTY_INDEX_FALLBACK) - ns.LAYOUT_METRIC.INDEX_OFFSET) * ns.ATTACHED_LAYOUT.PARTY_ROW_SPACING,
		}
		return containerAnchor, position
	end

	return nil, nil
end

function ns.GetAttachedDisplayAnchor(unit)
	if unit == ns.UNIT_TOKEN.PLAYER then
		return _G[ns.BLIZZARD_FRAME.PLAYER_FRAME]
	elseif unit == ns.UNIT_TOKEN.TARGET then
		return _G[ns.BLIZZARD_FRAME.TARGET_FRAME]
	elseif unit == ns.UNIT_TOKEN.FOCUS then
		return _G[ns.BLIZZARD_FRAME.FOCUS_FRAME]
	elseif unit == ns.UNIT_TOKEN.PET then
		return _G[ns.BLIZZARD_FRAME.PET_FRAME]
	end

	local partyIndex = unit:match(ns.PATTERN.PARTY_UNIT)
	if partyIndex then
		return get_party_anchor(unit, partyIndex)
	end

	return nil
end

function ns.GetDefaultAttachedPosition()
	return DEFAULT_ATTACHED_POSITION
end
