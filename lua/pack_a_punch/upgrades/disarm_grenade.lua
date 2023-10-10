local UPGRADE = {}
UPGRADE.id = "disarm_grenade"
UPGRADE.class = "weapon_ttt_zapgren"
UPGRADE.name = "Disarm Grenade"
UPGRADE.desc = "Forces players to drop their weapons\nand cannot pickup new ones for a few secs"

UPGRADE.convars = {
    {
        name = "pap_disarm_grenade_time",
        type = "int"
    }
}

function UPGRADE:Apply(SWEP)
    function SWEP:GetGrenadeName()
        return "ttt_pap_disarm_grenade"
    end

    self:AddHook("PlayerCanPickupWeapon", function(ply, wep)
        if ply.PAPDisarmGrenade then return false end
    end)
end

TTTPAP:Register(UPGRADE)