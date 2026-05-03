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
local anchorCache = nil
local anchorPositionCache = nil
local anchorCacheDepth = 0
local CACHE_MISS = false

local function create_party_container_position(partyIndex)
	return {
		point = PARTY_CONTAINER_ATTACHED_POSITION.point,
		relativePoint = PARTY_CONTAINER_ATTACHED_POSITION.relativePoint,
		x = PARTY_CONTAINER_ATTACHED_POSITION.x,
		y = PARTY_CONTAINER_ATTACHED_POSITION.y - ((tonumber(partyIndex) or ns.ATTACHED_LAYOUT.PARTY_INDEX_FALLBACK) - ns.LAYOUT_METRIC.INDEX_OFFSET) * ns.ATTACHED_LAYOUT.PARTY_ROW_SPACING,
	}
end

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

local function find_child_match(unit, ...)
	local fallback = nil
	for index = 1, select("#", ...) do
		local child = select(index, ...)
		if frame_matches_unit(child, unit) then
			if frame_is_visible(child) then
				return child
			end
			fallback = fallback or child
		end
	end
	return fallback
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
		return find_child_match(unit, container:GetChildren()) or fallback
	end

	return fallback
end

local function get_party_anchor(unit, partyIndex)
	local partyFrame = _G[ns.BLIZZARD_FRAME.PARTY_FRAME]
	local compactPartyFrame = _G[ns.BLIZZARD_FRAME.COMPACT_PARTY_FRAME]
	local compactRaidFrameContainer = _G[ns.BLIZZARD_FRAME.COMPACT_RAID_FRAME_CONTAINER]
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
				return directAnchor, PARTY_CONTAINER_ATTACHED_POSITION
			end
		end
	end

	local memberAnchor = find_member_frame(compactPartyFrame, unit)
		or find_member_frame(compactRaidFrameContainer, unit)
		or find_member_frame(partyFrame, unit)
	if memberAnchor then
		return memberAnchor, PARTY_CONTAINER_ATTACHED_POSITION
	end

	local containerAnchor = compactPartyFrame or partyFrame
	if containerAnchor and frame_is_visible(containerAnchor) then
		return containerAnchor, create_party_container_position(partyIndex)
	end

	return nil, nil
end

local function get_party_pet_anchor(unit, partyIndex)
	local compactRaidFrameContainer = _G[ns.BLIZZARD_FRAME.COMPACT_RAID_FRAME_CONTAINER]
	local directAnchors = {
		_G[ns.BLIZZARD_FRAME.PARTY_MEMBER_FRAME_PREFIX .. partyIndex .. ns.BLIZZARD_FRAME.PARTY_MEMBER_PET_FRAME_SUFFIX],
	}
	for index = 1, #directAnchors do
		local directAnchor = directAnchors[index]
		if directAnchor and frame_is_visible(directAnchor) then
			local frameUnit = get_frame_unit(directAnchor)
			if not frameUnit or frameUnit == unit then
				return directAnchor, PARTY_CONTAINER_ATTACHED_POSITION
			end
		end
	end

	local memberAnchor = find_member_frame(compactRaidFrameContainer, unit)
	if memberAnchor then
		return memberAnchor, PARTY_CONTAINER_ATTACHED_POSITION
	end
	return nil, nil
end

local function get_compact_raid_anchor(unit)
	return find_member_frame(_G[ns.BLIZZARD_FRAME.COMPACT_RAID_FRAME_CONTAINER], unit), nil
end

local function get_direct_indexed_anchor(prefix, suffix, unit, index)
	local directAnchor = _G[prefix .. index .. (suffix or ns.TEXT.EMPTY)]
	if directAnchor and frame_is_visible(directAnchor) then
		local frameUnit = get_frame_unit(directAnchor)
		if not frameUnit or frameUnit == unit then
			return directAnchor, nil
		end
	end
	return nil, nil
end

local function get_arena_anchor(unit, arenaIndex)
	local anchor = get_direct_indexed_anchor(ns.BLIZZARD_FRAME.ARENA_ENEMY_MATCH_FRAME_PREFIX, nil, unit, arenaIndex)
	if anchor then
		return anchor, nil
	end
	return get_direct_indexed_anchor(ns.BLIZZARD_FRAME.ARENA_ENEMY_FRAME_PREFIX, nil, unit, arenaIndex)
end

local function get_arena_pet_anchor(unit, arenaIndex)
	local anchor = get_direct_indexed_anchor(ns.BLIZZARD_FRAME.ARENA_ENEMY_MATCH_FRAME_PREFIX, ns.BLIZZARD_FRAME.ARENA_ENEMY_PET_FRAME_SUFFIX, unit, arenaIndex)
	if anchor then
		return anchor, nil
	end
	return get_direct_indexed_anchor(ns.BLIZZARD_FRAME.ARENA_ENEMY_FRAME_PREFIX, ns.BLIZZARD_FRAME.ARENA_ENEMY_PET_FRAME_SUFFIX, unit, arenaIndex)
end

local function resolve_attached_display_anchor(unit)
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
	local partyPetIndex = unit:match(ns.PATTERN.PARTY_PET_UNIT)
	if partyPetIndex then
		return get_party_pet_anchor(unit, partyPetIndex)
	end
	local raidIndex = unit:match(ns.PATTERN.RAID_UNIT)
	if raidIndex then
		return get_compact_raid_anchor(unit)
	end
	local raidPetIndex = unit:match(ns.PATTERN.RAID_PET_UNIT)
	if raidPetIndex then
		return get_compact_raid_anchor(unit)
	end
	local bossIndex = unit:match(ns.PATTERN.BOSS_UNIT)
	if bossIndex then
		return get_direct_indexed_anchor(ns.BLIZZARD_FRAME.BOSS_TARGET_FRAME_PREFIX, ns.BLIZZARD_FRAME.BOSS_TARGET_FRAME_SUFFIX, unit, bossIndex)
	end
	local arenaIndex = unit:match(ns.PATTERN.ARENA_UNIT)
	if arenaIndex then
		return get_arena_anchor(unit, arenaIndex)
	end
	local arenaPetIndex = unit:match(ns.PATTERN.ARENA_PET_UNIT)
	if arenaPetIndex then
		return get_arena_pet_anchor(unit, arenaPetIndex)
	end

	return nil
end

function ns.BeginAttachedAnchorCache()
	if anchorCacheDepth > 0 then
		anchorCacheDepth = anchorCacheDepth + 1
		return
	end
	anchorCacheDepth = 1
	anchorCache = anchorCache or {}
	anchorPositionCache = anchorPositionCache or {}
	for unit in pairs(anchorCache) do
		anchorCache[unit] = nil
		anchorPositionCache[unit] = nil
	end
end

function ns.EndAttachedAnchorCache()
	if anchorCacheDepth <= 0 then
		return
	end
	anchorCacheDepth = anchorCacheDepth - 1
	if anchorCacheDepth > 0 then
		return
	end
	anchorCache = nil
	anchorPositionCache = nil
end

function ns.GetAttachedDisplayAnchor(unit)
	if not unit then
		return nil
	end
	if anchorCache and anchorCache[unit] ~= nil then
		local anchor = anchorCache[unit]
		return anchor ~= CACHE_MISS and anchor or nil, anchorPositionCache and anchorPositionCache[unit] or nil
	end

	local anchor, position = resolve_attached_display_anchor(unit)
	if anchorCache then
		anchorCache[unit] = anchor or CACHE_MISS
		anchorPositionCache[unit] = position
	end
	return anchor, position
end

function ns.GetDefaultAttachedPosition()
	return DEFAULT_ATTACHED_POSITION
end
