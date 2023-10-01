-- i forgot to do git push last time lmfao, anyway here we go

local TFAModeKeys = {
	[0] = "",
	[1] = "0", 
	[2] = "1",
	[3] = "2",
	[4] = "3", 
	[5] = "4",
	[6] = "5",
	[7] = "6", 
	[8] = "7",
	[9] = "8",
	[10] = "9", 
	[11] = "A",
	[12] = "B",
	[13] = "C", 
	[14] = "D",
	[15] = "E",
	[16] = "F", 
	[17] = "G",
	[18] = "H",
	[19] = "I", 
	[20] = "J",
	[21] = "K",
	[22] = "L", 
	[23] = "M",
	[24] = "N",
	[25] = "O", 
	[26] = "P",
	[27] = "Q",
	[28] = "R", 
	[29] = "S",
	[30] = "T",
	[31] = "U", 
	[32] = "V",
	[33] = "W",
	[34] = "X", 
	[35] = "Y",
	[36] = "Z",
	[37] = "NPAD 0",
	[38] = "NPAD 1", 
	[39] = "NPAD 2",
	[40] = "NPAD 3",
	[41] = "NPAD 4", 
	[42] = "NPAD 5",
	[43] = "NPAD 6",
	[44] = "NPAD 7", 
	[45] = "NPAD 8",
	[46] = "NPAD 9",
	[47] = "NPAD /", 
	[48] = "NPAD *",
	[49] = "NPAD -",
	[50] = "NPAD +", 
	[51] = "NPAD ENTER",
	[52] = "NPAD .",
	[53] = "(", 
	[54] = ")",
	[55] = ";",
	[56] = "'", 
	[57] = "`",
	[58] = ",",
	[59] = ".", 
	[60] = "/",
	[61] = "\\",
	[62] = "-", 
	[63] = "=",
	[64] = "ENTER",
	[65] = "SPACE", 
	[66] = "BKSPC",
	[67] = "TAB",
	[68] = "CAPSLOCK", 
	[69] = "NUMLOCK",
	[70] = "ESCAPE",
	[71] = "SCRLOCK", 
	[72] = "INS",
	[73] = "DEL",
	[74] = "HOME", 
	[75] = "END",
	[76] = "PGUP",
	[77] = "PGDN", 
	[78] = "PAUSE",
	[79] = "LSHFT",
	[80] = "RSHFT", 
	[81] = "LALT",
	[82] = "RALT",
	[83] = "LCTRL", 
	-- 84 and 85 needs special Linux and macOS cases. Mac keyboards have Command and Linux uses "Menu", though I haven't see a dedicated
	-- Linux Menu key on any keyboard in my life yet.
	[84] = "RCTRL",
	[85] = "LWIN",
	[86] = "RWIN", 
	[87] = "APP",
	[88] = "UARRW",
	[89] = "LARRW", 
	[90] = "DARRW",
	[91] = "RARRW",
	[92] = "F1",
	[93] = "F2",
	[94] = "F3",
	[95] = "F4", 
	[96] = "F5",
	[97] = "F6",
	[98] = "F7", 
	[99] = "F8",
	[100] = "F9",
	[101] = "F10", 
	[102] = "F11",
	[103] = "F12",
	[104] = "CLOCKTGGL", 
	[105] = "NLOCKTGGL",
	[106] = "SLOCKTGGL",
	[107] = "M1", 
	[108] = "M2",
	[109] = "M3",
	[110] = "M4", 
	[111] = "M5",
	[112] = "MWUP",
	[113] = "MWDN"
}

local CPPAltfireWeps = {
	["Weapon_smg1"] = true,
	["Weapon_ar2"] = true,
	["Weapon_mp5_hl1"] = true
}  

local MWBaseFiremodes = {
    ["AUTOMATIC"] = "FULL AUTO", 
	["SEMI AUTO"] = "SEMI AUTO",
	["SEMI AUTOMATIC"] = "SEMI AUTO",
	["3RND BURST"] = "3-BURST"
}

local TFAFiremodes = {
    ["Full-Auto"] = "FULL AUTO", 
	["Semi-Auto"] = "SEMI AUTO",
	["3 Round Burst"] = "3-BURST"
}

-- All SORTS of ClientCVars
local hidden = CreateClientConVar("PKAD_Hidden", "0", true, false, "Blocks the ammo counter from rendering", 0, 2)
local sway = CreateClientConVar("PKAD_Sway", "1", true, false, "Display HUD swaying", 0, 1)
local dynamic = CreateClientConVar("PKAD_Dynamic", "0", true, false, "Hide HUD when moving (why the frick would you enable this?)", 0, 1)
local UserScale = CreateClientConVar("PKAD_Scale", "1", true, false, "Define your own scaling!")
local playername = ""
CreateClientConVar("PKAD_CornerColor", "65 124 174 124", true, false, "Ammo counter corner color.")
CreateClientConVar("PKAD_AmmobarColor", "85 144 194 200", true, false, "Ammo bar color.")
CreateClientConVar("PKAD_TextColor", "255 255 255 255", true, false, "Ammo counter text color.")
CreateClientConVar("PKAD_BlurTintColor", "0 0 0 0", true, false, "Blur tint color. Helps with visibility. Only works with blur enabled./n Alpha value is locked, sorry!")

CreateClientConVar("PKAD_DeadzoneX", "0", true, false, "Use this HUD while playing on your HDTV!", 0, 0.5)
CreateClientConVar("PKAD_DeadzoneY", "0", true, false, "Use this HUD while playing on your HDTV!", 0, 0.5)

-- Variables: Textures and the like
local blur = Material("pp/blurscreen")

local ARC9Installed = false
local ArcCWInstalled = false
local TFAInstalled = false

local hide = {
    CHudBattery = GetConVar("PKAD_Hidden"):GetBool(),
    CHudAmmo = true,
    CHudSecondaryAmmo = true
}

-- Functions.
function PKAmmoDisp_InitFonts()
	surface.CreateFont("PKAD_BigText", {
		shadow = true,
		blursize = 0,
		underline = false,
		rotary = false,
		strikeout = false,
		additive = false,
		antialias = false,
		extended = false,
		scanlines = 2,
		font = "x14y24pxHeadUpDaisy",
		italic = false,
		outline = false,
		symbol = false,
		weight = 500,
		size = 21 * scale
	})
	
	surface.CreateFont("PKAD_SmallText", {
		shadow = true,
		blursize = 0,
		underline = false,
		rotary = false,
		strikeout = false,
		additive = false,
		antialias = false,
		extended = false,
		scanlines = 2,
		font = "x14y24pxHeadUpDaisy",
		italic = false,
		outline = false,
		symbol = false,
		weight = 500,
		size = 18 * scale
	})

	surface.CreateFont("PKAD_HugeText", {
		shadow = true,
		blursize = 0,
		underline = false,
		rotary = false,
		strikeout = false,
		additive = false,
		antialias = false,
		extended = false,
		scanlines = 2,
		font = "x14y24pxHeadUpDaisy",
		italic = false,
		outline = false,
		symbol = false,
		weight = 250,
		size = 36 * scale
	})
end

-- Hooks
hook.Add("HUDShouldDraw", "PKAD_HideHL2HUD", function(name)
    if hidden:GetBool() then return end 
    if hide[name] then return false end
end)