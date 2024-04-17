local UPGRADE = {}
UPGRADE.id = "mine_train"
UPGRADE.class = "weapon_ttt_mine_turtle"
UPGRADE.name = "Mine Train"
UPGRADE.desc = "x2 ammo, runs the victim over with a train!"
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    function SWEP:MineDrop()
        local owner = self:GetOwner()

        if SERVER and IsValid(owner) then
            local mine = ents.Create("ttt_pap_mine_turtle")

            if IsValid(mine) then
                self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
                local src = owner:GetShootPos()
                local ang = owner:GetAimVector()
                local vel = owner:GetVelocity()
                local throw = vel + ang * 200
                mine:SetPos(src + ang * 10)
                mine:SetPlacer(owner)
                mine:Spawn()
                mine:SetMaterial(TTTPAP.camo)
                mine.PAPUpgrade = UPGRADE
                mine.fingerprints = self.fingerprints
                local phys = mine:GetPhysicsObject()

                if IsValid(phys) then
                    phys:Wake()
                    phys:SetVelocity(throw)
                end

                self:TakePrimaryAmmo(1)
                self:Deploy()
            end
        end
    end

    function SWEP:MineStick()
        local owner = self:GetOwner()

        if SERVER and IsValid(owner) then
            local ignore = {owner, self}

            local spos = owner:GetShootPos()
            local epos = spos + owner:GetAimVector() * 42

            local tr = util.TraceLine({
                start = spos,
                endpos = epos,
                filter = ignore,
                mask = MASK_SOLID
            })

            if tr.HitWorld then
                local mine = ents.Create("ttt_pap_mine_turtle")

                if IsValid(mine) then
                    local tr_ent = util.TraceEntity({
                        start = spos,
                        endpos = epos,
                        filter = ignore,
                        mask = MASK_SOLID
                    }, mine)

                    if tr_ent.HitWorld then
                        self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
                        local ang = tr_ent.HitNormal:Angle()
                        ang.p = ang.p + 90
                        mine:SetPos(tr_ent.HitPos + (tr_ent.HitNormal * 3))
                        mine:SetAngles(ang)
                        mine:SetPlacer(owner)
                        mine:Spawn()
                        mine:SetMaterial(TTTPAP.camo)
                        mine.PAPUpgrade = UPGRADE
                        mine.fingerprints = self.fingerprints
                        local phys = mine:GetPhysicsObject()

                        if IsValid(phys) then
                            phys:Wake()
                            phys:EnableMotion(false)
                        end

                        self:TakePrimaryAmmo(1)
                        self:Deploy()
                    end
                end
            end
        end
    end
end

TTTPAP:Register(UPGRADE)