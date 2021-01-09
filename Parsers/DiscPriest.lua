local name, addon = ...;



function addon:IsDiscPriest()
    local i = GetSpecialization();
	local specId = i and GetSpecializationInfo(i);
	return specId and (tonumber(specId) == addon.SpellType.DPRIEST);
end

atonementQueue = addon.Queue.CreateSpellQueue(nil);


addon.SpecInfo = addon.SpecInfo or {};
addon.SpecInfo[addon.SpellType.DPRIEST] = {
	{
		key="url",
		name="Focused Will",
		desc="Focused Will is focused on providing the best community possible for Priests in the World of Warcraft",
		value="https://discord.gg/focusedwill"
	},
	{
		key="url",
		name="WarcraftPriests.com",
		desc="Established in 2011 under HowToPriest.com, WarcraftPriests.com has a long history of being the premier priest community, now with hundreds of thousands of priests from all over the world coming together for all things Priest in World of Warcraft",
		value="https://discord.com/invite/warcraftpriests"
	},
};




--[[----------------------------------------------------------------------------
	Chain cast tracking
------------------------------------------------------------------------------]]
local nextDamageCastIsChainCast = false;
local nextAtonementApplicatorIsChainCast = false;
local atonementApplicators = {
	[addon.DiscPriest.PowerWordShield]=true,
	[addon.DiscPriest.RadianceHeal]=true,
	[addon.DiscPriest.ShadowMendHeal]=true
}
addon.DiscPriest.CastXfer = "xfer";
addon.DiscPriest.CastSmite = "smite";
addon.DiscPriest.CastApplicator = "applicator";
addon.DiscPriest.CastPWS = "pws";
addon.DiscPriest.CastShadowMend = "shadowmend";

function addon.DiscPriest:CHAIN_CAST(spellID)
	local spellInfo = addon.Spells:Get(spellID);
	if ( spellInfo.transfersToAtonement ) then
		addon.StatParser:IncChainSpellCast(addon.DiscPriest.CastXfer);
		nextDamageCastIsChainCast=spellID;
		
		if ( spellID == addon.DiscPriest.Smite ) then
			addon.StatParser:IncChainSpellCast(addon.DiscPriest.CastSmite);
		end
		
	elseif ( atonementApplicators[spellID] ) then
		addon.StatParser:IncChainSpellCast(addon.DiscPriest.CastApplicator);
		nextAtonementApplicatorIsChainCast=spellID;
		
		if ( spellID == addon.DiscPriest.PowerWordShield ) then
			addon.StatParser:IncChainSpellCast(addon.DiscPriest.CastPWS);
		elseif ( spellID == addon.DiscPriest.ShadowMendHeal ) then
			addon.StatParser:IncChainSpellCast(addon.DiscPriest.CastShadowMend);
		end
	end
end



--[[----------------------------------------------------------------------------
	Disc Priest Mastery
		- Calculated on targets with atonement
------------------------------------------------------------------------------]]
local function _Mastery(ev,spellInfo,heal,destUnit,M,ME)
	if spellInfo.mst then
		if (not ME) then
			if addon.DiscPriest.AtonementTracker:UnitHasAtonement(destUnit) then
				ME = 1;
			end
		end
		
		if (ME == 1) then
			--DISCIPLINE PRIEST MASTERY SNAPSHOT BUG
			--if hotfixed, remove the next line!!!!!
			-- M = addon.DiscPriest.AtonementTracker:TryGetUnitMasterySnapshot(destUnit)
			
			return heal / (1+M) / addon.MasteryConv;
		end
	end
	return 0;
end



--[[----------------------------------------------------------------------------
	Disc Priest Damage Event
		- Generates atonement events in the atonement queue
------------------------------------------------------------------------------]]
local lastTransfer = {}
--shallow table copy
local function copy(t) 
	local new_t = {};
	local mt = getmetatable(t);
	for k,v in pairs(t) do new_t[k] = v; end
	setmetatable(new_t,mt);
	return new_t;
end

local function _DamageEvent(spellInfo,amount,critFlag)
	if ( spellInfo.transfersToAtonement ) then
		if ( spellInfo.transfersToAtonementGracePeriod ) then
			local curTime = GetTime();
			
			if ( not lastTransfer[spellInfo.spellID] or (curTime - lastTransfer[spellInfo.spellID]) > spellInfo.transfersToAtonementGracePeriod) then
				lastTransfer[spellInfo.spellID] = curTime;
			else
				return; --too soon to xfer to atonement
			end
		end
		local numAtonement = addon.DiscPriest.AtonementTracker.count;
		
		
		local data = copy(spellInfo);
		data.chainCast = nextDamageCastIsChainCast or (spellInfo.spellID == addon.DiscPriest.PenanceCast2);
		
		--data.critFlag = critFlag; --this isnt needed since the atonement healing event also includes the critflag
		nextDamageCastIsChainCast = false;
		atonementQueue:Enqueue(numAtonement,data);
	end
end



--[[----------------------------------------------------------------------------
	Disc Priest Heal Event
		- Match spells from atonement queue & Allocate
------------------------------------------------------------------------------]]
local spellInfo_OnlyHasteHPM = { hstHPM=true };

local function _HealEvent(ev,spellInfo,heal,overhealing,destUnit,f)
	if ( spellInfo.spellID == addon.DiscPriest.AtonementHeal1 or spellInfo.spellID == addon.DiscPriest.AtonementHeal2 ) then
		local event = atonementQueue:MatchHeal();
		
		if ( event and event.data ) then
			local cur_seg = addon.SegmentManager:Get(0);
			local ttl_seg = addon.SegmentManager:Get("Total");
			
			--atonement healing HPC interactions
			if ( event.data.chainCast  ) then
				--Atonement Applicators gain haste HPC benefit from chain-casted Atonement-transfering spells 
				addon.StatParser:Allocate(ev,spellInfo_OnlyHasteHPM,heal,overhealing,destUnit,f,0,0,0,event.H,0,0,0,0);
			end
			
			local applicator_H = addon.DiscPriest.AtonementTracker:UnitHasAtonementFromChainCast(destUnit);
			if ( applicator_H ) then
				--Atonement-transfering spells gain haste HPC benefit from chain-casted Atonement Applicators
				addon.StatParser:Allocate(ev,spellInfo_OnlyHasteHPM,heal,overhealing,destUnit,f,0,0,0,applicator_H,0,0,0,0);
			end

			--haste HPCT
			if ( addon.DiscPriest.AtonementTracker:UnitHasAtonementFromPWS(destUnit) ) then
				--attribute atonement healing on targets with atonement from PWS (for haste HPCT)
				addon.StatParser:IncFillerHealing(heal);
			end
			
			if ( event.data.spellID == addon.DiscPriest.Smite ) then
				addon.StatParser:IncSmiteHealing(heal);
			end
			
			--Normal stat allocation
			addon.StatParser:Allocate(ev,event.data,heal,overhealing,destUnit,f,event.SP,event.C,addon.ply_crtbonus,event.H,event.V,event.M,1.0,event.L);
		end
		return true; --skip normal computation of healing event
	elseif ( spellInfo.spellID == addon.DiscPriest.ContritionHeal1 or spellInfo.spellID == addon.DiscPriest.ContritionHeal2 ) then
		local applicator_H = addon.DiscPriest.AtonementTracker:UnitHasAtonementFromChainCast(destUnit);
		if ( applicator_H ) then
			--Contrition ticks gain haste HPC benefit from chain-casted Atonement Applicators
			addon.StatParser:Allocate(ev,spellInfo_OnlyHasteHPM,heal,overhealing,destUnit,f,0,0,0,applicator_H,0,0,0,0);
		end
	elseif ( spellInfo.spellID == addon.DiscPriest.ShadowMendHeal ) then
		addon.StatParser:IncBucket(addon.DiscPriest.CastShadowMend,heal);
	end
	return false;
end



--[[----------------------------------------------------------------------------
	Luminous Barrier tracking
------------------------------------------------------------------------------]]
local LBTracker = {};
function LBTracker:Apply(destGUID,amount)
	local u = addon.UnitManager:Find(destGUID);
	if ( u ) then
		if ( self[u] ) then
			self[u].original = math.max(amount-self[u].original,0);
			self[u].current = amount;
		else
			self[u] = {
				original = amount,
				current = amount
			};
		end
		
		if ( addon.DiscPriest.AtonementTracker:UnitHasAtonement(u) ) then
			self[u].masteryFlag = true;
		end
		self[u].SP = addon.ply_sp;
		self[u].C = addon.ply_crt;
		self[u].CB = addon.ply_crtbonus;
		self[u].H = addon.ply_hst;
		self[u].M = addon.ply_mst;
		self[u].V = addon.ply_vrs;
		self[u].ts = GetTime();
	end
end

function LBTracker:Remove(destGUID,amount)
	local u = addon.UnitManager:Find(destGUID);
	if ( u ) then
		if ( self[u] ) then
			if ( amount == 0 ) then
				local t = self[u];
				if ( t ) then
					local spellInfo = addon.Spells:Get(addon.DiscPriest.LuminousBarrierAbsorb);
					local originalHeal = t.original;
					local f = addon.StatParser:GetParserForCurrentSpec();
					local ME = t.masteryFlag and 1 or 0;
					
					if ( spellInfo and originalHeal and originalHeal>0 and f ) then
						local exclude_cds = addon.hsw.db.global.excludeRaidHealingCooldowns	--filter out raid cooldowns if we are excluding them
						if ( not exclude_cds or (exclude_cds and not spellInfo.cd) ) then
							addon.StatParser:IncHealing(originalHeal,false,true);
							addon.StatParser:Allocate("SPELL_ABSORBED",spellInfo,originalHeal,0,u,f,t.SP,t.C,t.CB,t.H,t.V,t.M,ME,0);
						end
					end
				end
			end
			self[u] = nil;
		end
	end
end

local function hasLB(unit)
	for i=1,40,1 do
		local _,_,_,_,_,_,p,_,_,id,_,_,_,_,_,amt = UnitAura(unit,i);
		
		if ( not id ) then
			break;
		elseif (p == "player" and id == addon.DiscPriest.LuminousBarrierAbsorb ) then
			return amt;
		end
	end
	
	return false;
end

function LBTracker:EncounterStart()
	for guid,u in pairs(addon.UnitManager.units) do
		if ( u ) then
			local amount = hasLB(u);
			if ( amount and amount > 0 ) then
				self:ApplyOrRefresh(guid,amount);
			end
		end
	end
end
addon.DiscPriest.LBTracker = LBTracker;



--[[----------------------------------------------------------------------------
	Smite absorption tracking
------------------------------------------------------------------------------]]
function addon.DiscPriest:AbsorbSmite(destGUID,amount)
	local spellInfo = addon.Spells:Get(addon.DiscPriest.SmiteAbsorb);
	local u = addon.UnitManager:Find(destGUID);
	local f = addon.StatParser:GetParserForCurrentSpec();
	
	if ( spellInfo and u and f and amount and amount>0 ) then
		addon.StatParser:IncHealing(amount,spellInfo.filler,true); --not filler healing
		addon.StatParser:IncBucket(addon.DiscPriest.CastSmite,amount);
		addon.StatParser:Allocate("SPELL_ABSORBED",spellInfo,amount,0,u,f,addon.ply_sp,addon.ply_crt,addon.ply_crtbonus,addon.ply_hst,addon.ply_vrs,addon.ply_mst,0,0);
	end
end
	


--[[----------------------------------------------------------------------------
	Power word: shield tracking
------------------------------------------------------------------------------]]
local PWSTracker = {};
function PWSTracker:ApplyOrRefresh(destGUID,amount)
	local u = addon.UnitManager:Find(destGUID);
	if ( u ) then
		if ( self[u] ) then
			self[u].original = math.max(amount-self[u].current,0); --its possible to remove shield by overwriting a crit shield. So we clamp at 0.
			self[u].current = amount;
		else
			self[u] = {
				original = amount,
				current = amount
			};
		end
		if ( addon.DiscPriest.AtonementTracker:UnitHasAtonement(u) ) then
			self[u].masteryFlag = true;
		end
		self[u].intScalar = addon.AzeriteAugmentations:GetAugmentationFactor(addon.DiscPriest.PowerWordShield,u);
		self[u].SP = addon.ply_sp;
		self[u].C = addon.ply_crt;
		self[u].CB = addon.ply_crtbonus;
		self[u].M = addon.ply_mst;
		self[u].H = addon.ply_hst;
		self[u].V = addon.ply_vrs;
		self[u].ts = GetTime();
	end
end

function PWSTracker:Absorb(destGUID,amount)
	local u = addon.UnitManager:Find(destGUID);
	if ( u ) then
		if ( self[u] ) then
			self[u].current = math.max(self[u].current - amount,0);
			addon.StatParser:IncHealing(amount,true,true);
			addon.StatParser:IncBucket(addon.DiscPriest.CastPWS,amount);
		end
	end
end

function PWSTracker:Remove(destGUID,amount)
	local u = addon.UnitManager:Find(destGUID);
	if ( u ) then
		if ( self[u] ) then
			if ( amount == 0 ) then
				local t = self[u];
				if ( t ) then
					local spellInfo = addon.Spells:Get(addon.DiscPriest.PowerWordShield);
					local originalHeal = t.original;
					local f = addon.StatParser:GetParserForCurrentSpec();
					local ME = t.masteryFlag and 1 or 0;
					
					if ( spellInfo and originalHeal and originalHeal>0 and f ) then
						addon.StatParser:Allocate("SPELL_ABSORBED",spellInfo,originalHeal,0,u,f,t.SP,t.C,t.CB,t.H,t.V,t.M,ME,0);
					end
				end
			end
			--self[u] = nil;
		end
	end
end

local function hasShield(unit)
	for i=1,40,1 do
		local _,_,_,_,_,_,p,_,_,id,_,_,_,_,_,amt = UnitAura(unit,i);

		if ( not id ) then
			break;
		elseif (p == "player" and id == addon.DiscPriest.PowerWordShield ) then
			return amt;
		end
	end
	
	return false;
end

function PWSTracker:EncounterStart()
	for guid,u in pairs(addon.UnitManager.units) do
		if ( u ) then
			local amount = hasShield(u);
			if ( amount and amount > 0 ) then
				self:ApplyOrRefresh(guid,amount);
			end
		end
	end
end
addon.DiscPriest.PWSTracker = PWSTracker;



--[[----------------------------------------------------------------------------
	Atonement tracking
------------------------------------------------------------------------------]]
local AtonementTracker = {
	count=0,
	chainCastApplications = {},
	mastery = {},
};

function AtonementTracker:ApplyOrRefresh(destGUID)
	local u = addon.UnitManager:Find(destGUID);
	if ( u ) then
		if ( not self[u] ) then
			self.count = self.count + 1;
		end
		self[u] = GetTime();
		self.mastery[u] = addon.ply_mst; --store mastery at time of application
		self.chainCastApplications[u] = nextAtonementApplicatorIsChainCast and addon.ply_hst or nil; --store haste at time of application
		nextAtonementApplicatorIsChainCast = false;
	end
end


function AtonementTracker:Count()
	return self.count;
end

function AtonementTracker:Remove(destGUID)
	local u = addon.UnitManager:Find(destGUID);
	if ( u ) then
		if ( self[u] ) then
			self.count = math.max(0,self.count - 1);
		end
		self[u] = nil
		self.chainCastApplications[u] = nil;
		self.mastery[u] = nil;
	end
end

local function hasAtonement(unit)
	for i=1,40,1 do
		local _,_,_,_,_,_,p,_,_,id = UnitAura(unit,i);

		if ( not id ) then
			break;
		elseif (p == "player" and id == addon.DiscPriest.AtonementBuff ) then
			return true;
		end
	end
	
	return false;
end

function AtonementTracker:EncounterStart()
	for guid,u in pairs(addon.UnitManager.units) do
		if ( u and hasAtonement(u) ) then
			self:ApplyOrRefresh(guid);
		end
	end
end

function AtonementTracker:UnitHasAtonement(unit)
	if ( self[unit] ) then
		return true;
	else
		return false;
	end
end

function AtonementTracker:TryGetUnitMasterySnapshot(unit)
	if ( self.mastery[unit] ) then
		return self.mastery[unit];
	else
		return addon.ply_mst;
	end
end

function AtonementTracker:UnitHasAtonementFromPWS(unit)
	if ( unit ) then
		local pws_tbl = addon.DiscPriest.PWSTracker[unit];
		if ( pws_tbl ) then
			local t1 = self[unit];
			local t2 = pws_tbl.ts;
			return addon.BuffTracker:CompareTimestamps(t1,t2,0.3333);
		end
	end
	
	return false;
end

function AtonementTracker:UnitHasAtonementFromChainCast(unit)
	if ( self[unit] and self.chainCastApplications[unit] ) then
		return self.chainCastApplications[unit];
	else
		return false;
	end
end
addon.DiscPriest.AtonementTracker = AtonementTracker;



addon.StatParser:Create(addon.SpellType.DPRIEST,nil,nil,nil,nil,_Mastery,nil,_HealEvent,_DamageEvent);