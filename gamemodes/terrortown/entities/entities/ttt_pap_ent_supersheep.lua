AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_supersheep"

function ENT:Explode()
	if self.CollideCount ~= 0 then return end
	self.CollideCount = 1
	self:SetNWBool("exploded", true)
	self:SetNoDraw(true)
	if CLIENT then return end
	local explode = ents.Create("env_explosion") -- creates the explosion
	explode:SetPos(self:GetPos())
	explode:SetOwner(self.Owner) -- this sets you as the person who made the explosion
	explode:SetKeyValue("spawnflags", 129) --Setting the key values of the explosion
	explode:SetKeyValue("iMagnitude", "280") -- the magnitude
	explode:SetKeyValue("iRadiusOverride", "250")
	explode:Spawn() --this actually spawns the explosion
	explode:Fire("explode", "", 0)
	explode:EmitSound("weapon_AWP.Single", 400, 400) --
	local interpolValue = math.min(CurTime() - self.MinifiedStart, 1)
	self.BigHitbox:Remove()

	if self.Minified then
		util.BlastDamage(self.CorrespondingWeapon, self.Owner, self:GetPos(), 50 * interpolValue + 220 * (1 - interpolValue), 100 * interpolValue + 200 * (1 - interpolValue))
	else
		util.BlastDamage(self.CorrespondingWeapon, self.Owner, self:GetPos(), 220 * interpolValue + 50 * (1 - interpolValue), 200 * interpolValue + 100 * (1 - interpolValue))
	end

	for _, child in ipairs(self.PAPSheepChildren) do
		child:SetNoDraw(true)
	end

	for _, ent in ipairs(ents.FindInSphere(self:GetPos(), 200)) do
		-- Don't damage other supersheep, as this causes an infinite loop and crash...
		-- Only apply extra damage to players
		if IsValid(ent) and ent:IsPlayer() then
			local dmg = DamageInfo()
			dmg:SetDamageType(DMG_BLAST)
			dmg:SetDamage(1000)
			dmg:SetAttacker(self.Owner)
			dmg:SetInflictor(self)
			ent:TakeDamageInfo(dmg)
		end
	end

	-- Make some explosion effects and sound for the child sheep exploding
	for i = 1, 5 do
		local randomPos = self:GetPos() + VectorRand(-50, 50)

		timer.Simple(math.random(), function()
			local data = EffectData()
			data:SetOrigin(randomPos)
			util.Effect("HelicopterMegaBomb", data)
			sound.Play("BaseExplosionEffect.Sound", randomPos, 180, math.random(50, 150), math.random())
		end)
	end

	timer.Create("supersheep_explosion_delay", 1.5, 1, function()
		if IsValid(self) and IsValid(self.Owner) and IsValid(self.Owner:GetActiveWeapon()) then
			self.Owner:SetNWBool("supersheep_removed", true)
			self.Owner:GetActiveWeapon():Remove()
			self:Remove()
		end
	end)

	timer.Simple(1.6, function()
		if IsValid(self) then
			self:Remove()
		end
	end)
end