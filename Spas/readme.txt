
SpellAssignments (SPAS) v0.3.2
* Bumped client to 1.15.7


SpellAssignments (SPAS) v0.3.1
* Fixed LUA error in config.
* Bumped client to 1.15.6


SpellAssignments (SPAS) v0.3.0
* Removed dependency for Buffalo addon (!!)
* Bumped client to 1.15.5


SpellAssignments (SPAS) v0.2.1
* Fixed a bug which displayed Spas for classes not eligible.


SpellAssignments (SPAS) v0.2.0
* Added configuration of the UI.


SpellAssignments (SPAS) v0.1.10
* Current assigned targets are now saved.
* Added Blink option on Trigger: usefull when getting a Whisper.
* Now whispering target back if selected spell (PI!) is on Cooldown.


SpellAssignments (SPAS) v0.1.9
* Attempted to make config UI better. Work still in progress :)
* Fixed setting: settings are now stored per Class.




Missing:
* Remove cogwheel - replace with Rightclicking frame instead.

Done:
* UI: margins etc. in config screen.
	* UI:
		* Margin (0-8 pixels)
		* Size (16x16 ... 48x48?)
		* # of Rows (removed from UI again; bars look awfull)
	* Visibility config in UI.
* Functionality to evaluate activation rules (missing some rules but going ahead)
	* Polymorphed (replace with SPELLTRIGGER_DEBUFFACTIVE)
* Assigned players are not removed from spellInfo.UnitID; means unitId is still active.
* Possible bug: CD or Debuff not working in groups. Havent reproduced yet.
	* Happened because GetUnitidFromName did not take party into consideration. Using DigamAddonLib now.
* BUG: all configured debuff types changes - not only the one actually changed.
* Rules:
	* Collect debuffing into one configurable Have Debuff-rule
	* Whisper rules
	* mindcontrolled
	* SPELLTRIGGER_SPELLACTIVE, SPELLTRIGGER_SPELLINACTIVE
* GCD no longer triggers all spells to blank out.
* Visibility: Always in Raid+Groups, in Raids, (in PvP?), Never
* Screen position is now saved in settings.
* Framework for loading/saving (persisting) settings.
* Functionality to evaluate activation rules. Added Cooldown, Magic/Disease/Poison/Curse, LowHealth
* Cooldown version III? Now waiting for spell to actually go on CD.
* Feature: /spas version etc.
* UI:
	* Spells:
		* Enabled
			* Yes/No. If NO icon will not be shown at bar.
		* Visibility:
			* Always (really not)
			* When off cooldown
			* When target does not have buff <ID>
			* When target does have buff <ID>
			* When target have Magic/Curse/Poison/Disease
			* When target whispers me (contains "PI" / whatever)
		* Whispers:
			* Text to send to target (dropped for now)
* Add cast time to cooldown times; seems cooldown timer begins on casting start.
* Assignments still changing "randomly" (when groups are sorted). Need to fall back to unitname upon refresh.
	* Added spellInfo.FullName and will now check UnitID against the full name every time.
* Bug: RefreshSpellButtons() prints the full name of the player. Need to cut to <4> chars
* Add a heal or two
* UI: popup menu: order names alphabetically
* Support for cross realm buffing? Reload raid unitid's as well (should work for crossrealm)
* Bug: When a player is no longer in Roster, target should be cleared.
* Bug: Not sure why, but CD does not always reset. (CD refresh rewritten)
* Bug: UnitID was sometimes removed. (UnitID now saved on spellInfo).
* UI: class names should use UCFirst ("PRIEST" -> "Priest" etc.)
* UI: Added class icons to popup menu
* UI: Using UI constants for sizing but not configurable for the moment.
* UI: Added border and backdrop, removed Move icon since background is now movable.
* Removed Warlock, added Shaman
* Reload buffs when entering raid. Maybe a force reload option (at least command line option)



