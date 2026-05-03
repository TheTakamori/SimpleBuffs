SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local function get_or_create_row(frame, auraType)
	frame.rows = frame.rows or {}
	if frame.rows[auraType] then
		return frame.rows[auraType]
	end

	local row = CreateFrame("Frame", nil, frame)
	row.buttons = {}
	frame.rows[auraType] = row
	return row
end

local function position_button(button, row, index, size, spacing, layout)
	button:ClearAllPoints()
	if layout == ns.LAYOUT.VERTICAL then
		button:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -((index - 1) * (size + spacing)))
	elseif layout == ns.LAYOUT.VERTICAL_REVERSE then
		button:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, (index - 1) * (size + spacing))
	elseif layout == ns.LAYOUT.HORIZONTAL_REVERSE then
		button:SetPoint("TOPRIGHT", row, "TOPRIGHT", -((index - 1) * (size + spacing)), 0)
	else
		button:SetPoint("TOPLEFT", row, "TOPLEFT", (index - 1) * (size + spacing), 0)
	end
end

local function layout_size(count, size, spacing, layout)
	if count <= 0 then
		return 1, size
	end
	if layout == ns.LAYOUT.VERTICAL or layout == ns.LAYOUT.VERTICAL_REVERSE then
		return size, count * size + math.max(0, count - 1) * spacing
	end
	return count * size + math.max(0, count - 1) * spacing, size
end

function ns.UpdateAuraDisplayRow(row, model, appearance)
	local entries = (model and model.rows) or {}
	local size = appearance.iconSize
	local spacing = appearance.spacing
	local layout = appearance.layout
	local width, height = layout_size(#entries, size, spacing, layout)

	row:SetSize(width, height)

	for _, button in pairs(row.buttons) do
		button.unused = true
	end

	for index = 1, #entries do
		local entry = entries[index]
		local button = row.buttons[entry.key]
		if not button then
			button = ns.CreateAuraButton(row)
			row.buttons[entry.key] = button
		end
		button.unused = nil
		ns.ApplyAuraButton(button, entry, size, appearance)
		position_button(button, row, index, size, spacing, layout)
	end

	for _, button in pairs(row.buttons) do
		if button.unused then
			button:Hide()
			button.unused = nil
		end
	end

	row:SetShown(#entries > 0)
	return width, height
end

function ns.UpdateAuraDisplayFrame(frame, model)
	local appearance = ns.GetAppearance()
	local y = 0
	local maxWidth = 1
	local totalHeight = 0

	frame:SetScale(appearance.scale)
	frame:EnableMouse(frame.mode == ns.DISPLAY_MODE.STANDALONE and not ns.DB().locked)

	for _, auraType in ipairs(ns.AURA_TYPE_ORDER) do
		local row = get_or_create_row(frame, auraType)
		local width, height = ns.UpdateAuraDisplayRow(row, model and model[auraType], appearance)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, y)
		if row:IsShown() then
			y = y - height - appearance.rowSpacing
			totalHeight = totalHeight + height + appearance.rowSpacing
			if width > maxWidth then
				maxWidth = width
			end
		end
	end

	frame:SetSize(math.max(maxWidth, 64), math.max(totalHeight, appearance.iconSize))
end
