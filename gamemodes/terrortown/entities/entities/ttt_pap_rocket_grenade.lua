AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Model = Model("models/weapons/w_grenade.mdl")
--this is newv
ENT.WorldMaterial = 'liftgrenade/lift_grenade_w'
--this is new^
ENT.GrenadeLight = Material("sprites/light_glow02_add")
ENT.GrenadeColor = Color(0, 255, 0)
--new thing for grenade sprite
AccessorFunc(ENT, "radius", "Radius", FORCE_NUMBER)
AccessorFunc(ENT, "dmg", "Dmg", FORCE_NUMBER)

function ENT:Initialize()
	--new code for custom skin
	self:SetModel("models/weapons/w_grenade.mdl")
	self:SetSubMaterial(0, self.WorldMaterial)
	self:EmitSound("weapons/slam/throw.wav", SNDLVL_100dB)

	--code for sprite trail
	if SERVER then
		util.SpriteTrail(self, 0, Color(45, 255, 0), false, 25, 1, 4, 1 / (15 + 1) * 0.5, "trails/laser.vmt")
	end

	--old sprite trail util.SpriteTrail(self, 0, self.GrenadeColor, false, 1.25, 0, 0.35, 1/1.25 * 0.5, "trails/laser.vmt")
	--
	if not self:GetRadius() then
		self:SetRadius(300)
	end

	if not self:GetDmg() then
		self:SetDmg(200)
	end

	self:SetPAPCamo()

	return self.BaseClass.Initialize(self)
end

function ENT:Draw()
	self:DrawModel()
	render.SetMaterial(self.GrenadeLight)
	render.DrawSprite(self:GetUp() * 4.5 + self:GetPos(), 12.5, 12.5, self.GrenadeColor)
end

hook.Add("PreRender", "LiftGrenProj_DynamicLight", function()
	for k, v in pairs(ents.FindByClass("ttt_liftgren_proj")) do
		local dlight = DynamicLight(v:EntIndex())

		if dlight then
			dlight.pos = v:GetPos()
			dlight.r = 0
			dlight.g = 255
			dlight.b = 0
			dlight.brightness = 3
			dlight.Decay = 258
			dlight.Size = 90
			dlight.DieTime = CurTime() + 0.1
			dlight.Style = 0
		end
	end
end)

function ENT:Explode(tr)
	if SERVER then
		self:SetNoDraw(true)
		self:SetSolid(SOLID_NONE)

		if tr.Fraction ~= 1.0 then
			self:SetPos(tr.HitPos + tr.HitNormal * 0.6)
		end

		local pos = self:GetPos()
		local effect = EffectData()
		effect:SetStart(pos)
		effect:SetOrigin(pos)
		effect:SetScale(2)
		effect:SetRadius(2)
		effect:SetMagnitude(2)

		if tr.Fraction ~= 1.0 then
			effect:SetNormal(tr.HitNormal)
		end

		-- copied code:
		local gravityMult = 10

		for _, ent in pairs(ents.FindInSphere(self:GetPos(), 150)) do
			if IsValid(ent) and ent:GetClass() ~= "ttt_liftgren_proj" then
				if ent:IsPlayer() or ent:IsNPC() then
					if not ent:GetNWBool("beingLifted", false) then
						ent:SetNWBool("beingLifted", true)
						local backupgravity = ent:GetGravity()
						ent:SetGravity(-gravityMult)
						local entPos = ent:GetPos()
						entPos.z = entPos.z + 20
						ent:SetPos(entPos)
						ent:SetLocalVelocity(Vector(0, 0, gravityMult))

						timer.Simple(4.5, function()
							ent:SetGravity(backupgravity)
						end)

						timer.Simple(5, function()
							ent:SetNWBool("beingLifted", false)
						end)
					end
				elseif ent:GetClass() ~= "ttt_liftgren_proj" and IsValid(ent:GetPhysicsObject()) then
					if not ent:GetNWBool("beingLifted", false) then
						ent:SetNWBool("beingLifted", true)
						ent:GetPhysicsObject():EnableGravity(false)
						ent:GetPhysicsObject():SetVelocity(ent:GetVelocity() + Vector(0, 0, 2000))

						timer.Simple(4.5, function()
							if IsValid(ent) and IsValid(ent:GetPhysicsObject()) then
								ent:GetPhysicsObject():EnableGravity(true)
							end
						end)

						timer.Simple(5, function()
							if IsValid(ent) then
								ent:SetNWBool("beingLifted", false)
							end
						end)
					end
				end
			end
		end

		self:EmitSound("ambient/machines/thumper_hit.wav", SNDLVL_180dB)
		self:EmitSound("npc/vort/health_charge.wav", SNDLVL_140dB)
		sound.Play("thrusters/rocket00.wav", pos, 180, 100, 1)
		local effectdata = EffectData()
		effectdata:SetOrigin(self:GetPos())
		util.Effect("VortDispel", effectdata)
		self:Remove()
	end
end

--collision sounds code
function ENT:PhysicsCollide(colData, collider)
	if colData.Speed > 300 then
		local soundNumber = math.random(3)
		local volumeCalc = math.min(1, colData.Speed / 500)
		self:EmitSound(Sound("physics/metal/metal_grenade_impact_hard" .. soundNumber .. ".wav"), 75, 100, volumeCalc)
	end
end