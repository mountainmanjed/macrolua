--[[
FBA-rr input display script
written by Dammit
last update 5/11/2010

This script must be reloaded when you change games.
]]

local c={        --colors:
on1 =0xffff00ff, --pressed: yellow inside
on2 =0x000000ff, --pressed: black border
off1=0x00000000, --unpressed: clear inside
off2=0x00000033  --unpressed: mostly-clear black border
}

inp={}
dofile("input-modules.lua","r")

local function inputsmatch(table1,table2) --check if all keys of table1 are also keys of table2
	local checklist={}
	for k,v in pairs(table1) do
		checklist[k]=false
		for l,u in pairs(table2) do
			if k==l then
				checklist[k]=true
				break
			end
		end
	end
	for k,v in pairs(checklist) do
		if v==false then
			return false
		end
	end
	return true
end

local module
for k,v in pairs(inp) do --find out which module is the correct one
	if inputsmatch(v,joypad.get(1)) then
		module=k
		break
	end
end

local function inpdisplay(m)
	if not module then
		gui.text(0,0,"I don't know how to display this game's input.\nPlease add a module for it!")
	else
		for k,v in pairs(joypad.get(1)) do
			if m[k] then --display only defined inputs
				local color1,color2=c.on1,c.on2
				if m[k][4] then --analog
					gui.text(m[k][2]+m[k][4],m[k][3]+m[k][5],v,color1,color2) --display the value
				else --digital
					if v==0 then color1,color2=c.off1,c.off2 end --button not pressed
				end
				gui.text(m[k][2],m[k][3],m[k][1],color1,color2)
			end
		end
	end
end

function displayfunc()
	inpdisplay(inp[module])
end

gui.register(function()
	inpdisplay(inp[module])
end)
