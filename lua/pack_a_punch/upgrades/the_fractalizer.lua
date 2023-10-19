local UPGRADE = {}
UPGRADE.id = "the_fractalizer"
UPGRADE.class = "tfa_shrinkray"
UPGRADE.name = "The Fractalizer"
UPGRADE.desc = "Immune to your own shots + extra ammo\nYou make higher-pitched sounds!"

function UPGRADE:Apply(SWEP)
    -- Is a CoD weapon, so has its own PAP function we can take advantage of, this is not from this mod
    SWEP:OnPaP()
    SWEP:GetOwner().PAPTheBabyKickerImmune = true

    self:AddHook("PlayerPostThink", function(ply)
        if ply.PAPTheBabyKickerImmune then
            ply:SetNW2Bool("IsBaby", true)
            ply:SetNW2Bool("ShouldKickBaby", false)
        end
    end)

    -- Counter-act the damage penalty for being a baby if the player is immune to being one
    self:AddHook("EntityTakeDamage", function(target, dmginfo)
        local attacker = dmginfo:GetAttacker()

        if IsValid(attacker) and attacker:GetNW2Bool("IsBaby") and attacker.PAPTheBabyKickerImmune then
            dmginfo:ScaleDamage(5)
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PAPTheBabyKickerImmune = nil
        ply:SetNW2Bool("IsBaby", false)
        ply:SetNW2Bool("ShouldKickBaby", false)
    end
end

TTTPAP:Register(UPGRADE)