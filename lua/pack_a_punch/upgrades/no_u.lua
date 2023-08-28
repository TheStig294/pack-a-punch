local UPGRADE = {}
UPGRADE.id = "no_u"
UPGRADE.class = "weapon_unoreverse"
UPGRADE.name = "no u"
UPGRADE.desc = "Lasts twice as long"

function UPGRADE:Apply(SWEP)
    SWEP.UnoReverseLength = GetConVar("ttt_uno_reverse_length"):GetInt() * 2

    if CLIENT then
        SWEP.VElements.v_element.material = TTTPAP.camo
        SWEP.WElements.w_element.material = TTTPAP.camo
    end
end

TTTPAP:Register(UPGRADE)