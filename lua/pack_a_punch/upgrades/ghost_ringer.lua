local UPGRADE = {}
UPGRADE.id = "ghost_ringer"
UPGRADE.class = "weapon_ttt_dead_ringer"
UPGRADE.name = "Ghost Ringer"
UPGRADE.desc = "Become a ghost while active!"
local upgradeApplied = false

function UPGRADE:Apply(SWEP)
    if upgradeApplied then return end
    upgradeApplied = true
    local PLAYER = FindMetaTable("Player")
    PLAYER.PAPOldDRfakedeath = PLAYER.DRfakedeath

    function PLAYER:DRfakedeath(dmg)
        self:PAPOldDRfakedeath(dmg)
        local wep = self:GetWeapon(UPGRADE.class)
        if not IsValid(wep) then return end
        if not wep.PAPUpgrade or wep.PAPUpgrade.id ~= UPGRADE.id then return end
        self:SetMoveType(MOVETYPE_NOCLIP)
    end

    PLAYER.PAPOldDRuncloak = PLAYER.DRuncloak

    function PLAYER:DRuncloak()
        self:PAPOldDRuncloak()

        if UPGRADE:IsAlive(self) then
            self:SetMoveType(MOVETYPE_WALK)

            -- Give players a moment to get unstuck if they are currently stuck
            timer.Simple(4, function()
                if UPGRADE:IsAlive(self) and not self:IsInWorld() or not UPGRADE:PlayerNotStuck(self) then
                    local oldHealth = self:Health()
                    self:Spawn()
                    self:SetHealth(oldHealth)
                    self:EmitSound("ttt/spy_uncloak_feigndeath.wav")
                    -- Dead ringer doesn't reset properly here because of the player spawn call so we have to manually set it to charging mode
                    self:SetNWInt("DRStatus", 4)
                    self:SetNWBool("DRDead", false)
                    self:SetNWInt("DRCharge", 0)
                    self:ChatPrint("You were stuck and respawned!")
                end
            end)
        end
    end
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        if self:IsAlive(ply) then
            ply:SetMoveType(MOVETYPE_WALK)
        end
    end
end

TTTPAP:Register(UPGRADE)