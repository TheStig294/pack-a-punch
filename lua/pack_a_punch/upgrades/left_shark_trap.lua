local UPGRADE = {}
UPGRADE.id = "left_shark_trap"
UPGRADE.class = "weapon_shark_trap"
UPGRADE.name = "Left Shark Trap"
UPGRADE.desc = "2 traps, changes the shark's model!"
UPGRADE.noSound = true

function UPGRADE:Apply(SWEP)
    self:SetClip(SWEP, 2)
    SWEP.AmmoEnt = nil
    SWEP.Primary.Ammo = "AirboatGun"
    SWEP.Primary.Sound = ""

    -- Code from the shark trap SWEP and cleaned up
    -- https://steamcommunity.com/sharedfiles/filedetails/?id=2550782000
    function SWEP:PrimaryAttack()
        if CLIENT or not self:CanPrimaryAttack() then return end
        local owner = self:GetOwner()

        local tr = util.TraceLine({
            start = owner:GetShootPos(),
            endpos = owner:GetShootPos() + owner:GetAimVector() * 100,
            filter = owner
        })

        if tr.HitWorld then
            local dot = vector_up:Dot(tr.HitNormal)

            if dot > 0.55 and dot <= 1 then
                local ent = ents.Create("ttt_pap_left_shark_trap")
                ent:SetPos(tr.HitPos + tr.HitNormal)
                local ang = tr.HitNormal:Angle()
                ang:RotateAroundAxis(ang:Right(), -90)
                ent:SetAngles(ang)
                ent:SetPlacer(owner)
                ent:Spawn()
                ent.fingerprints = self.fingerprints
                self:TakePrimaryAmmo(1)
                self:SetNextPrimaryFire(CurTime() + 0.5)

                if self:Clip1() <= 0 then
                    self:Remove()
                end
            end
        end
    end
end

TTTPAP:Register(UPGRADE)