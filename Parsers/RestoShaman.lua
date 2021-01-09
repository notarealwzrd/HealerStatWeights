local name, addon = ...;


function addon:IsRestoShaman()
    local i = GetSpecialization();
	local specId = i and GetSpecializationInfo(i);
	return specId and (tonumber(specId) == addon.SpellType.SHAMAN);
end



addon.SpecInfo = addon.SpecInfo or {};
addon.SpecInfo[addon.SpellType.SHAMAN] = {
	{
		key="url",
		name="Discord - Ancestral Guidance",
		desc="Welcome to Ancestral Guidance, a server dedicated to Restoration Shamans.",
		value="https://discord.com/invite/AcTek6e"
	},
	{
		key="url",
		name="Website - Ancestral Guidance",
		desc="Welcome to Ancestral Guidance! A website dedicated to resto shamans.",
		value="https://ancestralguidance.com/"
	},
	{
		key="url",
		name="Discord - Earthshrine",
		desc="A retail shaman community for any shaman specialization.",
		value="https://discord.gg/earthshrine"
	}
}



local function WeightedAvgStart(t)	
	t.sp_times_heal = 0;
	t.crit_times_heal = 0;
	t.haste_times_heal = 0;
	t.vers_times_heal = 0;
	t.mast_times_heal = 0;
	t.masteffect_times_heal = 0;
	t.critbonus_times_heal = 0;
	t.heal = 0.0001;
	t.dirty = false;
end

--[[----------------------------------------------------------------------------
	getMasteryEffect - Resto shaman mastery scales basesd on missing % health of target unit
------------------------------------------------------------------------------]]
local function getMasteryEffect(destUnit,effectiveHealing)
	if ( destUnit ) then
		local max_hp = UnitHealthMax(destUnit);
		if ( max_hp and max_hp > 0 ) then
			local orig_hp = math.max(0,UnitHealth(destUnit)-effectiveHealing);
			return (max_hp - orig_hp)/max_hp;
		end
	end
	return 0;
end



--[[----------------------------------------------------------------------------
	Ascendance - Spell queue & Buff tracking
------------------------------------------------------------------------------]]
local ascendance = {};
WeightedAvgStart(ascendance);
addon.BuffTracker:Track(addon.Shaman.AscendanceBuff, function() WeightedAvgStart(ascendance) end, nil);



--[[----------------------------------------------------------------------------
	Cloud Burst Totem
		Track weighted average of stat percentages on healing that feeds the
		cloudburst totem. These weighted averages can then be used by the
		decomp function.
------------------------------------------------------------------------------]]
local cbt = {};
WeightedAvgStart(cbt);
addon.BuffTracker:Track(addon.Shaman.CloudburstBuff,function() WeightedAvgStart(cbt) end,nil); --cloudburst totem



--[[----------------------------------------------------------------------------
	Resto Shaman Critical Strike
		- modified by tidal waves on healing surge
		- use weighted average of feeder spells for cloudburst
------------------------------------------------------------------------------]]
local function _CriticalStrike(ev,spellInfo,heal,destUnit,C,CB)	
	if ( spellInfo.spellID == addon.Shaman.HealingSurge ) then
		if ( addon.BuffTracker:Get(addon.Shaman.TidalWavesBuff) > 0 ) then
			C = C + 0.4;
		end
	end
	
	return addon.BaseParsers.CriticalStrike(ev,spellInfo,heal,destUnit,C,CB,nil);
end



--[[----------------------------------------------------------------------------
	Resto Shaman Mastery
		- Mastery effect is based on % hp on target
		- use weighted average of feeder spells for cloudburst
------------------------------------------------------------------------------]]
addon.Shaman.MasteryOriginalHeal = 0; --global var used by mastery

local function _Mastery(ev,spellInfo,heal,destUnit,M,ME_ascendance)
	if not spellInfo.mst then
		return 0;
	end
	
	local ME;
	if ME_ascendance then
		ME = ME_ascendance;
	else
		ME = getMasteryEffect(destUnit,addon.Shaman.MasteryOriginalHeal);
	end
	
	return ME*heal / (1+ME*M) / addon.MasteryConv;
end



--[[----------------------------------------------------------------------------
	Heal Event - Ascendance & CBT tracking
------------------------------------------------------------------------------]]
local function _HealEvent(ev,spellInfo,heal,overhealing,destUnit,f,origHeal)	
	addon.Shaman.MasteryOriginalHeal = origHeal; --set global var used by mastery
	
	--Ascendance
	if (spellInfo.spellID == addon.Shaman.Ascendance) then 
		if ( ascendance ) then
			ascendance.dirty = true; --next healing event will feed into the next ascendance tick.
			--Use weighted avg of stats that fed this ascendance tick
			local C = ascendance.crit_times_heal / ascendance.heal;
			local CB = ascendance.critbonus_times_heal / ascendance.heal;
			local M = ascendance.mast_times_heal / ascendance.heal;
			local ME = ascendance.masteffect_times_heal / ascendance.heal;
			local V = ascendance.vers_times_heal / ascendance.heal;
			local H = ascendance.haste_times_heal / ascendance.heal;
			local SP = ascendance.sp_times_heal / ascendance.heal;
			addon.StatParser:Allocate(ev,spellInfo,heal,overhealing,destUnit,f,SP,C,CB,H,V,M,ME,0);
		end
		return true;
	elseif ( addon.BuffTracker:Get(addon.Shaman.AscendanceBuff) > 0 ) then
		if ( ascendance.dirty ) then
			WeightedAvgStart(ascendance);
		end
		
		local total_heal = heal+overhealing;
		if ( spellInfo.mst ) then
			ascendance.mast_times_heal = ascendance.mast_times_heal + addon.ply_mst * total_heal;
			ascendance.masteffect_times_heal = ascendance.masteffect_times_heal + getMasteryEffect(destUnit,origHeal) * total_heal;
		end
		
		if ( spellInfo.int ) then
			ascendance.sp_times_heal = ascendance.sp_times_heal + (addon.ply_sp) * total_heal;
		end
		
		if ( spellInfo.crt ) then
			ascendance.crit_times_heal = ascendance.crit_times_heal + (addon.ply_crt) * total_heal;
			ascendance.critbonus_times_heal = ascendance.critbonus_times_heal + (addon.ply_crtbonus) * total_heal;
		end
		
		if ( spellInfo.hstHPCT ) then
			ascendance.haste_times_heal = ascendance.haste_times_heal + (addon.ply_hst) * total_heal;
		end
		
		if ( spellInfo.vrs ) then
			ascendance.vers_times_heal = ascendance.vers_times_heal + (addon.ply_vrs) * total_heal;
		end
		
		ascendance.heal = ascendance.heal + total_heal;
	end
	
	--CBT
	if ( spellInfo.spellID == addon.Shaman.CloudburstHeal ) then
		if ( cbt ) then
			--Use weighted avg of stats that fed cloudburst
			local C = cbt.crit_times_heal / cbt.heal;
			local CB = cbt.critbonus_times_heal / cbt.heal;
			local M = cbt.mast_times_heal / cbt.heal;
			local ME = cbt.masteffect_times_heal / cbt.heal;
			local V = cbt.vers_times_heal / cbt.heal;
			local H = cbt.haste_times_heal / cbt.heal;
			local SP = cbt.sp_times_heal / cbt.heal;
			addon.StatParser:Allocate(ev,spellInfo,heal,overhealing,destUnit,f,SP,C,CB,H,V,M,ME,0); 
		end
		return true;
	elseif ( addon.BuffTracker:Get(addon.Shaman.CloudburstBuff) > 0 ) then
		local total_heal = heal+overhealing;
		if ( spellInfo.mst ) then
			cbt.mast_times_heal = cbt.mast_times_heal + addon.ply_mst * total_heal;
			cbt.masteffect_times_heal = cbt.masteffect_times_heal + getMasteryEffect(destUnit,origHeal) * total_heal;
		end
		
		if ( spellInfo.int ) then
			cbt.sp_times_heal = cbt.sp_times_heal + (addon.ply_sp) * total_heal;
		end
		
		if ( spellInfo.crt ) then
			cbt.crit_times_heal = cbt.crit_times_heal + (addon.ply_crt) * total_heal;
			cbt.critbonus_times_heal = cbt.critbonus_times_heal + (addon.ply_crtbonus) * total_heal;
		end
		
		if ( spellInfo.hstHPCT ) then
			cbt.haste_times_heal = cbt.haste_times_heal + (addon.ply_hst) * total_heal;
		end
		
		if ( spellInfo.vrs ) then
			cbt.vers_times_heal = cbt.vers_times_heal + (addon.ply_vrs) * total_heal;
		end
		
		cbt.heal = cbt.heal + total_heal;
	end
	
	return false;
end



--[[----------------------------------------------------------------------------
	Earthen Shield Totem absorption tracking
------------------------------------------------------------------------------]]
function addon.Shaman:AbsorbEarthenWallTotem(destGUID,amount)
	local spellInfo = addon.Spells:Get(addon.Shaman.EarthShield);
	local u = addon.UnitManager:Find(destGUID);
	local f = addon.StatParser:GetParserForCurrentSpec();
	
	if ( spellInfo and u and f and amount and amount>0 ) then
		addon.StatParser:IncHealing(amount,spellInfo.filler,true);
		addon.StatParser:Allocate("SPELL_ABSORBED",spellInfo,amount,0,u,f,addon.ply_sp,addon.ply_crt,addon.ply_crtbonus,addon.ply_hst,addon.ply_vrs,addon.ply_mst,nil,0);
	end
end



addon.StatParser:Create(addon.SpellType.SHAMAN,_Intellect,_CriticalStrike,_Haste,_Versatility,_Mastery,nil,_HealEvent);