TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

TTT_PAP_UPGRADES.weapon_ttt_hwapoon = {
    name = "Triple Hwapoon",
    desc = "Throw 3 hwapoons at once!",
    func = function(wep)
        if SERVER then
            wep.Primary.ClipSize = 3
            wep.Primary.ClipMax = 3
            wep.Primary.DefaultClip = 3
            wep:SetClip1(3)
        end
    end
}