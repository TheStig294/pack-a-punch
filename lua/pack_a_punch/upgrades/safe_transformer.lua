local UPGRADE = {}
UPGRADE.id = "safe_transformer"
UPGRADE.class = "weapon_sfk_safeplacer"
UPGRADE.name = "Safe Transformer"
UPGRADE.desc = "Turns a player into your safe!"

UPGRADE.convars = {
    {
        name = "pap_safe_transformer_extra_drop_time",
        type = "int"
    }
}

local extraDropTimeCvar = CreateConVar("pap_safe_transformer_extra_drop_time", 30, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds extra until the safe is dropped", 5, 120)

-- We need to bust out the rare UPGRADE:OnPurchase(), because the safe will drop when the player switches to holstered while upgrading it!
function UPGRADE:OnPurchase(SWEP)
    local own = SWEP:GetOwner()

    -- Give the safekeeper extra time to transform someone
    if IsValid(own) and own.TTTSafekeeperDropTime then
        own:SetProperty("TTTSafekeeperDropTime", own.TTTSafekeeperDropTime + extraDropTimeCvar:GetInt())
    end

    function SWEP:Holster()
        if not IsFirstTimePredicted() then return end
        local owner = self:GetOwner()
        -- The safe is supposed to be dropped when the player changes weapons or dies
        -- But we obviously don't want the player to drop the safe if they're upgrading it!
        local isUpgrading = owner:GetNWBool("TTTPAPIsUpgrading")

        if IsValid(owner) and not isUpgrading then
            self:PrimaryAttack()
        end

        return isUpgrading
    end
end

function UPGRADE:Apply(SWEP)
    -- Have to copy-paste the primary attack function here because we're changing too much
    -- Originally created by Malivil
    function SWEP:PrimaryAttack()
        if CLIENT then return end
        if not IsFirstTimePredicted() then return end
        local owner = self:GetOwner()
        if not IsPlayer(owner) then return end
        if owner:IsRoleAbilityDisabled() then return end
        -- Ignore the up-and-down component of where the player is aiming
        local aimVec = owner:GetAimVector()
        aimVec.z = 0
        -- Convert it to an angle and use that as the start position
        local eyeAngles = aimVec:Angle()
        local startPos = owner:GetPos()

        -- If the player is alive, place it in front of them
        if owner:Alive() and not owner:IsSpec() then
            startPos = startPos + eyeAngles:Forward() * 55
        end

        -- Find a location to drop the safe in front of the player
        local tr = owner:GetEyeTrace()
        local victim

        -- Make sure the hit isn't at the end of the length because that seems to mean it actually hasn't hit anything
        if UPGRADE:IsAlivePlayer(tr.Entity) then
            victim = tr.Entity
        elseif owner.TTTSafekeeperDropTime and owner.TTTSafekeeperDropTime < CurTime() then
            -- If the safekeeper takes too long, transform *them* into the safe!
            victim = owner
            owner:ClearQueuedMessage("sfkInvalidDrop")
            owner:QueueMessage(MSG_PRINTCENTER, "You got too tired and transformed yourself!")
        else
            -- If we didn't find a place, let the user know and don't actually place the safe
            owner:ClearQueuedMessage("sfkInvalidDrop")
            owner:QueueMessage(MSG_PRINTCENTER, "Look at a player to transform", nil, "sfkInvalidDrop")

            return
        end

        local safe = ents.Create("ttt_pap_safekeeper_safe")
        local ang = Angle(0, eyeAngles.y, 0)
        ang:RotateAroundAxis(Vector(0, 0, 1), 90)
        -- Spawn the safe
        safe:SetPos(victim:GetPos())
        safe:SetAngles(victim:EyeAngles())
        safe:SetPlacer(owner)
        SYNC:SetEntityProperty(safe, "TTTPAPSafeTransformerVictim", victim)
        victim:SetNoDraw(true)
        victim.TTTPAPSafeTransformerSafe = safe
        safe:Spawn()
        safe:Activate()
        UPGRADE:SetUpgraded(safe)
        owner:SetProperty("TTTSafekeeperSafe", safe:EntIndex())
        owner:ClearProperty("TTTSafekeeperDropTime", owner)
        self:Remove()
    end

    self:AddHook("PostPlayerDeath", function(victim)
        local safe = victim.TTTPAPSafeTransformerSafe

        if IsValid(safe) then
            SYNC:ClearEntityProperty(safe, "TTTPAPSafeTransformerVictim")
        end
    end)
end

-- Just to be safe...
-- (Haha, get it?)
function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply:SetNoDraw(false)
        ply.TTTPAPSafeTransformerSafe = nil
    end
end

TTTPAP:Register(UPGRADE)