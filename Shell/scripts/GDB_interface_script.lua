-- STAR WARS BATTLEFRONT II - REMASTER
-- Developer Documentation by Anakin

-- load all scripts needed for your custom gc match here
ScriptCB_DoFile("ifs_freeform_init_gdb")
ScriptCB_DoFile("ai_override")
ScriptCB_DoFile("multiteam_scripts")
ScriptCB_DoFile("ifs_freeform_start_gdb")
ScriptCB_DoFile("game_testscript")



----only override tables when we start the game, not just load this script
----otherwise it would change for all galactic conquests
----TODO load custom main function when a saved game is loaded, and reset tables when game exit
--gtw_custom_start = function()
--    ScriptCB_DoFile("gtw_main")
--                                  --function does not work just yet
--    --starts the game
--    ifs_freeform_start_gtw(this)
--end

-- some variables needed by the register function
local gcButtonTag = "debugGC"				-- the button tag needs to be unique
local gcButtonString = "Debug Galactic Conquest"		-- the name can be localized or hardcoded
local start_gc = ifs_freeform_start_gdb		-- This is the function that starts the gc match.

-- register the button
swbf2Remaster_registerCGCButton(gcButtonTag, gcButtonString, start_gc )