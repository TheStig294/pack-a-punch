local UPGRADE = {}
UPGRADE.id = "no_u"
UPGRADE.class = "weapon_unoreverse"
UPGRADE.name = "no u"
UPGRADE.desc = "Lasts longer"

UPGRADE.convars = {
    {
        name = "pap_no_u_length_mult",
        type = "float",
        decimals = 1
    }
}

local lengthMult = CreateConVar("pap_no_u_length_mult", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Length multiplier", 0.1, 5)

function UPGRADE:Apply(SWEP)
    if SERVER then
        SWEP.UnoReverseLength = GetConVar("ttt_uno_reverse_length"):GetInt() * lengthMult:GetFloat()
    end
end

TTTPAP:Register(UPGRADE)