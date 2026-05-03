SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

function ns.RuntimeEnsure()
	ns.Runtime = ns.Runtime or {}
	ns.Runtime.models = ns.Runtime.models or {}
	ns.Runtime.frames = ns.Runtime.frames or {}
	ns.Runtime.containers = ns.Runtime.containers or {}
	ns.Runtime.dirtyUnits = ns.Runtime.dirtyUnits or {}
	ns.Runtime.dirtyUnitList = ns.Runtime.dirtyUnitList or {}
	return ns.Runtime
end
