AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_mine_turtle"
ENT.HelloSound = Sound("ttt_pack_a_punch/mine_train/i_like_trains.mp3")
ENT.ExplosionSound = Sound("ttt_pack_a_punch/mine_train/train.mp3")

if SERVER then
    function ENT:Think()
        if IsValid(self) and self:IsActive() then
            if not self.HelloPlayed then
                local isValid

                for _, ent in ipairs(ents.FindInSphere(self:GetPos(), self.ScanRadius)) do
                    -- Spectator Deathmatch support
                    isValid = IsValid(ent) and ent:IsPlayer() and not ent:IsSpec()

                    if isValid and specDM then
                        isValid = not ent:IsGhost()
                    end

                    if isValid then
                        -- check if the target is visible
                        local spos = self:GetPos() + Vector(0, 0, 10) -- let it work a bit better on steps, but then it doesn't work so good at ceilings
                        local epos = ent:GetPos() + Vector(0, 0, 10) -- let it work a bit better on steps, but then it doesn't work so good at ceilings

                        local tr = util.TraceLine({
                            start = spos,
                            endpos = epos,
                            filter = self,
                            mask = MASK_SOLID
                        })

                        if not tr.HitWorld and IsValid(tr.Entity) and not table.HasValue(validDoors, tr.Entity:GetClass()) and ent:Alive() then
                            self.Target = ent
                            self:EmitSound(self.ClickSound)

                            timer.Simple(0.15, function()
                                if IsValid(self) then
                                    sound.Play(self.HelloSound, self:GetPos(), 100, math.random(95, 105), 1)
                                end
                            end)

                            self.HelloPlayed = true

                            timer.Simple(0.85, function()
                                if IsValid(self) then
                                    self:StartExplode(true)
                                end
                            end)

                            break
                        end
                    end
                end
            end

            self:NextThink(CurTime() + 0.05)

            return true
        end
    end
end

function ENT:Explode(checkActive)
    if IsValid(self) and not self.Exploding then
        if checkActive and not self:IsActive() then return end
        self.Exploding = true
        local pos = self:GetPos()
        local radius = self.BlastRadius
        local damage = self.BlastDamage
        self:EmitSound(self.ExplosionSound, 60, math.random(125, 150))
        util.BlastDamage(self, self:GetPlacer(), pos, radius, damage)
        local train = ents.Create("prop_dynamic")
        train:SetPos(owner:EyePos() + owner:GetAimVector() * 100)
        train:SetAngles(owner:EyeAngles())
        train.Target = self.Target
        train:Spawn()

        function train:Think()
            local time = CurTime()
            self.time = self.time or time
            local deltaTime = time - self.time
            self.time = time
            self.runTime = self.runTime or 0 + deltaTime
            local position = self:GetPos()
            local ang = self:GetAngles()
            ang:RotateAroundAxis(ang:Up(), 2)
            local forward = ang:Forward() * self.CarSpeed * deltaTime
            self.Dist = self.Dist + forward:Length()

            if self.Dist > self.CarRange then
                self.ToRemove = true
            end

            self.startPos = self.startPos or position

            if self.ToRemove then
                if CLIENT then return end
                self:StopSound(self.Sound)
                self:StopSound(self.Sound)
                SafeRemoveEntity(self.Trail)

                if IsValid(self.Target) and (self.Target:IsFrozen() or self.Target:HasGodMode()) then
                    self.Target:UnLock()
                end

                self:Remove()

                return
            end

            local set = pos + forward
            self:SetPos(set)
        end

        self:Remove()
    end
end