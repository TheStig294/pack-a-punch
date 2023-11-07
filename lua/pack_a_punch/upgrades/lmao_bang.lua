local UPGRADE = {}
UPGRADE.id = "lmao_bang"
UPGRADE.class = "weapon_sp_dbarrel"
UPGRADE.name = "Lmao Bang"
UPGRADE.desc = "x2 ammo, lmao bang"
UPGRADE.noSound = true
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    SWEP.Primary.Sound = "ttt_pack_a_punch/lmao_bang/bang1.mp3"
    SWEP.Secondary.Sound = "ttt_pack_a_punch/lmao_bang/bang2.mp3"
end

TTTPAP:Register(UPGRADE)