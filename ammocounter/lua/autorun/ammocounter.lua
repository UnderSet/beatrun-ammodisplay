-- Rewriting the HUD I used to make. Or at least, as much of it as I possibly can myself.
local hidden = CreateClientConVar("PKAmmoDisp_Hide", "0", true, false, "Blocks the ammo counter from rendering", 0, 2)
local sway = CreateClientConVar("PKAmmoDisp_Sway", "1", true, false, "Display HUD swaying", 0, 1)
local dynamic = CreateClientConVar("PKAmmoDisp_Dynamic", "0", true, false, "Hide HUD when moving (why the frick would you enable this?)", 0, 1)
local PerfDisplay = CreateClientConVar("PKAmmoDisp_PerfDisplay", "1", true, false, "Displays some miscellaneous stuff on your monitor/game window's top right.")
local NoBlur = CreateClientConVar("PKAmmoDisp_NoBlur", "0", true, false, "Disables blur effects. Only works on DX9+ (Windows) and Linux, as blur doesn't work with DX8 and below. Gives like 2fps or something. Does not affect Beatrun.")

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

-- Does the user have the supported weapon bases installed?
if DoesConVarExist("arc9_precache_sounds_onfirsttake") then
    print("ARC9 is installed!")             -- ARC9
    ARC9Installed = true
end
if DoesConVarExist("arccw_automaticreload") then
    print("ArcCW is installed!")            -- ArcCW (aka Arctic's Customizable Weaponry)
    ArcCWInstalled = true
end
if DoesConVarExist("cl_tfa_hud_enabled") then
    print("TFA Base is installed!")         -- TFA Base
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
    surface.CreateFont("funnitextbeeg", {
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

    surface.CreateFont("funnitexttiny", {
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

    surface.CreateFont("funnitexthuge", {
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

local function funnihud()
    local ply = LocalPlayer()
	local scrw = ScrW()
	local scrh = ScrH()

    hidealpha = math.Approach(hidealpha, 150 * ply:GetVelocity():Length() / 250, 100 * RealFrameTime())

    local lastframetime = (math.floor(math.Round(FrameTime(), 4) * 1000))
    framerate = math.Round(math.Approach(framerate, math.ceil(1 / FrameTime()), FrameTime() * 10000))

    scale = ScrH() / 1080

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
        surface.DrawRect(24 * scale + vp.z, scrh * BlurHeight + 0.0045 + vp.x, scale * 35, scale *14)
        surface.DrawRect(62 * scale + vp.z, scrh * BlurHeight + 0.0045 + vp.x, scale * 35, scale* 14)
        surface.DrawRect(100 * scale + vp.z, scrh * BlurHeight + 0.0045 + vp.x, scale * 35, scale* 14)
        surface.DrawRect(138 * scale + vp.z, scrh * BlurHeight + 0.0045 + vp.x, scale * 35, scale * 14)

        if ply:Armor() > 15 then
            surface.SetDrawColor(corner_color_c)
        else
            surface.SetDrawColor(230,0,0,corner_color_c.a)
        end
        surface.DrawRect(24 * scale + vp.z, scrh * BlurHeight + 0.0045 + vp.x, scale * (1.40 * armorsegment), scale * 14)
        surface.DrawRect(62 * scale + vp.z, scrh * BlurHeight + 0.0045 + vp.x, scale * (1.40 * armorsegment1), scale * 14)
        surface.DrawRect(100 * scale + vp.z, scrh * BlurHeight + 0.0045 + vp.x, scale * (1.40 * armorsegment2), scale * 14)
        surface.DrawRect(138 * scale + vp.z, scrh * BlurHeight + 0.0045 + vp.x, scale * (1.40 * armorsegment3), scale * 14)
        
        armor_color = nil
        if ply:Armor() > 15 then
            armor_color = text_color
        else
            armor_color = string.ToColor("230 0 0 " .. corner_color_c.a)
        end
        if ply:Armor() < 10 then
            surface.SetTextPos(182 * scale + vp.z, scrh * BlurHeight + 0.002 + vp.x)
            surface.SetTextColor(120,120,120,armorbackground.a)
            surface.DrawText("00")
            surface.SetTextColor(armor_color)
            surface.DrawText(ply:Armor())
        elseif ply:Armor() < 100 then
            surface.SetTextPos(182 * scale + vp.z, scrh * BlurHeight + 0.002 + vp.x)
            surface.SetTextColor(120,120,120,armorbackground.a)
            surface.DrawText("0")
            surface.SetTextColor(armor_color)
            surface.DrawText(ply:Armor())
        else
            surface.SetTextPos(182 * scale + vp.z, scrh * BlurHeight + 0.002 + vp.x)
            surface.SetTextColor(armor_color)
            surface.DrawText(ply:Armor())
        end
    end

    if PerfDisplay:GetBool() then
        local text1 = nil
        if GetConVar("fps_max"):GetInt() ~= 0 then
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
end