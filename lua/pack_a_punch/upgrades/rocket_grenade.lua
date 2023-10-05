local UPGRADE = {}
UPGRADE.id = "rocket_grenade"
UPGRADE.class = "weapon_ttt_liftgren"
UPGRADE.name = "Rocket Grenade"
UPGRADE.desc = "Launches players into the sky!"

function UPGRADE:Apply(SWEP)
    function SWEP:GetGrenadeName()
        return "ttt_pap_liftgren_proj"
    end
end

TTTPAP:Register(UPGRADE)