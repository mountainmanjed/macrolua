local $appname = "TranScripter"
local $version = "1.0"
local $verdate = "7/17/2010"
; Written by Dammit
; http://macrolua.googlecode.com/

opt("mustdeclarevars", 1)

local $configfile = "transcripter.ini"

; ------------------------------------------------------------------------------
; mednafen keymaps and mcm formats
; ------------------------------------------------------------------------------
local $mcm[6][2] = [ _ ; mcm consoles: type, players
	["lynx",  1], _
	["wswan", 1], _
	["ngp",   1], _
	["pce",   5], _
	["pcfx",  2], _
	["nes",   4] _
] ;med-rr 1.1 won't run gb, gba, sms or gg games

local $lynx[9][4] = [ _ ; mcm keymaps: description, symbol, byte, bit
	["down",     "D", 1, 7], _
	["up",       "U", 1, 6], _
	["right",    "R", 1, 5], _
	["left",     "L", 1, 4], _
	["option 1", "3", 1, 3], _
	["option 2", "4", 1, 2], _
	["B",        "2", 1, 1], _
	["A",        "1", 1, 0], _
	["start",    "S", 2, 4] _
]
local $wswan[11][4] = [ _
	["Y left",  "4", 1, 7], _
	["Y down",  "2", 1, 6], _
	["Y right", "6", 1, 5], _
	["Y up",    "8", 1, 4], _
	["X left",  "L", 1, 3], _
	["X down",  "D", 1, 2], _
	["X right", "R", 1, 1], _
	["X up",    "U", 1, 0], _
	["B",       "Z", 2, 6], _
	["A",       "Y", 2, 5], _
	["start",   "S", 2, 4] _
]
local $ngp[7][4] = [ _
	["up",     "U", 1, 0], _
	["down",   "D", 1, 1], _
	["left",   "L", 1, 2], _
	["right",  "R", 1, 3], _
	["A",      "1", 1, 4], _
	["B",      "2", 1, 5], _
	["option", "O", 1, 6] _
]
local $pce[13][4] = [ _
	["left",   "L", 1, 7], _
	["down",   "D", 1, 6], _
	["right",  "R", 1, 5], _
	["up",     "U", 1, 4], _
	["I",      "1", 1, 0], _
	["II",     "2", 1, 1], _
	["III",    "3", 2, 0], _
	["IV",     "4", 2, 1], _
	["V",      "5", 2, 2], _
	["VI",     "6", 2, 3], _
	["run",    "R", 1, 3], _
	["select", "S", 1, 2], _
	["mode",   "M", 2, 4] _
]
local $pcfx = $pce ;assumed same as pce, needs confirmation
local $nes[8][4] = [ _
	["up",     "U", 1, 0], _
	["down",   "D", 1, 1], _
	["left",   "L", 1, 2], _
	["right",  "R", 1, 3], _
	["A",      "1", 1, 4], _
	["B",      "2", 1, 5], _
	["select", "@", 1, 6], _
	["start",  "S", 1, 7] _
]

; ------------------------------------------------------------------------------
; TranScripter ini parsing
; ------------------------------------------------------------------------------
if not fileexists($configfile) then
	msgbox(0x30, $configfile & " error", "Config file '" & $configfile & "' does not exist.")
	exit
endif

local $startframe = iniread($configfile, "settings", "start frame", "")
local $rec = iniread($configfile, "settings", "movie file", "")
local $mis = iniread($configfile, "settings", "script file", "")
local $bak = execute(iniread($configfile, "settings", "create backup", true))
local $truncate = execute(iniread($configfile, "settings", "truncate excess", true))
local $showwarnings = execute(iniread($configfile, "settings", "show warnings", true))
local $maxwarnings = iniread($configfile, "settings", "max warnings", 20)

local $file = fileopen($rec, 0)
filesetpos($file, 0x74, 0)
local $t = findtype(fileread($file, 5))
fileflush($file)
local $gamekeys = eval($mcm[$t][0]), $nplayers = $mcm[$t][1], $nkeys = ubound($gamekeys)
local $bpp = findbpp($t)
local $bpf = $nplayers * $bpp + 1

local $reclength = (filegetsize($rec)-0x100)/$bpf

select
case not ($startframe == int($startframe) and $startframe > -1)
	msgbox(0x30, $configfile & " error", "'start frame' (" & $startframe & ") must be a non-negative integer.")
	exit
case not fileexists($rec)
	msgbox(0x30, $configfile & " error", "'movie file' (" & $rec & ") does not exist.")
	exit
case not stringright($rec,3) = "mcm"
	msgbox(0x30, $configfile & " error", "'movie file' (" & $rec & ") must be an .mcm.")
	exit
case not fileexists($mis)
	msgbox(0x30, $configfile & " error", "'script file' (" & $mis & ") does not exist.")
	exit
case ($reclength < $startframe)
	msgbox(0x30, $configfile & " error", _
		"'start frame' (" & $startframe & ") exceeds the framelength of the movie file (" & $reclength & ").")
	exit
endselect

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
	["-",         "pnext()"] _
]

local $status = 0, $l = @crlf, $framemame = false, $showlinenumbers = false, $warningstring = "", $useF_B = true
local $macrosize, $warningcount, $player, $nextkey, $unused, $frame, $line, $bracket[$nplayers+1], $inbrackets, _
	$press[$nplayers][$nkeys], $hold[$nplayers][$nkeys], $inputstream[1][$nplayers][$nkeys], $base

local $viewarray[5][2] = [ _
	[      "Raw string", ""], _
	["Processed string", ""], _
	[    "Input stream", ""], _
	[    "Delta stream", ""], _
	[   "Command queue", ""] _
]

filesetpos($file, 0x00, 0)
$base = fileread($file, 0x100 + $startframe*$bpf)
fileclose($file)

loadscript($mis)
if $warningcount > 0 and $showwarnings then msgbox(0x30, $warningcount & " warnings", $warningstring)
if not ($status = 4) then exit

if $bak then filecopy($rec, $rec & ".backup", 1)
if $truncate then
	$file = fileopen($rec, 2)
	filewrite($file, $base & $viewarray[4][1])
else
	$file = fileopen($rec, 1)
	filesetpos($file, 0x100 + $startframe*$bpf, 0)
	filewrite($file, $viewarray[4][1])
endif
fileclose($file)

; ------------------------------------------------------------------------------
; TranScripter functions
; ------------------------------------------------------------------------------
func findtype(byref $id) ; find the console type
	for $k = 0 to ubound($mcm)-1
		if stringinstr($id, $mcm[$k][0]) then return($k)
	next
	msgbox(0x30, "Error", "Can't determine console type from .mcm header.")
	exit
endfunc

func findbpp(byref $t) ; find the bytes per port/player
	local $b = 0
	for $k = 0 to ubound($gamekeys)-1
		if $gamekeys[$k][2] > $b then $b = $gamekeys[$k][2]
	next
	return $b
endfunc

func message(byref $msg)
	msgbox(0x30, "Script error", $msg)
endfunc

func setstatus(byref $s)
	$status = $s
endfunc

; ------------------------------------------------------------------------------
; Script parsing functions
; ------------------------------------------------------------------------------
func loadscript($file)
; ------------------------------------------------------------------------------
; Initialize parameters
	$frame = 0
	$line = 1
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
	;message("Loading " & $file & "...")

; Remove lines commented with "#"
	$macro = stringregexpreplace($macro, "#.*","")

; Remove frameMAME audio commands
	if $framemame then $macro = stringregexpreplace($macro, "[aA][mM!]|[aA][cCsS]\s?\d+|[aA][rR]\s?\d+\s\d+", "")

; Standardize line breaks
	$macro = stringregexpreplace($macro, "\r\n|\n", @cr)

; Remove the first "!" and everything after, and savestate ops
	$macro = stringregexpreplace($macro, "!.*|[$&]\s?\d+", "")

; Expand waits into dots
	while stringregexp($macro, "[wW]\s?\d+")
		local $execstring = stringregexpreplace($macro, "(.*?)([wW]\s?(\d+))(.*)", 'dots("\1","\2","\3","\4")')
		$macro = execute($execstring)
	wend

; Expand ()n loops
	while stringregexp($macro, "\(.*\)\s?\d+")
		local $execstring = stringregexpreplace($macro, "(.*)(\(.*?\))\s?(\d+)(.*)", 'loop("\1","\2","\3","\4")')
		$macro = execute($execstring)
	wend

; Remove commas, spaces and tabs
	$macro = stringregexpreplace($macro, "[, \t]", "")

; Final string dump
	$viewarray[1][1] = $macro 

; ------------------------------------------------------------------------------
; Process each character of the string to prepare the input stream array
	while $macro
		char(stringleft($macro, 1))
		$macro = stringtrimleft($macro, 1)
		if $warningcount >= $maxwarnings and $maxwarnings > 0 then
			;message("Error: Too many warnings" & $l)
			$warningstring &= $l & "Error: Too many warnings" & $l
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
		local $stillpressed = "", $stillheld = ""
		for $k = 0 to $nkeys-1
			if $press[$p][$k] = true then $stillpressed &= $gamekeys[$k][0] & " "
			if $hold[$p][$k] = true then $stillheld &= $gamekeys[$k][0] & " "
		next
		if $stillpressed then warning('Player ' & $p+1 & ' was left pressing without frame advance: ' & $stillpressed)
		if $stillheld then warning('Player ' & $p+1 & ' was left holding: ' & $stillheld)
	next

	if $unused then warning('Input left unprocessed: ' & $unused)

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
		$comdump &= chr(00) ; blank control byte
		$activity = false
		if $showlinenumbers then
			$inputdump &= stringformat("%" & $ndigits & "d", $f) & " "
			$deltadump &= stringformat("%" & $ndigits & "d", $f) & " "
		endif
		for $p = 0 to ubound($inputstream, 2)-1
			$inputdump &= "|"
			$deltadump &= "|"
			local $byte[$bpp]
			for $k = 0 to ubound($inputstream, 3)-1
				if $inputstream[$f][$p][$k] then
					$byte[$gamekeys[$k][2]-1] += 2^$gamekeys[$k][3]
					$inputdump &= $gamekeys[$k][1]
					if not $lastframe[$p][$k] then
						$deltadump &= "+"
						;updatequeue('send("{' & $gamekeys[$k][$p+2] & ' down}")', $activity, $idle)
					else
						$deltadump &= "."
					endif
					$lastframe[$p][$k] = true
				else
					$inputdump &= "."
					if $lastframe[$p][$k] then
						$deltadump &= "-"
						;updatequeue('send("{' & $gamekeys[$k][$p+2] & ' up}")', $activity, $idle)
					else
						$deltadump &= " "
					endif
					$lastframe[$p][$k] = false
				endif
			next
			for $b in $byte
				$comdump &= chr($b)
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
				;updatequeue('send("{' & $gamekeys[$k][$p+2] & ' up}")', $activity, $idle)
			else
				$deltadump &= " "
			endif
		next
	next
	$deltadump &= "|" & $l

#cs
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
#ce

	$viewarray[2][1] = $inputdump
	$viewarray[3][1] = $deltadump
	$viewarray[4][1] = $comdump
	;guictrlsetdata($progress, 0)
	setstatus(4)
	;$loadedfile = $file
	;$scripttimestamp = filegettime($loadedfile, 0, 1)
	;winsettitle($details, "", "Script analysis: " & $loadedfile)
	;message("Done loading script." & $l)

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
	if stringupper($key) == "F" and $useF_B then
		if mod($player, 2) == 0 then
			$key = "L"
		else
			$key = "R"
		endif
	elseif stringupper($key) == "B" and $useF_B then
		if mod($player, 2) == 0 then
			$key = "R"
		else
			$key = "L"
		endif
	endif
	for $k = 0 to $nkeys-1
		if stringupper($key) == $gamekeys[$k][1] then
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
	if $key == @cr then
		$line+=1
		return
	endif
	warning('Unrecognized symbol "' & $key & '"')
	$unused &= $key
endfunc

func warning(byref $msg)
	if $status = 2 then ; parsing still in progress
		;message("Warning on line " & $line & ", frame " & $frame & ": " & $msg)
		$warningstring &= "Warning on line " & $line & ", frame " & $frame & ": " & $msg & $l
	else
		;message("Warning: " & $msg)
		$warningstring &= "Warning: " & $msg & $l
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

#cs
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
#ce