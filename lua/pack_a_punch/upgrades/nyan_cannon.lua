local UPGRADE = {}
UPGRADE.id = "nyan_cannon"
UPGRADE.class = "the_xmas_gun"
UPGRADE.name = "Nyan Cannon"
UPGRADE.desc = "x2 ammo, shoots Nyan Cats!"
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    function SWEP:FirePresent()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        aim = owner:GetAimVector()
        side = aim:Cross(Vector(0, 0, 1))
        up = side:Cross(aim)
        pos = owner:GetShootPos() + side * 6 + up * -5

        if SERVER then
            local present = ents.Create("XmasPresent")
            if not present:IsValid() then return false end
            present:SetAngles(aim:Angle() + Angle(-0.25, 0.25, 0))
            present:SetPos(pos)
            present:SetOwner(owner)
            present:Spawn()
            present.Owner = owner
            present:Activate()
            eyes = owner:EyeAngles()
            local phys = present:GetPhysicsObject()
            phys:SetVelocity(owner:GetAimVector() * 10000)
            present:SetNoDraw(true)
            present:SetNWBool("PAPNyanCannon", true)
            present:EmitSound("ttt_pack_a_punch/nyan_cannon/nyan_cat.mp3")

            for _, child in ipairs(present:GetChildren()) do
                if child:GetClass() == "env_spritetrail" then
                    child:Remove()
                end
            end

            util.SpriteTrail(present, 0, Color(255, 255, 255, 255), false, 32, 30, 2, 0.128, "ttt_pack_a_punch/nyan_cannon/trail")
        end

        if SERVER and not owner:IsNPC() then
            local anglo = Angle(-3, -2, 0)
            owner:ViewPunch(anglo)
        end
    end

    local material = Material("ttt_pack_a_punch/nyan_cannon/nyan_cat.png", "nocull")

    self:AddHook("PostDrawOpaqueRenderables", function()
        for _, present in ipairs(ents.FindByClass("XmasPresent")) do
            if present:GetNWBool("PAPNyanCannon") then
                local angle = present:GetAngles()
                angle.x = 0
                cam.Start3D2D(present:GetPos(), angle + Angle(0, 90, 90), 0.1)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(material)
                surface.DrawTexturedRect(-256, -512, 512, 512)
                cam.End3D2D()
            end
        end
    end)
end

TTTPAP:Register(UPGRADE)