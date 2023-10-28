local UPGRADE = {}
UPGRADE.id = "double_turtle_grenade"
UPGRADE.class = "weapon_ttt_turtlenade"
UPGRADE.name = "Double Turtle Grenade"
UPGRADE.desc = "Throw 2 grenades!\nThe other takes an extra 20 seconds to explode!"

function UPGRADE:Apply(SWEP)
    function SWEP:PAPOldCreateGrenade(src, ang, vel, angimp, ply)
        local gren = ents.Create(self:GetGrenadeName())
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

        -- This has to happen AFTER Spawn() calls gren's Initialize()
        gren:SetDetonateExact(self:GetDetTime())

        return gren
    end

    function SWEP:CreateGrenade(src, ang, vel, angimp, ply)
        self:PAPOldCreateGrenade(src, ang, vel, angimp, ply)
        local gren = self:PAPOldCreateGrenade(src, ang, vel, angimp, ply)
        gren:SetDetonateExact(self:GetDetTime() + 20)
    end
end

TTTPAP:Register(UPGRADE)