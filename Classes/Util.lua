local name, addon = ...;


--[[----------------------------------------------------------------------------
	Utility functions
------------------------------------------------------------------------------]]
local Util = {};


function Util.HasAuraFromPlayer(unit,auraID)
	for i=1,40,1 do
		local _,_,_,_,_,_,p,_,_,id = UnitAura(unit,i);

		if ( not id ) then
			break;
		elseif (p == "player" and id==auraID) then
			return true;
		end
	end
	return false;
end

function Util.HasAnyAuraFromPlayer(unit,auraList)
	for i=1,40,1 do
		local _,_,_,_,_,_,p,_,_,id = UnitAura(unit,i);

		if ( not id ) then
			break;
		elseif (p == "player" and auraList[id]) then
			return true;
		end
	end
	return false;
end

function Util.CopyTable(t)
	local new_t = {};
	local mt = getmetatable(t);
	for k,v in pairs(t) do new_t[k] = v; end
	setmetatable(new_t,mt);
	return new_t;
end

addon.Util = Util;