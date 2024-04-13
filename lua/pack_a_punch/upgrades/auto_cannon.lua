local UPGRADE = {}
UPGRADE.id = "auto_cannon"
UPGRADE.class = "weapon_ttt_artillery"
UPGRADE.name = "Auto Cannon"
UPGRADE.desc = "Auto-shoots, pressing 'E' removes the cannon!"
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
    end
end)

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()
    local cannon

    if SERVER and IsValid(owner) then
        owner:PrintMessage(HUD_PRINTCENTER, "Pressing 'E' REMOVES the cannon!")
    end

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
            cannon:SetMaterial(TTTPAP.camo)

            for i = 1, musicVolume do
                cannon:EmitSound("ttt_pack_a_punch/auto_cannon/1812_overture.mp3")
            end

            cannon:SetUseType(SIMPLE_USE)
            cannon.UnlimitedAmmo = true
            cannon.Owner = ply
            cannon.ShowedWarningMessage = false

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
            local shootDelays = {15, 18, 20.8, 23.7, 26.5, 29.3, 32.2, 35.2}

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
            timer.Simple(38, function()
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