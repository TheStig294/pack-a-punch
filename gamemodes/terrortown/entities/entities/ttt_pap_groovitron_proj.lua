AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Model = Model("models/ttt_pack_a_punch/disco_ball/disco_ball.mdl")

ENT.DurationCvar = CreateConVar("pap_groovitron_duration", 10, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds the groovitron lasts", 1, 30)

ENT.RadiusCvar = CreateConVar("pap_groovitron_radius", 300, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Radius of area of effect", 1, 2000)

function ENT:Initialize()
	self:EmitSound("weapons/slam/throw.wav", SNDLVL_100dB)
	self:SetModel(self.Model)
	-- The model has the wrong scale so we just fix it here, units in blender is a pain...
	self:SetModelScale(10, 0.00001)

	-- Hooks used for forcing players into thirdperson view
	hook.Add("CalcView", "TTTPAPGroovitronThirdPerson", function(ply, pos, angles, fov, znear, zfar)
		if not ply:GetNWBool("TTTPAPGroovitronThirdPerson") then return end

		local view = {
			origin = pos - (angles:Forward() * 100),
			angles = angles,
			fov = fov,
			drawviewer = true,
			znear = znear,
			zfar = zfar
		}

		return view
	end)

	hook.Add("PostPlayerDeath", "TTTPAPGroovitronResetThirdPerson", function(ply)
		ply:Freeze(false)
		ply:SetNWBool("TTTPAPGroovitronThirdPerson", false)
	end)

	-- Remove thirdperson hooks at round end
	hook.Add("TTTPrepareRound", "TTTPAPGroovitronReset", function()
		hook.Remove("CalcView", "TTTPAPGroovitronThirdPerson")
		hook.Remove("PostPlayerDeath", "TTTPAPGroovitronResetThirdPerson")
		hook.Remove("TTTPrepareRound", "TTTPAPGroovitronReset")
	end)

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
	self.MusicName = "ttt_pack_a_punch/groovitron/" .. math.random(3) .. ".mp3"
	self:EmitSound(self.MusicName)
	self:EmitSound(self.MusicName)

	-- Work-around to stop the console yelling at us for changing how the entity collides with things, within a hook called by the entity colliding with something
	-- (Kinda like calling a damage function in a take damage hook, but we're disabling the physics altogether here, so PhysicsCollide can't be called again and cause an infinite loop, so we're fine)
	-- Making the disco ball not have collisions with anything
	timer.Simple(0, function()
		self:SetMoveType(MOVETYPE_NONE)
	end)

	-- Create some different coloured spotlights because, y'know, it's a disco ball
	local initialPos = self:GetPos()
	local spotlightEntities = {}

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
		table.insert(spotlightEntities, spotlight)
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

		for _, spotlight in ipairs(spotlightEntities) do
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

	-- Make the disco ball force everyone nearby to dance
	local danceTimer = "TTTPAPGroovitronDance" .. self:EntIndex()
	local dancingPlayers = {}

	timer.Create(danceTimer, 1, 0, function()
		-- If the disco ball has been removed, then free all dancing players
		if not IsValid(self) then
			timer.Remove(danceTimer)

			for ply, _ in pairs(dancingPlayers) do
				if IsValid(ply) then
					ply:Freeze(false)
					ply:SetNWBool("TTTPAPGroovitronThirdPerson", false)
					ply:DoAnimationEvent(ACT_RESET, 0)
				end
			end

			return
		end

		-- Search for nearby players (Skip the thrower!)
		for _, ply in ipairs(ents.FindInSphere(self:GetPos(), self.RadiusCvar:GetInt())) do
			if not IsValid(ply) or not ply:IsPlayer() or ply == self:GetThrower() or not ply:Alive() or ply:IsSpec() then continue end

			-- Freeze the player and set them to thirdperson
			if not ply:IsFrozen() then
				ply:Freeze(true)
				ply:SetNWBool("TTTPAPGroovitronThirdPerson", true)
				dancingPlayers[ply] = true
			end

			-- Randomly set a dance animation to play
			if math.random() < 0.5 then
				ply:DoAnimationEvent(ACT_GMOD_GESTURE_TAUNT_ZOMBIE, 1641)
			else
				ply:DoAnimationEvent(ACT_GMOD_TAUNT_DANCE, 1642)
			end
		end
	end)

	-- Remove the disco ball once time is up, and replace it with a harmless explosion
	timer.Simple(self.DurationCvar:GetInt(), function()
		for _, spotlight in ipairs(spotlightEntities) do
			if IsValid(spotlight) then
				spotlight:Remove()
			end
		end

		if IsValid(self) then
			local data = EffectData()
			data:SetOrigin(self:GetPos())
			util.Effect("HelicopterMegaBomb", data)
			self:EmitSound("BaseExplosionEffect.Sound")
			self:Remove()
		end
	end)
end

-- If the disco ball is removed at all, stop the music
function ENT:OnRemove()
	if self.MusicName then
		self:StopSound(self.MusicName)
		self:StopSound(self.MusicName)
	end
end