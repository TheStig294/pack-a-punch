local UPGRADE = {}
UPGRADE.id = "no_u"
UPGRADE.class = "weapon_unoreverse"
UPGRADE.name = "no u"
UPGRADE.desc = "Lasts longer"
UPGRADE.noSelectWep = true

UPGRADE.convars = {
    {
        name = "pap_no_u_length_mult",
        type = "float",
        decimals = 1
    }
}

local lengthMult = CreateConVar("pap_no_u_length_mult", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Length multiplier", 0.1, 5)

function UPGRADE:Apply(SWEP)
    SWEP.UnoReverseLength = GetConVar("ttt_uno_reverse_length"):GetInt() * lengthMult:GetFloat()

    if CLIENT then
        SWEP.VElements.v_element.material = TTTPAP.camo
        SWEP.WElements.w_element.material = TTTPAP.camo
    end
end

TTTPAP:Register(UPGRADE)