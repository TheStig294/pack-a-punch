local UPGRADE = {}
UPGRADE.id = "blue_screen_grenade"
UPGRADE.class = "ttt_cmdpmpt"
UPGRADE.name = "Blue Screen Grenade"
UPGRADE.desc = "Causes a 'blue screen' to players caught in the blast for a few seconds"
UPGRADE.newClass = "weapon_ttt_blue_screen_grenade"

function UPGRADE:Apply(SWEP)
    SWEP.HoldType = "grenade"

    if CLIENT then
        SWEP.PrintName = "Blue Screen Grenade"
        SWEP.Slot = 3
        SWEP.ViewModelFlip = false
        SWEP.ViewModelFOV = 54
        SWEP.Icon = "vgui/ttt/icon_nades"
        SWEP.IconLetter = "h"
    end

    SWEP.Base = "weapon_tttbasegrenade"
    SWEP.WeaponID = AMMO_DISCOMB
    SWEP.Kind = WEAPON_NADE
    SWEP.Spawnable = true
    SWEP.AutoSpawnable = true
    SWEP.UseHands = true
    SWEP.ViewModel = "models/weapons/cstrike/c_eq_fraggrenade.mdl"
    SWEP.WorldModel = "models/weapons/w_eq_fraggrenade.mdl"
    SWEP.Weight = 5

    function SWEP:GetGrenadeName()
        return "ttt_pap_blue_screen_grenade"
    end
end

TTTPAP:Register(UPGRADE)