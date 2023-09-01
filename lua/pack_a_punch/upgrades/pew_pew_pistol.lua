local UPGRADE = {}
UPGRADE.id = "pew_pew_pistol"
UPGRADE.class = "weapon_ttt_pistol_randomat"
UPGRADE.name = "Pew Pew Pistol"
UPGRADE.desc = "Makes old school western gunshot sounds!"

function UPGRADE:Apply(SWEP)
    SWEP.Primary.Sound = nil

    function SWEP:PrimaryAttack()
        self.BaseClass.PrimaryAttack(self)
        self:EmitSound("ttt_pack_a_punch/pew_pew_pistol/shoot" .. math.random(1, 6) .. ".mp3")
    end
end

TTTPAP:Register(UPGRADE)