local UPGRADE = {}
UPGRADE.id = "john_bomb_suicide"
UPGRADE.class = "weapon_ttt_suicide"
UPGRADE.name = "John Bomb"
UPGRADE.desc = "Plays the John Cena intro before exploding!"

function UPGRADE:Apply(SWEP)
    function SWEP:Initialize()
        util.PrecacheSound("ttt_pack_a_punch/john_bomb/johncena.mp3")
    end

    function SWEP:Asplode(owner)
        local ent = ents.Create("env_explosion")
        ent:SetPos(owner:GetPos())
        ent:SetOwner(owner)
        ent:Spawn()
        ent:SetKeyValue("iMagnitude", "250")
        ent:Fire("Explode", 0, 0)
        local dmg = DamageInfo()
        dmg:SetDamage(10000)
        dmg:SetDamageType(DMG_BLAST)
        dmg:SetInflictor(self)
        dmg:SetAttacker(owner)
        owner:TakeDamageInfo(dmg)
    end

    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        self:PAPOldPrimaryAttack()
        local owner = self:GetOwner()

        if IsValid(owner) then
            owner:StopSound("siege/suicide.wav")
            owner:EmitSound("ttt_pack_a_punch/john_bomb/johncena.mp3")
        end
    end
end

TTTPAP:Register(UPGRADE)