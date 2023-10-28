local UPGRADE = {}
UPGRADE.id = "fast_motion_grenade"
UPGRADE.class = "weapon_ttt_timeslowgrenade"
UPGRADE.name = "Fast Motion Grenade"
UPGRADE.desc = "Speeds everything up instead!"

UPGRADE.convars = {
    {
        name = "pap_fast_motion_grenade_speed_mult",
        type = float
    }
}

function UPGRADE:Apply(SWEP)
    function SWEP:GetGrenadeName()
        return "ttt_fast_motion_grenade_proj"
    end
end

TTTPAP:Register(UPGRADE)