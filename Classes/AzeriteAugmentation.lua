local name, addon = ...;

--[[
Many azerite traits augment healing done from existing spellIDs, and the amount added by the azerite traits does NOT scale with intellect.

This code is to estimate the percentage of a heal which was added by azerite, using knowledge of the spell coeffecients & calculated azerite coeffecients.
--]]
local AzeriteAugmentations = {
	Active={},
	Options={},
	SpellCoeffecients={},
	TraitCoeffecients={}
};


--[[
	Call this to setup an azerite trait augmenting an existing spellID. 
	
	The options table allows for some additional customization on the calculations:
		options.Overtime --when true, excludes calculation on direct healing or damage events
		options.Direct --when true, exclude calculation on non-direct healing or damage events
		options.ValueScalar(targetUnit) --scale the azerite value added by a multiplicative factor. A return value of 0 is equivalent to no value added. A value of 1 is equivalent to full value added.
		options.HealScalar(targetUnit) --scale the base healing by a multiplicative factor.
		options.Timeout					--require this many seconds to elapse before calculating again.	
]]
function AzeriteAugmentations:TraitAugmentsSpell(traitID,traitCoeffecient,spellID,spCoeffecient,options)
	local options = options or {};	
	self.TraitCoeffecients[traitID] = self.TraitCoeffecients[traitID] or {};
	self.TraitCoeffecients[traitID][spellID] = traitCoeffecient;
	self.SpellCoeffecients[spellID] = spCoeffecient;
	self.Options[traitID] = self.Options[traitID] or {};
	self.Options[traitID][spellID] = options;
end

--[[
	Call this function on gear change, before adding current azerite traits.
]]
function AzeriteAugmentations:ClearActiveTraits()
	wipe(self.Active);
end

--[[
	Call this function on gear change, for all equipped azerite traits
]]
function AzeriteAugmentations:SetActiveTrait(traitID,itemInt)
	if ( self.Options[traitID] ) then
		for spellID,_ in pairs(self.Options[traitID]) do
			self.Active[spellID] = self.Active[spellID] or {};
			self.Active[spellID][traitID] = self.Active[spellID][traitID] or 0;
			self.Active[spellID][traitID] = self.Active[spellID][traitID] + itemInt;
		end
	end
end

--[[
	Multiply intellect derivative by this factor to account for azerite augmentations which do not scale with intellect.
]]
function AzeriteAugmentations:GetAugmentationFactor(spellID,targetUnit,ev)
	if ( self.Active[spellID] ) then
		local azeriteAdded = 0;
		for traitID,intVal in pairs(self.Active[spellID]) do
			azeriteAdded = azeriteAdded + self:CalcAzeriteAdded(ev,spellID,traitID,intVal,targetUnit);
		end	
		
		local baseHeal = self:CalcBaseHeal(spellID);
		local frac = (baseHeal / (baseHeal+azeriteAdded));
		--addon:Msg("AzeriteAugmentation on spell "..spellID.." is "..tostring(math.floor((1-frac)*1000)/10).."%.");
		return frac;
	end
	
	return 1.0;
end



function AzeriteAugmentations:CalcAzeriteAdded(ev,spellID,traitID,intVal,targetUnit)
	--handle Timeouts
	local options = self.Options[traitID] and self.Options[traitID][spellID] or {};
	if ( options.Timeout and options.Timeout > 0 ) then
		local lastTimeout = options.lastTimeout or 0;
		local curTime = GetTime();
		
		if ( curTime - lastTimeout >= options.Timeout ) then
			--continue
			self.Options[traitID][spellID].lastTimeout = curTime;
		else
			return 0;
		end
	elseif ( options and options.Direct and (ev=="SPELL_PERIODIC_HEAL" or ev=="SPELL_PERIODIC_DAMAGE")) then
		return 0;
	elseif ( options and options.Overtime and (ev=="SPELL_HEAL" or ev=="SPELL_DAMAGE")) then
		return 0;
	end
	
	--handle custom Scalars
	local scalar;
	if ( options.ValueScalar ) then
		scalar = options.ValueScalar(targetUnit);
		--print("valuescalar",scalar);
	else
		scalar = 1.0;
	end
	
	--return value
	return scalar * intVal * self.TraitCoeffecients[traitID][spellID];
end

function AzeriteAugmentations:CalcBaseHeal(spellID)
	local scalar;
	local options = self.Options[traitID] and self.Options[traitID][spellID] or {};
	
	if ( options.HealScalar ) then
		scalar = options.HealScalar();
	else
		scalar = 1;
	end
	
	return addon.ply_sp * self.SpellCoeffecients[spellID] * scalar;
end



addon.AzeriteAugmentations = AzeriteAugmentations;









