local UPGRADE = {}
UPGRADE.id = "mustang_and_sally"
UPGRADE.class = "weapon_ttt_dragon_elites"
UPGRADE.name = "Mustang and Sally"
UPGRADE.desc = "Duel-wield grenade launcher!"

UPGRADE.convars = {
    {
        name = "pap_mustang_and_sally_ammo",
        type = "int"
    },
    {
        name = "pap_mustang_and_sally_damage",
        type = "int"
    }
}

local ammoCvar = CreateConVar("pap_mustang_and_sally_ammo", "8", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Ammo count", 1, 20)

local damageCvar = CreateConVar("pap_mustang_and_sally_damage", "10", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Amount of damage", 1, 50)

function UPGRADE:Apply(SWEP)
    SWEP.Primary.ClipMax = ammoCvar:GetInt() / 2
    SWEP.Primary.ClipSize = ammoCvar:GetInt() / 2
    SWEP.AmmoEnt = nil
    SWEP.Primary.Ammo = "AirboatGun"

    timer.Simple(0.1, function()
        SWEP:SetClip1(ammoCvar:GetInt() / 2)
        SWEP:GetOwner():SetAmmo(ammoCvar:GetInt() / 2, "AirboatGun")
    end)

    -- Shooting functions largely copied from weapon_cs_base
    function SWEP:PrimaryAttack(worldsnd)
        self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        if not self:CanPrimaryAttack() then return end

        if not worldsnd then
            self:EmitSound(self.Primary.Sound, self.Primary.SoundLevel)
        elseif SERVER then
            sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
        end

        self:ShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone())
        -- Spawn some fire as well!
        local tr = self:GetOwner():GetEyeTrace(MASK_SHOT)
        local pos = tr.HitPos

        if IsValid(tr.Entity) then
            pos = tr.Entity:GetPos()
        end

        if SERVER then
            local fireNade = ents.Create("ttt_firegrenade_proj")
            fireNade:SetPos(pos)
            fireNade:Spawn()
            fireNade:SetDmg(damageCvar:GetInt())
            fireNade:SetThrower(self:GetOwner())
            fireNade:Explode(tr)
        end

        self:TakePrimaryAmmo(1)
        local owner = self:GetOwner()
        if not IsValid(owner) or owner:IsNPC() or not owner.ViewPunch then return end
        owner:ViewPunch(Angle(util.SharedRandom(self:GetClass(), -0.2, -0.1, 0) * self.Primary.Recoil, util.SharedRandom(self:GetClass(), -0.1, 0.1, 1) * self.Primary.Recoil, 0))
    end
end

TTTPAP:Register(UPGRADE)