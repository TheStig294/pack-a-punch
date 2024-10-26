local UPGRADE = {}
UPGRADE.id = "quad_auto_radio"
UPGRADE.class = "weapon_ttt_radio"
UPGRADE.name = "Quad Auto-Radio"
UPGRADE.desc = "Auto-plays sounds, +3 extra radios!"

function UPGRADE:Apply(SWEP)
    SWEP.RadioCount = 0
    local throwsound = Sound("Weapon_SLAM.SatchelThrow")

    local radioSounds = {"scream", "explosion", "footsteps", "burning", "beeps", "shotgun", "pistol", "mac10", "deagle", "m16", "rifle", "huge"}

    -- c4 plant but different
    function SWEP:RadioDrop()
        if SERVER then
            local ply = self:GetOwner()
            if not IsValid(ply) then return end
            local vsrc = ply:GetShootPos()
            local vang = ply:GetAimVector()
            local vvel = ply:GetVelocity()
            local vthrow = vvel + vang * 200
            local radio = ents.Create("ttt_radio")

            if IsValid(radio) then
                radio:SetPos(vsrc + vang * 10)
                radio:SetOwner(ply)
                radio:Spawn()
                radio:PhysWake()
                radio:SetPAPCamo()
                local timerName = radio:EntIndex() .. "TTTPAPRadio"

                timer.Create(timerName, 20, 0, function()
                    if not IsValid(radio) then
                        timer.Remove(timerName)

                        return
                    end

                    if math.random() < 0.5 then return end
                    radio:PlaySound(radioSounds[math.random(#radioSounds)])
                end)

                local phys = radio:GetPhysicsObject()

                if IsValid(phys) then
                    phys:SetVelocity(vthrow)
                end

                self.RadioCount = self.RadioCount + 1

                if self.RadioCount >= 4 then
                    self:Remove()
                end

                self.Planted = true
            end
        end

        self:EmitSound(throwsound)
    end

    -- hey look, more C4 code
    function SWEP:RadioStick()
        if SERVER then
            local ply = self:GetOwner()
            if not IsValid(ply) then return end

            -- if self.Planted then return end
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
                local radio = ents.Create("ttt_radio")

                if IsValid(radio) then
                    radio:PointAtEntity(ply)

                    local tr_ent = util.TraceEntity({
                        start = spos,
                        endpos = epos,
                        filter = ignore,
                        mask = MASK_SOLID
                    }, radio)

                    if tr_ent.HitWorld then
                        local ang = tr_ent.HitNormal:Angle()
                        ang:RotateAroundAxis(ang:Up(), -180)
                        radio:SetPos(tr_ent.HitPos + ang:Forward() * -2.5)
                        radio:SetAngles(ang)
                        radio:SetOwner(ply)
                        radio:Spawn()
                        radio:SetPAPCamo()
                        local timerName = radio:EntIndex() .. "TTTPAPRadio"

                        timer.Create(timerName, 20, 240, function()
                            if not IsValid(radio) then
                                timer.Remove(timerName)

                                return
                            end

                            if math.random() < 0.5 then return end
                            radio:PlaySound(radioSounds[math.random(#radioSounds)])
                        end)

                        local phys = radio:GetPhysicsObject()

                        if IsValid(phys) then
                            phys:EnableMotion(false)
                        end

                        radio.IsOnWall = true
                        self.RadioCount = self.RadioCount + 1

                        if self.RadioCount >= 4 then
                            self:Remove()
                        end

                        self.Planted = true
                    end
                end
            end
        end
    end
end

TTTPAP:Register(UPGRADE)