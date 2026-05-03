SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local DEFAULT_ATTACHED_POSITION = {
	point = "TOPLEFT",
	relativePoint = "BOTTOMLEFT",
	x = 0,
	y = -6,
}

local PARTY_CONTAINER_ATTACHED_POSITION = {
	point = "TOPLEFT",
	relativePoint = "TOPRIGHT",
	x = 8,
	y = 0,
}

local function get_frame_unit(frame)
	if not frame then
		return nil
	end
	if frame.GetAttribute then
		local ok, unit = pcall(frame.GetAttribute, frame, "unit")
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
	if type(memberFrames) == "table" then
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
	local partyFrame = _G["PartyFrame"]
	local compactPartyFrame = _G["CompactPartyFrame"]
	local directAnchors = {
		_G["CompactPartyFrameMember" .. partyIndex],
		_G["PartyMemberFrame" .. partyIndex],
		_G["PartyFrameMember" .. partyIndex],
		partyFrame and partyFrame["MemberFrame" .. partyIndex],
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
			y = PARTY_CONTAINER_ATTACHED_POSITION.y - ((tonumber(partyIndex) or 1) - 1) * 44,
		}
		return containerAnchor, position
	end

	return nil, nil
end

function ns.GetAttachedDisplayAnchor(unit)
	if unit == "player" then
		return _G["PlayerFrame"]
	elseif unit == "target" then
		return _G["TargetFrame"]
	elseif unit == "focus" then
		return _G["FocusFrame"]
	elseif unit == "pet" then
		return _G["PetFrame"]
	end

	local partyIndex = unit:match("^party(%d+)$")
	if partyIndex then
		return get_party_anchor(unit, partyIndex)
	end

	return nil
end

function ns.GetDefaultAttachedPosition()
	return DEFAULT_ATTACHED_POSITION
end
