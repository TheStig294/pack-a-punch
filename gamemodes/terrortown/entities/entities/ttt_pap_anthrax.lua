AddCSLuaFile()
ENT.Type = "anim"
ENT.PrintName = "Anthrax Bottle Crate"

function ENT:Initialize()
	self:SetModel("models/props_junk/PlasticCrate01a.mdl")
	self:SetPAPCamo()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	local phys = self:GetPhysicsObject()

	if IsValid(phys) then
		phys:Wake()
		phys:EnableGravity(false)
	end

	timer.Simple(1.25, function()
		if IsValid(self) then
			self:SpawnBottles()
		end
	end)
end

function ENT:PhysicsCollide(data, physobj)
	self:EmitSound("physics/plastic/plastic_box_impact_soft" .. math.random(1, 4) .. ".wav")
	local hitEnt = data.HitEntity
	-- Don't damage traitors
	if not IsPlayer(hitEnt) or hitEnt:GetRole() == ROLE_TRAITOR or (hitEnt.IsTraitorTeam and hitEnt:IsTraitorTeam()) then return end
	local dmginfo = DamageInfo()
	dmginfo:SetDamage(9000)
	dmginfo:SetAttacker(self.PAPOwner or self)
	dmginfo:SetInflictor(self)
	-- Choose a damage type the jester is immune to, so they can't win by running into this
	dmginfo:SetDamageType(DMG_GENERIC)
	data.HitEntity:TakeDamageInfo(dmginfo)
end

function ENT:SpawnBottles()
	if CLIENT then return end

	for i = 1, 32 do
		local bottle = ents.Create("ttt_pap_anthrax_bottle")

		if IsValid(bottle) then
			bottle:SetPos(self:GetPos() + Vector(0, 0, 10) + VectorRand() * 5)
			bottle:SetAngles(Angle(math.Rand(0, 360), math.Rand(0, 360), math.Rand(0, 360)))
			bottle:Spawn()
			bottle:Activate()
			bottle.PAPOwner = self.PAPOwner
		end
	end
end