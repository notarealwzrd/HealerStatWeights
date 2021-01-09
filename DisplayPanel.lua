local name, addon = ...;
local media = LibStub("LibSharedMedia-3.0");



--[[----------------------------------------------------------------------------
    Strings & Patterns
------------------------------------------------------------------------------]]
local pattern_title = "%s";
local pattern_left = "Intellect\n"
                  .. "Critical Strike%s\n"
                  .. "Haste%s\n"
                  .. "Versatility%s\n"
                  .. "Mastery%s\n"
                  .. "Leech";
local pattern_right = "%.2f\n"
                  ..  "%.2f\n"
                  ..  "%.2f\n"
                  ..  "%.2f\n"
                  ..  "%.2f\n"
                  ..  "%.2f";
local haste_hpct = " (HPCT)";
local haste_hpm = "";
local vers_dr = " (DR)";
local crit_resurg = " (R)";
local pawn_pattern = [[( Pawn: v1: "%s": Class=%s, Spec=%s, Intellect=%.2f, CritRating=%.2f, HasteRating=%.2f, Versatility=%.2f, MasteryRating=%.2f, Leech=%.2f)]];
local pawn_str_name = "%s-HSW-%s";
local pawn_title = "Pawn String (Ctrl+A to select all, Ctrl+C to copy):";
local pawn_dialog_name = "HSW_GETPAWNSTRING";
local clearsegments_dialog_name = "HSW_CLEARALLSEGMENTS";
local clearsegments_title = "Clear all segments?";
local qelive_title = "QE Live Website (Ctrl+A to select all, Ctrl+C to copy):";
local qelive_pattern = "https://questionablyepic.com/live/?import=HSW&spec=%s&pname=%s&realm=%s&region=%s&CriticalStrike=%.2f&HasteHPCT=%.2f&HasteHPM=%.2f&Mastery=%.2f&Versatility=%.2f&Leech=%.2f&content=%s";
local qelive_noname_pattern = "https://questionablyepic.com/live/?import=HSW&spec=%s&CriticalStrike=%.2f&HasteHPCT=%.2f&HasteHPM=%.2f&Mastery=%.2f&Versatility=%.2f&Leech=%.2f&content=%s";



--[[----------------------------------------------------------------------------
    UpdateDisplayStats - update the display to show the given stats
------------------------------------------------------------------------------]]
function addon:UpdateDisplayStats()
    local int,crt,hst,vrs,mst,lee = addon:GetStatsForDisplay();
    self.frame.textR:SetFormattedText(pattern_right,int,crt,hst,vrs,mst,lee);
end



--[[----------------------------------------------------------------------------
    UpdateDisplayTitle - update the title of the display
------------------------------------------------------------------------------]]
function addon:UpdateDisplayTitle(title)
    self.frame.textTitle:SetFormattedText(pattern_title,title);    
end



--[[----------------------------------------------------------------------------
    UpdateDisplayLabels - update the display to reflect current filter settings
------------------------------------------------------------------------------]]
function addon:UpdateDisplayLabels()
    local crit_suffix = (self.hsw.db.global.useCritResurg and self:IsRestoShaman()) and crit_resurg or "";
    local haste_suffix = self.hsw.db.global.useHPMoverHPCT and haste_hpm or haste_hpct;
    local vers_suffix = self.hsw.db.global.useVersDR and vers_dr or "";
    local mastery_suffix = "";

    self.frame.textL:SetFormattedText(
        pattern_left, crit_suffix, haste_suffix, vers_suffix, mastery_suffix
    );
end



--[[----------------------------------------------------------------------------
    SetCurrentSegment - Change the currently-displayed segment
------------------------------------------------------------------------------]]
function addon:SetCurrentSegment(segmentID)
    self.currentSegment = segmentID;
    local id;
    
    if ( segmentID == 0 ) then
        id = "Current Fight";
    elseif ( segmentID == "Total" ) then
        id = "Total";
    else
        local segment = self.SegmentManager:Get(self.currentSegment);
        id = segment.id;
    end
    
    self:UpdateDisplayLabels();
    self:UpdateDisplayStats();
    self:UpdateDisplayTitle(id);
end



--[[----------------------------------------------------------------------------
    GetStatsForDisplay
------------------------------------------------------------------------------]]
function addon:GetStatsForDisplay()
    local segment = self.SegmentManager:Get(self.currentSegment);
    
    if ( not segment ) then
        return 1,0,0,0,0,0;
    end
    
    local t = segment.t;    
    if ( t.int == 0 ) then
        return 1,0,0,0,0,0;
    end

    local usingHPCT = not self.hsw.db.global.useHPMoverHPCT;
    local usingVersDR = self.hsw.db.global.useVersDR;
    local usingCritResurg = self:IsRestoShaman() and self.hsw.db.global.useCritResurg;
    
    local INT = 1;
    local CRIT = (usingCritResurg and (segment:GetManaRestoreValue()/addon.CritConv + t.crit) or t.crit) / t.int;
    local HASTE = (usingHPCT and segment:GetHasteHPCT() or segment:GetHaste()) / t.int;
    local VERS = (usingVersDR and t.vers_dr or t.vers) / t.int;
    local MAST = t.mast / t.int;
    local LEECH = t.leech / t.int;
    local MP5 = segment:GetMP5();
    return INT,CRIT,HASTE,VERS,MAST,LEECH,MP5;
end



--[[----------------------------------------------------------------------------
    SegmentMenu - Create & Display a segment selection dropdown menu
------------------------------------------------------------------------------]]
function addon:SegmentMenu()    
    local menu = {
        { text = "Select a Segment", isTitle = true},
        { text = "Total", func = function() addon:SetCurrentSegment("Total") end },
        { text = "Current Fight", func = function() addon:SetCurrentSegment(0) end}
    };
    
    for i=1,self.SegmentManager:Size()-1,1 do
        local segment = self.SegmentManager:Get(i);
        table.insert(menu,{ text = segment.id, func = function() addon:SetCurrentSegment(i) end });
    end
    
    if ( self.currentSegment == "Total" ) then
        menu[2].checked = true;
    elseif ( self.currentSegment == "Current" ) then
        menu[3].checked = true;
    else
        menu[3+(self.currentSegment or 0)].checked = true;
    end
    
    local menuFrame = CreateFrame("Frame", "HSW_SegmentMenu_Frame", UIParent, "UIDropDownMenuTemplate");
    EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU"); 
end



--[[----------------------------------------------------------------------------
    Show - Display the stats panel
------------------------------------------------------------------------------]]
function addon:Show()
    addon.frameVisible = true;
    self:SetCurrentSegment(self.currentSegment or "Total");
    if ( self.frame ) then
        self.frame:Show();
    end
end



--[[----------------------------------------------------------------------------
    Hide - Hide the stats panel
------------------------------------------------------------------------------]]
function addon:Hide()
    addon.frameVisible = false;
    if ( self.frame ) then
        self.frame:Hide();
    end
end



--[[----------------------------------------------------------------------------
    Msg - print a message to chat
------------------------------------------------------------------------------]]
function addon:Msg(s)
	if s then
		DEFAULT_CHAT_FRAME:AddMessage("|cff00fbf6[HSW]|r "..tostring(s),1,1,1);
	end
end



--[[----------------------------------------------------------------------------
    Enabled - Check if the addon should be enabled.
------------------------------------------------------------------------------]]
function addon:Enabled()
    if ( self.StatParser:IsCurrentSpecSupported() ) then
		if ( HSW_ENABLE_FOR_TESTING ) then
			return true;
		end
        
        local _,_,id = GetInstanceInfo();            
        if (( id == 1   and self.hsw.db.global.enabledInNormalDungeons )		or
            ( id == 2   and self.hsw.db.global.enabledInHeroicDungeons )    	or
            ( id == 23  and self.hsw.db.global.enabledInMythicDungeons )    	or
            ( id == 8   and self.hsw.db.global.enabledInMythicPlusDungeons ) 	or
            ( id == 14  and self.hsw.db.global.enabledInNormalRaids )       	or
            ( id == 15  and self.hsw.db.global.enabledInHeroicRaids )       	or
            ( id == 16 	and self.hsw.db.global.enabledInMythicRaids )       	or
            ( id == 17  and self.hsw.db.global.enabledInLfrRaids ))            	then
            return true;
        elseif self.hsw.db.global.alwaysEnabled then
            return true;
        end
    end

    return false;
end



--[[----------------------------------------------------------------------------
    InRaidInstance - Check if we are in a raid instance
------------------------------------------------------------------------------]]
function addon:InRaidInstance()
	local _,_,id = GetInstanceInfo(); 
	return id and (id >= 14 and id <= 17);
end



--[[----------------------------------------------------------------------------
    InMythicPlus - Check if we are in a mythic+ instance
------------------------------------------------------------------------------]]
function addon:InMythicPlus()
	local _,_,id = GetInstanceInfo(); 
	return id and (id == 8);
end



--[[----------------------------------------------------------------------------
    AdjustVisibility - Show or hide the frame
------------------------------------------------------------------------------]]    
function addon:AdjustVisibility()
    if ( not self.hsw.db.global.neverShow and (self:Enabled() or self.hsw.db.global.alwaysShow) ) then
        self:Show();
    else
        self:Hide();
    end
end



--[[----------------------------------------------------------------------------
    Lock - lock the stats panel
------------------------------------------------------------------------------]]
function addon:Lock()
    self:Msg("Healer Stat Weights frame locked.")
    self.hsw.db.global.frameLocked = true;
    self.frame:EnableMouse(not self.hsw.db.global.frameLocked);
    self.frame:SetMovable(not self.hsw.db.global.frameLocked);
end



--[[----------------------------------------------------------------------------
    Unlock - unlock the stats panel
------------------------------------------------------------------------------]]
function addon:Unlock()
    self:Msg("Healer Stat Weights frame unlocked.")
    self.hsw.db.global.frameLocked = false;
    self.frame:EnableMouse(not self.hsw.db.global.frameLocked);
    self.frame:SetMovable(not self.hsw.db.global.frameLocked);
end



--[[----------------------------------------------------------------------------
    Pawn String - Dialog to display pawn string for current segment
------------------------------------------------------------------------------]]
function addon:GetPawnString()
    local segment = self.SegmentManager:Get(self.currentSegment);
    local int,crt,hst,vrs,mst,lee = addon:GetStatsForDisplay();
    local class = UnitClass("Player");
    local specId = GetSpecialization();
    local title = string.format(pawn_str_name,class,(segment and segment.id or "Unknown"));
    return self:GetPawnStringRaw(title,class,specId,int,crt,hst,vrs,mst,lee);
end

function addon:GetPawnStringRaw(title,class,specId,int,crt,hst,vrs,mst,lee)	
    return string.format(pawn_pattern,title,class,specId,int,crt,hst,vrs,mst,lee);
end

addon.PawnHistoryDialogName = pawn_dialog_name.."_HISTORY";
StaticPopupDialogs[addon.PawnHistoryDialogName] = {
    text = pawn_title,
    button1 = OKAY,
    button2 = CANCEL,
    hasEditBox = true,
	editBoxWidth = 600,
	maxLetters = 9999,
    OnShow = function (self, data)
		local s = addon:GetPawnStringFromHistory();
        print(s);
        self.editBox:SetText(s)
    end,
    timeout = 0,
    exclusive = 1,
    hideOnEscape = 1,
    whileDead = 1
}

StaticPopupDialogs[pawn_dialog_name] = {
    text = pawn_title,
    button1 = OKAY,
    button2 = CANCEL,
    hasEditBox = true,
	editBoxWidth = 600,
	maxLetters = 9999,
    OnShow = function (self, data)
        local s = addon:GetPawnString();
        print(s);
        self.editBox:SetText(s)
    end,
    timeout = 0,
    exclusive = 1,
    hideOnEscape = 1,
    whileDead = 1
}



--[[----------------------------------------------------------------------------
    QE Live String - Dialog to display link to questionably epic website for current segment
------------------------------------------------------------------------------]]
function addon:GetQELiveStringRaw(specid,name,realm,regionLetters,crt,hstHPCT,hstHPM,mst,vrs,lee,isDungeon)	
    local s;
    local contentStr = isDungeon and "dungeon" or "raid";
    
    if ( name and realm and regionLetters ) then
        s = string.format(qelive_pattern,specid,name,realm,regionLetters,crt,hstHPCT,hstHPM,mst,vrs,lee,contentStr);
    else
        s = string.format(qelive_noname_pattern,specid,crt,hstHPCT,hstHPM,mst,vrs,lee,contentStr);
    end
    s = string.gsub(s,"%'","%%27");
    s = string.gsub(s," ","%%20");
    return s;
end

addon.QELiveDialogName = pawn_dialog_name.."_QELIVE";
StaticPopupDialogs[addon.QELiveDialogName] = {
    text = qelive_title,
    button1 = OKAY,
    button2 = CANCEL,
    hasEditBox = true,
	editBoxWidth = 600,
	maxLetters = 9999,
    OnShow = function (self, data)
		local s = addon:GetQELiveStringFromHistory();
        print(s);
        self.editBox:SetText(s)
    end,
    timeout = 0,
    exclusive = 1,
    hideOnEscape = 1,
    whileDead = 1
}



--[[----------------------------------------------------------------------------
    Clear All Segments - Dialog to clear segments
------------------------------------------------------------------------------]]
StaticPopupDialogs[clearsegments_dialog_name] = {
    text = clearsegments_title,
    button1 = YES,
    button2 = NO,
    OnAccept = function ()
        addon.SegmentManager:ResetAllSegments();
        addon:SetCurrentSegment(0);
    end,
    timeout = 0,
    exclusive = 1,
    hideOnEscape = 1,
    whileDead = 1
}



--[[----------------------------------------------------------------------------
    StartFight - Start a new combat segment 
------------------------------------------------------------------------------]]
function addon:StartFight(id)
    if ( self:Enabled() ) then
        if ( not self.inCombat ) then
            self:UpdatePlayerStats();
            self.UnitManager:Cache();
			if ( self:IsHolyPaladin() ) then
				self:CountBeaconsAtStartOfFight();
			elseif ( self:IsDiscPriest() ) then
				self.DiscPriest.PWSTracker:EncounterStart();
				self.DiscPriest.LBTracker:EncounterStart();
				self.DiscPriest.AtonementTracker:EncounterStart();
			elseif ( self:IsHolyPriest() ) then
				self.HolyPriest.EOLTracker:EncounterStart();
			end
				
            self.SegmentManager:Enqueue(id);
            
            --Set start time of total segment to match current segment
            local cur_seg = self.SegmentManager:Get(0);
            local ttl_seg = self.SegmentManager:Get("Total");            
            if ( ttl_seg and cur_seg ) then    
                ttl_seg.startTime = cur_seg.startTime;
            end
            
            self.inCombat = true;
            self:AdjustVisibility();
        end
    end
end



--[[----------------------------------------------------------------------------
    EndFight - End current combat segment 
------------------------------------------------------------------------------]]
function addon:EndFight(encounter_end)
    if ( self.inCombat ) then
		self.inCombat = false;

		local cur_seg = self.SegmentManager:Get(0);
		local ttl_seg = self.SegmentManager:Get("Total");
		if ( cur_seg ) then
			cur_seg:End();
			self:AddHistoricalSegment(cur_seg);
		end
		if ( ttl_seg ) then
			ttl_seg:End();
		end
    end
end



--[[----------------------------------------------------------------------------
    makeButton - Helper function used by SetupFrame
------------------------------------------------------------------------------]]
local function makeButton(parent, title, description, tex, clickfunc)
    local btn = CreateFrame("Button", nil, parent)
    btn.title = title
    btn:SetFrameLevel(5)
    btn:ClearAllPoints()
    btn:SetHeight(16)
    btn:SetWidth(16)
    btn:SetNormalTexture(tex)
    btn:SetHighlightTexture(tex, 1.0)
    btn:SetAlpha(0.35)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", clickfunc)
    btn:SetScript("OnEnter",
        function(this)
            GameTooltip_SetDefaultAnchor(GameTooltip, this)
            GameTooltip:SetText(title)
            GameTooltip:AddLine(description, 1, 1, 1, true)
            GameTooltip:Show()
        end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:Show()

    -- Add to our list of buttons.
    table.insert(parent.buttons,btn);
end



--[[----------------------------------------------------------------------------
    AdjustFontSizes - Change the font sizes on the stat weights frame
------------------------------------------------------------------------------]]
function addon:AdjustFontSizes()
    local p,s,f;
    
    p,s,f = self.frame.textL:GetFont();
    self.frame.textL:SetFont(p,self.hsw.db.global.fontSize,"OUTLINE");
    
    p,s,f = self.frame.textR:GetFont();
    self.frame.textR:SetFont(p,self.hsw.db.global.fontSize,"OUTLINE");
    
    p,s,f = self.frame.textTitle:GetFont();
    self.frame.textTitle:SetFont(p,self.hsw.db.global.fontSize+2,"OUTLINE");
end

function addon:AdjustFontColor()
	local color = self.hsw.db.global.fontColor;
	self.frame.textL:SetTextColor(color.r,color.g,color.b,color.a);
	self.frame.textR:SetTextColor(color.r,color.g,color.b,color.a);
	self.frame.textTitle:SetTextColor(color.r,color.g,color.b,color.a);
end

--[[----------------------------------------------------------------------------
    AdjustWidth - Change the width of the stat weights frame
------------------------------------------------------------------------------]]
local btn_size = 16;
function addon:AdjustWidth(newWidth)
    self.frame:SetWidth(newWidth);
    self.frame.textTitle:SetWidth(newWidth-btn_size*4);
end



--[[----------------------------------------------------------------------------
    AdjustFonts - Change the font used by the stat weights frame
------------------------------------------------------------------------------]]
function addon:AdjustFonts()
    local p,s,f = self.frame.textL:GetFont();
	local str = addon.hsw.db.global.fontStr;
	
	local path = p;
	if ( str ) then
		path = media:Fetch("font", str);
	end
	
    self.frame.textL:SetFont(path,s,f);
    
    p,s,f = self.frame.textR:GetFont();
    self.frame.textR:SetFont(path,s,f);
    
    p,s,f = self.frame.textTitle:GetFont();
    self.frame.textTitle:SetFont(path,s,f);
end



--[[----------------------------------------------------------------------------
    ResetFramePosition - Reset the frame's position to center of screen
------------------------------------------------------------------------------]]
function addon:ResetFramePosition()
	self.hsw.db.global.frameX = nil;
	self.frame:ClearAllPoints();
	self.frame:SetPoint("CENTER",0,0);
end



--[[----------------------------------------------------------------------------
    SetupFrame - Set up the main display panel
------------------------------------------------------------------------------]]
function addon:SetupFrame()
    if ( not self.frame ) then
        local W = self.hsw.db.global.frameWidth or 192;
        local H = 128;
        
        local frame = CreateFrame("Frame", nil, UIParent);
        frame:SetWidth(W);
        frame:SetHeight(H);
        frame:ClearAllPoints();
        
        if ( self.hsw.db.global.frameX ) then
            frame:SetPoint("BOTTOMLEFT",self.hsw.db.global.frameX or 0,self.hsw.db.global.frameY or 0);
        else
            frame:SetPoint("CENTER",0,0);
        end
        
        frame:EnableMouse(not self.hsw.db.global.frameLocked);
        frame:SetMovable(not self.hsw.db.global.frameLocked);
        frame:RegisterForDrag("LeftButton");
        frame:SetScript("OnDragStart",frame.StartMoving);
        frame:SetScript("OnDragStop",function(f)
            f:StopMovingOrSizing();
            self.hsw.db.global.frameX = f:GetLeft();
            self.hsw.db.global.frameY = f:GetBottom();
        end);
        
        local text = frame:CreateFontString(nil,"OVERLAY",GameFontNormal);    
        text:SetPoint("TOPLEFT", frame ,"TOPLEFT", 0, -btn_size)
        text:SetPoint("BOTTOMRIGHT", frame ,"BOTTOMRIGHT", 0, 0)
        text:SetJustifyH("LEFT");
        text:SetJustifyV("TOP");
        text:SetFontObject(GameFontWhite);
        text:SetShadowColor(0,0,0,.7);
        text:SetShadowOffset(1,1);
        local p,s,f = text:GetFont();
        text:SetFont(p,self.hsw.db.global.fontSize,"OUTLINE");
        frame.textL = text;
        
        text = frame:CreateFontString(nil,"OVERLAY",GameFontNormal);
        text:SetPoint("TOPLEFT", frame ,"TOPLEFT", 0, -btn_size)
        text:SetPoint("BOTTOMRIGHT", frame ,"BOTTOMRIGHT", 0, 0)
        text:SetJustifyH("RIGHT");
        text:SetJustifyV("TOP");
        text:SetFontObject(GameFontWhite);
        local p,s,f = text:GetFont();
        text:SetFont(p,self.hsw.db.global.fontSize,"OUTLINE");
        frame.textR = text;
        frame.buttons = {};
        
        makeButton(frame,"Clear","Clear out all segments.","Interface\\Buttons\\UI-StopButton",function() 
            if ( not addon.inCombat ) then
                StaticPopup_Show(clearsegments_dialog_name); 
            else
                addon:Msg("[HSW] Cannot clear segments while in combat.");
            end
        end);
        makeButton(frame,"Configure","Open the options menu","Interface\\Buttons\\UI-OptionsButton", function() 
            InterfaceOptionsFrame_OpenToCategory(self.hsw.optionsFrame)
            InterfaceOptionsFrame_OpenToCategory(self.hsw.optionsFrame)
        end);
        makeButton(frame,"Export","Get the pawn string for the current statweights.","Interface\\Buttons\\UI-GuildButton-MOTD-Up",function() 
            StaticPopup_Show(pawn_dialog_name); 
        end);
        makeButton(frame,"Segment","Select a segment","Interface\\Buttons\\UI-GuildButton-PublicNote-Up",function() 
            self:SegmentMenu() 
        end);
        
         --[[local bg = frame:CreateTexture(nil, "BACKGROUND");
        bg:SetAllPoints(true);
        bg:SetColorTexture(0.1,0.1,0.1,0.3);
        frame.texture = bg;]]

        text = frame:CreateFontString(nil,"OVERLAY",GameFontNormal);
        text:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0);
        text:SetJustifyH("LEFT");
        text:SetFontObject(GameFontWhite);
        local p,s,f = text:GetFont();
        text:SetFont(p,self.hsw.db.global.fontSize+2,"OUTLINE");
        text:SetWidth(W-btn_size*4);
        text:SetHeight(16);
        frame.textTitle = text;
        
        local h = -btn_size;
        for i=1,#frame.buttons,1 do
            frame.buttons[i]:SetPoint("TOPRIGHT",frame,"TOPRIGHT",h*(i-1),0);
        end
        self.frame = frame;
        
		self:AdjustFontColor()
		self:AdjustFonts()
        self:SetupUnitEvents();
    end
end



