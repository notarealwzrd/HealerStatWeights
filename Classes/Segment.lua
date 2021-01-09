local name, addon = ...;
local date = date;


--[[----------------------------------------------------------------------------
	Segment Class - Stores stat allocations
------------------------------------------------------------------------------]]
local Segment = {};



--[[----------------------------------------------------------------------------
	Helper Functions
------------------------------------------------------------------------------]]
--Create and return an empty stat table
local function getStatTable() 
	local t = {};
	t.int = 0;
	t.crit = 0;
	t.haste_hpm = 0; --haste hpc
	t.haste_hpct = 0;--haste hpct's upper-bound
	t.vers = 0;
	t.vers_dr = 0;
	t.mast = 0;
	t.leech = 0;
	return t;
end

--shallow table copy
local copy = addon.Util.CopyTable;



--[[----------------------------------------------------------------------------
	Segment.Create - Create a new Segment object with the given id/name
------------------------------------------------------------------------------]]
function Segment.Create(id) 
	local self = copy(Segment);
	self.t = getStatTable();
	self.id = id;
	self.nameSet = false;
	self.totalHealing = 0;
	self.fillerHealing = 0;
	self.fillerCasts = 0;
	self.fillerInt = 0;
	self.fillerHealingReduced = 0;
	self.fillerManaSpent = 0; 
	self.totalDuration = 0;
	self.manaRestore = 0;
	self.startTime = GetTime();
	self.startTimeStamp = date("%b %d, %I:%M %p");
	self.chainHaste = 0;
	self.chainCasts = 0;
	self.debug = {};
	self.casts = {};
	self.buckets = {};
	self.casts_hst = {};
	self.instance = {};
	self.instance.id = -1;
	self.instance.name = "";
	self.instance.level = -1;
	self.instance.difficultyId = -1;
	self.instance.bossFight = false;
	return self;
end



--[[----------------------------------------------------------------------------
	GetMP5 - MP5 estimation, normalized to int value
------------------------------------------------------------------------------]]
function Segment:GetMP5()
	if ( self.fillerManaSpent == 0 or self.fillerCasts == 0 ) then
		return 0;
	end
	
	local duration = self:GetDuration();
	if ( duration == 0 ) then
		return 0;
	end
	
	local int = self.fillerInt / self.fillerCasts;
	local fillerHPM = self.fillerHealing / (self.fillerManaSpent*addon.ManaPool);
	local HPS = self.totalHealing / duration;

	if ( HPS > 0 ) then
		return int * (fillerHPM/5) / (HPS);
	end
	
	return 0;
end



--[[----------------------------------------------------------------------------
	GetHasteHPCT - Haste HPCT estimation using filler spells
------------------------------------------------------------------------------]]
function Segment:GetHasteHPCT()
	if ( self.chainCasts == 0 or self.fillerCasts == 0 ) then
		return self.t.haste_hpm;
	end
	
	local hpct_est_added;
	local hpct_upper_bound;
	
	if ( addon:IsDiscPriest() ) then
		local xfer_casts,xfer_H,_ = self:GetBucketInfo(addon.DiscPriest.CastXfer);
		local applicator_casts,applicator_H,_ = self:GetBucketInfo(addon.DiscPriest.CastApplicator);
		local sm_casts,sm_H,sm_amt = self:GetBucketInfo(addon.DiscPriest.CastShadowMend);
		local _,_,pws_amt = self:GetBucketInfo(addon.DiscPriest.CastPWS);
		local _,_,smite_amt = self:GetBucketInfo(addon.DiscPriest.CastSmite); 
		
		local pws_added = (applicator_casts-sm_casts) * pws_amt / ( 1 + applicator_H ) / addon.HasteConv;
		local sm_added = sm_casts * sm_amt / ( 1 + sm_H ) / addon.HasteConv;
		local xfer_added = xfer_casts * smite_amt / ( 1 + xfer_H) / addon.HasteConv;
		
		hpct_est_added = pws_added + sm_added + xfer_added;
		hpct_upper_bound = 2*self.t.haste_hpct;
	else
		local avgFillerHealingPerCast = (self.fillerHealing-self.fillerHealingReduced) / self.fillerCasts;
		local avgHasteDuringChainCasts = self.chainHaste / self.chainCasts;
		
		hpct_est_added = avgFillerHealingPerCast * self.chainCasts / ( 1 + avgHasteDuringChainCasts ) / addon.HasteConv;
		hpct_upper_bound = self.t.haste_hpct;
	end
	
	local haste_hpct = math.min(self.t.haste_hpm+hpct_est_added, hpct_upper_bound);
	return haste_hpct;
end

function Segment:GetHaste()
	return math.min(self.t.haste_hpm,addon:IsDiscPriest() and 2*self.t.haste_hpct or self.t.haste_hpct);
end


--[[----------------------------------------------------------------------------
	GetManaRestoreValue - Get the estimated value of the restored mana on this segment
------------------------------------------------------------------------------]]
function Segment:GetManaRestoreValue()
	local denom = self.fillerManaSpent*addon.ManaPool;
	
	if ( denom == 0 ) then
		return 0;
	end
	
	local fillerHPM = self.fillerHealing / denom;
	return fillerHPM * self.manaRestore;
end



--[[----------------------------------------------------------------------------
	AllocateHeal - increment cumulative healing totals for the given stats
------------------------------------------------------------------------------]]
function Segment:AllocateHeal(int,crit,haste_hpm,haste_hpct,vers,mast,leech,spellId)
	self.t.int		 	= self.t.int		 + int;
	self.t.crit			= self.t.crit	 	 + crit;
	self.t.haste_hpm	= self.t.haste_hpm	 + haste_hpm;
	self.t.haste_hpct	= self.t.haste_hpct  + haste_hpct;
	self.t.vers 	 	= self.t.vers		 + vers;
	self.t.vers_dr  	= self.t.vers_dr	 + vers;
	self.t.mast 	 	= self.t.mast		 + mast;
	self.t.leech 	 	= self.t.leech	 	 + leech;
	
	if HSW_ENABLE_FOR_TESTING and spellId then
		self.debug[spellId] = self.debug[spellId] and self.debug[spellId]+int or int;
	end
end



--[[----------------------------------------------------------------------------
	GetDuration - get the length of this segment in seconds
------------------------------------------------------------------------------]]
function Segment:GetDuration()
	local d = self.totalDuration;
	if ( self.startTime >= 0 ) then
		d = d + (GetTime() - self.startTime);
	end
	return d;
end



--[[----------------------------------------------------------------------------
	End - the segment is no longer live, duration is fixed.
------------------------------------------------------------------------------]]
function Segment:End()
	self:SnapshotTalentsAndEquipment();

	self.totalDuration = self.totalDuration + (GetTime() - self.startTime);
	self.startTime = -1;
end



--[[----------------------------------------------------------------------------
	SnapshotTalentsAndEquipment
------------------------------------------------------------------------------]]
local function FetchItemInfoFromSlot(t,id)
	if ( id and tonumber(id) ) then
		local link = GetInventoryItemLink("player",id);
		if ( link ) then
			local name,_,_,ilvl,_,_,_,_,_,icon = GetItemInfo(link);

			if ( ilvl and icon and name ) then
				t[id] = {
					link=link,
					name=name,
					ilvl=ilvl,
					icon=icon
				};
			end
		end
	end
end

function Segment:SnapshotTalentsAndEquipment() 
	self.talentsSnapshot = true;
	self.selectedTalents = {};
	local r,c;
	local specGroupIndex = 1;

	for r=1,MAX_TALENT_TIERS,1 do 
		for c=1,NUM_TALENT_COLUMNS,1 do
			local _, _, _, selected, _, spellID = GetTalentInfo(r,c,specGroupIndex);
			if ( selected ) then
				table.insert(self.selectedTalents,spellID);
			end
		end
	end
	
	self.gear = self.gear or {};
	FetchItemInfoFromSlot(self.gear,13);
	FetchItemInfoFromSlot(self.gear,14);
end


--[[----------------------------------------------------------------------------
	AllocateHealDR - increment cumulative heal DR totals for the given stats
------------------------------------------------------------------------------]]
function Segment:AllocateHealDR(versatilityDR)
	self.t.vers_dr		= self.t.vers_dr	+ versatilityDR;
end



--[[----------------------------------------------------------------------------
	Increment functions
------------------------------------------------------------------------------]]
function Segment:IncChainCasts()
	self.chainHaste = self.chainHaste + addon.ply_hst;
	self.chainCasts = self.chainCasts + 1;
end

function Segment:IncTotalHealing(amount)
	self.totalHealing = self.totalHealing + amount;
end

function Segment:IncFillerHealing(amount)
	self.fillerHealing = self.fillerHealing + amount;
end

function Segment:IncFillerCasts(manaCost)
	self.fillerCasts = self.fillerCasts + 1;
	self.fillerManaSpent = self.fillerManaSpent + manaCost;
	self.fillerInt = self.fillerInt + (addon.ply_sp / addon.IntConv);
end			

function Segment:IncManaRestore(amount)
	self.manaRestore = self.manaRestore + amount;
end



--[[----------------------------------------------------------------------------
	Auxiliary data (Buckets)
------------------------------------------------------------------------------]]
function Segment:IncBucket(key,amount)
	if not self.buckets[key] then
		self.buckets[key] = 0;
	end
	self.buckets[key] = self.buckets[key]+amount;
end

function Segment:IncChainSpellCast(key)
	if not self.casts[key] then
		self.casts[key] = 1;
		self.casts_hst[key] = addon.ply_hst;
	else 
		self.casts[key] = self.casts[key] + 1;
		self.casts_hst[key] = self.casts_hst[key] + addon.ply_hst;
	end
end

function Segment:GetBucketInfo(key)
	local casts = self.casts[key] or 0;
	local haste_avg = casts>0 and self.casts_hst[key] and (self.casts_hst[key]/casts) or 0;
	local bucket_avg = casts>0 and self.buckets[key] and (self.buckets[key]/casts) or 0;
	return casts,haste_avg,bucket_avg;
end



--[[----------------------------------------------------------------------------
	SetupInstanceInfo - information about the instance this segment uses
------------------------------------------------------------------------------]]
function Segment:SetupInstanceInfo(isBossFight)
	local map_level, _, _ = C_ChallengeMode.GetActiveKeystoneInfo();
	local map_id = C_ChallengeMode.GetActiveChallengeMapID();
	local map_name = map_id and C_ChallengeMode.GetMapUIInfo and C_ChallengeMode.GetMapUIInfo(map_id) or "";	
	local _,_,id = GetInstanceInfo();
	
	self.instance.id = map_id;
	self.instance.name = map_name;
	self.instance.level = map_level;
	self.instance.difficultyId = id;
	self.instance.bossFight = isBossFight;
end

function Segment:GetInstanceInfo()
	return self.instance;
end

--[[----------------------------------------------------------------------------
	MergeSegment - merge information from another segment into this one.
				 - only call this after both segments have Ended with segment:End()
------------------------------------------------------------------------------]]
function Segment:MergeSegmentHelper(other,tableKey)
	local keys = {};
	for k,v in pairs(self[tableKey]) do 
		if type(v) == "number" then
			keys[k] = true;
		end
	end
	for k,v in pairs(other[tableKey]) do
		if type(v) == "number" then
			keys[k] = true;
		end
	end
	for k,_ in pairs(keys) do
		self[tableKey][k] = (self[tableKey][k] or 0) + (other[tableKey][k] or 0);
	end
end
	
function Segment:MergeSegment(other)
	local skip = {
		["totalDuration"]=true,
		["startTime"]=true,
		["startTimeStamp"]=true,
		["gear"] = true
	}
	
	self:MergeSegmentHelper(other,"t");
	self:MergeSegmentHelper(other,"casts");
	self:MergeSegmentHelper(other,"casts_hst");
	self:MergeSegmentHelper(other,"buckets");
	
	for k,v in pairs(self) do
		if ( type(v) == "number" and not skip[k] ) then
			self[k] = self[k] + (other[k] or 0.0);
		end
	end
	
	self.totalDuration = self.totalDuration + other:GetDuration();
end



--[[----------------------------------------------------------------------------
	Debug - print internal values of this segment to chat
------------------------------------------------------------------------------]]
function Segment:Debug()
	local tbl_header = function() print("=======") end;
	print("StatTable");
	tbl_header();
	for k,v in pairs(self.t) do
		if ( type(v) ~= "function" and type(v) ~= "table" ) then
			print(string.format("t.%s = %.5f", k, v));
		end
	end
	
	print("InstanceInfo");
	tbl_header();
	for k,v in pairs(self.instance) do
		if ( type(v) ~= "function" and type(v) ~= "table" ) then
			print("instance."..tostring(k),"=",v);
		end
	end
	
	print("Metadata");
	tbl_header();
	for k,v in pairs(self) do
		if ( type(v) ~= "function" and type(v) ~= "table" ) then
			if (type(v) == "number") then
				print(string.format("%s = %.5f", k, v));
			else
				print(k,"=",v);
			end
		end
	end
	
	print("Int SpellID Buckets");
	tbl_header();
	local intMainSum = 0;
	for k,v in pairs(self.debug) do
		print(string.format("%s = %.5f", k, v));
		intMainSum = intMainSum + v;
	end
	
	print("Calculated Values");
	tbl_header();	
	local mp5 = self:GetMP5();
	local duration = self:GetDuration();
	print("mp5 =",mp5);
	print(string.format("duration = %.5f",duration));
end

addon.Segment = Segment;