SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local function get_or_create_row(frame, auraType)
	frame.rows = frame.rows or {}
	if frame.rows[auraType] then
		return frame.rows[auraType]
	end

	local row = CreateFrame(ns.UI.FRAME, nil, frame)
	row.buttons = {}
	row.freeButtons = {}
	row.activeKeys = {}
	row.staleKeys = {}
	frame.rows[auraType] = row
	return row
end

local function position_button(button, row, index, size, spacing, layout, style)
	button:ClearAllPoints()
	if style == ns.AURA_STYLE.BAR then
		button:SetPoint(ns.UI.ANCHOR_TOPLEFT, row, ns.UI.ANCHOR_TOPLEFT, ns.LAYOUT_METRIC.ORIGIN_X, -((index - ns.LAYOUT_METRIC.INDEX_OFFSET) * (size + spacing)))
		return
	end
	if layout == ns.LAYOUT.VERTICAL then
		button:SetPoint(ns.UI.ANCHOR_TOPLEFT, row, ns.UI.ANCHOR_TOPLEFT, ns.LAYOUT_METRIC.ORIGIN_X, -((index - ns.LAYOUT_METRIC.INDEX_OFFSET) * (size + spacing)))
	elseif layout == ns.LAYOUT.VERTICAL_REVERSE then
		button:SetPoint(ns.UI.ANCHOR_BOTTOMLEFT, row, ns.UI.ANCHOR_BOTTOMLEFT, ns.LAYOUT_METRIC.ORIGIN_X, (index - ns.LAYOUT_METRIC.INDEX_OFFSET) * (size + spacing))
	elseif layout == ns.LAYOUT.HORIZONTAL_REVERSE then
		button:SetPoint(ns.UI.ANCHOR_TOPRIGHT, row, ns.UI.ANCHOR_TOPRIGHT, -((index - ns.LAYOUT_METRIC.INDEX_OFFSET) * (size + spacing)), ns.LAYOUT_METRIC.ORIGIN_Y)
	else
		button:SetPoint(ns.UI.ANCHOR_TOPLEFT, row, ns.UI.ANCHOR_TOPLEFT, (index - ns.LAYOUT_METRIC.INDEX_OFFSET) * (size + spacing), ns.LAYOUT_METRIC.ORIGIN_Y)
	end
end

local function layout_size(count, size, spacing, layout, style, barWidth)
	if count <= ns.NUMBER.ZERO then
		return ns.LAYOUT_METRIC.MIN_SIZE, size
	end
	if style == ns.AURA_STYLE.BAR then
		return barWidth, count * size + math.max(ns.NUMBER.ZERO, count - ns.LAYOUT_METRIC.INDEX_OFFSET) * spacing
	end
	if layout == ns.LAYOUT.VERTICAL or layout == ns.LAYOUT.VERTICAL_REVERSE then
		return size, count * size + math.max(ns.NUMBER.ZERO, count - ns.LAYOUT_METRIC.INDEX_OFFSET) * spacing
	end
	return count * size + math.max(ns.NUMBER.ZERO, count - ns.LAYOUT_METRIC.INDEX_OFFSET) * spacing, size
end

function ns.UpdateAuraDisplayRow(row, model, appearance, layout)
	local entries = (model and model.rows) or {}
	local size = appearance.iconSize
	local spacing = appearance.spacing
	local style = appearance.style or ns.AURA_STYLE.ICON
	local barWidth = appearance.barWidth or size
	layout = layout or ns.DEFAULTS.appearance.layout
	local width, height = layout_size(#entries, size, spacing, layout, style, barWidth)

	row:SetSize(width, height)

	for key in pairs(row.activeKeys) do
		row.activeKeys[key] = nil
	end
	for index = 1, #entries do
		row.activeKeys[entries[index].key] = true
	end

	row.staleKeys = row.staleKeys or {}
	for index = 1, #row.staleKeys do
		row.staleKeys[index] = nil
	end
	for key in pairs(row.buttons) do
		if not row.activeKeys[key] then
			row.staleKeys[#row.staleKeys + 1] = key
		end
	end
	for index = 1, #row.staleKeys do
		local key = row.staleKeys[index]
		local button = row.buttons[key]
		row.buttons[key] = nil
		button:Hide()
		button.entry = nil
		button.entryKey = nil
		button.unit = nil
		button.auraType = nil
		row.freeButtons[#row.freeButtons + 1] = button
		row.staleKeys[index] = nil
	end

	for index = 1, #entries do
		local entry = entries[index]
		local button = row.buttons[entry.key]
		if not button then
			button = table.remove(row.freeButtons) or ns.CreateAuraButton(row)
			row.buttons[entry.key] = button
		end
		ns.ApplyAuraButton(button, entry, size, appearance)
		position_button(button, row, index, size, spacing, layout, style)
	end

	row:SetShown(#entries > 0)
	return width, height
end

function ns.UpdateAuraDisplayFrame(frame, model)
	local auraType = frame.auraType
	if not auraType then
		return
	end

	local appearance = ns.GetUnitAppearance(frame.unit, auraType)
	local layout = ns.GetUnitLayout(frame.unit, auraType)
	local row = get_or_create_row(frame, auraType)
	local width, height = ns.UpdateAuraDisplayRow(row, model and model[auraType], appearance, layout)
	row:ClearAllPoints()
	row:SetPoint(ns.UI.ANCHOR_TOPLEFT, frame, ns.UI.ANCHOR_TOPLEFT, ns.LAYOUT_METRIC.ORIGIN_X, ns.LAYOUT_METRIC.ORIGIN_Y)
	local totalHeight = ns.LAYOUT_METRIC.ORIGIN_Y
	if row:IsShown() then
		totalHeight = totalHeight + height
	end

	frame:SetScale(appearance.scale)
	frame:EnableMouse(frame.mode == ns.DISPLAY_MODE.STANDALONE and not ns.DB().locked)

	frame:SetSize(math.max(width, ns.DISPLAY_FRAME.MIN_WIDTH), math.max(totalHeight, appearance.iconSize))
end
