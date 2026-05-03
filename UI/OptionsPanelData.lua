SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

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
		values = ns.LAYOUT_ORDER,
		get = function(groupKey)
			return ns.GetUnitGroupLayout(groupKey)
		end,
		set = function(groupKey, value)
			ns.SetUnitGroupLayout(groupKey, value)
		end,
		labels = ns.LAYOUT_LABEL,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_LAYOUT,
		refresh = ns.RepaintOptionsDisplays,
	},
	{
		header = ns.TEXT.OPTIONS_SORT,
		values = ns.SORT_RULE_ORDER,
		get = function(groupKey)
			return ns.GetUnitGroupSortRule(groupKey)
		end,
		set = function(groupKey, value)
			ns.SetUnitGroupSortRule(groupKey, value)
		end,
		labels = ns.SORT_RULE_LABEL,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_SORT,
	},
	{
		header = ns.TEXT.OPTIONS_FILTER,
		values = ns.FILTER_MODE_ORDER,
		get = function(groupKey)
			return ns.GetUnitGroupFilterMode(groupKey)
		end,
		set = function(groupKey, value)
			ns.SetUnitGroupFilterMode(groupKey, value)
		end,
		labels = ns.FILTER_MODE_LABEL,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_FILTER,
	},
}

ns.OPTIONS_STYLE_SLIDERS = {
	{
		text = ns.TEXT.OPTIONS_ICON_SIZE,
		key = ns.DB_KEY.ICON_SIZE,
		min = ns.LIMITS.ICON_SIZE_MIN,
		max = ns.LIMITS.ICON_SIZE_MAX,
		step = ns.OPTIONS_LAYOUT.SLIDER_STEP,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_ICON_SIZE,
		refresh = ns.RepaintOptionsDisplays,
	},
	{
		text = ns.TEXT.OPTIONS_SPACING,
		key = ns.DB_KEY.SPACING,
		min = ns.LIMITS.SPACING_MIN,
		max = ns.LIMITS.SPACING_MAX,
		step = ns.OPTIONS_LAYOUT.SLIDER_STEP,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_SPACING,
		refresh = ns.RepaintOptionsDisplays,
	},
	{
		text = ns.TEXT.OPTIONS_MAX_AURAS,
		key = ns.DB_KEY.MAX_AURAS,
		min = ns.LIMITS.MAX_AURAS_MIN,
		max = ns.LIMITS.MAX_AURAS_MAX,
		step = ns.OPTIONS_LAYOUT.SLIDER_STEP,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_MAX_AURAS,
		refresh = ns.RefreshOptionsDisplays,
	},
	{
		text = ns.TEXT.OPTIONS_SCALE,
		key = ns.DB_KEY.SCALE,
		min = ns.LIMITS.SCALE_MIN * ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER,
		max = ns.LIMITS.SCALE_MAX * ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER,
		step = ns.OPTIONS_LAYOUT.SCALE_STEP_PERCENT,
		tooltip = ns.TEXT.OPTIONS_TOOLTIP_SCALE,
		refresh = ns.RepaintOptionsDisplays,
		get = function(groupKey)
			return ns.GetUnitGroupAppearance(groupKey).scale * ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER
		end,
		set = function(groupKey, value)
			ns.SetUnitGroupAppearanceValue(groupKey, ns.DB_KEY.SCALE, value / ns.OPTIONS_LAYOUT.PERCENT_MULTIPLIER)
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
		refresh = ns.RepaintOptionsDisplays,
	},
	{
		text = ns.TEXT.OPTIONS_SHOW_SWIPE,
		key = ns.DB_KEY.SHOW_SWIPE,
		refresh = ns.RepaintOptionsDisplays,
	},
	{
		text = ns.TEXT.OPTIONS_SHOW_COUNTS,
		key = ns.DB_KEY.SHOW_COUNTS,
		refresh = ns.RepaintOptionsDisplays,
	},
}
