
Spas = select(2, ...)

local GCD = 1.5;

Spas.SPELLTRIGGER_MASK_COOLDOWN			= 0x000001;	-- Set if spell is on CD
Spas.SPELLTRIGGER_MASK_ALREADYEXISTS	= 0x000002;	-- Set if spell already exists on Target.
Spas.SPELLTRIGGER_MASK_LOWHEALTH		= 0x000004;	-- Set if Target is at Low health
Spas.SPELLTRIGGER_MASK_MAGICDEBUFF		= 0x000010;	-- Target have a magic debuff
Spas.SPELLTRIGGER_MASK_DISEASEDEBUFF	= 0x000020;	-- Target have a disease debuff
Spas.SPELLTRIGGER_MASK_POISONDEBUFF		= 0x000040;	-- Target have a poision debuff
Spas.SPELLTRIGGER_MASK_CURSEDEBUFF		= 0x000080;	-- Target have a curse debuff
Spas.SPELLTRIGGER_MASK_WHISPER			= 0x000100;	-- Set if Target whispered me
Spas.SPELLTRIGGER_MASK_MINDCONTROLLED	= 0x000200;	-- Set if Target is Mindcontrolled
Spas.SPELLTRIGGER_MASK_SPELLACTIVE		= 0x001000;	-- Target have one of these buffs
Spas.SPELLTRIGGER_MASK_SPELLNOTACTIVE	= 0x002000;	-- Target does not have one of these buffs

SPELLTRIGGER_NOCOOLDOWN					= "NOCOOLDOWN";
SPELLTRIGGER_NOTONTARGET				= "NOTONTARGET";
SPELLTRIGGER_LOWHEALTH					= "LOWHEALTH";
SPELLTRIGGER_DEBUFF_TYPE				= "DEBUFF_TYPE";
SPELLTRIGGER_TARGETWHISPER				= "TARGET_WHISPER";
SPELLTRIGGER_MINDCONTROLLED				= "MINDCONTROLLED";
SPELLTRIGGER_SPELLACTIVE				= "SPELLACTIVE";
SPELLTRIGGER_SPELLNOTACTIVE				= "SPELLNOTACTIVE";



Spas.config.debuffTypes = {
	["curse"]	= { ["Name"] = "curse",   ["Mask"] = Spas.SPELLTRIGGER_MASK_CURSEDEBUFF, },
	["disease"]	= { ["Name"] = "disease", ["Mask"] = Spas.SPELLTRIGGER_MASK_DISEASEDEBUFF, },
	["magic"]	= { ["Name"] = "magic",   ["Mask"] = Spas.SPELLTRIGGER_MASK_MAGICDEBUFF, },
	["poison"]	= { ["Name"] = "poison",  ["Mask"] = Spas.SPELLTRIGGER_MASK_POISONDEBUFF, },
}


--	SortOrder: define the order in dropdown boxes but does not have any functional as such:
Spas.config.spellTriggers = {
	[SPELLTRIGGER_NOCOOLDOWN] = {
		["ID"] = SPELLTRIGGER_NOCOOLDOWN,
		["Name"] = "Not on Cooldown",
		["SortOrder"] = 1,
		["Mask"] = Spas.SPELLTRIGGER_MASK_COOLDOWN,
		["Validate"] = function(paramValue) return paramValue; end,
	},
	[SPELLTRIGGER_NOTONTARGET] = {
		["ID"] = SPELLTRIGGER_NOTONTARGET,
		["Name"] = "Current spell is not active on Target",
		["SortOrder"] = 2,
		["Mask"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_ALREADYEXISTS,
		["Validate"] = function(paramValue) return paramValue; end,
	},
	[SPELLTRIGGER_LOWHEALTH] = {
		["ID"] = SPELLTRIGGER_LOWHEALTH,
		["Name"] = "Target have Low health", 
		["SortOrder"] = 3,
		["Mask"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_LOWHEALTH,
		["ParamSize"] = "small",
		["ParamText"] = "Percent:",
		["DefaultValue"] = 50,
		["Validate"] = function(paramValue)
			return paramValue, tonumber(paramValue); 
		end,
	},
	[SPELLTRIGGER_SPELLACTIVE] = {
		["ID"] = SPELLTRIGGER_SPELLACTIVE,
		["Name"] = "Target have one of these buffs:", 
		["SortOrder"] = 4,
		["Mask"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_SPELLACTIVE,
		["ParamSize"] = "large",
		["ParamText"] = "SpellID(s):",
		["DefaultValue"] = "insert spell name(s) separated by comma",
		["Validate"] = function(paramValue) 
			local paramNames = Spas:splitString(string.lower(paramValue), ",");
			local spellString = "";
			local spellNames = { };
			for n = 1, #paramNames, 1 do
				local spellName = Spas:trim(paramNames[n]);
				local _, _, _, _, _, _, spellId = GetSpellInfo(spellName);
				if spellId then
					if spellString ~= "" then
						spellString = spellString..", ";
					end;
					spellString = spellString..spellName;
					spellNames[spellName] = spellId;
				end;
			end;
			return spellString, spellNames;
		end,
	},
	[SPELLTRIGGER_SPELLNOTACTIVE] = {
		["ID"] = SPELLTRIGGER_SPELLNOTACTIVE,
		["Name"] = "Target does not have one of these buffs:", 
		["SortOrder"] = 5,
		["Mask"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_SPELLNOTACTIVE,
		["ParamSize"] = "large",
		["ParamText"] = "SpellID(s):",
		["DefaultValue"] = "insert spell name(s) separated by comma",
		["Validate"] = function(paramValue) 
			local paramNames = Spas:splitString(string.lower(paramValue), ",");
			local spellString = "";
			local spellNames = { };
			for n = 1, #paramNames, 1 do
				local spellName = Spas:trim(paramNames[n]);
				local _, _, _, _, _, _, spellId = GetSpellInfo(spellName);
				if spellId then
					if spellString ~= "" then
						spellString = spellString..", ";
					end;
					spellString = spellString..spellName;
					spellNames[spellName] = spellId;
				end;
			end;
			return spellString, spellNames;
		end,
	},
	[SPELLTRIGGER_DEBUFF_TYPE] = {
		["ID"] = SPELLTRIGGER_DEBUFF_TYPE,
		["Name"] = "Target have one of these Debuffs:", 
		["SortOrder"] = 6,
		["Mask"] = Spas.SPELLTRIGGER_MASK_COOLDOWN,
		["MaskDefault"] = Spas.SPELLTRIGGER_MASK_COOLDOWN,
		["ParamSize"] = "medium",
		["ParamText"] = "Debuff type(s):",
		["DefaultValue"] = "curse, disease, magic, poison",
		["Validate"] = function(paramValue)
			local debuffMask = 0;
			local debuffString = "";
			local debuffTypes = Spas:splitString(string.lower(paramValue), ",");
			for n = 1, #debuffTypes, 1 do
				local debuffType = Spas:trim(debuffTypes[n]);
				local debuffInfo = Spas.config.debuffTypes[debuffType];
				if debuffInfo then
					if debuffString ~= "" then
						debuffString = debuffString..", ";
					end;
					debuffString = debuffString .. debuffType;
					debuffMask = debuffMask + debuffInfo.Mask;
				end;
			end;
			--	Make sure Mask also include COOLDOWN event as well:
			debuffMask = bit.bor(debuffMask, Spas.SPELLTRIGGER_MASK_COOLDOWN);
			return debuffString, debuffMask;
		end,
	},
	[SPELLTRIGGER_TARGETWHISPER] = {
		["ID"] = SPELLTRIGGER_TARGETWHISPER,
		["Name"] = "Target whispers you a text.", 
		["SortOrder"] = 10,
		["Mask"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_WHISPER,
		["ParamSize"] = "medium",
		["ParamText"] = "Contains:",
		["DefaultValue"] = "PI",
		["Blinkable"] = 1,
		["Validate"] = function(paramValue) return string.lower(paramValue); end,
	},
	--	Special rules:
	[SPELLTRIGGER_MINDCONTROLLED] = {
		["ID"] = SPELLTRIGGER_MINDCONTROLLED,
		["Name"] = "Target is Mindcontrolled", 
		["SortOrder"] = 11,
		["Mask"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_MINDCONTROLLED,
		["ParamSize"] = nil,
		["ParamText"] = nil,
		["DefaultValue"] = "cause insanity",
		["Blinkable"] = 1,
		["Validate"] = function(paramValue) 
			local paramNames = Spas:splitString(string.lower(paramValue), ",");
			local spellString = "";
			local spellNames = { };
			for n = 1, #paramNames, 1 do
				local spellName = Spas:trim(paramNames[n]);
				local _, _, _, _, _, _, spellId = GetSpellInfo(spellName);
				if spellId then
					if spellString ~= "" then
						spellString = spellString..", ";
					end;
					spellString = spellString..spellName;
					spellNames[spellName] = spellId;
				end;
			end;
			return spellString, spellNames;
		end,
	},
};


Spas.spells = {};
Spas.spells["PRIEST"] = {
	["Cure Disease"] = {
		["IconID"] = 135935,
		["SortOrder"] = 1,
		["SpellID"] = 528,
		["CoolDown"] = GCD,
		["Enabled"] = 0,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_DEBUFF_TYPE],
		["ParamSize"] = "medium",
		["ParamText"] = "Debuff type(s):",
		["ParamValue"] = "disease",
		["ParamDefault"] = "disease",
		["ParamCompiled"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_DISEASEDEBUFF,
	},
	["Abolish Disease"] = {
		["IconID"] = 136066,
		["SortOrder"] = 2,
		["SpellID"] = 552,
		["CoolDown"] = 20,			-- No GCD, but lasts 20 seconds on target.
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_DEBUFF_TYPE],
		["ParamSize"] = "medium",
		["ParamText"] = "Debuff type(s):",
		["ParamValue"] = "disease",
		["ParamDefault"] = "disease",
		["ParamCompiled"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_DISEASEDEBUFF,
	},
	["Dispel Magic"] = {
		["IconID"] = 135894,
		["SortOrder"] = 3,
		["SpellID"] = 527,
		["CoolDown"] = GCD,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_DEBUFF_TYPE],
		["ParamSize"] = "medium",
		["ParamText"] = "Debuff type(s):",
		["ParamValue"] = "magic",
		["ParamDefault"] = "magic",
		["ParamCompiled"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_MAGICDEBUFF,
	},
	["Fear Ward"] = {
		["IconID"] = 135902,
		["SortOrder"] = 4,
		["SpellID"] = 6346,
		["CoolDown"] = 30,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_NOTONTARGET],
	},
	["Flash Heal"] = {
		["IconID"] = 135907,
		["SortOrder"] = 5,
		["SpellID"] = 2061,
		["CoolDown"] = GCD,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_LOWHEALTH],
		["ParamSize"] = "small",
		["ParamText"] = "Percent:",
		["ParamValue"] = "30",
	},
	["Renew"] = {
		["IconID"] = 135953,
		["SortOrder"] = 6,
		["SpellID"] = 139,
		["CoolDown"] = 15,			-- No GCD, but lasts 15 seconds on target.
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_NOTONTARGET],
	},
	["Power Word: Shield"] = {
		["IconID"] = 135940,		-- ...
		["SortOrder"] = 7,			-- ...
		["SpellID"] = 17,			-- Lowest spell ID (currently unused)
		["CoolDown"] = 15,			-- CD is only 4 seconds, but target will have a debuff for 15 seconds anyway!
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_NOTONTARGET],
	},
	["Power Infusion"] = {
		["IconID"] = 135939,
		["SortOrder"] = 8,
		["SpellID"] = 10060,
		["CoolDown"] = 180,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_TARGETWHISPER],
	},
};

Spas.spells["MAGE"] = {
	["Remove Lesser Curse"] = {
		["IconID"] = 136082,		-- ...
		["SortOrder"] = 1,			-- ...
		["SpellID"] = 475,			-- Lowest spell ID (currently unused)
		["CoolDown"] = GCD,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_DEBUFF_TYPE],
		["ParamSize"] = "medium",
		["ParamText"] = "Debuff type(s):",
		["ParamValue"] = "curse",
		["ParamDefault"] = "curse",
		["ParamCompiled"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_CURSEDEBUFF,
	},
	["Polymorph"] = {
		["IconID"] = 136071,
		["SortOrder"] = 2,
		["SpellID"] = 118,
		["CoolDown"] = GCD,			-- Lasts for up to 20 seconds, but we need to be able to re-cast.
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_MINDCONTROLLED],
		["ParamDefaultInternal"] = "cause insanity",
		--	"Cause Insanity" (24327)	: Hakkar@Zul'Gurub
		--	"Cause Insanity" (26079)	: Qiraji Brainwasher and Mindslayer @ AQ40
		--	"Weakened Soul" (6788)		: Can use this while testing!
	}
};

Spas.spells["DRUID"] = {
	["Abolish Poison"] = {
		["IconID"] = 136068,		-- ...
		["SortOrder"] = 1,			-- ...
		["SpellID"] = 2893,			-- Lowest spell ID (currently unused)
		["CoolDown"] = 8,			-- No CD, but lasts 8 seconds on target.
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_DEBUFF_TYPE],
		["ParamSize"] = "medium",
		["ParamText"] = "Debuff type(s):",
		["ParamValue"] = "poison",
		["ParamDefault"] = "poison",
		["ParamCompiled"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_POISONDEBUFF,
	},
	["Remove Curse"] = {
		["IconID"] = 135952,
		["SortOrder"] = 2,
		["SpellID"] = 2782,
		["CoolDown"] = GCD,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_DEBUFF_TYPE],
		["ParamSize"] = "medium",
		["ParamText"] = "Debuff type(s):",
		["ParamValue"] = "curse",
		["ParamDefault"] = "curse",
		["ParamCompiled"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_CURSEDEBUFF,
	},
	["Rejuvenation"] = {
		["IconID"] = 136081,
		["SortOrder"] = 3,
		["SpellID"] = 774,
		["CoolDown"] = 12+2,		-- No CD, but lasts 12 seconds on target. +2 seconds for cast time.
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_NOCOOLDOWN],
	},
	["Regrowth"] = {
		["IconID"] = 136085,
		["SortOrder"] = 4,
		["SpellID"] = 8936,
		["CoolDown"] = 21+2,		-- No CD, but lasts 21 seconds on target. +2 seconds for cast time.
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_NOCOOLDOWN],
	},
	["Swiftmend"] = {
		["IconID"] = 134914,
		["SortOrder"] = 5,
		["SpellID"] = 18562,
		["CoolDown"] = 15,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_SPELLACTIVE],
		["ParamDefault"] = "regrowth, rejuvenation";		-- One of these spells are required for Swiftmend
		["ParamCompiled"] = { ["regrowth"] = 8936, ["rejuvenation"] = 774 },
	},
	["Innervate"] = {
		["IconID"] = 136048,
		["SortOrder"] = 6,
		["SpellID"] = 29155,
		["CoolDown"] = 360,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_NOCOOLDOWN],
	},
};

Spas.spells["PALADIN"] = {
	["Divine Intervention"] = {
		["IconID"] = 136106,		-- ...
		["SortOrder"] = 1,			-- ...
		["SpellID"] = 19752,		-- Lowest spell ID (currently unused)
		["CoolDown"] = 180,			-- 3 minute GCD
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_NOCOOLDOWN],
	},
	["Blessing of Freedom"] = {
		["IconID"] = 135968,
		["SortOrder"] = 2,
		["SpellID"] = 1044,
		["CoolDown"] = 20,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_NOCOOLDOWN],
	},
	["Blessing of Protection"] = {
		["IconID"] = 135964,
		["SortOrder"] = 3,
		["SpellID"] = 1022,
		["CoolDown"] = 300,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_NOCOOLDOWN],
	},
	["Purify"] = {
		["IconID"] = 135949,		-- Removes disease and poison.
		["SortOrder"] = 4,
		["SpellID"] = 1152,
		["CoolDown"] = GCD,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_DEBUFF_TYPE],
		["ParamSize"] = "medium",
		["ParamText"] = "Debuff type(s):",
		["ParamValue"] = "disease, poison",
		["ParamDefault"] = "disease, poison",
		["ParamCompiled"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_DISEASEDEBUFF + Spas.SPELLTRIGGER_MASK_POISONDEBUFF,
	},
	["Cleanse"] = {
		["IconID"] = 135953,		-- Removes disease, poison and magic.
		["SortOrder"] = 5,
		["SpellID"] = 4987,
		["CoolDown"] = GCD,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_DEBUFF_TYPE],
		["ParamSize"] = "medium",
		["ParamText"] = "Debuff type(s):",
		["ParamValue"] = "disease, poison, magic",
		["ParamDefault"] = "disease, poison, magic",
		["ParamCompiled"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_DISEASEDEBUFF + Spas.SPELLTRIGGER_MASK_MAGICDEBUFF + Spas.SPELLTRIGGER_MASK_POISONDEBUFF,
	},
	["Lay on hands"] = {
		["IconID"] = 135928,
		["SortOrder"] = 6,
		["SpellID"] = 633,
		["CoolDown"] = 2400,		-- In best case 40 minutes GCD if having imp Lay on Hands (rank 2)
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_NOCOOLDOWN],
	},
	["Holy Shock"] = {
		["IconID"] = 135972,
		["SortOrder"] = 7,
		["SpellID"] = 20473,
		["CoolDown"] = 30,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_LOWHEALTH],
		["ParamSize"] = "small",
		["ParamText"] = "Percent:",
		["ParamValue"] = "30",
	},
	["Flash of Light"] = {
		["IconID"] = 135907,
		["SortOrder"] = 8,
		["SpellID"] = 19750,
		["CoolDown"] = GCD,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_LOWHEALTH],
		["ParamSize"] = "small",
		["ParamText"] = "Percent:",
		["ParamValue"] = "50",
		["ParamDefault"] = "50",
	},
};

Spas.spells["SHAMAN"] = {
	["Purge"] = {
		["IconID"] = 136075,		-- Removes 1-2 magic effects
		["SortOrder"] = 1,			-- ...
		["SpellID"] = 370,			-- Lowest spell ID (currently unused)
		["CoolDown"] = GCD,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_DEBUFF_TYPE],
		["ParamSize"] = "medium",
		["ParamText"] = "Debuff type(s):",
		["ParamValue"] = "magic",
		["ParamDefault"] = "magic",
		["ParamCompiled"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_MAGICDEBUFF,
	},
	["Cure Poison"] = {
		["IconID"] = 136067,		-- Removes poison
		["SortOrder"] = 2,
		["SpellID"] = 526,
		["CoolDown"] = GCD,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_DEBUFF_TYPE],
		["ParamSize"] = "medium",
		["ParamText"] = "Debuff type(s):",
		["ParamValue"] = "poison",
		["ParamDefault"] = "poison",
		["ParamCompiled"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_POISONDEBUFF,
	},
	["Cure Disease"] = {
		["IconID"] = 136083,		-- Removes disease
		["SortOrder"] = 3,
		["SpellID"] = 2870,
		["CoolDown"] = GCD,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_DEBUFF_TYPE],
		["ParamSize"] = "medium",
		["ParamText"] = "Debuff type(s):",
		["ParamValue"] = "disease",
		["ParamDefault"] = "disease",
		["ParamCompiled"] = Spas.SPELLTRIGGER_MASK_COOLDOWN + Spas.SPELLTRIGGER_MASK_DISEASEDEBUFF,
	},
	["Chain Heal"] = {
		["IconID"] = 136042,
		["SortOrder"] = 4,
		["SpellID"] = 1064,
		["CoolDown"] = GCD,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_LOWHEALTH],
		["ParamSize"] = "small",
		["ParamText"] = "Percent:",
		["ParamValue"] = "30",
	},
	["Lesser Healing Wave"] = {
		["IconID"] = 136043,
		["SortOrder"] = 5,
		["SpellID"] = 8004,
		["CoolDown"] = GCD,
		["Enabled"] = 1,
		["SpellTrigger"] = Spas.config.spellTriggers[SPELLTRIGGER_LOWHEALTH],
		["ParamSize"] = "small",
		["ParamText"] = "Percent:",
		["ParamValue"] = "50",
		["ParamDefault"] = "50",
	},
};

SPAS_VISIBILITY_NEVER		= 0x0000;
SPAS_VISIBILITY_SOLO		= 0x0001;
SPAS_VISIBILITY_PARTY		= 0x0002;
SPAS_VISIBILITY_RAID		= 0x0004;
SPAS_VISIBILITY_PVP			= 0x0008;
SPAS_VISIBILITY_ALWAYS		= 0x00ff;


Spas.ui.visibility = {
	["ALWAYS"] = {
		["Name"] = "Always",
		["Mask"] = SPAS_VISIBILITY_ALWAYS,
	},
	["GROUP"] = {
		["Name"] = "Raids and Groups",
		["Mask"] = SPAS_VISIBILITY_PARTY + SPAS_VISIBILITY_RAID,
	},
	["RAID"] = {
		["Name"] = "Raids only",
		["Mask"] = SPAS_VISIBILITY_RAID,
	},
	["PARTY"] = {
		["Name"] = "Groups only",
		["Mask"] = SPAS_VISIBILITY_PARTY,
	},
	["PVP"] = {
		["Name"] = "Battlegrounds only",
		["Mask"] = SPAS_VISIBILITY_PVP,
	},
	["SOLO"] = {
		["Name"] = "Solo only",
		["Mask"] = SPAS_VISIBILITY_SOLO,
	},
	["NEVER"] = {
		["Name"] = "Never (disabled)",
		["Mask"] = SPAS_VISIBILITY_NEVER,
	},
};



Spas.ui.backdrops = {}
Spas.ui.backdrops.DruidFrame = {
	bgFile = "Interface\\TalentFrame\\DruidRestoration-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 600,
};
Spas.ui.backdrops.MageFrame = {
	bgFile = "Interface\\TalentFrame\\MageFrost-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 600,
};
Spas.ui.backdrops.ShamanFrame = {
	bgFile = "Interface\\TalentFrame\\ShamanEnhancement-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 600,
};
Spas.ui.backdrops.PriestFrame = {
	bgFile = "Interface\\TalentFrame\\PriestDiscipline-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 600,
};
Spas.ui.backdrops.PaladinFrame = {
	bgFile = "Interface\\TalentFrame\\PaladinHoly-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 600,
};

Spas.ui.backdrops.ButtonFrame = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 4,
	tileEdge = false,
	tile = 0,
	tileSize = 32,
};




Spas.ui.classes = {}
Spas.ui.classes["DRUID"] = {
	["Color"] = { ["r"] = 255, ["g"] = 125, ["b"] = 10 },
	["IconFile"] = "Interface\\Icons\\classicon_druid",
}
Spas.ui.classes["HUNTER"] = {
	["Color"] = { ["r"] = 171, ["g"] = 212, ["b"] = 115 },
	["IconFile"] = "Interface\\Icons\\classicon_hunter",
}
Spas.ui.classes["MAGE"] = {
	["Color"] = { ["r"] = 105, ["g"] = 204, ["b"] = 240 },
	["IconFile"] = "Interface\\Icons\\classicon_mage",
}
Spas.ui.classes["PALADIN"] = {
	["Color"] = { ["r"] = 245, ["g"] = 140, ["b"] = 186 },
	["IconFile"] = "Interface\\Icons\\classicon_paladin",
}
Spas.ui.classes["PRIEST"] = {
	["Color"] = { ["r"] = 255, ["g"] = 255, ["b"] = 255 },
	["IconFile"] = "Interface\\Icons\\classicon_priest",
}
Spas.ui.classes["ROGUE"] = {
	["Color"] = { ["r"] = 255, ["g"] = 245, ["b"] = 105 },
	["IconFile"] = "Interface\\Icons\\classicon_rogue",
}
Spas.ui.classes["SHAMAN"] = {
	["Color"] = { ["r"] = 0, ["g"] = 112, ["b"] = 221 },
	["IconFile"] = "Interface\\Icons\\classicon_shaman",
}
Spas.ui.classes["WARLOCK"] = {
	["Color"] = { ["r"] = 148, ["g"] = 130, ["b"] = 201 },
	["IconFile"] = "Interface\\Icons\\classicon_warlock",
}
Spas.ui.classes["WARRIOR"] = {
	["Color"] = { ["r"] = 199, ["g"] = 156, ["b"] = 110 },
	["IconFile"] = "Interface\\Icons\\classicon_warrior",
}



