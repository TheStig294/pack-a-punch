local UPGRADE = {}
UPGRADE.id = "invincible_turret"
UPGRADE.class = "weapon_ttt_turret"
UPGRADE.name = "Invincible Turret"
UPGRADE.desc = "Invincible, immovable, x2 ammo, plays portal quotes!"

function UPGRADE:Apply(SWEP)
    -- Bug fixes from base weapon...
    SWEP.Primary.Delay = 0.1
    SWEP.Secondary.Delay = 0.1

    timer.Simple(0.1, function()
        SWEP:SetNextPrimaryFire(CurTime())
    end)

    function SWEP:PrimaryAttack()
        if SERVER then
            self:SpawnTurret()
        end

        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    end

    function SWEP:Deploy()
        return true
    end

    -- x2 ammo
    self:SetClip(SWEP, 2)

    if SERVER then
        function SWEP:SpawnTurret()
            local owner = self:GetOwner()
            if not IsValid(owner) then return end
            local tr = owner:GetEyeTrace()
            if not tr.HitWorld then return end

            -- Why doesn't it tell the player why you can't place it ugh...
            if tr.HitPos:Distance(owner:GetPos()) > 128 then
                owner:PrintMessage(HUD_PRINTCENTER, "Too far away!")

                return
            end

            local Views = owner:EyeAngles().y
            local ent = ents.Create("npc_turret_floor")
            ent:SetOwner(owner)
            ent:SetPos(tr.HitPos + tr.HitNormal)
            ent:SetAngles(Angle(0, Views, 0))
            ent:Spawn()
            ent:Activate()
            ent:SetDamageOwner(owner)
            local entphys = ent:GetPhysicsObject()

            if entphys:IsValid() then
                entphys:SetMass(entphys:GetMass() + 200)
            end

            ent.IsTurret = true
            ent.TTTPAPInvincibleTurret = true
            ent:SetPhysicsAttacker(owner)
            ent:SetTrigger(true)
            -- Immovable
            ent:SetMoveType(MOVETYPE_NONE)
            ent:SetPAPCamo()
            -- Plays Portal quotes
            local timerName = "TTTPAPInvincibleTurret" .. ent:EntIndex()

            timer.Create(timerName, 20, 0, function()
                if not IsValid(ent) then
                    timer.Remove(timerName)

                    return
                end

                local randomNum = math.random(1, 6)

                for i = 1, 2 do
                    ent:EmitSound("ttt_pack_a_punch/invincible_turret/passive" .. randomNum .. ".mp3")
                end
            end)

            self:TakePrimaryAmmo(1)

            if self:Clip1() <= 0 then
                self:Remove()
                owner:ConCommand("lastinv")
            end
        end
    end

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        -- Invincible
        if ent.TTTPAPInvincibleTurret then return true end
        -- Player damage quotes
        local inflictor = dmg:GetInflictor()

        if IsValid(inflictor) and inflictor.TTTPAPInvincibleTurret and not inflictor.TTTPAPInvincibleTurretCooldown then
            local randomNum = math.random(1, 5)

            for i = 1, 2 do
                inflictor:EmitSound("ttt_pack_a_punch/invincible_turret/attack" .. randomNum .. ".mp3")
            end

            if IsPlayer(ent) then
                ent:EmitSound("ttt_pack_a_punch/invincible_turret/attack" .. randomNum .. ".mp3")
            end

            inflictor.TTTPAPInvincibleTurretCooldown = true

            timer.Simple(3, function()
                if IsValid(inflictor) then
                    inflictor.TTTPAPInvincibleTurretCooldown = false
                end
            end)
        end
    end)
end

TTTPAP:Register(UPGRADE)