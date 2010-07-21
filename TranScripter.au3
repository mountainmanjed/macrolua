local $appname = "TranScripter"
local $version = "1.01"
local $verdate = "7/20/2010"
; Written by Dammit
; http://macrolua.googlecode.com/

opt("mustdeclarevars", 1)

local $configfile = "transcripter.ini"

; ------------------------------------------------------------------------------
; mednafen keymaps and mcm formats
; ------------------------------------------------------------------------------
local $ymv[13][2] = [ _ ; ymv keymap: description, symbol (order is as given)
	["left",  "L"], _
	["right", "R"], _
	["up",    "U"], _
	["down",  "D"], _
	["start", "S"], _
	["A",     "4"], _
	["B",     "5"], _
	["C",     "6"], _
	["X",     "1"], _
	["Y",     "2"], _
	["Z",     "3"], _
	["L",     "7"], _
	["R",     "8"] _
]

local $mcm[5][2] = [ _ ; mcm consoles: type, players
	["lynx",  1], _
	["wswan", 1], _
	["ngp",   1], _
	["pce",   5], _
	["nes",   4] _
] ; med-rr 1.1 windows ver. won't run gb, gba, sms, gg, or pcfx games

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
	["Y down",  "5", 1, 6], _
	["Y right", "6", 1, 5], _
	["Y up",    "8", 1, 4], _
	["X left",  "L", 1, 3], _
	["X down",  "D", 1, 2], _
	["X right", "R", 1, 1], _
	["X up",    "U", 1, 0], _
	["B",       "2", 2, 6], _
	["A",       "1", 2, 5], _
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
	["I",      "6", 1, 0], _
	["II",     "5", 1, 1], _
	["III",    "4", 2, 0], _
	["IV",     "1", 2, 1], _
	["V",      "2", 2, 2], _
	["VI",     "3", 2, 3], _
	["run",    "@", 1, 3], _
	["select", "S", 1, 2], _
	["mode",   "M", 2, 4] _
]
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

local $file, $gamekeys, $nplayers, $nkeys, $bpp, $bpf, $reclength, $l, $base

; ------------------------------------------------------------------------------
; TranScripter ini parsing
; ------------------------------------------------------------------------------
if not fileexists($configfile) then
	msgbox(0x30, $configfile & " error", "Config file '" & $configfile & "' not found.")
	exit
endif

local $startframe = iniread($configfile, "settings", "start frame", "")
local $rec = iniread($configfile, "settings", "movie file", "")
local $mis = iniread($configfile, "settings", "script file", "")
local $bak = execute(iniread($configfile, "settings", "create backup", true))
local $truncate = execute(iniread($configfile, "settings", "truncate excess", true))
local $showwarnings = execute(iniread($configfile, "settings", "show warnings", true))
local $maxwarnings = iniread($configfile, "settings", "max warnings", 20)
local $type = stringright($rec,3)

select
case not ($startframe == int($startframe) and $startframe > -1)
	msgbox(0x30, $configfile & " error", "start frame ('" & $startframe & "') must be a non-negative integer.")
	exit
case not fileexists($rec)
	msgbox(0x30, $configfile & " error", "movie file ('" & $rec & "') not found.")
	exit
case not fileexists($mis)
	msgbox(0x30, $configfile & " error", "script file ('" & $mis & "') not found.")
	exit
endselect

switch $type
case "ymv"
	$gamekeys = $ymv
	$nplayers = 1
	$nkeys = ubound($gamekeys)
	$file = fileopen($rec, 0)
	$base = fileread($file)
	$reclength = ubound(stringregexp(stringtrimleft($base, stringinstr($base, "|0|")-1), "\n\|.*\|.*\|", 3))+1
	if stringinstr($base, @crlf) then
		$l = @crlf
	else
		$l = @lf
	endif
	if $truncate then
		$base = stringleft($base, stringinstr($base, "|0|", 0, $startframe+1)-1)
	else
		$base = stringinstr($base, "|0|", 0, $startframe+1)-1
	endif
case "mcm"
	$file = fileopen($rec, 0)
	filesetpos($file, 0x74, 0)
	local $systype = findtype(fileread($file, 5))
	fileflush($file)
	$gamekeys = eval($mcm[$systype][0])
	$nplayers = $mcm[$systype][1]
	$nkeys = ubound($gamekeys)
	$bpp = 0
	for $k = 0 to ubound($gamekeys)-1 ; bytes per port/player
		if $gamekeys[$k][2] > $bpp then $bpp = $gamekeys[$k][2]
	next
	$bpf = $nplayers * $bpp + 1 ; bytes per frame
	$reclength = (filegetsize($rec)-0x100)/$bpf
	if $truncate then
		filesetpos($file, 0x00, 0)
		$base = fileread($file, 0x100 + $startframe*$bpf)
	else
		$base = 0x100 + $startframe*$bpf
	endif
case else
	msgbox(0x30, $configfile & " error", "movie file ('" & $rec & "') must be an .mcm or .ymv.")
	exit
endswitch
fileclose($file)

if ($reclength < $startframe) then
	msgbox(0x30, $configfile & " error", _
		"start frame (" & $startframe & ") exceeds the framelength of the movie file (" & $reclength & ").")
	exit
endif

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

local $status = 0, $framemame = false, $warningstring = "", $useF_B = true
local $macrosize, $warningcount, $player, $nextkey, $unused, $frame, $line, $bracket[$nplayers+1], $inbrackets, _
	$press[$nplayers][$nkeys], $hold[$nplayers][$nkeys], $inputstream[1][$nplayers][$nkeys]

local $result = loadscript($mis)
if $warningcount > 0 and $showwarnings then msgbox(0x30, $warningcount & " warnings", $warningstring)
if not ($status = 4) then exit

if $bak then filecopy($rec, $rec & ".backup", 1)
if $truncate then
	$file = fileopen($rec, 2)
	filewrite($file, $base & $result) ;  if $truncate then getvartype($base) = "string"
else
	$file = fileopen($rec, 1)
	filesetpos($file, $base, 0) ; if not $truncate then getvartype($base) = "int"
	filewrite($file, $result)
endif
fileclose($file)

; ------------------------------------------------------------------------------
; TranScripter functions
; ------------------------------------------------------------------------------
func findtype(byref $id) ; find the console type
	for $k = 0 to ubound($mcm)-1
		if stringinstr($id, $mcm[$k][0]) then return($k)
	next
	msgbox(0x30, "Error", "Can't determine console type from '" & $rec & "' header.")
	exit
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
; Produce the string to be written to file from the input stream array
	local $comdump = ""

	switch $type
	case "ymv"
		for $f = 0 to ubound($inputstream, 1)-1
			$comdump &= "|0" ; blank control byte
			for $p = 0 to ubound($inputstream, 2)-1
				$comdump &= "|"
				for $k = 0 to ubound($inputstream, 3)-1
					if $inputstream[$f][$p][$k] then
						$comdump &= $gamekeys[$k][1]
					else
						$comdump &= "."
					endif
				next
			next
			$comdump &= "|" & $l
		next
	case "mcm"
		for $f = 0 to ubound($inputstream, 1)-1
			$comdump &= chr(00) ; blank control byte
			for $p = 0 to ubound($inputstream, 2)-1
				local $byte[$bpp]
				for $k = 0 to ubound($inputstream, 3)-1
					if $inputstream[$f][$p][$k] then $byte[$gamekeys[$k][2]-1] += 2^$gamekeys[$k][3]
				next
				for $b in $byte
					$comdump &= chr($b)
				next
			next
		next
	endswitch

	setstatus(4)
	return($comdump)

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
