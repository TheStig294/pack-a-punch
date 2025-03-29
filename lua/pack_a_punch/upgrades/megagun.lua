local UPGRADE = {}
UPGRADE.id = "megagun"
UPGRADE.class = "weapon_minigun"
UPGRADE.name = "Megagun"
UPGRADE.desc = "Appears HUGE for everyone else, all stats up!"
UPGRADE.firerateMult = 1.2
UPGRADE.damageMult = 1.1
UPGRADE.spreadMult = 1.3
UPGRADE.ammoMult = 1.5
UPGRADE.recoilMult = 0.75

UPGRADE.convars = {
    {
        name = "pap_megagun_scale",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_megagun_uses_camo",
        type = "bool"
    }
}

local scaleCvar = CreateConVar("pap_megagun_scale", "10", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Size scale multiplier", 1, 20)

local camoCvar = CreateConVar("pap_megagun_uses_camo", "1", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Apply the Pack-a-Punch camo/texture?", 0, 1)

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