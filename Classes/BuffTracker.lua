local name, addon = ...;
addon.TimestampDelta = 0.050; --50ms



--[[----------------------------------------------------------------------------
	BuffTracker() - More effecient way of tracking buff/debuff on the player than 
				  querying on every healing event.
------------------------------------------------------------------------------]]
local BuffTracker = {};



--[[----------------------------------------------------------------------------
	Track() - start tracking the stackcount of this buff/debuff on the player
------------------------------------------------------------------------------]]
function BuffTracker:Track(spellId,fApply,fExpires)
	self[spellId] = {
		expiration = 0;
		stacks = 0;
		onApply = fApply or nil;
		onExpires = fExpires or nil;
	}
end



--[[----------------------------------------------------------------------------
	CompareTimestamps() - check if two events happened at the same time (Uses a small buffer window).
------------------------------------------------------------------------------]]
function BuffTracker:CompareTimestamps(ts1,ts2,leniancy)
	ts1 = ts1 or 0;
	ts2 = ts2 or 0;
	
	local leniancy = leniancy or addon.TimestampDelta;
	
	if ( ts1 > 0 and ts2 > 0 and math.abs(ts1-ts2) <= leniancy ) then
		return true;
	end
	return false;
end



--[[----------------------------------------------------------------------------
	UpdatePlayerBuffs() - Called on "UNIT_AURA" "Player", updates the stackcount of 
					    tracked buffs/debuffs.
------------------------------------------------------------------------------]]
function BuffTracker:UpdatePlayerBuffs()
	local found = {};
	
	for i=1,40,1 do
		local _,_,c,_,_,expiration,_,_,_,id = UnitAura("Player",i);

		if ( not id ) then
			break;
		elseif (self[id]) then
			self[id].expiration = expiration;
			found[id]=true;
			if ( not c or c==0 or not tonumber(c)) then
				c = 1;
			end
			
			local old_c = self[id].stacks;
			self[id].stacks = c;
			
			if ( c > old_c and self[id].onApply ) then --if stacks increase
				self[id].onApply(c,old_c);
			end
			
			if ( c < old_c and self[id].onExpires ) then --if stacks reduce, but dont drop entirely
				self[id].onExpires(c,old_c);
			end
		end
	end
	
	--check for buffs that fell off
	for id,t in pairs(self) do
		if type(t)=="table" then
			if not found[id] then
				local old_c = self[id].stacks;
				local c = 0;
				if ( old_c ~= c ) then
					self[id].stacks = c;
					if ( self[id].onExpires ) then
						self[id].onExpires(c,old_c);
					end
				end
			end
		end
	end
end

	
	
--[[----------------------------------------------------------------------------
	Get() - Query for the stackcount of a tracked buff/debuff
------------------------------------------------------------------------------]]
function BuffTracker:Get(spellId)
	if self[spellId] then
		if ( self[spellId].expiration == 0 or GetTime() <= self[spellId].expiration ) then
			return self[spellId].stacks;
		end
	end
	return 0;
end



addon.BuffTracker = BuffTracker;