local UPGRADE = {}
UPGRADE.id = "slampack"
UPGRADE.class = "weapon_ttt_jetpackspawner"
UPGRADE.name = "Slampack"
UPGRADE.desc = "Immune to fall damage, press crouch to slam!"

function UPGRADE:Apply(SWEP)
    function SWEP:CreateJetpack()
        if CLIENT then return end
        local jetpack = ents.Create("sent_jetpack")
        -- Re-enable the jetpack's slam ability!
        jetpack.PAPOldPredictedSetupMove = jetpack.PredictedSetupMove

        function jetpack:PredictedSetupMove(owner, mv, usercmd)
            if self:GetActive() then
                local vel = mv:GetVelocity()

                -- Quickly descend to do a ground slam, don't check for the velocity cap, we want to slam down as fast as we can
                if self:GetCanStomp() then
                    self:SetDoGroundSlam(mv:KeyDown(IN_DUCK))
                end

                --even if the user can't stomp, we still allow him to go down by crouching
                if mv:KeyDown(IN_DUCK) then
                    vel.z = vel.z - self:GetJetpackVelocity() * FrameTime()
                end

                mv:SetVelocity(vel)
            end

            self:PAPOldPredictedSetupMove(owner, mv, usercmd)
        end

        jetpack.PAPOldOnRemove = jetpack.OnRemove

        function jetpack:OnRemove()
            self:GetOwner().PAPJetpack = nil
            self:PAPOldOnRemove()
        end

        -- Spawn and auto-equip the jetpack
        local owner = self:GetOwner()

        if IsValid(jetpack) and IsValid(owner) then
            local vsrc = owner:GetShootPos()
            local vang = owner:GetAimVector()
            local vvel = owner:GetVelocity()
            local vthrow = vvel + vang * 100
            jetpack:SetPos(vsrc + vang * 10)
            jetpack:Spawn()
            jetpack:SetMaterial(TTTPAP.camo)
            owner.PAPJetpack = jetpack
            local phys = jetpack:GetPhysicsObject()

            if IsValid(phys) then
                phys:SetVelocity(vthrow)
                phys:SetMass(200)
            end

            self.ENT = jetpack
        end
    end

    self:AddHook("EntityTakeDamage", function(ply, dmg)
        -- Make them immune to fall damage!
        if IsValid(ply.PAPJetpack) and dmg:IsFallDamage() then
            return true
        else
            -- Play a sound on a jetpack player successfully slamming a player
            local attacker = dmg:GetAttacker()
            local inflictor = dmg:GetInflictor()

            if IsValid(attacker) and IsValid(inflictor) and IsValid(attacker.PAPJetpack) and IsValid(inflictor.PAPJetpack) then
                attacker:EmitSound("ttt_pack_a_punch/basketball/slam.mp3")
            end
        end
    end)
end

TTTPAP:Register(UPGRADE)