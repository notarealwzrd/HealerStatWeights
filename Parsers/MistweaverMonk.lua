local name, addon = ...;



function addon:IsMistweaverMonk()
    local i = GetSpecialization();
	local specId = i and GetSpecializationInfo(i);
	return specId and (tonumber(specId) == addon.SpellType.MONK);
end


addon.SpecInfo = addon.SpecInfo or {};
addon.SpecInfo[addon.SpellType.MONK] = {
	{
		key="url",
		name="Website - Peak of Serenity",
		desc="This is the place for information if you play a Brewmaster, Mistweaver, or Windwalker Monk in World of Warcraft.",
		value="https://www.peakofserenity.com/"
	},
	{
		key="url",
		name="Discord - Peak of Serenity",
		desc="Official Discord Server for the Peak of Serenity Community.",
		value="http://www.discord.gg/peakofserenity"
	}
}




--[[----------------------------------------------------------------------------
	Mistweaver Monk Mastery
		- calculated from Gust of Mists healing (similar to Hpriest Echo of Light)
------------------------------------------------------------------------------]]
local function _Mastery(ev,spellInfo,heal,destUnit,M)
	if ( spellInfo.spellID == addon.Monk.GustOfMists ) then
		if ( M == 0 ) then
			return 0;
		end
		return heal / M / addon.MasteryConv;
	end
	return 0;
end



addon.StatParser:Create(addon.SpellType.MONK,nil,nil,nil,nil,_Mastery,nil,nil);