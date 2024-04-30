local UPGRADE = {}
UPGRADE.id = "barrel_bomb"
UPGRADE.class = "weapon_ttt_clutterbomb"
UPGRADE.name = "Barrel Bomb"
UPGRADE.desc = "Always spawns explosive barrels!"

UPGRADE.convars = {
    {
        name = "pap_barrel_bomb_count",
        type = "int"
    }
}

function UPGRADE:Apply(SWEP)
    function SWEP:GetGrenadeName()
        return "ttt_pap_barrel_bomb_proj"
    end
end

TTTPAP:Register(UPGRADE)