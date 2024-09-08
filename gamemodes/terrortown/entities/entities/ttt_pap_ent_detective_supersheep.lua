AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_detective_supersheep"
ENT.PrintName = "Observer Sheep"
ENT.Pos = Vector(0, 0, 0)
ENT.ClosestPlayerDist = nil
ENT.ClosestPlayer = nil
ENT.DistancePerTick = 2
ENT.SecondsPerTick = 0.01
ENT.MarkedPlayers = {}

function ENT:PhysicsCollide(data, phys)
end

function ENT:OnTakeDamage(damage)
	if damage:GetDamage() <= 0 then return end
	self:SetHealth(self:Health() - damage:GetDamage())

	if (self:Health() <= 0) and SERVER then
		self:EmitSound("ttt_supersheep/sheep_sound.wav")
		self:Remove()
	end
end

function ENT:Think()
	local owner = self.Owner

	if not IsValid(owner) then
		if SERVER then
			self:Remove()
		end

		return
	end

	if CLIENT then return true end
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NOCLIP)
	self:SetSolid(SOLID_NONE)
	self.Pos = self:GetPos()
	self.ClosestPlayer = nil
	self.ClosestPlayerDist = nil

	for _, ply in player.Iterator() do
		-- Don't chase dead players, or players already marked
		if not self.MarkedPlayers[ply] and ply:Alive() and not ply:IsSpec() and ply ~= owner then
			local plyDist = self.Pos:DistToSqr(ply:GetPos())

			if not self.ClosestPlayerDist or self.ClosestPlayerDist > plyDist then
				self.ClosestPlayerDist = plyDist
				self.ClosestPlayer = ply
			end
		end
	end

	-- Don't chase anything if there is no closest player, or they are dead
	if IsValid(self.ClosestPlayer) and self.ClosestPlayer:Alive() and not self.ClosestPlayer:IsSpec() then
		-- 30 * 30 = 900 source units
		if self.ClosestPlayerDist < 900 then
			local dmg = DamageInfo()
			dmg:SetDamage(10)
			dmg:SetDamageType(DMG_VEHICLE)
			dmg:SetInflictor(self)
			dmg:SetAttacker(owner or self)
			self.ClosestPlayer:TakeDamageInfo(dmg)
			owner:EmitSound("weapons/crossbow/hitbod1.wav")
			self.ClosestPlayer:EmitSound("weapons/crossbow/hitbod1.wav")
			self:EmitSound("ttt_supersheep/sheep_sound.wav")
			self.ClosestPlayer:ChatPrint(owner:Nick() .. "'s upgraded observer sheep is now tracking your location through walls!")
			-- Mark close enough players and damage them a bit
			self.MarkedPlayers[self.ClosestPlayer] = true
			net.Start("TTTPAPObserverSheepSwarmMarkPlayer")
			net.WritePlayer(self.ClosestPlayer)
			net.Send(owner)
		else
			-- Else chase players down
			self:PointAtEntity(self.ClosestPlayer)
			local forward = self:GetForward()
			self.Pos:Add(forward * self.DistancePerTick)
			self:SetPos(self.Pos)
		end
	else
		-- Remove the sheep swarm once all players are tracked
		self:Remove()
	end

	local nextThink = CurTime() + self.SecondsPerTick

	if SERVER then
		self:NextThink(nextThink)
	else
		self:SetNextClientThink(nextThink)
	end

	return true
end