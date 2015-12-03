


---

# Introduction #

TranScripter is a program to script precise sequences of commands in emulators that have input recording functionality but lack Lua support. It works by writing the scripted inputs directly into the input recording file.

Currently it works with:
|emulator|version|movie format|
|:-------|:------|:-----------|
|[yabause-rr](http://code.google.com/p/yabause-rr/)|2541   |ymv         |
|[mednafen-rr](http://code.google.com/p/mednafen-rr/)|1.1    |mcm         |

For emulators with Lua, use [MacroLua](MacroLuaDocumentation.md) instead.

TranScripter was created with [AutoIt3](http://www.autoitscript.com/autoit3/index.shtml).


---

# Getting started with mednafen-rr #

Mednafen can be hard to use.

  * Command line help
  * Hotkey help
  * How to make an AVI

Hotkeys referenced below are the defaults and can be changed.

  * To configure controls all at once press **alt+shift+1** in game.
  * To remap a hotkey press **alt+shift+h** in game, then press the key to be changed.
  * Any setting can be changed by editing _mednafen.cfg_.
  * Refer to this key map if manually editing keys in _mednafen.cfg_.
  * If the keyboard becomes unresponsive in game try pressing **alt**.
  * Savestates saved during a movie cannot be loaded out of the movie and vice versa. Attempting this sometimes causes crash.

For launching the program, it's recommended to start out with the frontend, Mednafen-Front. If using the command line, you can copy valid commands from the CommandLine bar in Mednafen-Front. The `-loadstate`, `-mov`, and other options must come before the ROM name. The ROM must always be last.

## Example launch commands ##

Just load a ROM:

`mednafen ROMs\myrom.zip`

Double the screen size for NeoGeo Pocket:

`mednafen -ngp.xscale 2 -ngp.yscale 2 ROMs\myrom.zip`

Load a ROM and a savestate:

`mednafen -loadstate mcs\myrom.nc0 ROMs\myrom.zip`

Record a movie:

`mednafen -mov mcm\mymovie.mcm -record 1 ROMs\myrom.zip`

Play a movie and fast-forward with a savestate:

`mednafen -mov mcm\mymovie.mcm -play 1 -loadstate mcs\myrom.nc0 ROMs\myrom.zip`

Play a movie and record 2000 frames to an mmm file:

`mednafen -mov mcm\mymovie.mcm -play 1 -mmm 1 -mmmfile mcm\dump.mmm -mmmframes 2000 ROMs\myrom.zip`


---

# How to use TranScripter #

  1. Launch your game, deactivate read-only mode (**shift+t**) and start recording a movie (**ctrl+shift+r**) up to the point where you want the script to start. Save a state (**shift+F1**).
  1. Stop recording (**ctrl+shift+r**) so that the mcm will be properly formatted.
  1. Compose the _.mis_ script file. See below for the format.
  1. Edit _TranScripter.ini_ and designate the movie file and script file, and specify the movie frame that the script should start at. This start frame must be less than the frame length of the movie file, and must come before the savestate that will be used to fast-forward to the action.
  1. Run TranScripter. If there are no errors or warnings, there will be no feedback and the process was successful. Otherwise a box will pop up with any errors or warnings.
  1. Restart movie playback (**shift+p**), load the state (**F1**), and observe the result.
  1. Edit the _.mis_ file with any changes and repeat the last two steps until the desired results are achieved.


---

# Writing scripts #

The basic format is the same as [AutoMacro](AutoMacroDocumentation.md). There's no Lua, so savestate operations cannot be scripted.

The symbols for each system's keys are shown below:

## yabause-rr: ##
### Saturn ###
|U|up|
|:|:-|
|D|down|
|L|left|
|R|right|
|1|X |
|2|Y |
|3|Z |
|4|A |
|5|B |
|6|C |
|7|L |
|8|R |
|S|start|


## mednafen-rr: ##
### NeoGeo Pocket ###
|`U`|up|
|:--|:-|
|`D`|down|
|`L`|left|
|`R`|right|
|`1`|A |
|`2`|B |
|`O`|option|


### Wonderswan ###
|`U`|X up|
|:--|:---|
|`D`|X down|
|`L`|X left|
|`R`|X right|
|`8`|Y up|
|`5`|Y down|
|`4`|Y left|
|`6`|Y right|
|`1`|A   |
|`2`|B   |
|`S`|start|


### PC Engine ###
|`U`|up|
|:--|:-|
|`D`|down|
|`L`|left|
|`R`|right|
|`1`|IV|
|`2`|V |
|`3`|VI|
|`4`|III|
|`5`|II|
|`6`|I |
|`@`|run|
|`S`|select|
|`M`|mode|


### Lynx ###
|`U`|up|
|:--|:-|
|`D`|down|
|`L`|left|
|`R`|right|
|`1`|A |
|`2`|B |
|`3`|option 1|
|`4`|option 2|
|`S`|start|


### NES ###
|`U`|up|
|:--|:-|
|`D`|down|
|`L`|left|
|`R`|right|
|`1`|A |
|`2`|B |
|`@`|select|
|`S`|start|

The Windows version of mednafen-rr won't run games for:

  * Game Boy, Game Boy Advance, Sega Master System, Game Gear, PC-FX.