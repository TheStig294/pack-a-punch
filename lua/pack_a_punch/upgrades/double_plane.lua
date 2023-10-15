local UPGRADE = {}
UPGRADE.id = "double_plane"
UPGRADE.class = "weapon_ttt_paper_plane"
UPGRADE.name = "Double Plane"
UPGRADE.desc = "Spawns 2 planes that travel much faster"

function UPGRADE:Apply(SWEP)
    timer.Simple(0.1, function()
        SWEP:SetClip1(2)
    end)

    function SWEP:PrimaryAttack()
        if self.PAPTriplePlaneThrown then return end
        if not self:CanPrimaryAttack() then return end
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self.PAPTriplePlaneThrown = true
        local timername = "TTTPAPTriplePlane" .. self:EntIndex()

        timer.Create(timername, 0.5, 2, function()
            if not IsValid(self) then
                timer.Remove(timername)

                return
            end

            self:CreatePaperWing()
            self:TakePrimaryAmmo(1)

            if SERVER and timer.RepsLeft(timername) == 0 then
                self:Remove()
            end
        end)
    end

    local targetJester = GetConVar("ttt_paper_plane_target_jester")

    function SWEP:CreatePaperWing()
        if SERVER then
            local owner = self:GetOwner()
            local paper_plane = ents.Create("ttt_paper_plane_proj")

            if IsValid(paper_plane) and IsValid(owner) then
                local vsrc = owner:GetShootPos()
                local vang = owner:GetAimVector()
                local vvel = owner:GetVelocity()
                local vthrow = vvel + vang * 250
                paper_plane:SetPos(vsrc + vang * 50)
                paper_plane:SetAngles(owner:GetAimVector():Angle() + Angle(0, 180, 0))
                paper_plane:Spawn()
                paper_plane:SetThrower(owner)
                paper_plane:SetNWEntity("paper_plane_owner", owner)
                paper_plane:SetMaterial(TTTPAP.camo)

                function paper_plane:SearchPlayer()
                    if SERVER then
                        local pos = self:GetPos()
                        local sphere = ents.FindInSphere(pos, 5000)
                        local playersInSphere = {}
                        local thrower = self:GetThrower()

                        for key, v in pairs(sphere) do
                            if TTT2 then
                                if v:IsPlayer() and v:Alive() and not v:IsSpec() and v:GetTeam() ~= thrower:GetTeam() then
                                    table.insert(playersInSphere, v)
                                end
                            elseif CR_VERSION then
                                if v:IsPlayer() and v:Alive() and not v:IsSpec() and not v:IsSameTeam(thrower) and not (not targetJester:GetBool() and v:IsJesterTeam()) then
                                    table.insert(playersInSphere, v)
                                end
                            else
                                if v:IsPlayer() and v:GetRole() ~= thrower:GetRole() and v:Alive() and not v:IsSpec() then
                                    table.insert(playersInSphere, v)
                                end
                            end
                        end

                        local closestPlayer = self:GetClosestPlayer(self, playersInSphere)

                        if closestPlayer ~= nil then
                            local tracedata = {}
                            tracedata.start = closestPlayer:GetShootPos()
                            tracedata.endpos = self:GetPos()

                            tracedata.filter = {self, closestPlayer}

                            local tr = util.TraceLine(tracedata)

                            if tr.HitPos == tracedata.endpos then
                                local phys = self:GetPhysicsObject()
                                phys:ApplyForceCenter((self:GetPos() - closestPlayer:GetShootPos()) * -400)
                                phys:SetAngles((self:GetPos() - closestPlayer:GetShootPos()):Angle())
                            end
                        end

                        table.Empty(playersInSphere)
                    end
                end

                if TTT2 then
                    paper_plane.userdata = {
                        team = owner:GetTeam()
                    }

                    timer.Simple(0.1, function()
                        net.Start("ttt_paper_plane_register_thrower")
                        net.WriteEntity(paper_plane)
                        net.WriteString(owner:GetTeam())
                        net.Broadcast()
                    end)
                end

                local phys = paper_plane:GetPhysicsObject()

                if IsValid(phys) then
                    phys:SetVelocity(vthrow)
                    phys:SetMass(200)
                end

                self.ENT = paper_plane
            end
        end
    end
end

TTTPAP:Register(UPGRADE)