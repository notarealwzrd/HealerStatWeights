local name, addon = ...;
local _HealEvent;


function addon:IsHolyPriest()
    local i = GetSpecialization();
	local specId = i and GetSpecializationInfo(i);
	return specId and (tonumber(specId) == addon.SpellType.HPRIEST);
end



addon.SpecInfo = addon.SpecInfo or {};
addon.SpecInfo[addon.SpellType.HPRIEST] = {
	{
		key="url",
		name="WarcraftPriests.com",
		desc="Established in 2011 under HowToPriest.com, WarcraftPriests.com has a long history of being the premier priest community, now with hundreds of thousands of priests from all over the world coming together for all things Priest in World of Warcraft",
		value="https://discord.com/invite/warcraftpriests"
	}
}


--[[----------------------------------------------------------------------------
	Group up prayer of healing casts, so we can check which one was the lowest
	health for prayer of litany.
------------------------------------------------------------------------------]]
local POHBuckets = {};

local function CheckPOHBuckets()
	local n = #POHBuckets;
	if ( n <= 0 ) then
		return;
	end
	
	local lowest_i = 1;
	local i;
	
	for i=1,n,1 do
		if ( POHBuckets[i].hpPercent < POHBuckets[lowest_i].hpPercent) then
			lowest_i = i;
		end
	end
	POHBuckets[lowest_i].useScalar=true;
	
	for _,t in pairs(POHBuckets) do
		_HealEvent(t.ev,t.spellInfo,t.heal,t.overhealing,t.destUnit,t.f,t.heal,true,t.useScalar and t.scalar or 1)
	end
	
	wipe(POHBuckets);
end


--[[----------------------------------------------------------------------------
	Echo of Light Tracker
		Tracks a weighted average of stat percentages contributing to an echo
		of light tick.
------------------------------------------------------------------------------]]
local EOLTracker = {};
local EOLIgnorePercent = {}; --0 means include, 1 means exclude
local ticks_on_initial_application = 2;
local ticks_on_refresh = 3;

local function weighted_avg(stat1,w1,stat2,w2)
	return (stat1*w1+stat2*w2)/(w1+w2);
end

local function hasEcho(unit) --return amount per tick of EoL or nil
	for i=1,40,1 do
		local _,_,_,_,_,_,p,_,_,id,_,_,_,_,_,amt = UnitAura(unit,i);

		if ( not id ) then
			break;
		elseif (p == "player" and id == addon.HolyPriest.EchoOfLight ) then
			return amt;
		end
	end
	
	return false;
end

function EOLTracker:SetIgnore(destUnit) --ignore EOL healing from next application on this target.
	if ( destUnit ) then
		EOLIgnorePercent[destUnit] = 1;
	end
end

function EOLTracker:Apply(destGUID)
	CheckPOHBuckets();
	local u = addon.UnitManager:Find(destGUID);
	if ( u ) then
		local ignorePercent;
		if ( EOLIgnorePercent[u] ) then
			ignorePercent = EOLIgnorePercent[u];
			EOLIgnorePercent = 0;
		else
			ignorePercent = 0;
		end
		
		local amount = hasEcho(u) or 0;
		self[u] = {
			ignore = ignorePercent,
			current = amount*ticks_on_initial_application,
			SP = addon.ply_sp,
			C = addon.ply_crt,
			CB = addon.ply_crtbonus,
			H = addon.ply_hst,
			M = addon.ply_mst,
			V = addon.ply_vrs
		};
	end
end

function EOLTracker:Refresh(destGUID)
	CheckPOHBuckets();
	local u = addon.UnitManager:Find(destGUID);
	if ( u ) then
		local ignorePercent;
		if ( EOLIgnorePercent[u] ) then
			ignorePercent = EOLIgnorePercent[u];
			EOLIgnorePercent = 0;
		else
			ignorePercent = 0;
		end
		
		local amount = hasEcho(u) or 0;
		if not self[u] then
			self[u] = {
				ignore = ignorePercent,
				current = amount*ticks_on_refresh,
				SP = addon.ply_sp,
				C = addon.ply_crt,
				CB = addon.ply_crtbonus,
				H = addon.ply_hst,
				M = addon.ply_mst,
				V = addon.ply_vrs
			};
		else
			local after = math.max(0,ticks_on_refresh*amount-self[u].current);
			local before = ticks_on_refresh*amount-after;
		
			self[u].current = ticks_on_refresh*amount;
			self[u].ignore = weighted_avg(self[u].ignore,before,ignorePercent,after)
			self[u].SP = weighted_avg(self[u].SP,before,addon.ply_sp,after);
			self[u].C = weighted_avg(self[u].C,before,addon.ply_crt,after);
			self[u].CB = weighted_avg(self[u].CB,before,addon.ply_crtbonus,after);
			self[u].H = weighted_avg(self[u].H,before,addon.ply_hst,after);
			self[u].M = weighted_avg(self[u].M,before,addon.ply_mst,after);
			self[u].V = weighted_avg(self[u].V,before,addon.ply_vrs,after);	
		end
	end
end

function EOLTracker:Remove(destGUID)
	local u = addon.UnitManager:Find(destGUID);
	if ( u and self[u] ) then
		self[u] = nil;
	end
end

function EOLTracker:HealedUnit(u,amount)
	if ( u and self[u] ) then
		self[u].current = math.max(0,self[u].current-amount);
	end
end

function EOLTracker:Get(u)
	if ( u ) then
		return self[u];
	end
	return nil;
end

function EOLTracker:EncounterStart()
	for guid,u in pairs(addon.UnitManager.units) do
		if ( u ) then
			local amount = hasEcho(u);
			if ( amount and amount > 0 ) then
				self:Apply(guid,amount);
			end
		end
	end
end



--[[----------------------------------------------------------------------------
	Holy Priest Heal Event
		- Use echo of light tracker to correctly allocate echo of light stat contributions
		- Put POH events into a bucket, and handle them as a batch for PrayerfulLitany trait
		- Pass Azerite contribution of augmented spells to Echo of Light (affects Intellect)
------------------------------------------------------------------------------]]
local last_salvation_time = 0;
local pom_applications_from_salvation = 0;

_HealEvent = function(ev,spellInfo,heal,overhealing,destUnit,f,origHeal,skipBucket,scalar)
	if ( spellInfo.spellID == addon.HolyPriest.EchoOfLight ) then
		addon.HolyPriest.EOLTracker:HealedUnit(destUnit,heal+overhealing);
		local t = addon.HolyPriest.EOLTracker:Get(destUnit);
		if ( t ) then
			local notIgnored = math.max(1-t.ignore,0);
			addon.StatParser:Allocate(ev,spellInfo,heal*notIgnored,overhealing*notIgnored,destUnit,f,t.SP,t.C,t.CB,t.H,t.V,t.M,nil,0);
			return true; --skip default allocation
		end 
	elseif ( spellInfo.spellID == addon.HolyPriest.PrayerOfHealing ) then
		if ( not skipBucket ) then
			local targetHPPercent = (UnitHealth(destUnit)-heal)/UnitHealthMax(destUnit);
			table.insert(POHBuckets,{hpPercent=targetHPPercent,ev=ev,spellInfo=spellInfo,heal=heal,overhealing=overhealing,destUnit=destUnit,f=f});
			return true; --skip for now.
		else --frombucket
			addon.StatParser:Allocate(ev,spellInfo,heal,overhealing,destUnit,f,addon.ply_sp,addon.ply_crt,addon.ply_crtbonus,addon.ply_hst,addon.ply_vrs,addon.ply_mst,nil,addon.ply_lee)
			EOLTracker:SetScalar(destUnit,scalar);
		end
	end
	
	--Handle ignoring contribution from raid healing cooldowns. (Divine Hymn & Salvation)
	if ( addon.hsw.db.global.excludeRaidHealingCooldowns ) then
		--exclude EOL from raid cooldowns
		if ( spellInfo.cd ) then
			EOLTracker:SetIgnore(destUnit); 
		end
		
		--ignore renew/PoM from salvation. 
		if ( spellInfo.spellID == addon.HolyPriest.Salvation ) then
			last_salvation_time = GetTime();
			pom_applications_from_salvation = 0;		
		elseif ( spellInfo.spellID == addon.HolyPriest.Renew ) then --ignore next 15s of renew.
			if ( GetTime()-last_salvation_time <= 15.33 ) then
				if ( ev == "SPELL_HEAL" ) then --ignore EOL from direct portion of renew
					EOLTracker:SetIgnore(destUnit);
				end
				return true;
			end
		elseif ( spellInfo.spellID == addon.HolyPriest.PrayerOfMending ) then --ignore next 30s of PoM (or until #applications*2 ticks of PoM)
			pom_applications_from_salvation = math.max(0,pom_applications_from_salvation - 1);
			if ( pom_applications_from_salvation > 0 and GetTime()-last_salvation_time <= 30.33 ) then
				EOLTracker:SetIgnore(destUnit); --ignore EOL from POM as well
				return true;
			end
		end
	end
	
	return false;
end




--[[----------------------------------------------------------------------------
	Holy Priest Mastery
		- calculated from echo of light healing
------------------------------------------------------------------------------]]
local function _Mastery(ev,spellInfo,heal,destUnit,M)
	if ( spellInfo.spellID == addon.HolyPriest.EchoOfLight ) then --echo of light healing
		if ( M == 0 ) then
			return 0;
		end
		return heal / M / addon.MasteryConv; --divide by M instead of (1+M)
	end
	return 0;
end



addon.HolyPriest.EOLTracker = EOLTracker;
addon.StatParser:Create(addon.SpellType.HPRIEST,nil,nil,nil,nil,_Mastery,nil,_HealEvent,nil);