-- Rewriting the HUD I used to make. Or at least, as much of it as I possibly can myself.

-- Also yeah I should use a GLua linter.
-- This rewrite is meant to make the code more readable than the original was as much as I can,
-- and make it easier to work with. (also just 635 lines wow)
local hidden = CreateClientConVar("PKAmmoDisp_Hide", "0", true, false, "Blocks the ammo counter from rendering", 0, 2)
local sway = CreateClientConVar("PKAmmoDisp_Sway", "1", true, false, "Display HUD swaying", 0, 1)
local dynamic = CreateClientConVar("PKAmmoDisp_Dynamic", "0", true, false, "Hide HUD when moving (why the frick would you enable this?)", 0, 1)
local debug = CreateClientConVar("PKAmmoDisp_DebugStuff", "0", true, false, "Some stupid debug stuff I pulled over", 0, 1)
local PerfDisplay = CreateClientConVar("PKAmmoDisp_PerfDisplay", "1", true, false, "Displays some miscellaneous stuff on your monitor/game window's top right.")
local NoBlur = CreateClientConVar("PKAmmoDisp_NoBlur", "0", true, false, "Disables blur effects. Only works on DX9+ (Windows) and Linux, as blur doesn't work with DX8 and below. Gives like 2fps or something. Does not affect Beatrun.")
local playername = ""

steamworks.RequestPlayerInfo( LocalPlayer():SteamID64(), function( steamName )
	playername = steamName
end )

local scale = ScrH() / 1080
local framerate = 0
local frametime = 0

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
	end
end

local hidealpha = 0

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
	print("ARC9 is installed!")			 -- ARC9
	ARC9Installed = true
end
if DoesConVarExist("arccw_automaticreload") then
	print("ArcCW is installed!")			-- ArcCW (aka Arctic's Customizable Weaponry)
	ArcCWInstalled = true
end
if DoesConVarExist("cl_tfa_hud_enabled") then
	print("TFA Base is installed!")		 -- TFA Base
	TFAInstalled = true
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

local hidealpha = 0

local function PKAD_Draw()
    local pctime = os.time()
    local humantime = os.date("%Y/%m/%d %H:%M:%S",pctime)
    print(humantime)

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
		["Weapon_smg1"] = true,
		["Weapon_ar2"] = true,
		["Weapon_mp5_hl1"] = true,
		["Weapon_gauss"] = true,
		["Weapon_egon"] = true
	}  

	if IsValid(Weapon) then
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
		if self:GetUBGL() then
			ActivePrimaryFire = false
			return self:GetProcessedValue("UBGLFiremodeName")
		else
		end
	
		local arc9_mode = self:GetCurrentFiremodeTable()
	
		local pkad_firemode_text = "UNKNOWN"
	
		if arc9_mode.PrintName then
			pkad_firemode_text = arc9_mode.PrintName
		else
			if arc9_mode.Mode == 1 then
				pkad_firemode_text = "SEMI"
			elseif arc9_mode.Mode == 0 then
				pkad_firemode_text = "SAFETY"
			elseif arc9_mode.Mode < 0 then
				pkad_firemode_text = "AUTO"
			elseif arc9_mode.Mode > 1 then
				pkad_firemode_text = tostring(arc9_mode.Mode) .. "-BURST"
			end
		end
	
		if self:GetSafe() then
			pkad_firemode_text = "SAFETY"
		end
	
		return pkad_firemode_text
	end
	end

	local isarc9 = false
	local inarc9cust = false
	local isweparccw = false

	if ARC9Installed then
		isarc9 = Weapon.ARC9
		inarc9cust = isarc9 and Weapon:GetCustomize()
	end

	if ArcCWInstalled then
		isweparccw = Weapon.ArcCW
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
	elseif (isweparccw and GetConVar("arccw_mult_bottomlessclip"):GetBool()) then
		BottomlessMag = true
		InstantAltfire = true
	end

	pkad_firemode_text = "DEFAULT"
	if ARC9Installed and a9 then -- This acquires firemode. Yes, it takes this much code to simply acquire your bloody firemode.
		local arc9_mode = Weapon:GetCurrentFiremodeTable()
	
		pkad_firemode_text = Weapon:GetFiremodeName()
	
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

		pkad_firemode_text = Weapon:GetFiremodeName()

		pkad_firemode_text = string.upper(pkad_firemode_text)  
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

	CreateClientConVar("PKAmmoDisp_CornerColor", "65 124 174 124", true, false, "Ammo counter corner color.")
	CreateClientConVar("PKAmmoDisp_AmmobarColor", "85 144 194 200", true, false, "Ammo bar color.")
	CreateClientConVar("PKAmmoDisp_TextColor", "255 255 255 255", true, false, "Ammo counter text color.")
	--local ammobarcolor = nil

	local corner_color_c = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_CornerColor"))
	corner_color_c.a = math.Clamp(corner_color_c.a + 50, 0, 255)
	corner_color_c.a = dynamic:GetBool() and math.max(150 - hidealpha, 50) or corner_color_c.a
	local text_color = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_TextColor"))
	text_color.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or text_color.a
	local othertext = string.ToColor("255 255 255 255")
	othertext.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or othertext.a
	local ammobarcolor = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_AmmobarColor")), math.max(255 - hidealpha, 2)
	ammobarcolor.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or ammobarcolor.a

	local armorbackground = string.ToColor("110 110 110 128")
	armorbackground.a = dynamic:GetBool() and math.max(255 - hidealpha, 50) or armorbackground.a
	local ammolowcolor = string.ToColor("255 0 0 230")
	ammolowcolor.a = dynamic:GetBool() and math.max(230 - hidealpha, 50) or ammolowcolor.a
	local ammolowcolor1 = string.ToColor("100 50 50 100")
	ammolowcolor1.a = dynamic:GetBool() and math.max(100 - hidealpha, 50) or ammolowcolor.a

    local ReserveColor = nil
    local MagazineColor = nil
    local AltReserveColor = nil
    local AltfireColor = nil
    local AltMagBarColor = nil
    local MagBarColor = nil

    if PrimaryAmmo < PrimaryMag / 3 and not BottomlessMag then
        MagazineColor = ammolowcolor
        MagBarColor = ammolowcolor
    else
        MagazineColor = text_color
        MagBarColor = ammobarcolor
    end

    if PrimaryReserve != 0 then
        ReserveColor = text_color
    elseif InfiniteReserve then
        ReserveColor = text_color
    else
        ReserveColor = ammolowcolor
    end
    
    if SecondaryAmmo < SecondaryMag / 3 and not BottomlessMag then
        AltfireColor = ammolowcolor
        AltMagBarColor = ammolowcolor
    else
        AltfireColor = text_color
        AltMagBarColor = ammobarcolor
    end

    if SecondaryReserve != 0 then
        AltReserveColor = text_color
    elseif InfiniteReserve then
        AltReserveColor = text_color
    else
        AltReserveColor = ammolowcolor
    end

	local armorsegment = math.Clamp(ply:Armor(), 0, 25)
	local armorsegment1 = math.Clamp(ply:Armor() - 25, 0, 25)
	local armorsegment2 = math.Clamp(ply:Armor() - 50, 0, 25)
	local armorsegment3 = math.Clamp(ply:Armor() - 75, 0, 25)

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
		
		armor_color = nil
		if ply:Armor() > 15 then
			armor_color = text_color
		else
			armor_color = string.ToColor("230 0 0 " .. corner_color_c.a)
		end
		if ply:Armor() < 10 then
			surface.SetTextPos(182 * scale + vp.z, scrh * (BlurHeight + 0.002) + vp.x)
			surface.SetTextColor(120,120,120,armorbackground.a)
			surface.DrawText("00")
			surface.SetTextColor(armor_color)
			surface.DrawText(ply:Armor())
		elseif ply:Armor() < 100 then
			surface.SetTextPos(182 * scale + vp.z, scrh * (BlurHeight + 0.002) + vp.x)
			surface.SetTextColor(120,120,120,armorbackground.a)
			surface.DrawText("0")
			surface.SetTextColor(armor_color)
			surface.DrawText(ply:Armor())
		else
			surface.SetTextPos(182 * scale + vp.z, scrh * (BlurHeight + 0.002) + vp.x)
			surface.SetTextColor(armor_color)
			surface.DrawText(ply:Armor())
		end
	end

	if PerfDisplay:GetBool() then
		local text1 = nil
		if GetConVar("fps_max"):GetInt() != 0 then
			text1 = framerate .. "fps/" .. GetConVar("fps_max"):GetInt() .. "fps max (~" .. lastframetime .. "ms, " .. scrw .. "x" .. scrh .. ")" 
		else
			text1 = framerate .. "fps (~" .. lastframetime .. "ms, " .. scrw .. "x" .. scrh .. ")" 
		end
		local text2 = nil
		surface.SetFont("DebugTextScale")
		local txw, txh = surface.GetTextSize(text1)
		surface.SetTextPos(scrw - 8 * scale - txw, 0 + 10 * scale)
		surface.SetTextColor(128,128,128,200)
		surface.DrawText(text1)
		if game.SinglePlayer then
			text2 = ply:Ping() .. "ms to server on Singleplayer"
		else
			text2 = ply:Ping() .. "ms to server on " .. game.GetIPAddress
		end
		local tx2w, tx2h = surface.GetTextSize(text2)
		surface.SetTextPos(scrw - 8 * scale - tx2w, 0 + 10 * scale + txh * 1.25)
		surface.DrawText(text2)
	end

	if IsValid(Weapon) and ply:IsValid() and ply:Alive() and Weapon:GetPrimaryAmmoType() != -1 then
		surface.SetDrawColor(corner_color_c)
		surface.DrawRect(scrw * 0.886 + scale * 200 + vp.z, scrh * 0.895 + vp.x, 40 * scale, scale * 85)
		DrawBlurRect2(scrw * 0.886 + vp.z, scrh * 0.895 + vp.x, scale * 200, scale * 85, math.max(255 - hidealpha, 2))
		surface.SetDrawColor(corner_color_c)
		surface.DrawOutlinedRect(scrw * 0.886 + vp.z, scrh * 0.895 + vp.x, scale * 200, scale * 85)

        if !BottomlessMag then
            surface.SetFont("PKAD_BigText")
            local Reserve1W, Reserve1H = surface.GetTextSize("/" .. PrimaryReserve)
            surface.SetTextColor(ReserveColor)
            surface.SetTextPos((scrw * 0.986) - Reserve1W, scrh * 0.91)
            surface.DrawText("/" .. PrimaryReserve)

            surface.SetFont("PKAD_HugeText")
            local MagazineW, MagazineH = surface.GetTextSize(PrimaryAmmo)
            surface.SetTextPos(scrw * 0.986 - Reserve1W - MagazineW, scrh * 0.9)
            surface.SetTextColor(MagazineColor)
            surface.DrawText(PrimaryAmmo)

            surface.SetDrawColor(10, 50, 50, ammolowcolor1.a)
            surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.938 + vp.x, 150 * scale, scale * 5)
            surface.SetDrawColor(MagBarColor)
            surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.938 + 1 + vp.x, 150 * scale * MagFillRatio, scale * 5)

            if HasAltFire and !InstantAltfire then
                surface.SetDrawColor(corner_color_c)
                surface.DrawRect(scrw * 0.76025 + scale * 200 + vp.z, scrh * 0.895 + vp.x, 25 * scale, scale * 85)
                DrawBlurRect2(scrw * 0.78168 + vp.z, scrh * 0.895 + vp.x, scale * 161, scale * 85, math.max(255 - hidealpha, 2))
                surface.SetDrawColor(corner_color_c)
                surface.DrawOutlinedRect(scrw * 0.78168 + vp.z, scrh * 0.895 + vp.x, scale * 161, scale * 85)

                surface.SetFont("PKAD_BigText")
                local Reserve2H, Reserve2W = surface.GetTextSize("/" .. SecondaryReserve)
                surface.SetTextPos(scrw * 0.86 - Reserve2H + vp.z, scrh * 0.91 + vp.x)
                surface.SetTextColor(AltReserveColor)
                surface.DrawText("/" .. SecondaryReserve)

                surface.SetFont("PKAD_HugeText")
                local AltfireW, AltfireH = surface.GetTextSize(SecondaryAmmo)
                surface.SetTextPos(scrw * 0.86 - Reserve2H - AltfireW + vp.z, scrh * 0.9 + vp.x)
                surface.SetTextColor(AltfireColor)
                surface.DrawText(SecondaryAmmo)

                surface.SetDrawColor(10, 50, 50, ammolowcolor1.a)                    
                surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.938 + 1 + vp.x, 100 * scale, scale * 5)

                surface.SetDrawColor(AltMagBarColor)
                surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.938 + 1 + vp.x, 100 * scale * AltFillRatio, scale * 5)
            end
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
        print(DebugWepW .. " | " .. DebugWepH)
        surface.SetTextPos(ScrW() * 0.5 - (DebugWepW * 0.5), ScrH() * 0.55)
        surface.DrawText(PrimaryAmmo .. " | " .. SecondaryAmmo .. " | " .. PrimaryMag .. " | " .. SecondaryMag .. " | " .. OverCapacity .. " | " .. OverAltCapacity .. " | " .. PrimaryReserve .. " | " .. SecondaryReserve)

        local HealthDebugW, HealthDebugH = surface.GetTextSize(LocalPlayer():Health() .. "/" .. LocalPlayer():GetMaxHealth() .. " HP  |  " .. LocalPlayer():Armor() .. "/" .. LocalPlayer():GetMaxArmor() .. "AP")
        surface.SetTextPos(ScrW() * 0.5 - HealthDebugW * 0.5, ScrH() * 0.55 + DebugWepH)
        surface.DrawText(LocalPlayer():Health() .. "/" .. LocalPlayer():GetMaxHealth() .. " HP  |  " .. LocalPlayer():Armor() .. "/" .. LocalPlayer():GetMaxArmor() .. "AP")
    end
end )