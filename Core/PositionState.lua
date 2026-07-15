SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

function ns.SetLocked(locked)
	ns.DB().locked = locked == true
	return ns.DB().locked
end

function ns.ToggleLocked()
	return ns.SetLocked(not ns.DB().locked)
end

function ns.GetAttachedPosition(unit)
	return ns.DB().attached[unit]
end

-- Rounded to whole pixels before storing: SetPoint offsets are read back
-- through GetLeft/GetTop math (see pin_container_edge in UI/Display.lua)
-- on every login, and fractional offsets survive that round-trip less
-- reliably the lower a player's UI Scale is (each virtual unit covers more
-- real screen pixels, so sub-pixel remainders become visible drift).
local ROUND_HALF = 0.5

local function round(value)
	return value and math.floor(value + ROUND_HALF) or value
end

function ns.SaveStandalonePosition(unit, frame)
	if not frame or not ns.DB().standalone[unit] then
		return
	end
	local point, _, relativePoint, x, y = frame:GetPoint(ns.NUMBER.ONE)
	if not point then
		return
	end
	local saved = ns.DB().standalone[unit]
	saved.point = point
	saved.relativePoint = relativePoint or point
	saved.x = round(x) or ns.NUMBER.ZERO
	saved.y = round(y) or ns.NUMBER.ZERO
end

function ns.GetMinimapButtonAngle()
	return ns.DB().minimap.angle
end

function ns.SetMinimapButtonAngle(angle)
	ns.DB().minimap.angle = ns.Clamp(angle, ns.NUMBER.ZERO, ns.MINIMAP_MATH.FULL_CIRCLE_DEGREES, ns.DEFAULTS.minimap.angle)
	return ns.DB().minimap.angle
end

function ns.IsMinimapButtonHidden()
	return ns.DB().minimap.hide == true
end

function ns.SetMinimapButtonHidden(hidden)
	ns.DB().minimap.hide = hidden == true
	return ns.DB().minimap.hide
end
