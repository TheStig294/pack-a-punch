local UPGRADE = {}
UPGRADE.id = "auto_cannon"
UPGRADE.class = "weapon_ttt_artillery"
UPGRADE.name = "Auto Cannon"
UPGRADE.desc = "Auto-shoots, more damage, pressing 'E' removes the cannon!"

UPGRADE.convars = {
    {
        name = "pap_auto_cannon_damage",
        type = "int"
    }
}

local damageCvar = CreateConVar("pap_auto_cannon_damage", 1000, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage of the auto cannon's shells", 1, 1000)

-- As per usual, sound is abnormally quiet, so it is played over itself to be louder
local musicVolume = 4

local function RemoveCannon(cannon)
    for i = 1, musicVolume do
        cannon:StopSound("ttt_pack_a_punch/auto_cannon/1812_overture.mp3")
    end

    if SERVER then
        cannon:Remove()
    end
end

-- Causes the cannon to be removed if any of the shoot UI tries to be used
hook.Add("InitPostEntity", "TTTPAPModifyOrchestralCannon", function()
    if zay and zay.f and zay.f.Artillery_USE then
        local oldUse = zay.f.Artillery_USE

        function zay.f.Artillery_USE(Artillery, ply)
            if UPGRADE:IsUpgraded(Artillery) then
                RemoveCannon(Artillery)
            else
                return oldUse(Artillery, ply)
            end
        end

        local ENT = scripted_ents.GetStored("zay_shell")

        -- This is all copied from Zay's artillery cannon code, we're overriding this function just so the damage the cannon deals passes an inflictor
        -- so we can properly detect and change the upgraded cannon's damage
        function ENT:PhysicsCollide(data, phys)
            if self.zay_Collided == true then return end

            timer.Simple(0, function()
                if not IsValid(self) then return end
                self:SetNoDraw(true)
                local a_phys = self:GetPhysicsObject()

                if IsValid(a_phys) then
                    a_phys:Wake()
                    a_phys:EnableMotion(false)
                end
            end)

            zay.f.CreateNetEffect("shell_explosion", self:GetPos())

            for k, v in pairs(ents.FindInSphere(self:GetPos(), GetConVar("ttt_artillery_range"):GetFloat())) do
                if IsValid(v) then
                    local d = DamageInfo()
                    d:SetDamage(GetConVar("ttt_artillery_damage"):GetFloat())
                    d:SetAttacker(self:GetPhysicsAttacker())
                    -- All this just so the cannon shell's damage actually passes an inflictor...
                    d:SetInflictor(self)
                    d:SetDamageType(DMG_BLAST)
                    v:TakeDamageInfo(d)
                end
            end

            local deltime = FrameTime() * 2

            if not game.SinglePlayer() then
                deltime = FrameTime() * 6
            end

            SafeRemoveEntityDelayed(self, deltime)
            self.zay_Collided = true
        end
    end
end)

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()
    local cannon

    if SERVER and IsValid(owner) then
        owner:PrintMessage(HUD_PRINTCENTER, "Pressing 'E' REMOVES the cannon!")
    end

    -- Making the upgraded cannon's shells deal more damage
    self:AddHook("EntityTakeDamage", function(ent, dmg)
        local attacker = dmg:GetAttacker()
        local inflictor = dmg:GetInflictor()

        if IsValid(attacker) and IsValid(attacker.PAPAutoCannon) and IsValid(inflictor) and inflictor:GetClass() == "zay_shell" then
            dmg:SetDamage(damageCvar:GetInt())
        end
    end)

    function SWEP:PrimaryAttack()
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

        if SERVER then
            cannon = ents.Create("zay_artillery")
            if not IsValid(cannon) then return end
            local ply = self:GetOwner()
            local trace = ply:GetEyeTrace()
            local ang = trace.HitNormal:Angle()
            ang.pitch = ang.pitch + 90
            ang.yaw = ply:EyeAngles().yaw - 90
            if ang.pitch < 353 or ang.pitch > 367 then return end
            ang.pitch = 360
            cannon:SetPos(trace.HitPos - trace.HitNormal * -2.5)
            cannon:SetAngles(ang)
            cannon:SetColor(self.CannonColor)
            cannon:Spawn()
            cannon.PAPUpgrade = self.PAPUpgrade
            cannon:SetPAPCamo()

            for i = 1, musicVolume do
                cannon:EmitSound("ttt_pack_a_punch/auto_cannon/1812_overture.mp3")
            end

            cannon:SetUseType(SIMPLE_USE)
            cannon.UnlimitedAmmo = true
            cannon.Owner = ply
            cannon.ShowedWarningMessage = false
            ply.PAPAutoCannon = cannon

            -- Cannon removes itself on pressing 'E' on it
            cannon.Use = function(activator)
                RemoveCannon(cannon)
            end

            -- Warning message
            for _, p in ipairs(player.GetAll()) do
                p:ChatPrint(UPGRADE.name .. " placed! Press 'E' to disable it before it's too late!")
            end

            -- For the first 5 seconds, the cannon moves left
            local moveLeftTimer = "TTTPAPOrchestralCannonMoveLeft" .. cannon:EntIndex()

            timer.Create(moveLeftTimer, 1, 4, function()
                if not IsValid(cannon) then
                    timer.Remove(moveLeftTimer)

                    return
                end

                -- Left move has id = 2
                local button_id = 2
                zay.f.Artillery_Move(cannon, ply, button_id)
            end)

            -- Then after the music kicks in, the cannon fires in time with it, while also moving right before each shot
            local shootDelays = {5.65, 8.65, 11.45, 14.35, 17.15, 19.95, 22.85, 25.85}

            for _, delay in ipairs(shootDelays) do
                -- Moving the cannon right
                timer.Simple(delay - 0.5, function()
                    if IsValid(cannon) and IsValid(ply) then
                        -- Right move has id = 1
                        local button_id = 1
                        zay.f.Artillery_Move(cannon, ply, button_id)
                    elseif IsValid(cannon) and not IsValid(ply) then
                        RemoveCannon(cannon)
                    end
                end)

                -- Shooting the cannon
                timer.Simple(delay, function()
                    if IsValid(cannon) and IsValid(ply) then
                        zay.f.Artillery_Fire(cannon, ply)
                    elseif IsValid(cannon) and not IsValid(ply) then
                        RemoveCannon(cannon)
                    end
                end)
            end

            -- Removes the cannon automatically after it is done
            timer.Simple(28.65, function()
                if IsValid(cannon) then
                    RemoveCannon(cannon)
                end
            end)
        end

        if SERVER then
            self:Remove()
        end

        return self.BaseClass.PrimaryAttack(self)
    end
end

TTTPAP:Register(UPGRADE)