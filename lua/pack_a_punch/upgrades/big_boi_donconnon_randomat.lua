local UPGRADE = {}
UPGRADE.id = "big_boi_donconnon_randomat"
UPGRADE.class = "weapon_ttt_donconnon_randomat"
UPGRADE.name = "Big Boi Donconnon"
UPGRADE.desc = "Bigger hitbox, bigger explosion, leaves fire"

function UPGRADE:Apply(SWEP)
    function SWEP:PrimaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        -- Spawn PAP ent
        local doncon = ents.Create("ttt_pap_big_boi_donconnon")
        if not IsValid(doncon) then return end
        doncon:SetPos(owner:EyePos() + owner:GetAimVector() * 200)
        doncon:SetAngles(owner:EyeAngles())
        doncon:SetOwner(owner)
        doncon.SWEP = self

        if self.LockOnTarget ~= "none" then
            doncon.Homing = true
            doncon.Target = self.LockOnTarget
        else
            doncon.Homing = false
        end

        doncon.DonconDamage = 60
        doncon.DonconSpeed = 200
        doncon.DonconRange = 2000
        -- x2 default size
        doncon.DonconScale = 1.5
        doncon.DonconTurn = 0.00025
        -- New sound
        doncon.Sound = "ttt_pack_a_punch/big_boi_donconnon/o_rubber_tree_big.mp3"
        doncon:Spawn()
        self:UpdateHalo("none")
        self:Remove()
    end
end

TTTPAP:Register(UPGRADE)