local UPGRADE = {}
UPGRADE.id = "potion_leaping"
UPGRADE.class = "weapon_ttt_mc_jumppotion"
UPGRADE.name = "Leaping Potion"
UPGRADE.desc = "Jump much higher, no fall damage!"

UPGRADE.convars = {
    {
        name = "pap_potion_leaping_mult",
        type = "int"
    }
}

local multCvar = CreateConVar("pap_potion_leaping_jump_mult", "4", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Jump multiplier", 1, 10)

function UPGRADE:Apply(SWEP)
    timer.Simple(0.1, function()
        SWEP:SetClip1(-1)
    end)

    local DestroySound = "minecraft_original/glass2.wav"

    function SWEP:SecondaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        if not owner.PAPLeapingPotionOGJump then
            owner.PAPLeapingPotionOGJump = owner:GetJumpPower()
        end

        owner:SetJumpPower(owner.PAPLeapingPotionOGJump * multCvar:GetInt())
        owner.PAPLeappingPotion = true
        self:EmitSound(DestroySound)

        if SERVER then
            self:Remove()
        end
    end

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if ent.PAPLeappingPotion and dmg:IsFallDamage() then return true end
    end)

    self:AddHook("PostPlayerDeath", function(ply)
        if ply.PAPLeapingPotionOGJump then
            ply:SetJumpPower(ply.PAPLeapingPotionOGJump)
            ply.PAPLeapingPotionOGJump = nil
            ply.PAPLeappingPotion = nil
        end
    end)

    if CLIENT then
        SWEP.PAPOldDrawWorldModel = SWEP.DrawWorldModel

        function SWEP:DrawWorldModel()
            SWEP:PAPOldDrawWorldModel()

            if IsValid(self.WorldModelEnt) then
                self.WorldModelEnt:SetPAPCamo()
            end
        end
    end
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        if ply.PAPLeapingPotionOGJump then
            ply:SetJumpPower(ply.PAPLeapingPotionOGJump)
            ply.PAPLeapingPotionOGJump = nil
            ply.PAPLeappingPotion = nil
        end
    end
end

TTTPAP:Register(UPGRADE)