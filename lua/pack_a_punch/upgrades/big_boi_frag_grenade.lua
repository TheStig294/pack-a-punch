local UPGRADE = {}
UPGRADE.id = "big_boi_frag_grenade"
UPGRADE.class = "weapon_ttt_frag"
UPGRADE.name = "Big Boi Frag Grenade"

local radiusCvar = CreateConVar("pap_big_boi_frag_grenade_radius", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Explosion radius", 0, 10)

UPGRADE.desc = "x" .. radiusCvar:GetFloat() .. " explosion radius!"

UPGRADE.convars = {
    {
        name = "pap_big_boi_frag_grenade_radius",
        type = "float",
        decimals = 1
    }
}

function UPGRADE:Apply(SWEP)
    if SERVER then
        function SWEP:GetGrenadeName()
            return "ttt_pap_big_boi_frag"
        end
    end
end

TTTPAP:Register(UPGRADE)