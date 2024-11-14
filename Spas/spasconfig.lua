--[[
--	Spas configuration
--	------------------
--	Author: Mimma
--	File:   spasconfig.lua
--	Desc:	Configuration functionality
--]]

Spas = select(2, ...)

--	General variables:
Spas.vars = {};
Spas.vars.BootTime = GetTime();
Spas.vars.addonLoaded = false;
Spas.vars.maxSelectableSpells = 8;		--	This defines how many frames (buttons) we will pre-define.
Spas.vars.sortedSpells = {};			--	Learned spells (hidden or shown) for this character.
--	spellInfo.SpellName			Name of spell
--	spellInfo.FullName			Assigned player <Name+Realm>
--	spellInfo.UnitID			Assigned <unitID> - avoid using this if possible; it can change midfight!
--	spellInfo.OnCooldown		nil if not on CD, <value> until spell is nt on CD anymore.
--	spellInfo.ButtonIndex		1..8: which button is this spell assigned to in the UI (effectively Sort Order)
--	spellInfo.DisplayMask		Set by CD's etc. See ACTIVATION_MASKs in spasconstants.lua
--	from Spas.spells[class]:
--		spellInfo.IconID			Spell Icon ID
--		spellInfo.SortOrder			Sort order 1..8 on UI (before checking for Enabled flag I guess)
--		spellInfo.SpellID			Lowest spellID
--		spellInfo.CoolDown			Cooldown time. Lowest is GCD (1.5 second).
--		spellInfo.Enabled			0=Disabled, 1=Enabled
--		spellInfo.SpellTrigger		Contains spelltrigger structure from Spas.config.spellTriggers[<spelltrigger type>],
--		spellInfo.ParamSize			(for spells with parameters) Size of editbox: "small", "medium" or "large"
--		spellInfo.ParamText			(for spells with parameters) Caption shown in UI
--		spellInfo.ParamValue		(for spells with parameters) Raw text value as shown in textbox,
--		spellInfo.ParamDefault		(for spells with parameters) Default value (text) for Spell. If nil the triggers default is used.
--		spellInfo.ParamCompiled		(for spells with parameters) Compiled value (for example int, trimmed string or tables)
Spas.vars.spellButtons = {};			--	Buttons [1..8] so it is easy to do lookups.
Spas.vars.spellLabels = {};				--	Label [1..8] so it is easy to do lookups.
Spas.vars.configRules = {};				--	SpellTrigger [1..8] on config screen.

Spas.vars.selectableTargets = {};
local _, playerClass = UnitClass("player");
Spas.vars.playerClass = playerClass;
Spas.vars.playerFullName = "";

Spas.config = {};
Spas.config.Mode = 1;		--	1: Spells, 2: UI

Spas.ui = {};
Spas.ui.ConfigButtonAlphaOff = 0.7;
Spas.ui.ConfigButtonAlphaOn = 1.0;
Spas.ui.blinkAlphaOn = 1.0;
Spas.ui.blinkAlphaOff = 0.2;
Spas.ui.blinkAlpha = Spas.ui.blinkAlphaOn;
Spas.ui.coolDownAlpha = 0.3;
Spas.ui.colourSelectedSpell = '4444ff';
Spas.ui.configFrame = {}
Spas.ui.configFrame.iconSize = 48;
Spas.ui.configFrame.iconSpacing = 12;
Spas.ui.configFrame.hiddenSpellAlpha = 0.3;




--[[
	Initalize Configuration menu
--]]
function Spas:InitalizeConfigurationOptions()
	local posX = 0 + 40;
	local posY = 0 - 40;
	
	--	Show available spells:
	local iconHeight = Spas.ui.configFrame.iconSize + Spas.ui.configFrame.iconSpacing;
	local index;
	for spellIndex, spellInfo in next, Spas.vars.sortedSpells do
		local ruleControl = Spas.vars.configRules[spellInfo.ButtonIndex];
		local controlName = ruleControl:GetName();

		local spellButton = _G[controlName.."Spell"];
		spellButton:SetNormalTexture(spellInfo.IconID);
		spellButton:SetPushedTexture(spellInfo.IconID);
		spellButton:SetScript("OnClick", Spas_OnSpellConfigButtonClick);
		spellButton:Show();

		ruleControl:SetPoint("TOPLEFT", posX, posY);
		ruleControl:Show();

		posY = posY - iconHeight;
	end;

	SpasConfig:SetHeight(#Spas.vars.sortedSpells * iconHeight + 164);		--	164: room for top+bottom buttons etc.
end;


function Spas:RefreshConfigurationScreen()
	if Spas.config.Mode == 1 then
		SpasConfigButtonFrameSpellButton:SetAlpha(Spas.ui.ConfigButtonAlphaOn);
		SpasConfigButtonFrameUIButton:SetAlpha(Spas.ui.ConfigButtonAlphaOff);

		SpasConfigSpellFrame:Show();
		SpasConfigUIFrame:Hide();
		Spas:RefreshSpellConfigurationScreen();
	else
		SpasConfigButtonFrameSpellButton:SetAlpha(Spas.ui.ConfigButtonAlphaOff);
		SpasConfigButtonFrameUIButton:SetAlpha(Spas.ui.ConfigButtonAlphaOn);

		SpasConfigSpellFrame:Hide();
		SpasConfigUIFrame:Show();
		Spas:RefreshUIConfigurationScreen();
	end;
end;


function Spas:RefreshSpellConfigurationScreen()
	local spellIndex, spellInfo;
	for spellIndex, spellInfo in next, Spas.vars.sortedSpells do
		local ruleControl = Spas.vars.configRules[spellInfo.ButtonIndex];
		local controlName = ruleControl:GetName();

		--	Update spell icon status (enabled/disabled)
		local button = _G[controlName.."Spell"];
		if spellInfo.Enabled == 1 then
			button:SetAlpha(1.0);
		else
			button:SetAlpha(Spas.ui.configFrame.hiddenSpellAlpha);
		end;


		--	Update Comboboxes:
		--local spellTrigger = Spas.config.spellTriggers[spellInfo.SpellTrigger.ID];
		button = _G[controlName.."Trigger"];
		button:SetDefaultText(spellInfo.SpellTrigger.Name);

		--	Update Parameters for combobox:
		button = _G[controlName.."Params"];
		button:SetText(spellInfo.ParamValue or spellInfo.ParamDefault or "");

		local editboxSizes = {
			["small"]	= 48,
			["medium"]	= 200,
			["large"]	= 350,
		};

		local paramSize = spellInfo.SpellTrigger.ParamSize or "";
		if paramSize == "" then
			_G[controlName.."ParamsCaption"]:Hide();
			_G[controlName.."ParamsTexLeft"]:Hide();
			_G[controlName.."ParamsTexRight"]:Hide();
			_G[controlName.."ParamsTexCenter"]:Hide();
			button:Hide();
		else
			_G[controlName.."ParamsCaption"]:SetText(spellInfo.SpellTrigger.ParamText or "");

			_G[controlName.."ParamsCaption"]:Show();
			_G[controlName.."ParamsTexLeft"]:Show();
			_G[controlName.."ParamsTexRight"]:Show();
			_G[controlName.."ParamsTexCenter"]:Show();

			button:SetWidth(editboxSizes[paramSize] or 200);

			button:Show();
		end;
	end;
end;

function Spas:RefreshUIConfigurationScreen()
	SpasUIConfigIconSizeCaption:SetText(string.format("Size: %d x %s pixels", Spas.options.spellFrame.IconSize, Spas.options.spellFrame.IconSize));
	SpasUIConfigIconPaddingCaption:SetText(string.format("Padding: %d pixels", Spas.options.spellFrame.Spacing));
end;


--[[
	Save changes which are not already persisted.
	Also. Copy to Saved options.
--]]
function Spas:SaveConfigurationChanges()
	--	Spell enabled/disabled is already changed in-game.
	--	Rule is already saved.
	--	Rule Parameter is NOT stored, this will be done here.

	local spellIndex, spellInfo;
	for spellIndex, spellInfo in next, Spas.vars.sortedSpells do
		local ruleControl = Spas.vars.configRules[spellInfo.ButtonIndex];
		local controlName = ruleControl:GetName();

		--	Update Parameters in SpellInfo:
		button = _G[controlName.."Params"];
		
		--	Validate input:
		--	returns the formatted string
		if spellInfo.Enabled == 1 then
			local paramString, paramCompiled = spellInfo.SpellTrigger.Validate(button:GetText());

			--	For SpellTriggers with parameters: Check if parameter is nil and use trigger default:
			if spellInfo.SpellTrigger.DefaultValue then
				if not paramCompiled then
					--	Check spellDefault first:
					if spellInfo.ParamDefault then
						paramString, paramCompiled = spellInfo.SpellTrigger.Validate(spellInfo.ParamDefault);
					end;
					--	If spell does not have a valid default, then use the trigger default:
					if not paramCompiled then
						paramString, paramCompiled = spellInfo.SpellTrigger.Validate(spellInfo.SpellTrigger.DefaultValue);
					end;
				end;
				spellInfo.ParamCompiled = paramCompiled;
			end;
			spellInfo.ParamValue = paramString;
			button:SetText(paramString);
		end;
	end;

	self:SaveSettings();
end;

function Spas:OnSpellTriggerSelect(buttonIndex, spellTriggerID)
--	print(string.format("ButtonIndex=%d, spellTriggerID=%s", buttonIndex, spellTriggerID));

	local spellInfo = Spas:GetSpellByButtonIndex(buttonIndex);
	if spellInfo then
		spellInfo.SpellTrigger = Spas.config.spellTriggers[spellTriggerID];
		Spas:RefreshSpellConfigurationScreen();
	end;
end;

function Spas_OnSpellConfigButtonClick(self)
	local _, _, buttonIndex = string.find(self:GetName(), "spas_triggercontrol_(%d*)Spell");
	local buttonType = GetMouseButtonClicked();
	if buttonType == "LeftButton" then
		Spas:SetSpellEnabled(buttonIndex, 1);
	else
		Spas:SetSpellEnabled(buttonIndex, 0);
	end;
end;

function Spas:OpenConfiguration()
	Spas:RefreshConfigurationScreen();
	SpasConfig:Show();
end;

function Spas:CloseConfiguration()
	Spas:SaveConfigurationChanges();
	SpasConfig:Hide();
end;

function Spas:SetSpellEnabled(buttonIndex, enabled)
	local spellInfo = Spas:GetSpellByButtonIndex(buttonIndex);
	if spellInfo then
		spellInfo.Enabled = enabled;
		Spas:RefreshSpellConfigurationScreen();
		Spas:RefreshSpellButtons();
	end;
end;

function Spas_OnUIConfigIconSizeChanged(object)
	Spas:OnUIConfigIconSizeChanged(object);
end;

function Spas:OnUIConfigIconSizeChanged(object)
	local value = math.floor(object:GetValue());
	object:SetValueStep(1);
	object:SetValue(value);

	if not Spas.options then return; end;

	if value ~= Spas.options.spellFrame.IconSize then
		Spas.options.spellFrame.IconSize = value;
		Spas:RefreshSpellButtons();
	end;
	
	SpasUIConfigIconSizeCaption:SetText(string.format("Size: %d x %s pixels", value, value));
end;

function Spas_OnUIConfigIconPaddingChanged(object)
	Spas:OnUIConfigIconPaddingChanged(object);
end;

function Spas:OnUIConfigIconPaddingChanged(object)
	local value = math.floor(object:GetValue());
	object:SetValueStep(1);
	object:SetValue(value);

	if not Spas.options then return; end;

	if value ~= Spas.options.spellFrame.Spacing then
		Spas.options.spellFrame.Spacing = value;
		Spas:RefreshSpellButtons();
	end;
	
	SpasUIConfigIconPaddingCaption:SetText(string.format("Padding: %d pixels", value));
end;

function Spas_OnUIConfigIconsPerRowChanged(object)
	Spas:OnUIConfigIconsPerRowChanged(object);
end;

function Spas:OnUIConfigIconsPerRowChanged(object)
	local value = math.floor(object:GetValue());
	object:SetValueStep(1);
	object:SetValue(value);

	if not Spas.options then return; end;

	if value ~= Spas.options.spellFrame.IconsPerRow then
		Spas.options.spellFrame.IconsPerRow = value;
		Spas:RefreshSpellButtons();
	end;
	
--	BuffaloSliderPrayerThresholdText:SetText(string.format("%s/5 people", Buffalo.config.value.GroupBuffThreshold));
end;




--[[
	For all buttons for current character:
	Refresh spell target and spellIndex. Will hide and show spells as needed.
	To be called after roster updated or learning new spells.
--]]
function Spas:RefreshSpellButtons(debugDisplaySettings)
	local posX = 0;
	local posY = 0;

	if not Spas.options then return; end;

	--	spellFrame is nil while initializing
	if Spas.options.spellFrame then
		posX = Spas.options.spellFrame.Spacing;
		posY = -Spas.options.spellFrame.Spacing;
	end;

	local orgX = posX;
	local height = Spas.options.spellFrame.IconSize + 10 + 2*Spas.options.spellFrame.Spacing;
	local width = 16 + 4;

	Spas:InitializePossibleTargets();

	--	Assign and Enable buttons:
	local columnCount = 0;
	local columnMax = 0;
	for spellName, spellInfo in next, Spas.vars.sortedSpells do
		local button = nil;
		local buttonLabel = nil;

		button = Spas.vars.spellButtons[spellInfo.ButtonIndex];
		buttonLabel = _G[button:GetName() .. "_caption"];

		if spellInfo.Enabled == 1 then
			--	This update the UnitID; it may change when people are moved around the group.
			spellInfo.UnitID = Spas.lib:getUnitidFromName(spellInfo.FullName);

			--print(string.format("UnitID=%s, name=%s", (spellInfo.UnitID or "nil"), (spellInfo.FullName or "nil")));

			button:SetSize(Spas.options.spellFrame.IconSize, Spas.options.spellFrame.IconSize);
			button:SetPoint("TOPLEFT", posX, posY);

			button:SetNormalTexture(spellInfo.IconID);
			button:SetPushedTexture(spellInfo.IconID);
			button:SetAttribute("type", "spell");
			button:SetAttribute("spell", spellInfo.SpellName);
			button:SetAttribute("unit", spellInfo.UnitID);

			button:SetWidth(Spas.options.spellFrame.IconSize);
			button:SetHeight(Spas.options.spellFrame.IconSize);
			button:Show();

			Spas:ConfigureTargetSelection(spellInfo);

			--	buttonLabel holds name of assigned target (if any)
			local unitName = "";
			if spellInfo.UnitID ~= nil and spellInfo.UnitID ~= "player" then
				unitName = UnitName(spellInfo.UnitID);
			end;
			Spas:UpdateTargetName(buttonLabel, unitName);
			buttonLabel:Show();

			--	Catch errors runtime:
			if debugDisplaySettings == 1 then
				print(string.format("Updating buttons, Spell=%s, UnitID=%s (name=%s, full=%s)", spellInfo.SpellName, spellInfo.UnitID, UnitName(spellInfo.UnitID), spellInfo.FullName));
			end;

			columnCount = columnCount + 1;
			if columnCount >= Spas.options.spellFrame.IconsPerRow then
				columnCount = 0;
				posX = orgX;
				posY = posY - Spas.options.spellFrame.IconSize + Spas.options.spellFrame.Spacing;
			else
				posX = posX + Spas.options.spellFrame.IconSize + Spas.options.spellFrame.Spacing;
			end;

			if columnCount > columnMax then
				columnMax = columnCount;
			end;

		else
			button:Hide();
			buttonLabel:Hide();
		end;
	end;

	SpasButtonFrame:SetHeight(height + posY);
	SpasButtonFrame:SetWidth(width + columnMax * (Spas.options.spellFrame.IconSize + Spas.options.spellFrame.Spacing));
end;

--[[
	Pre-create all buttons+labels up to configured maximum.
	This is only to be one time: game initialization.
	Position is temporary; real positioning of (selected) buttons will happen later.
--]]
function Spas:CreateSpellButtons()
	Spas.vars.spellButtons = {};
	Spas.vars.spellLabels = {};
	Spas.vars.ConfigButtons = {};

	SpasButtonFrame:SetHeight(Spas.options.spellFrame.IconSize + Spas.options.spellFrame.Spacing + Spas.options.spellFrame.SpacingFooter)

	local index, buttonName;
	for index = 1, Spas.vars.maxSelectableSpells, 1 do
		buttonName = string.format("spas_spellbutton_%d", index);

		local button = CreateFrame("Button", buttonName, SpasButtonFrame, "SpasButtonTemplate");
		button:SetSize(Spas.options.spellFrame.IconSize, Spas.options.spellFrame.IconSize);
		button:SetPoint("TOPLEFT", 0, 0);
		button:SetNormalTexture(135894);
		button:SetScript("PreClick", Spas_OnBeforeSpellClick);
		button:SetScript("PostClick", Spas_OnAfterSpellClick);
		button:Hide();

		
		Spas.vars.spellButtons[index] = button;

		local buttonLabel = button:CreateFontString(string.format("%s_caption", buttonName), "OVERLAY", "GameTooltipText");
		buttonLabel:SetPoint("CENTER", 0, -20 );
		buttonLabel:SetFont("Fonts\\FRIZQT__.ttf", 8);
		buttonLabel:SetText("");
		buttonLabel:Hide();
		Spas.vars.spellLabels[index] = buttonLabel;

		local controlName = string.format("spas_triggercontrol_%d", index);
		local ruleConfig = CreateFrame("Frame", controlName, SpasConfigSpellFrame, "SpasRuleConfigTemplate");
		ruleConfig:SetPoint("TOPLEFT");
		ruleConfig:Hide();
		Spas.vars.configRules[index] = ruleConfig;

		local ruleCombo = _G[controlName .. "Trigger"];
		ruleCombo:SetupMenu(function(dropdown, rootDescription)
			rootDescription:CreateTitle("Active when:");

			local spellTriggerID, spellTrigger;
			for spellTriggerID, spellTrigger in next, Spas.config.spellTriggers do
				rootDescription:CreateButton(spellTrigger.Name, function() Spas:OnSpellTriggerSelect(index, spellTriggerID); end);
			end
		end);

	end;
end;


--[[
	Reload the spell table with spells known for the current character.
--]]
function Spas:LoadSpellTable()
	local _, className = UnitClass("player");

	Spas.vars.sortedSpells = {};

	local spells = Spas.spells[className];
	if not spells then
		--	This class does not support any of the configured spells.
		--	Hide addon is probably all we can do.
		SpasButtonFrame:Hide();
		return false;
	end;
	
	--	Now step through all spells and see which current character knows.
	--	Default assignment is the current player:
	local unitID = "player";
	local unitName = UnitName(unitID);
	local buttonIndex = 1;
	for spellName, spellInfo in next, spells do
		local foundName = GetSpellInfo(spellName);
		if foundName ~= nil then
			spellInfo["SpellName"] = spellName;
			spellInfo["FullName"] = Spas.lib:getPlayerAndRealm(unitID);
			spellInfo["UnitID"] = unitID;
			spellInfo["OnCooldown"] = 0;
			spellInfo["DisplayMask"] = 0;
			spellInfo["Enabled"] = spellInfo.Enabled;
			spellInfo["ButtonIndex"] = buttonIndex;
			tinsert(Spas.vars.sortedSpells, spellInfo);

			buttonIndex = buttonIndex + 1;
		end;
	end;

	table.sort(Spas.vars.sortedSpells, function (a, b) return a.SortOrder < b.SortOrder; end);

	return true;
end;

function Spas:InitializePossibleTargets()
	local unitId, unitName, unitRealm, unitClass;

	Spas.vars.selectableTargets = { };
	local playerName = UnitName("player");

	if IsInRaid() then
		for partyIndex = 1, 40, 1 do
			unitId = string.format("raid%d", partyIndex);
			unitName, unitRealm = UnitName(unitId);
			if unitName then
				_, unitClass = UnitClass(unitId);
				if unitClass then
					if unitRealm == "" then unitRealm = nil end;
					if not Spas.vars.selectableTargets[unitClass] then
						Spas.vars.selectableTargets[unitClass] = { };
					end;

					tinsert(Spas.vars.selectableTargets[unitClass], { ["UnitID"] = unitId, ["Name"] = unitName, ["Realm"] = unitRealm, ["Class"] = unitClass });
				end;
			end;
		end

	else
		unitId = "player";
		unitName, unitRealm = UnitName(unitId);
		Spas.vars.selectableTargets[Spas.vars.playerClass] = { }
		tinsert(Spas.vars.selectableTargets[Spas.vars.playerClass], { ["UnitID"] = unitId, ["Name"] = unitName, ["Realm"] = unitRealm, ["Class"] = Spas.vars.playerClass });

		for partyIndex = 1, 4, 1 do
			unitId = string.format("party%d", partyIndex);
			unitName, unitRealm = UnitName(unitId);
			if unitName then
				_, unitClass = UnitClass(unitId);
				if unitClass then	-- I experienced this to be nil?! How??
					if not Spas.vars.selectableTargets[unitClass] then
						Spas.vars.selectableTargets[unitClass] = { };
					end;
					tinsert(Spas.vars.selectableTargets[unitClass], { ["UnitID"] = unitId, ["Name"] = unitName, ["Realm"] = unitRealm, ["Class"] = unitClass });
				end;
			end;
		end
	end;

	--	Now sort the targets (unless Im all alone in the world!)
	for _, classTargets in next, Spas.vars.selectableTargets do
		if #classTargets > 1 then
			table.sort(classTargets, function (a, b) return a.Name < b.Name; end);			
		end;
	end;

	return targets;
end;

function Spas:ConfigureTargetSelection(spellInfo)
	local buttonIndex = spellInfo.ButtonIndex;
	local button = Spas.vars.spellButtons[buttonIndex];

	button:SetScript(
		"OnMouseUp",
		function(frame, button)
			if button == "RightButton" then
				local menuTitle = string.format("Assign |c80%s%s|r to:", Spas.ui.colourSelectedSpell, spellInfo.SpellName);
				local className, classInfo, targetName, targetInfo;
			
				MenuUtil.CreateContextMenu(UIParent, function(ownerRegion, rootDescription)
					rootDescription:CreateTitle(menuTitle);
				
					for className, classInfo in next, Spas.vars.selectableTargets do
						local classNameLower = Spas:UCFirst(className);
						local submenu = rootDescription:CreateButton(string.format("|T%s:16:16|t %s", Spas.ui.classes[className].IconFile, classNameLower));

						for targetName, targetInfo in next, classInfo do
							submenu:CreateButton(
								targetInfo.Name,
								function()
									frame:SetAttribute("unit", targetInfo.UnitID);

									Spas:UpdateTargetName(Spas.vars.spellLabels[buttonIndex], targetInfo.UnitID);

									spellInfo.FullName = Spas.lib:getPlayerAndRealm(targetInfo.UnitID);
									spellInfo.UnitID = targetInfo.UnitID;
									self:SaveSettings();
								end
							);
						end;
					end;

					rootDescription:CreateDivider();
					rootDescription:CreateButton(
						"Unassign", 
						function()
							frame:SetAttribute("unit", nil);
							Spas:UpdateTargetName(Spas.vars.spellLabels[buttonIndex], nil);
							spellInfo.FullName = "";
							spellInfo.UnitID = "player";
							self:SaveSettings();
						end
					);
					rootDescription:CreateButton(
						"Hide Spell", 
						function()
							Spas:SetSpellEnabled(buttonIndex, 0);
						end
					);
					rootDescription:CreateButton(
						"Cancel", 
						function() end
					);

				end);
			end
		end
	)
end;

function Spas:ConfigureConfigButton(configButton, spellInfo)
	configButton:SetScript(
		"OnMouseUp",
		function(frame, button)
			if button == "RightButton" then
				local menuTitle = string.format("Configure |c80%s%s|r :", Spas.ui.colourSelectedSpell, spellInfo.SpellName);
				local className, classInfo, targetName, targetInfo;
			
				MenuUtil.CreateContextMenu(UIParent, function(ownerRegion, rootDescription)
					rootDescription:CreateTitle(menuTitle);
				
--					for className, classInfo in next, Spas.vars.selectableTargets do
--						local classNameLower = Spas:UCFirst(className);
--						local submenu = rootDescription:CreateButton(string.format("|T%s:16:16|t %s", Spas.ui.classes[className].IconFile, classNameLower));
--						for targetName, targetInfo in next, classInfo do
--							submenu:CreateButton(
--								targetInfo.Name,
--								function()
--									frame:SetAttribute("unit", targetInfo.UnitID);
--									Spas:UpdateTargetName(Spas.vars.spellLabels[buttonIndex], targetInfo.UnitID);
--									spellInfo.FullName = Spas.lib:getPlayerAndRealm(targetInfo.UnitID);
--									spellInfo.UnitID = targetInfo.UnitID;
--								end
--							);
--						end;
--					end;

					rootDescription:CreateDivider();
					rootDescription:CreateButton(
						"Hide Spell", 
						function()
							Spas:SetSpellEnabled(spellInfo.ButtonIndex, 0);
						end
					);
					rootDescription:CreateButton(
						"Cancel", 
						function() end
					);

				end);
			end
		end
	)
end;


function Spas:UpdateTargetName(labelFrame, unitID)
	local labelText = "";
	local color = { ["r"] = 1, ["g"] = 1, ["b"] = 1 };

	if unitID then
		labelText = UnitName(unitID) or "";

		local _, unitClass = UnitClass(unitID);
		if unitClass then
			color = Spas.ui.classes[unitClass].Color;
		end;
	end;

	if #labelText > Spas.options.TargetNameLength then
		labelText = string.sub(labelText, 1, Spas.options.TargetNameLength);
	end;

	labelFrame:SetText(labelText);
	labelFrame:SetVertexColor(color.r/255, color.g/255, color.b/255);
end;

