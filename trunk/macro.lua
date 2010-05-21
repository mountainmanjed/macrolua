--[[
MacroLua: macro player/recorder for emulators with Lua
http://code.google.com/p/macrolua/
written by Dammit

User: Do not edit this file.
This script depends on macro-options.lua and macro-modules.lua.
See macro-readme.html for help and instructions.
]]

----------------------------------------------------------------------------------------------------
--[[ Prepare the script for the current emulator and the game. ]]--

local version = "1.05, 5/21/2010"
print("MacroLua v"..version)
dofile("macro-options.lua","r")
dofile("macro-modules.lua","r")
if fba and showfbainput then dofile("input-display.lua","r") end

emu=emu or gens --gens doesn't have the "emu" table of functions

if not savestate.registersave or not savestate.registerload then --registersave/registerload are unavailable in some emus
	print("With this emulator, loading a save during a macro will cause desync.")
end

local guiregisterhax = false --exploit that allows checking for hotkeys while paused
if fba or FCEU or pcsx then guiregisterhax = true end

if input.registerhotkey then
	print("Press Lua hotkey 1 for playback, hotkey 2 for recording, or hotkey 3 to convert to one-line-per-frame format.") print()
else
	print("Press",playkey,"for playback and",recordkey,"for recording.") print()
end

local moduleerror={}
local function inputsmatch(table1,table2) --crude method of matching the game to a module
	local checklist1,checklist2={},{}
	for b in pairs(table2) do checklist2[b]=false end
	for _,a in ipairs(table1) do
		checklist1[a[2]]=false
		for b in pairs(table2) do
			if a[2]==string.gsub(b,"P%d+","P#") then --Deal with FBA's annoying input names.
				checklist1[a[2]],checklist2[b]=true,true
			end
		end
	end
	for _,v in pairs(checklist1) do
		if not v then
			table.insert(moduleerror,"No game input for this module entry: ".._)
			return false
		end
	end
	for _,v in pairs(checklist2) do
		if not v and string.find(_,"P%d+") then --no need to map every useless switch in FBA
			table.insert(moduleerror,"No module entry for this game input: ".._)
			return false
		end
	end
	return true
end

local module,nplayers
local function findmodule()
	for k,v in ipairs(single) do
		if v[1] then
			nplayers=v[2]
			module=v[3]
			return
		end
	end
	error("No module available for this emulator.",0)
end

local function findFBAmodule()
	module=nil
	for k,v in ipairs(FBA) do --Find out which module is the correct one.
		if inputsmatch(v[3],joypad.get(1)) then --This function should go by ROM name instead of inputsmatch().
			print(v[1],"game detected.")
			nplayers=v[2]
			module=v[3]
			return
		else table.insert(moduleerror,v[1].." module does not match this game's inputs.") table.insert(moduleerror,"")
		end
	end
	for k,v in pairs(moduleerror) do print(v) end
	error("No game loaded or unknown controls or wrong formatted control module.",0)
end

if not fba then
	findmodule()
elseif not emu.registerstart then --registerstart is wanted in FBA
	findFBAmodule()
else
	emu.registerstart(function() findFBAmodule() end)
end

local hold,press={},{}
for p=1,nplayers do hold[p],press[p]={},{} end

----------------------------------------------------------------------------------------------------
--[[ Set up the playback variables and functions. ]]--

local frame,nextkey,inputstream,macrosize,inbrackets,bracket,player,stateop,stateslot

local statekeys={["$"]="save",["&"]="load",}

local function updatestream(p,f) --Inject holds and presses into the inputstream.
	for _,v in ipairs(module) do
		if hold[p][v[1]] or press[p][v[1]] then
			if not inputstream[f] then inputstream[f]={} end
			if not inputstream[f][p] then inputstream[f][p]="" end
			inputstream[f][p]=inputstream[f][p]..v[1]
		end
	end
	press[p]={} --Clear keypresses at the end of the frame.
end

local function warning(msg,expr)
	if expr==true then
		if not macrosize then print("Warning on frame",frame..":",msg)
		else print("Warning:",msg) end
		return true
	end
end

local funckeys={
	["."]=function()
		frame=frame+1
		if not inbrackets then for p=1,nplayers do updatestream(p,frame) end
		else updatestream(player,frame)
		end
	end,
	
	["_"]=function() nextkey=hold end,
	
	["^"]=function() nextkey=nil end,
	
	["*"]=function() hold[player]={} end,
	
	["+"]=function()
		if warning("cannot use '+' in brackets",inbrackets) then return end
		if warning("used '+' but already controlling player 1",player==1) then return end
		player=1
	end,
	
	["-"]=function()
		if warning("cannot use '-' in brackets",inbrackets) then return end
		if warning("used '-' but already controlling player "..player,player>=nplayers) then return end
		player=player+1
	end,
	
	["<"]=function()
		if warning("tried to open brackets but they were already open",inbrackets) then return end
		inbrackets=true
		player=1
		bracket[0]=frame
	end,
	
	["/"]=function()
		if warning("can only use '/' in brackets",not inbrackets) then return end
		if warning("used '/' but already controlling player "..player,player>=nplayers) then return end
		bracket[player]=frame
		player=player+1
		frame=bracket[0]
	end,
	
	[">"]=function()
		if warning("tried to close brackets but they were not open",not inbrackets) then return end
		bracket[player]=frame
		local highest=bracket[0]
		for p=1,nplayers do
			if not bracket[p] then bracket[p]=bracket[0] end
			if bracket[p]>highest then
				highest=bracket[p]
			end
		end
		for p=1,nplayers do
			while bracket[p]<=highest do
				updatestream(p,bracket[p])
				bracket[p]=bracket[p]+1
			end
		end
		frame=highest
		bracket={}
		inbrackets=false
		player=1
	end,
}

local function processframe(command)
	local op,slot,tempframe
	command=string.gsub(command,"([%$&])(%d+)",function(o,s) --Clear save/load strings first.
		op,slot,tempframe=o,s,frame --The frame number is not correct until the rest of the frame is parsed.
		return ""
	end)
	nextkey=press
	command=string.gsub(command,"(.)",function(c) --Deal with each key individually.
		for k in pairs(funckeys) do --special keys
			if c==k then
				funckeys[k]()
				return ""
			end
		end
		for _,v in ipairs(module) do --game keys
			if c==v[1] then
				if not nextkey then --release
					hold[player][v[1]]=nil
				else --press or hold
					nextkey[player][v[1]]=true
				end
				nextkey=press
				return ""
			end
		end
	end)
	if tempframe then --Resolve save/load ops with the now-correct frame number.
		stateop[frame]=statekeys[op]
		stateslot[frame]=slot
	end
	warning("'"..command.."' is unrecognized",command~="") --invalid keys
	return command
end

----------------------------------------------------------------------------------------------------
--[[ Read, interpret, and perform cleanup on the playback macro. ]]--

local function parse(macro)
	local file=io.input(string.gsub(path,"\\","/")..macro)
	local m=file:read("*a") --Open and read the file.
	file:close() --Close the file.
	m=string.gsub(m,"#.-\n","") --Remove lines commented with "#".
	m=string.gsub(m,"#.*","") --Remove the last line commented with "#".
	m=string.upper(m) --Case desensitize.
	if framemame then
		m=string.gsub(m,"A[CS]%s?%d+","") --Remove frameMAME audio commands.
		m=string.gsub(m,"AR%s?%d+%s%d+","") --Remove frameMAME audio commands.
		m=string.gsub(m,"A[M!]","") --Remove frameMAME audio commands.
	end
	m=string.gsub(m,"(!.*)","") --Remove everything after the first "!".
	m=string.gsub(m,"W%s?(%d+)",function(n) return string.rep(".",n) end) --Expand waits into dots.
	while string.find(m,"%b()%s?%d+") do --Recursively..
		m=string.gsub(m,"(%b())%s?(%d+)",function(s,n) --..expand ()n loops..
			s=string.sub(s,2,-2).."," --..and remove the parentheses.
			return string.rep(s,n)
		end)
	end
	m=string.gsub(m,"[,%s\t\n]","") --Remove spacing/readability characters.

	frame,macrosize,player=0,nil,1 --Initialize parameters.
	inputstream,stateop,stateslot={},{},{}
	inbrackets,bracket=false,{}

	m=string.gsub(m,"(.-[%.>])",function(c) return processframe(c) end) --Process each frame.
	macrosize=frame

	warning("input left unprocessed: "..m,m~="") --Check for anything left unresolved.

	for p=1,nplayers do --Check for keys still held.
		local leftovers=""
		for k in pairs(hold[p]) do
			leftovers=leftovers..k
		end
		if warning("player "..p.." was left holding "..leftovers,leftovers~="") then hold[p]={} end
	end

	if warning("brackets were left open.",inbrackets) then processframe(">") end --Check if brackets still open.

	frame=0
end

----------------------------------------------------------------------------------------------------
--[[ Set up the recording variables and functions. ]]--

local recframe,recinputstream
local waitstring,longstring="",""
if longwait > 0 then for i=1,longwait do waitstring=waitstring.."%." end end
if longline > 0 then for i=1,longline do longstring=longstring.."[^\n]" end end

local function finalize(t)
	if recframe==0 then
		print("Stopped recording after zero frames.") print()
		return
	end
	
	--Determine how many players were active.
	local np=nplayers
	for p=np,1,-1 do
		local active=false
		for f=1,recframe do
			active=t[f] and t[f][p]
			if active then break end
		end
		if active then break
		else np=np-1
		end
	end
	if np==0 then
		print("Stopped recording: No input was entered in",recframe,"frames.") print()
		return
	end
	
	--Substitute _holds and ^releases for long press sequences.
	if longpress > 0 then
		for p=1,np do
			for _,v in ipairs(module) do
				local hold,release,pressed,oldpressed=0,0,false,false
				for f=1,recframe+1 do
					pressed=t[f] and t[f][p] and string.find(t[f][p],v[1])
					if pressed and not oldpressed then hold=f end
					if not pressed and oldpressed then release=f
						if release-hold>=longpress then --only hold if the press is long
							if not t[release] then t[release]={} end
							if not t[release][p] then t[release][p]="" end
							if f==recframe+1 then recframe=f end --add another frame to process the release if necessary
							for fr=hold,release do t[fr][p]=string.gsub(t[fr][p],v[1],"") end --take away the presses
							t[hold][p]=t[hold][p].."_"..v[1] --add the hold at the beginning
							t[release][p]=t[release][p].."^"..v[1] --add the release at the end
						end
					end
					oldpressed=pressed
				end
			end
		end
	end
	
	--Compose the text in bracket format.
	local text="# "..os.date().."\n\n"
	local sep="<"
	for p=1,np do
		local str=sep.." # Player "..p.."\n"
		for f=1,recframe do
			if t[f] and t[f][p] then str=str..t[f][p] end
			str=str.."."
		end
		text=text..str.."\n\n"
		sep="/"
	end
	t=nil
	text=text..">\n"
	
	--If only Player 1 is active, get rid of the brackets.
	if not string.find(text,"\n/") then
		text=string.gsub(text,"< # Player 1\n","")
		text=string.gsub(text,"\n\n>","")
	end
	
	--Collapse long waits into W's.
	if longwait > 0 then
		text=string.gsub(text,"([\n%.])("..waitstring.."+)",function(c,n)
			return c.."W"..string.len(n)..","
		end)
	end
	text=string.gsub(text,",\n","\n") --Remove trailing commas.
	
	--Break up long lines.
	if longline > 0 then
		local startpos,endpos=0,0
		local before,after=string.sub(text,1,endpos),string.sub(text,endpos+1)
		while string.find(after,"\n("..longstring..".-),") do --Search for a long stretch w/o breaks.
			text=before..string.gsub(after,"\n("..longstring..".-),",function(line) --Insert a break after the next comma.
				return "\n"..line..",\n"
			end,1) --Do this once per search.
			startpos,endpos=string.find(text,"\n("..longstring..".-),",endpos) --Advance the start of the next search.
			before,after=string.sub(text,1,endpos),string.sub(text,endpos+1)
		end
	end
	
	--Save the text.
	local filename=os.date("%Y-%m-%d_%H-%M-%S")..".mis" --this should include the ROM name somehow
	local file=io.output(string.gsub(path,"\\","/")..filename)
	file:write(text) --Write to file.
	file:close() --Close the file.
	print("Recorded",recframe,"frames to",filename..".") print()
end

----------------------------------------------------------------------------------------------------
--[[ Set up the variables and functions for user control of playback and recording. ]]--

local playing,recording,pausenow=false,false,false

local function bulletproof(active,f1,f2,t1,t2) --1=current, 2=loaded
	if not active then return false end
	if f1==0 then return true end --loading on 0th frame is always OK
	if not t2 then
		print("Error: loaded state has no macro data")
		return false
	end
	for f=1,f2 do
		if type(t1[f])~=type(t2[f]) then --one has data in a table, the other is empty/nil
			print("Error: loaded macro does not match current macro on frame",f)
			return false
		elseif t1[f] and t2[f] then --both are tables with nonblank data
			for p=1,nplayers do
				if t1[f][p]~=t2[f][p] then
					print("Error: loaded macro does not match current macro on frame",f)
					return false
				end
			end
		end
	end
	print("Resumed from frame",f2) --no errors
	return true
end

if savestate.registersave and savestate.registerload then --registersave/registerload are unavailable in some emus

	savestate.registersave(function(slot)
		if playing then print("Saved progress to slot",slot,"while playing frame",frame) end
		if recording then print("Saved progress to slot",slot,"while recording frame",recframe) end
		if playing or recording then return frame,inputstream,macrosize,recframe,recinputstream end
	end)
	
	savestate.registerload(function(slot)
		if not playing and not recording then return end
		if playing then print("Loaded from slot",slot,"while playing frame",frame) end
		if recording then print("Loaded from slot",slot,"while recording frame",recframe) end
		local tmp={}
		tmp.frame,tmp.inputstream,tmp.macrosize,tmp.recframe,tmp.recinputstream=savestate.loadscriptdata(slot)
		playing=bulletproof(playing,frame,tmp.frame,inputstream,tmp.inputstream)
		recording=bulletproof(recording,recframe,tmp.recframe,recinputstream,tmp.recinputstream)
		frame         =tmp.frame          or frame
		inputstream   =tmp.inputstream    or inputstream
		macrosize     =tmp.macrosize      or macrosize
		recframe      =tmp.recframe       or recframe
		recinputstream=tmp.recinputstream or recinputstream
	end)
	
end

local function dostate(f)
	if stateop[f+1] then
		if savestate.create and savestate[stateop[f+1]] then
			savestate[stateop[f+1]](savestate.create(stateslot[f+1])) return
		elseif savestate[stateop[f+1]] then
			savestate[stateop[f+1]](stateslot[f+1]) return
		end
		warning("cannot do savestates with Lua in this emulator",true)
	end
end

local function playcontrol()
	if not playing then
		parse(playbackfile)
		dostate(frame)
		if not warning("Macro is zero frames long.",macrosize==0) then
			print("Now playing",playbackfile,"("..macrosize,"frames)")
			playing=true
		end
	else 
		playing=false
		inputstream=nil
		print("Canceled playback on frame",frame) print()
	end
end

local function reccontrol()
	if not recording then
		recording=true
		recframe=0
		recinputstream={}
		print("Started recording.")
	else 
		recording=false
		finalize(recinputstream)
	end
end

local function dumpinputstream()
	if not playing then
		parse(playbackfile)
		if not warning("Macro is zero frames long.",macrosize==0) then
			local dump=""
			for p=1,nplayers do --header row
				dump=dump.."|"
				for _,v in ipairs(module) do
					dump=dump..v[1]
				end
			end
			dump=dump.."|\r\n"
			for f=1,macrosize do --frame rows
				for p=1,nplayers do
					dump=dump.."|"
					for _,v in ipairs(module) do
						if inputstream[f] and inputstream[f][p] and string.find(inputstream[f][p],v[1]) then
							dump=dump..v[1]
						else
							dump=dump.."."
						end
					end
				end
				dump=dump.."|\r\n"
			end
			local filename=string.gsub(playbackfile,"%....$","")
			filename=filename.."-inputstream.txt"
			local file=io.output(string.gsub(path,"\\","/")..filename)
			file:write(dump) --Write to file.
			file:close() --Close the file.
			print("Converted",playbackfile,"to",filename.." ("..macrosize,"frames)") print()
		end
	end
end

emu.registerexit(function() --Attempt to save if the script exits while recording
	if recording then recording=false finalize(recinputstream) end
end)

local oldplaykey, oldrecordkey, olddumpkey

if input.registerhotkey then --use registerhotkey if available
	input.registerhotkey(1,function()
		playcontrol()
	end)

	input.registerhotkey(2,function()
		reccontrol()
	end)

	input.registerhotkey(3,function()
		dumpinputstream()
	end)
elseif guiregisterhax then --otherwise try to exploit the constantly running gui.register
	gui.register(function()
		if fba and showfbainput then displayfunc() end

		local nowplaykey=input.get()[playkey]
		if nowplaykey and not oldplaykey then
			playcontrol()
		end
		oldplaykey=nowplaykey

		local nowrecordkey=input.get()[recordkey]
		if nowrecordkey and not oldrecordkey then
			reccontrol()
		end
		oldrecordkey=nowrecordkey

		local nowdumpkey=input.get()[inputstreamkey]
		if nowdumpkey and not olddumpkey then
			dumpinputstream()
		end
		olddumpkey=nowdumpkey
	end)
end

----------------------------------------------------------------------------------------------------
--[[ Perform playback and check for user input before the frame. ]]--

emu.registerbefore(function()
	if not input.registerhotkey and not guiregisterhax then --as a last resort, check for hotkeys the hard way
		local nowplaykey=input.get()[playkey]
		if nowplaykey and not oldplaykey then
			playcontrol()
		end
		oldplaykey=nowplaykey

		local nowrecordkey=input.get()[recordkey]
		if nowrecordkey and not oldrecordkey then
			reccontrol()
		end
		oldrecordkey=nowrecordkey

		local nowdumpkey=input.get()[dumpkey]
		if nowdumpkey and not olddumpkey then
			dumpinputstream()
		end
		olddumpkey=nowdumpkey
	end

	if playing then
		frame=frame+1
		dostate(frame)
		if not inputstream[frame] then inputstream[frame]={} end
		for p=1,nplayers do if not inputstream[frame][p] then inputstream[frame][p]="" end end
		if fba then --In fba, joypad.set is called once without a player number.
			local i={}
			--local i=joypad.getdown() --This should allow lua+user input but it makes keys never get released
			for p=1,nplayers do
				for _,v in ipairs(module) do
					local u=string.gsub(v[2],"P#","P"..p)
					if string.find(inputstream[frame][p],v[1]) then i[u]=1 end
				end
			end
			joypad.set(i)
		else --In other emus, joypad.set is called separately for each player.
			for p=1,nplayers do
				local i=joypad.getdown(p) --This allows lua+user input
				for _,v in ipairs(module) do
					if string.find(inputstream[frame][p],v[1]) then i[v[2]]=true end
				end
				joypad.set(p,i)
			end
		end
		if frame>macrosize then
			playing=false
			inputstream=nil
			print("Macro finished playing.") print()
			if pauseafterplay then pausenow=true end
		end
	end
	
end)

----------------------------------------------------------------------------------------------------
--[[ Perform recording and print status after the frame. ]]--

emu.registerafter(function() --recording is done after the frame, not before, to catch input from playing macros
	if recording then
		recframe=recframe+1
		for p=1,nplayers do
			for _,v in ipairs(module) do
				local u=string.gsub(v[2],"P#","P"..p)
				if joypad.get(p)[u]==1 and not (p>1 and u==v[2]) or joypad.get(p)[u]==true then
					if not recinputstream[recframe] then recinputstream[recframe]={} end
					if not recinputstream[recframe][p] then recinputstream[recframe][p]="" end
					recinputstream[recframe][p]=recinputstream[recframe][p]..v[1]
				end
			end
		end
	end

	if playing then pmesg="macro playing: "..frame.."/"..macrosize end
	if recording then rmesg="macro recording: "..recframe end
	if playing and not recording then emu.message(pmesg) end
	if recording and not playing then emu.message(rmesg) end
	if playing and recording then emu.message(pmesg.."   "..rmesg) end
end)

----------------------------------------------------------------------------------------------------
--[[ Handle pausing in the while true loop. ]]--

while true do
	if pausenow then emu.pause() end
	pausenow=false
	emu.frameadvance()
end