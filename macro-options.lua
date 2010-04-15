--[[
This file is intended to be run by macro.lua
See macro-readme.html for help and instructions.

You may adjust these parameters.
]]--

playbackfile   = "sf2ce-1-maj.mis" --name of the macro to be played
path           = ".\\macro\\" --where the macro scripts are stored
playkey        = "semicolon" --press to start playing the macro, or to cancel a playing macro
recordkey      = "quote" --press to start and stop recording a macro
pauseafterplay = true --pause after a macro completes
longwait       = 4 --Minimum wait frames to be collapsed into Ws when recording
longpress      = 10 --Minimum continuous keypress frames to be collapsed into holds when recording
longline       = 60 --Minimum characters in a line to be broken up when recording
showfbainput   = true --run FBA-rr's input display script
