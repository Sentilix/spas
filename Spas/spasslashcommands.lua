
Spas = select(2, ...)


SLASH_SPAS_SPAS1 = "/spas"
SlashCmdList["SPAS_SPAS"] = function(msg)
	--	Options (if any) and params - the remainder (including eventual spaces):
	local _, _, option, params = string.find(msg, "(%S*)%s*(.*)")
	
	if not option or option == "" then
		option = "CONFIG"
	end
	option = string.upper(option);
		
	if (option == "CFG" or option == "CONFIG") then
		SlashCmdList["SPAS_CONFIG"]();
	elseif option == "VISIBILITY" then
		SlashCmdList["SPAS_VISIBILITY"](params);
	elseif option == "SHOW" then
		SlashCmdList["SPAS_SHOW"]();
	elseif option == "HIDE" then
		SlashCmdList["SPAS_HIDE"]();
	elseif option == "VERSION" then
		SlashCmdList["SPAS_VERSION"]();
	else
		Spas.lib:echo(string.format("Unknown command: %s", option));
	end
end


SLASH_SPAS_VISIBILITY1 = "/spasvisibility"
SlashCmdList["SPAS_VISIBILITY"] = function(params)
	if not Spas.vars.AddonLoaded then
		--	We get some funny errors if reading options before addon is ready.
		return;
	end;

	params = string.upper(params);
	local visibilityMode = Spas.ui.visibility[params];
	if visibilityMode then
		Spas.options.AddonVisibility = params;
		Spas.lib:echo(string.format("Visibility mode changed to %s%s%s", Spas.lib.chatColorHot, Spas.options.AddonVisibility, Spas.lib.chatColorNormal));
		Spas:UpdateAddonVisibility();
		Spas:SaveSettings();
		return;
	end;

	Spas.lib:echo("Usage:");
	Spas.lib:echo("  /spas visibility [mode]");
	Spas.lib:echo("where [mode] can be one of:");
	Spas.lib:echo("  ALWAYS        Always shown");
	Spas.lib:echo("  GROUP         Shown in Raid and Party");
	Spas.lib:echo("  RAID          Shown in Raid");
	Spas.lib:echo("  PARTY         Shown in Party (5 mans)");
	Spas.lib:echo("  PVP           Shown in Battlegrounds");
	Spas.lib:echo("  SOLO          Shown only when soloing");
	Spas.lib:echo("  NEVER         Never shown (disabled)");

	Spas.lib:echo(string.format("Current mode: %s%s%s", Spas.lib.chatColorHot, Spas.options.AddonVisibility, Spas.lib.chatColorNormal));
end


SLASH_SPAS_SHOW1 = "/spasshow"
SlashCmdList["SPAS_SHOW"] = function(msg)
	SpasButtonFrame:Show();
end


SLASH_SPAS_HIDE1 = "/spashide"	
SlashCmdList["SPAS_HIDE"] = function(msg)
	SpasButtonFrame:Hide();
end


SLASH_SPAS_VERSION1 = "/spasversion"
SlashCmdList["SPAS_VERSION"] = function(msg)
	if IsInRaid() or Spas.lib:isInParty() then
		Spas.lib:sendAddonMessage("TX_VERSION##");
	else
		Spas.lib:echo(string.format("%s is using SpellAssignments version %s", Spas.lib.localPlayerName, Spas.lib.addonVersion));
	end
end


SLASH_SPAS_CONFIG1 = "/spasconfig"
SLASH_SPAS_CONFIG2 = "/spascfg"
SlashCmdList["SPAS_CONFIG"] = function(msg)
	Spas:OpenConfiguration();
end


