local UPGRADE = {}
UPGRADE.id = "big_chicken"
UPGRADE.class = "weapon_ttt_chickennade"
UPGRADE.name = "Big Chicken"
UPGRADE.desc = "Spawns a big, invincible chicken, deals triple damage!"

function UPGRADE:Apply(SWEP)
    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        self.Attacking = false

        if not self.Attacking then
            self:SetNextPrimaryFire(CurTime() + 1)
            self:SendWeaponAnim(ACT_VM_PULLPIN)
            self.Attacking = true
        end

        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:SendWeaponAnim(ACT_VM_THROW)
        owner:SetAnimation(PLAYER_ATTACK1)
        self:TakePrimaryAmmo(1)
        if not SERVER then return end
        local plrang = owner:EyeAngles()
        local muzzlepos = owner:GetShootPos() + plrang:Right() * 5 - plrang:Up() * 7
        local muzzleforward = (util.TraceLine(util.GetPlayerTrace(owner)).HitPos - muzzlepos):GetNormalized()
        local egg = ents.Create("sent_egg")
        egg:SetPos(muzzlepos + muzzleforward * 5)
        egg:SetAngles((muzzleforward + VectorRand() * 0.4):Angle())
        egg:SetOwner(owner)
        egg:Spawn()
        egg:Activate()
        -- Egg has PaP camo
        egg:SetPAPCamo()
        local eggphys = egg:GetPhysicsObject()

        if eggphys:IsValid() then
            eggphys:AddVelocity(muzzleforward * 500)
            eggphys:AddAngleVelocity(VectorRand() * 200)
        end

        if self:Clip1() <= 0 then
            self:Remove()
            owner:ConCommand("lastinv")
        end

        function egg:PhysicsCollide(data)
            timer.Simple(0.05, function()
                if self.Spawning then return end
                self.Spawning = true
                local pos = data.HitPos
                local norm = data.HitNormal
                pos = pos + 4 * data.HitNormal

                if self.BreakEffects then
                    self:BreakEffects(pos, norm)
                end

                local chicken = ents.Create("ttt_chicken")
                chicken:SetPos(pos)
                chicken:Spawn()
                -- Chicken has PaP camo
                chicken:SetPAPCamo()
                chicken.TTTPAPBigChicken = true

                -- Makes the inception "duuuunnnn" meme sound lol
                for i = 1, 2 do
                    chicken:EmitSound("ttt_pack_a_punch/big_chicken/inception.mp3", 100)
                end

                -- Makes the chicken big
                chicken:SetModelScale(4, 0.001)
                chicken:Activate()
                local own = self:GetOwner()

                if not IsValid(own) then
                    own = chicken
                end

                chicken:SetAttacker(own)
                self:Remove()
            end)
        end
    end

    -- Makes the chicken make deep sounds
    self:AddHook("EntityEmitSound", function(data)
        if IsValid(data.Entity) and data.Entity.TTTPAPBigChicken then
            data.Pitch = math.random(55, 75)

            return true
        end
    end)

    -- Makes the chicken invincible, and deal double damage
    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if IsValid(ent) and ent.TTTPAPBigChicken then
            return true
        else
            local inflictor = dmg:GetInflictor()

            if IsValid(inflictor) and inflictor.TTTPAPBigChicken then
                dmg:ScaleDamage(3)
            end
        end
    end)
end

TTTPAP:Register(UPGRADE)