--[[
--	Spas Main file
--	--------------
--	Author: Mimma
--	File:   spasmain.lua
--	Desc:	Core functionality
--]]

Spas = select(2, ...)

function Spas:Initialize()
	Spas:LoadSettings();

	if Spas:LoadSpellTable() then
		Spas:CreateSpellButtons();
		Spas:RefreshSpellButtons();

		Spas:LoadSettings();		-- Must be called AFTER LoadSpells also to fill data for spellInfo

		SpasButtonFrame:Show();
		Spas:UpdateAddonVisibility();
	else
		Spas:LoadSettings();

		SpasButtonFrame:Hide();
	end;

	Spas:InitalizeConfigurationOptions();

	Spas.vars.addonLoaded = true;

	Spas:SaveSettings();
end;


function Spas:GetSelectedSpell(spellIndex)
	return Spas.vars.sortedSpells[1*spellIndex];
end;

function Spas:GetSpellByButtonIndex(buttonIndex)
	if buttonIndex then
		buttonIndex = 1 * buttonIndex;
		local spellInfo;
		for _, spellInfo in next, Spas.vars.sortedSpells do
			if spellInfo.ButtonIndex == buttonIndex then
				return spellInfo;
			end;
		end;
	end;
	return nil;
end;



--[[
	Addon communication
--]]

function Spas:HandleAddonMessage(msg, sender)
	local _, _, cmd, message, recipient = string.find(msg, "([^#]*)#([^#]*)#([^#]*)");	

	--	Ignore message if it is not for me. 
	--	Receipient can be blank, which means it is for everyone.
	if recipient ~= "" then
		-- Note: recipient comes with realmname. We need to compare
		-- with realmname too, even GetUnitName() does not return one:
		recipient = Spas.lib:getFullPlayerName(recipient);

		if recipient ~= ASpas.lib.localPlayerName then
			return
		end
	end


	if cmd == "TX_VERSION" then
		Spas:HandleTXVersion(message, sender)
	elseif cmd == "RX_VERSION" then
		Spas:HandleRXVersion(message, sender)
	end
end

--[[
	Respond to a TX_VERSION command.
	Input:
		msg is the raw message
		sender is the name of the message sender.
	We should whisper this guy back with our current version number.
	We therefore generate a response back (RX) in raid with the syntax:
	Spas:<sender (which is actually the receiver!)>:<version number>
--]]
function Spas:HandleTXVersion(message, sender)
	Spas.lib:sendAddonMessage(string.format("RX_VERSION#%s#", Spas.lib.addonVersion), sender);
end

--[[
	A version response (RX) was received. The version information is displayed locally.
--]]
function Spas:HandleRXVersion(message, sender)
	Spas.lib:echo(string.format("[%s] is using SpellAssignments version %s", sender, message))
end

function Spas_RepositionateButtonFrame(object)
	local x, y = object:GetLeft(), object:GetTop() - UIParent:GetHeight();

	Spas.options.ButtonFrame.X = x;
	Spas.options.ButtonFrame.Y = y;

	Spas:SaveSettings();
end;

function Spas:UpdateAddonVisibility()
	local visibility = Spas.ui.visibility[Spas.options.AddonVisibility or "ALWAYS"];

	local inInstance, instanceType = IsInInstance();

	local current = SPAS_VISIBILITY_SOLO;
	if instanceType == "pvp" then
		current = SPAS_VISIBILITY_PVP
	elseif IsInRaid() then
		current = SPAS_VISIBILITY_RAID
	elseif Spas.lib:isInParty() then
		current = SPAS_VISIBILITY_PARTY
	end;

	if bit.band(current, visibility.Mask) > 0 then
		SpasButtonFrame:Show();
	else
		SpasButtonFrame:Hide();
	end;
end;



--[[
--	EVENT HANDLERS
--]]

function Spas:OnConfigOpenButtonClick(self, ...)
	Spas:OpenConfiguration();
end;

function Spas:OnConfigCloseButtonClick()
	Spas:CloseConfiguration();
end;

function Spas_OnBeforeSpellClick(self, ...)
	--print(string.format("Clicking spell, unitID=%s", (self:GetAttribute("unit") or 'nil')));
end;

function Spas_OnAfterSpellClick(self, ...)
	local _, _, buttonIndex = string.find(self:GetName(), "spas_spellbutton_(%d*)");
	local spellInfo = Spas:GetSpellByButtonIndex(buttonIndex);
	--	This resets any incoming whisper:
	spellInfo.WhisperTimestamp = nil;
end;

function Spas:OnChatMsgAddon(event, ...)
	local prefix, msg, channel, sender = ...;

	if prefix == Spas.lib.addonPrefix then
		Spas:HandleAddonMessage(msg, sender);
	end
end

function Spas:OnChatMsgWhisper(event, ...)
	local message, fullName = ...;
	Spas:UpdateWhisperRules(fullName, message);
end;

function Spas:OnGroupRosterUpdate()
	Spas:RefreshSpellButtons();
	Spas:UpdateAddonVisibility();
end;

function Spas:OnEvent(self, event, ...)
	if (event == "ADDON_LOADED") then
		local addonname = ...;
		if addonname == Spas.lib.addonName then
			C_Timer.After(5, function()
				Spas:Initialize();
			end);

			SpasButtonFrame:Hide();
		end

	elseif (event == "CHAT_MSG_ADDON") then
		Spas:OnChatMsgAddon(event, ...)

	elseif (event == "CHAT_MSG_WHISPER") then
		Spas:OnChatMsgWhisper(event, ...)

	elseif (event == "GROUP_ROSTER_UPDATE") then
		Spas:OnGroupRosterUpdate(event, ...)
	end
end

function Spas_OnLoad()
	local _, classname = UnitClass("player");
	Spas.vars.playerClass = classname;
	Spas.vars.playerFullName = Spas.lib:getPlayerAndRealm("player");

	Spas.Version = Spas.lib:calculateVersion();

	Spas.lib:echo(string.format("Type %s/spas%s to configure the addon.", Spas.lib.chatColorHot, Spas.lib.chatColorNormal));

	_G["SpasVersionString"]:SetText(string.format("Spell Assignments / SPAS %s - by %s", Spas.lib.addonVersion, Spas.lib.addonAuthor));

	SpasConfigFrameCaption:SetText(string.format("Spell Assignments Configuration - %s", Spas.vars.playerClass));

    SpasEventFrame:RegisterEvent("ADDON_LOADED");
    SpasEventFrame:RegisterEvent("CHAT_MSG_ADDON");
    SpasEventFrame:RegisterEvent("CHAT_MSG_WHISPER");
    SpasEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
	

	local backdrops = {
		["DRUID"] = Spas.ui.backdrops.DruidFrame,
		["MAGE"] = Spas.ui.backdrops.MageFrame,
		["PALADIN"] = Spas.ui.backdrops.PaladinFrame,
		["PRIEST"] = Spas.ui.backdrops.PriestFrame,
		["SHAMAN"] = Spas.ui.backdrops.ShamanFrame,
	};
	SpasConfigFrame:SetBackdrop(backdrops[Spas.vars.playerClass]);
	SpasButtonFrame:SetBackdrop(Spas.ui.backdrops.ButtonFrame);

	C_ChatInfo.RegisterAddonMessagePrefix(Spas.lib.addonPrefix);
end

