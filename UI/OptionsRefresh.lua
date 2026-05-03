SimpleBuffs = SimpleBuffs or {}
local ns = SimpleBuffs

function ns.RefreshOptionsDisplays()
	if ns.RefreshAllDisplays then
		ns.RefreshAllDisplays()
	end
end

function ns.RepaintOptionsDisplays()
	if ns.RepaintAllDisplays then
		ns.RepaintAllDisplays()
	else
		ns.RefreshOptionsDisplays()
	end
end

function ns.RunOptionsRefresh(refresh)
	if refresh == false then
		return
	end
	(refresh or ns.RefreshOptionsDisplays)()
end
