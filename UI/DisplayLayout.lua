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

local function position_button(button, row, index, size, spacing, layout)
	button:ClearAllPoints()
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

local function layout_size(count, size, spacing, layout)
	if count <= ns.NUMBER.ZERO then
		return ns.LAYOUT_METRIC.MIN_SIZE, size
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
	layout = layout or ns.DEFAULTS.appearance.layout
	local width, height = layout_size(#entries, size, spacing, layout)

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
		position_button(button, row, index, size, spacing, layout)
	end

	row:SetShown(#entries > 0)
	return width, height
end

function ns.UpdateAuraDisplayFrame(frame, model)
	local appearance = ns.GetUnitAppearance(frame.unit)
	local layout = ns.GetUnitLayout(frame.unit)
	local y = ns.LAYOUT_METRIC.ORIGIN_Y
	local maxWidth = ns.LAYOUT_METRIC.MIN_SIZE
	local totalHeight = ns.LAYOUT_METRIC.ORIGIN_Y

	frame:SetScale(appearance.scale)
	frame:EnableMouse(frame.mode == ns.DISPLAY_MODE.STANDALONE and not ns.DB().locked)

	for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
		local row = get_or_create_row(frame, auraType)
		local width, height = ns.UpdateAuraDisplayRow(row, model and model[auraType], appearance, layout)
		row:ClearAllPoints()
		row:SetPoint(ns.UI.ANCHOR_TOPLEFT, frame, ns.UI.ANCHOR_TOPLEFT, ns.LAYOUT_METRIC.ORIGIN_X, y)
		if row:IsShown() then
			y = y - height - appearance.rowSpacing
			totalHeight = totalHeight + height + appearance.rowSpacing
			if width > maxWidth then
				maxWidth = width
			end
		end
	end

	frame:SetSize(math.max(maxWidth, ns.DISPLAY_FRAME.MIN_WIDTH), math.max(totalHeight, appearance.iconSize))
end
