AddCSLuaFile()
ENT.Type = "anim"
ENT.PrintName = "Banana Bomb"

function ENT:Initialize()
	self:SetModel("models/props/cs_italy/bananna_bunch.mdl")
	self:SetMaterial(TTTPAP.camo)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	timer.Simple(4, function()
		if IsValid(self) then
			self:SpawnBananas()
		end
	end)
end

function ENT:SpawnBananas()
	if CLIENT then return end

	for i = 1, 14 do
		local banana = ents.Create("ttt_pap_banana")

		if IsValid(banana) then
			banana:SetPos(self:GetPos() + Vector(0, 0, 10) + VectorRand() * 5)
			banana:SetAngles(Angle(math.Rand(0, 360), math.Rand(0, 360), math.Rand(0, 360)))
			banana:Spawn()
			banana:Activate()
			banana.PAPOwner = self.PAPOwner
		end
	end

	local bananaBus = ents.Create("ttt_pap_banana_bus")
	bananaBus:SetPos(self:GetPos())
	bananaBus:Spawn()
	bananaBus.PAPOwner = self.PAPOwner
	self:Remove()
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