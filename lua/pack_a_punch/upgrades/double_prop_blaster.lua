local UPGRADE = {}
UPGRADE.id = "double_prop_blaster"
UPGRADE.class = "weapon_prop_blaster"
UPGRADE.name = "Double Prop Blaster"
UPGRADE.desc = "Throw 2 grenades!\nThe other takes an extra 20 seconds to explode!"

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldCreateGrenade = SWEP.CreateGrenade

    function SWEP:CreateGrenade(src, ang, vel, angimp, ply)
        self:PAPOldCreateGrenade(src, ang, vel, angimp, ply)
        local dettime = self:GetDetTime()

        timer.Simple(1, function()
            local gren = ents.Create("ent_prop_blaster_grenade")
            if not IsValid(gren) then return end
            gren:SetPos(src)
            gren:SetAngles(ang)
            gren:SetOwner(ply)
            gren:SetThrower(ply)
            gren:SetGravity(0.4)
            gren:SetFriction(0.2)
            gren:SetElasticity(0.45)
            gren:Spawn()
            gren:PhysWake()
            gren:SetMaterial(TTTPAP.camo)
            local phys = gren:GetPhysicsObject()

            if IsValid(phys) then
                phys:SetVelocity(vel)
                phys:AddAngleVelocity(angimp)
            end

            gren:SetDetonateExact(dettime + 20)

            timer.Simple(18, function()
                if IsValid(gren) then
                    gren:EmitSound("prop_blaster/prop_blastin.wav")
                end
            end)
        end)
    end
end

TTTPAP:Register(UPGRADE)