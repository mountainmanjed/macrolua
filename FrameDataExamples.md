This is a guide to using Macrolua to find various kinds of frame data in fighting games. It's the same empirical process that you would have to follow to test on real hardware or with other forms of [tool-assistance](http://sonichurricane.com/?p=2157), but the savestates and precise timing of input in Macrolua makes it less tedious, and the way everything is written in a human-readable form makes the results easier to interpret.

These techniques require no special knowledge of the internal workings of the game, such as [memory addresses](http://tasvideos.org/EmulatorResources/RamSearch.html), or [hitboxes](http://code.google.com/p/mame-rr/wiki/Hitboxes), and can be adapted to any game. You only need to script the input and observe the result.



More examples may be added later.



&lt;hr /&gt;


# Getting started #

[Download Macrolua](http://code.google.com/p/macrolua/downloads/list), read up on the [usage](MacroLuaDocumentation.md), and set it up with the emulator.

## Downloads ##

Download the savestates and script files and use them with Macrolua to follow along on these exercises. The paths tell you where to put them at default emulator and Macrolua settings.
|emulator|savestate|script file|description|
|:-------|:--------|:----------|:----------|
|[mame-rr](http://code.google.com/p/mame-rr/)|[sta\ssf2t\7.sta](http://macrolua.googlecode.com/svn-history/r102/trunk/framedata/ssf2t/7.sta)|[macro\framedata-ssf2t.mis](http://macrolua.googlecode.com/svn-history/r104/trunk/framedata/framedata-ssf2t.mis)|Cammy vs. M.Bison, Fei-Long stage, Turbo 2 speed|
|mame-rr |[sta\sfa2\4.sta](http://macrolua.googlecode.com/svn-history/r102/trunk/framedata/sfa2/4.sta)|[macro\framedata-sfa2.mis](http://macrolua.googlecode.com/svn-history/r104/trunk/framedata/framedata-sfa2.mis)|Sodom vs. Akuma, Sodom stage, Normal speed|

## Methods ##

Any sources of inconsistency need to be excluded. It doesn't hurt to always use the same scripting style, and the same dummy in the same mode on the same stage. If you run into inconsistent results, those are the first variables you'll try to control anyway, so just take care of it at the beginning. (If the stage is randomly selected, you may want to use [cheat codes](http://www.mamecheat.co.uk/) to set the stage.)

In particular, [frameskip](http://combovid.com/?p=5002) needs to be disabled if it's in the game. If you try to collect data under its effect, not only will your numbers be inconsistent from trial to trial, but they will be lower than the true pre-skip values even if you average lots of trials. The nominal "Normal" settings aren't always without skipping, and some games have no skip-free option, but there may be cheat codes to disable frameskip. ([Here](http://www.mamecheat.co.uk/forums/viewtopic.php?f=4&t=4102) are some codes that work on SF2 Hyper Fighting and Super Turbo.) All of the tests here are with no frameskip unless noted otherwise.



&lt;hr /&gt;


# Examples #

## Startup ##

As the first example, let's examine Cammy's close standing MK in [ssf2t](http://maws.mameworld.info/maws/romset/ssf2t). To find startup, make player 1 attack and determine the maximum amount of time that can pass and still allow player 2 to block:

```
# cammy cl.MK (startup test)
&7 W10 5.W4,-_R,W10,^R! blocked
&7 W10 5.W5,-_R,W10,^R! hit
```

![http://img860.imageshack.us/img860/2977/ssf2tclmkblock.png](http://img860.imageshack.us/img860/2977/ssf2tclmkblock.png)

If no more than five frames pass before the opponent starts holding back, the attack is blocked. If there are six or more frames, the attack connects. (Remember that both dots and numerical `W` values advance frames.) This means there are five inactive frames before the first active frame.

Here we run into a small problem of how to define startup: You can either call it the number of pre-active frames, or the number up to the first active frame. It's a question of counting exclusively or inclusively. I will use the latter definition, pre-active plus one. Therefore, Cammy's cl.MK has a startup of 6.

## Frame advantage ##

Now let's find the frame advantage of this move, the time between the recovery of the attacker and victim. We can consider recovery complete when the player can jump, so determine the first frames that either player can input a jump:

```
# cammy cl.MK (frame+ test)
&7 W10 5.W28,U.W6,-U.! neither jump
&7 W10 5.W29,U.W6,-U.! both jump
```

Player 1 recovers first, and player 2 recovers seven frames later. Therefore, cl.MK has a frame advantage of +7. (If determining both at once is confusing, you can find the recovery of each player separately, then compare the results.)

To demonstrate the value of frame advantage, let's see what will link after this move. Repeating the startup experiment with Cammy's far standing MK shows that it also has a startup of 6. Since close MK is +7, this is a one-frame link:

```
# cammy cl.MK, far MK (link test)
&7 W10 5.W28,5.! far MK doesn't come out
&7 W10 5.W29,5.! far MK combos
&7 W10 5.W30,5.! far MK doesn't combo
```

![http://img190.imageshack.us/img190/3692/ssf2tfarmk.png](http://img190.imageshack.us/img190/3692/ssf2tfarmk.png)

Frame advantage can be further broken down into hit advantage or block advantage depending on how the opponent took the attack, but there's no difference in Street Fighter II.

## Active frames ##

Every attack has a particular number of frames that are capable of hitting. At one end of the scale are attacks with a single active frame, such as most throws, whereas many projectiles remain active until they leave the screen. Some moves, including all multi-hitting attacks, have multiple active phases that can have different hitboxes or other properties.

Now we'll determine the length of the active period in Cammy's close MK. The first frame it can hit was found to be 6, but the last frame can't be observed if the opponent gets hit by the early frames. To deal with this we'll put the opponent in an unhittable state for the first part of the active period by knocking down with a Cannon Drill/Spiral Arrow and having him get up into the cl.MK. (This is a simple example of a [meaty attack](http://sonichurricane.com/?p=171).)

The cl.MK must be performed at the earliest frame that it will connect on the rising opponent, and then the frame advantage of the meaty version must be found. The difference between the normal and meaty advantages, plus one, is the active period of the attack.

```
# cammy qcf+LK knockdown, walk up, meaty cl.MK (frame+ test)
&7 W10 D.DR._R.4.W84,^R, W40,5.! MK whiffs: too early
&7 W10 D.DR._R.4.W84,^R, W41,5.W28,U.W11,-U.! MK hits, neither jump
&7 W10 D.DR._R.4.W84,^R, W41,5.W29,U.W11,-U.! MK hits, both jump
```

The frame advantage of cl.MK with a maximum meaty setup is +12, while it was +7 normally. Therefore, the active period is (+12) - (+7) + 1 = 6 frames. (To understand why +1 is added, consider what happens with an attack with only one active frame: The difference between regular and meaty advantage is zero, but you know it has one active frame, so add one.)

Incidentally, the enormous frame advantage of the meaty cl.MK is enough to connect far HK as a one-frame link, though the spacing must not be too close, to avoid getting the close HK.

```
# cammy qcf+LK knockdown, walk up, meaty cl.MK, far HK (link test)
&7 W10 D.DR._R.4.W84,^R,W41, 5.W28,6.! far HK doesn't come out
&7 W10 D.DR._R.4.W84,^R,W41, 5.W29,6.! far HK combos
&7 W10 D.DR._R.4.W84,^R,W41, 5.W30,6.! far HK doesn't combo
```

![http://img838.imageshack.us/img838/9885/ssf2tfarhk.png](http://img838.imageshack.us/img838/9885/ssf2tfarhk.png)

Since it's a one-frame link and the lead-in frame advantage is +12, this also shows that the startup of far HK is 11.

## Recovery ##

The final phase of an attack is the recovery, after it has spent its potential to hit but before the player regains control. To determine it, find the total length of the attack and subtract the active and pre-active frames. The total length can be found by counting how much time it takes to whiff the attack before control is regained.

```
# cammy whiff cl.MK, jump (recovery test)
&7 W10 -U.W5,+5. W14,U.! whiff MK, no jump
&7 W10 -U.W5,+5. W15,U.! whiff MK, jump
```

![http://img10.imageshack.us/img10/894/ssf2tclmkwhiff.png](http://img10.imageshack.us/img10/894/ssf2tclmkwhiff.png)

(The opponent is jumping to avoid the kick, but has to stay close so that the close version comes out.) The total elapsed time until recovery is sixteen frames. 16 total - 6 active - 5 pre-active = 5 recovery frames. This verifies the frame data for Cammy's cl.MK (5 <font color='red'>6</font> 5) found by [T.Akiba](http://nki.combovideos.com/flame.html).

## Impact freeze ##

When any attack hits or is blocked, it causes both players to be briefly locked in place at the time of impact. This is known by various names: [impact freeze](http://sonichurricane.com/?p=1043), hitfreeze, hitstop, or hit pause. It's usually the same for all the attacks in a game, but Street Fighter Alpha series has more for heavier attacks and counterhits.

Hitfreeze can be determined by subtracting the total time for a connected attack from the time for a whiffed attack. The data has already been collected in our example: It took 30 frames for Cammy to jump after a hit, and 16 after a whiff. Therefore, there are 14 frames of hitfreeze.

Projectiles handle this differently. When a projectile hits, the victim suffers hitfreeze but the attacker does not. This means the hitfreeze is basically converted to longer hitstun for the victim and more frame advantage for the attacker.

## Hitstun ##

Hitstun is the period that the opponent loses control after taking the attack and is defenseless to further hits. The similar state after blocking is blockstun. Generally, the amount of hitstun or blockstun depends only on whether the attack is a light, medium or heavy normal, an air normal, or a special move. Strictly speaking, hitstun should exclude impact freeze.

To compute hitstun, start with the total time from the start of the attack up to the dummy's recovery, then subtract the attack's startup and the impact freeze. The total time was already found to be 37 frames in the frame advantage test. Subtract 6 startup and 14 hitfreeze for a hitstun of 17 frames. All ground medium attacks in ST have this hitstun.

Summary of Cammy's cl.MK frame data:
|![http://img684.imageshack.us/img684/4880/ssf2tcammyclmk1.png](http://img684.imageshack.us/img684/4880/ssf2tcammyclmk1.png)|![http://img840.imageshack.us/img840/3997/ssf2tcammyclmk2.png](http://img840.imageshack.us/img840/3997/ssf2tcammyclmk2.png)|![http://img830.imageshack.us/img830/3310/ssf2tcammyclmk3.png](http://img830.imageshack.us/img830/3310/ssf2tcammyclmk3.png)|
|:--------------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------|
|pre-active                                                                                                                 |active                                                                                                                     |recovery                                                                                                                   |startup                                                                                                                    |frame advantage                                                                                                            |impact freeze                                                                                                              |hitstun                                                                                                                    |
|5                                                                                                                          |6                                                                                                                          |5                                                                                                                          |6                                                                                                                          |+7 ~ +12                                                                                                                   |14                                                                                                                         |17                                                                                                                         |

## Charge requirements ##

Charge moves require the stick to be held in a certain direction for a certain period before they can be executed. We'll use the same SSF2T setup to test M.Bison/Vega's requirements. He's an interesting case because most of his moves require different amounts of charge:

```
# dictator _B,F+LK (charge test)
&7 W10 -_R,W77,^R.L.L4.! move doesn't come out
&7 W10 -_R,W78,^R.L.L4.! move comes out

# dictator _B,F+LP (charge test)
&7 W10 -_R,W59,^R.L.L1.! move doesn't come out
&7 W10 -_R,W60,^R.L.L1.! move comes out

# dictator _D,U+LK (charge test)
&7 W10 -_D,W59,^D.U.U4.! move doesn't come out
&7 W10 -_D,W60,^D.U.U4.! move comes out

# dictator _D,U+LP (charge test)
&7 W10 -_D,W60,^D.U.U1.! move doesn't come out
&7 W10 -_D,W61,^D.U.U1.! move comes out

# dictator super (charge test)
&7 W10 -_R,W69,^R.L.R.L.L4.! move doesn't come out
&7 W10 -_R,W70,^R.L.R.L.L4.! move comes out
```

![http://img96.imageshack.us/img96/2550/ssf2tnopscrusher.png](http://img96.imageshack.us/img96/2550/ssf2tnopscrusher.png)
![http://img190.imageshack.us/img190/3862/ssf2tpscrusher.png](http://img190.imageshack.us/img190/3862/ssf2tpscrusher.png)

Results:
|Scissor Kick|78 frames|
|:-----------|:--------|
|Psycho Crusher|60       |
|Headstomp   |60       |
|Devil's Reverse|61       |
|Knee Press Nightmare|70       |

(The reason why [T.Akiba](http://nki.combovideos.com/data.html#tame) had lower numbers and random success rates is there was no way to turn off frameskip.)

## Reversal timing ##

[Reversals](http://wiki.shoryuken.com/Super_Street_Fighter_2_Turbo#Reversals) are special moves input on the first frame after the player comes out of an uncontrollable state like hitstun, blockstun or knockdown. Using special moves with invulnerability as reversals is an important way to escape meaty attacks and other traps. If the move is executed too late, it's not a reversal and the player is vulnerable for at least one frame.

We'll again use the SSF2T setup to show that, in this game, sometimes it's impossible to get a reversal no matter how you time the input, thanks to turbo speed frameskip. For these tests, do not use the cheat code that eliminates frameskip. The speed here is Turbo 2, which is the same as Turbo 3 in the Japanese version, which is what they use in Japan.

Bison first knocks down Cammy with a c.HK slide, then times another c.HK to hit meaty as she wakes up. Cammy gets out of trouble with a reversal Thrust Kick/Cannon Spike:

```
&7 W12 -_R,W40,^R,_D6.W66,6.^D # knockdown slide, meaty slide
+W12,R.D.DR.4..5..6.! reversal F,D,DF+K
```

![http://img855.imageshack.us/img855/1011/ssf2treversal.png](http://img855.imageshack.us/img855/1011/ssf2treversal.png)

The Cammy player is pianoing the kick buttons (tapping them in sequence) to increase the chances that a press or release coincides with her wakeup frame.

It's also possible in Street Fighter II to use a normal throw as a reversal, though there won't be an on-screen message and it's not possible to use negative edge (button releases) to execute a throw. Furthermore, it only works against grounded attacks. It does work against Bison's slide:

```
&7 W12 -_R,W40,^R,_D6.W66,6.^D # knockdown slide, meaty slide
+W20,L6.! reversal throw
```

If this sequence of events is delayed by one frame, it's no longer possible for Cammy to perform the reversal:

```
&7 W13 -_R,W40,^R,_D6.W66,6.^D # knockdown slide, meaty slide (timing changed by one frame)
+W12?,R.D.DR.4..5..6.W100! reversal won't come out because of frameskip
```

![http://img121.imageshack.us/img121/2051/ssf2tnoreversal.png](http://img121.imageshack.us/img121/2051/ssf2tnoreversal.png)

Cammy tries the reversal but the move comes out too late and she eats the second slide. There's an incremental wait before the special move input (`W12?`), to make it clear that adjusting the timing won't help. Reversal failure doesn't happen with frameskip turned off, and happens more often at higher speeds. This problem was fixed after Street Fighter II.

## Unblockable attacks ##

The previous example relied on the ability to block until the last moment to determine startup. This won't work on unblockable attacks like throws. Instead, some other method of avoiding the attack must be used, which is going to depend on the game's engine and the available characters. Try to use a method that works instantly, like blocking does, or else you will have to correct for the delay in subsequent tests. Jumping is not necessarily instant defense against throws.

In this example we'll find the startup of [sfa2](http://maws.mameworld.info/maws/romset/sfa2) Sodom's Butsumetsu Buster, which is unblockable. Akuma has unhittable, unthrowable teleport moves that can be used to test the startup. But first we should confirm that the teleport starts as fast as blocking. To do this, test a normal blockable move and substitute teleporting for blocking:

```
# sodom MP (startup test: Akuma blocks)
&4 W10 2.W8,-_R,W10,^R! blocked
&4 W10 2.W9,-_R,W10,^R! hit

# sodom MP (startup test: Akuma teleports)
&4 W10 2.W5,-L.D.DL.456.! teleport
&4 W10 2.W6,-L.D.DL.456.! hit
```

The startup is the same, 10, in both cases so this confirms teleporting is instant. Now let's use it to test the command throw startup:

```
# sodom 360+LP throw (startup test: Akuma teleports)
&4 W10 L.D.R.U1. -W20,L.D.DL.456.! teleport
&4 W10 L.D.R.U1. -W21,L.D.DL.456.! thrown
```

![http://img822.imageshack.us/img822/5809/sfa2360p.png](http://img822.imageshack.us/img822/5809/sfa2360p.png)

The startup is 25 frames. What if you try to escape by jumping?

```
# sodom 360+LP throw (startup test: Akuma jumps)
&4 W10 L.D.R.U1. -W21,U.! jumps
&4 W10 L.D.R.U1. -W22,U.! thrown
```

![http://img594.imageshack.us/img594/7411/sfa2jump.png](http://img594.imageshack.us/img594/7411/sfa2jump.png)

The apparent startup is now 23, but we know it's 25. That means it takes Akuma two frames to get off the ground.

## Throw escape timing ##

Using the same setup, let's determine the amount of time that the victim of a normal throw has to escape in SFA2. But first we have to determine the startup of the throw:

```
# sodom HP normal throw (startup test)
&4 W10 -L.D.DL.456 .+R3.! teleport
&4 W10 -L.D.DL.456  +R3.! thrown
```

Akuma must teleport before the throw attempt to avoid it, which means the throw is committed to succeed or fail on the same frame that the button is pressed. Therefore the throw has zero pre-active frames and a startup of 1, which is typical of Capcom games. Now let's find how much time the opponent has to tech out:

```
# sodom HP normal throw (escape window test)
&4 W10 R3. -W2,L3.! techs out
&4 W10 R3. -W3,L3.! doesn't tech out
```

![http://img541.imageshack.us/img541/2183/sfa2tech.png](http://img541.imageshack.us/img541/2183/sfa2tech.png)

The opponent must act within 3 frames to soften the throw, an unusually small window. What happens if they both attempt to throw at the same time?

```
# sodom vs. akuma, simultaneous throws (random winners)
&4 W10? R3-L3.W100!
```

The winner is random. The incremental wait changes up the randomness, so just watch a few trials to see for yourself. In SFA2 the loser gets to tech out with no further input required.

## Superfreeze ##

Superfreeze is a special state that occurs during the startup of super moves. The gameplay freezes briefly and some kind of full-screen filter and dramatic animation is applied. No input is accepted from the players during this time, and inputs that came before are buffered until after the freeze is over. The length of the superfreeze is best defined as the duration of this input lockout.

In SFA2 there are actually two superfreeze phases: the first part when you can't do anything, and the second part when you can input and execute specials, supers and Custom Combo activation. Any moves input during the second part don't actually come out sooner. They are delayed until full control is returned. It's just extra time to buffer your reaction.

Using the previous setup, we can determine the freeze phases of Sodom's LP Meido no Miyage by finding the first frame when control is taken away, the first frame CC activation is possible, and the first frame jumping is possible. We're using CCs instead of other moves because they take only one frame to input, which reduces script complexity, and they cannot be executed with negative edge, which eliminates a source of ambiguity.

```
# sodom QCF,QCF+LP (superfreeze test)
&4 W10 -R.D.DR.123,W66,+D.DR.R.D.DR.R.1. -W3,1245.! CC
&4 W10 -R.D.DR.123,W66,+D.DR.R.D.DR.R.1. -W4,1245.! no CC
&4 W10 -R.D.DR.123,W66,+D.DR.R.D.DR.R.1. -W49,1245.! no CC
&4 W10 -R.D.DR.123,W66,+D.DR.R.D.DR.R.1. -W50,1245.! CC
&4 W10 -R.D.DR.123,W66,+D.DR.R.D.DR.R.1. -W59,U.! no jump
&4 W10 -R.D.DR.123,W66,+D.DR.R.D.DR.R.1. -W60,U.! jump
```

(Akuma teleports across the screen first so it's easier to see if he jumped.) The no-control phase lasts for 51 - 5 = 46 frames and starts on the fifth frame after input. The special-only phase lasts for 61 - 51 = 10 frames. Now that freeze and pre-freeze periods are known, we can get the post-freeze from the total startup:

```
# sodom QCF,QCF+LP (total startup test)
&4 W10 D.DR.R.D.DR.R.1. -W3,_R,W80,^R! blocked
&4 W10 D.DR.R.D.DR.R.1. -W4,_R,W80,^R! hit
```

![http://img97.imageshack.us/img97/2955/sfa2block.png](http://img97.imageshack.us/img97/2955/sfa2block.png)

It turns out that this move starts hitting right after superfreeze ends because holding back after the freeze starts, even for a long time, fails to block. In other words, there's zero frames between the freeze and the first active frame.

We can similarly find the startup profile of Sodom's other super, the Tenchu Satsu. But since it's unblockable we have to use a different method, like Akuma's teleport, to find the total startup.

```
# sodom 720+LP (superfreeze test)
&4 W10 -R.D.DR.123,W66,+R.D.L.U.R.D.L.U1  -1245.! CC
&4 W10 -R.D.DR.123,W66,+R.D.L.U.R.D.L.U1. -1245.! no CC
&4 W10 -R.D.DR.123,W66,+R.D.L.U.R.D.L.U1. -W50,1245.! no CC
&4 W10 -R.D.DR.123,W66,+R.D.L.U.R.D.L.U1. -W51,1245.! CC
&4 W10 -R.D.DR.123,W66,+R.D.L.U.R.D.L.U1. -W60,U.! no jump
&4 W10 -R.D.DR.123,W66,+R.D.L.U.R.D.L.U1. -W61,U.! jump

# sodom 720+LP (total startup test)
&4 W10 R.D.L.U.R.D.L.U1. -W61,R.D.DR.123.! teleport
&4 W10 R.D.L.U.R.D.L.U1. -W62,R.D.DR.123.! thrown
```

![http://img89.imageshack.us/img89/3590/sfa2tpescape.png](http://img89.imageshack.us/img89/3590/sfa2tpescape.png)

For this move, the opponent loses control one frame after execution, so there are zero pre-freeze frames. Special move control doesn't come back until frame 52, so there's no control for 52 - 1 = 51 frames. Only specials are allowed from frame 52 to 62, so the second phase is 10.

The second test shows that the active frame is the 65th, so there are 65 - 62 = 3 post-freeze frames before the active frame. That's just enough to escape by holding up during the freeze.

Here's the summary of these findings:

|super|pre-freeze|full lockout|specials only|post-freeze|total startup|
|:----|:---------|:-----------|:------------|:----------|:------------|
|Sodom QCF,QCF+LP|4         |46          |10           |0          |61           |
|Sodom 720+LP|0         |51          |10           |3          |65           |

In SFA2, [Custom Combo](http://wiki.shoryuken.com/Street_Fighter_Alpha_2#Custom_Combo_.28cc.29) activations have their own kind of superfreeze. CC freeze is more complicated because it's important to know when the attacker can start pressing buttons, and because the time the opponent loses and regains control is different at close range.

Since you can't jump during CC, we'll test the attacker's recovery with a normal attack:

```
# sodom lvl.3 CC (attacker's recovery)
&4 W10 1245. W35,6.! no kick
&4 W10 1245. W36,6.! kick
```

From midrange and farther, the opponent experiences a certain superfreeze:

```
# sodom lvl.3 CC (midrange superfreeze test)
&4 W10 -_R,W40,^R,+1245. -W4,1245.! CC
&4 W10 -_R,W40,^R,+1245. -W5,1245.! no CC
&4 W10 -_R,W40,^R,+1245. -W35,1245.! no CC
&4 W10 -_R,W40,^R,+1245. -W36,1245.! CC
&4 W10 -_R,W40,^R,+1245. -W45,U.! no jump
&4 W10 -_R,W40,^R,+1245. -W46,U.! jump
```

At close range it's different:

```
# sodom lvl.3 CC (close range superfreeze test)
&4 W10 1245. -W1,U.! jump
&4 W10 1245. -W2,U.! no jump
&4 W10 1245. -W46,U.! no jump
&4 W10 1245. -W47,U.! jump

&4 W10 1245. -W4,1245.! CC
&4 W10 1245. -W5,1245.! no CC
&4 W10 1245. -W35,1245.! no CC
&4 W10 1245. -W36,1245.! CC
```

![http://img69.imageshack.us/img69/1794/sfa2cc.png](http://img69.imageshack.us/img69/1794/sfa2cc.png)

Your ability to block, jump and do normals is taken away sooner and given back later, due to the blowout effect. But the special move lockout is unchanged from the long range case. There are even a few frames before the freeze when you can't block but you can input a special.

Here's the summary of Sodom's CC frame data:
|activation distance|Sodom recovers|opponent recovers|opponent frozen|opponent cannot buffer specials|
|:------------------|:-------------|:----------------|:--------------|:------------------------------|
|far                |37            |47               |6 ~ 46         |6 ~ 37                         |
|close              |37            |48               |2 ~ 47         |6 ~ 37                         |

Some characters, Rose for example, have different CC activation data.