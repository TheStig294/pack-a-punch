AddCSLuaFile()
ENT.Type = "anim"
ENT.PrintName = "Banana Bomb"

function ENT:Initialize()
	self:SetModel("models/props/cs_italy/bananna_bunch.mdl")
	self:SetMaterial(TTTPAP.camo)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	if CLIENT then return end

	timer.Simple(4, function()
		if IsValid(self) then
			local pos = self:GetPos()
			local explosionEffect = EffectData()
			explosionEffect:SetStart(pos)
			explosionEffect:SetOrigin(pos)
			explosionEffect:SetScale(1)
			util.Effect("Explosion", explosionEffect)
			util.BlastDamage(self, self.PAPOwner or self, self:GetPos(), 230, 90)
			local bananaBus = ents.Create("ttt_pap_banana_bus")
			bananaBus.PAPOwner = self.PAPOwner
			bananaBus:SetPos(self:GetPos())
			bananaBus:Spawn()
			self:Remove()
		end
	end)
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