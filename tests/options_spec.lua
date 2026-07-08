---@diagnostic disable: undefined-global

local support = require("support")
local assert = support.assert

local function find_column(ns, header)
	for index = 1, #ns.OPTIONS_UNIT_DROPDOWN_COLUMNS do
		local column = ns.OPTIONS_UNIT_DROPDOWN_COLUMNS[index]
		if column.header == header then
			return column
		end
	end
	return nil
end

return function(runner, ns)
	runner:test("RunOptionsRefresh handles defaults custom refresh and no-op", function()
		local refreshCount = 0
		local customCount = 0
		ns.RefreshAllDisplays = function()
			refreshCount = refreshCount + 1
		end

		ns.RunOptionsRefresh(false)
		assert.equal(refreshCount, 0)

		ns.RunOptionsRefresh()
		assert.equal(refreshCount, 1)

		ns.RunOptionsRefresh(function()
			customCount = customCount + 1
		end)
		assert.equal(customCount, 1)
	end)

	runner:test("Attached position metadata only shows for attached-capable modes", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()
		local attachedColumn = find_column(ns, nil)
		assert.equal(attachedColumn ~= nil, true)
		if not attachedColumn then
			return
		end

		assert.equal(attachedColumn.hideLabel, true)
		assert.equal(attachedColumn.sameRowAsPrevious, true)

		ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER, ns.DISPLAY_MODE.STANDALONE)
		assert.equal(attachedColumn.showWhen(ns.UNIT_GROUP.PLAYER), false)

		ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER, ns.DISPLAY_MODE.ATTACHED)
		assert.equal(attachedColumn.showWhen(ns.UNIT_GROUP.PLAYER), true)

		ns.SetUnitGroupDisplayMode(ns.UNIT_GROUP.PLAYER, ns.DISPLAY_MODE.BOTH)
		assert.equal(attachedColumn.showWhen(ns.UNIT_GROUP.PLAYER), true)
	end)

	runner:test("Style column exists and Layout/Sort/Bar Sort/Bar Anchor hide based on style", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		local styleColumn = find_column(ns, ns.TEXT.OPTIONS_STYLE)
		assert.equal(styleColumn ~= nil, true)

		local layoutColumn = find_column(ns, ns.TEXT.OPTIONS_LAYOUT)
		local sortColumn = find_column(ns, ns.TEXT.OPTIONS_SORT)
		local barSortColumn = find_column(ns, ns.TEXT.OPTIONS_BAR_SORT)
		local barAnchorColumn = find_column(ns, ns.TEXT.OPTIONS_BAR_ANCHOR)
		assert.equal(layoutColumn ~= nil, true)
		assert.equal(sortColumn ~= nil, true)
		assert.equal(barSortColumn ~= nil, true)
		assert.equal(barAnchorColumn ~= nil, true)

		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.ICON)
		assert.equal(layoutColumn.showWhen(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), true)
		assert.equal(sortColumn.showWhen(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), true)
		assert.equal(barSortColumn.showWhen(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), false)
		assert.equal(barAnchorColumn.showWhen(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), false)

		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)
		assert.equal(layoutColumn.showWhen(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), false)
		assert.equal(sortColumn.showWhen(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), false)
		assert.equal(barSortColumn.showWhen(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), true)
		assert.equal(barAnchorColumn.showWhen(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), true)
	end)

	runner:test("Bar Width slider and Show Swipe check hide based on style", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		local barWidthSlider
		for index = 1, #ns.OPTIONS_STYLE_SLIDERS do
			if ns.OPTIONS_STYLE_SLIDERS[index].key == ns.DB_KEY.BAR_WIDTH then
				barWidthSlider = ns.OPTIONS_STYLE_SLIDERS[index]
			end
		end
		assert.equal(barWidthSlider ~= nil, true)

		local showSwipeCheck
		for index = 1, #ns.OPTIONS_STYLE_CHECKS do
			if ns.OPTIONS_STYLE_CHECKS[index].key == ns.DB_KEY.SHOW_SWIPE then
				showSwipeCheck = ns.OPTIONS_STYLE_CHECKS[index]
			end
		end
		assert.equal(showSwipeCheck ~= nil, true)

		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.ICON)
		assert.equal(barWidthSlider.showWhen(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), false)
		assert.equal(showSwipeCheck.showWhen(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), true)

		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)
		assert.equal(barWidthSlider.showWhen(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), true)
		assert.equal(showSwipeCheck.showWhen(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), false)
	end)

	runner:test("Show Icon check only shows for bar style", function()
		_G.SimpleBuffsDB = nil
		ns.InitDB()

		local showIconCheck
		for index = 1, #ns.OPTIONS_STYLE_CHECKS do
			if ns.OPTIONS_STYLE_CHECKS[index].key == ns.DB_KEY.SHOW_ICON then
				showIconCheck = ns.OPTIONS_STYLE_CHECKS[index]
			end
		end
		assert.equal(showIconCheck ~= nil, true)

		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.ICON)
		assert.equal(showIconCheck.showWhen(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), false)

		ns.SetUnitGroupStyle(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF, ns.AURA_STYLE.BAR)
		assert.equal(showIconCheck.showWhen(ns.UNIT_GROUP.PLAYER, ns.AURA_TYPE.BUFF), true)
	end)

	runner:test("Layout/Bar Sort and Show Swipe/Show Icon pair onto shared rows", function()
		local layoutColumn = find_column(ns, ns.TEXT.OPTIONS_LAYOUT)
		local barSortColumn = find_column(ns, ns.TEXT.OPTIONS_BAR_SORT)
		local sortColumn = find_column(ns, ns.TEXT.OPTIONS_SORT)
		local barAnchorColumn = find_column(ns, ns.TEXT.OPTIONS_BAR_ANCHOR)
		local filterColumn = find_column(ns, ns.TEXT.OPTIONS_FILTER)
		local styleColumn = find_column(ns, ns.TEXT.OPTIONS_STYLE)

		-- Layout and Bar Sort are mutually exclusive (icon vs bar style), so
		-- they must share the exact same row/x slot instead of stacking.
		assert.equal(barSortColumn.sameRowAsPrevious, true)
		assert.equal(barSortColumn.x, layoutColumn.x)

		-- Sort and Bar Anchor are mutually exclusive (icon vs bar style), so
		-- they must share the secondary column's row/x slot instead of stacking.
		assert.equal(sortColumn.sameRowAsPrevious, true)
		assert.equal(sortColumn.x, ns.OPTIONS_LAYOUT.TAB_SECONDARY_CONTROL_X)
		assert.equal(barAnchorColumn.sameRowAsPrevious, true)
		assert.equal(barAnchorColumn.x, ns.OPTIONS_LAYOUT.TAB_SECONDARY_CONTROL_X)
		assert.equal(filterColumn.sameRowAsPrevious, true)
		assert.equal(filterColumn.x, ns.OPTIONS_LAYOUT.TAB_SECONDARY_CONTROL_X)
		assert.equal(styleColumn.sameRowAsPrevious, nil)

		local showSwipeCheck
		local showIconCheck
		for index = 1, #ns.OPTIONS_STYLE_CHECKS do
			if ns.OPTIONS_STYLE_CHECKS[index].key == ns.DB_KEY.SHOW_SWIPE then
				showSwipeCheck = ns.OPTIONS_STYLE_CHECKS[index]
			elseif ns.OPTIONS_STYLE_CHECKS[index].key == ns.DB_KEY.SHOW_ICON then
				showIconCheck = ns.OPTIONS_STYLE_CHECKS[index]
			end
		end
		assert.equal(showSwipeCheck.x, showIconCheck.x)
		assert.equal(showIconCheck.sameRowAsPrevious, true)
	end)

	runner:test("Copy From values include other unit groups only", function()
		local values = ns.GetCopyFromUnitGroupValues(ns.UNIT_GROUP.PLAYER)

		assert.equal(ns.IsKnownValue(values, ns.UNIT_GROUP.PLAYER), false)
		assert.equal(ns.IsKnownValue(values, ns.UNIT_GROUP.PET), true)
		assert.equal(#values, #ns.UNIT_GROUP_ORDER - 1)
	end)
end
