
Spas = select(2, ...)

--	Option interface for the Addon:
Spas.options = {};

--	Saved options:
SPAS_PERSISTED_OPTIONS = { };


local addonMetadata = {
	["ADDONNAME"]		= "Spas",
	["SHORTNAME"]		= "SPAS",
	["PREFIX"]			= "SpasV1",
	["NORMALCHATCOLOR"]	= "0080F0",
	["HOTCHATCOLOR"]	= "F8F8F8",
};

Spas.lib = DigamAddonLib:new(addonMetadata);


--[[
	We COULD load settings recursively, but ... nah!
	Want to control what comes in and what does not.
--]]
function Spas:LoadSettings()
	Spas.options.TargetNameLength			= self:GetConfigValue("options.TargetNameLength", 4);
	Spas.options.AddonVisibility			= self:GetConfigValue("options.AddonVisibility", "ALWAYS");
	Spas.options.ButtonFrame = {}
	Spas.options.ButtonFrame.X				= self:GetConfigValue("options.ButtonFrame.X", 0);
	Spas.options.ButtonFrame.Y				= self:GetConfigValue("options.ButtonFrame.Y", 0);
	Spas.options.spellFrame = {}
	Spas.options.spellFrame.IconSize		= self:GetConfigValue("options.spellFrame.IconSize", 32);
	Spas.options.spellFrame.Spacing			= self:GetConfigValue("options.spellFrame.Spacing", 2);
	Spas.options.spellFrame.SpacingFooter	= self:GetConfigValue("options.spellFrame.SpacingFooter", 10);

	--	Load spellTriggers into spellInfo directly:
	Spas:LoadSpellTriggerSettings();
end;

--	Set saved spellTriggers on spellInfo:
function Spas:LoadSpellTriggerSettings()
	Spas.options.spells = { };

	local keyname = "options.spells.%s.%s";
	local _, unitClass = UnitClass("player");
	local spells = Spas.spells[unitClass];
	if spells then
		for spellName, spellInfo in next, spells do
			if not spellInfo.SpellTrigger then
				-- "cannot happen": no spelltrigger defined. Use NOCOOLDOWN as fallback:
				--print(string.format("Trigger for spell=%s not set, using default", spellName));
				--spellInfo.SpellTrigger = Spas:clone(Spas.config.spellTriggers[SPELLTRIGGER_NOCOOLDOWN]);
				spellInfo.SpellTrigger = Spas.config.spellTriggers[SPELLTRIGGER_NOCOOLDOWN];
			end;

			spellInfo.Enabled		= self:GetConfigValue(string.format(keyname, spellName, "Enabled"), spellInfo.Enabled);
			local spellTriggerID	= self:GetConfigValue(string.format(keyname, spellName, "SpellTrigger.ID"), spellInfo.SpellTrigger.ID);
			--	Avoid nil index error:
			if not spellTriggerID then
				spellTriggerID = SPELLTRIGGER_NOCOOLDOWN;
			end;
			
			--spellInfo.SpellTrigger	= Spas:clone(Spas.config.spellTriggers[spellTriggerID]);
			spellInfo.SpellTrigger	= Spas.config.spellTriggers[spellTriggerID];
			if not spellInfo.SpellTrigger then
				-- This time it CAN happen: typically after an Addon update and the old type does not exist.
				--	Use COOLDOWN as fallback:
				--spellInfo.SpellTrigger = Spas:clone(Spas.config.spellTriggers[SPELLTRIGGER_NOCOOLDOWN]);
				spellInfo.SpellTrigger = Spas.config.spellTriggers[SPELLTRIGGER_NOCOOLDOWN];
			end;

			spellInfo.ParamValue = self:GetConfigValue(string.format(keyname, spellName, "ParamValue"), spellInfo.ParamValue);
		end;
	end;
end;


--	Update options table with spellTriggers from spells:
function Spas:RefreshSpellTriggerSettings()
	for spellIndex, spellInfo in next, Spas.vars.sortedSpells do
		if not spellInfo.SpellTrigger then
			-- "cannot happen": no spelltrigger defined. Use NOCOOLDOWN as fallback:
			--spellInfo.SpellTrigger = Spas:clone(Spas.config.spellTriggers[SPELLTRIGGER_NOCOOLDOWN]);
			spellInfo.SpellTrigger = Spas.config.spellTriggers[SPELLTRIGGER_NOCOOLDOWN];
		end;

		Spas.options.spells[spellInfo.SpellName] =
			{
				["Enabled"]			= spellInfo.Enabled or 0,
				["ParamValue"]		= spellInfo.ParamValue,
				["SpellTrigger"]	= {
					["ID"]			= spellInfo.SpellTrigger.ID,
				},
			}
	end;
end;


function Spas:GetConfigValue(keypath, defaultValue)
	local keys = self:splitString(keypath, ".");

	local value;
	local subTable = SPAS_PERSISTED_OPTIONS;
	for index = 1, #keys - 1, 1 do
		subTable = subTable[keys[index]];
		if not subTable then
			return defaultValue;
		end;
	end;

	return subTable[keys[#keys]] or defaultValue;
end;


function Spas:SaveSettings()
	self:RefreshSpellTriggerSettings();
	self:SaveSettingsRecursively(Spas.options, "options", SPAS_PERSISTED_OPTIONS);
end;

function Spas:SaveSettingsRecursively(keyvalue, keyname, curtable)
	if type(keyvalue) == "string" then
		curtable[keyname] = keyvalue;
	elseif type(keyvalue) == "number" then
		curtable[keyname] = keyvalue;
	elseif type(keyvalue) == "boolean" then
		curtable[keyname] = keyvalue;
	elseif type(keyvalue) == "table" then
		curtable[keyname] = { };
		for key, value in next, keyvalue do
			self:SaveSettingsRecursively(value, key, curtable[keyname]);
		end;
	else
		print(string.format("Unsupported type: %s", type(keyvalue)));
	end;
end;


