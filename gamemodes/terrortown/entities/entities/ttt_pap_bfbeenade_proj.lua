AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_beenade_proj"
AccessorFunc(ENT, "radius", "Radius", FORCE_NUMBER)
AccessorFunc(ENT, "dmg", "Dmg", FORCE_NUMBER)

function ENT:Initialize()
	self:SetModel("models/lucian/props/stupid_bee.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

	if SERVER then
		self:SetExplodeTime(0)
	end

	if not self:GetRadius() then
		self:SetRadius(256)
	end

	if not self:GetDmg() then
		self:SetDmg(0)
	end

	local phys = self:GetPhysicsObject()

	if phys:IsValid() then
		phys:SetMass(350)
	end

	self:SetPAPCamo()
	self:SetModelScale(5, 0.0001)
end

function ENT:Explode(tr)
	if SERVER then
		if GetConVar("beerandom"):GetInt() == 0 then
			Beecounter = GetConVar("beecount"):GetInt()
		else
			Beecounter = math.random(GetConVar("beerandommin"):GetInt(), GetConVar("beerandommax"):GetInt())
		end

		self:SetNoDraw(true)
		self:SetSolid(SOLID_NONE)
		local pos = self:GetPos()
		sound.Play("NONOTTHEBEES.wav", pos, 100, 100)

		-- pull out of the surface
		if tr.Fraction ~= 1.0 then
			self:SetPos(tr.HitPos + tr.HitNormal * 0.6)
		end

		local effect = EffectData()
		effect:SetStart(pos)
		effect:SetOrigin(pos)
		effect:SetScale(self.ExplosionRadius * 0.3)
		effect:SetRadius(self.ExplosionRadius)
		effect:SetMagnitude(self.ExplosionDamage)

		if tr.Fraction ~= 1.0 then
			effect:SetNormal(tr.HitNormal)
		end

		util.Effect("Explosion", effect, true, true)
		util.BlastDamage(self, self:GetThrower(), pos, self.ExplosionRadius, self.ExplosionDamage)
		self:SetDetonateExact(0)

		for i = 1, Beecounter do
			local spos = pos + Vector(math.random(-75, 75), math.random(-75, 75), math.random(0, 50))
			local contents = util.PointContents(spos)
			local _i = 0

			while i < 10 and (contents == CONTENTS_SOLID or contents == CONTENTS_PLAYERCLIP) do
				_i = 1 + i
				spos = pos + Vector(math.random(-125, 125), math.random(-125, 125), math.random(-50, 50))
				contents = util.PointContents(spos)
			end

			local headBee = SpawnNPC(self:GetThrower(), spos, BeeNPCClass)
			headBee:SetNPCState(2)
			local Bee = ents.Create("prop_dynamic")
			Bee:SetModel("models/lucian/props/stupid_bee.mdl")
			Bee:SetPos(spos)
			Bee:SetAngles(Angle(0, 0, 0))
			Bee:SetParent(headBee)
			Bee:SetModelScale(5, 0.0001)
			Bee:Activate()
			Bee:SetPAPCamo()
			-- Prevent the bees from being able to be picked up with a magneto stick,
			-- Since there's nothing you can do about it if the player is a jester killing you with it...
			-- (And in practice the stun + large invincible bee hitbox prevents you from shooting a player doing this anyway)
			-- 
			-- This is just a property the magneto stick looks for in SWEP:AllowPickup()
			Bee.CanPickup = false
			headBee:SetNWEntity("Thrower", self:GetThrower())
			headBee:SetNoDraw(true)
			headBee:SetHealth(1000)
			headBee:SetModelScale(5, 0.0001)
			headBee:Activate()
			headBee.CanPickup = false
			headBee.PAPBfbnade = true
		end

		self:Remove()
	else
		local spos = self:GetPos()

		local trs = util.TraceLine({
			start = spos + Vector(0, 0, 64),
			endpos = spos + Vector(0, 0, -128),
			filter = self
		})

		util.Decal("Scorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal)
		self:SetDetonateExact(0)
	end
end