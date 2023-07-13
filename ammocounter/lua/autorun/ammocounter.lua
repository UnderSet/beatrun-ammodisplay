--This is my attempt at making a one-file ammo counter HUD that fits Beatrun well.
--I wanna kill myself for making this thing.

--Uses some ARC9 code. See line 167 for details.
local hidden = CreateClientConVar("funniammocounter_hide", "0", true, false, "Blocks the funni ammo counter I made from rendering", 0, 2)
local sway = CreateClientConVar("funniamocounter_sway", "1", true, false, "Display HUD swaying", 0, 1)
local dynamic = CreateClientConVar("funniammocounter_dynamic", "0", true, false, "Hide HUD when moving", 0, 1)
local alignbias = CreateClientConVar("funniammocounter_rightalign", "0", true, false, "DEBUG: Text right align", 0, 1)

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
    surface.SetDrawColor(128, 128, 128, 96)
    surface.DrawRect(scrw * 0.5 + vp.z - 450 * scale, scrh * 0.965 + vp.x, 900 * scale, 4 * scale)
    if playervel <= 300 then -- "Wonderful" bar-style speedometer, as shown in some early Beatrun videos.
        surface.SetDrawColor(128, 128, 128, 146)
        surface.DrawRect(scrw * 0.5 + vp.z - (playervel / 2 * scale), scrh * 0.965 + vp.x, playervel * scale, 4 * scale)
    elseif playervel > 300 and playervel <= 700 then
        surface.SetDrawColor(220, 154, 13, 147)
        surface.DrawRect(scrw * 0.5 + vp.z - (playervel / 2 * scale), scrh * 0.964 + vp.x, playervel * scale, 6 * scale)
    elseif playervel > 700 and playervel < 900 then
        surface.SetDrawColor(210, 155, 36, 192)
        surface.DrawRect(scrw * 0.5 + vp.z - (playervel / 2 * scale), scrh * 0.963 + vp.x, playervel * scale, 8 * scale)
    elseif playervel >= 900 then
        surface.SetDrawColor(252, 202, 95)
        surface.DrawRect(scrw * 0.5 + vp.z - 900 / 2, scrh * 0.963 + vp.x, 900 * scale, 8 * scale)
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
        infmag2 = (math.Clamp(ply:GetAmmoCount(weapon:GetPrimaryAmmoType()), 0, 9999))
    end

    local melee = false
    local infmag = false

    if ammo1type == -1 and max1mag <= 0 then -- Taken and modified from ARC9 base, see: https://github.com/HaodongMo/ARC-9/blob/main/lua/arc9/client/cl_hud.lua#L692C1-L695C8
        melee = true
    elseif ammo1type ~= -1 and max1mag <= 0 then
        infmag = true
    end    
    
    if (not hidden:GetBool() and ply:IsValid() and ply:Alive() and not melee) then
		if dynamic:GetBool() then
			hidealpha = math.Approach(hidealpha, 150 * ply:GetVelocity():Length() / 250, 100 * RealFrameTime())
		else
			hidealpha = 0
		end

        local magrate = ammo1 / weapon:GetMaxClip1()
        local lowamount = weapon:GetMaxClip1() / 3

        CreateClientConVar("funniammocounter_cornercolor", "65 124 174 124", true, false, "Ammo counter corner color.")
        CreateClientConVar("funniammocounter_ammobarcolor", "85 144 194 200", true, false, "Ammo bar color.")
        CreateClientConVar("funniammocounter_textcolor", "255 255 255 255", true, false, "Ammo counter text color.")
        --local ammobarcolor = nil

	    local bgpadding = bgpadw > 200 and bgpadw + 40 or 200
    
        local corner_color_c = string.ToColor(LocalPlayer():GetInfo("funniammocounter_cornercolor"))
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

        local text_color = string.ToColor(LocalPlayer():GetInfo("funniammocounter_textcolor"))
		text_color.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or text_color.a

        surface.SetTextColor(text_color)
        surface.SetTextPos(rscrbor - speedlengthw + vp.z, scrh * 0.95 + vp.x)
        --surface.DrawText(speedtext)

        if not infmag then
            surface.SetFont("funnitextbeeg")
            local resrvw, resrvh = surface.GetTextSize(ammo1mag)
            surface.SetTextPos(rscrbor - resrvw + vp.z, scrh * 0.91 + vp.x)
            if ammo1mag == 0 then
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
                surface.DrawRect(scrw * 0.911 + vp.z, scrh * 0.94 + vp.x, 150 * scale, scale * 5)
                surface.SetDrawColor(255, 0, 0, 230)
                surface.DrawRect(scrw * 0.911 + vp.z, scrh * 0.94 + 1 + vp.x, 150 * scale * magrate, scale * 5)
                surface.SetDrawColor(corner_color_c)
            elseif ammo1 ~= -1 then
                surface.SetDrawColor(10, 50, 50, 100)
                surface.DrawRect(scrw * 0.911 + vp.z, scrh * 0.94 + vp.x, 150 * scale, scale * 5)
                surface.SetDrawColor(string.ToColor(LocalPlayer():GetInfo("funniammocounter_ammobarcolor")), math.max(255 - hidealpha, 2))
                surface.DrawRect(scrw * 0.911 + vp.z, scrh * 0.94 + 1 + vp.x, 150 * scale * magrate, scale * 5)
                surface.SetDrawColor(corner_color_c)
            end

            surface.SetDrawColor(corner_color_c)
            surface.DrawRect(scrw * 0.761 + scale * bgpadding + vp.z, scrh * 0.895 + vp.x, 20 * scale, scale * 85)
            DrawBlurRect2(scrw * 0.80 + vp.z, scrh * 0.895 + vp.x, scale * 125, scale * 85, math.max(255 - hidealpha, 2))
    
            surface.SetDrawColor(corner_color_c)
            surface.DrawOutlinedRect(scrw * 0.80 + vp.z, scrh * 0.895 + vp.x, scale * 125, scale * 85)
            
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

            if ammo1mag == 0 then
                surface.SetDrawColor(255, 0, 0, 230)
                surface.DrawRect(scrw * 0.911 + vp.z, scrh * 0.94 + 1 + vp.x, 150 * scale * magrate, scale * 5)
                surface.SetDrawColor(corner_color_c)
                surface.SetFont("funnitexttiny")
                local txtw, txth = surface.GetTextSize("NO MAGAZINE")
                surface.SetTextColor(255,255,255,255)
                surface.SetTextPos(rscrbor - txtw + vp.z, scrh * 0.93 + vp.x)
                surface.DrawText("NO MAGAZINE")
            else
                surface.SetDrawColor(string.ToColor(LocalPlayer():GetInfo("funniammocounter_ammobarcolor")), math.max(255 - hidealpha, 2))
                surface.DrawRect(scrw * 0.911 + vp.z, scrh * 0.94 + 1 + vp.x, 150 * scale * magrate, scale * 5)
                surface.SetDrawColor(corner_color_c)
                surface.SetFont("funnitexttiny")
                local txtw, txth = surface.GetTextSize("NO MAGAZINE")
                surface.SetTextColor(255,255,255,255)
                surface.SetTextPos(rscrbor - txtw + vp.z, scrh * 0.93 + vp.x)
                surface.DrawText("NO MAGAZINE")
            end
        end
        surface.SetTextPos(scrw * 0.5 + scale + vp.z, scrh * 0.6 + vp.x) -- Debugging stuff, enable if you're interested.
        surface.SetFont("funnitexttiny")
        surface.DrawText("DEBUG: MaxClip1: " .. weapon:GetMaxClip1())
        surface.SetTextPos(scrw * 0.5 + scale + vp.z, scrh * 0.62 + vp.x)
        surface.SetFont("funnitexttiny")
        surface.DrawText("DEBUG: PrimaryAmmoType: " .. weapon:GetPrimaryAmmoType())
        surface.SetTextPos(scrw * 0.5 + scale + vp.z, scrh * 0.64 + vp.x)
        surface.SetFont("funnitexttiny")
        surface.DrawText("DEBUG: MaxClip2: " .. weapon:GetMaxClip2())
        surface.SetTextPos(scrw * 0.5 + scale + vp.z, scrh * 0.66 + vp.x)
        surface.SetFont("funnitexttiny")
        surface.DrawText("DEBUG: SecondaryAmmoType: " .. weapon:GetSecondaryAmmoType())

        if melee then
            surface.SetDrawColor(255,255,255,255)
            surface.DrawRect(256, 256, 256, 256)
        end
        
    end
end

hook.Add("HUDPaint", "funnicounter", funnihud)