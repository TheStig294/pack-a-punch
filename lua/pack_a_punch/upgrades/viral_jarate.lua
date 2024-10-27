local UPGRADE = {}
UPGRADE.id = "viral_jarate"
UPGRADE.class = "weapon_ttt_jarate"
UPGRADE.name = "Viral Jarate"
UPGRADE.desc = "Larger splash area,\nspreads between nearby players, lasts forever!"

function UPGRADE:Apply(SWEP)
    function SWEP:GetGrenadeName()
        return "ttt_pap_jarate_proj"
    end
end

TTTPAP:Register(UPGRADE)