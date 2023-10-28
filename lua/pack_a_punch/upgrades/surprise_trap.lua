local UPGRADE = {}
UPGRADE.id = "surprise_trap"
UPGRADE.class = "weapon_ttt_shocktrap"
UPGRADE.name = "Surprise Trap"
UPGRADE.desc = "Can place 3, 'surprises' the victim"

function UPGRADE:Apply(SWEP)
    SWEP.Primary.ClipSize = 3

    timer.Simple(0.1, function()
        SWEP:SetClip1(3)
    end)

    local throwsound = Sound("Weapon_SLAM.SatchelThrow")

    function SWEP:DropTrap()
        if SERVER then
            local owner = self:GetOwner()
            if not IsValid(owner) then return end
            local shootpos = owner:GetShootPos()
            local aimvec = owner:GetAimVector()
            local velocity = owner:GetVelocity()
            local toss = velocity + aimvec * 200
            local trap = ents.Create("ttt_pap_surprise_trap")

            if IsValid(trap) then
                trap:SetPos(shootpos + aimvec * 10)
                trap:Spawn()
                -- trap:SetOwner(owner)
                trap:PhysWake()
                local phys = trap:GetPhysicsObject()

                if IsValid(phys) then
                    phys:SetVelocity(toss)
                end

                self:EmitSound(throwsound)
                self:TakePrimaryAmmo(1)

                if self:Clip1() <= 0 then
                    self:Remove()
                end
            end
        end
    end
end

TTTPAP:Register(UPGRADE)