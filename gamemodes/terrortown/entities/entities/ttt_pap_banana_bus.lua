if SERVER then
	AddCSLuaFile()
end

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "Bus"
ENT.Pos = Vector(0, 0, 0)
ENT.ClosestPlayerDist = nil
ENT.ClosestPlayer = nil
ENT.DistancePerTick = 2
ENT.SecondsPerTick = 0.01

function ENT:PlayBananaBusSound()
	self:EmitSound("ttt_pack_a_punch/banana_bus/banana_bus.mp3")
	self:EmitSound("ttt_pack_a_punch/banana_bus/banana_bus.mp3")
end

-- Set the prop to a bus
function ENT:Initialize()
	if SERVER then
		self:SetTrigger(true)
	end

	self:SetModel("models/ttt_pack_a_punch/bus/bus.mdl")
	self:SetMaterial(TTTPAP.camo)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NOCLIP)
	self:SetSolid(SOLID_VPHYSICS)
	self:PlayBananaBusSound()
	local phys = self:GetPhysicsObject()

	if IsValid(phys) then
		phys:Wake()
		phys:SetMass(1)
		phys:IsGravityEnabled(false)
	end

	if SERVER then
		util.SpriteTrail(self, 0, Color(255, 225, 53), false, 15, 1, 4, 1, "trails/plasma")
	end
end

function ENT:KillEnt(ent)
	local dmg = DamageInfo()
	dmg:SetDamage(10000)
	dmg:SetDamageType(DMG_GENERIC)
	dmg:SetInflictor(self)
	dmg:SetAttacker(self.PAPOwner or self)
	ent:TakeDamageInfo(dmg)
	self:PlayBananaBusSound()
end

-- Kill anything that touches it
function ENT:StartTouch(ent)
	if not IsValid(ent) then return end
	if ent:IsPlayer() and (not ent:Alive() or ent:IsSpec()) then return end
	self:KillEnt(ent)
	if ent:IsNPC() or ent:IsPlayer() then return end

	-- Let props that break have a chance to break
	timer.Simple(0.1, function()
		if IsValid(ent) then
			ent:Remove()
		end
	end)
end

function ENT:Think()
	self.Pos = self:GetPos()
	self.ClosestPlayer = nil
	self.ClosestPlayerDist = nil

	for _, ply in player.Iterator() do
		-- Don't chase dead players or jesters
		if ply:Alive() and not ply:IsSpec() and not (ply.IsJesterTeam and ply:IsJesterTeam()) then
			local plyDist = self.Pos:DistToSqr(ply:GetPos())

			if not self.ClosestPlayerDist or self.ClosestPlayerDist > plyDist then
				self.ClosestPlayerDist = plyDist
				self.ClosestPlayer = ply
			end
		end
	end

	if SERVER and IsValid(self.ClosestPlayer) and self.ClosestPlayer:Alive() and not self.ClosestPlayer:IsSpec() then
		-- 30 * 30 = 900 source units
		if self.ClosestPlayerDist < 900 then
			-- Kill close enough players
			self:KillEnt(self.ClosestPlayer)
		else
			-- Else chase players down
			self:PointAtEntity(self.ClosestPlayer)
			local angles = self:GetAngles()
			angles.y = angles.y - 90
			self:SetAngles(angles)
			local forward = self:GetForward()
			forward:Rotate(Angle(0, 90, 0))
			self.Pos:Add(forward * self.DistancePerTick)
			self:SetPos(self.Pos)
		end
	end

	local nextThink = CurTime() + self.SecondsPerTick

	if SERVER then
		self:NextThink(nextThink)
	else
		self:SetNextClientThink(nextThink)
	end

	return true
end