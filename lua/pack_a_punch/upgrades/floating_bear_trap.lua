local UPGRADE = {}
UPGRADE.id = "floating_bear_trap"
UPGRADE.class = "weapon_ttt_beartrap"
UPGRADE.name = "Floating Bear Trap"
UPGRADE.desc = "You can place 2 traps, floats around\nimmune to your own traps!"
UPGRADE.noSound = true

function UPGRADE:Apply(SWEP)
    if CLIENT then return end
    SWEP.Primary.ClipSize = 2

    timer.Simple(0.1, function()
        SWEP:SetClip1(2)
    end)

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()

        local tr = util.TraceLine({
            start = owner:GetShootPos(),
            endpos = owner:GetShootPos() + owner:GetAimVector() * 100,
            filter = owner
        })

        if tr.HitWorld then
            local dot = vector_up:Dot(tr.HitNormal)

            if dot > 0.55 and dot <= 1 then
                local ENT = ents.Create("ttt_bear_trap")
                ENT:SetPos(tr.HitPos + tr.HitNormal)
                local ang = tr.HitNormal:Angle()
                ang:RotateAroundAxis(ang:Right(), -90)
                ENT:SetAngles(ang)
                ENT:Spawn()
                ENT.Owner = owner
                ENT.fingerprints = self.fingerprints
                ENT.PAPOldTouch = ENT.Touch

                function ENT:Touch(toucher)
                    if not IsValid(toucher) or not toucher:IsPlayer() then return end
                    if toucher == owner then return end

                    return ENT:PAPOldTouch(toucher)
                end

                timer.Simple(0.1, function()
                    local phys = ENT:GetPhysicsObject()
                    phys:EnableGravity(false)
                    phys:EnableMotion(true)
                    phys:AddVelocity(VectorRand(0, 5))
                end)

                self:TakePrimaryAmmo(1)

                if self:Clip1() <= 0 then
                    self:Remove()
                end
            end
        end
    end
end

TTTPAP:Register(UPGRADE)