local UPGRADE = {}
UPGRADE.id = "invincible_barnacle"
UPGRADE.class = "weapon_ttt_barnacle"
UPGRADE.name = "Invincible Barnacle"
UPGRADE.desc = "Cannot be killed!\nPlays a 'help I'm stuck in a barnacle!' sound for the victim"

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPlaceTurret = SWEP.PlaceTurret

    function SWEP:PlaceTurret()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local pos = owner:GetEyeTrace().HitPos
        self:PAPOldPlaceTurret()

        for _, barnacle in ipairs(ents.FindByClass("npc_barnacle")) do
            if barnacle:GetPos() == pos then
                barnacle.PAPInvincibleBarnacle = true
                barnacle:SetPAPCamo()
                barnacle.CurrentSound = 1
            end
        end
    end

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        -- Block the damage if damaging an invincible barnacle
        if ent.PAPInvincibleBarnacle then return true end
        -- Else look for a player to play the help sound effect
        if CLIENT and not self:IsPlayer(ent) then return end
        local barnacle = dmg:GetInflictor()
        if not barnacle.PAPInvincibleBarnacle then return end

        -- Plays the "Help i'm stuck in a barnacle!" sound for everyone
        if not ent.PAPInvincibleBarnacleSoundCooldown then
            ent:EmitSound("ttt_pack_a_punch/invincible_barnacle/help" .. barnacle.CurrentSound .. ".mp3")
            barnacle.CurrentSound = barnacle.CurrentSound + 1
            ent.PAPInvincibleBarnacleSoundCooldown = true

            timer.Simple(2, function()
                ent.PAPInvincibleBarnacleSoundCooldown = false
            end)
        end
    end)
end

TTTPAP:Register(UPGRADE)