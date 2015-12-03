


---

# Introduction #

AutoMacro is a program to script and execute precise sequences of commands in PC games. It was created with [AutoIt3](http://www.autoitscript.com/autoit3/index.shtml).

This program requires the following things of your game or emulator to work:

  * It must be running on your PC.
  * It must be running at full speed or at least constant speed.
  * It must allow all players to be controlled by the keyboard simultaneously.
    * There is a patch available that enables the PC version of Street Fighter IV to do this:
    * http://forum.arcadecontrols.com/index.php?topic=96377.0

**This tool is not intended for use in competitive or online play.**<br>
Any videos produced with the aid of this program should disclose that they are tool-assisted.<br>
<br>
<hr />
<h1>Using the program</h1>
<h3>Basic usage</h3>

Open AutoMacro. This will generate a <i>macro.ini</i> file if one doesn't exist. Configure the gamekeys in <i>macro.ini</i> to match the settings in your game or emulator. Using a plain text editor, compose a script that will try to perform the desired sequence of commands. Save it as a <i>.mis</i> file. Open the program and load the script. This can be done by browsing for it (Ctrl+O), typing the filename into the bar, or by dragging and dropping the file onto the bar.<br>
<br>
Once you have the settings configured and a script loaded, you are ready to start sending the commands to the game. Make the game window active or full screen and get to the part where you want the sequence to begin. Enter the startkey and the action will proceed. When it's finished you can enter the startkey again to repeat the sequence. To stop it before it's complete, press the startkey again or the stopkey. You can make changes to the script file, reload it, and try again until the results are acceptable.<br>
<br>
<h3>Other functions</h3>

<b>Reload script</b> (F5) reparses the currently loaded script file and <b>Reload macro.ini</b> (Ctrl+F5) rereads the settings file. These things can be done automatically with the autoreload option.<br>
<br>
<b>Edit script</b> (F6) and <b>Edit macro.ini</b> (Ctrl+F6) opens these files with Notepad for quick editing.<br>
<br>
<b>Analyze script</b> (F7) opens a window with details about the currently loaded script. This function is useful for diagnosing problems.<br>
<br>
<ul><li><b>Raw string</b> shows the text of the file before any processing.<br>
</li><li><b>Processed string</b> shows the result after stripping unknown or commented text, and after expanding the shorthand for waits and loops.<br>
</li><li><b>Input stream</b> shows a frame-by-frame table of what inputs are active.<br>
</li><li><b>Delta stream</b> shows a frame-by-frame table of what inputs are activated or released.<br>
</li><li><b>Command queue</b> shows the list of the commands to be executed by AutoIt.</li></ul>

<b>Report current settings</b> (Ctrl+F7) outputs the configuration to the console. You can confirm that your gamekeys and other settings are configured properly this way.<br>
<br>
<ul><li>The hotkey bindings are shown in AutoIt's own format. They also appear in the File menu as written literally. They are greyed out because they are not intended to be activated this way.</li></ul>

<b>Unload script</b> (F8) clears the currently loaded script file.<br>
<br>
<b>Loop mode</b> (Alt+L) toggles loop mode. If active, the script goes back to the beginning after executing the last command. A macro running in loop mode will play indefinitely and must be stopped by pressing the startkey or stopkey.<br>
<br>
<hr />
<h1>Writing scripts</h1>

This section explains the script format.<br>
<br>
In the following commands, <code>n</code> represents a number and <code>k</code> represents a key symbol (direction or button) defined in the settings file.<br>
<table><thead><th><b><code>k</code></b></th><th>Input the gamekey k. The key is pressed for the current frame only and then released.</th></thead><tbody>
<tr><td><b><code>_k</code></b></td><td>Hold the gamekey k. The key is pressed for the current frame and any subsequent frames until released.</td></tr>
<tr><td><b><code>^k</code></b></td><td>Release the gamekey k, if held.                                                      </td></tr>
<tr><td><b><code>*</code></b></td><td>Release all held keys.                                                               </td></tr>
<tr><td><b><code>F</code></b></td><td>Input <code>R</code> for player 1 or odd numbered players, or <code>L</code> for player 2 or even numbered players.</td></tr>
<tr><td><b><code>B</code></b></td><td>Input <code>L</code> for player 1 or odd numbered players, or <code>R</code> for player 2 or even numbered players.</td></tr>
<tr><td><b><code>.</code></b></td><td>Advance one frame.                                                                   </td></tr>
<tr><td><b><code>Wn</code></b></td><td>Advance (wait) n frames.                                                             </td></tr>
<tr><td><b><code>+</code></b></td><td>Select player 1.                                                                     </td></tr>
<tr><td><b><code>-</code></b></td><td>Select the next player.                                                              </td></tr>
<tr><td><b><code>&lt;</code></b></td><td>Open a bracketed section and switch control to player 1.                             </td></tr>
<tr><td><b><code>/</code></b></td><td>Switch to the next player in a bracketed section.                                    </td></tr>
<tr><td><b><code>&gt;</code></b></td><td>Close a bracketed section.                                                           </td></tr>
<tr><td><b><code>()n</code></b></td><td>Repeat the commands enclosed in the parentheses n times. Loops can be nested.        </td></tr>
<tr><td><b><code># text</code></b></td><td>A comment. The rest of the line after the symbol is ignored by the script.<br>Comments that explain what the macro does are recommended.</td></tr>
<tr><td><b><code>!</code></b></td><td>End the macro. Any content after the end is ignored by the script, and can be used as comments.<br>Don't forget to advance at least one frame after the last input and before the end.</td></tr></tbody></table>

Macros are case insensitive. Commas, whitespaces, tabs and newlines can be used for spacing and legibility, but are ignored by the script. The exception is that some separation is required between multiplier or index numbers (such as after a <code>W</code>) and numerical key presses.<br>
<br>
Analog inputs are not (yet) supported.<br>
<br>
<ul><li><code>F</code> and <code>B</code> only get substituted if the module is using <code>L</code> and <code>R</code> and not already using <code>F</code> or <code>B</code>.</li></ul>

<h3>Synchronous multi-player control with <code>+ -</code></h3>

<ul><li>Commands are applied only to the selected player.<br>
</li><li>Player 1 is selected by default.<br>
</li><li>The <code>+</code> and <code>-</code> symbols are used to switch between players.<br>
</li><li>Time advancement applies to all players.<br>
</li><li>Nonselected players can give input with their held keys.<br>
</li><li>To modify the input of multiple players on the same frame, switch between them before advancing frames.</li></ul>

<h3>Asynchronous multi-player control with <code>&lt; / &gt;</code></h3>

<ul><li>Commands are applied only to the selected player.<br>
</li><li>Player 1 is selected when the brackets are opened.<br>
</li><li>Control is switched to the next player after each <code>/</code>.<br>
</li><li>Time advancement applies only to the selected player.<br>
</li><li>When the brackets are closed, time is advanced to the point of the player with the most frames, wait frames are added to the others to make up the difference, all player inputs are multiplexed, and control returns to player 1.<br>
</li><li>The <code>+ -</code> symbols are ignored inside brackets.</li></ul>

<hr />
<h1>Configuring the settings</h1>

The <i>macro.ini</i> file contains the user's settings. If it doesn't exist it will be created when running AutoMacro, and you can restore the default settings by removing the file.<br>
<table><thead><th><b><code>macrofile</code></b></th><th>This is the script that will be loaded automatically when starting the program. It can be left blank.</th></thead><tbody>
<tr><td><b><code>targetwindow</code></b></td><td>This is the text that must appear in the title bar of the active window in order for your script to be sent. Partial matches are OK, and it can be left blank.<br>Using this is recommended to avoid accidentally sending keystrokes to other programs.</td></tr>
<tr><td><b><code>startkey</code></b> </td><td>This is the hotkey or key combination to start playing, or to stop if currently playing.             </td></tr>
<tr><td><b><code>stopkey</code></b>  </td><td>Press this to stop if currently playing.                                                             </td></tr>
<tr><td><b><code>framelength</code></b></td><td>This is a number or numerical expression that defines how long a frame is in milliseconds. Games typically run at 60 frames per second (a frame length of 1000/60 ms) or else just under 60 fps.<br>This value should only be adjusted if the scripted input seems to run at the wrong speed.</td></tr>
<tr><td><b><code>nplayers</code></b> </td><td>Most games of interest are for two players, but any number can be supported.                         </td></tr>
<tr><td><b><code>nkeys</code></b>    </td><td>This is the number of keys (directions and buttons) for each player.<br>Avoid setting <code>nplayers</code> and <code>nkeys</code> higher than necessary or parsing will be slower.</td></tr>
<tr><td><b><code>gamekeys</code></b> </td><td>This table determines the mappings for each key and for each player.                                 </td></tr></tbody></table>

<ul><li>The first column is a descriptive name for the command.<br>
</li><li>The next column is the single-character, case-insensitive symbol to write in the script to perform that command.<br>
<blockquote>o Do not use these reserved characters: <code>w W . , _ ^ * + - &lt; / &gt; ( ) # ! "</code>
</blockquote></li><li>The remaining columns are the corresponding key bindings assigned for each player.<br>
</li><li>There must be a minimum of one column for each player (plus the first two columns) and one row for each key.<br>
</li><li>Each entry on a row must be separated by blank space.</li></ul>

<table><thead><th><b><code>maxwarnings</code></b></th><th>This is the maximum number of formatting problems (such as unknown symbols) that will be found before the parser stops trying to read a script.</th></thead><tbody>
<tr><td><b><code>autoreload</code></b> </td><td>If this is <code>true</code>, the program automatically reloads the script and the settings file when changes are made. If it is <code>false</code> they have to be reloaded manually.</td></tr>
<tr><td><b><code>showlinenumbers</code></b></td><td>Set to <code>true</code> or <code>false</code>, this determines whether the frame numbers are displayed for the input stream and delta stream in the script analysis window.</td></tr></tbody></table>

<h3>Assigning hotkeys and game keys</h3>

<ul><li>Most keyboard keys can be assigned to the hotkey functions, optionally combined with <code>Shift+</code>, <code>Ctrl+</code> and <code>Alt+</code> modifiers.<br>
</li><li>Key names must be in quotes and are not case sensitive.<br>
</li><li>Ensure that hotkeys, game keys, and the game's own hotkeys have separate bindings.<br>
<ul><li>However, if using an emulator with savestates, try this:<br />Make a savestate before the action, and set the startkey to match the loadstate key. This will make retries easier.<br>
</li></ul></li><li>Release any modifier keys during playback or else the sent keystrokes will also be modified.<br>
</li><li>Game keys are assigned the same way as hotkeys but with no modifiers allowed.<br>
</li><li>Special keys are designated by the following names:</li></ul>

<code>Space, Enter, Backspace, Delete, Up, Down, Left, Right, Home, End, Escape, Insert, Pgup, Pgdn, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, Tab, Printscreen, Pause, Numpad0, Numpad1, Numpad2, Numpad3, Numpad4, Numpad5, Numpad6, Numpad7, Numpad8, Numpad9, NumpadMult, NumpadAdd, NumpadSub, NumpadDiv, NumpadDot, NumpadEnter</code>

<h3>Examples</h3>

<ul><li><code>"q"</code>
</li><li><code>"SHIFT+;"</code>
</li><li><code>"ctrl+NUMPAD0"</code>
</li><li><code>"Ctrl+Alt+Shift+Backspace"</code>