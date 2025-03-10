local UPGRADE = {}
UPGRADE.id = "the_dark_side"
UPGRADE.class = "weapon_ttt_traitor_lightsaber"
UPGRADE.name = "The Dark Side"
UPGRADE.desc = "Pick up things using the force!\nPlayers take much more ammo to pick up"

function UPGRADE:Apply(SWEP)
    local lightsaber_hit_help
    local lightsaber_reload_help
    local lightsaber_mode_help

    if TTT2 then
        lightsaber_hit_help = "Hit with the lightsaber"
        lightsaber_reload_help = "Switch the force power"

        lightsaber_mode_help = {"Block incoming shots and send them back", "Unleash force lightning", "Push your enemies away from you", "Pull your enemies towards you", "Carry objects around"}
    else
        lightsaber_reload_help = "RELOAD to switch the force power"

        lightsaber_mode_help = {"MOUSE2 to block incoming shots and send them back", "MOUSE2 to unleash force lightning", "MOUSE2 to push your enemies away from you", "MOUSE2 to force pull your enemies towards you", "MOUSE2 to start carrying an object"}
    end

    timer.Simple(0.1, function()
        SWEP.darkMode = 4

        if CLIENT then
            SWEP:AddHUDHelp(lightsaber_mode_help[SWEP.darkMode + 1], lightsaber_reload_help, false)
        end
    end)

    -- Making it so there is an extra mode slot: darkMode = 4
    function SWEP:Reload()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        if self.ReloadingTime and CurTime() <= self.ReloadingTime then return end

        if self.isBlocking then
            self.isBlocking = false
        end

        if self.StandardRunSpeed ~= 0 then
            owner:SetWalkSpeed(self.StandardWalkSpeed)
            owner:SetRunSpeed(self.StandardRunSpeed)
        end

        -- Only thing changed is changing the max number of modes from 4 to 5 here
        self.darkMode = (self.darkMode + 1) % 5

        if CLIENT then
            if TTT2 then
                self:AddTTT2HUDHelp(lightsaber_hit_help, lightsaber_mode_help[self.darkMode + 1])
                self:AddHUDHelpLine(lightsaber_reload_help, Key("+reload", "R"))
            else
                self:AddHUDHelp(lightsaber_mode_help[self.darkMode + 1], lightsaber_reload_help, false)
            end
        end

        self:SetNextSecondaryFire(CurTime() + 0.1)
        self.ReloadingTime = CurTime() + 0.5

        if CLIENT then
            self:EmitSound("buttons/button14.wav")
        end

        self.reflectBullet = false
    end

    self:AddToHook(SWEP, "SecondaryAttack", function()
        if SWEP.darkMode == 4 then
            local owner = SWEP:GetOwner()
            if not IsValid(owner) or SWEP:Clip1() < 30 then return end

            if not owner.LagCompensation then
                owner:LagCompensation(true)
            end

            local target = owner:GetEyeTrace().Entity

            if not IsValid(SWEP.InitialTarget) then
                if not IsValid(target) then return end
                -- Wake up the entity's physics so objects aren't left floating in the air
                target:PhysWake()
                SWEP.InitialTarget = target
                SWEP.InitialDistance = owner:GetPos():Distance(target:GetPos())
            end

            SWEP.IsHoldingRightClick = true

            timer.Create("TTTPAPTheTraitorForceRightClick" .. SWEP:EntIndex(), 1, 1, function()
                if IsValid(SWEP) then
                    SWEP.IsHoldingRightClick = false
                    SWEP.InitialTarget = nil
                end
            end)

            SWEP:TakePrimaryAmmo(30)
            SWEP:SendWeaponAnim(ACT_RANGE_ATTACK2)
            SWEP:EmitSound("phantom/force/speed.wav")
            SWEP:SetNextSecondaryFire(CurTime() + 1)

            if owner.LagCompensation then
                owner:LagCompensation(false)
            end
        end
    end)

    self:AddToHook(SWEP, "Think", function()
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end

        if not owner.LagCompensation then
            owner:LagCompensation(true)
        end

        local ent = owner:GetEyeTrace().Entity

        owner.TTTPAPTheDarkSideEnt = {ent}

        if SERVER and SWEP.darkMode == 4 and SWEP.IsHoldingRightClick then
            local target = SWEP.InitialTarget
            local distance = SWEP.InitialDistance
            local tr = owner:GetEyeTrace()

            -- Not looking at the target
            -- Looking anywhere else while having a valid initial target
            -- Also check to ensure the object isn't getting pushed outside the map
            if (not IsValid(tr.Entity) or tr.Entity ~= target) and IsValid(target) and distance and target:IsInWorld() then
                local forwardVector = owner:GetForward() * distance
                local finalPos = owner:GetShootPos() + forwardVector

                if target:IsPlayer() then
                    local pushVector = finalPos - target:GetPos()
                    target:SetGroundEntity(NULL)
                    target:SetVelocity(pushVector)
                else
                    target:SetPos(finalPos)
                end
            end
        elseif SWEP.darkMode == 4 and not self.IsHoldingRightClick then
            SWEP.InitialTarget = nil
        end

        if owner.LagCompensation then
            owner:LagCompensation(false)
        end
    end)

    if CLIENT then
        self:AddHook("PreDrawHalos", function()
            local ply = LocalPlayer()
            if not ply.TTTPAPTheDarkSideEnt then return end
            local wep = ply:GetActiveWeapon()

            if IsValid(wep) and self:IsUpgraded(wep) then
                halo.Add(ply.TTTPAPTheDarkSideEnt, COLOR_WHITE, 1, 1, 3, true, false)
            end
        end)
    end

    -- Adding the HUD icon for the new mode
    if not TTT2 then
        function SWEP:DrawHUD()
            local offsetY = 0

            if hook.GetTable()["HUDPaint"]["SprintHUD"] ~= nil then
                offsetY = 80
            end

            if IsValid(self) then
                --here goes the new HUD
                local mode = "nothing"
                local darkModeCopy = self.darkMode
                local background = Material("vgui/ttt/force_push.png")

                if darkModeCopy == 1 then
                    mode = "Force Lightning"
                    background = Material("vgui/ttt/force_lightning.png")
                elseif darkModeCopy == 2 then
                    mode = "Force Push"
                    background = Material("vgui/ttt/force_push.png")
                elseif darkModeCopy == 3 then
                    mode = "Force Pull"
                    background = Material("vgui/ttt/force_pull.png")
                elseif darkModeCopy == 4 then
                    mode = "Force Carry"
                    background = Material("ttt_pack_a_punch/the_traitor_force/force_carry.png")
                elseif darkModeCopy == 0 then
                    mode = "Force Block"
                    background = Material("vgui/ttt/force_block.png")
                end

                local h = 16
                draw.RoundedBox(12, 295, ScrH() - h - 85 - offsetY, 160, 80, Color(0, 0, 0, 175))
                surface.SetMaterial(background)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawTexturedRect(300, ScrH() - h - 75 - offsetY, 150, 50)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetFont("HudHintTextLarge")
                local width = surface.GetTextSize(mode)
                draw.DrawText(mode, "HudHintTextLarge", 300 + (75 - width / 2.0), ScrH() - h - 25 - offsetY, Color(255, 255, 255, 255))
            end

            return self.BaseClass.DrawHUD(self)
        end
    end
end

TTTPAP:Register(UPGRADE)