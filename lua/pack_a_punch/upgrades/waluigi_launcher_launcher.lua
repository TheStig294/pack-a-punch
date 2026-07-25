local UPGRADE = {}
UPGRADE.id = "waluigi_launcher_launcher"
UPGRADE.class = "waluigi_launcher_ttt"
UPGRADE.name = "Waluigi Launcher Launcher"
UPGRADE.desc = "Shoots Waluigi Launchers!"

function UPGRADE:Apply(SWEP)
    SWEP.AllowDrop = true
    self:SetClip(SWEP, -1)

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        self:FireRocket()
        owner:SetAnimation(PLAYER_ATTACK1)
        self:SetNextPrimaryFire(CurTime() + 2)
        self:EmitSound(Sound("interceptor_shoot.single"))
        self.BaseClass.ShootEffects(self)
        self:EmitSound("ttt_pack_a_punch/waluigi_launcher_launcher/wah.mp3", 100, math.random(50, 200), 1, CHAN_STATIC)
    end

    function SWEP:FireRocket()
        if CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        aim = owner:GetAimVector()
        side = aim:Cross(Vector(0, 0, 1))
        up = side:Cross(aim)
        pos = owner:GetShootPos() + side * 4 + up * -3
        local launcher = ents.Create(self:GetClass())
        if not launcher:IsValid() then return false end
        launcher:SetAngles(aim:Angle() + Angle(-0.25, 0.25, 0))
        launcher:SetPos(pos)
        launcher:SetOwner(owner)
        launcher:Spawn()
        launcher:Activate()
        eyes = owner:EyeAngles()
        local phys = launcher:GetPhysicsObject()
        phys:SetVelocity(owner:GetAimVector() * 3500)

        if not owner:IsNPC() then
            owner:ViewPunch(Angle(-10, -5, 0))
        end
    end
end

TTTPAP:Register(UPGRADE)