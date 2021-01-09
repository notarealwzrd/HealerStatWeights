local name,addon = ...;
local hsw = LibStub("AceAddon-3.0"):NewAddon("HealerStatWeights", "AceConsole-3.0", "AceEvent-3.0")
local media = LibStub("LibSharedMedia-3.0");
local lsmlists = AceGUIWidgetLSMlists;


--[[----------------------------------------------------------------------------
Defaults
------------------------------------------------------------------------------]]
local function Color(r,g,b,a)
	local t = {};
	t.r = r;
	t.g = g;
	t.b = b;
	t.a = a or 1;
	return t;
end
local hswOptionsFrame;

local defaults = {
	global = {
		excludeRaidHealingCooldowns=false,
		useHPMoverHPCT=true,
		autoAssignHasteSetting=true,
		useVersDR=false,
		useCritResurg=false,
		fontSize=12,
		frameWidth=192,
		enabledInNormalDungeons=false,
		enabledInHeroicDungeons=false,
		enabledInMythicDungeons=false,
		enabledInMythicPlusDungeons=true,
		enabledInLfrRaids=false,
		enabledInNormalRaids=false,
		enabledInHeroicRaids=false,
		enabledInMythicRaids=true,
		frameLocked=false,
		maxSegments=10,
		back=0,
		front=0,
		historySize=200,
		alwaysShow=false,
		alwaysEnabled=false,
		fontColor=Color(1,1,1,1),
		fontStr=false,
		history={}
	}
}


local historySelected = 0;
local int_label = "Intellect";
local int_pct_label = "Intellect\nPer 1% HPS";
local crt_label = "Critical Strike";
local crt_pct_label = "Critical Strike\nPer 1% HPS";
local crt2_label = "Critical Strike\n+Resurgence";
local crt2_pct_label = "Critical Strike\n+Resurgence\nPer 1% HPS";
local crt2_label_old = "Critical Strike (+Resurgence)";
local hst_label = "Haste HPM\n(Haste per Cast)";
local hst_pct_label = "Haste HPM\nPer 1% HPS";
local hst_label_old = "Haste per Cast";
local hst2_label = "Haste HPCT\n(Haste per Cast Time)";
local hst2_pct_label = "Haste HPCT\nPer 1% HPS";
local hst2_label_old = "Haste per Cast Time (Estimated)";
local hst3_label = "Haste per Cast Time (Upper-bound)";
local vrs_label = "Versatility";
local vrs_pct_label = "Versatility\nPer 1% HPS";
local vrs2_label = "Versatility\n+Damage Reduction";
local vrs2_pct_label = "Versatility+DR\nPer 1% HPS";
local vrs2_label_old = "Versatility (+Damage Reduction)";
local mst_label = "Mastery";
local mst_pct_label = "Mastery\nPer 1% HPS";
local mp5_label = "MP5 (Estimated)";
local mp5_pct_label = "MP5 (Estimated)\nPer 1% HPS";
local lee_label = "Leech";
local lee_pct_label = "Per 1% HPS";
local cls_label = "Class/Spec";
local sgmt_label = "Segment";
local dur_label = "Duration";
local name_label = "Name";
local region_label = "Region";
local realm_label = "Realm";
local specid_label = "SpecID";
local talents_label = "Talents";
local datetime_label = "Date/Time";
local trinket1_label = "Trinket 1";
local trinket2_label = "Trinket 2";

local num_pattern = "%.2f";

local DropdownLabels = {
	Crt			= 	"Critical Strike",
	CrtRes		=	"Critical Strike (+Resurgence)",
	Hst			=	"Haste HPM",
	HstHPCT		=	"Haste HPCT",
	Vrs			=	"Versatility",
	VrsDR		=	"Versatility (+Damage Reduction)"
}

local globalResources = {
	{
		key="Do Stats Matter?",
		value="A little. But, not as much as you might think. Seriously, simple gameplay improvements have a much larger impact on performance than your stats... and this is coming from someone who wrote an entire addon to calculate statweights for you. :)"
	},
	{
		key="Community\nTools & Links",
		value="So, if you're interested in really improving your game, check out these additional tools/resources/communities to stay up-to-date with the current gameplay & recommendations for your spec."
	},
}

local DropdownLabelsRev = {};
for k,v in pairs(DropdownLabels) do
	DropdownLabelsRev[v] = k;
end

local SegmentLabels = {
	Int						=	int_label,
	IntPct					=	int_pct_label,
	Crt						=	crt_label,
	CrtPct					=	crt_pct_label,
	CrtRes					=	crt2_label,
	CrtResPct				=	crt2_pct_label,
	CrtResOld				=	crt2_label_old,
	Hst						=	hst_label,
	HstPct					= 	hst_pct_label,
	HstOld					=	hst_label_old,
	HstHPCT					= 	hst2_label,
	HstHPCTPct				=	hst2_pct_label,
	HstHPCTOld				=	hst2_label_old,
	Vrs						=	vrs_label,
	VrsPct					=	vrs_pct_label,
	VrsDR					= 	vrs2_label,
	VrsDRPct				= 	vrs2_pct_label,
	VrsDROld				=	vrs2_label_old,
	Mst						=	mst_label,
	MstPct					= 	mst_pct_label,
	Mp5						=	mp5_label,
	Mp5Pct					= 	mp5_pct_label,
	Lee						=	lee_label,
	LeePct					=	lee_pct_label,
	Class					=	cls_label,
	Talents					=	talents_label,
	Segment					=	sgmt_label,
	Duration				=	dur_label,
	Name					=	name_label,
	Region					=	region_label,
	Realm					=	realm_label,
	SpecID					=	specid_label,
	DateTime				= 	datetime_label,
	Slot13					= 	trinket1_label,
	Slot14					= 	trinket2_label
};



local spec_labels = {
	[105] = "Restoration Druid",
	[264] = "Restoration Shaman",
	[257] = "Holy Priest",
	[65] = "Holy Paladin",
	[270] = "Mistweaver Monk",
	[256] = "Discipline Priest"
}
local class_id_lookup = {
	["Restoration Druid"] = {class=11,spec=4},
	["Discipline Priest"] = {class=5,spec=1},
	["Holy Priest"] = {class=5,spec=2},
	["Holy Paladin"] = {class=2,spec=1},
	["Mistweaver Monk"] = {class=10,spec=2},
	["Restoration Shaman"] = {class=7,spec=3},
}

--[[----------------------------------------------------------------------------
Options
------------------------------------------------------------------------------]]

local _TEST=nil;
local options = {
	name = "Healer Stat Weights",
	handler = hsw,
	childGroups = "tab",
	type = "group",
	args = {
		optionsTab = { 
			name = "Options",
			type = "group",
			order = 1,
			args = {
				headerSettings = {
					name = "Calculation Settings",
					desc = "These settings control which calculations are performed. Can be toggled retroactively for past segments.",
					type = "header",
					order = 1
				},
				useHPM = {
					name = "Exclude Haste Effects on Cast Time (Use HPM over HPCT)",
					desc = "When checked, excludes the effects of haste on increased cast time. Can be toggled retroactively for past segments.",
					type = "toggle",
					order = 3,
					width = "full",
					get = function(info) return hsw.db.global.useHPMoverHPCT end,
					set = function(info,val) hsw.db.global.useHPMoverHPCT = val; addon:UpdateDisplayLabels(); addon:UpdateDisplayStats(); end
				},
				useVersDR = {
					name = "Include Damage Reduction effects on Versatility",
					desc = "When checked, includes the damage reduction effects of versatility. Can be toggled retroactively for past segments.",
					type = "toggle",
					order = 4,
					width = "full",
					get = function(info) return hsw.db.global.useVersDR end,
					set = function(info,val) hsw.db.global.useVersDR = val; addon:UpdateDisplayLabels(); addon:UpdateDisplayStats(); end
				},
				useCritResurg = {
					name = "Include Resurgence effects on Critical Strike (Shaman Only)",
					desc = "When checked, includes the value from mana gained through resurgence in the critical strike rating. Can be toggled retroactively for past segments.",
					type = "toggle",
					order = 5,
					width = "full",
					get = function(info) return hsw.db.global.useCritResurg end,
					set = function(info,val) hsw.db.global.useCritResurg = val; addon:UpdateDisplayLabels(); addon:UpdateDisplayStats(); end
				},
				excludeBigCDs = {
					name = "Exclude Raid Healing Cooldowns",
					desc = "When checked, excludes effects from big healing cooldowns, such as tranquility. Is NOT retroactive for past segments. Set this value before starting combat.",
					type = "toggle",
					order = 6,
					width = "full",
					get = function(info) return hsw.db.global.excludeRaidHealingCooldowns end,
					set = function(info,val) hsw.db.global.excludeRaidHealingCooldowns = val end
				},
				headerUI = {
					name = "UI Settings",
					desc = "These settings affect the UI of the addon.",
					type = "header",
					order = 8
				},
				
				neverShowFrame = {
					name = "Never Show Stats Frame",
					type = "toggle",
					desc = "This setting hides the stats panel. Enabled content will still get logged to the history tab.",
					order = 9.1,
					width = "full",
					get = function(info) return hsw.db.global.neverShow end,
					set = function(info,val) 
						if ( val ) then
							hsw.db.global.alwaysShow = false;		
						end
						hsw.db.global.neverShow=val; 
						addon:AdjustVisibility(); 
					end
				},

				showFrame = {
					name = "Always Show Stats Frame",
					type = "toggle",
					desc = "This setting makes the display panel ALWAYS show, regardless of content. By default, the frame only shows on enabled content.",
					order = 9.2,
					width = "full",
					disabled = function(info) return hsw.db.global.neverShow end,
					get = function(info) return hsw.db.global.alwaysShow end,
					set = function(info,val) hsw.db.global.alwaysShow=val; addon:AdjustVisibility(); end
				},
				frameLocked = {
					name = "Lock Frame",
					desc = "Disable moving the stat weights frame by clicking & dragging.",
					type = "toggle",
					order = 10,
					width = "full",
					disabled = function(info) return hsw.db.global.neverShow end,
					get = function(info) return hsw.db.global.frameLocked end,
					set = function(info,val) 
						hsw.db.global.frameLocked = val;
						if ( val ) then 
							addon:Lock(); 
						else 
							addon:Unlock(); 
						end
					end
				},
				fontSize = {
					name = "Font Size",
					desc = "Adjust the font size of the stat weights frame.",
					type = "range",
					order=11,
					min=8,
					max=18,
					step=1,
					get = function(info) return hsw.db.global.fontSize end,
					set = function(info,val) 
						hsw.db.global.fontSize = val;
						addon:AdjustFontSizes();
					end
				},
				frameWidth = {
					name = "Frame Width",
					desc = "Adjust the width of the stat weights frame.",
					type = "range",
					order=12,
					min=128,
					max=256,
					step=1,
					get = function(info) return hsw.db.global.frameWidth end,
					set = function(info,val) 
						hsw.db.global.frameWidth = val;
						addon:AdjustWidth(val);
					end
				},
				resetPosition = {
					name = "Reset Position",
					desc = "Reset the frame's position to the center of the screen.",
					type = "execute",
					order = 13,
					func = function() addon:ResetFramePosition() end
				},
				fontStr = {
					type = "select",
					name = "Font Type",
					dialogControl = "LSM30_Font",
					order = 14,
					values = lsmlists.font,
					get = function(info) return hsw.db.global.fontStr; end,
					set = function(info,val) hsw.db.global.fontStr = val; addon:AdjustFonts() end
				},
				fontColor = {
					name = "Font Color",
					type = "color",
					order = 15,
					get = function(info) return hsw.db.global.fontColor.r,hsw.db.global.fontColor.g,hsw.db.global.fontColor.b,hsw.db.global.fontColor.a end,
					set = function(info,r,g,b,a) 
						hsw.db.global.fontColor = Color(r,g,b,a);
						addon:AdjustFontColor(); 
					end
				},
				headerContentAndDifficulty = {
					name = "Content and Difficulty",
					desc = "These settings control which content and difficulties to calculate statweights for.",
					type = "header",
					order = 20
				},
				enabledAlways = {
					name = "Always Enabled",
					desc = "It's recommended to only use this addon for instanced PVE, but this setting allows you to run the addon for ANY content.",
					type = "toggle",
					order = 21,
					width = "full",
					get = function(info) return hsw.db.global.alwaysEnabled end,
					set = function(info,val) hsw.db.global.alwaysEnabled = val; addon:AdjustVisibility(); end
				},
				enabledInNormalDungeons = {
					name = "Dungeons (Normal)",
					type = "toggle",
					order = 22,
					width = "full",
					disabled = function(info) return hsw.db.global.alwaysEnabled end,
					get = function(info) return hsw.db.global.enabledInNormalDungeons end,
					set = function(info,val) hsw.db.global.enabledInNormalDungeons = val; addon:AdjustVisibility(); end
				},
				enabledInHeroicDungeons = {
					name = "Dungeons (Heroic)",
					type = "toggle",
					order = 23,
					width = "full",
					disabled = function(info) return hsw.db.global.alwaysEnabled end,
					get = function(info) return hsw.db.global.enabledInHeroicDungeons end,
					set = function(info,val) hsw.db.global.enabledInHeroicDungeons = val; addon:AdjustVisibility(); end
				},
				enabledInMythicDungeons = {
					name = "Dungeons (Mythic)",
					type = "toggle",
					order = 24,
					width = "full",
					disabled = function(info) return hsw.db.global.alwaysEnabled end,
					get = function(info) return hsw.db.global.enabledInMythicDungeons end,
					set = function(info,val) hsw.db.global.enabledInMythicDungeons = val; addon:AdjustVisibility(); end
				},
				enabledInMythicPlusDungeons = {
					name = "Dungeons (Mythic+)",
					type = "toggle",
					order = 25,
					width = "full",
					disabled = function(info) return hsw.db.global.alwaysEnabled end,
					get = function(info) return hsw.db.global.enabledInMythicPlusDungeons end,
					set = function(info,val) hsw.db.global.enabledInMythicPlusDungeons = val; addon:AdjustVisibility(); end
				},
				enabledInLfrRaids = {
					name = "Raids (LFR)",
					type = "toggle",
					order = 26,
					width = "full",
					disabled = function(info) return hsw.db.global.alwaysEnabled end,
					get = function(info) return hsw.db.global.enabledInLfrRaids end,
					set = function(info,val) hsw.db.global.enabledInLfrRaids = val; addon:AdjustVisibility(); end
				},
				enabledInNormalRaids = {
					name = "Raids (Normal)",
					type = "toggle",
					order = 27,
					width = "full",
					disabled = function(info) return hsw.db.global.alwaysEnabled end,
					get = function(info) return hsw.db.global.enabledInNormalRaids end,
					set = function(info,val) hsw.db.global.enabledInNormalRaids = val; addon:AdjustVisibility(); end
				},
				enabledInHeroicRaids = {
					name = "Raids (Heroic)",
					type = "toggle",
					order = 28,
					width = "full",
					disabled = function(info) return hsw.db.global.alwaysEnabled end,
					get = function(info) return hsw.db.global.enabledInHeroicRaids end,
					set = function(info,val) hsw.db.global.enabledInHeroicRaids = val; addon:AdjustVisibility(); end
				},
				enabledInMythicRaids = {
					name = "Raids (Mythic)",
					type = "toggle",
					order = 29,
					width = "full",
					disabled = function(info) return hsw.db.global.alwaysEnabled end,
					get = function(info) return hsw.db.global.enabledInMythicRaids end,
					set = function(info,val) hsw.db.global.enabledInMythicRaids = val; addon:AdjustVisibility(); end
				}
			}
		},
		historyTab = {
			name = "History",
			desc = "A list of your 100 most-recent segments.",
			type = "group",
			order = 2,
			width = 2,
			args = {},
		},
		-- vocabTab = {
		-- 	name = "",
		-- 	type = "group",
		-- 	order = 3,
		-- 	args = {}
		-- }
	}
}
local BlizOptionsTable = {
	name = "Healer Stat Weights",
	type = "group",
	args = {
		btn = {
			name = "/hsw",
			type = "execute",
			width = 1.0,
			func = function()
				hsw:OpenOptions();
				InterfaceOptionsFrame_Show();
			end
		}
	}
}

function addon:BuildOptionsTableForHistorySegment(i)
	local i = i;
	local h = self.History:Get(i);

	if ( not h ) then
		return nil;
	end

	local OptionsBuilder = addon.OptionsBuilder.Create(h);

	local dateTimeStr = h.DateTime and ("|cFFCCCCCC"..h.DateTime.."|r ") or "";
	OptionsBuilder:AddText( dateTimeStr, 2.5 );
	OptionsBuilder:AddHeaderButton("Pawn >>","Export as Pawn String",function()
		historySelected = i;
		addon:CreatePawnStringFromHistory();
	end);
	OptionsBuilder:AddNewLine();

	local segmentName = h.Segment .. " ("..h.Duration..")";

	if ( h.SpecID ) then
		local _,_,_,icon = GetSpecializationInfoByID(h.SpecID);
		if ( icon ) then
			segmentName = "|T "..icon..":24|t ".. segmentName;
		end
	end
	

	OptionsBuilder:AddHeaderRow(segmentName);
	OptionsBuilder:AddHeaderButton("QE >>","Export to QE Live",function()
		historySelected=i; 
		addon:CreateQEStringFromHistory(); 
	end);
	OptionsBuilder:AddNewLine();
		
	--Talents
	local tbl = h.Talents;
	local str = "";
	if ( tbl ) then
		for i,spellId in ipairs(tbl) do
			local _,_,iconId = GetSpellInfo(spellId);
			if ( iconId ) then
				str = str .. "|T " .. tostring(iconId) .. ":24|t ";
			end
		end
	end
	
	local function gearStr(gearTbl) 
		if ( not gearTbl ) then
			return nil;
		end
		
		local str = "";
		str = str .. gearTbl.icon and ("|T "..tostring(gearTbl.icon) .. ":16|t ") or "";
		str = str .. (gearTbl.ilvl or "").. " ";
		str = str .. (gearTbl.link or "");
		return str;
	end
	
	OptionsBuilder:AddDivider("Gear & Talents");
	OptionsBuilder:AddNewLine();
	OptionsBuilder:AddHeaderRow(str);

	local slot13 = gearStr(h.Slot13);
	if ( slot13 ) then
		OptionsBuilder:AddNewLine();
		OptionsBuilder:AddHeaderRow(slot13);
		OptionsBuilder:AddNewLine();
	end

	local slot14 = gearStr(h.Slot14);
	if ( slot14 ) then
		OptionsBuilder:AddNewLine();
		OptionsBuilder:AddHeaderRow(slot14);
		OptionsBuilder:AddNewLine();
	end

	OptionsBuilder:AddNewLine();
	

	--Stat weights
	
	local pctOptions = {
		Type="integer"
	};

	OptionsBuilder:AddDivider("Stat Weights");
	OptionsBuilder:AddKVPair("Int");
	OptionsBuilder:AddKVPair("Mp5");
	OptionsBuilder:AddNewLine();
	OptionsBuilder:AddNewLine();
	
	OptionsBuilder:AddKVPair("Crt");
	if ( h.SpecID == addon.SpellType.SHAMAN ) then
		OptionsBuilder:AddKVPair("CrtRes");
	else
		OptionsBuilder:AddKVPairRaw("","",{Type="string"});
	end
	OptionsBuilder:AddNewLine();
	OptionsBuilder:AddNewLine();
	
	OptionsBuilder:AddKVPair("Hst");
	OptionsBuilder:AddKVPair("HstHPCT");
	OptionsBuilder:AddNewLine();
	OptionsBuilder:AddNewLine();
	
	OptionsBuilder:AddKVPair("Vrs");
	OptionsBuilder:AddKVPair("VrsDR");
	OptionsBuilder:AddNewLine();
	OptionsBuilder:AddNewLine();
	
	OptionsBuilder:AddKVPair("Mst");
	OptionsBuilder:AddKVPair("Lee");
	OptionsBuilder:AddNewLine();
	OptionsBuilder:AddNewLine();

	--Stats per 1%
	if ( h.IntPct and h.IntPct>0 ) then
		OptionsBuilder:AddDivider("Stat Rating Per 1% HPS");
		OptionsBuilder:AddKVPair("IntPct",pctOptions);
		OptionsBuilder:AddKVPair("Mp5Pct",pctOptions);
		OptionsBuilder:AddNewLine();
		OptionsBuilder:AddNewLine();
		OptionsBuilder:AddKVPair("CrtPct",pctOptions);
		
		if ( h.SpecID == addon.SpellType.SHAMAN ) then
			OptionsBuilder:AddKVPair("CrtResPct",pctOptions);
		else
			OptionsBuilder:AddKVPairRaw("","",{Type="string"});
		end

		OptionsBuilder:AddNewLine();
		OptionsBuilder:AddNewLine();
		OptionsBuilder:AddKVPair("HstPct",pctOptions);
		OptionsBuilder:AddKVPair("HstHPCTPct",pctOptions);
		OptionsBuilder:AddNewLine();
		OptionsBuilder:AddNewLine();
		OptionsBuilder:AddKVPair("VrsPct",pctOptions);
		OptionsBuilder:AddKVPair("VrsDRPct",pctOptions);
		OptionsBuilder:AddNewLine();
		OptionsBuilder:AddNewLine();
		OptionsBuilder:AddKVPair("MstPct",pctOptions);
		OptionsBuilder:AddKVPair("LeePct",pctOptions);
		OptionsBuilder:AddNewLine();
		OptionsBuilder:AddNewLine();
	end
	
	if ( self.SpecInfo[h.SpecID] ) then
		OptionsBuilder:AddDivider("Resources");

		local specInfoOptions = {
			Width=2.75,
			Type="string"
		};

		

		for _,v in ipairs(globalResources) do
			if ( v.key == "url" ) then				
				OptionsBuilder:AddURL(v.value,v.name,v.desc);
			else	
				OptionsBuilder:AddKVPairRaw(v.key,v.value,specInfoOptions);
			end
			OptionsBuilder:AddNewLine();
			OptionsBuilder:AddNewLine();
		end


		for _,v in ipairs(self.SpecInfo[h.SpecID]) do
			if ( v.key == "url" ) then				
				OptionsBuilder:AddURL(v.value,v.name,v.desc);
			else	
				OptionsBuilder:AddKVPairRaw(v.key,v.value,specInfoOptions);
			end
			OptionsBuilder:AddNewLine();
			OptionsBuilder:AddNewLine();
		end
	end

	return OptionsBuilder:GetOptions();
end

--[[----------------------------------------------------------------------------
Create Options UI for Historical Segments List
------------------------------------------------------------------------------]]
local function TryBuildHistoryList()
	if ( not addon.History:GetDirty() ) then
		return false;
	end
	local i;
	local optionsTable = {};
	local historyArgs = {};

	-- build a list of controls in our history tab.
	local tbl = addon:GetHistoricalSegmentsList();
	for i,v in pairs(tbl) do
		local t = addon:BuildOptionsTableForHistorySegment(i);
		if ( t ) then
			historyArgs["ctrl"..i] = {
				name=v,
				order = i+1,
				type = "group",
				args = t
			};
		end
	end

	optionsTable.HistorySelection = {
		name = "Logged Encounters",
		type = "group",
		order = 1,
		args = historyArgs,
	};

	addon.History:ClearDirty();
	return optionsTable;
end



--[[----------------------------------------------------------------------------
Dynamically Create our Options UI
------------------------------------------------------------------------------]]
local function BuildOptionsTable(uiTypes,uiName,appName)
	local historyList = TryBuildHistoryList();

	if ( historyList ) then
		options.args.historyTab.args = historyList;		
	end

	return options;
end



--[[----------------------------------------------------------------------------
Handle Chat Commands
------------------------------------------------------------------------------]]
function hsw:ChatCommand(input)
	if not input or input:trim() == "" then
		if ( not hswOptionsFrame ) then
			self:OpenOptions();
		end
	end
	
	local lwr_input = string.lower(input);
	
	if ( lwr_input == "show" ) then
		addon:Show();
	elseif ( lwr_input == "hide" ) then
		addon:Hide();
	elseif ( lwr_input == "lock" ) then
		addon:Lock();
	elseif ( lwr_input == "unlock" ) then
		addon:Unlock();
	elseif ( lwr_input == "debug" ) then
		local seg = addon.SegmentManager:Get(addon.currentSegment);
		if ( seg ) then seg:Debug() end
	elseif (lwr_input == "start" ) then
		HFA_ENABLE_FOR_TESTING=true;
		addon:Show();
		addon:StartFight("test");
	elseif (lwr_input == "end" ) then
		addon:EndFight();
	end
end



--[[----------------------------------------------------------------------------
	History - store/retrieve historical segments	
------------------------------------------------------------------------------]]
addon.History = addon.Queue.CreateHistoryQueue();
addon.MythicPlusActive = false;
local dungeonCombinedSegment = nil;

local function mergeDungeonSegments(segment)
	local info = segment:GetInstanceInfo();
	
	if not dungeonCombinedSegment then --create empty segment
		local str = info.name;
		if info.level then
			str = str .. " +"..info.level;
		end	
		dungeonCombinedSegment = addon.Segment.Create(str);
		dungeonCombinedSegment:SetupInstanceInfo(true);
		dungeonCombinedSegment:End();
	end
		
	dungeonCombinedSegment:MergeSegment(segment);
end

function addon:TryAddTotalInstanceSegmentToHistory() --handle adding the total dungeon segment
	if ( dungeonCombinedSegment ) then
		self:AddHistoricalSegment(dungeonCombinedSegment);
		dungeonCombinedSegment = nil
	end
end

function addon:AddHistoricalSegment(segment)
    if ( not segment or not segment.t or segment.t.int==0) then
		--dont add empty segments
        return
	end
	
	if ( self:InRaidInstance() and not segment.instance.bossFight ) then
		--dont add trash fights while in a raid instance
		return;
	end
	
	if ( self.MythicPlusActive ) then --try to merge this segment into the current running history
		mergeDungeonSegments(segment);
	end
	local info = segment:GetInstanceInfo();
	
    local h = {};
	local duration = segment:GetDuration() or 0;
	local m = math.floor(duration/60);
	local s = math.floor(duration - m*60);
	local t_str = m..":"..(s<10 and "0" or "")..s;
	local resurg_add = self:IsRestoShaman() and (segment:GetManaRestoreValue()/self.CritConv) or 0;
    local i = GetSpecialization();
	local specId = GetSpecializationInfo(i);
	local name, realm = UnitFullName("player");
	local regionID = GetCurrentRegion();

	local regions = {
		[1]="US",
		[2]="KR",
		[3]="EU",
		[4]="TW",
		[5]="CN"
	};

	local tab_str = "    ";
	h.tab = info.bossFight and "" or tab_str;
	h.tab = self.MythicPlusActive and h.tab..tab_str or h.tab;
	
	h.isDungeon = not self:InRaidInstance();
	h.Segment = segment.id;
	h.Duration = t_str;
	h.Class = spec_labels[specId] or "Unknown";
	h.Int = 1.0;
	h.Crt = segment.t.crit/segment.t.int;
	h.CrtRes = (segment.t.crit+resurg_add)/segment.t.int;
	h.Hst = segment:GetHaste()/segment.t.int;
	h.HstHPCT = segment:GetHasteHPCT() / segment.t.int;
	h.HstHPCT2 = segment.t.haste_hpct / segment.t.int;
	h.Vrs = segment.t.vers / segment.t.int;
	h.VrsDR = segment.t.vers_dr / segment.t.int;
	h.Mst = segment.t.mast / segment.t.int;
	h.Lee = segment.t.leech / segment.t.int;
	h.Mp5 = segment:GetMP5();
	h.DateTime	= segment.startTimeStamp;
	h.Slot13 = segment.gear and segment.gear[13] or nil;
	h.Slot14 = segment.gear and segment.gear[14] or nil;

	--TotalHealing/100/statBucket = x
	local onePercentTotalHealing = segment.totalHealing / 100.0;
	local function healingPerOnePercent(bucket)
		return bucket and bucket > 0 and onePercentTotalHealing / bucket or 0.0;
	end

	h.LeePct	 = healingPerOnePercent(segment.t.leech);
	h.IntPct	 = healingPerOnePercent(segment.t.int);
	h.CrtPct	 = healingPerOnePercent(segment.t.crit);
	h.CrtResPct	 = healingPerOnePercent(segment.t.crit+resurg_add);
	h.VrsPct	 = healingPerOnePercent(segment.t.vers);
	h.VrsDRPct	 = healingPerOnePercent(segment.t.vers_dr);
	h.Mp5Pct	 = healingPerOnePercent(segment:GetMP5() * segment.t.int);
	h.MstPct	 = healingPerOnePercent(segment.t.mast);
	h.HstPct	 = healingPerOnePercent(segment:GetHaste());
	h.HstHPCTPct = healingPerOnePercent(segment:GetHasteHPCT());

	h.Talents = segment.talentsSnapshot and segment.selectedTalents or {};
	h.SpecID = specId;
	h.Name=name or "Unknown";
	h.Realm=realm or "Unknown";
	h.Region=regions[regionID] or "Unknown";

	self.History:Enqueue(h,segment);
end


local pawnOptionsFrame;
local qeOptionsFrame;
local pawnOptionsWidth = 220;
function addon:GetPawnStringFromHistory()
	local h = addon.History:Get(historySelected);
	if not pawnOptionsFrame or not h then
		return "";
	end
	local t = class_id_lookup[h.Class];
	local class = GetClassInfo(t.class);
	local specId = t.spec;
		
	local int_key = "Int";
	local hst_key = DropdownLabelsRev[pawnOptionsFrame.haste_dropdown.selectedLabel];
	local crt_key = DropdownLabelsRev[pawnOptionsFrame.crit_dropdown.selectedLabel];
	local vrs_key = DropdownLabelsRev[pawnOptionsFrame.vers_dropdown.selectedLabel];
	local mst_key = "Mst";
	local lee_key = "Lee";

	return self:GetPawnStringRaw(h.Segment,class,specId,h[int_key],h[crt_key],h[hst_key],h[vrs_key],h[mst_key],h[lee_key]);
end

function addon:GetQELiveStringFromHistory() 	
	local h = addon.History:Get(historySelected);

	if not qeOptionsFrame or not h then
		return "";
	end

	local specid = 0;
	for k,v in pairs(spec_labels) do
		if ( v == h.Class ) then
			specid = k;
			break;
		end
	end
	
	

	local hstHPC_key = "Hst";
	local hstHPCT_key = "HstHPCT";
	local crt_key = DropdownLabelsRev[qeOptionsFrame.crit_dropdown.selectedLabel];
	local vrs_key = DropdownLabelsRev[qeOptionsFrame.vers_dropdown.selectedLabel];
	local mst_key = "Mst";
	local lee_key = "Lee";

	local isDungeonOrTrash = string.find(h.Segment or ""," %+") or h.isDungeon;

	return self:GetQELiveStringRaw(specid,h.Name,h.Realm,h.Region,h[crt_key],h[hstHPCT_key],h[hstHPC_key],h[mst_key],h[vrs_key],h[lee_key],isDungeonOrTrash);
end

function addon:CreateQEStringFromHistory()
	if not qeOptionsFrame then
		qeOptionsFrame = CreateFrame("Frame","HSW_CQSFW",UIParent, BackdropTemplateMixin and "BackdropTemplate");
		qeOptionsFrame:SetWidth(pawnOptionsWidth);
		qeOptionsFrame:SetHeight(128);
		qeOptionsFrame:SetPoint("CENTER",0,0);
		qeOptionsFrame:SetFrameStrata("TOOLTIP");
		qeOptionsFrame:SetMovable(true);
		qeOptionsFrame:EnableMouse(true);
		qeOptionsFrame:RegisterForDrag("LeftButton");
		qeOptionsFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
												edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
												tile = true, tileSize = 16, edgeSize = 16, 
												insets = { left = 4, right = 4, top = 4, bottom = 4 }});
		qeOptionsFrame:SetBackdropColor(0,0,0,1);

		local function addMenuButton(frame,label)
			local info = UIDropDownMenu_CreateInfo();
			info.checked = (label == frame.selectedLabel);
			info.func = function() frame.selectedLabel = label; UIDropDownMenu_SetText(frame,label); CloseDropDownMenus(); end
			info.text = label;
			UIDropDownMenu_AddButton(info,1);
		end
		local function SetupDropdownMenu(labels)	
			local dropdown = CreateFrame("Frame", "HSW_CQSFH_"..labels[1], qeOptionsFrame, "UIDropDownMenuTemplate");
			local function init(self,level)
				if ( level == 1 ) then
					for i,v in ipairs(labels) do
						addMenuButton(dropdown,v);
					end		
				end	
			end
			
			dropdown.selectedLabel = labels[1];
			UIDropDownMenu_SetText(dropdown,labels[1]);
			UIDropDownMenu_SetWidth(dropdown, pawnOptionsWidth-50, 8);
			UIDropDownMenu_Initialize(dropdown,init);
			return dropdown;
		end;
		
		-- local haste_labels = {DropdownLabels.Hst,DropdownLabels.HstHPCT};
		local crit_labels = {DropdownLabels.Crt,DropdownLabels.CrtRes};
		local vers_labels = {DropdownLabels.Vrs,DropdownLabels.VrsDR};
		-- local haste_dropdown = SetupDropdownMenu(haste_labels);
		-- haste_dropdown:ClearAllPoints();
		-- haste_dropdown:SetPoint("TOPLEFT",0,-8);
		-- qeOptionsFrame.haste_dropdown = haste_dropdown;
		
		local crit_dropdown = SetupDropdownMenu(crit_labels);
		crit_dropdown:ClearAllPoints();
		crit_dropdown:SetPoint("TOPLEFT",0,-32);
		qeOptionsFrame.crit_dropdown = crit_dropdown;
		
		local vers_dropdown = SetupDropdownMenu(vers_labels);
		vers_dropdown:ClearAllPoints();
		vers_dropdown:SetPoint("TOPLEFT",0,-56);
		qeOptionsFrame.vers_dropdown = vers_dropdown;
		
		
		local btn_cancel = CreateFrame("Button","HSW_CQSFH_Cancel",qeOptionsFrame,"UIPanelButtonTemplate");
		btn_cancel:SetPoint("BOTTOMRIGHT",-8,8);
		btn_cancel:SetHeight(24);
		btn_cancel:SetWidth(pawnOptionsWidth/2-16);
		btn_cancel:SetNormalFontObject("GameFontNormalSmall");
		btn_cancel:SetText("Cancel");
		btn_cancel:SetScript("OnClick",function() 
			qeOptionsFrame:Hide();
		end);
		
		local btn_accept = CreateFrame("Button","HSW_CQSFH_Accept",qeOptionsFrame,"UIPanelButtonTemplate");
		btn_accept:SetPoint("BOTTOMLEFT",8,8);
		btn_accept:SetHeight(24);
		btn_accept:SetWidth(pawnOptionsWidth/2-16);
		btn_accept:SetNormalFontObject("GameFontNormalSmall");
		btn_accept:SetText("Create!");
		btn_accept:SetScript("OnClick",function()
			qeOptionsFrame:Hide();
			StaticPopup_Show(addon.QELiveDialogName);
		end);
	end
	
	qeOptionsFrame:Show();
end

function addon:CreatePawnStringFromHistory()
	if not pawnOptionsFrame then
		pawnOptionsFrame = CreateFrame("Frame","HSW_CPSFW",UIParent);
		pawnOptionsFrame:SetWidth(pawnOptionsWidth);
		pawnOptionsFrame:SetHeight(128);
		pawnOptionsFrame:SetPoint("CENTER",0,0);
		pawnOptionsFrame:SetFrameStrata("TOOLTIP");
		pawnOptionsFrame:SetMovable(true);
		pawnOptionsFrame:EnableMouse(true);
		pawnOptionsFrame:RegisterForDrag("LeftButton");
		pawnOptionsFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
												edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
												tile = true, tileSize = 16, edgeSize = 16, 
												insets = { left = 4, right = 4, top = 4, bottom = 4 }});
		pawnOptionsFrame:SetBackdropColor(0,0,0,1);

			
		local function addMenuButton(frame,label)
			local info = UIDropDownMenu_CreateInfo();
			info.checked = (label == frame.selectedLabel);
			info.func = function() frame.selectedLabel = label; UIDropDownMenu_SetText(frame,label); CloseDropDownMenus(); end
			info.text = label;
			UIDropDownMenu_AddButton(info,1);
		end
		local function SetupDropdownMenu(labels)	
			local dropdown = CreateFrame("Frame", "HSW_CPSFH_"..labels[1], pawnOptionsFrame, "UIDropDownMenuTemplate");
			local function init(self,level)
				if ( level == 1 ) then
					for i,v in ipairs(labels) do
						addMenuButton(dropdown,v);
					end		
				end	
			end
			
			dropdown.selectedLabel = labels[1];
			UIDropDownMenu_SetText(dropdown,labels[1]);
			UIDropDownMenu_SetWidth(dropdown, pawnOptionsWidth-50, 8);
			UIDropDownMenu_Initialize(dropdown,init);
			return dropdown;
		end;
		
		local haste_labels = {DropdownLabels.Hst,DropdownLabels.HstHPCT};
		local crit_labels = {DropdownLabels.Crt,DropdownLabels.CrtRes};
		local vers_labels = {DropdownLabels.Vrs,DropdownLabels.VrsDR};
		local haste_dropdown = SetupDropdownMenu(haste_labels);
		haste_dropdown:ClearAllPoints();
		haste_dropdown:SetPoint("TOPLEFT",0,-8);
		pawnOptionsFrame.haste_dropdown = haste_dropdown;
		
		local crit_dropdown = SetupDropdownMenu(crit_labels);
		crit_dropdown:ClearAllPoints();
		crit_dropdown:SetPoint("TOPLEFT",0,-32);
		pawnOptionsFrame.crit_dropdown = crit_dropdown;
		
		local vers_dropdown = SetupDropdownMenu(vers_labels);
		vers_dropdown:ClearAllPoints();
		vers_dropdown:SetPoint("TOPLEFT",0,-56);
		pawnOptionsFrame.vers_dropdown = vers_dropdown;
		
		
		local btn_cancel = CreateFrame("Button","HSW_CPSFH_Cancel",pawnOptionsFrame,"UIPanelButtonTemplate");
		btn_cancel:SetPoint("BOTTOMRIGHT",-8,8);
		btn_cancel:SetHeight(24);
		btn_cancel:SetWidth(pawnOptionsWidth/2-16);
		btn_cancel:SetNormalFontObject("GameFontNormalSmall");
		btn_cancel:SetText("Cancel");
		btn_cancel:SetScript("OnClick",function() 
			pawnOptionsFrame:Hide();
		end);
		
		local btn_accept = CreateFrame("Button","HSW_CPSFH_Accept",pawnOptionsFrame,"UIPanelButtonTemplate");
		btn_accept:SetPoint("BOTTOMLEFT",8,8);
		btn_accept:SetHeight(24);
		btn_accept:SetWidth(pawnOptionsWidth/2-16);
		btn_accept:SetNormalFontObject("GameFontNormalSmall");
		btn_accept:SetText("Create!");
		btn_accept:SetScript("OnClick",function()
			pawnOptionsFrame:Hide();
			StaticPopup_Show(addon.PawnHistoryDialogName);
		end);



		
	end
	
	pawnOptionsFrame:Show();
end

local function addExampleSegment()
	local s = addon.Segment.Create("Example Segment!");
	s:AllocateHeal(1,math.random(),math.random(),math.random(),math.random(),math.random(),math.random(),math.random(),math.random());
	s:AllocateHealDR(math.random()*0.1);
	addon:AddHistoricalSegment(s);
end

function addon:GetHistoricalSegmentsList()
	local t = {};
	local n = addon.History:Size();
	local h;
	
	if ( n == 0 ) then
		addExampleSegment();
		n = addon.History:Size();
	end
	
	for i=0,n-1,1 do
		h = addon.History:Get(i);
		if ( h ) then
			local segment_name = (h.tab or "");
			

			for key,oldKey in pairs ( addon.SegmentLabels ) do
				if ( h[oldKey] ) then
					h[key] = h[oldKey];
				end
			end
			for key,_ in pairs(addon.SegmentLabels) do
				if ( h[key] ) then
					local s,e = string.find(key,"Old");
					if ( s ) then
						local newKey = string.sub(key,1,s-1);
						h[newKey] = h[key];
					end
				end
			end

			local specId = nil;

			for id,label in pairs(spec_labels) do 
				if ( label == h.Class ) then
					specId = id;
					break;
				end
			end

			if ( specId ) then
				local _,_,_,icon = GetSpecializationInfoByID(specId);
				if ( icon ) then
					segment_name = segment_name .. " |T "..icon..":18|t ";
				end
			end
			
			segment_name = segment_name .. h.Segment .. " " .. h.Duration;
			t[i] = segment_name;
		end
	end
	
	return t;
end



--[[----------------------------------------------------------------------------
Open Options
------------------------------------------------------------------------------]]
function hsw:OpenOptions()
	local AceGUI = LibStub("AceGUI-3.0")
	local hsw_frame = AceGUI:Create("Frame");
	hswOptionsFrame = hsw_frame;
	hsw_frame:SetTitle("Healer Stat Weights");
	
	local version = GetAddOnMetadata("HealerStatWeights","Version");
	if ( version ) then
		hsw_frame:SetStatusText("version "..version); --TODO programmatically update this with variable from T.O.C. file
	else
		hsw_frame:SetStatusText("version ???");
	end

	
	hsw_frame:SetWidth(900);
	hsw_frame:SetHeight(640);
	hsw_frame:EnableResize(false);
	hsw_frame:SetLayout("Flow");
	hsw_frame:SetCallback("OnClose",function(w)
		AceGUI:Release(w)
		hswOptionsFrame = nil;
	end);
	hsw_frame:Show();

	--create a simple container
	local container = AceGUI:Create("SimpleGroup");
	container:SetFullHeight(true);
	container:SetFullWidth(true);
	LibStub("AceConfigDialog-3.0"):Open("HealerStatWeights",container);
	hsw_frame:AddChild(container);
end



--[[----------------------------------------------------------------------------
Addon Initialized
------------------------------------------------------------------------------]]
function hsw:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("HSW_DB", defaults)

	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("HealerStatWeights",BuildOptionsTable,true);
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("HSW_Bliz",BlizOptionsTable);

	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("HSW_Bliz", "Healer Stat Weights");
	self:RegisterChatCommand("hsw","ChatCommand");
end


addon.SegmentLabels = SegmentLabels;
addon.hsw = hsw;