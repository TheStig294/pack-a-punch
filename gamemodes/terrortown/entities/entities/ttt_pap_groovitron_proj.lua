AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Model = Model("models/ttt_pack_a_punch/disco_ball/disco_ball.mdl")

ENT.DurationCvar = CreateConVar("pap_groovitron_duration", 10, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds the groovitron lasts", 1, 30)

ENT.RadiusCvar = CreateConVar("pap_groovitron_radius", 500, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Radius of area of effect", 1, 2000)

AccessorFunc(ENT, "radius", "Radius", FORCE_NUMBER)

function ENT:Initialize()
	self:EmitSound("weapons/slam/throw.wav", SNDLVL_100dB)
	self:SetModel(self.Model)
	-- The model has the wrong scale so we just fix it here, units in blender is a pain...
	self:SetModelScale(10, 0.00001)
	self.Collided = false

	return self.BaseClass.Initialize(self)
end

-- Unused, just here to keep the ttt_basegrenade_proj happy
function ENT:Explode(tr)
end

function ENT:PhysicsCollide()
	if self.Collided then return end
	self.Collided = true
	-- Set the disco ball to face upright and make a "tink" sound
	self:SetAngles(Angle(0, 0, 0))
	self:EmitSound("Flashbang.Bounce")

	-- Work-around to stop the console yelling at us for changing how the entity collides with things, within a hook called by the entity colliding with something
	-- (Kinda like calling a damage function in a take damage hook, but we're disabling the physics altogether here, so PhysicsCollide can't be called again and cause an infinite loop, so we're fine)
	-- Making the disco ball not have collisions with anything
	timer.Simple(0, function()
		self:SetMoveType(MOVETYPE_NONE)
	end)

	-- Create some different coloured spotlights because, y'know, it's a disco ball
	local initialPos = self:GetPos()
	self.SpotlightEntities = {}

	-- Angle, colour
	local spotlightValues = {
		{0, "255 0 0"},
		{90, "0 255 0"},
		{180, "0 0 255"},
		{270, "255 255 255"}
	}

	-- Source comes with these handy-dandy beam_spotlight entities which are PERFECT for what we want (That even rotate themselves!)
	-- There might be a disco ball somewhere in the Half-Life games... maybe, I've never played them
	for _, lightValues in ipairs(spotlightValues) do
		local spotlight = ents.Create("beam_spotlight")
		spotlight:SetPos(initialPos)
		spotlight:SetAngles(Angle(45, lightValues[1], 0))
		spotlight:Spawn()
		spotlight:Fire("LightOn")
		spotlight:Fire("Start")
		spotlight:Fire("Color", lightValues[2])
		table.insert(self.SpotlightEntities, spotlight)
	end

	-- Make the disco ball rise up from where it landed
	local finalPos = self:GetPos()
	finalPos.z = finalPos.z + 120
	local riseTimer = "TTTPAPGroovitronRise" .. self:EntIndex()

	timer.Create(riseTimer, 0.01, 100, function()
		if not IsValid(self) then
			timer.Remove(riseTimer)

			return
		end

		local animationProgressPercent = (100 - timer.RepsLeft(riseTimer)) / 100
		local pos = LerpVector(animationProgressPercent, initialPos, finalPos)
		self:SetPos(pos)

		for _, spotlight in ipairs(self.SpotlightEntities) do
			if IsValid(spotlight) then
				spotlight:SetPos(pos)
			end
		end
	end)

	-- Make the disco ball rotate
	local rotateTimer = "TTTPAPGroovitronRotate" .. self:EntIndex()

	timer.Create(rotateTimer, 0.01, 0, function()
		if not IsValid(self) then
			timer.Remove(rotateTimer)

			return
		end

		local angles = self:GetAngles()
		angles.y = angles.y + 1
		self:SetAngles(angles)
	end)

	-- Remove the disco ball once time is up (Even if it hasn't finished rising up yet)
	timer.Simple(self.DurationCvar:GetInt(), function()
		if not IsValid(self) then return end

		for _, spotlight in ipairs(self.SpotlightEntities) do
			if IsValid(spotlight) then
				spotlight:Remove()
			end
		end

		if IsValid(self) then
			self:Remove()
		end
	end)
end