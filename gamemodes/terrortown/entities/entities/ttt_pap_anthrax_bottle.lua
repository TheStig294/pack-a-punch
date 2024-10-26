AddCSLuaFile()
ENT.Type = "anim"
ENT.PrintName = "Anthrax Bottle"

function ENT:Initialize()
	self:SetModel("models/props_junk/garbage_glassbottle003a.mdl")
	self:SetPAPCamo()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	local phys = self:GetPhysicsObject()

	if IsValid(phys) then
		phys:Wake()
		phys:EnableGravity(false)
	end
end

function ENT:PhysicsCollide(data, physobj)
	self:EmitSound("physics/glass/glass_bottle_impact_hard" .. math.random(1, 3) .. ".wav")
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