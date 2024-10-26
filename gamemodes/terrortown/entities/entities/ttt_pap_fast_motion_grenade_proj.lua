AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_timeslow_proj"
ENT.Model = Model("models/weapons/w_slowmo_grenade.mdl")
ENT.Icon = "vgui/ttt/icon_timeslow"

function ENT:Initialize()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
	self:SetPAPCamo()

	if SERVER then
		self:SetExplodeTime(0)
	end
end

local speedMultCvar = CreateConVar("pap_fast_motion_grenade_speed_mult", 2, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Game speed multiplier", 1, 4)

function ENT:Explode(tr)
	if SERVER then
		self:SetNoDraw(true)
		self:SetSolid(SOLID_NONE)

		-- pull out of the surface
		if tr.Fraction ~= 1.0 then
			self:SetPos(tr.HitPos + tr.HitNormal * 0.6)
		end

		local pos = self:GetPos()
		-- make sure we are removed, even if errors occur later
		self:Remove()
		local effect = EffectData()
		effect:SetStart(pos)
		effect:SetOrigin(pos)

		if tr.Fraction ~= 1.0 then
			effect:SetNormal(tr.HitNormal)
		end

		util.Effect("cball_explode", effect, true, true)
		SetSlowTime(true)
		game.SetTimeScale(speedMultCvar:GetFloat())
	else
		local spos = self:GetPos()

		local trs = util.TraceLine({
			start = spos + Vector(0, 0, 64),
			endpos = spos + Vector(0, 0, -128),
			filter = self
		})

		util.Decal("SmallScorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal)
		self:SetDetonateExact(0)
	end
end