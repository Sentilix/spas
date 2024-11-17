
Spas = select(2, ...)

Spas.vars.timerTick = 0;
Spas.vars.timerInterval = 0.3;
Spas.vars.blinkIntervalTarget = 0.4;		--	This is the desired blink interval. The real interval will be calculated below:

local blink = math.floor(0.5 + (Spas.vars.blinkIntervalTarget / Spas.vars.timerInterval), 0);
Spas.vars.blinkInterval = Spas.vars.timerInterval * blink;		--	This is the calculated Interval:

Spas.timers = {}
Spas.timers["SpellCooldownCheck"] = {
	["Timer"] = 0,
	["Interval"] = Spas.vars.timerInterval,
	["Task"] = function() Spas:SpellCooldownCheck() end,
}
Spas.timers["TargetBuffCheck"] = {
	["Timer"] = 0,
	["Interval"] = Spas.vars.timerInterval,
	["Task"] = function() Spas:TargetBuffCheck() end,
}
Spas.timers["SpellDebuffSchoolCheck"] = {
	["Timer"] = 0,
	["Interval"] = Spas.vars.timerInterval,
	["Task"] = function() Spas:OnSpellDebuffSchoolCheck() end,
}
Spas.timers["LowHealthCheck"] = {
	["Timer"] = 0,
	["Interval"] = Spas.vars.timerInterval,
	["Task"] = function() Spas:OnLowHealthCheck() end,
}
Spas.timers["WhisperCheck"] = {
	["Timer"] = 0,
	["Interval"] = Spas.vars.timerInterval,
	["Task"] = function() Spas:WhisperCheck() end,
	["TTL"] = 30,
}				
Spas.timers["ApplySpellTriggers"] = {
	["Timer"] = 0,
	["Interval"] = Spas.vars.timerInterval,
	["Task"] = function() Spas:OnApplySpellTriggers() end,
}
Spas.timers["Blink"] = {
	["Timer"] = 0,
	["Interval"] = Spas.vars.blinkInterval,
	["Task"] = function() Spas:Blink() end,
}


--[[
	Timer main entry:
	This delegate tasks to the sub timers:
--]]
function Spas:OnTimer(elapsed)
	Spas.vars.timerTick = Spas.vars.timerTick + elapsed;

	if not Spas.vars.AddonLoaded then
		return;
	end;

	for taskName, taskInfo in next, Spas.timers do
		if taskInfo.Timer < Spas.vars.timerTick then
			taskInfo.Timer = Spas.vars.timerTick + taskInfo.Interval;
			taskInfo:Task();
		end;
	end;
end;


--[[
	Task: CooldownCheck
	Check if any of the spells are currently on CD.
	A spell on CD is marked as spellInfo.OnCooldown=1.
--]]
function Spas:SpellCooldownCheck()
	for spellIndex, spellInfo in next, Spas.vars.sortedSpells do
		if spellInfo.Enabled == 1 then
			local oldCDValue = spellInfo.OnCooldown;
			local startTime, cooldownTime = GetSpellCooldown(spellInfo.SpellName, BOOKTYPE_SPELL);

			--	The 1.5 check prevents icons going blank during GCD: it is terribly annoying to see all icons blink!
			if (cooldownTime > 1.5) and (startTime > Spas.vars.timerTick) then
				spellInfo.OnCooldown = 1;
				spellInfo.DisplayMask = bit.bor(spellInfo.DisplayMask, Spas.SPELLTRIGGER_MASK_COOLDOWN);
			else
				spellInfo.OnCooldown = 0;
				spellInfo.DisplayMask = bit.band(spellInfo.DisplayMask, -1 - Spas.SPELLTRIGGER_MASK_COOLDOWN);
			end;
		end;
	end;
end;


--[[
	Task: TargetBuffCheck
	Check buffs on target. There are three rules using this check:
	* SPELLTRIGGER_NOTONTARGET		: Current spell is not on target
	* SPELLTRIGGER_SPELLACTIVE		: Target have one or more of spells in parameters
	* SPELLTRIGGER_SPELLNOTACTIVE	: Target are missing one or more of spells in parameters
--]]
function Spas:TargetBuffCheck()
	--	Cache buff results per Unit - no need to get results from same Unit multiple times!
	local buffCache = {};

	--	Identify buffs for all configured Units:
	local buffIndex, spellIndex, spellInfo;
	for spellIndex, spellInfo in next, Spas.vars.sortedSpells do
		if spellInfo.Enabled == 1 then		
			local buffOnTarget = 0;
			local spellOnTarget = 0;
			local spellNotOnTarget = 0;

			local unitID = spellInfo.UnitID;
			if unitID then
				--	Part 1: Cache the spell info:
				if not buffCache[unitID] then
					buffCache[unitID] = { };

					for buffIndex = 1, 32, 1 do
						local buffName, iconID, _, _, duration, expirationTime = UnitBuff(unitID, buffIndex, "CANCELABLE");
						if not buffName then break; end;

						--	Name: normal case, name: lower case :-)
						tinsert(buffCache[unitID], { ["Name"] = buffName, ["name"] = string.lower(buffName) } );
					end;			
				end;


				--	part 2: Check the rules:
				for buffIndex = 1, #buffCache[unitID], 1 do
					--	SPELLTRIGGER_NOTONTARGET
					if buffCache[unitID][buffIndex].Name == spellInfo.SpellName then
						buffOnTarget = 1;
					end;
				
					--	SPELLTRIGGER_SPELLACTIVE
					if bit.band(spellInfo.SpellTrigger.Mask, Spas.SPELLTRIGGER_MASK_SPELLACTIVE) > 0 then
						if spellInfo.ParamCompiled then
							for spellName, spellId in next, spellInfo.ParamCompiled do
								if buffCache[unitID][buffIndex].name == spellName then
									spellOnTarget = 1;
									break;
								end;
							end;
						end;
					end;
					--	SPELLTRIGGER_SPELLNOTACTIVE
					if bit.band(spellInfo.SpellTrigger.Mask, Spas.SPELLTRIGGER_MASK_SPELLNOTACTIVE) > 0 then
						if spellInfo.ParamCompiled then
							for spellName, spellId in next, spellInfo.ParamCompiled do
								if buffCache[unitID][buffIndex].name == spellName then
									--	1: one or more of the spells was fóund on target.
									spellNotOnTarget = 1;
									break;
								end;
							end;
						end;
					end;
				end;
			end;

			if buffOnTarget == 1 then
				spellInfo.DisplayMask = bit.bor(spellInfo.DisplayMask, Spas.SPELLTRIGGER_MASK_ALREADYEXISTS);
			else
				spellInfo.DisplayMask = bit.band(spellInfo.DisplayMask, -1 - Spas.SPELLTRIGGER_MASK_ALREADYEXISTS);
			end;

			if spellOnTarget == 1 then
				spellInfo.DisplayMask = bit.band(spellInfo.DisplayMask, -1 - Spas.SPELLTRIGGER_MASK_SPELLACTIVE);
			else
				spellInfo.DisplayMask = bit.bor(spellInfo.DisplayMask, Spas.SPELLTRIGGER_MASK_SPELLACTIVE);
			end;

			if spellNotOnTarget == 1 then
				spellInfo.DisplayMask = bit.bor(spellInfo.DisplayMask, Spas.SPELLTRIGGER_MASK_SPELLNOTACTIVE);
			else
				spellInfo.DisplayMask = bit.band(spellInfo.DisplayMask, -1 - Spas.SPELLTRIGGER_MASK_SPELLNOTACTIVE);
			end;

		end;
	end;
end;


function Spas:OnSpellDebuffSchoolCheck()
	--	Cache debuff results per Unit - no need to get results from same Unit multiple times!
	local debuffCache = {};

	local debuffMask = 0;
	local buffIndex, spellIndex, spellInfo;
	for spellIndex, spellInfo in next, Spas.vars.sortedSpells do
		if spellInfo.Enabled == 1 then		
			local unitID = spellInfo.UnitID or "player";
			if not debuffCache[unitID] then
				debuffCache[unitID] = { };

				for buffIndex = 1, 32, 1 do
					local debuffName, _, _, debuffType = UnitDebuff(unitID, buffIndex);

					if not debuffName then
						break; 
					end;

					--print(string.format("Debuff found, name=%s, type=%s", debuffName, (debuffType or "nil")));
					tinsert(debuffCache[unitID], { ["DebuffName"] = string.lower(debuffName), ["DebuffType"] = string.lower(debuffType or "unknown") } );
				end;
			end;

			--	Logic seems flawed, but ...
			--	We set a "1" bit if target does NOT have a debuff, since the SpellTrigger accepts "0" as no errors.
			debuffMask = 0x0000f0;	--	Set all debuff types as OFF:
			for _, cacheInfo in next, debuffCache[unitID] do
				local debuffInfo = Spas.config.debuffTypes[cacheInfo.DebuffType];
				if debuffInfo then
					--print(string.format("Found debuff of type=%s, spell=%s", cacheInfo.DebuffName, cacheInfo.SpellName));
					debuffMask = bit.band(debuffMask, -1 - debuffInfo.Mask);		-- clear school bit
				end;
			end;

			--	Mask old bits out (reset all debuff types):
			spellInfo.DisplayMask = bit.band(spellInfo.DisplayMask, 0x0ffff0f);
			--	And set new update debuff mask:
			spellInfo.DisplayMask = bit.bor(spellInfo.DisplayMask, debuffMask);


			--	Mindcontrol Check:
			local isMindcontrolled = false;
			if bit.band(spellInfo.SpellTrigger.Mask, Spas.SPELLTRIGGER_MASK_MINDCONTROLLED) > 0 then
				local spellNames = Spas:splitString(spellInfo.ParamDefaultInternal, ",");

				for n=1, #spellNames, 1 do
					for _, debuffInfo in next, debuffCache[unitID] do
						if spellNames[n] == debuffInfo.DebuffName then
							isMindcontrolled = 1;
							break;
						end;
					end;
				end;
			end;
			
			if isMindcontrolled == 1 then
				spellInfo.DisplayMask = bit.band(spellInfo.DisplayMask, -1 - Spas.SPELLTRIGGER_MASK_MINDCONTROLLED);
			else
				spellInfo.DisplayMask = bit.bor(spellInfo.DisplayMask, Spas.SPELLTRIGGER_MASK_MINDCONTROLLED);
			end;
		end;
	end;
end;

--[[
	LowHealth:
	Set the bit as long Target has at least 20% health:
--]]
function Spas:OnLowHealthCheck()
	local buffIndex, spellIndex, spellInfo;
	for spellIndex, spellInfo in next, Spas.vars.sortedSpells do
		if spellInfo.Enabled == 1 then
			local healthThreshold = tonumber(spellInfo.ActivationParams);
			if not healthThreshold then				
				local spell = Spas.spells[Spas.vars.playerClass];
				if spell ~= nil then
					local rule = spell[spellInfo.SpellName];
					if rule ~= nil then
						healthThreshold = tonumber(rule.ActivationParams);
					end;
				end;

				healthThreshold = healthThreshold or 25;		-- hard default: 25%
			end

			local isLowHealth = false;
			if spellInfo.UnitID then
				local health = UnitHealth(spellInfo.UnitID);
				local healthMax = UnitHealthMax(spellInfo.UnitID);
				if (health / healthMax * 100) < healthThreshold then
					isLowHealth = true;
				end;
			end;

			--	Less than X% health?
			if isLowHealth then
				spellInfo.DisplayMask = bit.band(spellInfo.DisplayMask, -1 - Spas.SPELLTRIGGER_MASK_LOWHEALTH);
			else
				spellInfo.DisplayMask = bit.bor(spellInfo.DisplayMask, Spas.SPELLTRIGGER_MASK_LOWHEALTH);
			end;

		end;
	end;
end;

function Spas:WhisperCheck()
	for spellIndex, spellInfo in next, Spas.vars.sortedSpells do
		if spellInfo.Enabled == 1 then
			local triggered = false;
			if bit.band(spellInfo.SpellTrigger.Mask, Spas.SPELLTRIGGER_MASK_WHISPER) > 0 then
				--	Do we have a whisper, and if yes, from our configured target?
				if spellInfo.WhisperFullName then
					if spellInfo.FullName == spellInfo.WhisperFullName then
						--	We do. Does it contain the configured message?
						if spellInfo.WhisperMessage and spellInfo.ParamValue then
							local incoming = string.lower(spellInfo.WhisperMessage);
							local config = string.lower(spellInfo.ParamValue);
							if string.find(incoming, config) then
								triggered = true;

								--	Whisper target back if cooldown left is longer than 5 seconds:
								local startTime, cooldownTime = GetSpellCooldown(spellInfo.SpellName, BOOKTYPE_SPELL);
								local endTime = startTime - Spas.vars.BootTime + cooldownTime;
								local timeLeft = endTime - Spas.vars.timerTick;
								if timeLeft > 5 and spellInfo.FullName ~= "" then
									Spas.lib:sendWhisper(spellInfo.FullName, string.format("-[SPAS]- Sorry, %s is still on cooldown for another %d seconds.", spellInfo.SpellName, timeLeft));
								end;

								spellInfo.WhisperTimestamp = Spas.vars.timerTick;
								spellInfo.WhisperFullName = nil;
								spellInfo.WhisperMessage = nil;
							end;
						end; 
					end;
				end;
			end;

			--	Reset whisper:
			if spellInfo.WhisperTimestamp then
				if (spellInfo.WhisperTimestamp + Spas.timers.WhisperCheck.TTL) > Spas.vars.timerTick then
					triggered = true;
				else
					spellInfo.WhisperTimestamp = nil;
				end;
			end;

			if triggered then
				spellInfo.DisplayMask = bit.band(spellInfo.DisplayMask, -1 - Spas.SPELLTRIGGER_MASK_WHISPER);
			else
				spellInfo.DisplayMask = bit.bor(spellInfo.DisplayMask, Spas.SPELLTRIGGER_MASK_WHISPER);
			end;

			--	When should we reset this? When casted (ofc) .. but also after - say - 30 seconds?
		end;
	end;
end;

				
--[[
	This checks the result of all tasks and hide/show spell icons accordingly.
--]]
function Spas:OnApplySpellTriggers()
	local buffIndex, spellIndex, spellInfo;
	for spellIndex, spellInfo in next, Spas.vars.sortedSpells do
		if spellInfo.Enabled == 1 then

			local button = Spas.vars.spellButtons[spellInfo.ButtonIndex];
			local ruleMask = spellInfo.SpellTrigger.Mask or 0;

			--	Special handling for the SPELLTRIGGER_DEBUFF_TYPE rule:
			if spellInfo.SpellTrigger.ID == SPELLTRIGGER_DEBUFF_TYPE then
				--	If any of the bits (debuffs) are up we will have to set ALL configured debug flags, not only the active one:
				local paramValueInternal = tonumber(spellInfo.ParamCompiled) or 0;
				if bit.band(spellInfo.DisplayMask, 0x00f0) < bit.band(paramValueInternal, 0x00f0) then
					ruleMask = bit.band(ruleMask, -1 - paramValueInternal);
				else
					ruleMask = bit.bor(ruleMask, paramValueInternal);
				end;
			end;

			if bit.band(ruleMask, spellInfo.DisplayMask) > 0 then
				button:SetAlpha(Spas.ui.coolDownAlpha);
			else
				if spellInfo.SpellTrigger.Blinkable then
					button:SetAlpha(Spas.ui.blinkAlpha);
				else
					button:SetAlpha(1.0);
				end;
			end;
		end;
	end;
end;

--[[
	Toggle Blink colour
--]]
function Spas:Blink()
	if Spas.ui.blinkAlpha == Spas.ui.blinkAlphaOn then
		Spas.ui.blinkAlpha = Spas.ui.blinkAlphaOff;
	else
		Spas.ui.blinkAlpha = Spas.ui.blinkAlphaOn;
	end;		
end;


--[[
	Called when we get an incoming whisper:
--]]
function Spas:UpdateWhisperRules(fullName, message)
	local buffIndex, spellIndex, spellInfo;
	for spellIndex, spellInfo in next, Spas.vars.sortedSpells do
		if spellInfo.Enabled == 1 then
			if bit.band(spellInfo.SpellTrigger.Mask, Spas.SPELLTRIGGER_MASK_WHISPER) > 0 then
				--	Found a rule requiring a Whisper. Apply whisper data:
				spellInfo.WhisperFullName = fullName;
				spellInfo.WhisperMessage = message;				
			end;
		end
	end;
end;
