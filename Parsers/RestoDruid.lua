local name, addon = ...;



function addon:IsRestoDruid()
    local i = GetSpecialization();
	local specId = i and GetSpecializationInfo(i);
	return specId and (tonumber(specId) == addon.SpellType.DRUID);
end



addon.SpecInfo = addon.SpecInfo or {};
addon.SpecInfo[addon.SpellType.DRUID] = {
	{
		key="url",
		name="Discord - Dreamgrove",
		desc="",
		value="https://discord.com/invite/dreamgrove"
	},
	{
		key="url",
		name="Website - Questionably Epic",
		desc="World of Warcraft Healing Theorycrafting Website. Home of the QE Live Gear Analyzer",
		value="https://questionablyepic.com/"
	}
}



--[[----------------------------------------------------------------------------
	hotCount() - get the resto druid mastery effect (hotcount)
------------------------------------------------------------------------------]]
local hots = { --spells that count towards druid mastery stacks
	[addon.Druid.Tranquility]=true,
	[addon.Druid.Rejuvenation]=true,
	[addon.Druid.Germination]=true,
	[addon.Druid.LifebloomHoT]=true,
	[addon.Druid.Regrowth]=true, --regrowth
	[addon.Druid.WildGrowth]=true,
	[addon.Druid.SpringBlossoms]=true,
	[addon.Druid.Cultivation]=true,
	[addon.Druid.CenarionWard]=true,
	[addon.Druid.DreamerHoT]=true,
	[addon.Druid.FrenziedRegen]=true
}

function addon.Druid:IsHOT(spellID)
	return hots[spellID];
end

local function hotCount(unit)
	local count = 0;
	for i=1,40,1 do
		local _,_,_,_,_,_,p,_,_,id = UnitAura(unit,i);

		if ( not id ) then
			break;
		elseif (p == "player" and hots[id]) then
			count = count + 1;
		end
	end
	
	return count;
end

local function hasRegrowthHoT(unit) 
	local count = 0;
	for i=1,40,1 do
		local _,_,_,_,_,_,p,_,_,id = UnitAura(unit,i);

		if ( not id ) then
			break;
		elseif (p == "player" and id == addon.Druid.Regrowth) then
			return true;
		end
	end
	return false;
end



--[[----------------------------------------------------------------------------
	Druid Critical Strike 
		- modified by abundance on regrowth
		- modified by rank2 regrowth
------------------------------------------------------------------------------]]
local function _CriticalStrike(ev,spellInfo,heal,destUnit,C,CB)
	
	if ( spellInfo.spellID == addon.Druid.Regrowth ) then
		local abundance = addon.BuffTracker:Get(addon.Druid.AbundanceBuff);
		C = C + (abundance * 0.06);

		--check for initial hit of regrowth on an existing regrowth HoT
		if ( ev ~= "SPELL_PERIODIC_HEAL" and hasRegrowthHoT(destUnit) ) then
			C = C + 0.40; --rank2 regrowth
		end
	end
	
	return addon.BaseParsers.CriticalStrike(ev,spellInfo,heal,destUnit,C,CB,nil);
end



--[[----------------------------------------------------------------------------
	Druid Mastery 
		- modified by hotcount on target
		- amplified when using Nourish
		- frenzied regen not affected by it's own mastery stack
------------------------------------------------------------------------------]]
local DruidArtifactWeaponID = 128306;

local function _Mastery(ev,spellInfo,heal,destUnit,M)
	if ( spellInfo.mst ) then --spell is affected by mastery, get the hotCount on target.		
		--HotCount
		local count = hotCount(destUnit);
		
		--Nourish
		if ( spellInfo.spellID == addon.Druid.Nourish ) then
			count = count * 3;
		end

		--Frenzied Regen:
		--[[ 
			Frenzied regen is a "HoT" that boosts the mastery of other spells,
			Frenzied regen healing is increased by druid mastery,
			BUT frenzied regen is not increased by it's own mastery HoT (1-9-2021)
			This is the only druid spell I have found which works this way.
		--]]
		if ( spellInfo.spellID == addon.Druid.FrenziedRegen ) then 
			count = math.max(0,count-1);
		end

		return count*heal / (1+count*M) / addon.MasteryConv;
	end
	return 0;
end



addon.StatParser:Create(addon.SpellType.DRUID,nil,_CriticalStrike,nil,nil,_Mastery,nil,nil);