-- Credit goes to Corvatile: https://steamcommunity.com/sharedfiles/filedetails/?id=3041239513
-- This is mostly the discombob thrown entity code as well, from base TTT
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Model = Model("models/weapons/w_grenade.mdl")
--this is newv
ENT.WorldMaterial = 'clutterbomb/models/items/w_grenadesheet_proj'
--this is new^
ENT.GrenadeLight = Material("sprites/light_glow02_add")
ENT.GrenadeColor = Color(255, 111, 0)
--new thing for grenade sprite
AccessorFunc(ENT, "radius", "Radius", FORCE_NUMBER)
AccessorFunc(ENT, "dmg", "Dmg", FORCE_NUMBER)

local barrelCountCvar = CreateConVar("pap_barrel_bomb_count", 12, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "No. of spawned barrels", 1, 20)

function ENT:Initialize()
	--new code for custom skin
	self:SetModel("models/weapons/w_grenade.mdl")
	self:SetSubMaterial(0, self.WorldMaterial)
	self:EmitSound("weapons/slam/throw.wav", SNDLVL_100dB)
	self:SetPAPCamo()

	--code for sprite trail
	if SERVER then
		util.SpriteTrail(self, 0, Color(255, 111, 0), false, 25, 1, 4, 1 / (15 + 1) * 0.5, "trails/laser.vmt")
	end

	if not self:GetRadius() then
		self:SetRadius(250)
	end

	if not self:GetDmg() then
		self:SetDmg(0)
	end

	return self.BaseClass.Initialize(self)
end

function ENT:Draw()
	self:DrawModel()
	render.SetMaterial(self.GrenadeLight)
	render.DrawSprite(self:GetUp() * 4.5 + self:GetPos(), 12.5, 12.5, self.GrenadeColor)
end

hook.Add("PreRender", "BarrelbombProj_DynamicLight", function()
	for k, v in pairs(ents.FindByClass("ttt_barrel_bomb_proj")) do
		local dlight = DynamicLight(v:EntIndex())

		if dlight then
			dlight.pos = v:GetPos()
			dlight.r = 255
			dlight.g = 111
			dlight.b = 0
			dlight.brightness = 4
			dlight.Decay = 258
			dlight.Size = 258
			dlight.DieTime = CurTime() + 0.1
			dlight.Style = 4
		end
	end
end)

local vectors = {-1, 1}

function ENT:Explode(tr)
	if SERVER then
		self:SetNoDraw(true)
		self:SetSolid(SOLID_NONE)

		if tr.Fraction ~= 1.0 then
			self:SetPos(tr.HitPos + tr.HitNormal * 0.6)
		end

		local pos = self:GetPos()
		util.ScreenShake(pos, 40, 70, 0.5, 250)
		local soundNumber = math.random(2)
		self:EmitSound(Sound("physics/wood/wood_furniture_break" .. soundNumber .. ".wav"), SNDLVL_150dB)
		local effect = EffectData()
		effect:SetOrigin(self:GetPos() + Vector(0, 0, 10))
		effect:SetStart(self:GetPos() + Vector(0, 0, 10))
		util.Effect("striderbuster_attach_ring", effect, true, true)
		---spawns exploding barrels
		self:EmitSound("ambient/alarms/klaxon1.wav", SNDLVL_180dB)
		self:EmitSound("ambient/alarms/klaxon1.wav", SNDLVL_180dB)

		for i = 1, barrelCountCvar:GetInt() do
			local prop = ents.Create("prop_physics")
			prop:SetModel("models/props_c17/oildrum001_explosive.mdl")
			prop:SetPos(self:LocalToWorld(self:OBBCenter()) + Vector(math.random(-35, 35), math.random(-35, 35), math.random(25, 50)))
			prop:Spawn()
			local phys = prop:GetPhysicsObject()
			if not IsValid(phys) then return end
			phys:AddAngleVelocity(VectorRand() * phys:GetMass() * 0.5)
			phys:ApplyForceCenter((Vector(vectors[math.random(#vectors)], vectors[math.random(#vectors)], 0) * 0.5) * phys:GetMass() * 0.5)
		end

		local explode = ents.Create("env_physexplosion") -- creates the explosion
		explode:SetPos(self:GetPos())
		-- this creates the explosion through your self.Owner:GetEyeTrace, which is why I put eyetrace in front
		explode:SetOwner(self.Owner) -- this sets you as the person who made the explosion
		explode:Spawn() --this actually spawns the explosion
		explode:SetKeyValue("iMagnitude", "15") -- the magnitude
		explode:Fire("Explode", 0, 0)
		self:Remove()
	end
end

--collision sounds code
function ENT:PhysicsCollide(colData, collider)
	if colData.Speed > 300 then
		local soundNumber = math.random(5)
		local volumeCalc = math.min(1, colData.Speed / 500)
		self:EmitSound(Sound("physics/wood/wood_crate_impact_hard" .. soundNumber .. ".wav"), 75, 100, volumeCalc)
	end
end