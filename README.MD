# beatrun-ammocounter
My attempt at making an ammo display that works well with Beatrun. *Currently in rewrite and is not usable.*~~<br>If it doesn't show up, run the following command in the Developer Console: `lua_openscript_cl autorun\ammocounter.lua`~~

**No, Spawnmenu options *won't* be added, even in the rewrite. Do not ask for it.**

## Features
- Fully clientside, works with any server that has `sv_allowcslua` allowed
- Primary ammo display, with viewpunch offset and firemode display
- Secondary/alt-fire ammo display, with mag-style altfire support *(why does no other HUD support this properly?)*
- Support for mag-less weapons
- Armor display because Beatrun doesn't have one
- Optional speedometer, works outside of Beatrun too

## To be done
Just check the Issues tab, will ya?

![image of the Issues tab](images/checkissues.png)
<br>*No, seriously, check Issues. Please. It saves me so much time.*

## Credits
- [datæ](https://steamcommunity.com/id/75651121243836): the *original, **possibly malicious*** Beatrun gamemode
- [Arctic](https://github.com/haodongmo): some used ARC9 code for determining melee weapons
