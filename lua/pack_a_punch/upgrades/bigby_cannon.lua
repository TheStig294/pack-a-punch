local UPGRADE = {}
UPGRADE.id = "bigby_cannon"
UPGRADE.class = "weapon_ttt_randomatbeecannon"
UPGRADE.name = "Bigby Cannon"
UPGRADE.desc = "Spawns big bees!"

UPGRADE.convars = {
    {
        name = "pap_bigby_cannon_scale",
        type = "int"
    }
}

local scaleCvar = CreateConVar("pap_bigby_cannon_scale", "8", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Size scale of spawned bees", 1, 10)

function UPGRADE:Apply(SWEP)
    local ShootSound = Sound("weapons/grenade_launcher1.wav")
    local scale = scaleCvar:GetInt()

    function SWEP:PrimaryAttack()
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:EmitSound(ShootSound)
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        if SERVER then
            -- Height should be roughly half way up the player to show like it kinda came out of the gun
            local height = owner:Crouching() and 14 or 32
            -- Spawn a bee and give it forward velocity like it was just shot out of the gun
            local bee = Randomat:SpawnBee(owner, nil, height)
            bee:SetModelScale(scale, 0.001)
            bee:Activate()
            local ang = owner:EyeAngles()
            bee:SetPos(owner:GetShootPos() + ang:Forward() * 50 + ang:Right() * 1 - ang:Up() * 1)
            bee:SetAngles(ang)
            local physobj = bee:GetPhysicsObject()

            if IsValid(physobj) then
                physobj:SetVelocity(owner:GetAimVector() * 750)
            end

            local beeProp

            for _, ent in ipairs(bee:GetChildren()) do
                if ent:GetClass() == "prop_dynamic" then
                    beeProp = ent
                    break
                end
            end

            if IsValid(beeProp) then
                beeProp:SetModelScale(scale, 0.001)
                beeProp:Activate()
                beeProp:SetPAPCamo()
            end
        end

        if owner:IsNPC() or not owner.ViewPunch then return end
        owner:ViewPunch(Angle(util.SharedRandom(self:GetClass(), -0.2, -0.1, 0) * self.Primary.Recoil, util.SharedRandom(self:GetClass(), -0.1, 0.1, 1) * self.Primary.Recoil, 0))
    end
end

TTTPAP:Register(UPGRADE)