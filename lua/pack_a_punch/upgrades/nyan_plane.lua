local UPGRADE = {}
UPGRADE.id = "nyan_plane"
UPGRADE.class = "weapon_ttt_paper_plane"
UPGRADE.name = "Nyan Plane"
UPGRADE.desc = "Moves faster, is now a Nyan Cat!"

UPGRADE.convars = {
    {
        name = "pap_nyan_plane_speed_mult",
        type = "float",
        decimals = "2"
    }
}

local speedMultCvar = CreateConVar("pap_nyan_plane_speed_mult", "1.2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Speed multiplier", 0.1, 2)

function UPGRADE:Apply(SWEP)
    local targetJester = GetConVar("ttt_paper_plane_target_jester")

    local function CanTargetOwnTeam(thrower)
        local targetTraitors = cvars.Bool("ttt_snailplane_target_fellow_traitors")
        local targetInnocents = cvars.Bool("ttt_snailplane_target_fellow_innocents")
        local targetMonsters = cvars.Bool("ttt_snailplane_target_fellow_monsters")

        if TTT2 then
            if thrower:GetTeam() == TEAM_TRAITOR and targetTraitors then return true end
            if thrower:GetTeam() == TEAM_INNOCENT and targetInnocents then return true end
        elseif CR_VERSION then
            if thrower:IsTraitorTeam() and targetTraitors then return true end
            if thrower:IsInnocentTeam() and targetInnocents then return true end
            if thrower:IsMonsterTeam() and targetMonsters then return true end
        else
            if thrower:IsTraitor() and targetTraitors then return true end
            if not thrower:IsTraitor() and targetInnocents then return true end
        end

        return false
    end

    function SWEP:CreatePaperWing()
        if SERVER then
            local owner = self:GetOwner()
            local plane = ents.Create("ttt_paper_plane_proj")

            if IsValid(plane) and IsValid(owner) then
                local vsrc = owner:GetShootPos()
                local vang = owner:GetAimVector()
                local vvel = owner:GetVelocity()
                local vthrow = vvel + vang * 250
                plane:SetPos(vsrc + vang * 50)
                plane:SetAngles(owner:GetAimVector():Angle() + Angle(0, 180, 0))
                plane:Spawn()
                plane:SetThrower(owner)
                plane:SetNWEntity("paper_plane_owner", owner)
                -- Added PAPUpgrade flag
                plane:SetNWBool("TTTPAPNyanPlane", true)

                -- Replacing the red trail with the nyan cat rainbow trail
                for _, ent in ipairs(plane:GetChildren()) do
                    if ent:GetClass() == "env_spritetrail" then
                        ent:Remove()
                    end
                end

                util.SpriteTrail(plane, 0, Color(255, 255, 255, 255), false, 32, 30, 2, 0.128, "ttt_pack_a_punch/nyan_cannon/trail")

                -- Replacing the plane model, and gun model if present with a 2D nyan cat sprite
                -- This is drawn outise the CreatePaperWing hook far below in a PostDrawOpaqueRenderables hook attatched to the upgrade instead
                if IsValid(plane.gunModel) then
                    plane.gunModel:Remove()
                end

                plane:SetNoDraw(true)

                -- Playing the minecraft note block nyan cat music on a loop
                for i = 1, 3 do
                    plane:EmitSound("ttt_pack_a_punch/nyan_plane/mc_nyan_cat.mp3")
                end

                plane:CallOnRemove("TTTPAPNyanPlaneStopMusic", function(ent)
                    for i = 1, 3 do
                        ent:StopSound("ttt_pack_a_punch/nyan_plane/mc_nyan_cat.mp3")
                    end
                end)

                local timername = "TTTPAPNyanPlaneMusicLoop" .. plane:EntIndex()

                timer.Create(timername, 28.846, 0, function()
                    if not IsValid(plane) then
                        timer.Remove(timername)

                        return
                    end

                    for i = 1, 3 do
                        plane:EmitSound("ttt_pack_a_punch/nyan_plane/mc_nyan_cat.mp3")
                    end
                end)

                -- This whole hook has to be copied to make the plane move faster while still being compatible with servers with just the base paper plane mod
                -- and not the snail plane mod
                function plane:SearchPlayer()
                    if SERVER then
                        local pos = self:GetPos()
                        local sphere = ents.FindInSphere(pos, 5000)
                        local playersInSphere = {}
                        local thrower = self:GetThrower()

                        for key, v in pairs(sphere) do
                            if v:IsPlayer() and v:Alive() and not v:IsSpec() and v ~= thrower then
                                if TTT2 then
                                    if v:GetTeam() ~= thrower:GetTeam() or CanTargetOwnTeam(thrower) then
                                        table.insert(playersInSphere, v)
                                    end
                                elseif CR_VERSION then
                                    if (not v:IsSameTeam(thrower) or CanTargetOwnTeam(thrower)) and not (not targetJester:GetBool() and v:IsJesterTeam()) then
                                        table.insert(playersInSphere, v)
                                    end
                                else
                                    if v:IsTraitor() ~= thrower:IsTraitor() or CanTargetOwnTeam(thrower) then
                                        table.insert(playersInSphere, v)
                                    end
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
                                -- Default speed multiplier: -200
                                -- Speed is increased by pap_nyan_plane_speed_mult convar
                                phys:ApplyForceCenter((self:GetPos() - closestPlayer:GetShootPos()) * -(speedMultCvar:GetFloat() * cvars.Number("ttt_snailplane_speed", 200)))
                                phys:SetAngles((self:GetPos() - closestPlayer:GetShootPos()):Angle())
                            end
                            -- No warning music
                        end

                        table.Empty(playersInSphere)
                    end
                end

                if TTT2 then
                    plane.userdata = {
                        team = owner:GetTeam()
                    }

                    timer.Simple(0.1, function()
                        net.Start("ttt_paper_plane_register_thrower")
                        net.WriteEntity(plane)
                        net.WriteString(owner:GetTeam())
                        net.Broadcast()
                    end)
                end

                local phys = plane:GetPhysicsObject()

                if IsValid(phys) then
                    phys:SetVelocity(vthrow)
                    phys:SetMass(200)
                end

                self.ENT = plane
            end
        end
    end

    local material = Material("ttt_pack_a_punch/nyan_cannon/nyan_cat.png", "nocull")

    self:AddHook("PostDrawOpaqueRenderables", function()
        for _, plane in ipairs(ents.FindByClass("ttt_paper_plane_proj")) do
            if plane:GetNWBool("TTTPAPNyanPlane") then
                local angle = plane:GetAngles()
                angle.x = 0
                cam.Start3D2D(plane:GetPos(), angle + Angle(0, 180, 90), 0.1)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(material)
                surface.DrawTexturedRect(0, -256, 512, 512)
                cam.End3D2D()
            end
        end
    end)
end

TTTPAP:Register(UPGRADE)