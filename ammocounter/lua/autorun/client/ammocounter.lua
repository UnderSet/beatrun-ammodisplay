-- Rewriting the HUD I used to make. Or at least, as much of it as I possibly can myself.

-- Also yeah I should use a GLua linter.
-- This rewrite is meant to make the code more readable than the original was as much as I can,
-- and make it easier to work with. (also just 635 lines wow)
local hidden = CreateClientConVar("PKAmmoDisp_Hide", "0", true, false, "Blocks the ammo counter from rendering", 0, 2)
local sway = CreateClientConVar("PKAmmoDisp_Sway", "1", true, false, "Display HUD swaying", 0, 1)
local dynamic = CreateClientConVar("PKAmmoDisp_Dynamic", "0", true, false, "Hide HUD when moving (why the frick would you enable this?)", 0, 1)
local debug = CreateClientConVar("PKAmmoDisp_DebugStuff", "0", true, false, "Some stupid debug stuff I pulled over", 0, 1)
local PerfDisplay = CreateClientConVar("PKAmmoDisp_PerfDisplay", "1", true, false, "Displays some miscellaneous stuff on your monitor/game window's top right.")
local NoBlur = CreateClientConVar("PKAmmoDisp_NoBlur", "0", true, false, "Disables blur effects. Blur only works on DX9+. Does not affect Beatrun or the Player ID on the top-right.")
local playername = ""
CreateClientConVar("PKAmmoDisp_CornerColor", "65 124 174 124", true, false, "Ammo counter corner color.")
CreateClientConVar("PKAmmoDisp_AmmobarColor", "85 144 194 200", true, false, "Ammo bar color.")
CreateClientConVar("PKAmmoDisp_TextColor", "255 255 255 255", true, false, "Ammo counter text color.")
CreateClientConVar("PKAmmoDisp_BlurTintColor", "0 0 0 0", true, false, "Blur tint color. Helps with visibility. Only works with blur enabled./n Alpha value is locked, sorry!")

local scale = ScrH() / 1080
local framerate = 0
local frametime = 0
local hidealpha = 0

function GetCurrentFiremodeTable()
	local fm = self:GetFiremode()
	
	if fm > #self:GetValue("Firemodes") then
		fm = 1
		self:SetFiremode(fm)
	end
	
	return self:GetValue("Firemodes")[fm]
end

local blur = Material("pp/blurscreen")

local function DrawBlurRect2(x, y, w, h, a)
	if render.GetDXLevel() < 90 or GetConVar("PKAmmoDisp_NoBlur"):GetBool() then
		surface.SetDrawColor(80,80,80,50)
		surface.DrawRect(x,y,w,h)
	else
		local X = 0
		local Y = 0
		
		surface.SetDrawColor(255, 255, 255, a)
		surface.SetMaterial(blur)
		
		for i = 1, 2 do
			blur:SetFloat("$blur", i / 3 * 5)
			blur:Recompute()
			
			render.UpdateScreenEffectTexture()
			render.SetScissorRect(x, y, x + w, y + h, true)
			
			surface.DrawTexturedRect(X * -1, Y * -1, ScrW(), ScrH())
			
			render.SetScissorRect(0, 0, 0, 0, false)
		end

		BlurTintColor = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_BlurTintColor"))
		BlurTintColor.a = dynamic:GetBool() and math.max(50 - hidealpha, 0) or BlurTintColor.a
		surface.SetDrawColor(BlurTintColor)
		surface.DrawRect(x,y,w,h)
		--print(tostring(BlurTintColor))
	end
end

local function PermaBlur(x, y, w, h, a)
	if render.GetDXLevel() < 90 then
		surface.SetDrawColor(80,80,80,120)
		surface.DrawRect(x,y,w,h)
	else
		local X = 0
		local Y = 0
		
		surface.SetDrawColor(255, 255, 255, a)
		surface.SetMaterial(blur)
		
		for i = 1, 2 do
			blur:SetFloat("$blur", i / 3 * 5)
			blur:Recompute()
			
			render.UpdateScreenEffectTexture()
			render.SetScissorRect(x, y, x + w, y + h, true)
			
			surface.DrawTexturedRect(X * -1, Y * -1, ScrW(), ScrH())
			
			render.SetScissorRect(0, 0, 0, 0, false)
		end

		surface.SetDrawColor(80,80,80,120)
		surface.DrawRect(x,y,w,h)
	end
end

local function DrawDarkBlur(x, y, w, h, a)
	if render.GetDXLevel() < 90 or GetConVar("PKAmmoDisp_NoBlur"):GetBool() then
		surface.SetDrawColor(133,133,133,120)
		surface.DrawRect(x,y,w,h)
	else
		local X = 0
		local Y = 0
		
		surface.SetDrawColor(255, 255, 255, a)
		surface.SetMaterial(blur)
		
		for i = 1, 2 do
			blur:SetFloat("$blur", i / 3 * 5)
			blur:Recompute()
			
			render.UpdateScreenEffectTexture()
			render.SetScissorRect(x, y, x + w, y + h, true)
			
			surface.DrawTexturedRect(X * -1, Y * -1, ScrW(), ScrH())
			
			render.SetScissorRect(0, 0, 0, 0, false)

			surface.SetDrawColor(65,65,65,90)
			surface.DrawRect(x,y,w,h)
		end
	end
end

function DoesConVarExist(luavar)
	local var = GetConVar(luavar)
	
	if !var then
		return false
	else
		return true
	end
end

local IsPlayingBeatrun = false
if DoesConVarExist("Beatrun_FOV") then -- This is my best fricking idea on how to detect non-vanilla Beatrun.
	IsPlayingBeatrun = true
end

local ARC9Installed = false
local ArcCWInstalled = false
local TFAInstalled = false

-- Does the user have the supported Weapon bases installed?
if DoesConVarExist("arc9_precache_sounds_onfirsttake") then
	print("[PKAD] ARC9 is installed and enabled!")			 -- ARC9
	ARC9Installed = true
end
if DoesConVarExist("arccw_automaticreload") then
	print("[PKAD] ArcCW is installed and enabled!")			-- ArcCW (aka Arctic's Customizable Weaponry)
	ArcCWInstalled = true
end
if DoesConVarExist("cl_tfa_hud_enabled") then
	print("[PKAD] TFA Base is installed and enabled!")		 -- TFA Base
	TFAInstalled = true
end
if DoesConVarExist("mgbase_hud_firemode") then
	print("[PKAD] Modern Warfare Base is installed and enabled!")
	print("[PKAD] (!) WARNING: Support for this base is unstable. Use other weapon bases if possible!")
end

function IsInputBound(bind) -- Renamed ARC9 function. Don't wanna cause conflicts.
	local key = input.LookupBinding(bind)
	
	if !key then
		return falsedddddddddd
	else
		return true
	end
end

local hide = {
	CHudBattery = true,
	CHudAmmo = true,
	CHudSecondaryAmmo = true
}

local CPPAltfireWeps = {
	["Weapon_smg1"] = true,
	["Weapon_ar2"] = true,
	["Weapon_mp5_hl1"] = true
}  

local MWBaseFiremodes = {
    ["AUTOMATIC"] = "FULL AUTO", 
    ["SEMI AUTO"] = "SEMI AUTO",
    ["3RND BURST"] = "3-BURST"
}

local TFAFiremodes = {
    ["Full-Auto"] = "FULL AUTO", 
    ["Semi-Auto"] = "SEMI AUTO",
    ["3 Round Burst"] = "3-BURST"
}

hook.Add("HUDShouldDraw", "hidefunnyshit", function(name)
	if hidden:GetBool() then return end
	if hide[name] then return false end
end)

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
	
	surface.CreateFont("DebugTextScale", {
		shadow = false,
		blursize = 0,
		underline = false,
		rotary = false,
		strikeout = false,
		additive = false,
		antialias = true,
		extended = false,
		scanlines = 0,
		font = "x14y24pxHeadUpDaisy", -- WE ARE NOT DEALING WITH LICENSING COURIER NEW
		italic = false,
		outline = false,
		symbol = false,
		weight = 250,
		size = 15 * scale
	})
end

PKAmmoDisp_InitFonts()

hook.Add( "OnScreenSizeChanged", "UpdateFonts", function() -- Also magically updates ScrW()
	PKAmmoDisp_InitFonts()
end )

concommand.Add("PKAmmoDisp_ResetFonts", function(ply, cmd, args, argStr) PKAmmoDisp_InitFonts() end, nil, "Reinitialize ALL fonts used by the addon.")

local hidealpha = 0

local function PKAD_Draw()
	local usekey = string.upper(string.Replace(input.LookupBinding("+use", 1), "MOUSE", "M"))
	local attack2 = string.upper(string.Replace(input.LookupBinding("+attack2", 1), "MOUSE", "M"))
	local reloadkey = string.upper(string.Replace(input.LookupBinding("+reload", 1), "MOUSE", "M"))
	local zoomkey = nil
	
	if IsInputBound("+zoom") then 
		zoomkey = string.upper(string.Replace(input.LookupBinding("+zoom", 1), "MOUSE", "M")) 
	else 
		zoomkey = "NONE" 
	end
	
	playername = LocalPlayer():Nick()
	local PCTime = os.time()
	local HumanTime = os.date("%H:%M:%S",PCTime)
	local DayOfWeek = os.date("%A, ")
	local IRLday = tonumber(os.date("%d",PCTime))
	local IRLmonth = os.date("%B ",PCTime)
	local IRLyear = os.date("%Y",PCTime)
	if string.match(IRLday,"1") and IRLday != 11 then
		IRLday = IRLday .. "st, "
	elseif string.match(IRLday,"2") and IRLday != 12 then
		IRLday = IRLday .. "nd, "
	elseif string.match(IRLday,"3") and IRLday != 13 then
		IRLday = IRLday .. "rd, "
	else
		IRLday = IRLday .. "th, "
	end

	local ply = LocalPlayer()
	local scrw = ScrW()
	local scrh = ScrH()
	
	if dynamic:GetBool() then
		hidealpha = math.Approach(hidealpha, 150 * ply:GetVelocity():Length() / 250, 100 * RealFrameTime())
	end
	
	local lastframetime = (math.floor(math.Round(FrameTime(), 4) * 1000))
	framerate = math.Round(math.Approach(framerate, math.ceil(1 / FrameTime()), FrameTime() * 10000))
	
	scale = ScrH() / 1080

	local Weapon = ply:GetActiveWeapon()
	local WeaponClass = nil
	local PrimaryAmmo, SecondaryAmmo, PrimaryMag, SecondaryMag, PrimaryReserve, SecondaryReserve, HasAltFire, BottomlessMag, InstantAltfire = -1, -1, -1, -1, -1, -1, false, false, false

	local VanillaAutomatics = {
		["weapon_smg1"] = true,
		["weapon_ar2"] = true,
		["weapon_mp5_hl1"] = true,
		["weapon_gauss"] = true,
		["weapon_egon"] = true
	}  

	if IsValid(Weapon) and ply:Alive() then
		WeaponClass = Weapon:GetClass()
		PrimaryAmmo = math.Clamp(Weapon:Clip1(), 0, Weapon:GetMaxClip1())
		SecondaryAmmo = math.Clamp(Weapon:Clip2(), 0, Weapon:GetMaxClip2())
		PrimaryMag = Weapon:GetMaxClip1()
		SecondaryMag = Weapon:GetMaxClip2()
		PrimaryReserve = math.Clamp(ply:GetAmmoCount(Weapon:GetPrimaryAmmoType()), 0, 9999)
		SecondaryReserve = math.Clamp(ply:GetAmmoCount(Weapon:GetSecondaryAmmoType()), 0, 9999)
		OverCapacity = math.Clamp(Weapon:Clip1() - Weapon:GetMaxClip1(), 0, 9999)
		OverAltCapacity = math.Clamp(Weapon:Clip2() - Weapon:GetMaxClip2(), 0, 9999)
		if Weapon:GetSecondaryAmmoType() != -1 then
			HasAltFire = true
		end
		MagFillRatio = PrimaryAmmo / PrimaryMag
		AltFillRatio = SecondaryAmmo / SecondaryMag
	end

	local ActivePrimaryFire = true -- Self-explanatory.

	if ARC9Installed then function GetFiremodeName()
		if Weapon:GetUBGL() then
			ActivePrimaryFire = false
			return Weapon:GetProcessedValue("UBGLFiremodeName")
		else
		end
		
		local arc9_mode = Weapon:GetCurrentFiremodeTable()
		local pkad_firemode_text = "UNKNOWN"
		
		if arc9_mode.PrintName then
			pkad_firemode_text = arc9_mode.PrintName
		else
			if arc9_mode.Mode == 1 then
				pkad_firemode_text = "SEMI AUTO"
			elseif arc9_mode.Mode == 0 then
				pkad_firemode_text = "SAFETY"
			elseif arc9_mode.Mode < 0 then
				pkad_firemode_text = "FULL AUTO"
			elseif arc9_mode.Mode > 1 then
				pkad_firemode_text = tostring(arc9_mode.Mode) .. "-BURST"
			end
		end
		
		if Weapon:GetSafe() then
			pkad_firemode_text = "SAFETY"
		end
		
		return pkad_firemode_text
	end
	end
	if ArcCWInstalled then function GetCWFiremodeName()
		if Weapon:GetBuff_Hook("Hook_FiremodeName") then return Weapon:GetBuff_Hook("Hook_FiremodeName") end
	
		local abbrev = GetConVar("arccw_hud_fcgabbrev"):GetBool() and ".abbrev" or ""
	
		if Weapon:GetInUBGL() then
			ActivePrimaryFire = false
			return Weapon:GetBuff_Override("UBGL_PrintName") and Weapon:GetBuff_Override("UBGL_PrintName") or ArcCW.GetTranslation("fcg.ubgl" .. abbrev)
		end
	
		local fm = Weapon:GetCurrentFiremode()
	
		if fm.PrintName then
			local phrase = ArcCW.GetPhraseFromString(fm.PrintName)
			return phrase and ArcCW.GetTranslation(phrase .. abbrev) or ArcCW.TryTranslation(fm.PrintName)
		end
	
		local mode = fm.Mode
		if mode == 0 then return "SAFETY" end
		if mode == 1 then return "SEMI AUTO" end
		if mode >= 2 then return "FULL AUTO" end
		if mode < 0 then return string.format(tostring(-mode)) end
	end
	end

	local isarc9 = false
	local inarc9cust = false
	local isweparccw = false
	local ismgbase = false -- MW Base is called mg_ in-engine, FYI to coders who stumbled here
	local istfabase = false

	if ARC9Installed then
		isarc9 = Weapon.ARC9
		inarc9cust = isarc9 and Weapon:GetCustomize()
	end

	if ArcCWInstalled then
		isweparccw = Weapon.ArcCW
	end

	if TFAInstalled then
		istfabase = Weapon.IsTFAWeapon
	end

	if string.match(tostring(WeaponClass), "mg_") and !isarc9 and !isweparccw then -- I have ZERO other fucking clue as to how to detect MW Base as it's barely documented.
		ismgbase = true
	end

	local InfiniteReserve = nil
	
	-- Infinite ammo detection. Works for ARC9 and ArcCW.
	if isarc9 and (Weapon:GetInfiniteAmmo() or GetConVar("arc9_infinite_ammo"):GetBool()) then
		InfiniteReserve = true
		PrimaryReserve = "inf"
		SecondaryReserve = "inf"
		--infmag3 = "∞"
	elseif (isweparccw and GetConVar("arccw_mult_infiniteammo"):GetBool()) then
		InfiniteReserve = true
		PrimaryReserve = "inf"
		SecondaryReserve = "inf"
	end

	-- Bottomless clip detection. Same as infinite ammo detection.
	if isarc9 and Weapon:GetProcessedValue("BottomlessClip", true) then
		BottomlessMag = true
		InstantAltfire = true
	elseif isweparccw and GetConVar("arccw_mult_bottomlessclip"):GetBool() then
		BottomlessMag = true
		InstantAltfire = false
		-- For some inexplicable reason altfire for ArcCW is NOT affected by its bottomless clip CVar.
	elseif !isarc9 and !isweparccw and PrimaryMag == -1 then
		BottomlessMag = true
	end
	
	pkad_firemode_text = "FULL AUTO"

	-- This MESS acquires firemode. Because ARC9 and ArcCW is weird.
	if isarc9 then -- Biggest blunder ever: forgor to change a9 to isarc9. bruh.
		local arc9_mode = Weapon:GetCurrentFiremodeTable()
		
		pkad_firemode_text = GetFiremodeName()
		
		-- Funny note: Some ARC9 functions are global so we can just use them directly if ARC9 is installed! Hooray!
		if #Weapon:GetValue("Firemodes") > 1 then
			wepmultifire = true
		end
	
		if Weapon:GetProcessedValue("NoFiremodeWhenEmpty", true) and Weapon:Clip1() <= 0 then
			wepmultifire = false
		end
		
		if Weapon:GetUBGL() then
			arc9_mode = {
				Mode = Weapon:GetCurrentFiremode(),
				PrintName = Weapon:GetProcessedValue("UBGLFiremodeName")
			}
			pkad_firemode_text = arc9_mode.PrintName
			wepmultifire = false
			ActivePrimaryFire = false
		end
		
		if Weapon:GetSafe() then
			arc9safety = true
		end
		
		if Weapon:GetInfiniteAmmo() then
			arc9inf_reserve = true
		end
		
		if Weapon:GetJammed() then
			arc9jammed = true
		end
		
		if Weapon:GetProcessedValue("Overheat", true) then
			arc9showheat = true
			heat = Weapon:GetHeatAmount()
			heatcap = Weapon:GetProcessedValue("HeatCapacity")
			heatlocked = Weapon:GetHeatLockout()
		end
	elseif Weapon.ArcCW then
		local arccw_mode = Weapon:GetCurrentFiremode()
		
		pkad_firemode_text = GetCWFiremodeName()

		pkad_firemode_text = string.upper(pkad_firemode_text)  
	elseif ismgbase then
		if !Weapon:GetSafety() then
			pkad_firemode_text = string.upper(Weapon.Firemodes[Weapon:GetFiremode()].Name) -- Do we need two complicated tables for this?
			for k,v in pairs(MWBaseFiremodes) do
				if k == pkad_firemode_text then
					pkad_firemode_text = v
				end
			end
		else
			pkad_firemode_text = "SAFETY"
		end
	elseif istfabase then
		pkad_firemode_text = Weapon:GetFireModeName()
		-- It's a miracle how all of these bases don't conflict regarding their GetFiremode() or equivalent function.
	elseif ply:Alive() then
		if Weapon:IsScripted() then
			if !Weapon.Primary.Automatic then
				pkad_firemode_text = "SEMI AUTO"
			end
			
			if Weapon.ThreeRoundBurst then
				pkad_firemode_text = "3-BURST"
			end
			
			if Weapon.TwoRoundBurst then
				pkad_firemode_text = "2-BURST"
			end
			
			if Weapon.GetSafe then
				if Weapon:GetSafe() then
					pkad_firemode_text = "SAFETY"
				end
			end
			
			if isfunction(Weapon.Safe) then
				if Weapon:Safe() then
					pkad_firemode_text = "SAFETY"
				end
			end
			
			if isfunction(Weapon.Safety) then
				if Weapon:Safety() then
					pkad_firemode_text = "SAFETY"
				end
			end
		elseif !VanillaAutomatics[Weapon:GetClass()] then
			pkad_firemode_text = "SEMI AUTO"
		end
	end
	
	if SecondaryMag == -1 then
		InstantAltfire = true
	end

	local pkad_alt_firemode = nil

	if !ActivePrimaryFire then
		pkad_firemode_text = "TOGGLE"
		pkad_alt_firemode = "UNDERBARREL"
	elseif ActivePrimaryFire then
		pkad_alt_firemode = "TOGGLE"
	end

	local ubglkey = ""
	local firemodekey = ""
	if isarc9 and !IsInputBound("+arc9_ubgl") then
		ubglkey = "[" .. usekey .."]+" .. "[" .. attack2 .. "]"
	elseif isarc9 and IsInputBound("+arc9_ubgl") then
		ubglkey = "[" .. string.upper(input.LookupBinding("+arc9_ubgl", 1)) .. "]"
	elseif isweparccw and IsInputBound("arccw_toggle_ubgl") then
		ubglkey = "[" .. string.upper(input.LookupBinding("arccw_toggle_ubgl", 1)) .. "]"
	elseif isweparccw then
		ubglkey = "[" .. usekey .."]+" .. "[" .. reloadkey .. "]"
	end

	if isarc9 then
		firemodekey = "[" .. zoomkey .. "]"
	elseif isweparccw and IsInputBound("arccw_firemode") then
		firemodekey = "[" .. string.upper(input.LookupBinding("arccw_firemode", 1)) .. "]"
	elseif isweparccw then
		firemodekey = "[" .. zoomkey .. "]"
	elseif ismgbase then -- Bruh why does MWB use E+R (fully default bindings) for firemode???
		firemodekey = "[" .. usekey .."]+" .. "[" .. reloadkey .. "]"
	end

	--surface.SetTextPos(500,500)
	--surface.SetTextColor(255,255,255,255)
	--surface.DrawText(pkad_firemode_text)
	--
	--local ammobarcolor = nil
	
	local corner_color_c = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_CornerColor"))
	corner_color_c.a = math.Clamp(corner_color_c.a + 50, 0, 255)
	corner_color_c.a = dynamic:GetBool() and math.max(150 - hidealpha, 25) or corner_color_c.a
	local text_color = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_TextColor"))
	text_color.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or text_color.a
	local otherammocolor = string.ToColor("153 153 153 255")
	otherammocolor.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or otherammocolor.a
	local othertext = string.ToColor("255 255 255 255")
	othertext.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or othertext.a

	local ammobarcolor = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_AmmobarColor")), math.max(255 - hidealpha, 2)
	ammobarcolor.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or ammobarcolor.a

	local armorbackground = string.ToColor("110 110 110 128")
	armorbackground.a = dynamic:GetBool() and math.max(255 - hidealpha, 25) or armorbackground.a
	local ammolowcolor = string.ToColor("255 0 0 230")
	ammolowcolor.a = dynamic:GetBool() and math.max(230 - hidealpha, 25) or ammolowcolor.a
	local ammolowcolor1 = string.ToColor("100 50 50 100")
	ammolowcolor1.a = dynamic:GetBool() and math.max(100 - hidealpha, 25) or ammolowcolor.a

	local AmmoColor = nil
	local AlternateAmmoColor = nil 
	local LowAmmoColor = nil
	local AlternateLowAmmoColor = nil 

	if !ActivePrimaryFire then
		AmmoColor = otherammocolor
		AlternateAmmoColor = text_color
		LowAmmoColor = ammolowcolor1
		AlternateLowAmmoColor = ammolowcolor
	else
		AmmoColor = text_color
		AlternateAmmoColor = otherammocolor
		LowAmmoColor = ammolowcolor
		AlternateLowAmmoColor = ammolowcolor1
	end

	local ReserveColor = nil
	local MagazineColor = nil
	local AltReserveColor = nil
	local AltfireColor = nil
	local AltMagBarColor = nil
	local MagBarColor = nil

	if PrimaryAmmo < PrimaryMag / 3 and !BottomlessMag then
		MagazineColor = LowAmmoColor
		MagBarColor = ammolowcolor
	else
		MagazineColor = AmmoColor
		MagBarColor = ammobarcolor
	end

	if PrimaryReserve != 0 then
		ReserveColor = AmmoColor
	elseif InfiniteReserve then
		ReserveColor = AmmoColor
	else
		ReserveColor = LowAmmoColor
	end
	
	if SecondaryAmmo < SecondaryMag / 3 and !BottomlessMag and !InstantAltfire then
		AltfireColor = AlternateLowAmmoColor
		AltMagBarColor = ammolowcolor
	elseif InstantAltfire then
		AltfireColor = AlternateAmmoColor
		AltMagBarColor = ammobarcolor
	else
		AltfireColor = AlternateAmmoColor
		AltMagBarColor = ammobarcolor
	end

	if SecondaryReserve != 0 and !InstantAltfire then
		AltReserveColor = AlternateAmmoColor
	elseif InfiniteReserve and !InstantAltfire then
		AltReserveColor = AlternateAmmoColor
	elseif InstantAltfire then
		AltReserveColor = AmmoColor
	else
		AltReserveColor = AlternateLowAmmoColor
	end

	local armorsegment = math.Clamp(ply:Armor(), 0, 25)
	local armorsegment1 = math.Clamp(ply:Armor() - 25, 0, 25)
	local armorsegment2 = math.Clamp(ply:Armor() - 50, 0, 25)
	local armorsegment3 = math.Clamp(ply:Armor() - 75, 0, 25)
	local armorsegment4 = math.Clamp(ply:Armor() - 100, 0, 25)
	local armorsegment5 = math.Clamp(ply:Armor() - 125, 0, 25)
	local armorsegment6 = math.Clamp(ply:Armor() - 150, 0, 25)
	local armorsegment7 = math.Clamp(ply:Armor() - 175, 0, 25)

	local vp = ply:GetViewPunchAngles()
	if !sway:GetBool() then
		vp.x = 0
		vp.z = 0
	end

	if ply:Armor() > 0 then
		surface.SetFont("PKAD_SmallText")
		local BlurHeight = 0.862
		if IsPlayingBeatrun and GetConVar("Beatrun_HUDHidden"):GetInt() == 1 then
			BlurHeight = 0.925
		elseif IsPlayingBeatrun and GetConVar("Beatrun_HUDHidden"):GetInt() == 2 then
			BlurHeight = 0.95
		end
		surface.SetDrawColor(corner_color_c)
		surface.DrawRect(-20 * scale + vp.z, scrh * BlurHeight + vp.x, scale * 40, scale * 26)
		DrawBlurRect2(scale * 20 + vp.z, scrh * BlurHeight + vp.x, scale * 200, scale * 26, math.max(255 - hidealpha, 2))
		surface.SetDrawColor(corner_color_c)
		surface.DrawOutlinedRect(scale * 20 + vp.z, scrh * BlurHeight + vp.x, scale * 200, scale * 26)
		
		surface.SetDrawColor(110,110,110,armorbackground.a)
		surface.DrawRect(24 * scale + vp.z, scrh * (BlurHeight + 0.0045) + vp.x, scale * 35, scale *14)
		surface.DrawRect(62 * scale + vp.z, scrh * (BlurHeight + 0.0045) + vp.x, scale * 35, scale* 14)
		surface.DrawRect(100 * scale + vp.z, scrh * (BlurHeight + 0.0045) + vp.x, scale * 35, scale* 14)
		surface.DrawRect(138 * scale + vp.z, scrh * (BlurHeight + 0.0045) + vp.x, scale * 35, scale * 14)

		if ply:Armor() > 15 then
			surface.SetDrawColor(corner_color_c)
		else
			surface.SetDrawColor(230,0,0,corner_color_c.a)
		end
		surface.DrawRect(24 * scale + vp.z, scrh * (BlurHeight + 0.0045) + vp.x, scale * (1.40 * armorsegment), scale * 14)
		surface.DrawRect(62 * scale + vp.z, scrh * (BlurHeight + 0.0045) + vp.x, scale * (1.40 * armorsegment1), scale * 14)
		surface.DrawRect(100 * scale + vp.z, scrh * (BlurHeight + 0.0045) + vp.x, scale * (1.40 * armorsegment2), scale * 14)
		surface.DrawRect(138 * scale + vp.z, scrh * (BlurHeight + 0.0045) + vp.x, scale * (1.40 * armorsegment3), scale * 14)

		surface.SetDrawColor(200,200,200,255)
		surface.DrawRect(62 * scale + vp.z, scrh * (BlurHeight + 0.004) + vp.x, scale * (1.40 * armorsegment5), scale * 9)
		surface.DrawRect(24 * scale + vp.z, scrh * (BlurHeight + 0.004) + vp.x, scale * (1.40 * armorsegment4), scale * 9)
		surface.DrawRect(100 * scale + vp.z, scrh * (BlurHeight + 0.004) + vp.x, scale * (1.40 * armorsegment6), scale * 9)
		surface.DrawRect(138 * scale + vp.z, scrh * (BlurHeight + 0.004) + vp.x, scale * (1.40 * armorsegment7), scale * 9)
		
		armor_color = nil
		if ply:Armor() > 15 then
			armor_color = text_color
		else
			armor_color = string.ToColor("230 0 0 " .. corner_color_c.a)
		end
		if ply:Armor() < 10 then
			surface.SetTextPos(182 * scale + vp.z, scrh * (BlurHeight + 0.003) + vp.x)
			surface.SetTextColor(120,120,120,armorbackground.a)
			surface.DrawText("00")
			surface.SetTextColor(armor_color)
			surface.DrawText(ply:Armor())
		elseif ply:Armor() < 100 then
			surface.SetTextPos(182 * scale + vp.z, scrh * (BlurHeight + 0.003) + vp.x)
			surface.SetTextColor(120,120,120,armorbackground.a)
			surface.DrawText("0")
			surface.SetTextColor(armor_color)
			surface.DrawText(ply:Armor())
		else
			surface.SetTextPos(182 * scale + vp.z, scrh * (BlurHeight + 0.003) + vp.x)
			surface.SetTextColor(armor_color)
			surface.DrawText(ply:Armor())
		end
	end

	IsPlayingBeatrun = true -- Testing
	local brinfo = ""
	if IsPlayingBeatrun then
		brinfo = " (" .. LocalPlayer():SteamID() .. " | Beatrun: " .. VERSIONGLOBAL .. ")"
	end
	surface.SetFont("DebugTextScale")
	local namew, nameh = surface.GetTextSize("Player: " .. playername .. brinfo)
	surface.SetTextPos(scrw - 9 * scale - namew, 0 + 10 * scale)
	PermaBlur(scrw - 15 * scale - namew, 0 + 6 * scale, namew + 10 * scale, 22 * scale, 255)
	if IsPlayingBeatrun then
		surface.SetTextColor(218,218,218,255)
	else
		surface.SetTextColor(200,200,200,200)
	end
	surface.DrawText("Player: " .. playername .. brinfo)

	if PerfDisplay:GetBool() then
		local text1 = HumanTime .. " | " .. DayOfWeek .. IRLmonth .. IRLday .. IRLyear -- Time display
		surface.SetFont("DebugTextScale")
		local txw, txh = surface.GetTextSize(text1)
		surface.SetTextPos(scrw - 9 * scale - txw, 0 + 10 * scale + 18)
		surface.SetTextColor(128,128,128,200)
		surface.DrawText(text1)

		local text2 = nil -- FPS/Frametime display
		if GetConVar("fps_max"):GetInt() != 0 then
			text2 = framerate .. "fps/" .. GetConVar("fps_max"):GetInt() .. "fps max (~" .. lastframetime .. "ms, " .. scrw .. "x" .. scrh .. ")" 
		else
			text2 = framerate .. "fps (~" .. lastframetime .. "ms, " .. scrw .. "x" .. scrh .. ")" 
		end
		surface.SetFont("DebugTextScale")
		local tx2w, tx2h = surface.GetTextSize(text2)
		surface.SetTextPos(scrw - 8 * scale - tx2w, 0 + 10 * scale + 36)
		surface.SetTextColor(128,128,128,200)
		surface.DrawText(text2)

		local text3 = nil
		if game.SinglePlayer then
			text3 = ply:Ping() .. "ms to server on Singleplayer"
		else
			text3 = ply:Ping() .. "ms to server on " .. game.GetIPAddress
		end
		local tx3w, tx3h = surface.GetTextSize(text3)
		surface.SetTextPos(scrw - 8 * scale - tx3w, 0 + 10 * scale + 54)
		surface.DrawText(text3)
	end

	if ply:Alive() then
		if VanillaAutomatics[Weapon:GetClass()] then
			ubglkey = "[" .. attack2 .. "]"
			firemodekey = ""
			pkad_alt_firemode = "FIRE"
		end
	end
	
	-- Kind of usable but needs work, mostly ok tho
	if !ActivePrimaryFire and !VanillaAutomatics[Weapon:GetClass()] then
		firemodekey = ubglkey
		ubglkey = ""
	end
	
	surface.SetFont("PKAD_SmallText")
	local FiremodeW, FiremodeH = surface.GetTextSize(pkad_firemode_text)
	local AltFiremodeW, AltFiremodeH = surface.GetTextSize(pkad_alt_firemode)
	
	if IsValid(Weapon) and ply:IsValid() and ply:Alive() and Weapon:GetPrimaryAmmoType() != -1 then
		surface.SetDrawColor(corner_color_c)
		surface.DrawRect(scrw - 18.88 * scale + vp.z, scrh * 0.895 + vp.x, 40 * scale, scale * 85)
		DrawBlurRect2(scrw - 218.88 * scale + vp.z, scrh * 0.895 + vp.x, scale * 200, scale * 85, math.max(255 - hidealpha, 2))
		surface.SetDrawColor(corner_color_c)
		surface.DrawOutlinedRect(scrw - 218.88 * scale + vp.z, scrh * 0.895 + vp.x, scale * 200, scale * 85)

		if !BottomlessMag then
			local OverflowText = ""
			if OverCapacity > 0 then
				OverflowText = "+" .. OverCapacity
			end

			local OverflowSizeW, OverflowSizeY = surface.GetTextSize(OverflowText)
			surface.SetFont("PKAD_BigText")
			local Reserve1W, Reserve1H = surface.GetTextSize("/" .. PrimaryReserve)
			surface.SetTextColor(ReserveColor)
			surface.SetTextPos(scrw - 26.88 * scale - Reserve1W + vp.z, scrh * 0.91 + vp.x)
			surface.DrawText("/" .. PrimaryReserve)

			surface.SetFont("PKAD_HugeText")
			local MagazineW, MagazineH = surface.GetTextSize(PrimaryAmmo)
			surface.SetTextPos(scrw - 26.88 * scale - Reserve1W - OverflowSizeW - MagazineW + vp.z, scrh * 0.9 + vp.x)
			surface.SetTextColor(MagazineColor)
			surface.DrawText(PrimaryAmmo)

			surface.SetDrawColor(10, 50, 50, ammolowcolor1.a)
			surface.DrawRect(scrw - 176.64 * scale + vp.z, scrh * 0.938 + vp.x, 150 * scale, scale * 2.55)
			surface.SetDrawColor(MagBarColor)
			surface.DrawRect(scrw - 176.64 * scale + vp.z, scrh * 0.938 + vp.x, 150 * scale * MagFillRatio, scale * 5)

			surface.SetFont("PKAD_SmallText")
			surface.SetTextPos(scrw - 26.88 - Reserve1W - OverflowSizeW + vp.z, scrh * 0.91 + vp.x)
			surface.DrawText(OverflowText)

			surface.SetTextColor(AlternateAmmoColor)
			surface.SetFont("PKAD_SmallText")
			surface.SetTextPos(scrw - 26.88 * scale - FiremodeW + vp.z, scrh * 0.95 + vp.x)
			surface.DrawText(pkad_firemode_text)

            surface.SetTextPos(scrw - 218.88 * scale + vp.z, scrh * 0.95 + vp.x)
            surface.SetTextColor(255,255,255,othertext.a)
            surface.DrawText(firemodekey)

			--if !InstantAltfire then
			--	surface.SetDrawColor(128,68,92,255)
			--	surface.DrawRect(28,28,28,28)
			--end
		elseif BottomlessMag then
			--local Reserve1W, Reserve1H = surface.GetTextSize(PrimaryReserve)
			--surface.SetTextColor(ReserveColor)
			--surface.SetTextPos((scrw * 0.986) - Reserve1W + vp.z, scrh * 0.91 + vp.x)
			--surface.DrawText(PrimaryReserve)
			
			surface.SetFont("PKAD_HugeText")
			local MagazineW, MagazineH = surface.GetTextSize(PrimaryReserve + math.Clamp(PrimaryAmmo, 0, 9999))
			surface.SetTextPos(scrw * 0.986 - MagazineW + vp.z, scrh * 0.9 + vp.x)
			surface.SetTextColor(MagazineColor)
			surface.DrawText(PrimaryReserve + math.Clamp(PrimaryAmmo, 0, 9999))
			
			surface.SetDrawColor(MagBarColor)
			surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.938 + vp.x, 150 * scale, scale * 5)
			
			surface.SetTextColor(AlternateAmmoColor)
			surface.SetFont("PKAD_SmallText")
			surface.SetTextPos(scrw - 26.88 * scale - FiremodeW + vp.z, scrh * 0.95 + vp.x)
			surface.DrawText(pkad_firemode_text)
			
            surface.SetTextPos(scrw - 218.88 * scale + vp.z, scrh * 0.95 + vp.x)
            surface.SetTextColor(255,255,255,othertext.a)
            surface.DrawText(firemodekey)
		end

		if HasAltFire and InstantAltfire then
			surface.SetDrawColor(corner_color_c)
			surface.DrawRect(scrw - 260.512 * scale + vp.z, scrh * 0.895 + vp.x, 25 * scale, scale * 85)
			DrawBlurRect2(scrw - 419.174 * scale + vp.z, scrh * 0.895 + vp.x, scale * 161, scale * 85, math.max(255 - 	hidealpha, 2))
			surface.SetDrawColor(corner_color_c)
			surface.DrawOutlinedRect(scrw - 419.174 * scale + vp.z, scrh * 0.895 + vp.x, scale * 161, scale * 85)
		
			surface.SetFont("PKAD_HugeText")
			local Reserve2H, Reserve2W = surface.GetTextSize((SecondaryReserve + math.Clamp(SecondaryAmmo, 0, 9999)))
			surface.SetTextPos(scrw - 268 * scale - Reserve2H + vp.z, scrh * 0.9 + vp.x)
			surface.SetTextColor(AltReserveColor)
			surface.DrawText((SecondaryReserve + math.Clamp(SecondaryAmmo, 0, 9999)))
		
			surface.SetDrawColor(AltMagBarColor)					
			surface.DrawRect(scrw - 364 * scale + vp.z, scrh * 0.938 + 1 + vp.x, 100 * scale, scale * 5)
		
			surface.SetTextColor(AmmoColor)
			surface.SetFont("PKAD_SmallText")
			surface.SetTextPos(scrw - 268 * scale - AltFiremodeW + vp.z, scrh * 0.95 + vp.x)
			surface.DrawText(pkad_alt_firemode)
		
			surface.SetTextColor(255,255,255,othertext.a)
			surface.SetTextPos(scrw - 414.72 * scale + vp.z, scrh * 0.95 + vp.x)
			surface.DrawText(ubglkey)
		elseif HasAltFire and !InstantAltfire then
			surface.SetDrawColor(corner_color_c)
			surface.DrawRect(scrw - 260.512 * scale + vp.z, scrh * 0.895 + vp.x, 25 * scale, scale * 85)
			DrawBlurRect2(scrw - 419.174 * scale + vp.z, scrh * 0.895 + vp.x, scale * 161, scale * 85, math.max(255 - hidealpha, 2))
			surface.SetDrawColor(corner_color_c)
			surface.DrawOutlinedRect(scrw - 419.174 * scale + vp.z, scrh * 0.895 + vp.x, scale * 161, scale * 85)
			
			surface.SetFont("PKAD_BigText")
			local Reserve2W, Reserve2H = surface.GetTextSize("/" .. SecondaryReserve)
			surface.SetTextPos(scrw - 268 * scale - Reserve2W + vp.z, scrh * 0.91 + vp.x)
			surface.SetTextColor(AltReserveColor)
			surface.DrawText("/" .. SecondaryReserve)

			local OverflowAltText = ""
			if OverAltCapacity > 0 then
				OverflowAltText = "+" .. OverAltCapacity
			end
			local OverflowAltSizeW, OverflowAltSizeY = surface.GetTextSize(OverflowAltText)
			surface.SetFont("PKAD_SmallText")
			surface.SetTextPos(scrw - 268 * scale - Reserve2W - OverflowAltSizeW + vp.z, scrh * 0.91 + vp.x)
			surface.DrawText(OverflowAltText)
			
			surface.SetFont("PKAD_HugeText")
			local AltfireW, AltfireH = surface.GetTextSize(SecondaryAmmo)
			surface.SetTextPos(scrw - 268 * scale - Reserve2W - AltfireW - OverflowAltSizeW + vp.z, scrh * 0.9 + vp.x)
			surface.SetTextColor(AltfireColor)
			surface.DrawText(SecondaryAmmo)
			
			surface.SetDrawColor(10, 50, 50, ammolowcolor1.a)					
			surface.DrawRect(scrw - 361 * scale + vp.z, scrh * 0.938 + 1 + vp.x, 100 * scale, scale * 2.55)
			
			surface.SetDrawColor(AltMagBarColor)
			surface.DrawRect(scrw - 361 * scale + vp.z, scrh * 0.938 + 1 + vp.x, 100 * scale * AltFillRatio, scale * 5)
		
			surface.SetTextColor(AmmoColor)
			surface.SetFont("PKAD_SmallText")
			surface.SetTextPos(scrw - 268 * scale - AltFiremodeW + vp.z, scrh * 0.95 + vp.x)
			surface.DrawText(pkad_alt_firemode)
		
			surface.SetTextColor(255,255,255,othertext.a)
			surface.SetTextPos(scrw - 414.72 * scale + vp.z, scrh * 0.95 + vp.x)
			surface.DrawText(ubglkey)
		end
	end
end

local DispSegments = { -- Element alighment helpers, used while debugging
"0",
	"0.1",
	"0.2",
	"0.3",
	"0.4",
	"0.5",
	"0.6",
	"0.7",
	"0.8",
	"0.9",
	"0.05",
	"0.15",
	"0.25",
	"0.35",
	"0.45",
	"0.55",
	"0.65",
	"0.75",
	"0.85",
	"0.95",
}

hook.Add("HUDPaint", "PKAD_Draw", PKAD_Draw) -- bruh its not PKAD_Draw()

hook.Add( "HUDPaint", "drawsegment", function( name )
	local scale = ScrH() / 1080

	if debug:GetBool() then
		local Wepon = LocalPlayer():GetActiveWeapon()
		if IsValid(Wepon) then
			WeaponClass = Wepon:GetClass()
			PrimaryAmmo = math.Clamp(Wepon:Clip1(), 0, Wepon:GetMaxClip1())
			SecondaryAmmo = math.Clamp(Wepon:Clip2(), 0, Wepon:GetMaxClip2())
			PrimaryMag = Wepon:GetMaxClip1()
			SecondaryMag = Wepon:GetMaxClip2()
			PrimaryReserve = math.Clamp(LocalPlayer():GetAmmoCount(Wepon:GetPrimaryAmmoType()), 0, 9999)
			SecondaryReserve = math.Clamp(LocalPlayer():GetAmmoCount(Wepon:GetSecondaryAmmoType()), 0, 9999)
			OverCapacity = math.Clamp(Wepon:Clip1() - Wepon:GetMaxClip1(), 0, 9999)
			OverAltCapacity = math.Clamp(Wepon:Clip2() - Wepon:GetMaxClip2(), 0, 9999)
			if Wepon:GetSecondaryAmmoType() != -1 then
				HasAltFire = true
			end
			MagFillRatio = PrimaryAmmo / PrimaryMag
			AltFillRatio = SecondaryAmmo / SecondaryMag
		end
		for i=1,#DispSegments do
			surface.SetDrawColor(255,255,255,128)
			surface.DrawRect(ScrW() * DispSegments[i], 1, 1, ScrH()) 
			surface.DrawRect(1, ScrH() * DispSegments[i], ScrW(), 1) 
			surface.SetDrawColor(255,255,255,64)
			surface.DrawRect(ScrW() * (DispSegments[i] + 0.025), 1, 1, ScrH()) 
			surface.DrawRect(1, ScrH() * (DispSegments[i] + 0.025), ScrW(), 1) 
		end
		surface.SetTextColor(255,255,255,255)
		surface.SetFont("PKAD_SmallText")
		local weapondata = PrimaryAmmo .. " | " .. SecondaryAmmo .. " | " .. PrimaryMag .. " | " .. SecondaryMag .. " | " .. OverCapacity .. " | " .. OverAltCapacity .. " | " .. PrimaryReserve .. " | " .. SecondaryReserve

		local DebugWepW, DebugWepH = surface.GetTextSize(weapondata)
		surface.SetTextPos(ScrW() * 0.5 - (DebugWepW * 0.5), ScrH() * 0.55)
		surface.DrawText(PrimaryAmmo .. " | " .. SecondaryAmmo .. " | " .. PrimaryMag .. " | " .. SecondaryMag .. " | " .. OverCapacity .. " | " .. OverAltCapacity .. " | " .. PrimaryReserve .. " | " .. SecondaryReserve)

		local HealthDebugW, HealthDebugH = surface.GetTextSize(LocalPlayer():Health() .. "/" .. LocalPlayer():GetMaxHealth() .. " HP  |  " .. LocalPlayer():Armor() .. "/" .. LocalPlayer():GetMaxArmor() .. "AP")
		surface.SetTextPos(ScrW() * 0.5 - HealthDebugW * 0.5, ScrH() * 0.55 + DebugWepH)
		surface.DrawText(LocalPlayer():Health() .. "/" .. LocalPlayer():GetMaxHealth() .. " HP  |  " .. LocalPlayer():Armor() .. "/" .. LocalPlayer():GetMaxArmor() .. "AP")
	end
end )

concommand.Add("pkad_debug_printspeed", function(ply, cmd, args)
	print(LocalPlayer():GetVelocity():Length() .. " | " .. LocalPlayer():GetVelocity():Length2D() .. " | " .. LocalPlayer():GetVelocity():Length() * 0.06858125 .. " | " .. LocalPlayer():GetVelocity():Length2D() * 0.06858125)
end )