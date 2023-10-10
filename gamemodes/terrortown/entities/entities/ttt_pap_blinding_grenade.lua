AddCSLuaFile()
ENT.Base = "ttt_thrownflashbang"
ENT.Type = "anim"

if SERVER then
	util.AddNetworkString("TTTPAPBlindingGrenade")
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self:SetMaterial(TTTPAP.camo)
end

function ENT:Explode()
	self:EmitSound(Sound("weapons/flashbang/flashbang_explode" .. math.random(1, 2) .. ".wav"))

	for _, ply in ipairs(ents.FindInSphere(self:GetPos(), 300)) do
		if not IsValid(ply) or not ply:IsPlayer() then continue end
		net.Start("TTTPAPBlindingGrenade")
		net.Send(ply)
	end

	self:Remove()
end

if CLIENT then
	net.Receive("TTTPAPBlindingGrenade", function()
		local client = LocalPlayer()
		client:ScreenFade(SCREENFADE.STAYOUT, COLOR_BLACK, 0, 0)

		hook.Add("Think", "TTTPAPBlindingGrenade", function()
			if not client:Alive() or client:IsSpec() then
				hook.Remove("Think", "TTTPAPBlindingGrenade")
				hook.Remove("PreDrawHalos", "TTTPAPBlindingGrenade")
				hook.Remove("TTTPrepareRound", "TTTPAPBlindingGrenade")
				client:ScreenFade(SCREENFADE.PURGE, COLOR_BLACK, 0, 0)
			end
		end)

		hook.Add("PreDrawHalos", "TTTPAPBlindingGrenade", function()
			local plys = {}

			for _, ply in ipairs(player.GetAll()) do
				if ply:Alive() and not ply:IsSpec() then
					table.insert(plys, ply)
				end
			end

			halo.Add(plys, COLOR_WHITE, 1, 1, 1, true, true)
		end)

		hook.Add("TTTPrepareRound", "TTTPAPBlindingGrenade", function()
			hook.Remove("Think", "TTTPAPBlindingGrenade")
			hook.Remove("PreDrawHalos", "TTTPAPBlindingGrenade")
			hook.Remove("TTTPrepareRound", "TTTPAPBlindingGrenade")
			client:ScreenFade(SCREENFADE.PURGE, COLOR_BLACK, 0, 0)
		end)
	end)
end