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



--[[----------------------------------------------------------------------------
	Druid Critical Strike 
		- modified by abundance on regrowth
------------------------------------------------------------------------------]]
local function _CriticalStrike(ev,spellInfo,heal,destUnit,C,CB)
	
	if ( spellInfo.spellID == addon.Druid.Regrowth ) then
		local abundance = addon.BuffTracker:Get(addon.Druid.AbundanceBuff);
		C = C + (abundance * 0.06);
	
		--TOOD: on regrowth initial heal, check if regrowth HoT already exists on the target and add 40% increased crit chance
	end
	
	return addon.BaseParsers.CriticalStrike(ev,spellInfo,heal,destUnit,C,CB,nil);
end



--[[----------------------------------------------------------------------------
	Druid Mastery 
		- modified by hotcount on target
------------------------------------------------------------------------------]]
local DruidArtifactWeaponID = 128306;

local function _Mastery(ev,spellInfo,heal,destUnit,M)
	if ( spellInfo.mst ) then --spell is affected by mastery, get the hotCount on target.		
		local count = hotCount(destUnit);
		
		if ( spellInfo.spellID == addon.Druid.FrenziedRegen and not IsEquippedItem(DruidArtifactWeaponID) ) then --FR isnt affected by itself when not using artifact weapon https://imgur.com/SmHa1bw
			count = math.max(0,count-1);
		end
		
		if ( spellInfo.spellID == addon.Druid.Nourish ) then
			count = count * 3;
		end

		return count*heal / (1+count*M) / addon.MasteryConv;
	end
	return 0;
end



addon.StatParser:Create(addon.SpellType.DRUID,nil,_CriticalStrike,nil,nil,_Mastery,nil,nil);