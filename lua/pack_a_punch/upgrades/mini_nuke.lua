local UPGRADE = {}
UPGRADE.id = "mini_nuke"
UPGRADE.class = "weapon_ttt_c4"
UPGRADE.name = "Mini-Nuke"
UPGRADE.desc = "x1.5 explosion damage and radius\nTriggers a smaller additional explosion 20 seconds after being placed"

function UPGRADE:Apply(SWEP)
    local throwsound = Sound("Weapon_SLAM.SatchelThrow")

    -- mostly replicating HL2DM slam throw here
    function SWEP:BombDrop()
        if SERVER then
            local ply = self:GetOwner()
            if not IsValid(ply) then return end
            if self.Planted then return end
            local vsrc = ply:GetShootPos()
            local vang = ply:GetAimVector()
            local vvel = ply:GetVelocity()
            local vthrow = vvel + vang * 200
            local bomb = ents.Create("ttt_c4")

            if IsValid(bomb) then
                bomb:SetPos(vsrc + vang * 10)
                bomb:SetOwner(ply)
                bomb:SetThrower(ply)
                bomb:Spawn()
                bomb:PointAtEntity(ply)
                bomb:SetMaterial(TTTPAP.camo)
                bomb:SetDmg(bomb:GetDmg() * 1.5)
                bomb:SetRadius(bomb:GetRadius() * 1.5)

                local ignore = {ply, self}

                local spos = ply:GetShootPos()
                local epos = spos + ply:GetAimVector() * 80

                local tr = util.TraceLine({
                    start = spos,
                    endpos = epos,
                    filter = ignore,
                    mask = MASK_SOLID
                })

                timer.Simple(20, function()
                    if IsValid(bomb) then
                        StartFires(bomb:GetPos(), tr, 8, 10, true, ply)
                    end
                end)

                local ang = bomb:GetAngles()
                ang:RotateAroundAxis(ang:Up(), 180)
                bomb:SetAngles(ang)
                bomb.fingerprints = self.fingerprints
                bomb:PhysWake()
                local phys = bomb:GetPhysicsObject()

                if IsValid(phys) then
                    phys:SetVelocity(vthrow)
                end

                self:Remove()
                self.Planted = true
            end

            ply:SetAnimation(PLAYER_ATTACK1)
        end

        self:EmitSound(throwsound)
        self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
    end

    -- again replicating slam, now its attach fn
    function SWEP:BombStick()
        if SERVER then
            local ply = self:GetOwner()
            if not IsValid(ply) then return end
            if self.Planted then return end

            local ignore = {ply, self}

            local spos = ply:GetShootPos()
            local epos = spos + ply:GetAimVector() * 80

            local tr = util.TraceLine({
                start = spos,
                endpos = epos,
                filter = ignore,
                mask = MASK_SOLID
            })

            if tr.HitWorld then
                local bomb = ents.Create("ttt_c4")

                if IsValid(bomb) then
                    bomb:PointAtEntity(ply)

                    local tr_ent = util.TraceEntity({
                        start = spos,
                        endpos = epos,
                        filter = ignore,
                        mask = MASK_SOLID
                    }, bomb)

                    if tr_ent.HitWorld then
                        local ang = tr_ent.HitNormal:Angle()
                        ang:RotateAroundAxis(ang:Right(), -90)
                        ang:RotateAroundAxis(ang:Up(), 180)
                        bomb:SetPos(tr_ent.HitPos)
                        bomb:SetAngles(ang)
                        bomb:SetOwner(ply)
                        bomb:SetThrower(ply)
                        bomb:Spawn()
                        bomb:SetMaterial(TTTPAP.camo)
                        bomb:SetDmg(bomb:GetDmg() * 1.5)
                        bomb:SetRadius(bomb:GetRadius() * 1.5)

                        timer.Simple(20, function()
                            if IsValid(bomb) then
                                StartFires(bomb:GetPos(), tr, 8, 10, true, ply)
                            end
                        end)

                        bomb.fingerprints = self.fingerprints
                        local phys = bomb:GetPhysicsObject()

                        if IsValid(phys) then
                            phys:EnableMotion(false)
                        end

                        bomb.IsOnWall = true
                        self:Remove()
                        self.Planted = true
                    end
                end

                ply:SetAnimation(PLAYER_ATTACK1)
            end
        end
    end
end

TTTPAP:Register(UPGRADE)