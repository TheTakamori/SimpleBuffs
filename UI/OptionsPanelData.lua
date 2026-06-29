SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local copyFromUnitGroupValues = {}

function ns.GetCopyFromUnitGroupValues(groupKey)
	local values = copyFromUnitGroupValues[groupKey] or {}
	copyFromUnitGroupValues[groupKey] = values

	for index = #values, 1, -1 do
		values[index] = nil
	end
	for _, otherGroupKey in ipairs(ns.UNIT_GROUP_ORDER) do
		if otherGroupKey ~= groupKey then
			values[#values + 1] = otherGroupKey
		end
	end
	return values
end

ns.OPTIONS_UNIT_DROPDOWN_COLUMNS = {
	{
		header = ns.TEXT.OPTIONS_MODE,
		values = function(groupKey)
			return ns.GetUnitGroupDisplayModes(groupKey)
		end,
		get = function(groupKey)
			return ns.GetUnitGroupDisplayMode(groupKey)
		end,
		set = function(groupKey, value)
			ns.SetUnitGroupDisplayMode(groupKey, value)
		end,
		labels = ns.DISPLAY_MODE_LABEL,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_MODE,
		refresh = ns.RepaintOptionsDisplays,
	},
	{
		values = ns.ATTACHED_POSITION_ORDER,
		hideLabel = true,
		sameRowAsPrevious = true,
		x = ns.OPTIONS_LAYOUT.TAB_PRIMARY_CONTROL_X + ns.OPTIONS_LAYOUT.TAB_DROPDOWN_WIDTH + ns.OPTIONS_LAYOUT.TAB_INLINE_CONTROL_GAP_X,
		get = function(groupKey)
			return ns.GetUnitGroupAttachedPosition(groupKey)
		end,
		set = function(groupKey, value)
			ns.SetUnitGroupAttachedPosition(groupKey, value)
		end,
		labels = ns.ATTACHED_POSITION_LABEL,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_ATTACHED_POSITION,
		refresh = ns.RepaintOptionsDisplays,
		showWhen = function(groupKey)
			local mode = ns.GetUnitGroupDisplayMode(groupKey)
			return mode == ns.DISPLAY_MODE.ATTACHED or mode == ns.DISPLAY_MODE.BOTH
		end,
	},
	{
		header = ns.TEXT.OPTIONS_LAYOUT,
		perAura = true,
		values = ns.LAYOUT_ORDER,
		get = function(groupKey, auraType)
			return ns.GetUnitGroupLayout(groupKey, auraType)
		end,
		set = function(groupKey, auraType, value)
			ns.SetUnitGroupLayout(groupKey, auraType, value)
		end,
		labels = ns.LAYOUT_LABEL,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_LAYOUT,
		refresh = ns.RepaintOptionsDisplays,
	},
	{
		header = ns.TEXT.OPTIONS_SORT,
		perAura = true,
		values = ns.SORT_RULE_ORDER,
		get = function(groupKey, auraType)
			return ns.GetUnitGroupSortRule(groupKey, auraType)
		end,
		set = function(groupKey, auraType, value)
			ns.SetUnitGroupSortRule(groupKey, auraType, value)
		end,
		labels = ns.SORT_RULE_LABEL,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_SORT,
	},
	{
		header = ns.TEXT.OPTIONS_FILTER,
		perAura = true,
		values = ns.FILTER_MODE_ORDER,
		get = function(groupKey, auraType)
			return ns.GetUnitGroupFilterMode(groupKey, auraType)
		end,
		set = function(groupKey, auraType, value)
			ns.SetUnitGroupFilterMode(groupKey, auraType, value)
		end,
		labels = ns.FILTER_MODE_LABEL,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_FILTER,
	},
}

ns.OPTIONS_STYLE_SLIDERS = {
	{
		text = ns.TEXT.OPTIONS_ICON_SIZE,
		key = ns.DB_KEY.ICON_SIZE,
		perAura = true,
		min = ns.LIMITS.ICON_SIZE_MIN,
		max = ns.LIMITS.ICON_SIZE_MAX,
		step = ns.OPTIONS_LAYOUT.SLIDER_STEP,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_ICON_SIZE,
		refresh = ns.RepaintOptionsDisplays,
	},
	{
		text = ns.TEXT.OPTIONS_SPACING,
		key = ns.DB_KEY.SPACING,
		perAura = true,
		min = ns.LIMITS.SPACING_MIN,
		max = ns.LIMITS.SPACING_MAX,
		step = ns.OPTIONS_LAYOUT.SLIDER_STEP,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_SPACING,
		refresh = ns.RepaintOptionsDisplays,
	},
	{
		text = ns.TEXT.OPTIONS_MAX_AURAS,
		key = ns.DB_KEY.MAX_AURAS,
		perAura = true,
		min = ns.LIMITS.MAX_AURAS_MIN,
		max = ns.LIMITS.MAX_AURAS_MAX,
		step = ns.OPTIONS_LAYOUT.SLIDER_STEP,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_MAX_AURAS,
		refresh = ns.RefreshOptionsDisplays,
	},
	{
		text = ns.TEXT.OPTIONS_SCALE,
		key = ns.DB_KEY.SCALE,
		perAura = true,
		min = ns.LIMITS.SCALE_MIN * ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER,
		max = ns.LIMITS.SCALE_MAX * ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER,
		step = ns.OPTIONS_LAYOUT.SCALE_STEP_PERCENT,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_SCALE,
		refresh = ns.RepaintOptionsDisplays,
		get = function(groupKey, auraType)
			return ns.GetUnitGroupAppearance(groupKey, auraType).scale * ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER
		end,
		set = function(groupKey, auraType, value)
			ns.SetUnitGroupAppearanceValue(groupKey, auraType, ns.DB_KEY.SCALE, value / ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER)
		end,
		format = function(value)
			return tostring(math.floor(value)) .. ns.TEXT.PERCENT
		end,
	},
}

ns.OPTIONS_STYLE_CHECKS = {
	{
		text = ns.TEXT.OPTIONS_SHOW_COUNTDOWN,
		key = ns.DB_KEY.SHOW_COUNTDOWN,
		perAura = true,
		refresh = ns.RepaintOptionsDisplays,
	},
	{
		text = ns.TEXT.OPTIONS_SHOW_SWIPE,
		key = ns.DB_KEY.SHOW_SWIPE,
		perAura = true,
		refresh = ns.RepaintOptionsDisplays,
	},
	{
		text = ns.TEXT.OPTIONS_SHOW_COUNTS,
		key = ns.DB_KEY.SHOW_COUNTS,
		perAura = true,
		refresh = ns.RepaintOptionsDisplays,
	},
}
