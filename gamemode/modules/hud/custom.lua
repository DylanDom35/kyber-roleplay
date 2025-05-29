hook.Add("HUDPaint", "Kyber_CustomHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local hp = math.Clamp(ply:Health(), 0, 100)
    local armor = math.Clamp(ply:Armor(), 0, 100)
    local scrW, scrH = ScrW(), ScrH()

    -- === Left Circle: Health + Armor ===
    draw.RoundedBox(8, 20, scrH - 120, 100, 100, Color(10, 10, 10, 180))

    draw.SimpleText("♥", "DermaLarge", 70, scrH - 100, Color(200, 0, 0, 200), TEXT_ALIGN_CENTER)
    draw.SimpleText(hp, "Trebuchet24", 70, scrH - 70, Color(255, 255, 255), TEXT_ALIGN_CENTER)

    draw.SimpleText("⛨", "DermaLarge", 30, scrH - 100, Color(0, 100, 200, 200), TEXT_ALIGN_CENTER)
    draw.SimpleText(armor, "Trebuchet24", 30, scrH - 70, Color(255, 255, 255), TEXT_ALIGN_CENTER)

    -- === Right Circle: Weapon Icon ===
    draw.RoundedBox(8, scrW - 120, scrH - 120, 100, 100, Color(10, 10, 10, 180))

    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then
        local clip = wep:Clip1() or 0
        local max = wep:GetMaxClip1() or 0
        local ammoColor = clip == 0 and Color(255, 0, 0) or Color(255, 255, 0)

        draw.SimpleText(wep:GetPrintName() or "No Weapon", "Trebuchet18", scrW - 70, scrH - 100, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        draw.SimpleText(clip .. "/" .. max, "Trebuchet24", scrW - 70, scrH - 70, ammoColor, TEXT_ALIGN_CENTER)
    end
end)

-- Disable default HUD
local hide = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudAmmo"] = true,
    ["CHudSecondaryAmmo"] = true
}
hook.Add("HUDShouldDraw", "Kyber_HideDefaultHUD", function(name)
    if hide[name] then return false end
end)
