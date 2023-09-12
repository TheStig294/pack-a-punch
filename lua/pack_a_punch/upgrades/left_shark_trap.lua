local UPGRADE = {}
UPGRADE.id = "left_shark_trap"
UPGRADE.class = "weapon_shark_trap"
UPGRADE.name = "Left Shark Trap"
UPGRADE.desc = "Changes the shark's model!"

function UPGRADE:Apply(SWEP)
    if SERVER then
        -- Code from the shark trap SWEP and cleaned up
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
                    local ent = ents.Create("ttt_pap_left_shark_trap")
                    ent:SetPos(tr.HitPos + tr.HitNormal)
                    local ang = tr.HitNormal:Angle()
                    ang:RotateAroundAxis(ang:Right(), -90)
                    ent:SetAngles(ang)
                    ent:Spawn()
                    ent.Owner = self.GetOwner
                    ent.fingerprints = self.fingerprints
                    self:Remove()
                end
            end
        end
    end
end

TTTPAP:Register(UPGRADE)