SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

local simulateEnabledCount = 0
local simulateTicker = nil

function ns.RuntimeEnsure()
	ns.Runtime = ns.Runtime or {}
	ns.Runtime.models = ns.Runtime.models or {}
	ns.Runtime.frames = ns.Runtime.frames or {}
	ns.Runtime.containers = ns.Runtime.containers or {}
	ns.Runtime.dirtyUnits = ns.Runtime.dirtyUnits or {}
	ns.Runtime.dirtyUnitList = ns.Runtime.dirtyUnitList or {}
	ns.Runtime.simulate = ns.Runtime.simulate or {}
	ns.Runtime.simulatePhase = ns.Runtime.simulatePhase or ns.NUMBER.ZERO
	return ns.Runtime
end

-- Simulate is a preview-only toggle: deliberately NOT persisted to
-- SimpleBuffsDB, so it always resets to off on reload/relog rather than
-- risking someone leaving fake auras showing on their live raid frames
-- without noticing.
function ns.IsSimulateEnabled(groupKey, auraType)
	local runtime = ns.RuntimeEnsure()
	return runtime.simulate[groupKey] ~= nil and runtime.simulate[groupKey][auraType] == true
end

-- How far through ns.SIMULATE.GROWTH_FRACTIONS the preview currently is;
-- Core/Scanner.lua's sample-row builder uses this to vary how many sample
-- auras it returns, so Simulate visibly grows and shrinks the display
-- instead of always showing a fixed count.
function ns.GetSimulatePhase()
	return ns.RuntimeEnsure().simulatePhase
end

function ns.AdvanceSimulatePhase()
	local runtime = ns.RuntimeEnsure()
	runtime.simulatePhase = (runtime.simulatePhase + ns.NUMBER.ONE) % #ns.SIMULATE.GROWTH_FRACTIONS
	return runtime.simulatePhase
end

local function refresh_simulated_groups()
	local runtime = ns.RuntimeEnsure()
	for groupKey, auraTypes in pairs(runtime.simulate) do
		local groupHasSimulate = false
		for _, enabled in pairs(auraTypes) do
			if enabled then
				groupHasSimulate = true
				break
			end
		end
		if groupHasSimulate and ns.ForEachUnitInGroup then
			ns.ForEachUnitInGroup(groupKey, function(unit)
				if ns.RefreshAndUpdateUnit then
					ns.RefreshAndUpdateUnit(unit)
				end
			end)
		end
	end
	if ns.LayoutStandaloneContainers then
		ns.LayoutStandaloneContainers()
	end
end

local function stop_simulate_ticker()
	if simulateTicker and simulateTicker.Cancel then
		simulateTicker:Cancel()
	end
	simulateTicker = nil
end

-- C_Timer only exists in the live client, not the plain-Lua test harness;
-- ns.AdvanceSimulatePhase/refresh_simulated_groups stay directly testable
-- without it, and this scheduling wrapper is simply skipped under tests.
local function start_simulate_ticker()
	if simulateTicker or not C_Timer then
		return
	end
	simulateTicker = C_Timer.NewTicker(ns.SIMULATE.TICK_INTERVAL_SECONDS, function()
		ns.AdvanceSimulatePhase()
		refresh_simulated_groups()
	end)
end

function ns.SetSimulateEnabled(groupKey, auraType, enabled)
	local runtime = ns.RuntimeEnsure()
	runtime.simulate[groupKey] = runtime.simulate[groupKey] or {}
	local wasEnabled = runtime.simulate[groupKey][auraType] == true
	local isEnabled = enabled == true
	runtime.simulate[groupKey][auraType] = isEnabled

	if isEnabled and not wasEnabled then
		simulateEnabledCount = simulateEnabledCount + ns.NUMBER.ONE
		runtime.simulatePhase = ns.NUMBER.ZERO
		start_simulate_ticker()
	elseif not isEnabled and wasEnabled then
		simulateEnabledCount = math.max(ns.NUMBER.ZERO, simulateEnabledCount - ns.NUMBER.ONE)
		if simulateEnabledCount == ns.NUMBER.ZERO then
			stop_simulate_ticker()
		end
	end
	return true
end
