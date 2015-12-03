


---

# Introduction #

The purpose of this Lua script is to play back and record sequences of button presses in a compact format that is easily readable and editable. Some applications:

  * an alternative to using serialized rerecords for recording input, which can be easier with multiple players
  * a functional, parseable markup that doubles as a shorthand transcript notation, good for fighting game combo videos
  * a converter that can change an input sequence from a cryptic format such as [FBM](http://code.google.com/p/fbarr/wiki/FBMfileformat) to a human readable one for further editing
  * a converter that can change an input sequence from one emulator to another

MacroLua is portable to any emulator equipped with the core EmuLua functions. It can still work in a limited capacity if some of the functions are missing.


---

# A word on MAME-rr #

The current version of [MAME-rr](http://code.google.com/p/mame-rr/downloads/list) (0139-test2) has some oddities with the savestate system and the first few scripted frames get merged together. To avoid problems:

  * Start playing scripts with the emulator in an unpaused state. Starting from pause will be off by one frame.
  * Leave at least a few blank frames at the start.
  * If scripting a save, leave a few blank frames after the last input.
  * Don't try to load states if using recording mode. Recording is not bulletproof.


---

# How to use macros #

Download and set up one of the supported emulators. Choose the latest available version.

Extract the macro archive contents into the emulator's folder. Open _macro-options.lua_  with a text editor and ensure that the macrofile to be played and the path settings are correct. The default path looks for the macros in a folder called _./macro_.

Run the emulator and open the game. Find _Lua Scripting_ in the menus (Ctrl+L in MAME-rr) and open a script window. Browse for _macro.lua_ and run it. If there's a gamekey definition module available for your game, it is identified in the output console. In the case of arcade emus, the _input-display.lua_ script is run alongside the macro script.

## How to play back ##

Get to the desired point in the game and press the start key (semicolon, or whatever is bound to Lua hotkey 1) to start playback. The macro specified will be analyzed, and warnings appear in the output console if it is misformatted. The scripted sequence will proceed as the game runs normally or in frame advance.

You may replay the macro repeatedly. You may cut the playback short by pressing the start key again before playback is complete. You may also edit the macro file and play the new macro without reloading the script.

## How to record ##

Get to the desired point in the game and press the record key (quote, or Lua hotkey 2) to start recording. Any keys input by the player(s), by keypress recordings such as FBM, or even by a playing macro will be recorded. You can use frame advance for more precision. Savestate operations and analog controls are not recorded. Pressing the record key again stops and writes the recording to a _.mis_ file named after the date and time. If multiple players were recorded, the macro is output in asynchronous (bracket) format.

## Key bindings ##

If the emulator supports `input.registerhotkey()`, the keys to start and stop macros are Lua hotkeys 1 and 2 rather than semicolon and quote. These keys can be bound in the emulator's hotkey configuration.

## Savestates ##

Some emulators allow the progress of any macros being played or recorded to be saved alongside the savestate. Loading this savestate also restores the progress and the playing/recording status. If this is not supported, loading a savestate during a macro will cause a desync.

Even if those functions aren't available, savestate operations may always be written into the script, and scripts should start with a savestate to ensure consistent playback.


---

# How to read and write macros #

You may produce macros by recording them or by writing them out according to the format below.

In the following commands, `n` represents a number and `k` represents a key (direction, button or switch) defined by the game's module.
|**`k`**|Input the gamekey k. The key is pressed for the current frame only and then released.|
|:------|:------------------------------------------------------------------------------------|
|**`_k`**|Hold the gamekey k. The key is pressed for the current frame and any subsequent frames until released.|
|**`^k`**|Release the gamekey k, if held.                                                      |
|**`*`**|Release all held keys.                                                               |
|**`k[n]`**|Set the analog control `k` to the (decimal) value `n` for one frame.                 |
|**`k[-nh]`**|You may use a minus sign to set the an analog to a negative number, and `h` to signify a hexadecimal number.|
|**`_k[n]`**|Hold an analog control at the value `n`. You may change the held value by entering another hold. There's no need to release first.|
|**`^k[n]`**|When releasing an analog control, it makes no difference if there is a `^` or not. Either way the value is set for one frame and then the control is released. Use `*` or a value of 0 for immediate release.|
|**`F`**|Input `R` for player 1 or odd numbered players, or `L` for player 2 or even numbered players.|
|**`B`**|Input `L` for player 1 or odd numbered players, or `R` for player 2 or even numbered players.|
|`F` and `B` only get substituted if the module is using `L` and `R` and not already using `F` or `B`.| |
|**`.`**|Advance one frame.                                                                   |
|**`Wn`**|Advance (wait) n frames.                                                             |
|**`Wn?`**|Incremental wait mode: If a wait command is followed by a `?`, the macro will loop back to the beginning when it reaches the end and repeat indefinitely, both the savestates and the inputs. Stop by pressing the playback key again.<br><br>After each iteration, the value of <code>n</code> increases by one, and the value is displayed on screen. This is a more efficient way of finding the optimal wait period for a setup. There can be no more than one incremental wait in a script. If incremental wait is used, standard loop mode is disabled.<br>
<tr><td><b><code>+</code></b></td><td>Select player 1.                                                                     </td></tr>
<tr><td><b><code>-</code></b></td><td>Select the next player.                                                              </td></tr>
<tr><td><b><code>&lt;</code></b></td><td>Open a bracketed section and switch control to player 1.                             </td></tr>
<tr><td><b><code>/</code></b></td><td>Switch to the next player in a bracketed section.                                    </td></tr>
<tr><td><b><code>&gt;</code></b></td><td>Close a bracketed section.                                                           </td></tr>
<tr><td><b><code>$n</code></b></td><td>Save the current state to slot n.<br>This can save checkpoints in a long sequence of commands.</td></tr>
<tr><td><b><code>&amp;n</code></b></td><td>Load savestate slot n. This is useful to put in the first frame.                     </td></tr>
<tr><td><b><code>()n</code></b></td><td>Repeat the commands enclosed in the parentheses n times. Loops can be nested.        </td></tr>
<tr><td><b><code>#text</code></b></td><td>A comment. The rest of the line after the symbol is ignored by the parser.<br>Comments should explain the setup and goal of the macro.</td></tr>
<tr><td><b><code>!</code></b></td><td>End the macro. Any content after the end is ignored by the parser, and can be used as comments.<br>Don't forget to advance at least one frame after the last input and before the end.</td></tr>
<tr><td><b><code>???</code></b></td><td>If a script has three consecutive <code>?</code> symbols in an uncommented area, MacroLua converts it to the expanded one-line-per-frame format. Analog control values are given as hexadecimal numbers. The conversion occurs instead of playback and is activated by the playback key. The result is saved as a text file. This feature can help in analyzing and debugging scripts.</td></tr></tbody></table>

Macros are case insensitive. Commas, whitespaces, tabs and newlines can be used for spacing and legibility, but are ignored by the script. The exception is that some separation is required between multiplier or index numbers (such as after a <code>W</code>) and numerical key presses.<br>
<br>
<h3>Synchronous multi-player control with + -</h3>

<ul><li>Commands are applied only to the selected player.<br>
</li><li>Player 1 is selected by default.<br>
</li><li>The + and - symbols are used to switch between players.<br>
</li><li>Time advancement applies to all players.<br>
</li><li>Nonselected players can give input with their held keys.<br>
</li><li>To modify the input of multiple players on the same frame, switch between them before advancing frames.</li></ul>

<h3>Asynchronous multi-player control with < / ></h3>

<ul><li>Commands are applied only to the selected player.<br>
</li><li>Player 1 is selected when the brackets are opened.<br>
</li><li>Control is switched to the next player after each /.<br>
</li><li>Time advancement applies only to the selected player.<br>
</li><li>When the brackets are closed, time is advanced to the point of the player with the most frames, wait frames are added to the others to make up the difference, all player inputs are multiplexed, and control returns to player 1.<br>
</li><li>The + - symbols are ignored inside brackets.</li></ul>

<h3>Savestates</h3>

Save and load operations are performed one frame before the game inputs at the same position. For example, a state operation placed between the second and third dots is done after the second frame advance, while the game inputs there are done after the third. This behavior allows operations to be scripted on the zeroth frame of the macro, resulting in a movie that effectively starts from savestate.<br>
<br>
Each emulator has its own limit on savestate indexes.<br>
<br>
<hr />
<h1>Control modules</h1>

The game inputs and the symbols used to activate them depend on game system. MacroLua selects the symbol-input mapping based on what emulator is running it, and in the case of arcade, based on the game being run. The traditional format is <code>U</code>,<code>D</code>,<code>L</code>,<code>R</code> for up, down, left and right, and numbers counting up from <code>1</code> for the buttons. Symbols should be a single character for digital controls, but analog symbols can have multiple characters.<br>
<br>
Avoid using the reserved characters in symbols: <b><code>. W w _ ^ * + - &lt; / &gt; ( ) [ ] $ &amp; # ! ?</code></b>

The available sets are written in <i>macro-modules.lua</i>, and more can be added. Ask for help if needed. The non-arcade systems have a single keyset for all games, so the format only needs to be defined once for each console. However, there are many undefined arcade profiles. MacroLua tries to autogenerate an arcade module if none is available by observing what keys are present in the game. This should work well with games that use an ordinary joystick and numbered buttons.<br>
<br>
<hr />
<h1>Configuration options</h1>

The <i>macro-options.lua</i> file contains the user's settings. This file can be edited with any text editor. To update settings, restart the Lua script.<br>
<br>
<table><thead><th>The file, path and key options must be enclosed in quotes.<br>The hotkey options are ignored if the emulator supports Lua hotkeys.</th><th> </th></thead><tbody>
<tr><td><code>playbackfile</code>                                                                                                         </td><td>This is the filename of the script to be played.</td></tr>
<tr><td><code>path</code>                                                                                                                 </td><td>This is the path where the script file is found and where recordings will be placed. The path may be either relative to macro.lua or absolute. Use either double forward slashes (<code>.\\path\\</code>) or single backslashes (<code>./path/</code>).</td></tr>
<tr><td><code>playkey</code>                                                                                                              </td><td>Press to start playing the specified script or to cancel an already playing script.</td></tr>
<tr><td><code>recordkey</code>                                                                                                            </td><td>Press to start recording input to a new script and to finish a recording in progress.</td></tr>
<tr><td><code>togglepausekey</code>                                                                                                       </td><td>When a script finishes, the game can be paused automatically. Press this to turn autopause on or off. There is a pause between each repetition in standard loop mode or incremental wait mode.</td></tr>
<tr><td><code>toggleloopkey</code>                                                                                                        </td><td>If loop mode is active, the macro will loop back to the beginning when it reaches the end and repeat indefinitely, both the savestates and the inputs. Stop by pressing the playback key again.<br><br>This is useful if you want to make successive changes to a script without having to enter the play command each time. If the emulator supports lua+user input, this can also be used for practicing against a scripted attack from the other player.<br><br>If incremental wait mode is active, this key instead cycles between increasing, decreasing, or preserving the delay.</td></tr>
<tr><td>After recording player input, the results are written to file. The following three options affect the style of the output:        </td><td> </td></tr>
<tr><td><code>longwait</code>                                                                                                             </td><td>Idle frames are collapsed into <code>Wn</code> phrases as a shorthand. This option specifies the minimum number of idle frames to trigger this. Set it to 0 to never use <code>Wn</code> phrases.</td></tr>
<tr><td><code>longpress</code>                                                                                                            </td><td>When an input is active for many consecutive frames, it is abbreviated as a <code>_k</code> at the beginning and a corresponding <code>^k</code> at the end instead of writing <code>k</code> every frame. This option specifies the minimum number of held frames to trigger this. Set it to 0 to never use <code>_k ^k</code> phrases.</td></tr>
<tr><td><code>longline</code>                                                                                                             </td><td>Each player's input can be broken up into multiple lines. This option specifies the minimum number of characters to trigger a linebreak. Set it to 0 to not break up lines.</td></tr>
<tr><td><code>framemame</code>                                                                                                            </td><td>Set to <code>true</code> only if running a script that was made for frameMAME, so that the parser can ignore the audio commands. Otherwise leave as <code>false</code>. This only applies to FBA-rr and MAME-rr.</td></tr></tbody></table>

If the emulator doesn't use Lua hotkeys, you must define hotkeys manually. They must be selected from the following list.<br>
<b>Key names are case sensitive.</b>

<code>shift, control, alt, capslock, numlock, scrolllock, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16, F17, F18, F19, F20, F21, F22, F23, F24, backspace, tab, enter, pause, escape, space, pageup, pagedown, end, home, insert, delete, left, up, right, down, numpad0, numpad1, numpad2, numpad3, numpad4, numpad5, numpad6, numpad7, numpad8, numpad9, numpad*, numpad+, numpad-, numpad., numpad/, tilde, plus, minus, leftbracket, rightbracket, semicolon, quote, comma, period, slash, backslash</code>

<hr />
<h1>Special playback modes</h1>
Here is a review of MacroLua's special modes:<br>
<table><thead><th> <b>mode</b> </th><th> <b>activated by</b> </th><th> <b>function</b> </th></thead><tbody>
<tr><td>text dump mode</td><td><code>???</code> written in the script</td><td>Output the script to an expanded frame-by-frame form that may be easier to read.<br>(No playback.)</td></tr>
<tr><td>incremental wait mode</td><td><code>Wn?</code> written in the script</td><td>Loop and automatically adjust the wait period after each iteration.<br>(Macro file is not reread between loops.)</td></tr>
<tr><td>standard loop mode</td><td>press the toggle loop key</td><td>Loop and automatically reread the macro file after each iteration.</td></tr></tbody></table>

<hr />
<h1>How to mute the background music in arcade games</h1>

You may want to record videos with the sound effects but without the music. The reliable method to disable music is with a cheat code: The memory addresses that control music are forced to hold values that prevent it from playing.<br>
<br>
For FBA-rr, find the code that works for your game in the <i>./FBA examples/mutecodes.txt</i> file provided. Copy the code into an .ini file that matches the rom's short name and put it in FBA's cheat folder (e.g. <i>./support/cheats/sfa3.ini</i>). You may augment this file with other codes as well. Then run the rom (restart if already running) and find Enable Cheats in the Misc menu. If the .ini is properly formatted, the option is available. Click the music entry and select the disable option from the dropbox.<br>
<br>
The available FBA mute codes have been converted to MAME xml format and are found in the official cheat code pack. Place <i>cheat.zip</i> in MAME-rr's folder to make the codes available. Access the cheats from the in-game menu in MAME.<br>
<br>
Not all games have known mute codes. You can request more at <a href='http://cheat.retrogames.com/'>Pugsy's site</a>.<br>
<br>
<hr />
<h1>Lua feature availability in each emulator</h1>

<table><thead><th>emulator</th><th>version tested</th><th><code>emu</code> alias</th><th>hotkey while paused</th><th>lua+user input</th><th>bulletproof savestates</th><th>adapt to ROMs</th><th>analog scripting</th></thead><tbody>
<tr><td><a href='http://code.google.com/p/mame-rr/downloads/list'>MAME-rr</a></td><td><code>0139-test2</code></td><td><code>mame</code>     </td><td>○                  </td><td>○             </td><td>×                     </td><td>○            </td><td>×               </td></tr>
<tr><td><a href='http://code.google.com/p/fbarr/downloads/list'>FBA-rr</a></td><td><code>0.0.5a</code></td><td><code>fba</code>      </td><td>○                  </td><td>○             </td><td>○                     </td><td>○            </td><td>○               </td></tr>
<tr><td><a href='http://code.google.com/p/pcsxrr/downloads/list'>PCSX-rr</a></td><td><code>0.1.3b</code></td><td><code>pcsx</code>     </td><td>○                  </td><td>○             </td><td>×                     </td><td>×            </td><td>×               </td></tr>
<tr><td><a href='http://code.google.com/p/psxjin/downloads/list'>psxjin</a></td><td><code>2.0 svn619</code></td><td><code>psxjin</code>   </td><td>×                  </td><td>○             </td><td>×                     </td><td>×            </td><td>×               </td></tr>
<tr><td><a href='http://code.google.com/p/gens-rerecording/downloads/list'>Gens-rr</a></td><td><code>svn296</code></td><td><code>gens</code>     </td><td>○                  </td><td>○             </td><td>○                     </td><td>×            </td><td>n/a             </td></tr>
<tr><td><a href='http://code.google.com/p/snes9x-rr/downloads/list'>snes9x-rr</a></td><td><code>1.43 svn146</code></td><td><code>snes9x</code>   </td><td>×                  </td><td>○             </td><td>○                     </td><td>×            </td><td>n/a             </td></tr>
<tr><td>        </td><td><code>1.51 svn147</code><sup>1</sup></td><td><code>snes9x</code>   </td><td>×                  </td><td>○             </td><td>○                     </td><td>×            </td><td>n/a             </td></tr>
<tr><td>        </td><td><code>1.52 r185</code><sup>2</sup></td><td>×                     </td><td>○                  </td><td>×             </td><td>×                     </td><td>×            </td><td>n/a             </td></tr>
<tr><td><a href='http://code.google.com/p/vba-rerecording/downloads/list'>VBA-rr</a></td><td><a href='http://code.google.com/p/vba-rerecording/downloads/detail?name=vba-rerecording-svn225-win32.zip'>svn225</a></td><td><code>vba</code>      </td><td>×                  </td><td>○             </td><td>×                     </td><td>×            </td><td>n/a             </td></tr>
<tr><td>        </td><td><code>23.4a</code><sup>3</sup></td><td><code>vba</code>      </td><td>×                  </td><td>○             </td><td>×                     </td><td>×            </td><td>n/a             </td></tr>
<tr><td><a href='http://www.fceux.com/web/download.html'>FCEUX</a></td><td><code>2.1.3</code></td><td><code>FCEU</code>     </td><td>○                  </td><td>○             </td><td>○                     </td><td>×            </td><td>n/a             </td></tr>
<tr><td><a href='http://code.google.com/p/pcejin/downloads/list'>PCEjin</a></td><td><code>SVN177</code><sup>4</sup></td><td>×                     </td><td>○                  </td><td>○             </td><td>○                     </td><td>×            </td><td>n/a             </td></tr>
<tr><td><a href='http://desmume.org/'>DeSmuMe</a></td><td><code>0.9.6</code></td><td>not yet tested        </td><td> </td><td> </td><td> </td><td> </td><td> </td></tr>
<tr><td><a href='http://code.google.com/p/mednafen-rr/'>mednafen-rr</a></td><td><code>1.1</code></td><td>use <a href='TranScripterDocumentation.md'>TranScripter</a></td><td> </td><td> </td><td> </td><td> </td><td> </td></tr>
<tr><td><a href='http://code.google.com/p/yabause-rr/'>yabause-rr</a></td><td><code>svn2541</code></td><td>use <a href='TranScripterDocumentation.md'>TranScripter</a></td><td> </td><td> </td><td> </td><td> </td><td> </td></tr>
<tr><td><a href='http://code.google.com/p/mupen64-rr/'>mupen64-rr</a></td><td><code>v8</code></td><td>does not support Lua  </td><td> </td><td> </td><td> </td><td> </td><td> </td></tr></tbody></table>

<ul><li><code>[1]</code> snes9x 1.51 <code>svn147</code> only accepts Lua input from within a <code>while true do</code> loop, so playback won't work.<br>
</li><li><code>[2]</code> snes9x 1.52 <code>r185</code> lacks an <code>emu</code> alias, <code>savestate.save</code>, <code>savestate.load</code> and the entire <code>joypad</code> library.<br>
</li><li><code>[3]</code> VBA versions after <code>svn225</code> only accept Lua input from within a <code>while true do</code> loop and won't work.<br>
</li><li><code>[4]</code> PCEjin may only need an <code>emu</code> alias to work.</li></ul>

<table><thead><th><code>emu</code> alias</th><th>MacroLua identifies the emulator and control scheme by the name of this table of functions.</th></thead><tbody>
<tr><td>hotkey while paused   </td><td>If <code>input.registerhotkey()</code> is available, the user can start and stop recording during pause. The fallback is <code>input.get()</code>, which has the same function but cannot be done while paused.<br><br>However, it's possible to use <code>input.get()</code> while paused in FBA, PCSX and FCEUX, due to a defect in the Lua implementation. In these cases the hotkeys will activate even if the emulator is not in focus.</td></tr>
<tr><td>lua+user input        </td><td>The emulator may take input from both a Lua script and the user simultaneously if <code>joypad.set()</code> allows it.</td></tr>
<tr><td>bulletproof savestates</td><td>The user may load savestates while playing or recording without losing progress if <code>savestate.registersave()</code> and <code>savestate.registerload()</code> are available. MAME-rr has other problems with savestates.<br><br>This feature has not been well tested.</td></tr>
<tr><td>adapt to ROMs         </td><td>MacroLua can name recordings and reset the control scheme based on the loaded game if <code>emu.registerstart()</code> and a function that returns the name of the game are present.</td></tr>
<tr><td>analog scripting      </td><td>If the emulator's system has analog controls and the emu handles them properly with <code>joypad.set()</code>, MacroLua can script analog inputs.</td></tr>