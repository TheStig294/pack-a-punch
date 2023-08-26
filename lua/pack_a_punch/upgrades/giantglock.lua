local UPGRADE = {}
UPGRADE.id = "giantglock"
UPGRADE.classname = "tfa_dax_big_glock"
UPGRADE.name = "Giant Glock"
UPGRADE.desc = "Appears so big for everyone else you're a walking gun..."
UPGRADE.firerateMult = 1

function UPGRADE:Apply(SWEP)
    local scale = 10
    local i = 0

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