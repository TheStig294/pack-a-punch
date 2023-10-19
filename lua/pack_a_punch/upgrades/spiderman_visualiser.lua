local UPGRADE = {}
UPGRADE.id = "spiderman_visualiser"
UPGRADE.class = "weapon_ttt_cse"
UPGRADE.name = "Spiderman Visualiser"
UPGRADE.desc = "Shows the pointing spiderman meme"

function UPGRADE:Apply(SWEP)
    local throwsound = Sound("Weapon_SLAM.SatchelThrow")

    function SWEP:DropDevice()
        local cse = nil

        if SERVER then
            local ply = self:GetOwner()
            if not IsValid(ply) then return end
            if self.Planted then return end
            local vsrc = ply:GetShootPos()
            local vang = ply:GetAimVector()
            local vvel = ply:GetVelocity()
            local vthrow = vvel + vang * 200
            cse = ents.Create("ttt_pap_spiderman_visualiser")

            if IsValid(cse) then
                cse:SetPos(vsrc + vang * 10)
                cse:SetOwner(ply)
                cse:SetThrower(ply)
                cse:Spawn()
                cse:PhysWake()
                cse:SetMaterial(TTTPAP.camo)
                local phys = cse:GetPhysicsObject()

                if IsValid(phys) then
                    phys:SetVelocity(vthrow)
                end

                self:Remove()
                self.Planted = true
            end
        end

        self:EmitSound(throwsound)

        return cse
    end
end

TTTPAP:Register(UPGRADE)