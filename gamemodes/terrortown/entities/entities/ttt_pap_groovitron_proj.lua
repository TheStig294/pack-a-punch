AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Model = Model("models/ttt_pack_a_punch/disco_ball/disco_ball.mdl")
ENT.GrenadeLight = Material("sprites/light_glow02_add")
ENT.GrenadeColor = Color(255, 111, 0)
AccessorFunc(ENT, "radius", "Radius", FORCE_NUMBER)

local radiusCvar = CreateConVar("pap_groovitron_radius", 500, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Radius of area of effect", 1, 3000)

function ENT:Initialize()
	self:SetModel(self.Model)
	self:EmitSound("weapons/slam/throw.wav", SNDLVL_100dB)
	-- if SERVER then
	-- 	util.SpriteTrail(self, 0, Color(255, 111, 0), false, 25, 1, 4, 1 / (15 + 1) * 0.5, "trails/laser.vmt")
	-- end
	self:SetRadius(radiusCvar:GetInt())
	self:SetModelScale(10, 0.00001)
	self.Collided = false

	return self.BaseClass.Initialize(self)
end

-- function ENT:Draw()
-- 	local dlight = DynamicLight(self:EntIndex())
-- 	if dlight then
-- 		dlight.pos = self:GetPos()
-- 		dlight.r = 255
-- 		dlight.g = 111
-- 		dlight.b = 0
-- 		dlight.brightness = 4
-- 		dlight.Decay = 258
-- 		dlight.Size = 258
-- 		dlight.DieTime = CurTime() + 0.1
-- 		dlight.Style = 4
-- 	end
-- 	self:DrawModel()
-- 	render.SetMaterial(self.GrenadeLight)
-- 	render.DrawSprite(self:GetUp() * 4.5 + self:GetPos(), 12.5, 12.5, self.GrenadeColor)
-- end
function ENT:Explode(tr)
	if SERVER then
		self:Remove()
	end
end

function ENT:PhysicsCollide()
	if self.Collided then return end
	self.Collided = true
	self:EmitSound("Flashbang.Bounce")
	self:SetAngles(Angle(0, 0, 0))
	self:SetMoveType(MOVETYPE_NONE)
	local initialPos = self:GetPos()
	local finalPos = self:GetPos()
	finalPos.z = finalPos.z + 120
	local timername = "TTTPAPGroovitronRiseDiscoBall" .. self:EntIndex()

	timer.Create(timername, 0.01, 100, function()
		if not IsValid(self) then
			timer.Remove(timername)

			return
		end

		local animationProgressPercent = (100 - timer.RepsLeft(timername)) / 100
		local pos = LerpVector(animationProgressPercent, initialPos, finalPos)
		self:SetPos(pos)
	end)
end