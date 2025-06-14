local UPGRADE = {}
UPGRADE.id = "mega_barrel_transformer"
UPGRADE.class = "weapon_bam_transformer"
UPGRADE.name = "MEGA Barrel Transformer"
UPGRADE.desc = "Turn into a MASSIVE barrel!"

function UPGRADE:Apply(SWEP)
    self:AddToHook(SWEP, "PrimaryAttack", function()
        local owner = SWEP:GetOwner()
        if not IsValid(owner) or not IsValid(owner.BarrelMimicEnt) then return end
        owner.BarrelMimicEnt:SetModelScale(10, 1)
        owner.BarrelMimicEnt:SetPAPCamo()
        owner:EmitSound("ttt_pack_a_punch/mega_barrel_transformer/duuun.mp3")

        timer.Simple(1, function()
            if not IsValid(owner) or not IsValid(owner.BarrelMimicEnt) then return end
            owner.BarrelMimicEnt:Activate()
        end)
    end)
end

TTTPAP:Register(UPGRADE)