local UPGRADE = {}
UPGRADE.id = "nyan_plane"
UPGRADE.class = "weapon_ttt_paper_plane"
UPGRADE.name = "Nyan Plane"
UPGRADE.desc = "Throws 2 planes at once, is now a Nyan Cat!"

function UPGRADE:Apply(SWEP)
    local function SpawnPlane(wep)
        if CLIENT then return end
        local owner = wep:GetOwner()
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

            wep.ENT = plane
        end
    end

    function SWEP:CreatePaperWing()
        if CLIENT then return end

        for i = 1, 2 do
            SpawnPlane(self)
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