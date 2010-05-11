--Define below input abbreviations and on-screen positions for each module.
--You may add new modules and comment out any inputs you never want displayed.

local x,dx,y,dy,i
--------------------------------------------------------------------------------
--Capcom 6-button fighters
x,dx=0x8,0x128
y,dy=0xd0,0
i={}
for n=0,1 do
	i["P"..(n+1).." Coin"]        ={"C", x+dx*n+0x00,y+dy*n+0x0}
	i["P"..(n+1).." Start"]       ={"S", x+dx*n+0x00,y+dy*n+0x8}
	i["P"..(n+1).." Up"]          ={"^", x+dx*n+0x18,y+dy*n+0x0}
	i["P"..(n+1).." Down"]        ={"v", x+dx*n+0x18,y+dy*n+0x8}
	i["P"..(n+1).." Left"]        ={"<", x+dx*n+0x10,y+dy*n+0x4}
	i["P"..(n+1).." Right"]       ={">", x+dx*n+0x20,y+dy*n+0x4}
	i["P"..(n+1).." Weak Punch"]  ={"LP",x+dx*n+0x30,y+dy*n+0x0}
	i["P"..(n+1).." Medium Punch"]={"MP",x+dx*n+0x38,y+dy*n+0x0}
	i["P"..(n+1).." Strong Punch"]={"HP",x+dx*n+0x40,y+dy*n+0x0}
	i["P"..(n+1).." Weak Kick"]   ={"LK",x+dx*n+0x30,y+dy*n+0x8}
	i["P"..(n+1).." Medium Kick"] ={"MK",x+dx*n+0x38,y+dy*n+0x8}
	i["P"..(n+1).." Strong Kick"] ={"HK",x+dx*n+0x40,y+dy*n+0x8}
end
table.insert(inp,i)

--------------------------------------------------------------------------------
--NeoGeo
x,dx=0x8,0xd0
y,dy=0xc8,0
i={}
for n=0,1 do
	i["P"..(n+1).." Coin"]    ={"C",x+dx*n+0x04,y+dy*n+0x0}
	i["P"..(n+1).." Start"]   ={"S",x+dx*n+0x00,y+dy*n+0x8}
	i["P"..(n+1).." Select"]  ={"s",x+dx*n+0x08,y+dy*n+0x8}
	i["P"..(n+1).." Up"]      ={"^",x+dx*n+0x20,y+dy*n+0x0}
	i["P"..(n+1).." Down"]    ={"v",x+dx*n+0x20,y+dy*n+0x8}
	i["P"..(n+1).." Left"]    ={"<",x+dx*n+0x18,y+dy*n+0x4}
	i["P"..(n+1).." Right"]   ={">",x+dx*n+0x28,y+dy*n+0x4}
	i["P"..(n+1).." Button A"]={"A",x+dx*n+0x38,y+dy*n+0x4}
	i["P"..(n+1).." Button B"]={"B",x+dx*n+0x40,y+dy*n+0x4}
	i["P"..(n+1).." Button C"]={"C",x+dx*n+0x48,y+dy*n+0x4}
	i["P"..(n+1).." Button D"]={"D",x+dx*n+0x50,y+dy*n+0x4}
end
table.insert(inp,i)

--------------------------------------------------------------------------------
--PGM
x,dx=0x10,0x70
y,dy=0xc0,0
i={}
for n=0,3 do
	i["P"..(n+1).." Coin"]    ={"C",x+dx*n+0x00,y+dy*n+0x0}
	i["P"..(n+1).." Start"]   ={"S",x+dx*n+0x00,y+dy*n+0x8}
	i["P"..(n+1).." Up"]      ={"^",x+dx*n+0x14,y+dy*n+0x0}
	i["P"..(n+1).." Down"]    ={"v",x+dx*n+0x14,y+dy*n+0x8}
	i["P"..(n+1).." Left"]    ={"<",x+dx*n+0x0c,y+dy*n+0x4}
	i["P"..(n+1).." Right"]   ={">",x+dx*n+0x1c,y+dy*n+0x4}
	i["P"..(n+1).." Button 1"]={"1",x+dx*n+0x2c,y+dy*n+0x4}
	i["P"..(n+1).." Button 2"]={"2",x+dx*n+0x34,y+dy*n+0x4}
	i["P"..(n+1).." Button 3"]={"3",x+dx*n+0x3c,y+dy*n+0x4}
	i["P"..(n+1).." Button 4"]={"4",x+dx*n+0x44,y+dy*n+0x4}
end
table.insert(inp,i)

--------------------------------------------------------------------------------
--Dungeons & Dragons (Capcom)
x,dx=0x24,0xc0
y,dy=0,0xd0
i={}
for n=0,3 do
	i["P"..(n+1).." Coin"]  ={"c",x+n%2*dx+0x00,y+math.floor(n/2)*dy+0x0}
	i["P"..(n+1).." Start"] ={"s",x+n%2*dx+0x00,y+math.floor(n/2)*dy+0x8}
	i["P"..(n+1).." Up"]    ={"^",x+n%2*dx+0x18,y+math.floor(n/2)*dy+0x0}
	i["P"..(n+1).." Down"]  ={"v",x+n%2*dx+0x18,y+math.floor(n/2)*dy+0x8}
	i["P"..(n+1).." Left"]  ={"<",x+n%2*dx+0x10,y+math.floor(n/2)*dy+0x4}
	i["P"..(n+1).." Right"] ={">",x+n%2*dx+0x20,y+math.floor(n/2)*dy+0x4}
	i["P"..(n+1).." Attack"]={"A",x+n%2*dx+0x30,y+math.floor(n/2)*dy+0x8}
	i["P"..(n+1).." Jump"]  ={"J",x+n%2*dx+0x38,y+math.floor(n/2)*dy+0x8}
	i["P"..(n+1).." Select"]={"S",x+n%2*dx+0x30,y+math.floor(n/2)*dy+0x0}
	i["P"..(n+1).." Use"]   ={"U",x+n%2*dx+0x38,y+math.floor(n/2)*dy+0x0}
end
table.insert(inp,i)

--------------------------------------------------------------------------------
--TMNT games (Konami)
x,dx=0x10,0x48
y,dy=0x20,0
i={}
for n=0,3 do
	i["Coin "..(n+1)]       ={"C",x+dx*n+0x00,y+dy*n+0x4}
	i["P"..(n+1).." Up"]    ={"^",x+dx*n+0x14,y+dy*n+0x0}
	i["P"..(n+1).." Down"]  ={"v",x+dx*n+0x14,y+dy*n+0x8}
	i["P"..(n+1).." Left"]  ={"<",x+dx*n+0x0c,y+dy*n+0x4}
	i["P"..(n+1).." Right"] ={">",x+dx*n+0x1c,y+dy*n+0x4}
	i["P"..(n+1).." Fire 1"]={"1",x+dx*n+0x2c,y+dy*n+0x4}
	i["P"..(n+1).." Fire 2"]={"2",x+dx*n+0x34,y+dy*n+0x4}
end
table.insert(inp,i)

--------------------------------------------------------------------------------
--After Burner II (Sega)
x,dx=0x80,0x10
y,dy=0xc8,0
i={
	["Coin 1"]    ={"C1", x+0x00,y+0x00},
	["Coin 2"]    ={"C2", x+0x00,y+0x08},
	["Start 1"]   ={"S1", x+0x00,y+0x10},
	["Left/Right"]={"L/R",x+0x10,y+0x00,dx,dy},
	["Up/Down"]   ={"U/D",x+0x10,y+0x08,dx,dy},
	["Throttle"]  ={"T",  x+0x10,y+0x10,dx,dy},
	["Vulcan"]    ={"V",  x+0x30,y+0x04},
	["Missile"]   ={"M",  x+0x30,y+0x0c}
}
table.insert(inp,i)

--------------------------------------------------------------------------------
--Street Fighter 1 (Capcom pre-'90s)
x,dx=0x8,0x128
y,dy=0xd0,0
i={}
for n=0,1 do
	i["P"..(n+1).." Start"]   ={"S", x+dx*n+0x00,y+dy*n+0x8}
	i["P"..(n+1).." Up"]      ={"^", x+dx*n+0x18,y+dy*n+0x0}
	i["P"..(n+1).." Down"]    ={"v", x+dx*n+0x18,y+dy*n+0x8}
	i["P"..(n+1).." Left"]    ={"<", x+dx*n+0x10,y+dy*n+0x4}
	i["P"..(n+1).." Right"]   ={">", x+dx*n+0x20,y+dy*n+0x4}
	i["P"..(n+1).." Button 1"]={"LP",x+dx*n+0x30,y+dy*n+0x0}
	i["P"..(n+1).." Button 2"]={"MP",x+dx*n+0x38,y+dy*n+0x0}
	i["P"..(n+1).." Button 3"]={"HP",x+dx*n+0x40,y+dy*n+0x0}
	i["P"..(n+1).." Button 4"]={"LK",x+dx*n+0x30,y+dy*n+0x8}
	i["P"..(n+1).." Button 5"]={"MK",x+dx*n+0x38,y+dy*n+0x8}
	i["P"..(n+1).." Button 6"]={"HK",x+dx*n+0x40,y+dy*n+0x8}
end
table.insert(inp,i)

--------------------------------------------------------------------------------
