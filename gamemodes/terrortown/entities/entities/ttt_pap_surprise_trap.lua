AddCSLuaFile()
--[[Made by Slim Jim and PtGaming]]
-- I wouldn't touch anything below unless you know what you're doing.
ENT.Icon = "vgui/ttt/icon_shocktrap.png"
ENT.Type = "anim"
ENT.Projectile = true
ENT.CanHavePrints = true
ENT.TriggerSound = Sound("npc/assassin/ball_zap1.wav")
ENT.Model = Model("models/props_phx/gears/bevel12.mdl")

function ENT:Initialize()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetHealth(25) -- Trap Health

	return self.BaseClass.Initialize(self)
end

function ENT:ZipZap(v)
	if SERVER then
		local pos = self.Entity:GetPos()
		self:EmitSound(self.TriggerSound, 500)
		if not self:IsValid() then return end

		if v:IsValid() then
			local vragdoll = ents.Create("prop_ragdoll")
			vragdoll:SetPos(v:GetPos())
			local velocity = v:GetVelocity()
			vragdoll:SetAngles(v:GetAngles())
			vragdoll:SetModel(v:GetModel())
			vragdoll:Spawn()
			local j = 1

			while true do
				local phys_obj = vragdoll:GetPhysicsObjectNum(j)

				if phys_obj then
					phys_obj:SetVelocity(velocity)
					j = j + 1
				else
					break
				end
			end

			local vweapons = v:GetWeapons()
			local curhealth = v:Health()
			local curammo = v:GetActiveWeapon():Clip1()
			local curwep = v:GetActiveWeapon():GetClass()
			respawnweapons = {}

			for a, b in pairs(vweapons) do
				table.insert(respawnweapons, #respawnweapons, b:GetClass())
			end

			v:Spectate(OBS_MODE_CHASE)
			v:SpectateEntity(vragdoll)
			v:StripWeapons()

			-- Change timer length here if you want the victim to be ragdolled for a different amount of time.
			timer.Simple(8, function()
				local pos1 = vragdoll:GetPos()

				if IsValid(v) then
					v:UnSpectate()
					v:Spawn()
					v:SetHealth(curhealth - 20)
				end

				for a, b in pairs(respawnweapons) do
					if not v:HasWeapon(b) then
						v:Give(b)

						if b == curwep then
							v:GetWeapon(curwep):SetClip1(curammo)
						end
					end
				end

				pos1.z = pos1.z + 10
				v:SetPos(pos1)
				vragdoll:Remove()

				if v:Health() <= 0 then
					v:Kill()
				end

				oldspeed = v:GetWalkSpeed()
				v:SetWalkSpeed(oldspeed * 0.45)

				-- Change timer length here if you want the victim to be slowed for a different amount of time.
				timer.Simple(8, function()
					v:SetWalkSpeed(oldspeed)
				end)
			end)
		end

		self:Remove()
	end
end

ENT.touched = false

if SERVER then
	util.AddNetworkString("TTTPAPSurpriseTrapPopup")
end

function ENT:StartTouch(ply)
	if self.touched then return end

	if ply:IsValid() and ply:IsPlayer() then
		self.touched = true
		self:ZipZap(ply)
		ply:EmitSound("ttt_pack_a_punch/surprise_trap/surprise.mp3")

		-- If a yogs playermodel is installed, popup is a yogs-specific reference
		local yogsModels = {"models/bradyjharty/yogscast/lankychu.mdl", "models/bradyjharty/yogscast/breeh.mdl", "models/bradyjharty/yogscast/breeh2.mdl", "models/bradyjharty/yogscast/lewis.mdl", "models/bradyjharty/yogscast/sharky.mdl"}

		local yogsModelInstalled = false

		for _, model in ipairs(yogsModels) do
			if util.IsValidModel(model) then
				yogsModelInstalled = true
				break
			end
		end

		net.Start("TTTPAPSurpriseTrapPopup")
		net.WriteBool(yogsModelInstalled)
		net.Send(ply)
	end
end

if CLIENT then
	net.Receive("TTTPAPSurpriseTrapPopup", function()
		local yogsModelInstalled = net.ReadBool()
		local mat

		if yogsModelInstalled then
			mat = Material("ttt_pack_a_punch/surprise_trap/surprise_lewis.png")
		else
			mat = Material("ttt_pack_a_punch/surprise_trap/surprise.png")
		end

		local x = ScrW() / 2 - 256
		local y = ScrH() / 2 - 256

		hook.Add("PostDrawHUD", "TTTPAPSurpriseTrapPopup", function()
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(mat)
			surface.DrawTexturedRect(x, y, 512, 512)
		end)

		timer.Simple(1, function()
			hook.Remove("PostDrawHUD", "TTTPAPSurpriseTrapPopup")
		end)
	end)
end

if SERVER then
	local zapsound = Sound("npc/assassin/ball_zap1.wav")

	function ENT:OnTakeDamage(dmginfo)
		if dmginfo:GetAttacker() == self:GetOwner() then return end
		self:TakePhysicsDamage(dmginfo)
		self:SetHealth(self:Health() - dmginfo:GetDamage())

		if self:Health() <= 0 then
			self:Remove()
			local effect = EffectData()
			effect:SetOrigin(self:GetPos())
			util.Effect("cball_explode", effect)
			sound.Play(zapsound, self:GetPos())
		end
	end
end