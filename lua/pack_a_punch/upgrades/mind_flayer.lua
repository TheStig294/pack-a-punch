local UPGRADE = {}
UPGRADE.id = "mind_flayer"
UPGRADE.class = "weapon_ttt_brain_parasite"
UPGRADE.name = "Mind Flayer"
UPGRADE.desc = "x2 ammo\nForces victims to mimic your actions, on death they turn into a zombie!"
UPGRADE.noSound = true
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    SWEP.IsSilent = true
    SWEP.Primary.Sound = Sound("Weapon_USP.SilencedShot")
    SWEP.Primary.SoundLevel = 50
    SWEP.IronSightsPos = Vector(-5.91, -4, 2.84)
    SWEP.IronSightsAng = Vector(-0.5, 0, 0)
    SWEP.PrimaryAnim = ACT_VM_PRIMARYATTACK_SILENCED
    SWEP.ReloadAnim = ACT_VM_RELOAD_SILENCED

    function SWEP:Deploy()
        self:SendWeaponAnim(ACT_VM_DRAW_SILENCED)

        return self.BaseClass.Deploy(self)
    end

    function SWEP:PrimaryAttack()
        if not self:CanPrimaryAttack() then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        self:TakePrimaryAmmo(1)
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:ShootEffects()
        owner:EmitSound(self.Primary.Sound)

        if owner:IsPlayer() then
            owner:ViewPunch(Angle(math.Rand(-0.2, -0.1) * self.Primary.Recoil, math.Rand(-0.1, 0.1) * self.Primary.Recoil, 0))
        end

        if CLIENT or not IsFirstTimePredicted() then return end
        local tr = owner:GetEyeTrace()
        local victim = tr.Entity
        if not IsValid(victim) or not victim:IsPlayer() then return end
        victim:SetNWEntity("PAPMindFlayerControlled", owner)
        owner:SetNWBool("PAPMindFlayerControlling", true)
        victim:ChatPrint("You feel a wriggling in the back of your skull...")
        victim:SetEyeAngles(owner:EyeAngles())

        timer.Simple(20, function()
            if IsValid(victim) and IsValid(victim:GetNWEntity("PAPMindFlayerControlled")) then
                victim:SetNWEntity("PAPMindFlayerControlled", nil)
                local dmg = DamageInfo()

                if not IsValid(owner) then
                    owner = victim
                end

                dmg:SetInflictor(ents.Create("weapon_ttt_brain_parasite"))
                dmg:SetAttacker(owner)
                dmg:SetDamage(10000)
                dmg:SetDamageType(DMG_BULLET)
                -- Replacing the dead player with a zombie
                local zombie = ents.Create("npc_fastzombie")
                zombie:SetPos(victim:GetPos())
                zombie:Spawn()
                victim:TakeDamageInfo(dmg)
            end
        end)
    end

    self:AddHook("PostPlayerDeath", function(victim)
        victim:SetNWEntity("PAPMindFlayerControlled", nil)
        victim:SetNWBool("PAPMindFlayerControlling", nil)
    end)

    self:AddHook("StartCommand", function(ply, ucmd)
        if not IsValid(ply) then return end

        -- The controlling player
        if ply:GetNWBool("PAPMindFlayerControlling") then
            ply.PAPMindFlayerUsing = ucmd:KeyDown(IN_USE)
            ply.PAPMindFlayerAttacking = ucmd:KeyDown(IN_ATTACK)
            ply.PAPMindFlayerReloading = ucmd:KeyDown(IN_RELOAD)
            ply.PAPMindFlayerJumping = ucmd:KeyDown(IN_JUMP)
            ply.PAPMindFlayerCrouching = ucmd:KeyDown(IN_DUCK)
            ply.PAPMindFlayerIsMoving = ucmd:KeyDown(IN_FORWARD) or ucmd:KeyDown(IN_BACK) or ucmd:KeyDown(IN_MOVELEFT) or ucmd:KeyDown(IN_MOVERIGHT)
            ply.PAPMindFlayerForwardMovement = ucmd:GetForwardMove()
            ply.PAPMindFlayerSidewardMovement = ucmd:GetSideMove()
            ply.PAPMindFlayerUpMovement = ucmd:GetUpMove()
            ply.PAPMindFlayerMouseX = ucmd:GetMouseX()
            ply.PAPMindFlayerMouseY = ucmd:GetMouseY()
        end

        -- The player being controlled
        if IsValid(ply:GetNWEntity("PAPMindFlayerControlled")) then
            local owner = ply:GetNWEntity("PAPMindFlayerControlled")

            -- Attack 
            if owner.PAPMindFlayerAttacking then
                ucmd:SetButtons(ucmd:GetButtons() + IN_ATTACK)
            end

            -- Basic movement
            -- Basically, only run the movement stuff if at least one kind of movement is actually happening...
            if owner.PAPMindFlayerIsMoving or owner.PAPMindFlayerCrouching or owner.PAPMindFlayerJumping or owner.PAPMindFlayerUsing then
                owner.PAPMindFlayerViewAngles = Angle(owner.PAPMindFlayerViewAngles.p + owner.PAPMindFlayerMouseY / 30, owner.PAPMindFlayerViewAngles.y - owner.PAPMindFlayerMouseX / 30, 0)
                owner.PAPMindFlayerViewAngles.p = math.Clamp(owner.PAPMindFlayerViewAngles.p, -89, 89)
                ucmd:SetViewAngles(owner.PAPMindFlayerViewAngles)
                ucmd:SetForwardMove(owner.PAPMindFlayerForwardMovement)
                ucmd:SetSideMove(owner.PAPMindFlayerSidewardMovement)
                ucmd:SetUpMove(owner.PAPMindFlayerUpMovement)
            else
                owner.PAPMindFlayerViewAngles = ucmd:GetViewAngles()
            end

            -- Command Movement
            if owner.PAPMindFlayerCrouching and not ucmd:KeyDown(IN_DUCK) then
                ucmd:SetButtons(ucmd:GetButtons() + IN_DUCK)
            end

            if owner.PAPMindFlayerJumping and not ucmd:KeyDown(IN_JUMP) then
                ucmd:SetButtons(ucmd:GetButtons() + IN_JUMP)
            end

            if owner.PAPMindFlayerUsing and not ucmd:KeyDown(IN_USE) then
                ucmd:SetButtons(ucmd:GetButtons() + IN_USE)
            end
        end
    end)

    -- Switching Weapons
    if SERVER then
        self:AddHook("PlayerSwitchWeapon", function(ply, oldWep, newWep)
            if ply:GetNWBool("PAPMindFlayerControlling") then
                local victims = {}

                for _, p in player.Iterator() do
                    local controller = p:GetNWEntity("PAPMindFlayerControlled")

                    if IsValid(controller) and controller == ply then
                        table.insert(victims, p)
                    end
                end

                local kind = newWep.Kind

                for _, victim in ipairs(victims) do
                    for _, wep in ipairs(victim:GetWeapons()) do
                        if wep.Kind == kind then
                            victim:SelectWeapon(WEPS.GetClass(wep))
                            break
                        end
                    end
                end
            end
        end)
    end
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply:SetNWEntity("PAPMindFlayerControlled", nil)
        ply:SetNWBool("PAPMindFlayerControlling", nil)
        ply.PAPMindFlayerUsing = nil
        ply.PAPMindFlayerAttacking = nil
        ply.PAPMindFlayerReloading = nil
        ply.PAPMindFlayerJumping = nil
        ply.PAPMindFlayerCrouching = nil
        ply.PAPMindFlayerIsMoving = nil
        ply.PAPMindFlayerForwardMovement = nil
        ply.PAPMindFlayerSidewardMovement = nil
        ply.PAPMindFlayerUpMovement = nil
        ply.PAPMindFlayerMouseX = nil
        ply.PAPMindFlayerMouseY = nil
        ply.PAPMindFlayerAttackTime = nil
        ply.PAPMindFlayerViewAngles = nil
    end
end

TTTPAP:Register(UPGRADE)