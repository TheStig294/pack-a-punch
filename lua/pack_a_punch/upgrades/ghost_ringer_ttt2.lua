local UPGRADE = {}
UPGRADE.id = "ghost_ringer_ttt2"
UPGRADE.class = "weapon_ttt_deadringer"
UPGRADE.name = "Ghost Ringer"
UPGRADE.desc = "Become a ghost while active!"
local upgradeApplied = false

function UPGRADE:Apply(SWEP)
    if upgradeApplied then return end
    upgradeApplied = true

    hook.Add("DeadRingerCloak", "TTTPAPGhostRingerTTT2", function(ringer, owner, dmg, rag)
        if self:IsUpgraded(ringer) then
            owner:SetMoveType(MOVETYPE_NOCLIP)
        end
    end)

    hook.Add("DeadRingerUncloak", "TTTPAPGhostRingerTTT2", function(ringer, owner)
        if not ringer.PAPUpgrade or ringer.PAPUpgrade.id ~= self.id then return end

        if self:IsAlive(owner) then
            owner:SetMoveType(MOVETYPE_WALK)

            -- Give players a moment to get unstuck if they are currently stuck
            timer.Simple(4, function()
                if self:IsAlive(owner) and not owner:IsInWorld() or not UPGRADE:PlayerNotStuck(owner) then
                    local oldHealth = owner:Health()
                    owner:Spawn()
                    owner:SetHealth(oldHealth)
                    owner:EmitSound("ttt/spy_uncloak_feigndeath.wav")
                    -- Dead ringer doesn't reset properly here because of the player spawn call so we have to manually set it to charging mode
                    owner:SetNWInt("DRStatus", 4)
                    owner:SetNWBool("DRDead", false)
                    owner:SetNWInt("DRCharge", 0)
                    owner:ChatPrint("You were stuck and respawned!")
                end
            end)
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        if self:IsAlive(ply) then
            ply:SetMoveType(MOVETYPE_WALK)
        end
    end
end

TTTPAP:Register(UPGRADE)