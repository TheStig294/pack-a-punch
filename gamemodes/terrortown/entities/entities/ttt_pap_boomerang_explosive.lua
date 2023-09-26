AddCSLuaFile()
ENT.Base = "ent_boomerangclose"
ENT.Type = "anim"
ENT.PrintName = "Explosive Boomerang"

function ENT:Initialize()
    self.BaseClass.Initialize(self)
    self:SetMaterial(TTTPAP.camo)
end

function ENT:PhysicsCollide(data, phys)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if self.Drop or self.Hits >= 4 then return end
    local hitEntity = data.HitEntity

    if hitEntity == owner then
        owner:Give("weapon_ttt_boomerang")

        if SERVER then
            self:Remove()
        end
    end

    if IsValid(hitEntity) then
        if hitEntity:IsPlayer() or hitEntity:GetClass() ~= "prop_ragdoll" then
            self:SetPos(self:GetPos() + (self.LastVelocity:GetNormalized() * 40))
            self:SetAngles(Angle(20, 0, 90))
            self:GetPhysicsObject():AddAngleVelocity(Vector(0, -1000, 0) - self:GetPhysicsObject():GetAngleVelocity())
        end

        if hitEntity == self.LastHitEntity and self.TargetReached == self.LastHitDirection then return end
        self.LastHitEntity = hitEntity
        self.LastHitDirection = self.TargetReached

        if hitEntity:IsPlayer() then
            self.Hits = self.Hits + 1
        end

        -- Plays a larger explosion sound
        self:EmitSound("ambient/explosions/explode_3.wav")
        local explode = ents.Create("env_explosion")
        explode:SetPos(self:GetPos())

        if IsValid(owner) then
            explode:SetOwner(owner)
            owner.PAPExplosiveBoomerang = false
            -- Leaves a bunch of fire on exploding
            local tr = util.QuickTrace(self:GetPos(), Vector(0, 0, -1))
            StartFires(self:GetPos(), tr, 20, 40, false, owner)
        end

        explode:SetKeyValue("iMagnitude", 200)
        explode:SetKeyValue("iRadiusOverride", 200)
        explode:Spawn()
        explode:Fire("Explode", 0, 0)
        self:Remove()
    end

    if not hitEntity:IsPlayer() and hitEntity:GetClass() ~= "prop_ragdoll" then
        self.CollideCount = self.CollideCount + 1

        if self.CollideCount > 1 then
            owner:SetNWEntity("boomerang_swep", self)

            timer.Create("propTimer", 1, 1, function()
                deploySwep(self)
            end)

            self.Drop = true
        else
            self:SetPos(self:GetPos() + ((owner:GetShootPos() - self:GetPos()):GetNormalized() * 20))
            self:GoYourWayBack(20, 600)
        end
    else
        self:SetAngles(Angle(20, 0, 90))
        self:NextThink(CurTime())
    end
end