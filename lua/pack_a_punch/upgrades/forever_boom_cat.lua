local UPGRADE = {}
UPGRADE.id = "forever_boom_cat"
UPGRADE.class = "weapon_ttt_boom_cat"
UPGRADE.name = "Forever Boom Cat"
UPGRADE.desc = "Lasts forever!"

function UPGRADE:Apply(SWEP)
    function SWEP:GetGrenadeName()
        return "ttt_pap_boom_cat_proj"
    end
end

TTTPAP:Register(UPGRADE)