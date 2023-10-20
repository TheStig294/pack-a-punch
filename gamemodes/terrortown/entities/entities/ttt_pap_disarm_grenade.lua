AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Model = Model("models/weapons/w_grenade.mdl")
--this is newv
ENT.WorldMaterial = 'zapgrenade/models/items/w_grenadesheet_proj'
--this is new^
ENT.GrenadeLight = Material("sprites/light_glow02_add")
ENT.GrenadeColor = Color(173, 255, 236)
--new thing for grenade sprite
AccessorFunc(ENT, "radius", "Radius", FORCE_NUMBER)
AccessorFunc(ENT, "dmg", "Dmg", FORCE_NUMBER)

function ENT:Initialize()
	--new code for custom skin
	self:SetModel("models/weapons/w_grenade.mdl")
	self:SetSubMaterial(0, self.WorldMaterial)
	self:EmitSound("weapons/slam/throw.wav", SNDLVL_100dB)

	--code for sprite trail
	if SERVER then
		util.SpriteTrail(self, 0, Color(173, 255, 236), false, 25, 1, 4, 1 / (15 + 1) * 0.5, "trails/laser.vmt")
	end

	--old sprite trail util.SpriteTrail(self, 0, self.GrenadeColor, false, 1.25, 0, 0.35, 1/1.25 * 0.5, "trails/laser.vmt")
	--
	if not self:GetRadius() then
		self:SetRadius(250)
	end

	if not self:GetDmg() then
		self:SetDmg(6)
	end

	self:SetMaterial(TTTPAP.camo)

	return self.BaseClass.Initialize(self)
end

function ENT:Draw()
	self:DrawModel()
	render.SetMaterial(self.GrenadeLight)
	render.DrawSprite(self:GetUp() * 4.5 + self:GetPos(), 12.5, 12.5, self.GrenadeColor)
end

hook.Add("PreRender", "ZapGrenProj_DynamicLight", function()
	for k, v in pairs(ents.FindByClass("ttt_zapgren_proj")) do
		local dlight = DynamicLight(v:EntIndex())

		if dlight then
			dlight.pos = v:GetPos()
			dlight.r = 173
			dlight.g = 255
			dlight.b = 236
			dlight.brightness = 5
			dlight.Decay = 384
			dlight.Size = 128
			dlight.DieTime = CurTime() + 0.1
			dlight.Style = 6
		end
	end
end)

local disarmTimeCvar = CreateConVar("pap_disarm_grenade_time", 10, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Secs players are disarmed", 1, 20)

local undroppableRemoveCvar = CreateConVar("pap_disarm_grenade_undroppable_remove", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Remove undroppable weapons?", 0, 1)

function ENT:Explode(tr)
	if CLIENT then return end
	self:SetNoDraw(true)
	self:SetSolid(SOLID_NONE)

	if tr.Fraction ~= 1.0 then
		self:SetPos(tr.HitPos + tr.HitNormal * 0.6)
	end

	local pos = self:GetPos()
	local effectdata = EffectData()
	effectdata:SetOrigin(self:GetPos())
	util.Effect("StunstickImpact", effectdata)
	util.Effect("TeslaZap", effectdata)

	local shockPlayerSounds = {"vo/ravenholm/monk_pain04.wav", "vo/ravenholm/monk_pain06.wav", "vo/ravenholm/monk_pain09.wav", "vo/ravenholm/monk_pain12.wav"}

	util.ScreenShake(pos, 60, 90, 0.7, 150)
	local removeUndroppable = undroppableRemoveCvar:GetBool()

	for _, ply in pairs(ents.FindInSphere(self:GetPos(), 150)) do
		if IsValid(ply) and ply:IsPlayer() then
			local playerteslaedata = EffectData()
			playerteslaedata:SetEntity(ply)
			playerteslaedata:SetMagnitude(3)
			playerteslaedata:SetScale(2)
			playerteslaedata:SetOrigin(self:GetPos())
			util.Effect("TeslaHitBoxes", playerteslaedata)
			ply:EmitSound("npc/scanner/scanner_electric2.wav")
			local randomshockPlayerSound = shockPlayerSounds[math.random(1, #shockPlayerSounds)]
			ply:EmitSound(randomshockPlayerSound)
			local d = DamageInfo()
			d:SetDamage(1)
			d:SetAttacker(self:GetOwner())
			d:SetDamageType(DMG_SHOCK)
			ply:TakeDamageInfo(d)
			ply.PAPDisarmGrenade = true
			local disarmTime = disarmTimeCvar:GetInt()
			ply:ChatPrint("You've been disarmed for " .. disarmTime .. " seconds!")

			timer.Simple(disarmTime, function()
				ply.PAPDisarmGrenade = false
			end)

			if ply:Alive() and not ply:IsSpec() then
				for _, wep in ipairs(ply:GetWeapons()) do
					if wep.AllowDrop or removeUndroppable then
						ply:DropWeapon(wep)
					end
				end
			end

			local timername = "TTTPAPDisarmGrenade" .. ply:SteamID64()

			timer.Create("TTTPAPDisarmGrenade", 0.15, 4, function()
				if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then
					timer.Remove(timername)

					return
				end

				util.Effect("TeslaHitBoxes", playerteslaedata)
				ply:TakeDamageInfo(d)
			end)
		end

		self:EmitSound("ambient/levels/labs/electric_explosion3.wav", SNDLVL_180dB)
		self:Remove()
	end
end

--collision sounds code
function ENT:PhysicsCollide(colData, collider)
	if colData.Speed > 300 then
		local soundNumber = math.random(3)
		local volumeCalc = math.min(1, colData.Speed / 500)
		self:EmitSound(Sound("physics/metal/metal_canister_impact_soft" .. soundNumber .. ".wav"), 75, 100, volumeCalc)
	end
end