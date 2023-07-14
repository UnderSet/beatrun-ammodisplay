--This is my attempt at making a one-file ammo counter HUD that fits Beatrun well.
--I wanna kill myself for making this thing.

--Uses some ARC9 code. See line 167 for details.
local hidden = CreateClientConVar("PKAmmoDisp_Hide", "0", true, false, "Blocks the ammo counter from rendering", 0, 2)
local sway = CreateClientConVar("PKAmmoDisp_Sway", "1", true, false, "Display HUD swaying", 0, 1)
local dynamic = CreateClientConVar("PKAmmoDisp_Dynamic", "0", true, false, "Hide HUD when moving", 0, 1)
local showspeed = CreateClientConVar("PKAmmoDisp_Speedometer", "0", true, false, "Show a speedometer at the bottom of the display", 0, 1)

local hide = {
    CHudAmmo = true,
    CHudSecondaryAmmo = true
}

hook.Add("HUDShouldDraw", "hidefunnyshit", function(name)
	if hide[name] then return false end
end)

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
	size = ScreenScale(7)
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
	size = ScreenScale(6)
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
	size = ScreenScale(12)
})

local blur = Material("pp/blurscreen")

local function DrawBlurRect2(x, y, w, h, a)
	if render.GetDXLevel() < 90 then return end

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

local hidealpha = 0

local function funnihud()
    local ply = LocalPlayer()
	local scrw = ScrW()
	local scrh = ScrH()

    local scale = ScrH() / 1080

	if hidden:GetInt() > 1 then return end
    
	local vp = ply:GetViewPunchAngles()

	if not sway:GetBool() then
		vp.x = 0
		vp.z = 0
	end

    nicktext = ply:Nick()

    surface.SetFont("funnitexttiny")

    local nickw, nickh = surface.GetTextSize(nicktext)

    surface.SetFont("funnitextbeeg")

	--local coursew, _ = surface.GetTextSize(coursename)
	local bgpadw = nickw
	-- local bgpadh = nickh

	--[[if bgpadw < coursew then
		bgpadw = coursew
	end
    ]]
    

    local playervel = ply:GetVelocity():Length2D()
    local roundvel = math.Round(ply:GetVelocity():Length2D())
    local speedtext = math.Round(ply:GetVelocity():Length2D() * 0.06858125) .. " km/h"
    local spedtext = roundvel .. " u/s (" .. speedtext .. ")"
    local spedw = nil

    if showspeed:GetBool() then
        surface.SetDrawColor(128, 128, 128, 96)
        surface.DrawRect(scrw * 0.5 + vp.z - 450 * scale, scrh * 0.965 + vp.x, 900 * scale, 1 * scale)
        local drawcolor = nil
        if playervel <= 300 then -- "Wonderful" bar-style speedometer, as shown in some early Beatrun videos.
            surface.SetDrawColor(128, 128, 128, 146)
            surface.DrawRect(scrw * 0.5 + vp.z - (playervel / 2 * scale), scrh * 0.965 + vp.x, playervel * scale, 4 * scale)
            surface.SetTextColor(128, 128, 128, 146)
            surface.SetFont("funnitextbeeg")
            local spedw = surface.GetTextSize(spedtext)
            surface.SetTextPos(scrw * 0.5 - (spedw / 2) + vp.x, scrh * 0.947 + vp.z)
            surface.DrawText(spedtext)
        elseif playervel > 300 and playervel <= 700 then
            surface.SetDrawColor(220, 154, 13, 147)
            surface.DrawRect(scrw * 0.5 + vp.z - (playervel / 2 * scale), scrh * 0.964 + vp.x, playervel * scale, 6 * scale)
            surface.SetTextColor(220, 154, 13, 147)
            surface.SetFont("funnitextbeeg")
            local spedw = surface.GetTextSize(spedtext)
            surface.SetTextPos(scrw * 0.5 - (spedw / 2) + vp.x, scrh * 0.947 + vp.z)
            surface.DrawText(spedtext)
        elseif playervel > 700 and playervel < 900 then
            surface.SetDrawColor(210, 155, 36, 192)
            surface.DrawRect(scrw * 0.5 + vp.z - (playervel / 2 * scale), scrh * 0.963 + vp.x, playervel * scale, 8 * scale)
            surface.SetTextColor(210, 155, 36, 192)
            surface.SetFont("funnitextbeeg")
            local spedw = surface.GetTextSize(spedtext)
            surface.SetTextPos(scrw * 0.5 - (spedw / 2) + vp.x, scrh * 0.947 + vp.z)
            surface.DrawText(spedtext)
        elseif playervel >= 900 then
            surface.SetDrawColor(252, 202, 95)
            surface.DrawRect(scrw * 0.5 + vp.z - 900 / 2, scrh * 0.963 + vp.x, 900 * scale, 8 * scale)
            surface.SetTextColor(252, 202, 95)
            surface.SetFont("funnitextbeeg")
            local spedw = surface.GetTextSize(spedtext)
            surface.SetTextPos(scrw * 0.5 - (spedw / 2) + vp.x, scrh * 0.947 + vp.z)
            surface.DrawText(spedtext)
        end
    end

    local weapon = ply:GetActiveWeapon()
    local ammo1, ammo1mag, ammo2, ammo2mag, hasSecondaryAmmoType = -1, -1, -1, -1, false;
    if (IsValid(weapon)) then
        ammo1 = math.Clamp(weapon:Clip1(), -1, 9999)
        ammo1mag = ("/" .. math.Clamp(ply:GetAmmoCount(weapon:GetPrimaryAmmoType()), 0, 9999))
        ammo2 = math.Clamp(weapon:Clip2(), -1, 9999)
        ammo2mag = ("/" .. math.Clamp(ply:GetAmmoCount(weapon:GetSecondaryAmmoType()), 0, 9999))
        hasSecondaryAmmoType = false
        ammo1type = weapon:GetPrimaryAmmoType()
        ammo2type = weapon:GetSecondaryAmmoType()
        max1mag = weapon:GetMaxClip1()
        maxmag2 = weapon:GetMaxClip2()
        infmag2 = (math.Clamp(ply:GetAmmoCount(weapon:GetPrimaryAmmoType()), 0, 9999))
        infmag3 = (math.Clamp(ply:GetAmmoCount(weapon:GetSecondaryAmmoType()), 0, 9999))
    end

    local melee = false
    local infmag = false
    local HasAltFire = false
    local UsesAltMag = 0

    if ammo1type == -1 and max1mag <= 0 then -- Taken and modified from ARC9 base, see: https://github.com/HaodongMo/ARC-9/blob/main/lua/arc9/client/cl_hud.lua#L692C1-L695C8
        melee = true
    elseif ammo1type ~= -1 and max1mag <= 0 then
        infmag = true
    end    

    if ammo2type == -1 then
        HasAltFire = false
    elseif ammo2type ~= -1 and maxmag2 <= 0 then
        HasAltFire = true
    elseif ammo2type ~= -1 and maxmag2 > 0 then
        HasAltFire = true
        UsesAltMag = 1
    end
    
    if (not hidden:GetBool() and ply:IsValid() and ply:Alive() and not melee) then
		if dynamic:GetBool() then
			hidealpha = math.Approach(hidealpha, 150 * ply:GetVelocity():Length() / 250, 100 * RealFrameTime())
		else
			hidealpha = 0
		end

        local magrate = ammo1 / weapon:GetMaxClip1()
        local magrate2 = ammo2 / weapon:GetMaxClip2()
        local lowamount = weapon:GetMaxClip1() / 3

        CreateClientConVar("PKAmmoDisp_CornerColor", "65 124 174 124", true, false, "Ammo counter corner color.")
        CreateClientConVar("PKAmmoDisp_AmmobarColor", "85 144 194 200", true, false, "Ammo bar color.")
        CreateClientConVar("PKAmmoDisp_TextColor", "255 255 255 255", true, false, "Ammo counter text color.")
        --local ammobarcolor = nil

	    local bgpadding = bgpadw > 200 and bgpadw + 40 or 200
    
        local corner_color_c = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_CornerColor"))
        corner_color_c.a = math.Clamp(corner_color_c.a + 50, 0, 255)
        corner_color_c.a = dynamic:GetBool() and math.max(150 - hidealpha, 50) or corner_color_c.a

        surface.SetDrawColor(corner_color_c)
        surface.DrawRect(scrw * 0.886 + scale * bgpadding + vp.z, scrh * 0.895 + vp.x, 40 * scale, scale * 85)
        DrawBlurRect2(scrw * 0.886 + vp.z, scrh * 0.895 + vp.x, scale * bgpadding, scale * 85, math.max(255 - hidealpha, 2))

        surface.SetDrawColor(corner_color_c)
        surface.DrawOutlinedRect(scrw * 0.886 + vp.z, scrh * 0.895 + vp.x, scale * bgpadding, scale * 85)

        local speedtext = math.Round(ply:GetVelocity():Length2D() * 0.06858125) .. " km/h"
        local speedlengthw, speedlengthh = surface.GetTextSize(speedtext)
        --print(speedlengthw .. "   " .. speedlengthh)
        local rscrbor = scrw * 0.986

        local text_color = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_TextColor"))
		text_color.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or text_color.a

        surface.SetTextColor(text_color)
        surface.SetTextPos(rscrbor - speedlengthw + vp.z, scrh * 0.95 + vp.x)
        --surface.DrawText(speedtext)

        if not infmag then
            surface.SetFont("funnitextbeeg")
            local resrvw, resrvh = surface.GetTextSize(ammo1mag)
            surface.SetTextPos(rscrbor - resrvw + vp.z, scrh * 0.91 + vp.x)
            if infmag2 == 0 then
                surface.SetTextColor(255,0,0,255)
                surface.DrawText(ammo1mag)
                surface.SetTextColor(text_color)
            else
                surface.DrawText(ammo1mag)
            end

            surface.SetFont("funnitexthuge")
            local magw, magh = surface.GetTextSize(ammo1)
            surface.SetTextPos(rscrbor - resrvw - magw + vp.z, scrh * 0.9 + vp.x)
            if ammo1 < weapon:GetMaxClip1() / 3 then
                surface.SetTextColor(255,0,0,255)
                surface.DrawText(ammo1)
                surface.SetTextColor(text_color)
                --ammobarcolor = "220 0 0 255"
            else
                surface.DrawText(ammo1)
            end

            if ammo1 ~= -1 and ammo1 < (weapon:GetMaxClip1() / 3) then
                surface.SetDrawColor(200, 30, 30, 100)
                surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.938 + vp.x, 150 * scale, scale * 5)
                surface.SetDrawColor(255, 0, 0, 230)
                surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.938 + 1 + vp.x, 150 * scale * magrate, scale * 5)
                surface.SetDrawColor(corner_color_c)
            elseif ammo1 ~= -1 then
                surface.SetDrawColor(10, 50, 50, 100)
                surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.938 + vp.x, 150 * scale, scale * 5)
                surface.SetDrawColor(string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_AmmobarColor")), math.max(255 - hidealpha, 2))
                surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.938 + 1 + vp.x, 150 * scale * magrate, scale * 5)
                surface.SetDrawColor(corner_color_c)
            end

            if HasAltFire and UsesAltMag == 0 then
                surface.SetDrawColor(corner_color_c)
                surface.DrawRect(scrw * 0.76025 + scale * bgpadding + vp.z, scrh * 0.895 + vp.x, 25 * scale, scale * 85)
                DrawBlurRect2(scrw * 0.80 + vp.z, scrh * 0.895 + vp.x, scale * 125, scale * 85, math.max(255 - hidealpha, 2))
                surface.SetDrawColor(corner_color_c)
                surface.DrawOutlinedRect(scrw * 0.80 + vp.z, scrh * 0.895 + vp.x, scale * 125, scale * 85)

                surface.SetFont("funnitexthuge")
                local mag2w, mag2h = surface.GetTextSize(infmag3)
                surface.SetTextPos(scrw * 0.86 - mag2w + vp.z, scrh * 0.9 + vp.x)
                if infmag3 == 0 then
                    surface.SetTextColor(255,0,0,255)
                    surface.DrawText(infmag3)
                    surface.SetTextColor(text_color)
                    --ammobarcolor = "220 0 0 255"
                else
                    surface.DrawText(infmag3)
                end

                if infmag2 == 0 then
                    surface.SetDrawColor(255, 0, 0, 230)
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale * magrate2, scale * 5)
                    surface.SetDrawColor(corner_color_c)
                else
                    surface.SetDrawColor(string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_AmmobarColor")), math.max(255 - hidealpha, 2))
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale * magrate2, scale * 5)
                    surface.SetDrawColor(corner_color_c)
                end
            elseif HasAltFire and UsesAltMag == 1 then
                surface.SetDrawColor(corner_color_c)
                surface.DrawRect(scrw * 0.76025 + scale * bgpadding + vp.z, scrh * 0.895 + vp.x, 23 * scale, scale * 85)
                DrawBlurRect2(scrw * 0.788 + vp.z, scrh * 0.895 + vp.x, scale * 149, scale * 85, math.max(255 - hidealpha, 2))
                surface.SetDrawColor(corner_color_c)
                surface.DrawOutlinedRect(scrw * 0.788 + vp.z, scrh * 0.895 + vp.x, scale * 149, scale * 85)

                surface.SetFont("funnitextbeeg")
                local resrv2w, resrv2h = surface.GetTextSize(ammo2mag)
                surface.SetTextPos(scrw * 0.86 - resrv2w + vp.z, scrh * 0.91 + vp.x)
                if infmag3 == 0 then
                    surface.SetTextColor(255,0,0,255)
                    surface.DrawText(ammo2mag)
                    surface.SetTextColor(text_color)
                else
                    surface.DrawText(ammo2mag)
                end
    
                surface.SetFont("funnitexthuge")
                local mag2w, mag2h = surface.GetTextSize(ammo2)
                surface.SetTextPos(scrw * 0.86 - resrv2w - mag2w + vp.z, scrh * 0.9 + vp.x)
                if ammo2 < weapon:GetMaxClip2() / 3 then
                    surface.SetTextColor(255,0,0,255)
                    surface.DrawText(ammo2)
                    surface.SetTextColor(text_color)
                    --ammobarcolor = "220 0 0 255"
                else
                    surface.DrawText(ammo2)
                end

                if ammo2 ~= -1 and ammo2 < (weapon:GetMaxClip2() / 3) then
                    surface.SetDrawColor(200, 30, 30, 100)
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale, scale * 5)
                    surface.SetDrawColor(255, 0, 0, 230)
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale * magrate2, scale * 5)
                    surface.SetDrawColor(corner_color_c)
                elseif ammo2 ~= -1 then
                    surface.SetDrawColor(10, 50, 50, 100)                    
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale, scale * 5)
                    surface.SetDrawColor(string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_AmmobarColor")), math.max(255 - hidealpha, 2))
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale * magrate2, scale * 5)
                    surface.SetDrawColor(corner_color_c)
                end
            end
            --print(bgpadding)
        elseif infmag then
            --[[surface.SetFont("funnitextbeeg")
            local resrvw, resrvh = surface.GetTextSize(ammo1mag)
            surface.SetTextPos(rscrbor - resrvw + vp.z, scrh * 0.91 + vp.x)
            if ammo1mag == 0 then
                surface.SetTextColor(255,0,0,255)
                surface.DrawText(ammo1mag)
                surface.SetTextColor(text_color)
            else
                surface.DrawText(ammo1mag)
            end
            ]]

            surface.SetFont("funnitexthuge")
            local magw, magh = surface.GetTextSize(infmag2)
            surface.SetTextPos(rscrbor - magw + vp.z, scrh * 0.9 + vp.x)
            if infmag2 == 0 then
                surface.SetTextColor(255,0,0,255)
                surface.DrawText(infmag2)
                surface.SetTextColor(text_color)
                --ammobarcolor = "220 0 0 255"
            else
                surface.DrawText(infmag2)
            end

            if infmag2 == 0 then
                surface.SetDrawColor(255, 0, 0, 230)
                surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.94 + 1 + vp.x, 150 * scale * magrate, scale * 5)
                surface.SetDrawColor(corner_color_c)
                surface.SetFont("funnitexttiny")
                local txtw, txth = surface.GetTextSize("NO MAGAZINE")
                surface.SetTextColor(255,255,255,255)
                surface.SetTextPos(rscrbor - txtw + vp.z, scrh * 0.93 + vp.x)
                surface.DrawText("NO MAGAZINE")
            else
                surface.SetDrawColor(string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_AmmobarColor")), math.max(255 - hidealpha, 2))
                surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.94 + 1 + vp.x, 150 * scale * magrate, scale * 5)
                surface.SetDrawColor(corner_color_c)
                surface.SetFont("funnitexttiny")
                local txtw, txth = surface.GetTextSize("NO MAGAZINE")
                surface.SetTextColor(255,255,255,255)
                surface.SetTextPos(rscrbor - txtw + vp.z, scrh * 0.93 + vp.x)
                surface.DrawText("NO MAGAZINE")
            end
        end

        if melee then
            surface.SetDrawColor(255,255,255,255)
            surface.DrawRect(256, 256, 256, 256)
        end
        
    end
end

hook.Add("HUDPaint", "funnicounter", funnihud)

local DispSegments = { -- Element alighment helpers, used while debugging
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

local debug = CreateClientConVar("PKAmmoDisp_Debug", "0", true, false, "Enable some debugging functions\nWARNING: Will cause a lot of Lua errors on death.", 0, 1)

hook.Add( "HUDPaint", "drawsegment", function( name )
    local scale = ScrH() / 1080

    if debug:GetBool() then
        local weapon = ply:GetActiveWeapon()
        local ammo1, ammo1mag, ammo2, ammo2mag, hasSecondaryAmmoType = -1, -1, -1, -1, false;
        for i=1,#DispSegments do
            surface.SetDrawColor(255,255,255,255)
            surface.DrawRect(ScrW() * DispSegments[i], 1, 1, ScrH()) 
            surface.DrawRect(1, ScrH() * DispSegments[i], ScrW(), 1) 
            surface.SetDrawColor(255,255,255,128)
            surface.DrawRect(ScrW() * (DispSegments[i] + 0.025), 1, 1, ScrH()) 
            surface.DrawRect(1, ScrH() * (DispSegments[i] + 0.025), ScrW(), 1) 
        end
        surface.SetTextPos(ScrW() * 0.5 + scale, ScrH() * 0.6) -- Debugging stuff, enable if you're interested.
        surface.SetFont("funnitexttiny")
        surface.DrawText("DEBUG: MaxClip1: " .. weapon:GetMaxClip1())
        surface.SetTextPos(ScrW() * 0.5 + scale, ScrH() * 0.62)
        surface.SetFont("funnitexttiny")
        surface.DrawText("DEBUG: PrimaryAmmoType: " .. weapon:GetPrimaryAmmoType())
        surface.SetTextPos(ScrW() * 0.5 + scale, ScrH() * 0.64)
        surface.SetFont("funnitexttiny")
        surface.DrawText("DEBUG: MaxClip2: " .. weapon:GetMaxClip2())
        surface.SetTextPos(ScrW() * 0.5 + scale, ScrH() * 0.66)
        surface.SetFont("funnitexttiny")
        surface.DrawText("DEBUG: SecondaryAmmoType: " .. weapon:GetSecondaryAmmoType())
    end
end )