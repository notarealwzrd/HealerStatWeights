local name, addon = ...;



--[[----------------------------------------------------------------------------
	CastTracker() - Tracks the number of times the player chain-casted spells
------------------------------------------------------------------------------]]
local CastTracker = {};
local endcast = 0;
local castedSpellID = 0;
local leniancy = 0.33333; --1/3 of a second



--[[----------------------------------------------------------------------------
	IncChainCasts() --update info on current/total segments.
------------------------------------------------------------------------------]]
function CastTracker:IncChainCasts(spellID)
	local cur_seg = addon.SegmentManager:Get(0);
	local ttl_seg = addon.SegmentManager:Get("Total");
	
	if ( cur_seg ) then
		cur_seg:IncChainCasts();
	end
	
	if ( ttl_seg ) then
		ttl_seg:IncChainCasts();
	end
	
	addon.DiscPriest:CHAIN_CAST(spellID);
end



--[[----------------------------------------------------------------------------
	StartCast() - unit_spellcast_start player
------------------------------------------------------------------------------]]
function CastTracker:StartCast(unit,n)
	if ( not addon.inCombat ) then
		return;
	end
	
	local _, _, _, startTimeMS, endTimeMS, _, _, _, spellID = UnitCastingInfo("player");

	local spellInfo = addon.Spells:Get(spellID);
	if ( not spellInfo ) then
		return;
	end
	
	if ( addon.BuffTracker:CompareTimestamps(startTimeMS/1000,endcast,leniancy) ) then
		castedSpellID = spellID;
	end
	endcast = endTimeMS / 1000; --convert ms to s
end



--[[----------------------------------------------------------------------------
	FinishCast() - unit_spellcast_succeeded player
------------------------------------------------------------------------------]]
local casted = {};

function CastTracker:FinishCast(unit,n,spellID,_,a)
	if ( not addon.inCombat ) then
		return;
	end
	
	local curTime = GetTime();
	local flag = false;
	
	local spellInfo = addon.Spells:Get(spellID);
	if ( not spellInfo ) then
		if ( HSW_ENABLE_FOR_TESTING ) then
			if not casted[spellID] then
				addon:Msg("Spellcast Discovered: "..tostring(spellID));
				casted[spellID] = true;
			end
		end
		return;
	end
	
	if ( castedSpellID == spellID ) then 
		--chain cast on casted spell
		self:IncChainCasts(spellID);
		endcast = curTime;
	else
		local start,dur = GetSpellCooldown(spellID);
		if ( start > 0 ) then
			if ( addon.BuffTracker:CompareTimestamps(curTime,endcast,leniancy) ) then
				self:IncChainCasts(spellID);		
			end
			endcast = start+dur;
		else
			endcast = curTime;
		end
	end
	
	if ( castedSpellID ~= 0 ) then
		castedSpellID = 0;
	end
end



addon.CastTracker = CastTracker;