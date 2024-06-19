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
	self:EmitSound(Sound("weapons/flashbang/flashbang_explode" .. math.random(2) .. ".wav"))

	for _, ply in ipairs(ents.FindInSphere(self:GetPos(), 300)) do
		if not IsValid(ply) or not ply:IsPlayer() then continue end
		net.Start("TTTPAPBlindingGrenade")
		net.Send(ply)
	end

	self:Remove()
end

if CLIENT then
	local function EndBlindness(client)
		hook.Remove("PreDrawHalos", "TTTPAPBlindingGrenade")
		timer.Remove("TTTPAPBlindingGrenadeEnd")
		hook.Remove("Think", "TTTPAPBlindingGrenade")
		hook.Remove("TTTPrepareRound", "TTTPAPBlindingGrenade")
		client:ScreenFade(SCREENFADE.PURGE, COLOR_BLACK, 0, 0)
		client:ScreenFade(SCREENFADE.IN, COLOR_BLACK, 3, 0)
	end

	net.Receive("TTTPAPBlindingGrenade", function()
		local client = LocalPlayer()
		local durationCvar = GetConVar("pap_blinding_grenade_seconds_duration")
		client:ScreenFade(SCREENFADE.OUT, COLOR_BLACK, 0.5, 10000)
		chat.AddText("Upgraded flashbang! Your vision will return in " .. durationCvar:GetInt() .. " seconds!")

		hook.Add("PreDrawHalos", "TTTPAPBlindingGrenade", function()
			local plys = {}

			for _, ply in ipairs(player.GetAll()) do
				if ply:Alive() and not ply:IsSpec() then
					table.insert(plys, ply)
				end
			end

			halo.Add(plys, COLOR_WHITE, 1, 1, 1, true, true)
		end)

		timer.Create("TTTPAPBlindingGrenadeEnd", durationCvar:GetInt(), 1, function()
			EndBlindness(client)
		end)

		hook.Add("Think", "TTTPAPBlindingGrenade", function()
			if not client:Alive() or client:IsSpec() then
				EndBlindness(client)
			end
		end)

		hook.Add("TTTPrepareRound", "TTTPAPBlindingGrenade", function()
			EndBlindness(client)
		end)
	end)
end