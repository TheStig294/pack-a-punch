local UPGRADE = {}
UPGRADE.id = "giant_glock"
UPGRADE.class = "tfa_dax_big_glock"
UPGRADE.name = "Giant Glock"
UPGRADE.desc = "Appears HUGE for everyone else, or when on the ground!"

UPGRADE.convars = {
    {
        name = "ttt_pap_giant_glock_scale",
        type = "float",
        decimals = 1
    },
    {
        name = "ttt_pap_giant_glock_use_camo",
        type = "bool"
    }
}

local scaleCvar = CreateConVar("ttt_pap_giant_glock_scale", "10", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Size scale multiplier", 1, 20)

local camoCvar = CreateConVar("ttt_pap_giant_glock_use_camo", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Apply the Pack-a-Punch camo/texture?", 0, 1)

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

function UPGRADE:Condition()
    local randomNum = math.random(1, 2)
    print("Upgrade condition random num:", randomNum)

    return randomNum == 1
end

TTTPAP:Register(UPGRADE)