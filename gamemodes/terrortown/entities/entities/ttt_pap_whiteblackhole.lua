AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_redblackhole"

if SERVER then
	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self:SetPAPCamo()
	end

	local screenFadeColour = Color(255, 255, 255, 20)

	function ENT:Think()
		if self.DieAt < CurTime() then
			self:Remove()

			return
		end

		local pos = self:GetPos()
		local valve_radius = self:GetRadius() * 18

		for _, ent in pairs(ents.FindInSphere(pos, valve_radius)) do
			local posdiff = -(ent:GetPos() - pos)
			local dist = posdiff:Length()
			posdiff:Normalize()

			if ent:IsPlayer() and ent:Alive() and not ent:IsSpec() and ent:GetRole() ~= ROLE_JESTER and ent:GetRole() ~= ROLE_SWAPPER and not (ent.IsJesterTeam and ent:IsJesterTeam()) then
				ent:TakeDamage(math.random(2), self:GetSpawner())
				self:IncrRadius(0.2)
				ent:EmitSound("ambient/energy/zap8.wav")
				ent:ScreenFade(SCREENFADE.IN, screenFadeColour, 0.1, 0.1)
				local force = -posdiff * ((valve_radius - dist) / 25) * 45
				ent:SetVelocity(force)
			end
		end

		self:NextThink(CurTime() + 0.1)

		return true
	end
end