local speedCvar = CreateConVar("pap_banana_bus_speed", "1.5", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Speed the bus travels (units/tick)", 0.1, 5)

if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TTTPAPBananaBusOutline")
end

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "Banana Bus"
ENT.Pos = Vector(0, 0, 0)
ENT.ClosestPlayerDist = nil
ENT.ClosestPlayer = nil
ENT.DistancePerTick = 2
ENT.SecondsPerTick = 0.01

function ENT:PlayBananaBusSound()
	for i = 1, 2 do
		self:EmitSound("ttt_pack_a_punch/banana_bus/banana_bus.mp3")
	end
end

-- Set the prop to a bus, apply the PaP camo, and add a yellow trail
function ENT:Initialize()
	self.DistancePerTick = speedCvar:GetFloat()
	self:SetModel("models/ttt_pack_a_punch/bus/bus.mdl")
	self:SetPAPCamo()
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NOCLIP)
	self:SetSolid(SOLID_NONE)
	self:PlayBananaBusSound()

	if SERVER then
		util.SpriteTrail(self, 0, Color(255, 225, 53), false, 30, 1, 4, 2, "trails/plasma")
	end

	timer.Simple(2, function()
		if not IsValid(self) then return end

		-- Adding an outline around the bus for the thrower
		if SERVER and IsValid(self.PAPOwner) then
			net.Start("TTTPAPBananaBusOutline")
			net.WriteEntity(self)
			net.Send(self.PAPOwner)
		end
	end)
end

if CLIENT then
	local haloEntities = {}

	net.Receive("TTTPAPBananaBusOutline", function()
		local bus = net.ReadEntity()

		if table.IsEmpty(haloEntities) then
			hook.Add("PreDrawHalos", "TTTPAPBananaBusOutline", function()
				halo.Add(haloEntities, COLOR_WHITE, 1, 1, 2, true, true)
			end)

			hook.Add("TTTPrepareRound", "TTTPAPBananaBusOutlineReset", function()
				table.Empty(haloEntities)
				hook.Remove("PreDrawHalos", "TTTPAPBananaBusOutline")
				hook.Remove("TTTPrepareRound", "TTTPAPBananaBusOutlineReset")
			end)
		end

		table.insert(haloEntities, bus)
	end)
end

function ENT:Think()
	self.Pos = self:GetPos()
	self.ClosestPlayer = nil
	self.ClosestPlayerDist = nil

	for _, ply in player.Iterator() do
		-- Don't chase dead players or jesters
		if ply:Alive() and not ply:IsSpec() and not (ply.IsJesterTeam and ply:IsJesterTeam()) then
			local plyDist = self.Pos:DistToSqr(ply:GetPos())

			if not self.ClosestPlayerDist or self.ClosestPlayerDist > plyDist then
				self.ClosestPlayerDist = plyDist
				self.ClosestPlayer = ply
			end
		end
	end

	-- Don't chase anything if there is no closest player, or they are dead
	if SERVER and IsValid(self.ClosestPlayer) and self.ClosestPlayer:Alive() and not self.ClosestPlayer:IsSpec() then
		-- 30 * 30 = 900 source units
		if self.ClosestPlayerDist < 900 then
			-- Kill close enough players
			local dmg = DamageInfo()
			dmg:SetDamage(10000)
			dmg:SetDamageType(DMG_GENERIC)
			dmg:SetInflictor(self)
			dmg:SetAttacker(self.PAPOwner or self)
			self.ClosestPlayer:TakeDamageInfo(dmg)
			self:PlayBananaBusSound()
		else
			-- Else chase players down
			self:PointAtEntity(self.ClosestPlayer)
			local angles = self:GetAngles()
			angles.y = angles.y - 90
			self:SetAngles(angles)
			local forward = self:GetForward()
			forward:Rotate(Angle(0, 90, 0))
			self.Pos:Add(forward * self.DistancePerTick)
			self:SetPos(self.Pos)
		end
	end

	local nextThink = CurTime() + self.SecondsPerTick

	if SERVER then
		self:NextThink(nextThink)
	else
		self:SetNextClientThink(nextThink)
	end

	return true
end