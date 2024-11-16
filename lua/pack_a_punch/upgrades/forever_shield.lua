local UPGRADE = {}
UPGRADE.id = "forever_shield"
UPGRADE.class = "weapon_ttt_force_shield"
UPGRADE.name = "Forever Shield"
UPGRADE.desc = "Has infinite health and lasts forever!"

function UPGRADE:Apply(SWEP)
    if SERVER then
        util.AddNetworkString("TTTPAPForeverShield")
    end

    if CLIENT then
        net.Receive("TTTPAPForeverShield", function()
            local shield = net.ReadEntity()
            shield.totalLifeTime = 10000

            -- Doesn't take damage
            function shield:OnTakeDamage()
            end

            function shield:Draw()
                self:DrawModel()
                local shieldPos = self:GetPos()
                shieldPos.z = shieldPos.z + 96
                local shieldAngle = self:GetAngles()
                shieldAngle = Angle(0, shieldAngle.y, 90)
                cam.Start3D2D(shieldPos, shieldAngle, .225)
                draw.SimpleText("PAP Upgraded! Infinite", "OvR_Load_HUD_Holo_1", 0, 0, Color(130, 248, 181, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                cam.End3D2D()
            end
        end)
    end

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()

        if SERVER then
            owner.active_aug1_cooldown = owner.active_aug1_cooldown or CurTime()
            owner.emitSoundCooldown = owner.emitSoundCooldown or CurTime()
            local augJustFired = false --This is required so it doesnt play the cooldown sound when firing

            if CurTime() >= owner.active_aug1_cooldown then
                augJustFired = true --Were firing so the augment will have been fired at the end of this if block

                -- .1 seconds from this timer, set augJustFired back to false
                timer.Simple(.1, function()
                    augJustFired = false
                end)

                owner.active_aug1_cooldown = CurTime() + 33

                --Play a sound when cooldown is over
                timer.Simple(33, function()
                    owner:EmitSound("npc/scanner/combat_scan5.wav", 40)
                end)

                owner:EmitSound("npc/attack_helicopter/aheli_mine_drop1.wav", 35)

                if SERVER then
                    local shieldDeployer = ents.Create("shield_deployer")
                    local _shieldDeployAngleYaw = owner:GetEyeTrace().Normal:Angle().yaw
                    shieldDeployer.shieldDeployAngleYaw = _shieldDeployAngleYaw
                    shieldDeployer:SetPos(owner:GetPos() + Vector(0, 0, 48))
                    shieldDeployer:SetAngles(owner:GetAngles())
                    shieldDeployer:Spawn()
                    local shieldDeployerPhys = shieldDeployer.phys
                    shieldDeployer:Activate()

                    if shieldDeployer:GetPhysicsObject():IsValid() and owner:IsValid() then
                        shieldDeployerPhys:SetVelocityInstantaneous(owner:EyeAngles():Forward() * 500)
                    end

                    function shieldDeployer:PhysicsCollide(data, phys)
                        if self.deployed == false then
                            ParticleEffect("vortigaunt_glow_beam_cp1b", self:GetPos(), self:GetAngles())
                            self:Remove()

                            if SERVER then
                                local shield = ents.Create("force_shield")
                                -- "Infinite" time
                                shield.totalLifeTime = 10000

                                -- Doesn't take damage
                                function shield:OnTakeDamage()
                                end

                                shield:SetPos(self:GetPos())
                                shield:SetAngles(Angle(0, self.shieldDeployAngleYaw - 90, 0))
                                shield:Spawn()

                                timer.Simple(2, function()
                                    if not IsValid(shield) then return end
                                    net.Start("TTTPAPForeverShield")
                                    net.WriteEntity(shield)
                                    net.Broadcast()
                                end)
                            end
                        end

                        self.deployed = true
                    end
                end

                if aug_forceshield_Vmanip_compatible then
                    net.Start("VManip_SimplePlay")
                    net.WriteString("use")
                    net.Send(owner)
                end

                owner:ViewPunch(Angle(-4, 0, 0))
                self:Remove()
            end

            if not augJustFired and CurTime() >= owner.emitSoundCooldown then
                owner.emitSoundCooldown = CurTime() + 2.5
                owner:EmitSound("buttons/combine_button_locked.wav", 35)
            end
        end
    end
end

TTTPAP:Register(UPGRADE)