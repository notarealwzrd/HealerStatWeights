local name, addon = ...;



--[[----------------------------------------------------------------------------
	Stat conversion factors (data taken from simc)
	https:--github.com/simulationcraft/simc/blob/bfa-dev/engine/dbc/generated/sc_scale_data.inc
------------------------------------------------------------------------------]]
local hst_cnv =   {
    2.550202644,	2.550202644,	2.550202644,	2.550202644,	2.550202644,	
    2.550202644,	2.550202644,	2.550202644,	2.550202644,	2.550202644,	
    2.550202644,	2.677712777,	2.805222909,	2.932733041,	3.060243173,	
    3.187753306,	3.315263438,	3.44277357,	3.570283702,	3.697793835,	
    3.825303967,	3.952814099,	4.080324231,	4.207834363,	4.335344496,	
    4.466618727,	4.603118595,	4.745078773,	4.892745624,	5.046377837,	
    5.206247087,	5.372638744,	5.545852617,	5.726203744,	5.914023226,	
    6.109659115,	6.313477343,	6.525862721,	6.747219984,	6.977974908,	
    7.23803877,	7.507795016,	7.787604874,	8.077843034,	8.378898152,	
    8.691173367,	9.015086844,	9.351072331,	9.699579745,	10.06107577,	
    11.10794054,	12.26373262,	13.53978599,	14.94861396,	16.50403187,	
    18.22129252,	20.11723583,	22.21045389,	24.52147334,	33.00000009,	
};
	
local crt_cnv =   {
    2.704760381,	2.704760381,	2.704760381,	2.704760381,	2.704760381,	--    5
    2.704760381,	2.704760381,	2.704760381,	2.704760381,	2.704760381,	--   10
    2.704760381,	2.8399984,	2.975236419,	3.110474438,	3.245712457,	--   15
    3.380950476,	3.516188495,	3.651426514,	3.786664533,	3.921902552,	--   20
    4.057140571,	4.19237859,	4.327616609,	4.462854628,	4.598092647,	--   25
    4.737322892,	4.88209548,	5.032659304,	5.189275662,	5.352218918,	--   30
    5.521777213,	5.698253213,	5.881964896,	6.073246395,	6.272448877,	--   35
    6.479941485,	6.696112333,	6.921369552,	7.156142407,	7.400882478,	--   40
    7.676707786,	7.962812896,	8.259580927,	8.567409279,	8.886710161,	--   45
    9.217911147,	9.561455743,	9.917803988,	10.28743306,	10.67083793,	--   50
    11.78114906,	13.00698914,	14.36037908,	15.85459057,	17.50427622,	--   55
    19.32561328,	21.33646224,	23.55654201,	26.00762324,	35.00000009,	--   60
};

local mst_cnv =   {
    2.704760381,	2.704760381,	2.704760381,	2.704760381,	2.704760381,	--    5
    2.704760381,	2.704760381,	2.704760381,	2.704760381,	2.704760381,	--   10
    2.704760381,	2.8399984,	2.975236419,	3.110474438,	3.245712457,	--   15
    3.380950476,	3.516188495,	3.651426514,	3.786664533,	3.921902552,	--   20
    4.057140571,	4.19237859,	4.327616609,	4.462854628,	4.598092647,	--   25
    4.737322892,	4.88209548,	5.032659304,	5.189275662,	5.352218918,	--   30
    5.521777213,	5.698253213,	5.881964896,	6.073246395,	6.272448877,	--   35
    6.479941485,	6.696112333,	6.921369552,	7.156142407,	7.400882478,	--   40
    7.676707786,	7.962812896,	8.259580927,	8.567409279,	8.886710161,	--   45
    9.217911147,	9.561455743,	9.917803988,	10.28743306,	10.67083793,	--   50
    11.78114906,	13.00698914,	14.36037908,	15.85459057,	17.50427622,	--   55
    19.32561328,	21.33646224,	23.55654201,	26.00762324,	35.00000009,	--   60
};

local vrs_cnv =   {
    3.091154721,	3.091154721,	3.091154721,	3.091154721,	3.091154721,	--    5
    3.091154721,	3.091154721,	3.091154721,	3.091154721,	3.091154721,	--   10
    3.091154721,	3.245712457,	3.400270193,	3.554827929,	3.709385665,	--   15
    3.863943401,	4.018501137,	4.173058873,	4.327616609,	4.482174345,	--   20
    4.636732081,	4.791289817,	4.945847553,	5.100405289,	5.254963025,	--   25
    5.414083305,	5.579537691,	5.751610634,	5.930600757,	6.11682162,	--   30
    6.310602529,	6.512289386,	6.722245596,	6.940853023,	7.168513002,	--   35
    7.405647412,	7.65269981,	7.910136631,	8.178448466,	8.458151403,	--   40
    8.773380327,	9.100357595,	9.439521059,	9.79132489,	10.15624018,	--   45
    10.5347556,	10.92737799,	11.33463313,	11.75706636,	12.19524335,	--   50
    13.46417035,	14.86513044,	16.4118618,	18.11953208,	20.00488711,	--   55
    22.08641518,	24.38452828,	26.92176229,	29.72299799,	40.0000001,	--   60
};

local lee_cnv =   {
    1.622856228,	1.622856228,	1.622856228,	1.622856228,	1.622856228,	--    5
    1.622856228,	1.622856228,	1.622856228,	1.622856228,	1.622856228,	--   10
    1.622856228,	1.70399904,	1.785141851,	1.866284663,	1.947427474,	--   15
    2.028570285,	2.109713097,	2.190855908,	2.27199872,	2.353141531,	--   20
    2.434284342,	2.515427154,	2.596569965,	2.677712777,	2.758855588,	--   25
    2.842393735,	2.929257288,	3.019595583,	3.113565397,	3.211331351,	--   30
    3.313066328,	3.418951928,	3.529178938,	3.643947837,	3.763469326,	--   35
    3.887964891,	4.0176674,	4.152821731,	4.293685444,	4.440529487,	--   40
    4.606024672,	4.777687737,	4.955748556,	5.140445567,	5.332026097,	--   45
    5.530746688,	5.736873446,	5.950682393,	6.172459837,	6.40250276,	--   50
    7.068689434,	7.804193483,	8.616227447,	9.51275434,	10.50256573,	--   55
    11.59536797,	12.80187735,	14.1339252,	15.60457394,	21.00000006,	--   60
};

local mna_cnv = {
  52,	54,	57,	60,	62,	--    5
  66,	69,	72,	76,	80,	--   10
  86,	93,	101,	110,	119,	--   15
  129,	140,	152,	165,	178,	--   20
  193,	210,	227,	246,	267,	--   25
  289,	314,	340,	369,	400,	--   30
  433,	469,	509,	551,	598,	--   35
  648,	702,	761,	825,	894,	--   40
  969,	1050,	1138,	1234,	1337,	--   45
  1449,	1571,	1702,	1845,	2000,	--   50
  2349,	2759,	3241,	3807,	4472,	--   55
  5253,	6170,	7247,	8513,	10000,	--   60
};



function addon:SetupConversionFactors()
	addon.IntConv		= 1.05; --int to SP conversion factor
	
	local mastery_factor = 1;
	
	if ( self:IsRestoDruid() ) then
		mastery_factor = 2.0;
	elseif ( self:IsRestoShaman() ) then
		mastery_factor = 1/3;
	elseif ( self:IsHolyPriest() ) then
		mastery_factor = 4/5;
	elseif ( self:IsHolyPaladin() ) then
		mastery_factor = 2/3;
	elseif ( self:IsMistweaverMonk() ) then
		mastery_factor = 1/3;
	elseif ( self:IsDiscPriest() ) then
		mastery_factor = 5/6;
	end
	
	--TODO we gotta make these use a function that takes your current % of the stat as parameter
	local level = UnitLevel("Player");
	level = math.max(level,1);
	addon.CritConv 		= crt_cnv[level]*100;
	addon.HasteConv 	= hst_cnv[level]*100;
	addon.VersConv 		= vrs_cnv[level]*100;
	addon.MasteryConv 	= mst_cnv[level]*100 * mastery_factor;
	addon.LeechConv		= lee_cnv[level]*100;
	addon.ManaPool 		= mna_cnv[level]*5;
end



--[[----------------------------------------------------------------------------
	UpdatePlayerStats - Update stats for current player.
------------------------------------------------------------------------------]]
function addon:UpdatePlayerStats()
	self.ply_sp  = GetSpellBonusDamage(4);
    self.ply_crt = GetCritChance() / 100;
	self.ply_hst = UnitSpellHaste("Player") / 100;
	self.ply_vrs = (GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)) / 100;
	self.ply_mst = GetMasteryEffect() / 100;
	self.ply_lee = GetLifesteal() / 100;
    
	--Adjust for haste multiplier effects
	local haste_multiplier = 1;
	if ( addon.BuffTracker:Get(addon.BloodlustId)>0 or
		 addon.BuffTracker:Get(addon.HeroismId)>0 or
		 addon.BuffTracker:Get(addon.DrumsOfFuryId)>0 or
		 addon.BuffTracker:Get(addon.TimewarpId)>0 or
		 addon.BuffTracker:Get(addon.PrimalRageId)>0 ) then
		haste_multiplier = haste_multiplier * 1.30;
	end
	if ( addon.BuffTracker:Get(addon.BerserkingId)>0 ) then
		haste_multiplier = haste_multiplier * 1.15;
	end
	if ( addon.BuffTracker:Get(addon.Paladin.HolyAvenger)>0) then
		haste_multiplier = haste_multiplier * 1.30;
	end
	self.ply_hst = math.max((1+self.ply_hst) / haste_multiplier - 1,0);
	
	--adjust for intellect multiplier effects
	if ( addon.BuffTracker:Get(addon.ArcaneIntellectId)>0 ) then
		self.IntConv = 1.05*1.05;
	else
		self.IntConv = 1.05;
	end
	
	--Adjust for crit bonus effects
	local race = UnitRace("Player");
	self.ply_crtbonus = 1;
	if ( race == "Tauren") then
		self.ply_crtbonus = self.ply_crtbonus * 1.04; --yes 1.04, not 1.02
    end
	if ( IsEquippedItem("Drape of Shame") ) then 
		self.ply_crtbonus = self.ply_crtbonus * 1.05;
    end
	if ( addon.critBonus ) then
		self.ply_crtbonus = self.ply_crtbonus * (1+addon.critBonus);
	end
end


--[[----------------------------------------------------------------------------
Basic Stat Derivative Calculations
------------------------------------------------------------------------------]]
--Int
local function _Intellect(ev,s,heal,destUnit,SP,f)
	if ( f and f.Intellect ) then
		return f.Intellect(ev,s,heal,destUnit,SP);
	end
	
	if ( s.int ) then
		return (heal / SP) * addon.IntConv;
	end
	
	return 0;
end

--Crit
--CB is a bonus to critical strike healing (Drape of Shame, Tauren Racial, etc)
local function _CriticalStrike(ev,s,heal,destUnit,C,CB,f)
	if ( f and f.CriticalStrike ) then
		return f.CriticalStrike(ev,s,heal,destUnit,C,CB);
	end
	
	C = math.min(C,1.00); --clamp crit chance at 100%
	
	if ( s.crt ) then
		return heal*CB / (1+C*CB) / addon.CritConv;
	end
	
	return 0;
end

--Haste (returns hpm and hpct values)
local function _Haste(ev,s,heal,destUnit,H,f)
	if ( f and f.Haste ) then
		return f.Haste(ev,s,heal,destUnit,H);
	end
	if not H then
		return 0;
	end
	local canHPM = s.hstHPM or (s.hstHPMPeriodic and ev == "SPELL_PERIODIC_HEAL");
	local canHPCT2 = canHPM and s.hstHPCT;
	local canHPCT1 = canHPM or s.hstHPCT;
	
	local hpm = 0;
	local hpct = 0;
	
	if ( canHPM ) then
		hpm = heal / (1+H) / addon.HasteConv;
	end
	
	if (canHPCT2) then
		hpct = 2*heal / (1+H) / addon.HasteConv;
	elseif (canHPCT1) then
		hpct = heal / (1+H) / addon.HasteConv;
	end
	
	if ( s.hstHPMequalsHPCT ) then
		hpm = hpct;
	end

	return hpm,hpct;
end

--Vers
local function _Versatility(ev,s,heal,destUnit,V,f)
	if ( f and f.Versatility ) then
		return f.Versatility(ev,s,heal,destUnit,V);
	end
	
	if ( s.vrs ) then
		return heal / (1+V) / addon.VersConv;
	end
	
	return 0;
end

--Mastery
local function _Mastery(ev,s,heal,destUnit,M,ME,f)
	if ( f and f.Mastery ) then
		return f.Mastery(ev,s,heal,destUnit,M,ME)
	end
	
	if ( s.mst ) then
		return heal / ( 1+M ) / addon.MasteryConv; 
	end
	
	return 0;
end

--Leech
local function _Leech(ev,s,heal,destUnit,L,f)
	if ( f and f.Leech ) then
		return f.Leech(ev,s,heal,destUnit,L);
	end
	
	if s.lee and destUnit ~= "player" and (UnitHealth("player")+(heal*L)) < UnitHealthMax("player") then
		return heal / (1+L) / addon.LeechConv;
	end
	
	return 0;
end

local BaseParsers = {
	Intellect = _Intellect,
	CriticalStrike = _CriticalStrike,
	Haste = _Haste,
	Versatility = _Versatility,
	Mastery = _Mastery,
	Leech = _Leech
}



--[[----------------------------------------------------------------------------
	StatParser - Create & Get combat log parsers for each spec
------------------------------------------------------------------------------]]
local StatParser = {};



--[[----------------------------------------------------------------------------
	Create - add a new stat parser to be used by the addon.
------------------------------------------------------------------------------]]
function StatParser:Create(id,func_I,func_C,func_H,func_V,func_M,func_L,func_HealEvent,func_DamageEvent)
	self[id] = {};
	if ( func_HealEvent ) then self[id].HealEvent = func_HealEvent; end
	if ( func_DamageEvent ) then self[id].DamageEvent = func_DamageEvent; end
	if ( func_I ) then self[id].Intellect = func_I; end
	if ( func_C ) then self[id].CriticalStrike = func_C; end
	if ( func_H ) then self[id].Haste = func_H; end
	if ( func_V ) then self[id].Versatility = func_V; end
	if ( func_M ) then self[id].Mastery = func_M; end
	if ( func_L ) then self[id].Leech = func_L; end
end


--[[----------------------------------------------------------------------------
	GetParserForCurrentSpec
------------------------------------------------------------------------------]]
function StatParser:GetParserForCurrentSpec()
    local i = GetSpecialization();
	local specId = GetSpecializationInfo(i);
	return self[specId and tonumber(specId) or 0],specId;
end

function StatParser:IncFillerHealing(heal)
	local cur_seg = addon.SegmentManager:Get(0);
	local ttl_seg = addon.SegmentManager:Get("Total");
	if ( cur_seg ) then
		cur_seg:IncFillerHealing(heal);
	end
	if ( ttl_seg ) then
		ttl_seg:IncFillerHealing(heal);
	end
end

function StatParser:IncBucket(key,amount)
	local cur_seg = addon.SegmentManager:Get(0);
	local ttl_seg = addon.SegmentManager:Get("Total");
	
	if ( cur_seg ) then
		cur_seg:IncBucket(key,amount);
	end
	if ( ttl_seg ) then
		ttl_seg:IncBucket(key,amount);
	end
end

function StatParser:IncChainSpellCast(spellID)
	local cur_seg = addon.SegmentManager:Get(0);
	local ttl_seg = addon.SegmentManager:Get("Total");
	
	if ( cur_seg ) then
		cur_seg:IncChainSpellCast(spellID);
	end
	if ( ttl_seg ) then
		ttl_seg:IncChainSpellCast(spellID);
	end
end

function StatParser:IncHealing(heal,updateFiller,updateTotal)
	local cur_seg = addon.SegmentManager:Get(0);
	local ttl_seg = addon.SegmentManager:Get("Total");
	if ( cur_seg ) then
		if ( updateFiller ) then
			cur_seg:IncFillerHealing(heal);
		end
		if ( updateTotal ) then
			cur_seg:IncTotalHealing(heal);
		end
	end
	if ( ttl_seg ) then
		if ( updateFiller ) then
			ttl_seg:IncFillerHealing(heal);
		end
		if ( updateTotal ) then
			ttl_seg:IncTotalHealing(heal);
		end
	end
end

function StatParser:Allocate(ev,spellInfo,heal,overhealing,destUnit,f,SP,C,CB,H,V,M,ME,L)
	local cur_seg = addon.SegmentManager:Get(0);
	local ttl_seg = addon.SegmentManager:Get("Total");
	local OH = overhealing>0
	local _I,_C,_Hhpm,_Hhpct,_M,_V,_L = 0,0,0,0,0,0,0;

	if ( HSW_ENABLE_FOR_TESTING ) then
		addon:Msg("allocate spellid="..(spellInfo.spellID or "unknown").." destunit="..destUnit.." amount="..heal);
	end
	
	if (not OH) then --allocate effective healing
		_I 	 			= _Intellect(ev,spellInfo,heal,destUnit,SP,f);
		_C				= _CriticalStrike(ev,spellInfo,heal,destUnit,C,CB,f) ;
		_Hhpm,_Hhpct	= _Haste(ev,spellInfo,heal,destUnit,H,f);
		_M	 			= _Mastery(ev,spellInfo,heal,destUnit,M,ME,f);
		_V	 			= _Versatility(ev,spellInfo,heal,destUnit,V,f);
		_L	 			= _Leech(ev,spellInfo,heal,destUnit,L,f);
	elseif ( addon.BuffTracker:Get(addon.VelensId) == 1 ) then --allow all normal healing, and 50% of overhealing to be counted
		heal = heal+overhealing*0.5;
		_I 	 			= _Intellect(ev,spellInfo,heal,destUnit,SP,f);
		_C				= _CriticalStrike(ev,spellInfo,heal,destUnit,C,CB,f);
		_Hhpm,_Hhpct	= _Haste(ev,spellInfo,heal,destUnit,H,f);
		_M	 			= _Mastery(ev,spellInfo,heal,destUnit,M,ME,f);
		_V	 			= _Versatility(ev,spellInfo,heal,destUnit,V,f);
		_L	 			= _Leech(ev,spellInfo,heal,destUnit,L,f);
	else --overhealing with no velens buff, so only possible to attribute leech
		_L	 			= _Leech(ev,spellInfo,heal,destUnit,L,f);
	end
	
	--Add derivatives to current & total segments
	if ( cur_seg ) then
		cur_seg:AllocateHeal(_I,_C,_Hhpm,_Hhpct,_V,_M,_L,spellInfo.spellID);
	end
	if ( ttl_seg ) then
		ttl_seg:AllocateHeal(_I,_C,_Hhpm,_Hhpct,_V,_M,_L,spellInfo.spellID);
	end
	
	--update display to user
	addon:UpdateDisplayStats();
end


function StatParser:AllocateDamageLeech(ev,spellInfo,amount,L)
	local _L = _Leech(ev,spellInfo,amount,nil,L,nil);
	local cur_seg = addon.SegmentManager:Get(0);
	local ttl_seg = addon.SegmentManager:Get("Total");
	
	--Track healing amount of filler spells vs overall healing. (For mp5 calculations)
	if ( cur_seg ) then
		cur_seg:AllocateHeal(0,0,0,0,0,0,_L);
	end
	if ( ttl_seg ) then
		cur_seg:AllocateHeal(0,0,0,0,0,0,_L);
	end
end

--[[----------------------------------------------------------------------------
	DecompHealingForCurrentSpec
------------------------------------------------------------------------------]]
function StatParser:DecompHealingForCurrentSpec(ev,destGUID,spellID,critFlag,heal,overhealing)
	local f,specId = self:GetParserForCurrentSpec();
	
	--check if parser exist for current spec
	if ( f ) then 
		--check if spellInfo is valid for current spec.
		local spellInfo = addon.Spells:Get(spellID);
		if ( spellInfo and (spellInfo.spellType == specId or spellInfo.spellType == addon.SpellType.SHARED) ) then
			--make sure destGUID describes a valid unit (Exclude healing to pets/npcs)
			local destUnit = addon.UnitManager:Find(destGUID);
			if destUnit then 
				
				--Reduce crit heals down to the non-crit amount
				local OH = overhealing and overhealing>0;
				local orig_heal = heal;
				if ( critFlag ) then
					heal = heal / ( 1 + addon.ply_crtbonus );
					overhealing = OH and overhealing / ( 1 + addon.ply_crtbonus ) or 0;
				end
				
				--Allow the class parser to do pre-computations on this heal event
				local skipAllocate=false;
				if ( f.HealEvent ) then
					skipAllocate = f.HealEvent(ev,spellInfo,heal,overhealing,destUnit,f,orig_heal);
				end
				
				--filter out raid cooldowns if we are excluding them
				if ( addon.hsw.db.global.excludeRaidHealingCooldowns and spellInfo.cd ) then
					return;
				end
				
				--Track healing amount of filler spells vs overall healing. (For mp5 calculations)
				self:IncHealing(orig_heal,spellInfo.filler,true);
				
				--Allocate healing derivatives for each stat
				if ( not skipAllocate ) then
					self:Allocate(ev,spellInfo,heal,overhealing,destUnit,f,addon.ply_sp,addon.ply_crt,addon.ply_crtbonus,addon.ply_hst,addon.ply_vrs,addon.ply_mst,nil,addon.ply_lee);
				end
			end
		elseif ( not spellInfo ) then
			addon:DiscoverIgnoredSpell(spellID);
		end
	end
end



--[[----------------------------------------------------------------------------
	DecompDamageDone
------------------------------------------------------------------------------]]
function StatParser:DecompDamageDone(amt,spellID,critFlag)
	local f,specId = self:GetParserForCurrentSpec();
	
	local spellInfo = addon.Spells:Get(spellID);
	if ( spellInfo and (spellInfo.spellType == specId or spellInfo.spellType == addon.SpellType.SHARED) ) then
		if ( f and f.DamageEvent ) then 
			f.DamageEvent(spellInfo,amt,critFlag);
		end
		
		self:AllocateDamageLeech("SPELL_DAMAGE",spellInfo,amt,addon.ply_lee);
	end
end



--[[----------------------------------------------------------------------------
	DecompDamageTaken
------------------------------------------------------------------------------]]
function StatParser:DecompDamageTaken(amt,dontClamp)
	amt = amt or 0;
	
	if not dontClamp then
		amt = math.min(UnitHealthMax("Player"),amt);
	end
	
	local V = addon.ply_vrs/2;
	if ( V >= 1 ) then
		return 0;
	end
	
	amt = amt / (1-V) / (addon.VersConv*2);
	
	--Add derivatives to current & total segments
	local cur_seg = addon.SegmentManager:Get(0);
	local ttl_seg = addon.SegmentManager:Get("Total");
	if ( cur_seg ) then
		cur_seg:AllocateHealDR(amt);
	end
	if ( ttl_seg ) then
		ttl_seg:AllocateHealDR(amt);
	end
end



--[[----------------------------------------------------------------------------
	IsCurrentSpecSupported - Check if current spec is supported
------------------------------------------------------------------------------]]
function StatParser:IsCurrentSpecSupported()
	local f = self:GetParserForCurrentSpec();
	
	if ( f ) then
		return true;
	else
		return false;
	end
end


addon.BaseParsers = BaseParsers;
addon.StatParser = StatParser;