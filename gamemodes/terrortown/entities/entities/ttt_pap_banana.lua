AddCSLuaFile()
ENT.Type = "anim"
ENT.PrintName = "Banana Bomb"

function ENT:Initialize()
	self:SetModel("models/props/cs_italy/bananna.mdl")
	self:SetMaterial(TTTPAP.camo)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	local phys = self:GetPhysicsObject()

	if IsValid(phys) then
		phys:ApplyForceCenter(phys:GetMass() * (VectorRand() + Vector(0, 0, 2)) * math.Rand(4, 8) * 10)

		timer.Simple(0.5, function()
			if IsValid(phys) then
				phys:ApplyForceCenter(Vector(0, 0, 15) * 10)
			end
		end)

		timer.Simple(1.5, function()
			if IsValid(self) then
				local pos = self:GetPos()
				local explosionEffect = EffectData()
				explosionEffect:SetStart(pos)
				explosionEffect:SetOrigin(pos)
				explosionEffect:SetScale(1)
				util.Effect("Explosion", explosionEffect)

				if SERVER then
					util.BlastDamage(self, self.PAPOwner or self, self:GetPos(), 230, 90)
					self:Remove()
				end
			end
		end)
	end
end

function ENT:PhysicsCollide(data, phys)
	self:EmitSound(Sound("weapons/bugbait/bugbait_squeeze" .. math.random(1, 3) .. ".wav"))
	local LastSpeed = math.max(data.OurOldVelocity:Length(), data.Speed)
	local physobj = data.PhysObject
	local NewVelocity = physobj:GetVelocity()
	NewVelocity:Normalize()
	LastSpeed = math.max(NewVelocity:Length(), LastSpeed)
	local TargetVelocity = NewVelocity * LastSpeed * 0.85
	physobj:SetVelocity(TargetVelocity)
end