local UPGRADE = {}
UPGRADE.id = "instant_possession"
UPGRADE.class = "weapon_ttt_demonsign"
UPGRADE.name = "Instant Possession"
UPGRADE.desc = "You automatically respawn in place of anyone who walks over it!"
local upgradedSWEPs = {}

function UPGRADE:Apply(SWEP)
    if CLIENT then return end
    table.insert(upgradedSWEPs, SWEP)

    timer.Create("TTTPAPInstantPossession", 0.1, 0, function()
        for _, wep in ipairs(upgradedSWEPs) do
            -- Victim is only set when the owner of the demonic possession has died, and someone walks over it
            local victim = wep.victim
            local owner = wep.LastOwner

            if IsValid(wep) and self:IsUpgraded(wep) and self:IsAlivePlayer(victim) and self:IsPlayer(owner) and not self:IsAlive(owner) then
                local pos = victim:GetPos()
                local dmg = DamageInfo()
                dmg:SetDamage(10000)
                dmg:SetDamageType(DMG_BURN)
                dmg:SetInflictor(wep)
                dmg:SetAttacker(owner)
                victim:TakeDamageInfo(dmg)

                -- Check the victim wasn't immune to burn damage first (e.g. Jester)
                -- or for whatever reason didn't actually die 
                timer.Simple(0.1, function()
                    if self:IsAlive(victim) then
                        victim:Kill()
                    end

                    victim:ChatPrint("You walked over " .. owner:Nick() .. "'s upgraded demonic possession...")
                    owner:SpawnForRound(true)

                    timer.Simple(0, function()
                        owner:SetPos(pos)
                        owner:ChatPrint(victim:Nick() .. " walked over your upgraded demonic possession!")
                    end)
                end)
            end
        end
    end)
end

function UPGRADE:Reset()
    table.Empty(upgradedSWEPs)
    timer.Remove("TTTPAPInstantPossession")

    -- Fixing error spam with the base weapon...
    for _, ply in player.Iterator() do
        hook.Remove("StartCommand", "Demon_MoveVictim" .. ply:Nick())
    end
end

TTTPAP:Register(UPGRADE)