local UPGRADE = {}
UPGRADE.id = "the_fractalizer"
UPGRADE.class = "tfa_shrinkray"
UPGRADE.name = "The Fractalizer"
UPGRADE.desc = "Immune to becoming a baby + extra ammo\nYou make higher-pitched sounds!"
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    -- Is a CoD weapon, so has its own PAP function we can take advantage of, this is not from this mod
    SWEP:OnPaP()
    -- Keep track of who is the owner, in case someone else picks it up
    -- Only the current owner of the weapon should be immune to baby maker shots
    SWEP.PAPOwner = SWEP:GetOwner()

    if IsValid(SWEP.PAPOwner) then
        SWEP.PAPOwner.PAPTheBabyKickerImmune = "immune"
    end

    self:AddToHook(SWEP, "OwnerChanged", function()
        if IsValid(SWEP.PAPOwner) then
            SWEP.PAPOwner.PAPTheBabyKickerImmune = "not immune"
        end

        SWEP.PAPOwner = SWEP:GetOwner()

        if IsValid(SWEP.PAPOwner) then
            SWEP.PAPOwner.PAPTheBabyKickerImmune = "immune"
        end
    end)

    self:AddHook("PlayerPostThink", function(ply)
        if ply.PAPTheBabyKickerImmune == "immune" then
            ply:SetNW2Bool("IsBaby", true)
            ply:SetNW2Bool("ShouldKickBaby", false)
        elseif ply.PAPTheBabyKickerImmune == "not immune" then
            ply:SetNW2Bool("IsBaby", false)
            ply:SetNW2Bool("ShouldKickBaby", true)
            ply.PAPTheBabyKickerImmune = nil
        end
    end)

    -- Counter-act the damage penalty for being a baby if the player is immune to being one
    self:AddHook("EntityTakeDamage", function(target, dmginfo)
        local attacker = dmginfo:GetAttacker()

        if IsValid(attacker) and attacker:GetNW2Bool("IsBaby") and attacker.PAPTheBabyKickerImmune == "immune" then
            dmginfo:ScaleDamage(5)
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.PAPTheBabyKickerImmune = nil
        ply:SetNW2Bool("IsBaby", false)
        ply:SetNW2Bool("ShouldKickBaby", false)
    end
end

TTTPAP:Register(UPGRADE)