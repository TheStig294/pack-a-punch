AddCSLuaFile()
ENT.Base = "ttt_safekeeper_safe"
ENT.Type = "anim"

function ENT:Initialize()
	self:SetEndTime(CurTime() + GetConVar("ttt_safekeeper_move_cooldown"):GetInt())
	self:SetModel(self.SafeModel)

	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
	end

	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	-- Set the physics of the safe to still collide with everything but players, so the victim doesn't get stuck
	self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)

	if SERVER then
		self.BlockList = {}

		for blocked_id in string.gmatch(GetConVar("ttt_safekeeper_weapons_blocklist"):GetString(), "([^,]+)") do
			TableInsert(self.BlockList, blocked_id:Trim())
		end

		self:SetUseType(CONTINUOUS_USE)
	end
end

function ENT:Think()
	local victim = self.TTTPAPSafeTransformerVictim
	if not IsValid(victim) then return end
	local angles = victim:GetAngles()
	local pos = victim:GetPos()
	self:SetAngles(angles)
	self:SetPos(pos)
	-- Forcing the safe's think hook to run every frame to make the safe move smoothly
	self:NextThink(CurTime())

	if CLIENT then
		self:SetNextClientThink(CurTime())
	end
	-- Return true to apply the server and client NextThink calls

	return true
end

if SERVER then
	function ENT:Use(activator)
		if self:GetOpen() then return end
		if not IsPlayer(activator) or not activator:IsActive() then return end
		local placer = self:GetPlacer()
		if not IsPlayer(placer) then return end
		-- Don't let the player turned into a safe open themselves...
		local victim = self.TTTPAPSafeTransformerVictim

		if IsValid(victim) and activator == victim then
			victim:ClearQueuedMessage("TTTPAPsfkPickupSelf")
			victim:QueueMessage(MSG_PRINTCENTER, "You can't pick yourself up!", 3, "TTTPAPsfkPickupSelf")

			return
		end

		local curTime = CurTime()

		if activator == placer then
			if not GetConVar("ttt_safekeeper_move_safe"):GetBool() then return end
			if (self:GetEndTime() - curTime) > 0 then return end
			-- Make sure to re-upgrade the safe once picked up
			local SWEP = activator:Give("weapon_sfk_safeplacer")
			TTTPAP:ApplyUpgrade(SWEP, self.PAPUpgrade)
			self:SetPlacer(nil)
			self:Remove()

			return
		end

		-- If this is a new activator, start tracking how long they've been using it for
		local stealTarget = activator.TTTSafekeeperPickTarget

		if self ~= stealTarget then
			if GetConVar("ttt_safekeeper_warn_pick_start"):GetBool() then
				placer:ClearQueuedMessage("sfkSafePickStart")
				placer:QueueMessage(MSG_PRINTBOTH, "Your safe is being picked!", nil, "sfkSafePickStart")
				net.Start("TTT_SafekeeperPlaySound")
				net.WriteString("pick")
				net.Send(placer)
			end

			activator:SetProperty("TTTSafekeeperPickTarget", self, activator)
			activator:SetProperty("TTTSafekeeperPickStart", curTime, activator)
		end

		-- Keep track of the last time they used it so we can time it out
		activator.TTTSafekeeperLastPickTime = curTime
	end

	function ENT:OnRemove(...)
		local victim = self.TTTPAPSafeTransformerVictim

		if IsValid(victim) then
			victim:SetNoDraw(false)
		end

		local placer = self:GetPlacer()

		-- Re-upgrade the safe placer weapon if the safe keeper picks up the safe
		if IsPlayer(placer) then
			for _, wep in ipairs(placer:GetWeapons()) do
				if WEPS.GetClass(wep) == self.PAPUpgrade.class then
					TTTPAP:ApplyUpgrade(wep, self.PAPUpgrade)
				end
			end
		end

		return self.BaseClass.OnRemove(self, ...)
	end
end