local UPGRADE = {}
UPGRADE.id = "double_death_link"
UPGRADE.class = "weapon_ttt_death_link"
UPGRADE.name = "Double Death Link"
UPGRADE.desc = "You can link one more person,\nbypasses explosion immunities!"

function UPGRADE:Apply(SWEP)
    self:SetClip(SWEP, 2)
    if CLIENT then return end

    function SWEP:PrimaryAttack()
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end
        local victim = owner:GetEyeTrace().Entity
        if not IsPlayer(victim) then return end

        if victim.TTTPAPDoubleDeathLink then
            owner:ChatPrint("Player already death linked!")

            return
        end

        victim.TTTPAPDoubleDeathLink = victim.TTTPAPDoubleDeathLink or {}
        owner.TTTPAPDoubleDeathLink = owner.TTTPAPDoubleDeathLink or {}
        table.insert(victim.TTTPAPDoubleDeathLink, owner)
        table.insert(owner.TTTPAPDoubleDeathLink, victim)
        owner:ChatPrint("You death linked with: " .. victim:Nick())
        self:TakePrimaryAmmo(1)
        self:SendWeaponAnim(ACT_DEPLOY)

        if self:Clip1() <= 0 then
            self:Remove()
            owner:ConCommand("lastinv")
        end
    end

    self:AddHook("PostPlayerDeath", function(ply)
        local victims = ply.TTTPAPDoubleDeathLink
        if not victims or not istable(victims) then return end
        ply.TTTPAPDoubleDeathLink = nil

        for _, victim in ipairs(victims) do
            -- No chance of an infinite loop because PostPlayerDeath reports the player as dead from ply:Alive(), which self:IsAlivePlayer() uses
            if not self:IsAlivePlayer(victim) then continue end
            victim:ChatPrint("You were death-linked with " .. ply:Nick() .. "!")
            local dmg = DamageInfo()
            dmg:SetDamageType(DMG_CLUB)
            dmg:SetDamage(10000)
            dmg:SetInflictor(ents.Create("weapon_ttt_death_link"))
            dmg:SetAttacker(ply)
            victim:TakeDamageInfo(dmg)

            -- In case the player is immune to "club" damage, force-kill them without any damage info
            timer.Simple(0.1, function()
                if victim:Alive() and not victim:IsSpec() then
                    victim:Kill()
                end
            end)
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPDoubleDeathLink = nil
    end
end

TTTPAP:Register(UPGRADE)