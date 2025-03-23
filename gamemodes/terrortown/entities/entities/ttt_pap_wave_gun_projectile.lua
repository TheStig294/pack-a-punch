AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "obj_wgun_proj2"

if SERVER then
	util.AddNetworkString("TTTPAPWaveGunInflation")
end

local radiusCvar = CreateConVar("pap_wave_gun_radius", 200, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Radius of AOE shot", 1, 500)

function ENT:Explode(ent, pos, normal)
	self.BaseClass.Explode(self, ent, pos, normal)
	if CLIENT then return end
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	for _, ply in pairs(ents.FindInSphere(pos, radiusCvar:GetInt())) do
		if not IsValid(ply) or not ply:IsPlayer() then continue end
		if not ply:Alive() or ply:IsSpec() or ply == owner then continue end
		local dmg = DamageInfo()
		dmg:SetDamage(10000)
		dmg:SetAttacker(owner)
		dmg:SetDamageType(DMG_SONIC)
		ply:TakeDamageInfo(dmg)

		timer.Simple(0.1, function()
			local rag = ply.server_ragdoll or ply:GetRagdollEntity()
			local timername = "TTTPAPWaveGunInflation" .. ply:SteamID64()

			-- Set player ragdoll to fly off into the air
			for i = 0, rag:GetPhysicsObjectCount() - 1 do
				local phys = rag:GetPhysicsObjectNum(i)
				phys:EnableGravity(false)
				phys:SetVelocity(VectorRand(-16, 16))
			end

			-- Start expanding ragdoll bones,
			-- not done on the server because of lag caused by repeated calls to ent:ManipulateBoneScale()
			net.Start("TTTPAPWaveGunInflation")
			net.WriteString(timername)
			net.WriteEntity(rag)
			net.Broadcast()

			timer.Simple(5.1, function()
				if IsValid(rag) then
					rag:Remove()
				end
			end)
		end)
	end
end

if CLIENT then
	net.Receive("TTTPAPWaveGunInflation", function()
		local timername = net.ReadString()
		local rag = net.ReadEntity()
		rag.PAPWaveGunInflationScale = 1

		timer.Create(timername, 0.05, 100, function()
			-- Invalid ent, remove timer
			if not IsValid(rag) then
				timer.Remove(timername)

				return
			end

			-- If inflated, pop
			if timer.RepsLeft(timername) == 0 then
				ParticleEffectAttach("wgun_pop", PATTACH_ABSORIGIN_FOLLOW, rag, 1)
				rag:EmitSound("weapons/zapwavegun/microwave_ding.ogg", 100, math.random(90, 110))
				timer.Remove(timername)
			else
				-- Else, keep inflating
				rag.PAPWaveGunInflationScale = rag.PAPWaveGunInflationScale + 0.01

				for i = 0, rag:GetBoneCount() do
					rag:ManipulateBoneScale(i, Vector(rag.PAPWaveGunInflationScale, rag.PAPWaveGunInflationScale, rag.PAPWaveGunInflationScale))
				end
			end
		end)
	end)
end