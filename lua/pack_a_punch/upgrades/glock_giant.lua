local UPGRADE = {}
UPGRADE.id = "glock_giant"
UPGRADE.class = "tfa_dax_big_glock"
UPGRADE.name = "Giant Glock"
UPGRADE.desc = "Appears HUGE for everyone else, or when on the ground!"

UPGRADE.convars = {
    {
        name = "pap_glock_giant_scale",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_glock_giant_uses_camo",
        type = "bool"
    }
}

local scaleCvar = CreateConVar("pap_glock_giant_scale", "10", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Size scale multiplier", 1, 20)

local camoCvar = CreateConVar("pap_glock_giant_uses_camo", "1", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Apply the Pack-a-Punch camo/texture?", 0, 1)

function UPGRADE:Apply(SWEP)
    local scale = scaleCvar:GetFloat()
    local i = 0

    if not camoCvar:GetBool() then
        self.noCamo = true
    end

    while i < SWEP:GetBoneCount() do
        SWEP:ManipulateBoneScale(i, Vector(scale, scale, scale))
        i = i + 1
    end
end

TTTPAP:Register(UPGRADE)