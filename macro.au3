local $appname = "AutoMacro"
local $version = "1.04"
local $verdate = "5/29/2010"
; Written by Dammit
; http://macrolua.googlecode.com/

#include <windowsconstants.au3>
#include <guiconstantsex.au3>
#include <editconstants.au3>
#include <comboconstants.au3>
#include <staticconstants.au3>
#include <scrollbarconstants.au3>
#include <guiedit.au3>

opt("mustdeclarevars", 1)
opt("guioneventmode", 1)
opt("guicoordmode", 1)
opt("wintitlematchmode", 2)
opt("sendkeydelay", 0)
opt("sendkeydowndelay", 0)

; prevent duplicate instances
if winexists($appname & " " & $version) then
    msgbox(0x30, "Error", $appname & " is already running.")
    exit
endif

; ------------------------------------------------------------------------------
; GUI parameters
; ------------------------------------------------------------------------------
local $status = 0, $l = @crlf, $fontname = "courier new", $fontsize = 10, $choicestring = ""
local $mainx = 420, $mainy = 340, $detailsx = 500, $detailsy = 600, _
	$aboutx = 224, $abouty = 160, $winleft = 20, $wintop = 80, $btnx = 100, $btny = 24
local $statusarray[6] = [ _
	"no script loaded", _
	"script error", _
	"processing script...", _
	"analyzing inputstream...", _
	"ready to send", _
	"now sending..."]
local $viewarray[5][2] = [ _
	[      "Raw string", ""], _
	["Processed string", ""], _
	[    "Input stream", ""], _
	[    "Delta stream", ""], _
	[   "Command queue", ""]]
for $i = 1 to ubound($viewarray)-1
	$choicestring &= $viewarray[$i][0] & "|"
next

; ------------------------------------------------------------------------------
; INI parameters
; ------------------------------------------------------------------------------
local $configfile = "macro.ini"

; User can't exceed these maximums
local $maxnplayers = 10, $maxnkeys = 20

; Array that determines what gets loaded from the ini
; Second column describes what format is expected
local $settings[11][2] = [ _
	[      "macrofile", -3], _
	[   "targetwindow", -3], _
	[       "startkey", -3], _
	[        "stopkey", -3], _
	[    "framelength", -1], _
	[       "nplayers", $maxnplayers], _
	[          "nkeys", $maxnkeys], _
	[    "maxwarnings",  0], _
	[     "autoreload", -2], _
	["showlinenumbers", -2], _
	[      "framemame", -2]]
	
; These values will be used in case of invalid ini values
local $macrofile = "sample.mis", $targetwindow = "", $startkey = "Ctrl+P", $stopkey = "Ctrl+S"
local $framelength = 1000/60, $nplayers = 2, $nkeys = 10, $useF_B = true
local $gamekeys[$nkeys][$nplayers+2] = [ _
	[     "right", "R", "right", "numpad6"], _
	[      "left", "L",  "left", "numpad4"], _
	[      "down", "D",  "down", "numpad2"], _
	[        "up", "U",    "up", "numpad8"], _
	[       "jab", "1",     "a",       "g"], _
	[    "strong", "2",     "s",       "h"], _
	[    "fierce", "3",     "d",       "j"], _
	[     "short", "4",     "z",       "b"], _
	[   "forward", "5",     "x",       "n"], _
	["roundhouse", "6",     "c",       "m"]]
local $autoreload = true, $showlinenumbers = true, $maxwarnings = 20, $framemame = false

; Table of special key names
local $spkeys = "(SPACE|ENTER|BACKSPACE|BS|INSERT|INS|DELETE|DEL|HOME|END|PGUP|PGDN|" & _
"UP|DOWN|LEFT|RIGHT|ESCAPE|ESC|F12|F11|F10|F9|F8|F7|F6|F5|F4|F3|F2|F1|TAB|PRINTSCREEN|PAUSE|" & _
"NUMPAD0|NUMPAD1|NUMPAD2|NUMPAD3|NUMPAD4|NUMPAD5|NUMPAD6|NUMPAD7|NUMPAD8|NUMPAD9|" & _
"NUMPADMULT|NUMPADADD|NUMPADSUB|NUMPADDIV|NUMPADDOT|NUMPADENTER)"

; ------------------------------------------------------------------------------
; Script parser parameters
; ------------------------------------------------------------------------------
local $funckeys[9][2] = [ _
[".",       "advance()"], _
["_",          "hold()"], _
["^",       "release()"], _
["*",    "releaseall()"], _
["<",  "openbrackets()"], _
["/",  "nextbrackets()"], _
[">", "closebrackets()"], _
["+",        "pfirst()"], _
["-",         "pnext()"]]

local $macrosize, $warningcount, $player, $nextkey, $unused, $frame, $bracket[$nplayers+1], $inbrackets, _
	$press[$nplayers][$nkeys], $hold[$nplayers][$nkeys], $inputstream[1][$nplayers][$nkeys], $comqueue[1]
local $loadedfile, $scripttimestamp, $configtimestamp

; Keystroke sender parameters
local $play = false, $stop = false

; ------------------------------------------------------------------------------
; initialize GUI
; ------------------------------------------------------------------------------
guiregistermsg($wm_getminmaxinfo, 'wm_getminmaxinfo')

; ------------------------------------------------------------------------------
; Main window

local $mainwindow = guicreate($appname & " " & $version, $mainx, $mainy, $winleft, $wintop, _
	bitor($ws_maximizebox, $ws_sizebox, $ws_sysmenu, $ws_overlappedwindow), $ws_ex_acceptfiles)
guisetstate(@sw_show, $mainwindow)
guisetonevent($gui_event_close, "quit")

local $filemenu = guictrlcreatemenu("&File")
local $startitem = guictrlcreatemenuitem("Start sending", $filemenu)
guictrlsetstate($startitem, $gui_disable)
local $stopitem = guictrlcreatemenuitem("Stop sending", $filemenu)
guictrlsetstate($stopitem, $gui_disable)
guictrlcreatemenuitem("", $filemenu)
local $clearitem = guictrlcreatemenuitem("Clear console" & @tab & "Ctrl+C", $filemenu)
guictrlsetonevent($clearitem, "clear")
local $quititem = guictrlcreatemenuitem("Quit" & @tab & "Ctrl+Q", $filemenu)
guictrlsetonevent($quititem, "quit")

local $scriptmenu = guictrlcreatemenu("&Script")
local $openitem = guictrlcreatemenuitem("Browse for new script" & @tab & "Ctrl+O", $scriptmenu)
guictrlsetonevent($openitem, "browse")
local $reloadscriptitem = guictrlcreatemenuitem("Reload script" & @tab & "F5", $scriptmenu)
guictrlsetonevent($reloadscriptitem, "loadfilebar")
local $editscriptitem = guictrlcreatemenuitem("Edit script" & @tab & "F6", $scriptmenu)
guictrlsetonevent($editscriptitem, "editscript")
local $viewscriptitem = guictrlcreatemenuitem("Analyze script" & @tab & "F7", $scriptmenu)
guictrlsetonevent($viewscriptitem, "showdetails")
local $unloadscriptitem = guictrlcreatemenuitem("Unload script" & @tab & "F8", $scriptmenu)
guictrlsetonevent($unloadscriptitem, "unloadscript")

local $configmenu = guictrlcreatemenu("&Config")
local $reloadconfigitem = guictrlcreatemenuitem("Reload " & $configfile & @tab & "Ctrl+F5", $configmenu)
guictrlsetonevent($reloadconfigitem, "loadsettings")
local $editconfigitem = guictrlcreatemenuitem("Edit " & $configfile & @tab & "Ctrl+F6", $configmenu)
guictrlsetonevent($editconfigitem, "editsettings")
local $viewconfigitem = guictrlcreatemenuitem("Report current settings" & @tab & "Ctrl+F7", $configmenu)
guictrlsetonevent($viewconfigitem, "printsettings")

local $helpmenu = guictrlcreatemenu("&Help")
local $readmeitem = guictrlcreatemenuitem("Instructions" & @tab & "F1", $helpmenu)
guictrlsetonevent($readmeitem, "readme")
guictrlsetonevent(guictrlcreatemenuitem("About", $helpmenu), "showabout")

guictrlcreatelabel("Script file", 4, 8)
guictrlsetresizing(-1, $gui_dockleft + $gui_docktop + $gui_dockwidth + $gui_dockheight)
local $filebar = guictrlcreateinput("", -1, 24, $mainx-8)
guictrlsetresizing(-1, $gui_dockleft + $gui_dockright + $gui_docktop + $gui_dockheight)
guictrlsetstate(-1, $gui_dropaccepted)
guictrlsetonevent(-1, "dragndrop")

guictrlsetonevent(guictrlcreatebutton("&Browse", -1, 48, $btnx, $btny), "browse")
guictrlsetresizing(-1, $gui_dockleft + $gui_docktop + $gui_dockwidth + $gui_dockheight)
guictrlsetonevent(guictrlcreatebutton("&Reload", $btnx+8, -1, $btnx, $btny), "loadfilebar")
guictrlsetresizing(-1, $gui_dockleft + $gui_docktop + $gui_dockwidth + $gui_dockheight)
guictrlsetonevent(guictrlcreatebutton("&Edit", $btnx*2+12, -1, $btnx, $btny), "editscript")
guictrlsetresizing(-1, $gui_dockleft + $gui_docktop + $gui_dockwidth + $gui_dockheight)
guictrlsetonevent(guictrlcreatebutton("&Analyze", $btnx*3+16, -1, $btnx, $btny), "showdetails")
guictrlsetresizing(-1, $gui_dockleft + $gui_docktop + $gui_dockwidth + $gui_dockheight)

guictrlcreatelabel("Output console", 4, 80, -1, 12)
guictrlsetresizing(-1, $gui_dockleft + $gui_docktop + $gui_dockwidth + $gui_dockheight)
local $console = guictrlcreateedit("", -1, 96, $mainx-8, $mainy-136, _
	bitor($es_autovscroll, $es_readonly, $ws_vscroll))
guictrlsetresizing(-1, $gui_dockleft + $gui_dockright + $gui_docktop + $gui_dockbottom)
if @osarch == "X64" and not @autoitx64 then message("Notice: This operating system can run the 64-bit version of this tool." & $l)

local $statusbox = guictrlcreatelabel("", 0, $mainy-36, 140, 16, $ss_sunken)
guictrlsetresizing(-1, $gui_dockleft + $gui_dockwidth + $gui_dockheight)
guictrlsetfont(-1, -1, 800)
local $framebox = guictrlcreatelabel("", 142, -1, 90, 16, bitor($ss_right, $ss_sunken))
guictrlsetresizing(-1, $gui_dockleft + $gui_dockwidth + $gui_dockheight)
local $progress = guictrlcreateprogress(234, -1, $mainx-204, 16, $ss_sunken)
guictrlsetresizing(-1, $gui_dockleft + $gui_dockright + $gui_dockheight)

local $accelkeys[13][2] = [ _
	[       "^c", $clearitem], _
	[       "^q", $quititem], _
	[       "^o", $openitem], _
	[     "{f5}", $reloadscriptitem], _
	[     "{f6}", $editscriptitem], _
	[     "{f7}", $viewscriptitem], _
	[     "{f8}", $unloadscriptitem], _
	[    "^{f5}", $reloadconfigitem], _
	[    "^{f6}", $editconfigitem], _
	[    "^{f7}", $viewconfigitem], _
	[     "{f1}", $readmeitem], _
	[ "{escape}", $console], _ ; make the escape key harmless
	["+{escape}", $console]]
guisetaccelerators($accelkeys)

; ------------------------------------------------------------------------------
; Script details window

local $details = guicreate("Script analysis", $detailsx, $detailsy, $winleft+$mainx+8, $wintop, _
	bitor($ws_maximizebox, $ws_sizebox, $ws_sysmenu, $ws_overlappedwindow))
guisetonevent($gui_event_close, "showdetails")

local $leftpane = guictrlcreateedit("", 4, 4, $detailsx/2-8, $detailsy-32, _
	bitor($es_multiline, $es_autovscroll, $es_readonly, $ws_vscroll))
guictrlsetresizing(-1, $gui_dockleft + $gui_dockhcenter + $gui_docktop + $gui_dockbottom)
guictrlsetfont(-1, $fontsize, -1, -1, $fontname)
local $rightpane = guictrlcreateedit("", $detailsx/2+4, -1, -1, -1, _
	bitor($es_multiline, $es_autovscroll, $es_readonly, $ws_vscroll))
guictrlsetresizing(-1, $gui_dockright + $gui_dockhcenter + $gui_docktop + $gui_dockbottom)
guictrlsetfont(-1, $fontsize, -1, -1, $fontname)

local $leftchoice = guictrlcreatecombo($viewarray[0][0], 4, $detailsy-24, 124, -1, $cbs_dropdownlist)
guictrlsetresizing(-1, $gui_dockleft + $gui_dockbottom + $gui_dockwidth + $gui_dockheight)
guictrlsetdata(-1, $choicestring, $viewarray[2][0])
guictrlsetonevent(-1, "leftchoice")
local $rightchoice = guictrlcreatecombo($viewarray[0][0], $detailsx/2+4, -1, -1, -1, $cbs_dropdownlist)
guictrlsetresizing(-1, $gui_dockhcenter + $gui_dockbottom + $gui_dockwidth + $gui_dockheight)
guictrlsetdata(-1, $choicestring, $viewarray[4][0])
guictrlsetonevent(-1, "rightchoice")

; ------------------------------------------------------------------------------
; About window

local $about = guicreate("About", $aboutx, $abouty, -1, -1, 0)
guisetonevent($gui_event_close, "hideabout")

guictrlcreatelabel($appname & " " & $version & ", " & $verdate, -4, 16, $aboutx, -1, $ss_center)

local $aboutlink = guictrlcreatelabel("http://macrolua.googlecode.com/", -4, 32, $aboutx, -1, $ss_center)
guictrlsetcolor(-1, 0x0000ff)
guictrlsetfont(-1, -1, -1, 4)
guictrlsetcursor(-1, 0)
guictrlsetonevent(-1, "aboutlink")

guictrlcreatelabel("Created with AutoIt " & @autoitversion, -4, 64, $aboutx, -1, $ss_center)

guictrlsetonevent(guictrlcreatebutton("OK", $aboutx/2-$btnx/2-4, 96, $btnx, $btny), "hideabout")

; ------------------------------------------------------------------------------
; load settings and script on startup and loop indefinitely
; ------------------------------------------------------------------------------
loadsettings()
loadfilebar()

while true
	sleep(1000)
	if $autoreload then
		if $configtimestamp <> filegettime($configfile, 0, 1) then
			message("Detected changes to config file.")
			loadsettings()
			$configtimestamp = filegettime($configfile, 0, 1)
		elseif $loadedfile and $scripttimestamp <> filegettime($loadedfile, 0, 1) then
			message("Detected changes to loaded script.")
			loadscript($loadedfile)
			$scripttimestamp = filegettime($loadedfile, 0, 1)
		endif
	endif
wend

; ------------------------------------------------------------------------------
; GUI functions
; ------------------------------------------------------------------------------
func setstatus(byref $s)
	if $s < 3 then 
		$loadedfile = ""
		winsettitle($details, "", "Script analysis")
		for $i = 0 to ubound($viewarray)-1
			$viewarray[$i][1] = ""
		next
		guictrlsetdata($framebox, "")
	else
		guictrlsetdata($framebox, $macrosize & " frames ")
	endif
	if $s = 0 and $status > 1 then message("Unloading script.")
	leftchoice()
	rightchoice()
	guictrlsetdata($statusbox, $statusarray[$s])
	$status = $s
endfunc

func quit()
	exit
endfunc

; makes drag 'n' drop overwrite previous box contents
func dragndrop()
	_guictrledit_setsel($filebar, 0, -1)
endfunc

func browse()
	local $macrofile = fileopendialog("Select a macro file", @workingdir, "Script files (*.mis;*.txt)|All (*.*)", 1)
	if not @error then
		guictrlsetdata($filebar, $macrofile)
		loadfilebar()
	endif
endfunc

func loadfilebar()
	loadscript(guictrlread($filebar))
endfunc

func editscript()
	local $editfile = guictrlread($filebar)
	local $edithandle = fileopen($editfile, 0)
	if $edithandle > -1 then run("notepad.exe " & $editfile)
	fileclose($edithandle)
endfunc

func unloadscript()
	setstatus(0)
endfunc

func message($msg)
	local $end = stringlen(guictrlread($console))
	_guictrledit_setsel($console, $end, $end)
	_guictrledit_scroll($console, $sb_scrollcaret)
	guictrlsetdata($console, $msg & $l, 1)
endfunc

func clear()
	guictrlsetdata($console, "")
endfunc

func showdetails()
	if bitand(wingetstate("Script analysis"), 0x2) then
		guisetstate(@sw_hide, $details)
	else
		guisetstate(@sw_show, $details)
	endif
endfunc

func leftchoice()
	for $i = 0 to ubound($viewarray)-1
		if guictrlread($leftchoice) == $viewarray[$i][0] then return guictrlsetdata($leftpane, $viewarray[$i][1])
	next
endfunc

func rightchoice()
	for $i = 0 to ubound($viewarray)-1
		if guictrlread($rightchoice) == $viewarray[$i][0] then return guictrlsetdata($rightpane, $viewarray[$i][1])
	next
endfunc

func readme()
	shellexecute("macro-readme.html")
endfunc

func showabout()
	guisetstate(@sw_hide, $about)
	guisetstate(@sw_show, $about)
endfunc

func hideabout()
	guisetstate(@sw_hide, $about)
endfunc

func aboutlink()
	shellexecute("http://macrolua.googlecode.com/")
endfunc

; Enforces minimum size for the windows
func wm_getminmaxinfo($hwnd, $msgid, $wparam, $lparam)
	#forceref $msgid, $wparam
	local $minmaxinfo = dllstructcreate("int;int;int;int;int;int;int;int;int;int", $lparam)
	switch $hwnd
		case $mainwindow
			dllstructsetdata($minmaxinfo, 7, $mainx+8); min width
			dllstructsetdata($minmaxinfo, 8, $mainy); min height
		case $details
			dllstructsetdata($minmaxinfo, 7, $detailsx+8); min width
			dllstructsetdata($minmaxinfo, 8, $detailsy/2); min height
	endswitch
endfunc

; ------------------------------------------------------------------------------
; INI functions
; ------------------------------------------------------------------------------

func editsettings()
	local $confighandle = fileopen($configfile, 0)
	if $confighandle > -1 then run("notepad.exe " & $configfile)
	fileclose($confighandle)
endfunc

func printsettings()
	message("Game key settings:")
	for $p = 0 to $nplayers+1
		local $keystring
		switch $p
			case 0
				$keystring = "Key names: "
			case 1
				$keystring = "Script symbols: "
			case else
				$keystring = "Player " & $p-1 & "'s keys: "
		endswitch
		for $k = 0 to ubound($gamekeys)-1
			$keystring &= $gamekeys[$k][$p] & ", "
		next
		message(stringtrimright($keystring, 2))
	next
	message("")
	
	message("Other settings:")
	for $i = 0 to ubound($settings)-1
		message($settings[$i][0] & ": " & eval($settings[$i][0]))
	next
	message("")
endfunc

func loadsettings()
	if not fileexists($configfile) then
		message($configfile & " not found. Creating a new one.")
		local $configtext = '' _
'; Settings file for AutoMacro' & $l & _
'; Remove this file to restore all defaults.' & $l & $l & _
'; For help please read the documentation.' & $l & $l & _
'[Settings]' & $l & $l & _
'; Script to load at startup (leave as "" for none)' & $l & _
'; relative or absolute paths are OK' & $l & _
'macrofile = "sample.mis"' & $l & $l & _
'; Name of the window that must be active for playback to proceed (leave as "" for none)' & $l & _
'; partial name matches are OK' & $l & _
'targetwindow = ""' & $l & $l & _
'; Key to start playback or cancel remaining playback if playing' & $l & _
'; default is "Ctrl+P"' & $l & _
'startkey = "Ctrl+P"' & $l & $l & _
'; Key to cancel remaining playback if playing' & $l & _
'; default is "Ctrl+S"' & $l & _
'stopkey = "Ctrl+S"' & $l & $l & _
'; Length of a frame in milliseconds' & $l & _
'framelength = 1000/60' & $l & $l & _
'; Maximum number of players' & $l & _
'nplayers = 2' & $l & $l & _
'; Number of keys per player' & $l & _
'nkeys = 10' & $l & $l & _
'; Key mappings for each player in order of:' & $l & _
'; description, script symbol, P1 key, P2 key' & $l & _
'key 1  = "      right    R    right    numpad6 "' & $l & _
'key 2  = "       left    L     left    numpad4 "' & $l & _
'key 3  = "       down    D     down    numpad2 "' & $l & _
'key 4  = "         up    U       up    numpad8 "' & $l & _
'key 5  = "        jab    1        a          g "' & $l & _
'key 6  = "     strong    2        s          h "' & $l & _
'key 7  = "     fierce    3        d          j "' & $l & _
'key 8  = "      short    4        z          b "' & $l & _
'key 9  = "    forward    5        x          n "' & $l & _
'key 10 = " roundhouse    6        c          m "' & $l & $l & _
'; Maximum number of script warnings before stopping (set to 0 for no limit)' & $l & _
'maxwarnings = 20' & $l & $l & _
'; Auto reload the loaded script if it is changed' & $l & _
'autoreload = true' & $l & $l & _
'; Style of the text in the script analysis window' & $l & _
'showlinenumbers = true' & $l & $l & _
'; remove frameMAME audio commands from script (leave as false unless using frameMAME scripts)' & $l & _
'framemame = false' & $l & _

		local $inihandle = fileopen($configfile, 2)
		filewrite($inihandle, $configtext)
		fileflush($inihandle)
		fileclose($inihandle)
		loadsettings()
		return
	else
		message("Loading " & $configfile & "...")
	endif

; Load misc. settings
	for $i = 0 to ubound($settings)-1
		local $val = iniread($configfile, "settings", $settings[$i][0], "missing")
		if $val == "missing" then
			warning(string($settings[$i][0]) & " setting was not found in " & $configfile)
			message("Using default: " & eval($settings[$i][0]))
			continueloop
		endif
		if $settings[$i][1] > -3 then $val = execute($val) ; turn strings into numbers
		switch $settings[$i][1]
			case -3 ; string
				assign($settings[$i][0], $val)
			case -2 ; boolean
				if isbool($val) then
					assign($settings[$i][0], $val)
				else
					warning(string($settings[$i][0]) & " must be set to either true or false")
					message("Using default: " & eval($settings[$i][0]))
				endif
			case -1 ; numerical expression
				if isnumber($val) and $val > 0 then
					assign($settings[$i][0], $val)
				else
					warning(string($settings[$i][0]) & " must be a positive number or numerical expression")
					message("Using default: " & eval($settings[$i][0]))
				endif
			case 0 ; int with no limit
				if isint($val) then
					assign($settings[$i][0], $val)
				else
					warning(string($settings[$i][0]) & " must be an integer")
					message("Using default: " & eval($settings[$i][0]))
				endif
			case else ; int with this as maximum
				if not isint($val) or $val < 1 then
					warning(string($settings[$i][0]) & " must be a positive integer")
					message("Using default: " & eval($settings[$i][0]))
				elseif $val > $settings[$i][1] then
					warning(string($settings[$i][0]) & " is too high (" & $settings[$i][1] & " is the maximum)")
					message("Using default: " & eval($settings[$i][0]))
				else
					assign($settings[$i][0], $val)
				endif
		endswitch
	next

; Load gamekeys
	dim $gamekeys[$nkeys][$nplayers+2]
	for $k = 0 to $nkeys-1
		local $keystring = iniread($configfile, "settings", "key " & $k+1, "missing")
		local $defaultkeystring = ""
		for $i = 0 to ubound($gamekeys, 2)-1
			$defaultkeystring &= $gamekeys[$k][$i] & ", "
		next
		$defaultkeystring = stringtrimright($defaultkeystring, 2)
		if $keystring = "missing" then
			warning("key " & $k+1 & " setting was not found in " & $configfile)
			message("Using default: " & $defaultkeystring)
			continueloop
		endif
		$keystring = stringsplit(stringstripws($keystring, 7), " ", 2)
		if ubound($keystring) < $nplayers+2 then
			warning("With " & $nplayers & " players, key " & $k+1 & " setting should have " & $nplayers+2 & " space-separated entries.")
			message("Using default: " & $defaultkeystring)
			continueloop
		endif
		for $p = 0 to $nplayers+1
			$gamekeys[$k][$p] = $keystring[$p]
		next
	next

	$useF_B = false
	local $usingF = false, $usingB = false, $usingL = false, $usingR = false
; Case desensitize the gamekey symbols
	for $k = 0 to $nkeys-1
		for $p = 1 to $nplayers+1
			$gamekeys[$k][$p] = stringupper($gamekeys[$k][$p])
		next
		switch $gamekeys[$k][1]
		case "F"
			$usingF = true
		case "B"
			$usingB = true
		case "L"
			$usingL = true
		case "R"
			$usingR = true
		endswitch
	next
; Check if it's OK to substitute F/B for L/R
	if not $usingF and not $usingB and $usingL and $usingR then
		$useF_B = true
	endif

	guictrlsetdata($filebar, $macrofile)
	applyhotkey($startkey, "playback", $startitem, "Start sending", 0)
	applyhotkey($stopkey, "stopplayback", $stopitem, "Stop sending", 1)
	$configtimestamp = filegettime($configfile, 0, 1)
	message("Done loading settings." & $l)
	setstatus(0)
endfunc

func applyhotkey(byref $key, byref $functext, byref $menuitem, byref $menutext, byref $menupos)
	guictrldelete($menuitem)
	$menuitem = guictrlcreatemenuitem($menutext & @tab & $key, $filemenu, $menupos)
	guictrlsetstate($menuitem, $gui_disable)

	$key = stringupper($key)
	$key = stringregexpreplace($key, "SHIFT[+|-|\s]", "+")
	$key = stringregexpreplace($key, "CTRL[+|-|\s]", "^")
	$key = stringregexpreplace($key, "ALT[+|-|\s]", "!")
	$key = stringregexpreplace($key, $spkeys, "{\1}")
	$key = stringlower($key)
	$key = stringstripws($key, 8)

	hotkeyset($key, $functext)
endfunc

; ------------------------------------------------------------------------------
; Script parsing functions
; ------------------------------------------------------------------------------
func loadscript($file)
; ------------------------------------------------------------------------------
; Initialize parameters
	$frame = 0
	$macrosize = 0
	$warningcount = 0
	$nextkey = 0
	$player = 1
	$unused = ""
	$inbrackets = false
	dim $bracket[$nplayers+1]
	dim $press[$nplayers][$nkeys]
	dim $hold[$nplayers][$nkeys]
	dim $inputstream[1][$nplayers][$nkeys]
	dim $comqueue[1]

; ------------------------------------------------------------------------------
; Read the input file and prepare the macro string from its contents
	if not $file then return

	local $macrohandle = fileopen($file, 0)
	if $macrohandle = -1 then
		message("Error: Unable to open " & $file & $l)
		setstatus(1)
		return
	endif
	setstatus(2)
	local $macro = fileread($macrohandle)
	fileclose($macrohandle)

	$viewarray[0][1] = $macro ; Raw string dump
	message("Loading " & $file & "...")

; Remove lines commented with "#"
	$macro = stringregexpreplace($macro, "#.*","")

; Case desensitize
	$macro = stringupper($macro)

; Remove frameMAME audio commands
	if $framemame then $macro = stringregexpreplace($macro, "A[M!]|A[CS]\s?\d+|AR\s?\d+\s\d+", "")

; Replace line breaks with commas
	$macro = stringregexpreplace($macro, "[\r\n]", ",")

; Remove the first "!" and everything after, and savestate ops
	$macro = stringregexpreplace($macro, "!.*|[$&]\s?\d+", "")

; Expand waits into dots
	while stringregexp($macro,"W\s?\d+")
		local $execstring = stringregexpreplace($macro, "(.*?)(W\s?(\d+))(.*)", 'dots("\1","\2","\3","\4")')
		$macro = execute($execstring)
	wend

; Expand ()n loops
	while stringregexp($macro,"\(.*\)\s?\d+")
		local $execstring = stringregexpreplace($macro, "(.*)(\(.*?\))\s?(\d+)(.*)", 'loop("\1","\2","\3","\4")')
		$macro = execute($execstring)
	wend

; Remove commas and spaces
	$macro = stringregexpreplace($macro,"[,\s]", "")

; Final string dump
	$viewarray[1][1] = $macro 

; ------------------------------------------------------------------------------
; Process each character of the string to prepare the input stream array
	while $macro
		char(stringleft($macro, 1))
		$macro = stringtrimleft($macro, 1)
		if $warningcount >= $maxwarnings and $maxwarnings > 0 then
			message("Error: Too many warnings" & $l)
			setstatus(1)
			return
		endif
	wend

; Length is now determined
	$macrosize = $frame

	if $macrosize = 0 then
		message("Error: Macro is zero frames long" & $l)
		setstatus(1)
		return
	endif

; Remove the last element (always empty) from $inputstream
	redim $inputstream[$frame][$nplayers][$nkeys]

	setstatus(3)

	if $inbrackets then
		warning("Brackets were left open.")
		closebrackets()
	endif

	for $p = 0 to $nplayers-1
		local $stillheld = ""
		for $k = 0 to $nkeys-1
			if $hold[$p][$k] = true then $stillheld &= $gamekeys[$k][0] & " "
		next
		if $stillheld then warning('Player ' & $p+1 & ' was left holding: ' & $stillheld)
	next

	if $unused then warning('Unprocessed input: ' & $unused)

; ------------------------------------------------------------------------------
; Produce the string dumps and the command queue from the input stream array
	local $ndigits = digits($macrosize), $lastframe[$nplayers][$nkeys], $idle = 0, $activity = false, _
		$inputdump = "", $deltadump = "", $comdump = ""

; Header row
	if $showlinenumbers then
		for $d = 1 to $ndigits
			$inputdump &= " "
			$deltadump &= " "
		next
		$inputdump &= " "
		$deltadump &= " "
	endif

	for $p = 0 to ubound($inputstream, 2)-1
		$inputdump &= "|"
		$deltadump &= "|"
		for $k = 0 to ubound($inputstream, 3)-1
			$inputdump &= $gamekeys[$k][1]
			$deltadump &= $gamekeys[$k][1]
		next
	next
	$inputdump &= "|" & $l
	$deltadump &= "|" & $l

; Frame rows
	for $f = 0 to ubound($inputstream, 1)-1
		$activity = false
		if $showlinenumbers then
			$inputdump &= stringformat("%" & $ndigits & "d", $f) & " "
			$deltadump &= stringformat("%" & $ndigits & "d", $f) & " "
		endif
		for $p = 0 to ubound($inputstream, 2)-1
			$inputdump &= "|"
			$deltadump &= "|"
			for $k = 0 to ubound($inputstream, 3)-1
				if $inputstream[$f][$p][$k] then
					$inputdump &= $gamekeys[$k][1]
					if not $lastframe[$p][$k] then
						$deltadump &= "+"
						updatequeue('send("{' & $gamekeys[$k][$p+2] & ' down}")', $activity, $idle)
					else
						$deltadump &= "."
					endif
					$lastframe[$p][$k] = true
				else
					$inputdump &= "."
					if $lastframe[$p][$k] then
						$deltadump &= "-"
						updatequeue('send("{' & $gamekeys[$k][$p+2] & ' up}")', $activity, $idle)
					else
						$deltadump &= " "
					endif
					$lastframe[$p][$k] = false
				endif
			next
		next
		$inputdump &= "|" & $l
		$deltadump &= "|" & $l
		if $activity then $idle = 0
		$idle += 1
	next

; Release anything pressed on the last frame
	$activity = false
	if $showlinenumbers then $deltadump &= $macrosize & " "
	for $p = 0 to ubound($inputstream, 2)-1
		$deltadump &= "|"
		for $k = 0 to ubound($inputstream, 3)-1
			if $lastframe[$p][$k] then
				$deltadump &= "-"
				updatequeue('send("{' & $gamekeys[$k][$p+2] & ' up}")', $activity, $idle)
			else
				$deltadump &= " "
			endif
		next
	next
	$deltadump &= "|" & $l

; Remove the last element (always empty) from $comqueue
	if ubound($comqueue) > 1 then
		redim $comqueue[ubound($comqueue)-1]
	else
		warning("There are zero commands in this script.")
	endif

; Produce the command queue string from the array
	for $e in $comqueue
		$comdump &= $e & $l
	next

	$viewarray[2][1] = $inputdump
	$viewarray[3][1] = $deltadump
	$viewarray[4][1] = $comdump
	guictrlsetdata($progress, 0)
	setstatus(4)
	$loadedfile = $file
	$scripttimestamp = filegettime($loadedfile, 0, 1)
	winsettitle($details, "", "Script analysis: " & $loadedfile)
	message("Done loading script." & $l)

endfunc ;==>parse

; ------------------------------------------------------------------------------
; Helper functions for script parser

; expand W expressions into dots
func dots(byref $before, byref $replace, byref $count, byref $after)
	local $sub = ""
	for $i = 1 to $count
		$sub &= "."
	next
	return $before & $sub & $after
endfunc

; expand () expressions into loops
func loop(byref $before, byref $replace, byref $count, byref $after)
	$replace = stringtrimleft($replace, 1)
	$replace = stringtrimright($replace, 1)
	local $sub = ""
	for $i = 1 to $count
		$sub &= $replace
	next
	return $before & $sub & $after
endfunc

func advance() ; "."
	if isint($frame/10) then guictrlsetdata($framebox, "frame " & $frame)
	if $inbrackets then
		execute("updatestream(" & $player-1 & ")")
		if $frame+1 >= ubound($inputstream) then ; If in brackets, grow $inputstream only if necessary
			redim $inputstream[$frame+2][$nplayers][$nkeys]
		endif
	else
		for $p = 0 to $nplayers-1
			execute("updatestream(" & $p & ")")
		next
		redim $inputstream[$frame+2][$nplayers][$nkeys]
	endif
	$frame += 1
endfunc

func hold() ; "_"
	$nextkey = 1
endfunc

func release() ; "^"
	$nextkey = 2
endfunc

func releaseall() ; "*"
	local $used = false
	for $k = 0 to $nkeys-1
		if $hold[$player-1][$k] then $used = true
		$hold[$player-1][$k] = false
	next
	if not $used then warning("Used '*' for player " & $player & " but no holds to release")
endfunc

func openbrackets() ; "<"
	if $inbrackets then
		warning("Tried to open brackets but they were already open")
	else
		$inbrackets = true
		$player = 1
		$bracket[0] = $frame
	endif
endfunc

func nextbrackets() ; "/"
	if not $inbrackets then
		warning("Can only use '/' in brackets")
	elseif $player >= $nplayers then
		warning("Used '/' but player " & $player & " is already selected")
	else
		$bracket[$player] = $frame
		$player += 1
		$frame = $bracket[0]
	endif
endfunc

func closebrackets() ; ">"
	if not $inbrackets then
		warning("Tried to close brackets but they were not open")
	else
		$bracket[$player] = $frame
		local $highest = $bracket[0]
		for $p = 0 to $nplayers-1
			if not $bracket[$p+1] then
				$bracket[$p+1] = $bracket[0]
			elseif $bracket[$p+1] > $highest then
				$highest = $bracket[$p+1]
			endif
		next
		for $p = 0 to $nplayers-1
			$frame = $bracket[$p+1]
			while $frame <= $highest
				execute("updatestream(" & $p & ")")
				$frame += 1
			wend
		next
		$frame = $highest
		$inbrackets = false
		$player = 1
		for $p = 0 to $nplayers ; Reset $bracket for the next set
			$bracket[$p] = 0
		next
	endif
endfunc

func pfirst() ; "+"
	if $inbrackets then
		warning("Cannot use '+' in brackets")
	elseif $player = 1 then
		warning("Used '+' but player 1 is already selected")
	else
		$player = 1
	endif
endfunc

func pnext() ; "-"
	if $inbrackets then
		warning("Cannot use '-' in brackets")
	elseif $player >= $nplayers then
		warning("Used '-' but player " & $player & " is already selected")
	else
		$player += 1
	endif
endfunc

func resetnextkey(byref $k)
	if $nextkey = 1 then
		warning("Tried to hold non-gamekey '" & $k & "'")
	elseif $nextkey = 2 then
		warning("Tried to release non-gamekey '" & $k & "'")
	endif
	$nextkey = 0 ; press
endfunc

; This function has to be run from execute() for unknown reasons or else bad things happen
func updatestream(byref $p)
	for $k = 0 to $nkeys-1
		if $hold[$p][$k] or $press[$p][$k] then
		$inputstream[$frame][$p][$k] = $gamekeys[$k][1]
		endif
	next
	for $k = 0 to $nkeys-1
		$press[$p][$k] = false
	next
endfunc

func char(byref $key)
	for $k = 0 to ubound($funckeys)-1
		if $key == $funckeys[$k][0] then
			resetnextkey($key)
			execute($funckeys[$k][1])
			return
		endif
	next
	if $key == "F" and $useF_B then
		if mod($player, 2) == 0 then
			$key = "L"
		else
			$key = "R"
		endif
	elseif $key == "B" and $useF_B then
		if mod($player, 2) == 0 then
			$key = "R"
		else
			$key = "L"
		endif
	endif
	for $k = 0 to $nkeys-1
		if $key == $gamekeys[$k][1] then
			switch $nextkey
			case 0 ; press
				if $press[$player-1][$k] or $hold[$player-1][$k] then warning("" & $key & " is already down for player " & $player)
				$press[$player-1][$k] = true
			case 1 ; hold
				if $press[$player-1][$k] or $hold[$player-1][$k] then warning("" & $key & " is already down for player " & $player)
				$hold[$player-1][$k] = true
			case 2 ; release
				if not $hold[$player-1][$k] then warning("" & $key & " is already up for player " & $player)
				$hold[$player-1][$k] = false
			endswitch
			$nextkey = 0 ; press
			return
		endif
	next
	warning('Unrecognized symbol "' & $key & '"')
	$unused &= $key
endfunc

func warning(byref $msg)
	if $status = 2 then ; parsing still in progress
		message("Warning on frame " & $frame & ": " & $msg)
	else
		message("Warning: " & $msg)
	endif
	$warningcount += 1
endfunc

; find the number of digits for printing frame numbers evenly
func digits(byref $num)
	local $ndigits = 0, $result = $num+1
	while $result > 1
		$result /= 10
		$ndigits += 1
	wend
	return $ndigits
endfunc

; what to do when something in the input stream changed
func updatequeue(byref $command, byref $act, byref $id)
	if not $act and $id > 0 then
		$comqueue[ubound($comqueue)-1] = 'sleep(' & $framelength*$id & ')'
		redim $comqueue[ubound($comqueue)+1]
		$id = 0
	endif
	$comqueue[ubound($comqueue)-1] = $command
	redim $comqueue[ubound($comqueue)+1]
	$act = true
endfunc

; ------------------------------------------------------------------------------
; Keystroke sender functions
; ------------------------------------------------------------------------------
func inithotkeyfunc(byref $hotkey, byref $funcstring)
	hotkeyset($hotkey) ; deregister hotkey to avoid self recursion
	send($hotkey); pass the hotkey through to the running app
	hotkeyset($hotkey, $funcstring) ; reregister hotkey
	controlsend("", "", "", "", 0) ; supposedly prevents stuck keys
endfunc

func stopplayback()
	inithotkeyfunc($stopkey, "stopplayback")
	if $play then $stop = true
endfunc

func playback()
	inithotkeyfunc($startkey, "playback")
	if $targetwindow and not winactive($targetwindow) then
		message('Target window "' & $targetwindow & '" must be active to begin playback.')
		return
	endif
	if $status < 4 or $stop then return
	if $play then
		$stop = true
		return
	endif
	$play = true
	setstatus(5)
	message("Starting playback...")
	for $i = 1 to ubound($comqueue)
		execute($comqueue[$i-1])
		guictrlsetdata($progress, $i/ubound($comqueue)*100)
		if $stop then
			for $p = 2 to $nplayers+1
				for $k = 0 to $nkeys-1
					send("{" & $gamekeys[$k][$p] & " up}") ; release any and all gamekeys
				next
			next
			$play = false
			$stop = false
			setstatus(4)
			message("User canceled playback.")
			return
		elseif $targetwindow and not winactive($targetwindow) then
			$play = false
			$stop = false
			setstatus(4)
			message("Stopped playback because target window lost focus.")
			return
		endif
	next
	$play = false
	message("Done.")
	setstatus(4)
endfunc
