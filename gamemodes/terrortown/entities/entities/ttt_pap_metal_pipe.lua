AddCSLuaFile()
ENT.Type = "anim"
ENT.PrintName = "Metal Pipe"
ENT.Base = "thw_ent"

function ENT:Initialize()
	self:SetModel("models/props_pipes/destroyedpipes01d.mdl")
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	local phys = self:GetPhysicsObject()

	if phys:IsValid() then
		phys:Wake()
	end

	if SERVER then
		self:SetTrigger(true)
		local ang = self:GetAngles()
		ang:RotateAroundAxis(ang:Up(), -90)
		self:SetAngles(ang)

		timer.Simple(8, function()
			if IsValid(self) then
				self:Remove()
			end
		end)
	end
end

function ENT:StartTouch(ent)
	if IsValid(ent) then
		ent:TakeDamage(10000, self.PAPOwner or self, self)
		self:EmitSound("ttt_pack_a_punch/metal_pipe/metal_pipe.mp3")
	end
end