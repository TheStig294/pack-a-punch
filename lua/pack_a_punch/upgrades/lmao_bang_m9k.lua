local UPGRADE = {}
UPGRADE.id = "lmao_bang_m9k"
UPGRADE.class = "weapon_m9k_dbarrel"
UPGRADE.name = "Lmao Bang"
UPGRADE.desc = "x2 ammo, new gun shoot sounds!"
UPGRADE.noSound = true
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    SWEP.Primary.Sound = "ttt_pack_a_punch/lmao_bang/bang1.mp3"
    SWEP.Secondary.Sound = "ttt_pack_a_punch/lmao_bang/bang2.mp3"
end

TTTPAP:Register(UPGRADE)