local UPGRADE = {}
UPGRADE.id = "reflex_revolver"
UPGRADE.class = "weapon_ttt_duel_revolver_randomat"
UPGRADE.name = "Reflex Revolver"
UPGRADE.desc = "x2 mouse sensitivity"

function UPGRADE:Apply(SWEP)
    function SWEP:AdjustMouseSensitivity()
        return 2
    end
end

TTTPAP:Register(UPGRADE)