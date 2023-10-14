local UPGRADE = {}
UPGRADE.id = "ghost_ringer"
UPGRADE.class = "weapon_ttt_dead_ringer"
UPGRADE.name = "Ghost Ringer"
UPGRADE.desc = "Become a ghost while active!"
local upgradeApplied = false

function UPGRADE:Apply(SWEP)
    if upgradeApplied then return end

    -- From my "Crouch to unstuck" mod, modified slightly for use for this upgrade
    local function PlayerNotStuck(ply)
        -- Check player is no-clipping
        if ply:IsEFlagSet(EFL_NOCLIP_ACTIVE) then return true end
        -- Check player is alive
        if not ply:Alive() or (ply.IsSpec and ply:IsSpec()) then return true end
        -- Check player is not in a vehicle prop like an airboat
        local parent = ply:GetParent()

        if IsValid(parent) then
            local class = parent:GetClass()

            if string.StartWith(class, "prop_vehicle") then
                ply.NotStuckWasInVehicle = true

                return true
            end
        else
            -- Parent returns NULL while exiting a vehicle, delay running the usual stuck-check code to give time to exit
            timer.Simple(1.5, function()
                if IsValid(ply) then
                    ply.NotStuckWasInVehicle = false
                end
            end)

            if ply.NotStuckWasInVehicle then return true end
        end

        local pos = ply:GetPos()

        local t = {
            start = pos,
            endpos = pos,
            mask = MASK_PLAYERSOLID,
            filter = ply
        }

        local isSolidEnt = util.TraceEntity(t, ply).StartSolid
        local ent = util.TraceEntity(t, ply).Entity

        if IsValid(ent) then
            -- A backup check if an entity can be passed through or not
            local nonPlayerCollisionGroups = {1, 2, 10, 11, 12, 15, 16, 17, 20}

            local entGroup = ent:GetCollisionGroup()

            for i, group in ipairs(nonPlayerCollisionGroups) do
                if entGroup == group then return true end
            end

            -- Workaround to stop TTT entities being used to boost through walls and for other ignored classes
            if ent.CanUseKey then return true end
        end
        -- Else, use what the trace returned

        return not isSolidEnt
    end

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
                if UPGRADE:IsAlive(self) and not self:IsInWorld() or not PlayerNotStuck(self) then
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
        ply.PAPGhostRinger = nil

        if self:IsAlive(ply) then
            ply:SetMoveType(MOVETYPE_WALK)
        end
    end
end

TTTPAP:Register(UPGRADE)