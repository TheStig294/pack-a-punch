local UPGRADE = {}
UPGRADE.id = "jester_faker"
UPGRADE.class = "weapon_ttt_m4a1_s"
UPGRADE.name = "Jester Faker"
UPGRADE.desc = "While held, you can't deal damage to traitors"
UPGRADE.noCamo = true
UPGRADE.noSound = true

function UPGRADE:Apply(SWEP)
    SWEP.Primary.Sound = Sound("Weapon_M4A1.Single")
    SWEP:GetOwner().PAPJesterFaker = SWEP

    self:AddHook("EntityTakeDamage", function(victim, dmg)
        local attacker = dmg:GetAttacker()
        -- Only affect players
        if not self:IsPlayer(attacker) or not self:IsPlayer(victim) then return end
        -- Only affect players with the jester faker
        local inflictor = attacker:GetActiveWeapon()
        if not attacker.PAPJesterFaker or inflictor ~= attacker.PAPJesterFaker then return end
        -- Only affect traitors
        if victim:GetRole() == ROLE_TRAITOR or (victim.IsTraitorTeam and victim:IsTraitorTeam()) then return true end
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PAPJesterFaker = nil
    end
end

TTTPAP:Register(UPGRADE)