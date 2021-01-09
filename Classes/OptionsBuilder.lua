local name, addon = ...;



--[[----------------------------------------------------------------------------
    OptionsBuilder - Helper class for constructing well-formatted AceOptions table
------------------------------------------------------------------------------]]
local OptionsBuilder = {};
local pattern_decimal = "%.2f";
local pattern_percent = "%.1f";



--[[----------------------------------------------------------------------------
    Create - Create a new instance of this class
------------------------------------------------------------------------------]]
--shallow table copy
local copy = addon.Util.CopyTable;

function OptionsBuilder.Create(h)
    local self = copy(OptionsBuilder);
    self.t = {};
    self.h = h;
    self.order = 1;
    return self;
end



--[[----------------------------------------------------------------------------
    AddCtrl - Add a control
------------------------------------------------------------------------------]]
function OptionsBuilder:AddCtrl(controlArgs)
    controlArgs.order = self.order;
    self.t["c"..self.order] = controlArgs;
    self.order = self.order + 1;
end



--[[----------------------------------------------------------------------------
    AddKVPair - Create a description KV Pair, formatted using options:
        Width        = 1.05 (default)
        Type         = "decimal", "integer", "percent", "percentint", "string"
        KeyColor     = "FFFFFF"
        ValueColor   = "FFF569"
        ValueSuffix  = ""
        ValuePrefix  = ""
------------------------------------------------------------------------------]]
local function fmtValue(value,options)
    local color = options.ValueColor;
    local prefix = options.ValuePrefix;
    local type = options.Type;
    local suffix = options.ValueSuffix;

    local value = value or 0.0;
    local str;

    if ( type == "percent" ) then
        value = tonumber(value) or 0.0;
        value = value * 100.0;
        str = string.format(pattern_percent,value);
    elseif ( type == "percentint" ) then
        value = tonumber(value) or 0.0;
        value = math.floor(value * 100.0);
        str = tostring(value);
    elseif ( type == "integer" ) then
        value = tonumber(value) or 0.0;
        value = math.floor(value);
        str = tostring(value);
    elseif ( type == "decimal" ) then
        value = tonumber(value) or 0.0;
        str = string.format(pattern_decimal,value);
    else
        str = tostring(value);
    end
    
    return "|CFF"..color..prefix..str..suffix.."|r";
end

local function fmtKey(key,options)
    local color = options.KeyColor;

    if ( color == "FFFFFF" ) then
        return key;
    else
        return "|cFF"..color..key.."|r";
    end
end

function OptionsBuilder:AddKVPair(index,options)
    local key = addon.SegmentLabels[index];
    local value = self.h[index];
    self:AddKVPairRaw(key,value,options)
end

function OptionsBuilder:AddKVPairRaw(key,value,options)
    local options = options or {};
    local key = key or "";
    local value = value or "";

    options.ValueSuffix = options.ValueSuffix or "";
    options.ValuePrefix = options.ValuePrefix or "";
    options.Type = options.Type or "decimal";
    options.Width = options.Width and tonumber(options.Width) or 0.90;

    if ( options.Type == "string" ) then
        options.KeyColor = options.KeyColor or "FFF569";
        options.ValueColor = options.ValueColor or "FFFFFF";
        self:AddCtrl({
            name = fmtKey(key,options),
            fontSize = "large",
            type = "description",
            width = options.Width / 1.05 * 0.3
        });
        self:AddCtrl({
            name = fmtValue(value,options),
            type = "description",
            width=options.Width / 1.05 * 0.75
        });
    else
        options.KeyColor = options.KeyColor or "FFFFFF";
        options.ValueColor = options.ValueColor or "FFF569";
        self:AddCtrl({
            name = fmtValue(value,options),
            type = "description",  
            fontSize = options.FontSize or "large",
            width=options.Width / 1.05 * 0.3
        });
        self:AddCtrl({
            name = fmtKey(key,options),
            type = "description",
            width = options.Width / 1.05 * 0.75
        });
    end
end


--[[----------------------------------------------------------------------------
    AddHeaderRow - Add text at the start of a header row
------------------------------------------------------------------------------]]
function OptionsBuilder:AddHeaderRow(text,width)
    self:AddCtrl({
        name = text,
        type = "description",
        fontSize = "large",
        width = width or 2.5
    });
end



--[[----------------------------------------------------------------------------
    AddText - Add text
------------------------------------------------------------------------------]]
function OptionsBuilder:AddText(text,width)
    self:AddCtrl({
        name = text,
        type = "description",
        width = width or 0.5
    });
end


--[[----------------------------------------------------------------------------
    AddHeaderButton - Add a button at the end of a header row
------------------------------------------------------------------------------]]
function OptionsBuilder:AddHeaderButton(name, desc, func)
    self:AddCtrl({
		name = name,
		desc = desc,
		type = "execute",
		width = 0.5,
		func = func
	});
end



--[[----------------------------------------------------------------------------
    AddDivider - Add a dividing line with optional text
------------------------------------------------------------------------------]]
function OptionsBuilder:AddDivider(text)
    local text = text or "";

    self:AddCtrl({
        name = text,
        type = "header",
        width = "full"
    });
end



--[[----------------------------------------------------------------------------
    AddNewLine - add a newline
------------------------------------------------------------------------------]]
function OptionsBuilder:AddNewLine()
    self:AddCtrl({
        name = "",
        type = "description",
        width = "full"
    });
end



--[[----------------------------------------------------------------------------
    NewLine - add a newline
------------------------------------------------------------------------------]]
function OptionsBuilder:GetOptions()
    return self.t;
end



--[[----------------------------------------------------------------------------
    URL - Add a wide control that contains a URL
------------------------------------------------------------------------------]]
function OptionsBuilder:AddURL(url,name,desc)
    local url = url or "";
    local desc = desc or "";

    self:AddCtrl({
        type = "input",
        name = name,
        desc = desc,
        get = function(info) return url end,
        set = function(info,val) end,
        width = 2.75
    });
end



addon.OptionsBuilder = OptionsBuilder;

