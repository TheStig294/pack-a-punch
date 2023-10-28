local UPGRADE = {}
UPGRADE.id = "come_on_and_slam"
UPGRADE.class = "weapon_ttt_slam"
UPGRADE.name = "Come on and SLAM"
UPGRADE.desc = "x2 ammo, new detonate sound!"
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    local slamSound = "ttt_pack_a_punch/basketball/slam.mp3"
    SWEP.PAPOldSecondaryAttack = SWEP.SecondaryAttack

    function SWEP:SecondaryAttack()
        local owner = self:GetOwner()

        if SERVER and self:GetActiveSatchel() > 0 and self:GetNextSecondaryFire() <= CurTime() and IsValid(owner) then
            owner:EmitSound(slamSound)
        end

        self:PAPOldSecondaryAttack()
    end
end

TTTPAP:Register(UPGRADE)