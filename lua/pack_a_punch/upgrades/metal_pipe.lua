local UPGRADE = {}
UPGRADE.id = "metal_pipe"
UPGRADE.class = "thw_swep"
UPGRADE.name = "Metal Pipe"
UPGRADE.desc = "x2 ammo, shorter falling distance, turns into a metal pipe"
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    function SWEP:Deploy()
    end

    SWEP:StopSound("draw")
    SWEP.TTTPAPMetalPipeUses = 2

    function SWEP:PrimaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local ent = ents.Create("ttt_pap_metal_pipe")
        if not IsValid(ent) then return end
        local pos = owner:GetEyeTrace().HitPos
        pos:Add(Vector(0, 0, 200))
        ent:SetPos(pos)
        ent.PAPOwner = owner
        ent:Spawn()
        owner:EmitSound(TTTPAP.shootSound)
        -- Ammo is not working properly for this weapon for some reason, so we have to hack it in...
        self.TTTPAPMetalPipeUses = self.TTTPAPMetalPipeUses - 1

        if self.TTTPAPMetalPipeUses <= 0 then
            timer.Simple(0.1, function()
                self:Remove()
                owner:ConCommand("lastinv")
            end)
        end

        return self.BaseClass.PrimaryAttack(self)
    end
end

TTTPAP:Register(UPGRADE)