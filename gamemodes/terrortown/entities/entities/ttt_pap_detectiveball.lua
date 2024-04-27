AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_detectiveball"

if SERVER then
	function ENT:PhysicsCollide(Data, PhysObj)
		local ent = Data.HitEntity
		local owner = self.PAPOwner

		if IsValid(ent) and ent:IsPlayer() then
			self:Infect(ent)

			if IsValid(owner) then
				owner:ChatPrint(ent:Nick() .. " will become a detective in 10 seconds!")
			end
		elseif IsValid(owner) then
			local UPGRADE = self.PAPUpgrade

			timer.Simple(1, function()
				if not IsValid(owner) then return end
				local SWEP = owner:Give("weapon_ttt_detectiveball")
				TTTPAP:ApplyUpgrade(SWEP, UPGRADE)
			end)
		end

		self:Remove()
	end
end

function ENT:Infect(ply)
	local detective_ids = {}

	for k, p in pairs(player.GetAll()) do
		if (p:IsRole(ROLE_DETECTIVE) or (p.IsDetectiveTeam and p:IsDetectiveTeam())) and p:Alive() then
			table.insert(detective_ids, p:EntIndex())
		end
	end

	if ply ~= nil and ply ~= NULL and ply ~= null and SERVER and ply:IsPlayer() and ply:IsValid() then
		if not timer.Exists("InfectionTimer" .. ply:GetName() .. "") then
			timer.Create("InfectionTimer" .. ply:GetName() .. "", math.random(DetectiveBallConfig.InfectTimeMin, DetectiveBallConfig.InfectTimeMax), 1, function()
				if ply:Alive() and table.Count(detective_ids) < 2 then
					if DetectiveBallConfig.PZ then
						local pos = ply:GetPos()
						ply:SetRole(ROLE_DETECTIVE)
						ply:AddCredits(1)
						ply:SetHealth(100)
						ply:SetPos(pos)
						ply:PrintMessage(HUD_PRINTCENTER, "You are a Detective and healthy!")
						SendFullStateUpdate()

						for k, p in pairs(player.GetAll()) do
							p:ChatPrint(ply:GetName() .. " is a Detective!")
						end
					end
				elseif ply:Alive() and table.Count(detective_ids) >= 2 then
					if DetectiveBallConfig.PZ then
						ply:SetHealth(100)
						ply:PrintMessage(HUD_PRINTTALK, "You are healed!")
					end
				end
			end)

			if DetectiveBallConfig.InfectMessage then
				if table.Count(detective_ids) < 2 then
					ply:PrintMessage(HUD_PRINTCENTER, "You will become a Detective and heal in 10 seconds!")
				else
					ply:PrintMessage(HUD_PRINTCENTER, "Too many Detectives. Only healing in 10 seconds!")

					for k, p in pairs(player.GetAll()) do
						if (p:GetRole() == ROLE_DETECTIVE or (p.IsDetectiveTeam and p:IsDetectiveTeam())) and self:GetOwner() then
							p:PrintMessage(HUD_PRINTCENTER, "Too many Detectives. Only healing in 10 seconds!")
						end
					end
				end
			end
		end

		if DetectiveBallConfig.ScreenTick and not timer.Exists("ShakeTimer" .. ply:GetName() .. "") then
			timer.Create("ShakeTimer" .. ply:GetName() .. "", DetectiveBallConfig.ScreenTickFreq, 0, function()
				ply:ViewPunch(Angle(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)))

				timer.Simple(10, function()
					timer.Remove("ShakeTimer" .. ply:GetName() .. "")
				end)
			end)
		end
	end
end