local UPGRADE = {}
UPGRADE.id = "potion_slow"
UPGRADE.class = "weapon_ttt_mc_poison"
UPGRADE.name = "Slowness Potion"
UPGRADE.desc = "Slows a player down permenantly!"

UPGRADE.convars = {
    {
        name = "pap_potion_slow_mult",
        type = "float",
        decimal = 1
    }
}

local multCvar = CreateConVar("pap_potion_slow_mult", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Slowness multiplier", 1, 10)

function UPGRADE:Apply(SWEP)
    timer.Simple(0.1, function()
        SWEP:SetClip1(-1)
    end)

    local DenySound = "minecraft_original/wood_click.wav"
    local DestroySound = "minecraft_original/glass2.wav"

    function SWEP:PrimaryAttack()
        if CLIENT then return end

        if self:GetOwner():IsPlayer() then
            self:GetOwner():LagCompensation(true)
        end

        local tr = util.TraceLine({
            start = self:GetOwner():GetShootPos(),
            endpos = self:GetOwner():GetShootPos() + self:GetOwner():GetAimVector() * 64,
            filter = self:GetOwner()
        })

        if self:GetOwner():IsPlayer() then
            self:GetOwner():LagCompensation(false)
        end

        local ent = tr.Entity
        self:DoSlow(ent, true)
    end

    function SWEP:DoSlow(ent, primary)
        local owner = self:GetOwner()

        if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC()) then
            ent:SetLaggedMovementValue(ent:GetLaggedMovementValue() / multCvar:GetFloat())
            self:Remove()
            ent:EmitSound(DestroySound)
        else
            owner:EmitSound(DenySound)

            if primary then
                self:SetNextPrimaryFire(CurTime() + 1)
            else
                self:SetNextSecondaryFire(CurTime() + 1)
            end
        end
    end

    function SWEP:SecondaryAttack()
        if CLIENT then return end
        local ent = self:GetOwner()
        self:DoSlow(ent)
    end

    if CLIENT then
        SWEP.PAPOldDrawWorldModel = SWEP.DrawWorldModel

        function SWEP:DrawWorldModel()
            SWEP:PAPOldDrawWorldModel()

            if IsValid(self.WorldModelEnt) then
                self.WorldModelEnt:SetMaterial(TTTPAP.camo)
            end
        end
    end
end

TTTPAP:Register(UPGRADE)